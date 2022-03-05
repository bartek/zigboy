const SDL = @import("sdl2");
const std = @import("std");

const Atomic = std.atomic.Atomic;
const cwd = fs.cwd();
const eql = std.mem.eql;
const fs = std.fs;
const print = std.debug.print;
const warn = std.log.warn;

const stdin = std.io.getStdIn().reader();

const c = @import("./cpu.zig");
const gameboy = @import("./gameboy.zig");
const State = @import("./state.zig").State;

const scale = 2;
const width = 160;
const height = 144;

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var debug: bool = false;

    // Identify args
    var args = std.process.args();
    while (args.next(allocator)) |error_or_arg| {
        const arg = error_or_arg catch |err| {
            warn("Error parsing arguments: {s}", .{err});
            return err;
        };
        if (eql(u8, arg, "-d")) {
            debug = true;
        }
    }

    var cpu = try c.CPU.init(allocator);

    // Atomics
    var done = Atomic(bool).init(false);

    // Load Tetris into memory
    const buffer = cwd.readFileAlloc(allocator, "./roms/tetris.gb", 32768) catch |err| {
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
    const thread_gb = try std.Thread.spawn(.{}, gameboy.runThread, .{ &done, &cpu, &state });
    defer thread_gb.join();

    // Initialize SDL
    const status = SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO | SDL.SDL_INIT_GAMECONTROLLER);
    if (status < 0) sdlPanic();
    defer SDL.SDL_Quit();

    var title_buf: [0x20]u8 = [_]u8{0x00} ** 0x20;
    const title = try std.fmt.bufPrint(&title_buf, "zigboy", .{});

    var window = SDL.SDL_CreateWindow(
        title.ptr,
        SDL.SDL_WINDOWPOS_CENTERED,
        SDL.SDL_WINDOWPOS_CENTERED,
        width * scale,
        height * scale,
        SDL.SDL_WINDOW_SHOWN,
    ) orelse sdlPanic();
    defer SDL.SDL_DestroyWindow(window);

    var renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
    defer SDL.SDL_DestroyRenderer(renderer);

    const texture = SDL.SDL_CreateTexture(renderer, SDL.SDL_PIXELFORMAT_BGR555, SDL.SDL_TEXTUREACCESS_STREAMING, 240, 160) orelse sdlPanic();
    defer SDL.SDL_DestroyTexture(texture);

    var i: usize = 0;
    game_loop: while (true) : (i += 1) {
        var event: SDL.SDL_Event = undefined;

        if (SDL.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                SDL.SDL_QUIT => break :game_loop,
                else => {},
            }
        }

        _ = SDL.SDL_RenderCopy(renderer, texture, null, null);
        SDL.SDL_RenderPresent(renderer);
    }

    done.store(true, .Unordered);
}

fn quickSleep() void {
    std.time.sleep(500 * std.time.ns_per_ms);
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown sdl error";
    @panic(std.mem.sliceTo(str, 0));
}
