;
;       OEM FORMAT module for IBM PC DOS 2.1
;

CODE	SEGMENT	PUBLIC 'CODE'

        ASSUME CS:CODE,DS:CODE

EXTRN   SWITCHMAP:WORD,DRIVE:BYTE
EXTRN   FDSKSIZ:DWORD,SECSIZ:WORD,CLUSSIZ:WORD,SYSSIZ:DWORD

PUBLIC  INIT,DISKFORMAT,BADSECTOR,DONE,WRTFAT,HARDFLAG
PUBLIC  FATID,STARTSECTOR,SWITCHLIST,FREESPACE,FATSPACE

        DW      OFFSET BOOT2X
        DW      OFFSET BOOT1X

; ===================================================

WRTFAT:
        MOV	AL,DRIVE
        CBW
        MOV	CX,BPFTSEC      ; All FAT sectors
        MOV	DX,1		; Starting sector of 1st FAT
        MOV	BX,FATSPACE
        INT	26H		; Absolute disk write
        POP	AX
        JB	GORET
        MOV	AL,DRIVE
        CBW
        MOV	CX,BPFTSEC      ; All FAT sectors
        MOV	DX,CX
        INC	DX		; Starting sector of 2nd FAT
        MOV	BX,FATSPACE
        INT	26H		; Absolute disk write
        POP	AX
        JB	GORET
        JMP	SHORT OKRET

; ===================================================

INIT:
        MOV	AL,DRIVE
        MOV	FMTDRIVE,AL
        INT	11H	        ; EQUIPMENT DETERMINATION
                                ; Return: AX = equipment flag bits
        ROL	AL,1
        ROL	AL,1
        AND	AX,3	        ; Any additional drives	installed?
        JNZ	INIT1
        MOV	BYTE PTR FMTDRIVE,0	; No, force A: (drive 0)
        INC	AX
INIT1:
        MOV	BYTE PTR HARDFLAG,0
        CMP	DRIVE,AL
        JBE	PHANTOM
        MOV	HARDFLAG,AL
        PUSH	AX
        MOV	AH,8
        MOV	DL,80H
        INT	13H	        ; Get drive parms, returns # of drives in DL
        POP	AX
        JB	SETDRV

        ADD	AL,DL
SETDRV:
        CMP	DRIVE,AL
        JBE	DRVOK
        MOV	DX,OFFSET NOTCDM
        JMP	SHORT OUTMSG

DRVOK:
        TEST	SWITCHMAP,18H   ; SWITCH_8+SWITCH_1
        JZ	OKRET
        MOV	DX,OFFSET HDCOMPM
OUTMSG:
        CALL	PRTMSG
        STC
        RET

PHANTOM:
        MOV	AL,DRIVE
        PUSH	DS
        MOV	BX,50H
        MOV	DS,BX
        ASSUME DS:NOTHING
        MOV	DS:4,AL
        POP	DS
        ASSUME DS:CODE
        MOV	AL,BYTE PTR SWITCHMAP
        AND	AL,13H	        ; Mask SWITCH_8+SWITCH_V+SWITCH_S
        CMP	AL,12H	        ; SWITCH_8+SWITCH_V?
        JNZ	OKRET
        MOV	DX,OFFSET INCOMPM
        JMP	SHORT OUTMSG

OKRET:
        CLC
GORET:
        RET

; ===================================================

DONE:
        TEST	SWITCHMAP,20H   ; SWITCH_B?
        JZ	DONE_B
        MOV	AL,DRIVE
        ADD	AL,'A'
        MOV	BYTE PTR BIONAME,AL
        MOV	BYTE PTR DOSNAME,AL
        MOV	CX,6
        MOV	DX,OFFSET BIONAME
        MOV	AH,3CH
        INT	21H	        ; Create a file with handle
        MOV	BX,AX
        MOV	CX,780H
        MOV	DX,OFFSET BOGUSDOS
        MOV	AH,40H
        INT	21H	        ; Write file with handle
        MOV	AH,3EH
        INT	21H	        ; Close a file with handle
        MOV	CX,6
        MOV	DX,OFFSET DOSNAME
        MOV	AH,3CH
        INT	21H	        ; Create a file with handle
        MOV	BX,AX
        MOV	CX,1900H
        MOV	DX,OFFSET BOGUSDOS
        MOV	AH,40H
        INT	21H	        ; Write file with handle
        MOV	AH,3EH
        INT	21H	        ; Close file with handle
        ADD	WORD PTR SYSSIZ,2200h
