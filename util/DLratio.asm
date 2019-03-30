******************************************************************************
******									******
******		DLratio - Gjør diverse ting med DL ration		******
******									******
******		DLratio <ratio nr> [<listing file> [NOACTION]]		******
******									******
******************************************************************************

; d2 og d3 er scratch
; d4 og d7 brukes også.

	include 'abbs:first.i'

	include	'exec/types.i'
	include	'exec/ports.i'
	include	'exec/io.i'
	include	'exec/memory.i'
	include	'exec/tasks.i'
	include	'libraries/dos.i'

	include	'asm.i'
	include	'bbs.i'

start	move.l	4,a6
	move.l	d0,d0store
	move.l	a0,a0store
	openlib	dos
	moveq.l	#3,d7			; d7 er error. Her, ingne abbs
	lea	mainmsgportname,a1
	jsrlib	FindPort
	tst.l	d0
	beq	9$
	moveq.l	#1,d7			; usage text
	bsr	parsecomandline
	beq.s	9$
	moveq.l	#0,d4			; fil ptr
	moveq.l	#4,d7			; error create port
	lea	tmpportname,a0
	moveq.l	#0,d0
	bsr	CreatePort
	beq.s	9$
	move.l	d0,port
	lea	msg,a0
	move.l	d0,MN_REPLYPORT(a0)
	move.l	listfname,d1
	beq.s	1$
	moveq.l	#2,d7			; file open error.
	move.l	dosbase,a6
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.s	9$
	move.l	4,a6
1$

	moveq.l	#0,d7			; Alt ok så langt.

	moveq.l	#0,d6			; usernr
2$	move.l	d6,d0
	bsr	douser
	beq.s	8$
	addq.l	#1,d6
	bra.s	2$

8$	move.l	4,a6
	move.l	port,d0
	beq.s	81$
	move.l	d0,a0
	bsr	DeletePort
81$	move.l	dosbase,a6
	move.l	d4,d1
	beq.s	9$
	jsrlib	Close
9$	move.l	d7,d0
	beq.s	99$
	bsr	skriverror
99$	move.l	4,a6
	closlib	dos
no_dos	rts

douser	push	d5
	move.l	d0,d5
	lea	tmpuser,a0
	bsr	loadusernr
	bmi	9$
	beq	99$
	lea	tmpuser,a0
	move.b	ConfAccess(a0),d0
	btst	#ACCB_FileVIP,d0	; Skal vi sjekke denne brukeren ?
	bne	99$			; Nei, da er vi ferdige

	moveq.l	#0,d0
	move.w	Uploaded(a0),d0		; sjekker ratio
	addq.l	#1,d0
	move.l	rationr,d1
	mulu	d1,d0
	moveq.l	#0,d1
	move.w	Downloaded(a0),d1
	cmp.l	d1,d0
	bhi.s	1$			; Vi er under
	move.b	ConfAccess(a0),d0	; Har vi DL access ??
	btst	#ACCB_Download,d0
	beq.s	8$			; Nei, da gjør vi ikke noe.
	and.b	#~ACCF_Download,d0	; fjerner DL access
	move.b	d0,ConfAccess(a0)

; skrive til fil at brukeren mistet access
	lea	Name(a0),a0
	moveq.l	#Sizeof_NameT+1,d0
	bsr	writetextlfill
	lea	lostdlacctext,a0
	bsr	writedostext
	bra.s	2$			; Lagrer brukeren

1$	move.b	ConfAccess(a0),d0	; Har vi DL access ??
	btst	#ACCB_Download,d0
	bne.s	99$			; Ja, da er dette en NOP
	btst	#ACCB_Upload,d0		; Har han UL access ??
	beq.s	8$			; Nei, da skal han ikke få DL heller
	or.b	#ACCF_Download,d0
	move.b	d0,ConfAccess(a0)	; oppdaterer
; skrive til fil at brukeren mistet access
	lea	Name(a0),a0
	moveq.l	#Sizeof_NameT+1,d0
	bsr	writetextlfill
	lea	regaindlacctext,a0
	bsr	writedostext

2$	tst.w	noaction
	bne.s	8$
	move.l	d5,d0			; lagrer bruker
	lea	tmpuser,a0
	bsr	saveusernr
	bmi.s	9$
	beq.s	99$
8$	clrz
	bra.s	99$
9$	setz
99$	pop	d5
	rts

loadusernr
	lea	msg,a1
	move.w	#Main_loadusernr,m_Command(a1)
	move.l	d0,m_UserNr(a1)
	move.l	a0,m_Data(a1)
	bsr	handlemsg
	beq.s	8$
	lea	msg,a1
	move.w	m_Error(a1),d0
	cmp.w	#Error_OK,d0
	beq.s	9$
	cmp.w	#Error_EOF,d0
	beq.s	99$
	moveq.l	#5,d7			; Abbs error retur
	setn
	setz
	bra.s	99$
