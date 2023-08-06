EXTRN   DEVICE_LIST:DWORD
EXTRN   MEMORY_SIZE:WORD
EXTRN   CURRENT_DOS_LOCATION:WORD
EXTRN   FINAL_DOS_LOCATION:WORD
EXTRN   DEFAULT_DRIVE:BYTE
EXTRN   SYSINIT:FAR

BIOSSEG EQU     70h

CODE    SEGMENT
        ASSUME  CS:CODE,DS:CODE,ES:CODE,SS:CODE

START:
		jmp	INIT

                db 20 dup(0)

HEADER		db 'Ver 2.15'

DSKTBL		dw offset DSK_INIT
		dw offset MEDIACHK
		dw offset GET_BPB
		dw offset CMDERR
		dw offset DSK_READ
		dw offset BUS_EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset DSK_WRIT	; Write	operation
		dw offset DSK_WRTV

CONTBL		dw offset EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset CMDERR
		dw offset CON_READ
		dw offset CON_RDND
		dw offset EXIT
		dw offset CON_FLSH
		dw offset CON_WRIT
		dw offset CON_WRIT

AUXTBL		dw offset EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset CMDERR
		dw offset AUX_READ
		dw offset AUX_RDND
		dw offset EXIT
		dw offset AUX_FLSH
		dw offset AUX_WRIT
		dw offset AUX_WRIT
		dw offset AUX_WRST

TIMTBL		dw offset EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset CMDERR
		dw offset TIM_READ
		dw offset BUS_EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset TIM_WRT
		dw offset TIM_WRT
PRNTBL		dw offset EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset CMDERR
		dw offset EXITP
		dw offset BUS_EXIT
		dw offset EXIT
		dw offset EXIT
		dw offset PRN_WRT
		dw offset PRN_WRT
		dw offset PRN_STA
		dw offset EXIT

PTRSAV		dd 0
AUXNUM		db 0


STRATEGY	proc far
		mov	word ptr cs:PTRSAV, bx
		mov	word ptr cs:PTRSAV+2, es
		ret

CON_INT:
		push	si
		mov	si, offset CONTBL
		jmp	short ENTRY

AUX_INT:
		push	si
		push	ax
		xor	al, al
		jmp	short AUXENT

AUX2INT:
		push	si
		push	ax
		mov	al, 1
AUXENT:
		mov	si, offset AUXTBL
		jmp	short ENTRY1

PRN_INT:
		push	si
		push	ax
		xor	al, al
		jmp	short PRNENT

PRN2INT:
		push	si
		push	ax
		mov	al, 1
		jmp	short PRNENT

PRN3INT:
		push	si
		push	ax
		mov	al, 2
PRNENT:
		mov	si, offset PRNTBL
		jmp	short ENTRY1

TIM_INT:
		push	si
		mov	si, offset TIMTBL
		jmp	short ENTRY

DSK_INT:
		push	si
		mov	si, offset DSKTBL
ENTRY:
		push	ax
ENTRY1:
		push	cx
		push	dx
		push	di
		push	bp
		push	ds
		push	es
		push	bx
		mov	cs:AUXNUM, al
		lds	bx, cs:PTRSAV
		mov	al, [bx+1]	; UNIT
		mov	ah, [bx+0Dh]	; MEDIA
		mov	cx, [bx+12h]	; COUNT
		mov	dx, [bx+14h]	; START
		xchg	ax, di
		mov	al, [bx+2]	; CMD
		xor	ah, ah
		add	si, ax
		add	si, ax
		cmp	al, 0Bh		; is command code a valid number?
		ja	CMDERR
		xchg	ax, di
		les	di, [bx+0Eh]	; TRANS
		push	cs
		pop	ds
		jmp	word ptr [si]

BUS_EXIT:
		mov	ah, 3
		jmp	short ERR1
CMDERR:
		mov	al, 3
DEVERR:
		lds	bx, PTRSAV
		sub	[bx+12h], cx
		mov	ah, 81h
		jmp	short ERR1

EXITP:
		lds	bx, PTRSAV
		xor	ax, ax
		mov	[bx+12h], ax
EXIT:
		mov	ah, 1
ERR1:
		lds	bx, cs:PTRSAV
		mov	[bx+3],	ax
		pop	bx
		pop	es
		pop	ds
		pop	bp
		pop	di
		pop	dx
		pop	cx
		pop	ax
		pop	si
		ret
STRATEGY	endp


OUTCHR:
		sti
		push	ax
		mov	bx, 7
		mov	ah, 0Eh
		int	10h		; Write TTY
		pop	ax
		iret


GETDX:
		mov	dl, AUXNUM
		xor	dh, dh
		ret

