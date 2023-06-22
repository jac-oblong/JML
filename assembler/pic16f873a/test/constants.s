.const ZERO 0
.const ONE 1
.const TWO 2
.const THREE 3
.const FOUR 4
.const FIVE 0x5
.const SIX 0x6
.const SEVEN 0x7
.const EIGHT 0x8
.const NINE 0x9
.const TEN 0xA
.const ELEVEN 0xB
.const TWELVE 0xC
.const THIRTEEN 0b1101
.const FOURTEEN 0b1110
.const FIFTEEN 0b1111
.const SIXTEEN 0b10000


addwf ZERO, ONE
andwf TWO, ZERO
clrf THREE
clrw
comf FOUR, ONE
decf FIVE, ZERO
decfsz SIX, ONE
incf SEVEN, ZERO
incfsz EIGHT, ONE
iorwf NINE, ZERO
movf TEN, ONE
movwf ELEVEN
nop
rlf TWELVE, 0
rrf THIRTEEN, 1
subwf FOURTEEN, 0
swapf FIFTEEN, 1
xorwf SIXTEEN, 0
bcf 30, 1
bsf 31, 2
btfsc 32, 3
btfss 33, 4
addlw 34
andlw 35
call 36
clrwdt
goto 37
iorlw 38
movlw 39
retfie
retlw 40
return
sleep
sublw 41
xorlw 42
