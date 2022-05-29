const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const boot = @import("./bootrom.zig");
const PPU = @import("./ppu.zig").PPU;

pub const Memory = struct {
    const Self = @This();

    // Game Boy contains an 8-bit processor, meaning it can access 8-bits of data
    // at one time. To access this data, it has a 16-bit address bus, which can
    // address 65,536 positions of memory.
    const memory_size = 65536;

    allocator: Allocator,
    memory: []u8,

    boot_rom: [256]u8,
    boot_rom_enabled: bool,

    ppu: *PPU,

    pub fn init(allocator: Allocator, ppu: *PPU) !Self {
        return Self{
            .allocator = allocator,
            .memory = try allocator.alloc(u8, memory_size),
            .boot_rom = boot.rom,
            .boot_rom_enabled = true,

            .ppu = ppu,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }

    pub fn read(self: *Self, address: u16) u8 {
        if (address < 0x100) {
            return self.boot_rom[address];
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
        switch (address) {
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
        for (buffer) |b, index| {
            self.write(@intCast(u16, index), b);
        }
    }
};