CBREAK:
		mov	cs:ALTAH, 3
;		nop
INTRET:
		iret

DEVSTART	dw offset AUXDEV
		dw BIOSSEG
		dw 8013h
		dw offset STRATEGY
		dw offset CON_INT
                db 'CON     '

ALTAH		db 0

CON_READ:
		jcxz	CONR_DON

CONRNXT:
		push	cx
		call	CHRIN
		pop	cx
		stosb
		loop	CONRNXT

CONR_DON:
		jmp	EXIT


CHRIN:
		xor	ax, ax
		xchg	al, ALTAH
		or	al, al
		jnz	KEYRET
		int	16h		; KBD: Read char from buffer with wait
		or	ax, ax
		jz	CHRIN
		cmp	ax, 7200h	; Check	for CTRL-PRTSC
		jnz	ALT15
		mov	al, 16		; indicate prtsc
ALT15:
		or	al, al
		jnz	KEYRET
		mov	ALTAH, ah
KEYRET:
		ret

CON_RDND:
		mov	al, ALTAH
		or	al, al
		jnz	RDEXIT
		mov	ah, 1
		int	16h		; KBD: Buffer peek, ZF set if empty
		jz	CONBUS
		or	ax, ax
		jnz	NOTBRK
		mov	ah, 0
		int	16h		; KBD: Read char from buffer with wait
		jmp	CON_RDND
NOTBRK:
		cmp	ax, 7200h	; check	for ctrl-prtsc
		jnz	RDEXIT
		mov	al, 16
RDEXIT:
		lds	bx, PTRSAV
		mov	[bx+0Dh], al
EXVEC:
		jmp	EXIT

CONBUS:
		jmp	BUS_EXIT

CON_FLSH:
		call	FLUSH
		jmp	EXVEC

FLUSH:
		mov	ALTAH, 0	; Clear	pending	character
		push	ds
		xor	bp, bp
		mov	ds, bp
		mov	byte ptr ds:[41Ah], 1Eh ; Empty BIOS keyboard buffer
		mov	byte ptr ds:[41Ch], 1Eh
		pop	ds
		ret

CON_WRIT:
		jcxz	EXVEC
CONWNXT:
		mov	al, es:[di]
		inc	di
		push	cx
		push	di
		int	29h		; Shortcut to OUTCHR
		pop	di
		pop	cx
		loop	CONWNXT
		jmp	EXVEC

AUXDEV		dw offset PRNDEV
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset AUX_INT
                db 'AUX     '

DEVCOM1		dw offset DEVLPT1
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset AUX_INT
                db 'COM1    '

AUXBUF		db    0
		db    0

AUX_READ:
		jcxz	EXVEC2
		call	GETBX
		xor	ax, ax
		xchg	al, [bx]
		or	al, al
		jnz	AUX2

AUX1:
		call	AUXIN
AUX2:
		stosb
		loop	AUX1

EXVEC2:
		jmp	EXIT


AUXIN:
		mov	ah, 2
		call	AUXSVC
		test	ah, 0Eh
		jz	AROK
		pop	ax
		mov	al, 0Bh		; report a 'read error'
		jmp	DEVERR

AROK:
		ret


AUX_RDND:
		call	GETBX
		mov	al, [bx]
		or	al, al
		jnz	AUXRDX
		call	AUXSTAT
		test	ah, 1
		jz	AUXBUS
		test	al, 20h
		jz	AUXBUS
		call	AUXIN
		call	GETBX
		mov	[bx], al
AUXRDX:
		jmp	RDEXIT

AUXBUS:
		jmp	BUS_EXIT

AUX_WRST:
		call	AUXSTAT
		test	al, 20h
		jz	AUXBUS
		test	ah, 20h
		jz	AUXBUS
		jmp	EXVEC2


AUXSTAT:
		mov	ah, 3
AUXSVC:
		call	GETDX
		int	14h             ; Serial service
		ret

AUX_FLSH:
		call	GETBX
		mov	byte ptr [bx], 0
		jmp	EXVEC2
AUX_WRIT:
		jcxz	EXVEC2
AUX_LOOP:
		mov	al, es:[di]
		inc	di
		mov	ah, 1
		call	AUXSVC
		test	ah, 80h
		jz	AWOK
		mov	al, 0Ah
		jmp	DEVERR
AWOK:
		loop	AUX_LOOP
		jmp	EXVEC2


GETBX:
		call	GETDX
		mov	bx, dx
		add	bx, offset AUXBUF
		ret


PRNDEV		dw offset TIMDEV
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset PRN_INT
                db 'PRN     '

DEVLPT1		dw offset DEVLPT2
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset PRN_INT
                db 'LPT1    '

PRNBYTE 	db 0

