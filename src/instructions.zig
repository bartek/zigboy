const std = @import("std");
const print = std.debug.print;

const c = @import("./cpu.zig");

// Step is the actual execution of the Opcode
pub const Step = *const fn (cpu: *c.CPU) void;

// Opcode is an instruction for the CPU
pub const Opcode = struct {
    label: []const u8, // e.g. "XOR A,A"
    value: u16, // e.g. 0x31
    length: u8,
    cycles: u8, // clock cycles

    step: Step,
};

pub fn operation(cpu: *c.CPU, opcode: u16) Opcode {
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
        0x1 => {
            op = .{
                .label = "LD BC, u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .step = ldBCu16,
            };
        },
        0x6 => {
            op = .{
                .label = "LD B,u8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = ldBu8,
            };
        },
        0x69 => {
            op = .{
                .label = "LD L,C",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = ldLC,
            };
        },
        0x11 => {
            op = .{
                .label = "LD DE,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .step = ldDeu16,
            };
        },
        0x12 => {
            op = .{
                .label = "LD (DE),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldDea,
            };
        },
        0x14 => {
            op = .{
                .label = "INC D",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = incD,
            };
        },
        0x17 => {
            op = .{
                .label = "RL A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = rla,
            };
        },
        0x18 => {
            op = .{
                .label = "JR i8",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = jri8,
            };
        },
        0x1a => {
            op = .{
                .label = "LD A,(DE)",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldAMDe,
            };
        },
        0x1c => {
            op = .{
                .label = "INC E",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = incE,
            };
        },
        0x20 => {
            op = .{
                .label = "JR NZ,i8",
                .value = opcode,
                .length = 2,
                .cycles = 12, // FIXME: with/without branch timing to review
                .step = jrNZi8,
            };
        },
        0x21 => {
            op = .{
                .label = "LD HL,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .step = ldHlu16,
            };
        },
        0x23 => {
            op = .{
                .label = "INC HL",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = incHL,
            };
        },
        0x24 => {
            op = .{
                .label = "INC H",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = incH,
            };
        },
        0x28 => {
            op = .{
                .label = "JR Z,i8",
                .value = opcode,
                .length = 2,
                .cycles = 12, // FIXME: with/without branch timing to review
                .step = jrZi8,
            };
        },
        0x2a => {
            op = .{
                .label = "LDI A,(HL)",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldAMHl,
            };
        },
        0x2c => {
            op = .{
                .label = "INC L",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = incL,
            };
        },
        0x31 => {
            op = .{
                .label = "LD SP,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .step = ldSpu16,
            };
        },
        0x30 => {
            op = .{
                .label = "JR NC,i8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = jrNCi8,
            };
        },
        0x3e => {
            op = .{
                .label = "LD A,u8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = ldAu8,
            };
        },
        0x47 => {
            op = .{
                .label = "LD B,A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = ldBA,
            };
        },
        0x4f => {
            op = .{
                .label = "LD C,A",
                .value = opcode,
                .length = 1,
                .cycles = 3,
                .step = ldCA,
            };
        },
        0x5 => {
            op = .{
                .label = "LD D,B",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = ldDB,
            };
        },
        0x77 => {
            op = .{
                .label = "LD (HL),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldHlA,
            };
        },
        0x78 => {
            op = .{
                .label = "LD A,B",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = ldAB,
            };
        },
        0x7c => {
            op = .{
                .label = "LD A,H",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldAH,
            };
        },
        0x7d => {
            op = .{
                .label = "LD A,L",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldAL,
            };
        },
        0xc1 => {
            op = .{
                .label = "POP BC",
                .value = opcode,
                .length = 1,
                .cycles = 12,
                .step = popBC,
            };
        },
        0xc3 => {
            op = .{
                .label = "JP u16",
                .value = opcode,
                .length = 3,
                .cycles = 16,
                .step = jpu16,
            };
        },
        0xc4 => {
            op = .{
                .label = "CALL NZ,u16",
                .value = opcode,
                .length = 3,
                .cycles = 24,
                .step = callNZu16,
            };
        },
        0xc5 => {
            op = .{
                .label = "PUSH BC",
                .value = opcode,
                .length = 1,
                .cycles = 16,
                .step = pushBC,
            };
        },
        0xcd => {
            op = .{
                .label = "CALL u16",
                .value = opcode,
                .length = 3,
                .cycles = 124,
                .step = callu16,
            };
        },
        0x03 => {
            op = .{
                .label = "INC BC",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = incBc,
            };
        },
        0x32 => {
            op = .{
                .label = "LD (HL-),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldHlADec,
            };
        },
        0xaa => {
            op = .{
                .label = "XOR A,D",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = xorAD,
            };
        },
        0xaf => {
            op = .{
                .label = "XOR A,A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = xorAA,
            };
        },
        0xb1 => {
            op = .{
                .label = "DEC DE",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = decDE,
            };
        },

        0x73 => {
            op = .{
                .label = "LD (HL),E",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ldHlE,
            };
        },
        0x8 => {
            op = .{
                .label = "ADD A,B",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = addAB,
            };
        },

        0x83 => {
            op = .{
                .label = "ADD A,E",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = addAE,
            };
        },
        0x89 => {
            op = .{
                .label = "ADD A,C",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = addAC,
            };
        },
        0x0c => {
            op = .{
                .label = "INC C",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = incC,
            };
        },
        0xc9 => {
            op = .{
                .label = "RET",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = ret,
            };
        },
        0xd0 => {
            op = .{
                .label = "RET NC",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .step = retNc,
            };
        },
        0x0d => {
            op = .{
                .label = "DEC C",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .step = decC,
            };
        },
        0x0e => {
            op = .{
                .label = "LD C,u8",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = ldCu8,
            };
        },
        0xe0 => {
            op = .{
                .label = "LD (FF00+u8),A",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .step = ldAintoN,
            };
        },
        0xe1 => {
            op = .{
                .label = "POP HL",
                .value = opcode,
                .length = 1,
                .cycles = 12,
                .step = popHL,
            };
        },
        0xe2 => {
            op = .{
                .label = "LD (FF00+C),A",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .step = ldAintoC,
            };
        },
        0xe5 => {
            op = .{
                .label = "PUSH HL",
                .value = opcode,
                .length = 1,
                .cycles = 16,
                .step = pushHL,
            };
        },
        0xe6 => {
            op = .{
                .label = "AND A, u8",
                .value = opcode,
                .length = 1,
                .cycles = 16,
                .step = andAu8,
            };
        },
        0xea => {
            op = .{
                .label = "LD (u16),A",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .step = ldNNintoA,
            };
        },
        0xf1 => {
            op = .{
                .label = "POP AF",
                .value = opcode,
                .length = 1,
                .cycles = 12,
                .step = popAF,
            };
        },
        0xf3 => {
            op = .{
                .label = "DI",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .step = di,
            };
        },
        0xf5 => {
            op = .{
                .label = "PUSH AF",
                .value = opcode,
                .length = 1,
                .cycles = 16,
                .step = pushAF,
            };
        },
        0xfa => {
            op = .{
                .label = "LD A,(u16)",
                .value = opcode,
                .length = 2,
                .cycles = 12,
                .step = ldAintoNN,
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
        .step = undefined,
    };

    switch (opcode) {
        0x11 => {
            op = .{
                .label = "RL C",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = rlC,
            };
        },
        0x7c => {
            op = .{
                .label = "BIT 7,H",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = bit7h,
            };
        },
        else => {
            print("[extended] not implemented 0x{x}\n", .{opcode});
        },
    }

    return op;
}

fn noop(cpu: *c.CPU) void {
    _ = cpu;
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

fn ldLC(cpu: *c.CPU) void {
    var v = cpu.bc.lo();
    cpu.hl.setLo(v);
}

fn ldAintoNN(cpu: *c.CPU) void {
    var v = cpu.memory.read(cpu.popPC16());
    cpu.af.setHi(v);
}

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

// LD A,L
fn ldAL(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.de.lo());
}
// LD A,B
fn ldAB(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.bc.hi());
}

