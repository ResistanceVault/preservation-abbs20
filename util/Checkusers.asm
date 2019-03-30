	include	'abbs:include/first.i'

	include	'exec/types.i'
	include	'exec/memory.i'
	include	'dos/dosextens.i'
	include	'dos/dos.i'

	include	'asm.i'
	include	'bbs.i'

	code
start	move.l	4,a6
	openlib	dos
	move.l	#ConfigRecord_SIZEOF,d7	; mem size
	add.l	#UserRecord_SIZEOF,d7
	lea	indexfilename,a0
	bsr	getfilelen
	beq	9$
	addq.l	#1,d0
	and.b	#$fe,d0
	add.l	d0,d7
	move.l	d0,indsize
	lea	nrindexfilename,a0
	bsr	getfilelen
	beq	9$
	addq.l	#1,d0
	and.b	#$fe,d0
	add.l	d0,d7
	move.l	d0,nrsize
	lea	userfilename,a0
	bsr	getfilelen
	beq	9$
	divu	#UserRecord_SIZEOF,d0
	moveq.l	#0,d1
	move.w	d0,d1
	move.l	d1,numuser
	swap	d0
	tst.w	d0
	beq.s	1$
	lea	wsizeuf,a0
	bsr	writedostext
	bra	9$

1$	move.l	d7,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	bne.s	2$
	lea	nomemtext,a0
	bsr	writedostext
	bra	9$
2$	move.l	d0,a5
	move.l	a5,configm
	move.l	a5,a0
	add.l	#ConfigRecord_SIZEOF,a0
	move.l	a0,tmpuser
	add.l	#UserRecord_SIZEOF,a0
	move.l	a0,nrindex
	add.l	nrsize,a0
	move.l	a0,index
	lea	indexfilename,a0
	move.l	index,a1
	move.l	indsize,d0
	bsr	readfile
	beq.s	8$
	lea	nrindexfilename,a0
	move.l	nrindex,a1
	move.l	nrsize,d0
	bsr	readfile
	beq.s	8$
	lea	configfilename,a0
	move.l	configm,a1
	move.l	#ConfigRecord_SIZEOF,d0
	bsr	readfile
	beq.s	8$

	move.l	dosbase,a6
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	bne.s	3$
	lea	errreadingftext,a0
	bsr	writedostext
	move.l	#userfilename,a0
	bsr	writedostext
	bsr	nl
	bra.s	8$

3$	moveq.l	#0,d0
	move.l	d0,ret
	bsr	do_check

7$	move.l	d4,d1
	jsrlib	Close
8$	move.l	4,a6
	move.l	d7,d0
	move.l	a5,a1
	jsrlib	FreeMem
9$	closlib	dos
no_dos	move.l	ret,d0
	rts

; d4 = serfileptr
do_check
	push	d7/a3/a4/a5/a2/d6
	moveq.l	#0,d7
	move.l	configm,a0
	move.l	(Users,a0),d6
	move.l	nrindex,a5
	move.l	index,a4
	move.l	tmpuser,a3

1$	move.l	(a5)+,d0
	cmp.l	#-1,d0
	beq.b	1$			; hopper over denne. Slettet bruker.
	mulu	#Log_entry_SIZEOF,d0
	move.l	a4,a2
	add.l	d0,a2			; log entry'n

	move.l	l_UserNr(a2),d0
	cmp.l	d0,d7
	beq.s	2$
	move.l	#10,ret
	move.l	d7,d0
	bsr	skrivnr
	bsr	spa
	lea	piler,a0
	bsr	writedostext
	bsr	spa
	move.l	l_UserNr(a2),d0
	bsr	skrivnr
	bsr	spa
	lea	l_Name(a2),a0
	bsr	writedostext
	bsr	nl

2$	move.l	l_RecordNr(a2),d2
	cmp.l	numuser,d2
	bls.s	21$
	move.l	#10,ret
	lea	irecnum,a0
	bsr	writedostext
	bra	8$

21$	move.l	d4,d1
	mulu	#UserRecord_SIZEOF,d2
	moveq.l	#OFFSET_BEGINNING,d3
	jsrlib	Seek
	moveq.l	#-1,d1			; error ?
	cmp.l	d0,d1
	bne.s	3$
	move.l	#10,ret
	bsr	10$
	bsr	spa
	lea	seeker,a0
	bsr	writedostext
	bsr	nl
	bra	8$

3$	move.l	d4,d1
	move.l	a3,d2
	move.l	#UserRecord_SIZEOF,d3
	jsrlib	Read
	cmp.l	d3,d0
	beq.s	4$
	move.l	#10,ret
	bsr	10$
	bsr	spa
	lea	reader,a0
	bsr	writedostext
	bsr	nl
	bra	8$

4$	lea	l_Name(a2),a0
	lea	Name(a3),a1
	bsr	comparestrings
	beq.s	5$
	move.l	#10,ret
	bsr	10$
	bsr	spa
	lea	piler,a0
	bsr	writedostext
	bsr	spa
	lea	Name(a3),a0
	bsr	writedostext
	bsr	nl

