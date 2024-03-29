// Rom layout and bios assembler to C interface.
//
// Copyright (C) 2009-2013  Kevin O'Connor <kevin@koconnor.net>
//
// This file may be distributed under the terms of the GNU LGPLv3 license.


#include "asm-offsets.h" // BREGS_*
#include "config.h" // CONFIG_*
#include "entryfuncs.S" // ENTRY_*


/****************************************************************
 * Rom Header
 ****************************************************************/

        .section .rom.header
        .code16gcc
        .global _rom_header, _rom_header_size, _rom_header_checksum
_rom_header:
        .word 0xaa55
_rom_header_size:
        .byte 0
_rom_header_entry:
        jmp _optionrom_entry
_rom_header_checksum:
        .byte 0
_rom_header_other:
        .space 17
_rom_header_pcidata:
#if CONFIG_VGA_PCI == 1
        .word rom_pci_data
#else
        .word 0
#endif
_rom_header_pnpdata:
        .word 0
_rom_header_other2:
        .word 0
_rom_header_signature:
        .asciz "IBM"


/****************************************************************
 * Entry points
 ****************************************************************/

        // This macro is the same as ENTRY_ARG except the "calll"
        // instruction is avoided to work around known issues in the
        // emulation of some versions of x86emu.
        .macro ENTRY_ARG_VGA cfunc
        cli
        cld
        PUSHBREGS
        movw %ss, %ax           // Move %ss to %ds
        movw %ax, %ds
        movl %esp, %ebx         // Backup %esp, then zero high bits
        movzwl %sp, %esp
        movl %esp, %eax         // First arg is pointer to struct bregs
        pushw %ax ; callw \cfunc
        movl %ebx, %esp         // Restore %esp (including high bits)
        POPBREGS
        .endm

        DECLFUNC entry_104f05
entry_104f05:
        ENTRY_ARG_VGA vbe_104f05
        lretw

        DECLFUNC _optionrom_entry
_optionrom_entry:
        ENTRY_ARG_VGA vga_post
        lretw

        DECLFUNC entry_10
entry_10:
        ENTRY_ARG_VGA handle_10
        iretw

        // Entry point using extra stack
        DECLFUNC entry_10_extrastack
entry_10_extrastack:
        cli
        cld
        pushw %ds               // Set %ds:%eax to space on ExtraStack
        pushl %eax
        movzwl %cs:ExtraStackSeg, %eax
        movl %eax, %ds
        movl $(CONFIG_VGA_EXTRA_STACK_SIZE-BREGS_size-8), %eax
        popl BREGS_eax(%eax)    // Backup registers
        popw BREGS_ds(%eax)
        movl %edi, BREGS_edi(%eax)
        movl %esi, BREGS_esi(%eax)
        movl %ebp, BREGS_ebp(%eax)
        movl %ebx, BREGS_ebx(%eax)
        movl %edx, BREGS_edx(%eax)
        movl %ecx, BREGS_ecx(%eax)
        movw %es, BREGS_es(%eax)
        movl %esp, BREGS_size+0(%eax)
        movzwl %sp, %esp
        movw %ss, BREGS_size+4(%eax)
        movl (%esp), %edx
        movl %edx, BREGS_code(%eax)
        movw 4(%esp), %dx
        movw %dx, BREGS_flags(%eax)

        movw %ds, %dx           // Setup %ss/%esp and call function
        movw %dx, %ss
        movl %eax, %esp
        pushw %ax ; callw handle_10

        movl %esp, %eax         // Restore registers and return
        movw BREGS_size+4(%eax), %ss
        movl BREGS_size+0(%eax), %esp
        popl %edx
        popw %dx
        pushw BREGS_flags(%eax)
        pushl BREGS_code(%eax)
        movl BREGS_edi(%eax), %edi
        movl BREGS_esi(%eax), %esi
        movl BREGS_ebp(%eax), %ebp
        movl BREGS_ebx(%eax), %ebx
        movl BREGS_edx(%eax), %edx
        movl BREGS_ecx(%eax), %ecx
        movw BREGS_es(%eax), %es
        pushw BREGS_ds(%eax)
        pushl BREGS_eax(%eax)
        popl %eax
        popw %ds
        iretw
