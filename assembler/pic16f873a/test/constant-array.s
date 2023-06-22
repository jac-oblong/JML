.const NUMBERS[] { 0, 1, 2, 3, 4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0b1101, 0b1110, 0b1111, 0b10000 }


addwf NUMBERS[0], NUMBERS[1]
andwf NUMBERS[2], NUMBERS[0]
clrf NUMBERS[3] 
clrw
comf NUMBERS[4], NUMBERS[1]
decf NUMBERS[5], NUMBERS[0]
decfsz NUMBERS[6], NUMBERS[1]
incf NUMBERS[7], NUMBERS[0]
incfsz NUMBERS[8], NUMBERS[1]
iorwf NUMBERS[9], NUMBERS[0]
movf NUMBERS[10], NUMBERS[1]
movwf NUMBERS[11] 
nop
rlf NUMBERS[12], 0
rrf NUMBERS[13], 1
subwf NUMBERS[14], 0
swapf NUMBERS[15], 1
xorwf NUMBERS[16], 0
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
