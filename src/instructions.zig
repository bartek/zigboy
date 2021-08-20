const std = @import("std");
const print = std.debug.print;

const c = @import("./cpu.zig");

// Step is single step within an Opcode
pub const Step = fn (cpu: *c.CPU) void;

// Opcode is an instruction for the CPU
pub const Opcode = struct {
    label: []const u8, // e.g. "XOR A,A"
    value: u16, // e.g. 0x31
    length: u8,
    cycles: u8, // clock cycles

    // Zig note: The usage of .steps in initializing the Opcode looks like so:
    // .steps = &[_]Step{
    //     ldSpu16,
    // }
    // This is implicitly a constant, and thus, we have to give the compiler a
    // hint that this is expected, hence the `const` in this definition.
    // Alternatively, the steps could be explicitly defined as a non-constant
    // (var steps = [_]Step{...}, but it feels syntactically more enjoyable to
    // do it this way.
    steps: []const Step,
};

pub fn operation(cpu: *c.CPU, opcode: u16) Opcode {
    var op: Opcode = .{
        .label = undefined,
        .value = opcode, // This is repeated. Not sure why Zig doesn't allow it to be omitted in the subsequent usage.
        .length = undefined,
        .cycles = undefined,
        .steps = undefined,
    };

    switch (opcode) {
        0x0 => {
            op = .{
                .label = "NOP",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{},
            };
        },
        0x11 => {
            op = .{
                .label = "LD DE,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .steps = &[_]Step{
                    ldDeu16,
                },
            };
        },
        0x20 => {
            op = .{
                .label = "JR NZ,u8",
                .value = opcode,
                .length = 2,
                .cycles = 12, // FIXME: with/without branch timing to review
                .steps = &[_]Step{
                    jrNz8,
                },
            };
        },
        0x31 => {
            op = .{
                .label = "LD SP,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .steps = &[_]Step{
                    ldSpu16,
                },
            };
        },
        0xc3 => {
            op = .{
                .label = "JP u16",
                .value = opcode,
                .length = 3,
                .cycles = 16,
                .steps = &[_]Step{
                    jpu16,
                },
            };
        },
        0x21 => {
            op = .{
                .label = "LD HL,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .steps = &[_]Step{
                    ldHlu16,
                },
            };
        },
        0x03 => {
            op = .{
                .label = "INC BC",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    incBc,
                },
            };
        },
        0x32 => {
            op = .{
                .label = "LD (HL-),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldHlA,
                },
            };
        },
        0xaf => {
            op = .{
                .label = "XOR A,A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    xorAA,
                },
            };
        },

        0x73 => {
            op = .{
                .label = "LD (HL),E",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldHlE,
                },
            };
        },
        0x8 => {
            op = .{
                .label = "ADD A,B",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    addAB,
                },
            };
        },

        0x83 => {
            op = .{
                .label = "ADD A,E",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    addAE,
                },
            };
        },
        0x89 => {
            op = .{
                .label = "ADD A,C",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    addAC,
                },
            };
        },
        0xc => {
            op = .{
                .label = "RET NZ",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    retNz,
                },
            };
        },
        0xd => {
            op = .{
                .label = "RET NC",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    retNc,
                },
            };
        },

        // -- Extended Callbacks
        // called via the opcode 0xcb which is an extended opcode meaning
        // the next immediate byte has to be decoded and treated as the opcode
        0xcb => {
            var next: u16 = cpu.popPC();
            op = extendedOperation(cpu, next);
        },
        else => {
            print("not implemented\n", .{});
        },
    }

    return op;
}

fn extendedOperation(cpu: *c.CPU, opcode: u16) Opcode {
    var op: Opcode = .{
        .label = undefined,
        .value = opcode, // This is repeated. Not sure why Zig doesn't allow it to be omitted in the subsequent usage.
        .length = undefined,
        .cycles = undefined,
        .steps = undefined,
    };

    switch (opcode) {
        0x7c => {
            op = .{
                .label = "BIT 7,H",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .steps = &[_]Step{
                    bit7h,
                },
            };
        },
        else => {
            print("[extended] not implemented\n", .{});
        },
    }

    return op;
}


