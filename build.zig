const std = @import("std");
const Sdk = @import("lib/SDL.zig/Sdk.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const zigboy = b.addExecutable(.{
        .name = "zigboy",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const sdk = Sdk.init(b, null); // SDL2 Init
    sdk.link(zigboy, .dynamic);

    // Add "sdl2" package that exposes the SDL2 api (like SDL_Init or SDL_CreateWindow)
    zigboy.addModule("sdl2", sdk.getNativeModule());
    b.installArtifact(zigboy);

    const run_exe = b.addRunArtifact(zigboy);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
