OBJS = sys.obj sysmes.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe
EXEFIX = msdos ..\..\tools\exefix

SYS.COM: $(OBJS)
	$(LINK) SYS+SYSMES;
	$(EXE2BIN) SYS SYS.COM
	del -f $(OBJS) SYS.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst sys.EXE