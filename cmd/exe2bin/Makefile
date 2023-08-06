OBJS = exe2bin.obj   exemes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

EXE2BIN.COM: $(OBJS)
	$(LINK) EXE2BIN+EXEMES;
	del -f $(OBJS)

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst EXE2BIN.COM