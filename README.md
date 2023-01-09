# zigboy

:construction: zigboy is a work-in-progress Game Boy emulator written in Zig :construction:

## Why?

I had fun building my [CHIP-8 emulator](https://github.com/bartek/zip-8) using
Zig and now I'm attempting the Game Boy. Of course, it's also an excuse to learn
Zig! Apart from minor dabbling with C++ in college, Zig is my introduction to a
lower level, "systems" language. A desire to get more comfortable with this
space!

## Run

Ensure SDL libraries are installed. For MacOS:

    brew install sdl2

Then:

    zig build run

## TODO

Everything

## References

### Technical Specifications

* [Game Boy Architecture](https://www.copetti.org/writings/consoles/game-boy/#memory-available)
* [Pandoc](https://gbdev.io/pandocs/CPU_Instruction_Set.html)
* [Game Boy CPU Manual](http://marc.rawer.de/Gameboy/Docs/GBCPUman.pdf)
* [Game Boy Bootstrap ROM](https://gbdev.gg8.se/wiki/articles/Gameboy_Bootstrap_ROM)
* [opscode table](https://izik1.github.io/gbops/)
   * [opcode summary](https://www.devrs.com/gb/files/opcodes.html)
* [CPU opcode Reference](https://rgbds.gbdev.io/docs/v0.5.1/gbz80.7#POP_r16)
* [Gameboy logs, to help verify run](https://github.com/wheremyfoodat/Gameboy-logs)

### Presentations

* https://petar-v.com/talks/emulation.pdf

### Blog Posts

* [A journey into Game Boy emulation](https://robertovaccari.com/blog/2020_09_26_gameboy/)
* [emudev.de](emudev.de/gameboy-emulator/getting-started-with-the-cpu/)
* [Writing an emulator](https://blog.tigris.fr/2019/07/28/writing-an-emulator-memory-management/)
* [Deep dive into opcode implementation](https://raphaelstaebler.medium.com/building-a-gameboy-from-scratch-part-2-the-cpu-d6986a5c6c74)
