const Allocator = std.mem.Allocator;
const fmt = std.fmt;
const std = @import("std");

const instructions = @import("./instructions.zig");
const Opcode = instructions.Opcode;
const Memory = @import("./memory.zig").Memory;
const flipBit = @import("./functions.zig").flipBit;
const bits = @import("./bits.zig");

fn pause() ![]const u8 {
    const stdin = std.io.getStdIn().reader();

    var buf: [10]u8 = undefined;

    const line = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
    return line orelse "";
}

// register is a "virtual" 16-bit register which joins two 8-bit registers
// together. If the register was AF, A would be the Hi byte and F the Lo.
pub const register = struct {
    value: u16,

    // mask is a possible value in the register, only used for AF register
    // where the lower bits of F cannot be set.
    mask: u16,

    pub fn init(value: u16) register {
        return register{
            .value = value,
            .mask = 0x00,
        };
    }

    fn updateMask(self: *register) void {
        if (self.mask != 0) {
            self.value &= self.mask;
        }
    }

    pub fn set(self: *register, value: u16) void {
        self.value = value;
        self.updateMask();
    }

    pub fn setLo(self: *register, value: u8) void {
        self.value = @as(u16, value) | (@as(u16, self.value) & 0xFF00);
        self.updateMask();
    }

    pub fn setHi(self: *register, value: u8) void {
        self.value = @as(u16, value) << 8 | (@as(u16, self.value) & 0xFF);
        self.updateMask();
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
    const Self = @This();
    const debug = false;

    af: register,
    bc: register,
    de: register,
    hl: register,

    // Program Counter
    pc: u16,

    // Stack Pointer
    sp: u16,

    memory: *Memory,

    interruptsEnabled: bool,

    pub fn init(memory: *Memory) !Self {
        var af = register.init(0x01b0);
        af.mask = 0xFFF0;

        // Initial values defined by https://gbdev.io/pandocs/Power_Up_Sequence.html#cpu-registers
        var c = Self{
            .memory = memory,
            .af = af,
            .bc = register.init(0x0013),
            .de = register.init(0x00D8),
            .hl = register.init(0x014d),
            .pc = 0x0100,
            .sp = 0xfffe,
            .interruptsEnabled = false,
        };

        c.setZero(true);
        c.setNegative(false);

        return c;
    }

    pub fn deinit(self: *Self) void {
        self.memory.deinit();
    }

    // tick ticks the CPU
    pub fn tick(self: *Self) Opcode {
        if (debug) {
            var mem: u8 = self.memory.read(self.pc);
            var mem1: u8 = self.memory.read(self.pc + 1);
            var mem2: u8 = self.memory.read(self.pc + 2);
            var mem3: u8 = self.memory.read(self.pc + 3);
            std.debug.print("A: {X:0>2} " ++
                "F: {X:0>2} " ++
                "B: {X:0>2} " ++
                "C: {X:0>2} " ++
                "D: {X:0>2} " ++
                "E: {X:0>2} " ++
                "H: {X:0>2} " ++
                "L: {X:0>2} " ++
                "SP: {X:0>4} " ++
                "PC: 00:{X:0>4} " ++
                "({X:0>2} {X:0>2} {X:0>2} {X:0>2})\n", .{ self.af.hi(), self.af.lo(), self.bc.hi(), self.bc.lo(), self.de.hi(), self.de.lo(), self.hl.hi(), self.hl.lo(), self.sp, self.pc, mem, mem1, mem2, mem3 });
        }

        //var line = pause() catch |err| {
        //    std.debug.print("Error: {}\n", .{err});
        //    return Opcode{
        //        .label = "NOP",
        //        .value = 0x0,
        //        .length = 1,
        //        .cycles = 4,
        //        .steps = undefined,
        //    };
        //};
        //std.debug.print("{s}", .{line});

        var opcode = self.popPC();
        var instruction = instructions.operation(self, opcode);

        self.execute(instruction);
        return instruction;
    }

    // popPC reads a single byte from memory and increments PC
    pub fn popPC(self: *Self) u8 {
        var opcode: u8 = self.memory.read(self.pc);
        self.pc +%= 1;
        return opcode;
    }

    // popPC16 reads two bytes from memory and increments PC twice
    pub fn popPC16(self: *Self) u16 {
        var b1: u16 = self.popPC();
        var b2: u16 = self.popPC();
        return b1 | (b2 << 8);
    }

    // pushStack pushes two bytes onto the stack and decrements stack pointer
    // twice
    pub fn pushStack(self: *Self, value: u16) void {
        self.memory.write(self.sp - 1, @intCast(u8, (value & 0xff00) >> 8));
        self.memory.write(self.sp - 2, @intCast(u8, (value & 0xff)));
        self.sp -= 2;
    }

    // popStack pops the next 16 bit value off the stack and increments SP
    pub fn popStack(self: *Self) u16 {
        var b1: u16 = self.memory.read(self.sp);
        var b2: u16 = self.memory.read(self.sp + 1);
        self.sp +%= 2;

        return b1 | (b2 << 8);
    }

    // execute accepts an Opcode struct and executes the packed instruction
    // https://izik1.github.io/gbops/index.html
    pub fn execute(self: *Self, opcode: instructions.Opcode) void {
        opcode.step(self);
    }

    // The F register is a special register because it contains the values of 4
    // flags which allow the CPU to track particular states:
    pub fn setFlag(self: *Self, comptime bit: u8, on: bool) void {
        if (on) {
            self.af.setLo(bits.set(self.af.lo(), bit));
        } else {
            self.af.setLo(bits.clear(self.af.lo(), bit));
        }
    }

    // Zero Flag. Set when the result of a mathemetical instruction is zero
    pub fn zero(self: *Self) bool {
        return self.af.hilo() >> 7 & 1 == 1;
    }

    // Carry Flag. Used by conditional jumps and instructions such as ADC, SBC, RL, RLA, etc.
    pub fn carry(self: *Self) bool {
        return self.af.hilo() >> 4 & 1 == 1;
    }

    // setZ sets the zero flag
    pub fn setZero(self: *Self, on: bool) void {
        self.setFlag(7, on);
    }

    // setN sets the negative flag
    pub fn setNegative(self: *Self, on: bool) void {
        self.setFlag(6, on);
    }

    // setH sets the half carry flag
    pub fn setHalfCarry(self: *Self, on: bool) void {
        self.setFlag(5, on);
    }

    // setC sets the carry flag
    pub fn setCarry(self: *Self, on: bool) void {
        self.setFlag(4, on);
    }
};
