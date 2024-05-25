#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = edlin.obj     edlmes.obj    edlproc.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

EDLIN.COM: $(OBJS)
	$(LINK) EDLIN+EDLPROC+EDLMES;
	$(EXE2BIN) EDLIN EDLIN.COM
	del -f $(OBJS) EDLIN.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst EDLIN.COM