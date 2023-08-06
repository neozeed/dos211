TITLE   DEBUGger Messages
FALSE   EQU     0
TRUE    EQU     NOT FALSE

SYSVER  EQU     FALSE                   ;if true, i/o direct to bios
                                        ; so DOS can be debugged
IBMJAPVER   EQU FALSE                   ; true for their special parity stuff

.xlist
.xcref
        INCLUDE ..\..\inc\DOSSYM.ASM
.cref
.list

FIRSTDRV EQU    "A"

CODE    SEGMENT PUBLIC BYTE 'CODE'
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
CONST   ENDS

DATA    SEGMENT PUBLIC BYTE
        EXTRN   ParityFlag:BYTE
DATA    ENDS

DG      GROUP   CODE,CONST,DATA


CODE    SEGMENT PUBLIC BYTE 'CODE'
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

        EXTRN   RPRBUF:NEAR,RESTART:NEAR
        PUBLIC  DRVERR, TrapParity, ReleaseParity, NMIInt, NMIIntEnd
TrapParity:
        IF IBMJAPVER
        PUSH    BX
        PUSH    ES
        PUSH    DX                      ; save location of new offset
        MOV     DX,OFFSET DG:NMIInt     ; DS:DX has new interrupt vector
        CALL    SwapInt                 ; diddle interrupts
        ASSUME  ES:NOTHING
        MOV     WORD PTR [NMIPtr],BX    ; save old offset
        MOV     WORD PTR [NMIPtr+2],ES  ; save old segment
        POP     DX                      ; get old regs back
        POP     ES                      ; restore old values
        ASSUME  ES:DG
        POP     BX
        MOV     BYTE PTR [ParityFlag],0 ; no interrupts detected yet!
        RET
SwapInt:
        PUSH    AX
        MOV     AX,(Get_interrupt_vector SHL 8) + 2
        INT     21h                     ; get old nmi vector
        MOV     AX,(Set_Interrupt_Vector SHL 8) + 2
        INT     21h                     ; let OS set new vector
        POP     AX
        ENDIF
        RET
ReleaseParity:
        IF  IBMJAPVER
        PUSH    DX
        PUSH    DS
        PUSH    BX
        PUSH    ES
        LDS     DX,DWORD PTR [NMIPtr]   ; get old vector
        CALL    SwapInt                 ; diddle back to original
        POP     ES
        POP     BX
        POP     DS
        POP     DX
        MOV     [ParityFlag],0          ; no interrupts possible!
        ENDIF
        RET

NMIInt:
        IF IBMJAPVER
        PUSH    AX                      ; save AX
        IN      AL,0A0h                 ; get status register
        OR      AL,1                    ; was there parity check?
        POP     AX                      ; get old AX back
        JZ      NMIChain                ; no, go chain interrupt
        OUT     0A2h,AL                 ; reset NMI detector
        MOV     CS:[ParityFlag],1       ; signal detection
        IRET
NMIChain:
        JMP     DWORD PTR CS:[NMIPtr]   ; chain the vectors
NMIPtr  DD      ?                       ; where old NMI gets stashed
        ENDIF
NMIIntEnd:

DRVERR: MOV     DX,OFFSET DG:DISK
        OR      AL,AL
        JNZ     SAVDRV
        MOV     DX,OFFSET DG:WRTPRO
SAVDRV:
        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES
        ADD     BYTE PTR DRVLET,FIRSTDRV
        MOV     SI,OFFSET DG:READM
        MOV     DI,OFFSET DG:ERRTYP
        CMP     BYTE PTR RDFLG,WRITE
        JNZ     MOVMES
        MOV     SI,OFFSET DG:WRITM
MOVMES:
        MOVSW
        MOVSW
        CALL    RPRBUF
        MOV     DX,OFFSET DG:DSKERR
        JMP     RESTART
CODEEND:

CODE    ENDS


CONST   SEGMENT PUBLIC BYTE

        PUBLIC  BADVER,ENDMES,CARRET,NAMBAD,NOTFND,NOROOM
        PUBLIC  NOSPACE,DRVLET
        PUBLIC  ACCMES
        PUBLIC  TOOBIG,SYNERR,ERRMES,BACMES
        PUBLIC  EXEBAD,HEXERR,EXEWRT,HEXWRT,WRTMES1,WRTMES2
        PUBLIC  EXECEMES, ParityMes
        EXTRN   RDFLG:BYTE

        IF      SYSVER
        PUBLIC  BADDEV,BADLSTMES
BADDEV      DB      "Bad device name",13,10,"$"
BADLSTMES   DB    "Couldn't open list device PRN",13,10
            DB      "Enter name of list device? $"
        ENDIF

BADVER      DB      "Incorrect DOS version",13,10,"$"
ENDMES      DB      13,10,"Program terminated normally"
CARRET      DB      13,10,"$"
NAMBAD      DB      "Invalid drive specification",13,10,"$"
NOTFND      DB      "File not found",13,10,"$"
NOROOM      DB      "File creation error",13,10,"$"
NOSPACE     DB      "Insufficient space on disk",13,10,"$"


DISK        DB      "Disk$"
WRTPRO      DB      "Write protect$"
DSKERR      DB      " error "
ERRTYP      DB      "reading drive "
DRVLET      DB      "A",13,10,"$"
READM       DB      "read"
WRITM       DB      "writ"


TOOBIG      DB      "Insufficient memory",13,10,"$"
SYNERR      DB      '^'
ERRMES      DB      " Error",13,10+80H
BACMES      DB      32,8+80H
EXEBAD      LABEL   BYTE
HEXERR      DB      "Error in EXE or HEX file",13,10,"$"
EXEWRT      LABEL   BYTE
HEXWRT      DB      "EXE and HEX files cannot be written",13,10,"$"
WRTMES1     DB      "Writing $"
WRTMES2     DB      " bytes",13,10,"$"
EXECEMES    DB     "EXEC failure",13,10,"$"
ACCMES      DB      "Access denied",13,10,"$"
ParityMes   DB      "Parity error or nonexistant memory error detected",13,10,"$"

CONSTEND:

CONST   ENDS
        END
