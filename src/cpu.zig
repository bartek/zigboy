const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const instructions = @import("./instructions.zig");
const memory = @import("./memory.zig");

// register is a "virtual" 16-bit register which joins two 8-bit registers
// together. If the register was AF, A would be the Hi byte and F the Lo.
pub const register = struct {
    value: u16,

    pub fn set(self: *register, value: u16) void {
        self.value = value;
    }

    pub fn setLo(self: *register, value: u8) void {
        self.value = @intCast(u16, value) | (@intCast(u16, self.value) & 0xFF00);
    }

    pub fn setHi(self: *register, value: u8) void {
        self.value = @intCast(u16, value) << 8 | (@intCast(u16, self.value) & 0xFF);
    }

    pub fn hilo(self: *register) u16 {
        return self.value;
    }

    pub fn lo(self: *register) u8 {
        return @intCast(u8, self.value & 0xFF);
    }

    pub fn hi(self: *register) u8 {
        return @intCast(u8, self.value >> 8);
    }
};

// The Game Boy CPU is composed of 8 different registers which are responsible
// for holding onto little pieces of data that the CPU can manipulate when it
// executes various instructions. These registers are named A, B, C, D, E, F, H,
// and L. Since they are 8-bit registers, they can hold only 8-bit values.
// However, the Game Boy can combine two registers in order to read and write
// 16-bit values. The valid combinations then are AF, BC, DE, and HL.
pub const CPU = struct {
    af: register,
    bc: register,
    de: register,
    hl: register,

    // Program Counter
    pc: u16,

    // Stack Pointer
    sp: u16,

    memory: memory.Memory,

    pub fn init(allocator: *Allocator) !CPU {
        return CPU{
            .memory = try memory.Memory.init(allocator),
            .af = undefined,
            .bc = undefined,
            .de = undefined,
            .hl = undefined,
            .pc = 0x00,
            .sp = undefined,
        };
    }

    pub fn deinit(self: *CPU) void {
        self.memory.deinit();
    }

    // tick ticks the CPU
    pub fn tick(self: *CPU) void {
        var opcode = self.popPC();
        self.execute(instructions.operation(self, opcode));
    }

    // popPC reads a single byte from memory and increments PC
    pub fn popPC(self: *CPU) u16 {
        var opcode: u16 = self.memory.read(self.pc);
        self.pc += 1;
        return opcode;
    }

    pub fn popPC16(self: *CPU) u16 {
        var b1: u16 = self.popPC();
        var b2: u16 = self.popPC();
        return b2 << 8 | b1;
    }

    // execute accepts an Opcode struct and executes the packed instruction
    // https://izik1.github.io/gbops/index.html
    pub fn execute(self: *CPU, opcode: instructions.Opcode) void {
        for (opcode.steps) |step| {
            step(self);
        }
    }

    // The F register is a special register because it contains the values of 4
    // flags which allow the CPU to track particular states:
    pub fn setFlag(self: *CPU, comptime index: u8, on: bool) void {
        if (on) {
            self.af.setLo(self.af.lo() | (1 << index));
        } else {
            self.af.setLo(self.af.lo() ^ (1 << index));
        }
    }

    // Zero Flag. Set when the result of a mathemetical instruction is zero
    pub fn Z(self: *CPU) bool {
        return self.af.hilo() >> 7 & 1 == 1;
    }

    // setZ sets the zero flag
    pub fn setZ(self: *CPU, on: bool) void {
        self.setFlag(7, on);
    }

    // setN sets the negative flag
    pub fn setN(self: *CPU, on: bool) void {
        self.setFlag(6, on);
    }

    // setH sets the half carry flag
    pub fn setH(self: *CPU, on: bool) void {
        self.setFlag(5, on);
    }

    // setC sets the carry flag
    pub fn setC(self: *CPU, on: bool) void {
        self.setFlag(4, on);
    }
};
