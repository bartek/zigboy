const std = @import("std");
const testing = std.testing;

const Memory = @import("./memory.zig").Memory;
const bits = @import("./bits.zig");
const instructions = @import("./instructions.zig");

// register is a virtual 16-bit register which joints two 8-bit registers
// together. IF the register was AF, A would be the hi byte and F the lo.
pub const register = struct {
    value: u16,

    // mask is a possivle value in the register, only used for AF where the
    // lower bits of F cannot be set.
    mask: u16,

    pub fn init(value: u16) register {
        return register{
            .value = value,
            .mask = 0x00,
        };
    }

    pub fn set(self: *register, value: u16) void {
        self.value = value;
        self.updateMask();
    }

    pub fn get(self: *register) u16 {
        return self.value;
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
        return @intCast(self.value & 0xFF);
    }

    pub fn hi(self: *register) u8 {
        return @intCast(self.value >> 8);
    }

    fn updateMask(self: *register) void {
        if (self.mask != 0) {
            self.value &= self.mask;
        }
    }
};

pub const Registers = struct {
    af: register,
    bc: register,
    de: register,
    hl: register,

    pub const Config = struct {
        af: register = register.init(0x00),
        bc: register = register.init(0x00),
        de: register = register.init(0x00),
        hl: register = register.init(0x00),
    };

    pub fn init(config: Config) Registers {
        return Registers{
            .af = config.af,
            .bc = config.bc,
            .de = config.de,
            .hl = config.hl,
        };
    }
};

test "Registers" {
    var registers: Registers = undefined;

    registers.af = register.init(0xFF11);
    try testing.expectEqual(registers.af.hi(), 0xFF);
    try testing.expectEqual(registers.af.lo(), 0x11);
    registers.af.setHi(0x11);
    registers.af.setLo(0x55);
    try testing.expectEqual(registers.af.hi(), 0x11);
    try testing.expectEqual(registers.af.lo(), 0x55);
}

// SM83 is the CPU for the GameBoy
// It is composed of 8 different registers, each of which is a pair of 8-bit
// registers. These registers are manipulated by the CPU when it executes
// instructions.
pub const SM83 = struct {
    registers: Registers,

    // Program counter
    pc: u16,

    // Stack Pointer
    sp: u16,

    memory: Memory,

    interrupts: bool,

    pub const Config = struct {
        registers: Registers,
        pc: u16 = 0x0,
        sp: u16 = 0x0,
        ram: [][]u16,
    };

    // init initializes the CPU
    pub fn init(allocator: std.mem.Allocator, config: Config) !SM83 {
        var cpu = SM83{
            .memory = try Memory.init(allocator),
            .registers = config.registers,
            .pc = config.pc,
            .sp = config.sp,
            .interrupts = false,
        };

        for (config.ram) |ram| {
            const value: u8 = @truncate(ram[1]);
            std.debug.print("Initializing memory: 0x{x}={d}\n", .{ ram[0], value });
            cpu.memory.write(ram[0], value);
        }

        return cpu;
    }

    // tick ticks the CPU
    // https://izik1.github.io/gbops/index.html
    pub fn tick(self: *SM83) void {
        std.debug.print("Tick with PC={}\n", .{self.pc});

        const opcode: u8 = self.memory.read(self.pc);

        const arg_type = instructions.OP_TYPES[opcode];
        const arg_len = instructions.OP_ARG_BYTES[arg_type];

        // Jump instructions must be set prior to incrementing PC
        const jump_arg = instructions.jump_op(self, self.pc +% 1, arg_type);
        self.pc +%= 1 + arg_len;

        // TODO: Read OP_CYCLES
        instructions.operation(self, opcode, jump_arg);
    }

    pub fn getRegister(self: *SM83, n: u16) u8 {
        return switch (@as(u3, @intCast(n & 0x07))) {
            0 => self.registers.bc.hi(),
            1 => self.registers.bc.lo(),
            2 => self.registers.de.hi(),
            3 => self.registers.de.lo(),
            4 => self.registers.hl.hi(),
            5 => self.registers.hl.lo(),
            6 => self.memory.read(self.registers.hl.hilo()),
            7 => self.registers.af.hi(),
        };
    }

    pub fn setRegister(self: *SM83, n: u8, value: u8) void {
        switch (@as(u3, @intCast(n & 0x07))) {
            0 => self.registers.bc.setHi(value),
            1 => self.registers.bc.setLo(value),
            2 => self.registers.de.setHi(value),
            3 => self.registers.de.setLo(value),
            4 => self.registers.hl.setHi(value),
            5 => self.registers.hl.setLo(value),
            6 => self.memory.write(self.registers.hl.hilo(), value),
            7 => self.registers.af.setHi(value),
        }
    }
    // pushStack pushes two bytes onto the stack and decrements stack pointer
    // twice
    pub fn pushStack(self: *SM83, value: u16) void {
        self.memory.write(self.sp - 1, @truncate(value >> 8)); // High byte
        self.memory.write(self.sp - 2, @truncate(value & 0xFF)); // Low byte
        self.sp -= 2;
    }

    pub fn pop(self: *SM83) u16 {
        const v = (@as(u16, self.memory.read(self.sp + 1)) << 8) | @as(u16, self.memory.read(self.sp));
        self.sp += 2;
        return v;
    }

    // The F register is a special register because it contains the values of 4
    // flags which allow the CPU to track particular states:
    pub fn setFlag(self: *SM83, comptime bit: u8, on: bool) void {
        if (on) {
            self.registers.af.setLo(bits.set(self.registers.af.lo(), bit));
        } else {
            self.registers.af.setLo(bits.clear(self.registers.af.lo(), bit));
        }
    }

    // Zero Flag. Set when the result of a mathemetical instruction is zero
    pub fn zero(self: *SM83) bool {
        return self.registers.af.hilo() >> 7 & 1 == 1;
    }

    // Carry Flag. Used by conditional jumps and instructions such as ADC, SBC, RL, RLA, etc.
    pub fn carry(self: *SM83) bool {
        return self.registers.af.hilo() >> 4 & 1 == 1;
    }

    // Half Carry Flag. Used for BCD arithmetic
    pub fn halfCarry(self: *SM83) bool {
        return self.registers.af.hilo() >> 5 & 1 == 1;
    }

    pub fn negative(self: *SM83) bool {
        return self.registers.af.hilo() >> 6 & 1 == 1;
    }

    // setZ sets the zero flag
    pub fn setZero(self: *SM83, on: bool) void {
        self.setFlag(7, on);
    }

    // setN sets the negative flag
    pub fn setNegative(self: *SM83, on: bool) void {
        self.setFlag(6, on);
    }

    // setH sets the half carry flag
    pub fn setHalfCarry(self: *SM83, on: bool) void {
        self.setFlag(5, on);
    }

    // setC sets the carry flag
    pub fn setCarry(self: *SM83, on: bool) void {
        self.setFlag(4, on);
    }

    pub fn deinit(self: *SM83) void {
        self.memory.deinit();
    }
};

// add_and_set_flags performs an add instruction on the input values, storing them using the set
// function. Also updates flags accordingly
fn add_and_set_flags(cpu: *SM83, v1: u8, v2: u8) u8 {
    const total: u8 = v1 +% v2;

    cpu.setZero(total == 0);
    cpu.setHalfCarry((v1 & 0x0F) + (v2 & 0x0F) > 0x0F);
    cpu.setCarry(total > 0xFF); // If result is greater than 255

    return total;
}
