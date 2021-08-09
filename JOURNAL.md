# Day 1

About a year ago I had begun dabbling in emulation. The space was new to me and
the itch was there through a desire to be reconnected to the video games of my
childhood. I could just as easily *play* those games, but that didn't feel
rewarding. I had this desire to see them come to life through a technically
difficult project that I could accomplish within a meaninful time frame.

Roll back to September 2020. I'm living in Halifax, have a new born, and am
actively on the job hunt. In order to flex my programming muscles I spend the
extremely limited time I have attempting to program a Gameboy emulator, mostly in the
evenings after the kids fall asleep. For the most part, that time is spent wrapping my head around the concepts of emulation:

* Understanding that you're writing software which is "pretending" to be
  hardware
* The concept of clocks, cycles, ticks, how a CPU works, memory maps, etc.

For many evenings, because my work was so sporadic (newborns don't sleep, in
case you weren't aware), I ran in circles around the concepts. Eventually, I
took a break to breathe.

A few rested months later, I decided to revisit emulation and
programmed a simple [CHIP-8 Emulator](https://github.com/bartek/zip-8) using
[Zig](https://ziglang.org/). This proved to be a great opportunity to learn Zig,
a fun language that feels as if it's here to replace C, but also an opportunity
to take those concepts -- of clocks, cycles, cpu, etc. -- and apply them to a
simpler project.

Writing the CHIP-8 emulator validated my understanding and provided me
confidence, which ultimately can lead to an initial piece of advice: Start with
_Hello World!_, and in emulation, that's a CHIP-8 emulator!

And now we're here in the present. Today, I revisit emulating the Game Boy.
Because I enjoyed it so much the first time, I'll be using Zig (I write Go
during my day job and I love the idea of learning a new language each year, so
I'll flex more Zig muscles for this project!)

## CPU





## Appendix

* [Pandocs](https://gbdev.io/pandocs/Specifications.html), a comprehensive
  technical reference for the Game Boy
* 


