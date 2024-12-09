const std = @import("std");

const print = std.debug.print;
const panic = std.debug.panic;
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
    std.debug.print("Operation: 0x{x}\n", .{opcode});
    switch (opcode) {
        0x0 => {
            return .{
                .label = "NOP",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = noop,
            };
        },
        0xaa => {
            return .{
                .label = "XOR A,D",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = xorAD,
            };
        },
        0x22 => {
            return .{
                .label = "LD (HL+),A",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .step = ldiHLA,
            };
        },
        0x31 => {
            return .{
                .label = "LD SP,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .step = ldSpu16,
            };
        },
        else => {
            panic("\n!! not implemented 0x{x}\n", .{opcode});
        },
    }
}

fn noop(cpu: *c.SM83) void {
    _ = cpu;
}

fn xorAD(cpu: *c.SM83) void {
    const a1: u8 = cpu.registers.af.hi();
    const a2: u8 = cpu.registers.de.hi();

    std.debug.print("XOR A,D: {d} ^ {d}\n", .{ a1, a2 });
    const v: u8 = a1 ^ a2;
    cpu.registers.af.setHi(v);

    // Set flags
    cpu.setZero(v == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(false);
}

// LD SP,16
fn ldSpu16(cpu: *c.SM83) void {
    _ = cpu; // cpu.sp = cpu.popPC16();
}

// LD (HL+),A
fn ldiHLA(cpu: *c.SM83) void {
    const v = cpu.registers.hl.hilo();
    cpu.memory.write(v, cpu.registers.af.hi()); // memory[hl] = a
    cpu.registers.hl.set(v + 1);
}
