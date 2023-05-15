; Mouse Protocol Analyzer for serial mice
; Copyright (c) 1997-2002 Nagy Daniel <nagyd@users.sourceforge.net>
; This is a dirty-hack version of protocol.asm for the ISA Blaster.
; Copyright (c) 2023 Scrap Computing 
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
;
;

; %pagesize 255
; %noincl
;%macs
; %nosyms
;%depth 0
; %linum 0
; %pcnt 0
;%bin 0
; warn
; locals

; .model use16 tiny --- use jwasm -mt option instead

dataref equ <offset @data>	; offset relative data group

include ../asmlib/asm.mac
; *** include ../asmlib/hll.mac
include ../asmlib/code.def
include ../asmlib/code.mac
include ../asmlib/macro.mac
include ../asmlib/bios/area0.def
include ../asmlib/convert/digit.mac
include ../asmlib/convert/count2x.mac
include ../asmlib/dos/io.mac
include ../asmlib/dos/mem.mac
include ../asmlib/hard/pic8259a.def
include ../asmlib/hard/uart.def

nl		equ <13,10>
eos		equ <'$'>

say		macro	stroff:vararg
		MOVOFF_	dx,<stroff>
		call	saystr
endm


;€€€€€€€€€€€€€€€€€€€€€€€€€€€€ DATA SEGMENTS €€€€€€€€€€€€€€€€€€€€€€€€€€€€€

.data

S_COMinfo	db 'Dump data stream from working mouse. Press ESC to exit...',nl
		db '1200 bps, '
databits	db	     '5 data bits, '
stopbits	db			   '1 stop bit.',nl
		db 'Reset:',eos
S_spaces	db nl,' '
S_bitbyte	db	  '     ',eos
S_byte		db '   ',eos

.const

S_wrongPnP	db 'Wrong PnP data...'
CRLF2		db nl
CRLF		db nl,eos
PnP_OEM		db 'Manufacturer: ',eos
PnP_header	db '  Product ID: ',eos
PnP_hdnext	db '    Serial #: ',eos
		db '       Class: ',eos
		db '   Driver ID: ',eos
		db '   User name: ',eos
PnP_hdend	label byte

S_notCOM	db 'COM port not found!',nl,eos
Syntax		db 'Syntax: protocol <COM (1-4)> [<bytes in event (3-5)>'
		db			' [<COM LCR value (2-3)>]]',nl,eos

; .data?	; BSS

oldIRQaddr	dd ?		; old IRQ handler address

; programend segment virtual	; place at the end of current segment
; *** actually this was wrong in 2.0 - even TASM put queue at offset 0 :-p
	even
;!!! this segment placed at the end of .data? segment, which placed after
;!!! other segments, thus in .COM program PnPdata points after program
;!!! end and before stack top

PNPdata		label byte	; buffer for PnP data

queue		db 32 dup(?)	; queue for incoming serial data
queue_end	label byte

; programend ends


;€€€€€€€€€€€€€€€€€€€€€€€€€€€€€ CODE SEGMENT €€€€€€€€€€€€€€€€€€€€€€€€€€€€€

.code
; .startup	-- in jwasm this does "ds=dx=cs+0" (cs+0 is a reloc)
	org 100h
                assume ds:DGROUP
start::
		cld
		mov	si,80h			; offset PSP:cmdline_len
		lodsb
		cbw				; OPTIMIZE: instead MOV AH,0
		movadd	di,si,ax

		mov	al,3 			; IRQ 3
		mov	cl,al			; Save the IRQ number in cl
		add	al,8			; INT=IRQ+8
		mov	[IRQintnum],al
		mov	al,1
		shl	al,cl			; convert IRQ into bit mask
		mov	[PIC1state],al		; PIC interrupt disabler
		not	al
		mov	[notPIC1state],al	; PIC interrupt enabler

		mov	ax,2e8h			; IO Address 2e8
		mov	[IO_address],ax
	
	
		;mov	dx,dataref:S_notCOM
		;; jc	EXITERRMSG

		call	processmouse

HELP:		mov	dx,dataref:Syntax
EXITERRMSG:	say
		int	20h

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

skipwhite	proc
		cmp	di,si
;	if_ ae					; JB mean CF=1
	jb @@skipb
		lodsb
		cmp	al,' '
		jbe	skipwhite
		sub	al,'0'
		jb	HELP
		;clc
;	end_
@@skipb:
		ret
skipwhite	endp

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

processmouse	proc
		mov	ax,1Fh			; disable mouse
		call	mousedrv

;----- initialize mouse and dump PnP info

		mov	si,[IO_address]
		call	disableUART
		;; call	resetmouse

;----- install IRQ handler and enable interrupt

		mov	al,[IRQintnum]
;		DOSGetIntr
	mov ah,35h
	int 21h
		saveFAR [oldIRQaddr],es,bx	; save old IRQ handler
		;mov	al,[IRQintnum]
;		DOSSetIntr ,,,@code:IRQhandler
	mov dx,offset @code:IRQhandler
	mov ah,25h
	int 21h
		call	enableUART

;===== process mouse data until keystroke

		MOVSEG	es,ds,,@data
		mov	bx,dataref:queue

;	loop_
@@mainloop:	hlt
		mov	ah,1
		int	16h			; check for keystroke
