// Extended instructions, 0xCB Prefixed
const std = @import("std");
const print = std.debug.print;

const c = @import("./cpu.zig");
const Opcode = @import("./opcode.zig").Opcode;

pub fn extendedOperation(opcode: u16) Opcode {
    // FIXME: Move this to a foor loop like so:
    // https://github.com/Humpheh/goboy/blob/master/pkg/gb/instructions_cb.go
    // This is a much simpler instruction set to build. Start with SRL
    var op: Opcode = .{
        .label = undefined,
        .value = opcode, // This is repeated. Not sure why Zig doesn't allow it to be omitted in the subsequent usage.
        .length = undefined,
        .cycles = undefined,
        .step = undefined,
    };

    //const get_map: [8]*const fn () u8 = [_]*const fn () u8{
    //    struct {
    //        fn f() u8 {
    //            return cpu.bc.hi();
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.bc.lo();
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.de.hi();
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.de.lo();
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.hl.hi();
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.hl.lo();
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.memory.read(cpu.hl.hilo());
    //        }
    //    }.f,
    //    struct {
    //        fn f() u8 {
    //            return cpu.af.hi();
    //        }
    //    }.f,
    //};

    //var set_map: [8]*const fn (v: u8) void = [_]*const fn (v: u8) void{
    //    cpu.bc.setHi,
    //    cpu.bc.setLo,
    //    cpu.de.setHi,
    //    cpu.de.setLo,
    //    cpu.hl.setHi,
    //    cpu.hl.setLo,
    //    struct {
    //        fn f(v: u8) void {
    //            return cpu.memory.write(cpu.hl.hilo(), v);
    //        }
    //    }.f,
    //    cpu.af.setHi,
    //};

    //var instructions: [0x100]fn () void = undefined;

    //var i: usize = 0;
    //while (i < 8) {
    //    instructions[0x38 + i] = return struct {
    //        fn f(y: usize) void {
    //            print("{x}", .{get_map[i]});
    //        }
    //    }.f;
    //    // setmap, getmap
    //    //srl(i: usize) fn() void {
    //    //    return struct {
    //    //        fn srl() void {
    //    //            cpu.srl(i);
    //    //        }
    //    //    }.srl;
    //    //}
    //}

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
        0x19 => {
            op = .{
                .label = "RR C",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = rrC,
            };
        },
        0x38 => {
            op = .{
                .label = "SRL B",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .step = srlB,
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

fn addAu8(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.popPC();

    var total: u8 = add_and_set_flags(cpu, v1, v2);
    cpu.af.setHi(total);
}

// SUBS
//
// SUB A,u8
fn subAu8(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.popPC();

    var total: u8 = v1 -% v2;
    cpu.af.setHi(total);

    cpu.setZero(total == 0);
    cpu.setNegative(true);
    cpu.setHalfCarry((v1 & 0x0F) < (v2 & 0x0F));
    cpu.setCarry(v2 > v1);
}

// SUB A,B (r8)
fn subAB(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.bc.hi();

    var total: u8 = v1 -% v2;
    cpu.af.setHi(total);

    cpu.setZero(total == 0);
    cpu.setNegative(true);
    cpu.setHalfCarry((v1 & 0x0F) < (v2 & 0x0F));
    cpu.setCarry(v2 > v1);
}

// LOADS

fn ldHu8(cpu: *c.CPU) void {
    cpu.hl.setHi(cpu.popPC());
}

// LD A,(FF00+u8)
fn ldAfromN(cpu: *c.CPU) void {
    var v: u8 = cpu.memory.read(0xff00 + @as(u16, cpu.popPC()));
    cpu.af.setHi(v);
}

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

// LD B,(HL)
fn ldBHL(cpu: *c.CPU) void {
    var v: u8 = cpu.memory.read(cpu.hl.hilo());
    cpu.bc.setHi(v);
}

// LD B,A
fn ldBA(cpu: *c.CPU) void {
    cpu.bc.setHi(cpu.af.hi());
}

// LD C,(HL)
fn ldCHL(cpu: *c.CPU) void {
    var v: u8 = cpu.memory.read(cpu.hl.hilo());
    cpu.bc.setLo(v);
}

// LD C,A
fn ldCA(cpu: *c.CPU) void {
    cpu.bc.setLo(cpu.af.hi());
}

// LD A,L
fn ldAL(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.hl.lo());
}
// LD A,B
fn ldAB(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.bc.hi());
}

// LD A,H
fn ldAH(cpu: *c.CPU) void {
    cpu.af.setHi(cpu.hl.hi());
}

// LD D,(HL)
fn ldDHL(cpu: *c.CPU) void {
    var v: u8 = cpu.memory.read(cpu.hl.hilo());
    cpu.de.setHi(v);
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

// LD (HL+),A
fn ldiHLA(cpu: *c.CPU) void {
    var v = cpu.hl.hilo();
    cpu.memory.write(v, cpu.af.hi());
    cpu.hl.set(v + 1);
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

// OR

// OR A,A
fn orAA(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.af.hi();

    var total: u8 = v1 | v2;
    cpu.af.setHi(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(false);
}

// OR A,C
fn orAC(cpu: *c.CPU) void {
    var v1: u8 = cpu.af.hi();
    var v2: u8 = cpu.bc.lo();

    var total: u8 = v1 | v2;

    cpu.af.setHi(total);
    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(false);
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

// XOR A,C
fn xorAC(cpu: *c.CPU) void {
    var a1: u8 = cpu.af.hi();
    var a2: u8 = cpu.bc.lo();

    var v: u8 = a1 ^ a2;
    cpu.af.setHi(v);

    // Set flags
    cpu.setZero(v == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(false);
}

// XOR A,(HL)
fn xorAHL(cpu: *c.CPU) void {
    var a1: u8 = cpu.af.hi();
    var a2: u8 = cpu.memory.read(cpu.hl.hilo());

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
// JR C,i8
fn jrCi8(cpu: *c.CPU) void {
    var v: u8 = cpu.popPC();
    if (cpu.carry()) {
        cpu.pc += @intCast(u16, v);
    }
}

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

// INC DE
fn incDE(cpu: *c.CPU) void {
    var v: u16 = cpu.de.hilo();
    cpu.de.set(v +% 1);
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

fn dec(cpu: *c.CPU, v: u8) u8 {
    var total = v - 1;
    cpu.setZero(total == 0);
    cpu.setNegative(true);
    cpu.setHalfCarry(v & 0x0f == 0);
    return total;
}

//
// DEC B
fn decB(cpu: *c.CPU) void {
    var v = dec(cpu, cpu.bc.hi());
    cpu.bc.setHi(v);
}

// DEC C
fn decC(cpu: *c.CPU) void {
    var v = dec(cpu, cpu.bc.lo());
    cpu.bc.setLo(v);
}

// DEC L
fn decL(cpu: *c.CPU) void {
    var v = dec(cpu, cpu.hl.lo());
    cpu.hl.setLo(v);
}

// DEC DE
// FIXME: Flags?
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
fn push(cpu: *c.CPU, f: u16) void {
    cpu.pushStack(f);
}

// PUSH DE
fn pushDE(cpu: *c.CPU) void {
    cpu.pushStack(cpu.de.hilo());
}

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

// COPY

// CP A,u8
fn cpAu8(cpu: *c.CPU) void {
    var v1: u8 = cpu.popPC();
    var v2: u8 = cpu.af.hi();
    var total = v2 -% v1;

    cpu.setZero(total == 0);
    cpu.setNegative(true);
    cpu.setHalfCarry((v1 & 0x0f) > (v2 & 0x0f));
    cpu.setCarry(v1 > v2);
}

fn halfCarryAdd(v1: u8, v2: u8) bool {
    return (v1 & 0xf) + (v2 & 0xf) > 0xf;
}

// SERIAL
//
// SRL B
fn srlB(cpu: *c.CPU) void {
    var v: u8 = cpu.bc.hi();
    var carry = v & 1;
    var total: u8 = v >> 1;
    cpu.bc.setHi(total);

    cpu.setZero(total == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(carry == 1);
}

fn rrC(cpu: *c.CPU) void {
    var v: u8 = cpu.de.hi();
    var carry = v & 1;
    var rot: u8 = (v >> 1) | (@boolToInt(cpu.carry()) << 7);
    cpu.de.setHi(rot);

    cpu.setZero(rot == 0);
    cpu.setNegative(false);
    cpu.setHalfCarry(false);
    cpu.setCarry(carry == 1);
}
