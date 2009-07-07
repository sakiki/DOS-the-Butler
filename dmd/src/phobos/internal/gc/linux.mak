
# makefile to build linux D garbage collector

#DMD=../../../dmd
DMD=dmd
CFLAGS=-g -m32
#DFLAGS=-unittest -g -release
DFLAGS=-release -O -inline -I../..
#DFLAGS=-release -inline -O
CC=gcc

OBJS= gc.o gcx.o gcbits.o gclinux.o gcold.o

SRC= gc.d gcx.d gcbits.d win32.d gclinux.d gcold.d testgc.d win32.mak linux.mak

.c.o:
	$(CC) -c $(CFLAGS) $*

.d.o:
	$(DMD) -c $(DFLAGS) $*

targets : testgc dmgc.a

testgc : testgc.o $(OBJS) linux.mak
	$(DMD) -of$@ testgc.o gc.o gcx.o gcbits.o gclinux.o -g

testgc.o : testgc.d
	$(DMD) -c $(DFLAGS) testgc.d

dmgc.a : $(OBJS) linux.mak
	ar -r $@ $(OBJS)

gc.o : gc.d
	$(DMD) -c $(DFLAGS) gc.d

gcold.o : gcold.d
	$(DMD) -c $(DFLAGS) gcold.d

gcx.o : gcx.d
	$(DMD) -c $(DFLAGS) gcx.d gcbits.d

#gcbits.o : gcbits.d
#	$(DMD) -c $(DFLAGS) gcbits.d

gclinux.o : gclinux.d
	$(DMD) -c $(DFLAGS) gclinux.d

zip : $(SRC)
	$(RM) dmgc.zip
	zip dmgc $(SRC)

clean:
	$(RM) $(OBJS) dmgc.a testgc testgc.o
