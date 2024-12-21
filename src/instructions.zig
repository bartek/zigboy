const std = @import("std");

const print = std.debug.print;
const panic = std.debug.panic;
const assert = std.debug.assert;

const c = @import("./cpu.zig");

pub const OpArg = packed union {
    u8: u8, // B
    i8: i8, // b
    u16: u16, // H
};

pub const OP_ARG_BYTES = [_]u2{ 0, 1, 2, 1 };
pub const OP_TYPES = [_]u2{
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 2, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0, // 0
    1, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 1
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 2
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 3
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 4
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 5
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 6
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 7
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // A
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // B
    0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 2, 0, 2, 2, 1, 0, // C
    0, 0, 2, 0, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0, // D
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, // E
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, // F
};

pub const OP_CYCLES = [_]u8{
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1, // 0
    0, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1, // 1
    2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1, // 2
    2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1, // 3
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 4
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 5
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 6
    2, 2, 2, 2, 2, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 1, // 7
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 8
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 9
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // A
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // B
    2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 0, 3, 6, 2, 4, // C
    2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4, // D
    3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4, // E
    3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4, // F
};

pub const OP_CB_CYCLES = [_]u8{
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 0
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 1
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 2
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 3
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 4
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 5
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 6
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 7
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 8
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 9
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // A
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // B
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // C
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // D
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // E
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // F
};

pub fn jump_op(cpu: *c.SM83, addr: u16, arg_type: u2) OpArg {
    return switch (arg_type) {
        0 => OpArg{ .u16 = 0 },
        1 => OpArg{ .u8 = cpu.memory.read(addr) },
        2 => OpArg{ .u16 = @as(u16, @intCast(cpu.memory.read(addr))) | @as(u16, @intCast(cpu.memory.read(addr + 1))) << 8 },
        3 => OpArg{ .i8 = @as(i8, @bitCast(cpu.memory.read(addr))) },
    };
}

pub fn operation_cb(cpu: *c.SM83, opcode: u16) void {
    return switch (opcode) {
        0x20 => {
            var v: u8 = cpu.getRegister(opcode);
            std.debug.print("register is {d}", .{v});
            cpu.setCarry((v & 1 << 7) != 0);
            v <<= 1;
            v &= 0xFF;
            cpu.setNegative(false);
            cpu.setHalfCarry(false);
            cpu.setZero(v == 0);
        },
        else => {
            panic("\n!! not implemented 0x{x}\n", .{opcode});
        },
    };
}

pub fn operation(cpu: *c.SM83, opcode: u16, arg: OpArg) void {
    std.debug.print("Operation: 0x{x}\n", .{opcode});
    return switch (opcode) {
        0x0 => {}, // NOP
        0x01 => {
            cpu.registers.bc.set(arg.u16);
        },
        0x02 => {
            cpu.memory.write(cpu.registers.bc.hilo(), cpu.registers.af.hi());
        },
        0x06 => {
            cpu.registers.bc.setHi(arg.u8);
        },
        0x20 => {
            if (!cpu.zero()) {
                cpu.pc = @as(u16, @intCast(@as(i32, @intCast(cpu.pc)) + arg.i8));
            }
        },
        0xa8...0xaf => {},
        //.{
        //            .label = "XOR A,D",
        //            .length = 1,
        //            .cycles = 4,
        //            .step = xorAD,
        //        },
        0xa3 => {
            const total: u8 = cpu.registers.af.hi() & cpu.registers.de.lo();
            cpu.registers.af.setHi(total);

            cpu.setZero(total == 0);
            cpu.setNegative(false);
            cpu.setHalfCarry(true);
            cpu.setCarry(false);
        },
        0xb9 => {
            // TODO: Do range 0xb8..0xBf all CP
            const a: u8 = cpu.registers.af.hi();
            const rc: u8 = cpu.registers.bc.lo();
            const total: u8 = a -% rc;

            cpu.setZero(total == 0);
            cpu.setNegative(true);
            cpu.setHalfCarry((a & 0x0f) < (rc & 0x0f));
            cpu.setCarry(a < rc);
        },
        0xbb => {
            const a: u8 = cpu.registers.af.hi();
            const e: u8 = cpu.registers.de.lo();
            const total: u8 = a -% e;

            cpu.setZero(total == 0);
            cpu.setNegative(true);
            cpu.setHalfCarry((a & 0x0f) < (e & 0x0f));
            cpu.setCarry(a < e);
        },
        0xe2 => {
            cpu.memory.write(0xff00 | @as(u16, cpu.registers.bc.lo()), cpu.registers.af.hi());
        },
        //0x10 => .{
        //    .label = "STOP",
        //    .length = 1,
        //    .cycles = 4,
        //    .step = stop,
        //},
        0x1a => {
            cpu.registers.af.setHi(cpu.memory.read(cpu.registers.de.hilo()));
        },
        //0x22 => .{
        //    .label = "LD (HL+),A",
        //    .length = 3,
        //    .cycles = 12,
        //    .step = ldiHLA,
        //},
        //0x31 => .{
        //    .label = "LD SP,u16",
        //    .length = 3,
        //    .cycles = 12,
        //    .step = ldSpu16,
        //},
        0x4f => {
            cpu.registers.bc.setLo(cpu.registers.af.hi());
        },
        0xd4 => {
            if (!cpu.carry()) {
                cpu.pushStack(arg.u16);
                cpu.pc = arg.u16;
            }
        },
        else => {
            panic("\n!! not implemented 0x{x}\n", .{opcode});
        },
    };
}

fn noop(cpu: *c.SM83) void {
    _ = cpu;
}

// CALL NZ,u16
// Perform a CALL operation by pushing the current PC to the stack and jumping
// to the next address, only if Z is false
fn callNCu16(cpu: *c.SM83) void {
    const address: u16 = cpu.popPC16();
    if (!cpu.carry()) {
        cpu.pushStack(cpu.pc);
        cpu.pc = address;
    }
}

fn ldCA(cpu: *c.SM83) void {
    cpu.registers.bc.setLo(cpu.registers.af.hi());
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