PRN_WRT:
		jcxz	EXVEC3

PRN_LOOP:
		mov	al, es:[di]
		inc	di
		mov	PRNBYTE, 0

PRNL1:
		xor	ah, ah
		call	PRNOP
		jz	GOPRLP
		xor	PRNBYTE, 1
		jnz	PRNL1
PMESSG:
		jmp	DEVERR

GOPRLP:
		loop	PRN_LOOP

EXVEC3:
		jmp	EXIT

PRN_STA:
		call	PRNSTAT
		jnz	PMESSG
		test	ah, 80h
		jnz	EXVEC3
		jmp	BUS_EXIT

PRNSTAT:
		mov	ah, 2
PRNOP:
		call	GETDX
		int	17h             ; Printer service
		mov	al, 2		; error_I24_not_ready
		test	ah, 1
		jnz	PRNOP2
		mov	al, 10
		test	ah, 8
		jz	PRNOP2
		test	ah, 20h
		jz	PRNOP1
		mov	al, 9
PRNOP1:
		or	al, al
PRNOP2:
		ret


TIMDEV		dw offset DSKDEV
		dw BIOSSEG
		dw 8008h
		dw offset STRATEGY
		dw offset TIM_INT
                db 'CLOCK$  '

DAYCNT		dw 0


TIM_WRT:
		mov	ax, es:[di]	; Days since 1-1-1980
		push	ax		; Save on the stack for	later
		mov	cx, es:[di+2]	; Minutes (CL) and hours (CH)
		mov	dx, es:[di+4]	; 100ths of second (DL)	and seconds (DH)
		mov	al, 60
		mul	ch		; Convert hours	to minutes
		mov	ch, 0
		add	ax, cx		; AX now holds hours+mins in minutes
		mov	cx, 6000	; 100ths of seconds in a minute
		mov	bx, dx		; Stash	DX (seconds and	100ths)	in BX
		mul	cx		; DX:AX	now holds hours/minutes	in 100ths of seconds
		mov	cx, ax		; Stash	low word of result in CX
		mov	al, 100
		mul	bh		; AX now has seconds in	100ths/sec
		add	cx, ax		; Add seconds to DX:CX
		adc	dx, 0
		mov	bh, 0		; BX now hold only 100ths/sec
		add	cx, bx		; Add 100ths fo	DX:CX
		adc	dx, 0
		xchg	ax, dx		; Swap DX:CX into DX:AX
		xchg	ax, cx		; DX:CX	now holds time of day in 100ths	of a second
		mov	bx, 59659	; 1,193,180 * 5	/ 100
		mul	bx		; Multiply high	word
		xchg	dx, cx		; Swap DX:AX with CX:DX
		xchg	ax, dx
		mul	bx		; Multiply low word
		add	ax, cx
		adc	dx, 0		; DX:AX	now holds timer	ticks *	5
		xchg	ax, dx		; Swap around DX and AX
		mov	bx, 5		; AX now has the high word
		div	bl		; Divide AX by 5
		mov	cl, al		; Put quotient in CL
		mov	ch, 0		; And zero extend (we know result will fit)
		mov	al, ah		; Now move remainder into AL
		cbw			; And sign extend
		xchg	ax, dx		; DX now holds remainder, AX the low word
		div	bx		; Now divide DX:AX by 5
		mov	dx, ax		; And put the result (low word)	back in	DX
		cli			; Prevent clock	interrupts?
		mov	ah, 1
		int	1Ah		; CLOCK	- SET TIME OF DAY
					; CX:DX	= clock	count
					; Return: time of day set
		pop	DAYCNT
		sti
		jmp	EXIT

TIM_READ:
		xor	ah, ah
		int	1Ah		; Get time of day (ticks in CX:DX), AL !=0 if rollover
		or	al, al
		jz	SAMEDAY
		inc	DAYCNT
SAMEDAY:
		mov	si, DAYCNT
		mov	ax, cx		; CX:DX	to AX:BX
		mov	bx, dx
		shl	dx, 1		; Multiply CX:DX by 4
		rcl	cx, 1
		shl	dx, 1
		rcl	cx, 1
		add	dx, bx		; Add to multiply by 5
		adc	ax, cx
		xchg	ax, dx		; AX:DX	now holds initial timer	ticks *	5
		mov	cx, 59659	; 1,193,180 * 5	/ 100
		div	cx
		mov	bx, ax		; Stash	quotient in BX
		xor	ax, ax
		div	cx		; Now divide the remainder
		mov	dx, bx
		mov	cx, 200
		div	cx
		cmp	dl, 100
		jb	NOADJ
		sub	dl, 100
