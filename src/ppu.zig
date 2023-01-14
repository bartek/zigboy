const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const std = @import("std");
const print = @import("std").debug.print;

const bits = @import("./bits.zig");

const Fetcher = @import("./fetcher.zig").Fetcher;
const Screen = @import("./screen.zig").Screen;

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

    // scan_line_counter is the scan line counter
    // It is reset to 456 whenever the LCD is disabled
    scan_line_counter: usize,

    // screen is the screen we write pixels to.
    screen: *Screen,

    // x is the number of pixels already output on the current scanline
    x: u8,

    highest_color: u8 = 0,

    fetcher: Fetcher = undefined,

    pub fn init(screen: *Screen) !PPU {
        return PPU{
            .ly = 0,
            .ticks = 0,
            .scan_line_counter = 0,
            .state = ppu_state.oam_scan,
            .screen = screen,
            .x = 0,
        };
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

    // Check the LCD Control Register ( LCDC : $FF40 )
    // When this register is Bit 7, the LCD display is enabled.
    fn is_lcd_enabled(self: *PPU) bool {
        return bits.is_set(self.LCDC, 7);
    }

    // Check and set the LCD status
    // The LCD is controlled by the programmer, not the cpu. Thus, it is reset here.
    // FIXME: PPU needs to be aware of memory.
    fn set_lcd_status(self: *PPU) void {
        if (!self.is_lcd_enabled()) {
            // LCD is off. FIXME: Do the reset of the PPU here as well
            // clear screen
            // reset scanline
            // reset bits, etc. to review
            self.scan_line_counter = 456;

            // Reset the LCD
            var status: u8 = 0;
            status = bits.clear(self.LCDC, 0);
            status = bits.clear(self.LCDC, 1);
        }
    }

    // tick updates the graphic state
    pub fn tick(self: *PPU) void {
        self.set_lcd_status();

        // FIXME: How do we enable the LCD? Seems to come from the bootrom,
        // somehow. Figure out when address 0xf44 is written to
        //if (!self.is_lcd_enabled()) {
        //    return;
        //}

        self.ticks += 1;

        switch (self.state) {
            // In OAM search, PPU scans the OAM (Objects Attribute Memory) from
            // 0xFE00 to 0xFE9F to mix sprite pixels in the current line later.
            // This always takes 40 clock ticks.
            ppu_state.oam_scan => {
                //print("ppu_state: oam_scan", .{});
                if (self.ticks == 40) {
                    // Initialize pixel transfer state
                    self.x = 0;
                    var tile_line = self.ly % 8;
                    var tilemap_row_addr = 0x9800 + (@as(u16, self.ly / 8) * 32);

                    self.fetcher.start(tilemap_row_addr, tile_line);

                    self.state = ppu_state.pixel_transfer;
                }
            },
            ppu_state.pixel_transfer => {
                //print("ppu_state: pixel_transfer", .{});
                // Fetch pixel data into our pixel FIFO
                self.fetcher.tick();

                // Stop if the FIFO is not holding at least 8 pixels.
                if (self.fetcher.fifo.length() <= 8) {
                    return;
                }

                // Put a pixel from the FIFO on screen if we have any.
                var pixel_color = self.fetcher.fifo.pop() catch |err| {
                    print("PPU: Error while popping pixel from FIFO: {!}\n", .{err});
                    @panic("unexpected fifo pop error");
                };

                var palette_color = (self.BGP >> @truncate(u3, (@intCast(usize, pixel_color) * 2))) & 3;

                var color: u8 = 0x00000000;
                switch (palette_color) {
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

                self.screen.write(color);

                // Check if the scanline is complete.
                self.x += 1;
                if (self.x == width) {
                    // Blank slate
                    self.screen.hblank();
                    self.state = ppu_state.hblank;
                }
            },
            ppu_state.hblank => {
                //print("hblank", .{});
                // TODO: wait, then go back to sprite search for next line, or
                // vblank
                if (self.ticks == 456) {
                    self.ticks = 0;
                    self.ly += 1;
                    if (self.ly == height) {
                        self.screen.vblank();
                        self.state = ppu_state.vblank;
                    } else {
                        self.state = ppu_state.oam_scan;
                    }
                }
            },
            ppu_state.vblank => {
                //print("vblank", .{});
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