// ADDS
// add_and_set_flags performs an add instruction on the input values, storing them using the set
// function. Also updates flags accordingly
fn add_and_set_flags(cpu: *c.CPU, v1: u8, v2: u8) u8 {
    var total: u8 = v1 +% v2;

    cpu.setZ(total == 0);
    cpu.setH( (v1 & 0x0F) + (v2 & 0x0F) > 0x0F);
    cpu.setC(total > 0xFF); // If result is greater than 255

    return total;
}

fn addAE(cpu: *c.CPU) void {
    var v1: u8 = cpu.de.hi();
    var v2: u8 = cpu.af.hi();

    var total: u8 = add_and_set_flags(cpu, v1, v2);

    cpu.af.setHi(total);
}

fn addAC(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.bc.lo();

    var total: u8 = add_and_set_flags(cpu, v1, v2);

    cpu.af.setHi(total);
}

fn addAB(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.bc.hi();

    var total: u8 = add_and_set_flags(cpu, v1, v2);

    cpu.af.setHi(total);

}

// LOADS

// LD SP,16
fn ldSpu16(cpu: *c.CPU) void {
    cpu.sp = cpu.popPC16();
}

// LD HL,u16
fn ldHlu16(cpu: *c.CPU) void {
    cpu.hl.set(cpu.popPC16());
}

fn ldDeu16(cpu: *c.CPU) void {
    cpu.de.set(cpu.popPC16());
}

// LD (HL),E
// Load E into memory address HL
fn ldHlE(cpu: *c.CPU) void {
    cpu.memory.write(cpu.hl.hilo(), cpu.de.hi());
}

// LD (HL-),A
// Load to the address specified by the 16-bit register HL, data from A
// The value of HL is decremented after memory write
fn ldHlA(cpu: *c.CPU) void {
    var address: u16 = cpu.hl.hilo();
    cpu.memory.write(address, cpu.af.hi());
    cpu.hl.set(cpu.hl.hilo() - 1);
}

// XOR A,A
// XOR A with itself (or, set it to 0)
fn xorAA(cpu: *c.CPU) void {
    var a1: u8 = cpu.af.hi();
    var a2: u8 = cpu.af.hi();

    var v: u8 = a1 ^ a2;
    cpu.af.setHi(v);

    // Set flags
    cpu.setZ(v == 0);
    cpu.setN(false);
    cpu.setH(false);
    cpu.setC(false);
}

// Jumps

// JR NZ,u8
// Unconditional jump to the relative address specified by popping PC, only
// occurring if Z is false
fn jrNz8(cpu: *c.CPU) void {
    var address: u16 = cpu.popPC();
    if (!cpu.Z()) {
        var next: u16 = cpu.pc + address;
        cpu.pc = next;
    }
}

// JP u16
// Jump to the address specified by extracting 16 bytes
fn jpu16(cpu: *c.CPU) void {
    var address: u16 = cpu.popPC16();
    cpu.pc = address;
}

// RET NZ
// If Z is negative, pop return address from stack and jump to it.
fn retNz(cpu: *c.CPU) void {
    if (!cpu.Z()) {
        cpu.pc = cpu.popStack();
    }
}

// RET NC
// If C, pop return address from stack and jump to it.
fn retNc(cpu: *c.CPU) void {
    if (cpu.C()) {
        cpu.pc = cpu.popStack();
    }
}

// Increments
//
// INC BC
fn incBc(cpu: *c.CPU) void {
    var v: u16 = cpu.bc.hilo();
    cpu.bc.set(v + 1);
}

// Extended Operations

// BIT 7,H
// Test bit at index 7 using value H
fn bit7h(cpu: *c.CPU) void {
    var v: u8 = cpu.hl.hi();
    var index: u3 = 7;

    cpu.setZ((v >> index) & 1 == 0);
    cpu.setN(false);
    cpu.setH(true);
}

