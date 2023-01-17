const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const boot = @import("./bootrom.zig");
const PPU = @import("./ppu.zig").PPU;
const Cart = @import("./cart.zig").Cart;

pub const Memory = struct {
    const Self = @This();

    // Game Boy contains an 8-bit processor, meaning it can access 8-bits of data
    // at one time. To access this data, it has a 16-bit address bus, which can
    // address 65,536 positions of memory.
    const memory_size = 65536;

    cart: Cart,
    allocator: Allocator,
    memory: []u8,

    boot_rom: [256]u8,
    boot_rom_enabled: bool,

    ppu: *PPU,

    pub fn init(allocator: Allocator, ppu: *PPU) !Self {
        var m = Self{
            .allocator = allocator,
            .memory = try allocator.alloc(u8, memory_size),
            .cart = try Cart.init(allocator),
            .boot_rom = boot.rom,
            .boot_rom_enabled = true,

            .ppu = ppu,
        };

        m.memory[0x04] = 0x1e;
        m.memory[0x05] = 0x00;
        m.memory[0x06] = 0x00;
        m.memory[0x07] = 0xf8;
        m.memory[0x0f] = 0xe1;
        m.memory[0x10] = 0x80;
        m.memory[0x11] = 0xbf;
        m.memory[0x12] = 0xf3;
        m.memory[0x14] = 0xbf;
        m.memory[0x16] = 0x3f;
        m.memory[0x17] = 0x00;
        m.memory[0x19] = 0xbf;
        m.memory[0x1a] = 0x7f;
        m.memory[0x1b] = 0xff;
        m.memory[0x1c] = 0x9f;
        m.memory[0x1e] = 0xbf;
        m.memory[0x20] = 0xff;
        m.memory[0x21] = 0x00;
        m.memory[0x22] = 0x00;
        m.memory[0x23] = 0xbf;
        m.memory[0x24] = 0x77;
        m.memory[0x25] = 0xf3;
        m.memory[0x26] = 0xf1;
        m.memory[0x40] = 0x91;
        m.memory[0x41] = 0x85;
        m.memory[0x42] = 0x00;
        m.memory[0x43] = 0x00;
        m.memory[0x45] = 0x00;
        m.memory[0x47] = 0xfc;
        m.memory[0x48] = 0xff;
        m.memory[0x49] = 0xff;
        m.memory[0x4a] = 0x00;
        m.memory[0x4b] = 0x00;

        return m;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }

    pub fn read(self: *Self, address: u16) u8 {
        if (address < 0x100) {
            return self.boot_rom[address];
        }

        if (address < 0x8000) {
            return self.cart.read(address);
        }

        switch (address) {
            0xff40 => {
                return self.ppu.read(address);
            },
            0xff44 => {
                return self.ppu.read(address);
            },
            0xff47 => {
                return self.ppu.read(address);
            },
            else => {
                return self.memory[address];
            },
        }
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        std.debug.print("write: {x} {x}\n", .{ address, value });
        switch (address) {
            0xff01 => { // Serial port
                print("{c}", .{value});
            },
            // Register used to unmap bootrom. Not used by regular games
            0xff50 => {
                if (value == 1) {
                    self.boot_rom_enabled = false;
                }
            },
            0xff40 => {
                self.ppu.write(address, value);
            },
            0xff44 => {
                // LY is read-only
            },
            0xff47 => {
                self.ppu.write(address, value);
            },
            else => {
                self.memory[address] = value;
            },
        }
    }

    // loadRom loads a buffer into memory
    pub fn loadRom(self: *Self, buffer: []u8) !void {
        return self.cart.load(buffer);
    }
};
