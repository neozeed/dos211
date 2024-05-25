#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = format.obj   formes.obj   genfor.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

FORMAT.COM: $(OBJS)
	$(LINK) FORMAT+FORMES+GENFOR;
	$(EXE2BIN) FORMAT FORMAT.COM
	del -f $(OBJS) FORMAT.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst FORMAT.COM