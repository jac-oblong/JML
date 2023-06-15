# PIC16F873A

This microcontroller is used in various peripherals on the computer(s). Data
sheets can be found in the [datasheets](/docs/datasheets/) directory. For
information on memory organization in the microcontroller, the
[PIC16F873A](/docs/datasheets/PIC16F873A.pdf) data sheet should be referenced.
For information on programming the microcontroller, use the
[Programming](/docs/datasheets/PIC16F873A-Flash-Memory-Programming.pdf)
datasheet.

Code and circuit schematic used to program the microcontroller can be found in
this directory.

The microcontroller is relatively easy to use and has a simple instruction set.


## Use 
The assembler is very easy to use, simply call the name of executalbe followed
by the name of the file to assemble.

Options:
- `-o` can be used to specify the output file (default is `a.out` or `a.o` on a 
  jml-XX computer). Example: `-o out.bin`
- `-s` can be used to specify the size (number of words/instructions) the output
  file should be. Any space not filled by instructions will be automatically
  filled with `nop`. Example: `-s 2300`
- `--word-size` can be used to specify the number of bits used for each machine
  code instruction. The PIC16F873A has 14-bit instructions, so any number
  smaller than that will overwrite data. The default value is 16-bit, but any
  value can be used. Example: `--word-size 32`


## Instruction Set 
**IMPORTANT NOTE**: In the datasheet, instructions are given in all caps, but 
this is not the case for this assembler. Instead, they should be all lowercase.

Reference the [PIC16F873A](/docs/datasheets/PIC16F873A.pdf) datasheet for a full
list and explanation of the instruction set. Make sure to read the note above.


## Syntax
There are some important changes to the syntax from how it appears in the
datasheet. Most importantly, all instructions should be lowercase instead of
uppercase.

Each instruction should be on a new line, with a space after the instruction
itself and a comma between each "argument".

#### Numbers
Literal numbers can be be specified in decimal (`128`) in binary (`0b01000000`)
or in hex (`0x40`).

#### Strings/Characters
Like **C**, strings should be surrounded by double quotes, and characters by
single quotes. A null terminator will be appended to each string.

#### Labels
Labels should be placed on their own line followed by a colon. It is good
practice to start a label with an underscore and put the label in all caps. For
example: `_LOOP:`, which can then be used: `goto _LOOP`. Underscores, numbers,
and letters are all acceptable in labels, but the first character cannot be a
number. Additionally, no more than one underscore can be used in sequence. 
`____HI__` is not a valid name.

#### Constants
Constants are sequences of characters used to represent a value. It is good
practice to put constants in all caps, separate words with underscores and place
all constants at the beginning of the file. A constant can be declared as
follows: `REG_FILE_ADDR = 0x00`, and used as follows: `clrf REG_FILE_ADDR`.
During assembly, all instances of `REG_FILE_ADDR` will be replaced with `0x00`.
Similar to labels, underscores, numbers and letters are all acceptable, but the
first character cannot be a number. Additionally, no more than one underscore
can be used in sequence. `____HI__` is not a valid name.

Constants can hold more than one value by using brackets. `CONSTANT_ARRAY[5] =
{0x00, 0x01, 0x02, 0x03, 0x04}` will "store" the 5 values in `CONSTANT_ARRAY`.
These values can then be retrieved by using `CONSTANT_ARRAY[1]`, which would
return `0x01`.

The following constants are defined by default: `W`(working 
register/accumulator), `PC` (program counter), `TO` (time-out bit), `PD`
(power-down bit). They can be overwritten.

#### Other
`.org` can be used to specify where in memory the machine code should be placed.
If none is specified, `0x00` is assumed by default. It is up to the programmer
to make sure that no two blocks of code overwrite each other.
