const std = @import("std");

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
pub const SM83 = struct {
    af: register,
    bc: register,
    de: register,
    hl: register,

    pub fn init() SM83 {
        return SM83{};
    }
};

test "register test" {}
