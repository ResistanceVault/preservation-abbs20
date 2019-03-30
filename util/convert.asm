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
	lea	aconvtext,a0
	beq	9$
	lea	wrongformattext,a0
	cmp.l	#9908,d2
	bne	9$

; oppretter 2 nye conf'er (fil'er)
	add.w	#2,ActiveConf(MainBase)
	cmp.w	#MaxConferences,ActiveConf(MainBase)
	lea	conferencefull,a0
	bcc	9$
	lea	resymetext,a0
	bsr	fillin
	lea	errorcrconffile,a0
	beq	9$
	lea	fileinfotext,a0
	bsr	fillin
	lea	errorcrconffile,a0
	beq	9$

; oppdaterer alle brukere
	move.l	dosbase,a6
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d6				; file ptr
	bne.s	10$
	lea	erroropenftext,a0
	move.l	4,a6
	bra	9$

10$	bsr	douser
	bne.s	10$

	move.l	d6,d1
	jsrlib	Close
	move.l	4,a6

	lea	2*Sizeof_NameT+ConfNames(MainBase),a0
	lea	4*Sizeof_NameT+ConfNames(MainBase),a1
	move.l	#(MaxConferences-4)*Sizeof_NameT,d0
	bsr	copymemrev
	lea	2*Sizeof_NameT+ConfNames(MainBase),a1
	lea	resymetext,a0
	bsr	strcopy
	lea	3*Sizeof_NameT+ConfNames(MainBase),a1
	lea	fileinfotext,a0
	bsr	strcopy

	lea	2*1+ConfSW(MainBase),a0
	lea	4*1+ConfSW(MainBase),a1
	moveq.l	#(MaxConferences-4)*1,d0
	bsr	copymemrev
	lea	2*1+ConfSW(MainBase),a0
	move.b	#CONFSWF_Special+CONFSWF_Resign+CONFSWF_ImmRead,(a0)
	move.b	#CONFSWF_Special+CONFSWF_Resign+CONFSWF_ImmRead,1(a0)

	lea	2*4+ConfDefaultMsg(MainBase),a0
	lea	4*4+ConfDefaultMsg(MainBase),a1
	move.l	#(MaxConferences-4)*4,d0
	bsr	copymemrev
	lea	2*4+ConfDefaultMsg(MainBase),a0
	moveq.l	#0,d0
	move.l	d0,(a0)
	move.l	d0,4(a0)

	lea	2*1+ConfBullets(MainBase),a0
	lea	4*1+ConfBullets(MainBase),a1
	moveq.l	#(MaxConferences-4)*1,d0
	bsr	copymemrev
	lea	2*1+ConfBullets(MainBase),a0
	move.b	#0,(a0)
	move.b	#0,1(a0)

; flytter alle conf'er 2 plasser nedover
; setter de 2 nye inn på de tom'e plassene.

	move.w	#MaxConferences,d3		; oppdaterer MaxScan og order
	move.w	#50,d0
	moveq.l	#1,d1
	lea	ConfOrder(MainBase),a1
	lea	ConfMaxScan(MainBase),a0
1$	move.w	d0,(a0)+
	move.b	d1,(a1)+
	addq.l	#1,d1
	sub.w	#1,d3
	bne.s	1$

	move.w	#MaxFileDirs,d3			; oppdaterer Filedir order
	moveq.l	#1,d1
	lea	FileOrder(MainBase),a1
4$	move.b	d1,(a1)+
	addq.l	#1,d1
	sub.w	#1,d3
	bne.s	4$

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
	jsrlib	Close

	lea	altoktext,a0
9$	bsr	writedostext
no_file	move.l	4,a6
	move.l	#ConfigRecord_SIZEOF,d0
	move.l	MainBase,a1
	jsrlib	FreeMem
no_mem	closlib	dos
no_dos	rts

