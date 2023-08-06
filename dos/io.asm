
CODE    SEGMENT BYTE PUBLIC 'CODE'
;
; (Reconstructed) IO.ASM for MSDOS
;
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

        public  $STD_AUX_OUTPUT
        public  $STD_PRINTER_OUTPUT
        public  Tab

        extrn   ESCCHAR:BYTE
        extrn   PFLAG:BYTE
        extrn   CARPOS:BYTE
        extrn   STARTPOS:BYTE
        extrn   INBUF:BYTE
        extrn   INSMODE:BYTE
        extrn   CHARCO:BYTE
        extrn   STATCHK:NEAR
        extrn   RAWOUT:NEAR
        extrn   RAWOUT2:NEAR
        extrn   SPOOLINT:NEAR
        extrn   IOFUNC:NEAR

.xlist
.xcref
INCLUDE ..\inc\DOSSYM.ASM
INCLUDE ..\inc\DEVSYM.ASM
.cref
.list


        procedure       $STD_CON_INPUT, NEAR
        call    $STD_CON_INPUT_NO_ECHO
        push    ax
        call    OUT
        pop     ax
        return
$STD_CON_INPUT  endp
;
        procedure       $STD_CON_OUTPUT, NEAR
        mov     al, dl
        entry   OUT
        cmp     al, ' '
        jc      out_controlch
        cmp     al, c_DEL       ;DEL does not increase CARPOS
        jz      out_notprint
        inc     ss:CARPOS
out_notprint:
        push    ds
        push    si
        inc     ss:charco
        and     ss:charco, 3
        jnz     out_nobreak
        push    ax
        call    STATCHK
        pop     ax
out_nobreak:
        call    RAWOUT
        pop     si
        pop     ds
        test    ss:PFLAG, 0FFH          ;Echoing to printer?
        retz
        push    bx
        push    ds
        push    si
        mov     bx, 1                   ;STDOUT
        invoke  GET_IO_FCB
        jc      j_out_finish
        test    [SI.fcb_DEVID],080H     ;If STDOUT is redirected to a file,
        jz      j_out_finish            ;don't echo to printer.
        mov     bx, 4
        jmp     short out_rawout2       ;Otherwise echo to stdlpt
        ret

j_out_finish:
        jmp     short out_finish

out_controlch:
        cmp     al, c_CR        ;CR resets console X to 0
        jz      out_cr
        cmp     al, c_BS        ;BS decreases console X
        jz      out_bs
        cmp     al, c_HT        ;HT moves to next tabstop
        jnz     out_notprint
        mov     al, ss:CARPOS
        or      al, 0F8h
        neg     al              ;Spaces to next tabstop

TAB:
        push    cx
        mov     cl, al
        mov     ch, 0
        jcxz    TAB_end
TAB1:
        mov     al, ' '
        call    OUT
        loop    TAB1
TAB_end:
        pop     cx
        ret
;
out_cr:
        mov     ss:CARPOS, 0
        jmp     short out_notprint
;
j_OUT:  jmp     short OUT
;
out_bs:
        dec     ss:CARPOS
        jmp     short out_notprint

$STD_CON_OUTPUT endp

        procedure BUFOUT, NEAR
        cmp     al, ' '         ;Render printable characters
        jnc     j_OUT
        cmp     al, c_HT        ;and tabs
        jz      j_OUT
        push    ax
        mov     al, '^'
        call    OUT
        pop     ax
        or      al, 40h
        call    OUT
        return
BUFOUT  endp

        procedure   $STD_AUX_INPUT,NEAR   ;System call 3
        call    STATCHK
        mov     bx, 3   ;stdaux file handle
        call    GET_IO_FCB
        retc
        jmp     short auxin2
;
auxin1: call    SPOOLINT
auxin2: mov     ah, 1   ;Get input status
        call    IOFUNC
        jz      auxin1  ;Spin until there's something there
        xor     ah, ah
        call    IOFUNC  ;Get the byte
        ret

$STD_AUX_INPUT  endp

        procedure   $STD_AUX_OUTPUT,NEAR        ;System call 4
        push    bx
        mov     bx, 3   ;stdaux file handle
        jmp     short aux_lpt_out
;
        entry $STD_PRINTER_OUTPUT
        push    bx
        mov     bx, 4   ;stdlpt file handle
aux_lpt_out:
        mov     al, dl
        push    ax
        call    STATCHK
        pop     ax
        push    ds
        push    si
out_rawout2:
        call    RAWOUT2
out_finish:
        pop     si
        pop     ds
        pop     bx
        ret
$STD_AUX_OUTPUT endp



        public  $STD_CON_INPUT_NO_ECHO
        public  $STD_CON_STRING_OUTPUT

        procedure   $STD_CON_INPUT_NO_ECHO,NEAR   ;System call 8
        push    ds
        push    si
conin1: call    STATCHK ;Wait for input ready
        jz      conin1
        xor     ah, ah
        call    IOFUNC
        pop     si
        pop     ds
        return

$STD_CON_INPUT_NO_ECHO  endp

        procedure   $STD_CON_STRING_OUTPUT,NEAR   ;System call 9
ASSUME  DS:NOTHING,ES:NOTHING

        mov     si, dx
output1:
        lodsb
        cmp     al,'$'
        retz
        call    OUT
        jmp     short output1


$STD_CON_STRING_OUTPUT endp

INCLUDE STRIN.ASM

        ASSUME  SS:DOSGROUP,CS:DOSGROUP

        public  $STD_CON_INPUT_STATUS
        public  $STD_CON_INPUT_FLUSH

        extrn   REDISP:NEAR

        procedure $STD_CON_INPUT_STATUS, NEAR   ;System call 11
        call    STATCHK
        mov     al, 0
        retz
        or      al, 0FFH
        ret

$STD_CON_INPUT_STATUS   endp

        procedure $STD_CON_INPUT_FLUSH, NEAR    ;System call 12
        push    ax
        push    dx
        xor     bx, bx
        call    GET_IO_FCB
        jc      flush1
        mov     ah, 4
        call    IOFUNC
flush1: pop     dx
        pop     ax
        mov     ah, al
        cmp     al, STD_CON_INPUT
        jz      flush2
        cmp     al, RAW_CON_IO
        jz      flush2
        cmp     al, RAW_CON_INPUT
        jz      flush2
        cmp     al, STD_CON_INPUT_NO_ECHO
        jz      flush2
        cmp     al, STD_CON_STRING_INPUT
        jz      flush2
        mov     al, 0
        ret
;
flush2: cli
        jmp     REDISP
$STD_CON_INPUT_FLUSH    endp

CODE    ENDS
        END
