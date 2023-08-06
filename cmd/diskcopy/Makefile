OBJS = diskcopy.obj   diskmes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

DISKCOPY.COM: $(OBJS)
	$(LINK) DISKCOPY+DISKMES;
	$(EXE2BIN) DISKCOPY DISKCOPY.COM
	del -f $(OBJS) DISKCOPY.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst DISKCOPY.COM