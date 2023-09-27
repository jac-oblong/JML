;; 'OS' for the jml-8 mini computer

;; Brief explanation of organization:
;;
;; Everything is organized under 'headers'
;;
;; The interrupt table, interrupt definitions and function defintions are at the
;; end of the file
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

;; I/O ADDRESS FOR CTC
CTC_TIMER0: equ 0x08
CTC_TIMER1: equ 0x09
CTC_TIMER2: equ 0x0A
CTC_TIMER3: equ 0x0B

;; FIFO BUFFER FOR HOLDING INPUT DATA (0x8000-0x80FD) (memory address 0x80FF
;; holds where the tail of the buffer is and where data should be read from,
;; 0x80FE holds where the head of the buffer is and where new data should be
;; put) (this buffer is rolling)
RX_DATA_BASE: equ 0x8000
RX_DATA_HEAD: equ 0x80FE    ; only to be written to by an interrupt
RX_DATA_TAIL: equ 0x80FF    ; only to be written to by _main

;; DEFAULT STARTING LOCATION OF STACK
STACKSTART: equ 0x0000


.org 0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALIZE CTC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_init_ctc:
  ld A, 0x47                    ; initialize timer 0 of ctc to counter mode,
  out (CTC_TIMER0), A           ; no interrupt, time constant follows, reset

  ld A, 8                       ; count for ctc0, should generate ~150kHz for
                                ; 9600 baud rate used by SIO channel A
  out (CTC_TIMER0), A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALIZE SIO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_init_sio:
  jp continue_sio_init          ; jump over this section of data
SIO_A_INIT_DATA_BEGIN:
  db 0x30                       ; reset any errors, select WR0
  db 0x18                       ; reset channel A
  db 0x04                       ; select WR4
  db 0x44                       ; no parity, 1 stop bit, 8 data bits, x16 clock
  db 0x05                       ; select WR5
  db 0xE8                       ; dtr active, enable tx, 8 data bits
  db 0x01                       ; select WR1
  db 0x10                       ; interrup on all rx characters, parity error is
                                ; special condition
  db 0x03                       ; enable rx, 8 bits per character
SIO_A_INIT_DATA_SIZE: equ $-SIO_A_INIT_DATA_BEGIN
SIO_B_INIT_DATA_BEGIN:
  db 0x01                       ; select WR1
  db 0x04                       ; no interrupt in chb, spec rx condition affects
                                ; interrupt vector
  db 0x02                       ; select WR2
  db 0xF0                       ; load interrupt vector with lower 8 bits
                                ; (lowest 4 will be changed depending on vector)
SIO_B_INIT_DATA_SIZE: equ $-SIO_B_INIT_DATA_BEGIN

continue_sio_init:
  ld C, SIO_A_CONT              ; load C with location of sio cha control
  ld B, SIO_A_INIT_DATA_SIZE    ; load B with number of bytes to load
  ld HL, SIO_A_INIT_DATA_BEGIN  ; load HL with beginning of data
  otir

  ld C, SIO_B_CONT              ; repeat for chb
  ld B, SIO_B_INIT_DATA_SIZE
  ld HL, SIO_B_INIT_DATA_BEGIN
  otir

  ;; SIO channel A is now active, ready for use with UART

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_main:
  ld A, interrupt_vector_table/256
  ld I, A                       ; load I reg, used for int vectors
  ld SP, STACKSTART             ; load SP with starting value
  im 2                          ; set interrupt mode to 2
  ei                            ; enable interrupts

send_all_chars_loop:
  ld A, 0x0A                    ; line feed
  out (SIO_A_DATA), A           ; send to uart
  call f_uart_block_tx_empty
  ld A, 0x0D                    ; carriage return
  out (SIO_A_DATA), A           ; send to uart
  call f_uart_block_tx_empty
  ld A, 0x20                    ; load A with ascii for ' '
send_a_char:
  out (SIO_A_DATA), A           ; send to uart
  ld B, A                       ; save A in B
  call f_uart_block_tx_empty
  ld A, B                       ; retrieve A from B
  inc A                         ; go to next ascii value
  bit 7, A                      ; check if bit 7 if set in A
  jp z, send_a_char             ; if not overflow, send next char
  jp send_all_chars_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION DEFINITIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; turns off the RTS pin going from SIO to other device
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_uart_rts_off:
  push AF
  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0xE8                    ; DTR active, tx 8 bit, tx on, RTS off
  out (SIO_A_CONT), A
  pop AF
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; turns on the RTS pin going from SIO to other device
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_uart_rts_on:
  push AF
  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0xEA                    ; DTR active, tx 8 bit, tx on, RTS on
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

  jp z, uart_block_tx_empty_repeat
  pop AF
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__uart_rx_available:
  ;; retrieves received data from uart and adds to input buffer
  di                            ; disable interrupts
  ex AF, AF'                    ; exchange all registers
  exx

  call f_uart_rts_off           ; tell host to not send more data

  ld HL, RX_DATA_BASE           ; set base of input buffer
  ld A, (RX_DATA_HEAD)          ; get current location of input buffer
  inc A
  cp 0xFE                       ; upper limit of input buffer
  jp NZ, store_byte
  ld A, 0x00

store_byte:
  ld (RX_DATA_HEAD), A          ; store new location of HEAD
  ld L, A                       ; HL now has location where new byte should go

  in A, (SIO_A_DATA)            ; read rx byte and store in buffer
  ld (HL), A

  call f_uart_rts_on            ; allow for more data to be sent

  ex AF, AF'                    ; exchange registers again
  exx
  ei
  reti

__spec_rx_condition:
  halt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPT TABLE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.org 0x1F00
interrupt_vector_table:

  ;; interrupt vectors for SIO channel B, not used
  ;; .org 0x1FF0
  ;; defw __chb_tx_buf_empty
  ;; .org 0x1FF2
  ;; defw __chb_status_change
  ;; .org 0x1FF4
  ;; defw __chb_rx_available
  ;; .org 0x1FF6
  ;; defw __spec_rx_condition

  ;; interrupt vectors for SIO channel A (uart), not all are used
  ;; .org 0x1FF8
  ;; defw __uart_tx_buf_empty
  ;; .org 0x1FFA
  ;; defw __uart_stats_change
  .org 0x1FFC
  defw __uart_rx_available
  .org 0x1FFE
  defw __spec_rx_condition