// LD A,H
fn ldAH(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.hl.hi());
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

// LD BC,u16
fn ldBCu16(cpu: *c.CPU) void {
    cpu.bc.set(cpu.popPC16());
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

// LD (u16),A
fn ldNNintoA(cpu: *c.CPU) void {
    cpu.memory.write(cpu.popPC16(), cpu.af.hi());
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

fn xorAD(cpu: *c.CPU) void {
    var a1: u8 = cpu.af.hi();
    var a2: u8 = cpu.de.hi();

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

// POP AF
fn popAF(cpu: *c.CPU) void {
    var v: u16 = cpu.popStack();
    cpu.af.set(v);
}

// POP HL
fn popHL(cpu: *c.CPU) void {
    cpu.hl.set(cpu.popStack());
}

// POP BC
fn popBC(cpu: *c.CPU) void {
    cpu.bc.set(cpu.popStack());
}

// Jumps
//
//
// JR i8. Relative jump, no condition.
fn jri8(cpu: *c.CPU) void {
    var offset = cpu.popPC();
    cpu.pc += @intCast(u16, offset);
}

// JR Z,i8. Relative jump, if zero flag is set.
fn jrZi8(cpu: *c.CPU) void {
    var offset = cpu.popPC();
    if (cpu.zero()) {
        cpu.pc += @intCast(u16, offset);
    }
}

// JR NZ,i8
// Conditional jump to the relative address specified by popping PC, only
// occurring if Z is false
fn jrNZi8(cpu: *c.CPU) void {
    var offset = @bitCast(i8, cpu.popPC());

    if (!cpu.zero()) {
        var result = @intCast(i32, cpu.pc);
        result +%= offset;
        cpu.pc = @intCast(u16, result);
    }
}

// JR NC,i8
// Conditional jump to the relative address specified by popping PC, only
// occurring if C is false
fn jrNCi8(cpu: *c.CPU) void {
    if (!cpu.carry()) {
        var addr = @intCast(i32, cpu.pc);
        cpu.pc = @intCast(u16, addr);
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

// RET
// Pop return address from stack and jump to it.
fn ret(cpu: *c.CPU) void {
    cpu.pc = cpu.popStack();
}

// RET NC
// If not carry, pop return address from stack and jump to it.
fn retNc(cpu: *c.CPU) void {
    if (!cpu.carry()) {
        ret(cpu);
    }
}

fn halfCarryAdd(v1: u8, v2: u8) bool {
    return (v1 & 0xf) + (v2 & 0xf) > 0xf;
}

// Increments

// INC HL
fn incHL(cpu: *c.CPU) void {
    var v: u16 = cpu.hl.hilo() +% 1;
    cpu.hl.set(v);
}

// INC BC
fn incBc(cpu: *c.CPU) void {
    var v: u16 = cpu.bc.hilo();
    cpu.bc.set(v +% 1);
}

fn incD(cpu: *c.CPU) void {
    var v: u8 = cpu.de.hi();
    var total = v +% 1;
    cpu.de.setHi(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(halfCarryAdd(v, 1));
}

fn incE(cpu: *c.CPU) void {
    var v: u8 = cpu.de.lo();
    var total = v +% 1;
    cpu.de.setLo(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(halfCarryAdd(v, 1));
}

fn incL(cpu: *c.CPU) void {
    var v: u8 = cpu.hl.lo();
    var total = v +% 1;
    cpu.hl.setLo(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(halfCarryAdd(v, 1));
}

fn incH(cpu: *c.CPU) void {
    var v: u8 = cpu.hl.hi();
    var total = v +% 1;
    cpu.hl.setHi(total);

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

// DEC

// DEC C
fn decC(cpu: *c.CPU) void {
    var v: u8 = cpu.bc.lo();
    var total: u8 = v - 1;
    cpu.bc.setLo(total);

    cpu.setZero(total == 0);
    cpu.setNegative(true);
    cpu.setHalfCarry(v & 0x0f == 0);
}
// DEC DE
fn decDE(cpu: *c.CPU) void {
    var v: u16 = cpu.de.hilo();
    cpu.de.set(v -% 1);
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

// PUSH AF
fn pushAF(cpu: *c.CPU) void {
    cpu.pushStack(cpu.af.hilo());
}

// PUSH HL
fn pushHL(cpu: *c.CPU) void {
    cpu.pushStack(cpu.hl.hilo());
}

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

// CALL NZ,u16
// Perform a CALL operation by pushing the current PC to the stack and jumping
// to the next address, only if Z is false
fn callNZu16(cpu: *c.CPU) void {
    var address: u16 = cpu.popPC16();
    if (!cpu.zero()) {
        cpu.pushStack(cpu.pc);
        cpu.pc = address;
    }
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

// AND
fn andAu8(cpu: *c.CPU) void {
    var v: u8 = cpu.popPC();
    var total: u8 = v & cpu.af.hi();

    cpu.af.setHi(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(true);
    cpu.setCarry(false);
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

fn di(cpu: *c.CPU) void {
    cpu.interruptsEnabled = false;
}
