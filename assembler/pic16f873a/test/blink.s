.const PORTA 0x05
.const TRISA 0x85

.const STATUS 0x03
.const RP0    5
.const RP1    6
.const C      0 ; carry out


.org 0x0000 ; Reset vector
  goto 0x0005

.org 0x0004 ; Interrupt vector


.org 0x0005

  bcf STATUS, RP0
  bcf STATUS, RP1 ; select bank 0
  clrf PORTA      ; clear PORTA
  bsf STATUS, RP0 ; select bank 1
  bcf TRISA, 0    ; set PORTA:PIN0 as output

.label _LOOP
  clrw
  addwf PORTA, 0  ; clear W, then put PORTA in W
  xorlw 0x01      ; flip bit 0 of W
  movwf PORTA     ; store W back into PORTA

  clrw
.label _DELAY     ; count to 256, then go back to _LOOP
  addlw 0x01      ; add 1 to W
  btfss STATUS, C
  goto _DELAY
  goto _LOOP
