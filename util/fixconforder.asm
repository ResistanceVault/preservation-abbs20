	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/dos.i'

	include	'asm.i'
	include	'bbs.i'

	code

MainBase	equr	a5

start	move.l	4,a6
	openlib	dos
	move.l	#ConfigRecord_SIZEOF,d0		; allokerer minne
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	bne.s	2$
	lea	nomem,a0
	bsr	writedostext
	bra	no_mem
2$	move.l	d0,MainBase

	move.l	dosbase,a6			; leser filen
	move.l	#configfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	bne.s	3$
	lea	erropenfiletext,a0
	bsr	writedostext
	bra	no_file
3$	move.l	d4,d1
	move.l	MainBase,d2
	move.l	#ConfigRecord_SIZEOF,d3
	jsrlib	Read
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d3,d2
	lea	erropenfiletext,a0
	bne	9$

	move.w	#MaxConferences,d3		; oppdaterer order
	moveq.l	#1,d1
	lea	ConfOrder(MainBase),a1
	lea	ConfNames(MainBase),a2
1$	move.b	d1,(a1)+
	tst.b	(a2)
	bne.s	4$				; ikke sletta..
	lea	ConfSW(MainBase),a0
	clr.b	-1(a0,d1.w)
	lea	ConfBullets(MainBase),a0
	clr.b	-1(a0,d1.w)
4$	lea	Sizeof_NameT(a2),a2
	addq.l	#1,d1
	sub.w	#1,d3
	bne.s	1$


	move.l	dosbase,a6
	move.l	#configfilename,d1
	move.l	#MODE_READWRITE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.s	no_file
	move.l	d4,d1
	move.l	MainBase,d2
	move.l	#ConfigRecord_SIZEOF,d3
	jsrlib	Write
	move.l	d4,d1
	move.l	d0,d4
	jsrlib	Close
	lea	fileerrortext,a0
	cmp.l	d4,d3
	bne.s	9$
	lea	altoktext,a0
9$	bsr	writedostext
no_file	move.l	4,a6
	move.l	#ConfigRecord_SIZEOF,d0
	move.l	MainBase,a1
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

copymemrev
	subq.l	#1,d0
	bcs.s	9$
	add.l	d0,a0
	add.l	d0,a1
	move.b	(a0),(a1)
	sub.w	#1,d0
	bcs.s	9$
1$	move.b	-(a0),-(a1)
	dbf	d0,1$
9$	rts

******************************
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.s	1$
	rts

	BSS

dosbase	ds.l	1

	DATA

erroropenftext	dc.b	'Error opening file.',10,0
errorreadftext	dc.b	'Error reading file.',10,0
fileerrortext	dc.b	'File error.',10,0
altoktext	dc.b	'Fixing sucessfull',10,0
erropenfiletext	dc.b	'Error opening configfile',10,0
nomem		dc.b	'Can''t get memory',10,0
dosname		dc.b	'dos.library',0
configfilename	dc.b	'abbs:config/configfile',0
	END