douser	lea	tmpuser,a2
	move.l	d6,d1
	move.l	a2,d2
	move.l	#UserRecord_SIZEOF,d3
	jsrlib	Read
	tst.l	d0
	clrn
	beq	9$			; 0 == EOF
	cmp.l	d0,d3
	bne	7$

	lea	2+ConfAccess(a2),a0
	lea	4+ConfAccess(a2),a1
	moveq.l	#(MaxConferences-4)*1,d0
	bsr	copymemrev

	lea	2*4+Conflastread(a2),a0
	lea	4*4+Conflastread(a2),a1
	move.l	#(MaxConferences-4)*4,d0
	bsr	copymemrev

	lea	2+ConfAccess(a2),a0
	move.b	-2(a0),d0		; henter news access
	btst	#ACCB_Sysop,d0		; er vi sysop ?
	beq.s	1$			; nei
	move.b	#ACCF_Read+ACCF_Sysop,(a0)
	move.b	#ACCF_Read+ACCF_Sysop,1(a0)
	bra.s	2$			; gir full access i de nye conf'ene
1$	move.b	#ACCF_Read,(a0)		; gir read access i conf'en
	move.b	#ACCF_Read,1(a0)
2$
	lea	2*4+Conflastread(a2),a0
	moveq.l	#0,d0
	move.l	d0,(a0)
	move.l	d0,4(a0)

	move.l	d6,d1				; søker tilbake
	move.l	#UserRecord_SIZEOF,d2
	neg.l	d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq	6$				; error
	move.l	d6,d1				; og lagrer brukeren
	move.l	#UserRecord_SIZEOF,d3
	move.l	a2,d2
	jsrlib	Write
	cmp.l	d0,d3
	bne	6$
	clrz
	bra.s	9$

6$	lea	fileerrortext,a0
	bra.s	8$
7$	lea	errorreadftext,a0
8$	bsr	writedostext
	setz
	setn
9$	rts

fillin	move.l	a0,-(a7)
	lea	conferancepath,a0
	lea	tekst,a1
	bsr	strcopy
	move.l	(a7),a0
	subq.l	#1,a1
	bsr	strcopy
	subq.l	#1,a1
	lea	dotmessagestext,a0
	bsr	strcopy
	lea	tekst,a0		; Filnavn (path/konfnavn.messages)
	move.l	a0,d1
	move.l	dosbase,a6
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d1
	beq	9$
	jsrlib	Close
	lea	conferancepath,a0
	lea	tekst,a1
	bsr	strcopy
	move.l	(a7),a0
	subq.l	#1,a1
	bsr	strcopy
	subq.l	#1,a1
	lea	dotmsgheadertxt,a0
	bsr	strcopy
	lea	tekst,a0		; Filnavn (path/konfnavn.msgheaders)
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d1
	beq.s	9$
	jsrlib	Close
	clrz
9$	addq.l	#4,a7
	move.l	4,a6
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

	BSS

tekst	ds.b	80
dosbase	ds.l	1
tmpuser	ds.b	UserRecord_SIZEOF

	DATA

erroropenftext	dc.b	'Error opening file.',10,0
errorreadftext	dc.b	'Error reading file.',10,0
fileerrortext	dc.b	'File error.',10,0
errorcrconffile	dc.b	'Error while creating conference files!',10,0
conferencefull	dc.b	'Conferencelist Full.',10,0
aconvtext	dc.b	'Already converted!',10,0
wrongformattext	dc.b	'Wrong Format/Read Error.',10,0
altoktext	dc.b	'Conversion sucessfull',10,0
erropenfiletext	dc.b	'Error opening configfile',10,0
nomem		dc.b	'Can''t get memory',10,0
dosname		dc.b	'dos.library',0
configfilename	dc.b	'abbs:config/configfile',0
conferancepath	dc.b	'abbs:conferences/',0
resymetext	dc.b	'USERINFO',0
fileinfotext	dc.b	'FILEINFO',0
dotmessagestext	dc.b	'.m',0
dotmsgheadertxt	dc.b	'.h',0
userfilename	dc.b	'abbs:config/userfile',0
	END
