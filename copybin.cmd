del /f /q bin
del /f /q ms
@copy bios\IBMBIO.COM bin
@copy dos\IBMDOS.COM bin
@copy cmd\exe2bin\EXE2BIN.EXE bin
@copy cmd\fc\FC.EXE bin
@copy cmd\find\FIND.EXE bin
@copy cmd\sort\SORT.EXE bin
@copy cmd\chkdsk\CHKDSK.COM bin
@copy cmd\command\COMMAND.COM bin
@copy cmd\debug\DEBUG.COM bin
@copy cmd\diskcopy\DISKCOPY.COM bin
@copy cmd\edlin\EDLIN.COM bin
@copy cmd\format\FORMAT.COM bin
@copy cmd\more\MORE.COM bin
@copy cmd\print\PRINT.COM bin
@copy cmd\recover\RECOVER.COM bin
@copy cmd\sys\SYS.COM bin

@copy msdos\MSDOS.SYS msbin
@copy cmdms\sort\SORT.EXE msbin
@copy cmdms\command\COMMAND.COM msbin
@copy cmdms\debug\DEBUG.COM msbin
@copy cmdms\format\FORMAT.COM msbin
@copy cmdms\more\MORE.COM msbin
@copy cmdms\print\PRINT.COM msbin
@copy cmdms\recover\RECOVER.COM msbin

