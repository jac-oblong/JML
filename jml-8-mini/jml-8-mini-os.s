  ;; 'OS' for the jml-8 mini computer
  ;; currently just tests RAM (0x8000 - 0xFFFF)

org 0x0000

  LD B, 0x55                    ; value with which to test RAM
  LD HL, 0xFFFF                 ; start at high address of RAM

loop:
  LD (HL), B                    ; store value in memory
  LD A, (HL)                    ; retrieve value from mem
  CP B                          ; compare A to B
  JR NZ, error

  DEC HL                        ; go to next location
  LD A, 0x7F                    ; load A with high value stop
  CP H                          ; compare A to H
  JR NZ, loop             ; if not equal, continue
                                ; equal, so passed 0x8000 boundary of mem

end:
  HALT                          ; stop running

error:
  JP error
