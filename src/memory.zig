const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const boot = @import("./bootrom.zig");

pub const Memory = struct {
    // Game Boy contains an 8-bit processor, meaning it can access 8-bits of data
    // at one time. To access this data, it has a 16-bit address bus, which can
    // address 65,536 positions of memory.
    const memory_size = 65536;

    allocator: Allocator,
    memory: []u8,

    boot_rom: [256]u8,
    boot_rom_enabled: bool,

    pub fn init(allocator: Allocator) !Memory {
        return Memory{
            .allocator = allocator,
            .memory = try allocator.alloc(u8, memory_size),
            .boot_rom = boot.rom,
            .boot_rom_enabled = true,
        };
    }

    pub fn deinit(self: *Memory) void {
        self.allocator.free(self.memory);
    }

    pub fn read(self: *Memory, address: u16) u8 {
        if (address < 0x100) {
            return self.boot_rom[address];
        } else {
            return self.memory[address];
        }
    }

    pub fn write(self: *Memory, address: u16, value: u8) void {

        switch(address) {
            // Register used to unmap bootrom. Not used by regular games
            0xff50 => {
                print("FIXME: NO MORE BOOTROM!", .{});
                if (value == 1) {
                    self.boot_rom_enabled = false;
                }
            },
            else => {
                self.memory[address] = value;
            },
        }
    }

    // loadRom loads a buffer into memory, starting at 0x100
    // as < 0x100 is reserved for the bootrom
    pub fn loadRom(self: *Memory, buffer: []u8) !void {
        for (buffer) |b, index| {
            self.write(@intCast(u16, index + 0x100), b);
        }
    }
};
