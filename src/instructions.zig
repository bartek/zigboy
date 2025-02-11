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
    0, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 1
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
        0x2a => {
            cpu.registers.af.setHi(cpu.memory.read(cpu.registers.hl.hilo()));
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
        0x3f => { // CCF
            cpu.setNegative(false);
            cpu.setHalfCarry(false);
            cpu.setCarry(!cpu.carry());
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
        0x1f => { // RRA
            const carry: u8 = if (cpu.carry()) 1 else 0;
            cpu.setCarry((cpu.registers.af.hi() & 1) != 0);
            cpu.registers.af.setHi((cpu.registers.af.hi() >> 1) | (carry << 7));

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
        0x80...0x87 => { // ADD A,r
            const v = cpu.getRegister(opcode);
            const res: i16 = @as(i16, @intCast(cpu.registers.af.hi())) +% @as(i16, @intCast(v));
            cpu.setHalfCarry((cpu.registers.af.hi() & 0x0f) + (v & 0x0f) > 0x0f);
            cpu.setCarry(res > 0xff);
            cpu.registers.af.setHi(cpu.registers.af.hi() +% v);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
        },
        0xc4 => { // CALL NZ,u16
            if (!cpu.zero()) {
                cpu.pushStack(cpu.pc +% 2);
                cpu.pc = arg.u16;
            }
        },
        0xce => { // ADC A,u8
            const carry: u8 = if (cpu.carry()) 1 else 0;
            const res: i16 = @as(i16, @intCast(cpu.registers.af.hi())) +% @as(i16, @intCast(arg.u8)) +% @as(i16, @intCast(carry));
            cpu.setHalfCarry((cpu.registers.af.hi() & 0x0f) + (arg.u8 & 0x0f) + carry > 0x0f);
            cpu.setCarry(res > 0xff);
            cpu.registers.af.setHi(cpu.registers.af.hi() +% arg.u8 +% carry);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
        },
        0x88...0x8f => { // ADC A,r
            const v = cpu.getRegister(opcode);
            const carry: u8 = if (cpu.carry()) 1 else 0;
            const res: i16 = @as(i16, @intCast(cpu.registers.af.hi())) +% @as(i16, @intCast(v)) +% @as(i16, @intCast(carry));
            cpu.setHalfCarry((cpu.registers.af.hi() & 0x0f) + (v & 0x0f) + carry > 0x0f);
            cpu.setCarry(res > 0xff);
            cpu.registers.af.setHi(cpu.registers.af.hi() +% v +% carry);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
        },
        0xb8...0xbf => { // CP r
            const v = cpu.getRegister(opcode);
            const a: u8 = cpu.registers.af.hi();
            const total: u8 = a -% v;

            cpu.setZero(total == 0);
            cpu.setNegative(true);
            cpu.setHalfCarry((a & 0x0f) < (v & 0x0f));
            cpu.setCarry(a < v);
        },
        0x90...0x97 => { // SUB A,r
            const v = cpu.getRegister(opcode);
            cpu.setCarry(cpu.registers.af.hi() < v);
            cpu.setHalfCarry((cpu.registers.af.hi() & 0x0f) < (v & 0x0f));
            cpu.registers.af.setHi(cpu.registers.af.hi() -% v);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(true);
        },
        0x98...0x9f => { // SBC A,r
            const v = cpu.getRegister(opcode);
            const carry: u8 = if (cpu.carry()) 1 else 0;
            const res: i16 = @as(i16, @intCast(cpu.registers.af.hi())) -% @as(i16, @intCast(v)) -% @as(i16, @intCast(carry));
            cpu.setHalfCarry((cpu.registers.af.hi() ^ v ^ (res & 0x0ff)) & (1 << 4) != 0);
            cpu.setCarry(res < 0);
            cpu.registers.af.setHi(cpu.registers.af.hi() -% v -% carry);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(true);
        },
        0xd2 => { // JP NC,u16
            if (!cpu.carry()) {
                cpu.pc = arg.u16;
            }
        },
        0xde => { // SBC A,u8
            const carry: u8 = if (cpu.carry()) 1 else 0;
            const res: i16 = @as(i16, @intCast(cpu.registers.af.hi())) -% @as(i16, @intCast(arg.u8)) -% @as(i16, @intCast(carry));
            cpu.setHalfCarry(((cpu.registers.af.hi() ^ arg.u8 ^ (res & 0x0ff)) & (1 << 4)) != 0);
            cpu.setCarry(res < 0);
            cpu.registers.af.setHi(cpu.registers.af.hi() -% arg.u8 -% carry);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(true);
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
        0xa => { // LD A,(BC)
            cpu.registers.af.setHi(cpu.memory.read(cpu.registers.bc.hilo()));
        },
        0xa8...0xaf => { // XOR
            const v = cpu.getRegister(opcode);
            cpu.registers.af.setHi(cpu.registers.af.hi() ^ v);

            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
            cpu.setHalfCarry(false);
            cpu.setCarry(false);
        },
        0xa0...0xa7 => { // AND A,u8
            const v = cpu.getRegister(opcode);
            cpu.registers.af.setHi(cpu.registers.af.hi() & v);

            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
            cpu.setHalfCarry(true);
            cpu.setCarry(false);
        },
        0xf3 => { // DI
            cpu.interrupts = false;
        },
        0xe2 => {
            cpu.memory.write(0xff00 | @as(u16, cpu.registers.bc.lo()), cpu.registers.af.hi());
        },
        0xe9 => { // JP HL
            cpu.pc = cpu.registers.hl.hilo();
        },
        0x1a => {
            cpu.registers.af.setHi(cpu.memory.read(cpu.registers.de.hilo()));
        },
        0xf => { // LD A,(FF00+u8)
            cpu.registers.af.setHi(cpu.memory.read(@as(u16, @intCast(0xFF00)) + arg.u8));
        },
        0xf2 => { // LD A,(FF00+C)
            cpu.registers.af.setHi(cpu.memory.read(@as(u16, @intCast(0xFF00)) + cpu.registers.bc.lo()));
        },
        0xfe => { // CP A,u8
            const v = arg.u8;
            const a: u8 = cpu.registers.af.hi();
            const total: u8 = a -% v;

            cpu.setZero(total == 0);
            cpu.setNegative(true);
            cpu.setHalfCarry((a & 0x0f) < (v & 0x0f));
            cpu.setCarry(a < v);
        },
        0xc3 => {
            cpu.pc = arg.u16;
        },
        0xc8 => { // RET Z
            if (cpu.zero()) {
                cpu.pc = cpu.pop();
            }
        },
        0xc9 => { // RET
            cpu.pc = cpu.pop();
        },
        0xcc => { // CALL Z,u16
            if (cpu.zero()) {
                cpu.pushStack(cpu.pc);
                cpu.pc = arg.u16;
            }
        },
        0xcd => {
            cpu.pushStack(cpu.pc);
            cpu.pc = arg.u16;
        },
        0xd8 => { // RET C
            if (cpu.carry()) {
                cpu.pc = cpu.pop();
            }
        },
        0xd9 => { // RETI
            cpu.pc = cpu.pop();
            cpu.interrupts = true;
        },
        0xdc => { // CALL C,u16
            if (cpu.carry()) {
                cpu.pushStack(cpu.pc);
                cpu.pc = arg.u16;
            }
        },
        0xee => { // XOR A,u8
            cpu.registers.af.setHi(cpu.registers.af.hi() ^ arg.u8);
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setCarry(false);
            cpu.setNegative(false);
            cpu.setHalfCarry(false);
        },
        0xb0...0xb7 => { // OR
            cpu.registers.af.setHi(cpu.registers.af.hi() | cpu.getRegister(opcode));
            cpu.setZero(cpu.registers.af.hi() == 0);
            cpu.setNegative(false);
            cpu.setCarry(false);
            cpu.setHalfCarry(false);
        },
        0x3a => {
            cpu.registers.af.setHi(cpu.memory.read(cpu.registers.hl.hilo()));
            cpu.registers.hl.set(cpu.registers.hl.hilo() -% 1);
        },
        0x3e => { // LD A,u8
            cpu.registers.af.setHi(arg.u8);
        },
        0xc2 => {
            if (!cpu.zero()) {
                cpu.pc = arg.u16;
            }
        },
        0xc7 => {
            cpu.pushStack(cpu.pc);
            cpu.pc = 0x00;
        },
        0xc0 => {
            if (!cpu.zero()) {
                cpu.pc = cpu.pop();
            }
        },
        0xf0 => {
            cpu.registers.af.setHi(cpu.memory.read(@as(u16, @intCast(0xff00)) + arg.u8));
        },
        0xf5 => { // PUSH AF
            cpu.pushStack(cpu.registers.af.hilo());
        },
        0xc5 => { // PUSH BC
            cpu.pushStack(cpu.registers.bc.hilo());
        },
        0xd5 => { // PUSH DE
            cpu.pushStack(cpu.registers.de.hilo());
        },
        0xe5 => { // PUSH HL
            cpu.pushStack(cpu.registers.hl.hilo());
        },
        0xe8 => { // ADD SP,i8
            const v: u16 = @as(u16, @intCast(@as(i64, @intCast((@as(i32, @intCast(cpu.sp)) + arg.i8))) & 0xFFFF));
            cpu.setHalfCarry(((cpu.sp ^ @as(u16, @bitCast(@as(i16, @intCast(arg.i8)))) ^ v) & 0x10) != 0);
            cpu.setCarry(((cpu.sp ^ @as(u16, @bitCast(@as(i16, @intCast(arg.i8)))) ^ v) & 0x100) != 0);
            cpu.setZero(false);
            cpu.setNegative(false);
            cpu.sp = v;
        },
        0xd4 => {
            if (!cpu.carry()) {
                cpu.pushStack(arg.u16);
                cpu.pc = arg.u16;
            }
        },
        0xf8 => { // LD HL,SP+i8 // TODO: Skipped for now as failing
            const v = @as(i32, @intCast(cpu.sp)) + arg.i8;
            if (arg.i8 >= 0) {
                cpu.setCarry((@as(i32, @intCast(cpu.sp & 0xFF)) + (arg.i8)) > 0xFF);
                cpu.setHalfCarry((@as(i32, @intCast(cpu.sp & 0x0F)) + (arg.i8 & 0x0F)) > 0x0F);
            } else {
                cpu.setCarry((v & 0xFF) <= (cpu.sp & 0xFF));
                cpu.setHalfCarry((v & 0x0F) <= (cpu.sp & 0x0F));
            }
            cpu.registers.hl.set(@as(u16, @intCast(v)));
            cpu.setZero(false);
            cpu.setNegative(false);
        },
        0xf9 => {
            cpu.sp = cpu.registers.hl.hilo();
        },
        // Misc Instructions
        0x2f => { // CPL
            cpu.registers.af.setHi(cpu.registers.af.hi() ^ 0xff);
            cpu.setNegative(true);
            cpu.setHalfCarry(true);
        },
        0xfb => { // EI
            cpu.interrupts = true;
        },
        else => {
            panic("\n!! not implemented 0x{x}\n", .{opcode});
        },
    };
}
