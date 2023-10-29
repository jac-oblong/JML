;; Firmware for the jml-8-mini computer

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
;;
;; Interrupts exclusively use the alternate registers of the Z80, so using them
;; elsewhere is not advised

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONSTANT DECLARATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; FIFO BUFFER FOR HOLDING INPUT DATA (0x8000-0x80FD) (memory address 0x80FF
;; holds where the tail of the buffer is and where data should be read from,
;; 0x80FE holds where the head of the buffer is and where the new data should be
;; written to) (this buffer is circular) (When more data is added than can be
;; stored, the newest data is ignored) (When data is read, it is overwritten
;; with 0x00 to signal that it can be written to)
RX_BUF_BASE: equ 0x8000
RX_BUF_SIZE: equ 0xFE           ; total size of buffer in bytes
RX_BUF_HEAD: equ 0x80FE         ; only to be written to by an interrupt
RX_BUF_TAIL: equ 0x80FF         ; only to be written to by _main
RX_BUF_HEAD_VAL: equ 0x00       ; initial value for head
RX_BUF_TAIL_VAL: equ 0x00       ; initial value for tail

;; DEFAULT STARTING LOCATION OF STACK
STACKSTART: equ 0x0000


.org 0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_init:
  ;; stackpointer and interrupt stuff
  ld A, 0x1F
  ld I, A                       ; load I reg, used for int vectors
  ld SP, STACKSTART             ; load SP with starting value

  ;; rx buffer
  ld HL, RX_BUF_HEAD            ; reset rx buffer pointers
  ld (HL), RX_BUF_HEAD_VAL
  ld HL, RX_BUF_TAIL
  ld (HL), RX_BUF_TAIL_VAL
  ld L, RX_BUF_TAIL_VAL         ; set beginning of rx buffer to value 0x00 to
  ld (HL), 0x00                 ; show that it is empty

  ;; interrupt mode and initializing other hardware
  im 2                          ; set interrupt mode to 2
  call f_init_ctc
  call f_init_sio
  ei                            ; enable interrupts

main_loop:
  halt

  call f_rx_buf_retrieve_byte
  cp 0x00                       ; if no byte present send 'A' (just a test for
                                ; now) and return to start of loop
  jr z, main_loop

  call f_uart_send_byte

  jr main_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION DEFINITIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; checks if there is data in the rx buffer (purely by the nature of how the
;; function works, A will have the new data when returning, but using this
;; function to fetch data will break the entire input buffer system)
;; clobbers A: will have value 0 if no data, non-zero if data in buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_rx_buf_has_data:
  push HL

  ld HL, RX_BUF_TAIL
  ld A, (HL)                    ; load A with read section of buffer
  ld L, A                       ; point HL to where to read from
  ld A, (HL)                    ; read "new" byte into A
                                ; if A == 0x00, then no data has been written

  pop HL
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; retrieves one byte from the rx buffer, if there is any data
;; clobbers A: will have value 0 (NULL) if no data in the buffer, otherwise
;; will have the first byte from the buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_rx_buf_retrieve_byte:
  push HL
  push BC

  call f_rx_buf_has_data        ; check if buffer has data
  cp 0x00
  jr z, rx_buf_retr_byte_end    ; quit if no data

  ld B, A                       ; temporarily store data in B
  ld HL, RX_BUF_TAIL
  ld A, (HL)                    ; retrieving where the tail is pointing,
  inc A                         ; incrementing it, and storing it back if it
  cp RX_BUF_SIZE                ; does not cause overflow
  jr nz, rx_buf_retr_byte_save_tail
  ld A, 0x00                    ; tail overflowed bounds, so setting back to 0
rx_buf_retr_byte_save_tail:
  ld (HL), A
  ld A, B                       ; B had the data in the buffer, so moving to A

rx_buf_retr_byte_end:
  pop BC
  pop HL
  ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INCLUDES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include "../include/sio.s"
#include "../include/ctc.s"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__uart_rx_available:
  ex AF, AF'
  exx

  in A, (SIO_A_DATA)            ; retrieve the new byte
  ld B, A                       ; store new byte in B

  ld HL, RX_BUF_HEAD
  ld DE, HL                     ; make a copy in DE, will be useful later
  ld A, (HL)
  ld L, A                       ; point HL to where in buffer to write new data

  ld A, (HL)                    ; make sure there is room for new data
  cp 0x00
  jr nz, uart_rx_avail_end

  ld (HL), B                    ; store the new data into the buffer and
  inc HL                        ; increment where head is pointing
  ld A, L
  cp RX_BUF_SIZE                ; make sure new position is not overflowing buf
  jr nz, uart_rx_avail_store_new_head
  ld A, 0x00
uart_rx_avail_store_new_head:
  ld HL, DE                     ; retrive location of head from DE
  ld (HL), A                    ; store new value of head

uart_rx_avail_end:
  exx
  ex AF, AF'
  ei
  reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; special cases not handled yet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
__spec_rx_condition:
  jp 0x0000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPT TABLE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.org 0x1F00
interrupt_vector_table:

  ;; interrupt vectors for SIO channel B, not used
  ;; .org 0x1FF0
  ;; dw __chb_tx_buf_empty
  ;; .org 0x1FF2
  ;; dw __chb_status_change
  ;; .org 0x1FF4
  ;; dw __chb_rx_available
  ;; .org 0x1FF6
  ;; dw __spec_rx_condition

  ;; interrupt vectors for SIO channel A (uart), not all are used
  ;; .org 0x1FF8
  ;; dw __uart_tx_buf_empty
  ;; .org 0x1FFA
  ;; dw __uart_stats_change
  .org 0x1FFC
  dw __uart_rx_available
  .org 0x1FFE
  dw __spec_rx_condition
