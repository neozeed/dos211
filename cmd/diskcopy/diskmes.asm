        TITLE   DISKCOPY Messages

FALSE   EQU     0
TRUE    EQU     NOT FALSE


.xlist
.xcref
        INCLUDE ..\..\inc\DOSSYM.ASM
.cref
.list

;
bdos    equ     21h
boot    equ     20h
aread   equ     25h
awrite  equ     26h

cr      equ     0dh
lf      equ     0ah
;

CODE    SEGMENT PUBLIC BYTE
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
CONST   ENDS

DATA    SEGMENT PUBLIC BYTE
DATA    ENDS

DG      GROUP   CODE,CONST,DATA

CODE  SEGMENT PUBLIC BYTE
        assume  cs:DG,ds:DG,es:DG,ss:DG

        EXTRN   PRINT:NEAR,PCRLF:NEAR,ASKANOTHER:NEAR,sec64k:WORD,secsiz:WORD
        PUBLIC  dskrd,dskwrt,promptyn

promptyn:
;Prompt message in DX
;Prompt user for Y or N answer. Zero set if Y
        CALL    PRINT
PAGAIN:
        MOV     DX,OFFSET DG:YES_NO
        CALL    PRINT
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H
        PUSH    AX
        CALL    PCRLF
        POP     AX
        OR      AL,20H          ;Convert to lower case
        CMP     AL,'y'
        JZ      GOTANS
        CMP     AL,'n'
        JZ      GOTNANS
        JMP     PAGAIN
GOTNANS:
        OR      AL,AL           ;Reset zero
GOTANS:
        RET

hecode  db      0
tcount  dw      ?

dskrd:
        mov     byte ptr cs:[drvlet],"A"
        add     cs:[drvlet],al
        mov     cs:[tcount],cx
        push    ds
        push    cx
        push    dx
nxtrd:
        push    ax
        push    bx
        push    dx
        mov     cx,cs:[sec64k]
        cmp     cx,cs:[tcount]
        jbe     gotrcnt
        mov     cx,cs:[tcount]
gotrcnt:
        push    cx
        int     aread
        mov     cs:[hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     cx
        pop     dx
        pop     bx
        pop     ax
        jnc     rdok
        mov     si,OFFSET DG: reading
        call    dskerr
        jz      nxtrd   ;Repeat this 64K read
rdok:
        sub     cs:[tcount],cx
        jbe     dskret
        add     dx,cx
        push    dx
        push    ax
        mov     ax,cs:[secsiz]
        mul     cx          ;ax byte count of transfer (know transfer <= 64K)
        or      dl,dl
        jnz     exact64
        push    ax
        mov     cl,4
        shr     ax,cl
        mov     cx,ds
        add     cx,ax
        mov     ds,cx
        pop     cx
        and     cx,0FH
        add     bx,cx
        jnc     popgo
exact64:
        mov     cx,ds
        add     cx,1000H
        mov     ds,cx
popgo:
        pop     ax
        pop     dx
        jmp     nxtrd

dskret:
        pop     dx
        pop     cx
        pop     ds
        clc
        ret


dskwrt:
        mov     byte ptr cs:[drvlet],"A"
        add     cs:[drvlet],al
        mov     cs:[tcount],cx
        push    ds
        push    cx
        push    dx
nxtwrt:
        push    ax
        push    bx
        push    dx
        mov     cx,cs:[sec64k]
        cmp     cx,cs:[tcount]
        jbe     gotwcnt
        mov     cx,cs:[tcount]
gotwcnt:
        push    cx
        int     awrite
        mov     cs:[hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     cx
        pop     dx
        pop     bx
        pop     ax
        jnc     wrtok
        mov     si,OFFSET DG: writing
        call    dskerr
        jz      nxtwrt  ;Repeat this 64K write
wrtok:
        sub     cs:[tcount],cx
        jbe     dskret
        add     dx,cx
        push    dx
        push    ax
        mov     ax,cs:[secsiz]
        mul     cx          ;ax byte count of transfer (know transfer <= 64K)
        or      dl,dl
        jnz     exact64w
        push    ax
        mov     cl,4
        shr     ax,cl
        mov     cx,ds
        add     cx,ax
        mov     ds,cx
        pop     cx
        and     cx,0FH
        add     bx,cx
        jnc     popgow
exact64w:
        mov     cx,ds
        add     cx,1000H
        mov     ds,cx
popgow:
        pop     ax
        pop     dx
        jmp     nxtwrt


DSKERR:
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    ES
        CALL    PCRLF
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
        MOV     DX,OFFSET DG: ERRMES
        CALL    PRINT
        MOV     DX,SI
        CALL    PRINT
        MOV     DX,OFFSET DG: DRVMES
        CALL    PRINT
ASK:
        MOV     DX,OFFSET DG: REQUEST
        CALL    PRINT
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H             ; Get response
        OR      AL,20H          ; Convert to lower case
        PUSH    AX
        CALL    PCRLF
        CALL    PCRLF
        POP     AX
        CMP     AL,"i"          ; Ignore?
        JZ      EEXITNZ
        CMP     AL,"r"          ; Retry?
        JZ      EEXIT
        CMP     AL,"a"          ; Abort?
        JNZ     ASK
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        CLI
        mov     ss,ax
        mov     sp,100h         ; Reset stack
        STI
        MOV     DX,OFFSET DG:ABMES
        JMP     ASKANOTHER

EEXITNZ:
        OR      AL,AL           ; Resets zero flag
EEXIT:
        POP     ES
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        POP     DS
        RET


CODE  ENDS

CONST   SEGMENT PUBLIC BYTE

        PUBLIC  cpymsg,good1,goodmsg,srcmsg,srclet,dstmsg,dstlet
        PUBLIC  keymsg,drverr1,drverr3,crlf,fdstmsg,fdstlet,anoprompt

MESBAS  DW      OFFSET DG: ERR0
        DW      OFFSET DG: ERR1
        DW      OFFSET DG: ERR2
        DW      OFFSET DG: ERR3
        DW      OFFSET DG: ERR4
        DW      OFFSET DG: ERR5
        DW      OFFSET DG: ERR6
        DW      OFFSET DG: ERR7
        DW      OFFSET DG: ERR8
        DW      OFFSET DG: ERR9
        DW      OFFSET DG: ERR10
        DW      OFFSET DG: ERR11
        DW      OFFSET DG: ERR12

READING DB      "read$"
WRITING DB      "writ$"
ERRMES  DB      " error $"
DRVMES  DB      "ing drive "
DRVLET  DB      "A$"
REQUEST DB      13,10,"Abort, Retry, Ignore? $"

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

YES_NO  DB      "(Y/N)? $"
anoprompt db    cr,lf,'Copy another $'
cpymsg  db      cr,lf,cr,lf,'Copying...$'
good1   db      cr,lf,cr,lf
goodmsg db      'Copy complete',cr,lf,'$'
ABMES   db      'Copy not completed',cr,lf,'$'
srcmsg  db      cr,lf,cr,lf,'Insert source diskette in drive '
srclet  db      'A:$'
fdstmsg db      cr,lf,'Insert formatted target diskette in drive '
fdstlet db      'A:$'
dstmsg  db      cr,lf,'Insert target diskette in drive '
dstlet  db      'A:$'
keymsg  db      cr,lf,'Strike any key when ready $'
drverr1 db      cr,lf,'Invalid drive specification',cr,lf,'$'
drverr3 db      cr,lf,cr,lf,'Source and target disks are not the'
        db      cr,lf,'  same format. Cannot do the copy.'
crlf    db      cr,lf,'$'

CONST   ENDS
        END
   