NOADJ:
		cmc
		mov	bl, dl		; Store	100ths in BL
		rcl	ax, 1		; Multiply by two again
		mov	dl, 0
		rcl	dx, 1
		mov	cx, 60
		div	cx
		mov	bh, dl		; Store	seconds	in BH
		div	cl		; Divide AX by 60
		xchg	al, ah		; Swap quotient	and remainder
		push	ax
		mov	ax, si		; Days since 1-1-1980
		stosw
		pop	ax		; Minutes (AL) and hours (AH)
		stosw
		mov	ax, bx		; 100ths of second (AL)	and seconds (AH)
		stosw
		jmp	EXIT

DSKDEV		dw offset DEVCOM1
		dw BIOSSEG
		dw 0
		dw offset STRATEGY
		dw offset DSK_INT

DRVMAX		db 4
CURDRV		db 0FFh			; Current floppy drive
CURCYL		db 0			; Current floppy cylinder
CURDISK 	db 0FFh
TIM_LO		dw 0FFFFh
TIM_HI		dw 0FFFFh
RFLAG		dw 2
PHANTOM 	db 0
MOVFLG		db 0
word_3E2	dw 0
HARDNUM		db 99
DRIVENUM	db 0
CURHD		db 0
CURSEC		db 0
CURTRK		dw 0
SPSAV		dw 0


MEDIACHK:
		mov	di, 1
		test	ah, 4
		jz	MEDCHG
		xor	di, di
		mov	si, offset CURDISK
		cmp	al, [si]
		jnz	MEDCHG
		xor	ah, ah
		int	1Ah		; Get time of day (ticks in CX:DX), AL !=0 if rollover
		or	al, al
		jz	NOROLL
		inc	DAYCNT
NOROLL:
		sub	dx, [si+1]	; TIM_LO
		sbb	cx, [si+3]	; TIM_HI
		or	cx, cx
		jnz	MEDCHG
		or	dx, dx
		jz	MEDCHG
		cmp	dx, 40		; 40 ticks is a	little over 2 seconds
		ja	MEDCHG

		inc	di		; Media	not changed
MEDCHG:
		lds	bx, PTRSAV
		mov	[bx+0Eh], di
		jmp	EXIT

GET_BPB:
		mov	ah, es:[di]
		call	SETDRIVE
GET_BP1:
		lds	bx, PTRSAV
		mov	[bx+0Dh], ah
		mov	[bx+12h], di
		mov	word ptr [bx+14h], cs
		jmp	EXIT

SETDRIVE:
		push	ax
		push	cx
		push	dx
		push	bx
		mov	cl, ah
		and	cl, 0F8h
		cmp	cl, 0F8h	; Top 5	bits set?
		jz	IDGOOD
		mov	ah, 0FEh
IDGOOD:
		mov	di, offset HDRIVE
		cmp	al, [HARDNUM]
		jz	GOTDRIVE
		jb	GETFLPY
		mov	di, offset DRIVEX
		jmp	short GOTDRIVE

GETFLPY:
		mov	al, 1
		mov	bx, 4008h
		mov	cx, 320
		mov	dx, 101h
		mov	di, offset FDRIVE
		test	ah, 2		; 9 spt	rather than 8?
		jnz	CHKSID
		inc	al
		inc	bl		; Increment sectors per	track
		add	cx, 40		; Add 40 sectors per side
CHKSID:
		test	ah, 1		; Double sided disk?
		jz	FILLBPB
		add	cx, cx		; Double total sectors
		mov	bh, 112		; More root dir	entries
		inc	dh		; Increment sides
		inc	dl		; and sectors per cluster
FILLBPB:
		mov	[di+2],	dh
		mov	[di+6],	bh
		mov	[di+8],	cx
		mov	[di+0Ah], ah
		mov	[di+0Bh], al
		mov	[di+0Dh], bl
		mov	[di+0Fh], dl
GOTDRIVE:
		pop	bx
		pop	dx
		pop	cx
		pop	ax
		ret


FDRIVE		dw 512                  ; Bytes per sector
		db 1			; Sectors per cluster
		dw 1			; Reserved sectors
		db 2			; No. of FATs
		dw 64			; Root dir entries
		dw 360			; Total	sectors
		db 0FCh			; Media	descriptor byte
		dw 2			; Number of FAT	sectors
		dw 9			; Sectors per track
		dw 1			; Head limits
		dw 0			; Hidden sectors

DSK_READ:
		call	DISKRD
		jmp	short DSKDON

DSK_WRTV:
		mov	RFLAG, 103h	; Write	with verify
		jmp	short GODSK

DSK_WRIT:
		mov	RFLAG, 3	; Write	operation
GODSK:
		call	DISKIO
DSKDON:
		jnb	DSKXIT
		jmp	DEVERR

