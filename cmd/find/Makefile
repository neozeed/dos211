OBJS = find.obj   findmes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
FIND = msdos ..\..\tools\exe2bin.exe

FIND.COM: $(OBJS)
	$(LINK) FIND+FINDMES;
	del -f $(OBJS)

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst FIND.EXE