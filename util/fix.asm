	opt 	L+,D+,O+	; linkable, debuginfo, optimize (?)

	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/dos.i'

	include	'asm.i'
	include	'bbs.i'

	code
start	move.l	4,a6
	openlib	dos

	move.l	#mem_SIZEOF,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	beq	no_mem
	move.l	d0,a5

	lea	bconfig(a5),a0
	lea	configfilename,a1
	move.l	#ConfigRecord_SIZEOF,d0
	bsr	readfile
	beq	no_file

;	lea	bNrTabell(a5),a0
;	lea	nrindexfilename,a1
;	move.l	#4*Hashentries,d0
;	bsr	readfile
;	beq.s	no_file

	lea	bHashTabell(a5),a0
	lea	indexfilename,a1
	move.l	#(hash_entry_SIZEOF*(DiffHashvalues+Hashentries)),d0
	bsr	readfile
	beq	no_file

	move.l	dosbase,a6
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	no_file

	moveq.l	#0,d7
1$	move.l	d4,d1
	lea	busermem(a5),a0
	move.l	a0,d2
	move.l	#UserRecord_SIZEOF,d3
	jsrlib	Read
	tst.l	d0
	beq	5$
	cmp.l	d3,d0
	bne	fil_err

	move.l	d7,Usernr(a5)
	lea	Name(a5),a0
	bsr	hash
2$	move.l	d0,d2
	lea	bHashTabell(a5),a1
	mulu	#hash_entry_SIZEOF,d0
	lea	0(a1,d0.l),a2		; Henter Hashentry
	moveq.l	#30,d0
	lea	h_Name(a2),a1
	lea	Name(a5),a0
	bsr	comparestringsfull
	beq.s	3$
	move.l	h_HashChain(a2),d0
	bne.s	2$
	lea	Name(a5),a0
	bsr	writedostext
	lea	hashnotfoundtxt,a0
	bsr	writedostext
	bra.s	9$
3$	move.l	d7,d0
	lea	bNrTabell(a5),a0
	lsl.l	#2,d0
	move.l	d2,0(a0,d0.l)
	move.l	d4,d1
	move.l	#-UserRecord_SIZEOF,d2
	move.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	move.l	d4,d1
	lea	busermem(a5),a0
	move.l	a0,d2
	move.l	#UserRecord_SIZEOF,d3
	jsrlib	Write
	addq.l	#1,d7
	bra	1$

5$	move.l	d4,d1
	jsrlib	Close

	lea	bconfig(a5),a0
	move.l	d7,Users(a0)
	lea	configfilename,a1
	move.l	#ConfigRecord_SIZEOF,d0
	bsr	savefile
	beq.s	8$

	lea	bNrTabell(a5),a0
	lea	nrindexfilename,a1
	move.l	#4*Hashentries,d0
	bsr	savefile
8$	bra.s	no_file

9$
fil_err	move.l	d4,d1
	jsrlib	Close
no_file	move.l	4,a6
	move.l	#mem_SIZEOF,d0
	move.l	a5,a1
	jsrlib	FreeMem
no_mem	closlib	dos
no_dos	rts

writedostext
	movem.l	d2-d3/a6,-(a7)
	move.l	dosbase,a6
	move.l	a0,d2
	bsr	strlen
	move.l	d0,d3
	jsrlib	Output
	move.l	d0,d1
	jsrlib	Write
	movem.l	(a7)+,d2-d3/a6
	rts

savefile
	movem.l	a2/a6/d2-d4,-(a7)
	move.l	a0,a2
	move.l	d0,d3
	move.l	dosbase,a6
	move.l	a1,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.s	9$
	move.l	d4,d1
	move.l	a2,d2
	jsrlib	Write
	move.l	d4,d1
	jsrlib	Close
	clrz
9$	movem.l	(a7)+,d2-d4/a2/a6
	rts

readfile
	movem.l	a2/a6/d2-d4,-(a7)
	move.l	a0,a2
	move.l	d0,d3
	move.l	dosbase,a6
	move.l	a1,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.s	9$
	move.l	d4,d1
	move.l	a2,d2
	jsrlib	Read
	move.l	d4,d1
	jsrlib	Close
	clrz
9$	movem.l	(a7)+,d2-d4/a2/a6
	rts

******************************
;len = strlen (string)
;d0		a0
******************************
strlen	moveq.l	#-1,d0
1$	tst.b	(a0)+
	dbeq	d0,1$
	not.w	d0
	ext.l	d0
	rts

******************************
;result = comparestringsfull (streng,streng1,length)
;Zero bit		      a0.l   a1.l    d0.w
******************************
comparestringsfull
	subq.w	#1,d0
1$	move.b	(a0)+,d1
	cmp.b	(a1)+,d1
	dbne	d0,1$
	rts

******************************
;hashvalue = Hash (streng)
;d0.l		   a0.l
;0 =< hashvalue < 256
******************************

	IFNE	(DiffHashvalues-256)
	FAIL	; Maa skrive om hash rutinene.
	ENDC
hash	move.w	d2,-(sp)
	move.l	a0,a1
	moveq.l	#-1,d0
1$	tst.b	(a0)+
	dbeq	d0,1$
	not.w	d0
	move.w	d0,d2
	subq.w	#1,d2
	ext.l	d0
				;Hash (d0) := length
				;for n = 0 to length

2$	move.l	d0,d1		;13X=x(8+4+1)=8x+4x+x
	lsl.l	#2,d1
	add.l	d1,d0		; x + 4x
	lsl.l	#1,d1		; (x + 4x) + 8x
	add.l	d1,d0		;Hash := Hash * 13

	move.b	(a1)+,d1
	ext.w	d1
	ext.l	d1
	add.l	d1,d0		; Hash := hash + ascii(streng(tegnnr))
	and.l	#$fff,d0	; Hash := Hash & $fff
	dbf	d2,2$		; next n

	lsr.l	#3,d0
	move.w	(sp)+,d2
	ext.l	d0
	rts


******************************
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.s	1$
	rts

	DATA
dosbase		dc.l	0
hashnotfoundtxt	dc.b	10,'User not found in hash chain !!!',10,0
dosname		dc.b	'dos.library',0
configfilename	dc.b	'abbs:config/configfile',0
userfilename	dc.b	'abbs:config/userfile',0
indexfilename	dc.b	'abbs:config/userfile.index',0
nrindexfilename	dc.b	'abbs:config/userfile.nrindex',0

	STRUCTURE mem,0
	STRUCT	busermem,UserRecord_SIZEOF
	STRUCT	bconfig,ConfigRecord_SIZEOF
	STRUCT	bNrTabell,4*Hashentries
	STRUCT	bHashTabell,(hash_entry_SIZEOF*(DiffHashvalues+Hashentries))
	LABEL	mem_SIZEOF

	END
