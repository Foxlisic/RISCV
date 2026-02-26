.section .text
.global _start
_start:
        li      x3, 0x5
        li      x2, 0xDEDABEEF
        sw      x2, 0x5(x3)
        la      x4, _s1
        addi    x1, x0, -3
        addi    x2, x0, 16
        sub     x3, x1, x2
_s1:    beq     x0, x0, _start
