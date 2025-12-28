# OBJCODE.MAK - Borland Makefile for Qmodem
# -------------------------------------------------
# Make sure the Borland version of Make and Turbo Assembler is in your path and 
# then execute with:
#
#	make -fobjcode 
#
#

adir=src\   		# line must end with a comment to retain the trailing backslash
asm=TASM.EXE 

dummy: objcode

objcode: $(adir)checkrim.obj $(adir)cinkey2.obj $(adir)com16550.obj \
	$(adir)com8250.obj $(adir)comisi.obj $(adir)comm.obj \
	$(adir)comp-crc.obj $(adir)crcblock.obj $(adir)crcupd.obj \
	$(adir)delay.obj $(adir)desqview.obj $(adir)downld0a.obj \
	$(adir)execswap.obj $(adir)givebk31.obj $(adir)int14.obj \
	$(adir)int1c.obj $(adir)int1cisi.obj $(adir)tpstack.obj \
	$(adir)updcrc.obj

.asm.obj:
	@ cd $(asmdir)
	$(asm) $.;
	@ cd ..

# Assembler source files
$(adir)checkrim.obj: $(adir)checkrim.asm
$(adir)cinkey2.obj: $(adir)cinkey2.asm
$(adir)com16550.obj: $(adir)com16550.asm
$(adir)com8250.obj: $(adir)com8250.asm
$(adir)comisi.obj: $(adir)comisi.asm
$(adir)comm.obj: $(adir)comm.asm
$(adir)comp-crc.obj: $(adir)comp-crc.asm
$(adir)crcblock.obj: $(adir)crcblock.asm
$(adir)crcupd.obj: $(adir)crcupd.asm
$(adir)delay.obj: $(adir)delay.asm
$(adir)desqview.obj: $(adir)desqview.asm
$(adir)downld0a.obj: $(adir)downld0a.asm
$(adir)execswap.obj: $(adir)execswap.asm
$(adir)givebk31.obj: $(adir)givebk31.asm
$(adir)int14.obj: $(adir)int14.asm
$(adir)int1c.obj: $(adir)int1c.asm
$(adir)initcisi.obj: $(adir)int1cisi.asm
$(adir)tpstack.obj: $(adir)tpstack.asm
$(adir)updcrc.obj: $(adir)updcrc.asm
