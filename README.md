# jml-16
16-bit computer built from scrap

## Design
The computer is designed in individual sections that come together to create the
whole system. This is useful as it makes changing a section easy.

## Parts
All parts have been scrapped from other computers/electronics. Using different
parts will likely produce a better computer.

### Changing parts
The high-level for this computer is designed in such a way that parts can easily
be swapped out for a different component with similar functionality. For 
example, the vga display driver can be swapped out for a different driver as
long as the inputs and outputs stay consistent.

Obviously, the hardware within specific modules cannot be swapped out as easily
without fully ensuring similar functionality.

## Folder Organization
Datasheets for parts, in addition to general documentation about the entire
project can be found in the [docs](/docs/) directory.

The assembler used to convert assembly to machine code can be found in the
[assembler](/assembler/) directory.

<!--
The compiler used to compile C code can be found in the [compiler](/compiler/)
directory.
-->

Information about the keyboard interface can be found in [keyboard](/keyboard/).

Information about the monitor interface can be found in [monitor](/monitor/).

Information about the different central computers can be found in any dirctory 
titled **jml-XX**.

Links to programs designed to be run on the **jml** family of computers can be 
found in [programs](/programs/)
