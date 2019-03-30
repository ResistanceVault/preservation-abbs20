 *****************************************************************
 *
 * NAME
 *	Paragon.asm
 *
 * DESCRIPTION
 *	Paragon interface routines
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: Paragon.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: Paragon.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'

;	IFND	__M68
	include	'exec/types.i'
	include	'dos/dostags.i'
	include	'intuition/intuition.i'
;	ENDC
	include	'asm.i'
	include	'bbs.i'
	include	'fse.i'
	include	'node.i'

	XDEF	doparagondoor
	XDEF	handleparagonmsg

	XREF	strcopy
	XREF	konverter
	XREF	getfilelen
	XREF	paragonportname
	XREF	fillinnodenr
	XREF	CreatePort
	XREF	nyconfgrabtext
	XREF	writecontextlen
	XREF	writecontext
	XREF	newconline
	XREF	memcopylen
	XREF	dosbase
	XREF	exebase
	XREF	dointuition
	XREF	waitsecs
	XREF	DeletePort
	XREF	writeerroro
	XREF	testbreak
	XREF	writetext
	XREF	writetexti
	XREF	writetexto
	XREF	outimage
	XREF	breakoutimage
	XREF	serwritestringdo
	XREF	writeconchar
	XREF	writechari
	XREF	nulltext
	XREF	mayedlinepromptfull
	XREF	strcopymaxlen
	XREF	readchar
	XREF	typefilenoerror
	XREF	memclr
	XREF	calleditor
	XREF	updatetime
	XREF	nodelist
	XREF	doorspath
	XREF	abbsrootname
	XREF	abbsextension
	XREF	gettimestr
	XREF	saveuserarea
	XREF	strcat
	XREF	findfile
	XREF	typefileansi
	XREF	typefile
	XREF	sendintermsg
	XREF	doconsole
	XREF	doserial
	XREF	skrivnr
	XREF	justchecksysopaccess

	XREF	pltellsysoptext

	section	paragonkode,code

; a0 = programname
; a1 = feilmelding
doparagondoor
	push	a2/a3/d2/d3/d4/d5
	move.l	a1,d5				; husker feilmelding
	move.l	a0,a2				; husker filnavn

	lea	(tmptext,NodeBase),a1		; bygger opp execute linje
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	movea.l	a1,a0
	jsr	(konverter)
	move.b	#0,(a0)

	move.l	a2,a0				; sjekker om fila finnes
	jsr	(getfilelen)
	beq	8$				; var ingen, eller size 0: error

	lea	(Paragonportname,NodeBase),a1	; bygger opp port navnet
	lea	(paragonportname),a0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	lea	(Paragonportname,NodeBase),a0
	moveq.l	#0,d0
	jsr	(CreatePort)
	move.l	d0,d4				; husker porten
	beq	8$				; var ingen, error
	move.l	d4,a2				; flytter porten

	lea	(nyconfgrabtext),a0		; Skriver ut kommandoen vi kjører
	moveq.l	#3,d0
	jsr	(writecontextlen)
	lea	(tmptext,NodeBase),a0		; command string
	jsr	(writecontext)
	jsr	(newconline)

	lea	(tmplargestore,NodeBase),a3
	move.l	a3,a1
	lea	(doparagondoortags),a0
	moveq.l	#doparagondoortagsend-doparagondoortags+2,d0
	jsr	(memcopylen)

	movea.l	(dosbase),a6
	move.l	#niltext,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,(4,a3)
	beq.b	5$

	move.l	#niltext,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,(4+8,a3)
	bne.b	4$
	move.l	(4,a3),d1
	jsrlib	Close
5$	movea.l	(exebase),a6
	bra.b	8$

4$	lea	(tmptext,NodeBase),a1
	move.l	a1,d1
	move.l	a3,d2
	jsrlib	SystemTagList
	movea.l	(exebase),a6
	tst.l	d0
	bne.b	7$

	move.b	MP_SIGBIT(a2),d0
	moveq.l	#0,d4
	bset	d0,d4
	move.l	d4,d3				; setter opp signalene
	or.l	(intsigbit,NodeBase),d3

1$	move.l	d3,d0
	jsrlib	Wait
	move.l	d0,d2
	and.l	d4,d0
	beq.b	2$
	bsr.b	(10$)
	beq.b	3$
