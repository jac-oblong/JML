;; SIO code for the jml-8-mini computer

;; Brief explanation of organization:
;;
;; Everything is organized under 'headers'
;;
;; Labels are formatted in the following ways:
;;      * interrupt labels are preceded by '__' (2 underscores)
;;      * labels not designed to be called/jumped to are preceded by '_'
;;      * function labels are preceded by 'f_'
;;      * general flow control labels are not preceded by anything
;;
;; Labels inside of a function should have part of the function name in it in
;; order to prevent conflicting labels
;;
;; When calling a function, no registers should be clobbered (excluding F)
;; If a register's value is changed, it should be listed in the description
;;
;; Interrupts exclusively use the alternate registers of the Z80, so using them
;; elsewhere is not advised

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONSTANT DECLARATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; I/O ADDRESS FOR SIO
SIO_A_DATA: equ 0x04
SIO_A_CONT: equ 0x05
SIO_B_DATA: equ 0x06
SIO_B_CONT: equ 0x07

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALIZE SIO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initializes the SIO to work with UART at 9600 baud
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_init_sio:
  ld C, SIO_A_CONT              ; load C with location of sio cha control
  ld B, SIO_A_INIT_DATA_SIZE    ; load B with number of bytes to load
  ld HL, SIO_A_INIT_DATA_BEGIN  ; load HL with beginning of data
  otir

  ld C, SIO_B_CONT              ; repeat for chb
  ld B, SIO_B_INIT_DATA_SIZE
  ld HL, SIO_B_INIT_DATA_BEGIN
  otir

  ;; SIO channel A is now active, ready for use with UART
  ret

;; data block used to initialize SIO
SIO_A_INIT_DATA_BEGIN:
  db 0x30                       ; reset any errors, select WR0
  db 0x18                       ; reset channel A
  db 0x04                       ; select WR4
  db 0x44                       ; no parity, 1 stop bit, 8 data bits, x16 clock
  db 0x05                       ; select WR5
  db 0x68                       ; dtr inactive, enable tx, 8 data bits
  db 0x01                       ; select WR1
  db 0x1C                       ; interrup on all rx characters
  db 0x03                       ; select WR3
  db 0xC1                       ; enable rx, 8 bits per character
SIO_A_INIT_DATA_SIZE: equ $-SIO_A_INIT_DATA_BEGIN
SIO_B_INIT_DATA_BEGIN:
  db 0x01                       ; select WR1
  db 0x04                       ; no interrupt in chb, spec rx condition affects
                                ; interrupt vector
  db 0x02                       ; select WR2
  db 0xF0                       ; load interrupt vector with lower 8 bits
                                ; (lowest 4 will be changed depending on vector)
SIO_B_INIT_DATA_SIZE: equ $-SIO_B_INIT_DATA_BEGIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION DEFINITIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; signal that UART should not receive new characters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_uart_rx_off:
  push AF

  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0x68                    ; dtr inactive, enable tx, 8 data bits
  out (SIO_A_CONT), A

  pop AF
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; signal that UART can receive new characters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_uart_rx_on:
  push AF

  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0xE8                    ; dtr active, enable tx, 8 data bits
  out (SIO_A_CONT), A

  pop AF
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; blocks until the tx buffer is empty
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_uart_block_tx_empty:
  push AF
uart_block_tx_empty_repeat:
  sub A                         ; clear A

  inc A                         ; select RR1
  out (SIO_A_CONT), A

  in A, (SIO_A_CONT)            ; read value of RR1
  bit 0, A                      ; test bit zero of A, will be 0 when empty

  jr z, uart_block_tx_empty_repeat
  pop AF
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sends one byte of data in A to UART port
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_uart_send_byte:
  out (SIO_A_DATA), A
  ret
