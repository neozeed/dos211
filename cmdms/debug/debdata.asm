.xlist
.xcref
INCLUDE debequ.asm
INCLUDE ..\..\inc\dossym.asm
.list
.cref

CODE    SEGMENT PUBLIC BYTE 'CODE'
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
CONST   ENDS

DATA    SEGMENT PUBLIC BYTE
DATA    ENDS

DG      GROUP   CODE,CONST,DATA

DATA    SEGMENT PUBLIC BYTE


        PUBLIC  ParityFlag,XNXOPT,XNXCMD,SWITCHAR,EXTPTR,HANDLE,TRANSADD
        PUBLIC  PARSERR,ASMADD,DISADD,DISCNT,ASMSP,INDEX,DEFDUMP,DEFLEN
        PUBLIC  REGSAVE,SEGSAVE,OFFSAVE,TEMP,BUFFER,BYTCNT,OPCODE,AWORD
        PUBLIC  REGMEM,MIDFLD,MODE,NSEG,OPBUF,BRKCNT,TCOUNT,ASSEM_CNT
        PUBLIC  ASSEM1,ASSEM2,ASSEM3,ASSEM4,ASSEM5,ASSEM6,BYTEBUF,BPTAB
        PUBLIC  DIFLG,SIFLG,BXFLG,BPFLG,NEGFLG,NUMFLG,MEMFLG,REGFLG
        PUBLIC  MOVFLG,TSTFLG,SEGFLG,LOWNUM,HINUM,F8087,DIRFLG,DATAEND


ParityFlag  DB  0
XNXOPT  DB      ?                       ; AL OPTION FOR DOS COMMAND
XNXCMD  DB      ?                       ; DOS COMMAND FOR OPEN_A_FILE TO PERFORM
SWITCHAR DB     ?                       ; CURRENT SWITCH CHARACTER
EXTPTR  DW      ?                       ; POINTER TO FILE EXTENSION
HANDLE  DW      ?                       ; CURRENT HANDLE
TRANSADD DD     ?                       ; TRANSFER ADDRESS

PARSERR DB      ?
ASMADD  DB      4 DUP (?)
DISADD  DB      4 DUP (?)
DISCNT  DW      ?
ASMSP   DW      ?                       ; SP AT ENTRY TO ASM
INDEX   DW      ?
DEFDUMP DB      4 DUP (?)
DEFLEN  DW      ?
REGSAVE DW      ?
SEGSAVE DW      ?
OFFSAVE DW      ?

; The following data areas are destroyed during hex file read
TEMP    DB      4 DUP(?)
BUFFER  LABEL   BYTE
BYTCNT  DB      ?
OPCODE  DW      ?
AWORD   DB      ?
REGMEM  DB      ?
MIDFLD  DB      ?
MODE    DB      ?
NSEG    DW      ?
OPBUF   DB      OPBUFLEN DUP (?)
BRKCNT  DW      ?                       ; Number of breakpoints
TCOUNT  DW      ?                       ; Number of steps to trace
ASSEM_CNT       DB      ?               ; preserve order of assem_cnt and assem1
ASSEM1          DB      ?
ASSEM2          DB      ?
ASSEM3          DB      ?
ASSEM4          DB      ?
ASSEM5          DB      ?
ASSEM6          DB      ?               ; preserve order of assemx and bytebuf
BYTEBUF DB      BUFLEN  DUP (?)         ; Table used by LIST
BPTAB   DB      BPLEN   DUP (?)         ; Breakpoint table
DIFLG   DB      ?
SIFLG   DB      ?
BXFLG   DB      ?
BPFLG   DB      ?
NEGFLG  DB      ?
NUMFLG  DB      ?                       ; ZERO MEANS NO NUMBER SEEN
MEMFLG  DB      ?
REGFLG  DB      ?
MOVFLG  DB      ?
TSTFLG  DB      ?
SEGFLG  DB      ?
LOWNUM  DW      ?
HINUM   DW      ?
F8087   DB      ?
DIRFLG  DB      ?
        DB      BUFFER+BUFSIZ-$ DUP (?)

DATAEND LABEL   WORD

DATA    ENDS
        END
