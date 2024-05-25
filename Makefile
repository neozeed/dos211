#************************* Root level Makefile *************************

make    =nmake

all:
	cd bios
        $(make)
	cd ..
	cd cmd
	cd chkdsk
        $(make)
	cd ..\command
        $(make)
	cd ..\debug
        $(make)
	cd ..\diskcopy
        $(make)
	cd ..\edlin
        $(make)
	cd ..\exe2bin
        $(make)
	cd ..\fc
        $(make)
	cd ..\find
        $(make)
	cd ..\format
        $(make)
	cd ..\more
        $(make)
	cd ..\print
        $(make)
	cd ..\recover
        $(make)
	cd ..\sort
        $(make)
	cd ..\sys
        $(make)
	cd ..\..\cmdms
	cd command
        $(make)
	cd ..\debug
        $(make)
	cd ..\format
        $(make)
	cd ..\more
        $(make)
	cd ..\print
        $(make)
	cd ..\recover
        $(make)
	cd ..\sort
        $(make)
	cd ..\..
	cd dos
        $(make)
	cd ..\msdos
        $(make)
	cd ..


clean:
	cd bios
        $(make) clean
	cd ..
	cd cmd
	cd chkdsk
        $(make) clean
	cd ..\command
        $(make) clean
	cd ..\debug
        $(make) clean
	cd ..\diskcopy
        $(make) clean
	cd ..\edlin
        $(make) clean
	cd ..\exe2bin
        $(make) clean
	cd ..\fc
        $(make) clean
	cd ..\find
        $(make) clean
	cd ..\format
        $(make) clean
	cd ..\more
        $(make) clean
	cd ..\print
        $(make) clean
	cd ..\recover
        $(make) clean
	cd ..\sort
        $(make) clean
	cd ..\sys
        $(make) clean
	cd ..\..\cmdms
	cd command
        $(make) clean
	cd ..\debug
        $(make) clean
	cd ..\format
        $(make) clean
	cd ..\more
        $(make) clean
	cd ..\print
        $(make) clean
	cd ..\recover
        $(make) clean
	cd ..\sort
        $(make) clean
	cd ..\..
	cd dos
        $(make) clean
	cd ..\msdos
        $(make) clean
	cd ..
