addwf 0b0, 0b1
andwf 0b10, 0b0
clrf 0b11
clrw
comf 0b100, 0b1
decf 0b101, 0b0
decfsz 0b110, 0b1
incf 0b111, 0b0
incfsz 0b1000, 0b1
iorwf 0b1001, 0b0
movf 0b1010, 0b1
movwf 0b1011
nop
rlf 0b1100, 0b0
rrf 0b1101, 0b1
subwf 0b1110, 0b0
swapf 0b1111, 0b1
xorwf 0b10000, 0b0
bcf 0b11110, 0b1
bsf 0b11111, 0b10
btfsc 0b100000, 0b11
btfss 0b100001, 0b100
addlw 0b100010
andlw 0b100011
call 0b100100
clrwdt
goto 0b100101
iorlw 0b100110
movlw 0b100111
retfie
retlw 0b101000
return
sleep
sublw 0b101001
xorlw 0b101010
