TITLE   RECOVER Messages
FALSE   EQU     0
TRUE    EQU     NOT FALSE


bdos    equ     21h
boot    equ     20h
aread   equ     25h
awrite  equ     26h


.xlist
.xcref
        INCLUDE ..\..\inc\DOSSYM.ASM
;The DOST: prefix is a DEC TOPS/20 directory prefix. Remove it for
;   assembly in MS-DOS assembly environments using MASM. The DOSSYM.ASM
;   file must exist though, it is included with OEM distribution.
.cref
.list

code    segment public
code    ends

const   segment public byte
const   ends

data    segment public byte
        EXTRN   filsiz:WORD
data    ends


dg      group   code,const,data

cr      equ     0dh
lf      equ     0ah

code    segment public byte
        assume  cs:dg,ds:dg,es:dg,ss:dg

        EXTRN   PCRLF:NEAR,PRINT:NEAR,INT_23:NEAR,CONVERT:NEAR
        PUBLIC  dskwrt,dskrd,DSKERR,report

hecode  db      0

dskwrt: push    ax
        push    bx
        push    cx
        push    dx
        int     awrite
        mov     [hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        jnc     pret
        mov     si,offset dg: writing
        call    dskerr
        jz      dskwrt
        clc
pret:   ret

dskrd:  push    ax
        push    bx
        push    cx
        push    dx
        int     aread
        mov     [hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        jnc     pret
        mov     si,offset dg: reading
        call    dskerr
        jz      dskrd
        clc
        ret

DSKERR:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    ES
        CALL    PCRLF
        MOV     AL,[HECODE]
        CMP     AL,12
        JBE     HAVCOD
        MOV     AL,12
HAVCOD:
        XOR     AH,AH
        MOV     DI,AX
        SHL     DI,1
        MOV     DX,WORD PTR [DI+MESBAS] ; Get pointer to error message
        CALL    PRINT          ; Print error type
        MOV     DX,OFFSET DG:ERRMES
        CALL    PRINT
        MOV     DX,SI
        CALL    PRINT
        MOV     DX,OFFSET DG:DRVMES
        CALL    PRINT
ASK:
        MOV     DX,OFFSET DG:REQUEST
        CALL    PRINT
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H             ; Get response
        PUSH    AX
        CALL    PCRLF
        POP     AX
        OR      AL,20H          ; Convert to lower case
        CMP     AL,"i"          ; Ignore?
        JZ      EEXITNZ
        CMP     AL,"r"          ; Retry?
        JZ      EEXIT
        CMP     AL,"a"          ; Abort?
        JNZ     ASK
        JMP     INT_23

EEXITNZ:
        OR      AL,AL           ; Resets zero flag
EEXIT:
        POP     ES
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

;******************************************
; Prints the XXX of YYY bytes recovered message.
; The XXX value is a dword at di+16 on entry.
; The YYY value is a dword (declared as a word) at filsiz.
; Note:
;       If it is desired to print a message before the first number,
;          point at the message with DX and call PRINT.

report:
        mov     si,[di+16]      ;Get the XXX value
        mov     di,[di+18]
        mov     bx,offset dg: ofmsg
        call    convert         ;Print "XXX of "  (DI:SI followed by message
                                ;                  pointed to by BX)
        mov     si,filsiz       ;Get the YYY value
        mov     di,filsiz+2
        mov     bx,offset dg: endmsg
        call    convert         ;Print "YYY bytes recovered CR LF"
        ret

code    ends

const   segment public byte

        PUBLIC  BADVER,askmsg,drvlet,DRVLET1,dirmsg,recmsg_pre
        PUBLIC  crlf,drverr,baddrv,opnerr,recmsg_post

MESBAS  DW      OFFSET DG:ERR0
        DW      OFFSET DG:ERR1
        DW      OFFSET DG:ERR2
        DW      OFFSET DG:ERR3
        DW      OFFSET DG:ERR4
        DW      OFFSET DG:ERR5
        DW      OFFSET DG:ERR6
        DW      OFFSET DG:ERR7
        DW      OFFSET DG:ERR8
        DW      OFFSET DG:ERR9
        DW      OFFSET DG:ERR10
        DW      OFFSET DG:ERR11
        DW      OFFSET DG:ERR12

READING DB      "read$"
WRITING DB      "writ$"
ERRMES  DB      " error $"
DRVMES  DB      "ing drive "
DRVLET1 DB      "A",13,10,"$"
REQUEST DB      "Abort, Retry, Ignore? $"

ERR0    DB      "Write protect$"
ERR1    DB      "Bad unit$"
ERR2    DB      "Not ready$"
ERR3    DB      "Bad command$"
ERR4    DB      "Data$"
ERR5    DB      "Bad call format$"
ERR6    DB      "Seek$"
ERR7    DB      "Non-DOS disk$"
ERR8    DB      "Sector not found$"
ERR9    DB      "No paper$"
ERR10   DB      "Write fault$"
ERR11   DB      "Read fault$"
ERR12   DB      "Disk$"

;-----------------------------------------------------------------------;

BADVER  DB      "Incorrect DOS version"
crlf    db      cr,lf,'$'
askmsg  db      cr,lf,'Press any key to begin recovery of the'
        db      cr,lf,'file(s) on drive '
drvlet  db      'A: ',cr,lf,cr,lf,'$'
dirmsg  db      cr,lf,'Warning - directory full',cr,lf,'$'

;"recmsg_pre<number of files recovered>recmsg_post"
recmsg_post     db      ' file(s) recovered',cr,lf
recmsg_pre      db      '$'

ofmsg   db      ' of $'
endmsg  db      ' bytes recovered',13,10,"$"

drverr  db      'Invalid number of parameters$'
baddrv  db      'Invalid drive or file name$'
opnerr  db      'File not found$'


const   ends
        end
