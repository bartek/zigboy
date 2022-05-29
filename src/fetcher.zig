const std = @import("std");
const print = @import("std").debug.print;

const Fifo = @import("./fifo.zig").Fifo;
const Memory = @import("./memory.zig").Memory;

const fetcher_state = enum {
    read_tile_id,
    read_tile_data0,
    read_tile_data1,
    push_to_fifo,
};

// Fetcher is the component responsible for loading the FIFO registers with data
//
// It is continously active throughout PPU Mode 3 and keeps supplying the FIFO
// with new pixels to shift out. The process of fetching pixels is split up into
// 4 different steps, which are defined in the tick method.
pub const Fetcher = struct {
    const Self = @This();

    // fifo is the pixel FIFO that the PPU will read and write to.
    // It has a fized capacity of 16 items.
    fifo: Fifo(u8, 16),

    // ticks is the clock cycle counter for timing
    ticks: u16 = 0,

    // state is current state of our fetcher state machine.
    state: fetcher_state,

    tile_id: u8 = 0,

    tile_index: u8 = 0,

    tile_data: [8]u8 = undefined,

    map_address: u16 = 0,

    tile_line: u8 = 0,

    memory: *Memory,

    pub fn init(memory: *Memory) !Self {
        return Self{
            .fifo = try Fifo(u8, 16).init(0),
            .state = fetcher_state.read_tile_id,

            .memory = memory,
        };
    }

    // start starts fetching a line of pixels from the given tile address
    // tile_line indicates which row of pixels to pick from each tile read.
    pub fn start(self: *Self, map_address: u16, tile_line: u8) void {
        self.tile_index = 0;
        self.map_address = map_address;
        self.tile_line = tile_line;
        self.state = fetcher_state.read_tile_id;

        self.fifo.clear();
    }

    pub fn tick(self: *Self) void {
        // The fetcher runs at half the speed of the PPU (every 2 ticks, also
        // called 2 T-Cycles)
        self.ticks += 1;
        if (self.ticks < 2) {
            return;
        }
        self.ticks = 0;

        switch (self.state) {
            fetcher_state.read_tile_id => {
                self.tile_id = self.memory.read(self.map_address + @as(u16, self.tile_index));
                self.state = fetcher_state.read_tile_data0;
            },
            fetcher_state.read_tile_data0 => {
                self.read_tile_line(0, self.tile_id, self.tile_line, &self.tile_data);
                self.state = fetcher_state.read_tile_data1;
            },
            fetcher_state.read_tile_data1 => {
                self.read_tile_line(1, self.tile_id, self.tile_line, &self.tile_data);
                self.state = fetcher_state.push_to_fifo;
            },
            fetcher_state.push_to_fifo => {
                if (self.fifo.length() <= 8) {
                    var i: usize = 7;
                    while (i > 0) {
                        self.fifo.push(self.tile_data[i]) catch |err| {
                            print("FIFO overflow\n {s}", .{err});
                        };
                        i -= 1;
                    }
                }
                self.tile_index += 1;
                self.state = fetcher_state.read_tile_id;
            },
        }
    }

    fn read_tile_line(self: *Self, bit_plane: u8, tile_id: u8, tile_line: u8, tile_data: *[8]u8) void {
        var offset = 0x800 + (@as(u16, tile_id) * 16);
        var address = offset + (@as(u16, tile_line) * 2);
        var data = self.memory.read(address + bit_plane);

        var pos: usize = 0;
        while (pos <= 7) {
            if (bit_plane == 0) {
                // Least significant bit, replace the previous value.
                tile_data[pos] = (data >> @intCast(u3, pos)) & 1;
            } else {
                // Most significant bit, update the previous value.
                tile_data[pos] |= (data >> @intCast(u3, pos)) << 1;
            }
            pos += 1;
        }
    }
};
