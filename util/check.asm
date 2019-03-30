	include	'abbs:first.i'

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

	cmp.l	Usernr(a5),d7
	bne.s	2$
	addq.l	#1,d7
	bra	1$
2$	lea	Name+busermem(a5),a0
	bsr	writedostext
	lea	Usernrinccwtext,a0
	bsr	writedostext
	bra.s	6$
5$	lea	noproblemwutext,a0
	bsr	writedostext
6$
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

	DATA
dosbase		dc.l	0
Usernrinccwtext	dc.b	'Usernr increment count wrong !!',10,0
noproblemwutext	dc.b	'No problem with the usernumbers in the config file',10,0
dosname		dc.b	'dos.library',0
userfilename	dc.b	'abbs:config/userfile',0

	STRUCTURE mem,0
	STRUCT	busermem,UserRecord_SIZEOF
	LABEL	mem_SIZEOF
	END
