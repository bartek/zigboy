const std = @import("std");
const SDL = @import("sdl2");

const width = 160;
const height = 144;
const scale = 2;

const palette = [4][4]u8{
    [_]u8{ 0xe0, 0xf0, 0xe7, 0xff }, // White
    [_]u8{ 0x8b, 0xa3, 0x94, 0xff }, // Light Gray
    [_]u8{ 0x55, 0x64, 0x5a, 0xff }, // Dark gray
    [_]u8{ 0x34, 0x3d, 0x37, 0xff }, // Black
};

// Screen contains the video game screen and debug info.
pub const Screen = struct {
    const Self = @This();

    // window is the pointer to the SDL Window
    window: *SDL.SDL_Window,
    debugWindow: *SDL.SDL_Window,

    // renderer is the pointer to the SDL Renderer
    renderer: *SDL.SDL_Renderer,
    debugRenderer: *SDL.SDL_Renderer,

    // texture is the pointer to the SDL Texture
    texture: *SDL.SDL_Texture,
    debugTexture: *SDL.SDL_Texture,

    // buffer is the texture buffer for the current frame
    // 160x144 pixels stored using 4 bytes per pixel (as per RGBA32) gives us
    // the exact size we need for the buffer.
    buffer: [width * height * 4]u8 = undefined,

    // offset is where new pixel data should be written into the buffer
    offset: usize = 0,

    pub fn init() !Self {
        // Initialize SDL
        const status = SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO | SDL.SDL_INIT_GAMECONTROLLER);
        if (status < 0) sdlPanic();

        var title_buf: [0x20]u8 = [_]u8{0x00} ** 0x20;
        const title = try std.fmt.bufPrint(&title_buf, "zigboy", .{});

        var debugWindow = SDL.SDL_CreateWindow(
            title.ptr,
            SDL.SDL_WINDOWPOS_CENTERED,
            SDL.SDL_WINDOWPOS_CENTERED,
            width * scale,
            height * scale,
            SDL.SDL_WINDOW_SHOWN,
        ) orelse sdlPanic();

        var window = SDL.SDL_CreateWindow(
            title.ptr,
            SDL.SDL_WINDOWPOS_CENTERED,
            SDL.SDL_WINDOWPOS_CENTERED,
            width * scale,
            height * scale,
            SDL.SDL_WINDOW_SHOWN,
        ) orelse sdlPanic();

        var renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
        var debugRenderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();

        const texture = SDL.SDL_CreateTexture(renderer, SDL.SDL_PIXELFORMAT_BGR555, SDL.SDL_TEXTUREACCESS_STREAMING, width, height) orelse sdlPanic();

        // Text surface for fonts, which we use for displaying the debug pane.
        var color = SDL.SDL_Color{ .r = 0xff, .g = 0xff, .b = 0xff, .a = 0xff };
        var font = SDL.TTF_OpenFont("assets/B612Mono-Bold.ttf", 16) orelse sdlPanic();
        var textSurface = SDL.TTF_RenderText_Solid(font, "Hello, world!", color) orelse sdlPanic();

        var debugTexture = SDL.SDL_CreateTextureFromSurface(debugRenderer, textSurface) orelse sdlPanic();

        //SDL.SDL_FreeSurface(debugSurface);
        return Self{
            .window = window,
            .texture = texture,
            .renderer = renderer,

            .debugWindow = debugWindow,
            .debugRenderer = debugRenderer,
            .debugTexture = debugTexture,
        };
    }

    // write adds a new pixel to the texture buffer
    // the pixel is an index into the palette
    pub fn write(self: *Self, index: u8) void {
        var color = palette[index];
        self.buffer[0 + self.offset] = color[0];
        self.buffer[1 + self.offset] = color[1];
        self.buffer[2 + self.offset] = color[2];
        self.buffer[3 + self.offset] = color[3];
        self.offset += 4;
    }

    pub fn hblank(self: *Self) void {
        _ = self;
        // noop; can we remove?
    }

    // vblank is called when the PPU reaches VBlank state. At this point, the
    // SDL buffer is ready for display.
    pub fn vblank(self: *Self) void {
        std.debug.print("vblank", .{});
        _ = SDL.SDL_UpdateTexture(self.texture, null, &self.buffer, width * 4);
        _ = SDL.SDL_RenderCopy(self.renderer, self.texture, null, null);
        self.offset = 0;

        SDL.SDL_RenderPresent(self.renderer);
        SDL.SDL_RenderPresent(self.debugRenderer);
    }

    pub fn deinit(self: *Self) void {
        SDL.SDL_Quit();
        SDL.SDL_DestroyWindow(self.window);
        SDL.SDL_DestroyWindow(self.debugWindow);
        SDL.SDL_DestroyRenderer(self.renderer);
        SDL.SDL_DestroyRenderer(self.debugRenderer);
        SDL.SDL_DestroyTexture(self.texture);
    }
};

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown sdl error";
    @panic(std.mem.sliceTo(str, 0));
}
