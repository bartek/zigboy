const std = @import("std");
const Atomic = std.atomic.Value;

const Memory = @import("./memory.zig").Memory;
const SM83 = @import("./cpu.zig").SM83;
const gameboy = @import("./gameboy.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var memory = try Memory.init(allocator);
    var cpu = try SM83.init(&memory);
    var done = Atomic(bool).init(false);

    // Create a separate thread for the emulator to run
    const thread_gb = try std.Thread.spawn(.{}, gameboy.run_thread, .{ &done, &cpu });
    defer thread_gb.join();

    var i: usize = 0;
    // Run
    while (true) : (i += 1) {
        // _
    }

    done.store(true, .Unordered);

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
