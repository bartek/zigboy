const std = @import("std");

const fs = std.fs;
const cwd = fs.cwd();
const print = std.debug.print;
const allocPrint = std.fmt.allocPrint;
const File = std.fs.File;

const CPU = @import("./cpu.zig").CPU;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

// State is a representation of current Gameboy state for the purposes of
// debugging
pub const State = struct {
    pub const Capacity = 20;

    debug: bool,

    container: ArrayList([]u8),
    instructions: ArrayList([]const u8),
    log_file: *File,
    cpu: *CPU,

    pub fn init(allocator: Allocator, cpu: *CPU, log_file: *File, debug: bool) !State {
        return State{
            .debug = debug,
            .cpu = cpu,
            .log_file = log_file,
            .container = ArrayList([]u8).init(allocator),
            .instructions = ArrayList([]const u8).init(allocator),
        };
    }

    // Returns a slice of the entire container
    pub fn current(self: State) [][]u8 {
        return self.container.items[0..];
    }

    pub fn instrs(self: State) []u8 {
        return self.instructions.items[0..];
    }

    pub fn top(self: State) []u8 {
        return self.container.items[self.container.items.len - 1];
    }

    // append writes debug information to the debug container
    // Matches format at https://github.com/wheremyfoodat/Gameboy-logs
    // to allow for programmatic comparison.
    pub fn append(self: *State) !void {
        if (self.debug) {}
        //var mem: u8 = self.cpu.memory.read(self.cpu.pc);
        //var mem1: u8 = self.cpu.memory.read(self.cpu.pc + 1);
        //var mem2: u8 = self.cpu.memory.read(self.cpu.pc + 2);
        //var mem3: u8 = self.cpu.memory.read(self.cpu.pc + 3);

        //const buf = allocPrint(std.heap.page_allocator, "A: {X:0>2} " ++
        //    "F: {X:0>2} " ++
        //    "B: {X:0>2} " ++
        //    "C: {X:0>2} " ++
        //    "D: {X:0>2} " ++
        //    "E: {X:0>2} " ++
        //    "H: {X:0>2} " ++
        //    "L: {X:0>2} " ++
        //    "SP: {X:0>4} " ++
        //    "PC: 00:{X:0>4} " ++
        //    "({X:0>2} {X:0>2} {X:0>2} {X:0>2})\n", .{ self.cpu.af.hi(), self.cpu.af.lo(), self.cpu.bc.hi(), self.cpu.bc.lo(), self.cpu.de.hi(), self.cpu.de.lo(), self.cpu.hl.hi(), self.cpu.hl.lo(), self.cpu.sp, self.cpu.pc, mem, mem1, mem2, mem3 }) catch |err| {
        //    print("{!}", .{err});
        //    return;
        //};

        //try self.container.append(buf);

        //// If the container is over capacity, reduce it
        //if (self.container.items.len > Capacity) {
        //    _ = self.container.orderedRemove(0);
        //}

        //if (self.debug) {
        //    _ = try self.log_file.writeAll(buf);
        //}
    }

    pub fn append_instruction(self: *State, instr: []const u8) void {
        self.instructions.append(instr) catch unreachable;

        if (self.instructions.items.len > Capacity) {
            _ = self.instructions.orderedRemove(0);
        }
    }
};