;	tst.b	(readcharstatus,NodeBase)	; noe galt ?
;	bne.b	3$				; jepp.

2$	move.l	d2,d0
	and.l	(intsigbit,NodeBase),d0		; var det int bit ?
	beq.b	1$				; nei.
	jsr	(dointuition)			; behandler det.
	moveq.l	#5,d0
	jsr	(waitsecs)
	bra.b	1$
;	beq.b	3$
;	tst.b	(readcharstatus,NodeBase)	; noe galt ?
;	beq.b	1$				; nei.
; OBS, door'en må få beskjed om at vi forsvinner...

3$	move.l	a2,a0
	jsr	(DeletePort)
	bra.s	9$

7$	move.l	a2,a0
	jsr	(DeletePort)
8$	move.l	d5,a0
	jsr	(writeerroro)
9$	pop	a2/a3/d2/d3/d4/d5
	rts

10$	move.l	a2,a0
	jsrlib	GetMsg
	tst.l	d0
	beq.s	11$
	move.l	d0,a3
	move.l	d0,a0
	bsr.b	handleparagonmsg
	beq.s	13$
	moveq.l	#0,d0
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	beq.b	12$				; nei.
	moveq.l	#1,d0
12$	move.w	d0,(p_carrier,a3)		; carrier lost status
	move.l	a3,a1
	jsrlib	ReplyMsg
	bra.s	10$
13$	move.l	a3,a1				; reply the message
	jsrlib	ReplyMsg
	clrz
11$	notz
	rts

; a0 : message
handleparagonmsg
	push	a2
	move.l	a0,a2
;	move.w	(p_Command,a2),d0		; Henter ut kommando nummeret
;	jsr	(skrivnrw)
;	move.b	#' ',d0
;	jsr	(writechari)
	move.w	(p_Command,a2),d0		; Henter ut kommando nummeret
	subq.w	#1,d0
	bcs.b	1$				; vil ikke ha null
	cmp.w	#33,d0
	bcc.b	1$				; for høyt nummer
	lea	(paragon_cmds),a0
	asl.w	#2,d0
	movea.l	(0,a0,d0.w),a0
	jsr	(a0)				; Utfører funksjonen
	bra.b	9$
1$	bsr	cmdnotsupported
	clrz
9$	pop	a2
	rts

; paragon kommandoer har meldingen i a2
; returnerer z = 1, hvis door'en har avsluttet
paragon_1				; output string
	jsr	(testbreak)
	beq.b	1$
	lea	(p_string,a2),a0
	jsr	(writetext)
	cmpi.w	#1,(p_Data,a2)
	bne.s	3$
	jsr	(outimage)
	bra.b	4$
3$	jsr	(breakoutimage)
4$	moveq.l	#0,d0
	bra.b	2$
1$	moveq.l	#-1,d0			; user hit the brakes
2$	move.w	d0,(p_Data,a2)
	clrz
	rts

paragon_2				; writestring to screen only
	tst.b	Tinymode(NodeBase)
	bne.s	9$
	lea	(p_string,a2),a0
	jsr	(writecontext)
9$	clrz
	rts

paragon_3				; output character to serial only
	IFND	DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Lokal node ?
	beq.b	9$				; Ja, da har vi lov uansett
	lea	(tmptext,NodeBase),a0			; sier fra at vi drar..
	move.w	(p_Data,a2),d0
	move.b	d0,(0,a0)
	move.b	#0,(1,a0)
	jsr	(serwritestringdo)
	ENDC
9$	clrz
	rts

paragon_4				; output character to screen only
	tst.b	Tinymode(NodeBase)
	bne.s	9$
	move.w	(p_Data,a2),d0
	jsr	(writeconchar)
9$	clrz
	rts

paragon_5				; output character
	move.w	(p_Data,a2),d0
	jsr	(writechari)
	clrz
	rts

paragon_25				; skulle ha tatt opp til 250 tegn, men ..
paragon_6				; promt user for input (no stacking)
	move.b	#0,(readlinemore,NodeBase)	 ; flusher input'en
