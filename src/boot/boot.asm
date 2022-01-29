ORG 0x7c00
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
	jmp short start	; short jump: jmp 3bytes(the 3 first of the BiosParameterBlock) 
	nop		; noOperation(in this 3bytes jump)

times 33 db 0		; leave alone 33 bytes(those for the BiosParameterBlock instructions)

start:
	jmp 0:step2	; this will make our code segment become 0x7c0

step2:
	cli 	; clear interrupts as we gonna segment(critical), we block any swap from bios
	mov ax, 0x00
	mov ds, ax	; ds = data segment	
	mov es, ax	; extra segment
	mov ss, ax 	; stack segment(at 0)
	mov sp, 0x7c00	; set stack pointer(so our stack will be 7c00 (bits ??)) 
	sti 	; enable interrupts	

.load_protected:
	cli
	lgdt[gdt_descriptor]	; load Global Descriptor Table
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax		; reset the registers now 
	jmp CODE_SEG:load32
	
; set the GDT (switch from real to protected mode)
gdt_start:
gdt_null:	; first thing we need is a null segment
	dd 0x0	; set 64 bits of 0
	dd 0x0
	
; offset 0x8 (offset of the table we are about to make the code descripter)
; we do not care much about it, it just the default setting to access full memory
gdt_code:		; CS should point to this
	dw 0xffff	; segment limit first 0-15 bits
	dw 0		; base 0-15 bits
	db 0		; base 16-23 bits
	db 0x9a		; Access byte
	db 11001111b	; Hight 4 bits flags and the low 4 bits flags
	db 0		; Base 24-31 bits

;offset 0x10
gdt_data:		; DS, SS, ES, FS, GS
	dw 0xffff	; segment limit first 0-15 bits
	dw 0		; base 0-15 bits
	db 0		; base 16-23 bits
	db 0x92		; Access byte
	db 11001111b	; Hight 4 bits flags and the low 4 bits flags
	db 0		; Base 24-31 bits

gdt_end:

gdt_descriptor:
	dw gdt_end -  gdt_start-1
	dd gdt_start

[BITS 32]
load32:
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov ebp, 0x00200000	; set the base pointer to point to
	mov esp, ebp		; set the stack pointer
	jmp $

	; enable the A20line
	; jump the 21st bit(its needed to fix a bug between 286 and 8086)
	in al, 0x92
	or al, 2
	out 0x92, al

error_message: db 'Failed to load sector', 0

times 510-($ - $$) db 0
dw 0xAA55

buffer: 	; we will use it later
