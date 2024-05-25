#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = sort.obj sortmes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe
EXEFIX = msdos ..\..\tools\exefix

SORT.COM: $(OBJS)
	$(LINK) SORT+SORTMES;
	$(EXEFIX) SORT.EXE 1 1
	del -f $(OBJS)

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst SORT.EXE