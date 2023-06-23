addwf 0, 1 ; here
andwf 2, 0
clrf 3
clrw
comf 4, 1 ; here
decf 5, 0
decfsz 6, 1 ; here
incf 7, 0
incfsz 8, 1 ; here
iorwf 9, 0
movf 10, 1 ; here
movwf 11
nop
rlf 12, 0
rrf 13, 1 ; here
subwf 14, 0

.label _SIXTEEN
swapf 15, 1 ; here
xorwf _SIXTEEN, 0
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
