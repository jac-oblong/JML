;; 'OS' for the jml-8 mini computer

;; Brief explanation of organization:
;;
;; Everything is organized under 'headers'
;;
;; The interrupt table, interrupt definitions and function defintions are at the
;; end of the file (and end of rom)
;;
;; Labels are formatted in the following ways:
;;      * interrupt labels are preceded by '__' (2 underscores)
;;      * labels not designed to be called/jumped to are preceded by '_'
;;      * function labels are preceded by 'f_'
;;      * general flow control labels are not preceded by anything
;;
;; When calling a function, BC and HL are the only set of registers guaranteed
;; to not be changed, the SP will be edited as described in the functions
;; documentation, additionally, if reg I changes it will be listed in
;; documentation along with relevant change

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


.org 0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALIZE CTC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_init_ctc:
  ld A, 0x07                    ; initialize timer 0 of ctc to timer mode,
  out (CTC_TIMER0), A           ; no interrupt, /16 prescaler,
                                ; automatic triggering, time constant follows,
                                ; and reset

  ld A, 26                      ; count for ctc0, should generate ~9.6kHz
  out (CTC_TIMER0), A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALIZE SIO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_init_sio:
  ld A, 0x30                    ; reset any errors, select WR0
  out (SIO_A_CONT), A
  ld A, 0x18                    ; reset channel A
  out (SIO_A_CONT), A

  ld A, 0x04                    ; select WR4
  out (SIO_A_CONT), A
  ld A, 0x05                    ; odd parity, 1 stop bit, 8 data bits, x1 clock
  out (SIO_A_CONT), A

  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0xE8                    ; dtr active, enable tx, 8 data bits
  out (SIO_A_CONT), A

  ld A, 0x01                    ; select WR1
  out (SIO_B_CONT), A
  ld A, 0x04                    ; no interrupt in channel b, special rx conditon
                                ; affects int vec
  out (SIO_B_CONT), A

  ls A, 0x02                    ; select WR2
  out (SIO_B_CONT), A
  ld A, 0xF0                    ; load interrupt vector (lower 8 bits, lowest 4
                                ; will be changed to match vector)
  out (SIO_B_CONT), A

  ld A, 0x01                    ; select WR1
  out (SIO_A_CONT), A
  ld A, 0x10                    ; interrupt on all rx characters, parity error
                                ; is special condition
  out (SIO_A_CONT), A

  ld A, 0x03                    ; select WR1
  out (SIO_A_CONT), A
  ld A, 0xC1                    ; enable rx, 8 bits per character
  out (SIO_A_CONT), A

  ;; SIO channel A is now active, ready for use with UART

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_main:
  ls A, 0x1F
  ls I, A                       ; load I reg with 0x1F, used for int vectors
  im 2                          ; set interrupt mode to 2
  ei                            ; enable interrupts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION DEFINITIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_uart_rts_off:
  ;; turns off the RTS pin going from SIO to other device
  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0xE8                    ; DTR active, tx 8 bit, tx on, RTS off
  out (SIO_A_CONT), A
  ret

f_uart_rts_on:
  ;; turns on the RTS pin going from SIO to other device
  ld A, 0x05                    ; select WR5
  out (SIO_A_CONT), A
  ld A, 0xEA                    ; DTR active, tx 8 bit, tx on, RTS on
  out (SIO_A_CONT), A
  ret

f_uart_send_byte:
  ;; sends a single byte, the byte is expected to be in reg B when calling the
  ;; function, this function may 'block' until the tx buffer is empty

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPT TABLE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