DONE_B:
        JMP	SHORT CHK_8

BIONAME:
        DB      'X:\IBMBIO.COM',0
DOSNAME:
        DB      'X:\IBMDOS.COM',0


BOGUSDOS:
        PUSH	CS
        POP	DS
        MOV	AL,20H
        OUT	20H,AL	        ; Send EOI
        MOV	SI,BOGUSMSG
SYSMESLP:
        LODSB
ENDSYSLP:
        OR	AL,AL
        JZ	ENDSYSLP
        MOV	AH,0EH
        MOV	BX,7
        INT	10H	        ; Write TTY
        JMP	SHORT SYSMESLP

NO_SYS_MES:
	DB      'Non-System disk or disk error',13,10,0

BOGUSMSG = NO_SYS_MES - BOGUSDOS

CHK_8:
        TEST	SWITCHMAP,10H   ; SWITCH_8?
        JNZ	DO_SW_8
        JMP	OKRET

DO_SW_8:
        MOV	AL,DRIVE
        CBW
        MOV	CX,7            ; Read 7 sectors
        MOV	DX,3            ; 4th sector -- root directory
        MOV	BX,FATSPACE
        INT	25H	        ; Absolute disk read
        POP	AX
        JNB	CLR_ROOT
DONE_ERR:
        RET

CLR_ROOT:
        MOV	BX,FATSPACE
        MOV	BYTE PTR [BX+11],6
        MOV	BYTE PTR [BX+11+32],6
        MOV	AX,BPDRCNT
        DEC	AX
        MOV	BX,32
        MUL	BX
        ADD	AX,FATSPACE
        MOV	BX,AX
        XOR	AX,AX
        MOV	AH,0E5H	        ; Unused directory entry marker
NXTROOT:
        CMP	[BX],AL
        JNZ	WR_ROOT
        MOV	[BX],AH	        ; Set markers for DOS 1.x
        SUB	BX,32
        CMP	BX,FATSPACE
        JNB	NXTROOT
WR_ROOT:
        MOV	AL,DRIVE
        CBW
        MOV	CX,7	        ; Write	7 sectors
        MOV	DX,3	        ; Start	at sector 3 (4th sector)
        MOV	BX,FATSPACE
        INT	26H	        ; Absolute disk write
        POP	AX
DON_ERR2:
        JB	DONE_ERR
        TEST	SWITCHMAP,1     ; SWITCH_S?
        JNZ	DONEOK
        MOV	AL,DRIVE
        CBW
        MOV	BX,OFFSET BOOT1X
        CMP	BYTE PTR FATID,0FEH	; Single-sided 8-sector	disk?
        JZ	WRSEC
        MOV	WORD PTR [BX+3],103H    ; Fix up starting sector of system area
WRSEC:
        MOV	CX,1
        XOR	DX, DX
        INT	26H	        ; Absolute disk write
        POP	AX
        JB	DON_ERR2
DONEOK:
        CLC
        RET

; ===================================================

DISKFORMAT:
        CMP	HARDFLAG,0
        JNZ	FMTHARD
        JMP	FMTFLOP

FMTHARD:
        MOV	BYTE PTR FATID,0F8h
        XOR	BX,BX
        MOV	WORD PTR HDD_BPB,BX ; Initially points to 70:0
        PUSH	DS
        LDS	BX,HDD_BPB
        MOV	BX,[BX]	        ; Word at 70:0 is offset of HARDDRV in IBMBIO
        MOV	AL,[BX]	        ; First	BIOS drive number
        INC	BX		; Point	to the hard disk BPB
        POP	DS
        MOV	WORD PTR HDD_BPB,BX
        MOV	HARDDRV,AL
        MOV	DL,DRIVE
        SUB	DL,HARDFLAG
        DEC	DL
        JZ	HAVHDD	        ; Was it the first hard	disk?
        ADD	WORD PTR HDD_BPB,19     ; No, point to the second BPB