paragon_7				; promt user for input (with stacking)
	lea	(p_string,a2),a0
	lea	(nulltext),a1
	moveq.l	#0,d0
	move.w	(p_Data,a2),d0
	bne.b	3$			; ikke size 0
	lea	(nulltext),a0		; size 0, så vi slenger med egen string
3$	cmpi.w	#78,d0			; forhindrer for lange input linjer
	bls.b	1$
	move.w	#78,d0
1$	jsr	(mayedlinepromptfull)
	lea	(p_string,a2),a1
	bne.b	2$			; noe gikk galt/ingen input
	move.b	#0,(a1)			; returnerer 0 string,to be sure
	bra.s	9$
2$	move.w	#78,d0
	jsr	(strcopymaxlen)
9$	clrz
	rts

paragon_8				; output string, and hotkey for char
	lea	(p_string,a2),a0
	jsr	(writetexti)
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase) ; nulstiller more faren
1$	jsr	(readchar)
	beq.b	2$
	bmi.b	1$			; Dropper spesial tegn.
	bra.s	3$
2$	moveq.l	#0,d0
3$	lea	(p_string,a2),a0
	move.b	d0,(a0)
	clrz
	rts

paragon_9				; throw out user
	move.b	#Thrownout,(readcharstatus,NodeBase)
	clrz
	rts

paragon_10				; display text file
	lea	(p_string,a2),a0
	moveq.l	#0,d0			; både con og ser
	jsr	(typefilenoerror)
	clrz
	rts

paragon_11				; find out if the file is locked/availible
	push	d2			; doesn't handle wildcard's yet
	lea	(p_string,a2),a0
	move.l	a0,d1
	moveq.l	#EXCLUSIVE_LOCK,d2
	movea.l	(dosbase),a6
	jsrlib	Lock
	move.l	d0,d1
	beq.b	1$
	jsrlib	UnLock
	moveq.l	#0,d0
	bra.b	2$
1$	moveq.l	#-1,d0
2$	move.w	d0,(p_Data,a2)
	movea.l	(exebase),a6
	pop	d2
	clrz
	rts

paragon_12				; Edit file
	push	d2-d5
	lea	(tmpmsgheader,NodeBase),a0
	moveq.l	#MessageRecord_SIZEOF,d0
	jsr	(memclr)
	lea	(tmpmsgheader,NodeBase),a0
	moveq.l	#-1,d0
	move.l	d0,(MsgTo,a0)
	move.l	(msgmemsize,NodeBase),d0
	move.l	(tmpmsgmem,NodeBase),a1
	move.l	a1,d1
	jsr	(calleditor)
	beq.b	9$
	move.l	a0,d5
	lea	(p_string,a2),a0
	movea.l	(dosbase),a6
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	1$
	move.l	d0,d1
	move.l	d5,d2
	moveq.l	#0,d3
	move.w	(NrBytes+tmpmsgheader,NodeBase),d3
	jsrlib	Write
	move.l	d4,d1
	jsrlib	Close
1$	movea.l	(exebase),a6

;Edits the file called doormsg->string, and will not allow the file to
;exceed doormsg->data lines in length.

9$	pop	d2-d5
	clrz
	rts

paragon_13				; return user status
	move.w	(p_Data,a2),d0
	beq.b	7$	
	subq.w	#1,d0
	beq	10$			; User access level
	moveq.l	#0,d1
	subq.w	#1,d0
	beq.s	8$			; User Xpertaccess mode
	subq.w	#1,d0
	beq.s	8$			; User Net credits
	move.w	(TimesOn+CU,NodeBase),d1
	subq.w	#1,d0
	beq.s	8$			; Nummers of calls
	subq.w	#1,d0
	beq.s	8$			; Calls to system
	subq.w	#1,d0
	beq.s	2$			; Graphic mode
	subq.w	#1,d0
	beq.s	1$			; Time remaining
	moveq.l	#80,d1
	subq.w	#1,d0
	beq.s	8$			; Screen collums
	move.w	(PageLength+CU,NodeBase),d1
	subq.w	#1,d0
	beq.s	8$			; Screen rows
	subq.w	#1,d0
	beq.s	3$			; Baud rate
	move.w	#210,d1
	subq.w	#1,d0
	beq.s	8$			; Paragon Version nr
	subq.w	#1,d0
	bne.s	7$			; ukjennt sub
	bra.b	4$			; users online

