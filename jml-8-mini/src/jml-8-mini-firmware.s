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
;; 0x80FE holds where the head of the buffer is and where the newest byte of
;; data is) (this buffer is rolling)
RX_BUF_BASE: equ 0x8000
RX_BUF_SIZE: equ 0xFE           ; total size of buffer in bytes
RX_BUF_HEAD: equ 0x80FE         ; only to be written to by an interrupt
RX_BUF_TAIL: equ 0x80FF         ; only to be written to by _main
RX_BUF_HEAD_VAL: equ 0xFF       ; initial value for head
RX_BUF_TAIL_VAL: equ 0x00       ; initial value for tail

;; DEFAULT STARTING LOCATION OF STACK
STACKSTART: equ 0x0000


.org 0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_main:
  ld A, 0x1F
  ld I, A                       ; load I reg, used for int vectors
  ld SP, STACKSTART             ; load SP with starting value
  ld HL, RX_BUF_HEAD            ; reset rx buffer pointers
  ld (HL), RX_BUF_HEAD_VAL
  inc HL
  ld (HL), RX_BUF_TAIL_VAL
  im 2                          ; set interrupt mode to 2
  call f_ctc_init
  call f_sio_init
  ei                            ; enable interrupts

loop:
  jp loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION DEFINITIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; checks if there is data in the rx buffer
;; clobbers A: will have value 0 if no data, non-zero if data in buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_rx_buf_has_data:
  push HL

  ld HL, RX_BUF_HEAD
  ld A, (HL)
  inc HL                        ; set HL to point at tail
  sub (HL)                      ; subtract the tail from the head

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
  jp z, rx_buf_retr_byte_end    ; quit if no data

  ld HL, RX_BUF_TAIL
  ld A, (HL)                    ; retrieving the data at the tail, incrementing
  ld L, A                       ; where tail is pointing (ensuring that there is
  ld B, (HL)                    ; no overflow), and saving the new value back in
  inc A                         ; the tail
  cp RX_BUF_SIZE
  jp nz, rx_buf_retr_byte_save_tail
  ld A, 0x00
rx_buf_retr_byte_save_tail:
  ld HL, RX_BUF_TAIL
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
#include "sio.s"
#include "ctc.s"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__uart_rx_available:
  push AF

  in A, (SIO_A_DATA)
  call f_uart_block_tx_empty
  inc A
  out (SIO_A_DATA), A
  call f_uart_block_tx_empty

  pop AF
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
