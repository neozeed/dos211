#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = recover.obj recmes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

RECOVER.COM: $(OBJS)
	$(LINK) RECOVER+RECMES;
	$(EXE2BIN) RECOVER RECOVER.COM
	del -f $(OBJS) RECOVER.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst RECOVER.COM