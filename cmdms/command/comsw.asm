; Use the following booleans to set assembly flags
FALSE   EQU     0
TRUE    EQU     NOT FALSE

IBMVER  EQU     FALSE   ; Switch to build IBM version of Command
IBM     EQU     IBMVER
MSVER   EQU     TRUE    ; Switch to build MS-DOS version of Command

HIGHMEM EQU     FALSE   ; Run resident part above transient (high memory)
KANJI   EQU     false   ; Support for dual byte Microsoft KANJI standard
IBMJAPAN        EQU     FALSE   ;MUST BE TRUE (along with IBM and KANJI)

