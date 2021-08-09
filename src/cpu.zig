const std = @import("std");
const Allocator = std.mem.Allocator;

const register = struct {
    value: uint16,

    pub fn setLo(self: *register, value: u8) void {
        self.value = u16(value) | u16(self.value)&0xFF00;
    }

    pub fn setHi(self: *register, value: u8) void {
        self.value = u16(val)<<8 | (u16(self.value) & 0xFF);
    }
};

// The Game Boy CPU is composed of 8 different registers which are responsible
// for holding onto little pieces of data that the CPU can manipulate when it
// executes various instructions. These registers are named A, B, C, D, E, F, H,
// and L. Since they are 8-bit registers, they can hold only 8-bit values.
// However, the Game Boy can combine two registers in order to read and write
// 16-bit values. The valid combinations then are AF, BC, DE, and HL.
pub const CPU = struct {
    allocator: *Allocator,

    af: register,
    bc: register,
    de: register,
    hl: register,

    // Program Counter
    pc: u16,

    // Stack Pointer
    sp: u16,

    pub fn init(allocator: *Allocator) !CPU {
        return CPU{
        };
    }
};
