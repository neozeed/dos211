        title   EDLIN Messages

;-----------------------------------------------------------------------;
;                                                                       ;
;       Done for Vers 2.00 (rev 9) by Aaron Reynolds                    ;
;       Update for rev. 11 by M.A. Ulloa                                ;
;                                                                       ;
;-----------------------------------------------------------------------;

FALSE   EQU     0
TRUE    EQU     NOT FALSE


        .xlist
        INCLUDE ..\..\inc\DOSSYM.ASM
        .list


CODE    SEGMENT PUBLIC BYTE
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
CONST   ENDS

DATA    SEGMENT PUBLIC BYTE
        EXTRN   QFLG:BYTE,FCB2:BYTE
DATA    ENDS

DG      GROUP   CODE,CONST,DATA

CODE SEGMENT PUBLIC BYTE

ASSUME  CS:DG,DS:DG,SS:DG,ES:DG

        PUBLIC  QUIT,QUERY
        EXTRN   rest_dir:NEAR,CRLF:NEAR

QUIT:
        MOV     DX,OFFSET DG:QMES
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT
        INT     21H              ;Really quit?
        AND     AL,5FH
        CMP     AL,"Y"
        JZ      NOCRLF
        JMP     CRLF
NOCRLF:
        MOV     DX,OFFSET DG:FCB2
        MOV     AH,FCB_CLOSE
        INT     21H
        MOV     AH,FCB_DELETE
        INT     21H
        call    rest_dir                ;restore directory if needed
        INT     20H

QUERY:
        TEST    BYTE PTR [QFLG],-1
        JZ      RET9
        MOV     DX,OFFSET DG:ASK
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT
        INT     21H
        PUSH    AX
        CALL    CRLF
        POP     AX
        CMP     AL,13           ;Carriage return means yes
        JZ      RET9
        CMP     AL,"Y"
        JZ      RET9
        CMP     AL,"y"
RET9:   RET

CODE    ENDS

CONST   SEGMENT PUBLIC BYTE

        PUBLIC  BADDRV,NDNAME,bad_vers_err,opt_err,NOBAK
        PUBLIC  NODIR,DSKFUL,MEMFUL,FILENM,BADCOM,NEWFIL
        PUBLIC  NOSUCH,TOOLNG,EOF,DEST,MRGERR,ro_err,bcreat

BADDRV  DB      "Invalid drive or file name$"
NDNAME  DB      "File name must be specified$"

bad_vers_err db "Incorrect DOS version$"
opt_err db      "Invalid Parameter$"
ro_err  db      "Invalid operation: R/O file",13,10,"$"
bcreat  db      "File Creation Error",13,10,"$"

NOBAK   DB      "Cannot edit .BAK file--rename file$"
NODIR   DB      "No room in directory for file$"
DSKFUL  DB      "Disk full-- write not completed$"
MEMFUL  DB      13,10,"Insufficient memory",13,10,"$"
FILENM  DB      "File not found",13,10,"$"
BADCOM  DB      "Entry error",13,10,"$"
NEWFIL  DB      "New file",13,10,"$"
NOSUCH  DB      "Not found",13,10,"$"
ASK     DB      "O.K.? $"
TOOLNG  DB      "Line too long",13,10,"$"
EOF     DB      "End of input file",13,10,"$"
QMES    DB      "Abort edit (Y/N)? $"
DEST    DB      "Must specify destination line number",13,10,"$"
MRGERR  DB      "Not enough room to merge the entire file",13,10,"$"

CONST   ENDS
        END
                        