#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = more.obj moremes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

MORE.COM: $(OBJS)
	$(LINK) MORE+MOREMES;
	$(EXE2BIN) MORE MORE.COM
	del -f $(OBJS) MORE.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst MORE.COM