DSKXIT:
		jmp	EXIT

DISKRD:
		mov	byte ptr RFLAG, 2 ; Read operation
DISKIO:
		clc
		jcxz	IORET
		mov	CURDISK, al
		mov	SPSAV, sp
		xchg	bx, di
		call	SETDRIVE
		mov	si, dx
		add	si, cx
		add	dx, [di+11h]
		cmp	si, [di+8]
		jbe	DRVOK
		mov	al, 8
		stc
IORET:
		ret

DRVOK:
		cmp	al, [HARDNUM]
		jb	CHKSNG
		mov	al, HARDDRV
		jz	GOTDRV
		inc	al
		jmp	short GOTDRV

CHKSNG:
		cmp	PHANTOM,1
		jnz	GOTDRV
		call	SWPDSK
GOTDRV:
		mov	DRIVENUM, al
		mov	word_3E2, cx
		xchg	ax, dx
		xor	dx, dx
		div	word ptr [di+0Dh]
		inc	dl
		mov	CURSEC, dl
		mov	cx, [di+0Fh]
		xor	dx, dx
		div	cx
		mov	CURHD, dl
		mov	CURTRK, ax
		mov	ax, word_3E2
		mov	si, es
		shl	si, 1
		shl	si, 1
		shl	si, 1
		shl	si, 1
		add	si, bx
		add	si, 511
		jb	BUFFER
		xchg	bx, si
		shr	bh, 1
		mov	ah, 80h
		sub	ah, bh
		xchg	bx, si
		cmp	ah, al
		jbe	DOBLOCK
		mov	ah, al
DOBLOCK:
		push	ax
		mov	al, ah
		call	BLOCK
		pop	ax
		sub	al, ah
		jz	CHKTIM

BUFFER:
		push	ax
		push	es
		push	bx
		call	MOVE
		add	bh, 2
		call	DISK1
		pop	bx
		pop	es
		pop	ax
		call	MOVE
		dec	al
		add	bh, 2
		call	BLOCK
CHKTIM:
		xor	ah, ah
		int	1Ah		; Get time of day (ticks in CX:DX), AL !=0 if rollover
		or	al, al		; Passed midnight?
		jz	NOROLL2
		inc	DAYCNT	        ; Yes, increment date
NOROLL2:
		mov	TIM_LO, dx
		mov	TIM_HI, cx
		clc
		ret


MOVE:
		push	di
		push	bx
		push	ax
		mov	di, bx
		add	bh, 2
		mov	si, bx
		cld
		mov	cx, 256
MOVW:
		mov	bx, es:[di]
		mov	ax, es:[si]
		mov	es:[si], bx
		stosw
		inc	si
		inc	si
		loop	MOVW
		xor	MOVFLG, 1
		pop	ax
		pop	bx
		pop	di
RETZ:
		ret


BLOCK:
		or	al, al
		jz	RETZ
		mov	ah, [di+0Dh]
		inc	ah
		sub	ah, CURSEC
		cmp	ah, al
		jbe	GOTMIN
		mov	ah, al
GOTMIN:
		push	ax
		mov	al, ah
		call	DISK
		pop	ax
		sub	al, ah
		shl	ah, 1
		add	bh, ah
		jmp	BLOCK


DISK1:
		mov	al, 1
DISK:
		mov	si, 5		; Retry	count
		mov	ah, byte ptr RFLAG
RETRY:
		push	ax
		mov	dx, CURTRK
		mov	cl, 6
		shl	dh, cl
		or	dh, CURSEC
		mov	cx, dx
		xchg	ch, cl
		mov	dx, word ptr DRIVENUM
		test	dl, 80h		; Is it	a hard disk?
		jnz	DOIO
		cmp	ah, 2		; Is it	a read?
		jz	SETTLIO
		cmp	dl, CURDRV
		jnz	DOIO
		cmp	ch, CURCYL
		jnz	DOIO

SETTLIO:
		call	FastSettle
		int	13h             ; Disk service
		call	SlowSettle
		jmp	short IODONE

DOIO:
		int	13h             ; Disk service
IODONE:
		pushf
		test	dl, 80h
		jnz	CHKVFY
		mov	CURDRV, dl
		mov	CURCYL, ch
CHKVFY:
		popf
		jb	AGAIN
		pop	ax
		push	ax
		cmp	RFLAG, 103h	; Write	with verify?
		jnz	NOVFY
		mov	ah, 4		; Verify
		call	FastSettle
		int	13h             ; Disk service
		call	SlowSettle
		jb	AGAIN

