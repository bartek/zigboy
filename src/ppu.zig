const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const std = @import("std");
const print = @import("std").debug.print;

const Fetcher = @import("./fetcher.zig").Fetcher;

// ppu_state contains possible PPU states
const ppu_state = enum(u8) {
    oam_scan,
    pixel_transfer,
    hblank,
    vblank,
};

const palette = [4][3]u8{
    [3]u8{ 0xff, 0xff, 0xff }, // White
    [3]u8{ 0xaa, 0xaa, 0xaa }, // Light gray
    [3]u8{ 0x55, 0x55, 0x55 }, // Dark gray
    [3]u8{ 0x00, 0x00, 0x00 }, // Black
};

const width = 160;
const height = 144;
pub const framebuf_pitch = width * @sizeOf(u32);

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
    // LCDC is the LCD control register
    LCDC: u8 = 0,

    // BGP is the background map tiles palette
    BGP: u8 = 0,

    // ly is the number of the line currently being displayed
    // This is in Memory Location 0xFF44
    ly: u8,

    // state is the current state of the machine
    state: ppu_state,

    // ticks is the clock ticks counter for the current line
    ticks: usize,

    // buffer contains the pixels to display on screen
    // 160x144 pixels stored using 4 bytes per pixel (as per RGBA32) gives us
    // the exact size we need for the buffer.
    buffer: [width * height * 4]u8 = undefined,

    // x is the number of pixels already output on the current scanline
    x: u8,

    // offset
    offset: usize = 0,

    highest_color: u8 = 0,

    fetcher: Fetcher = undefined,

    pub fn init(allocator: Allocator) !PPU {
        const bufs = try allocator.alloc(u8, (framebuf_pitch * height) * 2);
        std.mem.set(u8, bufs, 0);

        return PPU{
            .ly = 0,
            .ticks = 0,
            .state = ppu_state.oam_scan,
            .x = 0,
        };
    }

    pub fn assign_fetcher(self: *PPU, fetcher: Fetcher) void {
        self.fetcher = fetcher;
    }

    pub fn get_buffer(self: *PPU) []u8 {
        return &self.buffer;
    }

    // read provides a public function for memory to read from the PPU
    pub fn read(self: *PPU, address: u16) u8 {
        switch (address) {
            0xff40 => {
                return self.LCDC;
            },
            0xff44 => {
                return self.ly;
            },
            0xff47 => {
                return self.BGP;
            },
            else => {
                @panic("PPU: read from invalid address");
            },
        }
    }
    // write provides a public function for memory to write to the PPU
    pub fn write(self: *PPU, address: u16, value: u8) void {
        switch (address) {
            0xff40 => {
                self.LCDC = value;
            },
            0xff47 => {
                self.BGP = value;
            },
            else => {
                @panic("PPU: Invalid write to address");
            },
        }
    }

    pub fn tick(self: *PPU) void {
        // Screen assumed on, count ticks.
        self.ticks += 1;

        switch (self.state) {
            // In OAM search, PPU scans the OAM (Objects Attribute Memory) from
            // 0xFE00 to 0xFE9F to mix sprite pixels in the current line later.
            // This always takes 40 clock ticks.
            ppu_state.oam_scan => {
                if (self.ticks == 40) {
                    // Initialize pixel transfer state
                    self.x = 0;
                    var tile_line = self.ly % 8;
                    //print("Tile line {d}, {d}\n", .{ tile_line, self.ly });
                    var tilemap_row_addr = 0x9800 + (@as(u16, self.ly / 8) * 32);

                    self.fetcher.start(tilemap_row_addr, tile_line);

                    self.state = ppu_state.pixel_transfer;
                }
            },
            ppu_state.pixel_transfer => {
                // Fetch pixel data into our pixel FIFO
                self.fetcher.tick();

                // Stop if the FIFO is not holding at least 8 pixels.
                if (self.fetcher.fifo.length() <= 8) {
                    return;
                }

                // Put a pixel from the FIFO on screen if we have any.
                var pixel_color = self.fetcher.fifo.pop() catch |err| {
                    print("PPU: Error while popping pixel from FIFO: {s}\n", .{err});
                    @panic("unexpected fifo pop error");
                };

                print("Pixel Color {d}\n", .{pixel_color});
                var color: u8 = 0x00000000;

                switch (pixel_color) {
                    0...50 => {
                        color = 0;
                    },
                    51...100 => {
                        color = 1;
                    },
                    101...150 => {
                        color = 2;
                    },
                    151...200 => {
                        color = 3;
                    },
                    else => {
                        color = 0x000000ee;
                    },
                }

                self.buffer[0 + self.offset] = color;
                self.buffer[1 + self.offset] = color;
                self.buffer[2 + self.offset] = color;
                self.buffer[3 + self.offset] = color;
                self.offset += 4;

                // Check if the scanline is complete.
                self.x += 1;
                if (self.x == width) {
                    // Blank slate
                    // Screen.HBlank
                    self.state = ppu_state.hblank;
                }
            },
            ppu_state.hblank => {
                // TODO: wait, then go back to sprite search for next line, or
                // vblank
                if (self.ticks == 456) {
                    self.ticks = 0;
                    self.ly += 1;
                    if (self.ly == height) {
                        // Call Screen.VBlank here
                        self.offset = 0;
                        self.state = ppu_state.vblank;
                    } else {
                        self.state = ppu_state.oam_scan;
                    }
                }
            },
            ppu_state.vblank => {
                if (self.ticks == 456) {
                    self.ticks = 0;
                    self.ly += 1;
                    if (self.ly == 153) {
                        // End of VBlank, back to initial state.
                        self.ly = 0;
                        self.state = ppu_state.oam_scan;
                    }
                }
            },
        }
    }
};
