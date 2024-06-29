const std = @import("std");

const instructions = @import("./instructions.zig");
const Memory = @import("./memory.zig").Memory;

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

    fn updateMask(self: *register) void {
        if (self.mask != 0) {
            self.value &= self.mask;
        }
    }
};

// SM83 is the CPU for the GameBoy
// It is composed of 8 different registers, each of which is a pair of 8-bit
// registers. These registers are manipulated by the CPU when it executes
// instructions.
pub const SM83 = struct {
    af: register,
    bc: register,
    de: register,
    hl: register,

    // Program counter
    pc: u16,

    memory: *Memory,

    pub fn init(memory: *Memory) !SM83 {
        return SM83{
            .memory = memory,
            .af = register.init(0x01b0),
            .bc = register.init(0x0013),
            .de = register.init(0x00D8),
            .hl = register.init(0x014d),
            .pc = 0x0100,
        };
    }

    // tick ticks the CPU
    pub fn tick(self: *SM83) instructions.Opcode {
        const instruction = instructions.operation(self, self.popPC());
        self.execute(instruction);
        return instruction;
    }

    // execute accepts an Opcode struct and executes the packed instruction
    // https://izik1.github.io/gbops/index.html
    pub fn execute(self: *SM83, opcode: instructions.Opcode) void {
        opcode.step(self);
    }

    pub fn popPC(self: *SM83) u8 {
        const opcode: u8 = self.memory.read(self.pc);
        self.pc +%= 1;
        return opcode;
    }
};

test "register test" {}
