	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/dos.i'

	include	'asm.i'
	include	'bbs.i'

	section kode,code

	STRUCTURE mem,0
	STRUCT	configmem,ConfigRecord_SIZEOF
	STRUCT	msgheader,MessageRecord_SIZEOF
	STRUCT	textbuffer,80
	LABEL	mem_SIZEOF


start	move.l	4,a6
	openlib	dos
	move.l	#mem_SIZEOF,d0		; allokerer minne
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
	lea	(configmem,MainBase),a0
	move.l	a0,d2
	move.l	#ConfigRecord_SIZEOF,d3
	jsrlib	Read
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d3,d2
	lea	erropenfiletext,a0
	bne	9$

	bsr	dofix
	beq.b	no_file

	lea	altoktext,a0
9$	bsr	writedostext
no_file	move.l	4,a6
	move.l	#mem_SIZEOF,d0
	move.l	MainBase,a1
	jsrlib	FreeMem
no_mem	closlib	dos
no_dos	rts

dofix	push	d2/a2
	move.w	#MaxConferences,d3		; oppdaterer order
	lea	(ConfNames+configmem,MainBase),a2
1$	tst.b	(a2)
	beq.s	4$				; sletta..
	move.l	a2,a0
	lea	(dotmsgheadertxt),a1
	bsr	createconffilepath
	bsr	recover
	beq.b	9$

4$	lea	Sizeof_NameT(a2),a2
	sub.w	#1,d3
	bne.s	1$
	clrz
9$	pop	d2/a2
	rts

; a0 = filename
recover	push	d2-d4/a2
	move.l	a0,d1
	move.l	#MODE_READWRITE,d2
	jsrlib	Open
	move.l	d0,d4				; husker
	lea	(erroropenftext),a0
	beq.b	8$
	lea	(msgheader,MainBase),a2

1$	move.l	d4,d1
	move.l	a2,d2
	moveq.l	#MessageRecord_SIZEOF,d3
	jsrlib	Read
	tst.l	d0
	beq.b	6$				; ferdig
	cmp.l	d0,d3
	bne.b	7$
	moveq.l	#-1,d0
	cmp.l	(MsgTo,a2),d0
	bne.b	1$				; ikke til all, da tar vi neste
	move.b	(MsgStatus,a2),d0
	btst	#MSTATB_Dontshow,d0
	beq.b	1$				; ikke slettet fullt ut
	bclr	#MSTATB_Dontshow,d0
	move.b	d0,(MsgStatus,a2)
	move.l	d4,d1
	moveq.l	#-MessageRecord_SIZEOF,d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	jsrlib	IoErr
	tst.l	d0
	bne.b	7$				; error
	move.l	d4,d1
	move.l	a2,d2
	moveq.l	#MessageRecord_SIZEOF,d3
	jsrlib	Write
	cmp.l	d0,d3
	beq.b	1$				; ok, går videre
	bra.b	7$				; error

6$	move.l	d4,d1
	jsrlib	Close
	clrz
	bra.b	9$
	
7$	move.l	d4,d1
	jsrlib	Close
	lea	(fileerrortext),a0
8$	bsr	writedostext
	setz
9$	pop	d2-d4/a2
	rts

; a0 = conf/fil name
; a1 = extension
createconffilepath
	push	a2/a3
	move.l	a0,a2
	move.l	a1,a3
	lea	conferencepath,a0
	lea	textbuffer(MainBase),a1	; må bruke denne bufferen.. (renconf bruker dette)
	jsr	strcopy
	subq.l	#1,a1
	move.l	a2,a0
1$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	2$
	move.b	d0,(a1)+
	cmp.b	#'/',d0
	bne.b	1$
	move.b	#' ',-1(a1)
	bra.b	1$
2$	move.l	a3,a0
	jsr	strcopy
	lea	textbuffer(MainBase),a0	; Filnavn
	move.l	a0,d0
	pop	a2/a3
	rts

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

	section bsss,BSS

dosbase	ds.l	1

	section daata,DATA

erroropenftext	dc.b	'Error opening file (abbs running ??).',10,0
errorreadftext	dc.b	'Error reading file.',10,0
fileerrortext	dc.b	'File error.',10,0
altoktext	dc.b	'Fixing sucessfull',10,0
erropenfiletext	dc.b	'Error opening configfile',10,0
nomem		dc.b	'Can''t get memory',10,0
dosname		dc.b	'dos.library',0
configfilename	dc.b	'abbs:config/configfile',0
dotmsgheadertxt	dc.b	'.h',0
conferencepath	dc.b	'abbs:conferences/',0

	END