HAVHDD:
        ADD	DL,HARDDRV
        MOV	FMTDRIVE,DL
        CALL	GETHDPARM
        JMP	FMTCMN

FMTFLOP:
        MOV	CURCYL,	0
        MOV	TRACKS,	40	; No 96tpi yet!
        MOV	BYTE PTR ERRFLG,0
        MOV	SI,OFFSET BPB92 ; 9 SPT, double sided
        TEST	SWITCHMAP,8	; SWITCH_1?
        JZ	CHK8SEC
        MOV	SI,OFFSET BPB91 ; 9 SPT, single sided
        TEST	SWITCHMAP,10H	; SWITCH_8?
        JZ	SETBPB
        MOV	SI,OFFSET BPB81 ; 8 SPT, single sided
        JMP	SHORT SETBPB
; ---------------------------------------------------------------------------

CHK8SEC:
        TEST	SWITCHMAP,10H	; SWITCH_8?
        JZ	SETBPB
        MOV	SI,OFFSET BPB82 ; 8 SPT, double sided
SETBPB:
        PUSH	DS
        POP	ES
        ASSUME ES:CODE
        MOV	DI,OFFSET BPCLUS
        MOV	CX,BPBSIZ
        CLD
        REP     MOVSB		; Copy over, skip sector size (leave at	512)
FMTCMN:
        MOV	AL,BPFTCNT
        CBW
        MUL	BPFTSEC
        ADD	AX,BPRES
        MOV	STARTSECTOR,AX
        MOV	AX,32
        MUL	BPDRCNT
        MOV	BX,BPSECSZ
        ADD	AX,BX
        DEC	AX
        XOR	DX,DX
        DIV	BX
        ADD	STARTSECTOR, AX
        CALL	SETHEAD
        MOV	DX,OFFSET FMTPRGM
        CALL	PRTMSG
RSTTRY:
        CALL	DSKRESET
        JNB	RSTOK
        CALL	CHKERR
        CMP	BYTE PTR RETRIES,0
        JNZ	RSTTRY
RSTOK:
        CMP	HARDFLAG,0
        JNZ	TRKVERIFY
        MOV	BYTE PTR RETRIES,3
TRKFORMAT:
        MOV	DH,CURHEAD
        XOR	CH,CH
        CALL	FMTTRACK
        JNB	SETRETRY
        CALL	CHKERR
        CMP	BYTE PTR RETRIES,0
        JNZ	TRKFORMAT
        MOV	BYTE PTR ERRFLG,1
        CLC
        RET

SETRETRY:
        MOV	BYTE PTR RETRIES,3
        MOV	DH,CURHEAD
        DEC	CURHEAD
        OR	DH,DH
        JNZ	TRKFORMAT
        CALL	SETHEAD
TRKVERIFY:
        MOV	DH,CURHEAD
        CALL	SETCYL
        CALL	VFYTRACK
        JNC	FMTDON
        CALL	CHKERR
        CMP	BYTE PTR RETRIES,0
        JNZ	TRKVERIFY
        CMP	HARDFLAG,0
        JNZ	BADHDTRK
        CMP	CURHEAD,0
        JNZ	FIX1SIDE
BADHDTRK:
        MOV	BYTE PTR ERRFLG,1
        CLC
        RET

FIX1SIDE:
        DEC	BYTE PTR FATID
        SUB	BYTE PTR STARTSECTOR,3
        MOV	BYTE PTR BPDRCNT,64
        MOV	BYTE PTR BPB_HED,1
        SHR	BPSCCNT,1
FMTDON:
        MOV	BYTE PTR RETRIES,3
        MOV	DH,CURHEAD
        DEC	CURHEAD
        OR	DH,DH
        JNZ	TRKVERIFY
        CALL	SETHEAD
        INC	CURCYL
        CLC
        RET