;	while_ zero
	jnz @@emainloop	; at least this is what the HLL/TASM version had!
		cmp	bx,[queue@]
		je	@@mainloop

		cmp	bx,dataref:queue_end
;	 if_ ae
	jb @@mainb
		mov	bx,dataref:queue
;	 end_
@@mainb:
		mov	ah,[bx]
		inc	bx

		mov	di,dataref:S_bitbyte+1
;	 countloop_ 8				; 8 bits
	mov cx,8
@@cl8:
		mov	al,'0' shr 1
		rol	ax,1
		stosb
;	 end_
	loop @@cl8
		say	@data:S_bitbyte

;	CODE_	MOV_AL	IOdone,<db 0>		; processed bytes counter
	OPCODE_MOV_AL
IOdone	db 0
		inc	ax			; OPTIMIZE: AX instead AL
;	CODE_	CMP_AL	limit,<db 3>
	OPCODE_CMP_AL
limit	db 3
;	 if_ ae
	jb @@limitb
		say	@data:CRLF
		mov	al,0			; restart counter of bytes
;	 end_
@@limitb:
		mov	[IOdone],al
;	end_ loop
	j @@mainloop

;===== final: flush keystroke, deinstall handler and exit

@@emainloop:
		mov	ah,0
		int	16h			; get keystroke

		call	disableUART
;	CODE_	MOV_AX	IRQintnum,<db ?,25h>	; INT number of selected IRQ
	OPCODE_MOV_AX
IRQintnum	db ?, 25h
		lds	dx,[oldIRQaddr]
		assume	ds:nothing
		int	21h			; set INT in DS:DX

;----- reset mouse and exit through RET

		xor	ax,ax			; reset mouse
		;j	mousedrv
processmouse	endp
		assume	ds:@data

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

mousedrv	proc
		push	ax
		push	bx
		push	es
		DOSGetIntr 33h
		mov	ax,es
		test	ax,ax
		pop	es
		pop	bx
		pop	ax
;	if_ nz
	jz @@drvnoi33
		int	33h
;	end_
@@drvnoi33:
		ret
mousedrv	endp

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

;€€€€€€€€€€€€€€€€€€€€€€€€€€€€ COMM ROUTINES €€€€€€€€€€€€€€€€€€€€€€€€€€€€€

disableUART	proc
		in	al,PIC1_IMR		; {21h} get IMR
;	CODE_	OR_AL	PIC1state,<db ?>		; set bit to disable interrupt
	OPCODE_OR_AL
PIC1state	db ?
		out	PIC1_IMR,al		; {21h} disable serial interrupts
;-----
		movidx	dx,LCR_index,si		; {3FBh} LCR: DLAB off
;		 out_	dx,%LCR<>,%MCR<>	; {3FCh} MCR: DTR/RTS/OUT2 off
	xor ax,ax
	out dx,ax
		movidx	dx,IER_index,si,LCR_index
		 ;mov	ax,(FCR<> shl 8)+IER<>	; {3F9h} IER: interrupts off
		 out	dx,ax			; {3FAh} FCR: disable FIFO
		ret
disableUART	endp

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

enableUART	proc
		in	al,PIC1_IMR		; {21h} get IMR
;	CODE_	AND_AL	notPIC1state,<db ?>	; clear bit to enable interrupt
	OPCODE_AND_AL
notPIC1state	db ?
		out	PIC1_IMR,al		; {21h} enable serial interrupts
		ret
enableUART	endp

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

saystr		proc
		DOSWriteS
		ret
saystr		endp

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

byte2hexa	proc
		mov	cl,4
		_byte_hex_AX al,0,cl
		ret
byte2hexa	endp


;€€€€€€€€€€€€€€€€€€€€€€€€€€€€€ IRQ HANDLER €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€

IRQhandler	proc
		assume	ds:nothing,es:nothing,ss:nothing
		push	ax
		push	dx
		push	bx
;	CODE_	MOV_DX	IO_address,<dw ?>	; UART IO address
	OPCODE_MOV_DX
IO_address	dw ?
		push	dx
		movidx	dx,LSR_index
		 in	al,dx			; {3FDh} LSR: clear error bits
		xchg	bx,ax			; OPTIMIZE: instead MOV BL,AL
		pop	dx
		movidx	dx,RBR_index
		 in	al,dx			; {3F8h} flush receive buffer

		shr	bl,LSR_RBF+1
;	if_ carry				; process data if data ready
	jnc @@qnc
;	CODE_	MOV_BX	queue@,<dw dataref:queue>
	OPCODE_MOV_BX
queue@	dw dataref:queue
		cmp	bx,dataref:queue_end
;	 if_ ae
	jb @@qb
		mov	bx,dataref:queue
;	 end_
@@qb:
		mov	cs:[bx],al
		inc	bx
		mov	[queue@],bx
;	end_
@@qnc:
;		out_	PIC1_OCW2,%OCW2<OCW2_EOI> ; {20h} end of interrupt
	mov al,00100000b	; aaabbccc - nonspecific EOF
	out PIC1_OCW2,al
		pop	bx
		pop	dx
		pop	ax
		iret
IRQhandler	endp
		assume	ds:@data

;€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€

end start
