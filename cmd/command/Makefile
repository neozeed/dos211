OBJS = command.obj    copy.obj       copyproc.obj   cparse.obj       init.obj       rdata.obj      \
	rucode.obj     tcode.obj      tcode2.obj     tcode3.obj     tcode4.obj     tcode5.obj       \
	tdata.obj      tspc.obj       tucode.obj     uinit.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

COMMAND.COM: $(OBJS)
	$(LINK) @COMLINK
	$(EXE2BIN) COMMAND COMMAND.COM
	del -f $(OBJS) COMMAND.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst COMMAND.COM