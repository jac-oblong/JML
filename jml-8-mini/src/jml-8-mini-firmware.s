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
;;      * function labels are preceded by 'f_' (meant to be called)
;;      * general flow control labels are not preceded by anything
;;      * labels in all caps are used to access data
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

;; DEFAULT STARTING LOCATION OF STACK
STACKSTART: equ 0x0000

;; LOCATION OF BASIC
BASIC:  equ 0x0380

;; STRING INFORMATION
NUL:  equ 0x00
TAB:  equ 0x09
LF:   equ 0x0A
CR:   equ 0x0D
DEL:  equ 0x7F


.org 0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_reset:
  jp init

;; used by BASIC
.org 0x0008
  jp f_uart_put_byte
.org 0x0010
  jp f_uart_get_byte
.org 0x0018
  jp f_uart_check_input

INIT_MESSAGE:
.text LF,CR,"(B)ASIC, (R)EAD MEM, (W)RITE MEM, (J)UMP MEM",LF,CR,NUL

init:
  ;; stackpointer
  ld hl, STACKSTART
  ld sp, hl

  ;; initializing other hardware
  call f_init_ctc
  call f_init_sio
  call f_uart_rx_on

monitor:
  ld HL, INIT_MESSAGE           ; print out init message
  call f_uart_put_string

  call f_uart_get_byte          ; get response
  and 0x5F                      ; capitalize the response
  cp 'B'                        ; check what user asked for
  jp z, BASIC
  cp 'R'
  jr z, monitor_read
  cp 'W'
  jr z, monitor_write
  cp 'J'
  jp z, monitor_jump
  jr monitor                    ; retry if response not recognized

MONITOR_READ_MSG:
  .text LF,CR,"READING, ENTER {START ADDR}:{END ADDR}",CR,LF,NUL
monitor_read:
  ld HL, MONITOR_READ_MSG
  call f_uart_put_string
  ld A, 0x00
  jr monitor_func

MONITOR_WRITE_MSG:
  .text LF,CR,"WRITING, ENTER {START ADDR} {DATA} {DATA}...\n",CR,LF,NUL
monitor_write:
  ld HL, MONITOR_WRITE_MSG
  call f_uart_put_string
  ld A, 0x01
  jr monitor_func

MONITOR_JUMP_MSG:
  .text LF,CR,"JUMPING, ENTER {ADDR}",CR,LF,NUL
monitor_jump:
  ld HL, MONITOR_JUMP_MSG
  call f_uart_put_string
  ld A, 0x02
  jr monitor_func

monitor_func:
  push AF
  ld A, '>'
  call f_uart_put_byte          ; print prompt
  call f_load_HL_hex
  pop AF
  cp 0x02                       ; did user specify to jump?
  jp nz, read_or_write
block_jump_newline:
  call f_uart_get_byte          ; wait for user to hit enter to actually jump
  cp CR
  jr nz, block_jump_newline
  jp HL                         ; if so, then jump
read_or_write:
  cp 0x01                       ; did user specify to write?
  jp z, write

  ;; now doing read operations
  ld BC, HL                     ; transfer starting point into BC
  call f_uart_get_byte          ; user will enter 'random' character between
  call f_uart_put_byte          ; start and end locations
  call f_load_HL_hex            ; load ending point into HL
block_read_newline:
  call f_uart_get_byte          ; wait for user to hit enter to start printing
  cp CR
  jr nz, block_read_newline
  call f_uart_put_byte          ; print out the newline
  ld A, LF
  call f_uart_put_byte
  ld E, 8                       ; how many bytes to print on each line
read_loop_outer:
  ld A, B                       ; print out BC in hex
  call f_print_A_hex
  ld A, C
  call f_print_A_hex
  ld A, ':'                     ; print out ":\t"
  call f_print_A_hex
  ld A, TAB
  call f_print_A_hex
  ;; print actual data in memory
  ld D, 0                       ; will keep track of how many times looped
