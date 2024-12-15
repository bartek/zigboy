const std = @import("std");

const print = std.debug.print;
const panic = std.debug.panic;
const assert = std.debug.assert;

const c = @import("./cpu.zig");

// Step is the actual execution of the Opcode
pub const Step = *const fn (cpu: *c.SM83) void;

// Opcode is an instruction for the CPU
pub const Opcode = struct {
    label: []const u8, // e.g. "XOR A,A"
    length: u8,
    cycles: u8, // clock cycles

    // Step is the operation for the opcode
    step: Step,
};

pub fn operation(_: *c.SM83, opcode: u16) Opcode {
    std.debug.print("Operation: 0x{x}\n", .{opcode});
    switch (opcode) {
        0x0 => {
            return .{
                .label = "NOP",
                .length = 1,
                .cycles = 4,
                .step = noop,
            };
        },
        0x01 => {
            return .{
                .label = "LD BC,u16",
                .length = 3,
                .cycles = 12,
                .step = ldRegu16(struct {
                    pub fn setBC(cpu: *c.SM83, value: u16) void {
                        cpu.registers.bc.set(value);
                    }
                }.setBC),
            };
        },
        0x02 => {
            return .{
                .label = "LD (BC),A",
                .length = 1,
                .cycles = 8,
                .step = ldBCA,
            };
        },
        0x06 => {
            return .{
                .label = "LD B,u8",
                .length = 2,
                .cycles = 8,
                .step = ldRegu8(struct {
                    pub fn setB(cpu: *c.SM83, value: u8) void {
                        cpu.registers.bc.setHi(value);
                    }
                }.setB),
            };
        },
        0xaa => {
            return .{
                .label = "XOR A,D",
                .length = 1,
                .cycles = 4,
                .step = xorAD,
            };
        },
        0x10 => {
            return .{
                .label = "STOP",
                .length = 1,
                .cycles = 4,
                .step = stop,
            };
        },
        0x22 => {
            return .{
                .label = "LD (HL+),A",
                .length = 3,
                .cycles = 12,
                .step = ldiHLA,
            };
        },
        0x31 => {
            return .{
                .label = "LD SP,u16",
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

// LD <reg>,u8
fn ldRegu8(comptime setter: *const fn (*c.SM83, u8) void) fn (*c.SM83) void {
    return struct {
        pub fn load(cpu: *c.SM83) void {
            setter(cpu, cpu.popPC());
        }
    }.load;
}

// LD <reg>,u16
fn ldRegu16(comptime setter: *const fn (*c.SM83, u16) void) fn (*c.SM83) void {
    return struct {
        pub fn load(cpu: *c.SM83) void {
            setter(cpu, cpu.popPC16());
        }
    }.load;
}

// LD (<reg2:u16>),<reg1:u8>
// Load <reg1:u8> into memory address <reg2:u16>
fn ldRegMem(comptime setter: *const fn (*c.SM83, u8, u16) void) fn (*c.SM83) void {
    return struct {
        pub fn load(cpu: *c.SM83) void {
            setter(cpu, cpu.registers.af.hi(), cpu.registers.hl.hilo());
        }
    }.load;
}

// LD (BC),A
fn ldBCA(cpu: *c.SM83) void {
    cpu.memory.write(cpu.registers.bc.hilo(), cpu.registers.af.hi());
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

// STOP
fn stop(cpu: *c.SM83) void {
    // TODO: gbops says this has changed in understanding since Oct 30 2021
    // Prior to October 30th, 2021, STOP was referenced as being two bytes
    // long, however, it is one byte. There is a potentially confusing fact in
    // that STOP skips one byte after itself. However, it doesn't care what
    // byte comes after it.
    //
    // Pop the next value as the STOP instruction is two bytes long.
    const s = cpu.popPC();
    std.debug.print("{x}", .{s});

    //// If the next instruction is not 0x00 this is likely a corrupted
    //// instruction.
    //assert(s == 0x00);
}
