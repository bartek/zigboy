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

pub fn operation(cpu: *c.SM83, opcode: u8, arg: OpArg) void {
    std.debug.print("Operation: 0x{x}\n", .{opcode});
    return switch (opcode) {
        0x0 => {}, // NOP
        0x01 => {
            cpu.registers.bc.set(arg.u16);
        },
        0x02 => {
            cpu.memory.write(cpu.registers.bc.hilo(), cpu.registers.af.hi());
        },
        0x03 => {
            cpu.registers.bc.set(cpu.registers.bc.hilo() +% 1);
        },
        0x23 => {
            cpu.registers.hl.set(cpu.registers.hl.hilo() +% 1);
        },
        0x04, 0x14, 0x24, 0x0C, 0x1C, 0x2C, 0x34, 0x3C => { // INC r
            const v = cpu.getRegister((opcode - 0x04) / 8);

            cpu.setHalfCarry((v & 0x0f) == 0x0f);
            cpu.setZero(v +% 1 == 0);
            cpu.setNegative(false);

            const vo: u8 = @intCast(opcode - 0x04);
            cpu.setRegister(vo / 8, v +% 1);
        },
        0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D => { // DEC r
            const v = cpu.getRegister((opcode - 0x05) / 8);

            cpu.setHalfCarry((v -% 1 & 0x0f) == 0x0f);
            cpu.setZero(v -% 1 == 0);
            cpu.setNegative(true);

            const vo: u8 = @intCast(opcode - 0x05);
            cpu.setRegister(vo / 8, v -% 1);
        },
        0x06, 0x36 => { // LD r,n
            cpu.setRegister((opcode - 0x06) / 8, arg.u8);
        },
        0x07, 0x17 => { // RCLA, RLA
            const carry: u8 = if (cpu.carry()) 1 else 0;
            switch (opcode) {
                0x07 => { // RCLA
                    cpu.setCarry((cpu.registers.af.hi() & 1 << 7) != 0);
                    cpu.registers.af.setHi((cpu.registers.af.hi() << 1) | (cpu.registers.af.hi() >> 7));
                },
                0x17 => { // RLA
                    cpu.setCarry((cpu.registers.af.hi() & 1 << 7) != 0);
                    cpu.registers.af.setHi((cpu.registers.af.hi() << 1) | carry);
                },
                else => {}, // NOP
            }

            cpu.setNegative(false);
            cpu.setHalfCarry(false);
            cpu.setZero(false);
        },
        0x08 => { // LD (u16),SP
            cpu.memory.write(arg.u16 + 1, @as(u8, @intCast((cpu.sp >> 8) & 0xff)));
            cpu.memory.write(arg.u16, @as(u8, @intCast(cpu.sp & 0xff)));
        },
        0x09, 0x19, 0x29, 0x39 => { // ADD HL,rr
            const v = switch (opcode) {
                0x09 => cpu.registers.bc.hilo(),
                0x19 => cpu.registers.de.hilo(),
                0x29 => cpu.registers.hl.hilo(),
                0x39 => cpu.sp,
                else => 0,
            };

            cpu.setHalfCarry((cpu.registers.hl.hilo() & 0x0fff) + (v & 0x0fff) > 0x0fff);
            cpu.setCarry(@as(u32, cpu.registers.hl.hilo()) + @as(u32, v) > 0xffff);
            cpu.registers.hl.set(cpu.registers.hl.hilo() +% v);
            cpu.setNegative(false);
        },
        0x33 => {
            cpu.sp = cpu.sp +% 1;
        },
        0x37 => { // SCF
            cpu.setNegative(false);
            cpu.setHalfCarry(false);
            cpu.setCarry(true);
        },
        0x40...0x7F => { // LD r,r
            cpu.setRegister((opcode - 0x40) >> 3, cpu.getRegister(opcode - 0x40));
        },
        0x10 => {}, // STOP. noop has dmg games don't use STOP, so not implementing
        0x11 => {
            cpu.registers.de.set(arg.u16);
        },
        0x12 => {
            std.debug.print("af is {d}", .{cpu.registers.af.hi()});
            cpu.memory.write(cpu.registers.de.hilo(), cpu.registers.af.hi());
        },
        0x13 => {
            cpu.registers.de.set(cpu.registers.de.hilo() +% 1);
        },
        0x16 => {
            cpu.registers.de.setHi(arg.u8);
        },
        0x18, 0x20, 0x28, 0x30, 0x38 => { // JUMP i8
            const should_jump = switch (opcode) {
                0x18 => true,
                0x20 => !cpu.zero(),
                0x28 => cpu.zero(), // TODO: Test failing
                0x30 => !cpu.carry(),
                0x38 => cpu.carry(),
                else => false, // NOP, unexpected
            };
            if (should_jump) {
                cpu.pc = @as(u16, @intCast(@as(i32, @intCast(cpu.pc)) + arg.i8));
            }
        },
        0x21 => { // TODO: Test case failing after after a set amount of iterations.
            cpu.registers.hl.set(arg.u16);
        },
        0x22 => {
            cpu.memory.write(cpu.registers.hl.hilo(), cpu.registers.af.hi());
            cpu.registers.hl.set(cpu.registers.hl.hilo() +% 1);
        },
        0x26 => {
            cpu.registers.hl.setHi(arg.u8);
        },
        0x27 => { // DAA
            var v: u16 = cpu.registers.af.hi();
            if (!cpu.negative()) {
                if (cpu.halfCarry() or (v & 0x0f) > 9) {
                    v = v +% 6;
                }
                if (cpu.carry() or v > 0x9f) {
                    v = v +% 0x60;
                }
            } else {
                if (cpu.halfCarry()) {
                    v = v -% 6;
                    if (!cpu.carry()) {
                        v &= 0xFF;
                    }
                }
                if (cpu.carry()) {
                    v = v -% 0x60;
                }
            }

            cpu.setHalfCarry(false);
            if (v & 0x100 != 0) {
                cpu.setCarry(true);
            }
            cpu.registers.af.setHi(@as(u8, @intCast(v & 0xff)));
            cpu.setZero(cpu.registers.af.hi() == 0);
        },
        0x31 => {
            cpu.sp = arg.u16;
        },
        0x32 => {
            cpu.memory.write(cpu.registers.hl.hilo(), cpu.registers.af.hi());
            cpu.registers.hl.set(cpu.registers.hl.hilo() -% 1);
        },
        0x90...0x97 => { // SUB
            const v = cpu.getRegister(opcode);
            cpu.setCarry(cpu.registers.af.hi() < v);
            cpu.setHalfCarry((cpu.registers.af.hi() & 0x0f) < (v & 0x0f));
            cpu.registers.af.setHi(cpu.registers.af.hi() -% v);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(true);
        },
        0xa8...0xaf => { // XOR
            const v = cpu.getRegister(opcode);
            cpu.registers.af.setHi(cpu.registers.af.hi() ^ v);

            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
            cpu.setHalfCarry(false);
            cpu.setCarry(false);
        },
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
        0x1a => {
            cpu.registers.af.setHi(cpu.memory.read(cpu.registers.de.hilo()));
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