NOVFY:
		pop	ax
		and	cl, 3Fh
		xor	ah, ah
		sub	word_3E2, ax
		add	cl, al
		mov	CURSEC, cl
		cmp	cl, [di+0Dh]
		jbe	DSKRET
		mov	CURSEC, 1
		mov	dh, CURHD
		inc	dh
		cmp	dh, [di+0Fh]
		jb	SAVHD
		xor	dh, dh
		inc	CURTRK
SAVHD:
		mov	CURHD, dh
DSKRET:
		ret

SettleValue	db 0Fh

FastSettle	proc near
		mov	SettleValue,0
		jmp	short SetSettle
FastSettle	endp

SlowSettle	proc near
		mov	SettleValue,0Fh
SetSettle:
		pushf
		push	ds
		push	ax
		xor	ax, ax
		mov	ds, ax
		mov	al, cs:SettleValue
		mov	byte ptr ds:[52Bh], al ; Disk head settle? See DOS 3.21 OAK
		pop	ax
		pop	ds
		popf
		ret
SlowSettle	endp

AGAIN:
		push	ax
		mov	ah, 0
		int	13h		; Reset disk
		mov	CURDRV, -1
		pop	ax
		dec	si		; Decrement retry count
		jz	NORETRY
		cmp	ah, 80h
		jz	NORETRY
		pop	ax
		jmp	RETRY

NORETRY:
		cmp	MOVFLG, 0
		jz	MAPERROR
		pop	bx
		pop	bx
		pop	es
		call	MOVE
MAPERROR:
		push	cs
		pop	es
		mov	al, ah
		mov	ERROUT, al
		mov	cx, 7
		nop
		mov	di, offset ERRIN
		repne scasb
		mov	al, [di+NUMERR]
		mov	cx, word_3E2
		mov	sp, SPSAV
		stc
		ret

ERRIN		db 80h
		db 40h
		db 10h
		db 8
		db 4
		db 3
ERROUT		db 0
		db 2
		db 6
		db 4
		db 4
		db 8
		db 0
		db 0Ch

NUMERR  =       ERROUT-ERRIN

DSK_INIT:
		mov	ah, DRVMAX
		mov	di, offset DSKDRVS
		jmp	GET_BP1

DSKDRVS		dw offset FDRIVE
		dw offset FDRIVE
		dw offset FDRIVE
		dw offset FDRIVE
HDSKTAB		dw offset HDRIVE
		dw offset DRIVEX

DEVLPT2		dw offset DEVLPT3
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset PRN2INT
                db 'LPT2    '

DEVLPT3		dw offset DEVCOM2
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset PRN3INT
                db 'LPT3    '

DEVCOM2		dw 0FFFFh
		dw BIOSSEG
		dw 8000h
		dw offset STRATEGY
		dw offset AUX2INT
                db 'COM2    '

SWPDSK		proc near
		push	ds
		xor	si, si
		mov	ds, si
		mov	ah, al
		xchg	ah, ds:[504h]
		pop	ds
		cmp	al, ah
		jz	NOSWP
		add	al, 'A'
		mov	SNGMSG+1Ch,al
		mov	si, offset SNGMSG
		push	bx
		call	WRMSG
		call	FLUSH
		xor	ah, ah
		int	16h		; KBD: Buffer peek, ZF set if empty
		pop	bx
NOSWP:
		xor	al, al
WRMRET:
		ret
SWPDSK		endp


WRMSG:
		lodsb
		and	al, 7Fh
		jz	WRMRET
		int	29h             ; Shortcut to OUTCHR
		jmp	WRMSG


SNGMSG		db 13,10
		db 'Insert diskette for drive A: and strike',13,10
		db 'any key when ready',13,10
		db 10,0

HNUM		db 0
HARDDRV		db 80h

HDRIVE		dw 512
		db 1
		dw 1
		db 2
		dw 16
		dw 0
		db 0F8h
		dw 1
		dw 0
		dw 0
		dw 0

DRIVEX		dw 512
		db 0
		dw 1
		db 2
		dw 0
		dw 0
		db 0F8h
		dw 0
		dw 0
		dw 0
		dw 0

DRVFAT		dw 0
BIOSTRT		dw 0
DOSCNT		dw 0