; ===================================================

DSKRESET:
        MOV	AL,BYTE PTR BPB_SPT
        MOV	CX,1
        MOV	DL,FMTDRIVE
        XOR	DH,DH
        MOV	AH,0	        ; Reset	disk
        CALL	INT13
        RET

; ===================================================

FMTTRACK:
        MOV	DI,1
        MOV	BX,OFFSET FMTMEND
        MOV	AL,9
NXTSEC:
        SUB	BX,4
        MOV	[BX],CH
        MOV	[BX+DI],DH
        DEC	AL
        JNZ	NXTSEC
        MOV	DL,FMTDRIVE
        MOV	AL,BYTE PTR BPB_SPT
        MOV	AH,5	        ; Format track
        CALL	COPYMAP
        MOV	BX,60H	        ; Buffer at 60:0
        MOV	ES,BX
        ASSUME ES:NOTHING
        XOR	BX,BX
        CALL	INT13
        PUSH	CS
        POP	ES
        ASSUME ES:CODE
        CALL	COPYMAP
        RET

; ===================================================

VFYTRACK:
        MOV	DL,FMTDRIVE
        MOV	AL,BYTE PTR BPB_SPT ; One track
        OR	CL,1	        ; Start	at sector 1
        MOV	AH,4	        ; Verify disk sectors
        CALL	INT13
        RET

; ===================================================

CHKERR:
        CMP	AH,3
        JNZ	NOTWP
        MOV	DX,OFFSET WPERRM
PRTERR:
        CALL	PRTMSG
        MOV	AH,0	        ; Reset	disk
        CALL	INT13
        ADD	SP,2
        JMP	RETERR

NOTWP:
        CMP	AH,80H
        JNZ	GENERR
        MOV	DX,OFFSET NOTRDYM
        JMP	SHORT PRTERR

GENERR:
        MOV	AH,0	        ; Reset	disk
        CALL	INT13
        DEC	BYTE PTR RETRIES
        RET

; ===================================================

BADSECTOR:
        MOV	BYTE PTR RETRIES,3
        CMP	BYTE PTR ERRFLG,0 ; Was there an error?
        JZ	FMTCONT
        MOV	BYTE PTR ERRFLG,0 ; Yes, clear flag and report
        XOR	AX,AX
        MOV	BX,AX	        ; Bad sector number
        MOV	AL,BYTE PTR BPB_SPT ; Number of consecutive sectors
        CLC
        RET

FMTCONT:
        CALL	DSKRESET
        JNB	NEXTTRACK
        CALL	CHKERR
        CMP	BYTE PTR RETRIES,0
        JNZ	FMTCONT
NEXTTRACK:
        MOV	CX,CURCYL
        CMP	CX,TRACKS       ; All tracks/cylinders done?
        JNB	WRBOOT
        CMP	HARDFLAG,0
        JNZ	RETRYVFY
        MOV	BYTE PTR RETRIES,3
TRYFMT:
        MOV	DH,CURHEAD
        MOV	CH,BYTE PTR CURCYL
        CALL	FMTTRACK
        JNB	RETRYVFY
        CALL	CHKERR
        CMP	BYTE PTR RETRIES,0 ; Retries left?
        JNZ	TRYFMT
        JMP	RPTBAD	        ; Report bad sectors (track)

RETRYVFY:
        MOV	BYTE PTR RETRIES,3
TRYVFY:
        MOV	DH,CURHEAD
        CALL	SETCYL
        CALL	VFYTRACK
        JNB	NXTHED
        CALL	CHKERR
        CMP	BYTE PTR RETRIES,0 ; Retries left?
        JNZ	TRYVFY
        JMP	RPTBAD	        ; Report bad sectors (track)

NXTHED:
        MOV	DH,CURHEAD
        DEC	CURHEAD
        OR	DH,DH	        ; Last head done?
        JNZ	NEXTTRACK       ; No, next head	on same	cylinder
        CALL	SETHEAD
        CALL	SETCYL
        MOV	DX,CURCYL
        INC	DX	        ; Next cylinder
        MOV	CURCYL,	DX
        JMP	SHORT NEXTTRACK

