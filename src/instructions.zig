const std = @import("std");
const print = std.debug.print;

const c = @import("./cpu.zig");

// Step is single step within an Opcode
pub const Step = *const fn (cpu: *c.CPU) void;

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
        0x6 => {
            op = .{
                .label = "LD B,u8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .steps = &[_]Step{
                    ldBu8,
                },
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
        0x12 => {
            op = .{
                .label = "LD (DE),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldDea,
                },
            };
        },
        0x17 => {
            op = .{
                .label = "RL A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    rla,
                },
            };
        },
        0x1a => {
            op = .{
                .label = "LD A,(DE)",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldAMDe,
                },
            };
        },
        0x1c => {
            op = .{
                .label = "INC E",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    incE,
                },
            };
        },
        0x20 => {
            op = .{
                .label = "JR NZ,i8",
                .value = opcode,
                .length = 2,
                .cycles = 12, // FIXME: with/without branch timing to review
                .steps = &[_]Step{
                    jrNzi8,
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
        0x2a => {
            op = .{
                .label = "LDI A,(HL)",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldAMHl,
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
        0x3e => {
            op = .{
                .label = "LD A,u8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .steps = &[_]Step{
                    ldAu8,
                },
            };
        },
        0x47 => {
            op = .{
                .label = "LD B,A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    ldBA,
                },
            };
        },
        0x4f => {
            op = .{
                .label = "LD C,A",
                .value = opcode,
                .length = 1,
                .cycles = 3,
                .steps = &[_]Step{
                    ldCA,
                },
            };
        },
        0x5 => {
            op = .{
                .label = "LD D,B",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    ldDB,
                },
            };
        },
        0x77 => {
            op = .{
                .label = "LD (HL),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldHlA,
                },
            };
        },
        0xc1 => {
            op = .{
                .label = "POP BC",
                .value = opcode,
                .length = 1,
                .cycles = 12,
                .steps = &[_]Step{
                    popBC,
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
        0xc5 => {
            op = .{
                .label = "PUSH BC",
                .value = opcode,
                .length = 1,
                .cycles = 16,
                .steps = &[_]Step{
                    pushBC,
                },
            };
        },
        0xcd => {
            op = .{
                .label = "CALL u16",
                .value = opcode,
                .length = 3,
                .cycles = 124,
                .steps = &[_]Step{
                    callu16,
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
                    ldHlADec,
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
        0x0c => {
            op = .{
                .label = "INC C",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    incC,
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
        0x0e => {
            op = .{
                .label = "LD C,u8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .steps = &[_]Step{
                    ldCu8,
                },
            };
        },
        0xe0 => {
            op = .{
                .label = "LD (FF00+u8),A",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .steps = &[_]Step{
                    ldAintoN,
                },
            };
        },
        0xe2 => {
            op = .{
                .label = "LD (FF00+C),A",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .steps = &[_]Step{
                    ldAintoC,
                },
            };
        },

        // -- Extended Callbacks
        // called via the opcode 0xcb which is an extended opcode meaning
        // the next immediate byte has to be decoded and treated as the opcode
        0xcb => {
            var next: u16 = cpu.popPC();
            op = extendedOperation(next);
        },
        else => {
            print("not implemented 0x{x}\n", .{opcode});
        },
    }

    return op;
}

fn extendedOperation(opcode: u16) Opcode {
    var op: Opcode = .{
        .label = undefined,
        .value = opcode, // This is repeated. Not sure why Zig doesn't allow it to be omitted in the subsequent usage.
        .length = undefined,
        .cycles = undefined,
        .steps = undefined,
    };

    switch (opcode) {
        0x11 => {
            op = .{
                .label = "RL C",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .steps = &[_]Step{
                    rlC,
                },
            };
        },
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
            print("[extended] not implemented 0x{x}\n", .{opcode});
        },
    }

    return op;
}

// ADDS
// add_and_set_flags performs an add instruction on the input values, storing them using the set
// function. Also updates flags accordingly
fn add_and_set_flags(cpu: *c.CPU, v1: u8, v2: u8) u8 {
    var total: u8 = v1 +% v2;

    cpu.setZero(total == 0);
    cpu.setHalfCarry((v1 & 0x0F) + (v2 & 0x0F) > 0x0F);
    cpu.setCarry(total > 0xFF); // If result is greater than 255

    return total;
}

fn addAE(cpu: *c.CPU) void {
    var v1: u8 = cpu.de.lo();
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

// LD A,(DE)
// Read at memory location (DE) and load into A
fn ldAMDe(cpu: *c.CPU) void {
    var v: u8 = cpu.memory.read(cpu.de.hilo());
    cpu.af.setHi(v);
}

// LD (DE),A
fn ldDea(cpu: *c.CPU) void {
    var v: u8 = cpu.af.hi();
    cpu.memory.write(cpu.de.hilo(), v);
}

// LDI A,(HL)
// Read at memory location (HL) and load into A
fn ldAMHl(cpu: *c.CPU) void {
    var v: u8 = cpu.memory.read(cpu.hl.hilo());
    cpu.af.setHi(v);
    cpu.hl.set(cpu.hl.hilo() + 1);
}

// LD B,A
fn ldBA(cpu: *c.CPU) void {
    cpu.bc.setHi(cpu.af.hi());
}

// LD C,A
fn ldCA(cpu: *c.CPU) void {
    cpu.bc.setLo(cpu.af.hi());
}

// LD D,B
fn ldDB(cpu: *c.CPU) void {
    cpu.de.setHi(cpu.bc.hi());
}

// LD A,u8
fn ldAu8(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.popPC());
}

// LD C,u8
fn ldCu8(cpu: *c.CPU) void {
    cpu.bc.setLo(cpu.popPC());
}

// LD B,u8
fn ldBu8(cpu: *c.CPU) void {
    cpu.bc.setHi(cpu.popPC());
}

// LD SP,16
fn ldSpu16(cpu: *c.CPU) void {
    cpu.sp = cpu.popPC16();
}

// LD HL,u16
fn ldHlu16(cpu: *c.CPU) void {
    var v = cpu.popPC16();
    cpu.hl.set(v);
}

fn ldDeu16(cpu: *c.CPU) void {
    cpu.de.set(cpu.popPC16());
}

// LD (HL),A
// Load A into memory address HL
fn ldHlA(cpu: *c.CPU) void {
    cpu.memory.write(cpu.hl.hilo(), cpu.af.hi());
}

// LD (HL),E
// Load E into memory address HL
fn ldHlE(cpu: *c.CPU) void {
    cpu.memory.write(cpu.hl.hilo(), cpu.de.lo());
}

// LD (FF00+u8),A
// Load A into [0xff00 + N]
fn ldAintoN(cpu: *c.CPU) void {
    var address: u16 = cpu.popPC();
    cpu.memory.write(0xff00 | address, cpu.af.hi());
}

// LD (FF00+C),A
// Load A into [0xff00 + C]
fn ldAintoC(cpu: *c.CPU) void {
    cpu.memory.write(0xff00 | @intCast(u16, cpu.bc.lo()), cpu.af.hi());
}

// LD (HL-),A
// Load to the address specified by the 16-bit register HL, data from A
// The value of HL is decremented after memory write
fn ldHlADec(cpu: *c.CPU) void {
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
    cpu.setZero(v == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(false);
}

// POP u16
// Pop register u16 from the stack

// POP BC
fn popBC(cpu: *c.CPU) void {
    cpu.bc.set(cpu.popStack());
}

// Jumps

// JR NZ,i8
// Unconditional jump to the relative address specified by popping PC, only
// occurring if Z is false
fn jrNzi8(cpu: *c.CPU) void {
    var offset = @bitCast(i8, cpu.popPC());

    if (!cpu.zero()) {
        var result = @intCast(i16, cpu.pc);
        result +%= offset;
        cpu.pc = @intCast(u16, result);
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
    if (!cpu.zero()) {
        cpu.pc = cpu.popStack();
    }
}

// RET NC
// If carry,  pop return address from stack and jump to it.
fn retNc(cpu: *c.CPU) void {
    if (cpu.carry()) {
        cpu.pc = cpu.popStack();
    }
}

fn halfCarryAdd(v1: u8, v2: u8) bool {
    return (v1 & 0xf) + (v2 & 0xf) > 0xf;
}

// Increments
//
// INC BC
fn incBc(cpu: *c.CPU) void {
    print("FIXME: FLAGS", .{});
    var v: u16 = cpu.bc.hilo();
    cpu.bc.set(v + 1);
}

fn incE(cpu: *c.CPU) void {
    var v: u8 = cpu.de.lo();
    var total: u8 = v + 1;
    cpu.de.setLo(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(halfCarryAdd(v, 1));
}

fn incC(cpu: *c.CPU) void {
    var v: u8 = cpu.bc.lo();
    var total: u8 = v + 1;
    cpu.bc.setLo(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(halfCarryAdd(v, 1));
}

// Extended Operations

// BIT 7,H
// Test bit at index 7 using value H
fn bit7h(cpu: *c.CPU) void {
    var v: u8 = cpu.hl.hi();
    var index: u3 = 7;

    cpu.setZero((v & (@as(usize, 1) << index)) == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(true);
}

// PUSH
// Push onto the stack

// PUSH BC
fn pushBC(cpu: *c.CPU) void {
    cpu.pushStack(cpu.bc.hilo());
}

// CALL

// Perform a CALL operation by pushing the current PC to the stack and jumping
// to the next address
fn callu16(cpu: *c.CPU) void {
    var address: u16 = cpu.popPC16();
    cpu.pushStack(cpu.pc);
    cpu.pc = address;
}

// Rotate is a helper function to rotate an u8 to the left through carry and
// update CPU flags
fn rotate(cpu: *c.CPU, value: u8) u8 {
    var oldcarry: u8 = @boolToInt(cpu.carry());
    cpu.setCarry(value & 0x80 != 0);

    var rot: u8 = (value << 1) | oldcarry;

    cpu.setZero(rot == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);

    return rot;
}

// RL C
// Rotate C to the left through carry
fn rlC(cpu: *c.CPU) void {
    var rot: u8 = rotate(cpu, cpu.bc.lo());
    cpu.bc.setLo(rot);
}

// RL A
// Rotate register A left through carry
fn rla(cpu: *c.CPU) void {
    var rot: u8 = rotate(cpu, cpu.af.hi());
    cpu.af.setHi(rot);
}
