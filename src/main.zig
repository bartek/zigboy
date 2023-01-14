const SDL = @import("sdl2");
const std = @import("std");

const Atomic = std.atomic.Atomic;
const cwd = fs.cwd();
const eql = std.mem.eql;
const fs = std.fs;
const print = std.debug.print;
const warn = std.log.warn;

const stdin = std.io.getStdIn().reader();

const CPU = @import("./cpu.zig").CPU;
const Fetcher = @import("./fetcher.zig").Fetcher;
const Memory = @import("./memory.zig").Memory;
const PPU = @import("./ppu.zig").PPU;
const Screen = @import("./screen.zig").Screen;
const State = @import("./state.zig").State;
const gameboy = @import("./gameboy.zig");

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var debug: bool = true;

    // Load screen (SDL)
    var screen = try Screen.init();
    defer screen.deinit();

    // Load PPU
    var ppu = try PPU.init(&screen);

    // Prepare memory
    var memory = try Memory.init(allocator, &ppu);

    // Prepare fetcher
    var fetcher = try Fetcher.init(&memory);
    ppu.fetcher = fetcher;

    // Load CPU
    var cpu = try CPU.init(&memory);

    // Atomics
    var done = Atomic(bool).init(false);

    // Load rom into memory
    const buffer = cwd.readFileAlloc(allocator, "./roms/06-ld r,r.gb", 65536) catch |err| {
        warn("unable to open file: {s}\n", .{@errorName(err)});
        return err;
    };

    try cpu.memory.loadRom(buffer);

    // Initialize log file
    var log_file = try cwd.createFile("./debug/log.txt", .{});
    defer log_file.close();

    // State is a connection between modules for debugging, useful things
    var state = try State.init(allocator, &cpu, &log_file, debug);

    // Create a separate thread for the emulator to run
    const thread_gb = try std.Thread.spawn(.{}, gameboy.run_thread, .{ &done, &cpu, &ppu, &state });
    defer thread_gb.join();

    var i: usize = 0;
    game_loop: while (true) : (i += 1) {
        var event: SDL.SDL_Event = undefined;

        if (SDL.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                SDL.SDL_QUIT => break :game_loop,
                else => {},
            }
        }
    }

    done.store(true, .Unordered);
}

fn quickSleep() void {
    std.time.sleep(500 * std.time.ns_per_ms);
}
