PHDRS
{
    text_pt PT_LOAD FLAGS(5); /* 101 RX для кода   */
    data_pt PT_LOAD FLAGS(6); /* 110 RW для данных */
}

SECTIONS
{
    . = 0x0; /* Стартовый адрес */

    .text   : { *(.text.init) *(.text) *(.text.*) } : text_pt
    .rodata : { *(.rodata .rodata.*) } : text_pt
    .data   : { *(.data) } : data_pt
    .bss    : { *(.bss) }  : data_pt

    _stack_top = 0x10000;

    /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) }
}
