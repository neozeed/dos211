OBJS = print.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

PRINT.COM: $(OBJS)
	$(LINK) PRINT;
	$(EXE2BIN) PRINT PRINT.COM
	del -f $(OBJS) PRINT.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst PRINT.COM