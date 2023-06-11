# jml-16
16-bit computer built from scrap

## Parts
All parts have been scrapped from other computers/electronics. Using different
parts will likely produce a better computer.

### Changing parts
The software for this computer is designed in such a way that parts can easily
be swapped out for a different component with similar functionality. For
example, changing the microprocessor will only require editing the assembler.

Obviously, the hardware design is much more reliant on the specific component
used, so changing parts will not be as easy.

## Design
The computer is designed in individual sections that come together to create the
whole system. This is useful as it makes changing a section easy.

## Folder Organization
Datasheets for parts, in addition to general documentation about the entire
project can be found in the [docs](/docs/) directory.

The assembler used to convert assembly to machine code can be found in the
[assembler](/assembler/) directory.
NOTE: Only one assembler is used, but not all components have the same
instructions. Thus, it is necessary to specify what component in the assembly
file.

The compiler used to compile C code can be found in the [compiler](/compiler/)
directory.

Information about the keyboard interface can be found in [keyboard](/keyboard/).

Information about the monitor interface can be found in [monitor](/monitor/).

Information about the different microprocessors can be found in
[microprocessor](/microprocessor/).

Links to programs designed to be run on the **jml** family of computers can be 
found in [programs](/programs/)