WRBOOT:
        MOV	BX,OFFSET BOOT2X
        MOV	DX,0            ; Start at very first sector
        MOV	CX,1            ; Write 1 sector
        MOV	AH,0
        MOV	AL,DRIVE
        INT	26H	        ; Absolute disk write
        JB	BTWERR
        MOV	DX,OFFSET FMTDONM
        CALL	PRTMSG
        POPF
        XOR	AX,AX
        CLC
        RET

BTWERR:
        POPF
        MOV	DX,OFFSET BWERRM
        CALL	PRTMSG
RETERR:
        STC
        RET

RPTBAD:
        MOV	AX,CURCYL
        MUL	BPB_HED
        MOV	BL,CURHEAD
        XOR	BH,BH
        ADD	AX,BX
        MUL	BPB_SPT
        SUB	AX,BPB_HID
        MOV	BX,AX	        ; First	bad sector to report
        MOV	DH,CURHEAD
        DEC	CURHEAD
        OR	DH,DH	        ; Done last head?
        JNZ	BSRET
        CALL	SETHEAD	        ; Reset	head
        INC	CURCYL	        ; Next track/cylinder
BSRET:
        MOV	AX,BPB_SPT      ; Number of consecutive	sectors
        CLC
        RET

; ===================================================

PRTMSG:
        MOV	AH,9
        INT	21H	        ; DOS Print String
        RET

; ===================================================

SETCYL:
        MOV	CX,CURCYL
        XCHG	CH,CL
        ROR	CL,1
        ROR	CL,1
        AND	CL,0C0H
        RET

; ===================================================

GETHDPARM:
        PUSH	DS
        POP	ES
        MOV	DI,OFFSET BPSECSZ
        LDS	SI,HDD_BPB
        MOV	CX,19
        CLD
        REP     MOVSB	        ; Copy BPB from	IBMBIO
        PUSH	CS
        POP	DS
        MOV	AX,BPB_HID
        MOV	BX,BPSCCNT
        CALL	CALC_CYL
        DEC	AX
        MOV	CURCYL,	AX
        MOV	AX,BX
        CALL	CALC_CYL
        ADD	AX,CURCYL
        MOV	TRACKS,	AX
        RET

; ===================================================

CALC_CYL:
        PUSH	AX
        MOV	AL,BYTE PTR BPB_HED
        MUL	BYTE PTR BPB_SPT
        MOV	CX,AX
        POP	AX
        ADD	AX,CX
        DEC	AX
        XOR	DX,DX
        DIV	CX
        RET

; ===================================================

SETHEAD:
        MOV	DH,BYTE PTR BPB_HED
        DEC	DH
        MOV	CURHEAD,DH
        RET

; ===================================================

COPYMAP:
        PUSHF
        PUSH	ES
        PUSH	DI
        PUSH	SI
        PUSH	CX
        PUSH	BX
        PUSH	AX
        MOV	DI,60H
        MOV	ES,DI
        ASSUME ES:NOTHING
        XOR	DI,DI
        MOV	SI,OFFSET FMTMAP
        MOV	CX,18	        ; 9*4 bytes
MCPYLP:
        LODSW
        MOV	BX,ES:[DI]
        STOSW
        MOV	[SI-2],	BX
        LOOP	MCPYLP
        POP	AX
        POP	BX
        POP	CX
        POP	SI
        POP	DI
        POP	ES
        ASSUME ES:NOTHING
        POPF
        RET

; ===================================================

INT13:
        INT	13H
        RET


SWITCHLIST:
	DB      6
        DB      'B'     ; 8-sector disk	that can be made
                        ; bootable under either DOS 1.x or 2.x
        DB      '8'     ; 8 sectors per track
        DB      '1'     ; Single-sided format
        DB      'O'     ; Old style directory with E5h in all
                        ; unused entries
        DB      'V'     ; Ask for a volume label
        DB      'S'     ; Copy system files

BPB81	DB      1
        DW      1
        DB      2
        DW      64
        DW      320
        DB      0FEH
        DW      1
        DW      8
        DW      1
        DW      0
        DB      0

