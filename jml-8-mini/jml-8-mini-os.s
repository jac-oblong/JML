  ;; 'OS' for the jml-8 mini computer
  ;; currently just tests RAM (0x8000 - 0xFFFF)

org 0x0000

  LD B, 0x00                    ; value with which to test RAM
outer_loop:
  LD (HL), 0x8000               ; start at upper address of memory

inner_loop:
  LD (HL), B                    ; store value in memory
  LD A, (HL)                    ; retrieve value from mem
  ;; THIS IS WHERE 'CP B' and 'JP NZ, ...' would go when testing

  INC (HL)                      ; go to next location
  JR NZ, inner_loop

  INC B                         ; go to next value for test if B NZ
  JR NZ, outer_loop

  HALT                          ; stop running
