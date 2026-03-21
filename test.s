.section .text
.global _start
_start:
        li      x1, 0x12345678
        li      x2, 0x44332211
        la      x3, _d2-1
        lw      x5, 0(x3)
_s0:    bgeu    x1, x2, _s3
# -------------------------------------
        sw      x2, 0(x3)
        lw      x4, 2(x3)
# -------------------------------------
        li      x4, 0x55302211
        sra     x1, x4, 1
        addi    x1, x0, -3
        addi    x2, x1, -24
        sub     x4, x2, x3
        jal     x5,_s2
# -------------------------------------
_s3:    li      x5, 0x11223344
        sw      x2, 0x5(x3)
_s1:    beq     x0, x0, _start
_s2:    jalr    x8, x5, 0

_d1:    .word   0xDEBA8050
_d2:    .word   0xDEBA80C0