BPB82	DB      2
        DW      1
        DB      2
        DW      112
        DW      640
        DB      0FFH
        DW      1
        DW      8
        DW      2
        DW      0
        DB      0

BPB91	DB      1
        DW      1
        DB      2
        DW      64
        DW      360
        DB      0FCH
        DW      2
        DW      9
        DW      1
        DW      0
        DB      0

BPB92	DB      2
        DW      1
        DB      2
        DW      112
        DW      720
        DB      0FDH
        DW      2
        DW      9
        DW      2
        DW      0
        DB      0

FMTPRGM	DB      'Formatting...$'
        DB      '0'
FMTDONM	DB      'Format complete',13,10,'$'
WPERRM	DB      13,10,'Attempted write-protect violation',13,10,'$'
BWERRM	DB      13,10,'Unable to write BOOT',13,10,'$'
HDCOMPM	DB      13,10,'Parameter not compatible with fixed disk',13,10,'$'
INCOMPM	DB      13,10,'Parameters not compatible',13,10,'$'
NOTRDYM	DB      13,10,'Drive not ready',13,10,'$'
NOTCDM	DB      13,10,'Disk not compatible',13,10,'$'

FMTMAP	DB      0            ; Floppy format	template
        DB      0
        DB      1
        DB      2
        DB      0
        DB      0
        DB      2
        DB      2
        DB      0
        DB      0
        DB      3
        DB      2
        DB      0
        DB      0
        DB      4
        DB      2
        DB      0
        DB      0
        DB      5
        DB      2
        DB      0
        DB      0
        DB      6
        DB      2
        DB      0
        DB      0
        DB      7
        DB      2
        DB      0
        DB      0
        DB      8
        DB      2
        DB      0
        DB      0
        DB      9
        DB      2
FMTMEND:

HARDFLAG	DB      0
FMTDRIVE	DB      0
CURCYL		DW      0

CURHEAD		DB      0

ERRFLG		DB      0

RETRIES		DB      0

STARTSECTOR	DW      0
TRACKS		DW      0

HDD_BPB		DD      700000h

FREESPACE	DW      33F8h
FATSPACE	DW      OFFSET FAT_SPACE

