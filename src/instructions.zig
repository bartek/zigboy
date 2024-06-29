const std = @import("std");

const print = std.debug.print;
const c = @import("./cpu.zig");

// Step is the actual execution of the Opcode
pub const Step = *const fn (cpu: *c.SM83) void;

// Opcode is an instruction for the CPU
pub const Opcode = struct {
    label: []const u8, // e.g. "XOR A,A"
    value: u16, // e.g. 0x31
    length: u8,
    cycles: u8, // clock cycles

    step: Step,
};

pub fn operation(_: *c.SM83, opcode: u16) Opcode {
    var op: Opcode = .{
        .label = undefined,
        .value = undefined,
        .length = undefined,
        .cycles = undefined,
        .step = undefined,
    };

    switch (opcode) {
        0x0 => {
            op = .{
                .label = "NOP",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = noop,
            };
        },
        else => {
            print("not implemented 0x{x}\n", .{opcode});
        },
    }

    return op;
}

fn noop(cpu: *c.SM83) void {
    _ = cpu;
}
