#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = fc.obj   fcmes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
FC = msdos ..\..\tools\exe2bin.exe

FC.COM: $(OBJS)
	$(LINK) FC+FCMES;
	del -f $(OBJS)

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst FC.EXE