8$	move.w	d1,(p_Data,a2)
	bra.b	9$
7$	bsr	cmdnotsupported
9$	clrz
	rts

1$	move.w	#$7fff,d1
	move.w	(TimeLimit+CU,NodeBase),d0
	beq.b	8$
	jsr	(updatetime)
	move.w	(TimeLimit+CU,NodeBase),d1
	sub.w	(TimeUsed+CU,NodeBase),d1
	bcc.b	8$
	moveq.l	#0,d1
	bra.b	8$

2$	moveq.l	#0,d1			; graphic mode
	move.w	(Userbits+CU,NodeBase),d0
	and.w	#USERF_RAW+USERF_ANSIMenus,d0
	beq.b	8$
	moveq.l	#1,d1
	bra.b	8$

3$	movea.l	(nodenoden,NodeBase),a0
	move.l	(Nodespeed,a0),d1
	divu	#300,d1
	bra.b	8$

4$	moveq.l	#0,d1			; antall users online
	move.l	nodelist+LH_HEAD,a0	; Henter pointer til foerste node
6$	move.w	(Nodenr,a0),d0
	beq.b	5$			; Hopper over noder som er nede
	moveq	#NDSF_Stealth,d0
	and.b	(Nodedivstatus,a0),d0	; er det stealth login ?
	bne.b	5$			; Jepp, teller ikke denne
	move.w	(Nodestatus,a0),d0
	beq.s	5$			; ikke på
	addq.l	#1,d1
5$	move.l	(LN_SUCC,a0),a0		; Henter ptr til nestenode
	move.l	(LN_SUCC,a0),d0
	bne.b	6$			; flere noder. Same prosedure as last year
	bra.b	8$

10$	jsr	(justchecksysopaccess)
	beq.b	11$
	moveq.l	#100,d1			; sysop'er har level 100
	bra	8$
11$	moveq.l	#0,d1			; alle andre har 0


paragon_14				; return user status
	move.w	(p_Data,a2),d0
	beq.b	7$
	lea	(Name+CU,NodeBase),a0
	cmpi.w	#1,d0			; user name
	beq.b	8$
	cmpi.w	#2,d0			; passwd
	beq.b	7$			; ulovelig
	lea	(Address+CU,NodeBase),a0
	cmpi.w	#3,d0			; Adress
	beq.b	8$
	lea	(CityState+CU,NodeBase),a0
	cmpi.w	#6,d0			; City/state
	bls.b	8$
	lea	(doorspath),a0
	cmpi.w	#7,d0			; Doors path
	beq.b	8$
	lea	(abbsrootname),a1
	cmpi.w	#8,d0			; ABBS path
	beq.b	8$
	cmpi.b	#9,d0			; date

	cmpi.b	#10,d0			; time
	bne.s	7$			; ukjennt
	lea	(tmpdatestamp,NodeBase),a0
	move.l	a0,d1
	movea.l	(dosbase),a6
	jsrlib	DateStamp
	movea.l	(exebase),a6
	lea	(tmpdatestamp,NodeBase),a0
	lea	(tmptext,NodeBase),a1
	jsr	(gettimestr)
	lea	(tmptext,NodeBase),a0

8$	lea	(p_string,a2),a1
	moveq.l	#78,d0
	jsr	(strcopymaxlen)
	bra.b	9$
7$	bsr	cmdnotsupported
9$	clrz
	rts

paragon_15				; set user access level
	clrz
	rts

paragon_16				; set user status
	move.w	(p_Data,a2),d0
	beq.b	7$
	subq.w	#1,d0			; user name
	beq.b	9$			; nop
	subq.w	#1,d0			; passwd
	beq.b	7$
	lea	(Address+CU,NodeBase),a1
	move.w	#Sizeof_NameT,d1
	subq.w	#1,d0			; Adress
	beq.b	8$
	lea	(CityState+CU,NodeBase),a1
	subq.w	#3,d0			; City/state
	bcs.b	8$
	beq.b	8$

	subq.w	#4,d0			; Doors path++
	bcs.b	9$			; nop
	bra.b	7$			; ukjennt

