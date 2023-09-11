  ;; 'OS' for the jml-8 mini computer

org 0x0000

  ;;
  ;; Stall for a while
  ;;
  LD B, 0xFF
loop_outer:
  LD C, 0xFF
loop_inner:
  DEC C
  JR loop_inner

  DEC B
  JR loop_outer
