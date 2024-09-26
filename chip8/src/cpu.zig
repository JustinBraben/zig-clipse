const std = @import("std");
const Bitmap = @import("bitmap.zig").Bitmap;
const Display = @import("display.zig").Display;

pub const CPU = struct {
    const Self = @This();

    /// Memory represents the RAM used by the emulator.
    memory: *[]u8,

    /// Bitmap represents the display buffer for drawing graphics.
    bitmap: *Bitmap,

    /// Display is responsible for handling screen rendering.
    display: *Display,

    /// Program counter (PC) keeps track of the currently executing instruction.
    pc: u16, // Program counter

    /// Index register (I) is used for memory address operations.
    i: u16,

    /// Delay timer (DT) decrements at a rate of 60Hz when not zero.
    dtimer: u8,

    /// Sound timer (ST) decrements at a rate of 60Hz and plays a sound when not zero.
    stimer: u8,

    /// General-purpose registers (V0 to VF) used for various operations.
    v: [16]u8,

    /// Stack stores the program counter when a subroutine is called.
    stack: [16]u16,

    /// Stack index represents the current level of the stack.
    stack_idx: u8,

    /// Paused indicates whether the emulator is currently paused.
    paused: bool,

    /// Paused_x is the index of the paused opcode for debugging purposes.
    paused_x: u8,

    /// Speed represents the speed multiplier for the emulator (e.g., 2x speed).
    speed: u8,

    pub fn init(
        memory: *[]u8, // Pointer to device memory
        bitmap: *Bitmap,
        display: *Display,
    ) Self {
        return Self{
            .memory = memory,
            .bitmap = bitmap,
            .display = display,
            .pc = 0x200, // ROMs are loaded in at 0x200 so this is where the PC will be
            .i = 0,
            .dtimer = 0,
            .stimer = 0,
            .v = std.mem.zeroes([16]u8), // Create zero-initialized filled array
            .stack = std.mem.zeroes([16]u16),
            .stack_idx = 0,
            .paused = false,
            .paused_x = 0, // For storing key press after un-pausing
            .speed = 10,
        };
    }

    pub fn tick(self: *Self) void {
        if (self.paused) {
            var index: u8 = 0;
            while (index < 16) : (index += 1) {
                if (self.display.keys[index]) {
                    self.paused = false;
                    self.v[self.paused_x] = index;
                }
            }
        }

        // No running instructions
        // While the emulator is paused
        // Can't squash this into one check for !self.puased
        // Emulator needs to attempt to cycle through this each tick
        var i: u8 = 0;
        while (i < self.speed) : (i += 1) {
            if (!self.paused) {
                // CHIP-8 opcodes are two bytes long
                // .* is used to dereference pointers in Zig
                const opcode: u16 = (@as(u16, self.memory.*[self.pc]) << 8 | @as(u16, self.memory.*[self.pc + 1]));
                self.executeInstruction(opcode);
            }
        }

        if (!self.paused) {
            self.updateTimers();
        }

        self.playSound();
    }

    /// Update timers
    fn updateTimers(self: *Self) void {
        if (self.dtimer > 0) self.dtimer -= 1;
        if (self.stimer > 0) self.stimer -= 1;
    }

    fn playSound(self: *Self) void {
        if (self.stimer > 0) {
            // TODO
        } else {
            // TODO
        }
    }

    /// Push address to stack
    fn stackPush(self: *Self, address: u16) void {
        if (self.stack_idx > 15) return;

        self.stack[self.stack_idx] = address;
        self.stack_idx += 1;
    }

    fn stackPop(self: *Self) u16 {
        if (self.stack_idx == 0) return 0;

        const value = self.stack[self.stack_idx - 1];
        self.stack_idx -= 1;
        return value;
    }

    /// Execute opcode
    fn executeInstruction(self: *Self, opcode: u16) void {
        self.pc += 2;

        const x = (opcode & 0x0F00) >> 8;
        const y = (opcode & 0x00F0) >> 4;

        // Big 'ol opcode switch
        switch (opcode & 0xF000) {
            0x0000 => {
                switch (opcode) {
                    0x00E0 => {
                        self.bitmap.clear(0);
                    },
                    0x00EE => {
                        self.pc = self.stackPop();
                    },
                    else => {},
                }
            },
            0x1000 => {
                self.pc = (opcode & 0xFFF);
            },
            0x2000 => {
                self.stackPush(self.pc);
                self.pc = (opcode & 0xFFF);
            },
            0x3000 => {
                if (self.v[x] == (opcode & 0xFF)) self.pc += 2;
            },
            0x4000 => {
                if (self.v[x] != (opcode & 0xFF)) self.pc += 2;
            },
            0x5000 => {
                if (self.v[x] == self.v[y]) self.pc += 2;
            },
            0x6000 => {
                self.v[x] = @as(u8, @truncate(opcode & 0xFF));
            },
            0x7000 => {
                self.v[x] +%= @as(u8, @truncate(opcode & 0xFF));
            },
            0x8000 => {
                switch (opcode & 0xF) {
                    0x0 => {
                        self.v[x] = self.v[y];
                    },
                    0x1 => {
                        self.v[x] |= self.v[y];
                        self.v[0xF] = 0;
                    },
                    0x2 => {
                        self.v[x] &= self.v[y];
                        self.v[0xF] = 0;
                    },
                    0x3 => {
                        self.v[x] ^= self.v[y];
                        self.v[0xF] = 0;
                    },
                    0x4 => {
                        const sum: u32 = (@as(u32, self.v[x]) + @as(u32, self.v[y]));
                        self.v[x] = @as(u8, @truncate(sum));

                        self.v[0xF] = 0;
                        if (sum > 0xFF)
                            self.v[0xF] = 1;
                    },
                    0x5 => {
                        const vX = self.v[x];
                        const vY = self.v[y];

                        self.v[x] = vX -% vY;

                        self.v[0xF] = 0;
                        if (vX > vY)
                            self.v[0xF] = 1;
                    },
                    0x6 => {
                        const vY = self.v[y];

                        self.v[x] = vY >> 1;

                        self.v[0xF] = 0;
                        if (vY & 0x01 != 0)
                            self.v[0xF] = 1;
                    },
                    0x7 => {
                        const vX = self.v[x];
                        const vY = self.v[y];

                        self.v[x] = vY -% vX;

                        self.v[0xF] = 0;
                        if (vY > vX)
                            self.v[0xF] = 1;
                    },
                    0xE => {
                        const vY = self.v[y];

                        self.v[x] = vY << 1;

                        self.v[0xF] = 0;
                        if (vY & 0x80 != 0)
                            self.v[0xF] = 1;
                    },
                    else => {},
                }
            },
            0x9000 => {
                if (self.v[x] != self.v[y]) self.pc += 2;
            },
            0xA000 => {
                self.i = (opcode & 0xFFF);
            },
            0xB000 => {
                self.pc = (opcode & 0xFFF) + self.v[0];
            },
            0xC000 => {
                // Get the operating system
                // to generate a random seed
                var seed: u64 = 11111;
                std.posix.getrandom(std.mem.asBytes(&seed)) catch {};

                // Generate a random number
                var rnd = std.rand.DefaultPrng.init(seed);
                const num = rnd.random().int(u8);

                // AND and store
                self.v[x] = num & (@as(u8, @truncate(opcode)) & 0xFF);
            },
            0xD000 => {
                const width: u16 = 8; // ALL sprite are 8 wide
                const height = (opcode & 0xF);

                // One of the few instructions
                // where it's fine to set this first
                self.v[0xF] = 0;

                var row: u8 = 0;
                while (row < height) : (row += 1) {
                    var sprite = self.memory.*[self.i + row];

                    var col: u8 = 0;
                    while (col < width) : (col += 1) {
                        // Wrap the x and y around
                        // the screen if outside
                        // the bounds
                        const px = self.v[x] % self.bitmap.width;
                        const py = self.v[y] % self.bitmap.height;

                        // We don't wrap pixels that
                        // are outside of the bounds
                        if (px + col >= self.bitmap.width) continue;
                        if (py + row >= self.bitmap.height) continue;

                        // If the bit (sprite) is not 0
                        // render/erase the pixel
                        if ((sprite & 0x80) > 0) {
                            // If setPixel returns true
                            // a pixel was erased, so set
                            // VF to 1
                            if (self.bitmap.setPixel(px + col, py + row)) {
                                self.v[0xF] = 1;
                            }
                        }

                        // Shift the sprite left 1 and
                        // move the next col/bit of the
                        // sprite into the first position
                        sprite <<= 1;
                    }
                }
            },
            0xE000 => {
                switch (opcode & 0xFF) {
                    0x9E => {
                        if (self.display.keys[self.v[x]]) self.pc += 2;
                    },
                    0xA1 => {
                        if (!self.display.keys[self.v[x]]) self.pc += 2;
                    },
                    else => {},
                }
            },
            0xF000 => {
                switch (opcode & 0xFF) {
                    0x07 => {
                        self.v[x] = self.dtimer;
                    },
                    0x0A => {
                        self.paused = true;
                        self.paused_x = @as(u8, @truncate(x));
                    },
                    0x15 => {
                        self.dtimer = self.v[x];
                    },
                    0x18 => {
                        self.stimer = self.v[x];
                    },
                    0x1E => {
                        self.i += self.v[x];
                    },
                    0x29 => {
                        self.i = @as(u16, @intCast(self.v[x])) * 5;
                    },
                    0x33 => {
                        self.memory.*[self.i + 0] = (self.v[x] / 100) % 10;
                        self.memory.*[self.i + 1] = (self.v[x] / 10) % 10;
                        self.memory.*[self.i + 2] = self.v[x] % 10;
                    },
                    0x55 => {
                        var ri: u16 = 0;
                        while (ri <= x) : (ri += 1) {
                            self.memory.*[self.i + ri] = self.v[ri];
                        }
                        self.i += ri;
                    },
                    0x65 => {
                        var ri: u16 = 0;
                        while (ri <= x) : (ri += 1) {
                            self.v[ri] = self.memory.*[self.i + ri];
                        }
                        self.i += ri;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
};