8$	lea	(p_string,a2),a0
	move.w	d1,d0
	push	a0/d0
	jsr	(strcopymaxlen)
	pop	a0/d0
	jsr	(saveuserarea)
	bra.b	9$
7$	bsr	cmdnotsupported
9$	clrz
	rts

paragon_17				; return random number
	moveq.l	#0,d0
	move.w	(p_Data,a2),d0
	move.l	d0,-(sp)
	XREF	_RangeRand
	jsr	(_RangeRand)
	addq.l	#4,sp
	move.w	d0,(p_Data,a2)
	clrz
	rts

paragon_18				; reset loss of carrier state
	move.b	#OK,(readcharstatus,NodeBase)
	clrz
	rts

paragon_19				; show graphics textfile
	link.w	a3,#-80
	lea	(p_string,a2),a0
	lea	sp,a1
	jsr	(strcopy)
	lea	sp,a1
	move.w	(Userbits+CU,NodeBase),d1
	btst	#USERB_ANSIMenus,d1	; ANSI ?
	beq.b	1$			; nope

	lea	(gr1text),a0
	jsr	(strcat)
	lea	sp,a0
	jsr	(findfile)
	bne.b	2$
	lea	(p_string,a2),a0
	lea	sp,a1
	jsr	(strcopy)
	lea	sp,a1
	bra.b	1$

2$	moveq.l	#0,d0			; både con og ser
	lea	sp,a0
	jsr	(typefileansi)
	bra.b	9$

1$	lea	(txttext),a0
	jsr	(strcat)
	lea	sp,a0
	jsr	(findfile)
	bne.b	3$
	lea	(p_string,a2),a0
	lea	sp,a1
	jsr	(strcopy)
3$	moveq.l	#0,d0			; både con og ser
	lea	sp,a0
	jsr	(typefile)

9$	unlk	a3
	clrz
	rts

paragon_20				; end door session
	setz
	rts

paragon_21				; update user's timelimit
	move.w	(TimeLimit+CU,NodeBase),d0	; Har vi limit ?
	beq.b	9$			; nei, gir f..
	add.w	(p_Data,a2),d0
	beq.s	2$
	bpl.b	1$
2$	moveq.l	#1,d0
1$	move.w	d0,(TimeLimit+CU,NodeBase)
9$	clrz
	rts

paragon_22				; get pointer to config (FY FY FY)
	bsr	cmdnotsupported
	clrz
	rts

paragon_23				; ???? Hva skal denne gjøre ?

paragon_24				; disse er udokkumentere
paragon_27
paragon_28
paragon_29
	bsr	cmdnotsupported
	clrz
	rts

paragon_26				; sender node melding
	push	a3
	move.l	(Tmpusermem,NodeBase),a3
	moveq.l	#79,d0
	lea	(p_string,a2),a0
	lea	(i_msg,a3),a1
	jsr	(memcopylen)
	move.b	#0,(a1)			; paranoia
	move.b	#2,(i_type,a3)		; node melding
	move.w	(NodeNumber,NodeBase),(i_franode,a2)
	moveq.l	#0,d0
	move.w	(p_Data,a2),d0		; sender meldingen
	movea.l	a3,a0
	move.b	#0,(i_pri,a0)
	jsr	(sendintermsg)
	pop	a3
	clrz
	rts

paragon_30				; Sjekk etter input
	move.w	(p_Data,a2),d0
	move.w	#0,(p_Data,a2)		; ikke noe klart
	cmp.b	#1,d0			; console ?
	bne.b	1$
	move.l	(creadreq,NodeBase),d0
	beq.b	9$			; ikke noe tegn
	move.l	d0,a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	9$			; Nei. ikke noe tegn her.
8$	move.w	#-1,(p_Data,a2)		; det er et tegn klart
	bra.b	9$

1$	cmp.b	#2,d0			; serial ?
	bne.b	9$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Skal denne noden være serial ?
	beq.b	9$			; nei
	movea.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	bne.b	8$			; Ja, vi har et tegn
	ENDC
9$	clrz
	rts

