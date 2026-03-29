#
#	Makefile
#
#  FFODUMP main build file
#	- GPL-3.0
#


AS 	= nasm
Q 	= @
LD	= ld

SRC 	= main.asm
OBJ 	= obj.o



all:
	$(Q)$(AS) -f elf64 $(SRC) -o $(OBJ)
	$(Q)$(LD) $(OBJ) -o ffodump
	$(Q)echo " AS   $(SRC)"

clean:
	$(Q)rm $(OBJ) ffodump
	$(Q)echo " MKF  clean!"
