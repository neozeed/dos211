#
####################### dependencies begin here. #########################
#
include ..\rules


OBJ = ibmbio.obj    sysimes.obj   sysinit.obj

MASM = msdos ..\tools\masm
LINK = msdos ..\tools\LINK
EXE2BIN = msdos ..\tools\exe2bin.exe

ibmbio.com: $(OBJ)
	$(LINK) IBMBIO+SYSINIT+SYSIMES;
	$(EXE2BIN) IBMBIO IBMBIO.COM < 70.TXT
	del -f $(OBJ) ibmbio.exe

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL
#	$(MASM) $*.asm $*.obj $*.lst $*.crf


clean:
	del -f $(OBJ) *.crf *.lst ibmbio.com