5$	move.l	Usernr(a3),d0
	cmp.l	d0,d7
	beq.s	6$
	move.l	#10,ret
	move.l	d7,d0
	bsr	skrivnr
	bsr	spa
	bsr	spa
	lea	piler,a0
	bsr	writedostext
	bsr	spa
	move.l	Usernr(a3),d0
	bsr	skrivnr
	bsr	spa
	lea	l_Name(a2),a0
	bsr	writedostext
	bsr	nl

6$


8$	addq.l	#1,d7
	cmp.l	d7,d6
	bhi	1$
	
9$	pop	d7/a3/a4/a5/a2/d6
	rts

10$	move.l	d7,d0
	bsr	skrivnr
	bsr	spa
	lea	l_Name(a2),a0
	bra	writedostext


spa	lea	sptext,a0
	bra	writedostext

nl	lea	nltext,a0
	bra	writedostext

******************************
;result = comparestrings (streng,streng1)
;Zero bit		  a0.l   a1.l
******************************
comparestrings
1$	move.b	(a0)+,d0
	beq.s	2$
	move.b	(a1)+,d1
	beq.s	3$
	cmp.b	d0,d1
	bne.s	9$
	bra.s	1$
2$	tst.b	(a1)
	rts
3$	clrz
9$	rts

skrivnr	lea	tekst,a0
	bsr	konverter
	lea	tekst,a0
	bra	writedostext

; d0 = tall
; a0 = inn streng.
konverterw
	and.l	#$ffff,d0
konverter
	link	a5,#-12
	move.l	sp,a1
1$	moveq.l	#10,d1
	bsr	divspes
	add.w	#'0',d1
	move.b	d1,(a1)+
	tst.l	d0
	bne.s	1$
	move.l	a1,d1
	moveq.l	#0,d0
2$	move.b	-(a1),(a0)+
	add.l	#1,d0
	cmpa.l	a1,sp
	bne.s	2$
	clr.b	(a0)
	sub.l	sp,d1
	unlk	a5
	rts

divspes	move.l	d2,-(sp)
	swap	d1
	move.w	d1,d2
	bne.s	9$
	swap	d0
	swap	d1
	swap	d2
	move.w	d0,d2
	beq.s	1$
	divu	d1,d2
	move.w	d2,d0
1$	swap	d0
	move.w	d0,d2
	divu	d1,d2
	move.w	d2,d0
	swap	d2
	move.w	d2,d1
9$	move.l	(sp)+,d2
	rts

writedostext
	push	d2-d3/a6
	move.l	dosbase,a6
	move.l	a0,d2
	bsr	strlen
	move.l	d0,d3
	jsrlib	Output
	move.l	d0,d1
	jsrlib	Write
	pop	d2-d3/a6
	rts

;a0 = filename
;a1 = adr
;d0 = size
readfile
	push	d2-d5/a6/a2
	move.l	a0,a2
	move.l	dosbase,a6
	move.l	d0,d3
	move.l	a1,d5
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.s	2$
	move.l	d4,d1
	move.l	d5,d2
	jsrlib	Read
	cmp.l	d3,d0
	beq.s	1$
	move.l	d4,d1
	jsrlib	Close
2$	lea	errreadingftext,a0
	bsr	writedostext
	move.l	a2,a0
	bsr	writedostext
	bsr	nl
	setz
	bra.s	9$
1$	move.l	d4,d1
	jsrlib	Close
	clrz
9$	pop	d2-d5/a6/a2
	rts

getfilelen
	push	d2/d3/a2
	move.l	dosbase,a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.s	1$
	move.l	d0,d3
	lea	infoblockmem,a0
	move.l	a0,d2
	jsrlib	Examine
	move.l	d0,d2
	beq.s	2$
	lea	infoblockmem,a0
	move.l	fib_Size(a0),d2
2$	move.l	d3,d1
	jsrlib	UnLock
	move.l	d2,d0
	bne.s	9$
1$	lea	cntfindsizetext,a0
	bsr	writedostext
	move.l	a2,a0
	bsr	writedostext
	bsr	nl
	setz
9$	move.l	4,a6
	pop	d2/d3/a2
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
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.s	1$
	rts

	section bdata,BSS

infoblockmem
	ds.b	fib_SIZEOF+2
tekst	ds.b	80
configm	ds.l	1
tmpuser ds.l	1
nrindex	ds.l	1
index	ds.l	1
dosbase	ds.l	1
nrsize	ds.l	1
indsize	ds.l	1
numuser	ds.l	1

		section data,data

ret	dc.l	100

dosname		dc.b	'dos.library',0
userfilename	dc.b	'abbs:config/userfile',0
indexfilename	dc.b	'abbs:config/userfile.index',0
nrindexfilename	dc.b	'abbs:config/userfile.nrindex',0
configfilename	dc.b	'abbs:config/configfile',0
cntfindsizetext	dc.b	'Can''t find size of : ',0
nomemtext	dc.b	'Can''t get memory',10,0
errreadingftext	dc.b	'Error reading file : ',0


nltext	dc.b	10,0
sptext	dc.b	' ',0
piler	dc.b	'<->',0
irecnum	dc.b	'Illegal record number',10,0
seeker	dc.b	'Seek error'
reader	dc.b	'Read error'
wsizeuf	dc.b	'Wrong size on userfile',10,0
	END
