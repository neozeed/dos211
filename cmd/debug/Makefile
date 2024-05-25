#
####################### dependencies begin here. #########################
#
include ..\..\rules



OBJS = debasm.obj     debcom1.obj    debcom2.obj    debconst.obj   debdata.obj    debmes.obj     \
	debuasm.obj debug.obj

MASM = msdos ..\..\tools\masm
LINK = msdos ..\..\tools\LINK
EXE2BIN = msdos ..\..\tools\exe2bin.exe

DEBUG.COM: $(OBJS)
	$(LINK) DEBUG+DEBCOM1+DEBCOM2+DEBCONST+DEBDATA+DEBASM+DEBUASM+DEBMES;
	$(EXE2BIN) DEBUG DEBUG.COM
	del -f $(OBJS) DEBUG.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst DEBUG.COM