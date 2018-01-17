# MRISC32
*Mostly harmless Reduced Instruction Set Computer, 32-bit edition*

This is an experimental, custom 32-bit RISC CPU.

## Tools

Currently there is a simple assembler (written in python) and a CPU simulator (written in C++).

# Design

## Goals

* Experiment and learn the pros and cons of various design decisions.
* Keep things simple - both the ISA and the architecture.
* The ISA should map well to a [classic 5-stage RISC pipeline](https://en.wikipedia.org/wiki/Classic_RISC_pipeline).
* The ISA should scale from small embedded to larger superscalar implementations.
* The CPU should be easy to implement in an FPGA.


## Non-goals

* Don't support multiple word sizes or running modes. If a 64-bit CPU is required, create a new ISA and recompile your software.
* Don't be fast and optimal for everything.
* Don't be extensible at the cost of more complicated IF/ID stages.


## Features

* All instructions are 32 bits wide and easy to decode.
* There is one 32-entry, 32-bit scalar register file, R0-R31.
  - Five registers are special (Z, PC, SP, LR, VL).
  - 27 registers are general purpose.
  - All GPRs can be used for all types (integers, pointers and floating point).
  - PC is user-visible (for arithmetic and addressing) but read-only (to simplify branching logic).
* Branches are executed in the ID (instruction decode) step, which gives a low branch misprediction penalty.
* Conditional moves further reduce the cost of branch mispredictions.
* Conditionals (branches, moves) are based on register content (there are *no* condition codes).
* Unlike early RISC architectures, there are *no* delay slots.
* Many traditional floating point operations are handled by integer operations, reducing the number of necessary instructions:
  - Load/store.
  - Compare/branch.
  - Conditional moves.
  - Sign and bit manipulation (e.g. neg, abs).
* There is currently no HW support for 64-bit floating point operations (that is left for a 64-bit version of the ISA).


## SIMD extensions (WIP)

* SIMD instructions use a Cray-like vector model:
  - 32 vector registers, V0-V31, with 32 (TBD) entries in each register.
  - A Vector Length (VL) register controls the length of the vector operation (1-32 elements), which essentially eliminates the need for complicated main+tail-loop constructs.
  - All vector entries are the same size (32 bits), regardless if they represent bytes, half-words, words or floats.
  - The same execution units can be used for both vector operations and scalar operations.
  - There are vector,vector and vector,scalar versions of most integer and floating point operations.
  - Vector loads and stores have a stride parameter.

See: [SIMDDesign.md](doc/SIMDDesign.md).


## Register model and conventions

The scalar registers are allocated as follows:

| Register | Alias | Purpose | Saved by callee |
|---|---|---|---|
| r0  | z | Always zero (read-only) | - |
| r1-r8   | | Subroutine arguments / return values | no |
| r9-r15  | | Temporaries (scratch) | no |
| r16-r26 | | Saved registers | yes |
| r27 | fp | Frame pointer (optional) | yes |
| r28 | vl | Vector length register (holds the last index for vector operations, 0-31) | yes |
| r29 | lr | Link register (return address, must be 4-byte aligned) | yes |
| r30 | sp | Stack pointer (must be 4-byte aligned on subroutine entry) | yes |
| r31 | pc | Program counter (read-only, always 4-byte aligned) | - |

The vector registers are allocated as follows:

| Register | Alias | Purpose | Saved by callee |
|---|---|---|---|
| v0  | vz | Always zero (read-only) | - |
| v1-v8   | | Subroutine arguments / return values | no |
| v9-v15  | | Temporaries (scratch) | no |
| v16-v31 | | Saved registers | yes |


## Instructions

*Still under construction*

### Legend

| Name | Description |
|---|---|
| rd | Destination register |
| ra | Source register 1 |
| rb | Source register 2 |
| rc | Source register 3 |
| i14 | 14-bit immediate value |
| i19 | 19-bit immediate value |
| i24 | 24-bit immediate value |
| c | Carry bit (ALU) |

### Integer instructions

| Mnemonic | Operands | Operation | Description |
|---|---|---|---|
|nop| - | - | No operation |
|or | rd, ra, rb | rd <= ra \| rb | Bitwise or |
|nor| rd, ra, rb | rd <= ~(ra \| rb)  | Bitwise nor |
|and| rd, ra, rb | rd <= ra & rb | Bitwise and |
|xor| rd, ra, rb | rd <= ra ^ rb | Bitwise exclusive or |
|add| rd, ra, rb | c:rd <= ra + rb | Addition |
|sub| rd, ra, rb | c:rd <= ra - rb | Subtraction |
|addc| rd, ra, rb | c:rd <= ra + rb + c | Addition with carry |
|subc| rd, ra, rb | c:rd <= ra - rb + c | Subtraction with carry |
|lsl| rd, ra, rb | rd <= ra << rb | Logic shift left |
|asr| rd, ra, rb | rd <= ra >> rb (signed) | Arithmetic shift right |
|lsr| rd, ra, rb | rd <= ra >> rb (unsigned) | Logic shift right |
|clz| rd, ra | rd <= clz(ra) | Count leading zeros |
|rev| rd, ra | rd <= rev(ra) | Reverse bit order |
|ext.b| rd, ra | rd <= signextend(ra[7:0]) | Sign-extend byte to word |
|ext.h| rd, ra | rd <= signextend(ra[15:0]) | Sign-extend halfword to word |
|ldx.b| rd, ra, rb | rd <= [ra + rb] (byte) | Load unsigned byte, indexed |
|ldx.h| rd, ra, rb | rd <= [ra + rb] (halfword) | Load unsigned halfword, indexed |
|ldx.w| rd, ra, rb | rd <= [ra + rb] (word) | Load word, indexed |
|stx.b| rc, ra, rb | [ra + rb] <= rc (byte) | Store byte, indexed |
|stx.h| rc, ra, rb | [ra + rb] <= rc (halfword) | Store halfowrd, indexed |
|stx.w| rc, ra, rb | [ra + rb] <= rc (word) | Store word, indexed |
|meq | rd, ra, rb | rd <= rb if ra == 0 | Conditionally move if equal to zero |
|mne | rd, ra, rb | rd <= rb if ra != 0 | Conditionally move if not equal to zero |
|mlt | rd, ra, rb | rd <= rb if ra < 0 | Conditionally move if less than zero |
|mle | rd, ra, rb | rd <= rb if ra <= 0 | Conditionally move if less than or equal to zero |
|mgt | rd, ra, rb | rd <= rb if ra > 0 | Conditionally move if greater than zero |
|mge | rd, ra, rb | rd <= rb if ra >= 0 | Conditionally move if greater than or equal to zero |
|jmp | ra | pc <= ra | Jump to register address |
|jsr | ra | lr <= pc+4, pc <= ra | Jump to register address and link |
|ori | rd, ra, i14 | rd <= ra \| signextend(i14) | Bitwise or |
|nori| rd, ra, i14 | rd <= ~(ra \| signextend(i14)) | Bitwise nor |
|andi| rd, ra, i14 | rd <= ra & signextend(i14) | Bitwise and |
|xori| rd, ra, i14 | rd <= ra ^ signextend(i14) | Bitwise exclusive or |
|addi| rd, ra, i14 | c:rd <= ra + signextend(i14) | Addition |
|subi| rd, ra, i14 | c:rd <= ra - signextend(i14) | Subtraction |
|addci| rd, ra, i14 | c:rd <= ra + signextend(i14) + c | Addition with carry |
|subci| rd, ra, i14 | c:rd <= ra - signextend(i14) + c | Subtraction with carry |
|lsli| rd, ra, i14 | rd <= ra << signextend(i14) | Logic shift left |
|asri| rd, ra, i14 | rd <= ra >> signextend(i14) (signed) | Arithmetic shift right |
|lsri| rd, ra, i14 | rd <= ra >> signextend(i14) (unsigned) | Logic shift right |
|ld.b| rd, ra, i14 | rd <= [ra + signextend(i14)] (byte) | Load unsigned byte |
|ld.h| rd, ra, i14 | rd <= [ra + signextend(i14)] (halfword) | Load unsigned halfword |
|ld.w| rd, ra, i14 | rd <= [ra + signextend(i14)] (word) | Load word |
|st.b| rc, ra, i14 | [ra + signextend(i14)] <= rc (byte) | Store byte |
|st.h| rc, ra, i14 | [ra + signextend(i14)] <= rc (halfword) | Store halfowrd |
|st.w| rc, ra, i14 | [ra + signextend(i14)] <= rc (word) | Store word |
|beq | ra, i19 | pc <= pc+signextend(i19)*4 if ra == 0 | Conditionally branch if equal to zero |
|bne | ra, i19 | pc <= pc+signextend(i19)*4 if ra != 0 | Conditionally branch if not equal to zero |
|bge | ra, i19 | pc <= pc+signextend(i19)*4 if ra >= 0 | Conditionally branch if greater than or equal to zero |
|bgt | ra, i19 | pc <= pc+signextend(i19)*4 if ra > 0 | Conditionally branch if greater than zero |
|ble | ra, i19 | pc <= pc+signextend(i19)*4 if ra <= 0 | Conditionally branch if less than or equal to zero |
|blt | ra, i19 | pc <= pc+signextend(i19)*4 if ra < 0 | Conditionally branch if less than zero |
|ldi | rd, i19 | rd <= signextend(i19) | Load immediate (low 19 bits) |
|ldhi| rd, i19 | rd <= i19 << 13 | Load immediate (high 19 bits) |
|bra | i24 | pc <= pc+signextend(i24)*4 | Branch unconditionally |
|bsr | i24 | lr <= pc+4, pc <= pc+signextend(i24)*4 | Branch unconditionally and link |

### Floating point instructions

| Mnemonic | Operands | Operation | Description |
|---|---|---|---|
|itof| rd, ra | rd <= (float)ra | Cast integer to float |
|ftoi| rd, ra | rd <= (int)ra | Cast float to integer |
|fadd| rd, ra, rb | rd <= ra + rb | Floating point addition |
|fsub| rd, ra, rb | rd <= ra - rb | Floating point difference |
|fmul| rd, ra, rb | rd <= ra * rb | Floating point multiplication |
|fdiv| rd, ra, rb | rd <= ra / rb | Floating point division |

### Planned instructions

* Improved support for unsigned comparisons (sgtu, sltu, ...).
* Integer multiplication and division (32-bit operands and 64-bit results).
* Control instructions/registers (cache control, interrupt masks, status flags, ...).
* Load Linked (ll) and Store Conditional (sc) for atomic operations.
* Single-instruction load of common constants (mostly floating point: 1.0, PI, ...).

### Common constructs

| Problem | Solution |
|---|---|
| Load 32-bit immediate | ldhi + ori |
| Move register | or rd,ra,z |
| Negate value | sub rd,z,ra |
| Invert all bits | nor rd,ra,ra |
| Compare and branch | sub + b[cc] |
| Return from subroutine | jmp lr |
| Push to stack | subi sp,sp,N + st.w ra,pc,0 + ... |
| Pop from stack | ld.w rd,pc,0 + ... + addi sp,sp,N |
| Floating point negation | ldhi + xor |
| Floating point absolute value | ldhi + nor + and |
| Floating point compare and branch | fsub + b[cc] |

