# PIC16F873A Programmer

## Info
An Arduino Micro was used to upload the code.

[PlatformIO](https://platformio.org) was used to upload the code, but the
Arduino IDE should also work.

[KiCad](https://www.kicad.org) was used for the [schematics](schematics/).

[PIC16F873A Programming Datasheet](/docs/datasheets/PIC16F873A-Flash-Memory-Programming.pdf)

## Important
Serial communication should be happening at a baud rate of 2400. This slowing of
speed allows for the Arduino to keep up with incoming data while also ensuring
the PIC16F873A has enough time to process each command.

There are three buttons, each with a corresponding LED. When the LED is lit, the
corresponding button will have an affect on code execution.

## Usage
The Arduino expects to recieve data via the Serial port, which it will then
upload to the PIC16F873A microcontroller.

The first `0x2000` bytes recieved are considered to be part of program memory. 
Since each word in program memory is 14 bits, every two consecutive bits make up
one word. For example, if the 33rd and 34th bytes sent are `0x30` and `0x4F` 
respectively, then the 17th (34 / 2) word in memory would be `0x304F`. And the 
pattern would continue for the 35th and 36th bytes, etc.

After the first `0x2000` bytes, the next `128` bytes correspond to EEPROM
memory. Programming has to be restarted by pressing the pushbutton before
sending EEPROM data.

Uploading a file to the Arduino can be done using PlatformIO.

The `pio device monitor` command will start the serial monitor. From there,
`<Ctrl>-T` asks as the escape sequence and `<Ctrl>-U` can be used to specify a
file to upload.
