.section .text
.global _start
_start:
        li      x1, 0x0000DEDA
        li      x2, 0xDEDABEEF
        la      x3, _s1
# -------------------------------------
        lw      x2, 0(x3)
# -------------------------------------
        sra     x1, x2, 2
        addi    x1, x0, -3
        addi    x2, x1, -24
        sub     x4, x2, x3
        jal     x5,_s2
# -------------------------------------
        li      x5, 0x11223344
        sw      x2, 0x5(x3)
_s1:    beq     x0, x0, _start
_s2:    jalr    x8, x5, 0
