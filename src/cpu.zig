const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const instructions = @import("./instructions.zig");
const memory = @import("./memory.zig");
const flipBit = @import("./functions.zig").flipBit;

// register is a "virtual" 16-bit register which joins two 8-bit registers
// together. If the register was AF, A would be the Hi byte and F the Lo.
pub const register = struct {
    value: u16,

    pub fn init(value: u8) register {
        return register{
            .value = value,
        };
    }

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
            .af = register.init(0x00),
            .bc = register.init(0x00),
            .de = register.init(0x00),
            .hl = register.init(0x00),
            .pc = 0x00,
            .sp = 0x00,
        };
    }

    pub fn deinit(self: *CPU) void {
        self.memory.deinit();
    }

    // debug prints debug information
    // Matches format at https://github.com/wheremyfoodat/Gameboy-logs
    // to allow for programmatic comparison.
    pub fn debug(self: *CPU) void {
        var mem: u8 = self.memory.read(self.pc);
        var mem1: u8 = self.memory.read(self.pc + 1);
        var mem2: u8 = self.memory.read(self.pc + 2);
        var mem3: u8 = self.memory.read(self.pc + 3);

        print("A: {X:0>2} " ++
            "F: {X:0>2} " ++
            "B: {X:0>2} " ++
            "C: {X:0>2} " ++
            "D: {X:0>2} " ++
            "E: {X:0>2} " ++
            "H: {X:0>2} " ++
            "L: {X:0>2} " ++
            "SP: {X:0>4} " ++
            "PC: 00:{X:0>4} " ++
            "({X:0>2} {X:0>2} {X:0>2} {X:0>2}) ", .{ self.af.hi(), self.af.lo(), self.bc.hi(), self.bc.lo(), self.de.hi(), self.de.lo(), self.hl.hi(), self.hl.lo(), self.sp, self.pc, mem, mem1, mem2, mem3 });
    }

    // tick ticks the CPU
    pub fn tick(self: *CPU) void {
        self.debug();
        var opcode = self.popPC();
        var instruction = instructions.operation(self, opcode);
        self.execute(instruction);
    }

    // popPC reads a single byte from memory and increments PC
    pub fn popPC(self: *CPU) u8 {
        var opcode: u8 = self.memory.read(self.pc);
        self.pc +%= 1;
        return opcode;
    }

    // popPC16 reads two bytes from memory and increments PC twice
    pub fn popPC16(self: *CPU) u16 {
        var b1: u16 = self.popPC();
        var b2: u16 = self.popPC();
        return b1 | (b2 << 8);
    }


    // pushStack pushes two bytes onto the stack and decrements stack pointer
    // twice
    pub fn pushStack(self: *CPU, value: u16) void {
        self.memory.write(self.sp-1, @intCast(u8, (value & 0xff00) >> 8));
        self.memory.write(self.sp-2, @intCast(u8, (value & 0xff)));
        self.sp -= 2;
    }

    // popStack pops the next 16 bit value off the stack and increments SP
    pub fn popStack(self: *CPU) u16 {
        var b1: u16 = self.memory.read(self.sp);
        var b2: u16 = self.memory.read(self.sp + 1);
        self.sp += 2;

        return b1 | (b2 << 8);
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
            self.af.setLo(self.af.lo() & flipBit(1 << index));
        }
    }

    // Zero Flag. Set when the result of a mathemetical instruction is zero
    pub fn zero(self: *CPU) bool {
        return self.af.hilo() >> 7 & 1 == 1;
    }

    // Carry Flag. Used by conditional jumps and instructions such as ADC, SBC, RL, RLA, etc.
    pub fn carry(self: *CPU) bool {
        return self.af.hilo() >> 4 & 1 == 1;
    }

    // setZ sets the zero flag
    pub fn setZero(self: *CPU, on: bool) void {
        self.setFlag(7, on);
    }

    // setN sets the negative flag
    pub fn setNegative(self: *CPU, on: bool) void {
        self.setFlag(6, on);
    }

    // setH sets the half carry flag
    pub fn setHalfCarry(self: *CPU, on: bool) void {
        self.setFlag(5, on);
    }

    // setC sets the carry flag
    pub fn setCarry(self: *CPU, on: bool) void {
        self.setFlag(4, on);
    }
};