BOOT1X	db 0EBh
        db  27h
        db  90h
        db    8
        db    0
        db 14h,	21h dup(0), 0CDh, 19h, 0FAh, 8Ch, 0C8h,	8Eh, 0D8h
        db 33h,	0D2h, 8Eh, 0D2h, 0BCh, 0, 7Ch, 0FBh, 0B8h, 60h
        db 0, 8Eh, 0D8h, 8Eh, 0C0h, 33h, 0D2h, 8Bh, 0C2h, 0CDh
        db 13h,	72h, 69h, 0E8h,	85h, 0,	72h, 0DDh, 2Eh,	83h, 3Eh
        db 3, 7Ch, 8, 74h, 6, 2Eh, 0C6h, 6, 64h, 7Dh, 2, 0BBh
        db 2 dup(0), 2Eh, 8Bh, 0Eh, 3, 7Ch, 51h, 0B0h, 9, 2Ah
        db 0C1h, 0B4h, 0, 8Bh, 0F0h, 56h, 33h, 0D2h, 33h, 0C0h
        db 8Ah,	0C5h, 2Eh, 0F6h, 36h, 64h, 7Dh,	8Ah, 0E8h, 8Ah
        db 0F4h, 8Bh, 0C6h, 0B4h, 2, 0CDh, 13h,	72h, 2Dh, 5Eh
        db 59h,	2Eh, 29h, 36h, 5, 7Ch, 74h, 1Fh, 8Bh, 0C6h, 2Eh
        db 0F7h, 26h, 65h, 7Dh,	3, 0D8h, 0FEh, 0C5h, 0B1h, 1, 51h
        db 0BEh, 8, 0, 2Eh, 3Bh, 36h, 5, 2 dup(7Ch), 5,	2Eh, 8Bh
        db 36h,	5, 7Ch,	0EBh, 0C0h, 0EAh, 2 dup(0), 60h, 0, 0BEh
        db 67h,	7Dh, 0E8h, 2, 0, 0EBh, 0FEh, 32h, 0FFh,	2Eh, 0ACh
        db 24h,	7Fh, 74h, 0Bh, 56h, 0B4h, 0Eh, 0BBh, 7,	0, 0CDh
        db 10h,	5Eh, 0EBh, 0EFh, 0C3h, 0E9h, 33h, 0FFh,	0BBh, 2	dup(0)
        db 0B9h, 4, 0, 0B8h, 1,	2, 0CDh, 13h, 1Eh, 72h,	33h, 8Ch
        db 0C8h, 8Eh, 0D8h, 0BFh, 2 dup(0), 0B9h, 0Bh, 0, 26h
        db 80h,	0Dh, 20h, 26h, 80h, 4Dh, 2 dup(20h), 47h, 0E2h
        db 0F4h, 0BFh, 2 dup(0), 0BEh, 8Bh, 7Dh, 0B9h, 0Bh, 0
        db 0FCh, 0F3h, 0A6h, 75h, 0Fh, 0BFh, 20h, 0, 0BEh, 97h
        db 7Dh,	0B9h, 0Bh, 0, 0F3h, 0A6h, 75h, 2, 1Fh, 0C3h, 0BEh
        db 1Bh,	7Dh, 0E8h, 0A2h, 0FFh, 0B4h, 0,	0CDh, 16h, 1Fh
        db 0F9h, 0C3h
        db 0Dh,0Ah
        db 'Non-System disk or disk error',0Dh,0Ah
        db 'Replace and strike any key when ready',0Dh,0Ah,0
        db 1, 0, 2
        db 0Dh,0Ah
        db 'Disk Boot failure',0Dh,0Ah,0
        db 'Microsoft,Inc ibmbio  com0ibmdos  com0'
        db    5
        db 0C6h
        db    6
        db  77h
        db  2Fh
        db 0FFh
        db  83h
        db  7Eh
        db 0FCh
        db    0
        db  75h
        db  0Bh
        db  80h
        db  7Eh
        db 0F7h
        db  3Bh
        db  75h
        db    5
        db 0C6h
        db    6
        db  76h
        db  2Fh
        db 0FFh
        db  89h
        db 0ECh
        db  5Dh
        db 0CAh
        db    4

        ORG     BOOT1X + 512

BOOT2X	DB      0EBh,2Ch,90h    ; JMP short
        DB      'IBM  2.0'

BPSECSZ	DW      512

BPCLUS	DB      1
BPRES	DW      1
BPFTCNT	DB      2
BPDRCNT	DW      64
BPSCCNT	DW      360

FATID	DB      0FCH
BPFTSEC	DW      2
BPB_SPT	DW      9
BPB_HED	DW      1

BPB_HID	DW      0

HARDDRV	DB      0

