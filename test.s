.section .text
.global _start
_start:
        li      x4, 4
        lw      x1, 0(x4)
_s2:    li      x1, 0x00020000
        li      x2, 0x12345678
        add     x2, x2, x4
        li      x3, 0x00020000 + 0x140*400
_s0:    sw      x2, 0(x1)
        add     x1, x1, 4
        add     x2, x2, 1
        bne     x1, x3, _s0
        add     x4, x4, 1
        j       _s2

