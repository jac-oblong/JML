# Keyboard

The keyboard used is a ps/2 keyboard. Specifically the **Perixx PERIBOARD-409P
Wired PS2 Mini** keyboard. This keyboard does not natively use the ps/2
protocol. It is capable of both ps/2 and usb, and so requires the host to send a
code to the keyboard to initialize ps/2 protocol. The keyboard driver for this
computer should work for native ps/2 keyboards in addition to this odd keyboard.

## Changes to Normal ps/2 protocol

Normal ps/2 keyboards will send usually send the code `0xAA` to the computer if
they are working correctly on bootup, and then continue with normal operation.
The **PERIBOARD-409P**, however, will continually send that scancode until
receiving a response in order to tell if it should be using ps/2 or usb
protocol. Because of this, the computer will send the code `0xFF` (the code for
reset) when `0xAA` is received.

Some links I found helpful in discovering this problem:
[StackExchange](https://electronics.stackexchange.com/questions/625609/scan-codes-from-ps-2-keyboard-misbehaviors)
[Reddit](https://www.reddit.com/r/beneater/comments/m836ul/ps2_keyboard_not_working_on_the_6502_but_is/)

## Directory Organization

The `arduino-based-reciever` directory has code for an initial version of the
keyboard interface. This was used as a starting point for interfacing with the
keyboard, including how to interface with the **Perixx PERIBOARD-409P**. It is
not used in the final version of the computer, but may be useful in
understanding how the interface works on a basic level.