read_loop_inner_hex:
  ld A, (BC)
  call f_print_A_hex            ; print out all data in hex with each byte
  ld A, ' '                     ; separated by spaces
  call f_print_A_hex
  inc D                         ; increment # of loops
  inc BC                        ; increment memory address pointer
  ld A, D
  cp E                         ; have we looped the correct # of times?
  jr nz, read_loop_inner_hex
  ;; end of this line
  ld A, LF                      ; print newline
  call f_print_A_hex
  ld A, CR
  call f_print_A_hex
  ;; compare BC and HL
  push HL                       ; save because we will modify
  scf
  ccf                           ; clear carry flag
  sbc HL, BC
  ld A, H
  cp 0
  jr nz, read_loop_outer_again  ; not done yet
  ld A, L
  cp 0
  jr z, exit_read               ; done with read
  cp 8
  jr nc, read_loop_outer_again  ; difference is greater than 8 so keep chugging
  ld E, L                       ; diff less than 8, so don't print all 8
read_loop_outer_again:
  pop HL
  jr read_loop_outer
exit_read:
  jp monitor

write:
  call f_uart_get_byte          ; space between address and data doesn't matter
  call f_uart_put_byte
write_loop:
  call f_load_A_hex             ; get value entered by user
  ld (HL),A                     ; load that data into memory
  inc HL
  call f_uart_get_byte          ; did user enter space or newline?
  call f_uart_put_byte
  cp CR
  jr nz, write_loop             ; if not newline, more data coming
  jp monitor                    ; done with write, back to monitor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; reads input until recieve 4 valid hex numbers, stores the value in HL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_load_HL_hex:
  push AF

  call f_load_A_hex
  ld H, A
  call f_load_A_hex
  ld L, A

  pop AF
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; reads input until recieved 2 valid hex numbers, stores value in A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
f_load_A_hex:
  push BC

  ld BC, 0                      ; B will keep track of loop (first or second)
get_hex_loop:
  call f_uart_get_byte          ; get newest byte
  call f_uart_put_byte          ; echo it back
  cp '0'
  jr c, not_hex                 ; not hex if less than '0'
  cp ':'
  jr c, numerical_hex           ; between '0' and '9', so a numerical hex number
  and 0x5F                      ; capitalize (we know either letter or not hex)
  cp 'A'
  jr c, not_hex                 ; not hex if less than 'A'
  cp 'G'
  jr c, alpha_hex               ; between 'A' and 'F', so alpha hex number
  ;; data was not hex, print out error message and reset (jump to 0x0000)
not_hex:
  ld HL, NOT_HEX_ERROR
  call f_uart_put_string
  jp 0x0000
NOT_HEX_ERROR:
  .text "ERROR: VALID HEX REQUIRED",LF,CR,LF,LF,NUL

numerical_hex:
  sub '0'                       ; convert from ascii to actual value
  jr store_value                ; store value in C (until done twice)

alpha_hex:
  sub 'A'                       ; convert from ascii to actual value
  add 10

store_value:
  bit 0, B                      ; is B even or odd? (0 or 1?)
  jr nz, is_odd
  sla A                         ; shift low nibble of A into high nibble
  sla A
  sla A
  sla A
is_odd:
  or C                          ; copy any data in high nibble of C into A
  ld C, A                       ; load data in A into C
should_repeat_again:
  inc B
  ld A, B
  cp 2                          ; have we gotten a full byte?
  jr nz, get_hex_loop           ; if not, get more
load_A_hex_end:
  ld A, C                       ; data in C should now be put in A
  pop BC
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; prints value stored in A in hex
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEX_VALUES:
  .text "0123456789ABCDEF"
f_print_A_hex:
  push AF
  push BC
  push HL

  ld HL, HEX_VALUES
  ld B, A                       ; B has copy of A

  and 0xF0                      ; zero out lower nibble of A
  ld C, A
  srl C                         ; put high nibble in lower nibble of C
  srl C
  srl C
  srl C
  ld A, B                       ; retrieve unmodified copy of A
  ld B, 0                       ; zero out B so we can do HL + BC and get hex
  push AF                       ; save value of AF (will be overwriting A soon)
  add HL, BC                    ; calculate which hex value to use
  ld A, (HL)
  call f_uart_put_byte          ; print out that hex
  pop AF                        ; restore value of AF
  and 0x0F                      ; zero out upper nibble of A
  ld C, A
  ld HL, HEX_VALUES
  add HL, BC                    ; calculate which hex value for lower nibble
  ld A, (HL)
  call f_uart_put_byte          ; print out that hex value

  pop HL
  pop BC
  pop AF
  ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INCLUDES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include "../include/sio.s"
#include "../include/ctc.s"
#include "basic.s"