8$	moveq.l	#3,d7			; Ingen abbs port
	clrz
9$	notz
99$	rts

saveusernr
	lea	msg,a1
	move.w	#Main_saveusernr,m_Command(a1)
	move.l	d0,m_UserNr(a1)
	move.l	a0,m_Data(a1)
	bsr	handlemsg
	beq.s	8$
	lea	msg,a1
	move.w	m_Error(a1),d0
	cmp.w	#Error_OK,d0
	beq.s	9$
	moveq.l	#5,d7			; Abbs error retur
	setn
	setz
	bra.s	99$
8$	moveq.l	#3,d7			; Ingen abbs port
	clrz
9$	notz
99$	rts

handlemsg
	move.l	a1,-(a7)
	jsrlib	Forbid
	lea	mainmsgportname,a1
	jsrlib	FindPort
	move.l	(a7)+,a1
	tst.l	d0
	beq.s	9$
	move.l	d0,a0
	jsrlib	PutMsg
	jsrlib	Permit
1$	move.l	port,a0
	jsrlib	WaitPort
	tst.l	d0
	beq.s	1$
	move.l	port,a0
	jsrlib	GetMsg
	tst.l	d0
	beq.s	1$
	rts
9$	jsrlib	Permit
	setz
	rts

writetextlfill
	movem.l	d2/a2,-(sp)
	move.l	d0,d2
	move.l	a0,a2
	bsr	strlen
	sub.l	d0,d2
	move.l	a2,a0
	bsr	writedostextlen
	move.l	d2,d0
	bmi.s	9$
	beq.s	9$
	lea	spacetext,a0		; .. og jevner ut med space
	bsr	writedostextlen
9$	movem.l	(sp)+,d2/a2
	rts

writedostextlen
	move.l	d4,d1			; Skriver vi til fil ?
	beq.s	9$			; Nei
	movem.l	d2-d3/a6,-(a7)
	move.l	dosbase,a6
	move.l	a0,d2
	move.l	d0,d3
	jsrlib	Write
	movem.l	(a7)+,d2-d3/a6
9$	rts

writedostext
	move.l	d4,d1			; Skriver vi til fil ?
	beq.s	9$			; Nei
	movem.l	d2-d3/a6,-(a7)
	move.l	dosbase,a6
	move.l	a0,d2
	bsr	strlen
	move.l	d0,d3
	move.l	d4,d1
	jsrlib	Write
	movem.l	(a7)+,d2-d3/a6
9$	rts

skriverror
	lea	errormsg,a0
	subq.l	#1,d0
	lsl.l	#2,d0
	add.l	d0,a0
	move.l	(a0),a0
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

parsecomandline
	push	d2/a2
	move.l	d0store,d0
	move.l	a0store,a0
	move.l	a0,a2
	move.l	d0,d2
	moveq.l	#0,d1
	move.w	d1,noaction
	move.l	d1,listfname
	move.l	d1,rationr

	subq.l	#1,d2
	bcs	8$		; For kort com line
	cmp.b	#' ',(a0)
	bne.s	1$
	addq.l	#1,a0
	move.l	a0,a2
	subq.l	#1,d2
	bcs	8$		; For kort com line
1$	move.b	(a0)+,d0
	beq.s	3$
	subq.l	#1,d2
	bcs	3$
	cmp.b	#' ',d0
	bne.s	1$
	bra.s	4$
3$	move.b	#0,-1(a0)
	move.l	a2,a0
	bsr	atoi
	bmi	8$		; Ikke noe tall
	beq	8$		; Kan ikke ha null.
	move.l	d0,rationr
	bra.s	7$
4$	move.b	#0,-1(a0)
	exg	a0,a2
	bsr	atoi
	bmi.s	8$		; Ikke noe tall
	beq.s	8$		; Kan ikke ha null.
	move.l	d0,rationr
	move.l	a2,a0

5$	move.b	(a0)+,d0
	beq.s	6$
	subq.l	#1,d2
	bcs.s	6$
	cmp.b	#' ',d0
	bne.s	5$
	move.b	#0,-1(a0)
	move.l	a2,listfname
	move.l	a0,a2
	bra.s	2$
6$	move.b	#0,-1(a0)
	move.l	a2,listfname
	bra.s	7$

2$	move.b	(a0)+,d0
	beq.s	10$
	subq.l	#1,d2
	bcs.s	10$
	cmp.b	#' ',d0
	bne.s	2$
10$	move.b	#0,-1(a0)
	move.l	a2,a0
	bsr	upword
	lea	noactiontext,a1
	bsr	comparestrings
	bne.s	8$
	move.w	#1,noaction
	clrz
	bra.s	9$
	rts
7$	tst.l	rationr
	bra.s	9$
8$	setz
9$	pop	d2/a2
	rts

