const std = @import("std");
const Sdk = @import("lib/SDL.zig/Sdk.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Zig SDL Bindings
    const sdk = Sdk.init(b);

    const exe = b.addExecutable("zigboy", "src/main.zig");

    exe.setTarget(target);
    sdk.link(exe, .dynamic);

    // Add "sdl2" package that exposes the SDL2 api (like SDL_Init or SDL_CreateWindow)
    exe.addPackage(sdk.getNativePackage("sdl2"));

    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
