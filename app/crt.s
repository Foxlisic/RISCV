# ------------------------------------------
.section .text.init
.global _start
.align  4
# ------------------------------------------
_start: la      sp, _stack_top
        call    main
loop:   j       loop
# ------------------------------------------