paragon_31
	move.w	(p_Data,a2),d0
	move.w	#0,(p_Data,a2)		; ikke noe klart
	cmp.b	#1,d0			; console ?
	bne.b	1$

	move.l	(pastetext,NodeBase),d1		; sjekker om det ligger tegn og venter
	bne.b	3$				; det gjorde det. 
	move.l	(creadreq,NodeBase),d0
	beq.b	9$			; ikke mulig å sjekke == ikke noe tegn
	move.l	d0,a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	9$			; Nei. ikke noe tegn her.
3$	jsr	(doconsole)
	bne.b	8$
2$	jsr	(readchar)
	beq.b	8$
	bmi.b	2$
	bra.b	8$


1$	cmp.b	#2,d0			; serial ?
	bne.b	9$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Skal denne noden være serial ?
	beq.b	9$			; nei
	movea.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	9$			; Ikke noe tegn

	jsr	(doserial)
	beq.s	2$			; ikke noe
;	bne.b	8$
	ELSE
	bra.b	9$
	ENDC
8$	move.w	d0,(p_Data,a2)		; det er et tegn klart
9$	clrz
	rts

paragon_32				; oppdater carrier status
	clrz
	rts

paragon_33
	push	d2
	moveq.l	#0,d0
	move.w	(p_Data,a2),d0		; henter timeout
	beq.b	9$			; det er ingen

	movea.l	(timer1req,NodeBase),a1
	move.l	d0,(TV_SECS+IOTV_TIME,a1)
	moveq.l	#0,d0
	move.l	d0,(TV_MICRO+IOTV_TIME,a1)
	move.w	#TR_ADDREQUEST,(IO_COMMAND,a1)
	jsrlib	SendIO				; Starter timeout'en.

	move.l	(timer1sigbit,NodeBase),d0
	or.l	(sersigbit,NodeBase),d0
	or.l	(consigbit,NodeBase),d0
	jsrlib	Wait				; venter på første signalet
	move.l	d0,d2				; lagrer det vi fikk
	and.l	(timer1sigbit,NodeBase),d0	; var det timeout ?
	bne.b	3$				; jepp.
	movea.l	(timer1req,NodeBase),a1		; abort'er timeren.
	jsrlib	AbortIO
3$	movea.l	(timer1req,NodeBase),a1
	jsrlib	WaitIO
	move.l	(timer1sigbit,NodeBase),d0
	not.l	d0
	and.l	d0,d2			; sletter timerbitet ifra det vi fikk
	beq.s	9$			; ikke noe igjen
	move.l	d2,d0			; setter de igjen, siden vi ikke
	move.l	d2,d1			; behandler dem nå
	jsrlib	SetSignal
9$	pop	d2
	clrz
	rts

cmdnotsupported
	moveq.l	#0,d0
	move.w	(p_Command,a2),d0	; Henter ut kommando nummeret
	jsr	(skrivnr)
	lea	(notsuptext),a0
	jsr	(writetexto)
	lea	pltellsysoptext,a0
	jsr	(writetexto)
	moveq.l	#0,d0
	move.w	d0,(p_Data,a2)
	move.b	d0,(p_string,a2)
	move.l	d0,(p_config,a2)
	move.l	d0,(p_msg,a2)
	moveq.l	#5,d0			; venter 5 sek
	jmp	(waitsecs)
	rts

	section	paragondata,data

paragon_cmds
	dc.l	paragon_1,paragon_2,paragon_3,paragon_4,paragon_5,paragon_6
	dc.l	paragon_7,paragon_8,paragon_9,paragon_10,paragon_11,paragon_12
	dc.l	paragon_13,paragon_14,paragon_15,paragon_16,paragon_17,paragon_18
	dc.l	paragon_19,paragon_20,paragon_21,paragon_22,paragon_23,paragon_24
	dc.l	paragon_25,paragon_26,paragon_27,paragon_28,paragon_29,paragon_30
	dc.l	paragon_31,paragon_32,paragon_33

doparagondoortags
	dc.l	SYS_Input,0
	dc.l	SYS_Output,0
	dc.l	SYS_Asynch,1,TAG_DONE,0
doparagondoortagsend

niltext		dc.b	'NIL:',0
notsuptext	dc.b	' : Command not supported. This door can''t be used with abbs',0
txttext		dc.b	'.TXT',0
gr1text		dc.b	'.GR1',0

	END
