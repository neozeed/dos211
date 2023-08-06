        TITLE   DISKCOPY MSDOS Disk Copier
;----------------------------------------------------------
;
;       Diskcopy - Program to copy entire diskettes
;
;       Copyright 1982 by Microsoft Corporation
;       Written by Chris Peters, August 1982
;
;-----------------------------------------------------------
;
; Rev 1.00      Initial instance
; Rev 1.20
;               Read in > 64K hunks

FALSE   EQU     0
TRUE    EQU     NOT FALSE


bdos    equ     21h
boot    equ     20h
aread   equ     25h
awrite  equ     26h

        INCLUDE ..\..\inc\DOSSYM.ASM

fcb     equ     5ch

CODE    SEGMENT PUBLIC
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
CONST   ENDS

DATA    SEGMENT PUBLIC BYTE
DATA    ENDS

DG      GROUP   CODE,CONST,DATA

CODE  segment PUBLIC
        assume  cs:DG,ds:DG,es:DG,ss:DG

        EXTRN   dskrd:NEAR,dskwrt:NEAR,promptyn:NEAR
        PUBLIC  PRINT,PCRLF,ASKANOTHER,sec64k,secsiz

        org     100h

diskcopy:
        jmp     disk_entry

HEADER  DB      "Vers 1.20"

source  db      0
dest    db      0
count   dw      0
start   dw      0
secsiz  dw      0
passcnt dw      0
sec64k  dw      0
media   db      0
buffer  dw      0
bufsiz  dw      0

pcrlf:  mov     dx,OFFSET DG: crlf
print:  mov     ah,STD_CON_STRING_OUTPUT
        int     bdos
pret:   ret

getkey: mov     dx,OFFSET DG: keymsg
        call    print
        mov     ah,12                   ;wait for key press
        mov     al,1
        int     21h
        ret
;
; returns number of sectors on the disk in cx, sector size in ax
;
getdpb: push    ds
        inc     dl
        mov     ah,GET_DPB
        int     bdos
        mov     al,[bx+dpb_cluster_mask]
        cbw
        inc     ax
        mov     cx,[bx+dpb_max_cluster]
        dec     cx
        mul     cx
        add     ax,[bx+dpb_first_sector]
        mov     cx,[bx+dpb_sector_size]
        mov     bl,[bx+dpb_media]
        pop     ds
        ret

getdrv: mov     al,[bx]
        dec     al
        cmp     al,-1
        jnz     get1
        mov     ah,19h
        int     21h
get1:   ret
;
; set zero flag if drives the same
;
compare:push    ax
        mov     al,[dest]
        cmp     al,[source]
        pop     ax
        ret

printerr:
        call    print
        int     boot

disk_entry:
        cli                     ;set up local stack
        mov     sp,100h
        sti


;Code to print header
;       PUSH    AX
;       MOV     DX,OFFSET DG: HEADER
;       CALL    print
;       POP     AX

        mov     dx,OFFSET DG: drverr1
        inc     al
        jz      printerr
        inc     ah
        jz      printerr

        mov     bx,fcb
        call    getdrv
        mov     [source],al
        add     [srclet],al
        mov     bx,fcb+16
        call    getdrv
        mov     [dest],al
        add     [dstlet],al
        add     [fdstlet],al
        mov     ah,DISK_RESET
        int     bdos                    ;empty buffer queue

        mov     bx,OFFSET DG:progsiz + 15
        shr     bx,1
        shr     bx,1
        shr     bx,1
        shr     bx,1
        mov     ah,setblock
        int     21h                     ;give back extra memory

        mov     bx,0FFFFh               ;ask for Biggest hunk
        mov     ah,alloc
        int     21h
        jnc     gotmem
        mov     ah,alloc
        int     21h
gotmem:
        mov     [buffer],ax
        mov     [bufsiz],bx

copyagn:
        mov     [start],0               ;Initialize start sector
        call    compare
        jz      onedrv1
        mov     dx,OFFSET DG: srcmsg
        call    print
onedrv1:mov     dx,OFFSET DG: fdstmsg
        call    print
        call    getkey

        mov     dl,[dest]
        call    getdpb
        mov     [count],ax
        mov     [secsiz],cx
        mov     [media],bl

        call    compare
        jnz     twodrv1
        mov     dx,OFFSET DG: srcmsg
        call    print
        call    getkey

twodrv1:mov     dl,[source]
        call    getdpb
        mov     dx,OFFSET DG: drverr3
        cmp     [media],bl              ;make sure media and sizes match
        jnz     errv
        cmp     [count],ax
        jz      sizeok
errv:   jmp     printerr

sizeok:
        mov     bx,[secsiz]
        add     bx,15
        mov     cl,4
        shr     bx,cl
        xor     dx,dx
        mov     ax,1000H
        div     bx
        mov     [sec64k],ax     ;set number of sectors in 64K bytes
        xor     dx,dx
        mov     ax,[bufsiz]
        div     bx
        mov     [passcnt],ax    ;set number of sectors per pass

        call    compare         ;print copying....
        jz      loop
        mov     dx,OFFSET DG: cpymsg
        call    print

loop:   push    ds

        mov     al,[source]
        xor     bx,bx
        mov     cx,[passcnt]
        cmp     cx,[count]
        jbe     countok
        mov     cx,[count]
countok:mov     dx,[start]
        mov     ds,[buffer]
        call    dskrd
        pop     ds

        push    ds
        push    cx

        call    compare
        jnz     twodrv2
        mov     dx,OFFSET DG: dstmsg
        call    print
        call    getkey

twodrv2:mov     al,[dest]
        xor     bx,bx
        mov     dx,[start]
        mov     ds,[buffer]
        call    dskwrt
        pop     cx
        pop     ds

        add     [start],cx
        sub     [count],cx
        jbe     quitcopy

        call    compare
        jnz     loop
        mov     dx,OFFSET DG: srcmsg
        call    print
        call    getkey
        jmp     loop

quitcopy:
        mov     ah,DISK_RESET
        int     bdos                    ;empty buffer queue
        mov     dx,OFFSET DG: goodmsg
        call    compare
        jnz     twodrv3
        mov     dx,OFFSET DG: good1

ASKANOTHER:
twodrv3:call    print
        mov     dx,OFFSET DG:anoprompt
        call    promptyn
        jnz     alldone
        jmp     copyagn
alldone:
        int     boot            ;home, james...

CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        EXTRN   fdstmsg:BYTE,dstmsg:BYTE,fdstlet:BYTE,dstlet:BYTE
        EXTRN   cpymsg:BYTE,good1:BYTE,goodmsg:BYTE,srcmsg:BYTE,srclet:BYTE
        EXTRN   keymsg:BYTE,drverr1:BYTE,drverr3:BYTE,crlf:BYTE
        EXTRN   anoprompt:BYTE

        db      ' MICROSOFT - PETERS '
CONST   ENDS

DATA    SEGMENT BYTE

progsiz LABEL   BYTE

DATA    ends
        end     diskcopy
                            