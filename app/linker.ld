SECTIONS
{
    . = 0x0; /* Стартовый адрес */

    .text : {
        *(.text.entry)
        *(.text)
    }

    .rodata : {
        *(.rodata .rodata.*)
    }

    .data : { 
        *(.data) 
    }

    .bss  : { 
        *(.bss)
    }

    _stack_top = 0x10000;

    /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) }
}