INIT:
		xor	dx, dx
		cli
		mov	ss, dx
		mov	sp, 700h
		sti
		push	cx		; save number of floppies and media byte
		mov	cs:BIOSTRT, bx	; save first data sector
		push	ax		; save boot drive number, and media byte
		mov	al, 20h
		out	20h, al		; Interrupt controller,	8259A.
		mov	si, offset DEVCOM2
		call	AUX_INIT
		mov	si, offset DEVCOM1
		call	AUX_INIT
		mov	si, offset DEVLPT3
		call	PRINT_INIT
		mov	si, offset DEVLPT2
		call	PRINT_INIT
		mov	si, offset DEVLPT1
		call	PRINT_INIT
		xor	dx, dx
		mov	ds, dx		; Set DS, ES to	zero
		mov	es, dx
		mov	ax, cs
		mov	ds:[6Ch], offset CBREAK ; INT 1Bh
		mov	ds:[6Eh], ax
		mov	word ptr ds:[0A4h], offset OUTCHR ; INT 29h
		mov	word ptr ds:[0A6h], ax
		mov	ds:[78h], 522h  ; Set INT 1Eh to 0:522
		mov	ds:[7Ah], es
		mov	di, 4		; INT 2	(NMI)
		mov	bx, offset INTRET
		xchg	ax, bx
		stosw
		xchg	ax, bx
		stosw
		add	di, 4
		xchg	ax, bx
		stosw
		xchg	ax, bx
		stosw
		xchg	ax, bx
		stosw
		xchg	ax, bx
		stosw
		add	di, 28h	; '('
		xchg	ax, bx
		stosw
		xchg	ax, bx
		stosw
		mov	word ptr ds:[500H], dx
		mov	word ptr ds:[504H], dx
		mov	di, 522h	; Write	DPT to 0:522
		mov	ax, 2DFh
		stosw
		mov	ax, 225h
		stosw
		mov	ax, 2A09h	; 9 sectors per	track
		stosw
		mov	ax, 50FFh
		stosw
		mov	ax, 0FF6h
		stosw
		mov	al, 2
		stosb
		int	12h		; Get memory size in 1K units
		mov	cl, 6		; Convert KB to	paragraphs
		shl	ax, cl
		pop	cx
		mov	cs:DRVFAT, cx
		mov	dx, 11Bh
		mov	ds, dx
		assume ds:nothing
		mov	ds:MEMORY_SIZE,	ax ; Mem size in paras
		inc	cl
		mov	ds:DEFAULT_DRIVE, cl ; Store to	DEFAULT_DRIVE
		mov	word ptr ds:CURRENT_DOS_LOCATION, 21Bh
		mov	word ptr ds:FINAL_DOS_LOCATION, 0EAh
		mov	word ptr ds:DEVICE_LIST, offset	DEVSTART ; To DEVICE_LIST
		mov	ax, cs
		mov	word ptr ds:DEVICE_LIST+2, ax ;	DEVICE_LIST segment
		push	cs
		push	cs
		pop	ds
		assume ds:CODE
		pop	es
		xor	si, si          ; Write to 70:0, FORMAT looks there
		mov	word ptr [si], offset HARDDRV
		int	11h		; Get equipment flags
		and	al, 0C0h
		jnz	MORDRV
		inc	PHANTOM
MORDRV:
		pop	ax
		mov	[HARDNUM], al
		mov	[DRVMAX], al
		shl	ax, 1
		mov	di, offset DSKDRVS
		add	di, ax
		mov	si, offset HDSKTAB
		movsw
		movsw
		mov	ah, 8
		mov	dl, 80h
		int	13h		; Get drive parameters (1st hard disk)
		jb	ENDDRV

		mov	HNUM, dl        ; Number of hard disks
ENDDRV:
		mov	dl, 80h
		mov	di, offset HDRIVE
		cmp	HNUM, 0
		jle	CONFIGURE
		call	SETHARD
		mov	dl, 81h
		mov	di, offset DRIVEX
		jc	CHKHD2
		cmp	HNUM, 2
		jz	TWOHD
		jmp	short SETIT

CHKHD2:
		mov	HARDDRV, dl
		mov	di, offset HDRIVE
		dec	HNUM
		cmp	HNUM, 0
		jz	CONFIGURE
TWOHD:
		call	SETHARD
		jnb	SETIT
		dec	HNUM
SETIT:
		mov	al, HNUM
		or	al, al
		jz	CONFIGURE
		add	al, [HARDNUM]
		mov	DRVMAX, al
		mov	al, HNUM
		jmp	short CFGHD

CONFIGURE:
		cmp	PHANTOM, 1
		jz	CFGDONE
		mov	dx, SEG SYSINIT
		mov	ds, dx
		assume ds:nothing
		mov	word ptr ds:FINAL_DOS_LOCATION, 0E3h
		jmp	short CFGDONE

CFGHD:
		mov	dx, SEG SYSINIT
		mov	ds, dx
		mov	word ptr ds:FINAL_DOS_LOCATION, 0EBh
		dec	al
		jz	CFGDONE
		mov	word ptr ds:FINAL_DOS_LOCATION, 0ECh