******************************
;len = strlen (string)
;d0		a0
******************************
strlen	moveq.l	#-1,d0
1$	tst.b	(a0)+
	dbeq	d0,1$
	not.w	d0
	and.l	#$ffff,d0
	rts

atoi	moveq.l	#-1,d0
	moveq.l	#0,d1
1$	move.b	(a0)+,d1
	beq.s	9$
	cmp.b	#' ',d1
	beq.s	9$
	cmp.b	#10,d1
	beq.s	9$
	cmp.b	#13,d1
	beq.s	9$
	sub.b	#'0',d1
	bcs.s	8$
	cmp.b	#9,d1
	bhi.s	8$
	cmp.l	#-1,d0
	bne.s	2$
	move.l	d1,d0
	bra.s	1$
2$	mulu	#10,d0
	add.l	d1,d0
	bra.s	1$
8$	setn
	rts
9$	tst.w	d0
	rts

******************************
;char = upchar (char)
;d0.b		d0.b
******************************

upchar	cmp.b	#'a',d0
	bcs.s	1$
	cmp.b	#'z',d0
	bhi.s	2$
	sub.b	#'a'-'A',d0
1$	rts
2$	cmp.b	#224,d0		; Starten på utenlandske tegn (små)
	bcs.s	3$
	sub.b	#32,d0		; Forskjellen på Store og små ISO tegn.
3$	rts

******************************
;string = upword (string)
;a0		  a0
;does a upchar on every char in the first
;word of string (space or null separates words)
******************************
upword	movem.l	a0/d0,-(sp)
	move.l	a0,a1
3$	move.b	(a0)+,d0
	beq.s	1$
	cmp.b	#' ',d0
	beq.s	1$
	bsr	upchar
2$	move.b	d0,(a1)+
	bra.s	3$
1$	movem.l	(sp)+,a0/d0
	rts

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

******************************
;CreatePort
;inputs : name,priority (a0,d0)
;outputs: msgport (d0)
******************************
CreatePort
	movem.l	d2/d3/a2/a3,-(sp)
	move.l	a0,a2
	move.l	d0,d3
	move.l	#MP_SIZE,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	beq.s	1$
	move.l	d0,a3
	moveq.l	#-1,d0
	move.l	d0,d2
	jsrlib	AllocSignal
	cmp.l	d2,d0
	beq.s	2$
	move.b	d0,MP_SIGBIT(a3)
	sub.l	a1,a1
	jsrlib	FindTask
	move.l	d0,MP_SIGTASK(a3)
	move.l	a2,LN_NAME(a3)
	move.b	d3,LN_PRI(a3)
	move.b	#NT_MSGPORT,LN_TYPE(a3)
	move.b	#PA_SIGNAL,MP_FLAGS(a3)
	move.l	a3,a1
	jsrlib	AddPort
	move.l	a3,d0
	movem.l	(sp)+,a2/a3/d2/d3
	rts

2$	move.l	a3,a1
	move.l	#MP_SIZE,d0
	jsrlib	FreeMem
1$	movem.l	(sp)+,a2/a3/d2/d3
	setz
	rts

******************************
;DeletePort
;inputs : msgport (a0)
;outputs: none
******************************
DeletePort
	move.l	a2,-(sp)
	move.l	a0,a2
	move.l	a0,a1
	jsrlib	RemPort
	move.b	MP_SIGBIT(a2),d0
	jsrlib	FreeSignal
	move.l	a2,a1
	move.l	#MP_SIZE,d0
	jsrlib	FreeMem
	move.l	(sp)+,a2
	rts

	BSS

noaction	ds.w	1
d0store		ds.l	1
a0store		ds.l	1
port		ds.l	1
dosbase		ds.l	1
listfname	ds.l	1
rationr		ds.l	1
tmpuser		ds.b	UserRecord_SIZEOF
msg		ds.b	ABBSmsg_SIZE

	DATA
noactiontext	dc.b	'NOACTION',0
dosname		dc.b	'dos.library',0
mainmsgportname	dc.b	'ABBS mainport',0
tmpportname	dc.b	'DLratio port',0
lostdlacctext	dc.b	'lost his/her download access',10,0
regaindlacctext	dc.b	'regained his/her download access',10,0
spacetext	dc.b	'                                                  ',0

; error meldinger :
errormsg	dc.l	usagetext
		dc.l	nofiletext
		dc.l	noporttext
		dc.l	nocporttext
		dc.l	abbserrortext

usagetext	dc.b	'Usage : DLratio <ratio nr> [<listing file> [NOACTION]]',10,0
nofiletext	dc.b	'Error opening list file',10,0
noporttext	dc.b	'Can''t find abbs !',10,0
nocporttext	dc.b	'Couldn''t create port.',10,0
abbserrortext	dc.b	'ABBS returned an error',10,0
		END
