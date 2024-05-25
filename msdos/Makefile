#
####################### dependencies begin here. #########################
#
include ..\rules


OBJS = msdos.obj mscode.obj dosmes.obj misc.obj getset.obj dircall.obj alloc.obj dev.obj dir.obj disk.obj \
	fat.obj rom.obj stdbuf.obj stdcall.obj stdctrlc.obj stdfcb.obj stdproc.obj stdio.obj \
	time.obj xenix.obj xenix2.obj 

MASM = $(emu) ..\tools\masm
LINK = $(emu) ..\tools\LINK
EXE2BIN = $(emu) ..\tools\exe2bin.exe

MSDOS.SYS: $(OBJS)
	$(LINK) @DOSLINK
	$(EXE2BIN) MSDOS MSDOS.SYS
	del -f $(OBJS) MSDOS.EXE

%.obj: %.asm
	$(MASM) $*.asm $*.obj NUL NUL

clean:
	del -f $(OBJS) *.crf *.lst MSDOS.EXE MSDOS.SYS