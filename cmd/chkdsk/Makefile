#
####################### dependencies begin here. #########################
#
include ..\..\rules


OBJS = chkdsk.obj    chkmes.obj    chkproc.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

CHKDSK.COM: $(OBJS)
	$(LINK) CHKDSK+CHKPROC+CHKMES;
	$(EXE2BIN) CHKDSK CHKDSK.COM
	del -f $(OBJS) CHKDSK.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst CHKDSK.COM