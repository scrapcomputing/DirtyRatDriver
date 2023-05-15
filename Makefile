# Makefile to create CTMOUSE.EXE
# tools used:
# - GNU make
# - JWasm v2.12pre
# - gcc or clang
# - bin2exe (built from source included in the repo)

# As default, just the English version CTMOUSE.EXE is created.
# To create all versions, enter "wmake alllang".

# Macros for building, deleting ########################################

AS=jwasm
GCC=gcc
RM=rm -f

# Uncomment this to build for 8088/8086
ASFLAGS=-c -bin -0
# Uncomment this to build for 286 and better
# ASFLAGS=-c -bin -2

# Targets ##############################################################

all: drtrat.exe drtproto.exe

alllang: ctm-en.exe ctm-br.exe ctm-de.exe ctm-es.exe ctm-fr.exe \
	ctm-hu.exe ctm-it.exe ctm-lv.exe ctm-pl.exe ctm-pt.exe ctm-sk.exe

drtrat.exe: ctm-en.msg ctmouse.asm bin2exe
	$(AS) $(ASFLAGS) -D\?LANG=ctm-en -Foctmouse.bin ctmouse.asm
	./bin2exe -s 512 ctmouse.bin drtrat.exe

drtproto.exe: utility/drtproto.asm bin2exe
	$(MAKE) -C utility drtproto.exe


%.exe: %.msg ctmouse.asm bin2exe
	$(AS) $(ASFLAGS) -D\?LANG=$* -Fo$*.bin ctmouse.asm
	./bin2exe -s 512 $*.bin $*.exe

bin2exe: bin2exe.c
	$(GCC) bin2exe.c -o bin2exe

# Clean up #############################################################

clean:
	-$(RM) *.bin
	-$(RM) *.o
	-$(RM) *.lst
	-$(RM) *.map

distclean: clean
	-$(RM) bin2exe
	-$(RM) ctmouse.exe
	-$(RM) ctm-*.exe

