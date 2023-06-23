.const DATA_OUT 0x1F

.label _LOOP1P
  clrw
  addlw 0xFF
  movwf DATA_OUT
  addlw 0x01
  btfsc DATA_OUT, 3
  goto _LOOP1P
