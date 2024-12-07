const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Cart = struct {
    const Self = @This();

    // Game Boy contains an 8-bit processor, meaning it can access 8-bits of data
    // at one time. To access this data, it has a 16-bit address bus, which can
    // address 65,536 positions of memory.
    const memory_size = 65536;

    memory: []u8,

    pub fn init(memory: []u8) !Self {
        return Self{
            .memory = memory,
        };
    }

    pub fn load(self: *Self, buffer: []u8) !void {
        for (buffer, 0..) |b, index| {
            self.memory[index] = b;
        }
    }

    pub fn read(self: *Self, address: u16) u8 {
        return self.memory[address];
    }
};