BPBSIZ  = $ - BPCLUS

        db 0
        db 0Ah,	0DFh, 2, 25h, 2, 9, 2Ah, 0FFh, 50h, 0F6h, 0Fh
        db 2, 0CDh, 19h, 0FAh, 33h, 0C0h, 8Eh, 0D0h, 0BCh, 0, 7Ch
        db 8Eh,	0D8h, 0A3h, 7Ah, 0, 0C7h, 6, 78h, 0, 21h, 7Ch
        db 0FBh, 0CDh, 13h, 73h, 3, 0E9h, 95h, 0, 0Eh, 1Fh, 0A0h
        db 10h,	7Ch, 98h, 0F7h,	26h, 16h, 7Ch, 3, 6, 1Ch, 7Ch
        db 3, 6, 0Eh, 7Ch, 0A3h, 3, 7Ch, 0A3h, 13h, 7Ch, 0B8h
        db 20h,	0, 0F7h, 26h, 11h, 7Ch,	5, 0FFh, 1, 0BBh, 0, 2
        db 0F7h, 0F3h, 1, 6, 13h, 7Ch, 0E8h, 7Eh, 0, 72h, 0B3h
        db 0A1h, 13h, 7Ch, 0A3h, 7Eh, 7Dh, 0B8h, 70h, 0, 8Eh, 0C0h
        db 8Eh,	0D8h, 0BBh, 2 dup(0), 2Eh, 0A1h, 13h, 7Ch, 0E8h
        db 0B6h, 0, 2Eh, 0A0h, 18h, 7Ch, 2Eh, 2Ah, 6, 15h, 7Ch
        db 0FEh, 0C0h, 32h, 0E4h, 50h, 0B4h, 2,	0E8h, 0C1h, 0
        db 58h,	72h, 38h, 2Eh, 28h, 6, 20h, 7Ch, 76h, 0Eh, 2Eh
        db 1, 6, 13h, 7Ch, 2Eh,	0F7h, 26h, 0Bh,	7Ch, 3,	0D8h, 0EBh
        db 0CEh, 0Eh, 1Fh, 0CDh, 11h, 0D0h, 0C0h, 0D0h,	0C0h, 25h
        db 3, 0, 75h, 1, 2 dup(40h), 8Bh, 0C8h,	0F6h, 6, 1Eh, 7Ch
        db 80h,	75h, 2,	33h, 0C0h, 8Bh,	1Eh, 7Eh, 7Dh, 0EAh, 2 dup(0)
        db 70h,	0, 0BEh, 0C9h, 7Dh, 0E8h, 2, 0,	0EBh, 0FEh, 2Eh
        db 0ACh, 24h, 7Fh, 74h,	4Dh, 0B4h, 0Eh,	0BBh, 7, 0, 0CDh
        db 10h,	0EBh, 0F1h, 0B8h, 50h, 0, 8Eh, 0C0h, 0Eh, 1Fh
        db 2Eh,	0A1h, 3, 7Ch, 0E8h, 43h, 0, 0BBh, 2 dup(0), 0B8h
        db 1, 2, 0E8h, 58h, 0, 72h, 2Ch, 33h, 0FFh, 0B9h, 0Bh
        db 0, 26h, 80h,	0Dh, 20h, 26h, 80h, 4Dh, 2 dup(20h), 47h
        db 0E2h, 0F4h, 33h, 0FFh, 0BEh,	0DFh, 7Dh, 0B9h, 0Bh, 0
        db 0FCh, 0F3h, 0A6h, 75h, 0Eh, 0BFh, 20h, 0, 0BEh, 0EBh
        db 7Dh,	0B9h, 0Bh, 0, 0F3h, 0A6h, 75h, 1, 0C3h,	0BEh, 80h
        db 7Dh,	0E8h, 0A6h, 0FFh, 0B4h,	0, 0CDh, 16h, 0F9h, 0C3h
        db 1Eh,	0Eh, 1Fh, 33h, 0D2h, 0F7h, 36h,	18h, 7Ch, 0FEh
        db 0C2h, 88h, 16h, 15h,	7Ch, 33h, 0D2h,	0F7h, 36h, 1Ah
        db 7Ch,	88h, 16h, 1Fh, 7Ch, 0A3h, 8, 7Ch, 1Fh, 0C3h, 2Eh
        db 8Bh,	16h, 8,	7Ch, 0B1h, 6, 0D2h, 0E6h, 2Eh, 0Ah, 36h
        db 15h,	7Ch, 8Bh, 0CAh,	86h, 0E9h, 2Eh,	8Bh, 16h, 1Eh
        db 7Ch,	0CDh, 13h, 0C3h, 2 dup(0)
	db 0Dh,0Ah
        db 'Non-System disk or disk error',0Dh,0Ah
        db 'Replace and strike any key when ready',0Dh,0Ah,0
        db 0Dh,0Ah
	db 'Disk Boot failure',0Dh,0Ah,0
	db 'ibmbio  com0ibmdos  com0',0
        db    0
        db    0
        db    0
        db    0
        db    0
        db    0
        db  55h
        db 0AAh

FAT_SPACE:
	DB      0F8H,0FFH,0FFH
        DB      1AH,1AH,1AH,1AH,1AH

CODE	ENDS

        END
