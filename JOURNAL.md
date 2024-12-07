## Testing 

https://github.com/adtennant/GameboyCPUTests/blob/master/v2/README.md

Each file tests a single opcode.
You need to parse the JSON into an array of test cases per file.
For each test case, you'll instantiate your CPU based on the initial state from the test case.
Then you'll fetch and execute a single instruction.
Once you're done, you'll compare your CPU to the expected state.
If there are any mismatches, log the initial, expected, and actual state of your CPU, all three in full.
If you're going for cycle accuracy, you can use the expected cyclesvalues to compare to your own


## Day 3

See instruction table:

https://github.com/tiehuis/zig-gameboy/blob/master/src/cpu.zig

Inspiration:

https://compilerbook.com

Write the book, the emulator. It's possible! 

## Day 2 std.io.InStream

What is this and how does it work for the CPU? It looks like it's been removed as of  zig 0.13, so what is the updated canonical means of implementing the same behaviour?

# Day 1 - Second Attempt, Second Time

Maybe now? Motivation is rising, winter is here!

https://github.com/isaachier/gbemu/blob/master/src/cpu.zig

What's this Stream concept? Looks interesting.

Also, adding tests to CPU file before I go any further. Helpful.

# Day 0 - Second Attempt

Revisiting the emulator two years later. Let's try and get this project off the ground!

Goal is to get a CPU running that has actual unit tests. Last time flying blind was brutal. No unit tests, no way to know if the CPU was doing the right thing. This killed progress when trying to implement the PPU etc.

Inspiration: https://www.reddit.com/r/EmuDev/comments/1c2rls3/the_start_of_my_nes_emulator/

Are there JSON tests for GameBoy? Yes, this is likely what I want. Blargg is an integration test and hurt my progress as well.


# Day 2

It's been awhile since Day 1 and I'll pretend that a year did not pass since.

For today's note, I want to describe an ever important debug line:

```
A: F5 F: 10 B: 01 C: 10 D: C1 E: 00 H: 41 L: 00 SP: FFFE PC: 00:020C (0D 20 F7 78)
```

Without worrying about the particulars, this is the defacto standard log line
when debugging the CPU. In this line, we display the values of all registers
and read memory at the upcoming PC, as well as the following three.

There are a [variety of logs](https://github.com/wheremyfoodat/Gameboy-logs) from working emulators which output 
in this format; these come from running [blargg test roms](https://github.com/L-P/blargg-test-roms/tree/master/cpu_instrs).

With this knowledge combined, I can take the output of my emulator and do a line-by-line review between my emulator and the working one. Of course, doing this manually is not ideal, so a simple script can help:

```
#!/bin/bash

file1=$1
file2=$2

# Compare the files line by line
i=0;
while IFS= read -r line1 && IFS= read -r line2 <&3; do
    i=$((i+1))
    if [ "$line1" != "$line2" ]; then
        echo "${i} Line differs:"
        echo "> $line1"
        echo "< $line2"
    fi
done <"$file1" 3<"$file2"

# Handle error cases
if [ $? -ne 0 ]; then
    echo "Error: Either $file1 or $file2 does not exist or is empty"
fi
```
This approach helped me pinpoint where errors existed within my CPU
instructions. Once I identified the line, I would observe the first value in
the brackets (e.g. `(0D ...)`) and review the instruction I've written for it.
In all cases when debugging my CPU, my issue was that the instruction was
incorrectly implemented.

At this point, I have an emulator which matches the log output of #6 (blargg
test rom). Next step is to get the actual output of the blargg rom showing up,
my emulator doesn't ever seem to write to the serial port (0xff01)


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

## Appendix

* [Pandocs](https://gbdev.io/pandocs/Specifications.html), a comprehensive
  technical reference for the Game Boy
