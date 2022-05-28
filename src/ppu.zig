const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const fifo = std.fifo;
const std = @import("std");

const Memory = @import("./memory.zig").Memory;

// ppu_state contains possible PPU states
const ppu_state = enum(u8) {
    oam_search,
    pixel_transfer,
    hblank,
    vblank,
};

const ppu_width = 160;
const ppu_height = 144;

//                                 PPU States and Transitions
//
//             ┌────────────────┐                    ┌───────────────────────┐
//             ▼             No │                    ▼                       │ No
//      ┌────────────┐     ┌────┴────┐ Yes   ┌────────────────┐       ┌──────┴─────┐
//      │ OAM Search │     │  Done?  ├─────► │ Pixel Transfer │─────► │  x = 160?  │
//      └────────────┘     └─────────┘       └────────────────┘       └──────┬─────┘
//             ▲                                                             │ Yes
//             │                                                             ▼
//             │ ◄─────────────────────────────────┐                   ┌──────────┐
//             │                                   │                ┌► │  HBlank  ├─┐
//        Yes  │                                   │ No          No │  └──────────┘ │
//       ┌─────┴────┐     ┌────────┐   Yes   ┌─────┴────┐    Yes   ┌┴────────┐      │
//       │ LY = 153 │ ◄───│ VBlank │ ◄───────┤  LY=144  │ ◄────────│  Done?  │ ◄────┘
//       └─────┬────┘     └────────┘         └──────────┘          └─────────┘
//        No   │              ▲
//             └──────────────┘
pub const PPU = struct {
    // ly is the number of the line currently being displayed
    // This is in Memory Location 0xFF44
    ly: u8,

    // state is the current state of the machine
    state: ppu_state,

    // ticks is the clock ticks counter for the current line
    ticks: u8,

    // x is the number of pixels already output on the current scanline
    x: u8,

    fetcher: Fetcher,

    pub fn init(allocator: Allocator, memory: *Memory) !PPU {
        return PPU{
            .ly = 0,
            .ticks = 0,
            .state = ppu_state.oam_search,
            .fetcher = try Fetcher.init(allocator, memory),
            .x = 0,
        };
    }

    pub fn tick(self: *PPU) void {
        switch (self.state) {
            ppu_state.oam_search => {
                if (self.ticks == 40) {
                    // Initialize pixel transfer state
                    self.x = 0;
                    var tile_line = self.ly % 8;
                    var tilemap_row_addr = 0x9800 + @as(u16, (self.ly / 8) * 32);

                    self.fetcher.start(tilemap_row_addr, tile_line);

                    self.state = ppu_state.pixel_transfer;
                }
            },
            ppu_state.pixel_transfer => {
                self.x += 1;

                if (self.x == ppu_width) {
                    // TODO: Push pixel data to display
                    self.state = ppu_state.hblank;
                }
            },
            ppu_state.hblank => {
                // TODO: wait, then go back to sprite search for next line, or
                // vblank
                if (self.ticks == 456) {
                    self.ticks = 0;
                    self.ly += 1;
                    if (self.ly == ppu_height) {
                        self.state = ppu_state.vblank;
                    } else {
                        self.state = ppu_state.oam_search;
                    }
                }
            },
            ppu_state.vblank => {
                if (self.ticks == 456) {
                    self.ticks = 0;
                    self.ly += 1;
                    if (self.ly == 153) {
                        self.ly = 0;
                        self.state = ppu_state.oam_search;
                    }
                }
            },
        }
    }
};

const fetcher_state = enum {
    read_tile_id,
    read_tile_data0,
    read_tile_data1,
    push_to_fifo,
};

const Fetcher = struct {
    // fifo is the pixel FIFO that the PPU will read
    fifo: std.fifo.LinearFifo(u8, .Dynamic),

    // mmu is a reference to the global memory management system
    memory: *Memory,

    // ticks is the clock cycle counter for timing
    ticks: u16,

    // state is current state of our fetcher state machine.
    state: fetcher_state,

    tile_id: u8,

    tile_index: u8,

    tile_data: ArrayList([]u8),

    map_address: u16,

    tile_line: u8,

    pub fn init(allocator: Allocator, memory: *Memory) !Fetcher {
        _ = allocator;
        return Fetcher{
            .memory = memory,
            .fifo = fifo.LinearFifo(u8, .Dynamic).init(allocator),
            .ticks = 0,
            .tile_index = 0,
            .tile_id = 0,
            .tile_line = 0,
            .tile_data = ArrayList([]u8).init(allocator),
            .map_address = 0,
            .state = fetcher_state.read_tile_id,
        };
    }

    pub fn deinit(self: *Fetcher) void {
        self.fifo.deinit();
    }

    // start starts fetching a line of pixels from the given tile address
    // tile_line indicates which row of pixels to pick from each tile read.
    pub fn start(self: *Fetcher, map_address: u16, tile_line: u8) void {
        self.tile_index = 0;
        self.map_address = map_address;
        self.tile_line = tile_line;
        self.state = fetcher_state.read_tile_id;
        //self.fifo.writer().print("!");
    }

    pub fn tick(self: *Fetcher) void {
        // The fetcher runs at half the speed of the PPU (every 2 ticks)
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
                self.fifo.writer().print("!!!");
                var offset = 0x800 + (@as(u16, self.tile_id) * 16);

                var address = offset + (@as(u16, self.tile_lin) * 2);

                var data = self.memory.read(address);

                var pos: u8 = 0;
                while (pos <= 7) {
                    self.pixel_data[pos] = (data >> pos) & 1;
                }

                // Advance to next tile in the map's row
                self.tile_index += 1;

                self.state = fetcher_state.read_tile_data1;
            },
            fetcher_state.read_tile_data1 => {
                self.state = fetcher_state.push_to_fifo;
            },
            fetcher_state.push_to_fifo => {
                if (self.fifo.writableLength() <= 8) {
                    var i: usize = 7;
                    while (i >= 0) {
                        self.fifo.write(self.state.tile_data[i]);
                        i -= 1;
                    }
                }

                self.state = fetcher_state.read_tile_id;
            },
        }
    }
};
