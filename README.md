# DirtyRat DOS Mouse Driver

DirtyRat is a small open source DOS mouse driver that works with the [ISA Blaster](https://github.com/scrapcomputing/ISABlaster) DirtyRat USB Mouse adapter project.
The TSR has a very small footprint of almost 3KB and should work with 8088/8086 CPUs.

Please note that it won't work with a regular serial or PS/2 mouse.

DirtyRat is a modified version of the CuteMouse DOS driver based on [Davide Bresolin's version](https://github.com/davidebreso/ctmouse) that can be compiled with JWasm 2.12 on a modern Linux or Mac host, and is compatible with 8088/8086 CPUs.

The original CuteMouse driver project was developed from 1997 to 2009 by Nagy Daniel, Eric Auer, and many others. The project is hosted on [SourceForge](https://cutemouse.sourceforge.net) and released under the terms of the GNU General Public License (GPL).

# Download

DOS Binaries for the driver `drtrat.exe` and the protocol utility `drtproto.exe` are available in the releases: https://github.com/scrapcomputing/DirtyRatDriver/releases

# Build instructions

- Make sure your system has [JWasm 2.12](https://www.japheth.de/JWasm.html) installed
- And also make sure that `jwasm` is in your PATH, for example in bash: `export PATH=$PATH:<path/to/jwasm>`
- Change to the project directory and run `make`
- This should produce two DOS executables:
  - `drtrat.exe` which is the mouse driver, and
  - `utility/drtproto.exe` which is a helper tool that dumps the binary data sent by the mouse

# How to use

- In DOS run: `drtrat.exe`. This installs the TSR with the default configuration.
- `drtrat.exe /?` lists the available options
- You can override the default I/O address with `/A`. For example, `/A2e9` sets the I/O address to `0x2e9`.
- You can override the default IRQ with `/I`. For example, `/I4` sets the IRQ to `4`.

# License

* CuteMouse and this repository as a whole are distributed under the terms of the GPL version 2. See the `LICENSE` file for more details.
* `bin2exe.c` is a modified version of the `bin2exe` utility included in [booterify](https://github.com/raphnet/booterify), developed by Raphaël Assenat and distributed under the MIT License.