CFGDONE:
		push	cs
		pop	ds
		assume ds:CODE
		call	GETFAT
		xor	di, di
		mov	al, es:[di]
		mov	byte ptr DRVFAT+1, al
		mov	ax, DRVFAT
		call	SETDRIVE
		mov	cl, [di+2]
		mov	ax, [di+11h]
		sub	BIOSTRT, ax
		xor	ch, ch
		push	ds
		xor	di, di
		mov	ds, di		; ES:DI	POINTS TO LOAD LOCATION
		mov	bx, word ptr ds:[53Ah]	; clus=*53A;
		pop	ds
LOADIT:
		mov	ax, 21Bh
		mov	es, ax
		assume es:nothing
		call	GETCLUS
		cmp	bx, 0FFFh
		jnz	LOADIT
		jmp	SYSINIT

GETFAT:
		xor	di, di
		mov	cx, 1
		mov	dx, cx
		mov	ax, 7C0h	; FATLOC
		mov	es, ax
		mov	al, byte ptr DRVFAT
		mov	ah, 0FCh
		jmp	DISKRD


GETBOOT:
		mov	cx, 1
		mov	ax, 201h	; Read one sector
		mov	bx, 7C0h	; Read to 7C0:0	aka 0:7C00
		mov	es, bx
		xor	bx, bx
		mov	dh, bh
		int	13h
		jb	ERRET
		cmp	word ptr es:1FEh, 0AA55h ; Check boot sector signature
		jnz	ERRET
		ret


SETHARD:
		push	dx
		mov	ah, 8
		int	13h		; Get drive parameters
		inc	dh
		mov	[di+0Fh], dh
		pop	dx
		jb	ERRET
		and	cl, 3Fh		; extract number of sectors/track
		mov	[di+0Dh], cl
		call	GETBOOT		; Check	boot sector signature
		jb	ERRET
		mov	bx, 1C2h
SET1:
		cmp	byte ptr es:[bx], 1
		jz	SET2
		add	bx, 16
		cmp	bx, 202h
		jnz	SET1

ERRET:
		stc
		ret

SET2:
		mov	ax, es:[bx+4]
		mov	[di+11h], ax
		mov	ax, es:[bx+8]
		cmp	ax, 40h
		jb	ERRET
		mov	[di+8],	ax
		mov	cx, 100h
		mov	dx, 40h
		cmp	ax, 200h
		jbe	GOTPARM
		add	ch, ch
		inc	cl
		mov	dx, 70h
		cmp	ax, 800h
		jbe	GOTPARM
		add	ch, ch
		inc	cl
		mov	dx, 100h
		cmp	ax, 2000h
		jbe	GOTPARM
		add	ch, ch
		inc	cl
		add	dx, dx
		cmp	ax, 7FA8h
		jbe	GOTPARM
		add	ch, ch
		inc	cl
		add	dx, dx
GOTPARM:
		mov	[di+6],	dx
		mov	[di+2],	ch
		xor	bx, bx
		mov	bl, ch
		dec	bx
		add	bx, ax
		shr	bx, cl
		inc	bx
		and	bl, 0FEh
		mov	si, bx
		shr	bx, 1
		add	bx, si
		add	bx, 511
		shr	bh, 1
		mov	[di+0Bh], bh
		clc
		ret


GETCLUS:
		push	cx
		push	di
		mov	DOSCNT, cx
		mov	ax, bx
		dec	ax
		dec	ax
		mul	cx
		add	ax, BIOSTRT
		mov	dx, ax
GETCL1:
		call	UNPACK
		sub	si, bx
		cmp	si, -1
		jnz	GETCL2
		add	DOSCNT, cx
		jmp	GETCL1

GETCL2:
		push	bx
		mov	ax, DRVFAT
		mov	cx, DOSCNT
		call	DISKRD
		pop	bx
		pop	di
		mov	ax, DOSCNT
		xchg	ah, al
		shl	ax, 1
		add	di, ax
		pop	cx
		ret


UNPACK:
		push	ds
		push	bx
		mov	si, 7C0h	; FATLOC
		mov	ds, si
		mov	si, bx
		shr	si, 1
		mov	bx, [bx+si]
		jnb	HAVCLUS
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
HAVCLUS:
		and	bx, 0FFFh
		pop	si
		pop	ds
		ret


PRINT_INIT:
		mov	bh, 1
		mov	dl, 17h		; Do INT 17h
		jmp	short DEV_INIT

AUX_INIT:
		mov	bx, 0A3h	; RSINIT
		mov	dl, 14h		; Do INT 14h
DEV_INIT:
		mov	byte ptr cs:INT_INS+1, dl
		mov	al, cs:[si+0Dh]
		sub	al, '1'
		cbw
		mov	dx, ax
		mov	ax, bx
INT_INS:
		int	17h             ; Printer service
		ret

CODE    ENDS
        END

