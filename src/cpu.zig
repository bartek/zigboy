const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const register = struct {
    value: u16,

    pub fn setLo(self: *register, value: u8) void {
        self.value = u16(value) | u16(self.value)&0xFF00;
    }

    pub fn setHi(self: *register, value: u8) void {
        self.value = u16(val)<<8 | (u16(self.value) & 0xFF);
    }
};


pub const Memory = struct {
    // GameBoy contains an 8-bit processor, meaning it can access 8-bits of data
    // at one time. To access this data, it has a 16-bit address bus, which can
    // address 65,536 positions of memory.
    const memory_size = 65536;

    allocator: *Allocator,
    memory: []u8,

    pub fn init(allocator: *Allocator) !Memory {
        return Memory{
            .allocator = allocator,
            .memory = try allocator.alloc(u8, memory_size),
        };
    }

    pub fn deinit(self: *Memory) void {
        self.allocator.free(self.memory);
    }

    pub fn read(self: *Memory, address: u16) u8 {
        return self.memory[address];
    }

    pub fn write(self: *Memory, address: u16, value: u8) void {
        self.memory[address] = value;
    }

    pub fn loadRom(self: *Memory, buffer: []u8) !void {
        for (buffer) |b, index| {
            self.write(@intCast(u16, index), b);
        }
    }
};

// The GameBoy CPU is composed of 8 different registers which are responsible
// for holding onto little pieces of data that the CPU can manipulate when it
// executes various instructions. These registers are named A, B, C, D, E, F, H,
// and L. Since they are 8-bit registers, they can hold only 8-bit values.
// However, the GameBoy can combine two registers in order to read and write
// 16-bit values. The valid combinations then are AF, BC, DE, and HL.
pub const CPU = struct {
    af: register,
    bc: register,
    de: register,
    hl: register,

    // Program Counter
    pc: u16,

    // Stack Pointer
    sp: u16,

    memory: Memory,

    pub fn init(allocator: *Allocator) !CPU {
        return CPU{
            .memory = try Memory.init(allocator),
            .af = undefined,
            .bc = undefined,
            .de = undefined,
            .hl = undefined,
            .pc = 0x00,
            .sp = undefined,
        };
    }

    pub fn deinit(self: *CPU) void {
        self.memory.deinit();
    }

    // tick ticks the CPU
    pub fn tick(self: *CPU) void{ 
        var opcode = self.fetch();
        self.execute(opcode);
    }

    pub fn fetch(self: *CPU) u16 {
        // read from memory
        // increment pc
        // return opcode
        var opcode: u16 = self.memory.read(self.pc);
        self.pc += 1;
        return opcode;
    }


    pub fn execute(self: *CPU, opcode: u16) void {
        print("0x{x}", .{opcode});
        // execute opcode
    }
};

test "CPU" {
    var cpu = try CPU.init(std.heap.page_allocator);
    cpu.tick();
    cpu.deinit();
}
