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
        };

        for (config.ram) |ram| {
            const value: u8 = @truncate(ram[1]);
            std.debug.print("Writing to memory: {d}={d}\n", .{ ram[0], value });
            cpu.memory.write(ram[0], value);
        }

        return cpu;
    }

    // tick ticks the CPU
    pub fn tick(self: *SM83) instructions.Opcode {
        const opcode = self.memory.read(self.pc);
        std.debug.print("Tick with PC={}: 0x{x}\n", .{ self.pc, opcode });
        const instruction = instructions.operation(self, opcode);
        std.debug.print("Instruction: {s}={}\n", .{ instruction.label, instruction });
        self.execute(instruction);
        self.pc +%= 1;
        return instruction;
    }

    // execute accepts an Opcode struct and executes the packed instruction
    // https://izik1.github.io/gbops/index.html
    pub fn execute(self: *SM83, opcode: instructions.Opcode) void {
        opcode.step(self);
    }

    // popPC16 reads two bytes from memory and increments PC twice
    //pub fn popPC16(self: *SM83) u16 {
    //    const b1: u16 = self.popPC();
    //    const b2: u16 = self.popPC();
    //    return b1 | (b2 << 8);
    //}

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
        return self.af.hilo() >> 7 & 1 == 1;
    }

    // Carry Flag. Used by conditional jumps and instructions such as ADC, SBC, RL, RLA, etc.
    pub fn carry(self: *SM83) bool {
        return self.af.hilo() >> 4 & 1 == 1;
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
