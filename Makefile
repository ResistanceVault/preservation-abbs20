#
# SAS LKM makefile
#

LIBS		= lib:amiga.lib lib:sc.lib lib:pools.lib
OBJS		=  Node.o Main.o FSE.o transfer.o abbsint.o div.o tables.o msg.o paragon.o \
			Browse.o ABBSmy.o QWK.o rexx.o NodeSupport.o Exeption.o Hippo.o JEO.o

OBJSSN		= ram:Node.o Main.o FSE.o Exeption.o abbsint.o div.o tables.o msg.o paragon.o transfer.o \
			Browse.o ABBSmy.o QWK.o rexx.o NodeSupport.o Hippo.o JEO.o

.asm.o:
	; assembling $*.asm
	@macro68 $*.asm incdir include: quiet failat=10 strictcomments OBJFILE $*.o

.s.o:
	macro68 $*.s incdir include: quiet OBJFILE $*.o

.c.o:
	sc $*.c Data=FARONLY cpu=000 param=register Autoregister AbsFuncPointer NoStackCheck

ABBS:		$(OBJS)
		; Linking ABBS
		@slink <WITH <
FROM $(OBJS)
LIBRARY $(LIBS)
TO ABBS
NOICONS
NODEBUG
BATCH
QUIET
WITH withfile
<

ram:Node.o: ram:Node.Asm Include:Node.i
	macro68 ram:Node.asm incdir include,include: quiet OBJFILE ram:Node.o

FSE.o:	FSE.asm Include:Node.i include/BBS.i

Node.o:	Node.asm Include:Node.i include/BBS.i Include:Nodedefs.i

Div.o:	Div.asm Include:Node.i include/BBS.i

Paragon.o:	Paragon.asm Include:Node.i include/BBS.i

QWK.o:		QWK.c Include:Node.h include/BBS.h

Hippo.o:	Hippo.c Include:Node.h include/BBS.h

Transfer.o:	Transfer.asm Include:Node.i include/BBS.i

Browse.o:	Browse.asm Include:Node.i include/BBS.i

rexx.o:	rexx.asm

ABBSd:		$(OBJS)
		; Linking ABBSd
		@slink <WITH <
FROM $(OBJS)
LIBRARY $(LIBS)
TO ABBSd
NOICONS
BATCH
QUIET
WITH withfile
<

ABBSsn:		$(OBJSSN)
		; Linking ABBSsn
		@slink <WITH <
FROM $(OBJSSN)
LIBRARY $(LIBS)
TO ABBS
NOICONS
NODEBUG
BATCH
QUIET
WITH withfile
<
