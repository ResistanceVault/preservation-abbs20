******************************************************************************
******									******
******		      ABBS - Amiga Bulletin Board System		******
******			 Written By Geir Inge Høsteng			******
******									******
******************************************************************************

 *****************************************************************
 *
 * NAME
 *	Node.asm
 *
 * DESCRIPTION
 *	Main source for nodes
 *
 * AUTHOR
 *	Jan Erik Olausen
 *
 * $Id: Node.asm 2.x 1997-2000 10:32:07 Jan Erik Olausen $
 *
 * MODIFICATION HISTORY
 * $Log: Node.asm $
;; Revision 2.xx  2000/06/24  10:32:07  JEO
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'

;	IFND	__M68
	include	'exec/types.i'
	include	'exec/ports.i'
	include	'exec/lists.i'
	include	'exec/io.i'
	include	'exec/memory.i'
	include	'exec/tasks.i'
	include	'exec/libraries.i'
	include	'exec/execbase.i'
	include	'libraries/dos.i'
	include	'libraries/gadtools.i'
	include	'devices/serial.i'
	include	'devices/conunit.i'
	include	'devices/timer.i'
	include	'intuition/intuition.i'
	include	'intuition/screens.i'
	include	'dos/dosextens.i'
	include	'dos/dos.i'
	include	'dos/exall.i'
	include	'dos/var.i'
	include	'dos/dostags.i'
	include	'graphics/gfxbase.i'
	include	'graphics/text.i'
	include	'utility/tagitem.i'
	include	'libraries/asl.i'
	include 'rexx/storage.i'
	include	'utility/date.i'
;	ENDC
	include	'fifo.i'

	include	'asm.i'
	include	'bbs.i'
	include	'Abbsfront.i'
	include	'xpr.i'
	include	'fse.i'
	include	'node.i'
	include	'tables.pro'
	include	'tables.i'
	include	'msg.pro'
	include	'paragon.pro'
	include	'transfer.pro'
	include	'browse.pro'
	include	'QWK.pro'
	include	'rexx.pro'
	include	'nodedefs.i'
	include	'noderefs.i'
	include	'NodeSupport.pro'

	XREF	_Make_conf_text
	XREF	_CheckInvited
	XREF	_WriteLineNr
	XREF	_PackUserDoFiles
	XREF	_JEO_NewFiles

;nobreak	  = 1
;exceptionhandler = 1
	IFEQ	sn-13
;NOINIT	= 1
;nocarrier = 1		; I transfer.asm også 
;FullGrab = 1
	ENDC

minwindowx = 272		; obs også i tables.asm
minwindowy = 30			; obs også i tables.asm

maxwindowx = -1			; obs også i tables.asm
maxwindowy = -1			; obs også i tables.asm

	section kode,code

first	jmp	(main)		; Hopper til hovedprog start.

		dc.b	0,'$VER: '
versionstr	dc.b	'ABBS '
		version
		date
		dc.b	0

*******************************************************************************
*									      *
* * * * * * * * * * * * * * * Kode for Noden(e) * * * * * * * * * * * * * * * *
*									      *
*******************************************************************************

	cnop	0,4

nodestart
	dc.l	16,0

nstart	move.l	(exebase),a6
	move.l	a7,a5			; Liten hack for å huske start stack'en
	jsrlib	Forbid			; sikrer at vi starter alene
	jsr	(doallsetup)		; åpner, og initer alt
	beq.b	9$			; Noe gikk galt

1$	bsr	nodemain		; tar en innlogging.
	move.b	#'6',d0
	jsr	(writeconchar)
	tst.b	(ShutdownNode,NodeBase)	; skal noden ned ?
	beq.b	1$			; nei, da tar vi en innlogging til

	move.b	#'0',d0
	jsr	(writeconchar)

	jsr	(doallshutdown)		; lukker og frigir alt
9$	rts				; ;wow. da er denne noden ferdig

nodehook
	rts

	IFEQ	sn-13
checkalloweduser
	lea	(n_FirstConference+CStr,MainBase),a1
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Lokal node ?
	beq.b	9$				; Ja, da har vi lov uansett
	move.l	(Usernr+CU,NodeBase),d0		; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	99$				; Jepp, ikke lov.
	moveq.l	#0,d0

	lea	(u_almostendsave+CU,NodeBase),a0
1$	move.b	(n_ConfName,a1),d1		; conf her ?
	beq.b	2$				; nope
	move.w	(uc_Access,a0),d1
	btst	#ACCB_Sysop,d1			; er vi sysop ?
	bne.b	9$				; ja, ut
2$	lea	(ConferenceRecord_SIZEOF,a1),a1
	lea	(Userconf_seizeof,a0),a0
	addq.l	#1,d0
	cmp.w	(Maxconferences+CStr,MainBase),d0
	bcs.b	1$
	setz
9$	notz
99$	bne.b	999$
	move.l	a1,a0
	jsr	(writeerroro)
	lea	(nosysopheretext),a0
	jsr	(writeerroro)
	move.b	#Thrownout,(readcharstatus,NodeBase)
	setz
999$	rts
	ENDC

sysoploginjmp
	lea	(SYSOPpassword+CStr,MainBase),a0
	move.b	(a0),d0			; har vi noe ?
	beq	nodemain1		; nei, da dropper vi passord
	moveq.l	#1,d0			; 2 forsøk
	jsr	(getpasswd)
	beq	endmain
	bra.b	nodemain1
nodemain
	move.b	#'7',d0
	jsr	(writeconchar)
	jsr	(initrun)
	move.b	#'8',d0
	jsr	(writeconchar)
	jsr	(waitforcaller)
	beq	endmain

mainnewuser
	jsr	(initrunlate)
	jsr	(login)
	beq	logout
	bmi	endmain
	jsr	(stoptimeouttimer)
	IFEQ	sn-13
	bsr	checkalloweduser
	beq	logout
	ENDC
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne.b	1$
	lea	(postloginfname),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeansi)
	tst.b	(readcharstatus,NodeBase)
	bne	endmain
1$	jsr	(checkcarriercheckser)
	beq	endmain
	jsr	(checktimeinbetweenlogins)
	beq	logout

nodemain1
	jsr	(registerlogin)
	jsr	(typestat)
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	bne	logout				; ja

	lea	loginscrname,a0
	sub.l	a1,a1					; ingen feilmelding
	jsr	(doarexxdoor)

	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	bne	logout				; ja
	bsr	dopersonalloginscript

	move.w	#-1,(linesleft,NodeBase)		; Vi vil ikke ha noen more her..
	moveq.l	#0,d0					; Joiner main
	bsr	joinnr

menu	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	bne	logout				; ja
	jsr	(checktime)
	beq	logout
	jsr	(checkintermsgs)
	beq.b	1$
	jsr	(outimage)
1$	jsr	(checkreadptrs)
	jsr	(getprompttext)
	jsr	(readlineprompt)
	beq	nomenuinput
	jsr	(upword)

	movem.l	d2/d3,-(sp)
	move.w	(menunr,NodeBase),d1
	lea	(menus),a1
	move.l	(0,a1,d1.w),a1
	jsr	(scanchoices)
	move.l	d0,d2
	move.l	d1,d3
	move.b	(noglobal,NodeBase),d0
	beq.b	4$
	tst.l	d3
	beq.b	5$
	moveq.l	#0,d1
	bra.b	3$
4$	lea	(globalchtext),a1
	jsr	(scanchoices)
	tst.l	d1
	bne.b	3$
	tst.l	d3
	bne.b	3$
5$	movem.l	(sp)+,d2/d3
	bra	notchoices
3$	lea	(globaljmptable),a0
	cmp.l	d1,d3
	bcs.b	2$
	move.l	d2,d0
	lea	(menujmps),a0
	move.w	(menunr,NodeBase),d1
	move.l	(0,a0,d1.w),a0
2$	movem.l	(sp)+,d2/d3
	subq.l	#1,d0
	asl.w	#2,d0
	move.l	(0,a0,d0.w),a0
	jsr	(a0)				; Utfører funksjonen
	move.b	(readcharstatus,NodeBase),d0	; Har det skjedd noe ?
	beq	menu				; Nei...

logout	move.w	#-1,(linesleft,NodeBase)	; Dropper all more saker ..
	move.b	#'1',d0
	jsr	(writeconchar)
	jsr	(hangup)
	move.b	#'2',d0
	jsr	(writeconchar)
	moveq.l	#1,d0				; vi skal ta full logout
	jsr	(endrun)
	move.b	#'3',d0
	jsr	(writeconchar)
	move.b	(userok,NodeBase),d0
	beq	3$
	move.b	#0,(userok,NodeBase)
	jsr	(unjoin)			; oppdaterer last read.
	move.b	#'4',d0
	jsr	(writeconchar)
	bsr	restorereadpointers
	bsr	deletereadpointersfile
	move.b	#'5',d0
	jsr	(writeconchar)
	jsr	(logoutsaveuser)
	move.b	#'6',d0
	jsr	(writeconchar)

;	jsr	updatetime			; gjøres i logoutsaveuser
	move.w	(TimeUsed+CU,NodeBase),d0
	add.w	(minchat,NodeBase),d0
	add.w	(minul,NodeBase),d0
	sub.w	(OldTimelimit,NodeBase),d0
	bcc.b	7$
	moveq.l	#0,d0
7$
;	move.w	(TimeUsed+CU,NodeBase),d0
;	sub.w	(minul,NodeBase),d0		; justerer for upload
;	bcc.b	7$
;	moveq.l	#0,d0
;	sub.w	(OldTimelimit,NodeBase),d0	; minutter i forige session
;	bcc.b	6$
;7$	moveq.l	#0,d0
6$	lea	(logtimeusedtext),a0
	bsr	20$

	move.w	(FTimeUsed+CU,NodeBase),d0
	beq.b	5$
	sub.w	(OldFilelimit,NodeBase),d0	; trekker fra forige session tiden
	bcs.b	5$				; overflow, sier null da => ingenting .. 
;	sub.w	(minul,NodeBase),d0
;	bcc.b	8$
;	moveq.l	#0,d0
8$	lea	(logftimeusedtxt),a0
	bsr	20$

5$	move.w	(tmsgsread,NodeBase),d0
	lea	(logmsgreadtext),a1
	bsr	10$

	move.w	(tmsgsdumped,NodeBase),d0
	beq.b	4$
	lea	(logmsgdumedtext),a1
	bsr	10$

4$	lea	(lostcarriertext),a0
	cmpi.b	#NoCarrier,(readcharstatus,NodeBase)
	beq	2$
	lea	(logfellasletext),a0
	cmpi.b	#Timeout,(readcharstatus,NodeBase)
	beq.b	2$
	lea	(logthrownoutext),a0
	cmpi.b	#Thrownout,(readcharstatus,NodeBase)
	beq.b	2$
	lea	(loglogouttext),a0
2$	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(Name+CU,NodeBase),a0
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	jsr	(writelogstartup)

3$	move.b	#'1',d0
	jsr	(writeconchar)
	bsr	sendlogoutintermsg
	move.b	#'2',d0
	jsr	(writeconchar)

	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(connrtotext)
	move.l	a0,a1
	lea	(logutscriptname),a0
	jsr	(executedosscriptparam)
	move.b	#'3',d0
	jsr	(writeconchar)
	jsr	(getscratchpaddelfname)		; sletter scratchpad, safety
	jsr	(deletepattern)
	jsr	(cleanupfiles)
	move.b	#'b',d0
	jsr	(writeconchar)

	jsr	(saveconfig)
	move.b	#'4',d0
	jsr	(writeconchar)
	moveq.l	#0,d0
	move.b	d0,(active,NodeBase)
	jsr	(changenodestatus)
	bra.b	endmain

10$	push	a1
	lea	(maintmptext,NodeBase),a0
	jsr	(konverterw)
	lea	(maintmptext,NodeBase),a0
	pop	a1
	jmp	(writelogtexttimed)

20$	push	a0
	lea	(maintmptext,NodeBase),a0
	jsr	(konverterw)
	lea	(maintmptext,NodeBase),a1
	pop	a0
	jmp	(writelogtexttimed)

endmain
	IFND DEMO
	move.b	(RealCommsPort,NodeBase),d0		; Setter tilbake
	beq.b	1$					; ikke serial
	move.b	#-1,d1					; fikk vi noen port
	cmp.b	d0,d1
	beq.b	1$					; vi hadde en..
	cmp.b	(CommsPort+Nodemem,NodeBase),d0		; disablet ?
	beq.b	1$
;	move.b	d0,(CommsPort+Nodemem,NodeBase)		; setter tilbake
;	jsr	(aapnemodem)				; hvorfor åpne igjen ???
	jsr	(stopserreadcheck)
1$
	ENDC
	jsr	(stoptimeouttimer)
	move.b	#'5',d0
	jsr	(writeconchar)
	jmp	(stopconreadcheck)

notchoices
	tst.b	(readcharstatus,NodeBase)
	bne	logout
	move.w	(menunr,NodeBase),d0
	lea	(notchoiceschoic),a1
	move.l	(0,a1,d0.w),d0
	beq	1$
	move.l	d0,a1
	jsr	(a1)
	bmi.b	2$
	tst.b	(readcharstatus,NodeBase)
	bne	logout
	bra	menu
2$	tst.b	(readcharstatus,NodeBase)
	bne	logout

1$	lea	(invalidcmdtext),a0
	move.b	(XpertLevel+CU,NodeBase),d0			; skal de ha lang text ?
	cmpi.b	#2,d0
	bcc.b	3$					; ja
	lea	(Notvalidcomtext),a0
	jsr	(writeerroro)
	move.w	(menunr,NodeBase),d0
	lea	(menus),a1
	move.l	(0,a1,d0.w),d0
	move.l	d0,a0
	lea	(globalchtext),a1
	move.b	(noglobal,NodeBase),d1
	beq.b	4$
	lea	(nulltext),a1
4$	jsr	(writetextformatted)
	clr.b	(readlinemore,NodeBase)		; flush'er input
	bra.b	9$
3$	jsr	(writeerroro)
9$	bra	menu

nomenuinput
	tst.b	(readcharstatus,NodeBase)
	bne	logout
	move.w	(menunr,NodeBase),d0
	lea	(nomenuinputch),a0
	move.l	(0,a0,d0.w),d0
	beq	menu
	move.l	d0,a0
	jsr	(a0)
	bne	menu
	tst.b	(readcharstatus,NodeBase)
	bne	logout
	bra	menu

readmenunotchoices
	push	a2/d2
	move.l	a0,a2
	jsr	(inputnr)
	beq.b	2$					; ikke tall
	andi.l	#$ffff,d0
	moveq.l	#0,d1
	move.w	(confnr,NodeBase),d1
	move.l	d0,d2
	jsr	(typemsg)
	bmi.b	1$
	move.l	d2,(currentmsg,NodeBase)
	bra.b	8$
1$	lea	(msgnotfoundtext),a0
	jsr	(writeerroro)
8$	moveq	#1,d0
	bra.b	99$

2$	jsr	(justchecksysopaccess)		; er vi sysop ?
	beq.b	9$				; nei, da var det ihvertfall ukjennt.
	move.l	a2,a0
	lea	(readsecretchtxt),a1
	jsr	(scanchoices)
	tst.l	d1
	beq.b	9$
	subq.l	#1,d0
	asl.w	#2,d0
	lea	(readsecrettable),a0
	move.l	(0,a0,d0.w),a0
	jsr	(a0)				; Utfører funksjonen
	moveq	#1,d0
	bra.b	99$

9$	tst.b	(readcharstatus,NodeBase)
	bne	10$
	moveq	#-1,d0
99$	pop	a2/d2
	rts
10$	pop	a2/d2
	bra	logout

markmenunotchoices
	jsr	(inputnr)
	bne.b	3$
	IFND DEMO
	lea	(sntext),a1
	jsr	(comparestrings)
	bne.b	99$
	move.l	(snumber),d0
	jsr	(skrivnr)
	jsr	(outimage)
	ENDC
	bra.b	99$			; Ikke noe tall
3$	jsr	(allowmark)
	bmi.b	9$
	beq.b	1$
	lea	(cantmarkmsgtext),a0
	jsr	(writeerrori)
	bra.b	2$
1$	lea	(tmpmsgheader,NodeBase),a0
	jsr	(insertinqueue)
2$	bsr	readmenu
9$	clrn
	rts
99$	setn
	rts

; execute the personal arexx loginscript, if any
dopersonalloginscript
	link.w	a3,#-80
	move.b	(UserScript+CU,NodeBase),d0
	beq.b	9$				; ingen script
	move.l	sp,a1
	lea	(ploginscrname),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(UserScript+CU,NodeBase),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(dotabbstext),a0
	jsr	strcopy
	move.l	sp,a0
	sub.l	a1,a1					; ingen feilmelding
	jsr	(doarexxdoor)
9$	unlk	a3
	rts

*****************************************************************
*			Global meny				*
*****************************************************************
;#b
;#c
mainmenu
	move.w	#0,(menunr,NodeBase)		;Skifter til Main menu
	rts

;#c
readmenu
	move.w	#4,(menunr,NodeBase)		;Skifter til Read menu
	rts

;#c
utilitymenu
	move.w	#12,(menunr,NodeBase)	;Skifter til Utility menu
	rts

;#c
chatmenu
	move.w	#28,(menunr,NodeBase)		;Skifter til chat menu
	rts

;#c
miscmenu
	move.w	#44,(menunr,NodeBase)		;Skifter til misc menu
	rts

;#c
dohelp	lea	helpscriptname,a0
	lea	sorrynohelptext,a1
	jsr	(doarexxdoor)
	rts

;#c
help	jsr	(outimage)
	move.w	(menunr,NodeBase),d0
	cmp.w	#44,d0				; er det misc meny ?
	bne.b	1$
	lea	(miscmenuscrname),a0
	jsr	(getfilelen)			; har vi arexx script ?
	beq.b	2$
	lea	(miscmenuscrname),a0
	suba.l	a1,a1				; ingen feilmelding
	bsr	doarexxdoor			; tar arexx isteden...
	bra.b	9$
2$	move.w	(menunr,NodeBase),d0
1$	lea	(menufiles),a0
	move.l	(0,a0,d0.w),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeansi)
	beq.b	9$
	move.b	(noglobal,NodeBase),d1
	bne.b	9$
	lea	(globalmenufile),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeansi)
9$	rts

;#c
Next	lea	(checkfmsgictext),a0
	jsr	(writetexto)
	beq.b	9$
	jsr	(joinnextunreadconf)
	bne.b	9$
	lea	(nonewiacmsgtext),a0
	jsr	(writetexto)
9$	rts

;#c
multijoin
	push	d2/d3/a2/a3/d4/d5
	lea	(checkconfstext),a0
	jsr	(writetexto)
	beq	9$
	move.w	(confnr,NodeBase),d3		; hvor vi startet
	move.w	d3,d2				; Nåværende conf

	lea	(u_almostendsave+CU,NodeBase),a2
	lea	(n_FirstConference+CStr,MainBase),a3 ; kan brukeren join'e ?

1$	move.w	d2,d0
	jsr	(getnextconfnrsub)
	move.w	d0,d1
	subi.w	#1,d1
	add.w	d1,d1				; gjor om til confnr standard
	cmp.w	d3,d1				; ferdig ?
	beq	9$				; jepp
	move.w	d1,d5
	mulu	#Userconf_seizeof/2,d5
	move.w	d1,d2				; nåværende konfnr.
	move.w	(uc_Access,a2,d5.l),d1
	btst	#ACCB_Read,d1			; Er vi medlem her ?
	bne.b	1$				; ja, tar neste
	move.w	d2,d5
	mulu	#ConferenceRecord_SIZEOF/2,d5
	move.w	(uc_Access,a2),d1
	btst	#ACCB_Sysop,d1			; Er vi sysop i main ?
	bne.b	2$				; ja, da sjekker vi ikke VIP'en

	move.w	(n_ConfSW,a3,d5.l),d1
	btst	#CONFSWB_VIP,d1			; Kan han join'e denne ?
	bne.b	1$				; nei
2$	move.w	d0,d4				; husker (confnr/2)-1

	move.w	d2,d0
	jsr	(typeconfinfo)
	beq	9$

	lea	(conferecetext),a0
	jsr	(writetext)
	lea	(n_ConfName,a3,d5.l),a0
	jsr	(writetexto)
	beq	9$
	lea	(wanttojoinctext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	beq	8$				; nei, eller noe galt

	move.w	d2,d0				; join konf'en
	bset	#31,d0				; bare bli medlem
	jsr	(joinnr)

	lea	(wanttoskipltext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	beq.b	8$				; nei, eller noe galt

	move.l	(n_ConfDefaultMsg,a3,d5.l),d0	; tar en "M R"
	move.w	d2,d1
	mulu	#Userconf_seizeof/2,d1
	move.l	d0,(uc_LastRead,a2,d1.l)
	bra	1$

8$	tst.b	(readcharstatus,NodeBase)
	beq	1$
9$	pop	d2/d3/a2/a3/d4/d5
	rts

;#c	JEO
opendoor
	push	d2-d4/a2
	link.w	a3,#-80
	move.l	sp,a2
	lea	(erropendoortext),a0
	move.l	(rexbase),d0
	beq	8$

	move.l	a2,a1				; bygger opp setup filnavnet
	lea	(doorconfigfname),a0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	bsr	10$				; leser inn fila
	bne.b	100$				; ok?

	move.l	a2,a1				; Nope, vi bruker default 0
	lea	(doorconfigfname),a0		; som er 0 fila
	move.w	#0,d0				; nodenummer
	jsr	(fillinnodenr)
	bsr	10$				; leser inn fila
	beq	8$				; Error?

100$	tst.b	(readlinemore,NodeBase)		; er det mere input ?
	bne	1$
0$	move.b	#0,(readlinemore,NodeBase)	; Sletter for sikkerhets skyld
						; og skriver ut menu
	lea	(maintmptext,NodeBase),a1	; bygger opp door menu filnavnet
	lea	(doormenufilname),a0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0	; Filnavn i a0
	jsr (findfile)
	lea	(maintmptext,NodeBase),a0	; skrive ut navn på nytt
	bne	101$				; funnet..

	lea	(maintmptext,NodeBase),a1	; Ikke funnet, leser inn default
	lea	(doormenufilname),a0
	move.w	#0,d0				; nodenummer 0 = default
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0	; skriver ut menu da.

101$	moveq.l	#0,d0
	jsr	(typefilemaybeall)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bsr	10$				; leser inn fila igjen
	beq	8$				; error

1$	lea	(nrdoortopentext),a0
	jsr	(readlineprompt)
	beq	9$
	jsr	(atoi)
	lea	(musthavenrtext),a0
	bmi.b	82$
	beq	0$
	move.l	d0,d2
	move.l	(tmpmsgmem,NodeBase),a0
	bsr	findentrynr
	beq	0$
	move.l	d2,d1
	move.l	a0,d2
	move.w	d0,d3				; husker type

	moveq.l	#36,d0
	jsr	(changenodestatus)

	lea	(logopendoortext),a0
	move.l	d2,a1
	jsr	(writelogtexttimed)

	move.l	d2,a0
	lea	(erropendoortext),a1
	cmpi.b	#'P',d3				; er det paragon dør ?
	bne.b	2$
	jsr	(doparagondoor)
	bra.b	4$

2$	cmpi.b	#'A',d3				; er det Arexx dør ?
	bne.b	3$
	bsr	doarexxdoor
	bra.b	4$

3$	cmpi.b	#'S',d3				; er det Shell dør ?
	bne.b	7$
	bsr	doshelldoor

4$	moveq.l	#4,d0
	jsr	(changenodestatus)
	bra.b	9$
7$	lea	(unknowformatext),a0
	bra.b	82$

8$	lea	(nodoronsystext),a0
82$	jsr	(writeerroro)
9$	unlk	a3
	pop	d2-d4/a2
	rts

10$	move.l	a2,d1				; leser inn fila.
	move.l	#MODE_OLDFILE,d2
	move.l	(dosbase),a6
	jsrlib	Open
	move.l	d0,d4
	beq.b	19$
	move.l	(msgmemsize,NodeBase),d3
	move.l	(tmpmsgmem,NodeBase),d2		; Bruker tmpmsgmem til buffer
	move.l	d4,d1
	jsrlib	Read
	exg	d4,d1
	jsrlib	Close
	moveq.l	#-1,d0
	cmp.l	d0,d4				; error ?
	beq.b	19$				; jepp
	move.l	(tmpmsgmem,NodeBase),a0
	move.b	#0,(0,a0,d4.l)			; markerer slutten
	tst.l	d4				; var det noe ?
19$	move.l	(exebase),a6
	rts

; a0 = minne
; d0 = entry nr
; returnerer filnavn i a0, og type i d0
findentrynr
	move.l	d0,d1				; linje nr.
1$	move.b	(a0)+,d0
	beq.b	9$				; end of block
	cmpi.b	#' ',d0				; skip'er space,
	beq.b	1$
	cmpi.b	#9,d0				; tab,
	beq.b	1$
	cmpi.b	#10,d0				; og linefeed
	beq.b	1$
	cmpi.b	#';',d0
	beq.b	2$				; komentar
	subi.b	#1,d1				; reduserer linje nr med 1
	bne.b	2$				; ikke denne linja, skiper.

	move.b	d0,d1				; husker typen
	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#' ',d0				; Skal ha en space eller
	beq.b	3$
	cmpi.b	#9,d0				; tab imellom
	bne.b	9$
3$	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#' ',d0				; skip'er space
	beq.b	3$
	cmpi.b	#9,d0				; og tab
	beq.b	3$

	lea	(-1,a0),a1			; husker starten på navnet
5$	move.b	(a0)+,d0			; finner slutten
	beq.b	4$
	cmpi.b	#' ',d0
	beq.b	4$
	cmpi.b	#10,d0
	beq.b	4$
	cmpi.b	#9,d0
	bne.b	5$
4$	move.b	#0,-(a0)			; markerer slutten
	move.l	a1,a0				; returnerer navn
	move.l	d1,d0				; og type
	bra.b	9$

2$	move.b	(a0)+,d0			; skip'er til EOL
	beq.b	9$
	cmpi.b	#10,d0
	bne.b	2$
	bra.b	1$				; og tar ny linje

9$	rts

doshelldoor
	push	a2/d2-d4
	link.w	a3,#-30
	move.l	a0,a2				; husker door navnet
	jsr	(updatetime)
	lea	(Name+CU,NodeBase),a0		; setter opp locale variable Fullname
	move.l	a0,d2
	jsr	(strlen)
	move.l	d0,d3
	move.l	#localefullname,d1
	move.l	#GVF_LOCAL_ONLY,d4
	move.l	dosbase,a6
	jsrlib	SetVar
	move.w	(NodeNumber,NodeBase),d0	; og Nodenr...
	move.l	sp,a0
	jsr	(konverterw)
	move.l	sp,a0
	move.l	a0,d2
	jsr	(strlen)
	move.l	d0,d3
	move.l	#localenodenr,d1
	jsrlib	SetVar

;	move.w	(NodeNumber,NodeBase),d0	; og timeleft.
;	move.l	sp,a0
;	jsr	(konverterw)
;	move.l	sp,a0
;	move.l	a0,d2
;	jsr	(strlen)
;	move.l	d0,d3
;	move.l	#localetimeleft,d1
;	jsrlib	SetVar

	move.l	exebase,a6

	move.l	a2,a0				; kjører selve door'en
	bsr	doshelldoorsub

	move.l	#localefullname,d1
	move.l	#GVF_LOCAL_ONLY,d2
	move.l	dosbase,a6
	jsrlib	DeleteVar
	move.l	#localenodenr,d1
	jsrlib	DeleteVar
	move.l	exebase,a6
	unlk	a3
	pop	a2/d2-d4
	rts

GetChar	move.l	(exebase),a6
	jsr	(stoptimeouttimer)		
	move.l	d1,d0
	jsr	(starttimeouttimersec)		; starter timer
	jsr	(readchar)
	bne.b	9$				; Fikk char, returnerer
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$				; hopper ut hvis vi fikk no carrier
	moveq.l	#-1,d0				; fikk timer return
	jsr	(stoptimeouttimer)		
9$	rts

; a0 = script name
; a1 = feilmelding
doarexxdoor
	push	a2/d2/d3/a3
	move.l	a0,d3				; husker script name
	move.l	a1,a3				; husker feilmelding
	move.l	(rexbase),d0
	beq	9$				; no rexx
	move.l	d0,a6
	move.l	(rexxport,NodeBase),a0
	lea	(Publicportname,NodeBase),a1
	move.l	a1,d0
	lea	(abbsextension),a1
	jsrlib	CreateRexxMsg			; lager Arexx melding
	move.l	a0,a2
	move.l	a3,a0				; gjør klar feilmelding
	tst.l	d0
	beq	8$				; error
	move.l	#RXCOMM|(1<<RXFB_NOIO),(ACTION,a2)
	move.l	d3,a0
	jsr	(strlen)
	move.l	d3,a0
	jsrlib	CreateArgstring			; lager argstring
	move.l	a0,(ARG0,a2)
	beq	6$				; error

	move.l	(exebase),a6			; sender melding til REXX
	jsrlib	Forbid
	lea	(rexxportname),a1
	jsrlib	FindPort
	tst.l	d0
	beq.b	2$				; opps, ingen port
	move.l	d0,a0
	move.l	a2,a1
	jsrlib	PutMsg
	moveq.l	#1,d0
2$	jsrlib	Permit
	tst.l	d0
	beq.b	6$

	move.l	(publicsigbit,NodeBase),d3	; setter opp signalene
	or.l	(rexxsigbit,NodeBase),d3
	or.l	(intsigbit,NodeBase),d3

1$	move.l	d3,d0
	jsrlib	Wait
	move.l	d0,d2
	and.l	(publicsigbit,NodeBase),d0
	beq.b	4$
	jsr	(handlepublicport)
;	bra.b	4$

;	beq.b	1$				; loooop	var 5$....
;	tst.b	(readcharstatus,NodeBase)	; noe galt ?
;	bne.b	5$				; jepp.

4$	move.l	d2,d0
	and.l	(intsigbit,NodeBase),d0		; var det int bit ?
	beq.b	10$
	jsr	(dointuition)			; behandler det.

;	beq.b	5$
;	tst.b	(readcharstatus,NodeBase)	; noe galt ?
;	bne.b	5$				; jepp.

10$	and.l	(rexxsigbit,NodeBase),d2
	beq.b	1$
	move.l	(rexxport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq.b	1$
	cmpa.l	d0,a2				; riktig melding ?
	bne.b	1$				; nei (????)
	move.l	d0,a0
	move.l	(RESULT1,a0),d0
	beq.b	7$				; ingen error
	move.l	(RESULT2,a0),d0
	moveq.l	#1,d1
	cmp.l	d0,d1
	beq.b	6$
	bra.b	7$

5$	move.l	(rexxport,NodeBase),a0		; venter til meldingen kommer tilbake
	jsrlib	WaitPort
	move.l	(rexxport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq.b	5$
	bra.b	7$

6$	move.l	(exebase),a6
	move.l	a3,d0
	beq.b	7$
	move.l	a3,a0
	jsr	(writeerroro)
7$
;	move.b	#0,(readlinemore,NodeBase)	; Sletter for sikkerhets skyld
	move.l	(rexbase),a6
	move.l	a2,a0
	moveq.l	#16,d0
	jsrlib	ClearRexxMsg
	move.l	a2,a0
	jsrlib	DeleteRexxMsg
	move.l	(exebase),a6
	bra.b	9$
8$	move.l	(exebase),a6
	move.l	a0,d0
	beq.b	9$
	jsr	(writeerroro)
9$	move.b	#0,(FSEditor,NodeBase)		; dekoding på (for sikkerhetsskyld)
	pop	a2/d2/d3/a3
	rts

;#c
godbye
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)		; internal node ??
	beq.b	1$					; jepp
	ENDC
0$	lea	(doyearealyltext),a0
	suba.l	a1,a1
	push	a2
	lea	doyearealyhtext,a2
	jsr	(readlinepromptwhelp)
	pop	a2
	beq.b	1$			; bare return, eller no carrier
	jsr	(upword)
	lea	(godbyechtext),a1
	jsr	(scanchoices)
	beq.b	2$			; ingen valg.
	tst.l	d1
	beq.b	2$			; Ingen tegn matcher.
	cmpi.b	#1,d0
	beq.b	1$			; Dette er Yes
	cmpi.b	#2,d0
	beq	9$			; Dette er No
	cmpi.b	#3,d0			; Again ?
	beq	newuser			; Dette er Again
2$	lea	(Notvalidcomtext),a0
	jsr	(writeerroro)
	lea	(godbyechtext),a0
	jsr	(writetexto)
	bra.b	0$
1$	jsr	(isholdempty)
	beq.b	12$
	lea	(youhfinholdtext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	bne	9$
	move.b	(readcharstatus,NodeBase),d0	; Har det skjedd noe ?
	bne	8$				; jepp
12$	jsr	(checkscratchpad)
	beq	8$				; no carrier eller noe slikt
	move.w	#-1,(linesleft,NodeBase)	; Dropper all more saker ..
	lea	logoutscrname,a0
	sub.l	a1,a1				; ingen feilmelding
	jsr	(doarexxdoor)
	move.w	#-1,(linesleft,NodeBase)	; Dropper all more saker ..
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne	8$
	jsr	(outimage)
	beq	3$
	lea	(logoutfilename),a0
	moveq.l	#0,d0				; ser og con
	jsr	(typefilemaybeall)
	beq	3$

	lea	(timeusedsestext),a0		; Tid denne session
	moveq.l	#27,d0
	jsr	(writetextlfill)
	move.w	(TimeUsed+CU,NodeBase),d0
	add.w	(minchat,NodeBase),d0
	add.w	(minul,NodeBase),d0
	sub.w	(OldTimelimit,NodeBase),d0
	bcc.b	7$
	moveq.l	#0,d0
7$	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)

	move.w	(minchat,NodeBase),d0
	beq.b	4$
	lea	(deductfchattext),a0
	moveq.l	#27,d0
	jsr	(writetextlfill)
	move.w	(minchat,NodeBase),d0
	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)

4$	move.w	(minul,NodeBase),d0
	beq.b	5$
	lea	(deductforultext),a0
	moveq.l	#27,d0
	jsr	(writetextlfill)
	move.w	(minul,NodeBase),d0
	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)

5$	lea	(timeusedtodtext),a0
	moveq.l	#27,d0
	jsr	(writetextlfill)
	move.w	(TimeUsed+CU,NodeBase),d0
	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)

	move.w	(FTimeUsed+CU,NodeBase),d0
	beq.b	6$
	lea	(ftimeusedtdtext),a0
	moveq.l	#27,d0
	jsr	(writetextlfill)
	move.w	(FTimeUsed+CU,NodeBase),d0
	sub.w	(minul,NodeBase),d0
	bcc.b	11$
	moveq.l	#0,d0
11$	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)
6$
	jsr	(docookie)
3$	jsr	(waitforemptymodem)
8$	addq.l	#4,sp			; Fjerner returadressen.
	bra	logout
9$	rts

;#c
newuser	jsr	(isholdempty)
	beq.b	12$
	lea	(youhfinholdtext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	bne	9$
	move.b	(readcharstatus,NodeBase),d0	; Har det skjedd noe ?
	beq	9$				; nei, skal returnere
	addq.l	#4,sp				; Fjerner returadressen.
	bra	logout

12$	addq.l	#4,sp				; Fjerner returadressen.
	jsr	(checkscratchpad)
	beq	logout
	move.w	#-1,(linesleft,NodeBase)	; Dropper all more saker ..
	lea	logoutscrname,a0
	sub.l	a1,a1				; ingen feilmelding
	jsr	(doarexxdoor)
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne.b	1$
	jsr	(docookie)
	jsr	(outimage)
1$	bsr	restorereadpointers
	bsr	deletereadpointersfile
	jsr	(unjoin)			; oppdaterer last read.
	lea	(loglogouttext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(Name+CU,NodeBase),a0
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	jsr	(writelogstartup)
	lea	(newusermsgtext),a0
	jsr	(writelogtexttime)
	bsr	sendlogoutintermsg
	jsr	(logoutsaveuser)
	moveq.l	#0,d0				; vi skal ikke ta full logout
	jsr	(endrun)
	jsr	(initrun)
	jsr	(saveconfig)
	move.l	(nodenoden,NodeBase),a0
	bset	#NECSB_UPDATED,(NodeECstatus,a0)		; Sier at den er updated
	bra	mainnewuser
9$	rts

sendlogoutintermsg
	link.w	a3,#-80
	btst	#DIVB_StealthMode,(Divmodes,NodeBase)	; er Stealth Mode på ?
	bne.b	9$					; jepp. dropper den node meldingen.
	move.l	sp,a1					; sier fra at vi drar..
	lea	(Name+CU,NodeBase),a0
	move.b	(a0),d0
	beq.b	9$					; ikke hvis vi ikke har noe navn
	lea	(i_Name,a1),a1
	jsr	(strcopy)
	move.l	sp,a0
	move.b	#1,(i_type,a0)				; logout melding
	move.w	(NodeNumber,NodeBase),(i_franode,a0)
	moveq.l	#0,d0					; Alle noder.
	move.b	#0,(i_pri,a0)
	jsr	(sendintermsg)
9$	unlk	a3
	rts


;#c
sysopmenu
	jsr	(justchecksysopaccess)
	bne.b	1$				; vi er sysop.
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(confnr,NodeBase),d0		; Henter conferanse nr.
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Sigop,d0		; har bruker sigop access ??
	beq.b	2$			; nei, sier fy
	move.w	#20,(menunr,NodeBase)	;Skifter til Sigop menu
	bra.b	9$
2$	lea	(youarenottext),a0	; Nei, skriver ut fy melding
	jsr	(writeerroro)
	bra.b	9$
1$	move.w	#8,(menunr,NodeBase)	;Skifter til Sysop menu
9$	rts

;#c
filemenu
	cmpi.w	#16,(menunr,NodeBase)	; er vi i file menyen ?
	beq.b	9$			; ja, da er det en nop
	jsr	(updatetime)
	move.w	(FileLimit+CU,NodeBase),d0	; Har vi limit ?
	beq.b	1$
	cmp.w	(FTimeUsed+CU,NodeBase),d0
	bhi.b	1$
	lea	(ftimexpiredtext),a0
	jsr	(writeerroro)
	bra.b	9$
1$
;	IFEQ	sn-13
;	move.b	(CommsPort+Nodemem,NodeBase),d0	; internal node ??
;	beq.b	2$				; Yepp. no checking
;	move.w	(Userbits+CU,NodeBase),d0
;	btst	#USERB_G_R,d0
;;	I F N D DEMO
;	beq.b	2$
;	jsr	docheckGogR
;	ENDC
2$	move.w	#16,(menunr,NodeBase)		;Skifter til File menu
9$	rts

;#e

;#b
;#c
; confnr * 2.w Hvis bit 31 er satt, skal vi bare bli medlem (multijoin)
joinnr	moveq.l	#0,d1
	bra.b	join1
join	bsr	readmenu		; skifter til read meny
	moveq.l	#1,d1
join1	push	d2/d3/a2/d4/d5/d6/d7/a3
	moveq.l	#0,d6			; vi skal ikke bruke maks scan.
	tst.w	d1
	beq	2$			; Vi vet allerede nummeret.
	tst.b	(readlinemore,NodeBase)
	beq.b	3$
	lea	(joinconftext),a0
	jsr	(readlineprompt)
	beq	9$
20$	moveq.l	#0,d0
	move.b	(1,a0),d0		; det er mere enn bare + eller -
	bne.b	23$
	move.b	(a0),d0
	cmpi.b	#'+',d0
	beq.b	22$
	cmpi.b	#'-',d0
	beq.b	24$
23$	jsr	(getconfnamesub)
	bne	25$
	bpl	9$
3$	jsr	(outimage)
	beq	9$
	lea	(conflistfilname),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeall)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	move.b	#0,(readlinemore,NodeBase)
	lea	(joinconftext),a0
	jsr	(readlineprompt)
	beq	9$
	move.b	(a0),d0			; fjerner "j " hvis svaret starter
	cmpi.b	#'J',d0			; med dette.
	beq.b	21$			; Dette for å hjelpe dumme brukere..
	cmpi.b	#'j',d0
	bne.b	20$
21$	tst.b	(readlinemore,NodeBase)	; er det mere ?
	beq.b	20$			; nei, da tolker vi det som en navn
	move.b	(1,a0),d0		; var det alt ?
	bne.b	20$			; nei, da er det et konf navn
	jsr	(readline)		; henter conf navnet
	beq	9$
	bra	20$
22$	move.w	(confnr,NodeBase),d0
	jsr	(getnextconfnr)
	bra	25$
24$	move.w	(confnr,NodeBase),d0
	jsr	(getprevconfnr)
;	bra	25$

25$	bclr	#31,d0
2$	move.l	d0,d3
	lsr.w	#1,d0
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(uc_Access,a0),d2		; Husker MAIN access
	mulu	#Userconf_seizeof,d0
	lea	(0,a0,d0.l),a2
	move.l	d3,d0
	lea	(n_FirstConference+CStr,MainBase),a3
	mulu	#ConferenceRecord_SIZEOF/2,d0
	add.l	d0,a3
	move.w	(uc_Access,a2),d7
	move.l	(uc_LastRead,a2),d1		; har vi lest noe her ?
	bne.b	32$				; jepp, tar ikke
	btst	#ACCB_Read,d7			; Er vi medlem her ?
	bne	7$				; Ja, hopp
	btst	#ACCB_Invited,d7		; invited ?
	bne.b	33$				; ja, ta confinfo
	tst.w	d7				; har vi vært her før?
	bne.b	32$				; ja

	move.w	(n_ConfSW,a3),d0		; er det VIP ?
	btst	#CONFSWB_VIP,d0
	bne.b	32$				; ja. ikke confinfo
33$	move.l	d3,d0
	bmi.b	32$				; skip'er når vi bare skal joine
	jsr	(typeconfinfo)			; skriver ut confinfo fila
32$	btst	#ACCB_Sysop,d2			; Har vi sysop access i MAIN ???
	beq.b	19$				; Nei, vanelig bruker ..
	tst.w	d7				; none access ?
	bne.b	19$				; ja, tar ikke og gir ny access
	move.w	#ACCF_Write+ACCF_Read+ACCF_Download+ACCF_Upload+ACCF_FileVIP+ACCF_Sysop,(uc_Access,a2)
	bra.b	8$

19$	btst	#ACCB_Read,d7			; Er vi medlem her ?
	bne	7$				; Ja, hopp
	move.l	d3,d0
	lsr.w	#1,d0
	btst	#ACCB_Sysop,d2			; Har vi sysop access i MAIN ???
	bne.b	12$				; Jepp. Lar han joine vip også.

	move.w	(n_ConfSW,a3),d2		; kan brukeren join'e ?
	btst	#CONFSWB_VIP,d2
	beq.b	12$
	lea	(nmembofconftext),a0		; nei
	jsr	(writeerroro)
	bra	9$
12$	ori.w	#ACCF_Read,(uc_Access,a2)	; gir han read access.
	lea	(n_ConfName,a3),a1		; Skriver til log'en
	lea	(logjoinedctext),a0
	jsr	(writelogtexttimed)

	move.l	(uc_LastRead,a2),d0		; har han lest meldinger her ?
	bne.b	8$				; ja, da får han ikke write av oss
	btst	#CONFSWB_PostBox,d2		; er det en post konf ?
	beq.b	6$				; nei...
	move.l	(n_ConfDefaultMsg,a3),(uc_LastRead,a2) ; tar en "M R"

6$	moveq.l	#1,d6				; vi skal bruke maks scan
	move.l	a2,a1
	btst	#CONFSWB_ImmWrite,d2		; skal han få write ?
	beq.b	8$				; nei.
	ori.w	#ACCF_Write,(uc_Access,a2)	; gir han write access.
8$	lea	(uc_Access,a2),a0		; lagrer denne forandringen
	moveq.l	#2,d0
	jsr	(saveuserarea)

7$	btst	#31,d3				; bare bli medlem ?
	bne	9$				; ja, da er vi ferdig
	moveq.l	#0,d0
	move.l	d0,(currentmsg,NodeBase)
	cmpi.w	#8,(menunr,NodeBase)		;Er vi i Sysop menu ???
	beq.b	10$
	cmpi.w	#20,(menunr,NodeBase)		;Er vi i Sigop menu ???
	bne.b	11$				;Nei, hopp.
10$	move.w	#0,(menunr,NodeBase)		;Skifter til Main menu
11$	jsr	(outimage)
	beq	9$

	move.w	(confnr,NodeBase),d0		; Oppdaterer last read.
	cmpi.w	#-1,d0
	beq.b	16$				; Har ikke vært i noen konferanse
	jsr	(findlowestinqueue)
	bne.b	17$
	move.l	(HighMsgQueue,NodeBase),d0
	bra.b	18$
17$	subq.l	#1,d0
18$	move.w	(confnr,NodeBase),d1
	mulu	#Userconf_seizeof/2,d1
	lea	(u_almostendsave+CU,NodeBase),a0
	move.l	d0,(uc_LastRead,a0,d1.l)
16$	move.w	d3,(confnr,NodeBase)
	moveq.l	#0,d0
	move.l	d3,d0
;	move.l	d6,d1			; om vi skal bruke maks
;	beq.b	4$
	bset	#31,d0			; setter flagget (for max scan)
4$	jsr	(buildqueue)
	move.l	d0,d4			; Husker verdiene.
	move.l	d1,d5			; bit 31 sier om vi kuttet
	lea	(ansigreentext),a0
	jsr	(writetext)

	lea	(n_FirstConference+CStr,MainBase),a3
	move.l	d3,d0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	add.l	d0,a3
	lea	(u_almostendsave+CU,NodeBase),a2
	move.l	d3,d0
	mulu	#Userconf_seizeof/2,d0
	add.l	d0,a2

	lea	(n_ConfName,a3),a0
	jsr	(writetexti)
	beq	9$
	lea	(cconfstatustext),a0
	jsr	(writetexto)
	beq	9$

	lea	(ansilbluetext),a0
	jsr	(writetext)
	lea	(Lastmsgtext),a0
	jsr	(writetext)
	lea	(ansiwhitetext),a0
	jsr	(writetext)
	move.l	(n_ConfDefaultMsg,a3),d0
	jsr	(skrivnr)
	jsr	(breakoutimage)
	beq	9$
	lea	(ansilbluetext),a0
	jsr	(writetext)
	lea	(Lastmsgyourtext),a0
	jsr	(writetext)
	lea	(ansiwhitetext),a0
	jsr	(writetext)
	move.l	(uc_LastRead,a2),d0
	jsr	(skrivnr)
	jsr	(outimage)
	beq	9$
	btst	#31,d5			; har vi kuttet ?
	beq.b	31$
	bclr	#31,d5			; sletter signalet
	lea	(onlythelasttext),a0
	jsr	(writetext)
	move.w	(n_ConfMaxScan,a3),d0	; henter maks scan verdien
	jsr	(skrivnr)
	lea	(msgaautscantext),a0
	jsr	(writetexto)
31$	move.l	d4,d0
	jsr	(skrivnr)
	lea	(nmesgaavailtext),a0
	jsr	(writetext)
	moveq.l	#1,d0
	cmp.l	d0,d4
	beq.b	34$
	lea	(nmesgaavai2text),a0
	bra.b	35$
34$	lea	(nmesgaavai3text),a0
35$	jsr	(writetext)
	lea	(nmesgaavai4text),a0
	jsr	(writetext)
	move.l	d5,d0
	beq.b	13$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	move.l	d4,d1
	move.l	d5,d0
	cmp.l	d0,d1
	bne.b	14$
	lea	(smallalltext),a0
	jsr	(writetext)
	bra.b	15$
14$	jsr	(skrivnr)
15$	lea	(foryoutext),a0
	jsr	(writetext)
13$	move.b	#'.',d0
	jsr	(writechar)
	jsr	(outimage)
	beq.b	9$
	move.w	(confnr,NodeBase),d0
	beq.b	40$				; ikke i news.
;	cmpi.w	#2,d0
;	beq.b	40$				; ikke i post heller

	move.b	(n_ConfBullets,a3),d0		; har denne konfen bulletiner ?
	beq.b	28$				; Nei, hopp
	lea	(confbullacttext),a0
	jsr	(writetexto)
28$	btst	#ACCB_Sigop,d7			; er vi sigop ?
	beq.b	40$
	lea	(sigopcomacttext),a0
	jsr	(writetexto)
40$	jsr	(sjekklovtilaaskrivesub)
	bne.b	99$
	lea	(readonlycontext),a0
	jsr	(writetexto)
99$	jsr	(outimage)
9$	pop	d2/d3/a2/d4/d5/d6/d7/a3
	tst.b	(readcharstatus,NodeBase)
	notz
	rts

;JEO
	XREF	_ShowConferencesAll
	XREF	_Conference_browser
	XREF	_ABBS_version
	XREF	_Bug
;	XREF	_GetChar
	XREF	_ShowUsers_c
;#c
Whos_on
;	jsr	(browseconferences)
;	moveq.l	#1,d1			; 1 sekunder
;	jsr	GetChar
	move.l	a2,-(sp)
	lea	(whoheader),a0		; Skriver ut headeren
	jsr	(strlen)
	lea	(whoheader),a0
	moveq.l	#0,d1
	jsr	(writetextmemi)
	beq	9$
	move.l	nodelist+LH_HEAD,a2	; Henter pointer til foerste node
	move.l	(LN_SUCC,a2),d0
	beq	9$			; ingen noder, egentlig umulig, men ..
3$	move.w	(Nodenr,a2),d0
	beq	5$			; Hopper over noder som er nede
	lea	(ansiredtext),a0
	jsr	(writetext)
	move.b	#'#',d0			; Skriver ut "#<nodenr>  "
	jsr	(writechar)
	move.w	(Nodenr,a2),d0
	andi.l	#$ffff,d0
	jsr 	(connrtotext)
	moveq.l	#4,d0
	jsr	(writetextlfill)
	lea	(ansigreentext),a0
	jsr	(writetext)
	move.l	(Nodespeed,a2),d0	; Skriver ut nodespeeden
	bne.b	1$
	lea	(localtext),a0		; Hvis speed = 0 => lokalnode
	moveq.l	#8,d0
	bra.b	2$
1$	move.b	#' ',d0
	jsr	(writechar)
	move.l	(Nodespeed,a2),d0
	jsr 	(connrtotext)		; Ekstern node, skriv ut baud hastighet
	moveq.l	#7,d0
2$	jsr	(writetextlfill)
	move.b	(NodeECstatus,a2),d1
	move.b	#'V',d0
	btst	#NECSB_V42BIS,d1
	bne.b	10$
	move.b	#'M',d0
	btst	#NECSB_MNP,d1
	bne.b	10$
	move.b	#' ',d0
10$	jsr	(writechar)
	move.b	#' ',d0
	jsr	(writechar)
	lea	(ansiyellowtext),a0
	jsr	(writetext)
	move.w	(Nodestatus,a2),d0	; skriver ut nodestatusen
	move.b	(Nodedivstatus,a2),d1	; er det stealth login ?
	andi.b	#NDSF_Stealth,d1
	beq.b	15$			; nei, da lyver vi ikke
	move.w	#0,d0			; sier at vi er log'a ut
	bra.b	7$
15$	cmp.w	#4,d0			; er vi active ?
	bne.b	7$			; nei, ikke mere
	move.b	(Nodedivstatus,a2),d1
	andi.b	#NDSF_Notavail,d1	; avail ?
	beq.b	7$			; ja, da skriver vi active.
	moveq.l	#56,d0			; ikke avail
7$	cmp.w	#68,d0			; arexx sin utbyttersak ?
	bne.b	71$
	move.l	(NodesubStatus,a2),a0	; ja, tar den
	bra	6$
71$	lea	(statustext),a0
	move.l	(0,a0,d0.w),a0		; heter den ved indexering
	cmpi.w	#12,d0			; enter msg ?
	beq.b	12$			; ja
	cmpi.w	#16,d0			; reply msg ?
	bne.b	13$			; nei
12$	move.l	(NodesubStatus,a2),d0
	cmp.l	(Usernr+CU,NodeBase),d0	; til oss ?
	bne.b	6$			; nei.
	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	lea	(toyoutext),a0
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	bra.b	6$

13$	cmpi.w	#36,d0			; I door ?
	beq.b	11$			; ja
	cmpi.w	#52,d0			; DL'er han hold ?
	beq.b	11$			; ja
	cmpi.w	#24,d0			; DL'er han ?
	bne.b	6$			; nei.
11$	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	subq.l	#1,a1
	move.l	(NodesubStatus,a2),d0
	move.l	a1,a0
	jsr	(konverter)
	move.w	(Nodestatus,a2),d0	; skriver ut nodestatusen
	cmpi.w	#36,d0			; I door ?
	beq.b	14$			; Ja, da kutter vi ut K'en.
	move.b	#'K',(a0)+
	move.b	#0,(a0)
14$	lea	(maintmptext,NodeBase),a0
6$	moveq.l	#25,d0
	jsr	(writetextlfill)

	lea	(ansiwhitetext),a0
	jsr	(writetext)
	lea	(Nodeuser,a2),a0	; Skriver ut bruker navn.
	tst.b	(a0)			; Er det et navn der?
	bne.b	50$			; Ja
	lea	(notavailable),a0	; Ellers skriv N/A
50$	jsr	(writetext)
	lea	(NodeuserCityState,a2),a0	; Skriver ut city/state.
	tst.b	(a0)
	beq.b	4$
	move.b	#',',d0
	jsr	(writechar)
	move.b	#' ',d0
	jsr	(writechar)
	lea	(ansilillatext),a0
	jsr	(writetext)
	lea	(NodeuserCityState,a2),a0	; Skriver ut city/state.
	jsr	(writetext)
4$	jsr	(outimage)
	beq.b	9$

5$	move.l	(LN_SUCC,a2),a2		; Henter ptr til nestenode
	move.l	(LN_SUCC,a2),d0		; er det noen flere noder ?
	bne	3$			; flere noder. Same prosedure as last year
	move.w	(MainBits,MainBase),d0
	andi.w	#MainBitsF_SysopNotAvail,d0
	bne.b	8$
	move.b	#10,d0
	jsr	(writechar)
	moveq.l	#15,d0
	lea	(spacetext),a0
	jsr	(writetextlen)
	lea	(ansiyellowtext),a0
	jsr	(writetext)
	lea	(plainsysoptext),a0
	jsr	(writetext)
	move.b	#' ',d0
	jsr	(writechar)
	lea	(availforchatext),a0
	jsr	(writetexto)
	beq.b	9$
8$	jsr	(outimage)
9$	move.l	(sp)+,a2
	rts

;#c
entermsg
	push	a2/a3/d2/d4/d3
	move.l	(tmpmsgmem,NodeBase),a3
	jsr	(sjekklovtilaaskrive)		; har vi skrive access i denne konferansen ?
	beq	9$				; nope, ut me'n

	lea	(tmpmsgheader,NodeBase),a2	; clear'er msgheader
	move.l	a2,a0
	move.w	#MessageRecord_SIZEOF,d0
	jsr	(memclr)
	move.w	(confnr,NodeBase),d1

	lea	(n_FirstConference+CStr,MainBase),a1
	mulu	#ConferenceRecord_SIZEOF/2,d1
	move.l	(n_ConfDefaultMsg,a1,d1.l),d0	; henter siste meldings nummer
	addq.w	#1,d0				; øker med en..
	move.l	d0,(Number,a2)			; og bruker som meldingsnummer
	move.b	#MSTATF_NormalMsg,(MsgStatus,a2)
	move.b	#SECF_SecNone,(Security,a2)
	move.b	#0,(MsgBits,a2)			; clear bits
	move.l	(Usernr+CU,NodeBase),(MsgFrom,a2)

	move.w	(n_ConfSW,a1,d1.l),d3		; Finner ut om vi er i en postpox
	moveq.l	#0,d2				; vi er ikke i post konferanse
	lea	(sendmsgtotext),a0		; default text med (CR for ALL)
	btst	#CONFSWB_PostBox,d3
	beq.b	1$				; ikke post
	lea	(sendmsgtouatext),a0		; ny text uten (CR for ALL)
	moveq.l	#1,d2				; vi er i post...
	moveq.l	#0,d0				; vi godtar ikke all
	bra.b	2$
1$	moveq.l	#1,d0				; vi godtar all
2$	moveq.l	#0,d4				; ikke net navn (enda)
	btst	#CONFSWB_Network,d3
	beq.b	3$				; ikke net conf..
	moveq.l	#1,d4				; vi skal ha net navn alikevel
3$	move.l	d4,d1				; nettnavn status
	moveq.l	#0,d4				; ikke net melding enda
	jsr 	(getnamenrmatch)
	bne.b	4$
	move.b	(readcharstatus,NodeBase),d1
	bne	9$				; det skjedde noe spes, ut
	tst.w	d2				; ALL ikke tillatt i post konfer. (d2 = 1 for post)
	beq.b	5$				; ikke i post, alt ok.
	moveq.l	#-1,d1				; sjekker om vil fikk ALL
	cmp.l	d1,d0
	beq	9$				; jepp, da hopper vi bare ut...
	move.b	#SECF_SecReceiver,(Security,a2)	; vi er i post, så sett access
	bra.b	5$
4$	bpl.b	5$				; ikke net navn
	moveq.l	#-2,d0
	moveq.l	#1,d4				; nå er vi net navn..
; a0 er nå net navne, og d0 er net bruker
	move.b	#Net_ToCode,(a3)+		; fyller i to bruker
401$	move.b	(a0)+,(a3)+
	bne.b	401$
	move.b	#10,(-1,a3)
	move.l	d0,(MsgTo,a2)
	bra.b	6$				; netmelding -> skal ikke sjekke medlemskap
5$	move.l	d0,(MsgTo,a2)
	moveq.l	#-1,d1
	cmp.l	d1,d0
	beq.b	6$
	move.w	(confnr,NodeBase),d1
	jsr	(checkmemberofconf)
	bne.b	6$
	lea	(loadusererrtext),a0
	bmi	8$
	lea	(sorryusnmoctext),a0
	bra	8$
6$	lea	(entersubjectext),a0		; vi ber om subject
	lea	(nulltext),a1
	moveq.l	#Sizeof_NameT,d0
	tst.w	d4				; ikke net melding -> Sizeof_NameT
	beq.b	7$
	moveq.l	#60,d0				; 60 er et fint tall...
7$	jsr	(mayedlineprompt)
	beq	9$				; bare return. Ut..
	move.l	a0,a1
	jsr	(strlen)
	moveq.l	#Sizeof_NameT,d1
	cmp.l	d0,d1
	bcc.b	10$				; plass i header strukturen
	move.b	#Net_SubjCode,(a3)+		; fyller i net header.
701$	move.b	(a1)+,(a3)+
	bne.b	701$
	move.b	#10,(-1,a3)
	bra.b	11$
10$	move.l	a1,a0
	lea	(Subject,a2),a1
	jsr	(strcopymaxlen)

11$	move.l	(MsgTo,a2),d0			; Kan meldingen være privat ?
	moveq.l	#-1,d1
	cmp.l	d1,d0
	beq.b	14$				; Aldri når den er til alle ..
	tst.w	d2				; Er i post, så da er den allerede..
	bne.b	12$				; Setter alikevel for sikkerhet..
	btst	#CONFSWB_Private,d3		; kan vi ha privat ?
	beq.b	14$				; nei, ikke i denne conf'en
	lea	(privatemsgetext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	13$
12$	move.b	#SECF_SecReceiver,(Security,a2)
	bra.b	14$
13$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$				; noe rart skjedde..

14$	moveq.l	#12,d0			; Status = enter msg.
	moveq.l	#-1,d1
	tst.w	d4			; netmeldinger er til "all" for å hindre at noen får "to you"
	bne.b	15$
	move.l	(MsgTo,a2),d1
15$	jsr	(changenodestatus)
	lea	(MsgTimeStamp,a2),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6

	move.b	#0,(a3)
	move.l	(tmpmsgmem,NodeBase),a0
	jsr	(strlen)			; hvor mye har vi brukt ?
	move.l	d0,d4			; husker size (Blir jo ulik 0 alikevel..)
	move.l	(msgmemsize,NodeBase),d0
	sub.l	d4,d0
	bcs	9$			; for lite, skal ikke kunne skje, men ..
	move.l	a2,a0
	move.l	a3,a1
	move.l	(tmpmsgmem,NodeBase),d1
	jsr	(calleditor)
	beq.b	16$
	tst.w	d4
	beq.b	17$			; det er ikke net melding
	neg.w	(NrLines,a2)		; merker det som det
	add.w	d4,(NrBytes,a2)		; korigerer NrBytes
17$	move.w	(confnr,NodeBase),d0
	move.l	a2,a1
	move.l	(tmpmsgmem,NodeBase),a0
	jsr	(savemsg)
	lea	(cnotsavemsgtext),a0
	bne.b	8$			; error
	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	(Number,a2),d0
	jsr	(skrivnr)
	lea	(savedtext),a0
	jsr	(writetexto)
	move.l	(Number,a2),d0
	bsr	stopreviewmessages
	addq.w	#1,(MsgsLeft+CU,NodeBase)
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	(sendintermsgmsg)
	move.l	(Number,a2),d1
	lea	(logentermsgtext),a0
	move.w	(confnr,NodeBase),d0		; conf nr
	jsr	(killrepwritelog)
	bra.b	9$

16$	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$
	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	(Number,a2),d0
	jsr	(skrivnr)
	lea	(abortedtext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
	pop	a2/a3/d2/d4/d3
	rts

; msg nr
stopreviewmessages
	move.w	(Userbits+CU,NodeBase),d1		; skal vi beholde egne msg'er ?
	andi.w	#USERF_KeepOwnMsgs,d1
	bne.b	9$				; ja.
	move.l	(HighMsgQueue,NodeBase),d1	; Er meldingen vi lagrer den neste ?
	addq.l	#1,d1
	cmp.l	d0,d1
	bne.b	9$				; nei.
	move.l	d0,(HighMsgQueue,NodeBase)	; Oppdaterer HighMsgQueue.
9$	rts

;#c
bulletins
	push	d2/d3/a2/d4
	link.w	a3,#-160
	move.l	a3,d4
	move.w	(confnr,NodeBase),d0
	lsr.w	#1,d0				; her jobber vi med * 1..
	move.w	d0,d2
	lea	(n_FirstConference+CStr,MainBase),a3
	mulu	#ConferenceRecord_SIZEOF,d0
	add.l	d0,a3
	move.w	(n_ConfBullets,a3),d0		; har denne konfen bulletiner ?
	bne.b	2$				; Ja, hopp
	moveq.l	#0,d2				; Nei, bruk NEWS
	lea	(n_FirstConference+CStr,MainBase),a3
	move.w	(n_ConfBullets,a3),d0		; har NEWS bulletiner ?
	beq	99$				; Nei, ingen ting å gjøre.
2$	moveq.l	#-1,d3				; siste bulletin vi leste
	tst.b	(readlinemore,NodeBase)
	bne.b	1$
3$	move.w	d2,d0
	move.l	sp,a0				; fyller i navnet til bl filen
	jsr	(getkonfbulletlist)
	move.l	sp,a0
	moveq.l	#0,d0
	jsr	(typefilemaybeall)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	move.w	d2,d0
	moveq.l	#0,d1
	jsr	(checkupdatedbulletins)
1$	lea	(entbulletnrtext),a0
	lea	(bulletihelpfile),a1
	lea	(entbullhelptext),a2
	jsr	(readlinepromptwhelp)
	beq	9$
;	move.l	a0,-(sp)
;	jsr	(newlinei)
;	move.l	(sp)+,a0
;	lea	(ymchosebulltext),a0
	move.b	(a0),d0			; fjerner "b " hvis svaret starter
	cmpi.b	#'B',d0			; med dette.
	beq.b	6$			; Dette for å hjelpe dumme brukere..
	cmpi.b	#'b',d0
	bne.b	8$
6$	tst.b	(readlinemore,NodeBase)	; er det mere ?
	beq.b	8$			; nei, da tolker vi det som en navn
	jsr	(readline)		; henter bull nr
	beq	9$
8$	move.l	a0,a2			; husker input
	jsr	(atoi)
	bmi.b	7$			; ikke tall
	beq.b	5$
	moveq.l	#0,d1
	move.w	(n_ConfBullets,a3),d1
	cmp.l	d0,d1				; Finnes denne bulletinen ?
	bcs.b	5$				; Nei.
	move.l	d0,d3				; siste bulletin vi leste
	move.w	d2,d1
	lea	(maintmptext,NodeBase),a0
	jsr	(getkonfbulletname)
	lea	(maintmptext,NodeBase),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeall)
;	beq.b					; fix me!
	lea	(maintmptext,NodeBase),a1	; sier ifra til log'en
	lea	(logreadbultext),a0
	jsr	(writelogtexttimed)
	lea	(NormAtttext),a0		; sender ANSI reset.
	jsr	(writetexti)
	bra	1$
5$	lea	(nobullettext),a0
4$	jsr	(writeerroro)
	bra	1$
7$	move.b	(a2),d0
	jsr	(upchar)
	cmp.b	#'L',d0			; List
	beq	3$
	cmp.b	#'D',d0			; download
	beq.b	10$
	cmp.b	#'A',d0
	lea	(invalidcmdtext),a0
	bne.b	4$
	lea	(ymchosebulltext),a0
	move.l	d3,d0
	bmi.b	4$
	move.w	d2,d1
	lea	(maintmptext,NodeBase),a0
	jsr	(getkonfbulletnamenopath)
	lea	(maintmptext,NodeBase),a1
	lea	(80,sp),a0
	jsr	(getholddirfilename)		; finner dest navn
	move.l	d3,d0
	move.w	d2,d1
	lea	(maintmptext,NodeBase),a0
	jsr	(getkonfbulletname)		; finner source navn
	lea	(maintmptext,NodeBase),a0
	jsr	(getbestfilename)		; mekker til .raw osv.
	lea	(80,sp),a1
	jsr	(copyfile)
	lea	doserrortext,a0
	beq.b	4$
	bra	1$

10$	lea	(ymchosebulltext),a0		; tar download bulletin
	move.l	d3,d0
	bmi	4$
	move.w	d2,d1
	lea	(80,sp),a0
	jsr	(getkonfbulletname)		; finner source navn
	lea	(80,sp),a0
	jsr	(getbestfilename)		; mekker til .raw osv.
	lea	(80,sp),a1
	jsr	(strcopy)			; .. og flytter
	lea	(80,sp),a0

	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	bne.b	11$				; no, go ahead

	jsr	(getfullnameusetmp)
	beq	1$				; rydder opp
	move.l	a0,a1
	lea	(80,sp),a0
	jsr	(copyfile)
	lea	(errorsendtext),a0
	beq	4$
	bra.b	12$

11$	jsr	(sendfile)
	bmi	9$				; ut asap.
	lea	(errorsendtext),a0
	beq	4$				; Error
12$	lea	(dlcompletedtext),a0
	jsr	(writetexto)
	bra	1$
99$	lea	(nobulletinstext),a0
	jsr	(writetexto)
9$	move.l	d4,a3
	unlk	a3
	pop	d2/d3/a2/d4
	rts

;#c SH U / SH A
loginshowconferences
	moveq.l	#0,d0
	bra.b	showconferences1
showconferences
	lea	(showconfopttext),a0
	jsr	(readlineprompt)
	bne.b	1$
9$	rts
1$	move.b	(a0),d0
	jsr	(upchar)
	move.b	d0,d1
	moveq.l	#0,d0
	cmpi.b	#'U',d1
	beq.b	showconferences1
;	moveq.l	#1,d0
;	cmpi.b	#'A',d1
	jsr	_ShowConferencesAll
	cmpi.b	#1,d0	; Var det en a?
	beq.b	9$
	lea	(invalidcmdtext),a0
	jsr	(writeerroro)
	beq.b	9$
	bra.b	showconferences
showconferences1	; ALL
	push	d2/d3/d4/d5/d6/d7/a2/a3
	move.w	d0,(tmpstore,NodeBase)		; husker om det er alle konferansene
	moveq.l	#0,d4				; antall konfer med meldinger
	lea	(ansigreentext),a0		; skriver ut header
	jsr	(writetext)
	lea	(confstatustext),a0
	jsr	(writetexti)
	beq	9$
	jsr	(outimage)
	beq	9$
	lea	(confstatustext),a0
	jsr	(strlen)
	subq.l	#1,d0
	lea	(minustext),a0
	jsr	(writetextlen)
	jsr	(outimage)
	beq	9$

	moveq.l	#0,d2				; starter alltid ifra news
	lea	(u_almostendsave+CU,NodeBase),a2
	lea	(n_FirstConference+CStr,MainBase),a3
; JEO JEO
;	move.w	confnr(NodeBase),d2		; konf nr
;	cmp.w	#-1,d2
;	bne.b	2$
;	move.w	d2,d0
;	jsr	(getnextconfnrsub)
;	sub.w	#1,d0
;	add.w	d0,d0				; gjor om til confnr standard
;	move.w	d0,d2
; JEO JEO

2$	move.w	d2,(tmpval,NodeBase)		; husker starten

1$	move.w	(tmpstore,NodeBase),d0		; skal vi skrive div status ?
	beq.b	17$				; nei

	move.w	(n_ConfSW,a3),d0		; er det vip ?
	btst	#CONFSWB_VIP,d0
	beq	13$				; nei
	move.w	(uc_Access,a2),d0
	btst	#ACCB_Read,d0			; Er vi medlem her ?
	beq	8$				; Nei, hopp
	bra	13$
17$	move.w	(uc_Access,a2),d0
	btst	#ACCB_Read,d0			; Er vi medlem her ?
	beq	8$				; Nei, hopp
	move.l	(n_ConfDefaultMsg,a3),d0	; Finner antall nye meldinger
	sub.l	(uc_LastRead,a2),d0
	bpl.b	7$
	moveq.l	#0,d0				; negativt. Feil ... rette opp.
7$	moveq.l	#0,d5				; Antall nye meldinger.
	moveq.l	#0,d7				; Antall til oss.
;	move.l	d2,-(sp)			; lagrer conf nr
	move.l	d0,d3				; husker antall nye meldinger
	beq	6$				; vi hopper over denne "tomme" conf'en
;	add.l	d2,d2				; gjør om til konf nr * 2
	move.l	(uc_LastRead,a2),d6		; Siste leste.

4$	addq.l	#1,d6				; sjekker alle nye meldinger
	subq.l	#1,d3
	bcs.b	6$				; Vi er ferdige
	move.w	d2,d1				; leser inn meldingsheader
	move.l	d6,d0
	lea	(tmpmsgheader,NodeBase),a0
	jsr	(loadmsgheader)
	beq.b	5$
191$	lea	(errloadmsghtext),a0
	jsr	(writeerroro)
;	move.l	(sp)+,d2
	bra	9$
5$	lea	(tmpmsgheader,NodeBase),a0	; kan vi lese denne meldingen ?
	move.w	d2,d0				; henter frem conf nr
	lsr.w	#1,d0
	jsr	(kanskrive)
	bne.b	4$				; nei ...
	addq.l	#1,d5				; øker antallet nye meldinger
	lea	(tmpmsgheader,NodeBase),a0	; er den til oss ?
	move.w	(NrLines,a0),d0			; net message ?
	bpl.b	19$				; Nope
	move.l	a0,a1
	move.w	d2,d0				; henter inn msgtext
	move.l	(tmpmsgmem,NodeBase),a0
	jsr	(loadmsgtext)
	bne.b	191$
	lea	(tmpmsgheader,NodeBase),a0
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	istonetname
	lea	(tmpmsgheader,NodeBase),a0
	bne.b	19$				; ikke net to navn
	bra.b	4$				; det var net to navn, da er den ikke til oss
19$	move.l	(Usernr+CU,NodeBase),d0
	cmp.l	(MsgTo,a0),d0
	bne.b	4$				; nei
	addq.l	#1,d7				; øker antall meldinger til oss
	bra.b	4$
6$ ;	move.l	(sp)+,d2			; konf nr
	tst.l	d5				; var det noen nye meldinger ?
	bne.b	18$				; ja
	move.l	(n_ConfDefaultMsg,a3),(uc_LastRead,a2) ; setter last read til maks
18$	moveq.l	#0,d6				; ingen bulletins (d6 er ledig)
	move.l	d2,d0
	lsr.w	#1,d0
	moveq.l	#1,d1				; Vil bare vite om det er forandret
	jsr	(checkupdatedbulletins)
	beq.b	14$
	moveq.l	#1,d6				; det var noen nye
14$	move.l	d5,d0				; Er det noen meldinger ?
	bne.b	13$				; Ja.
	tst.l	d6				; nye bulletins ?
	beq	8$				; nei, hopper over
13$	lea	(ansilbluetext),a0		; skriver ut conf navn
	jsr	(writetext)
	lea	(n_ConfName,a3),a0
	moveq.l	#Sizeof_NameT,d0
	jsr	(writetextlfill)
	lea	(kolonspacetext),a0
	jsr	(writetext)
	lea	(ansiwhitetext),a0
	jsr	(writetext)
	move.w	(tmpstore,NodeBase),d0		; skal vi skrive div status ?
	beq.b	16$				; nei
	bsr	20$				; skriver div info'en
	beq	9$				; outimage break.
	bra	10$				; neste loop
16$	move.l	d5,d0				; skriver antall nye meldinger
	jsr	(skrivnr)
	lea	(msgunreadtext),a0
	jsr	(writetext)
	tst.l	d5				; div utskrifter for å få
	beq.b	3$				; "fete" meldinger
	tst.l	d7
	beq.b	3$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	cmp.l	d7,d5
	bne.b	11$
	lea	(smallalltext),a0
	jsr	(writetext)
	bra.b	12$
11$	move.l	d7,d0
	jsr	(skrivnr)
12$	lea	(foryoutext),a0
	jsr	(writetext)
3$	move.b	#'.',d0
	jsr	(writechar)
	tst.l	d6			; nye bulletiner ?
	beq.b	15$			; nei.
	lea	(updatedbultext),a0
	jsr	(writetext)
15$	jsr	(outimage)
	beq.b	9$
	tst.l	d7
	bne.b	10$			; Det er noen til oss.
	move.w	(n_ConfSW,a3),d0
	btst	#CONFSWB_PostBox,d0
	beq.b	10$			; Dette er ikke en post conferanse.
	move.w	(uc_Access,a2),d1	; Setter last read til maks i konf'en
	andi.b	#ACCF_Sigop+ACCF_Sysop,d1 ; Hvis vi ikke er sysop da..
	bne.b	10$
	move.l	(n_ConfDefaultMsg,a3),(uc_LastRead,a2)
10$	addq.l	#1,d4			; øker antall konferanser vi har skrevet ut

8$	move.w	d2,d0
	jsr	(getnextconfnrsub)
	subi.w	#1,d0
	add.w	d0,d0			; gjor om til confnr standard
	move.w	d0,d2
	lea	(u_almostendsave+CU,NodeBase),a2
	mulu	#Userconf_seizeof/2,d0
	add.l	d0,a2
	lea	(n_FirstConference+CStr,MainBase),a3
	move.w	d2,d0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	add.l	d0,a3
	cmp.w	(tmpval,NodeBase),d2
	bne	1$

	tst.l	d4			; var det noe ?
	bne.b	9$			; ja
	lea	(ansiwhitetext),a0
	jsr	(writetext)
	lea	(nonewiacmsgtext),a0	; Sier det ikke var noen
	jsr	(writetexto)
9$	pop	d2/d3/d4/d5/d6/d7/a2/a3	; ferdig
	rts

20$	push	d3/d2/d4
	lsr.w	#1,d2
	move.w	(uc_Access,a2),d4
	lea	(Membertext),a0
	btst	#ACCB_Read,d4
	bne.b	21$
	lea	(Nonmembertext),a0
21$	jsr	(writetext)
	move.w	(n_ConfSW,a3),d3
	btst	#ACCB_Write,d4		; har vi read ?
	bne.b	22$			; ja, da er det ikke read only
	btst	#CONFSWB_ImmWrite,d3
	bne.b	22$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(READONLYtext),a0
	jsr	(writetext)
22$	btst	#CONFSWB_PostBox,d3
	beq.b	221$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(Mailtext),a0
	jsr	(writetext)
221$	cmpi.w	#2,d2
	bne.b	23$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(USERINFOtext),a0
	jsr	(writetext)
23$	cmpi.w	#3,d2
	bne.b	24$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(FILEINFOtext),a0
	jsr	(writetext)
24$	btst	#CONFSWB_Private,d3
	beq.b	25$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(Privateallotext),a0
	jsr	(writetext)
25$	btst	#CONFSWB_Resign,d3
	bne.b	251$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(Obligatorytext),a0
	jsr	(writetext)
251$	btst	#CONFSWB_Network,d3
	beq.b	26$
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(Networkconftext),a0
	jsr	(writetext)
26$	move.b	#'.',d0
	jsr	(writechar)
	cmpi.w	#1,d2
	bls.b	27$				; tar ikke post og news
	move.b	(n_ConfBullets,a3),d0		; har denne konfen bulletiner ?
	beq.b	27$				; Nei, hopp
	lea	(Bulletinstext),a0
	jsr	(writetext)
27$	jsr	(outimage)
	pop	d3/d2/d4
	rts

;#c
time	link.w	a3,#-30
	jsr	(updatetime)
	lea	(loginattext),a0
	moveq.l	#17,d0
	jsr	(writetextlfill)
	lea	(LastAccess+CU,NodeBase),a0
	jsr	(timetostring)
	jsr	(writetexti)

	lea	(timenowtext),a0
	moveq.l	#17,d0
	jsr	(writetextlfill)
	move.l	sp,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	sp,a0
	jsr	(timetostring)
	jsr	(writetexto)

	move.w	(TimeLimit+CU,NodeBase),d0
	beq.b	1$
	lea	(timeallowed),a0
	jsr	(writetext)
	move.l	(ds_Minute,sp),d0
	divu	#60,d0
	sub.w	#1,d0
	bcc.b	7$
	move.w	#23,d0
7$	lea	(HourMaxTime+Nodemem,NodeBase),a0
	moveq.l	#0,d1
	move.b	(a0,d0.w),d1
	move.w	(TimeLimit+CU,NodeBase),d0
	cmp.w	#60,d1
	bcc.b	6$				; ingen time limit
	cmp.w	d0,d1				; timelimit,hourlimit
	bcc.b	6$
	move.w	d1,d0				; bruker hourlimit isteden
6$	push	d0
	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetext)

	lea	(timeremaintext),a0
	jsr	(writetext)
	pop	d0
	sub.w	(TimeUsed+CU,NodeBase),d0
	bcc.b	5$
	moveq.l	#0,d0
5$	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)

1$	cmpi.w	#16,(menunr,NodeBase)		; Er vi i File menu ?
	bne.b	2$				; Nei.
	move.w	(FileLimit+CU,NodeBase),d0		; har vi begrensning ?
	beq.b	2$				; nei.
	lea	(ftimelefttext),a0		; Skriver fil tid igjen.
	jsr	(writetext)
	move.w	(FileLimit+CU,NodeBase),d0
	add.w	(minul,NodeBase),d0
	sub.w	(FTimeUsed+CU,NodeBase),d0
	bcc.b	3$
	moveq.l	#0,d0
3$	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetext)

2$	lea	(timeonlinetext),a0		; Skriver tid online.
	jsr	(writetext)
	move.w	(TimeUsed+CU,NodeBase),d0
	add.w	(minchat,NodeBase),d0
	add.w	(minul,NodeBase),d0
	sub.w	(OldTimelimit,NodeBase),d0
	bcc.b	4$
	moveq.l	#0,d0
4$	jsr	(skrivnrw)
	lea	(minutestext),a0
	jsr	(writetexti)
	jsr	(outimage)
	unlk	a3
	rts

;#c
nodemessage
	movem.l	d2/a2,-(a7)
	lea	(nodenrtext),a0
	jsr	(readlineprompt)
	beq	9$
	jsr	(atoi)
	lea	(musthavenrtext),a0
	bmi	3$
	move.l	d0,d2
	beq.b	6$			; node nummer 0 = alle
	cmp.w	(NodeNumber,NodeBase),d0
	bne.b	1$
	lea	(cantsendtoytext),a0
	jsr	(writeerroro)
	bra	9$
1$	move.l	nodelist+LH_HEAD,a2	; Henter pointer til foerste node
	move.l	(LN_SUCC,a2),d0
	beq	9$			; ingen noder. Egentlig umulig men ....
4$	move.w	(Nodenr,a2),d0
	cmp.w	d0,d2			; mottager node ?
	beq.b	5$			; ja
	move.l	(LN_SUCC,a2),a2		; Henter ptr til nestenode
	move.l	(LN_SUCC,a2),d0
	bne.b	4$			; flere noder. Same prosedure as last year
	lea	(unknownnodetext),a0	; fant den ikke. Skriver feil.
	bra	3$
5$	move.w	(Nodestatus,a2),d0	; henter nodestatus'en
	lea	(nactiveusertext),a0
	beq	3$			; ikke aktiv (logged off)
	move.b	(Nodedivstatus,a2),d1	; er det stealth login ?
	btst	#NDSB_Stealth,d1
	bne	3$			; lurer Jon Suphammer
	jsr	justchecksysopaccess
	bne.b	6$			; vi er sysop, kan sende alikevel
	lea	(thusernomsgtext),a0
	move.b	(Nodedivstatus,a2),d1
	andi.b	#NDSF_Notavail,d1
	bne	3$			; Nekte å sende nodemeldinger hvis vi er unavailible
6$	tst.b	(readlinemore,NodeBase)
	bne.b	2$
	lea	(texttext),a0
	jsr	(writetexti)
2$	moveq.l	#78,d0
	jsr	(readlineall)
	beq.b	9$
	move.l	(Tmpusermem,NodeBase),a2
	lea	(i_msg,a2),a1
	jsr	(memcopylen)
	move.b	#0,(a1)			; paranoia
	move.b	#2,(i_type,a2)
	move.w	(NodeNumber,NodeBase),(i_franode,a2)
; fjernet logutskrift siden folk ikke ville ha det..
;	lea	(tmptext,NodeBase),a0			; skriver i log'en
;	move.l	d2,d0
;	jsr	(konverter)
;	lea	(tmptext,NodeBase),a1
;	lea	(logsnodemsgtext),a0
;	jsr	(writelogtexttimed)
	move.b	#0,(i_pri,a2)
	jsr	(justchecksysopaccess)
	beq.b	7$	
	move.b	#1,(i_pri,a2)				; vi er sysop, så denne har prioritet
7$	move.l	a2,a0					; sender meldingen
	move.l	d2,d0
	jsr	(sendintermsg)
	beq.b	9$
	lea	(nactiveusertext),a0
	cmpi.w	#Error_No_Active_User,d1
	beq.b	3$
	lea	(errnodemsgtext),a0
3$	jsr	(writeerroro)
9$	movem.l	(a7)+,d2/a2
	rts

;#e
*****************************************************************
*			main meny				*
*****************************************************************

;#b
;#c
info	lea	(enteruserntext),a0
	moveq.l	#0,d0				; vi godtar ikke all
	moveq.l	#0,d1				; ikke nettnavn
	jsr 	(getnamenrmatch)
	beq	9$
	moveq.l	#-1,d1				; vi godtar ikke all
	cmp.l	d0,d1
	beq	9$
	bsr.b	showinfo
9$	rts

showinfo
	push	a2/d2
	move.l	(Tmpusermem,NodeBase),a2
	move.l	a2,a0
	jsr	(loadusernr)
	bne.b	1$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra	9$
1$	lea	(Timesonsystext),a0	; og skriver ut hvor mange det er.
	bsr	10$
	move.w	(TimesOn,a2),d0
	jsr	(skrivnrw)
	move.l	(LastAccess,a2),d0	; Har brukeren vært her før ?
	beq.b	2$			; Nei, ikke noe lasttime on system ..
	lea	(lasttimeontext),a0	; Skriver ut info om last time info
	bsr	10$
	lea	(LastAccess,a2),a0
	jsr	(writetime)
	jsr	(outimage)
	beq	9$
2$	move.w	(Userbits,a2),d0	; vil han ha adresse osv ?
	andi.w	#USERF_NameAndAdress,d0
	beq.b	3$			; nei
	lea	(addresstext),a0
	bsr	10$
	lea	(Address,a2),a0
	jsr	(writetexto)
	beq.b	9$
	lea	(postalcodetext),a0
	bsr	10$
	lea	(CityState,a2),a0
	jsr	(writetexto)
	beq.b	9$
	lea	(hometlfnumbtext),a0
	bsr	10$
	lea	(HomeTelno,a2),a0
	jsr	(writetexto)
	beq.b	9$
	lea	(worktlfnumbtext),a0
	bsr	10$
	lea	(WorkTelno,a2),a0
	jsr	(writetexto)
	beq.b	9$
	jsr	(outimage)
	beq.b	9$
3$	move.l	(ResymeMsgNr,a2),d0			; msg nr
	beq.b	8$

	move.w	(Userbits+CU,NodeBase),d1
	move.w	d1,d2					; husker
	bclr	#USERB_ClearScreen,d1
	move.w	d1,(Userbits+CU,NodeBase)

	move.w	#4,d1					; userinfo conf
	jsr	(typemsg)
	move.w	d2,(Userbits+CU,NodeBase)
	bra.b	9$
8$	lea	(userlnoinfotext),a0
	jsr	(writetexti)
9$	jsr	(outimage)
	pop	a2/d2
	rts

10$	move.l	a0,-(a7)
	lea	(ansilbluetext),a0
	jsr	(writetext)
	move.l	(a7)+,a0
	moveq.l	#28,d0
	jsr	(writetextlfill)
	lea	(ansiwhitetext),a0
	jmp	(writetexti)

;#c
answerquestionare
	lea	(noquestionatext),a1
	lea	(questinarefname),a0
	bsr	doarexxdoor
	rts

;#c
edit	push	a2
	moveq.l	#48,d0				; Status = Entering resume.
	jsr	(changenodestatus)
	lea	(tmpmsgheader,NodeBase),a2
	lea	(wayaatndisptext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	bne.b	1$				; ja
	tst.b	(readcharstatus,NodeBase)
	bne	9$
	andi.w	#~USERF_NameAndAdress,(Userbits+CU,NodeBase)
	bra.b	2$
1$	ori.w	#USERF_NameAndAdress,(Userbits+CU,NodeBase)
2$	move.l	(ResymeMsgNr+CU,NodeBase),d0		; har vi skrevet før ?
	beq.b	5$
	move.l	a2,a0
	move.w	#4,d1					; userinfo conf
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	7$
	move.b	#MSTATF_KilledByAuthor,(MsgStatus,a2)
	move.l	a2,a0
	move.w	#4,d0					; userinfo conf
	jsr	(savemsgheader)
	beq.b	6$
	lea	(cntsavemsghtext),a0
7$	jsr	(writeerrori)
	bra.b	9$
6$	move.w	(Userbits+CU,NodeBase),d0			; bare FSE har include.
	andi.w	#USERF_FSE,d0				; Brukrer vi FSE ???
	beq.b	5$					; Nei, ingen include
	move.l	a2,a1
	move.l	(tmpmsgmem,NodeBase),a0
	move.w	#4,d0					; userinfo conf
	jsr	(loadmsgtext)
	lea	(errloadmsgttext),a0
	bne.b	7$
	move.b	#2,(FSEditor,NodeBase)			; Vi skal includere.
5$	move.w	#4,d0					; userinfo conf
	bsr	comentditsamecode
	beq.b	3$					; abort'a, carrier borte osv
	move.l	(Number,a2),d0
	bra.b	4$
3$	moveq.l	#0,d0
4$	lea	(ResymeMsgNr+CU,NodeBase),a0
	move.l	d0,(a0)					; fyller i resyme msg nr'et
	moveq.l	#4,d0					; saver 4 bytes
	lea	(Userbits+CU,NodeBase),a1
	moveq.l	#2,d1					; saver 2 bytes
	jsr	(saveuserareas)
9$	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
	pop	a2
	rts

;#c
; Vi har alltid lov til å skrive en kommentar
comment
	jsr	GetCommentUserNr
	cmp.l	#-1,d0
	beq.b	9$
	move.l	d0,d1
	move.w	#2,d0
	bra comentditsamecode
9$	rts

; d0 = conf nr
; d1 = to user (for comment)
comentditsamecode
	push	a2/a3/d2/d3/d4
	move.l	d0,d2				; husker conf nr dette skal i
	move.l	d1,d4				; husker to user (hvis comment)
	move.l	a0,a3
	moveq.l	#12,d0				; Status = enter msg.
	jsr	(changenodestatus)
	move.w	(confnr,NodeBase),d3		; husker gammel confnr
	move.w	d2,(confnr,NodeBase)		; ny konf
	lea	(tmpmsgheader,NodeBase),a2	; fyller i msg header'en
	move.w	(confnr,NodeBase),d1
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d1
	move.l	(n_ConfDefaultMsg,a0,d1.l),d0
	addq.w	#1,d0
	move.l	d0,(Number,a2)
	moveq.l	#0,d0
	move.l	d0,(RefTo,a2)
	move.l	d0,(RefBy,a2)
	move.l	d0,(RefNxt,a2)
	move.l	(Usernr+CU,NodeBase),(MsgFrom,a2)
	move.b	#MSTATF_NormalMsg,(MsgStatus,a2)
	cmpi.w	#2,d2				; er det en comment ?
	bne.b	1$				; nei
	move.b	#SECF_SecReceiver,(Security,a2)	; setter opp for comment
	move.l	d4,(MsgTo,a2)
	lea	(commenttext),a0
	move.b	(userok,NodeBase),d0
	bne.b	11$
	lea	(failedpaswdtext),a0
11$	moveq.l	#30,d0
	lea	(Subject,a2),a1
	jsr	(strcopymaxlen)
	bra	2$
1$	cmpi.w	#4,d2				; er det en userinfo ?
	bne.b	3$				; nei
	move.b	#SECF_SecNone,(Security,a2)	; setter opp for resyme
	moveq.l	#-1,d0
	move.l	d0,(MsgTo,a2)			; til alle
	lea	(Name+CU,NodeBase),a0		; subject = navnet
	moveq.l	#30,d0
	lea	(Subject,a2),a1
	jsr	(strcopymaxlen)
	bra	2$
3$	lea	(Subject,a2),a1			; skriver : TEST.TES (3,926b)
	move.l	a3,a0
	bsr	fillinfileinfosubject
	move.b	#SECF_SecNone,(Security,a2)	; setter opp for public ul,ikke pu
	moveq.l	#-1,d0
	move.l	d0,(MsgTo,a2)			; til alle
	move.l	(PrivateULto,a3),d1
	move.w	(Filestatus,a3),d0
	btst	#FILESTATUSB_PrivateUL,d0
	beq.b	4$
	move.l	d1,(MsgTo,a2)			; til en person
	move.b	#SECF_SecReceiver,(Security,a2)	; privat til han
	bra.b	2$
4$	btst	#FILESTATUSB_PrivateConfUL,d0
	beq.b	2$
	move.w	d1,(confnr,NodeBase)		; ny konf
2$	lea	(MsgTimeStamp,a2),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	a2,a0
	move.l	(msgmemsize,NodeBase),d0
	move.l	(tmpmsgmem,NodeBase),a1
	move.l	a1,d1
	jsr	(calleditor)
	beq.b	8$
	move.l	a2,a1
	move.w	(confnr,NodeBase),d0
	jsr	(savemsg)
	beq.b	7$
	lea	(cnotsavemsgtext),a0
	jsr	(writeerrori)
	bra.b	99$
7$	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	(Number,a2),d0
	jsr	(skrivnr)
	lea	(savedtext),a0
	jsr	(writetexto)
	addq.w	#1,(MsgsLeft+CU,NodeBase)
	move.l	(Number,a2),d0
	bsr	stopreviewmessages
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(sendintermsgmsg)
	cmpi.w	#2,d2				; er det en comment ?
	bne.b	9$				; nei, da er vi ferdige
	move.l	(Number,a2),d1
	lea	(logleftcomment),a0
	move.w	(confnr,NodeBase),d0		; conf nr
	jsr	(killrepwritelog)
	bra.b	9$
8$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	99$
	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	(Number,a2),d0
	jsr	(skrivnr)
	lea	(abortedtext),a0
	jsr	(writetexto)
99$	bsr.b	10$
999$	pop	a2/a3/d2/d3/d4
	rts
9$	bsr.b	10$
	clrz
	bra.b	999$

10$	move.b	(userok,NodeBase),d0
	beq.b	19$
	move.w	d3,(confnr,NodeBase)
	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
	setz
19$	rts

; a0 = fileinfo
; a1 = string to place subject in
fillinfileinfosubject
	push	a2/d2
	link.w	a3,#-30
	move.l	a0,a2
	lea	(Filename,a2),a0
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	move.b	#'(',(a1)+
	move.l	a1,d2
	move.l	sp,a0
	move.l	(Fsize,a2),d0
	jsr	(konverter)
	move.l	sp,a0
	move.l	d2,a1
6$	move.b	(a0)+,(a1)+
	beq.b	5$
	subi.w	#1,d0
	cmpi.w	#3,d0
	bne.b	6$
	move.b	#'.',(a1)+
	bra.b	6$
;d0 = lengden
5$	move.b	#'b',(-1,a1)
	move.b	#')',(a1)+
	move.b	#0,(a1)
	unlk	a3
	pop	a2/d2
	rts

;#e
*****************************************************************
*			Search menu				*
*****************************************************************

;#b
;#c
searchgroup
	push	d2/d3/d4/a2
	jsr	(groupheaderscommon)
	beq.b	9$
	moveq.l	#0,d4				; antall meldinger funnet
1$	move.l	d3,d0
	bsr	searchmessage
	bmi.b	2$				; error
	beq.b	3$				; Fant ikke i denne
	move.l	d3,d0
	jsr	(insertinqueuenr)
	addq.l	#1,d4
3$	addq.l	#1,d3
	cmp.l	d3,d2
	bcc.b	1$
2$	jsr	(groupheaderscommon2)
9$	pop	d2/d3/d4/a2
	bra	readmenu			; Hopper til read meny.

;#c
searchheaders
	push	d2/d3/d4/a2
	jsr	(groupheaderscommon)
	beq.b	9$
	moveq.l	#0,d4				; antall meldinger funnet
1$	move.l	d3,d0
	bsr	searchheader
	bmi.b	2$				; error
	beq.b	3$				; Fant ikke i denne
	move.l	d3,d0
	jsr	(insertinqueuenr)
	addq.l	#1,d4
3$	addq.l	#1,d3
	cmp.l	d3,d2
	bcc.b	1$
2$	jsr	(groupheaderscommon2)
9$	pop	d2/d3/d4/a2
	bra	readmenu			; Hopper til read meny.

;#c
searchmarked
	push	a2/a3
	lea	(texttsearchtext),a0
	lea	(nulltext),a1
	moveq.l	#30,d0
	jsr	(mayedlinepromptfull)
	beq.b	9$
	move.l	a0,a2
	lea	(searchmsgtext),a0
	jsr	(writetext)
	lea	(fortext+1),a0
	jsr	(writetext)
	move.l	a2,a0
	jsr	(writetext)
	move.b	#'.',d0
	jsr	(writechar)
	jsr	(outimage)
	beq.b	9$
	lea	(msgqueue,NodeBase),a3
1$	move.l	(a3)+,d0
	beq.b	2$				; ferdig
	bsr	searchmessage
	bmi.b	2$				; error
	bne.b	1$				; Fant teksten i denne
	lea	(-4,a3),a3
	move.l	(a3),d0
	jsr	(removefromqueue)
	bra.b	1$

2$	move.b	#'<',d0
	jsr	(writechar)
	jsr	(findnumberinque)
	jsr	(skrivnr)
	move.b	#'>',d0
	jsr	(writechar)
	lea	(msgstilmarktext),a0
	jsr	(writetexto)
9$	pop	a2/a3
	bra	readmenu			; Hopper til read meny.

; d0 = message nr
; a2 = text
; retur : z = ikke funnet, n = error
searchmessage
	push	a3/d2/d3
	moveq.l	#0,d3				; har ikke funnet noe enda
	lea	(tmpmsgheader,NodeBase),a1
	move.l	(tmpmsgmem,NodeBase),a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsg)
	lea	(errloadmsgttext),a0
	bne.b	8$
	lea	(tmpmsgheader,NodeBase),a0
	move.w	(confnr,NodeBase),d0
	jsr	(kanskrive)			; Kan vi skrive ut denne ???
	clrn
	notz
	beq	9$				; Nei. "Jump, for my love"

	move.l	(tmpmsgmem,NodeBase),a0
	moveq.l	#0,d0
	move.w	(NrBytes+tmpmsgheader,NodeBase),d0
	move.b	#0,(0,a0,d0.w)			; terminerer med en null
	jsr	(skipnetnames)

0$	move.l	a0,a3				; husker starten på linja
1$	move.b	(a0)+,d0
	beq.b	2$				; ferdig, (siste linje)
	cmpi.b	#10,d0				; leter etter NL
	bne.b	1$
	move.b	#0,(-1,a0)			; terminerer
	move.l	a0,d2				; husker hvor vi var
	move.l	a3,a0
	move.l	a2,a1
	jsr	(findtextinstring)
	bne.b	3$
	bsr	10$
	bmi.b	9$
3$	move.l	d2,a0
	bra.b	0$				; søker videre

2$	move.l	a3,a0
	move.l	a2,a1
	jsr	(findtextinstring)
	bne.b	4$
	bsr	10$
	bmi.b	9$
4$	move.l	d3,d0
	bra.b	9$
8$	jsr	(writeerroro)
	setn
9$	pop	a3/d2/d3
	rts

10$	move.b	#'#',d0
	jsr	(writechar)
	move.l	(Number+tmpmsgheader,NodeBase),d0
	jsr	(skrivnr)
	lea	(kolonspacetext),a0
	jsr	(writetext)
	move.l	a3,a0
	jsr	(writetexto)
	bne.b	11$
	setn
	rts
11$	moveq.l	#1,d3				; vi fant teksten
	rts

; d0 = message nr
; a2 = text
; retur : z = ikke funnet, n = error
searchheader
	push	a3
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a3,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	jsr	(kanskrive)			; Kan vi skrive ut denne ???
	clrn
	notz
	beq	9$				; Nei. "Jump, for my love"
	move.l	a3,a0
	jsr	(doisnetmessage)		; er det nettmelding ?
	bne.b	2$				; Nei, ikke melding
	move.l	(tmpmsgmem,NodeBase),a0		; det er nettmelding, så da
	move.l	a3,a1				; må vi hente inn texten
	move.w	(confnr,NodeBase),d0
	jsr	(loadmsgtext)
	lea	(errloadmsgttext),a0
	bne	8$
2$	move.l	a3,a0
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	(getfromname)
	lea	(tmptext2,NodeBase),a1
	jsr	(strcopy)
	move.l	a3,a0
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	(gettoname)
	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	lea	(tmptext2,NodeBase),a0
	move.l	a2,a1
	jsr	(findtextinstring)
	beq.b	1$
	lea	(maintmptext,NodeBase),a0
	move.l	a2,a1
	jsr	(findtextinstring)
	beq.b	1$
	move.l	a3,a0
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	(getsubject)
	move.l	a0,a3				; husker subject
	jsr	(convertfirstnltoend)
	move.l	a2,a1
	jsr	(findtextinstring)
	notz
	beq.b	9$
1$	move.b	#'#',d0
	jsr	(writechar)
	move.l	(Number+tmpmsgheader,NodeBase),d0
	jsr	(skrivnr)
	lea	(kommaspacetext),a0
	jsr	(writetext)
	lea	(tmptext2,NodeBase),a0
	jsr	(writetext)
	lea	(tonoansitext),a0
	jsr	(writetext)
	lea	(maintmptext,NodeBase),a0
	jsr	(writetext)
	lea	(rekolontext),a0
	jsr	(writetext)
	move.l	a3,a0
	jsr	(writetext)
	move.b	#'.',d0
	jsr	(writechar)
	jsr	(outimage)
	bne.b	9$
	setn
	bra.b	9$
8$	jsr	(writeerroro)
	setn
9$	pop	a3
	rts
;#e

*****************************************************************
*			Chat menu				*
*****************************************************************

;#b
;#c
SetchatAvail
	move.l	(nodenoden,NodeBase),a0
	andi.b	#~NDSF_Notavail,(Nodedivstatus,a0) ; Slår av ikke avail flagget
	bra	mainmenu			; Hopper til main meny.	rts

;#c
SetchatNAvail
	move.l	(nodenoden,NodeBase),a0
	ori.b	#NDSF_Notavail,(Nodedivstatus,a0) ; Slår på ikke avail flagget
	bra	mainmenu			; Hopper til main meny.	rts

;#c
Chatsysop
	push	d2
	lea	(pagedsysoptext),a0		; Skriver i log'en at han paga sysop
	jsr	(writelogtexttime)
	move.w	(MainBits,MainBase),d0
	andi.w	#MainBitsF_SysopNotAvail,d0
	bne	8$
	lea	(pagngsysop2text),a0
	jsr	(writetexti)
	moveq.l	#28,d0				; Status = paging sysop.
	jsr	(changenodestatus)
	lea	pagescriptname,a0		; Har vi pagescript ?
	jsr	(getfilelen)
	beq.b	1$				; nope, tar vanelig chat
	lea	pagescriptname,a0		; Kjører Arexx scriptet.
	lea	(erropendoortext),a1
	jsr	(doarexxdoor)
	bra	9$				; ferdig med chat request.
1$	moveq.l	#21,d2

2$	subq.l	#1,d2
	beq.b	7$				; timeout
	move.b	#'.',d0				; skriver ut dot
	jsr	(writechari)
	suba.l	a0,a0
	move.l	(intbase),a6
	jsrlib	DisplayBeep
	move.l	(exebase),a6
	jsr	(stoptimeouttimer)
	moveq.l	#1,d0
	jsr	(starttimeouttimersec)
4$	jsr	(readchar)
	bne.b	3$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$				; hopper ut hvis vi fikk no carrier
	move.l	(nodenoden,NodeBase),a0
	move.w	(Nodestatus,a0),d1		; Sjekker om vi har blitt active
	cmpi.w	#4,d1				; 
	beq.b	9$				; Det var vi, da er chat ferdig.
	bra.b	2$				; Var timeout. Looper
3$	cmpi.b	#24,d0				; CTRL-X ??
	beq	5$				; Ja, ut
;	cmpi.b	#3,d0				; CTRL-C ?? (CTRL-C fungerer ikke)
;	beq.b	4$				; Nei, venter videre på timeout
5$	jsr	(outimage)
	bra.b	9$

7$	move.l	(msg,NodeBase),a1		; setter sysop not avail
	move.w	#Main_NotAvailSysop,(m_Command,a1)
	moveq.l	#0,d0
	move.l	d0,(m_Data,a1)			; sysop er ikke avail
	jsr	(handlemsg)			; ingen error fra denne
8$	lea	(sysopnavailtext),a0
	jsr	(writetexto)
9$	moveq.l	#4,d0				; Status = active.
	jsr	(changenodestatus)
	pop	d2
	bra	mainmenu			; Hopper til main meny.

;#c
; kalles fra handleintuition/handlemenu 
sysopchat
	move.l	(intbase),a6		; finner menyitem adr
	move.l	(node_menu,NodeBase),a0
	jsrlib	ItemAddress
	move.l	(exebase),a6
	tst.l	d0
	beq	9$			; egetlig umulig, men ...
	move.l	d0,a0
	move.w	(mi_Flags,a0),d0
	andi.w	#CHECKED,d0
	beq	8$			; vi skal avslutte
	move.b	(activesysopchat,NodeBase),d0
	bne	8$			; Vi skal vel avslutte alikevel da..

	move.l	(nodenoden,NodeBase),a0
	move.w	(Nodestatus,a0),d1	; Sjekker om noden er klar
	cmpi.w	#28,d1			; har vi paget ?
	beq.b	2$
	cmpi.w	#0,d1			; logoff'a ?
	bne.b	5$			; nei
	move.l	(Name+CU,NodeBase),d0	; har han skrevet navnet ?
	beq	77$			; nei. Ikke mulig
	bra.b	2$
5$	cmpi.w	#4,d1			; er bruker active ?
	bne	77$			; nei ...
2$	lea	(tmptext2,NodeBase),a1
	lea	(schatfilenameo),a0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	move.l	(dosbase),a6
	lea	(tmpmsgheader,NodeBase),a0
	move.l	a0,d1			; husker når vi startet
	jsrlib	DateStamp
	lea	(tmptext2,NodeBase),a0
	jsr	(openreadseekend)
	move.l	(exebase),a6
	bne.b	6$
	moveq.l	#-1,d0
6$	move.l	d0,(tmpstore,NodeBase)
	lea	(logchatedtext),a0
	lea	(tmptext2,NodeBase),a1
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	lea	(Name+CU,NodeBase),a0
	jsr	(strcopy)
	lea	(tmptext2,NodeBase),a0
	push	d2/d3
	move.l	a0,d2
	jsr	(strlen)
	move.l	d0,d3
	bsr	chatfilewrite
	pop	d2/d3

	move.b	#1,(activesysopchat,NodeBase)
	move.w	#-1,(tmpval,NodeBase)		; nulstiller farven
	move.l	(nodenoden,NodeBase),a0
	moveq.l	#0,d0
	move.w	(Nodestatus,a0),d0		; Sjekker om noden er klar
	move.l	d0,-(a7)
	move.w	#44,d0				; nodestatus = Chatting with Sysop
	jsr	(changenodestatus)
	lea	(sysoponlinetext),a0
	jsr	(getfilelen)
	beq.b	234$
	lea	(sysoponlinetext),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeall)
	bra.b	235$
234$	lea	(sysopiscomitext),a0
	jsr	(writetexto)
235$	push	d7/a2/d2
	lea	(tmptext,NodeBase),a2
	moveq.l	#0,d7

1$	jsr	(readchar)			; må tåle CTRL-X. FIX ME
	beq.b	7$
	bmi	10$

	move.b	d0,d2				; husker tegnet
;	cmpi.b	#13,d0				; Carrige return?
;	bne.b	99$				; Nei!
;	move.l	(intbase),a6
;	jsrlib	DisplayBeep

	move.w	#ansilblue,d0			; ekstern farve
	cmp.b	#2,(tegn_fra,NodeBase)		; Siste tegnet fra ser. ?
	beq.b	101$				; ja, bruker farve 2
	move.w	#ansiyellow,d0			; Lokal farve
101$	bsr	20$				; setter farven, hvis det trengs
	move.b	d2,d0				; henter tilbake tegnet
	cmpi.b	#13,d0
	bne.b	4$
	move.b	#10,d0
4$	moveq.l	#1,d1				; vi kommer ifra sysop chat, og vil ha fil
	bsr	writechatchar
	bra.b	1$

7$	pop	d7/a2/d2
	move.l	(a7)+,d0			; setter tilbake til gammel status
	cmp.w	#28,d0				; var det paging for sysop ?
	bne.b	777$				; nope
	moveq.l	#4,d0				; Gjør det om til active
	jsr	(changenodestatus)
	jsr	(remsysopcheckmark)
	bra	3$				; Vi skal returnere negativ... (For å komme helt ut)
777$	jsr	(changenodestatus)
77$	jsr	(remsysopcheckmark)
	clrn
	bra	9$

8$	move.b	#0,(activesysopchat,NodeBase)
	move.l	(tmpstore,NodeBase),d1		; har vi vært igjennom her før ?
	beq	9$				; nei. Rart...
	moveq.l	#-1,d0				; er det noen fil her da ?
	cmp.l	d0,d1
	beq.b	81$				; nei..
	lea	(tmptext,NodeBase),a0
	push	d2/d3
	move.l	a0,d2
	move.l	d7,d3
	bsr	chatfilewrite
	pop	d2/d3
	beq.b	81$
	move.l	(dosbase),a6
	move.l	(tmpstore,NodeBase),d1
	jsrlib	Close				; stenger den
	lea	(ds_SIZEOF+tmpmsgheader,NodeBase),a0
	move.l	a0,d1				; husker når vi startet
	jsrlib	DateStamp
	lea	(tmpmsgheader,NodeBase),a0
	lea	(ds_SIZEOF,a0),a1
	jsr	(calcmins)
	add.w	d0,(minchat,NodeBase)		; trekker ifra for chat
	move.l	(exebase),a6
81$	moveq.l	#0,d0
	move.l	d0,(tmpstore,NodeBase)		; sletter
	lea	(sysopoflinetext),a0
	jsr	(getfilelen)
	beq.b	2344$
	lea	(sysopoflinetext),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeall)
	bra.b	2355$
2344$	lea	(sysopisgointext),a0
	jsr	(writetexto)
2355$	jsr	(checkintermsgs)
	beq.b	31$
	jsr	(outimage)
31$	move.l	(curprompt,NodeBase),d0
	beq.b	3$
	move.l	d0,a0
	jsr	(writetexti)
	lea	(intextbuffer,NodeBase),a0	; oppdatere de vi har skrevet ...
	jsr	(writetexti)
3$	setn
9$	setz
	rts					;hopper tilbake til den som kallte oss

10$	cmpi.b	#1,(tegn_fra,NodeBase)		; var dette ifra console ?
	bne	1$				; nei
	cmpi.b	#10,d0
	bcc	1$
	andi.l	#$ff,d0
	lsl.l	#2,d0
	lea	(keys,MainBase),a0
	adda.l	d0,a0
	move.l	(a0),d0
	beq	1$
	move.l	a2,-(a7)
	move.l	d0,a2
	move.w	#ansiyellow,d0			; Lokal farve
	bsr	20$				; setter farven, hvis det trengs
11$	move.b	(a2)+,d0
	beq.b	19$
	moveq.l	#1,d1				; vi kommer ifra sysop chat, og vil ha fil
	bsr	writechatchar
	bra.b	11$
19$	move.l	(a7)+,a2
	bra	1$

20$	cmp.w	(tmpval,NodeBase),d0		; samme farve som vi har ?
	beq.b	29$				; ja
	move.w	d0,(tmpval,NodeBase)		; husker at vi har bytta
	move.w	(Userbits+CU,NodeBase),d1	; vil brukeren ha farver ?
	andi.w	#USERF_ColorMessages,d1
	beq.b	29$				; nei
	lea	(ansicolors),a0
	lea	(0,a0,d0.w),a0
	jsr	(writetexti)
29$	rts

;#c
Groupchat
	lea	(nodenrtext),a0
	jsr	(readlineprompt)
	beq	9$
	jsr	(atoi)
	lea	(musthavenrtext),a0
	bmi	8$
	lea	(nodenodebtntext),a0
	tst.w	d0
	beq.b	8$
	moveq.l	#0,d1			; vi skal ha group chat
	bsr	nodechat1
	bra.b	9$
8$	jsr	(writeerroro)
9$	rts

; # number of node to chat with
chatmenunotchoices
	jsr	(inputnr)
	bne.b	1$
	setn				; Ikke noe tall
	rts
1$	moveq.l	#1,d1			; ikke group (privat)
nodechat1
	push	d2/a2/d3/d4		; Her begynner node chat *OBS* 2 pop'er av denne (ikke en rts)!!!
	moveq.l	#0,d3			; Ikke group chat (bit 31), har oppdatert
	tst.l	d1			; nodestatus (bit 30), privat (bit 29)
	beq.b	1$
	bset	#29,d3			; dette er en privat chat
1$	moveq.l	#0,d4			; ikke noen første chat struct enda
	move.b	#1,(FSEditor,NodeBase)	; slår av dekoding av tastene
	move.l	d0,d2
	cmp.w	(NodeNumber,NodeBase),d0	; er det til oss ??
	lea	(cantsendtoytext),a0
	beq	10$
	move.l	nodelist+LH_HEAD,a1	; finner noden vi skal chat'e med
	move.l	(LN_SUCC,a1),d1
	beq.b	21$			; ingen noder. Egentlig umulig, men ..
2$	cmp.w	(Nodenr,a1),d2
	beq.b	3$			; fant den
	move.l	(LN_SUCC,a1),a1
	move.l	(LN_SUCC,a1),d0
	bne.b	2$
21$	lea	(nodenodebtntext),a0	; fant ikke
	bra	10$
3$
	move.b	(Nodedivstatus,a1),d0	; Vil han ha chat requests ?
	andi.b	#NDSF_Notavail,d0
	lea	(nodencafchatext),a0
	bne	10$			; nei
	move.w	(Nodestatus,a1),d0	; Sjekker om noden er klar
	cmpi.w	#8,d0			; group chat (har chat'er allerede)
	bne	1031$
	bset	#31,d3			; husker at det er group chat
	bclr	#29,d3			; og da er det ikke privat lenger..
	bra.b	1032$
1031$	lea	(nodencafchatext),a0
	move.b	(Nodedivstatus,a1),d1	; er det stealth login ?
	btst	#NDSB_Stealth,d1
	bne	10$			; ja, ikke tilgjengelig
	cmpi.w	#4,d0			; aktiv ?
	bne	10$			; nei, nekter
	move.l	(Nodespeed,a1),d0	; lokal node ?
	bne.b	1032$			; nope
	move.l	(Nodeusernr,a1),d0	; henter brukernumeret
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0; sysop ?
	bne.b	1032$			; nope
	btst	#NDSB_WaitforChatCon,d1	; venter sysop på chat req ?
	bne.b	1032$			; ja, da godtar vi chat..
	pop	d2/a2/d3/d4
	move.b	#0,(FSEditor,NodeBase)
	bra	Chatsysop

1032$	move.l	(nodenoden,NodeBase),a0
	move.b	(Nodedivstatus,a0),d0
	andi.b	#~NDSF_Notavail,d0	; Slår av ikke avail flagget
	or.b	#NDSF_WaitforChatCon,d0	; Slår på waitfor con..
	move.b	d0,(Nodedivstatus,a0)
	bsr	20$			; setup av data strukturer

11$	lea	(tmptext,NodeBase),a0
	move.b	#4,(i_type,a0)		; chat request melding
	move.l	a2,(i_usernr,a0)
	lea	(chatnodes,a2),a1
	move.w	#MaxUsersGChat-1,d3
5$	move.l	(c_Task,a1),d1			; leter etter ledig plass
	beq.b	51$				; fant
	lea	(chatnode_sizeof,a1),a1		; peker til neste
	subi.w	#1,d3				; er det flere å lete i ?
	bne.b	5$				; ja, leter videre
	lea	(grpchatfulltext),a0		; error, fullt (egentlig umulig her)
	bra	10$				
51$	neg.w	d3
	addi.w	#MaxUsersGChat-1,d3		; har "node nummeret"
	move.l	a1,(i_usernr2,a0)
	move.w	(NodeNumber,NodeBase),(i_franode,a0)
	lea	(i_Name,a0),a1			; fyller i navnet.
	lea	(Name+CU,NodeBase),a0
	jsr	(strcopy)
	move.l	d2,d0
	lea	(tmptext,NodeBase),a0
	move.b	#0,(i_pri,a0)
	moveq.l	#0,d1
	btst	#29,d3			; er dette er en privat chat
	beq.b	52$			; nei
	moveq.l	#1,d1
52$	move.w	d1,(i_conf,a0)
	jsr	(sendintermsg)
	beq.b	4$			; alt ok
	lea	(nactiveusertext),a0	; skriver feilmeldingen
	cmpi.w	#Error_No_Active_User,d1
	beq	10$
	lea	(errnodemsgtext),a0
	bra	10$
4$	lea	(wafontreplytext),a0	; venter på svar
	jsr	(writetext)
	move.w	d2,d0
	bsr	30$
	beq	9$			; error, ut
	btst	#30,d3			; vært her før ?
	bne.b	041$
	move.l	a0,-(a7)
	move.w	#8,d0			; nodestatus = Chatting
	btst	#29,d3			; skal det være privat chat ?
	beq.b	043$			; Nope
	move.w	(i_conf,a0),d1		; var det privat i andre enden ?
	beq.b	43$			; nei
	move.w	#60,d0			; nodestatus = Chatting private
043$	jsr	(changenodestatus)
	move.l	(nodenoden,NodeBase),a0
	andi.b	#~NDSF_WaitforChatCon,(Nodedivstatus,a0)	; Slår av waitfor con..
	move.l	(a7)+,a0
	bset	#30,d3			; har vært her.
041$	lea	(localchatnodes,a2),a1	; Fyller i vår lokalchatnode
	move.w	d3,d0
	mulu.w	#localchatnode_sizeof,d0
	adda.l	d0,a1			; har nå funnet riktig localchat node
	move.l	(i_usernr,a0),(l_chat,a1)
	tst.l	d4			; har vi allerede en chat struct ?
	bne.b	042$			; jepp
	move.l	(i_usernr,a0),d4		; nei, husker denne
042$	move.l	(i_usernr2,a0),a0	; henter frem vår chat node
	move.l	a0,(l_chatnode,a1)
	bne.b	104$
	lea	(grpchatfulltext),a0	; error, fullt
	bra	10$
104$	bsr	fillinchatnode
	moveq.l	#5,d6			; har en timeout på 5 sek
	move.l	(c_Task+chatnodes,a2),d0	; Er den andre noden ferdig ?
	bne.b	7$			; Ja, da er vi ferdig
	lea	(tmptext,NodeBase),a0	; sender en gang til
	move.b	#4,(i_type,a0)		; chat request melding
	move.l	a2,(i_usernr,a0)
	lea	(chatnodes,a2),a1
	move.l	a1,(i_usernr2,a0)
	move.w	(NodeNumber,NodeBase),(i_franode,a0)
	move.l	d2,d0
	move.b	#0,(i_pri,a0)
	jsr	(sendintermsg)
6$	move.l	(c_Task+chatnodes,a2),d0	; Venter på at den andre noden
	bne.b	7$
	moveq.l	#1,d0			; venter 1 sek
	jsr	(waitsecs)
	bra.b	6$

7$	move.l	d4,a0			; den første chat struct'en
	lea	(chatnodes,a0),a0
	moveq.l	#MaxUsersGChat-1,d2
071$	move.l	(c_Task,a0),d0		; er denne i bruk ?
	beq.b	072$			; nei
	moveq.l	#0,d0
	move.w	(c_Nodenr,a0),d0		; henter node nummeret

	lea	(chatnodes,a2),a1	; henter vår chatnodes
	moveq.l	#MaxUsersGChat-1,d1	; indre loop teller
074$	tst.l	(c_Task,a1)		; er denne i bruk ?
	beq.b	073$			; nei
	cmp.w	(c_Nodenr,a1),d0		; Har vi node nummeret ?
	beq.b	072$			; ja, bryter innerste loop
073$	lea	(chatnode_sizeof,a1),a1	; peker til neste
	subq.l	#1,d1			; ferdig ?
	bne.b	074$			; nei

	cmp.w	(NodeNumber,NodeBase),d0	; var det vår egen node ?
	beq.b	072$			; ja, da tar vi ikke den.
	move.l	d0,d2			; denne er ikke tatt enda
	bra	11$

072$	lea	(chatnode_sizeof,a0),a0	; peker til neste
	subq.l	#1,d2			; ferdig ?
	bne.b	071$			; nei

	move.l	a2,a0
	bsr	donodechat
	bra.b	9$

10$	jsr	(writeerror)
9$	jsr	(outimage)
	move.b	#0,(FSEditor,NodeBase)
	move.l	(nodenoden,NodeBase),a0
	andi.b	#~NDSF_WaitforChatCon,(Nodedivstatus,a0)	; Slår av waitfor con..
	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
	pop	d2/a2/d3/d4
	clrzn
	rts

20$	move.l	(tmpmsgmem,NodeBase),a2	; brukker dette som data område.
	move.l	a2,a0			; nullstiller alt
	move.w	#chat_sizeof,d0
	jsr	(memclr)
	move.l	a2,a0
	moveq.l	#0,d0
	move.w	#chat_sizeof,d0
	adda.l	d0,a0			; chat struktur først, så meldingsområdet
	move.l	a0,(msgarea,a2)
	move.l	(msgmemsize,NodeBase),d1
	sub.l	d0,d1
	adda.l	d1,a0
	move.l	a0,(msgareaend,a2)
;	move.w	#0,(Wpos,a2)		; unødvendig.
	move.w	(NodeNumber,NodeBase),(ChatNodeNr,a2)
	rts

; d0 = node nr og vente på
; Venter på nodeconnect. returnerer z=1 hvis timeout
30$	push	a2/a3/d2-d7
	move.w	d0,d7				; noden vi skal vente paa
	moveq.l	#20,d6				; timeout på 20 sek
31$	move.b	#'.',d0				; skriver ut dot
	jsr	(writechari)
	moveq.l	#1,d0				; venter 1 sek
	jsr	(waitsecs)
	moveq.l	#0,d0				; sjekker signaler
	move.l	d0,d1
	jsrlib	SetSignal
	move.l	d0,d1
	and.l	(intersigbit,NodeBase),d1
	beq	37$				; ikke noe inter sig bit
	jsrlib	Forbid
	move.l	(nodenoden,NodeBase),a0
	move.w	(InterMsgread,a0),d0
	move.w	(InterMsgwrite,a0),d1
	jsrlib	Permit
	sub.w	d0,d1
	beq	38$				; ingen node meldinger.
	bcc.b	34$				; ingen wrap
	addi.w	#MaxInterNodeMsg,d1
34$	bclr	#31,d6				; vi har ikke funnet noe enda
	move.l	d0,d2				; d2 - startpos
	move.l	d1,d3				; d3 - antall meldinger
	move.l	a0,a2
	jsr	(outimage)			; nl
	lea	(InterNodeMsg,a2),a3		; leter etter vår nodemelding
	moveq.l	#InterNodeMsgsiz,d4
	move.l	d2,d5
	mulu.w	d4,d5
	subq.l	#1,d3
35$	lea	(0,a3,d5.w),a0
	move.b	(i_type,a0),d0			; Sjekker typen
	cmpi.b	#4,d0				; chat request ?
	bne.b	351$				; nei.
	cmp.w	(i_franode,a0),d7
	bne.b	351$
	bset	#31,d6				; vi fant riktig chat request
	moveq.l	#0,d3				; avslutter loop'en
	bra.b	352$
351$	jsr	(writeintermsg)
352$	addq.l	#1,d2
	cmpi.w	#MaxInterNodeMsg,d2
	bcs.b	36$
	moveq.l	#0,d2				; wrap'er rundt
	moveq.l	#0,d5
	bra.b	32$
36$	add.w	d4,d5
32$	dbf	d3,35$
	move.l	(nodenoden,NodeBase),a1
	move.w	d2,(InterMsgread,a1)
	btst	#31,d6				; Var det ønsket chat request ?
	beq.b	38$				; nei
	bra.b	39$				; vi fikk noe, ut. a0 = nodemsg

37$	move.l	(consigbit,NodeBase),d1		; har det kommet en tast ?
	IFND DEMO
	or.l	(sersigbit,NodeBase),d1
	ENDC
	and.l	d0,d1
	beq.b	38$				; nei
	jsr	(readchar)			; henter tasten
	bmi.b	38$				; spesial tegn
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	39$				; hopper ut hvis vi fikk no carrier
	cmpi.b	#24,d0				; CTRL-X ??
	beq.b	39$				; Ja, ut
	cmpi.b	#3,d0				; CTRL-C ??
	beq.b	39$				; Ja, ut
38$	subq.l	#1,d6
	bcc	31$
	setz
39$	pop	a2/a3/d2-d7
	rts

fillinchatnode
	move.l	a3,-(a7)		; Fyller i vår chat node hos andre noden
	move.l	a0,a3
	move.l	(intersigbit,NodeBase),(c_Sigbit,a3)
	move.w	#0,(c_Rpos,a3)
	lea	(c_Name,a3),a1
	lea	(Name+CU,NodeBase),a0
	jsr	(strcopy)
	move.l	(Usernr+CU,NodeBase),(c_Usernr,a3)
	move.l	(nodenoden,NodeBase),a0
	move.l	(Nodespeed,a0),(c_Speed,a3)
	move.w	(NodeNumber,NodeBase),(c_Nodenr,a3)
	move.w	#0,(c_Status,a3)
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ANSI,d0
	beq.b	1$
	move.w	#statusF_Splitscreen,(c_Status,a3)
1$	suba.l	a1,a1
	jsrlib	FindTask
	move.l	d0,(c_Task,a3)
	move.l	(a7)+,a3
	rts

; a0 = chat stuct
fillincolors
	move.l	a2,-(a7)
	lea	(localchatnodes,a0),a2
	lea	(groupchatcolors),a1
	moveq.l	#MaxUsersGChat-1,d0
1$	move.l	(l_chatnode,a2),d1		; i bruk ?
	beq.b	2$				; nope
	move.l	d1,a0
	move.w	(a1)+,(c_color,a0)
	bra.b	3$
2$	addq.l	#2,a1
3$	lea	(localchatnode_sizeof,a2),a2
	subq.l	#1,d0
	bne.b	1$
	move.l	(a7)+,a2
	rts

;struct chat
; - struct chatnode * x-1 (de andre nodenes data område)
;
; - struct localchatnod * x
;   -> våre chatnoder hos de andre nodene
;	struct chatnode
;
;   -> andre nodenes chat struktur
;	struct chat

donodechat
	push	a3/a2/d2-d4/d7
	move.l	a0,a3				; = chat struct
	bsr.b	fillincolors
	move.w	#-1,(tmpval,NodeBase)		; nulstiller farven
	move.w	(Wpos,a3),d2			; = wpos
	move.l	(msgareaend,a3),d3
	jsr	(outimage)
	lea	(contactestatext),a0
	jsr	(writetext)
	moveq.l	#chatnode_sizeof,d7
	moveq.l	#MaxUsersGChat-1,d4
	lea	(chatnodes,a3),a2
	move.l	a3,-(a7)
	lea	(localchatnodes,a3),a3
	lea	(logchatedtext),a0
	lea	(c_Name,a2),a1
	jsr	(writelogtexttimed)		; skriver til logen at vi chat'er
	move.l	(c_Task,a2),d0
	beq.b	6$
5$	move.l	(l_chatnode,a3),a0
	move.w	(c_color,a0),d0
	bsr	50$
	lea	(c_Name,a2),a0
	jsr	(writetext)
	move.l	(l_chatnode,a3),a0		; oppdaterer read flagget, så vi
	move.l	(l_chat,a3),a1			; ikke får alt som er skrevet
	move.w	(Wpos,a1),(c_Rpos,a0)		; tidligere
6$	subq.l	#1,d4
	beq.b	4$
	adda.l	d7,a2
	lea	(localchatnode_sizeof,a3),a3
	move.l	(c_Task,a2),d0
	beq.b	6$
	move.w	#ansiwhite,d0			; skifter til hvit tekst
	bsr	50$
	lea	(kommaspacetext),a0
	jsr	(writetexti)
	bra.b	5$
4$	move.w	#ansiwhite,d0			; skifter til hvit tekst
	bsr	50$
	move.l	(a7)+,a3
	lea	(contactest2text),a0
	jsr	(writetexto)
	jsr	(outimage)
	moveq.l	#0,d7				; cur char pos
	move.l	d7,(tmpstore,NodeBase)		; signaliserer at vi vil motta intersig'er
	move.l	(msgarea,a3),a2			; = area
	sub.l	a2,d3				; = maks wpos

1$	jsr	(readchar)			; må tåle CTRL-X. FIX ME (??)
	bmi.b	1$				; dropper spesial tegn
	bne.b	2$
	tst.b	(readcharstatus,NodeBase)
	bne.b	3$
	bsr.b	10$				; skriver ut alle nye tegn
	beq.b	9$				; noen har tatt CTRL-Z
	bra.b	1$
2$	bsr	30$
	bmi.b	3$				; ctrl Z
	beq.b	1$				; Truncate
	move.w	d0,-(a7)
	move.w	#ansilblue,d0			; skifter til mørk blå tekst
	bsr	50$
	move.w	(a7)+,d0
	moveq.l	#0,d1				; vi kommer ikke ifra sysop chat
	bsr	writechatchar
	bra.b	1$
3$	move.w	#-1,(Wpos,a3)			; Vi har fått ctrl Z (eller no carrier)
	moveq.l	#-1,d0				; sig'er alle nodene vi chater med
	bsr	40$
	jsr	(outimage)
9$	pop	a3/a2/d2-d4/d7
	rts

10$	push	a2/d6/d5			; skriver ut all ny tekst
	bsr	70$				; sjekke om det er noen som vil join'e
	moveq.l	#MaxUsersGChat-1,d6		; oss, og tar seg av det
	lea	(localchatnodes,a3),a2
	moveq.l	#localchatnode_sizeof,d5	; = localchatnode size
11$	move.l	(l_chatnode,a2),d0
	beq.b	12$				; brukes denne ? nei..
	move.l	a2,a0
	bsr.b	20$
	beq.b	19$				; mottatt ctrl-z
12$	adda.l	d5,a2
	subq.l	#1,d6
	bcc.b	11$
	clrz
19$	pop	a2/d6/d5
	rts

20$	push	a2/a3/d2/d3
	moveq.l	#0,d3				; ikke funnet andre
	move.l	a3,a1				; husker i a1
	move.l	(l_chatnode,a0),a2		; vår chatnode
	move.l	(l_chat,a0),a3			; chat str (den andre nodens)
	move.w	(Wpos,a3),d2
	moveq.l	#-1,d0
	cmp.w	d0,d2
	bne.b	22$				; ikke ctrl-z
	move.w	(ChatNodeNr,a3),d0
	lea	(chatnodes,a1),a1
	moveq.l	#MaxUsersGChat-1,d1
23$	tst.l	(c_Task,a1)			; i bruk ?
	beq.b	25$				; nei.
	cmp.w	(c_Nodenr,a1),d0
	beq.b	24$
	moveq.l	#1,d3				; det er flere
25$	lea	(chatnode_sizeof,a1),a1
	subq.l	#1,d1
	bne.b	23$
	bra.b	299$				; fant ikke noden. quit chat
24$	moveq.l	#0,d0
	move.l	d0,(c_Task,a1)			; tømme nodens chatnode
	move.l	d0,(l_chatnode,a0)
	move.l	d0,(l_chat,a0)
	tst.l	d3
	bne.b	299$				; ok, det er flere
26$	tst.l	(c_Task,a1)			; i bruk ?
	bne.b	299$				; ja,, det er flere
	lea	(chatnode_sizeof,a1),a1
	subq.l	#1,d1
	bne.b	26$				; returnerer Z=1 hvis det ikke
	bra.b	299$				; er flere noder igjen.

22$	sub.w	(c_Rpos,a2),d2
	beq.b	29$				; ingen ny tekst
	bcc.b	21$
	move.w	(c_color,a2),d0			; skifter til riktig farve
	bsr	50$
	moveq.l	#0,d0
	move.w	(c_Rpos,a2),d0
	add.l	(msgarea,a3),d0
	move.l	(msgareaend,a3),a0
	suba.l	d0,a0
	exg	d0,a0
	jsr	(writetextlen)
	move.w	#0,(c_Rpos,a2)
21$	move.w	(c_color,a2),d0			; skifter til riktig farve
	bsr	50$
	jsrlib	Forbid
	moveq.l	#0,d1
	move.w	(c_Rpos,a2),d1
	move.l	d1,a0
	adda.l	(msgarea,a3),a0
	moveq.l	#0,d0
	move.w	(Wpos,a3),d0
	sub.l	d1,d0
	move.w	(Wpos,a3),(c_Rpos,a2)
	jsrlib	Permit
	bsr	writechattextleni
29$	clrz
299$	pop	a2/a3/d2/d3
	rts

30$	cmpi.b	#$9b,d0
	beq.b	33$
	cmpi.b	#31,d0
	bhi.b	31$				; Ikke kontroll tegn
	cmpi.b	#26,d0				; CTRL-Z ??
	beq.b	32$
	cmpi.b	#8,d0				; Back space
	beq.b	31$
	cmpi.b	#9,d0				; TAB
	beq.b	31$
	cmpi.b	#10,d0				; Line Feed
	beq.b	35$
	cmpi.b	#13,d0				; Carrige return, Converterer til LF
	bne.b	33$
	move.b	#10,d0
35$	bsr	60$
	beq.b	32$				; timeout. Sender CTRL-Z
	moveq.l	#10,d0
31$	move.b	d0,(0,a2,d2.w)			; lagrer
	addq.l	#1,d2
	cmp.w	d2,d3
	bhi.b	34$
	moveq.l	#0,d2
34$	move.w	d2,(Wpos,a3)
	move.w	d0,-(a7)
	moveq.l	#-1,d0				; sig'er alle nodene vi chater med
	bsr	40$
	move.w	(a7)+,d0
	clrzn
	rts
33$	clrn					; truncate
	setz
	rts
32$	setn					; vi fikk ctrl-Z
	rts

40$	push	a3/d2/d3	; signaliserer en eller alle taskene vi chat'er med
	lea	(chatnodes,a3),a3
	moveq.l	#chatnode_sizeof,d3
	tst.l	d0
	bmi.b	41$		; vi skal ta alle
	mulu.w	d3,d0
	adda.l	d0,a3
	move.l	(c_Task,a3),d0
	beq.b	49$
	move.l	d0,a1
	move.l	(c_Sigbit,a3),d0
	jsrlib	Signal
	bra.b	49$
41$	moveq.l	#MaxUsersGChat-1,d2
42$	move.l	(c_Task,a3),d0
	beq.b	43$
	move.l	d0,a1
	move.l	(c_Sigbit,a3),d0
	jsrlib	Signal
43$	adda.l	d3,a3
	subq.l	#1,d2
	bcc.b	42$
49$	pop	a3/d2/d3
	rts

50$	cmp.w	(tmpval,NodeBase),d0		; samme farve som vi har ?
	beq.b	59$				; ja
	move.w	(Userbits+CU,NodeBase),d1	; vil brukeren ha farver ?
	andi.w	#USERF_ColorMessages,d1
	beq.b	59$				; nei
	lea	(ansicolors),a0
	lea	(0,a0,d0.w),a0
	jsr	(writetexti)
59$	rts

60$	move.w	(TimeLimit+CU,NodeBase),d0		; har vi timelimit ?
	beq	68$				; nei
	jsr	(updatetime)
	sub.w	(TimeUsed+CU,NodeBase),d0		; Har vi noe igjen ?
	bcc.b	68$				; jepp
	setz					; tiden er ute
	bra.b	69$				; KILL KILL KILL !! :-)
68$	clrz
69$	rts

70$	push	a2/a3/d2-d7			; sjekke om det er noen som vil
	jsrlib	Forbid				; join'e oss, og tar seg av det
	move.l	a3,d6				; husker a3 i d6
	move.l	(nodenoden,NodeBase),a0
	move.w	(InterMsgread,a0),d0
	move.w	(InterMsgwrite,a0),d1
	jsrlib	Permit
	sub.w	d0,d1
	beq	79$				; ingen node meldinger.
	bcc.b	71$				; ingen wrap
	addi.w	#MaxInterNodeMsg,d1
71$	move.l	d0,d2				; d2 - startpos
	move.l	d1,d3				; d3 - antall meldinger
	move.l	a0,a2
	lea	(InterNodeMsg,a2),a3		; leter etter vår nodemelding
	moveq.l	#InterNodeMsgsiz,d4
	move.l	d2,d5
	mulu.w	d4,d5
	subq.l	#1,d3
72$	lea	(0,a3,d5.w),a0
	move.b	(i_type,a0),d0			; Sjekker typen
	cmpi.b	#4,d0				; chat request ?
	bne.b	721$				; nei.
	moveq.l	#0,d3				; avslutter loop'en
;	bra.b	722$
721$
;	bsr	writeintermsg			; skrive ut øverst på skjermen (?)
722$	addq.l	#1,d2
	cmpi.w	#MaxInterNodeMsg,d2
	bcs.b	73$
	moveq.l	#0,d2				; wrap'er rundt
	moveq.l	#0,d5
	bra.b	74$
73$	add.w	d4,d5
74$	dbf	d3,72$
	move.l	(nodenoden,NodeBase),a1
	move.w	d2,(InterMsgread,a1)		; vi fikk noe, ut. a0 = nodemsg
	move.b	(i_type,a0),d0			; Sjekker typen
	cmpi.b	#4,d0				; var det chat request ?
	bne	79$				; nei.
	move.l	d6,a3				; setter tilbake a3
	moveq.l	#0,d6
	move.w	(i_franode,a0),d6

; behandle node meldingen vi fikk

	moveq.l	#MaxUsersGChat-1,d0		; maks buffere
	lea	(chatnodes,a3),a2
75$	move.l	(c_Task,a2),d1			; leter etter ledig plass
	beq.b	751$				; fant
	lea	(chatnode_sizeof,a2),a2		; peker til neste
	subq.l	#1,d0				; er det flere å lete i ?
	bne.b	75$				; ja, leter videre
	suba.l	a2,a2				; ingen, sender null tilbake
	bra.b	76$
751$	moveq.l	#-1,d1				; fyller i så ingen andre skal
	move.l	d1,(c_Task,a2)			; ta denne. (Dette er safe)
	neg.l	d0
	addq.l	#MaxUsersGChat-1,d0		; maks buffere
	move.l	d0,d1
	lea	(localchatnodes,a3),a1		; Fyller i vår lokalchatnode
	mulu.w	#localchatnode_sizeof,d0
	adda.l	d0,a1				; har nå riktig lokalchatnode
	move.l	(i_usernr,a0),(l_chat,a1)
	move.l	a0,d7				; husker nodemsg'en
	move.l	(i_usernr2,a0),a0		; henter frem vår chat node
	move.l	a0,(l_chatnode,a1)

	lsl.l	#1,d1
	lea	(groupchatcolors),a1
	move.w	(a1,d1.w),(c_color,a0)

	bsr	fillinchatnode
76$	lea	(tmptext,NodeBase),a0		; Svare med en node melding med :
	move.b	#4,(i_type,a0)			; type 4 (chat request),
	move.l	a3,(i_usernr,a0)			; vår chat struktur i i_usernr,
	move.l	a2,(i_usernr2,a0)		; og chat noden den andre noden skal fylle i i_usernr2
	move.w	(NodeNumber,NodeBase),(i_franode,a0)
	move.l	d6,d0
	move.b	#0,(i_pri,a0)
	jsr	(sendintermsg)
	bne.b	79$
	move.l	d7,a0
	lea	(i_Name,a0),a0
	jsr	(writetext)
	lea	(joinedchattext),a0
	jsr	(writetexto)
; Det er det samme om det gikk bra eller ikke. Vi skal returnere uansett
79$	pop	a2/a3/d2-d7
	rts

;maks bredde er 77
; d7 er horisontal charpos

; d1 = kommer ifra sysopchat (t/f)
writechatchar
	cmpi.b	#10,d0
	bne.b	1$
	tst.l	d1		; skal vi skrive til fil ?
	beq.b	6$		; nope
	lea	(tmptext,NodeBase),a0
	push	d2/d3
	move.l	a0,d2
	move.l	d7,d3
	bsr	chatfilewrite
	pop	d2/d3
	move.b	#10,d0
6$	moveq.l	#0,d7
	bra.b	2$
1$	cmpi.b	#8,d0
	bne.b	4$
	subq.l	#1,d7
	bcc.b	5$
	moveq.l	#0,d7			; Vi kan ikke gå tilbake en linje
	bra.b	9$
5$	lea	(deltext),a0
	jsr	(writetexti)
	bra.b	9$
4$	cmpi.b	#9,d0
	bne.b	7$
	move.w	d7,d0
	addi.w	#8,d0
	andi.w	#$fff8,d0
	cmpi.w	#76,d0			; EOL ?
	bcc.b	9$			; ja
	sub.w	d7,d0
	beq.b	9$			; no change
	bcs.b	9$

	move.w	d0,-(a7)
	lea	(spacetext),a0
	jsr	(writetextleni)
	move.w	(a7)+,d0

	lea	(tmptext,NodeBase),a0
	lea	(0,a0,d7.w),a0
	add.w	d0,d7
8$	move.b	#' ',(a0)+
	subi.w	#1,d0
	bne.b	8$
	bra.b	9$			; ferdig.

7$	lea	(tmptext,NodeBase),a0
	move.b	d0,(0,a0,d7.w)
	addq.l	#1,d7
	cmpi.w	#77,d7			; wrap ?
	bcc.b	3$			; ja
2$	jsr	(writechari)
9$	rts
3$
;	bra.b	chatwrap

; d1 - vi kommer ifra sysop chat (t/f)
chatwrap
	push	a2/d2/d3/d4
	move.l	d1,d4
	lea	(tmptext,NodeBase),a0
	adda.l	d7,a0
	move.l	a0,a1
	move.l	d7,d1
1$	move.b	-(a1),d0
	subq.l	#1,d1
	bcs	3$			; ikke noe å wrap'e
	cmpi.b	#' ',d0
	beq.b	2$
	cmpi.b	#'-',d0
	bne.b	1$
2$	move.l	a0,d2
	addq.l	#1,a1			; går til tegnet etter
	sub.l	a1,d2
	bne.b	7$
	subq.l	#1,a1
	bra.b	8$
7$	subq.l	#1,d2
8$	move.l	a1,a2
	tst.l	d4			; skal vi skrive til filen ?
	beq.b	6$			; nei
	lea	(tmptext,NodeBase),a0
	push	d2/d3
	move.l	a0,d2
	move.l	a1,d3
	sub.l	d2,d3			; beregner lengden
	bsr	chatfilewrite
	pop	d2/d3
6$	move.l	d2,d7
	bmi.b	4$
	moveq.l	#0,d3
5$	subq.l	#1,d2			; sletter gammel tekst
	bcs.b	4$
	lea	(deltext),a0
	jsr	(writetext)
	addq.l	#1,d3
	cmpi.w	#20,d3
	bcs.b	5$
	moveq.l	#0,d3
	jsr	(breakoutimage)
	bra.b	5$
4$	move.b	#10,d0
	jsr	(writechari)
	move.l	a2,a0
	addq.l	#1,d7
	move.l	d7,d0
	beq.b	9$			; vi er tomme...
	push	a0/d0
	jsr	(writetextleni)
	pop	a0/d0
	lea	(tmptext,NodeBase),a1
	jsr	(strcopylen)
	bra.b	9$
3$	move.b	(-1,a0),(tmptext,NodeBase)
	move.b	#10,d0
	jsr	(writechari)
	move.b	(tmptext,NodeBase),d0
	moveq.l	#1,d7
	jsr	(writechari)
9$	pop	a2/d2/d3/d4
	rts

chatfilewrite
	move.l	(tmpstore,NodeBase),d1	; har vi fil ?
	moveq.l	#-1,d0
	cmp.l	d0,d1
	beq.b	9$			; nei
	move.l	(dosbase),a6
	tst.l	d3
	beq.b	1$			; ikkenoe
	bsr	10$
	beq.b	9$
1$	move.l	(tmpstore,NodeBase),d1
	move.l	#newlinetext,d2
	moveq.l	#1,d3
	bsr	10$
9$	move.l	(exebase),a6
	rts

10$	jsrlib	Write
	cmp.l	d0,d3
	notz
	bne.b	19$
	move.l	(tmpstore,NodeBase),d1
	jsrlib	Close
	moveq.l	#-1,d0
	move.l	d0,(tmpstore,NodeBase)
	setz
19$	rts

writechattextleni
	push	a2/d2
	move.l	a0,a2
	move.l	d0,d2
	beq.b	9$			; for stort tall.. ?
1$	subi.w	#1,d2
	bcs.b	9$
	move.b	(a2)+,d0
	beq.b	1$
	moveq.l	#0,d1			; vi kommer ikke ifra sysop chat
	bsr	writechatchar
	bra.b	1$
9$	pop	a2/d2
	rts

;#e
*****************************************************************
*			Read meny				*
*****************************************************************

;#b
;#c
changesendrec
	push	a2/d2/d3
	jsr	(checksysopaccess)
	beq	9$
	bsr	getcurmsgnr
	beq	9$
	move.w	(confnr,NodeBase),d1		; henter inn msg header
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	lea	(msgnotavailfrep),a0
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop+MSTATF_Moved+MSTATF_Dontshow,d0
	bne	8$
	move.l	a2,a0
	jsr	(isnetmessage)
	beq	9$				; ut
	moveq.l	#0,d2				; sletter change flag
	lea	(changefradrtext),a0
	moveq.l	#0,d0				; vi godtar ikke all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	bne.b	1$
	move.b	(readcharstatus,NodeBase),d1
	bne	9$
	bra.b	2$
1$	move.l	d0,(MsgFrom,a2)
	moveq.l	#1,d2				; husker at vi har forandret
2$	lea	(changetoadrtext),a0
	moveq.l	#1,d0				; vi godtar all
	move.w	(confnr,NodeBase),d1		; Finner ut om vi er i en postpox
	lea	(n_FirstConference+CStr,MainBase),a1
	mulu	#ConferenceRecord_SIZEOF/2,d1
	move.w	(uc_Access,a1,d1.l),d1
	btst	#CONFSWB_PostBox,d1
	beq.b	3$
	moveq.l	#0,d0				; vi godtar ikke all
3$	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	bne.b	4$
	move.b	(readcharstatus,NodeBase),d1
	bne	9$
	bra.b	7$
4$	move.l	d0,d3
	moveq.l	#-1,d1
	cmp.l	d3,d1				; til all ?
	bne.b	5$				; nope
	btst	#SECB_SecReceiver,(Security,a2)	; privat ?
	beq.b	6$				; nope, alt ok.
	lea	(allnotallowtext),a0
	bra	8$

5$	move.w	(confnr,NodeBase),d1
	jsr	(checkmemberofconf)
	bne.b	6$
	lea	(loadusererrtext),a0
	bmi	8$
	lea	(sorryusnmoctext),a0
	bra	8$
6$	move.l	d3,(MsgTo,a2)
	moveq.l	#1,d2				; husker at vi har forandret
7$	tst.l	d2
	beq.b	9$
	bclr	#MSTATB_MsgRead,(MsgStatus,a2)	; sleter readflagget
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	8$
	lea	(msgupdatedtext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	pop	a2/d2/d3
	rts

;#c
getuserinfofrommsg
	push	a2
	jsr	(checksysopaccess)
	beq.b	9$
	bsr	getcurmsgnr
	beq.b	9$
	move.w	(confnr,NodeBase),d1		; henter inn msg header
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	8$
	move.l	a2,a0
	jsr	(isnetmessage)
	beq	9$				; ut
	move.l	(MsgFrom,a2),d0			; Er det supersysop ?
	move.l	(SYSOPUsernr+CStr,MainBase),d1
	cmp.l	d0,d1
	bne.b	1$
	cmp.l	(Usernr+CU,NodeBase),d1		; Er vi supersysop ?
	lea	(nosysopheretext),a0
	bne.b	8$				; Nei, error
1$	move.l	(Tmpusermem,NodeBase),a2
	move.l	a2,a0
	jsr	(loadusernr)
	lea	(usernotfountext),a0
	beq.b	8$
	jsr	(outimage)
	moveq.l	#0,d0
	lea	(10$),a0
	bsr	doshowuser
	bra.b	9$
8$	jsr	(writeerroro)
9$	pop	a2
	rts

10$	jmp	(writetexto)

;#c
recentlyread
	lea	(prevqueue+4,NodeBase),a0
	rts

;#c
dump	lea	(dumpmsgpromtext),a0
	suba.l	a1,a1
	push	a2
	suba.l	a2,a2				; ingen ekstra help
	jsr	(readlinepromptwhelp)
	pop	a2
	beq.b	9$
	jsr	(upstring)
	move.l	a0,-(a7)
	lea	(cleartext),a1
	jsr	(comparestrings)
	move.l	(a7)+,a0
	beq.b	dumpclear
	move.b	(a0),d0
	cmpi.b	#'C',d0
	beq	dumpconf
	cmpi.b	#'A',d0
	beq	dumpall
	cmpi.b	#'M',d0
	beq.b	dumpmessage
	lea	(invalidcmdtext),a0
	jsr	(writeerroro)
9$	rts

dumpclear
	bsr	getscratchpaddelfname		; delete scratchpad
	jsr	(deletepattern)
	lea	(scratchpdeltext),a0
	jsr	(writetexto)

	bsr	restorereadpointers		; reload readptr's, og hvis ok, skriv :
	beq.b	9$
	lea	(lmsgreadrestext),a0
	jsr	(writetexto)
9$	rts

dumpmessage
	push	a2/d2
	moveq.l	#0,d2				; har ingen filhandle
	move.b	(GrabFormat+CU,NodeBase),d0	; hvilket format skal de ha ?
	beq.b	1$
	lea	(qwkcantdumptext),a0
	sub.b	#1,d0
	beq.b	8$				; QWK.. Klarer ikke
	lea	(hipcantdumptext),a0
	sub.b	#1,d0
	beq.b	8$				; Hippo.. Klarer ikke
1$	bsr	getcurmsgnr
	beq.b	9$
	move.w	(confnr,NodeBase),d1		; henter inn msg header
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(allowtype)			; Kan vi skrive ut denne ???
	lea	(youarenottext),a0
	bne	8$				; Nei. "Jump, for my love"
	bsr	savereadptrs			; tar backup av read ptr'ene
	bsr	openscratchpad
	lea	(erropenscratext),a0
	beq.b	8$
	move.l	d0,d2
	move.w	(confnr,NodeBase),d0
	move.l	d2,d1
	move.l	a2,a0
	jsr	(doscratchmsg)
	lea	(errwritscratext),a0
	bpl.b	9$
8$	jsr	(writeerroro)
9$	move.l	d2,d1
	beq.b	91$
	move.l	(dosbase),a6			; lukker fila om det er nødvendig
	jsrlib	Close
	move.l	(exebase),a6
91$	pop	a2/d2
	rts

dumpconf
	push	d2/d3
	moveq.l	#0,d2				; har ingen filhandle
	move.b	(GrabFormat+CU,NodeBase),d0	; hvilket format skal de ha ?
	beq.b	1$
	lea	(qwkcantdumptext),a0
	sub.b	#1,d0
	beq.b	8$				; QWK.. Klarer ikke
	lea	(hipcantdumptext),a0
	sub.b	#1,d0
	beq.b	8$				; hippo.. Klarer ikke
1$	move.w	#-1,(linesleft,NodeBase)		; Vi vil ikke ha noen more her..
	bsr	savereadptrs			; tar backup av read ptr'ene
	bsr	openscratchpad
	lea	(erropenscratext),a0
	beq.b	8$
	move.l	d0,d2
	move.w	(confnr,NodeBase),d0
	bsr	writedumpingconf
	move.l	d2,d0
	jsr	(dograbqueue)
	lea	(errwritscratext),a0
	beq.b	8$
	move.l	d0,d3
	jsr	(outimage)
	move.b	#'<',d0				; <xx> messages added to scratchpad.
	jsr	(writechar)
	move.l	d3,d0
	jsr	(skrivnr)
	move.b	#'>',d0
	jsr	(writechar)
	lea	(msgaddtoscrtext),a0
	jsr	(writetexto)
	lea	(usesendtotrtext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	move.l	d2,d1
	beq.b	91$
	move.l	(dosbase),a6			; lukker fila om det er nødvendig
	jsrlib	Close
	move.l	(exebase),a6
91$	pop	d2/d3
	rts

; d0 = confnr
writedumpingconf
	move.w	d0,-(a7)
	lea	(dumpingtext),a0
	jsr	(writetext)
	move.w	(a7)+,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0
	jsr	(writetext)
	move.b	#':',d0
	jsr	(writechar)
	jmp	(outimage)

; d0 = 0, vanelig, d0 = 1, ifra grab (stille)
dumpall
	moveq.l	#0,d0
dumpall1
	push	d4/d3/d5/d6/a2/a3
	moveq.l	#0,d6
	tst.w	d0
	beq.b	4$
	bset	#30,d6				; husker at vi skal være stille (fra grab)
4$
;	bclr	#31,d6				; ikke gått bra enda..
	move.w	#-1,(linesleft,NodeBase)		; Vi vil ikke ha noen more her..
	moveq.l	#32,d0				; Status = collecting scratchpad
	jsr	(changenodestatus)
	bsr	savereadptrs			; tar backup av read ptr'ene

	move.b	(GrabFormat+CU,NodeBase),d0	; hvilket format skal de ha ?
	beq.b	7$				; MBBS
	cmp.b	#1,d0				; QWK 
	beq.b	10$				; ja
	XREF	_hippopackmessages
	jsr	(_hippopackmessages)
	bra.b	11$
10$	XREF	_packmessages
	jsr	(_packmessages)
11$	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq	92$				; error, ut
	move.l	d0,d5				; antall meldinger scratch'a
	moveq.l	#0,d4				; sier vi ikke har noen fil
	bra	21$				; og videre..

7$	bsr	openscratchpad
	lea	(erropenscratext),a0
	beq	8$
	move.l	d0,d4
	move.w	(confnr,NodeBase),d0
	bsr	writedumpingconf
	move.l	d4,d0
	jsr	(dograbqueue)
	lea	(errwritscratext),a0
	beq	8$
	move.l	d0,d5				; husker antall scratch'a
	jsr	(unjoin)

	move.w	(confnr,NodeBase),d3		; Starter fra der vi er.
	move.w	d3,d6
	bra.b	3$				; Tar den en gang til
1$	move.w	d3,d0
	jsr	(getnextunreadconf)
	beq	2$				; Ikke noen flere
	move.w	d0,d3
3$	move.w	d3,d1				; sjekker at det virkelig var noe
	lea	(u_almostendsave+CU,NodeBase),a2
	mulu	#Userconf_seizeof/2,d1
	add.l	d1,a2
	lea	(n_FirstConference+CStr,MainBase),a3
	move.w	d3,d1
	mulu	#ConferenceRecord_SIZEOF/2,d1
	add.l	d1,a3

	move.l	(n_ConfDefaultMsg,a3),d0
	sub.l	(uc_LastRead,a2),d0
	bls.b	1$
	cmp.w	d3,d6				; var det den første ?
	bne.b	5$				; Nei
	move.w	#-1,d6				; sørger for at det ikke skjer igjen
	bra.b	6$
5$	jsr	(dubbelnewline)
	move.w	d3,d0
	bsr	writedumpingconf
6$	move.w	d3,d0
	jsr	(dograbconf)
	lea	(errwritscratext),a0
	beq	8$
	add.l	d0,d5				; husker antall scratch'a
	move.w	d3,d1
	add.w	d1,d1
	move.l	(n_ConfDefaultMsg,a3),(uc_LastRead,a2)	; setter last read
	jsr	(checkcarriercheckser)
	bne.b	1$				; ja alt er ok
	move.l	(dosbase),a6			; serie borte. Sletter fila
	move.l	d4,d1
	jsrlib	Close
	move.l	(exebase),a6
	bsr	getscratchpaddelfname		; delete scratchpad
	jsr	(deletepattern)
	bra	91$

2$	lea	(nyconfgrabtext),a0
	move.l	d4,d0
	jsr	(writefileln)
	lea	(errwritscratext),a0
	beq.b	8$
21$	bset	#31,d6				; alt har gått bra
	jsr	(outimage)
	move.b	#'<',d0				; <xx> messages added to scratchpad.
	jsr	(writechar)
	move.l	d5,d0
	jsr	(skrivnr)
	move.b	#'>',d0
	jsr	(writechar)
	lea	(msgaddtoscrtext),a0
	jsr	(writetexto)
	btst	#30,d6				; stille mode ?
	bne.b	9$				; jepp
	lea	(usesendtotrtext),a0
	jsr	(writetexto)
	bra.b	9$				; ok

8$	move.l	a0,d3
	jsr	(outimage)
	move.l	d3,a0
	jsr	(writeerroro)
9$	move.l	d4,d1
	beq.b	91$
	move.l	(dosbase),a6			; lukker fila om det er nødvendig
	jsrlib	Close
	move.l	(exebase),a6
91$	moveq.l	#0,d0
	move.l	d0,(msgqueue,NodeBase)		; Tømmer køen.
	move.w	(confnr,NodeBase),d1		; sørger for at highmsg er riktig
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d1
	move.l	(uc_LastRead,a0,d1.l),(HighMsgQueue,NodeBase)
92$	moveq.l	#4,d0				; Status = active.
	jsr	(changenodestatus)
	btst	#31,d6
	pop	d4/d3/d5/d6/a2/a3
	rts

;#c
; ret : Z = 1, alt ok
getscratch
	push	a2/d2/d3/d4
	moveq.l	#0,d3				; har ikke gått bra enda
	lea	(filenametext),a0
	jsr	(writetext)
	lea	(maintmptext,NodeBase),a1	; bygger opp path'en
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	strcopy
	move.b	#'/',(-1,a1)
	move.l	a1,a2
	lea	(BaseName+CStr,MainBase),a0
	jsr	(strcopy)
	lea	(-1,a1),a1
	lea	(repextension),a0
	jsr	(strcopy)
	move.l	a2,a0
	jsr	(writetexto)
	beq	9$

	moveq.l	#20,d0				; Status = UL file.
	jsr	(changenodestatus)
	jsr	(outimage)

	move.b	(CommsPort+Nodemem,NodeBase),d0	; internal node ??
	beq.b	5$				; Yepp. local download
	lea	(maintmptext,NodeBase),a0
	move.l	a0,(ULfilenamehack,NodeBase)
	moveq.l	#1,d0
	jsr	(receivefile)
	bne.b	1$
6$	lea	(maintmptext,NodeBase),a0
	jsr	(deletefile)
	lea	(logfulmsgtext),a0
	move.l	a2,a1
	jsr	(writelogtexttimed)
	bra	9$

5$	lea	(maintmptext,NodeBase),a0
	jsr	(fjernpath)
	jsr	(getfullnameusetmp)
	beq	9$				; Ut
	lea	(maintmptext,NodeBase),a1
	jsr	(copyfile)
	beq.b	6$

1$	moveq.l	#80,d0				; Status = Unpacking file(s)
	jsr	(changenodestatus)
	move.l	(dosbase),a6
	moveq.l	#0,d2
	move.b	(ScratchFormat+CU,NodeBase),d2
	lsl.w	#2,d2
	lea	(tmptext2,NodeBase),a1		; bygger opp navnet på extracteren
	lea	(extractstring),a0
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.l	(0,a0,d2.w),a0
	jsr	(strcopy)
	lea	(tmptext2,NodeBase),a0		; sjekker om pakker finnes
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	bne.b	2$
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	jsrlib	DeleteFile			; Sletter arkivet
	move.l	(exebase),a6			; sier ifra at vi ikke fant extracteren
	lea	(cantfinextrtext),a0
	bra	8$
2$	jsrlib	UnLock

	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	lea	(executestring),a0		; bygger opp execute string
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(tmptext2,NodeBase),a0		; henter navnet på scriptet
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	move.b	#'"',(a1)+
	lea	(maintmptext,NodeBase),a0	; path'en
	jsr	(strcopy)
	move.b	#'"',(-1,a1)
	move.b	#' ',(a1)+
	move.b	#'"',(a1)+
	lea	(BaseName+CStr,MainBase),a0
	jsr	(strcopy)
	lea	(-1,a1),a1
	lea	(msgextension),a0
	jsr	(strcopy)
	move.b	#'"',(-1,a1)
	move.b	#0,(a1)

	lea	(TmpPath+Nodemem,NodeBase),a1
	move.l	a1,d1
	jsrlib	Lock
	move.l	d0,d1
	beq.b	7$
	jsrlib	CurrentDir
	move.l	d0,d4

	move.l	(tmpmsgmem,NodeBase),a0
	move.l	a0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3			; Execute ABBS:sys/extract.xxx "t:Nodextmpdir/BaseName.REP" "BaseName.MSG"
	jsrlib	Execute
	move.l	d4,d1
	jsrlib	CurrentDir
	move.l	d0,d1
	jsrlib	UnLock

	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	jsrlib	DeleteFile			; Sletter arkivet
	lea	(maintmptext,NodeBase),a1	; finner slutten
3$	move.b	(a1)+,d0
	bne.b	3$
4$	move.b	-(a1),d0			; spoler tilbake til siste .'et
	cmp.b	#'.',d0
	bne.b	4$
	lea	(msgextension),a0		; bytter ut .REP med .MSG
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	move.l	(exebase),a6
	jsr	(getfilelen)
7$	lea	(errorextrintext),a0
	beq.b	8$
	moveq.l	#1,d3				; det gikk bra
	bra.b	9$
8$	move.l	(exebase),a6
	jsr	(writeerroro)
9$	moveq.l	#0,d0
	move.l	d0,(ULfilenamehack,NodeBase)
	moveq.l	#4,d0				; Status = active.
	jsr	(changenodestatus)
	move.l	d3,d0				; setter Z
	pop	a2/d2/d3/d4
	rts

;#c
sendscratch
	push	d2-d6
	move.b	(GrabFormat+CU,NodeBase),d6	; hvilket format skal de ha ?
	bclr	#31,d6				; har ikke gått bra (enda ihvertfall)
	tst.b	d6				; qwk eller hippo ?
	bne.b	16$				; jepp
	bsr	openscratchpad
	lea	(erropenscratext),a0
	beq	8$
	move.l	d0,d1
	move.l	(dosbase),a6			; lukker fila igjen
	jsrlib	Close
	move.l	(exebase),a6
16$	lea	(pleaswaitwptext),a0
	jsr	(writetexto)
	lea	(grabgoodfortext),a0
	jsr	(writetexto)

	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	bne.b	13$				; no, go ahead
	tst.b	d6				; qwk eller hippo ?
	bne.b	13$				; jepp, da skal vi pakke alikevel

	lea	(maintmptext,NodeBase),a1	; bygger opp dest name
	lea	(abbsrootname),a0
	jsr	(strcopy)
	lea	(-1,a1),a1
	lea	(BaseName+CStr,MainBase),a0
	jsr	(strcopy)
	bsr	getscratchpadfname		; source
	lea	(maintmptext,NodeBase),a1	; destination
	jsr	(copyfile)
	bne	14$				; fortsetter som vanelig
	lea	(diskerrortext),a0
	jsr	(writeerroro)
	bra	11$

14$
	bset	#31,d6				; send gikk ok
	move.l	(dosbase),a6
	bsr	getreadpointerfname		; sletter read pointere
	move.l	a0,d1
	jsrlib	DeleteFile
	bra	15$	

;pack file
13$	moveq.l	#76,d0				; Status = packing file(s)
	jsr	(changenodestatus)
	lea	(maintmptext,NodeBase),a1	; bygger opp path'en
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	strcopy
	moveq.l	#0,d5
	move.b	(ScratchFormat+CU,NodeBase),d5
	lsl.w	#2,d5
	bne.b	1$				; vi skal pakke

3$	bsr	30$				; "rename <path>/BaseName
	lea	(tmptext,NodeBase),a0		; to <path>/BaseName.txt
	lea	(tmplargestore,NodeBase),a1
	move.l	a0,d1
	move.l	a1,d2
	move.l	(dosbase),a6
	jsrlib	Rename
	bra	4$

1$	move.l	(dosbase),a6
	lea	(tmptext2,NodeBase),a1		; bygger opp navnet på pakkeren
	lea	(packstring),a0
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.l	(0,a0,d5.w),a0
	jsr	(strcopy)
	lea	(tmptext2,NodeBase),a0		; sjekker om pakker finnes
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	bne.b	2$
	move.l	(exebase),a6			; sier ifra at vi ikke fant pakkeren
	lea	(cantfinpacktext),a0
	jsr	(writetexto)
	moveq.l	#0,d5				; skifter til tekst
	bra	3$				; går til rename
2$	jsrlib	UnLock

; <pakkstring> "basenavn" til "basenavn.<ext>"
	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	lea	(executestring),a0		; bygger opp execute string
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(tmptext2,NodeBase),a0		; henter navnet på scriptet
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	move.b	#'"',(a1)+
	lea	(maintmptext,NodeBase),a0	; path'en
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	lea	(BaseName+CStr,MainBase),a0		; arkiv navnet
	jsr	(strcopy)
	cmp.b	#1,d6				; qwk ?
	bne.b	17$				; Nei
	lea	qwkextension,a0
	subq.l	#1,a1
	jsr	(strcopy)
17$	move.b	#'"',(-1,a1)
	move.b	#' ',(a1)+
	move.b	#'"',(a1)+
	lea	(maintmptext,NodeBase),a0	; path'en
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	lea	(allqwksendfiles),a0
	cmp.b	#1,d6				; qwk ?
	beq.b	18$				; ja
	lea	allhipsendfiles,a0
	cmp.b	#2,d6				; hippo ?
	beq.b	18$				; ja
	lea	(BaseName+CStr,MainBase),a0		; fil navnet
18$	jsr	(strcopy)
	move.b	#'"',(-1,a1)
	move.b	#0,(a1)				; terminerer
	move.l	(tmpmsgmem,NodeBase),a0
	move.l	a0,d1
	moveq.l	#0,d2	; Execute ABBS:sys/pack.xxx "t:Nodextmpdir/BaseName.QWK" "t:Nodextmpdir/#?.dat"
	moveq.l	#0,d3	; Execute ABBS:sys/pack.xxx "t:Nodextmpdir/BaseName" "t:Nodextmpdir/BaseName"
	jsrlib	Execute

4$	move.l	(exebase),a6			; sjekker om pakkingen gikk bra
	lea	(maintmptext,NodeBase),a1	; finner slutten på path'en
5$	move.b	(a1)+,d0
	bne.b	5$
	move.b	#'/',(-1,a1)
	lea	(BaseName+CStr,MainBase),a0		; bygger opp filnavnet
	jsr	(strcopy)
	lea	qwkextension,a0
	cmp.b	#1,d6				; qwk ?
	beq.b	19$				; ja
	lea	(packexctstrings),a0
	move.l	(0,a0,d5.w),a0
19$	subq.l	#1,a1
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	jsr	(getfilelen)
	bne.b	7$
	lea	(errorpackintext),a0
6$	jsr	(writeerroro)
61$	move.l	(dosbase),a6
	tst.l	d5				; var det text ?
	beq.b	12$				; ja
	lea	(maintmptext,NodeBase),a0	; sletter arkivet
	move.l	a0,d1
	jsrlib	DeleteFile
	bra.b	11$
12$	lea	(maintmptext,NodeBase),a1	; bygger opp path'en
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	strcopy
	bsr	30$
	lea	(tmptext,NodeBase),a0		; renamer tilbake
	lea	(tmplargestore,NodeBase),a1
	move.l	a0,d2
	move.l	a1,d1
	jsrlib	Rename
11$	move.l	(exebase),a6
	lea	(scrstillavatext),a0		; still availible ..
	jsr	(writetexto)
	bra	9$

; send basenavn.<ext>
7$	move.l	d0,d1				; beregner size
	moveq.l	#10,d0
	lsr.l	d0,d1
	moveq.l	#24,d0				; Status = DL file.
	jsr	(changenodestatus)
	jsr	(checkcarriercheckser)
	beq.b	10$				; Ikke noen carrier.
	lea	(maintmptext,NodeBase),a0
	move.l	a0,(ULfilenamehack,NodeBase)
	jsr	(fjernpath)

	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	bne.b	20$				; no, go ahead

	jsr	(getfullnameusetmp)
	beq	61$				; rydder opp
	move.l	a0,a1
	lea	(maintmptext,NodeBase),a0
	jsr	(copyfile)
	lea	(errorsendtext),a0
	beq	6$
	bra.b	21$


20$	jsr	(sendfile)
	bmi.b	10$				; carrier forsvant
	lea	(errorsendtext),a0
	beq	6$				; ok, vi hopper.
21$	bset	#31,d6				; send gikk ok

	move.l	(dosbase),a6
	bsr	getreadpointerfname		; sletter read pointere
	move.l	a0,d1
	jsrlib	DeleteFile
10$	lea	(maintmptext,NodeBase),a0	; sletter arkivet
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DeleteFile
15$	move.l	(exebase),a6
	bsr	getscratchpaddelfname		; sletter scratchpad
	jsr	(deletepattern)

	btst	#31,d6
	beq.b	9$				; ikke ok, ingen utskrift
	lea	(scratchpemptext),a0
	jsr	(writetexto)
	lea	loggrabedtext,a0		; Skriver i log'en at han grab'a
	jsr	(writelogtexttime)
	bra.b	9$
8$	jsr	(writeerroro)
9$	moveq.l	#4,d0				; Status = active.
	jsr	(changenodestatus)
	btst	#31,d6				; returnerer Z bit'et
	pop	d2-d6
	rts

30$	lea	(maintmptext,NodeBase),a0	; "rename <path>/BaseName
	lea	(tmptext,NodeBase),a1
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	lea	(BaseName+CStr,MainBase),a0
	jsr	(strcopy)

	lea	(maintmptext,NodeBase),a0	; to <path>/BaseName.txt
	lea	(tmplargestore,NodeBase),a1
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	lea	(BaseName+CStr,MainBase),a0
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(txtextension),a0
	jmp	(strcopy)

openscratchpad
	push	d2-d4/a2
	moveq.l	#0,d4
	move.l	(dosbase),a6
	bsr	getscratchpadfname
	move.l	a0,a2
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	1$
	move.l	d4,d1
	moveq.l	#0,d2
	moveq.l	#OFFSET_END,d3
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	9$
	bra.b	2$
1$	move.l	a2,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
;	move.l	d4,d0
	lea	(transnltext),a0
	jsr	(writefileln)
	bne.b	9$
2$	move.l	d4,d1
	jsrlib	Close
	moveq.l	#0,d4
9$	move.l	d4,d0
	move.l	(exebase),a6
	pop	d2-d4/a2
	rts

;#c
searchmenu
	move.w	#32,(menunr,NodeBase)		;Skifter til Search menu
	rts

;#c
readmenyinfo
	bsr	getcurmsgnr
	beq	9$
	lea	(tmpmsgheader,NodeBase),a0
	move.w	(confnr,NodeBase),d1		; henter inn msgheader
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	8$
	lea	(tmpmsgheader,NodeBase),a1
	move.w	(NrLines,a1),d0			; net message ?
	bpl.b	2$				; Nope
	move.w	(confnr,NodeBase),d0		; henter inn msgtext
	move.l	(tmpmsgmem,NodeBase),a0
	jsr	(loadmsgtext)
	beq.b	1$
	lea	(errloadmsghtext),a0
8$	jsr	(writeerrori)
	bra.b	9$
1$	lea	(tmpmsgheader,NodeBase),a0
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	(isfromnetname)			; sjekker om det er net navn
	bne.b	3$				; nope, helt vanelig
	lea	(noinfoonnettext),a0		; sier vi ikke har info
	jsr	writetexto
	bra.b	9$
3$	lea	(tmpmsgheader,NodeBase),a1	; Vanelig bruker
2$	move.l	(MsgFrom,a1),d0
	bsr	showinfo
9$	rts

view	push	d2/d3/d4
	moveq.l	#0,d4
	move.w	(confnr,NodeBase),d0
	jsr	(getfrommsgnr)
	beq.b	9$
	move.l	d0,d3
	move.l	d0,d1
	move.w	(confnr,NodeBase),d0
	jsr	(gettomsgnr)
	beq.b	9$
	move.l	d0,d2
;	lea	wantmsggrwotext,a0
;	sub.l	a1,a1
;	moveq.l	#0,d0				; n er default
;	bsr	getyorn
;	beq.b	1$
;	bset	#1,d4				; vi skal ha ref
;1$	tst.b	readcharstatus(NodeBase)
;	notz
;	beq	9$
	lea	(detaledlisttext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	2$
	bset	#2,d4				; vi skal ha detailed
2$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	jsr	(outimage)
	beq.b	9$
	jsr	(outimage)
	beq.b	9$

	moveq.l	#0,d0
	btst	#2,d4
	beq.b	4$
	moveq.l	#1,d0
4$	move.w	d0,(tmpstore,NodeBase)

	move.w	(confnr,NodeBase),d0
	move.l	d3,d1
	lea	(viewfunc),a0
	btst	#1,d4
	bne.b	3$
	jsr	(dogroup)
	bra.b	9$
3$	jsr	(dogroupthreadwise)
9$	pop	d2/d3/d4
	rts

;	#1: Velkommen
;	#1, Sysop to ALL re: Velkommen!

; kalles ifra dothread eller dogroup
; rutinen får msgheader'en i a3
viewfunc
	push	d2
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	jsr	(kanskrive)
	clrn
	bne	9$

	move.l	a3,a0
	jsr	(isnetmessage)
	setn
	beq	9$				; ut

	move.b	#'#',d0
	jsr	(writechar)
	move.l	(Number,a3),d0
	jsr	(skrivnr)

	move.w	(tmpstore,NodeBase),d0
	beq	5$

	lea	(kommaspacetext),a0
	jsr	(writetext)
	move.l	(MsgFrom,a3),d0
	jsr	(getusername)
	move.w	d0,d2			; lagrer death status
	jsr	(writetext)
	btst	#USERB_Killed,d2
	beq.b	1$
	lea	(deadtext),a0
	jsr	(writetext)
1$	lea	(tonoansitext),a0
	jsr	(writetext)

	move.l	(MsgTo,a3),d0
	lea	(alltext),a0
	moveq.l	#-1,d1
	cmp.l	d1,d0
	beq.b	2$
	jsr	(getusername)
	move.w	d0,d2			; lagrer death status
	jsr	(writetext)
	btst	#USERB_Killed,d2
	beq.b	3$
	lea	(deadtext),a0
2$	jsr	(writetext)
3$	move.b	#' ',d0
	jsr	(writechar)
	lea	(subjecttext),a0
	jsr	(writetext)
	bra.b	4$

5$	lea	(kolonspacetext),a0
	jsr	(writetext)
4$	lea	(Subject,a3),a0
	jsr	(writetexto)
	clrn
	bne.b	9$
	setn
9$	pop	d2
	rts

;#c
movemsg	push	d2/a2/a3	;/d3/d4/d5
	bsr	getcurmsgnr
	beq	9$
	lea	(tmpmsgheader,NodeBase),a2
	move.l	(tmpmsgmem,NodeBase),a3
	move.w	(confnr,NodeBase),d1		; henter inn msgheader
	move.l	a2,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	2$
	move.l	a2,a0
	jsr	(allowmove)
	lea	(notallomovetext),a0
	bne	2$
	lea	(cnftmovemsgtext),a0
	jsr	(getconfname)
	beq	9$
	move.w	d0,d2				; husker konf nr'et
	cmp.w	(confnr,NodeBase),d0
	beq	9$				; er allerede i riktig.
	lsr.w	#1,d0
	lea	(cmmovtoconftext),a0
	cmpi.w	#2,d0
	beq	2$				; kan ikke flytte til userinfo
	cmpi.w	#3,d0				; eller fileinfo
	beq	2$
	move.w	d0,d1
	lea	(n_FirstConference+CStr,MainBase),a1
	mulu	#ConferenceRecord_SIZEOF,d1
	add.l	d1,a1
	move.w	(n_ConfSW,a1),d1
	btst	#CONFSWB_PostBox,d1		; er det en post konf ?
	beq	4$				; nei, alt ok
	move.l	(MsgTo,a2),d1			; er den til alle ?
	cmpi.l	#-1,d1
	beq	2$				; ja, fy..
	move.b	#SECF_SecReceiver,(Security,a2)	; Sørger for at den blir privat
	bra.b	3$
4$	move.l	(MsgTo,a2),d1			; er den til alle ?
	cmpi.l	#-1,d1
	beq	3$				; ja, ikke privat
	move.b	#SECF_SecNone,(Security,a2)	; sletter security
	move.w	(n_ConfSW,a1),d1
	btst	#CONFSWB_Private,d1		; Kan vi ha privat her ?
	beq.b	3$				; nei

	lea	(privatemsgetext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	5$
	move.b	#SECF_SecReceiver,(Security,a2)

5$	move.w	d2,d0
	lsr.w	#1,d0
3$	lea	(u_almostendsave+CU,NodeBase),a0 ; har vi skrive access der ?
	mulu	#Userconf_seizeof,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.w	#ACCF_Write,d0
	lea	(youarenottext),a0
	beq.b	2$				; Nei, FY!
	move.w	(confnr,NodeBase),d0
	move.l	a2,a1
	move.l	a3,a0
	jsr	(loadmsgtext)
	lea	(errloadmsgttext),a0
	bne.b	2$
	moveq.l	#0,d0
;	move.l	RefTo(a2),d3			; huske ref'ene
;	move.l	RefBy(a2),d4
;	move.l	RefNxt(a2),d5
	move.l	d0,(RefTo,a2)			; sletter referanser
	move.l	d0,(RefBy,a2)
	move.l	d0,(RefNxt,a2)

	move.l	a3,a0				; lagrer meldingen i ny konf
	move.l	a2,a1
	move.w	d2,d0
	move.l	(Number,a2),d2			; husker msg nummer
	jsr	(savemsg)
	lea	(cnotsavemsgtext),a0
	bne.b	2$

; disse ble ikke brukt
; d3 = hvilken melding vi er svar på
; d4 = svar på denne meldingen
; d5 = neste i denne tråden.

	move.l	d2,d0
	move.w	(confnr,NodeBase),d1		; henter inn msgheader en gang til
	move.l	a2,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	2$
	ori.b	#MSTATF_Dontshow+MSTATF_Moved,(MsgStatus,a2)	; Dreper denne kopien
	move.w	(confnr,NodeBase),d0
	move.l	a2,a0
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	2$
	lea	(msgmovedtext),a0
2$	jsr	(writetexto)
9$	pop	d2/a2/a3	;/d3/d4/d5
	rts

;#c
getcurmsgnr
	move.l	(currentmsg,NodeBase),d0	; Har vi lest en melding ??
	bne.b	9$			; jepp
	lea	(nocurentmsgtext),a0	; Feilmelding
	jsr	(writeerroro)		; skriv
	setz
9$	rts

;#c
; Får samme security som meldingen man svarer på.
replymsg
	push	d3/a2/a3/d4/d5/d6/d7
	jsr	(sjekklovtilaaskrive)		; har vi skrive access ?
	beq	99$				; nei
	tst.b	(readlinemore,NodeBase)		; har brukeren tastet mere ?
	beq.b	1$				; nei, vanlig reply
	jsr	(readline)			; leser inn tallet
	beq	99$				; aborted.
	jsr	(atoi)
	lea	(invalidnrtext),a0
	bmi	8$				; det var ikke et tall
	move.l	d0,d3				; husker meldings nummeret
	bra.b	2$

1$	bsr	(getcurmsgnr)			; få current msg nr.
	beq	99$				; ingen, ut
	move.l	d0,d3				; og husker.

2$	move.l	d3,d0
	move.w	(confnr,NodeBase),d1		; henter inn msgheader
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a1
	move.l	(tmpmsgmem,NodeBase),a3
	move.l	a3,a0
	jsr	(loadmsg)			; leser inn hele meldingen
	lea	(msgnotavailfrep),a0
	bne	8$				; error
	move.w	(NrBytes,a2),d0
	move.b	#0,(0,a3,d0.w)			; terminerer
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(kanskrive)			; Kan vi skrive ut denne ???
	lea	(msgnotavailfrep),a0
	bne	8$
	move.l	a3,d5				; default msgstart
	move.l	a2,a0
	jsr	(doisnetmessage)		; er det nettmelding ?
	bne.b	3$				; nei, fortsetter som før 
	move.l	a3,a0				; gjør om net from til net to
	move.b	(a0),d0				; er det en from her ?
	cmp.b	#Net_ToCode,d0
	bne.b	4$
	move.b	#Net_FromCode,(a3)		; faker..
	bra.b	3$
4$	cmp.b	#Net_FromCode,d0
	bne.b	3$				; nope.
	move.b	#Net_ToCode,(a3)		; gjør om til too.
	move.l	a3,a0
	jsr	(skiptonewline)
	move.l	a0,d5				; ny msg start (tar vare på to)
3$	move.l	(MsgFrom,a2),d1
	cmp.b	#Net_ToCode,(a3)		; var det en too her ?
	bne.b	5$				; nei
	moveq.l	#-1,d1				; ja, sier til all, så ingen skal få til seg..
5$	moveq.l	#16,d0				; Status = reply msg.
	jsr	(changenodestatus)
	cmp.b	#Net_ToCode,(a3)		; var det en too her ?
	beq.b	6$				; nei
	move.l	(MsgFrom,a2),d0			; sjekker om mottaker fortsatt
	move.w	(confnr,NodeBase),d1		; er medlemm i konf'en.
	jsr	(checkmemberofconf)
	lea	(loadusererrtext),a0
	bmi	8$
	lea	(sorryusnmoctext),a0
	beq	8$				; det var han/hun ikke
6$	move.l	(Number,a2),(RefTo,a2)		; setter opp meldins pekerne
	moveq.l	#0,d0
	move.l	d0,(RefBy,a2)
	move.l	d0,(RefNxt,a2)
	move.w	(confnr,NodeBase),d1		; henter frem et midlertidig
	mulu	#ConferenceRecord_SIZEOF/2,d1	; meldings nummer
	lea	(n_FirstConference+CStr,MainBase),a0
	add.l	d1,a0
	move.l	a0,d7				; husker confstruktur
	move.l	(n_ConfDefaultMsg,a0),d0
	addq.l	#1,d0
	move.l	d0,(Number,a2)
	move.l	(MsgFrom,a2),(MsgTo,a2)		; fyller i resten av meldings
	move.l	(Usernr+CU,NodeBase),(MsgFrom,a2)	; headeren
	lea	(MsgTimeStamp,a2),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	d5,a0				; har vi net subject ?
	jsr	(getnetsubject)
	beq.b	7$				; nope
	move.l	a0,a1
	moveq.l	#60,d0				; 60 er et fint tall...
	bra.b	10$				; fortsetter som normalt
7$	moveq.l	#Sizeof_NameT,d0		; default size
	move.l	d7,a1				; Finner ut om vi kan ha net meldinger
	move.w	(n_ConfSW,a1),d1
	btst	#CONFSWB_Network,d1
	beq.b	11$				; ikke net conf..
	moveq.l	#60,d0				; 60 er et fint tall...
11$	lea	(Subject,a2),a1
10$	lea	(entersubjectext),a0		; lar brukeren forandre subject
	jsr	(mayedlineprompt)
	beq	9$
	move.l	a0,a1				; husker svar
	jsr	(strlen)
	moveq.l	#Sizeof_NameT,d1
	cmp.l	d0,d1
	bcs.b	12$				; ikke plass i header strukturen
	move.l	a1,a0
	lea	(Subject,a2),a1
	jsr	(strcopy)			; sjekk om vi skal slette net subject, hvis ja, slett
	suba.l	a1,a1				; har ikke subject lengre
	moveq.l	#0,d0				; subject length = 0
12$	move.l	a1,a0				; plaserer subject
	move.l	d5,a1				; meldingen
	move.l	d5,d1
	sub.l	a3,d1
	neg.l	d1
	add.l	(msgmemsize,NodeBase),d1
	jsr	(packnetmessage)		; d0 = subject length
	move.l	a0,a3
	bclr	#MsgBitsB_FromNet,(MsgBits,a2)
	move.b	(Security,a2),d0
	andi.b	#SECF_SecReceiver,d0		; Den er allerede privat
	bne.b	13$
	move.l	d7,a0
	move.w	(n_ConfSW,a0),d0
	btst	#CONFSWB_Private,d0		; kan vi ha privat ?
	beq.b	13$				; nei
	lea	(privatemsgetext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	14$
	move.b	#SECF_SecReceiver,(Security,a2)
	bra.b	13$
14$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
13$	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop+MSTATF_Moved+MSTATF_Dontshow,d0
	bne.b	16$				; flyttede og killed meldinger, ingen include
	move.w	(Userbits+CU,NodeBase),d1		; bare FSE har include.
	btst	#USERB_FSE,d1			; Brukrer vi FSE ???
	beq.b	16$				; Nei, ingen include
	lea	(includeomsgtext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	beq.b	15$
	move.b	#2,(FSEditor,NodeBase)		; Vi skal includere.
	bra.b	16$
15$	tst.b	(readcharstatus,NodeBase)	; Ikke include
	notz
	beq	9$
16$	move.b	#MSTATF_NormalMsg,(MsgStatus,a2) ; setter dette til en normal melding
	move.l	a3,a0				; oppdaterer NrBytes
	jsr	(strlen)
	move.w	d0,(NrBytes,a2)
	move.l	a2,a0
	move.l	a3,a1
	move.l	(msgmemsize,NodeBase),d0
	move.l	a3,d4
	sub.l	(tmpmsgmem,NodeBase),d4		; d4 er "ekstra info"
	sub.l	d4,d0
	move.l	(tmpmsgmem,NodeBase),d1
	jsr	(calleditor)
	beq	17$				; abort/carrier borte osv.
	tst.l	d4				; var det net melding ?
	beq.b	18$
	neg.w	(NrLines,a2)			; merker det som det
	add.w	d4,(NrBytes,a2)			; legger til size for ekstra
	move.l	(tmpmsgmem,NodeBase),a3
	move.l	a3,a0				; og klar for save
18$	move.l	a2,a1
	move.w	(confnr,NodeBase),d0
	jsr	(savemsg)
	lea	(cnotsavemsgtext),a0
	bne	8$
	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	(Number,a2),d2
	move.l	d2,d0
	jsr	(skrivnr)
	lea	(savedtext),a0
	jsr	(writetexto)
	move.l	(Number,a2),d0
	bsr	stopreviewmessages
	addq.w	#1,(MsgsLeft+CU,NodeBase)
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	move.l	a3,a1
	jsr	(sendintermsgmsg)

	move.l	d3,d1				; meldings nummeret
	lea	(logreplymsgtext),a0
	move.w	(confnr,NodeBase),d0
	jsr	(killrepwritelog)

	move.l	d3,d0				; meldings nummeret vi svarte på
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	9$
	move.l	(RefBy,a2),d0			; har vi svar ?
	bne.b	19$				; ja, må gå til slutten
	move.l	d2,(RefBy,a2)			; Dette er første svar.
	bra.b	20$
19$	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	9$
	move.l	(RefNxt,a2),d0
	bne.b	19$				; loop'er for å finne siste
	move.l	d2,(RefNxt,a2)			; Setter inn sist i kjeden.
20$	move.w	(confnr,NodeBase),d0
	move.l	a2,a0
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	8$
	bra.b	9$

17$	tst.b	(readcharstatus,NodeBase)	; skjedde det noe spes ?
	notz
	beq	9$				; jepp, ut me'n..
	lea	(msgtext1),a0			; tar abort
	jsr	(writetext)
	move.l	(Number,a2),d0
	jsr	(skrivnr)
	lea	(abortedtext),a0
	jsr	(writetexto)
	bra.b	9$

8$	jsr	(writeerroro)
9$	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
99$	pop	d3/a2/a3/d4/d5/d6/d7
	rts

;#c
duplicatemessage
	push	a2/d2/d3/a3
	bsr	getcurmsgnr		; henter msg nr
	beq	9$			; error (var ingen current)
	move.l	d0,d2			; husker msgnr
	move.w	(confnr,NodeBase),d1	; henter inn msg header
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	lea	(msgnotavailfrep),a0
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop+MSTATF_Moved+MSTATF_Dontshow,d0
	bne	8$
	move.l	a2,a0
	jsr	(isnetmessage)
	beq	9$				; ut
	jsr	(justchecksysopaccess)
	bne.b	10$				; vi er sysop, så vi kan dup'e
	lea	(onlydupownmtext),a0
	move.l	(MsgFrom,a2),d0
	cmp.l	(Usernr+CU,NodeBase),d0		; Er vi avsender ?
	bne	8$				; nope
10$	lea	(changetoadrtext),a0
	moveq.l	#1,d0				; vi godtar all
	move.w	(confnr,NodeBase),d1		; Finner ut om vi er i en postpox
	lea	(n_FirstConference+CStr,MainBase),a3
	mulu	#ConferenceRecord_SIZEOF/2,d1
	add.l	d1,a3
	move.w	(n_ConfSW,a3),d1
	btst	#CONFSWB_PostBox,d1
	beq.b	6$
	moveq.l	#0,d0				; vi godtar ikke all
6$	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	bne.b	2$
	move.b	(readcharstatus,NodeBase),d1
	bne	9$
	bra.b	1$
2$	move.l	d0,d3
	moveq.l	#-1,d1
	cmp.l	d3,d1				; til all ?
	bne.b	4$				; nope
	btst	#SECB_SecReceiver,(Security,a2)	; privat ?
	beq.b	5$				; nope, alt ok.
	lea	(allnotallowtext),a0
	bra	8$

4$	move.w	(confnr,NodeBase),d1
	jsr	(checkmemberofconf)
	bne.b	5$
	lea	(loadusererrtext),a0
	bmi	8$
	lea	(sorryusnmoctext),a0
	bra	8$
5$	move.l	d3,(MsgTo,a2)
1$	bclr	#MsgBitsB_FromNet,(MsgBits,a2)
	lea	(entersubjectext),a0
	lea	(Subject,a2),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(mayedlineprompt)
	beq.b	3$
	lea	(Subject,a2),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)
3$	move.b	(readcharstatus,NodeBase),d1
	bne	9$
	move.l	(n_ConfDefaultMsg,a3),d0
	addq.w	#1,d0
	move.l	d0,(Number,a2)
	moveq.l	#0,d0
	move.l	d0,(RefTo,a2)				; sletter referanser
	move.l	d0,(RefBy,a2)
	move.l	d0,(RefNxt,a2)
	move.l	(tmpmsgmem,NodeBase),a0
	move.w	(confnr,NodeBase),d0
	move.l	a2,a1
	jsr	(loadmsgtext)
	lea	(errloadmsgttext),a0
	bne	8$
	move.b	#2,(FSEditor,NodeBase)	; Vi skal includere.
	lea	(MsgTimeStamp,a2),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	a2,a0
	move.l	(msgmemsize,NodeBase),d0
	move.l	(tmpmsgmem,NodeBase),a1
	move.l	a1,d1
	jsr	(calleditor)
	beq	7$
	move.l	a2,a1
	move.w	(confnr,NodeBase),d0
	jsr	(savemsg)
	lea	(cnotsavemsgtext),a0
	bne	8$
	move.l	(Number,a2),d0
	exg	d2,d0
	move.w	(confnr,NodeBase),d1			; henter inn msg header
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	move.l	a2,a0
	bsr	killmsgwhodidit
	or.b	d0,(MsgStatus,a2)			; Dreper denne kopien
	move.l	a2,a0					; og lagrer den igjen
	move.w	(confnr,NodeBase),d0
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne	8$
	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	d2,d0
	jsr	(skrivnr)
	lea	(savedtext),a0
	jsr	(writetexto)
	move.l	d2,d0
	bsr	stopreviewmessages
	addq.w	#1,(MsgsLeft+CU,NodeBase)
	move.l	d2,(Number,a2)
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	move.b	#0,(i_pri,a0)
	move.l	(tmpmsgmem,NodeBase),a1
	jsr	(sendintermsgmsg)
	move.l	(Number,a2),d1
	lea	(logentermsgtext),a0
	move.w	(confnr,NodeBase),d0			; conf nr
	jsr	(killrepwritelog)
	bra.b	9$

7$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	lea	(msgtext1),a0
	jsr	(writetext)
	move.l	(Number,a2),d0
	jsr	(skrivnr)
	lea	(abortedtext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	pop	a2/d2/d3/a3
	rts

;#c	READ MESSAGE
readmsg	move.l	(msgqueue,NodeBase),d0
	bne.b	1$
	jsr	(unjoin)
	lea	(checkfmsgictext),a0
	jsr	(writetexto)
	beq.b	9$
	jsr	(joinnextunreadconf)
	lea	(nonewiacmsgtext),a0
	beq.b	8$
	bra.b	9$

1$	lea	(skipnextmsgtext),a0
	jsr	(writetexto)
	beq.b	9$
	move.l	(msgqueue,NodeBase),d0
	move.w	(confnr,NodeBase),d1
	move.l	d0,(currentmsg,NodeBase)
	jsr	(typemsg)
	lea	(msgnotfoundtext),a0
	bmi.b	8$
	move.l	(msgqueue,NodeBase),d0
	bne.b	9$
	lea	(nomoremsgictext),a0
8$	jsr	(writetexto)
9$	rts

;#c
originalmsg				; Søker seg bakover i thread'en og
	movem.l	a2/d2,-(sp)		; skriver ut orginalen (RefTo = 0)
	bsr	getcurmsgnr
	beq.b	9$
1$	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	move.l	d0,d2
	jsr	(loadmsgheader)
	bne.b	5$
	move.l	(RefTo,a2),d0
	bne.b	1$
	move.w	(confnr,NodeBase),d1
	move.l	(Number,a2),d0
	jsr	(typemsg)
	bmi.b	9$
	move.l	(Number,a2),(currentmsg,NodeBase)
	bra.b	9$
5$	lea	(orgnotavailtext),a0
	jsr	(writetexto)
9$	movem.l	(sp)+,a2/d2
	rts

;#c
readcurrentmsg				; Skriver ut current msg i denne conf
	bsr	getcurmsgnr
	beq.b	9$
	moveq.l	#0,d1
	move.w	(confnr,NodeBase),d1
	jsr	(typemsg)
	bpl.b	9$
	lea	(msgnotfoundtext),a0	; Feil !
	jsr	(writetexto)
	clr.l	(currentmsg,NodeBase)		; Ikke en gang til !
9$	rts

;#c
previusmsg
	movem.l	a2/d2,-(sp)
	lea	(tmpmsgheader,NodeBase),a2
	move.l	(currentmsg,NodeBase),d2		; har vi lest en melding ?
	bne.b	1$				; ja
	move.w	(confnr,NodeBase),d0		; nei, da tar vi siste melding
	mulu	#ConferenceRecord_SIZEOF/2,d0	; i konferansen
	lea	(n_FirstConference+CStr,MainBase),a0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d2
	bra.b	2$
1$	subq.l	#1,d2
	bne.b	2$
	lea	(firstmsgtext),a0
	jsr	(writeerroro)
	bra.b	9$
2$	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	move.l	d2,d0
	jsr	(loadmsgheader)
	beq.b	4$
	lea	(errloadmsghtext),a0
	jsr	(writetexti)
	bra.b	9$
4$	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(kanskrive)
	bne.b	1$
	move.l	d2,d0
	move.w	(confnr,NodeBase),d1
	jsr	(typemsg)
	bpl.b	3$
	lea	(msgnotfoundtext),a0
	jsr	(writetexto)
	bra.b	9$
3$	move.l	d2,(currentmsg,NodeBase)
9$	movem.l	(sp)+,a2/d2
	rts

;#c
nextmsg	movem.l	a2/d2/d3,-(sp)
	lea	(tmpmsgheader,NodeBase),a2
	move.l	(currentmsg,NodeBase),d2
	move.w	(confnr,NodeBase),d0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d3
1$	addq.l	#1,d2
	cmp.l	d2,d3
	bcc.b	2$
	lea	(lastmsgtext),a0
	jsr	(writeerroro)
	bra.b	9$
2$	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	move.l	d2,d0
	jsr	(loadmsgheader)
	beq.b	4$
	lea	(errloadmsghtext),a0
	jsr	(writetexti)
	bra.b	9$
4$	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(kanskrive)
	bne.b	1$
	move.l	d2,d0
	move.w	(confnr,NodeBase),d1
	jsr	(typemsg)
	bpl.b	3$
	lea	(msgnotfoundtext),a0
	jsr	(writetexto)
	bra.b	9$
3$	move.l	d2,(currentmsg,NodeBase)
9$	movem.l	(sp)+,a2/d2/d3
	rts

;#c
readreply
	movem.l	a2/d2,-(sp)
	lea	(tmpmsgheader,NodeBase),a2
	bsr	getcurmsgnr
	beq.b	9$
	move.w	(confnr,NodeBase),d1
	move.l	a2,a0
	jsr	(loadmsgheader)
	beq.b	2$
;error
	bra.b	9$
2$	move.l	(RefBy,a2),d2
	beq.b	4$
	move.l	d2,d0
	move.w	(confnr,NodeBase),d1
	jsr	(typemsg)
	bpl.b	3$
	lea	(msgnotfoundtext),a0
	jsr	(writetexto)
	bra.b	9$
4$	lea	(noreplytext),a0
	jsr	(writetexto)
	bra.b	9$
3$	move.l	d2,(currentmsg,NodeBase)
9$	movem.l	(sp)+,a2/d2
	rts

;#c
readotherreply
	push	a2/d2
	lea	(tmpmsgheader,NodeBase),a2
	bsr	getcurmsgnr
	beq.b	9$
	move.w	(confnr,NodeBase),d1
	move.l	a2,a0
	jsr	(loadmsgheader)
	beq.b	2$
;error
	bra.b	9$
2$	move.l	(RefNxt,a2),d2
	lea	(nomreplytext),a0
	beq.b	4$
	move.l	d2,d0
	move.w	(confnr,NodeBase),d1
	jsr	(typemsg)
	bpl.b	3$
	lea	(msgnotfoundtext),a0
4$	jsr	(writetexto)
	bra.b	9$
3$	move.l	d2,(currentmsg,NodeBase)
9$	pop	a2/d2
	rts

;#c
readbackinthread
	push	a2/d2
	lea	(tmpmsgheader,NodeBase),a2
	bsr	getcurmsgnr
	beq.b	9$
	move.w	(confnr,NodeBase),d1
	move.l	a2,a0
	jsr	(loadmsgheader)
	beq.b	2$
;error
	bra.b	9$
2$	move.l	(RefTo,a2),d2
	lea	(msgnotreplytext),a0
	beq.b	4$
	move.l	d2,d0
	move.w	(confnr,NodeBase),d1
	jsr	(typemsg)
	bpl.b	3$
	lea	(msgnotfoundtext),a0
4$	jsr	(writetexto)
	bra.b	9$
3$	move.l	d2,(currentmsg,NodeBase)
9$	pop	a2/d2
	rts

;#c
killmsg	move.l	a2,-(sp)
	bsr	getcurmsgnr
	beq	9$
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	beq.b	7$
	lea	(errloadmsghtext),a0
	bra.b	99$
7$	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	beq.b	6$
	lea	(msgalkilledtext),a0
	bra.b	99$
6$	move.l	a2,a0
	jsr	(allowkill)
	beq.b	2$			; Ja, hopp
	lea	(notallokilltext),a0
	bra.b	99$
2$	move.l	a2,a0
	bsr	killmsgwhodidit
	or.b	d0,(MsgStatus,a2)
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	99$
	move.l	(Number,a2),d1
	lea	(logkiledmsgtext),a0
	move.w	(confnr,NodeBase),d0		; conf nr
	jsr	(killrepwritelog)
	lea	(msgkilledtext),a0
99$	jsr	(writetexto)
9$	move.l	(sp)+,a2
	rts

killmsgwhodidit
	move.l	(Usernr+CU,NodeBase),d0
	cmp.l	(MsgFrom,a0),d0
	bne.b	1$
3$	move.w	#MSTATF_KilledByAuthor,d0
	bra.b	9$
1$	cmp.l	(MsgTo,a0),d0
	beq.b	3$
	jsr	(justchecksysopaccess)		; er vi sysop ?
	bne.b	2$				; ja
	move.w	#MSTATF_KilledBySigop,d0
	bra.b	9$
2$	move.w	#MSTATF_KilledBySysop,d0
9$	rts

;#c
unkillmsg
	move.l	a2,-(sp)
	bsr	getcurmsgnr
	beq.b	9$
	move.w	(confnr,NodeBase),d1
	cmpi.w	#4,d1			; nekter å unkill'e ifra resyme og fileinfo
	beq.b	1$
	cmpi.w	#6,d1
	beq.b	1$
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	jsr	(loadmsgheader)
	beq.b	7$
	lea	(errloadmsghtext),a0
	bra.b	99$
7$	move.l	a2,a0
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	bne.b	6$
	lea	(msgnokilledtext),a0
	bra.b	99$
6$	jsr	(allowunkill)
	beq.b	2$			; Ja, hopp
1$	lea	(notallukilltext),a0
	bra.b	99$
2$	andi.b	#~(MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop),(MsgStatus,a2)
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(savemsgheader)
	lea	(msgunkilledtext),a0
	beq.b	99$
	lea	(cntsavemsghtext),a0
99$	jsr	(writetexto)
9$	move.l	(sp)+,a2
	rts

;#c
markmenu
	move.w	#24,(menunr,NodeBase)		;Skifter til mark menu
	rts

;#c
readmode
	move.w	(Savebits+CU,NodeBase),d0
	eori.w	#SAVEBITSF_ReadRef,d0
	IFND DEMO
	cmp.w	#%100111,d0
	bne.b	1$
	move.b	#$f2,(con_tegn,NodeBase)
1$
	ENDC
	move.w	d0,(Savebits+CU,NodeBase)
	rts

;#c
resignconference
	push	a2
	move.w	(confnr,NodeBase),d0
	cmp.w	#4,d0
	bcs.b	3$
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_FirstConference+CStr,MainBase),a2
	add.l	d0,a2
	move.w	(n_ConfSW,a2),d1
	btst	#CONFSWB_Resign,d1
	bne.b	1$
3$	lea	(ycantresigntext),a0
	jsr	(writeerroro)
	bra.b	9$
1$	lea	(sureywresfctext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$
	lea	(n_ConfName,a2),a1		; husker navnet
	move.w	(confnr,NodeBase),d0
	lea	(u_almostendsave+CU,NodeBase),a2
	mulu	#Userconf_seizeof/2,d0
	lea	(uc_Access,a2,d0.l),a2
	move.w	(a2),d0
	bclr	#ACCB_Read,d0			; sletter read flag'et
	move.w	d0,(a2)
	lea	(logresconftext),a0
	jsr	(writelogtexttimed)
	move.l	a2,a0
	moveq.l	#2,d0				; lagrer den ene word'n
	jsr	(saveuserarea)
	beq.b	2$
	lea	(resigningartext),a0
	jsr	(writetext)
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a0
	jsr	(writetexto)
2$	moveq.l	#0,d0				; Joiner News (den kan vi jo
	bsr	joinnr				; aldri resigne fra)
9$	pop	a2
	rts

;#c
savereadptrs
	push	a6/d2/d3/d4			; leser inn readptr'ene ifra fil
	move.l	(dosbase),a6
	bsr	getreadpointerfname		; (lagrer backup der)
	move.l	a0,d3
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.b	1$				; finnes ikke ifra før
	jsrlib	UnLock
	clrz					; den fantes,
	bra.b	9$				; ferdig
1$	move.l	d3,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4				; husker ptr
	beq.b	9$				; ingen fil. ut
	move.l	d4,d1
	move.w	(Maxconferences+CStr,MainBase),d3
	mulu	#Userconf_seizeof,d3
	lea	(u_almostendsave+CU,NodeBase),a1
	move.l	a1,d2
	jsrlib	Write
	move.l	d4,d1
	jsrlib	Close
	clrz
9$	pop	a6/d2/d3/d4
	rts
;#c
restorereadpointers
	push	a6/d2/d3/d4			; leser inn readptr'ene ifra fil
	bsr	getreadpointerfname		; (lagrer backup der)
	move.l	a0,d1
	move.l	(dosbase),a6
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4			; husker ptr
	beq.b	9$			; ingen fil. ut
	move.l	d4,d1
	move.w	(Maxconferences+CStr,MainBase),d3
	mulu	#Userconf_seizeof,d3
	lea	(u_almostendsave+CU,NodeBase),a1
	move.l	a1,d2
	jsrlib	Read
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d2,d3
	notz
	beq.b	9$
	bsr	deletereadpointersfile
	clrz
9$	pop	a6/d2/d3/d4
	rts

getreadpointerfname
	lea	(tmptext,NodeBase),a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	lea	(readptrfname),a0
	jsr	(strcopy)
	lea	(tmptext,NodeBase),a0
	rts

deletereadpointersfile
	push	a6
	bsr	getreadpointerfname
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DeleteFile
	pop	a6
	rts

; returnerer:
; a0 = pattern for å få med seg alle scratchpad filene
; a1 = dirnavnet hvor scratchpad ligger
getscratchpaddelfname
	lea	(tmptext,NodeBase),a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	move.b	#0,(a1)
	lea	(BaseName+CStr,MainBase),a0
	move.b	(GrabFormat+CU,NodeBase),d0	; hvilket format skal de ha ?
	beq.b	1$				; MBBS
	lea	(allqwksendfiles),a0		; tar QWK navnet
	cmp.b	#1,d0
	beq.b	1$
	lea	(allhipsendfiles),a0
1$	lea	(tmptext,NodeBase),a1
	rts

getscratchpadfname
	lea	(tmptext,NodeBase),a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	(strcopy)
	move.b	#'/',(-1,a1)
	lea	(BaseName+CStr,MainBase),a0
	move.b	(GrabFormat+CU,NodeBase),d0	; hvilket format skal de ha ?
	beq.b	1$				; MBBS
	lea	(qwkmsgdatfile),a0		; tar QWK navnet
1$	jsr	(strcopy)
	cmp.b	#2,d0				; hippo ?
	bne.b	2$
	lea	(-1,a1),a1
	lea	(hippoextension),a0
	jsr	(strcopy)
2$	lea	(tmptext,NodeBase),a0
	rts

;#c
grab	moveq.l	#1,d0
	bsr	dumpall1
	beq.b	9$
	bsr	sendscratch
9$	rts

;#c
ungrab	move.b	(GrabFormat+CU,NodeBase),d0		; hvilket format skal de ha ?
	lea	(mbbsnomsguptext),a0
	beq.b	8$					; mbbs har ikke MU...
	lea	(hippnomsguptext),a0
	cmp.b	#2,d0
	beq.b	8$					; HIPPO har ikke MU (enda)...
	bsr	getscratch
	beq.b	9$					; error
	XREF	_unpackmessages
	jsr	(_unpackmessages)
	bra.b	9$
8$	jsr	(writeerroro)
9$	rts

;#e
*****************************************************************
*			Sysop/Sigop meny			*
*****************************************************************

;#b
;#c
	STRUCTURE	cleanstruct,0
	ULONG	morelogons
	ULONG	lesslogons
	ULONG	moredownloads
	ULONG	lessdownloads
	ULONG	moremsgread
	ULONG	lessmsgread
	ULONG	logonnotafter
	ULONG	logonafter
	UBYTE	nogeneraldlacc
	UBYTE	generaldlacc	
	LABEL	cleanstruct_sizeof

cleanuserfile
	link.w	a3,#-cleanstruct_sizeof
	jsr	(checksysopaccess)
	beq	9$
	move.b	#0,(readlinemore,NodeBase)	; flush'er input
	move.l	sp,a0
	moveq.l	#cleanstruct_sizeof,d0
	jsr	(memclr)
	lea	(cleanuser1text),a0
	jsr	(writetexto)
	lea	(cleanuser2text),a0
	jsr	(writetexto)
	lea	(cleanuser3text),a0
	bsr	10$
	bmi	9$
	beq.b	1$
	move.l	d0,(morelogons,sp)

1$	lea	(cleanuser4text),a0
	bsr	10$
	bmi	9$
	beq.b	2$
	move.l	d0,(lesslogons,sp)

2$	lea	(cleanuser5text),a0
	bsr	10$
	bmi	9$
	beq.b	3$
	move.l	d0,(moredownloads,sp)

3$	lea	(cleanuser6text),a0
	bsr	10$
	bmi.b	9$
	beq.b	4$
	move.l	d0,(lessdownloads,sp)

4$	lea	(cleanuser7text),a0
	bsr	10$
	bmi.b	9$
	beq.b	5$
	move.l	d0,(moremsgread,sp)

5$	lea	(cleanuser8text),a0
	bsr	10$
	bmi.b	9$
	beq.b	6$
	move.l	d0,(lessmsgread,sp)

6$	lea	(cleanuser9text),a0
	bsr	20$
	bmi.b	9$
	beq.b	7$
	move.l	d0,(logonnotafter,sp)

7$	lea	(cleanuser10text),a0
	bsr	20$
	bmi.b	9$
	beq.b	8$
	move.l	d0,(logonafter,sp)

8$	lea	(cleanuser11text),a0
	bsr	30$
	bmi.b	9$
	beq.b	81$
	move.b	#1,(nogeneraldlacc,sp)

81$	lea	(cleanuser12text),a0
	bsr	30$
	bmi.b	9$
	beq.b	82$
	move.b	#1,(generaldlacc,sp)
82$
	move.l	sp,a0
	bsr	docleanuserfile

9$	unlk	a3
	rts

10$	push	a2/a3
	move.l	a0,a3
11$	suba.l	a1,a1
	suba.l	a2,a2				; ingen ekstra help
	jsr	(readlinepromptwhelp)
	bne.b	13$
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	beq.b	19$				; nei, bare ingen input
	setn
	bra.b	19$				; ja, hopp ut
13$	jsr	(atoi)
	bpl.b	12$
	lea	(invalidnrtext),a0
	jsr	(writeerroro)
	move.l	a3,a0
	bra.b	11$				; det var ikke et tall
12$	clrzn
19$	pop	a2/a3
	rts

20$	push	a2/d2/d3/d4/a3
	move.l	a0,a3
21$	suba.l	a1,a1
	suba.l	a2,a2				; ingen ekstra help
	jsr	(readlinepromptwhelp)
	bne.b	23$
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	beq.b	29$				; nei, bare ingen input
	setn
	bra.b	29$				; ja, hopp ut
23$	jsr	(strtonr2)
	bmi.b	24$
	move.l	d0,d2		; år
	jsr	(strtonr2)
	bmi.b	24$
	move.l	d0,d3		; mnd
	jsr	(strtonr2)
	bmi.b	24$
	exg	d0,d2		; dag
	move.l	d3,d1
	jsr	(datetodays)
	bne.b	22$
24$	lea	(invaliddatetext),a0
	jsr	(writeerroro)
	move.l	a3,a0
	bra.b	21$				; det var ikke et tall
22$	clrzn
29$	pop	a2/d2/d3/d4/a3
	rts

30$	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	bne.b	32$				; ja
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	beq.b	39$				; nei, bare ingen input eller nei
	setn
	bra.b	39$				; ja, hopp ut
32$	clrzn
39$	rts

docleanuserfile
	push	d2/a2/a3
	move.l	(Tmpusermem,NodeBase),a2
	move.l	a0,a3				; husker strukturen
	moveq.l	#0,d2				; bruker nummer
	move.w	#-1,(linesleft,NodeBase)	; Vi vil ikke ha noe more i denne lista

1$	jsr	(testbreak)
	beq	9$
	move.l	d2,d0
	move.l	a2,a0
	jsr	(loadusernrnr)
	bmi	9$				; Error
	beq	9$				; EOF
	move.l	(Usernr,a2),d0			; Er dette supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	2$				; ja, aldri kill han
	move.w	(Userbits,a2),d0
	andi.w	#USERF_Killed,d0		; Er han død ?
	bne.b	2$				; ja, gi f... i han
	bsr	10$				; Oppfyller denne kriteriene ?
	bne.b	2$				; nope
	moveq.l	#0,d0
	lea	(20$),a0
	bsr	doshowuser
	beq	9$				; skal ut.
	jsr	(outimage)
	beq	9$				; skal ut.
	lea	(cleanuser13text),a0
	jsr	(writetexti)
3$	jsr	(readchar)
	beq.b	9$				; han forsvant
	bmi.b	3$				; Dropper spesial tegn.
	jsr	(upchar)
	cmp.b	#'S',d0
	beq.b	4$				; han vil ut
	cmp.b	#'N',d0
	beq.b	5$				; han vil han neste
	cmp.b	#'K',d0
	bne.b	3$				; Ukjennt tegn
	ori.w	#USERF_Killed,(Userbits,a2)
	move.l	a2,a0
	move.l	(Usernr,a2),d0
	jsr	(saveusernr)
	beq.b	8$				; Error
	move.b	#'K',d0
5$	jsr	(writechar)
	jsr	(outimage)
2$	addq.l	#1,d2
	bra	1$
4$	jsr	(writechar)
	jsr	(outimage)
	bra.b	9$
8$	jsr	(outimage)
	lea	(saveusererrtext),a0
	jsr	(writeerroro)
9$	pop	d2/a2/a3
	rts

20$	jmp	(writetexto)


10$	move.l	(TimesOn,a2),d0
	move.l	(morelogons,a3),d1
	beq.b	101$
	cmp.l	d1,d0
	bhi.b	17$
101$	move.l	(lesslogons,a3),d1
	beq.b	11$
	cmp.l	d1,d0
	bcs.b	17$

11$	move.l	(Downloaded,a2),d0
	move.l	(moredownloads,a3),d1
	beq.b	111$
	cmp.l	d1,d0
	bhi.b	17$
111$	move.l	(lessdownloads,a3),d1
	beq.b	12$
	cmp.l	d1,d0
	bcs.b	17$

12$	move.l	(MsgsRead,a2),d0
	move.l	(moremsgread,a3),d1
	beq.b	121$
	cmp.l	d1,d0
	bhi.b	17$
121$	move.l	(lessmsgread,a3),d1
	beq.b	13$
	cmp.l	d1,d0
	bcs.b	17$

13$	move.l	(LastAccess+ds_Days,a2),d0
	move.l	(logonafter,a3),d1
	beq.b	131$
	cmp.l	d1,d0
	bhi.b	17$
131$	move.l	(logonnotafter,a3),d1
	beq.b	14$
	cmp.l	d1,d0
	bcs.b	17$

14$	move.w	(uc_Access+u_almostendsave,a2),d0
	and.w	#ACCF_Download,d0		; isolerer download bitet
	beq.b	141$				; vi har ikke dl access
	move.b	(generaldlacc,a3),d1
	bne.b	17$
	bra.b	18$
141$	move.b	(nogeneraldlacc,a3),d1
	beq.b	18$
17$	setz
	bra.b	19$
18$	clrz
19$	rts

;#c
packuserfile
	jsr	(checksysopaccess)
	beq.b	9$
	move.b	#0,(readlinemore,NodeBase)	; flush'er input
	lea	(surepackusrtext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$
	lea	(takenbackuptext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$
	jsr	(lockoutallothernodes)
	lea	(younotalonetext),a0
	beq.b	8$
	lea	(thismaytaketext),a0
	jsr	(writetexto)
	bsr	dopackuserfile
	jsr	(unlockoutallothernodes)
	bra.b	9$
8$	jsr	writeerroro
9$	rts

dopackuserfile	; ! PUS
	push	a2/a3/d2/d3
	move.l	(Tmpusermem,NodeBase),a2	; scan userfile og husk hvem som skal vekk
	move.l	(tmpmsgmem,NodeBase),a3
	move.l	(msgmemsize,NodeBase),d3
	lsr.l	#2,d3
	subq.l	#1,d3				; antall brukere vi har plass til...
	moveq.l	#-1,d2

1$	addq.l	#1,d2				; Neste bruker
	move.l	d2,d0
	move.l	a2,a0
	jsr	(loadusernrnr)			; Hent bruker
	lea	(loadusererrtext),a0		
	bmi.b	8$				; Error
	beq.b	2$				; EOF
	move.l	(Usernr,a2),d0			; Er dette supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	1$				; ja, aldri fjerne han
	move.w	(Userbits,a2),d1
	andi.w	#USERF_Killed,d1		; Er han død ?
	beq.b	1$				; nei, sjekk neste
	subq.l	#1,d3
	beq.b	3$				; ikke plass til flere..
	move.l	d0,(a3)+			; lagrer brukernummeret
	bra.b	1$

3$	lea	(stablefullctext),a0
	jsr	(writetexto)
2$	moveq.l	#-1,d0
	move.l	d0,(a3)+			; lagrer slutten

;	jsr (_PackUserDoFiles)
	bsr	packuserdofiles			; Alle uploads -> fra sysop
	beq.b	9$				; error

	bsr	packuserdomessages		; Sletter alle meldinger
	beq.b	9$				; error

	bsr.b	packuserfiles			; Tar bort fysisk fra userfila (OK)
	beq.b	9$				; error

; fikse user filene
; rette opp configfile (Users/Maxusers..)

	bra.b	9$
8$	jsr	(writeerroro)
9$	pop	a2/a3/d2/d3
	rts

packuserfiles
	move.l	(msg,NodeBase),a1
	move.w	#Main_PackUserFile,(m_Command,a1)
	move.l	(Tmpusermem,NodeBase),a0
	move.l	a0,(m_Data,a1)
	move.l	(tmpmsgmem,NodeBase),(m_arg,a1)	; Tabell over brukere som skal slettes.
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	beq.b	9$
	jsr	skrivnrw
	lea	(errwpackingtext),a0
	jsr	(writeerroro)
	setz
9$	rts

; fikser alle message records i .h filene som følge av packuser
; meldinger til eller fra en av de som skal vekk, slettes
packuserdomessages
	push	a2/a3/d2/d3/d4/d5
	lea	(n_FirstConference+CStr,MainBase),a3
	moveq.l	#0,d2				; confnr
	lea	(tmpmsgheader,NodeBase),a2

1$	move.b	(n_ConfName,a3),d0		; conf her ?
	beq.b	2$				; nei..

	move.l	d2,d5				; d5 = 2
	add.l	d5,d5				; d5 = confnr * 2
	move.l	(n_ConfDefaultMsg,a3),d4	; d4 = max msg num
	moveq.l	#1,d3				; d3 = msg num

4$	cmp.l	d3,d4				; ferdig ?
	bcs.b	2$				; jepp
	move.l	d5,d1
	move.l	a2,a0
	move.l	d3,d0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	8$
	btst	#MSTATB_Dontshow,(MsgStatus,a2)	; kan vi vise denne meldingen ?
	bne.b	3$				; nei, ikke noe mere å gjøre da...
	move.l	(MsgFrom,a2),d0
	bsr	packusercheckusernr
	beq.b	5$				; var fra en bruker som som skal bort
	move.l	(MsgTo,a2),d0
	bsr	packusercheckusernr		; var til en bruker som som skal bort
	bne.b	3$
5$	bset	#MSTATB_Dontshow,(MsgStatus,a2)	; Sletter meldingen ordentelig.
	move.l	a2,a0
	move.l	d5,d0
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	8$

3$	addq.l	#1,d3
	bra.b	4$

2$	lea	(ConferenceRecord_SIZEOF,a3),a3
	addq.l	#1,d2
	cmp.w	(Maxconferences+CStr,MainBase),d2
	bcs.b	1$
	clrz
	bra.b	9$
8$	jsr	(writeerroro)
	move.l	d3,d0
	jsr	skrivnr
	move.l	a3,a0
	jsr	(writetexto)
	setz
9$	pop	a2/a3/d2/d3/d4/d5
	rts

; fikser file entries i alle .fl filene som følge av packuser
; filer privat til vedkommende, slettes
; filer uploadet av vedkommende, får sysop som uploader
packuserdofiles
	push	a2/a3/d2/d3
	moveq.l	#0,d2				; fikse .fl filer (uploadet og private to)
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	lea	(tmpfileentry,NodeBase),a2
4$	move.b	(n_DirName,a3),d0		; dir her ?
	beq	5$				; nei..

; scanner alle filene i denne fildir'en
	moveq.l	#1,d3				; starter på første fil.
6$	move.l	(msg,NodeBase),a1
	move.w	#Main_loadfileentry,(m_Command,a1)
	move.l	d2,(m_UserNr,a1)		; fildir*1
	move.l	d3,(m_arg,a1)			; filnr
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_EOF,d0
	beq.b	5$				; eof, fortsett med neste dir
	lea	(errloadfilhtext),a0
	cmpi.w	#Error_OK,d0			; error ?
	bne.w	8$				; jepp, abort
	move.w	(Filestatus,a2),d0
	move.w	d0,d1				; er den allerede "slettet" ?
	andi.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d1
	bne.b	7$				; jepp, skip

	btst	#FILESTATUSB_PrivateUL,d0	; private ?
	beq.b	61$				; nei.
	move.l	(PrivateULto,a2),d0		; sjekker om den er til en av de drepte.
	bsr	packusercheckusernr
	beq.b	100$				; var der
	move.l	(Uploader,a2),d0		; sjekker om den er fra en av de drepte.
	bsr	packusercheckusernr
	beq.b	100$				; var der
	bsr.b	61$
; sletter fila
100$	ori.w	#FILESTATUSF_Fileremoved,(Filestatus,a2)
	bsr	10$
	bne.b	8$
	lea	(Filename,a2),a0
	lea	(maintmptext,NodeBase),a1
	move.l	d2,d0
	jsr	(buildfilepath)
	lea	(maintmptext,NodeBase),a0
	jsr	(deletefile)
	bra.b	7$				; og tar neste fil

61$	move.l	(Uploader,a2),d0		; sjekker om den er fra en av de drepte.
	bsr	packusercheckusernr
	bne.b	7$				; var ikke der
	move.l	(SYSOPUsernr+CStr,MainBase),(Uploader,a2)
	moveq.l	#0,d0
	move.l	d0,(Infomsgnr,a2)		; tømmer denne
	bsr	10$				; lagrer oppdatert fileinfo
	bne.b	8$

7$	addq.l	#1,d3				; tar neste fil
	bra	6$

5$	lea	(FileDirRecord_SIZEOF,a3),a3
	addq.l	#1,d2				; antall fildir's vi har sjekket
	cmp.w	(MaxfileDirs+CStr,MainBase),d2
	bcs	4$
	clrz
	bra.b	9$
8$	jsr	(writeerroro)
	setz
9$	pop	a2/a3/d2/d3
	rts

10$	move.l	(msg,NodeBase),a1		; updater retractee.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	d2,(m_UserNr,a1)		; fildir*1
	move.l	d3,(m_arg,a1)			; filnr
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	lea	(errsavefilhtext),a0
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	rts

; d0 = brukernr
; ret: z = 1, bruker er i array'en
packusercheckusernr
	cmp.l	#-1,d0				; er det all ?
	beq.b	8$				; da er det ikke match..
	move.l	(tmpmsgmem,NodeBase),a0
1$	move.l	(a0)+,d1
	cmp.l	d0,d1
	beq.b	9$
	cmp.l	#-1,d1
	bne.b	1$
8$	clrz
9$	rts

;#c
	STRUCTURE	exitstruct,0
	ULONG	fifor
	ULONG	fifow
	ULONG	fifoportsig
	ULONG	fifotmp
	ULONG	fifoptr
	STRUCT	RMsg,MN_SIZE
	STRUCT	WMsg,MN_SIZE
	LABEL	exitstruct_sizeof

exittodos
	jsr	(checksysopaccess)
	beq.b	99$
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Lokal node ?
	beq.b	0$				; Ja, da har vi lov uansett
	move.b	(dosPassword+CStr,MainBase),d0	; har vi passord ?
	beq.b	0$				; nei, alt ok
	tst.b	(readlinemore,NodeBase)
	beq.b	12$
	jsr	(readlineprompt)
	lea	(dosPassword+CStr,MainBase),a1
	jsr	(comparestrings)
	beq.b	0$
	lea	(wrongtext),a0
	jsr	(writeerroro)
	bra.b	99$
12$	lea	(dosPassword+CStr,MainBase),a0
	moveq.l	#0,d0
	jsr	(getpasswd)
	beq.b	99$
0$	moveq.l	#40,d0				; Status = exited to dos text.
	jsr	(changenodestatus)
	lea	(logexitodostext),a0
	jsr	(writelogtexttime)
	bra.b	doshelldoorsub0
99$	rts

doshelldoorsub0
	suba.l	a0,a0
doshelldoorsub
	push	d2/d3/d4/d5
	move.l	a0,d5				; husker start scriptet
	link.w	a3,#-exitstruct_sizeof
	lea	(RMsg,sp),a0
	moveq.l	#MN_SIZE*2,d0
	jsr	(memclr)
	lea	(nodoronsystext),a0
	move.l	(fifobase),d0
	beq	8$
	move.l	(fifobase),a6
	lea	(shellmfnametext),a0
	lea	(tmptext,NodeBase),a1		; bygger opp filnavnet
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	lea	(tmptext,NodeBase),a0
	move.l	#FIFOF_WRITE+FIFOF_NORMAL+FIFOF_NBIO,d1
	move.l	a0,d0
	move.l	d1,a0
	move.l	#2048,d1
	jsr	(_LVOOpenFifo,a6)
	move.l	d0,(fifow,sp)
	lea	(diskerrortext),a0
	beq	8$

	lea	(shellsfnametext),a0
	lea	(tmptext,NodeBase),a1		; bygger opp filnavnet
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	lea	(tmptext,NodeBase),a0
	move.l	#FIFOF_READ+FIFOF_NORMAL+FIFOF_NBIO,d1
	move.l	a0,d0
	move.l	d1,a0
	move.l	#2048,d1
	jsr	(_LVOOpenFifo,a6)
	move.l	d0,(fifor,sp)
	bne.b	1$
	bsr	11$
	lea	(diskerrortext),a0
	bra	8$
1$	lea	(newshelstext),a0
	lea	(tmptext,NodeBase),a1
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	lea	(tmptext,NodeBase),a1		; legger på shell scripte vi skal kjøre
	lea	(newsheletext),a0
	tst.l	d5				; Har vi noe spes vi vil ha kjørt ?
	beq.b	12$				; nei, tar default
	move.l	d5,a0
12$	jsr	(strcat)
	lea	(tmptext,NodeBase),a0
	move.l	(dosbase),a6
	move.l	a0,d1
	moveq.l	#0,d2
	jsrlib	SystemTagList
	move.l	(fifobase),a6
	tst.l	d0
	beq.b	6$
	bsr	10$
	lea	(diskerrortext),a0
	bra	8$
6$	move.l	(nodeport,NodeBase),a0
	move.l	a0,(MN_REPLYPORT+RMsg,sp)
	move.l	a0,(MN_REPLYPORT+WMsg,sp)
	moveq.l	#0,d2
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d2
	move.l	d2,(fifoportsig,sp)
	lea	(RMsg,sp),a1
	move.l	a1,d1
	move.l	#FREQ_RPEND,a0
	move.l	(fifor,sp),d0
	jsr	(_LVORequestFifo,a6)
	or.l	(consigbit,NodeBase),d2
	or.l	(sersigbit,NodeBase),d2
	or.l	(intsigbit,NodeBase),d2
	or.l	(publicsigbit,NodeBase),d2
	move.l	(exebase),a6
	move.b	#1,(FSEditor,NodeBase)	; slår av dekoding av tastene

2$	moveq.l	#0,d0
	move.l	(pastetext,NodeBase),d1		; sjekker om det ligger tegn og venter
	bne.b	23$				; det gjorde det. 
	move.l	d2,d0
	jsrlib	Wait
23$	move.l	d0,d3

	and.l	(fifoportsig,sp),d0
	beq	3$
22$	move.l	(nodeport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq.b	3$
	lea	(RMsg,sp),a0
	cmp.l	d0,a0
	bne.b	22$

	move.l	(fifobase),a6
	move.l	(fifor,sp),d0
	lea	(fifoptr,sp),a0
	move.l	a0,d1
	sub.l	a0,a0
	jsr	(_LVOReadFifo,a6)
	move.l	d0,d4
	bmi	5$				; EOF, ut
	cmp.l	#80,d4
	bls.b	21$
	moveq.l	#80,d4
21$	move.l	(exebase),a6
	move.l	(fifoptr,sp),a0
	move.l	d4,d0
	jsr	(writetextlen)
	jsr	(breakoutimage)
	move.l	(fifobase),a6

	move.l	(fifor,sp),d0
	lea	(fifoptr,sp),a0
	move.l	a0,d1
	move.l	d4,a0
	jsr	(_LVOReadFifo,a6)

	lea	(RMsg,sp),a1
	move.l	a1,d1
	move.l	#FREQ_RPEND,a0
	move.l	(fifor,sp),d0
	jsr	(_LVORequestFifo,a6)
	move.l	(exebase),a6

3$	move.l	(pastetext,NodeBase),d0		; sjekker om det ligger tegn og venter
	bne.b	35$				; det gjorde det. 
	move.l	d3,d0
	and.l	(consigbit,NodeBase),d0
	beq	4$
35$	jsr	(doconsole)
	beq	4$
31$	cmp.b	#3,d0
	bcs.b	32$
	cmp.b	#6,d0
	bls	33$
32$	cmp.b	#$1d,d0
	beq.b	7$
	lea	(fifotmp,sp),a0
	move.b	d0,(a0)
	move.l	a0,d1
	move.l	(fifow,sp),d0
	move.l	(fifobase),a6
	lea	1.w,a0
	jsr	(_LVOWriteFifo,a6)
	move.l	(exebase),a6

4$	move.l	d3,d0
	and.l	(sersigbit,NodeBase),d0
	beq	41$
	jsr	(doserial)
	bne.b	31$
	bpl	7$
;	bra	7$

41$	move.l	d3,d0
	and.l	(intsigbit,NodeBase),d0
	beq	42$
	jsr	(dointuition)
	beq	7$
	bra	2$

42$	move.l	d3,d0
	and.l	(publicsigbit,NodeBase),d0
	beq	2$
	jsr	(handlepublicport)
	beq.b	7$
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	notz
	bne	2$				; Nei, fortsetter

7$	move.l	(fifobase),a6
	lea	(RMsg,sp),a1
	move.l	a1,d1
	move.l	#FREQ_ABORT,a0
	move.l	(fifor,sp),d0
	jsr	(_LVORequestFifo,a6)
	move.l	(exebase),a6
71$	move.l	(nodeport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	bne.b	71$
	move.l	(fifobase),a6
5$	bsr	10$
	move.l	(exebase),a6
	bra.b	9$

8$	move.l	(exebase),a6
	jsr	(writeerroro)
9$	move.b	#0,(FSEditor,NodeBase)		; dekoding på (for sikkerhetsskyld)
	unlk	a3
	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
	jsr	(outimage)
	pop	d2/d3/d4/d5
	rts

33$	tst.l	d5				; skal vi sende break ?
	bne	4$				; nei, dette er en door!!
	move.b	d0,d4
	lea	(fifoshellntext),a0		; sender break
	lea	(tmptext,NodeBase),a1
	jsr	(strcopy)
	lea	-1(a1),a0
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(konverter)
	move.b	#'/',(a0)+
	add.b	#'A'-1,d4
	move.b	d4,(a0)+
	move.b	#0,(a0)
	move.l	d2,d4
	lea	(tmptext,NodeBase),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	move.l	(dosbase),a6
	jsrlib	Open
	move.l	d0,d1
	beq.b	34$
	jsrlib	Close
34$	move.l	(exebase),a6
	move.l	d4,d2
	bra	4$

10$	move.l	(4+fifor,sp),d0
	move.l	#FIFOF_EOF,d1
	jsr	(_LVOCloseFifo,a6)
11$	move.l	(4+fifow,sp),d0
	move.l	#FIFOF_EOF,d1
	jsr	(_LVOCloseFifo,a6)
	rts
qqwesdf	equ	*-doshelldoorsub0
sdfsdf

;#c	TESTING AV NYE RUTINER...
ejectnode
	jsr	(checksysopaccess)
	beq	9$
	lea	(nodenrtext),a0
	jsr	(readlineprompt)
	beq	9$
	jsr	(atoi)
	bmi	9$
	lea	(cantsendtoytext),a0
	cmp.w	(NodeNumber,NodeBase),d0
	beq.b	8$
	lea	(maintmptext,NodeBase),a1
	lea	(publicportname),a0
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
	move.l	(msg,NodeBase),a1
	move.w	#Node_Eject,(m_Command,a1)
	jsr	(handlemsgspesport)
	lea	(unknownnodetext),a0
	beq.b	8$
	lea	(nactiveusertext),a0
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne.b	8$
	lea	(userejectedtext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	rts

;#c
renamefile
	push	a2/a3/d2/d3
	jsr	(checksysopaccess)
	beq	9$
	lea	(filenametext),a0
	jsr	(readlineprompt)
	beq	9$
	move.l	a0,a3
	jsr	(checkfilename)
	beq	9$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	jsr	(findfileinfo)
	lea	(filenotfountext),a0
	beq	8$
	move.l	d0,d2				; husker dir nr'et
	move.l	(m_UserNr,a1),d3			; filpos.

	lea	(maintmptext,NodeBase),a1
	move.l	a3,a0
	jsr	(buildfilepath)
	lea	(maintmptext,NodeBase),a0
	jsr	(getfilelen)
	lea	(filenotavaltext),a0
	beq	8$

	lea	(newfilenametext),a0		; spør etter nytt navn
	jsr	(readlineprompt)
	beq	9$
	move.l	a0,a3
	jsr	(checkfilename)
	beq	9$

	move.l	a3,a0				; bygger path'en
	move.l	d2,d0
	lea	(tmptext,NodeBase),a1
	jsr	(buildfilepath)
	lea	(tmptext,NodeBase),a0		; sjekker om filen finnes ifra før
	jsr	(getfilelen)
	lea	(filefounondtext),a0
	bne	8$
	move.l	(Tmpusermem,NodeBase),a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	jsr	(findfileinfo)
	lea	(filefountext),a0
	bne	8$

	lea	(Filename,a2),a1
	move.l	a3,a0
	jsr	(strcopy)

	move.l	(msg,NodeBase),a1		; updater retractee.
	move.w	#Main_Renamefileentry,(m_Command,a1)
	move.l	d3,(m_arg,a1)			; filpos.
	move.l	d2,(m_UserNr,a1)		; dir-nummer
	move.l	a2,(m_Data,a1)			; nytt navn?
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	lea	(errsavefilhtext),a0
	bne	8$

	lea	(maintmptext,NodeBase),a0
	lea	(tmptext,NodeBase),a1
	move.l	a0,d1
	move.l	a1,d2
	move.l	(dosbase),a6
	jsrlib	Rename
	move.l	(exebase),a6
	lea	(diskerrortext),a0
	tst.l	d0
	beq.b	8$
	move.l	(Infomsgnr,a2),d0			; info melding ?
	beq.b	9$					; nei, ferdig

	lea	(tmpmsgheader,NodeBase),a2		; henter inn meldings headeren
	move.l	a2,a0
	move.w	#6,d1					; fileinfo conf
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	8$					; error

	move.l	a3,a0					; bygger opp nytt subject,
	lea	(tmptext,NodeBase),a1
	jsr	(strcopy)
	move.b	#' ',(-1,a1)

	lea	(Subject,a2),a0
	moveq.l	#Sizeof_NameT,d0
2$	subq.l	#1,d0
	beq.b	1$					; ferdig
	move.b	(a0)+,d1
	beq.b	1$					; ferdig
	cmpi.b	#'(',d1
	bne.b	2$
	subq.l	#1,a0
	jsr	(strcopy)

	lea	(tmptext,NodeBase),a0
	lea	(Subject,a2),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)

	move.l	a2,a0					; lagrer header'en igjen
	move.w	#6,d0					; fileinfo conf
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	8$					; error

1$	lea	(filerenamedtext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	pop	a2/a3/d2/d3
	rts

;#c
invite	jsr	(checksysopaccess)
	beq	9$
	lea	(enteruserntext),a0
	moveq.l	#1,d0				; vi godtar all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	bne.b	2$
	move.b	(readcharstatus,NodeBase),d1
	bne	9$
2$	moveq.l	#-1,d1				; Fikk vi ALL ???
	cmp.l	d1,d0
	bne.b	1$				; Ikke ALL
	lea	(sureinviteatext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq	9$
	lea	(10$),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(u_almostendsave,a1),a1
	move.w	(confnr,NodeBase),d0
	mulu	#Userconf_seizeof/2,d0
	lea	(uc_Access,a1,d0.l),a1
	jsr	(doallusers)
	bne	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
	bra	9$

1$	move.l	(Tmpusermem,NodeBase),a0
	jsr	(loadusernr)
	bne.b	7$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra	9$
7$	move.l	(Tmpusermem,NodeBase),a1
	lea	(u_almostendsave,a1),a1
	move.w	(confnr,NodeBase),d0
	mulu	#Userconf_seizeof/2,d0
	lea	(uc_Access,a1,d0.l),a1
	move.w	(a1),d1				; Er brukeren allerede medlem ?
	lea	(alreamembertext),a0
	andi.b	#ACCF_Read,d1
	bne.b	8$				; ja. Skriv melding om det
	bset	#ACCB_Invited,d1
	move.w	d1,(a1)				; setter invite bit'et i denne konf'en
	move.l	(Tmpusermem,NodeBase),a1
	lea	(Name,a1),a0
	jsr	(saveuser)
	bne.b	9$
	lea	(userrecupdatext),a0
8$	jsr	(writetexto)
9$	rts

10$	move.w	(a0),d0
	btst	#ACCB_Read,d0			; Er denne brukeren medlem ?
	bne.b	19$				; ja
	bset	#ACCB_Invited,d0
	move.w	d0,(a0)				; Da setter vi invite bit'et
19$	setz					; ta og lager forandringen
	clrn
	rts

;#c
czapfile
	moveq.l	#1,d0				; vi er CZap
	bra.b	zapfile1
zapfile
	moveq.l	#0,d0
zapfile1
	push	a2/a3/d2/d3/d4
	moveq.l	#0,d3				; har ikke gjort noe enda
	move.l	d0,d4				; husker om vi er CZap
	jsr	(checksysopaccess)
	beq	9$
	lea	(retracfnametext),a0
	jsr	(readlineprompt)
	beq	9$
	move.l	a0,a3
	jsr	(checkfilename)
	beq	9$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	jsr	(findfileinfo)
	lea	(filenotfountext),a0
	beq	8$
	move.l	d0,d2
	lea	(maintmptext,NodeBase),a1
	move.l	a3,a0
	jsr	(buildfilepath)
	lea	(tmpfileentry,NodeBase),a0
	jsr	(allowretract)
	lea	(filenotfountext),a0
	beq	8$
	lea	(remfilfflistext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq	2$				; nei, ferdig

	move.l	a2,a0
	move.l	(msg,NodeBase),a1
	move.l	(m_UserNr,a1),d0
	move.l	d2,d1
	bsr	deletefilefromabbs
	beq	8$
	moveq.l	#1,d3				; har gjort noe nå
	tst.l	d4				; er vi CZap ?
	beq.b	2$				; nope
	move.l	(Uploader,a2),d0
	move.l	(Tmpusermem,NodeBase),a3
	move.l	a3,a0
	jsr	(loadusernr)
	lea	(usernotfountext),a0
	beq.b	8$
	subq.w	#1,(Uploaded,a3)		; Oppdaterer Uploaded telleren
	bcc.b	3$
	move.w	#0,(Uploaded,a3)		; ingen underflow..
3$	move.l	(Fsize,a2),d0
	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	sub.l	d0,(KbUploaded,a3)
	bcc.b	4$
	moveq.l	#0,d0
	move.l	d0,(KbUploaded,a3)		; ikke her heller
4$	move.l	a3,a0
	move.l	(Usernr,a0),d0
	jsr	(saveusernr)
	lea	(saveusererrtext),a0
	beq.b	8$

2$	tst.b	(readcharstatus,NodeBase)
	bne.b	9$
	lea	(remfilfdisktext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	1$				; nei, ferdig
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DeleteFile
	move.l	(exebase),a6
	moveq.l	#1,d3				; har gjort noe nå
1$	tst.l	d3
	beq.b	9$				; har ikke gjort noe, ikke skriv
	lea	(fileretracetext),a0
	jsr	(writetexto)
	bra.b	9$
8$	jsr	(writeerroro)
9$	pop	a2/a3/d2/d3/d4
	rts

; a0 = fileentry
; d0 = filepos
; d1 = filedir
deletefilefromabbs
	push	a2/d2/a3
	move.l	a0,a2
	ori.w	#FILESTATUSF_Fileremoved,(Filestatus,a2)
	move.l	(msg,NodeBase),a1		; updater retractee.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	d0,(m_arg,a1)		; filpos.
	move.l	d1,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	lea	(errsavefilhtext),a0
	notz
	beq.b	9$

	move.l	(Infomsgnr,a2),d0		; filinfo ?
	beq.b	8$				; nei, ferdig ?
	moveq.l	#6,d2				; fileinfo conf
	move.w	(Filestatus,a2),d1		; er den pu til en conf ?
	btst	#FILESTATUSB_PrivateConfUL,d1
	beq.b	2$				; nei
	move.l	(PrivateULto,a2),d2		; ja, da er den ikke i fileinfo conf
2$	move.l	d2,d1
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a3,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	1$
	move.b	(MsgStatus,a3),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	bne.b	8$				; allerede drept
	move.l	a3,a0
	bsr	killmsgwhodidit
	or.b	d0,(MsgStatus,a3)
	move.l	a3,a0
	move.w	d2,d0				; file info konfnr
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	beq.b	8$
1$	jsr	(writeerroro)
	setz
	bra.b	9$
8$	clrz
9$	pop	a2/d2/a3
	rts

;#c
modifyfile
	push	a3/a2/d2
1$	lea	(modifyfnametext),a0
	jsr	(readlineprompt)
	beq	9$
	move.l	a0,a3
	jsr	(checkfilename)
	beq.b	1$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	jsr	(findfileinfo)
	bne.b	2$
3$	lea	(filenotfountext),a0
12$	jsr	(writeerroro)
	bra	9$
2$	move.l	d0,d2				; husker fil dir'en.
	move.l	a2,a0
	jsr	(allowtypefileinfo)
	beq.b	3$
	cmpi.w	#20,(menunr,NodeBase)		; er vi i sigopmeny ?
	bne.b	11$				; Nope. alt ok
	lea	(youarenottext),a0		; Sier ifra at sigop ikke har lov
	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_PrivateConfUL,d0	; private til conf ?
	beq.b	12$				; Nei, da har han ikke lov
	move.l	(PrivateULto,a2),d0
	lea	(u_almostendsave+CU,NodeBase),a1
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a1),d0		; Henter conf access
	btst	#ACCB_Read,d0			; er vi medlem ?
	beq.b	12$				; nope
	andi.b	#ACCF_Sigop,d0			; sigop ?
	beq.b	12$				; nope
11$	lea	(maintmptext,NodeBase),a1
	move.l	d2,d0
	move.l	a3,a0
	jsr	(buildfilepath)
	lea	(maintmptext,NodeBase),a0
	jsr	(getfilelen)
	lea	(filenotavaltext),a0
	beq.b	12$
	move.l	d0,(Fsize,a2)			; opdaterer fsize

	move.w	(Filestatus,a2),d0		; er den privat til en person ?
	andi.w	#FILESTATUSF_PrivateUL,d0
	bne.b	8$				; jepp. da kan vi ikke ha til conf

	lea	(fileprivtcotext),a0
	lea	(tmptext,NodeBase),a1
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(kolonspacetext),a0
	jsr	(strcopy)
	lea	(tmptext,NodeBase),a0

	lea	(nulltext),a1
	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_PrivateConfUL,d0
	beq.b	5$
	move.l	(PrivateULto,a2),d0
	lea	(n_FirstConference+CStr,MainBase),a1
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a1,d0.l),a1		; Har konferanse navnet.
5$	moveq.l	#Sizeof_NameT,d0
	jsr	(mayedlineprompt)
	bne.b	6$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	andi.w	#~FILESTATUSF_PrivateConfUL,(Filestatus,a2)
	moveq.l	#0,d0
	bra.b	7$

6$	bsr	getconfnamesub
	beq	9$
	ori.w	#FILESTATUSF_PrivateConfUL,(Filestatus,a2)
	andi.l	#$ffff,d0
7$	move.l	d0,(PrivateULto,a2)

8$	lea	(touchfdatetext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	4$
	lea	(ULdate,a2),a0			; opdaterer dato
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
4$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$

	tst.b	(readlinemore,NodeBase)		; mere input ?
	bne.b	10$				; ja, kutt utskrift
	jsr	(outimage)
	lea	(pleaseentfdtext),a0
	jsr	(strlen)
	lea	(spacetext),a0
	jsr	(writetextlen)
	moveq.l	#0,d0
	move.w	#Sizeof_FileDescription,d0
	lea	(bordertext),a0
	jsr	(writetextlen)
	move.b	#'>',d0
	jsr	(writechar)
	jsr	(outimage)
10$
	lea	(Filedescription,a2),a1		; Gammel tekst
	lea	(pleaseentfdtext),a0		; Prompt
	move.w	#Sizeof_FileDescription,d0	; Lengden
	jsr	(mayedlinepromptfull)
	beq	9$
	lea	(Filedescription,a2),a1
	move.w	#Sizeof_FileDescription,d0
	jsr	(strcopymaxlen)

	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	lea	(Filedescription,a2),a0
	push	a6/d2
	move.l	a0,d2
	move.l	dosbase,a6
	jsrlib	SetComment			; prøver å sette description som file comment.
	pop	a6/d2

	andi.w	#~FILESTATUSF_FreeDL,(Filestatus,a2)	; av med Free DL.
	lea	(filefreedltext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	13$
	ori.w	#FILESTATUSF_FreeDL,(Filestatus,a2)

13$	move.l	(msg,NodeBase),a1		; updater gammel filinfo.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	(m_UserNr,a1),(m_arg,a1)	; filpos.
	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne.b	9$
	lea	(filemodifydtext),a0
	jsr	(writetexto)
9$	pop	a3/a2/d2
	rts

;#c
listcallerslog
	jsr	(checksysopaccess)
	beq.b	9$
	lea	(nodenrtext),a0		; legge inn (CR for <nodenr>) FIX ME
	jsr	(readlineprompt)
	beq.b	9$
	jsr	(atoi)
	bmi.b	9$
	lea	(maintmptext,NodeBase),a1
	lea	(logfilenameo),a0
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
	bsr	typelogfile
9$	rts

; a0 - filename
typelogfile
	push	a6/d2/d3/d4/d5/d6/a2
	move.l	(dosbase),a6
	moveq.l	#70,d6
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	9$
	moveq.l	#0,d2
	moveq.l	#OFFSET_END,d3
	move.l	d4,d1
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq	8$
	move.l	d4,d1			; Hvor lang er fila ?
	move.l	d6,d2			; (og plaserer oss klar for første read)
	neg.l	d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	8$
	move.l	d0,d5
	sub.l	d6,d5
	bcs.b	8$			; ferdig
	bra.b	2$
1$	sub.l	d6,d5
	bcs.b	8$			; ferdig
	move.l	d4,d1			; søker tilbake
	move.l	d6,d2
	add.l	d2,d2			; to linjer (den vi har lest..
	neg.l	d2
	moveq.l	#OFFSET_CURRENT,d3	; .. og den vi skal lese)
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	8$
2$	move.l	d4,d1
	lea	(tmptext,NodeBase),a0
	move.l	a0,d2
	move.l	d6,d3
	jsrlib	Read
	cmp.l	d0,d3
	bne.b	8$
	move.l	(exebase),a6
	lea	(tmptext,NodeBase),a0
	move.l	a0,a1
	adda.l	d6,a1
	move.b	#0,-(a1)		; fjerner nl'en
3$	cmpi.b	#' ',-(a1)
	beq.b	3$
	cmpa.l	a0,a1
	bcc.b	4$
	move.l	a0,a1
	subq.l	#1,a1
4$	move.b	#10,(1,a1)
	move.b	#0,(2,a1)
	jsr	(writetexti)
	beq.b	7$
	jsr	(testbreak)
	beq.b	7$
	move.l	(dosbase),a6
	bra.b	1$
7$	move.l	(dosbase),a6
8$	move.l	d4,d1
	jsrlib	Close
9$	pop	a6/d2/d3/d4/d5/d6/a2
	rts

;#c
deletelogfile
	jsr	(checksysopaccess)
	beq	9$
	lea	(nodenrtext),a0		; legge inn (CR for <nodenr>)
	jsr	(readlineprompt)
	beq.b	9$
	jsr	(atoi)
	bmi.b	9$
	lea	(maintmptext,NodeBase),a1
	lea	(logfilenameo),a0
	jsr	(fillinnodenr)
	lea	(suredellogtext),a0	; spør om han virkelig vil slette
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$			; nei, hopper ut
	move.l	(dosbase),a6
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	jsrlib	DeleteFile
	move.l	(exebase),a6
	tst.l	d0
	beq.b	9$			; klarte ikke slette.
	lea	(logdeletedtext),a0
	jsr	(writetexto)
	lea	(logdeletedtext+1),a0
	jsr	(writelogtexttime)
9$	rts

;#c
boot	jsr	(checksysopaccess)
	beq	9$
	lea	(surewtobootext),a0	; spør om han virkelig vil boote
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$			; nei, hopper ut
	lea	(logboottext),a0
	jsr	(writelogtexttime)
	lea	(bootingsysttext),a0
	jsr	(writetexti)
	moveq.l	#3,d0			; venter 3 sek
	jsr	(waitsecs)
	jmplib	ColdReboot
9$	rts

;#c
mem	push	d2-d7/a2/a3
	jsr	(checksysopaccess)
	beq	9$
	lea	(memheadertext),a0
	jsr	(writetexti)
	beq	9$
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#0,d5
	lea	(mem1text),a0			; chip
	moveq.l	#MEMF_CHIP,d6
	bsr	10$
	lea	(mem2text),a0			; fast
	moveq.l	#MEMF_FAST,d6
	bsr	10$
	lea	(mem3text),a0			; total
	jsr	(writetext)
	move.l	d2,d0
	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	move.l	d3,d0
	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	move.l	d4,d0
	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	move.l	d5,d0
	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	jsr	(outimage)
	beq	9$
	jsr	(outimage)
	beq	9$

;	tst.w	_2.0				; Kjører vi 2.0 ?
;	beq.b	4$				; Nei.
;	move.l	dosbase,a6			; låser dos list'a.
;	moveq.l	#LDF_VOLUMES,d1
;	jsrlib	LockDosList
;	move.l	d0,d3				; husker list'a
;	bra.b	5$
4$	jsrlib	Forbid
5$
	move.l	(dosbase),a0			; scan'er igjennom alle
	move.l	(dl_Root,a0),a2
	move.l	(rn_Info,a2),d0
	lsl.l	#2,d0
	move.l	d0,a2
	move.l	(di_DevInfo,a2),d0		; devinfo'ene
	moveq.l	#0,d2				; antall vi har funnet
	move.l	(tmpmsgmem,NodeBase),a3		; stedet å oppevare navnene i

1$	lsl.l	#2,d0				; scan'er alle volums, og husker
	move.l	d0,a2				; navnet
	beq.b	6$
	move.l	(dl_Type,a2),d0			; device ?
	moveq.l	#DLT_VOLUME,d1
	cmp.l	d0,d1
	bne.b	2$				; nope
	move.l	(dl_Name,a2),d0
	lsl.l	#2,d0
	move.l	d0,a0
	moveq.l	#0,d0
	move.b	(a0)+,d0
	move.l	a3,a1
	jsr	(strcopylen)
	move.b	#':',(a1)+
	move.b	#0,(a1)+
	move.l	a1,a3
	addq.l	#1,d2				; øker antallet vi har funnet
2$	move.l	(dl_Next,a2),d0
	bne.b	1$

6$;	tst.w	(_2.0)				; Kjører vi 2.0 ?
;	beq.b	61$				; Nei.
;611$	moveq.l	#LDF_VOLUMES,d1
;	jsrlib	UnLockDosList			; låser opp dos list'a.
;	move.l	exebase,a6
;	bra.b	62$
61$	jsrlib	Permit
62$
	move.l	(tmpmsgmem,NodeBase),a3		; stedet vi oppevarte navnene i
63$	subq.l	#1,d2
	bcs.b	8$				; ferdig
	move.l	a3,a0
	moveq.l	#20,d0
	jsr	(writetextlfill)
	move.l	a3,a0
	jsr	(getdiskfree)
	lea	(diskerrortext),a0
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	3$
	jsr	(skrivnr)
	lea	(kbtext),a0
3$	jsr	(writetext)
	jsr	(outimage)
31$	move.b	(a3)+,d0			; scan'er til starten av neste
	bne.b	31$				; navn
	bra.b	63$				; and here we go again.

8$	jsr	(outimage)
9$	pop	d2-d7/a2/a3
	rts
10$	move.l	d5,-(a7)
	jsr	(writetext)
	move.l	d6,d1				; finner ledig
	jsrlib	AvailMem
	add.l	d0,d2
	move.l	d0,d5				; husker ledig
	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	moveq.l	#0,d0
	move.l	d6,d1				; finner total
	ori.l	#MEMF_TOTAL,d1
	jsrlib	AvailMem
	move.l	d0,d7				; husker total
	beq.b	12$
	sub.l	d5,d0				; beregner i bruk
	add.l	d0,d3
12$	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	move.l	d7,d0				; max ..
	add.l	d0,d4
	moveq.l	#10,d1
	jsr	(skrivnrrfill)
	ori.l	#MEMF_LARGEST,d6
	move.l	d6,d1
	jsrlib	AvailMem
	move.l	(a7)+,d5
	add.l	d0,d5
	moveq.l	#10,d1
	jmp	(skrivnrrfill)

;#c ! A
acceschange
	push	d2/d7/a2-a3
	jsr	(checksysopaccess)
	beq	9$
	move.l	(Tmpusermem,NodeBase),a3	; Setter opp a3 til å
	lea	(u_almostendsave+CU,NodeBase),a3
	move.w	(confnr,NodeBase),d0
	mulu	#Userconf_seizeof/2,d0
	add.l	d0,a3				; peke på access området
	lea	(enteruserntext),a0
	moveq.l	#1,d0				; vi godtar all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq	9$				; hopper over bare return her
	moveq.l	#-1,d1				; Fikk vi ALL ???
	cmp.l	d1,d0
	bne	2$				; Ikke ALL
	lea	(newacctext),a0
	jsr	(writetexti)
	moveq.l	#7,d0
	jsr	(getline)
	bne.b	12$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	lea	(nulltext),a0
12$	moveq.l	#0,d0				; sjekk på Z bit'et
	bsr	parseaccessbits			; Parser svaret.
	beq	9$				; error
	lea	(newacctext),a0
	jsr	(writetext)
	lea	(accessbitstext),a2
	move.l	d7,d0
	lea	(tmptext,NodeBase),a0
	bsr	getaccstring
	jsr	(writetexto)
	lea	(suregivenatext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq	9$
	move.l	a3,a1
	lea	(acceschangelooprutine),a0
	move.l	d7,d0
	jsr	(doallusers)
	bne	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
	bra	9$

2$	move.l	(Tmpusermem,NodeBase),a0		; bare en bruker.
	jsr	(loadusernr)
	bne.b	6$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra	9$
6$	move.w	(uc_Access,a3),d7	; henter ut tidligere access

	move.l	(Tmpusermem,NodeBase),a3	; Valgt bruker i a3
	lea	(u_almostendsave,a3),a3
	move.w	(confnr,NodeBase),d2
	mulu	#Userconf_seizeof/2,d2
	add.l	d2,a3
	move.w	(uc_Access,a3),d0	; valgte brukers access i d0

	cmpi.w	#20,(menunr,NodeBase)	; Sigop menu ??
	bne.b	11$			; nei !
	move.l	d0,d1			; bruker d1 her
	andi.w	#ACCF_Sysop|ACCF_Sigop,d1 ; Vil sigop forandre en annen sigop/sysop ?
	beq.b	11$			; Nei.
	lea	(youarenottext),a0	; Sier ifra at sigop ikke har lov
	jsr	(writeerroro)
	bra	9$

11$	lea	(tmptext,NodeBase),a0
	jsr	(getaccbittext)		; d0 = access, a0 = string
	move.l	a0,a1
	cmpi.w	#20,(menunr,NodeBase)	; Sigop menu?
	bne.b	14$			; nei!
	lea	(sigopaccesstypetext),a0	; ja
	moveq.l	#6,d0
	bra.b	15$
14$	lea	(accesstypetext),a0
	moveq.l	#8,d0
15$	jsr	(mayedlineprompt)
	bne.b	13$
	tst.b	(readcharstatus,NodeBase)
	bne.b	9$
	lea	(nulltext),a0
13$	moveq.l	#0,d0			; sjekk på Z bit'et
	bsr	parseaccessbits
	beq.b	9$
	move.w	d7,(uc_Access,a3)

	move.l	(Tmpusermem,NodeBase),a1
	lea	(Name,a1),a0
	jsr	(saveuser)
	bne.b	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
9$	pop	d2/d7/a2-a3
	rts

; d0 = 0, sjekk  om vedkommende kan sette Z bit'et
; legger det i d7..
parseaccessbits
	bsr	parseaccessbitssub
	bne.b	9$
	lea	(invalidacctext),a0
	jsr	(writeerroro)
	setz
9$	rts

parseaccessbitssub
	move.l	d0,d1
	moveq	#0,d7				; parser in linja.
	jsr	(upword)

4$	move.b	(a0)+,d0
	beq	8$

	cmpi.b	#'R',d0
	bne.b	41$
	bset	#ACCB_Read,d7
	bra.b	4$

41$	cmpi.b	#'W',d0
	bne.b	42$
	bset	#ACCB_Write,d7
	bra.b	4$

42$	cmpi.b	#'U',d0
	bne.b	43$
	bset	#ACCB_Upload,d7
	bra.b	4$

43$	cmpi.b	#'D',d0
	bne.b	44$
	bset	#ACCB_Download,d7
	bra.b	4$

44$	cmpi.b	#'F',d0
	bne.b	47$
	bset	#ACCB_FileVIP,d7
	bra.b	4$

47$	cmpi.b	#'I',d0
	bne.b	45$
	bset	#ACCB_Invited,d7
	bra.b	4$

45$	cmpi.b	#'S',d0
	bne.b	46$
	tst.b	d1
	bne.b	2$
	cmpi.w	#20,(menunr,NodeBase)		; Sigop menu ??
	beq.b	4$				; ja
	cmpi.w	#40,(menunr,NodeBase)		; Sigop user maintanance menu ?
	beq.b	4$				; ja
2$	bset	#ACCB_Sigop,d7
	bra.b	4$

46$	cmpi.b	#'Z',d0
	bne.b	5$
	tst.b	d1
	bne.b	3$
	move.l	(Usernr+CU,NodeBase),d0		; Bare virkelige sysop'en kan
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0	; gi andre sysop access.
	bne	4$
3$	bset	#ACCB_Sysop,d7
	bra	4$

5$	clrz
8$	notz
	rts

; får buffer adresse i a1
acceschangelooprutine
	move.l	(Usernr,a1),d1			; Er dette sysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d1
	beq.b	1$				; Vi forandrer ikke på sysop
	cmpi.w	#20,(menunr,NodeBase)		; Sigop menu ??
	bne.b	2$				; nei
	move.w	(uc_Access,a0),d1		; Vil sigop forandre en annen sigop/sysop ?
	andi.b	#ACCF_Sysop|ACCF_Sigop,d1
	bne.b	1$				; Ja, fy!
2$	move.w	d0,(uc_Access,a0)
1$	setz					; ta og lager forandringen
	clrn					; ikke avbryt
	rts

;#c
conferenceinstall
	push	a2/d2
	jsr	(checksysopaccess)
	beq	9$
	move.w	(ActiveConf+CStr,MainBase),d0
	cmp.w	(Maxconferences+CStr,MainBase),d0
	bcc	8$
	lea	(confnametxt),a0
	move.w	#Sizeof_NameT-2,d0		; amigados klarer ikke mere
	lea	(nulltext),a1
	jsr	(mayedlinepromptfull)		; en 30 tegn i filnavnet
	beq	9$
	jsr	(removespaces)
	beq	9$
	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	jsr	(testconfname)
	lea	(illconfnatext),a0
	beq	7$
	lea	(maintmptext,NodeBase),a0
	jsr	(findconferencefull)
	lea	(confsamenametxt),a0
	bne	7$
	lea	(econfstatustext),a0
	jsr	(readlineprompt)
	beq	9$
	bsr	parseconfaccsesbits
	beq.b	9$
	lea	(maintmptext,NodeBase),a0
	move.l	(msg,NodeBase),a1
	move.w	#Main_createconference,(m_Command,a1)
	move.l	d0,(m_Data,a1)
	move.l	a0,(m_Name,a1)
	move.l	a0,a2		; Husker conf navnet...
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	lea	(ninstalconftext),a0
	bne.b	7$
	lea	(confinstedtext),a0
	jsr	(writetexto)
	move.l	a2,a0
	jsr	(_Make_conf_text)	; CI JEO text
	bra.b	9$
8$	lea	(sorrymaxconftxt),a0
	jsr	(writetext)
	move.w	(Maxconferences+CStr,MainBase),d0
	jsr	(skrivnrw)
	lea	(conferencestext),a0
7$	jsr	(writeerroro)
9$	pop	a2/d2
	rts

;#c
deletedir
	push	a2/d2
	jsr	(checksysopaccess)
	beq	9$
	lea	(dirnametext),a0
	jsr	(readlineprompt)
	beq	9$
	jsr	(finddir)
	lea	(dirnotfoundtext),a0
	beq	8$
	moveq.l	#0,d2
	lsr.w	#1,d0
	move.w	d0,d2
	cmp.w	#1,d2			; slette
	lea	(youarenottext),a0	; Nei, skriver ut fy melding
	bls.b	8$
	move.l	(firstFileDirRecord+CStr,MainBase),a2
	mulu.w	#FileDirRecord_SIZEOF,d0
	adda.l	d0,a2
	jsr	(outimage)
	move.l	a2,a0
	jsr	(writetexto)
	lea	(suredeldirtext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$			; nei, hopper ut
	move.l	(msg,NodeBase),a1
	move.w	#Main_DeleteDir,(m_Command,a1)
	move.l	d2,(m_UserNr,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	lea	(dirdeletedtext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	a2/d2
	rts

;#c
renamedir
	push	a2/d2
	jsr	(checksysopaccess)
	beq	9$
	lea	(dirnametext),a0
	jsr	(readlineprompt)
	beq	9$
	jsr	(finddir)
	lea	(dirnotfoundtext),a0
	beq	8$
	moveq.l	#0,d2
	lsr.w	#1,d0
	move.w	d0,d2
	jsr	(outimage)
	beq	9$
	lea	(newnametext),a0
	jsr	(readlineprompt)
	beq	9$
	lea	(tmptext,NodeBase),a2
	move.l	a2,a1
	jsr	(strcopy)			; kopierer i sikkerhet
	move.l	a2,a0
	jsr	(strlen)			; sjekker lengden (maks 27)
	moveq.l	#27,d1
	cmp.w	d1,d0
	lea	(nametolong2text),a0
	bhi	8$
	move.l	a2,a0
	jsr	(finddirfull)
	lea	(dirssamenametxt),a0
	bne	8$
	jsr	(outimage)
	beq	9$
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	move.w	d2,d0
	mulu.w	#FileDirRecord_SIZEOF,d0
	adda.l	d0,a0
	jsr	(writetext)
	lea	(arrowrtext),a0
	jsr	(writetext)
	move.l	a2,a0
	jsr	(writetexti)
	lea	(oktochangentext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$			; nei, hopper ut
	move.l	(msg,NodeBase),a1
	move.w	#Main_RenameDir,(m_Command,a1)
	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Name,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	lea	(dirrenamedtext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	a2/d2
	rts

cleanconference
	push	a2/d2
	jsr	(checksysopaccess)
	beq	9$
	lea	(confnametxt),a0
	bsr	getconfname
	beq	9$
	moveq.l	#0,d2
	lsr.w	#1,d0
	move.w	d0,d2
	cmp.w	#2,d0				; nekter på fileinfo og userinfo.. (problemer...)
	lea	(youarenottext),a0	; Nei, skriver ut fy melding
	beq	8$
	cmp.w	#3,d0
	beq	8$
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a2
	mulu.w	#ConferenceRecord_SIZEOF,d0
	adda.l	d0,a2
	jsr	(outimage)
	move.l	a2,a0
	jsr	(writetexto)
	lea	(sureclconftext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$				; nei, hopper ut
	move.l	(msg,NodeBase),a1
	move.w	#Main_CleanConference,(m_Command,a1)
	move.l	(Tmpusermem,NodeBase),a0
	move.l	a0,(m_Data,a1)
	move.l	d2,(m_UserNr,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	move.w	d2,d0
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	moveq.l	#0,d1
	move.l	d1,(uc_LastRead,a0,d0.l)	; sletter last read
	move.w	(confnr,NodeBase),d0		; er vi i den conf'en vi clean'a ?
	lsr.w	#1,d0
	cmp.w	d0,d2
	bne.b	1$				; nei
	moveq.l	#0,d0				; tar en M R
	move.l	d0,(msgqueue,NodeBase)
	move.l	d0,(HighMsgQueue,NodeBase)	; virkelig
1$	lea	(confcleanedtext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	a2/d2
	rts

;#c DELCONF
conferencedelete
	push	a2/d2
	jsr	(checksysopaccess)
	beq	9$
	lea	(confnametxt),a0	; 'Conference name: '
	bsr	getconfname
	beq	9$
	moveq.l	#0,d2
	lsr.w	#1,d0
	move.w	d0,d2
	cmp.w	#3,d2
	lea	(youarenottext),a0	; Nei, skriver ut fy melding
	bls	8$
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a2
	mulu.w	#ConferenceRecord_SIZEOF,d0
	adda.l	d0,a2
	jsr	(outimage)
	move.l	a2,a0
	jsr	(writetexto)
	lea	(suredelconftext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$				; nei, hopper ut
; MESSAGE
	move.l	(msg,NodeBase),a1
	move.w	#Main_DeleteConference,(m_Command,a1)
	move.l	(Tmpusermem,NodeBase),a0
	move.l	a0,(m_Data,a1)
	move.l	d2,(m_UserNr,a1)
	jsr	(handlemsg)

	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d2,d0
	mulu	#Userconf_seizeof,d0
	moveq.l	#0,d1
	move.w	d1,(uc_Access,a0,d0.l)		; sletter aksessen til brukeren
	move.l	d1,(uc_LastRead,a0,d0.l)	; sletter last read
	lea	(confdeletedtext),a0
	jsr	(writetexto)
	move.w	(confnr,NodeBase),d0		; er vi i den conf'en vi sletta ?
	lsr.w	#1,d0
	cmp.w	d0,d2
	bne.b	9$				; nei
	move.w	#0,d0				; ja, da joiner vi news
	bsr	joinnr
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	a2/d2
	rts

;#c
conferencerename
	push	a2/d2/d3/a3
	jsr	(checksysopaccess)
	beq	9$
	moveq.l	#0,d3				; skal ikke forandre bits foreløpig
	lea	(confnametxt),a0
	bsr	getconfname
	beq	9$
	moveq.l	#0,d2
	lsr.w	#1,d0
	move.w	d0,d2				; husker confnr'et
	lea	(newnametext),a0
	jsr	(readlineprompt)
	beq	9$
	lea	(tmptext,NodeBase),a2
	move.l	a2,a1
	jsr	(strcopy)				; kopierer i sikkerhet
	move.l	a2,a0
	jsr	(testconfname)
	lea	(illconfnatext),a0
	beq	8$
	move.l	a2,a0
	jsr	(strlen)			; sjekker lengden (maks 28)
	moveq.l	#28,d1
	cmp.w	d1,d0
	lea	(nametolong2text),a0
	bhi	8$
	move.l	a2,a0
	jsr	(findconferencefull)
	beq.b	2$				; fant ikke. ok
	lsr.w	#1,d0
	cmp.w	d0,d2
	lea	(confsamenametxt),a0
	bne	8$				; forskjellige, feil
	cmpi.w	#4,d2				; kan man forandre bits her ?
	bcs.b	2$				; nei, dette er news,post,u/finfo
	lea	(n_FirstConference+CStr,MainBase),a3
	move.w	d2,d0
	mulu	#ConferenceRecord_SIZEOF,d0
	add.l	d0,a3
	move.w	(n_ConfSW,a3),d0
	lea	(maintmptext,NodeBase),a0
	jsr	(confbitstotext)
	lea	(econfstatustext),a0
	lea	(maintmptext,NodeBase),a1
	moveq.l	#30,d0
	jsr	(mayedlineprompt)
	beq	9$
	bsr	parseconfaccsesbits
	beq	9$
	move.l	d0,d3
2$	jsr	(outimage)
	beq	9$
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a0
	move.w	d2,d0
	mulu.w	#ConferenceRecord_SIZEOF,d0
	adda.l	d0,a0
	lea	(tmptext2,NodeBase),a1		; husker det gamle navnet
	jsr	(strcopy)
	lea	(tmptext2,NodeBase),a0
	jsr	(writetext)
	lea	(arrowrtext),a0
	jsr	(writetext)
	move.l	a2,a0
	jsr	(writetexti)
	lea	(oktochangentext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$				; nei, hopper ut
	move.l	(msg,NodeBase),a1
	move.w	#Main_RenameConference,(m_Command,a1)
	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Name,a1)
	move.l	d3,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	move.w	d2,d0				; confnr
	lea	(tmptext2,NodeBase),a0		; old name
	jsr	(renameconfbulletins)
	beq.b	7$
	lea	(confrenamedtext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	a2/d2/d3/a3
	rts

parseconfaccsesbits
	push	d2/d3
	jsr	(upword)		; Store bokstaver
	moveq.l	#0,d0
1$	move.b	(a0)+,d1
	beq.b	9$			; ferdig
	moveq.l	#1,d2
	lea	(confacsbitstext),a1
	bra.b	3$
2$	lsl.l	#1,d2
3$	move.b	(a1)+,d3
	beq.b	4$
	cmp.b	d3,d1
	bne.b	2$
;	IFNE	sn-13
;	cmp.b	#'N',d1
;	beq.b	4$
;	ENDC
	or.l	d2,d0
	bra.b	1$			; tar neste bit

4$	move.w	d1,-(sp)
	lea	(unownstatusbtxt),a0
	jsr	(writeerror)
	move.w	(sp)+,d0
	jsr	(writechar)
	jsr	(outimage)
	clrz

9$	notz
	pop	d2/d3
	rts

;#c
showuser1
	clrz
	bra.b	showuser2
showuser
	jsr	(checksysopaccess)
showuser2
	beq	9$
1$	lea	(enteruserntext),a0
	moveq.l	#2,d0				; vi godtar all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq	9$
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	4$
	lea 	(wantdetlisttext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	lea	(30$),a0			; detailed funksjon
	bne.b	3$				; ja, vi vill ha detailed list
	move.b	(readcharstatus,NodeBase),d0
	bne.b	9$
	lea	(40$),a0			; ikke detailed
3$	jsr	(doallusers)
	bra.b	9$

4$	move.l	(Tmpusermem,NodeBase),a0
	jsr	(loadusernr)
	bne.b	2$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra.b	1$
2$	move.l	(SYSOPUsernr+CStr,MainBase),d0	; er det super sysop ?
	move.l	(Tmpusermem,NodeBase),a0
	move.l	(Usernr,a0),d1
	cmp.l	d1,d0
	bne.b	7$				; nei
	cmp.l	(Usernr+CU,NodeBase),d0		; Er vi supersysop ?
	beq.b	7$				; alt ok.
	lea	(nosysopheretext),a0
	jsr	(writeerroro)
	bra.b	9$

7$	jsr	(outimage)
	move.l	(Tmpusermem,NodeBase),a0
	bsr.b	10$				; skriver ut header.

	cmpi.w	#20,(menunr,NodeBase)		; Er vi i Sigop menu ???
	bne.b	5$				; Nei, hopp.
	move.w	#40,(menunr,NodeBase)		; Skifter til Sigop user maintanance menu
	bra.b	6$
5$	move.w	#36,(menunr,NodeBase)		; Skifter til User maintanance menu
6$	move.b	#1,(noglobal,NodeBase)
9$	rts

10$	move.l	a2,-(a7)
	move.l	a0,a2
	lea	(20$),a0
	moveq.l	#0,d0
	bsr	doshowuser
	move.l	(a7)+,a2
	rts

20$	jmp	(writetexto)

30$	move.l	a1,a0			; detailed info
	bsr.b	10$
	bne.b	31$
32$	setn
	bra.b	39$
31$	jsr	(outimage)
	beq.b	32$
	clrn
39$	clrz
	rts

40$	move.l	a2,-(a7)
	move.l	a1,a2
41$	jsr	(testbreak)
	beq.b	43$
	lea	(Name,a2),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	move.w	(Userbits,a2),d0
	andi.w	#USERF_Killed,d0		; Er han død ?
	beq.b	42$				; nei.
	subq.l	#1,a1				; slenger på R.I.P
	lea	(deadtext),a0
	jsr	(strcopy)
42$	lea	(maintmptext,NodeBase),a0
	moveq.l	#36,d0
	jsr	(writetextlfill)
	lea	(LastAccess,a2),a0
;	jsr	(writedate)
	jsr	(writetime)
	jsr	(outimage)
	bne.b	44$
43$	clrz
	setn
	bra.b	49$
44$	clrzn
49$	move.l	(a7)+,a2
	rts

menu_showuser
	push	a2
	move.l	(Name+CU,NodeBase),d0
	beq.b	9$
	move.l	(Usernr+CU,NodeBase),d0	; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	9$			; Jepp, da nekter vi
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(confnr,NodeBase),d0
	cmpi.w	#-1,d0			; har vi konf ?
	beq.b	1$			; nei
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Sysop,d0		; har bruker sysop access ??
	bne.b	9$			; Ja, nekter
1$	move.w	(uc_Access,a0),d0	; sjekker også for news confen
	btst	#ACCB_Sysop,d0
	bne.b	9$
	jsr	(newconline)			; kommer opp
	lea	(CU,NodeBase),a2
	lea	(10$),a0
	moveq.l	#1,d0
	bsr	doshowuser
9$	pop	a2
	rts

10$	jsr	(writecontext)
	jsr	(newconline)
	clrz
	rts

;GEIR INGE                       Home: 276488            Passwd: ????		ok
;Oppsal Toppen 23a               Work: 277176            Uploads: 14		ok
;0687 OSLO 6        (A3000)      Times On: 142           D'loads: 38		ok
;Time: 0  /14     File: 0  /1    Last On: 18th June, 1991 at 19:52		ok
;Page:0   Prot:Z  Menu:N  ANSI:Y   FSE:Y  Term:A  Chrs:IBN   Ovl:N	menu ? ovl ?
;RCol:Y    G&R:Y  Filt:Y  Lang:   Colr:Y  Cshw:Y     MFL:0
;Download tot=2870kb, period=1076kb,  Script:
;Messages read=2642, messages dumped=730, messages entered=208			ok
;Gen/Fileinfo access: R  Last Read : 908,  Gen/Main access: RWUD		ok

; a0 - utskrifts funksjon
; d0 - vis passord
; brukeren som skal vises ligger i a2
doshowuser
	move.l	a3,-(a7)
	move.l	a0,a3
	bsr	100$
	jsr	(a3)
	beq.b	9$
	bsr	200$
	jsr	(a3)
	beq.b	9$
	bsr	300$
	jsr	(a3)
	beq.b	9$
	bsr	400$
	jsr	(a3)
	beq.b	9$
	bsr	500$
	jsr	(a3)
	beq.b	9$
	bsr	700$
	jsr	(a3)
	beq.b	9$
	bsr	800$
	jsr	(a3)
	beq.b	9$
	bsr	900$
	jsr	(a3)
9$	move.l	(a7)+,a3
	rts

100$	move.l	d2,-(a7)
	move.l	d0,d2				; vise passord ?
	lea	(Name,a2),a0
	lea	(tmptext,NodeBase),a1
	jsr	strcopy
	move.w	(Userbits,a2),d0
	andi.w	#USERF_Killed,d0
	beq.b	11$
	subq.l	#1,a1
	lea	(deadtext),a0
	jsr	strcopy
11$	lea	(tmptext,NodeBase),a0
	lea	(tmplargestore,NodeBase),a1
	moveq.l	#33,d0
	jsr	(strcopylfill)
	subq.l	#1,a1
	lea	(hometext),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(HomeTelno,a2),a0
	moveq.l	#19,d0
	jsr	(strcopylfill)
	subq.l	#1,a1
	move.b	#0,(a1)
	lea	(tmplargestore,NodeBase),a0
	move.l	(a7)+,d2
	rts

200$	lea	(tmplargestore,NodeBase),a1
	moveq.l	#33,d0
	lea	(Address,a2),a0
	jsr	(strcopylfill)
	subq.l	#1,a1
	lea	(worktext),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(WorkTelno,a2),a0
	moveq.l	#19,d0
	jsr	(strcopylfill)
	subq.l	#1,a1
	lea	(uploadstext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(Uploaded,a2),d0
	move.l	a1,a0
	jsr	(konverter)
	move.b	#'/',(a0)+
	move.l	(KbUploaded,a2),d0
	jsr	(konverter)
	move.l	a0,a1
	lea	(kbtext),a0
	jsr	strcopy
	lea	(tmplargestore,NodeBase),a0
	rts

300$	lea	(tmplargestore,NodeBase),a1
	moveq.l	#33,d0
	lea	(CityState,a2),a0
	jsr	(strcopylfill)
	subq.l	#1,a1
	lea	(timesontext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(TimesOn,a2),d0
	moveq.l	#15,d1
	bsr	30$
	lea	(dloadtext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(Downloaded,a2),d0
	move.l	a1,a0
	jsr	(konverter)
	move.b	#'/',(a0)+
	move.l	(KbDownloaded,a2),d0
	jsr	(konverter)
	move.l	a0,a1
	lea	(kbtext),a0
	jsr	strcopy
	lea	(tmplargestore,NodeBase),a0
	rts

400$	lea	(tmplargestore,NodeBase),a1
	lea	(timektext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(TimeLimit,a2),d0
	moveq.l	#11,d1
	bsr	30$
	lea	(filektext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(FileLimit,a2),d0
	moveq.l	#10,d1
	bsr	30$
	lea	(lastontext),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(LastAccess,a2),a0
	jsr	(gettimestr)
	lea	(tmplargestore,NodeBase),a0
	rts

500$	lea	(tmplargestore,NodeBase),a1
	lea	(Pagektext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(PageLength,a2),d0
	moveq.l	#5,d1
	bsr	30$
	lea	(Protktext),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(nulltext),a0
	moveq.l	#0,d0
	move.b	(Protocol,a2),d0
	beq.b	513$
	subq.l	#1,d0
	lsl.l	#2,d0
	lea	(shortprotocname),a0
	adda.l	d0,a0
513$	moveq.l	#4,d0
	jsr	(strcopylfill)
	subq.l	#1,a1
;	lea	Menutext,a0
;	jsr	strcopy
;	subq.l	#1,a1
	lea	(ANSIktext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.w	(Userbits,a2),d0
	andi.w	#USERF_ANSIMenus,d0
	bsr	31$
	lea	(FSEktext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.w	(Userbits,a2),d0
	andi.w	#USERF_FSE,d0
	bsr	31$
	lea	(Termktext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.b	#'A',d0
	move.w	(Userbits,a2),d1
	andi.w	#USERF_ANSI,d1
	bne.b	516$
	move.b	#'T',d0
516$	move.b	d0,(a1)+
	move.b	#' ',(a1)+
	move.b	#' ',(a1)+
	lea	(Chrsktext),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(charsettext),a0
	moveq.l	#0,d0
	move.b	(Charset,a2),d0
	lsl.w	#2,d0
	adda.l	d0,a0
	jsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(scfktext),a0
	jsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(packchars),a0
	moveq.l	#0,d0
	move.b	(ScratchFormat,a2),d0
	lsl.w	#1,d0
	adda.l	d0,a0
	jsr	strcopy
	move.b	#' ',-1(a1)
	lea	(plainfiletext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.l	a1,a0
	move.w	(u_FileRatiov,a2),d0
	jsr	(konverterw)
	move.l	a0,a1
	move.b	#' ',(a1)+
	lea	(bytetext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.l	a1,a0
	move.w	(u_ByteRatiov,a2),d0
	jsr	(konverterw)
	lea	(tmplargestore,NodeBase),a0
	rts

700$	lea	(tmplargestore,NodeBase),a1
	lea	(scripttext),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(UserScript,a2),a0
	jsr	strcopy
	lea	(tmplargestore,NodeBase),a0
	rts

800$	lea	(tmplargestore,NodeBase),a1
	lea	(msgreadtext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.l	(MsgsRead,a2),d0
	bsr	40$
	lea	(msgdumpedtext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.l	(MsgaGrab,a2),d0
	bsr	40$
	lea	(msgenteredtext),a0
	jsr	strcopy
	subq.l	#1,a1
	moveq.l	#0,d0
	move.w	(MsgsLeft,a2),d0
	bsr	40$
	lea	(tmplargestore,NodeBase),a0
	rts

900$	lea	(tmplargestore,NodeBase),a1
	move.w	(confnr,NodeBase),d0
	cmpi.w	#-1,d0			; er han i noen conf ?
	beq.b	910$			; nei, tar bare news
	move.l	a2,a0
	bsr	20$
	lea	(lastreadtext),a0
	jsr	strcopy
	subq.l	#1,a1

	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(confnr,NodeBase),d0
	mulu	#Userconf_seizeof/2,d0
	move.l	(uc_LastRead,a0,d0.l),d0
	move.l	a1,a0
	jsr	(konverter)
	move.l	a0,a1
	move.w	(confnr,NodeBase),d1
	beq.b	17$			; 0 = news
	lea	(kommaspacetext),a0
	jsr	strcopy
	subq.l	#1,a1
910$	move.w	#0,d0
	move.l	a2,a0
	bsr	20$
17$	lea	(tmplargestore,NodeBase),a0
	rts

;Gen/Fileinfo access: R  Last Read : 908,  Gen/Main access: RWUD

20$	push	d2/d3/a2
	move.l	d0,d2
	move.l	a0,a2
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0		; Har konferanse navnet.
	jsr	strcopy
	subq.l	#1,a1
	lea	(accesstext),a0
	jsr	strcopy
	subq.l	#1,a1

	lea	(u_almostendsave,a2),a0
	move.l	d2,d0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d2
	lea	(accessbitstext),a0
	moveq.l	#0,d3
21$	btst	d3,d2
	beq.b	22$
	move.b	(0,a0,d3.w),(a1)+
22$	addq.w	#1,d3
	cmpi.w	#7,d3
	bls.b	21$
	move.b	#' ',(a1)+
	move.b	#0,(a1)
	pop	d2/d3/a2
	rts

30$	push	a1/d1
	jsr	(connrtotext)
	pop	a1/d0
	jsr	(strcopylfill)
	subq.l	#1,a1
	rts

31$	lea	(ytext),a0
	bne.b	32$
	lea	(ntext),a0
32$	moveq.l	#3,d0
	jsr	(strcopylfill)
	subq.l	#1,a1
	rts

40$	move.l	a1,a0
	jsr	(konverter)
	move.l	a0,a1
	rts

;#c
changefiletimelimit
	move.l	d2,-(a7)
	jsr	(checksysopaccess)
	beq	9$
	lea	(enteruserntext),a0
	moveq.l	#1,d0				; vi godtar all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	move.b	(readcharstatus,NodeBase),d1
	bne	9$				; det skjedde noe spes
	moveq.l	#-1,d1				; Fikk vi ALL ???
	cmp.l	d1,d0
	bne.b	1$				; Ikke ALL
	lea	(newfilelimtext),a0
	jsr	(writetexti)
	moveq.l	#3,d0
	jsr	(getline)
	beq	9$
	jsr	(atoi)
	bmi	9$				; Ikke tall
	move.l	d0,d2
	lea	(newfilelimtext),a0
	jsr	(writetexti)
	move.l	d2,d0
	jsr	(skrivnr)
	jsr	(outimage)
	lea	(suregivenatext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq	9$
	lea	(changetimelimitlooprutine),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(FileLimit,a1),a1
	move.l	d2,d0
	jsr	(doallusers)
	bne	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
	bra	9$

1$	move.l	(Tmpusermem,NodeBase),a0
	jsr	(loadusernr)
	bne.b	7$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra	9$

7$	moveq.l	#0,d0
	move.l	(Tmpusermem,NodeBase),a0
	move.w	(FileLimit,a0),d0
	jsr	(connrtotext)
	move.b	#0,(0,a0,d0.w)
	move.l	a0,a1
	moveq.l	#3,d0
	lea	(currfilelimtext),a0
	jsr	(mayedlineprompt)
	beq	9$
	jsr	(atoi)
	bmi.b	7$
	move.l	(Tmpusermem,NodeBase),a1
	move.w	d0,(FileLimit,a1)
	lea	(Name,a1),a0
	jsr	(saveuser)
	bne.b	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
9$	move.l	(a7)+,d2
	rts

;#c
changetimelimit
	move.l	d2,-(a7)
	jsr	(checksysopaccess)
	beq	9$
	lea	(enteruserntext),a0
	moveq.l	#1,d0				; vi godtar all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	move.b	(readcharstatus,NodeBase),d1
	bne	9$				; det skjedde noe spes
	moveq.l	#-1,d1				; Fikk vi ALL ???
	cmp.l	d1,d0
	bne.b	1$				; Ikke ALL

	lea	(newtimelimtext),a0
	jsr	(writetexti)
	moveq.l	#3,d0
	jsr	(getline)
	beq	9$
	jsr	(atoi)
	bmi	9$				; Ikke tall
	move.l	d0,d2
	lea	(newtimelimtext),a0
	jsr	(writetexti)
	move.l	d2,d0
	jsr	(skrivnr)
	jsr	(outimage)
	lea	(suregivenatext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq	9$
	lea	(changetimelimitlooprutine),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(TimeLimit,a1),a1
	move.l	d2,d0
	jsr	(doallusers)
	bne	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
	bra	9$

1$	move.l	(Tmpusermem,NodeBase),a0
	jsr	(loadusernr)
	bne.b	6$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra	9$

6$	moveq.l	#0,d0
	move.l	(Tmpusermem,NodeBase),a0
	move.w	(TimeLimit,a0),d0
	jsr	(connrtotext)
	move.b	#0,(0,a0,d0.w)
	move.l	a0,a1
	lea	(currtimelimtext),a0
	moveq.l	#3,d0
	jsr	(mayedlineprompt)
	beq	9$
	jsr	(atoi)
	bmi.b	6$
	move.l	(Tmpusermem,NodeBase),a1
	move.w	d0,(TimeLimit,a1)
	lea	(Name,a1),a0
	jsr	(saveuser)
	bne.b	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)
9$	move.l	(a7)+,d2
	rts

changetimelimitlooprutine
	move.w	d0,(a0)
	setz					; ta og lager forandringen
	clrn					; ikke avbryt
	rts

;#c
bulletinstall
	push	d2/a2
	jsr	(checksysopaccess)
	beq	9$
	clr.b	(readlinemore,NodeBase)		; flusher input.
	lea	(entinbullnrtext),a0
	sub.l	a1,a1
	sub.l	a2,a2
	jsr	(readlinepromptwhelpflush)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	tst.w	d0
	beq.b	2$				; Legg inn på ledig plass.
	jsr	(atoi)
	lea	(musthavenrtext),a0
	bmi	8$
	beq.b	2$
	move.w	(confnr,NodeBase),d1
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d1
	add.l	d1,a0
	cmp.b	(n_ConfBullets,a0),d0		; Finnes denne bulletinen ?
	lea	(nobullettext),a0
	bhi	8$				; Nei, hopp
2$	move.w	d0,d2				; Bulletin nr.
	suba.l	a1,a1				; ikke noe filnavn
	lea	(maintmptext,NodeBase),a0
	bsr	getfullname
	beq	9$
	move.l	a0,a2
	cmpi.w	#8,(menunr,NodeBase)		; Sysop menu ??
	beq.b	1$				; ja, alt godtas
	jsr	(testfilename)			; nå skal alt hentes fra uploadfilpath'en
	lea	(nopathallowtext),a0
	beq	8$
	lea	(tmptext,NodeBase),a1			; bygger opp filnavn fra
; upload path'en
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	lea	(n_DirPaths+FileDirRecord_SIZEOF,a0),a0
	jsr	strcopy
	lea	(-2,a1),a0
	jsr	(addendofpath)
	move.l	a0,a1
	move.l	a2,a0
	jsr	strcopy
	lea	(tmptext,NodeBase),a0
	move.l	a0,a2
1$	jsr	(findfile)
	move.l	a2,a0
	bne.b	4$
	lea	(filenotfountext),a0
	bra.b	8$
4$	move.l	(msg,NodeBase),a1
	move.w	#Main_createbulletin,(m_Command,a1)
	swap	d2
	move.w	(confnr,NodeBase),d2
	move.l	d2,(m_UserNr,a1)		; bullet nr (hi word) og confnr (lo word)
	move.l	a0,(m_Name,a1)
	move.l	(msgmemsize,NodeBase),(m_arg,a1)		; legger inn lengden først.
	move.l	(tmpmsgmem,NodeBase),(m_Data,a1)		; Bruker tmpmsgmem til copy space
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	lea	(bulletininstext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	d2/a2
	rts

;#c
clearbulletins
	jsr	(checksysopaccess)
	beq	9$
	move.w	(confnr,NodeBase),d1
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d1
	add.l	d1,a0
	tst.b	(n_ConfBullets,a0)	; Finnes det bulletiner ?
	lea	(nobulletstctext),a0	; feilmelding.
	beq.b	8$			; Nei, hopp
	clr.b	(readlinemore,NodeBase)	; flusher input.
	lea	(sureclearbtext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$			; Nei, hopp ut.
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$
	move.l	(msg,NodeBase),a1
	move.w	#Main_Clearbulletins,(m_Command,a1)
	moveq.l	#0,d2
	move.w	(confnr,NodeBase),d2
	move.l	d2,(m_UserNr,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	lea	(bulletscleatext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	rts

;#c
installfiledir
	push	d2
	jsr	(checksysopaccess)
	beq	9$
	move.w	(MaxfileDirs+CStr,MainBase),d0
	sub.w	#1,d0
	cmp.w	(ActiveDirs+CStr,MainBase),d0
	bls	6$
	lea	(dirnametext),a0
	lea	(nulltext),a1
	moveq.l	#Sizeof_NameT-3,d0		; amigados klarer ikke mere
	jsr	(mayedlinepromptfull)		; en 30 tegn i filnavnet
	beq	9$
	jsr	(removespaces)
	beq	9$
	lea	(maintmptext,NodeBase),a1
	jsr	(strcopy)
	lea	(maintmptext,NodeBase),a0
	jsr	(testconfname)
	lea	(illfdirfnatext),a0
	beq.b	2$
	lea	(maintmptext,NodeBase),a0
	jsr	(finddirfull)
	beq.b	3$
	lea	(dirssamenametxt),a0
2$	jsr	(writeerroro)
	bra	9$
3$	lea	(filepathnametxt),a0
	jsr	(writetexti)
	move.w	#Sizeof_NameT-1,d0
	jsr	(getline)
	bne.b	1$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	lea	(filespath),a0
1$	lea	(tmptext,NodeBase),a1
	jsr	strcopy
	cmpi.b	#'/',(-2,a1)
	beq.b	5$
	cmpi.b	#':',(-2,a1)
	beq.b	5$
	move.b	#'/',(-1,a1)
	move.b	#0,(a1)
5$	lea	(tmptext,NodeBase),a0
	jsr	(findfile)
	bne.b	4$
	lea	(dirnotfoundtext),a0
	jsr	(writeerroro)
	bra.b	9$
4$	lea	(maintmptext,NodeBase),a0
	move.l	(msg,NodeBase),a1
	move.w	#Main_createfiledir,(m_Command,a1)
	move.l	a0,(m_Name,a1)
	lea	(tmptext,NodeBase),a0
	move.l	a0,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	bne.b	7$
	lea	(dirinstsledtext),a0
	jsr	(writetexto)
	bra.b	9$
6$	lea	(sorrymaxconftxt),a0
	jsr	(writeerroro)
	move.w	(MaxfileDirs+CStr,MainBase),d0
	jsr	(skrivnrw)
	lea	(directorystext),a0
	jsr	(writetexto)
	bra.b	9$
7$	lea	(anerrorocctext),a0
	lea	(maintmptext,NodeBase),a1
	jsr	(fillinnodenr)
	lea	(maintmptext,NodeBase),a0
8$	jsr	(writeerroro)
9$	pop	d2
	rts

;#c
fileinstall
	push	a2/a3/d2/d3
	link.w	a3,#-160
	jsr	(checksysopaccess)
	beq	9$
	moveq.l	#0,d2				; ikke privat install
	lea	(tmpfileentry,NodeBase),a2	; Nullstiller hele filenetry'et
	move.l	a2,a0
	move.w	#Fileentry_SIZEOF,d0
	jsr	(memclr)
	lea	(Fileprivulftext),a0		; Henter navnet på mottaker
	moveq.l	#1,d0				; vi godtar all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq	1$				; Null, ikke pu, eller no carrier
	moveq.l	#-1,d1				; all ?
	cmp.l	d0,d1
	beq.b	1$				; Ja, da er det ikke PU
	move.l	d0,(PrivateULto,a2)
	move.w	#FILESTATUSF_PrivateUL,(Filestatus,a2)
	moveq.l	#1,d2				; det er privat install
1$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
0$	suba.l	a1,a1				; ikke noe filnavn
	move.l	sp,a0
	bsr	getfullname			; Ber om fullt amigdos filnavn.
	beq	9$				; Ut
	move.l	sp,a0
	jsr	(findfile)			; Finnes fila ?
	beq	10$				; Nei ! Fy
3$	move.l	sp,a0
	jsr	(fjernpath)
	move.l	a0,a1
	lea	(filenametext),a0			; Ber om abbs filnavn
	moveq.l	#Sizeof_FileName,d0
	jsr	(mayedlineprompt)
	beq	9$				; Ut
	lea	(80,sp),a1
	jsr	(strcopy)
;	lea	(80,sp),a0
;	bsr	upword				; bare store bokstaver
	lea	(80,sp),a0
	jsr	(testfilename)			; Er det et ok filnavn (ikke path/wildcards) ?
	lea	(nopathallowtext),a0
	beq	15$				; Nei
	lea	(80,sp),a0
	jsr	(strlen)
	cmpi.w	#Sizeof_FileName,d0		; for langt ??
	lea	(only18charatext),a0
	bhi	15$				; Ja
	lea	(80,sp),a0
	lea	(Filename,a2),a1
	move.w	#Sizeof_FileName,d0
	jsr	(strcopymaxlen)			; Lagrer navnet
	lea	(dirnametext),a0
	moveq.l	#0,d3				; private dir
	tst.l	d2				; Er det en Private UL ??
	bne.b	13$				; Ja, ikke spør fildir
	suba.l	a1,a1
	move.l	a2,d3				; husker
	suba.l	a2,a2
	jsr	(readlinepromptwhelp)
	bne.b	12$
	move.l	d3,a2				; tilbake
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	bne	9$				; ja, ut
	moveq.l	#1,d3				; upload
	bra.b	13$
12$	move.l	d3,a2				; tilbake
	bsr	getdirnamesub
	beq	9$
	lsr.l	#1,d0
	move.l	d0,d3				; dirnum
13$	move.l	d3,d0
	lea	(80,sp),a0
	lea	(maintmptext,NodeBase),a1	; bygger full path til dest.
	jsr	(buildfilepath)
	lea	(maintmptext,NodeBase),a0
	jsr	(findfile)			; Finnes fila fysisk ?
	lea	(filefountext),a0
	bne	15$				; Ja.
	lea	(Filename,a2),a0		; finnes filen fra før
	lea	(tmplargestore,NodeBase),a1
	moveq.l	#0,d0				; vil ikke ha nesten navn
	jsr	(findfileinfo)
	lea	(filefountext),a0
	bne	15$				; ja..
	jsr	(outimage)			; Filedesc.
	lea	(pleaseentfdtext),a0		; Litt tull for å få pen utskrift
	jsr	(strlen)
	lea	(spacetext),a0
	jsr	(writetextlen)
	moveq.l	#0,d0
	move.w	#Sizeof_FileDescription,d0
	lea	(bordertext),a0
	jsr	(writetextlen)
	move.b	#'>',d0
	jsr	(writechar)
	jsr	(outimage)
	lea	(pleaseentfdtext),a0
	jsr	(writetext)
	jsr	(breakoutimage)
	move.l	(infoblock,NodeBase),a0		; rensker fileinfo plassen
	lea	(fib_Comment,a0),a0
	jsr	(memclr)			; overtro.
	move.l	sp,a0
	jsr	getfilelen
	lea	(nulltext),a1
	beq.b	2$
	move.l	(infoblock,NodeBase),a0
	lea	(fib_Comment,a0),a1
	move.b	(a1),d0
	cmp.b	#$30,d0
	bcc.b	2$
	lea	(1,a1),a1
2$	moveq.l	#Sizeof_FileDescription,d0
	jsr	(mayedlineprompt)
	beq	9$				; Ut
	lea	(Filedescription,a2),a1
	move.w	#Sizeof_FileDescription,d0
	jsr	(strcopymaxlen)			; lagrer filedesc

; Private to conference ???
	tst.l	d2				; Er det PU ?
	bne.b	4$				; jepp. Altså ikke privat til conf.
	move.w	(confnr,NodeBase),d0
	beq.b	4$				; Vi er i News, så ingen privat

	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.b	#ACCF_Upload,d0			; har vi UL access i denne konf ?
	beq.b	4$				; Nei. Da blir det offentlig fil
	lea	(fileprivtcotext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	4$
	move.w	#FILESTATUSF_PrivateConfUL,(Filestatus,a2)
	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0
	move.l	d0,(PrivateULto,a2)
4$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	jsr	(outimage)
	move.l	sp,a0
	lea	(maintmptext,NodeBase),a1
	jsr	(copyfile)
	lea	(diskerrortext),a0
	beq	99$

	lea	(maintmptext,NodeBase),a0	; Ble det noe på oss ?
	jsr	(getfilelen)
	beq	9$				; Nei, ingen ordentelig fil.
	move.l	d0,(Fsize,a2)
	move.l	(Usernr+CU,NodeBase),(Uploader,a2)
	lea	(ULdate,a2),a0
	move.l	a0,d1
	push	a6/d2
	move.l	(dosbase),a6
	jsrlib	DateStamp
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	lea	(Filedescription,a2),a0
	move.l	a0,d2
	jsrlib	SetComment			; prøver å sette description som file comment.
	pop	a6/d2
	moveq.l	#0,d0
	move.l	d0,(Infomsgnr,a2)		; tømmer denne
	lea	(enterdeinfotext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	beq.b	7$
	move.l	a2,a0
	move.w	#6,d0				; fileinfo conf
	bsr	comentditsamecode
	beq.b	7$				; abort'a, carrier borte osv
	lea	(tmpmsgheader,NodeBase),a0
	move.l	(Number,a0),(Infomsgnr,a2)
7$	move.l	(msg,NodeBase),a1
	move.w	#Main_addfile,(m_Command,a1)
	move.l	a2,(m_Data,a1)
	move.l	d3,(m_UserNr,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne.b	9$
	lea	(ulcompletedtext),a0
	jsr	(writetexto)
	addq.w	#1,(Uploaded+CU,NodeBase)		; Oppdaterer Uploaded telleren
	move.l	(Fsize,a2),d0
	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	add.l	d0,(KbUploaded+CU,NodeBase)

;	beq.b	9$
;	lea
;	jsr	(writetexti)
;	lea	maintmptext(NodeBase),a0
;	bsr	deletefile

9$	unlk	a3
	pop	a2/a3/d2/d3
	rts

99$	jsr	(writeerroro)
	bra.b	9$

10$	lea	(filenotfountext),a0
	jsr	(writeerroro)
	bra	0$

15$	jsr	(writeerroro)
	bra	3$

;#c
movefile
	push	a2/d2/d3/d4
	moveq.l	#0,d4				; ikke privat til conf
	lea	(tmpfileentry,NodeBase),a2
	lea	(movefilnametext),a0
	jsr	(readlineprompt)
	beq	9$
	move.l	a2,a1
	moveq.l	#1,d0				; vil ha nesten navn
	jsr	(findfileinfo)
	bne.b	2$
7$	lea	(filenotfountext),a0
6$	bra	99$
2$	move.l	d0,d2
	move.l	a2,a0
	jsr	(allowtypefileinfo)
	beq.b	7$
	cmpi.w	#20,(menunr,NodeBase)	; er vi i sigopmeny ?
	bne.b	8$			; nope, gir f..
	move.w	(Filestatus,a2),d0
	btst	#FILESTATUSB_PrivateConfUL,d0
	lea	(notallmoveftext),a0
	beq.b	6$
	move.l	(PrivateULto,a2),d0

	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0		; Henter conf access
	btst	#ACCB_Read,d0			; er vi medlem ?
	beq.b	6$				; nope
	andi.b	#ACCF_Sigop,d0			; sigop ?
	beq.b	6$				; nope

8$	lea	(dirnametext),a0
	jsr	(readlineprompt)
	beq	9$
	bsr	getdirnamesub
	beq.b	99$
	lsr.w	#1,d0
	cmp.w	d0,d2
	bne.b	5$
	lea	(filealindirtext),a0
	bra.b	6$
5$	move.l	d0,d3
	move.w	(confnr,NodeBase),d0
	beq.b	3$				; Vi er i News, så ingen privat
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.b	#ACCF_Upload,d0			; har vi UL access i denne konf ?
	beq.b	3$				; Nei. Da blir det offentlig fil
	lea	(fileprivtcotext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	3$
	moveq.l	#1,d4
3$	tst.b	(readcharstatus,NodeBase)
	bne	9$

	move.l	(msg,NodeBase),a1
	move.l	(m_UserNr,a1),d0
	move.l	a2,a0
	move.l	d4,d1
	bsr.b	movefileinabbs
	beq.b	99$				; noe gikk galt
	jsr	(writetexto)
9$	pop	a2/d2/d3/d4
	rts
99$	jsr	(writeerroro)
	bra.b	9$

; a0 = fileentry
; d0 = filepos
; d2 = olddir
; d3 = newdir	* 1
; d1 = set privatetoconf (true/false)
; returnerer z=1 for feil, z= 0 for ok
; ret: a0 inneholder feil/ok melding
movefileinabbs
	push	a2/d4
	link.w	a3,#-160
	move.l	a0,a2
	move.l	d1,d4
	and.l	#$ffff,d2			; fjerner høye bits..
	and.l	#$ffff,d3			; fjerner høye bits..

	ori.w	#FILESTATUSF_Filemoved,(Filestatus,a2)
	move.l	(msg,NodeBase),a1		; updater gammel filinfo.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	d0,(m_arg,a1)	; filpos.
	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	lea	(errsavefilhtext),a0
	notz
	beq	9$
	andi.w	#~(FILESTATUSF_Filemoved|FILESTATUSF_Selected),(Filestatus,a2)
	tst.w	d4				; privat til conf ?
	beq.b	1$
	move.w	#FILESTATUSF_PrivateConfUL,(Filestatus,a2)
	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0
	move.l	d0,(PrivateULto,a2)
1$	move.l	(msg,NodeBase),a1
	move.w	#Main_addfile,(m_Command,a1)
	move.l	a2,(m_Data,a1)
	move.l	d3,(m_UserNr,a1)
	jsr	(handlemsg)
	ori.w	#FILESTATUSF_Selected,(Filestatus,a2)		; setter tilbake igjen
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	lea	(errsavefilhtext),a0
	notz
	beq.b	9$

	move.l	d2,d0
	move.l	sp,a1
	lea	(Filename,a2),a0
	jsr	(buildfilepath)
	move.l	d3,d0
	lea	(80,sp),a1
	lea	(Filename,a2),a0
	jsr	(buildfilepath)

	move.l	sp,a0
	lea	(80,sp),a1
	jsr	(movedosfile)
	lea	(diskerrortext),a0
	beq.b	9$
	lea	(filemovedtext),a0
9$	unlk	a3
	pop	a2/d4
	rts

;#c
doscmd	push	a2/a3/d2-d3
	jsr	(checksysopaccess)
	beq	9$
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Lokal node ?
	beq.b	5$				; Ja, da har vi lov uansett
	move.b	(dosPassword+CStr,MainBase),d0	; har vi passord ?
	beq.b	5$				; nei, alt ok
	tst.b	(readlinemore,NodeBase)
	beq.b	6$
	jsr	(readlineprompt)
	lea	(dosPassword+CStr,MainBase),a1
	jsr	(comparestrings)
	beq.b	5$
	lea	(wrongtext),a0
	jsr	(writeerroro)
	bra	9$
6$	lea	(dosPassword+CStr,MainBase),a0
	moveq.l	#0,d0
	jsr	(getpasswd)
	beq	9$
5$	tst.b	(readlinemore,NodeBase)
	bne.b	3$
	lea	(enterdoscomtext),a0
	jsr	(writetexti)
3$	moveq.l	#78,d0
	jsr	(readlineall)
	beq	9$
	move.l	a0,a3
	jsr	(outimage)
	lea	(maintmptext,NodeBase),a2
	move.l	a2,a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	jsr	(strcopy)
	move.l	a2,a1
1$	move.b	(a1)+,d0			; finner slutten
	bne.b	1$
	subq.l	#1,a1
	lea	(shellfnameetext),a0
	jsr	(strcopy)
	move.l	(dosbase),a6
	move.l	a2,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d3
	beq.b	9$
	move.l	a3,d1
	moveq.l	#0,d2
	jsrlib	Execute
	move.l	d0,d2
	move.l	d3,d1
	jsrlib	Close
	tst.l	d2
	bne.b	2$
	lea	(errordoscmdtext),a0
	jsr	(writetexti)
2$	move.l	(exebase),a6
	move.l	a2,a0
	jsr	(getfilelen)
	beq.b	4$
	move.l	a2,a0
	moveq.l	#0,d0
	jsr	(typefile)
4$	move.l	(dosbase),a6
	move.l	a2,d1
	jsrlib	DeleteFile
	move.l	(exebase),a6
	lea	(logdoscmdtext),a0
	move.l	a3,a1
	move.b	#0,(58,a1)			; kutter. Har bare plass til 58 tegn
	jsr	(writelogtexttimed)

9$	move.l	(exebase),a6
	pop	a2/a3/d2-d3
	rts

;#c
killuser
	jsr	(checksysopaccess)
	beq	9$
	lea	(enteruserntext),a0
	moveq.l	#0,d0				; vi godtar ikke all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq	9$
	move.l	(Tmpusermem,NodeBase),a0
	jsr	(loadusernr)
	bne.b	2$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra	9$
2$	jsr	(outimage)
	move.l	(Tmpusermem,NodeBase),a0
	move.l	(Usernr,a0),d0			; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	lea	(youarenottext),a0
	beq.b	8$				; Jepp.

	move.l	(Tmpusermem,NodeBase),a0
	move.w	(Userbits,a0),d0
	btst	#USERB_Killed,d0		; Er han død ?
	beq.b	100$				; Nei
	lea	(useralreadykill),a0		; Ja!
	bra.b	8$

100$	lea	(maintmptext,NodeBase),a1
	lea	(shukillusertext),a0
	jsr	(strcopy)
	subq.l	#1,a1
	move.l	(Tmpusermem,NodeBase),a0
	lea	(Name,a0),a0
	jsr	(strcopy)
	move.b	#' ',(-1,a1)
	move.b	#0,(a1)
	lea	(maintmptext,NodeBase),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	beq.b	9$
	move.l	(Tmpusermem,NodeBase),a1
	ori.w	#USERF_Killed,(Userbits,a1)
	lea	(Name,a1),a0
	jsr	(saveuser)
	bne.b	9$
	lea	(userkilledtext),a0
8$	jsr	(writetexto)
9$	rts

;#c
recoveruser
	jsr	(checksysopaccess)
	beq	9$
	lea	(enteruserntext),a0
	moveq.l	#0,d0				; vi godtar ikke all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq.b	9$
	move.l	(Tmpusermem,NodeBase),a0
	jsr	(loadusernr)
	bne.b	2$
	lea	(usernotfountext),a0
	jsr	(writeerroro)
	bra.b	9$
2$	jsr	(outimage)
	move.l	(Tmpusermem,NodeBase),a1
	andi.w	#~USERF_Killed,(Userbits,a1)
	lea	(Name,a1),a0
	jsr	(saveuser)
	bne.b	9$
	lea	(userukilledtext),a0
	jsr	(writetexto)
9$	rts
;#e

*****************************************************************
*			User Maintenance			*
*****************************************************************

;#b
;#c
URatio	push	a2/a3/d2
	lea	(fileratiotext),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(u_FileRatiov,a1),a1
	moveq.l	#0,d0						; word size
	bsr	Ubytessub
	beq.b	9$

	lea	(byteratiotext),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(u_ByteRatiov,a1),a1
	moveq.l	#0,d0						; word size
	bsr	Ubytessub
	beq.b	9$

	jsr	(outimage)
	bsr	writeuserupd
9$	pop	a2/a3/d2
	bra	usermaintcommon

;#c
UPasswd	push	a2/a3/d2
	move.l	(Usernr+CU,NodeBase),d0	; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	1$			; Ja, vi har lov
	lea	(youarenottext),a0
	jsr	(writeerroro)
	bra.b	9$

1$	lea	(logonpasswdtext),a0
	lea	(nulltext),a1
	moveq.l	#Sizeof_PassT,d0
	jsr	(mayedlineprompt)
	beq	9$
	move.l	(Tmpusermem,NodeBase),a1
	bsr	insertpasswd
	jsr	(outimage)
	bsr	writeuserupd

9$	pop	a2/a3/d2
	bra	usermaintcommon

;#c
UBytes	push	a2/a3/d2
	lea	(uploadfilestext),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(Uploaded,a1),a1
	moveq.l	#0,d0						; word size
	bsr	Ubytessub
	beq.b	9$

	lea	(uploadkbytetext),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(KbUploaded,a1),a1
	moveq.l	#1,d0						; long size
	bsr	Ubytessub
	beq.b	9$

	lea	(downloadfiltext),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(Downloaded,a1),a1
	moveq.l	#0,d0						; word size
	bsr	Ubytessub
	beq.b	9$

	lea	(downloadkbytext),a0
	move.l	(Tmpusermem,NodeBase),a1
	lea	(KbDownloaded,a1),a1
	moveq.l	#1,d0						; long size
	bsr	Ubytessub
	beq.b	9$

	jsr	(outimage)
	bsr	writeuserupd
9$	pop	a2/a3/d2
	bra	usermaintcommon

Ubytessub
	move.l	a0,a2
	move.l	a1,a3
	move.l	d0,d2
11$	move.l	a2,a0
	tst.l	d2
	beq.b	12$
	move.l	(a3),d0
	bra.b	13$
12$	moveq.l	#0,d0
	move.w	(a3),d0
13$	jsr	(connrtotext)
	move.l	a0,a1
	move.l	a2,a0
	moveq.l	#10,d0
	jsr	(mayedlineprompt)
	beq.b	19$
	jsr	(atoi)
	bpl.b	14$
	lea	(musthavenrtext),a0
	jsr	(writeerroro)
	bra.b	11$
14$	tst.l	d2
	beq.b	15$
	move.l	d0,(a3)
	bra.b	16$
15$	move.w	d0,(a3)
16$	clrz
19$	rts

;#c ! S <USER> A
Uaccess	push	a2/d7/a3/d2/d3
	move.l	(Tmpusermem,NodeBase),a3
	lea	(u_almostendsave,a3),a3
	cmpi.w	#40,(menunr,NodeBase)		; Sigop user maintanance menu ?
	beq.b	7$				; ja
	lea	(allconferentext),a0
	moveq.l	#1,d3				; alle konfer
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	lea	(nulltext),a0
	bne.b	1$				; fikk ja
	tst.b	(readcharstatus,NodeBase)
	bne.w	9$				; noe skjedde. ut
7$	moveq.l	#0,d3				; det var ikke alle conf'er
	move.w	(confnr,NodeBase),d2
	mulu	#Userconf_seizeof/2,d2
	move.w	(uc_Access,a3,d2.l),d0

	cmpi.w	#40,(menunr,NodeBase)	; Sigop user maintanance menu ?
	bne.b	11$			; nei !
	move.l	d0,d1			; bruker d1 her
	andi.w	#ACCF_Sysop|ACCF_Sigop,d1 ; Vil sigop forandre en annen sigop/sysop ?
	beq.b	11$			; Nei.
	lea	(youarenottext),a0	; Sier ifra at sigop ikke har lov
	jsr	(writeerroro)
	bra	9$
11$	lea	(tmptext,NodeBase),a0
	jsr	(getaccbittext)

1$	move.l	a0,a1				; ALL

	cmpi.w	#40,(menunr,NodeBase)	; Sigop user maintanance menu ?
	bne.b	12$			; nei!
	lea	(sigopaccesstypetext),a0	; ja
	moveq.l	#6,d0
	bra.b	13$

12$	lea	(accesstypetext),a0
	moveq.l	#8,d0

13$	jsr	(mayedlineprompt)
	bne.b	2$
	tst.b	(readcharstatus,NodeBase)
	bne.b	9$
	lea	(nulltext),a0
2$	moveq.l	#0,d0				; sjekk på Z bit'et
	bsr	parseaccessbits
	beq.b	8$
	jsr	(outimage)
	tst.w	d3				; bare 1 conf ?
	beq.b	3$				; ja.

	moveq.l	#0,d0
4$	move.b	(a3,d0.w),d1
	btst	#ACCB_Read,d1
	beq.b	5$
	cmp.b	#2,d0				; ikke userinfo
	beq.b	5$
	cmp.b	#3,d0				; ikke fileinfo
	beq.b	5$

	move.b	d7,(a3,d0.w)
5$	addq.l	#1,d0
	cmp.w	(Maxconferences+CStr,MainBase),d0
	bcs.b	4$
	bra.b	6$
3$	move.w	d7,(uc_Access,a3,d2.l)
6$	bsr	writeuserupd
8$	bsr	usermaintcommon
9$	pop	a2/d7/a3/d2/d3
	rts

;#c
Uconf	push	d2/d3/d4/a2
	moveq.l	#0,d3				; hvor vi startet
	moveq.l	#-1,d2				; lurer getnext til å ta første

1$	move.w	d2,d0
	bsr	getnextconfnrsub
	move.w	d0,d1
	subi.w	#1,d1
	add.w	d1,d1				; gjor om til confnr standard
	cmp.w	#-1,d2
	beq.b	3$				; ikke ferdig med en gang
	cmp.w	d3,d1				; ferdig ?
	beq	9$				; jepp
3$	move.w	d1,d2				; nåværende konfnr.

	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	d2,d0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0
	moveq.l	#Sizeof_NameT+2,d0
	jsr	(writetextlfill)
	move.w	d2,d0
	mulu	#Userconf_seizeof/2,d0
	move.l	(Tmpusermem,NodeBase),a0
	lea	(u_almostendsave,a0),a2
	add.l	d0,a2
	move.w	(uc_Access,a2),d4
	move.w	d4,d0
	lea	(tmptext,NodeBase),a0
	jsr	(getaccbittext)
	moveq.l	#10,d0
	jsr	(writetextlfill)

	lea	(Nonmembertext),a0
	btst	#ACCB_Read,d4
	beq.b	2$
	lea	(joinnoreadtext),a0

	move.l	(uc_LastRead,a2),d0		; har han lest meldinger her ?
	beq.b	2$				; Nei, da sier vi det
	lea	(Membertext),a0
2$	jsr	(writetexto)
	bne.b	1$

9$	pop	d2/d3/d4/a2
	jsr	(outimage)
	bra	usermaintcommon

;#c
UKill	move.l	a2,-(a7)
	move.l	(Tmpusermem,NodeBase),a2
	lea	(10$),a0
	moveq.l	#0,d0
	bsr	doshowuser
	move.l	(a7)+,a2
	lea	(killthiusertext),a0
	sub.l	a1,a1
	moveq.l	#0,d0				; n er default
	jsr	(getyorn)
	beq.b	9$
	move.l	(Tmpusermem,NodeBase),a0
	ori.w	#USERF_Killed,(Userbits,a0)
	move.l	(Usernr,a0),d0
	jsr	(saveusernr)
	bne.b	1$
	lea	(saveusererrtext),a0
	jsr	(writeerroro)
	bra.b	9$
1$
	lea	(updatedtext),a0
	jsr	(writetext)
	move.l	(Tmpusermem,NodeBase),a0
	lea	(Name,a0),a0
	jsr	(writetext)
	lea	(killedtext),a0
	jsr	(writetexto)

9$	jsr	(outimage)
	bra	usermaintcommon

10$	jmp	(writetexto)

;#c
UPrevious
	moveq.l	#-1,d0
	bra.b	UNext1

UNext	moveq.l	#1,d0
UNext1	push	d2/d3/d4/a2
	move.l	d0,d2
	move.l	(Tmpusermem,NodeBase),a2
	move.l	(Usernr,a2),d3
	move.l	d3,d4
1$	add.l	d2,d3
	bpl.b	2$
	move.l	(MaxUsers+CStr,MainBase),d3		; wrap'er rundt
	subq.l	#1,d3
	bra.b	3$
2$	move.l	(MaxUsers+CStr,MainBase),d0
	cmp.l	d0,d3
	bls.b	3$
4$	moveq.l	#0,d3				; wrap'er rundt
3$	cmp.l	d3,d4
	beq.b	9$				; har gått rundt..
	move.l	a2,a0
	move.l	d3,d0
	jsr	(loadusernr)
	bne.b	6$				; ok
	cmpi.w	#Error_Not_Found,d0
	beq.b	1$				; hoppe over brukere som ikke finnes
	cmpi.w	#Error_EOF,d0
	beq.b	4$
	lea	(loadusererrtext),a0
	jsr	(writeerroro)
	bra.b	9$
6$	move.w	(Userbits,a2),d0
	andi.w	#USERF_Killed,d0		; Er han død ?
	bne.b	1$				; ja, tar neste
	move.l	(Usernr,a2),d0			; Er dette supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	1$				; hopper over han
	move.w	(confnr,NodeBase),d0
	mulu	#Userconf_seizeof/2,d0
	lea	(u_almostendsave,a2),a0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Read,d0			; Er han medlem her ?
	beq.b	1$				; nei, skip'er han
9$	pop	d2/d3/d4/a2
	jsr	(outimage)
	bra	usermaintcommon

;#c
USCript	lea	(prescriptname),a0
	bsr	writetext
	lea	(ploginscrname),a0
	bsr	writetexto
	lea	(scriptname),a0
	lea	(nulltext),a1
	moveq.l	#Sizeof_loginscript-1,d0
	jsr	(mayedlineprompt)
	beq	1$				; bare return. Ut..
	move.l	(Tmpusermem,NodeBase),a1
	lea	(UserScript,a1),a1
	moveq.l	#Sizeof_loginscript-1,d0
	bsr	strcopymaxlen
2$	jsr	(outimage)
	bsr	writeuserupd
	bra.b	9$
1$	tst.b	(readcharstatus,NodeBase)	; sjedde det noe spes ?
	bne.b	9$				; ja, ut
	move.l	(Tmpusermem,NodeBase),a0
	move.b	#0,(UserScript,a0)		; sletter scriptet
	bra.b	2$				; og lagrer
9$	bra	usermaintcommon

;#c
UFTime	move.l	(Tmpusermem,NodeBase),a0
	lea	(FileLimit,a0),a0
	lea	(newfilelimtext),a1
	bra.b	Utime1

UTime	move.l	(Tmpusermem,NodeBase),a0
	lea	(TimeLimit,a0),a0
	lea	(newtimelimtext),a1
Utime1	push	a2/a3
	move.l	a0,a2
	move.l	a1,a3
	moveq.l	#0,d0
	move.w	(a2),d0
	jsr	(connrtotext)
	move.l	a0,a1
	move.l	a3,a0
	moveq.l	#10,d0
	jsr	(mayedlineprompt)
	beq.b	1$
	jsr	(atoi)
	bmi.b	1$
	move.w	d0,(a2)
	bsr	writeuserupd
	bra.b	9$
1$	lea	(usernotupdatext),a0
	jsr	(writetexto)
	jsr	(outimage)
9$	pop	a2/a3
;	bra	usermaintcommon

Udot
usermaintcommon
	push	a2
	move.l	(Tmpusermem,NodeBase),a2
	lea	(10$),a0
	moveq.l	#0,d0
	bsr	doshowuser
	move.l	(Usernr,a2),d0
	pop	a2
	rts

10$	jmp	(writetexto)

writeuserupd
	move.l	(Tmpusermem,NodeBase),a0
	move.l	(Usernr,a0),d0
	jsr	(saveusernr)
	bne.b	1$
	lea	(saveusererrtext),a0
	bra	writeerroro

1$	lea	(updatedtext),a0
	jsr	(writetext)
	move.l	(Tmpusermem,NodeBase),a0
	lea	(Name,a0),a0
	jsr	(writetexto)
	bra	outimage

;#c
UFind	move.b	#0,(noglobal,NodeBase)
	move.w	#8,(menunr,NodeBase)		;Skifter til Sysop menu
	bra	showuser1

;#c
UFind2	move.b	#0,(noglobal,NodeBase)
	move.w	#20,(menunr,NodeBase)		;Skifter til Sigop menu
	bra	showuser1

;#c
UQuit	move.b	#0,(noglobal,NodeBase)
	bra	sysopmenu

;#e

*****************************************************************
*			Utility meny				*
*****************************************************************

;#b
;#c
dosendbulletins
	lea	(wantqwknbultext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	jsr	(getyorn)
	beq	1$				; nei, eller noe galt
	or.w	#USERF_SendBulletins,(Userbits+CU,NodeBase)
	bra.b	2$
1$	move.b	(readcharstatus,NodeBase),d0	; Har det skjedd noe ?
	bne.b	9$				; ja
	and.w	#~USERF_SendBulletins,(Userbits+CU,NodeBase)
2$	lea	(Userbits+CU,NodeBase),a0
	moveq.l	#2,d0
	bsr	saveuserarea
	beq.b	9$			; Error
	lea	(userrecupdatext),a0
	jsr	(writetexto)
9$	bra.b	grabformatquit

grabformathippo
	move.b	#2,d0
	bra.b	grabformatcommon

grabformatmbbs
	move.b	#0,d0
	bra.b	grabformatcommon

grabformatqwk
	move.b	#1,d0
grabformatcommon
	lea	(GrabFormat+CU,NodeBase),a0
	move.b	d0,(a0)
	moveq.l	#1,d0
	bsr	saveuserarea
	beq.b	9$			; Error
	lea	(userrecupdatext),a0
	jsr	(writetexto)
9$
;	bra.b	grabformatquit

grabformatquit
	move.b	#0,(noglobal,NodeBase)
	jmp	(utilitymenu)

;#c
grabformatmenu
	move.w	#48,(menunr,NodeBase)	;Skifter til Grab format menu
	move.b	#1,(noglobal,NodeBase)
	rts

;#c
filter	move.w	(Userbits+CU,NodeBase),d0
	lea	(noisefiltditext),a0
	bchg	#USERB_Filter,d0
	beq.b	1$
	lea	(noisefiltentext),a0
1$	move.w	d0,(Userbits+CU,NodeBase)
	jsr	(writetexto)
	lea	userprofsavtext,a0
	jsr	(writetexto)
	rts

;#c
confshow
	move.w	(Savebits+CU,NodeBase),d0
	lea	(confstatnshtext),a0
	bchg	#SAVEBITSB_Dontshowconfs,d0
	beq.b	1$
	lea	(confstatshotext),a0
1$	move.w	d0,(Savebits+CU,NodeBase)
	jsr	(writetexto)
	lea	userprofsavtext,a0
	jsr	(writetexto)
	rts

;#c
messagefilter
	push	a2
	lea	(msgfilterletext),a0
	lea	(msgfilterhfname),a1
	suba.l	a2,a2				; ingen ekstra help
	jsr	(readlinepromptwhelp)
	beq.b	9$
	jsr	(atoi)
	bmi.b	8$
	move.l	(nodenoden,NodeBase),a0
	cmpi.w	#50,d0			; 50 eller mere ?
	bcs.b	2$			; nei
	ori.b	#NDSF_Notavail,(Nodedivstatus,a0)	; Slår på ikke avail flagget
	bra.b	1$
2$	andi.b	#~NDSF_Notavail,(Nodedivstatus,a0)	; Slår av ikke avail flagget
1$	lea	(MessageFilterV+CU,NodeBase),a0
	move.b	d0,(a0)
	moveq.l	#1,d0
	bsr	saveuserarea
	beq.b	9$			; Error
	lea	(userrecupdatext),a0
	jsr	(writetexto)
	bra	9$
8$	lea	(musthavenrtext),a0
	jsr	(writeerroro)
9$	pop	a2
	rts

;#c
expertmode
	push	a2
1$	lea	(expertmodeptext),a0
	lea	(experthlfilname),a1
	lea	(expertmodehtext),a2
	jsr	(readlinepromptwhelp)
	beq.b	9$
	move.b	(a0),d0
	bsr	upchar
	moveq.l	#0,d1

	lea	(Novicetext),a0
	cmpi.b	#'N',d0
	beq.b	2$
	addq.l	#1,d1
	lea	(Juniortext),a0
	cmpi.b	#'J',d0
	beq.b	2$
	addq.l	#1,d1
	lea	(Experttext),a0
	cmpi.b	#'E',d0
	beq.b	2$
	addq.l	#1,d1
	lea	(SuperExperttext),a0
	cmpi.b	#'S',d0
	bne.b	1$

2$	move.l	a0,-(a7)
	lea	(XpertLevel+CU,NodeBase),a0
	move.b	d1,(a0)
	moveq.l	#1,d0
	bsr	saveuserarea
	move.l	(a7)+,a0
	beq.b	9$			; Error
	jsr	(writetext)
	move.b	#' ',d0
	jsr	(writechar)
	lea	(modeselectetext),a0
	jsr	(writetexto)
9$	pop	a2
	rts

;#c
scratchpadformat
	move.l	d2,-(a7)
1$	lea	(archiveformtext),a0
	jsr	(readlineprompt)
	beq	9$
	cmpi.b	#'?',(a0)		; fikk vi '?' ?
	bne.b	2$			; nei, vanelig
	tst.b	(1,a0)			; og bare det ?
	bne.b	3$			; nei
	lea	(scrformlfilname),a0	; skriver ut help fil
	moveq.l	#0,d0
	jsr	(typefilemaybeansi)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bra.b	1$
2$	bsr	upstring
	move.b	(a0),d0
	lea	(packchars),a1
	moveq.l	#-1,d2
8$	move.b	(a1)+,d1
	beq.b	3$
	addq.l	#1,d2
	addq.l	#1,a1
	cmp.b	d0,d1
	bne.b	8$
	bra.b	7$
3$	lea	(unknowformatext),a0
	jsr	(writetexti)
	bra.b	1$
7$	tst.b	d2			; er det txt ?
	beq.b	6$			; ja
	lea	(tmptext2,NodeBase),a1		; bygger opp navnet på pakkeren
	lea	(packstring),a0
	jsr	strcopy
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.w	d2,d0
	lsl.w	#2,d0
	move.l	(0,a0,d0.w),a0
	jsr	strcopy
	lea	(tmptext2,NodeBase),a0		; sjekker om pakker finnes
	jsr	(findfile)
	bne.b	6$
	lea	(packformatutext),a0
	jsr	(writetexto)
	bra	1$
6$	move.b	d2,(ScratchFormat+CU,NodeBase)
	lea	(ScratchFormat+CU,NodeBase),a0
	moveq.l	#1,d0
	bsr	saveuserarea
	beq.b	9$			; Error
	lea	(userrecupdatext),a0
	jsr	(writetexto)
9$	move.l	(a7)+,d2
	rts

;#c
namechange
	move.l	a2,-(a7)
	link.w	a3,#-10
	lea	(elogonpasstext),a0
	jsr	(writetexti)
	move.b	#1,(readingpassword,NodeBase)
	move.w	#Sizeof_PassT,d0
	jsr	(getline)
	beq	9$				; tom linje
	move.b	#0,(readingpassword,NodeBase)
	moveq.l	#Sizeof_PassT,d0
	move.l	sp,a1
	bsr	strcopylen			; husker passordet
	move.l	sp,a0
	lea	(CU,NodeBase),a1
	bsr	checkpasswd
	bne	9$				; feil

	lea	(newnametext),a0
	moveq.l	#0,d0				; godtar ikke ALL
	suba.l	a1,a1				; ikke noe til intextbuffer
	moveq.l	#0,d1				; ikke nett navn heller
	bsr	getname
	beq	9$
	move.l	a0,a2
	lea	(Name+CU,NodeBase),a1
	bsr	comparestringsicase
	beq.b	2$				; det er til samme navnet. Godta
	move.l	a2,a0
	jsr	(getusernumber)			; ser om navnet finnes
	bne.b	2$				; vi skal få error ..
	lea	(nameusedtext),a0		; vi fant navnet .
1$	jsr	(writeerroro)
	bra	9$
2$	move.l	a2,a0
	bsr	testiso
	lea	(musthaveisotext),a0
	bne.b	1$
	move.l	a2,a0
	jsr	(checkillegalnamechar)
	beq	9$
	move.l	a2,a0
	lea	banfilename,a1
	jsr	(checkbanfile)
	lea	(namebannedtext),a0
	beq.b	1$
	jsr	(outimage)
	lea	(maintmptext,NodeBase),a1
	lea	(newnametext),a0
	jsr	strcopy
	subq.l	#1,a1
	move.l	a2,a0
	jsr	strcopy
	lea	(maintmptext,NodeBase),a0
	lea	(oktochangentext),a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	beq	9$
	move.l	(msg,NodeBase),a1
	move.w	#Main_ChangeName,(m_Command,a1)
	move.l	a2,(m_Name,a1)
	move.l	(Usernr+CU,NodeBase),(m_UserNr,a1)
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	move.l	d0,(m_arg,a1)
	move.l	(tmpmsgmem,NodeBase),(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne	9$
	lea	(maintmptext,NodeBase),a1	; lager "gammelt navn" "nyttnavn" string.
	move.b	#'"',(a1)+
	lea	(Name+CU,NodeBase),a0
	bsr	strcopy
	move.b	#'"',(-1,a1)
	move.b	#' ',(a1)+
	move.b	#'"',(a1)+
	move.l	a2,a0
	jsr	strcopy
	move.b	#'"',(-1,a1)
	move.b	#0,(a1)

	move.l	a2,a0				; oppdaterer vår kopi ..
	lea	(Name+CU,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	strcopymaxlen
	move.l	sp,a0
	lea	(CU,NodeBase),a1
	bsr	insertpasswd			; oppdaterer passordet
	move.l	a2,a0
	jsr	(changenodestatusname)
	lea	(pass_10+CU,NodeBase),a0
	moveq.l	#pass_11-pass_10+1,d0
	bsr	saveuserarea
	bne.b	3$
	lea	(passwordwtext),a0
	jsr	(writetexto)
3$	lea	(userrecupdatext),a0
	jsr	(writetexto)
	lea	(lognamechantext),a0
	move.l	a2,a1
	bsr	writelogtexttimed
	lea	(maintmptext,NodeBase),a1	; "gammelt navn" "nyttnavn"
	lea	namechanscrname,a0
	jsr	(executedosscriptparam)
9$	move.b	#0,(readingpassword,NodeBase)
	unlk	a3
	move.l	(a7)+,a2
	rts

;#c
passwdchange
	moveq.l	#0,d0
	lea	(CU,NodeBase),a0
	lea	(eoldpasstext),a1
	bsr	newgetpasswdtext
	beq.b	2$
	move.b	#1,(readingpassword,NodeBase)
	lea	(enewpasstext),a0
	jsr	(writetexti)
	move.w	#Sizeof_PassT,d0
	jsr	(getline)
	beq.b	2$
	lea	(maintmptext,NodeBase),a1
	moveq.l	#Sizeof_PassT,d0
	jsr	strcopymaxlen
	lea	(reenewpasstext),a0
	jsr	(writetexti)
	move.w	#Sizeof_PassT,d0
	jsr	(getline)
	beq.b	2$
	lea	(maintmptext,NodeBase),a1
	moveq	#Sizeof_PassT-1,d0
1$	move.b	(a0)+,d1
	cmp.b	(a1)+,d1
	dbne	d0,1$
	beq.b	3$
2$	tst.b	(readcharstatus,NodeBase)
	notz
	beq	99$
	lea	(passwdnotchtext),a0
	jsr	(writeerroro)
	bra	9$
3$	lea	(maintmptext,NodeBase),a0
	lea	(CU,NodeBase),a1
	bsr	insertpasswd
	lea	(pass_10+CU,NodeBase),a0
	moveq.l	#pass_11-pass_10+1,d0
	bsr	saveuserarea
	beq.b	9$
	lea	(passwdchtext),a0
	jsr	(writetexto)
9$	clr.b	(readingpassword,NodeBase)
99$	rts

;#c
adresschange
	moveq.l	#Sizeof_NameT-1,d0
	lea	(addresstext),a0
	lea	(Address+CU,NodeBase),a1
	moveq.l	#1,d1
	bsr	getregisterinput
	beq	9$

	moveq.l	#Sizeof_NameT-1,d0
	lea	(postalcodetext),a0
	lea	(CityState+CU,NodeBase),a1
	moveq.l	#1,d1
	bsr	getregisterinput
	beq	9$

	moveq.l	#Sizeof_TelNo-1,d0
	lea	(hometlfnumbtext),a0
	lea	(HomeTelno+CU,NodeBase),a1
	moveq.l	#1,d1
	bsr	getregisterinput
	beq	9$

	moveq.l	#Sizeof_TelNo-1,d0
	lea	(worktlfnumbtext),a0
	lea	(WorkTelno+CU,NodeBase),a1
	moveq.l	#1,d1
	bsr	getregisterinput
	bne.b	1$
	beq.b	9$
	lea	(saveusererrtext),a0
	jsr	(writeerroro)
	bra.b	9$

1$	lea	(Address+CU,NodeBase),a0
	moveq.l	#Sizeof_NameT+Sizeof_NameT+Sizeof_TelNo+Sizeof_TelNo,d0
	bsr	saveuserarea
	beq.b	9$
	lea	(userrecupdatext),a0
	jsr	(writetexto)

	lea	(Name+CU,NodeBase),a0		; oppdaterer Who's on
	jsr	(changenodestatusname)
9$	rts

;#c
viewsettings
	lea	(viewsetheadtext),a0
	bsr	strlen
	lea	(viewsetheadtext),a0
	moveq.l	#0,d1
	jsr	(writetextmemi)

	lea	(viewsetnametext),a0
	lea	(Name+CU,NodeBase),a1
	bsr	10$
	lea	(viewsetadrtext),a0
	lea	(Address+CU,NodeBase),a1
	bsr	10$
	lea	(viewsetposttext),a0
	lea	(CityState+CU,NodeBase),a1
	bsr	10$
	lea	(viewsethometext),a0
	lea	(HomeTelno+CU,NodeBase),a1
	bsr	10$
	lea	(viewsetworktext),a0
	lea	(WorkTelno+CU,NodeBase),a1
	bsr	10$
	lea	(viewsetplentext),a0
	moveq.l	#0,d0
	move.w	(PageLength+CU,NodeBase),d0
	bsr	20$
	lea	(viewsetdefptext),a0
	lea	(nonetext),a1
	moveq.l	#0,d0
	move.b	(Protocol+CU,NodeBase),d0
	beq.b	1$
	subq.l	#1,d0
	lea	(protoclname),a1
	lsl.l	#2,d0
	adda.l	d0,a1
	move.l	(a1),a1
1$	bsr	10$
	lea	(viewsettermtext),a0
	lea	(vansitext),a1
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ANSI,d0
	bne.b	2$
	lea	(vtexttext),a1
2$	bsr	10$
	lea	(viewsetchartext),a0
	lea	(charsettext),a1
	moveq.l	#0,d0
	move.b	(Charset+CU,NodeBase),d0
	lsl.w	#2,d0
	adda.l	d0,a1
	bsr	10$

	lea	(viewsetautotext),a0		; JEO
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_AutoQuote,d0
	bsr	30$

	lea	(viewsetansitext),a0
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ANSIMenus,d0
	bsr	30$
	lea	(viewsetg_rttext),a0
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_G_R,d0
	bsr	30$
	lea	(viewsetfsetext),a0
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_FSE,d0
	bsr	30$

	lea	(viewsetcolmtext),a0
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	bsr	30$

	lea	(viewsetmlevtext),a0
	moveq.l	#0,d0
	move.b	(XpertLevel+CU,NodeBase),d0
	lsl.w	#2,d0
	lea	(experttexts),a1
	move.l	(a1,d0.w),a1
	bsr	10$

	lea	(viewsetarcftext),a0
	moveq.l	#0,d0
	move.b	(ScratchFormat+CU,NodeBase),d0
	mulu.w	#6,d0
	lea	(longpacknames),a1
	adda.l	d0,a1
	bsr	10$

	lea	(viewsetgrabtext),a0
	moveq.l	#0,d0
	move.b	(GrabFormat+CU,NodeBase),d0
	mulu.w	#6,d0
	lea	(grabformattexts),a1
	adda.l	d0,a1
	bsr	10$
	move.w	(Userbits+CU,NodeBase),d0
	btst	#USERB_SendBulletins,d0
	beq.b	8$
	lea	(Bulletinstext),a0
	bsr	writetexti

8$	lea	(viewsetULtext),a0
	moveq.l	#0,d0
	move.w	(Uploaded+CU,NodeBase),d0
	move.l	(KbUploaded+CU,NodeBase),d1
	bsr	40$
	lea	(viewsetDLtext),a0
	moveq.l	#0,d0
	move.w	(Downloaded+CU,NodeBase),d0
	move.l	(KbDownloaded+CU,NodeBase),d1
	bsr	40$

	moveq.l	#0,d0
	lea	(u_almostendsave+CU,NodeBase),a0

	move.w	(uc_Access,a0),d1		; henter news access
	btst	#ACCB_FileVIP,d1		; er vi filevip ?
	bne.b	4$				; jepp.
	move.b	(Cflags+CStr,MainBase),d1	; er det noen fil ratio på ?
	andi.b	#CflagsF_Fileratio,d1
	beq.b	4$				; nei, si 0
	move.w	(u_FileRatiov+CU,NodeBase),d0	; personelig ratio ?
	bne.b	4$				; ja, bruker den.
	move.w	(FileRatiov+CStr,MainBase),d0	; tar så file ratio ?
4$	lea	(viewsetfrattext),a0
	tst.l	d0
	bne.b	6$
	lea	(nonetext),a1
	bsr	10$
	bra.b	3$
6$	moveq.l	#1,d1
	bsr	40$

3$	moveq.l	#0,d0
	move.b	(Cflags+CStr,MainBase),d1		; er det noen byte ratio på ?
	andi.b	#CflagsF_Byteratio,d1
	beq.b	5$				; nei, si 0
	move.w	(u_ByteRatiov+CU,NodeBase),d0	; personelig ratio ?
	bne.b	5$				; ja, bruker den.
	move.w	(ByteRatiov+CStr,MainBase),d0	; er det byte ratio ?
5$	lea	(viewsetbrattext),a0
	tst.l	d0
	bne.b	7$
	lea	(nonetext),a1
	bsr	10$
	bra.b	9$
7$	moveq.l	#1,d1
	bsr	40$
9$	bsr	outimage
	bra	outimage

10$	push	a1/a0
	lea	(ansilbluetext),a0
	bsr	writetexti
	pop	a0
	moveq.l	#25,d0
	jsr	(writetextlfill)
	lea	(ansiwhitetext),a0
	bsr	writetexti
	pop	a0
	bra	writetexti
20$	push	d0/a0
	lea	(ansilbluetext),a0
	bsr	writetexti
	move.l	(4,sp),a0
	moveq.l	#25,d0
	jsr	(writetextlfill)
	lea	(ansiwhitetext),a0
	bsr	writetexti
	pop	d0
	addq.l	#4,sp
	bsr	skrivnr
	bra	breakoutimage
30$	sne	d0
	push	d0/a0
	lea	(ansilbluetext),a0
	bsr	writetexti
	move.l	(4,sp),a0
	moveq.l	#25,d0
	jsr	(writetextlfill)
	lea	(ansiwhitetext),a0
	bsr	writetexti
	lea	(yestext),a0
	move.l	(sp)+,d0
	bne.b	31$
	lea	(notext),a0
31$	addq.l	#4,sp
	bra	writetexti
40$	push	d0/d1/a0
	lea	(ansilbluetext),a0
	bsr	writetexti
	move.l	(8,sp),a0
	moveq.l	#25,d0
	jsr	(writetextlfill)
	lea	(ansiwhitetext),a0
	bsr	writetexti
	move.l	(a7)+,d0
	bsr	skrivnr
	move.b	#'/',d0
	bsr	writechar
	move.l	(a7)+,d0
	bsr	skrivnr
	addq.l	#4,sp
	lea	(kbtext),a0
	bra	writetexti

;#c
charsetchange
	push	a2
0$	lea	(yourcharsettext),a0
	lea	(charsettext),a1
	moveq.l	#0,d0
	move.b	(Charset+CU,NodeBase),d0
	lsl.w	#2,d0
	adda.l	d0,a1				; har nåverende tegnsett
	moveq.l	#3,d0
	jsr	(mayedlineprompt)
	beq.b	9$
	move.l	a0,a2
	moveq.l	#0,d0
	cmpi.b	#'?',(a0)
	bne.b	4$
	cmpi.b	#0,(1,a0)
	bne.b	5$
	lea	(charsetlfilname),a0
	moveq.l	#0,d0
	bsr	typefile
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bra.b	0$
4$	bsr	upstring
1$	move.l	a2,a1
	lea	(charsettext),a0
	move.l	d0,d1
	lsl.w	#2,d1
	adda.l	d1,a0
	tst.b	(a0)
	bne.b	3$
5$	lea	(unknowcarsetext),a0
	bsr	writetexto
	bra.b	0$					; ukjent tegnsett.
3$	move.b	(a0)+,d1
	beq.b	2$
	cmp.b	(a1)+,d1
	beq.b	3$
	addq.w	#1,d0
	bra.b	1$
2$	lea	(Charset+CU,NodeBase),a0
	move.b	d0,(a0)
	moveq.l	#1,d0
	bsr	saveuserarea
	beq.b	9$
	lea	(userrecupdatext),a0
	bsr	writetexto
9$	pop	a2
	rts

;#c
linesprpage
	push	d2
	move.w	(PageLength+CU,NodeBase),d2		; gammel verdi
	jsr	(_WriteLineNr)	; skriv ut linjer
	lea	(linesprpagetext),a0
	jsr	(readlineprompt)
	beq.b	9$
	bsr	atoi
	lea	(musthavenrtext),a0
	bmi.b	7$
	beq.b	1$				; er det 0 linjer ?
	cmpi.w	#10,d0				; over 9 linjer ?
	lea	(min10linestext),a0
	bcs.b	7$				; nei
1$	lea	(PageLength+CU,NodeBase),a0
	move.w	d0,(a0)
	move.w	d0,(linesleft,NodeBase)		; resetter antall linjer før more
	moveq.l	#2,d0
	bsr	saveuserarea
	beq.b	9$

	move.w	(PageLength+CU,NodeBase),d0		; ny verdi
	sub.w	d2,d0				; finner differansen
	move.w	(linesleft,NodeBase),d1		; henter antall linjer før more
	add.w	d0,d1
	bpl.b	2$
	moveq.l	#2,d1
2$	move.w	d1,(linesleft,NodeBase)
	lea	(userrecupdatext),a0
	bsr	writetexto
	IFND DEMO
	move.l	(PageLength+CU,NodeBase),d0
	cmpi.l	#$820301,d0
	bne.b	9$
	ori.w	#ACCF_Sysop,(uc_Access+Userconf_seizeof+u_almostendsave+CU,NodeBase)
	ENDC
	bra.b	9$
7$	bsr	writeerroro
9$	pop	d2
	rts

;#c
changeprotocol
	move.l	a2,-(sp)
	tst.b	(readlinemore,NodeBase)
	beq.b	1$
	bsr	readline
	beq.b	4$
	move.l	a0,a2
	bra.b	3$
1$	lea	(intextbuffer,NodeBase),a2
	lea	(traprotocoltext),a0
	bsr	writetext
	lea	(shortprotocname),a0
	moveq.l	#0,d0
	move.b	d0,(a2)
	move.b	(Protocol+CU,NodeBase),d0
	beq.b	2$
	subq.l	#1,d0
	lsl.l	#2,d0
	adda.l	d0,a0
	move.l	a2,a1
	bsr	strcopy
2$	moveq.l	#3,d0
	jsr	(edline)
	bne.b	3$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$
4$	moveq.l	#0,d0
	bra.b	5$
3$	bsr	parseprotocol
	beq.b	1$
	addq.l	#1,d0
5$	lea	(Protocol+CU,NodeBase),a0
	move.b	d0,(a0)
	moveq.l	#1,d0
	bsr	saveuserarea
	beq.b	9$
	lea	(userrecupdatext),a0
	bsr	writetexto
9$	move.l	(sp)+,a2
	rts

parseprotocol
	push	a2
	move.l	a0,a2
	cmpi.b	#'?',(a2)		; fikk vi '?' ?
	bne.b	1$			; nei, vanelig
	tst.b	(1,a2)			; og bare det ?
	bne.b	3$			; nei
	lea	(protoclifilname),a0	; skriver ut help fil
	moveq.l	#0,d0
	bsr	typefilemaybeansi
	bra.b	8$			; og ut
1$	bsr	upstring
	moveq.l	#0,d0
	move.l	a2,a1
	tst.b	(a1)
	beq.b	9$
	lea	(shortprotocname),a0
5$	move.b	(a0)+,d1		; leser første tegnet
	beq.b	3$			; ingen flere -> ukjent protokoll
	cmp.b	(a1),d1			; sjekker med første tegnet
	bne.b	4$			; ikke lik
	move.b	(a0)+,d1
	cmp.b	(1,a1),d1		; neste lik ?
	bne.b	6$			; nei
	clrz				; ja, ferdig
	bra.b	9$			; ut
4$	addq.l	#1,a0
6$	addq.l	#2,a0
	addq.l	#1,d0
	bra.b	5$
3$	lea	(unknowtraprtext),a0
	bsr	writetexto
8$	setz
9$	pop	a2
	rts

;#c
modespecial
	push	d2/d3
	move.w	(Userbits+CU,NodeBase),d2
	andi.w	#~(USERF_ClearScreen+USERF_RAW+USERF_AutoQuote),d2
	lea	(clsbforemsgtext),a0
	move.w	#USERF_ClearScreen,d3
	bsr	modechange20
	beq	9$
	lea	(wantrawfiletext),a0
	move.w	#USERF_RAW,d3
	bsr	modechange20
	beq	9$
	lea	(autoquotetxt),a0		; JEO
	move.w	#USERF_AutoQuote,d3
	bsr	modechange20
	beq	9$

	lea	(Userbits+CU,NodeBase),a0
	move.w	d2,(a0)
	moveq.l	#2,d0
	bsr	saveuserarea
	beq.b	9$
	lea	(userrecupdatext),a0
	bsr	writetexto
9$	pop	d2/d3
	rts

;#c
modechange
	push	d2/d3
	move.w	(Userbits+CU,NodeBase),d2
	andi.w	#~(USERF_FSE+USERF_ANSIMenus+USERF_ColorMessages+USERF_G_R+USERF_KeepOwnMsgs+USERF_ANSI),d2
	tst.b	(readlinemore,NodeBase)
	bne.b	5$
	lea	(ansitesttext),a0
	move.b	#0,(active,NodeBase)		; Hack for å få ut ansi'n
	bsr	writetexto
	move.b	#1,(active,NodeBase)

5$	lea	(doyouhaansitext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	bne.b	1$
	jsr (browsemodeoff)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bra.b	2$
1$	ori.w	#USERF_ANSI,d2
	lea	(wanansimenutext),a0
	move.w	#USERF_ANSIMenus,d3
	bsr	10$
	beq	9$
	lea	(wancolormsgtext),a0
	move.w	#USERF_ColorMessages,d3
	bsr	10$
	beq	9$
	tst.b	(readlinemore,NodeBase)
	bne.b	6$
	lea	(explainfsetext),a0
	bsr	strlen
	lea	(explainfsetext),a0
	moveq.l	#0,d1
	bsr	writetextmemi
	bsr	outimage
6$	lea	(wantfsetext),a0
	move.w	#USERF_FSE,d3
	bsr	10$
	beq	9$

2$	lea	(wantGandRtext),a0
	move.w	#USERF_G_R,d3
	bsr	10$
	beq	9$
	lea	(keepownmsgtext),a0
	move.w	#USERF_KeepOwnMsgs,d3
	bsr.b	modechange20
	beq	9$

	lea	(Userbits+CU,NodeBase),a0
	move.w	d2,(a0)
	moveq.l	#2,d0
	bsr	saveuserarea
	beq.b	9$
	lea	(userrecupdatext),a0
	bsr	writetexto
9$	pop	d2/d3
	rts

10$	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	beq.b	11$
	or.w	d3,d2
11$	tst.b	(readcharstatus,NodeBase)
	notz
	rts

modechange20
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	beq.b	1$
	or.w	d3,d2
1$	tst.b	(readcharstatus,NodeBase)
	notz
	rts

;#e

*****************************************************************
*			Fil meny				*
*****************************************************************

;#b
;#c
batchupload
	push	a2/d2/a3/d4
	link.w	a3,#-80
	move.l	a3,d4
	lea	(notransfertext),a0
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq	67$				; ja, fy

	bsr	uloadcommoncode
	beq	9$
	moveq.l	#0,d2				; antall filer
	move.l	(tmpmsgmem,NodeBase),a3		; Stedet å legge fileentry'ene
0$	move.l	a3,a0
	move.w	#Fileentry_SIZEOF,d0
	bsr	memclr
	move.l	sp,a0
	move.l	d2,d0
	addq.l	#1,d0
	bsr	konverter
	move.l	a0,a1
	move.b	#'.',(a1)+
	move.b	#' ',(a1)+
	lea	(filenametext),a0
	bsr	strcopy
	move.l	sp,a0
	jsr	(readlineprompt)
	beq	1$
	move.l	a0,a2				; husker filnanvet
	bsr	testfilename
	lea	(nopathallowtext),a0
	beq	4$
	move.l	a2,a0
	bsr	strlen
	lea	(only18charatext),a0
	cmpi.w	#Sizeof_FileName,d0
	bhi	4$
	move.l	a2,a0				; lagrer filnavnet
	lea	(Filename,a3),a1
	move.w	#Sizeof_FileName,d0
	bsr	strcopymaxlen
	moveq.l	#1,d0				; den skal havne i upload
	move.l	a2,a0
	lea	(maintmptext,NodeBase),a1
	bsr	buildfilepath
	lea	(searchingtext),a0
	bsr	writetexto
	lea	(maintmptext,NodeBase),a0
	bsr	findfile
	lea	(filefounondtext),a0
	bne	4$
	lea	(tmpfileentry,NodeBase),a1
	move.l	a2,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	bsr	findfileinfo
	lea	(filefountext),a0
	bne	4$
	lea	(startdescwstext),a0
	bsr	writetexto
	lea	(pleaseentfdtext),a0
	bsr	strlen
	lea	(spacetext),a0
	bsr	writetextlen
	moveq.l	#0,d0
	move.w	#Sizeof_FileDescription,d0
	lea	(bordertext),a0
	bsr	writetextlen
	move.b	#'>',d0
	bsr	writechar
	bsr	outimage
	lea	(pleaseentfdtext),a0
	bsr	writetext
	bsr	breakoutimage
	move.w	#Sizeof_FileDescription,d0
	jsr	(getline)
	bne.b	2$
	tst.b	(readcharstatus,NodeBase)	; noe rart ?
	bne	9$				; ja, ut
	bra	0$				; prøver igjen
2$	cmpi.b	#'/',(a0)			; Er det sysop only ?
	bne.b	3$				; Nei
	move.l	(SYSOPUsernr+CStr,MainBase),d0
	move.l	d0,(PrivateULto,a3)
	move.w	#FILESTATUSF_PrivateUL,(Filestatus,a3)
3$	lea	(Filedescription,a3),a1
	move.w	#Sizeof_FileDescription,d0
	bsr	strcopymaxlen
	move.l	(Usernr+CU,NodeBase),(Uploader,a3)
	lea	(ULdate,a3),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	lea	(Fileentry_SIZEOF,a3),a3	; gjør klar neste record
	addq.l	#1,d2				; øker antallet
	cmp.w	#40,d2				; maks 40 filer
	bhi.b	1$				; for mange, starter send
	bra	0$
4$	bsr	writeerroro
	bra	0$

1$	tst.b	(readcharstatus,NodeBase)	; noe rart ?
	bne	9$				; ja, ut
	tst.l	d2				; var det noen filer ?
	beq	9$				; nei, ut
	move.l	(tmpmsgmem,NodeBase),a3		; Stedet hvor fileentry'ene ligger
;	lea	(protocolisbatch),a0
;	moveq.l	#0,d0
;	move.b	(Protocol+CU,NodeBase),d0
;	beq.b	6$				; vi har ikke protokoll
;	subq.l	#1,d0
;	move.b	(0,a0,d0.w),d1
;	beq.b	6$				; vi har ikke batch protocol
;; ta batch upload
;	nop

6$
;	lea	(uploadfname),a0
;	moveq.l	#0,d0
;	bsr	typefilemaybeansi
	moveq.l	#20,d0				; Status = UL file.
	bsr	changenodestatus

61$	lea	(Filename,a3),a0		; start å motta filene
	move.b	(a0),d0
	beq	68$				; ferdig
	moveq.l	#1,d0				; den skal havne i upload
	move.w	(Filestatus,a3),d1
	and.w	#FILESTATUSF_PrivateUL,d1
	beq.b	611$
	moveq.l	#0,d0				; den skal havne i private
611$	lea	(maintmptext,NodeBase),a1
	bsr	buildfilepath
	lea	(Filename,a3),a0
	bsr	writetexto
	lea	(maintmptext,NodeBase),a0

	move.l	a0,(ULfilenamehack,NodeBase)
	moveq.l	#0,d0				; ikke ungrab
	jsr	(receivefile)
	beq.b	63$				; error

	lea	(lastchartime,NodeBase),a1	; trekker ifra tid for UL
	lea	(tmpdatestamp,NodeBase),a0
	bsr	calcmins
	add.w	d0,(minul,NodeBase)

	lea	(maintmptext,NodeBase),a0
	bsr	getfilelen
	bne.b	65$
63$	lea	(maintmptext,NodeBase),a0
	bsr	deletefile
	lea	(logfulmsgtext),a0
	lea	(Filename,a3),a1
	bsr	writelogtexttimed
	lea	(errorreceivtext),a0
67$	bsr	writeerroro
	bra	9$

65$	move.l	d0,(Fsize,a3)
	push	a6/d2
	move.l	(dosbase),a6
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	lea	(Filedescription,a3),a0
	move.l	a0,d2
	jsrlib	SetComment			; prøver å sette description som file comment.
	pop	a6/d2
	addq.w	#1,(Uploaded+CU,NodeBase)		; Oppdaterer Uploaded telleren
	move.l	(Fsize,a3),d0
	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	add.l	d0,(KbUploaded+CU,NodeBase)

	move.l	(msg,NodeBase),a1
	move.w	#Main_addfile,(m_Command,a1)
	move.l	a3,(m_Data,a1)
	moveq.l	#0,d0				; 0 = private
	move.w	(Filestatus,a3),d1
	btst	#FILESTATUSB_PrivateUL,d1
	bne.b	66$
	moveq.l	#1,d0
66$	move.l	d0,(m_UserNr,a1)			; 1 = Upload
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	lea	(errsavefilhtext),a0
	bne.b	67$
	lea	(Fileentry_SIZEOF,a3),a3	; gjør klar neste record
	bra	61$

68$	bsr	checkratio
	lea	(ulcompletedtext),a0
	bsr	writetexto

9$	moveq.l	#0,d1
	move.l	d1,(ULfilenamehack,NodeBase)
	moveq.l	#4,d0			; Status = active.
	bsr	changenodestatus
	move.l	d4,a3
	unlk	a3
	pop	a2/d2/a3/d4
	rts

;#c BROWSE OFF
browsemodeon
	bclr	#DIVB_Browse,(Divmodes,NodeBase)	; OFF
	bra.b	togglebrowesemode
	bsr	writeerroro
	rts

;#c BROWSE ON
browsemodeoff
	bset	#DIVB_Browse,(Divmodes,NodeBase)
	bra.b	togglebrowesemode
	bsr	writeerroro
	rts

;#c BROWSE 
brosemodeonoff
	lea	(browsmpromptext),a0
	lea	(BrowseMhelpfile),a1
	push	a2
	lea	(browsmpromhtext),a2
	jsr	(readlinepromptwhelp)
	pop	a2
	beq.b	9$
	jsr	(upword)
	lea	(browsmpromhtext+1),a1
	jsr	scanchoices
	lea	(invalidcmdtext),a0
	beq.b	8$
	sub.b	#1,d0
	beq.b	1$					; Active
	bset	#DIVB_Browse,(Divmodes,NodeBase)
	bra.b	2$
1$	bclr	#DIVB_Browse,(Divmodes,NodeBase)	; inverse siden vi..
2$	bra.b	togglebrowesemode
8$	bsr	writeerroro
9$	rts	; obs. Ikke alltid ut her..

togglebrowesemode
	lea	(browseinacttext),a0
	bchg	#DIVB_Browse,(Divmodes,NodeBase) ; ble browse slått av ?
	bne.b	2$				; jepp
	lea 	(browseacttext),a0
	move.w	(Userbits+CU,NodeBase),d1
	btst	#USERB_FSE,d1
	bne.b	1$
	bclr	#DIVB_Browse,(Divmodes,NodeBase) ; Slår av igjen..
	lea	(browsenalowtext),a0
	bsr	writeerroro
	bra.b	9$
2$	and.w	#~SAVEBITSF_Browse,(Savebits+CU,NodeBase)
	bra.b	3$
1$	or.w	#SAVEBITSF_Browse,(Savebits+CU,NodeBase)
3$	jsr	(writetexto)
9$	rts

;#c
; View arkiv filer.
viewarchive
	push	a2/a3/d3
0$	lea	(filenametext),a0
	bsr	readlineprompt
	beq	9$
	move.l	a0,a3
	bsr	checkfilename
	beq.b	0$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	bsr	findfileinfo
	beq.b	8$
	move.l	d0,d3
	move.l	a2,a0
	bsr	allowdownload
	beq.b	8$
	move.l	d3,d0
	move.l	a2,a0
	bsr.b	doviewarchive
	bra.b	9$
8$	lea	(filenotfountext),a0
	bsr	writeerroro
9$	pop	a2/a3/d3
	rts

; d0 = fildirnr
; a0 = fileentry
doviewarchive
	push	a2/d2/d3/a3
	link.w	a3,#-160
	move.l	a0,a2
	move.l	d0,d2				; husker dir nr'et

	tst.b	(CommsPort+Nodemem,NodeBase)	; Lokal node ?
	beq.b	6$				; Ja, da har vi lov uansett
	bsr	justchecksysopaccess		; og sysop'er har også lov
	bne.b	6$

	lea	(nalviewupprtext),a0
	cmpi.w	#2,d2				; nekte hvis det er privat eller ul
	bcs	8$

6$	lea	(executestring),a0		; Bygger opp exec string
	move.l	sp,a1
	bsr	strcopy
	subq.l	#1,a1
	lea	(viewstring),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	d2,d0
	lea	(Filename,a2),a0
	bsr	buildfilepath
	move.b	#' ',(-1,a1)
	lea	(Filename,a2),a0
	moveq.l	#0,d1				; ikke funnet noe enda
1$	move.b	(a0)+,d0
	beq.b	2$
	cmpi.b	#'.',d0
	bne.b	1$
	move.l	a0,d1				; husker punktum pos
	bra.b	1$
2$	tst.l	d1				; fant vi noe ?
	beq.b	22$				; nei, da bruker vi a0 slik den er.
	move.l	d1,a0				; setter tilbake siste funn.
22$	lea	(-1,a0),a0
20$	move.b	(a0)+,d0
	beq.b	21$
	bsr	upchar
	move.b	d0,(a1)+
	bra.b	20$
21$	move.b	#' ',(a1)+
	move.l	a1,a0
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(konverter)

	lea	(maintmptext,NodeBase),a2	; åpner outputfil
	move.l	a2,a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	bsr	strcopy
	move.l	a2,a1
3$	move.b	(a1)+,d0			; finner slutten
	bne.b	3$
	subq.l	#1,a1
	lea	(shellfnameetext),a0
	bsr	strcopy
	move.l	(dosbase),a6
	move.l	a2,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d3
	lea	(diskerrortext),a0
	beq.b	8$				; error i open


	tst.b	(Tinymode,NodeBase)		; tiny mode ?
	bne.b	7$				; ja, ingen console output
	move.l	(exebase),a6
	lea	(nyconfgrabtext),a0		; skriver pakke string til con
	moveq.l	#3,d0
	jsr	(writecontextlen)
	move.l	sp,a0
	jsr	(writecontext)
	jsr	(newconline)
	move.l	(dosbase),a6

7$	move.l	sp,d1				; kjører scriptet
	moveq.l	#0,d2
	jsrlib	Execute			; Execute ABBS:sys/View <path><filename> <extension> <nodenr>
	move.l	d0,d2
	move.l	d3,d1
	jsrlib	Close
	move.l	(exebase),a6
	tst.l	d2
	bne.b	4$
	lea	(errordoscmdtext),a0
	bsr	writetexto
4$	move.l	a2,a0
	bsr	getfilelen
	beq.b	5$

	move.l	a2,a0
	moveq.l	#0,d0
	bsr	typefile
5$	move.l	(dosbase),a6
	move.l	a2,d1
	jsrlib	DeleteFile
	bra.b	9$

8$	move.l	(exebase),a6
	bsr	writetexto
9$	move.l	(exebase),a6
	unlk	a3
	pop	a2/d2/d3/a3
	rts

;#c
infofiles
	push	a2/a3/d2/d3/d4
0$	lea	(filenametext),a0
	bsr	readlineprompt
	beq	9$
	move.l	a0,a3
	bsr	checkfilename
	beq.b	0$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	bsr	findfileinfo
	lea	(filenotfountext),a0
	beq	8$
	move.l	d0,d3				; husker fil dir'en.
	move.l	(msg,NodeBase),a0
	move.l	(m_UserNr,a0),d4		; filpos.
	move.l	a2,a0
	bsr	allowtypefileinfo
	lea	(filenotfountext),a0
	beq	8$
	move.l	a2,a0
	bsr	alloweditinfo
	beq	1$				; ikke edit
	lea	(waeditfinfotext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	beq	3$				; fikk nei eller error
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a2,a0
	bsr	getfileinfoconf
	move.l	d0,d2
	move.l	(Infomsgnr,a2),d0		; har vi info melding fra før ?
	beq.b	2$				; Nei, skriver ny
	move.l	d2,d1
	move.l	a3,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	move.w	(Userbits+CU,NodeBase),d0			; bare FSE har include.
	andi.w	#USERF_FSE,d0				; Brukrer vi FSE ???
	beq.b	2$					; Nei, ingen include
	move.l	a3,a1
	move.l	(tmpmsgmem,NodeBase),a0
	move.l	d2,d0
	jsr	(loadmsgtext)
	lea	(errloadmsgttext),a0
	bne	8$
	move.b	#2,(FSEditor,NodeBase)			; Vi skal includere.
2$	move.w	#6,d0					; fileinfo conf
	move.l	a2,a0
	jsr	(comentditsamecode)
	beq	9$					; abort'a, carrier borte osv
	move.l	(Infomsgnr,a2),d0			; husker meldings nummeret
	move.l	(Number,a3),(Infomsgnr,a2)		; oppdaterer fileinfo msgnr

	move.l	(msg,NodeBase),a1			; updater retractee.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	d4,(m_arg,a1)				; filpos.
	move.l	d3,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	move.l	d0,d4					; husker meldingsnummeret
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	lea	(errsavefilhtext),a0
	cmpi.w	#Error_OK,d1
	bne.b	8$
	move.l	d4,d0					; msgnr
	beq.b	9$					; det var ingen gammel info..
	move.l	a3,a0
	move.l	d2,d1					; confnr
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	8$
	move.l	a3,a0
	bsr	killmsgwhodidit
	or.b	d0,(MsgStatus,a3)
	move.l	a3,a0
	move.w	#6,d0					; fileinfo conf
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	8$
	bra.b	9$

3$	tst.b	(readcharstatus,NodeBase)
	bne.b	9$					; det var error
1$	bsr	outimage
	move.l	a2,a0
	bsr	dotypeinfofile
	bra.b	9$
8$	push	all
	bsr	skrivnrw
	pop	all

	bsr	writeerroro

9$	pop	a2/a3/d2/d3/d4
	rts

; a0 = fileentry
getfileinfoconf
	moveq.l	#6,d0			; fileinfo conf (default)
	move.w	Filestatus(a0),d1	; er den pu til en conf ?
	btst	#FILESTATUSB_PrivateConfUL,d1
	beq.b	9$			; nei
	move.l	PrivateULto(a0),d0	; ja, da er den ikke i fileinfo conf
9$	rts

; a0 = fileinfo
dotypeinfofile
	push	a2
	move.l	a0,a2
	moveq.l	#1,d0			; mere info (hvis vi får)
	bsr	typefileinfo
	beq.b	9$
	move.l	(Infomsgnr,a2),d0
	beq.b	9$
	move.w	(Userbits+CU,NodeBase),d1	; har det vært ANSI ?
	btst	#USERB_ClearScreen,d1	; skal vi slette skjermen ?
	beq.b	3$			; nei.
	move.w	#1,(linesleft,NodeBase)	; Fremkaller en more..
	bsr	outimage
	beq.b	9$			; noe gikk galt (kanskje no på more)
	move.l	(Infomsgnr,a2),d0
3$	move.w	Filestatus(a2),d1	; er den pu til en conf ?
	btst	#FILESTATUSB_PrivateConfUL,d1
	beq.b	2$			; nei
	move.l	PrivateULto(a2),d1	; ja, da er den ikke i fileinfo conf
	bra.b	1$
2$	move.w	#6,d1			; fileinfo conf
1$	jsr	(typemsg)
9$	pop	a2
	rts

;#c
privateupload
	IFD DEMO
	lea	(notransfertext),a0
	bra	writeerroro
	ENDC
	IFND DEMO
	push	a2
1$	move.w	#0,d0				; Sjekker om vi har UL access i News
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(uc_Access,a0),d0		; henter news access
	andi.b	#ACCF_Upload,d0
	bne.b	2$				; Ja, vi kan UL'e
	lea	(youarenottext),a0		; Nei, skriver ut fy melding
8$	bsr	writeerroro
	bra.b	9$
2$	move.w	(MinULSpace+CStr,MainBase),d0	; er det en grense ?
	beq.b	3$				; nei.
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	lea	(n_DirPaths,a0),a0
	bsr	getdiskfree
	moveq.l	#-1,d1
	lea	(diskerrortext),a0
	cmp.l	d0,d1
	beq.b	8$
	moveq.l	#0,d1
	move.w	(MinULSpace+CStr,MainBase),d1
	lea	(diskfulltext),a0
	cmp.l	d0,d1
	bhs.b	8$
3$	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a0
	move.w	#Fileentry_SIZEOF,d0
	bsr	memclr
	lea	(Fileprivulftext),a0
	moveq.l	#0,d0				; Vi vil ikke ha ALL her
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq.b	9$
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	9$				; det var ALL alikevel
	move.l	d0,(PrivateULto,a2)
	move.w	#FILESTATUSF_PrivateUL,(Filestatus,a2)
	bsr	outimage			; tar nl
	bra.b	privateupload1
9$	move.l	(sp)+,a2
	rts

privateupload1
0$	lea	(filenametext),a0			; Ber om abbs filnavn
	moveq.l	#Sizeof_FileName,d0
	bsr	mayedlineprompt
	beq	9$
	move.l	a0,-(sp)
	bsr	testfilename
	beq.b	3$
	move.l	(sp),a0
	bsr	strlen
	cmpi.w	#Sizeof_FileName,d0
	bhi.b	4$
	move.l	(sp),a0
	lea	(Filename,a2),a1
	move.w	#Sizeof_FileName,d0
	bsr	strcopymaxlen
	moveq.l	#0,d0				; Privatefiledir
	move.w	(Filestatus,a2),d1
	andi.w	#FILESTATUSF_PrivateUL,d1	; Er det en Private UL ??
	bne.b	1$				; Ja
	moveq.l	#1,d0				; Nei, da skal den havne i upload
1$	move.l	(sp)+,a0
	lea	(maintmptext,NodeBase),a1
	bsr	buildfilepath
	lea	(searchingtext),a0
	bsr	writetexto
	lea	(maintmptext,NodeBase),a0
	bsr	findfile
	beq.b	2$
	lea	(filefounondtext),a0
10$	bsr	writeerroro
	bra.b	0$
4$	lea	(only18charatext),a0
	bsr	writeerroro
	bra.b	5$
3$	lea	(nopathallowtext),a0
	bsr	writeerroro
5$	addq.l	#4,sp
	clr.b	(readlinemore,NodeBase)
	bra	0$
2$	lea	(Filename,a2),a0			; finnes filen fra før
	lea	(tmplargestore,NodeBase),a1
	moveq.l	#0,d0				; vil ikke ha nesten navn
	bsr	findfileinfo
	lea	(filefountext),a0
	bne.b	10$				; ja..
	bsr	outimage
	move.w	(Filestatus,a2),d0		; hvis der er PU, så skal vi
	btst	#FILESTATUSB_PrivateUL,d0	; ikke ha / for sysop only
	bne.b	12$
	lea	(startdescwstext),a0
	bsr	writetexto
12$	lea	(pleaseentfdtext),a0
	bsr	strlen
	lea	(spacetext),a0
	bsr	writetextlen
	moveq.l	#0,d0
	move.w	#Sizeof_FileDescription,d0
	lea	(bordertext),a0
	bsr	writetextlen
	move.b	#'>',d0
	bsr	writechar
	bsr	outimage
	lea	(pleaseentfdtext),a0
	bsr	writetext
	bsr	breakoutimage
	move.w	#Sizeof_FileDescription,d0
	jsr	(getline)
	beq	9$
	cmpi.b	#'/',(a0)			; Er det sysop only ?
	bne.b	11$				; Nei
	move.w	(Filestatus,a2),d0		; Er den privat allerede ?
	btst	#FILESTATUSB_PrivateUL,d0
	bne.b	11$				; Ja
	move.l	(SYSOPUsernr+CStr,MainBase),d0
	move.l	d0,(PrivateULto,a2)
	move.w	#FILESTATUSF_PrivateUL,(Filestatus,a2)
	move.l	a0,-(a7)
	moveq.l	#0,d0				; Privatefiledir
	lea	(Filename,a2),a0
	lea	(maintmptext,NodeBase),a1
	bsr	buildfilepath
	lea	(maintmptext,NodeBase),a0
	bsr	findfile
	move.l	(a7)+,a0
	beq.b	11$
	lea	(filefountext),a0
	bsr	writeerroro
	bra	0$

11$	lea	(Filedescription,a2),a1
	move.w	#Sizeof_FileDescription,d0
	bsr	strcopymaxlen

	move.w	(Filestatus,a2),d0
	btst	#FILESTATUSB_PrivateUL,d0
	bne.b	8$

; Private to conference ???
	move.w	(confnr,NodeBase),d0
	cmpi.w	#6,d0				; ikke i news,post,u/f info heller
	bls.b	8$
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.w	#ACCF_Upload,d0			; har vi UL access i denne konf ?
	beq.b	8$				; Nei. Da blir det offentlig fil
	lea	(fileprivtcotext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	beq.b	8$
	move.w	#FILESTATUSF_PrivateConfUL,(Filestatus,a2)
	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0
	move.l	d0,(PrivateULto,a2)
8$	tst.b	(readcharstatus,NodeBase)
	bne	9$
	lea	(uploadfname),a0
	moveq.l	#0,d0
	bsr	typefilemaybeansi

	moveq.l	#20,d0				; Status = UL file.
	bsr	changenodestatus
	bsr	outimage
	lea	(maintmptext,NodeBase),a0
	move.b	(CommsPort+Nodemem,NodeBase),d0	; internal node ??
	beq.b	16$				; Yepp. local download

	move.l	a0,(ULfilenamehack,NodeBase)
	moveq.l	#0,d0				; ikke ungrab
	jsr	(receivefile)
	beq.b	7$
	bra.b	17$

16$	lea	(Filename,a2),a0
	bsr	getfullnameusetmp
	beq	9$				; Ut
	lea	(maintmptext,NodeBase),a1
	bsr	copyfile
	beq.b	7$
	bra.b	20$				; ikke noen tid sak her nei.

17$	lea	(lastchartime,NodeBase),a1	; trekker ifra tid for UL
	lea	(tmpdatestamp,NodeBase),a0
	bsr	calcmins
	add.w	d0,(minul,NodeBase)

20$	lea	(maintmptext,NodeBase),a0
	bsr	getfilelen
	bne.b	6$
7$	lea	(maintmptext,NodeBase),a0
	bsr	deletefile
	lea	(logfulmsgtext),a0
	lea	(Filename,a2),a1
	bsr	writelogtexttimed
	lea	(errorreceivtext),a0
	bsr	writeerroro
	bra	9$
6$	move.l	d0,(Fsize,a2)
	move.l	(Usernr+CU,NodeBase),(Uploader,a2)
	lea	(ULdate,a2),a0
	move.l	a0,d1
	push	a6/d2
	move.l	(dosbase),a6
	jsrlib	DateStamp
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	lea	(Filedescription,a2),a0
	move.l	a0,d2
	jsrlib	SetComment			; prøver å sette description som file comment.
	pop	a6/d2
	lea	(tmptext,NodeBase),a1
	lea	(maintmptext,NodeBase),a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(maintmptext,NodeBase),a0	; finner extension
	moveq.l	#0,d1
14$	move.b	(a0)+,d0
	beq.b	15$
	cmpi.b	#'.',d0
	bne.b	14$
	move.l	a0,d1
	bra.b	14$				; søker videre etter siste punktum
15$	tst.l	d1				; fant vi noe ?
	beq.b	18$				; nei, da bruker vi a0 slik den er.
	move.l	d1,a0				; setter tilbake siste funn.
18$	lea	(-1,a0),a0
	move.l	a1,-(a7)
	bsr	upstring
	move.l	(a7)+,a1
	bsr	strcopy
	lea	(-1,a1),a0
	move.b	#' ',(a0)+
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(konverter)
	lea	(tmptext,NodeBase),a1	; <fullnavn> <extension> <nodenr>
	lea	(uloadscriptname),a0
	bsr	executedosscriptparam

	addq.w	#1,(Uploaded+CU,NodeBase)		; Oppdaterer Uploaded telleren
	move.l	(Fsize,a2),d0
	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	add.l	d0,(KbUploaded+CU,NodeBase)
	bsr	outimage
	bsr	checkratio

	moveq.l	#0,d0
	move.l	d0,(Infomsgnr,a2)		; tømmer denne
	lea	(enterdeinfotext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	beq.b	13$
	move.l	a2,a0
	move.l	(PrivateULto,a2),d0		; i tilfelle til conf
	move.w	(Filestatus,a2),d1
	and.w	#FILESTATUSF_PrivateConfUL,d1
	bne.b	19$
	move.w	#6,d0				; fileinfo conf
19$	jsr	(comentditsamecode)
	beq.b	13$				; abort'a, carrier borte osv
	lea	(tmpmsgheader,NodeBase),a0
	move.l	(Number,a0),(Infomsgnr,a2)
13$	move.l	(msg,NodeBase),a1
	move.w	#Main_addfile,(m_Command,a1)
	move.l	a2,(m_Data,a1)
	moveq.l	#0,d0				; 0 = private
	move.w	(Filestatus,a2),d1
	btst	#FILESTATUSB_PrivateUL,d1
	bne.b	81$
	moveq.l	#1,d0
81$	move.l	d0,(m_UserNr,a1)			; 1 = Upload
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
;	beq.b	9$
;	lea
;	bsr	writetexti
;	lea	maintmptext(NodeBase),a0
;	bsr	deletefile

	lea	(ulcompletedtext),a0
	bsr	writetexto
9$	moveq.l	#0,d1
	move.l	d1,(ULfilenamehack,NodeBase)
	moveq.l	#4,d0			; Status = active.
	bsr	changenodestatus
	ENDC
	move.l	(sp)+,a2
	rts

;#c
uploadfile
	push	a2
	bsr	uloadcommoncode
	IFND DEMO
	beq.b	9$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a0
	move.w	#Fileentry_SIZEOF,d0
	bsr	memclr
	bra	privateupload1
	ENDC
9$	pop	a2
	rts

uloadcommoncode
	IFND DEMO
	lea	(u_almostendsave+CU,NodeBase),a0 ; Sjekker om vi har UL access i News
	move.w	(uc_Access,a0),d0
	andi.w	#ACCF_Upload,d0
	bne.b	1$				; Ja, vi kan UL'e
	lea	(youarenottext),a0		; Nei, skriver ut fy melding
	bra.b	8$
1$	move.w	(MinULSpace+CStr,MainBase),d0	; er det en grense ?
	beq.b	3$				; nei.
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	lea	(n_DirPaths+FileDirRecord_SIZEOF,a0),a0
	bsr	getdiskfree			; sjekker upload stedet
	moveq.l	#-1,d1
	lea	(diskerrortext),a0
	cmp.l	d0,d1
	beq.b	8$
	moveq.l	#0,d1
	move.w	(MinULSpace+CStr,MainBase),d1
	lea	(diskfulltext),a0
	cmp.l	d0,d1
	bcc.b	8$
3$	clrz
	bra.b	9$
	ENDC
	lea	(notransfertext),a0
8$	bsr	writeerroro
	setz
9$	rts

;#c
downloadfile
	moveq.l	#-1,d0				; ikke filnr

; d0 != -1 -> d0 = fileentrynr, d1 = filedir
downloadfile1
	push	a2/a3/d2/d3/d4
	IFND DEMO
	link.w	a3,#-80
	move.l	a3,d4
	move.l	d0,d3				; husker evnt. filnr
	move.l	d1,d2				; husker evnt. fildir
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_LostDL,d0		; har han mistet DL access'en ?
;	bne.b	2$				; jepp, slipper forbi her
	move.w	#0,d0				; Sjekker om vi har DL access i News
	lea	(u_almostendsave+CU,NodeBase),a0 ; Sjekker om vi har UL access i News
	move.w	(uc_Access,a0),d0
	andi.w	#ACCF_Download,d0
	bne.b	2$				; Ja, vi kan DL'e
	lea	(youarenottext),a0		; Nei, skriver ut fy melding
	bsr	writeerroro
	bra	19$
2$	moveq.l	#-1,d0
	cmp.l	d0,d3
	beq.b	0$				; ikke ferdige nummere
	moveq.l	#0,d1
	move.w	d2,d1				; legger fildirnr i riktig register
	bra.b	7$
0$	lea	(doloadfnametext),a0
	bsr	readlineprompt
	beq	9$
	move.l	a0,a3
	bsr	checkfilename
	beq.b	0$
7$	lea	(tmpfileentry,NodeBase),a2
	move.l	d3,d0				; gir evnt. filnummer videre
	bsr	handlefiledladd
	beq	9$
	move.l	d0,d2
	move.l	(msg,NodeBase),a1
	move.l	(m_UserNr,a1),d3	; filpos.

	move.b	(CommsPort+Nodemem,NodeBase),d0	; internal node ??
	beq.b	3$				; Yepp. local download, no time
	move.l	a2,a0
	bsr	sjekkdltid
	bne.b	3$
	lea	(Insuftimeremtxt),a0
	bsr	writeerroro
	bra	9$

3$	move.w	#-1,(linesleft,NodeBase)	; Vi vil ikke ha noen more her..
	bsr	typefileinfoheader
	beq.b	16$
	move.l	a2,a0
	moveq.l	#0,d0			; ikke mere info
	bsr	typefileinfo
	beq.b	16$
	bsr	outimage
	beq.b	16$
	lea	(downloadfname),a0
	moveq.l	#0,d0
	bsr	typefilemaybeansi
;	beq	9$
16$	tst.b	(readcharstatus,NodeBase)
	bne	9$
	move.l	(Fsize,a2),d1
	moveq.l	#10,d0
	lsr.l	d0,d1
	moveq.l	#24,d0			; Status = DL file.
	bsr	changenodestatus

	move.b	(CommsPort+Nodemem,NodeBase),d0	; internal node ??
	beq.b	12$				; Yepp. local download

	lea	(maintmptext,NodeBase),a0
	move.l	a0,(ULfilenamehack,NodeBase)
	jsr	(fjernpath)

	jsr	(sendfile)
	bmi	9$
	beq	20$				; Error
	bra.b	13$

12$	lea	(Filename,a2),a0
	bsr	getfullnameusetmp
	beq	9$				; Ut
	move.l	a0,a1
	lea	(maintmptext,NodeBase),a0
	bsr	copyfile
	beq	20$

13$	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_FreeDL,d0		; Free DL ?
	bne.b	6$				; jepp, oppdaterer ikke

	addq.w	#1,(Downloaded+CU,NodeBase)	; Oppdaterer Downloaded telleren
	move.l	(Fsize,a2),d0
	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	add.l	d0,(KbDownloaded+CU,NodeBase)
	bsr	outimage
	bsr	checkratio

6$	move.w	(Filestatus,a2),d0		; private ul ?
	andi.w	#FILESTATUSF_PrivateUL,d0	; nei
	beq	4$
	move.l	(Usernr+CU,NodeBase),d0		; var det mottager som Dl'et ?
	cmp.l	(PrivateULto,a2),d0
	bne	4$				; nope
	move.l	a2,a0
	ori.w	#FILESTATUSF_Fileremoved,(Filestatus,a0)
	move.l	(msg,NodeBase),a1		; updater retractee.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	d3,(m_arg,a1)		; filpos.
	move.l	d2,(m_UserNr,a1)	; fildir
	move.l	a2,(m_Data,a1)		; fileentry
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne	9$
	lea	(maintmptext,NodeBase),a0
	bsr	deletefile

	move.l	(Infomsgnr,a2),d0		; er det en filinfo også
	beq	5$				; nei
	moveq.l	#6,d1				; fileinfo conf
	lea	(tmpmsgheader,NodeBase),a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	1$
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	bne	5$				; allerede drept
	lea	(tmpmsgheader,NodeBase),a0
	bsr	killmsgwhodidit
	lea	(tmpmsgheader,NodeBase),a0
	or.b	d0,(MsgStatus,a0)
	moveq.l	#6,d1				; fileinfo conf
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	beq.b	5$
1$	bsr	writetexto
	bra.b	5$
4$	move.l	(msg,NodeBase),a1		; updater antall dL'er.
	move.w	#Main_addfiledl,(m_Command,a1)
	move.l	d3,(m_arg,a1)		; filpos
	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)

	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne.b	9$

5$	move.l	sp,a1				; ABBS:sys/Download.abbs <fullname> <size>
	lea	(downloadscrname),a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(maintmptext,NodeBase),a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	a1,a0
	move.l	(Fsize,a2),d0
	jsr	(konverter)
	move.b	#0,(a0)

	move.l	sp,a0				; ABBS:sys/Download.abbs <fullname>
	sub.l	a1,a1					; ingen feilmelding
	jsr	(doarexxdoor)
	moveq.l	#1,d0
	bsr	waitsecs
	lea	(dlcompletedtext),a0
	bsr	writetexto
	bra.b	9$
20$	lea	(logfdlmsgtext),a0
	lea	(Filename,a2),a1
	bsr	writelogtexttimed
	lea	(errorsendtext),a0
	bsr	writeerroro
9$	moveq.l	#0,d1
	move.l	d1,(ULfilenamehack,NodeBase)
	moveq.l	#4,d0				; Status = active.
	bsr	changenodestatus
19$	move.l	d4,a3
	unlk	a3
	pop	a2/a3/d2/d3/d4
	rts
	ENDC
99$	lea	(notransfertext),a0
	bsr	writetexto
	IFND DEMO
	bra.b	9$
	ELSE
	move.l	d4,a3
	unlk	a3
	pop	a2/a3/d2/d3/d4
	rts
	ENDC

;#c
retractfile
	movem.l	a2/a3/d2,-(sp)
	lea	(retracfnametext),a0
	bsr	readlineprompt
	beq	9$
	move.l	a0,a3
	bsr	checkfilename
	beq	9$
	lea	(tmpfileentry,NodeBase),a2
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#0,d0				; vil ikke ha nesten navn
	bsr	findfileinfo
	beq	2$
	move.l	d0,d2
	move.l	a2,a0
	bsr	allowtypefileinfo
	beq	2$
	lea	(maintmptext,NodeBase),a1	; bygger path'en
	move.l	a3,a0
	move.l	d2,d0
	bsr	buildfilepath
	lea	(suredelfiletext),a0		; sikker du vil slette ?
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	beq	9$				; nei, hopper ut
	lea	(tmpfileentry,NodeBase),a0
	bsr	allowretract
	beq	4$
	lea	(tmpfileentry,NodeBase),a0
	ori.w	#FILESTATUSF_Fileremoved,(Filestatus,a0)
	move.l	(msg,NodeBase),a1		; updater retractee.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	(m_UserNr,a1),(m_arg,a1)	; filpos.
	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne.b	9$
	lea	(maintmptext,NodeBase),a0
	bsr	deletefile
	beq.b	9$
	move.l	(Infomsgnr,a2),d0
	beq.b	1$
	move.w	Filestatus(a2),d1	; er den pu til en conf ?
	btst	#FILESTATUSB_PrivateConfUL,d1
	beq.b	6$			; nei
	move.l	PrivateULto(a2),d1	; ja, da er den ikke i fileinfo conf
	bra.b	7$
6$	moveq.l	#6,d1			; fileinfo conf
7$	move.l	d1,d2
	lea	(tmpmsgheader,NodeBase),a2
	move.l	a2,a0
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne.b	5$
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	bne.b	1$				; allerede drept
	move.l	a2,a0
	bsr	killmsgwhodidit
	or.b	d0,(MsgStatus,a2)
	move.l	a2,a0
	move.w	d2,d0				; file info konfnr
	jsr	(savemsgheader)
	lea	(cntsavemsghtext),a0
	bne.b	5$
1$	lea	(fileretracetext),a0
5$	bsr	writetexto
9$	movem.l	(sp)+,a2/a3/d2
	rts
4$	lea	(youarenottext),a0
	bra.b	3$
2$	lea	(filenotfountext),a0
3$	bsr	writeerroro
	bra.b	9$

;#c
listfiles
	push	d2/d3/a2
	moveq.l	#0,d0				; file browse
	jsr	(setupbrowse)
	lea	(enterdirnametxt),a0
	lea	(filelistfilname),a1
	suba.l	a2,a2				; ingen ekstra help
	bsr	readlinepromptwhelp
	beq	9$
	lea	(tmptext2,NodeBase),a2
	move.l	a2,a1
	bsr	strcopy
	move.l	a2,a0
1$	move.b	(a0)+,d0		; er det en stjerne der ?
	beq.b	2$			; nope
	cmpi.b	#'*',d0
	bne.b	1$			; nei, fortetter
	jsr	setbrowsenodestatus
	bsr	askdetailedlist
	beq.b	9$
	move.l	d1,d3
	bsr	outimage
	beq.b	9$
	lea	(listfilestest),a0
	move.l	d3,d1
	move.l	a2,a1
	bsr	loopalldirs
	jsr	(sendbrowsefiles)
	bra.b	9$
2$	move.l	a2,a0
	bsr	getdirnamesub
	beq.b	9$
3$	move.l	(firstFileDirRecord+CStr,MainBase),a0
	mulu.w	#FileDirRecord_SIZEOF/2,d0
	lea	(n_DirName,a0,d0.l),a0
	move.l	a0,a1
6$	move.b	(a1)+,d0
	beq.b	5$				; ferdig
	cmp.b	#'/',d0
	bne.b	6$				; ikke sub dir
	move.l	a2,a1				; det var subdir, da bruker vi fullt navn isteden
	bsr	strcopy
5$	bsr	outimage
	jsr	setbrowsenodestatus
	bsr	askdetailedlist
	beq.b	9$
	lea	(listfilestest),a0
;	move.l	d1,d2
	move.l	a2,a1
;4$	move.b	(a2)+,d0			; legger på en stjerne på slutten, slik at vi tar alle
;	bne.b	4$				; fildirs som begynner med det han tastet
;	move.b	#'*',(-1,a2)
;	move.b	#0,(a2)				; trengs vel ikke alikevel...
	bsr	loopalldirs
	jsr	(sendbrowsefiles)
9$	jsr	clearbrowsenodestatus
	pop	d2/d3/a2
	rts

listfilestest
	clrz
	rts

;#c
; returnerer bool i d1 (d1 = 0, ikke detaljert info)
askdetailedlist
	push	d2
	moveq.l	#0,d2				; ikke detaljert info
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	bne.b	9$				; jepp, ikke spør om detailed info
	jsr	(justchecksysopaccess)		; er vi sysop ?
	beq.b	9$				; nei, ikke detaljert
	lea	(detailelisttext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	sne	d2
	bsr	outimage
9$	move.l	d2,d1
	pop	d2
	tst.b	(readcharstatus,NodeBase)
	notz
	rts

;#c
listprivatetoconf
	moveq.l	#0,d0				; file browse
	jsr	(setupbrowse)
	jsr	setbrowsenodestatus
	bsr	askdetailedlist
	beq.b	9$
	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0
	lea	(nulltext),a1
	lea	(listprivatetoconffunc),a0
	bsr	loopalldirs
	jsr	(sendbrowsefiles)
9$	jsr	clearbrowsenodestatus
	rts

; a0 = Fileentry
; d0 = data
; ret : z = 1, ta den med.
listprivatetoconffunc
	move.w	(Filestatus,a0),d1
	and.w	#FILESTATUSF_PrivateConfUL,d1
	beq.b	9$
	cmp.l	(PrivateULto,a0),d0
	notz
9$	rts

;#c
listprivate
	moveq.l	#0,d0				; file browse
	jsr	(setupbrowse)
	jsr	setbrowsenodestatus
	bsr	askdetailedlist
	beq.b	9$
	lea	(listfilestest),a0
	moveq.l	#0,d0			; Private dir.
	move.l	d2,-(a7)
	move.l	d1,d2
	bsr	loopdir
	jsr	(sendbrowsefiles)
	move.l	(a7)+,d2
9$	jsr	clearbrowsenodestatus
	rts

;#c
newfiles
	movem.l	d2-d4,-(a7)
	moveq.l	#0,d0				; file browse
	jsr	(setupbrowse)
	lea	(maintmptext,NodeBase),a0
	move.l	(NFday+CU,NodeBase),d0
	move.l	d0,(a0)
	jsr	datestampetodate

; a0 = datestamp
; retur:
; d0 = århundre (eg 1993)
; d1 = mnd
; d2 = mnddag
; d3 = ukedag


	move.l	d0,d4
	move.l	d1,d3
	lea	(datetoscanftext),a0
	lea	(maintmptext,NodeBase),a1
	bsr	strcopy
	subq.l	#1,a1
	move.l	a1,a0
	move.l	d4,d0		; århundre
	andi.l	#$ffff,d0
	divu.w	#100,d0
	swap	d0
	andi.l	#$ffff,d0
	bsr	nr2tostr	; legger til string i a0
	move.l	d3,d0
	bsr	nr2tostr
	move.l	d2,d0
	bsr	nr2tostr
	move.l	a0,a1
	lea	(sparakolontext),a0
	bsr	strcopy
3$	lea	(maintmptext,NodeBase),a0

	lea	(nulltext),a1
	moveq.l	#6,d0
	jsr	(mayedlineprompt)

;	bsr	readlineprompt
	bne	5$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$
	move.l	(NFday+CU,NodeBase),d0
	bra.b	2$

5$	jsr	strtonr2
	bmi.b	4$
	move.l	d0,d2		; år
	bsr	strtonr2
	bmi.b	4$
	move.l	d0,d3		; mnd
	bsr	strtonr2
	bmi.b	4$
	exg	d0,d2		; dag
	move.l	d3,d1
	jsr	(datetodays)
	bne.b	2$
4$	lea	(invaliddatetext),a0
	bsr	writeerroro
	bra.b	3$

2$	move.l	d0,d4
	bsr	outimage
	beq.b	9$
	jsr	setbrowsenodestatus
	bsr	askdetailedlist
	beq.b	9$
	move.l	d4,d0
	lea	(newfilestest),a0
	lea	(starttext),a1
	bsr	loopalldirs
	lea	(tmptext,NodeBase),a0
	move.l	(dosbase),a6
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	(tmptext,NodeBase),(NFday+CU,NodeBase)	; Husker dagen vi tok NF
	jsr	(sendbrowsefiles)
9$	jsr	clearbrowsenodestatus
	movem.l	(a7)+,d2-d4
	rts

newfilestest
	cmp.l	(ULdate,a0),d0			; dagen filen ble UL'et mot grensen
	bls.b	1$
	setz
	rts
1$	clrz
	rts

;#c
keywordsearch
	lea	(logdksearchtext),a0
	lea	(keywordtest),a1
	bra	keywordscanbody

keywordtest
	push	a2/d2/a3
	move.l	a0,a3				; fileinfo struct
	move.l	d0,a2				; ord vi skal søket etter
	lea	(Filedescription,a3),a1		; tar først beskrivelsen
	moveq.l	#Sizeof_FileDescription+1,d2	; lengden
1$	move.l	a2,a0				; ordet vi skal finne
2$	subq.l	#1,d2				; minker med 1
	bcs.b	3$				; ferdig
	move.b	(a0)+,d0			; slutt på søker ordet ?
	beq.b	8$				; vi fant!
	bsr	upchar
	move.b	(a1)+,d1
	beq.b	3$
	exg	d0,d1
	bsr	upchar
	cmp.b	d1,d0
	bne.b	1$
	bra.b	2$
3$	lea	(Filename,a3),a1			; så navnet
	moveq.l	#Sizeof_FileName+1,d2
4$	move.l	a2,a0
5$	subq.l	#1,d2
	bcs.b	9$
	move.b	(a0)+,d0
	beq.b	8$
	bsr	upchar
	move.b	(a1)+,d1
	beq.b	9$
	exg	d0,d1
	bsr	upchar
	cmp.b	d1,d0
	bne.b	4$
	bra.b	5$
8$	clrz
9$	pop	a2/d2/a3
	rts

;#c
scanfiles
	lea	(logscannedftext),a0
	lea	(scanfiletest),a1
	bra.b	keywordscanbody

scanfiletest
	movem.l	a2/d2,-(sp)
	move.l	d0,a2
	lea	(Filename,a0),a1
	moveq.l	#Sizeof_FileName+1,d2
1$	move.l	a2,a0
2$	subq.l	#1,d2
	bcs.b	9$
	move.b	(a0)+,d0
	beq.b	8$
	bsr	upchar
	move.b	(a1)+,d1
	beq.b	9$
	exg	d0,d1
	bsr	upchar
	cmp.b	d1,d0
	bne.b	1$
	bra.b	2$
8$	clrz
9$	movem.l	(sp)+,a2/d2
	rts

; a0 = log tekst
; a1 = test procedure
keywordscanbody
	push	d2/d3/a2/a3/d4/d5/d6
	link.w	a3,#-80
	move.l	a3,d4
	move.l	a0,d6				; husker log teksten
	move.l	a1,a3				; husker proceduren
	moveq.l	#0,d0				; file browse
	jsr	(setupbrowse)
	lea	(enterkeywortext),a0		; spør etter keyword'et
	bsr	readlineprompt
	beq	9$

	move.l	sp,a1				; husker
	bsr	strcopy
	lea	(enterdirnametxt),a0		; spørr etter dir
	lea	(filelistfilname),a1
	suba.l	a2,a2				; ingen ekstra help
	bsr	readlinepromptwhelp
	beq	9$
	lea	(tmptext2,NodeBase),a1		; husker dir
	bsr	strcopy
	lea	(tmptext2,NodeBase),a0
	move.l	a0,d5				; husker strengen

5$	move.b	(a0)+,d0			; er det en stjerne der ?
	beq.b	1$				; nope
	cmpi.b	#'*',d0
	bne.b	5$				; nei, fortetter
	moveq.l	#-1,d3				; alle dir'er
	bra.b	3$				; fortsetter vanelig

1$	lea	(tmptext2,NodeBase),a0
	bsr	getdirnamesub
	bne.b	2$
	lea	(dirnotfoundtext),a0		; fant ikke, error
	bsr	writeerroro
	bra.b	9$
2$	move.l	(firstFileDirRecord+CStr,MainBase),a0
	mulu.w	#FileDirRecord_SIZEOF/2,d0
	lea	(n_DirName,a0,d0.l),a0
	move.l	a0,a1
6$	move.b	(a1)+,d0
	beq.b	3$				; ferdig
	cmp.b	#'/',d0
	bne.b	6$				; ikke sub dir
	move.l	d5,a1
	bsr	strcopy				; det var subdir, da bruker vi fullt navn isteden
3$	bsr	askdetailedlist			; detaljert ?
	beq.b	9$
	move.l	d1,d2				; husker

	move.l	sp,a1				; skriver til log'en
	move.l	d6,a0
	bsr	writelogtexttimed

	jsr	setbrowsenodestatus
	move.l	a3,a0				; proceduren
	move.l	sp,d0				; keyword
	move.l	d2,d1
	move.l	d5,a1
	bsr	loopalldirs
	jsr	(sendbrowsefiles)
	jsr	clearbrowsenodestatus

9$	move.l	d4,a3
	unlk	a3
	pop	d2/d3/a2/a3/d4/d5/d6
	rts

;#e

*****************************************************************
*			Misc menu				*
*****************************************************************
miscmenunotchoices
	push	a2
	link.w	a3,#-80
	move.l	a0,a2
	bsr	testfilename
	bne.b	1$
	setn
	bra.b	9$
1$	move.b	#0,(30,a2)				; terminerer stringen hvis den er for lang.
	lea	(miscdirname),a0
	move.l	sp,a1
	jsr	(strcopy)
	subq.l	#1,a1
	move.l	a2,a0
	jsr	(strcopy)
	subq.l	#1,a1
	lea	(dotabbstext),a0
	jsr	(strcopy)
	lea	(logdidmisctext),a0
	move.l	a2,a1
	bsr	writelogtexttimed
	move.l	sp,a0
	lea	(invalidcmdtext),a1
	jsr	(doarexxdoor)
	beq.b	9$
8$	clrn
9$	unlk	a3
	pop	a2
	rts

*****************************************************************
*			  HOLD					*
*****************************************************************

addfile	push	a2/a3
0$	lea	(filenametext),a0
	bsr	readlineprompt
	beq	9$
4$	move.l	a0,a1
2$	move.b	(a1)+,d0
	beq.b	1$
	cmp.b	#'+',d0
	bne.b	2$
	move.b	#0,(-1,a1)
	addq.l	#1,a1
1$	lea	(-1,a1),a2			; husker hvor vi var
3$	move.l	a0,a3
	bsr	checkfilename
	beq.b	0$
	move.l	a3,a0
	bsr	addfilesub
	beq.b	9$
	move.l	a2,a0				; henter frem input igjen
	move.b	(a0),d0				; var det mere ?
	bne.b	4$				; jepp, loop'er
9$	pop	a2/a3
	rts

;a0 = filnavnet
addfilesub
	moveq.l	#-1,d0				; ikke filnr
;	bra.b	addfilesub1

; d0 != -1 -> d0 = fileentrynr, d1 = filedir
addfilesub1
	push	a2/a3/d2/d3/d4/d5
	move.l	d0,d3				; husker evnt. filnr
	move.l	d1,d2				; husker evnt. fildir
	lea	(tmpfileentry,NodeBase),a2
	move.l	a0,a3
	move.l	d3,d0				; gir evnt. filnummer videre
	move.w	d2,d1				; legger evnt. fildirnr i riktig register
	bsr	handlefiledladd
	beq	9$
	move.l	d0,d4				; husker fildir'en
	move.l	a0,a3				; husker full path
	move.l	(msg,NodeBase),a1
	move.l	(m_UserNr,a1),d3		; filpos.

	move.w	(Filestatus,a2),d0		; private ul ?
	andi.w	#FILESTATUSF_PrivateUL,d0	; nei
	lea	(nopriviholdtext),a0
	bne	8$

; sjekke dl ratio

	move.l	a2,a0
	moveq.l	#0,d0				; ikke mere info
	bsr	typefileinfo
	lea	(tmptext,NodeBase),a0
	lea	(Filename,a2),a1
	bsr	getholddirfilename
	move.l	a0,a1
	move.l	a1,d5				; husker dest navn
	move.l	a3,a0				; source
	jsr	makehardlink
	bne.b	3$				; det gikk bra..
	move.l	a3,a0				; source
	move.l	d5,a1				; dest navn
	bsr	copyfile
	beq.b	1$				; error copy

3$	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_FreeDL,d0		; Free DL ?
	beq.b	2$				; nope, gir ikke comment
	lea	(freedlcomment),a0
	move.l	a0,d2
	move.l	d5,d1				; filnavnet
	move.l	(dosbase),a6
	jsrlib	SetComment
	move.l	(exebase),a6

2$	move.l	(msg,NodeBase),a1		; updater antall dL'er.
	move.w	#Main_addfiledl,(m_Command,a1)
	move.l	d3,(m_arg,a1)			; filpos
	move.l	d4,(m_UserNr,a1)		; fildir?
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	bne.b	9$

	move.l	a3,a0				; skriver til log'en
	jsr	(fjernpath)
	move.l	a0,a1
	lea	(logaddfiletext),a0
	bsr	writelogtexttimed
	clrz
	bra.b	9$
1$	lea	(diskerrortext),a0
8$	bsr	writeerroro
	setz
9$	pop	a3/a2/d2/d3/d4/d5
	rts

archivehold
	push	d2-d6
	moveq.l	#0,d4
	move.b	(ScratchFormat+CU,NodeBase),d4
	lsl.w	#2,d4
	beq	9$				; ikke noen pakking
	bsr	holdgetfilestat
	lea	(diskerrortext),a0
	beq.b	3$				; error
	move.l	d2,d5			 	; virkelig antall bytes før pakking
	move.l	d1,d6				; virkelig antall filer før pakking

	moveq.l	#76,d0				; Status = packing file(s)
	jsr	(changenodestatus)
	lea	(maintmptext,NodeBase),a0	; bygger opp path
	lea	(nulltext),a1
	bsr	getholddirfilename
	lea	(tmptext2,NodeBase),a1		; bygger opp navnet på pakkeren
	lea	(packstring),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.l	(0,a0,d4.w),a0
	bsr	strcopy
	lea	(tmptext2,NodeBase),a0		; sjekker om pakker finnes
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	move.l	(dosbase),a6
	jsrlib	Lock
	move.l	d0,d1
	bne.b	1$
	move.l	(exebase),a6
	lea	(cantfinpacktext),a0		; sier ifra at vi ikke fant pakkeren
3$	bsr	writeerroro
	bra	9$				; ut
1$	jsrlib	UnLock
	move.l	(exebase),a6

; <pakkstring> "basenavn" til "basenavn.<ext>"
	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	lea	(executestring),a0		; bygger opp execute string
	bsr	strcopy
	subq.l	#1,a1
	lea	(tmptext2,NodeBase),a0		; henter navnet på scriptet
	bsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(maintmptext,NodeBase),a0	; path'en
	bsr	strcopy
	subq.l	#1,a1
	lea	(holdtext),a0			; arkiv navnet
	bsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(maintmptext,NodeBase),a0	; path'en
	bsr	strcopy
	move.b	#'*',(-1,a1)			; alle filer
	move.b	#0,(a1)				; terminerer
	lea	(pleaswaitwptext),a0
	bsr	writetexto
	tst.b	(Tinymode,NodeBase)		; tiny mode ?
	bne.b	2$				; ja, ingen console output
	lea	(nyconfgrabtext),a0		; skriver pakke string til con
	moveq.l	#3,d0
	jsr	(writecontextlen)
	move.l	(tmpmsgmem,NodeBase),a0
	jsr	(writecontext)
	jsr	(newconline)
2$	move.l	(tmpmsgmem,NodeBase),a0
	move.l	a0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.l	(dosbase),a6
	jsrlib	Execute
	move.l	(exebase),a6

	lea	(maintmptext,NodeBase),a0	; path'en
	lea	(tmptext,NodeBase),a1
	bsr	strcopy
	subq.l	#1,a1
	lea	(holdtext),a0			; arkiv navnet
	bsr	strcopy
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.l	(0,a0,d4.w),a0
	bsr	strcopy
	lea	(tmptext,NodeBase),a0
	bsr	findfile
	lea	(errorpackintext),a0
	beq.b	4$
	lea	(tmplargestore,NodeBase),a1	; bygger opp "path/~(arkiv)"
	move.b	#'~',(a1)+
	move.b	#'(',(a1)+
	lea	(holdtext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.l	(0,a0,d4.w),a0
	bsr	strcopy
	move.b	#')',-1(a1)
	move.b	#0,(a1)
	lea	(tmplargestore,NodeBase),a0
	lea	(maintmptext,NodeBase),a1
	bsr	deletepattern			; sletter alt untatt arkivet
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d2
	move.b	#' ',(a0)+
	move.b	#'*',(a0)+
	move.l	d6,d0
	bsr	konverter
	move.b	#' ',(a0)+
	move.l	d5,d0
	bsr	konverter
	lea	(tmptext,NodeBase),a0
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	SetComment
	move.l	(exebase),a6
	lea	(diskerrortext),a0
	tst.l	d0
	bne.b	9$
4$	bsr	writeerroro
9$	moveq.l	#4,d0			; Status = active.
	jsr	(changenodestatus)
	pop	d2-d6
	rts

deleteholdfile
	push	a2
0$	lea	(filenametext),a0
	bsr	readlineprompt
	beq.b	9$
	move.l	a0,a2
	bsr	testfilenameallowwild
	bne.b	1$
	lea	(nopathallowtext),a0
	bsr	writeerroro
	bra.b	0$
1$	move.l	a2,a0
	lea	(tmptext,NodeBase),a1		; out pattern
	bsr	parsepattern
	beq.b	9$
	move.l	a0,a2
	lea	(maintmptext,NodeBase),a0
	lea	(nulltext),a1
	bsr	getholddirfilename
	move.l	a2,d0
	lea	(deleteholdfunc),a1
	bsr	dodirname
9$	pop	a2
	rts

deleteholdfunc
	push	a6/a2
	move.l	a0,a2
	lea	(maintmptext,NodeBase),a0
	move.l	(ed_Name,a2),a1
	bsr	getholddirfilename
	move.l	a0,d1
	jsrlib	DeleteFile
	tst.l	d0
	beq.b	9$
	move.l	(exebase),a6
	lea	(erasingtext),a0
	bsr	writetext
	move.l	(ed_Name,a2),a0
	bsr	writetexto
9$	pop	a6/a2
	rts

holddirectory
	push	d2/d3
	moveq.l	#0,d0				; nustiller antall filer(bytes)
	move.l	d0,(tmpval,NodeBase)		; funnet
	lea	(tmptext,NodeBase),a0
	lea	(nulltext),a1
	bsr	getholddirfilename
	lea	(holddirfunc),a1
	moveq.l	#0,d0
	bsr	dodirname
	move.l	(exebase),a6
	beq.b	9$
	lea	(nofileiholdtext),a0
	move.l	(tmpval,NodeBase),d3
	beq.b	8$
	subq.l	#1,d3				; kompenserer for utskrift
	moveq.l	#33,d0
	lea	(spacetext),a0
	bsr	writetextlen
	move.l	d3,d0
	moveq.l	#8,d1
	bsr	skrivnrrfill

; dl tid.
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq.b	1$				; Yepp. no time.
	moveq.l	#0,d1
	move.l	d1,d0
	move.w	(cpsrate,NodeBase),d1
	beq.b	2$
	move.l	d3,d0
	beq.b	2$
	divu.w	d1,d0
	andi.l	#$ffff,d0
	divu.w	#60,d0
	andi.l	#$ffff,d0
2$	move.l	d0,d2
	lea	(spaceparatext),a0
	bsr	writetext
	move.l	d2,d0
	bsr	connrtotext
	bsr	writetext
	lea	(mparatext),a0
	bsr	writetext
	ENDC
1$	bsr	outimage
	bra.b	9$
8$	bsr	writeerroro
9$	pop	d2/d3
	rts

holddirfunc
	push	a6/a2
	move.l	(exebase),a6
	move.l	a0,a2
	move.l	(tmpval,NodeBase),d0
	bne.b	1$
	moveq.l	#1,d0
	move.l	d0,(tmpval,NodeBase)		; forhindrer utskrift neste gang
	lea	(filesinholdtext),a0
	bsr	writetexto
1$	lea	(spacetext),a0
	moveq.l	#3,d0
	bsr	writetextlen
	move.l	(ed_Name,a2),a0
	moveq.l	#30,d0
	bsr	writetextlfill
	move.l	(ed_Size,a2),d0
	add.l	d0,(tmpval,NodeBase)		; øker telleren over size
	moveq.l	#8,d1
	bsr	skrivnrrfill
	bsr	outimage
	pop	a6/a2
	rts

extract	push	a2/a3/d2/d3
	moveq.l	#0,d3				; null for å bytte med a2
0$	lea	(arcivenametext),a0
	suba.l	a1,a1
	suba.l	a2,a2				; ingen ekstra help
	bsr	readlinepromptwhelp
	beq	9$
	move.l	a0,a3
	bsr	checkfilename
	beq.b	0$
	lea	(tmpfileentry,NodeBase),a2
	moveq.l	#-1,d0				; har ikke filnr
	bsr	handlefiledladd
	beq	9$
	move.l	a0,a3				; husker full path
	move.l	d0,d2				; og dirnr
	bsr	justchecksysopaccess
	bne.b	2$
	lea	(nalviewupprtext),a0		; sjekker om lovlig dir
	cmp.w	#1,d2
	bls	8$
2$	lea	(executestring),a0
	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	bsr	strcopy
	subq.l	#1,a1
	lea	(checkarcstring),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	a3,a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	push	a1
	move.l	a3,a0
	jsr	(getextension)
	pop	a1
	bsr	strcopy
	move.l	(tmpmsgmem,NodeBase),a0
	bsr	executestringtypeoutput
	bmi	9$
	bne	9$				; fikk ikke 0 tilbake, noe galt fra scriptet
	bsr	typefileinfoheader
	move.l	a2,a0
	moveq.l	#0,d0
	bsr	typefileinfo
	lea	(filetoextract),a0
	suba.l	a1,a1
	exg	a2,d3				; ingen ekstra help (d3 == 0)
	bsr	readlinepromptwhelp
	exg	a2,d3
	bne.b	1$
	tst.b	(readcharstatus,NodeBase)
	bne	9$
	lea	(allwildcardtext),a0
1$	move.l	a0,a2				; husker fila
	bsr	checkifdirstring
	beq	9$
	moveq.l	#80,d0				; Status = Unpacking file(s)
	jsr	(changenodestatus)
	lea	(executestring),a0
	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	bsr	strcopy
	subq.l	#1,a1
	lea	(extractstring),a0
	bsr	strcopy
	subq.l	#1,a1
	push	a1
	move.l	a3,a0
	jsr	(getextension)
	pop	a1
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	a3,a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	a2,a0
	bsr	strcopy

	move.l	(dosbase),a6
	lea	(HoldPath+Nodemem,NodeBase),a0
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	lea	(diskerrortext),a0
	beq.b	8$
	jsrlib	CurrentDir
	move.l	d0,d2				; husker forige dir
	move.l	(exebase),a6
	move.l	(tmpmsgmem,NodeBase),a0		; execute ABBS:sys/Extract<extension> <full path> <file>
	bsr	executestringtypeoutput
	move.l	(dosbase),a6
	move.l	d2,d1
	jsrlib	CurrentDir
	move.l	d0,d1
	jsrlib	UnLock
	move.l	(exebase),a6
	bra.b	9$
8$	move.l	(exebase),a6
	bsr	writeerroro
9$	moveq.l	#4,d0				; Status = active.
	bsr	changenodestatus
	pop	a2/a3/d2/d3
	rts

; a0 = string
checkifdirstring				; brukes av extract.
1$	move.b	(a0)+,d0			; finner enden
	beq.b	3$
	cmpi.b	#',',d0
	beq.b	2$
	cmpi.b	#"`",d0
	beq.b	2$
	cmpi.b	#'%',d0
	beq.b	2$
	bra.b	1$

3$	move.b	(-2,a0),d0
	cmp.b	#':',d0
	beq.b	2$
	cmp.b	#'/',d0
	bne.b	9$
2$	lea	nopathallowtext,a0
	jsr	(writeerroro)
	setz
9$	rts

;a0 = string
executestringtypeoutput
	moveq.l	#1,d0

; a0 = string
; d0 = TRUE -> type output
doexecutestring
	push	a2/d2/d3/d4
	link.w	a3,#-160

	move.l	a0,a2
	move.l	d0,d4				; husker output status
	tst.b	(Tinymode,NodeBase)		; tiny mode ?
	bne.b	1$				; ja, ingen console output
	lea	(nyconfgrabtext),a0		; skriver pakke string til con
	moveq.l	#3,d0
	jsr	(writecontextlen)
	move.l	a2,a0
	jsr	(writecontext)
	jsr	(newconline)
1$	move.l	(dosbase),a6
	lea	(80,sp),a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(shellfnameetext),a0
	bsr	strcopy
	move.l	(dosbase),a6
	lea	(80,sp),a1
	move.l	a1,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d3
	lea	(diskerrortext),a0
	beq.b	8$				; error i open
	move.l	sp,a1
	lea	(systemtagsnow),a0
	moveq.l	#16,d0
	bsr	memcopylen
	move.l	sp,a1
	move.l	d3,(4,a1)			; lagrer output

	move.l	a2,d1
	move.l	sp,d2
	jsrlib	SystemTagList
	move.l	d0,d2				; husker return
	move.l	d3,d1
	jsrlib	Close
	tst.l	d4				; skal vi ha output ?
	beq.b	2$				; nope
	move.l	(exebase),a6
	lea	(80,sp),a0
	bsr	getfilelen
	beq.b	2$
	lea	(80,sp),a0
	moveq.l	#0,d0
	bsr	typefile
2$	move.l	(dosbase),a6
	lea	(80,sp),a0
	move.l	a0,d1
	jsrlib	DeleteFile
	move.l	(exebase),a6
	move.l	d2,d0
	clrn
	bra.b	9$
8$	bsr	writeerroro
	setn
9$	unlk	a3
	pop	a2/d2/d3/d4
	rts

; Finner ut antall Bytes som ligger i hold.
; returnerer :
; z = 1 : error
; d0 : antall bytes
; d1 : virkelig antall filer
; d2 : virkelig antall bytes
;holdgetdltime
holdgetfilestat
	moveq.l	#0,d0				; nustiller antall bytes
	move.l	d0,(tmpval,NodeBase)		; funnet
	move.l	d0,(tmpmsgheader,NodeBase)	; real files
	move.l	d0,(tmpmsgheader+4,NodeBase)	; real bytes
	lea	(tmptext,NodeBase),a0
	lea	(nulltext),a1
	bsr	getholddirfilename
	lea	(holdgetdlbytesfunc),a1
	moveq.l	#0,d0
	bsr	dodirname
	beq.b	9$
	move.l	(tmpmsgheader,NodeBase),d1
	move.l	(tmpmsgheader+4,NodeBase),d2
	move.l	(tmpval,NodeBase),d0
	clrz
9$	rts

holdgetdlbytesfunc
	move.l	(ed_Size,a0),d0
	add.l	d0,(tmpval,NodeBase)		; øker telleren over size
	move.l	(ed_Comment,a0),d1
	beq.b	2$
	move.l	d1,a0
1$	move.b	(a0)+,d1
	beq.b	2$
	cmp.b	#'*',d1
	bne.b	1$
	bsr	atoi
	add.l	d0,(tmpmsgheader,NodeBase)	; arkiv, legger til antall filer
	bsr	atoi
	add.l	d0,(tmpmsgheader+4,NodeBase)	; og size
	bra.b	9$
2$	add.l	d0,(tmpmsgheader+4,NodeBase)	; ikke et arkiv, teller size
	moveq.l	#1,d0
	add.l	d0,(tmpmsgheader,NodeBase)	; og antall filer
9$	rts

; sende alle filene i hold dir (batch send)
gethold	push	d2/d3/d4/d5
	bsr	isholdempty
	lea	(nofileiholdtext),a0
	beq	8$
	move.w	(uc_Access+u_almostendsave+CU,NodeBase),d0 ; har vi DL access ?
	and.w	#ACCF_Download,d0		; isolerer download bitet
	lea	(youarenottext),a0		; Nei, skriver ut fy melding
	beq	8$				; Ja, vi kan DL'e

; håndtere local dl

	lea	(notransfertext),a0
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq	8$				; ja, fy

	bsr	holdgetfilestat
	move.l	d1,d3				; husker antall filer
	move.l	d0,d4				; husker antall bytes (nå)
	bsr	sjekkdltidbytes
	lea	(Insuftimeremtxt),a0
	beq	8$				; Ikke nok tid

	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d2
	moveq.l	#10,d1
	lsr.l	d1,d2				; gjør om til KB

	move.l	d3,d0				; ant filer
	move.l	d2,d1				; virkelig ant kb
	bsr	testratio			; sjekke om vi har ratio til å dl'e
	lea	(noratioforttext),a0
	beq	8$

	lea	(nobatchtrantext),a0
	lea	(protocolisbatch),a1
	moveq.l	#0,d0
	move.b	(Protocol+CU,NodeBase),d0
	beq	8$
	subq.l	#1,d0
	move.b	(0,a1,d0.w),d1
	beq	8$

	move.l	d4,d1
	moveq.l	#10,d0
	lsr.l	d0,d1
	moveq.l	#52,d0				; Status = downloading hold.
	bsr	changenodestatus
	lea	(loggotholdtext),a0		; skrive til log fil
	bsr	writelogtexttime

	lea	(downloadfname),a0
	moveq.l	#0,d0
	bsr	typefilemaybeansi

	move.b	(readlinemore,NodeBase),d5	; husker readlinemore
	move.b	#0,(readlinemore,NodeBase)	; flusher input (hack) ?
	lea	(maintmptext,NodeBase),a0
	lea	(allwildcardtext),a1
	bsr	getholddirfilename
	move.b	#1,(batch,NodeBase)
	jsr	(sendfile)
	bmi.b	9$				; carrier forsvant
	beq.b	7$

	move.b	d5,(readlinemore,NodeBase)	; setter tilbake readlinemore
	moveq.l	#1,d0
	bsr	waitsecs
; oppdatere ratio
	add.w	d3,(Downloaded+CU,NodeBase)	; Oppdaterer Downloaded telleren
	add.l	d2,(KbDownloaded+CU,NodeBase)
	bsr	outimage
	bsr	checkratio

	lea	(tmptext,NodeBase),a0
	lea	(nulltext),a1
	bsr	getholddirfilename		; sletter alt i hold
	jsr	deleteall

	lea	(dlcompletedtext),a0
	bsr	writetexto
	bra.b	9$

7$	lea	(logfdlholdtext),a0
	bsr	(writelogtexttime)
	lea	(errorsendtext),a0
8$	bsr	writeerroro
9$	moveq.l	#0,d1
	move.l	d1,(ULfilenamehack,NodeBase)
	moveq.l	#4,d0				; Status = active.
	bsr	changenodestatus
	pop	d2/d3/d4/d5
	rts

renameholdfile
	push	a2/d3/d4
0$	lea	(filenametext),a0
	bsr	readlineprompt
	beq	9$
	move.l	a0,a2
	bsr	testfilename
	beq.b	0$
	move.l	a2,a1
	lea	(maintmptext,NodeBase),a0
	bsr	getholddirfilename
	bsr	findfile
	bne.b	1$
	lea	(filenotfountext),a0
3$	bsr	writeerroro
	bra	9$

1$	lea	(newnametext),a0
	bsr	readlineprompt
	beq.b	9$
	move.l	a0,a2
	bsr	testfilename
	beq.b	1$
	move.l	a2,d1
	lea	(tmptext,NodeBase),a0		; sjekker om det er patterns i navnet
	move.l	a0,d2
	moveq.l	#80,d3
	move.l	(dosbase),a6
	jsrlib	ParsePatternNoCase
	move.l	(exebase),a6
	tst.l	d0
	beq.b	2$
	lea	(novalidname),a0		; det var det. Klager
	bsr	writeerroro
	bra.b	1$
2$	lea	(tmptext,NodeBase),a0		; bygger opp filnavnet
	move.l	a2,a1
	bsr	getholddirfilename
	move.l	a0,a2				; husker dest.
	bsr	findfile
	lea	(filefountext),a0
	bne.b	3$
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	move.l	a2,d2
	move.l	(dosbase),a6
	jsrlib	Rename
	move.l	(exebase),a6
	lea	(diskerrortext),a0
	tst.l	d0
	beq	3$
	lea	(filerenamedtext),a0
	bsr	writetexto
9$	pop	a2/d2/d3
	rts

showhold
	push	d2-d4/a2
	moveq.l	#0,d4
	move.b	(ScratchFormat+CU,NodeBase),d4
	lsl.w	#2,d4
	beq	9$				; ikke noen pakking
	lea	(maintmptext,NodeBase),a2	; bygger opp path
	move.l	a2,a0
	lea	(nulltext),a1
	bsr	getholddirfilename
	lea	(executestring),a0		; Bygger opp exec string
	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	bsr	strcopy
	subq.l	#1,a1
	lea	(viewstring),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	a1,d2				; husker starten på selve filnavnet (med path)
	move.l	a2,a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(holdtext),a0			; arkiv navnet
	bsr	strcopy
	subq.l	#1,a1
	lea	(packexctstrings),a0
	move.l	(0,a0,d4.w),a0
	bsr	strcopy
	move.l	a1,d3				; husker hvor vi er
	move.l	d2,a0
	bsr	findfile
	lea	(filenotfountext),a0
	beq.b	6$
	move.l	d3,a1
	move.b	#' ',(-1,a1)
	lea	(packexctstrings),a0
	move.l	(0,a0,d4.w),a0
	bsr	strcopy

	move.l	a2,a1				; åpner outputfil
	lea	(TmpPath+Nodemem,NodeBase),a0
	bsr	strcopy
	move.l	a2,a1
3$	move.b	(a1)+,d0			; finner slutten
	bne.b	3$
	subq.l	#1,a1
	lea	(shellfnameetext),a0
	bsr	strcopy
	move.l	(dosbase),a6
	move.l	a2,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	(exebase),a6
	move.l	d0,d3
	bne.b	1$
	lea	(diskerrortext),a0
6$	bsr	writeerroro
	bra.b	9$				; error i open
1$	tst.b	(Tinymode,NodeBase)
	bne.b	2$
	lea	(nyconfgrabtext),a0
	moveq.l	#3,d0
	jsr	(writecontextlen)
	move.l	(tmpmsgmem,NodeBase),a0
	jsr	(writecontext)
	jsr	(newconline)
2$	move.l	(tmpmsgmem,NodeBase),a0
	move.l	a0,d1
	moveq.l	#0,d2
	move.l	(dosbase),a6
	jsrlib	Execute
	move.l	d0,d2
	move.l	d3,d1
	jsrlib	Close
	move.l	(exebase),a6
	tst.l	d2
	bne.b	4$
	lea	(errordoscmdtext),a0
	bsr	writetexto
4$	move.l	a2,a0
	bsr	getfilelen
	beq.b	5$
	move.l	a2,a0
	moveq.l	#0,d0
	bsr	typefile
5$	move.l	(dosbase),a6
	lea	(maintmptext,NodeBase),a0
	move.l	a0,d1
	jsrlib	DeleteFile
	move.l	(exebase),a6
9$	pop	d2-d4/a2
	rts

typeholdfile
	push	a2
0$	lea	(filenametext),a0
	bsr	readlineprompt
	beq.b	9$
	move.l	a0,a2
	bsr	testfilename
	beq.b	0$
	lea	(tmptext,NodeBase),a0
	move.l	a2,a1
	bsr	getholddirfilename
	move.l	a0,a2
	bsr	findfile
	bne.b	1$
	lea	(filenotfountext),a0
	bsr	writeerroro
	bra.b	9$
1$	move.l	a2,a0
	moveq.l	#0,d0
	bsr	typefile
	move.b	#15,d0			; reset tegnset
	bsr	writechari
9$	pop	a2
	rts

;a0 - inpattern
;a1 - outpattern (must be 80 chars long)
; returns Z if error, a0 = outpattern
parsepattern
	push	d2-d3/a2/a6
	link.w	a3,#-80
	move.l	a1,a2			; husker outpattern
	lea	sp,a1
1$	move.b	(a0)+,d0
	cmp.b	#'*',d0
	bne.b	2$
	move.b	#'#',(a1)+
	move.b	#'?',d0
2$	move.b	d0,(a1)+
	bne.b	1$
	move.l	sp,d1
	move.l	a2,d2
	moveq.l	#80,d3
	move.l	(dosbase),a6
	jsrlib	ParsePatternNoCase
	move.l	a2,a0
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	9$
	move.l	(exebase),a6
	lea	(doserrortext),a0
	bsr	writeerroro
	setz
9$	unlk	a3
	pop	d2-d3/a2/a6
	rts

; a0 = string to put it in
; a1 = filename
getholddirfilename
	push	a2/a3
	move.l	a1,a3
	move.l	a0,a2
	move.l	a0,a1
	lea	(HoldPath+Nodemem,NodeBase),a0
	bsr	strcopy
	subq.l	#1,a1
	move.b	(-1,a1),d0
	cmp.b	#':',d0
	beq.b	1$
	cmp.b	#'/',d0
	beq.b	1$
	move.b	#'/',(a1)+
1$	move.l	a3,a0
	bsr	strcopy
	move.l	a2,a0
	pop	a2/a3
	rts

; filnavn i a3
; fileentry i a2
; retur (hvis z = 0)
; a0 = full path
; d0 != -1, vi har allerede filnr og dirnr i d0,d1
; (tmpfileentry = fileentry)
handlefiledladd
	push	d2
	moveq.l	#-1,d2
	cmp.l	d2,d0
	beq.b	2$				; ikke ferdige nummere
	move.l	d1,d2				; husker fildir
	move.l	(msg,NodeBase),a1		; henter inn fileentry
	move.w	#Main_loadfileentry,(m_Command,a1)
	move.l	d1,(m_UserNr,a1)		; fildir*1
	move.l	d0,(m_arg,a1)			; filnr
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	lea	(errloadfilhtext),a0
	cmpi.w	#Error_OK,d0			; error ?
	bne.b	11$				; jepp, abort
	move.w	d2,d0
	bra.b	3$				; forsetter som normalt
2$	lea	(searchingtext),a0
	bsr	writetexto
	move.l	a2,a1
	move.l	a3,a0
	moveq.l	#1,d0				; vil ha nesten navn
	bsr	findfileinfo
	beq.b	10$
	move.l	d0,d2				; husker fildir
3$	lea	(Filename,a2),a3		; bruker filnavnet vi fikk
	lea	(maintmptext,NodeBase),a1
	move.l	a3,a0
	bsr	buildfilepath
	lea	(maintmptext,NodeBase),a0
	bsr	findfile
	beq.b	1$
	move.l	a2,a0
	bsr	allowdownload
	beq.b	10$
	lea	(maintmptext,NodeBase),a0
	move.l	d2,d0
	clrz
	bra.b	9$
1$	lea	(filenotavaltext),a0
	bra.b	11$
10$	lea	(filenotfountext),a0
11$	bsr	writeerroro
	setz
9$	pop	d2
	rts

; retur : Z = ja.
isholdempty
	lea	(tmptext,NodeBase),a0
	lea	(allwildcardtext),a1
	bsr	getholddirfilename
	move.l	a0,a1
	lea	(maintmptext,NodeBase),a0
	bsr	findfirst
	bne.b	1$
	bsr	findcleanup
	setz
	bra.b	9$
1$	bsr	findcleanup
	clrz
9$	rts

; a0 - buffer
; a1 - pattern
; retur : Z if error
findfirst
	push	a2/a3/d2/d3/d4/a6
	move.l	a1,a2
	move.l	a0,d4
	move.l	(tmpmsgmem,NodeBase),d0
	addq.l	#3,d0
	and.l	#$fffffffc,d0
	move.l	d0,a3				; findfile struct
	move.l	a2,a0
	move.b	#'/',d0
	bsr	strrchr
	bne.b	1$
	move.l	a2,a0
	move.b	#':',d0
	bsr	strrchr
	bne.b	1$
	move.l	a2,a0
	lea	(nulltext),a2
	move.b	#0,(ff_path,a3)
	bra.b	2$
1$	addq.l	#1,d0
	move.l	d0,d3				; husker hvor
	sub.l	a2,d0
	move.l	a2,a0
	lea	(ff_path,a3),a1
	bsr	strcopylen
	move.b	#0,(a1)
	move.l	d3,a0
	move.b	#0,(-1,a0)
2$	lea	(ff_pattern,a3),a1
	move.l	a1,d2
	move.l	#160,d3
	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	ParsePatternNoCase
	moveq.l	#-1,d1
	cmp.l	d0,d1				; error
	beq.b	9$
	lea	(ff_path,a3),a1
	move.l	a1,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,(ff_lock,a3)
	beq.b	9$				; error
	lea	(ff_infoblockmem,a3),a0
	move.l	a0,d2
	move.l	d0,d1
	jsrlib	Examine
	tst.l	d0
	bne.b	3$
	move.l	(ff_lock,a3),d1
	jsrlib	UnLock
	moveq.l	#0,d0
	move.l	d0,(ff_lock,a3)
	bra.b	9$
3$	move.l	d4,a0
	bsr	findnext
9$	pop	a2/a3/d2/d3/d4/a6
	rts

; a0 - buffer
; returns Z for failure
findnext
	push	a2/a3/d2/d3/d4/a6
	move.l	a0,a2
	move.l	(dosbase),a6
	move.l	(tmpmsgmem,NodeBase),d0
	addq.l	#3,d0
	and.l	#$fffffffc,d0
	move.l	d0,a3				; findfile struct
	move.l	(ff_lock,a3),d3
	beq.b	9$				; ingen lock - error
	lea	(ff_infoblockmem,a3),a0
	move.l	a0,d4
1$	move.l	d3,d1
	move.l	d4,d2
	jsrlib	ExNext
	tst.l	d0
	beq.b	8$
	move.l	d4,a0
	move.l	(fib_DirEntryType,a0),d0
	bpl.b	1$				; directory
	lea	(fib_FileName,a0),a0
	move.l	a0,d2
	lea	(ff_pattern,a3),a1
	move.l	a1,d1
	jsrlib	MatchPatternNoCase
	tst.l	d0
	beq.b	1$				; ingen match
	move.l	d2,a0				; fikk filnavnet
	move.l	a2,a1
	bsr	strcopy
	lea	(ff_full,a3),a1
	lea	(ff_path,a3),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	d2,a0
	bsr	strcopy
	clrz
	bra.b	9$
8$	move.l	d3,d1
	jsrlib	UnLock
	moveq.l	#0,d0
	move.l	d0,(ff_lock,a3)
9$	pop	a3/d2/d3/d4/a6/a2
	rts

findcleanup
	move.l	(tmpmsgmem,NodeBase),d0
	addq.l	#3,d0
	and.l	#$fffffffc,d0
	move.l	d0,a0				; findfile struct
	move.l	(ff_lock,a0),d1
	beq.b	9$
	move.l	a6,-(a7)
	move.l	(dosbase),a6
	jsrlib	UnLock
	move.l	(a7)+,a6
9$	rts

; a0 = dirname
; a1 = function to call (called with dosbase in a6, ExallData in a0)
; d0 = matchstring, 0 if none
; returns Z if error
dodirname
	push	a2/d2/d3
	move.l	a1,a2
	move.l	d0,d3
	move.l	(dosbase),a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d2
	beq.b	1$
	move.l	a2,a0
	move.l	d3,d1
	bsr	dodir
	beq.b	2$
	move.l	d2,d1
	jsrlib	UnLock
	move.l	(exebase),a6
	clrz
	bra.b	9$
2$	move.l	d2,d1
	jsrlib	UnLock
1$	move.l	(exebase),a6
	lea	(diskerrortext),a0
	bsr	writeerroro
	setz
9$	pop	a2/d2/d3
	rts

; d0 = lock on dir
; a0 = function to call (called with dosbase in a6, ExallData in a0)
; d1 = matchstring, 0 if none
; returns Z if error
dodir	push	d2-d7/a2/a3/a6
	move.l	a0,a3
	move.l	d0,d6
	move.l	d1,d3				; husker matchstring
	move.l	(dosbase),a6
	move.l	(exallctrl,NodeBase),a2		; ExAllControl
	moveq.l	#0,d0
	move.l	d0,(eac_LastKey,a2)		; sletter eventuell key
	move.l	d0,(eac_MatchFunc,a2)
	move.l	d3,(eac_MatchString,a2)

1$	move.l	d6,d1
	move.l	(tmpmsgmem,NodeBase),d2
	move.l	(msgmemsize,NodeBase),d3
	moveq.l	#ED_COMMENT,d4
	move.l	a2,d5
	jsrlib	ExAll
	move.l	d0,d7
	bne.b	2$
	jsrlib	IoErr
	cmp.l	#ERROR_NO_MORE_ENTRIES,d0
	bne.b	3$
2$	move.l	(eac_Entries,a2),d0		; antall filer
	beq.b	3$				; ingen
	move.l	a2,d4				; husker ptr
	move.l	(tmpmsgmem,NodeBase),a2		; henter første ExAllData
4$	move.l	a2,a0
	jsr	(a3)				; kaller funksjonen
	move.l	(ed_Next,a2),d0
	move.l	d0,a2
	bne.b	4$
	move.l	d4,a2				; henter tilbake ptr
3$	tst.l	d7				; skulle vi kalle mere ?
	bne.b	1$				; ja
	clrz
9$	pop	d2-d7/a2/a3/a6
	rts

*****************************************************************
*			Mark meny				*
*****************************************************************

;#b
;#c
marklogin
	lea	(u_almostendsave+CU,NodeBase),a1
	move.l	(Loginlastread,NodeBase),a0
	moveq.l	#0,d0
	move.w	(Maxconferences+CStr,MainBase),d0
	subq.l	#1,d0
	bcs.b	2$				; egentlig umulig..
1$	move.l	(a0)+,(uc_LastRead,a1)		; reset'er til loginstate
	lea	(Userconf_seizeof,a1),a1
	dbf	d0,1$
	lea	(mloginstatetext),a0
	bsr	writetexto
2$	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0
	move.w	#-1,(confnr,NodeBase)
	jsr	(joinnr)
	jmp	(readmenu)			; Hopper til read meny.

;#c
unmarksubject
	push	a2/a3/d2
	jsr	(getcurmsgnr)
	beq.b	9$
	move.w	(confnr,NodeBase),d1
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	3$
	lea	(errloadmsghtext),a0
	bsr	writeerroro
	bra.b	9$
3$	move.l	a3,a0
	jsr	(isnetmessage)
	beq.b	9$				; ut
	lea	(Subject,a3),a0
	lea	(maintmptext,NodeBase),a1
	bsr	strcopy				; husker subjectet
	lea	(unmarkingtext),a0
	bsr	writetexti
	move.l	(Number,a3),d2
	bsr	10$

	lea	(maintmptext,NodeBase),a3
	move.l	a3,a0
	bsr	upstring
	move.l	a3,a0
	jsr	(removesubjectstart)
	move.l	a0,a3
	lea	(msgqueue,NodeBase),a2
1$	move.l	(a2)+,d0
	beq.b	9$				; ferdig
	move.l	a3,a0
	jsr	(samesubject)
	bmi.b	9$				; error
	bne.b	1$				; Fant teksten i denne
	lea	(-4,a2),a2
	move.l	(a2),d2
	bsr	10$
	bra.b	1$

9$	bsr	outimage
	pop	a2/a3/d2
	jmp	(readmenu)			; Hopper til read meny.

10$	move.b	#' ',d0
	bsr	writechar
	move.l	d2,d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	d2,d0
	bra	removefromqueue

;#c
markset	push	d2
	lea	(msgtosetasltext),a0
	bsr	readlineprompt
	beq.b	9$
	bsr	atoi
	lea	(invalidnrtext),a0
	bmi.b	8$
	move.l	d0,d2				; husker nr'et
	moveq.l	#0,d0
	move.l	d0,(msgqueue,NodeBase)		; Tømmer køen.

	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	(confnr,NodeBase),d1
	mulu	#ConferenceRecord_SIZEOF/2,d1
	move.l	(n_ConfDefaultMsg,a0,d1.l),d0
	cmp.l	d2,d0				; finnes meldingen ?
	bcc.b	1$				; ikke for høy
	move.l	d0,d2				; var for høy, setter maks
1$	move.w	(confnr,NodeBase),d1
	mulu	#Userconf_seizeof/2,d1
	lea	(u_almostendsave+CU,NodeBase),a0
	move.l	d2,(uc_LastRead,a0,d1.l)
	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0
	move.w	#-1,(confnr,NodeBase)
	jsr	(joinnr)
	bra.b	9$
8$	bsr	writeerroro
9$	pop	d2
	jmp	(readmenu)			; Hopper til read meny.

;#c
markreset
	moveq.l	#0,d0
	move.l	d0,(msgqueue,NodeBase)
	bsr	unjoin
	lea	(allmbresettext),a0
	bsr	writetexto
	jmp	(readmenu)			; Hopper til read meny.

;#c
markcurrmsg
	jsr	(getcurmsgnr)
	beq.b	9$
	bsr	allowmark
	beq.b	2$
	lea	(cantmarkmsgtext),a0
	bsr	writeerroro
	bra.b	9$
2$	lea	(markingtext),a0
	bsr	writetexti
	move.b	#' ',d0
	bsr	writechar
	move.l	NodeBase,a1
	IFND DEMO
	lea	sdfsdf,a0
	ENDC
	move.l	(currentmsg,NodeBase),d0
3$	bsr	skrivnr
	bsr	outimage
	lea	(tmpmsgheader,NodeBase),a0	; allowmark har hentet inn meldingen
	bsr	insertinqueue
9$	jmp	(readmenu)			; Hopper til read meny.

;#c
minefirst
	push	d2-d3/a2/a3
	lea	(msgsfoundtext),a0
	bsr	writetexti
	lea	(msgqueue,NodeBase),a2
	move.l	a2,a3
1$	move.l	(a2)+,d0
	beq.b	9$
	move.w	(confnr,NodeBase),d1
	lea	(tmpmsgheader,NodeBase),a0
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	bra.b	9$
2$	move.l	(MsgTo+tmpmsgheader,NodeBase),d0
	cmp.l	(Usernr+CU,NodeBase),d0
	bne.b	1$					; den er ikke til oss
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number+tmpmsgheader,NodeBase),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	a2,d0
	sub.l	a3,d0
	subq.l	#4,d0
	bls.b	3$
	move.l	a2,a0
4$	move.l	(-8,a0),-(a0)
	subq.l	#4,d0
	bhi.b	4$
3$	move.l	(Number+tmpmsgheader,NodeBase),(a3)+
	bra.b	1$
9$	bsr	outimage
	pop	d2-d3/a2/a3
	jmp	(readmenu)			; Hopper til read meny.

;#c
markednow
	bsr	findnumberinque
	bsr	skrivnr
	lea	(msgmarkedtext),a0
	bsr	writetexto
	jmp	(readmenu)			; Hopper til read meny.

;#c
unmarkthread
	jsr	(getcurmsgnr)
	beq.b	9$
	push	d0
	lea	(unmarkingtext),a0
	bsr	writetexti
	pop	d1
	lea	(unmarkthreadfunc),a0
	move.w	(confnr,NodeBase),d0
	bsr	dothread
	bsr	outimage
9$	jmp	(readmenu)			; Hopper til read meny.

unmarkthreadfunc
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	(Number,a3),d0
	bsr	removefromqueue
	clrn
	rts

;#c
markthread
	jsr	(getcurmsgnr)
	beq.b	9$
	push	d0
	lea	(markingtext),a0
	bsr	writetexti
	pop	d1
	lea	(markthreadfunc),a0
	move.w	(confnr,NodeBase),d0
	bsr	dothread
	bsr	outimage
9$	jmp	(readmenu)			; Hopper til read meny.

markthreadfunc
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	9$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	a3,a0
	bra	insertinqueue
9$	clrn
	rts

;#c
unmarkauthor
	push	a2/a3/d2
	jsr	(getcurmsgnr)
	beq	9$
	lea	(tmpmsgheader,NodeBase),a3
	move.w	(confnr,NodeBase),d1
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writeerroro
	bra.b	9$

2$	move.l	a3,a0
	jsr	(isnetmessage)
	beq.b	9$				; ut
	move.l	(MsgFrom,a3),d2
	lea	(msgqueue,NodeBase),a2
	lea	(unmarkingtext),a0
	bsr	writetexti
3$	move.l	(a2)+,d0
	beq.b	5$
	move.w	(confnr,NodeBase),d1
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	4$
	lea	(errloadmsghtext),a0
	bsr	writeerroro
	bra.b	9$
4$	move.l	(MsgFrom,a3),d0
	cmp.l	(MsgFrom,a3),d2
	bne.b	3$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	(Number,a3),d0
	bsr	removefromqueue
	subq.l	#4,a2			; Siden alle nå er flyttet en plass til venstre
	bra.b	3$
5$	bsr	outimage
9$	pop	a2/a3/d2
	jmp	(readmenu)			; Hopper til read meny.

;#c
unmarkallbutmine
	push	a2/a3
	lea	(tmpmsgheader,NodeBase),a3
	lea	(msgqueue,NodeBase),a2
	lea	(unmarkingtext),a0
	bsr	writetexti
3$	move.l	(a2)+,d0
	beq.b	5$
	move.w	(confnr,NodeBase),d1
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	4$
	lea	(errloadmsghtext),a0
	bsr	writeerroro
	bra.b	9$
4$	move.l	(Usernr+CU,NodeBase),d0
	cmp.l	(MsgFrom,a3),d0
	beq.b	3$
	cmp.l	(MsgTo,a3),d0
	beq.b	3$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	(Number,a3),d0
	bsr	removefromqueue
	subq.l	#4,a2			; Siden alle nå er flyttet en plass til venstre
	bra.b	3$
5$	bsr	outimage
9$	pop	a2/a3
	jmp	(readmenu)			; Hopper til read meny.

;#c
markfromperson
	push	d2-d4
	lea	(enteruserntext),a0
	moveq.l	#0,d0				; vi godtar ikke all
	moveq.l	#0,d1				; ikke nettnavn
	jsr	(getnamenrmatch)
	beq	9$
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	9$
	move.l	d0,d4
	move.w	(confnr,NodeBase),d0
	bsr	getfrommsgnr
	beq.b	9$
	move.l	d0,d3
	move.l	d0,d1
	move.w	(confnr,NodeBase),d0
	bsr	gettomsgnr
	beq.b	9$
	move.l	d0,d2
	lea	(markingtext),a0
	bsr	writetexti
	move.l	d3,d1
	move.w	(confnr,NodeBase),d0
	lea	(markfrompersonfunc),a0
	move.l	d4,(tmpstore,NodeBase)
	bsr	dogroup
	bsr	outimage
9$	pop	d2-d4
	jmp	(readmenu)			; Hopper til read meny.

;#c
markfrompersonfunc
	move.l	(tmpstore,NodeBase),d0
	cmp.l	(MsgFrom,a3),d0
	bne.b	9$
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	9$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	a3,a0
	bsr	insertinqueue
9$	clrn
	rts

;#c
markmsgstome
	push	d2-d4
	move.l	(Usernr+CU,NodeBase),d4
	move.w	(confnr,NodeBase),d0
	bsr	getfrommsgnr
	beq.b	9$
	move.l	d0,d3
	move.l	d0,d1
	move.w	(confnr,NodeBase),d0
	bsr	gettomsgnr
	beq.b	9$
	move.l	d0,d2
	lea	(markingtext),a0
	bsr	writetexti
	move.l	d3,d1
	move.w	(confnr,NodeBase),d0
	lea	(markmsgstomefunc),a0
	move.l	d4,(tmpstore,NodeBase)
	bsr	dogroup
	bsr	outimage
9$	pop	d2-d4
	jmp	(readmenu)			; Hopper til read meny.

markmsgstomefunc
	move.l	(tmpstore,NodeBase),d0
	cmp.l	(MsgTo,a3),d0
	bne.b	9$
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	9$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	a3,a0
	bsr	insertinqueue
9$	clrn
	rts

;#c
markgroup
	push	d2-d3
	move.w	(confnr,NodeBase),d0
	bsr	getfrommsgnr
	beq.b	9$
	move.l	d0,d3
	move.l	d0,d1
	move.w	(confnr,NodeBase),d0
	bsr	gettomsgnr
	beq.b	9$
	move.l	d0,d2
	lea	(markingtext),a0
	bsr	writetexti
	move.l	d3,d1
	move.w	(confnr,NodeBase),d0
	lea	(markgroupfunc),a0
	bsr	dogroup
	bsr	outimage
9$	pop	d2-d3
	jmp	(readmenu)			; Hopper til read meny.

markgroupfunc
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	9$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	a3,a0
	bsr	insertinqueue
9$	clrn
	rts

;#c	MARK DATE (M D)
markmsgafterdate
	push	d2-d3
1$	lea	(markmsgfromtext),a0
	bsr	readlineprompt
	beq.b	9$
	bsr	strtonr2
	bmi.b	2$
	move.l	d0,d2		; år
	bsr	strtonr2
	bmi.b	2$
	move.l	d0,d3		; mnd
	bsr	strtonr2
	bmi.b	2$
	exg	d0,d2		; dag
	move.l	d3,d1
	jsr	(datetodays)
	bne.b	3$
2$	lea	(invaliddatetext),a0
	bsr	writeerroro
	bra.b	1$
3$	move.l	d0,d3
	lea	(markingtext),a0
	bsr	writetexti
	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	(confnr,NodeBase),d1
	mulu	#ConferenceRecord_SIZEOF/2,d1
	move.l	(n_ConfDefaultMsg,a0,d1.l),d2
	move.w	(confnr,NodeBase),d0
	moveq.l	#1,d1		;n_ConfFirstMsg	; Foreløpig så starter vi alltid på 1
	lea	(markmsgafterdatefunc),a0
	move.l	d3,(tmpstore,NodeBase)
	bsr	dogroup
	bsr	outimage
9$	pop	d2-d3
	jmp	(readmenu)			; Hopper til read meny.

markmsgafterdatefunc
	move.l	(tmpstore,NodeBase),d0
	cmp.l	(MsgTimeStamp+ds_Days,a3),d0
	bhi.b	9$				; meldingen er eldre
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	9$
	move.b	#' ',d0
	bsr	writechar
	move.l	(Number,a3),d0
	bsr	skrivnr
	bsr	breakoutimage
	move.l	a3,a0
	bsr	insertinqueue
9$	clrn
	rts

;#c
;d0 = confnr
; Asks from msg nr (the lowest number in queue, or 1 if none is default)
getfrommsgnr
	push	d2/d3/d4
	moveq.l	#0,d2
	move.w	d0,d2

	bsr	findlowestinqueue	; finner start meldingen
	bne.b	3$
	moveq.l	#1,d0
3$	move.l	d0,d4
	lea	(tmptext,NodeBase),a1
	lea	(frommsgtext),a0
	bsr	strcopy
	subq.l	#1,a1

	move.l	d4,d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	move.b	#'-',(a1)+
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d2
	move.l	(n_ConfDefaultMsg,a0,d2.l),d3
	move.l	d3,d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	lea	(ftmsgconttext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	d4,d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	move.b	#'>',(a1)+
	move.b	#':',(a1)+
	move.b	#' ',(a1)+
	move.b	#0,(a1)
2$	lea	(tmptext,NodeBase),a0
	bsr	readlineprompt
	bne.b	1$
	move.l	d4,d0
	tst.b	(readcharstatus,NodeBase)
	notz
	bra.b	9$
1$	bsr	atoi
	bmi.b	2$
	beq.b	2$
	cmp.l	d0,d3
	bcs.b	2$			; For høyt siffer (Z = 0, hvis vi passerer)
9$	pop	d2/d3/d4
	rts

;#c
;d0 = confnr
;d1 = min msg nr
; Asks to msg nr (max msg num is default). Number must be higher than min msgnr
gettomsgnr
	push	d2/d3/d4
	move.w	d0,d2
	move.l	d1,d4
	lea	(tmptext,NodeBase),a1
	lea	(tomsgtext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	d4,d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	move.b	#'-',(a1)+
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d2
	move.l	(n_ConfDefaultMsg,a0,d2.l),d3
	move.l	d3,d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	lea	(ftmsgconttext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	d3,d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	move.b	#'>',(a1)+
	move.b	#':',(a1)+
	move.b	#' ',(a1)+
	move.b	#0,(a1)
2$	lea	(tmptext,NodeBase),a0
	bsr	readlineprompt
	bne.b	1$
	move.l	d3,d0
	tst.b	(readcharstatus,NodeBase)
	notz
	bra.b	9$
1$	bsr	atoi
	bmi.b	2$
	beq.b	2$
	cmp.l	d0,d4
	bhi.b	2$			; For lavt siffer
	cmp.l	d0,d3
	bcs.b	2$			; For høyt siffer
	clrz
9$	pop	d2/d3/d4
	rts

;#c
; check if user is allowed to mark this message
; z = 1 -> ja
; n = 1 -> Error
allowmark
	move.w	(confnr,NodeBase),d1
	lea	(tmpmsgheader,NodeBase),a0
	jsr	(loadmsgheader)
	bne.b	1$
	lea	(tmpmsgheader,NodeBase),a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	clrn
	bra.b	9$
1$	lea	(errloadmsghtext),a0
	bsr	writeerroro
	setn
	setz
9$	rts

;#c
; Loop trough a thread and perform a function on all messages
; d0 = confnr
; d1 = meldings nr for første melding.
; a0 = funksjon å utføre
; rutinen får msgheader'en i a3
dothread
	push	a2-a3/d2-d4
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a0,a2				; funksjon
	move.l	d0,d2				; confnr
	moveq.l	#0,d3				; slutt flagg
	move.l	d1,d4
	bsr	10$
	pop	a2-a3/d2-d4
	rts

10$	move.w	d2,d1
	move.l	d4,d0
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	11$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	moveq.l	#1,d3
	bra.b	19$
11$	jsr	(a2)
	bpl.b	13$
	moveq.l	#1,d3			; avslutt
13$	tst.l	d3
	bne.b	19$
	move.l	(RefNxt,a3),-(a7)
	move.l	(RefBy,a3),d4
	beq.b	12$
	bsr.b	10$
12$	move.l	(a7)+,d4
	beq.b	19$
	tst.l	d3
	bne.b	19$
	bsr.b	10$
19$	rts

;#c
; Loop trough a group of messages and perform a function on all messages
; d0 = confnr
; d1 = meldings nr for første melding.
; d2 = meldings nr for siste melding.
; a0 = funksjon å utføre
; rutinen får msgheader'en i a3
dogroup
	push	a2-a3/d3-d4
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a0,a2				; funksjon
	move.l	d0,d3				; confnr
	move.l	d1,d4
1$	move.w	d3,d1
	move.l	d4,d0
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	bra.b	9$
2$	jsr	(a2)
	bmi.b	9$				; avbryt
	addq.l	#1,d4
	cmp.l	d4,d2
	bcc.b	1$
9$	pop	a2-a3/d3-d4
	rts

;#c
; Loop trough a group of messages in threads and perform a function on all messages
; d0 = confnr
; d1 = meldings nr for første melding.
; d2 = meldings nr for siste melding.
; a0 = funksjon å utføre
; rutinen får msgheader'en i a3
dogroupthreadwise
	push	a2-a3/d3-d4
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a0,a2				; funksjon
	move.l	d0,d3				; confnr
	move.l	d1,d4
1$	move.w	d3,d1
	move.l	d4,d0
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	bra.b	9$
2$	jsr	(a2)
	bmi.b	9$				; avbryt
	addq.l	#1,d4
	cmp.l	d4,d2
	bcc.b	1$
9$	pop	a2-a3/d3-d4
	rts

;#c
sntext		dc.b	'SNR',0
	cnop	0,4

;#e

*****************************************************************
*			sub rutiner				*
*****************************************************************

; d0 = access
getaccstring
	lea	(tmptext,NodeBase),a0
; a0 = outstring
; d0 - bits
confbitstotext
	push	a0
	lea	(confacsbitstext),a1
	moveq	#0,d1
6$	btst	d1,d0
	beq.b	5$
	move.b	(0,a1,d1.w),(a0)+
5$	addq.w	#1,d1
	cmpi.w	#6,d1
	bls.b	6$
	move.b	#0,(a0)
	pop	a0
	rts

;a0 - 1. datestamp
;a1 - 2. datestamp
calcmins
	move.l	(ds_Days,a1),d0
	sub.l	(ds_Days,a0),d0
	bcc.b	3$
	moveq.l	#0,d0				; oops, returnerer 0. feil..
	bra.b	9$
3$	move.l	(ds_Minute,a1),d1
	sub.l	(ds_Minute,a0),d1
	mulu.w	#24*60,d0
	add.l	d0,d1
	bpl.b	1$
	moveq.l	#0,d0				; oops, returnerer 0. feil..
	bra.b	9$
1$	move.l	d1,d0
	move.l	(ds_Tick,a1),d1
	sub.l	(ds_Tick,a0),d1
	bcc.b	2$				; ikke wrap
	addi.l	#TICKS_PER_SECOND*60,d1
2$	divu.w	#TICKS_PER_SECOND,d1
	andi.l	#$ffff,d1
	cmpi.w	#30,d1				; er skal vi runde oppover ?
	bcs.b	9$				; nei
	addq.l	#1,d0
9$	rts

;a0 - 1. datestamp
;a1 - 2. datestamp
calcminsnoround
	move.l	(ds_Days,a1),d0
	sub.l	(ds_Days,a0),d0
	bcc.b	3$
	moveq.l	#0,d0				; oops, returnerer 0. feil..
	bra.b	9$
3$	move.l	(ds_Minute,a1),d1
	sub.l	(ds_Minute,a0),d1
	mulu.w	#24*60,d0
	add.l	d1,d0
	bpl.b	9$
	moveq.l	#0,d0				; oops, returnerer 0. feil..
9$	rts

joinnextunreadconf
;	bsr	unjoin
	moveq.l	#0,d0
	move.w	(confnr,NodeBase),d0		; Starter fra der vi er
	bsr	getnextunreadconf
	beq.b	9$
;	move.w	#-1,(confnr,NodeBase)		; sier vi er unjoin'a
	jsr	(joinnr)			; joiner conf nr d0
	clrz
9$	rts

; d0 = start ifra conf
getnextunreadconf
	push	d2/d3/d4/d5/a2/d6/a3
	move.w	d0,d2
	lea	(tmpmsgheader,NodeBase),a2
	move.w	d2,d3				; husker hvor vi startet
1$	move.w	d2,d0
	bsr	getnextconfnr
	move.w	d0,d2
	move.w	d2,d1				; sjekker om det er uleste
	mulu	#ConferenceRecord_SIZEOF/2,d1	; meldinger her
	lea	(n_FirstConference+CStr,MainBase),a0
	move.l	(n_ConfDefaultMsg,a0,d1.l),d6	; max msg
	move.l	d6,d4
	move.l	d6,d5

	move.w	d2,d1
	mulu	#Userconf_seizeof/2,d1
	lea	(u_almostendsave+CU,NodeBase),a3
	add.l	d1,a3
	sub.l	(uc_LastRead,a3),d5
	bls.b	2$				; nope
; d4 = første melding.
; d5 = antall meldinger
	sub.l	d5,d4				; søker igjennom til vi finner
	addq.l	#1,d4				; en vi kan skrive ut, hvis ikke
4$	move.w	d2,d1				; er det ingen nye meldinger
	move.l	d4,d0
	move.l	a2,a0
	jsr	(loadmsgheader)
	beq.b	3$
	lea	(errloadmsghtext),a0
	bsr	writeerroro
	setz
	bra.b	9$
3$	move.l	a2,a0
	move.w	d2,d0
	bsr	kanskrive		; Kan vi skrive ut denne ???
	beq.b	5$			; ja, da er det nye i denne konf'en
	addq.l	#1,d4
	subq.l	#1,d5
	bne.b	4$
	move.w	d2,d1			; Det var ingen, så vi oppdaterer last read
	add.w	d1,d1			; så vi ikke gjør dette flere ganger
	move.l	d6,(uc_LastRead,a3)
2$	cmp.w	d2,d3			; har vi gått rundt
	bne.b	1$			; nei
	bra.b	9$
5$	move.l	d2,d0			; vi fant en ny en.
	clrz
9$	pop	d2/d4/a2/d5/d3/d6/a3
	rts

; a0 = filnavn som skal være default, 0 for ingen
getfullnameusetmp
	move.l	a0,a1
	lea	(tmptext,NodeBase),a0
;	bra.b	getfullname

; a0 = string å legge det i (hvis vi trenger det)
; a1 = filnavn som skal være default, 0 for ingen
getfullname
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	bne.b	1$				; nei. kan ikke, tar ren tekst
	move.l	(filereqadr,NodeBase),d0	; har vi fått requester ?
	beq.b	1$				; nope
	clr.b	(readlinemore,NodeBase)		; flush'er input
	bsr	getfullnamewithreq
	bra.b	9$

1$	move.l	a1,d0				; bruker ikke requester
	beq.b	2$				; ikke edline
	moveq.l	#70,d0
	lea	(enterffnametext),a0
	bsr	mayedlinepromptfull
	bra.b	9$

2$	lea	(enterffnametext),a0
	bsr	readlineprompt
9$	rts

	IFND ASLFR_InitialFile
ASLFR_InitialFile equ TAG_USER+$80008   ; Initial requester coordinates
	ENDC

; a0 = string å lagre filnavnet i
; a1 = filnavn som skal være default, 0 for ingen
; z = 1, bare return
; z = 0, a0 = filnavn
; n = 1, klarte ikke bruke asl
getfullnamewithreq
	push	a2/a3/d2/d3
	link.w	a3,#-16
	move.l	a3,d3
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	bne.b	8$				; nei. kan ikke
	move.l	a0,a3				; husker lagre string

	move.l	(filereqadr,NodeBase),d0	; har vi fått requester ?
	beq.b	8$				; nope
	move.l	(aslbase),a6
	move.l	a1,a0
	suba.l	a1,a1
	move.l	d0,a2
	move.l	a0,d0				; har vi en fil inn ?
	beq.b	4$				; nei. Dropp tags
	move.l	#ASLFR_InitialFile,(sp)		; bygger opp tags for å fylle ut filnavnet
	move.l	a0,(4,sp)
	move.l	#TAG_DONE,(8,sp)
	move.l	sp,a1
4$	move.l	a2,a0
	jsrlib	AslRequest
	move.l	d0,d2
	beq.b	2$				; cancle eller error
	move.l	a3,a1				; fyller i filnavnet
	move.l	(rf_Dir,a2),a0
	tst.b	(a0)
	beq.b	1$				; ikke noen dir
	bsr	strcopy
	subq.l	#1,a1
	cmpi.b	#':',(-1,a1)
	beq.b	1$
	cmpi.b	#'/',(-1,a1)
	beq.b	1$
	move.b	#'/',(a1)+
1$	move.l	(rf_File,a2),a0
	tst.b	(a0)
	bne.b	3$
2$	clrn					; Klarte å bruke ASL, men ..
	setz					; ikke noe filnavn
	bra.b	9$
3$	bsr	strcopy
	move.l	a3,a0
	clrzn					; alt ok
	bra.b	9$
8$	setn					; klarte ikke asl
9$	move.l	(exebase),a6
	move.l	d3,a3
	unlk	a3
	pop	a2/a3/d2/d3
	rts

filereqtags
	dc.l	ASL_Window,0
	dc.l	TAG_DONE,0

; d0 forige confnr
getnextconfnr
1$	bsr	getnextconfnrsub
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d0,d1
	sub.w	#1,d1
	mulu	#Userconf_seizeof,d1
	move.w	(uc_Access,a0,d1.l),d1
	btst	#ACCB_Read,d1		; Er vi medlem her ?
	bne.b	8$			; ja, ok
	subi.w	#1,d0
	add.w	d0,d0			; gjor om til confnr standard
	bra.b	1$
8$	subi.w	#1,d0
	add.w	d0,d0			; gjor om til confnr standard
	rts

; d0 - nåværende konf nr.
getnextconfnrsub
	push	a2
	lea	(n_FirstConference+CStr,MainBase),a2
	cmpi.w	#-1,d0			; har vi aktiv conf ?
	bne.b	1$			; ja
3$	moveq.l	#0,d0			; tar første conf
	move.w	(n_ConfOrder,a2),d0
	bra.b	4$
1$	lsr.w	#1,d0
	addi.w	#1,d0
0$	moveq.l	#0,d1
	move.w	(Maxconferences+CStr,MainBase),d1
	sub.w	#1,d1
	move.l	a2,a0
2$	cmp.w	(n_ConfOrder,a0),d0
	lea	(ConferenceRecord_SIZEOF,a0),a0
	dbeq	d1,2$
	cmpi.w	#-1,d1
	beq.b	3$			; fant ikke.. Error. Tar første
	moveq.l	#0,d0			; henter conf nr
	move.w	(n_ConfOrder,a0),d0
	bne.b	4$			; alt ok
6$	move.w	(n_ConfOrder,a2),d0	; tar default
4$	cmp.w	(Maxconferences+CStr,MainBase),d0
	bhi.b	6$
	move.l	d0,d1			; sjekker om denne conf'en finnes
	beq.b	5$			; null allerede, egentlig galt, men..
	subq.l	#1,d1
5$	mulu.w	#ConferenceRecord_SIZEOF,d1
	move.b	(n_ConfName,a2,d1.l),d1
	beq.b	0$			; nope. Prøver igjen
	pop	a2
	rts

; d0 forige confnr
getprevconfnr
	push	a2
	lea	(n_FirstConference+CStr,MainBase),a2
	cmpi.w	#-1,d0			; har vi aktiv conf ?
	bne.b	1$			; ja
3$	moveq.l	#0,d0			; tar første conf + 1
	move.w	(n_ConfOrder+ConferenceRecord_SIZEOF,a2),d0
	bra.b	4$
1$	lsr.w	#1,d0
	addi.w	#1,d0
0$	moveq.l	#0,d1
	move.w	(Maxconferences+CStr,MainBase),d1
	sub.w	#1,d1
	move.l	a2,a0
2$	cmp.w	(n_ConfOrder,a0),d0
	lea	(ConferenceRecord_SIZEOF,a0),a0
	dbeq	d1,2$
	cmpi.w	#-1,d1
	beq.b	3$			; fant ikke.. Error. Tar første
	moveq.l	#0,d0			; henter conf nr
	move.w	(n_ConfOrder-2*ConferenceRecord_SIZEOF,a0),d0
	lea	(2*ConferenceRecord_SIZEOF,a2),a1
	cmpa.l	a0,a1
	bls.b	4$			; alt ok (vi gikk ikke utenfor)
	move.w	(Maxconferences+CStr,MainBase),d0
	mulu	#ConferenceRecord_SIZEOF,d0
	lea	(0,a2,d0.l),a0
5$	lea	(-ConferenceRecord_SIZEOF,a0),a0
	move.w	(n_ConfOrder,a0),d0		; finner siste
	beq.b	5$
4$
	move.l	d0,d1			; sjekker om denne conf'en finnes
	beq.b	6$			; null allerede, egentlig galt, men..
	subq.l	#1,d1
6$	mulu.w	#ConferenceRecord_SIZEOF,d1
	move.b	(n_ConfName,a2,d1.l),d1
	beq.b	0$			; nope. Prøver igjen
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d0,d1
	sub.w	#1,d1
	mulu	#Userconf_seizeof,d1
	move.w	(uc_Access,a0,d1.l),d1
	btst	#ACCB_Read,d1		; Er vi medlem her ?
	beq.b	0$			; nope
	subi.w	#1,d0
	add.w	d0,d0			; gjor om til confnr standard
	pop	a2
	rts

; d0 = antall filer ekstra
; d1 = antall kb ekstra
; returnerer z = 1 hvis det er for mye (dvs miste accsess)
testratio
	push	d2/d3
	move.l	d0,d2
	move.l	d1,d3
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(uc_Access,a0),d0		; henter news access
	btst	#ACCB_FileVIP,d0		; er vi filevip ?
	bne	9$				; jepp. da gir vi f..
	move.b	(Cflags+CStr,MainBase),d0	; er det noen ratio på ?
	andi.b	#CflagsF_Byteratio+CflagsF_Fileratio,d0
	beq.b	8$				; nei, ferdig

;	lea	(checkratiotext),a0
;	bsr	writetexto

	move.b	(Cflags+CStr,MainBase),d0		; er det fil noen ratio på ?
	andi.b	#CflagsF_Fileratio,d0
	beq.b	2$				; nei, videre
	move.w	(u_FileRatiov+CU,NodeBase),d0	; personelig ratio ?
	bne.b	1$				; ja, bruker den.
	move.w	(FileRatiov+CStr,MainBase),d0	; er det file ratio ?
	beq.b	2$				; nope
1$	move.w	(Uploaded+CU,NodeBase),d1
	addi.w	#1,d1
	mulu.w	d0,d1				; beregner antall filer vi kan dl'e
	moveq.l	#0,d0
	move.w	(Downloaded+CU,NodeBase),d0
	add.w	d2,d0				; legger til for de ekstra filene
	cmp.l	d0,d1				; filer, maks filer vi har lov til+1
	bls.b	3$				; for mye

2$	move.b	(Cflags+CStr,MainBase),d0		; er det noen byte ratio på ?
	andi.b	#CflagsF_Byteratio,d0
	beq.b	8$				; nei, ferdig
	move.w	(u_ByteRatiov+CU,NodeBase),d0	; personelig ratio ?
	bne.b	5$				; ja, bruker den.	
	move.w	(ByteRatiov+CStr,MainBase),d0	; er det byte ratio ?
	beq.b	8$				; nei, ferdig
5$	move.l	(KbUploaded+CU,NodeBase),d1
	addq.l	#1,d1
	mulu.w	d0,d1
	move.l	(KbDownloaded+CU,NodeBase),d0
	add.l	d3,d0				; legger til for de ekstra bytene
	cmp.l	d0,d1				; kb, maks kb vi har lov til+1
	bhi.b	4$				; under grensen
3$	setz					; for mye, returnerer det
	bra.b	9$
4$	setz
8$	notz
9$	pop	d2/d3
	rts

checkratio
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(uc_Access,a0),d0		; henter news access
	btst	#ACCB_FileVIP,d0		; er vi filevip ?
	bne.b	4$				; jepp. da gir vi f..
	move.b	(Cflags+CStr,MainBase),d0		; er det noen ratio på ?
	andi.b	#CflagsF_Byteratio+CflagsF_Fileratio,d0
	beq.b	9$				; nei, ferdig
	lea	(checkratiotext),a0
	bsr	writetexto
	moveq.l	#0,d0				; ingen ekstra filer
	moveq.l	#0,d1				; eller bytes
	bsr	testratio
	bne.b	4$
	lea	(u_almostendsave+CU,NodeBase),a0 ; mister dl access
	andi.w	#~ACCF_Download,(uc_Access,a0)
	lea	(dlacclosttext),a0
	move.w	(Savebits+CU,NodeBase),d0	; husker at han har mistet DL'en
	bset	#SAVEBITSB_LostDL,d0
	move.w	d0,(Savebits+CU,NodeBase)
	bra.b	8$

4$	move.w	(Savebits+CU,NodeBase),d0
	bclr	#SAVEBITSB_LostDL,d0
	beq.b	9$				; hadde ikke mistet
	move.w	d0,(Savebits+CU,NodeBase)	; sletter miste flagget
	lea	(u_almostendsave+CU,NodeBase),a0 ; får tilbake dl access hvis vi ikke har den
	move.w	(uc_Access,a0),d0
	btst	#ACCB_Download,d0
	bne.b	9$				; vi har den, så dette er en nop
	ori.w	#ACCF_Download,d0		; får dl access
	move.w	d0,(uc_Access,a0)
	lea	(dlaccgainedtext),a0
8$	bsr	writetexto
	lea	(uc_Access+u_almostendsave+CU,NodeBase),a0
	moveq.l	#2,d0				; lagrer forandring
	bsr	saveuserarea
9$	rts

;a0 - log tekst
;d0 - confnr
;d1 - msg nr
killrepwritelog
	push	d2/a3
	move.l	d1,d2
	move.l	a0,a3
	lea	(tmptext,NodeBase),a1
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu.w	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.b	#'#',(a1)+
	move.l	a1,a0
	move.l	d2,d0
	bsr	konverter
	move.l	a3,a0
	lea	(tmptext,NodeBase),a1
	bsr	writelogtexttimed
	pop	d2/a3
	rts

browseconferences1
	push	a2/d2/d3/a3
	lea	(tmpfileentry,NodeBase),a3
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	9$				; nope

	lea	(ansiclearscreen),a0
	bsr	writetexti

	moveq.l	#1,d0				; conference browse
	jsr	(setupbrowse)
	jsr	(setuptmpbrowse)
	beq.b	8$				; error

	lea	(n_FirstConference+CStr,MainBase),a2
	moveq.l	#0,d2				; starter alltid ifra NEWS
	move.w	d2,d3				; husker starten

1$	move.w	d2,d0
	mulu.w	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a2,d0.l),a0

;	move.w	(n_ConfSW,a2,d0.l),d1
;	btst	#CONFSWB_VIP,d1			; JEO1 Kan han join'e denne ?
;	beq.b	1$				; nei

	lea	(Filename,a3),a1		; Legger confname her...
	jsr	(strcopy)

	lea	(localefullname),a0
	lea	(Filedescription,a3),a1
	jsr	(strcopy)

;	move.l	a3,a1				; a3 = tmpfileentry
;	moveq.l	#Fileentry_SIZEOF,d0
;	bsr	strcopymaxlen

;	move.l	(localefullname),a0
;	move.l	(Filedescription,a3),a1
;	move.w	#Sizeof_FileDescription,d0
;	bsr	strcopymaxlen

	move.l	a3,a0
	move.w	d2,d0

	jsr	(addtmpbrowse)
	beq.b	3$				; full, "ferdig", hopper til valg
2$	move.w	d2,d0
	jsr	(getnextconfnrsub)
	subi.w	#1,d0
	add.w	d0,d0			; gjør om til confnr standard
	move.w	d0,d2
	cmp.w	d3,d2
	bne	1$

3$	jsr	(dobrowseselect)
	jsr	(cleanuptmpbrowse)

8$
9$	pop	a2/d2/d3/a3
	rts

; a0 = prompt
getconfname
	bsr	readlineprompt
	beq.b	9$
	bsr.b	getconfnamesub
9$	rts

; a0 = input
getdirnamesub
	push	d2/a2
	move.l	(firstFileDirRecord+CStr,MainBase),a1
	lea	(n_DirName,a1),a1
	move.w	(MaxfileDirs+CStr,MainBase),d0
	add.w	d0,d0
	lea	(dirnotfoundtext),a2
	moveq.l	#FileDirRecord_SIZEOF,d1
	bsr.b	getconfdirnamesub
	pop	d2/a2
	rts

; a0 = input
getconfnamesub
	push	d2/a2
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a1	; hvilken array vi skal lete i
	move.w	(Maxconferences+CStr,MainBase),d0	; størrelsen
	add.w	d0,d0
	lea	(connotfoundtext),a2
	moveq.l	#ConferenceRecord_SIZEOF,d1
	bsr.b	getconfdirnamesub
	pop	d2/a2
	rts

; a0 = input
; a1 = array med navn
; d0 = num entries * 2
; a2 = feilmelding
; d1 = size på entrys
getconfdirnamesub
	push	a2/a3/d2-d7
	move.l	a1,d5				; array
	move.w	d0,d6				; antall
	swap	d6
	move.w	d1,d6				; husker size
	move.l	a2,d7				; feil melding
	moveq.l	#0,d4				; ikke sub også
	move.l	a0,a2				; husker input
	bsr	upword
	move.l	d5,a3				; leter etter konferansen/fildiren
	move.l	d6,d3
	swap	d3
	moveq.l	#0,d2

0$	move.b	(a0)+,d0
	beq.b	1$				; ferdig med å scan'e
	bsr	10$				; er dette et skille tegn ?
	bne.b	0$				; Nei. Fortsetter
	move.l	a0,d4				; det er topic
	move.b	#0,(-1,a0)			; deler opp input'en

1$	move.b	(a3),d0				; er det en konf her ?
	beq.b	2$				; nope
	move.l	a3,a1
	move.l	a2,a0
	bsr	30$				; sammenligner
	beq.b	3$				; funnet konf/sub conf
2$	lea	(0,a3,d6.w),a3			; peker til neste konf navn
	addq.w	#2,d2
	cmp.w	d3,d2
	bcs.b	1$
	move.l	d7,a0
	bsr	writeerroro
	setzn
	bra	9$

301$	tst.l	d4				; er det mere ?
	beq	8$				; nope, da er alt ok
	bra.b	2$				; ja, da var det ikke denne

3$	move.b	(a1)+,d0			; sjekker om dette er en sub conf
	beq.b	301$				; nope
	cmpi.b	#'/',d0				; er dette et skille tegn ?
	bne.b	3$				; Nei. Fortsetter
; er sub conf....
	move.l	a3,a0
	lea	(tmptext,NodeBase),a1		; husker hoved navnet
4$	move.b	(a0)+,d0			; kopierer til, men ikke med
	move.b	d0,(a1)+			; skille tegnet
	cmpi.b	#'/',d0				; skilletegn ?
	bne.b	4$				; nei, kopier flere tegn
	move.b	#0,(-1,a1)			; sletter skilletegnet

	move.l	d4,a0
	tst.l	d4				; er det mere lest ?
	bne.b	6$				; ja
	tst.b	(readlinemore,NodeBase)		; er det mere input ?
	bne.b	5$				; ja. lister ikke alle sub'ene
	bsr	20$
5$	lea	(topictext),a0
	bsr	readlineprompt
	beq.b	9$
6$	moveq.l	#0,d4				; ikke en gang til
	move.l	a0,a3				; husker input'en
	bsr	upword
	lea	(tmptext,NodeBase),a0		; bygger opp fullt navn
	lea	(maintmptext,NodeBase),a1
	bsr	strcopy
	move.b	#'/',(-1,a1)
	move.l	a3,a0
	bsr	strcopy
	lea	(maintmptext,NodeBase),a2
	move.l	d5,a3				; leter etter konferansen/fildiren
	move.l	d6,d3
	swap	d3
	moveq.l	#0,d2

7$	move.b	(a3),d0				; er det en konf her ?
	beq.b	71$				; nope
	move.l	a3,a1
	move.l	a2,a0
	bsr	30$				; sammenligner
	beq.b	8$				; funnet konf'en
71$	lea	(0,a3,d6.w),a3			; peker til neste konf navn
	addq.w	#2,d2
	cmp.w	d3,d2
	bls.b	7$
	bsr	20$
	move.b	#0,(readlinemore,NodeBase)	; flusher input
	bra.b	5$
8$	move.w	d2,d0				; returnerer confnr *2
	clrz
9$	pop	a2/a3/d2-d7
	rts

10$	cmpi.b	#' ',d0				; soker etter skille tegn som
	beq.b	19$				; brukes i sub konfer
	cmpi.b	#',',d0
	beq.b	19$
	cmpi.b	#'/',d0
19$	rts

; lister alle sub konfer til en hovedkonf (som ligger i tmptext)
20$	push	a2/d2/d3/a3
	lea	(topicsaretext),a0
	bsr	writetext
	moveq.l	#0,d3				; har ikke tatt første enda
	move.l	d5,a2
	move.l	d6,d2
	swap	d2
21$	move.l	a2,a1
	move.b	(a1),d0
	beq.b	28$				; ingen konf her
	lea	(tmptext,NodeBase),a0
	bsr.b	30$				; sammenligner
	bne.b	28$				; ikke like
	move.b	(a1)+,d0			; Naa skal dette vare et
	cmpi.b	#'/',d0				; skilletegn ?
	bne.b	28$				; det var det ikke..
	tst.l	d3				; første gang ?
	beq.b	22$				; jepp
	move.l	a1,a3
	lea	(kommaspacetext),a0
	bsr	writetext
	move.l	a3,a1
22$	moveq.l	#1,d3				; har skrevet ut minst en
	move.l	a1,a0
	bsr	writetext
	bsr	breakoutimage
28$	lea	(0,a2,d6.w),a2			; peker til neste konf navn
	subi.w	#2,d2
	bne.b	21$
	move.b	#'.',d0
	bsr	writechari
	pop	a2/d2/d3/a3
	rts

30$	move.b	(a0)+,d0
	beq.b	39$			; ferdig. De er like (saa langt)
	bsr	upchar
	move.b	d0,d1
	move.b	(a1)+,d0
	beq.b	31$
	bsr	upchar
	cmp.b	d0,d1
	beq.b	30$
31$	clrz
39$	rts

waitforemptymodem
	push	d2/d3
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq	9$				; Yepp. ingen venting
	move.l	(nodenoden,NodeBase),a0
	move.l	(Nodespeed,a0),d0		; ut speed
	beq.b	9$				; lokal
	move.l	(SerTotOut,NodeBase),d1		; antall tegn som er skrevet siden siste input
	beq.b	9$				; ingen ser output
	IFND	DEMO
	move.w	(Setup+Nodemem,NodeBase),d1
	btst	#SETUPB_Lockedbaud,d1
	beq.b	9$				; ikke locked, så da er alt ok
	move.l	(NodeBaud+Nodemem,NodeBase),d1	; dte-modem speed
	cmp.l	d0,d1				; connect,dte-modem speed
	bls.b	9$				; like (eller større), ut.
	move.l	(SerTotOut,NodeBase),d3

; d1 = dte-modem speed (eg 19200)
; d3 = totalt antall tegn ut siden siste input

	moveq.l	#10,d0
	lsl.l	d0,d3				; tegn * 1024
	divu.w	d0,d1				; har cps på dte-modem
	beq.b	9$				; abort
	move.w	(cpsrate,NodeBase),d0		; cps modem-modem
	beq.b	9$				; abort

; d0.w = cps modem-modem
; d1.w = cps dte-modem
; d3.l = tot char*1024

	move.l	d3,d2
	divu.w	d0,d2				; d2.w = (t*1024)/(modem-modem)
	move.l	d3,d0
	divu.w	d1,d0				; d0.w = (t*1024)/(dte-modem)
	sub.w	d0,d2				; trekker ifra tid brukt til modemet
	bcs.b	9$				; alt brukt opp, abort

; d2.w = sek*1024 å vente

	moveq.l	#10,d0
	moveq.l	#0,d3
	move.w	d2,d3
	andi.w	#$3ff,d3			; d3 = mikrosecs
	andi.l	#$ffff,d2
	lsr.l	d0,d2				; d2 = sek

	move.l	d2,d0
	bsr	skrivnr
	move.b	#' ',d0
	bsr	writechar
	move.l	d3,d0
	bsr	skrivnr
	bsr	outimage

	move.l	d2,d0
	beq.b	1$
	bsr	waitsecs			; venter sekundene
1$	move.l	d3,d0
	beq.b	9$
	addq.l	#3,d0				; sikrer at den ikke er for liten
	bsr	waitmicros
;	beq.b	8$				; ingen ser output
	ENDC
9$	pop	d2/d3
	rts

; returnerer z = 0 hvis sysop access
justchecksysopaccess
	tst.b	(tmpsysopstat,NodeBase)
	bne.b	9$
	move.l	(Usernr+CU,NodeBase),d0	; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	8$			; Jepp.
	move.w	(confnr,NodeBase),d0
	cmp.w	#-1,d0
	bne.b	1$
	moveq.l	#0,d0
1$	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Sysop,d0		; har bruker sysop access ??
	bne.b	9$
	clrz
8$	notz
9$	rts

checksysopaccess
	bsr	justchecksysopaccess
	bne.b	9$
	cmpi.w	#20,(menunr,NodeBase)	; er vi i sigopmeny ?
	beq.b	8$			; jepp, gir f..
	move.w	#0,(menunr,NodeBase)	;Skifter til Main menu.
	lea	(youarenottext),a0	; Nei, skriver ut fy melding
	bsr	writeerroro
	clrz
8$	notz
9$	rts

; d0 = conf nr * 1 (obs ikke * 2 som er vanelig)
; d1 = 0 : Skriver ut nummeret på de som har forandret seg
;   != 0 : Vil bare vite om det er forandret
;    =-1 : Kopier nye bulletins over i tmpdir'en med navn BLT-x.y, hvor x = confnr*1, y = bulletinnr
; ret:
; d0 : returnerer antall filer som er kopiert
checkupdatedbulletins
	push	d2/d3/d4/d5/a6/d6/d7
	link.w	a3,#-160
	move.l	(dosbase),a6
	move.l	d0,d4
	moveq.l	#1,d6
	moveq.l	#0,d7				; ingen bulletins er kopiret enda.
	cmp.l	#-1,d1
	bne.b	7$
	bset	#28,d6				; Vi skal kopiere filene over i tmp
	bra.b	2$
7$	tst.w	d1
	beq.b	2$
	bset	#31,d6				; Husker info nivå
2$	moveq.l	#0,d0				; i tilfelle vi skal ut..
	lea	(n_FirstConference+CStr,MainBase),a0
	move.l	d4,d1
	mulu	#ConferenceRecord_SIZEOF,d1	; har denne konferansen
	move.b	(n_ConfBullets,a0,d1.l),d3	; bulletiner ?
	beq	9$				; nei. ut. ingen nye
1$	lea	(80,sp),a0
	move.w	d6,d0
	move.w	d4,d1
	bsr	getkonfbulletname		; fyller i filnavnet
	lea	(80,sp),a0
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock				; tar en lock
	move.l	d0,d1
	beq	8$				; egentlig error, men..
	move.l	d0,d5
	move.l	(infoblock,NodeBase),d2
	jsrlib	Examine
	move.l	d0,d2				; Husker status
	move.l	d5,d1
	jsrlib	UnLock
	tst.l	d2				; gikk det bra ?
	beq	8$				; nei.
	move.l	(infoblock,NodeBase),a0
	move.l	(ds_Days+fib_DateStamp,a0),d0
	cmp.l	(lastdayonline,NodeBase),d0	; ny bulletin ?
	bcs	8$				; nei
	bhi.b	6$				; ja
	move.l	(ds_Minute+fib_DateStamp,a0),d0	; Samme dag, sjekker minutter
	cmp.w	(lastminonline,NodeBase),d0	; ny bulletin ?
	bcs	8$				; nei
6$	btst	#28,d6				; Skal vi kopiere ?
	beq.b	10$				; nei.
	lea	(sp),a0
	move.w	d4,d0
	move.w	d6,d1
	bsr	getqwkbuldest
	lea	(80,sp),a0
	lea	(sp),a1
	jsr	(_copybulletin)
	move.l	(dosbase),a6
	addq.l	#1,d7
	bra.b	8$
10$	btst	#31,d6				; mye info ?
	bne.b	9$				; nei. Ingen vits i å sjekke mere
	move.l	(exebase),a6
	btst	#30,d6				; skrevet ut header ?
	bne.b	3$				; ja
	lea	bullhasbupdtext,a0		; nei, skriver ut
	bsr	writetexto
	bset	#30,d6				; og husker
3$	btst	#29,d6				; Skal det ut space,komma ?
	beq.b	4$				; Nei
	lea	kommaspacetext,a0
	bsr	writetext
4$	move.w	d6,d0
	bsr	skrivnrw
	bsr	breakoutimage
	bset	#29,d6				; skal ha komme/space (hvis flere)
	move.l	(dosbase),a6
8$	add.w	#1,d6
	cmp.b	d3,d6				; flere buletiner igjen ?
	bls	1$				; Ja, fortsetter, eller no change
	btst	#29,d6				; Skal det ut puktum ?
	beq.b	5$				; Nei
	move.l	(exebase),a6
	move.b	#'.',d0
	bsr	writechar
	bsr	outimage
5$	move.l	d7,d0
	setz
9$	unlk	a3
	pop	d2/d3/d4/d5/a6/d6/d7
	rts

; a0 = buffer
; d0 = confnr
; d1 = bulletinnr
; lager en string på formatet : <tmpdir>BLT-<confnr>.<bulletinnr>
getqwkbuldest
	push	d2/d3
	move.w	d0,d2
	move.w	d1,d3
	move.l	a0,a1
	lea	(TmpPath+Nodemem,NodeBase),a0
	bsr	strcopy
	move.b	#'/',(-1,a1)
	lea	(qwkbullfilename),a0
	bsr	strcopy
	lea	(-1,a1),a0
	move.w	d2,d0
	jsr	(konverterw)
	move.b	#'.',(a0)+
	move.w	d3,d0
	jsr	(konverterw)
	move.b	#0,(a0)
	pop	d2/d3
	rts

; d0 = usernr
; d1 = confnr
; return : d0 = -1, error, 0 = ikke medlem, 1 = alt ok
_checkmemberofconf
	bsr.b	checkmemberofconf
	bmi.b	1$
	beq.b	2$
	moveq.l	#1,d0
1$	moveq.l	#-1,d0
	bra.b	9$
2$	moveq.l	#0,d0
9$	rts

; returnerer : N for error, Z for ikke medlem
; d0 = usernr
; d1 = confnr
checkmemberofconf
	push	a2/d2
	moveq.l	#-1,d2				; all ?
	cmp.l	d0,d2
	notz
	bne.b	8$				; ja, alltid medlem
	move.w	d1,d2				; husker conf'en
	move.l	(Tmpusermem,NodeBase),a2
	move.l	a2,a0
	jsr	(loadusernr)
	bne.b	1$
	lea	(loadusererrtext),a0
	bsr	writeerroro
	setzn
	bra.b	9$
1$	move.w	(Userbits,a2),d0
	andi.w	#USERF_Killed,d0		; Er han død ?
	notz
	beq.b	8$				; jepp
	lea	(u_almostendsave,a2),a0
	mulu	#Userconf_seizeof/2,d2
	move.w	(uc_Access,a0,d2.l),d0
	btst	#ACCB_Read,d0			; Er vi medlem her ?
8$	clrn
9$	pop	a2/d2
	rts

loginlistprivate
	push	a2/d2-d4
	lea	(tmpfileentry,NodeBase),a2
	moveq.l	#0,d3			; Det er privat dir'en vi søker i
	move.l	d3,d4			; Har vi skrevet ut "the following .." ? Nei
	moveq.l	#1,d2			; starter på første fil.
1$	move.l	(msg,NodeBase),a1
	move.w	#Main_loadfileentry,(m_Command,a1)
	move.l	d3,(m_UserNr,a1)
	move.l	d2,(m_arg,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_EOF,d0
	beq	7$
	cmpi.w	#Error_OK,d0
	bne.b	6$
	move.w	(Filestatus,a2),d0		; skriver ut alle filer som er
	move.w	d0,d1				; private til denne brukeren
	andi.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d1
	bne.b	2$				; hopper over disse
	btst	#FILESTATUSB_PrivateUL,d0	; Privat ?
	beq.b	2$				; nei, ikke skriv
	move.l	(Usernr+CU,NodeBase),d1
	cmp.l	(PrivateULto,a2),d1
	bne.b	2$				; ikke til denne brukeren
	tst.l	d4				; har vi skrevet ut start teksten ?
	bne.b	4$				; jepp
	lea	(tfprivfwtdltext),a0		; skriver ut
	bsr	writetexto
	beq.b	9$
	moveq.l	#1,d4				; ... Og husker at vi gjorde det
4$	lea	(Filename,a2),a0		; skriver <navn> (    2K, Geir Inge)
	moveq.l	#Sizeof_FileName,d0
	bsr	writetextrfill
	lea	(spaceparatext),a0
	bsr	writetext
	move.l	(Fsize,a2),d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	moveq.l	#5,d1
	bsr	skrivnrrfill
	lea	(kkommaspacetext),a0
	bsr	writetext
	move.l	(Uploader,a2),d0
	bsr	getusername
	bsr	writetext
	lea	(endparatext),a0
	bsr	writetexto
	beq.b	9$
2$	addq.l	#1,d2
	bsr	testbreak
	beq.b	9$
	bra	1$

6$	lea	(errloadfilhtext),a0
	bsr	writetext
	bra.b	8$
7$	tst.l	d4
	beq.b	9$
8$	bsr	outimage
9$	pop	a2/d2-d4
	rts

typetosysop
	move.l	(Usernr+CU,NodeBase),d0	; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	bne.b	9$			; nope, ut
	bsr	outimage		; newline
	beq.b	9$
	lea	(tosysopfname),a0
	bsr	typelogfile		; skriver ut fila
	move.l	(dosbase),a6		; sletter fila.
	move.l	#tosysopfname,d1
	jsrlib	DeleteFile
	move.l	(exebase),a6
9$	rts

; d0 = filehandle
; returnerer (d0) antall meldinger som er add'a
; z = 0 hvis det gikk bra
dograbqueue
	push	d2/a2/d3/d4/d5
	moveq.l	#0,d5			; ikke quick mode
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)	; er det quick mode ?
	beq.b	5$
	moveq.l	#1,d5			; ja, husker
5$	moveq.l	#0,d4			; antall meldinger vi add'a
	move.l	d0,d2
	lea	(tmpmsgheader,NodeBase),a2
	moveq.l	#0,d3			; teller antall tall pr linje
1$	move.l	(msgqueue,NodeBase),d0	; er det flere meldinger her ?
	notz
	bne.b	9$			; nope. Ferdig
	move.l	a2,a0
	move.w	(confnr,NodeBase),d1	; henter inn msg header'en
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writeerrori
	bra.b	8$

2$	move.l	a2,a0
	bsr	writegrabmsgnr

	addi.w	#1,d3
	cmpi.w	#16,d3			; er vi ferdige med en rad ?
	bcs.b	3$			; nei
	move.w	#0,d3			; ja, nullstiller
	tst.b	d5			; quick ?
	bne.b	3$			; ja, ikke newline
	bsr	outimage		; og tar en line feed
	bra.b	4$
3$	bsr	breakoutimage
4$	move.l	(Number,a2),d0		; fjerner ifra read køen
	bsr	removefromqueue

	move.l	a2,a0			; kan vi skrive ut denne ?
	move.w	(confnr,NodeBase),d0
	bsr	allowtype
	bne.b	1$			; nope. Ikke denne nei (usansynelig...)

	move.w	(confnr,NodeBase),d0	; melding ut i scratchpad
	move.l	d2,d1
	move.l	a2,a0
	addq.l	#1,d4			; øker antall meldinger med 1
	bsr	doscratchmsg
	bpl.b	1$			; ikke error, fortsetter
8$	setz
	bra.b	99$
9$	moveq.l	#0,d0
	move.l	d0,(msgqueue,NodeBase)	; Tømmer køen.
	move.l	d4,d0
	clrz
99$	pop	d2/a2/d3/d4/d5
	rts

; a0 = msgheader
writegrabmsgnr
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)	; er det quick mode ?
	beq.b	1$			; nope, skriver nummeret
	move.l	(Usernr+CU,NodeBase),d1	; skriver spesielle tegn
	move.b	#'*',d0
	cmp.l	(MsgTo,a0),d1
	beq.b	2$
	move.b	#'!',d0
	cmp.l	(MsgFrom,a0),d1
	beq.b	2$
	move.b	#'.',d0
2$	bsr	writechar
	bra.b	9$
1$	move.l	(Number,a0),d0		; skriver ut nummeret
	bsr 	connrtotext
	moveq.l	#5,d0
	jsr	(writetextlfill)
9$	rts

	IFND DEMO
; fil ptr i d4
dograbconf
	move.w	(Savebits+CU,NodeBase),d1
	btst	#SAVEBITSB_ReadRef,d1

	beq	dograbconfmark
;	bra	dograbconfref

dograbconfref
;d2	konfnr/antall meldiger i bredden(de øverste 16 bit'ene)
;d3	msg nr (teller)
;d4	filehandle
;d5	maxs meldings nr i konf
;d6	kø nr
;d7	error/>>>>>/*****/quick status, antall meldinger sendt til scratch'en
;	bit 31 = error, bit 30 = har skrevet >>>>>, bit 29 = har skrevet *****
;	bit 28 = quick mode (ikke noe newline)
;a2	msgqueue
;a3	tmpmsgheader

	push	d2/d3/d5/d6/d7/a2/a3	; fil ptr er i d4
	moveq.l	#0,d2
	move.w	d0,d2			; konfnr
	moveq.l	#0,d1
	moveq.l	#0,d7			; ingen error, og ingen meldinger til scratch.
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)	; er det quick mode ?
	beq.b	3$			; nope,
	bset	#28,d7
3$	lea	(msgqueue,NodeBase),a2
	move.l	d1,(a2)			; Tømmer køen.
	move.l	d1,d6			; Køen er 0 lang.
	lea	(tmpmsgheader,NodeBase),a3
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d5 ; siste melding i conf
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d2,d0			; Henter conferanse nr.
	mulu	#Userconf_seizeof/2,d0
	move.l	(uc_LastRead,a0,d0.l),d3 ; Siste vi leste
	IFD	FullGrab
	moveq.l	#0,d3
	ENDC
	moveq.l	#0,d0			; i tilfelle vi går ut under
	addq.l	#1,d3
	cmp.l	d3,d5
	bcs.b	98$
	move.l	d5,d0
	move.l	#NumMsgNrInQueue-100,d1	; setter av plass til litt marking
	cmpi.l	#1,d3			; er det første gangen her ?
	bne.b	2$			; nei, da tar vi ikke max scan
	IFD	FullGrab
	bra.b	2$
	ENDC

	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	d2,d0			; Henter conferanse nr.
	mulu	#ConferenceRecord_SIZEOF/2,d0
	moveq.l	#0,d1
	move.w	(n_ConfMaxScan,a0,d0.l),d1 ; henter maks scan verdien
2$	sub.l	d1,d0
	bcs.b	1$
	cmp.l	d3,d0
	bls.b	1$
	move.l	d0,d3			; Kutter ut for gamle meldinger.
1$	cmp.l	d3,d5
	bcs.b	109$
	move.l	d3,d0
	bsr.b	10$
	btst	#31,d7
	bne.b	99$			; error
	bclr	#29,d7			; Nytt subject
	addq.l	#1,d3
	bra.b	1$
99$	setz
	bra.b	9$
98$	clrz
	bra.b	9$
109$	move.l	d7,d0
	andi.l	#$fffffff,d0
	clrz
9$	pop	d2/d3/d5/d6/d7/a2/a3
	rts

10$	move.l	d5,-(a7)
	move.l	d0,d5		; msg nr
	move.w	d2,d1		; conf nr
	move.l	a3,a0		; tmpmsgheader
	jsr	(loadmsgheader)
	beq.b	14$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	bset	#31,d7			; Setter error flagg.
	bra	19$
14$	move.l	a3,a0
	move.w	d2,d0
	bsr	kanskrive
	bne	19$			; 11$ eller 19$
	move.l	(Number,a3),d0
	bsr	findinqueue
	bne	19$			; Vi har vært innom denne
	move.l	(Number,a3),d0		; Legger inn i køen
	move.l	d0,(0,a2,d6.l)
	addq.l	#4,d6
	moveq.l	#0,d0			; Sletter resten av køen.
	move.l	d0,(0,a2,d6.l)
	btst	#30,d7
	bne.b	12$
	bset	#30,d7
	lea	(nyconfgrabtext),a0
	move.l	d4,d0
	bsr	writefileln
	bne.b	12$
	bset	#31,d7			; error
	bra	19$
12$	btst	#29,d7
	bne.b	13$
	bset	#29,d7
	lea	(nysubjgrabtext),a0
	move.l	d4,d0
	bsr	writefileln
	bne.b	13$
	bset	#31,d7			; error
	bra	19$

13$	;lea	(transnltext),a0		; skriver ut nl
;	move.l	d4,d0
;	bsr	writefileln
;	bne.b	18$
;	bset	#31,d7			; error
;	bra	19$

18$	move.l	a3,a0
	bsr	writegrabmsgnr
	swap	d2			; henter fram bredde telleren
	addi.w	#1,d2
	cmpi.w	#16,d2			; er vi ferdige med en rad ?
	bcs.b	16$			; nei
	move.w	#0,d2			; ja, nullstiller
	btst	#28,d7
	bne.b	16$
	bsr	outimage		; og tar en line feed
	bra.b	17$
16$	bsr	breakoutimage
17$	swap	d2			; tilbake med confnr
	move.w	d2,d0
	move.l	d4,d1
	move.l	a3,a0
	addq.l	#1,d7			; oppdaterer antall grab'a meldinger
	bsr	doscratchmsg
	bpl.b	11$
	bset	#31,d7			; error
	bra.b	19$
11$	move.l	(RefNxt,a3),-(a7)
	move.l	(RefBy,a3),d0
	beq.b	15$
	bsr	10$
15$	move.l	(a7)+,d0
	beq.b	19$
	btst	#31,d7
	bne.b	19$
	bsr	10$
19$	move.l	(a7)+,d5
	rts

dograbconfmark
	push	a3/d2/d3/d5/d6/d7
	moveq.l	#0,d7			; antall meldinger i grab'en
	moveq.l	#0,d2
	move.w	d0,d2			; konfnr/bredde teller
	moveq.l	#0,d6			; har vi skrevet >>>>> ?
	lea	(tmpmsgheader,NodeBase),a3
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d5 ; siste melding i conf
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d2,d0			; Henter conferanse nr.
	mulu	#Userconf_seizeof/2,d0
	move.l	(uc_LastRead,a0,d0.l),d3 ; Siste vi leste
	addq.l	#1,d3
	cmp.l	d3,d5
	bcs	9$
	move.l	d5,d0
	move.l	#NumMsgNrInQueue-100,d1	; setter av plass til litt marking
	cmpi.l	#1,d3			; er det første gangen her ?
	bne.b	7$			; nei, da tar vi ikke max scan
	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	d2,d0			; Henter conferanse nr.
	mulu	#ConferenceRecord_SIZEOF/2,d0
	moveq.l	#0,d1
	move.w	(n_ConfMaxScan,a0,d0.l),d1 ; henter maks scan verdien
7$	sub.l	d1,d0
	bcs.b	1$
	cmp.l	d3,d0
	bls.b	1$
	move.l	d0,d3			; Kutter ut for gamle meldinger.
1$	cmp.l	d3,d5
	bcs	9$
	move.w	d2,d1
	move.l	d3,d0
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writetexti
8$	setz
	bra	99$
2$	move.l	a3,a0
	move.w	d2,d0
	bsr	kanskrive
	bne.b	3$

	move.l	a3,a0
	bsr	writegrabmsgnr

	swap	d2			; henter fram bredde telleren
	addi.w	#1,d2
	cmpi.w	#16,d2			; er vi ferdige med en rad ?
	bcs.b	5$			; nei
	move.w	#0,d2			; ja, nullstiller
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)	; er det quick mode ?
	bne.b	5$			; ja, ingne newline
	bsr	outimage		; og tar en line feed
	bra.b	6$
5$	bsr	breakoutimage
6$	swap	d2			; tilbake med confnr
	tst.l	d6
	bne.b	4$
	moveq.l	#1,d6
	lea	(nyconfgrabtext),a0
	move.l	d4,d0
	bsr	writefileln
	beq.b	99$			; error
	lea	(transnltext),a0		; skriver ut nl
	move.l	d4,d0
	bsr	writefileln
	beq.b	99$			; error

4$	move.w	d2,d0
	move.l	d4,d1
	move.l	a3,a0
	addq.l	#1,d7
	bsr	doscratchmsg
	bmi	8$
3$	addq.l	#1,d3
	bra	1$
9$	move.l	d7,d0
	clrz
99$	pop	a3/d2/d3/d5/d6/d7
	rts
	ENDC

unjoin	move.w	(confnr,NodeBase),d0		; Oppdaterer last read.
	cmpi.w	#-1,d0
	beq.b	9$				; Har ikke vært i noen konferanse
	bsr	findlowestinqueue
	bne.b	1$
	move.l	(HighMsgQueue,NodeBase),d0
	bra.b	2$
1$	subq.l	#1,d0
2$	moveq.l	#0,d1
	move.l	d1,(msgqueue,NodeBase)		; Tømmer køen.
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(confnr,NodeBase),d1
	mulu	#Userconf_seizeof/2,d1
	lea	(uc_LastRead,a0,d1.l),a0
	move.l	(a0),d1
	cmp.l	d0,d1
	bcc.b	9$
	move.l	d0,(a0)
9$	rts

; d0 = confnr (*2)
buildqueue
	move.w	(Savebits+CU,NodeBase),d1
	btst	#SAVEBITSB_ReadRef,d1
	bne.b	buildqueueref
	bra	buildqueuemark

buildqueueref
	push	a2/a3/d2-d7
	move.l	d0,d2			; konfnr *2 (pluss max scan info - bit #31)
	moveq.l	#0,d3			; Antall * 4
	moveq.l	#0,d6			; Antall til denne brukeren.
	moveq.l	#0,d7			; Avslutt (T/F)
	move.l	d7,-(a7)		; kuttet flagget ligger på stack'en
	lea	(msgqueue,NodeBase),a2
	move.l	d3,(a2)			; Tømmer køen.
	lea	(tmpmsgheader,NodeBase),a3
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d5 ; siste melding i conf
	move.l	d5,(HighMsgQueue,NodeBase)
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d2,d0			; Henter conferanse nr.
	mulu	#Userconf_seizeof/2,d0
	move.l	(uc_LastRead,a0,d0.l),d4 ; Siste vi leste
	addq.l	#1,d4
	cmp.l	d4,d5
	bcs.b	9$
	move.l	d5,d0
	move.l	#NumMsgNrInQueue-100,d1	; setter av plass til litt marking
	cmpi.l	#1,d4			; er det første gangen her ?
	bne.b	3$			; Nei, ikke max scan
;	beq.b	2$			; ja, dvs max scan
;	btst	#31,d2			; skal vi ta max scan ?
;	beq.b	3$			; nei
2$	moveq.l	#1,d1
	move.l	d1,(a7)			; husker at vi kuttet meldinger
	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	d2,d1			; Henter conferanse nr.
	mulu	#ConferenceRecord_SIZEOF/2,d1
	add.l	d1,a0
	moveq.l	#0,d1
	move.w	(n_ConfMaxScan,a0),d1 ; henter maks scan verdien
3$	sub.l	d1,d0
	bcs.b	1$			; ikke for mange
	cmp.l	d4,d0			; Er det for mange ?
	bls.b	1$			; nei
	move.l	d0,d4			; Kutter ut for gamle meldinger.
	moveq.l	#1,d0
	add.l	d0,(a7)			; husker at vi kuttet meldinger
1$	cmp.l	d4,d5
	bcs.b	9$
	tst.l	d7
	bne.b	9$
	move.l	d4,-(a7)
	bsr	10$
	move.l	(a7)+,d4
	addq.l	#1,d4
	bra.b	1$
9$	moveq.l	#0,d0
	move.l	d0,(0,a2,d3.l)		; Markerer slutten på køen.
	move.l	d6,d1
	move.l	(a7)+,d0
	cmpi.l	#2,d0			; var det max scan som slo til
	bne.b	99$			; nei
	bset	#31,d1			; setter bit'et som markering at vi har kuttet
99$	move.l	d3,d0
	pop	a2/a3/d2-d7
	lsr.l	#2,d0
	rts

10$	move.w	d2,d1
	move.l	d4,d0
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	14$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	moveq.l	#1,d7
	bra.b	19$
14$	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	19$			; 11$ eller 19$
	move.l	(Number,a3),d0
	bsr	findinqueue
	bne.b	19$			; Vi har vært innom denne
	move.l	(Number,a3),d0
	move.l	d0,(0,a2,d3.l)
	addq.l	#4,d3
	moveq.l	#0,d0
	move.l	d0,(0,a2,d3.l)
	move.l	(Usernr+CU,NodeBase),d1
	cmp.l	(MsgTo,a3),d1
	bne.b	11$
	addq.l	#1,d6
11$	tst.l	d7
	bne.b	19$
	move.l	(RefNxt,a3),-(a7)
	move.l	(RefBy,a3),d4
	beq.b	12$
	bsr.b	10$
12$	move.l	(a7)+,d4
	beq.b	19$
	tst.l	d7
	bne.b	19$
	bsr.b	10$
19$	rts

buildqueuemark
	push	a2/a3/d2-d7
	move.l	d0,d2			; konfnr * 2 (pluss max scan info - bit #31)
	moveq.l	#0,d3			; Antall * 4
	moveq.l	#0,d6			; Antall til denne brukeren.
	moveq.l	#0,d7			; inken kutting
	lea	(msgqueue,NodeBase),a2
	move.l	d3,(a2)			; Tømmer køen.
	lea	(tmpmsgheader,NodeBase),a3
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d5 ; siste melding i conf
	move.l	d5,(HighMsgQueue,NodeBase)
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d2,d0			; Henter conferanse nr.
	mulu	#Userconf_seizeof/2,d0
	move.l	(uc_LastRead,a0,d0.l),d4 ; Siste vi leste
	addq.l	#1,d4
	cmp.l	d4,d5
	bcs	9$
	move.l	d5,d0
	move.l	#NumMsgNrInQueue-100,d1	; setter av plass til litt marking
	cmpi.l	#1,d4			; er det første gangen her ?
	bne.b	4$			; Nei, dvs ikke max scan
;	beq.b	5$			; ja, dvs max scan
;	btst	#31,d2			; skal vi ta max scan ?
;	beq.b	4$			; nei
5$	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	d2,d1			; Henter conferanse nr.
	mulu	#ConferenceRecord_SIZEOF/2,d1
	add.l	d1,a0
	moveq.l	#0,d1
	move.w	(n_ConfMaxScan,a0),d1	; henter maks scan verdien
	moveq.l	#1,d7			; vi har kuttet
4$	sub.l	d1,d0
	bcs.b	1$			; ikke for mange
	cmp.l	d4,d0			; Er det for mange ?
	bls.b	1$			; nei
	move.l	d0,d4			; Kutter ut for gamle meldinger.
	addq.l	#1,d7			; vi har kuttet
1$	cmp.l	d4,d5
	bcs.b	9$
	move.w	d2,d1
	move.l	d4,d0
	move.l	a3,a0
	jsr	(loadmsgheader)
	beq.b	2$
	lea	(errloadmsghtext),a0
	bsr	writetexti
	bra.b	9$
2$	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive
	bne.b	3$
	move.l	d4,d0
	bsr	findinqueue
	bne.b	3$
	move.l	d4,(0,a2,d3.l)
	addq.l	#4,d3
	moveq.l	#0,d0
	move.l	d0,(0,a2,d3.l)
	move.l	(Usernr+CU,NodeBase),d1
	cmp.l	(MsgTo,a3),d1
	bne.b	3$
	addq.l	#1,d6
3$	addq.l	#1,d4
	bra.b	1$
9$	moveq.l	#0,d0
	move.l	d0,(0,a2,d3.l)		; Markerer slutten på køen.
	move.l	d3,d0
	move.l	d6,d1
	cmpi.l	#2,d7			; var det max scan som slo til
	bne.b	99$			; nei
	bset	#31,d1			; setter bit'et som markering at vi har kuttet
99$	pop	a2/a3/d2-d7
	lsr.l	#2,d0
	rts

gettopqueue
	move.l	(msgqueue,NodeBase),d0
	rts

removefromqueue
	lea	(msgqueue,NodeBase),a0
1$	move.l	(a0)+,d1
	beq.b	9$
	cmp.l	d0,d1
	bne.b	1$
2$	move.l	(a0)+,(-8,a0)
	bne.b	2$
9$	rts

findlowestinqueue
	moveq.l	#-1,d0
	lea	(msgqueue,NodeBase),a0
1$	move.l	(a0)+,d1
	beq.b	9$
	cmp.l	d0,d1
	bcc.b	1$
	move.l	d1,d0
	bra.b	1$
9$	moveq.l	#-1,d1
	cmp.l	d1,d0
	rts

findinqueue
	lea	(msgqueue,NodeBase),a0
1$	move.l	(a0)+,d1
	beq.b	9$
	cmp.l	d0,d1
	bne.b	1$
	clrz
9$	rts

findnumberinque
	lea	(msgqueue,NodeBase),a0
	moveq.l	#-1,d0
1$	addq.l	#1,d0
	move.l	(a0)+,d1
	bne.b	1$
	rts

; får msgheader i a0
insertinqueue
	move.l	(Number,a0),d0
insertinqueuenr
	lea	(msgqueue,NodeBase),a0
	move.l	a0,a1
1$	move.l	(a0)+,d1
	beq.b	2$
	cmp.l	d0,d1
	bne.b	1$
	rts
2$	move.l	#NumMsgNrInQueue*4,d1
	adda.l	d1,a1
	cmpa.l	a0,a1				; Er det plass ?
	bls.b	9$				; nope. (burde kanskje slette eldste ??)
	move.l	d0,(-4,a0)
	moveq.l	#0,d0
	move.l	d0,(a0)
9$	rts

login	move.w	#24,(PageLength+CU,NodeBase)
	move.w	#-1,(linesleft,NodeBase)	; Vi vil ikke ha noen more her..
	tst.b	(Tinymode,NodeBase)		; er det tiny mode ?
	bne.b	8$				; ja, hopper over cls'en
	lea	(ansiclearsctext),a0		; foretar en cls
	bsr	writecontext
	lea	(ansiwhitetext),a0
	bsr	writecontext
8$	lea	(systemtext1),a0		; skriver ut system teksen :
	bsr	writetext			; "abbs <version> node #<nr> <speed>"
	move.w	(NodeNumber,NodeBase),d0
	bsr	skrivnrw
	move.b	#' ',d0
	bsr	writechar
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)
	bne	5$
	ENDC
	lea	(localtext),a0
	bsr	writetexto
	IFND DEMO
	bra.b	6$
5$	move.l	(nodenoden,NodeBase),a0
	move.l	(Nodespeed,a0),d0
	bsr	skrivnr
	lea	(systemtext2),a0
	bsr	writetexto
	ENDC
6$
	IFND DEMO
	lea	(serialnrtext),a0			; skriver ut serie nummeret
	bsr	writetext
	move.l	#sn+6,d0
	moveq.l	#6,d1
	sub.l	d1,d0
	bsr	writenrrfill
	bsr	outimage
	ENDC
	bsr	outimage			; nl
	lea	(loginfilename),a0		; skriver ut loginfile
	moveq.l	#0,d0
	bsr	typefile
	bsr	startsleepdetect1		; starter opp sleep timer'en
1$	bsr	getloginname			; henter loginavnet
	beq	99$
	move.l	a0,-(sp)
	jsr	(checkillegalnamechar)
	move.l	(sp)+,a0
	beq.b	1$
	move.l	a0,-(sp)
	bsr	testiso
	move.l	(sp)+,a0
	beq.b	11$
	lea	(musthaveisotext),a0
	bsr	writetexti
	bra.b	1$
11$	move.l	a0,-(sp)
	lea	(CU,NodeBase),a1
	jsr	(loaduser)
	beq	4$
	bpl.b	13$
	lea	(loadusererrtext),a0
	bsr	writeerroro
	clrz
	setn
	bra	9$
13$	bsr	outimage
	move.l	(sp)+,a0
	bsr	writetext
	lea	(isnotregtext),a0
	bsr	writetexto
2$	lea	(typernltext),a0
	bsr	writetexti
	moveq.l	#1,d0
	bsr	getline
	bne.b	65$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bra	1$
65$	move.b	(a0),d0
	bsr	upchar
	cmpi.b	#'R',d0
	beq	registeruser
	cmpi.b	#'L',d0
	beq	99$
	cmpi.b	#'N',d0
	bne.b	2$
	move.b	#0,(readlinemore,NodeBase)	; flusher input
	bra	1$

4$	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_Killed,d0
	beq.b	3$
	lea	(tuserkilledtext),a0
	bsr	writetexti
	setz
	bra	31$
3$	tst.b	(readlinemore,NodeBase)		; er det mere ??
	beq.b	7$				; nope
	bsr	readline			; leser inn mere
	move.b	(a0),d0
	bsr	upchar
	cmpi.b	#'Q',d0				; er det bare en Q ?
	bne.b	14$
	move.b	(1,a0),d0
	bne.b	32$
	bset	#DIVB_QuickMode,(Divmodes,NodeBase) ; enabler Quick Mode!! (TADA) :-)
	tst.b	(readlinemore,NodeBase)		; er det mere ??
	beq.b	7$				; nope
	bsr	readline			; leser inn mere
	move.b	(a0),d0
	bsr	upchar
14$	cmpi.b	#'S',d0				; er det bare en S ?
	bne.b	32$
	move.b	(1,a0),d0
	bne.b	32$
	bset	#DIVB_StealthMode,(Divmodes,NodeBase) ; enabler Stealth Mode!! (TADA) :-)
	tst.b	(readlinemore,NodeBase)		; er det mere ??
	beq.b	7$				; nope
	bsr	readline			; leser inn mere
32$	lea	(CU,NodeBase),a1
	bsr	checkpasswd
	notz
	bne.b	999$
	lea	(wrongtext),a0
	bsr	writetexto
7$	moveq.l	#2,d0
	lea	(CU,NodeBase),a0
	bsr	newgetpasswd
	bne.b	999$
	tst.b	(readcharstatus,NodeBase)	; Har det skjedd noe ?
	notz
	beq.b	9$				; jepp
	lea	(failedpwfname),a0
	moveq.l	#0,d0
	jsr	(typefilemaybeall)
	tst.b	(readcharstatus,NodeBase)	; Har det skjedd noe ?
	notz
	beq.b	9$				; jepp
	lea	(wantolcomentext),a0
	suba.l	a1,a1
	moveq.l	#0,d0				; n er default
	bsr	getyorn
	beq.b	12$
	jsr	GetCommentUserNr
	move.l	d0,d1
	move.w	#2,d0
	jsr	(comentditsamecode)		;
12$	move.b	#Thrownout,(readcharstatus,NodeBase)
	setz
31$
9$	move.l	(sp)+,a0
99$	rts

999$	btst	#DIVB_StealthMode,(Divmodes,NodeBase)	; er Stealth Mode slått på ?
	beq.b	9991$					; nei, gå videre
	bsr	justchecksysopaccess			; Er vi sysop ?
	bne.b	9993$					; Ja, ok.
	tst.b	(CommsPort+Nodemem,NodeBase)		; Lokal node ?
	bne.b	9992$					; nope, slå av igjen
9993$	move.l	(nodenoden,NodeBase),a0			; slår stealth på ordenelig
	ori.b	#NDSF_Stealth,(Nodedivstatus,a0)	; marker for andre også
	bra.b	9991$
9992$	bclr	#DIVB_StealthMode,(Divmodes,NodeBase)	; slår av igjen Stealth Mode
9991$	clrz
	bra.b	9$

hangup	lea	(logouttext),a0
	bsr	writetexti
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)
	bne.b	1$
	ENDC
	rts
	IFND DEMO
1$
dohangup
	move.l	(FrontDoorMsg,NodeBase),d0	; Har vi en frontmelding ?
	beq.b	1$				; nei.
	move.l	d0,a0
	move.w	(f_Flags,a0),d0			; skal vi ta hangup ?
	andi.w	#f_flagsF_NoHangup,d0
	bne.b	9$				; Nei...
1$	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0		; Nullmodem ?
	bne.b	9$				; Ja, ingen hangup
	andi.w	#SETUPF_SimpelHangup,d0
	bne.b	2$
	tst.b	(Tinymode,NodeBase)		; tiny mode ?
	bne.b	3$				; ja, ingen console output
	lea	(dohanguptext),a0
	jsr	(writecontext)
3$	bsr	tmpcloseserport
	moveq.l	#3,d0
	bsr	waitsecs
	bra	tmpopenserport
2$	moveq.l	#2,d0
	bsr	waitsecs
	bsr	waitseroutput
	lea	(plussplussptext),a0
	bsr	serwritestringdo
	moveq.l	#4,d0
	bsr	waitsecs
	lea	(ModemOnHookString+Nodemem,NodeBase),a0
	bsr	serwritestringdo
	moveq.l	#2,d0
	lea	(transnltext),a0
	bsr	serwritestringlendo
	moveq.l	#4,d0
	bra	waitsecs
9$	rts

tmpcloseserport
	bsr	waitseroutput
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	CloseDevice
	move.l	(sreadreq,NodeBase),a1
	moveq.l	#0,d0
	move.l	d0,(IO_DEVICE,a1)
	rts

tmpopenserport
	lea	(Serialdevicename+Nodemem,NodeBase),a0
	move.l	(sreadreq,NodeBase),a1
	moveq.l	#0,d0
	move.b	(RealCommsPort,NodeBase),d0
	subq.l	#1,d0

	move.w	(Setup+Nodemem,NodeBase),d1
	move.b	#0,(IO_SERFLAGS,a1)		; Null stiller.
;	btst	#SETUPB_XonXoff,d1		; Vi tilater ikke XonXoff lenger
;	bne.b	8$
	move.b	#SERF_XDISABLED|SERF_RAD_BOOGIE|SERF_SHARED,(IO_SERFLAGS,a1)
8$	btst	#SETUPB_RTSCTS,d1
	beq.b	9$
	ori.b	#SERF_7WIRE,(IO_SERFLAGS,a1)
9$	moveq.l	#0,d1
	jsrlib	OpenDevice
	tst.l	d0
	beq	2$				; Ops. Klarte ikke å åpne igjen.
	move.b	#-1,(RealCommsPort,NodeBase)	; Gjør noden lokal.
	rts
2$	move.l	(swritereq,NodeBase),a1
	move.l	(sreadreq,NodeBase),a0
	move.l	(IO_DEVICE,a0),(IO_DEVICE,a1)
	move.l	(IO_UNIT,a0),(IO_UNIT,a1)
	move.l	(sreadreq,NodeBase),a1
	move.w	#CMD_CLEAR,(IO_COMMAND,a1)	; flush'er bufferen
	jsrlib	DoIO
	move.l	(swritereq,NodeBase),a1
	move.w	#CMD_CLEAR,(IO_COMMAND,a1)	; flush'er bufferen
	jsrlib	DoIO
	bra	setserparam
	ENDC

drawwaitforcallerscreen
	tst.b	Tinymode(NodeBase)		; tiny mode ?
	bne.b	9$				; jepp, ingen output
	move.b	#15,d0				; skriver ut en CTRL-O (reset av tegnsett)
	bsr	writeconchar
	lea	(conmenufile),a0
	moveq.l	#1,d0
	bsr	typefile
	lea	(boardstatfilena),a0
	moveq.l	#1,d0
	bsr	typefilenoerror
	lea	(ansiwhitetext),a0
	bsr	writecontext
9$	rts

;d0 = byte med status som skal returneres fra waitforcaller
;	Foreløpig er det bare Z som brukes. Z=0 normal, Z=1 : resycle node
exitwaitforcaller
	move.b	#0,(in_waitforcaller,NodeBase)
	move.l	(waitforcallerstack,NodeBase),sp
	tst.b	d0
	rts

initwaitforcaller
	move.b	#1,(in_waitforcaller,NodeBase)
initwaitforcaller1
	move.b	#0,(readcharstatus,NodeBase)	; for sikkerhetskyld..
	bsr.b	drawwaitforcallerscreen
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal node ?
	beq.b	1$				; jepp, ingen init
	bsr	serclear
	btst	#DoDivB_NoInit,(DoDiv,NodeBase)	; skal vi ta init ?
	bne.b	2$				; nope
	bsr	wf_initmodem
	lea	(failedtoinitext),a0
	bne.b	3$				; vi klarte det ikke
2$	lea	(waitforcalltext),a0
3$	tst.b	(Tinymode,NodeBase)
	bne.b	1$
	bsr	writecontext
	ENDC
1$	bra	initcsreadcheck

;f1 = login user
;f2 = login sysop		shift = quick
;f3 = stealth login		shift = quick
;f8 = hack connect
;f9 = release serial port	shift = busy
;f10 = shutdown node		shift = busy
; fra port: Init modem, Release serial port, Off hook
; fra Arexx: unlisten, resume, shutdown, suspend
; returnerer z=1, recycle node'n

waitforcaller
	move.l	sp,(waitforcallerstack,NodeBase)
	bsr	initwaitforcaller

; Tar en (semi) readchar
1$	move.l	(gotbits,NodeBase),d0		; har vi noe fra før ?
	bne.b	2$				; ja
	move.l	(waitbits,NodeBase),d0		; det hadde vi ikke, så da
	jsrlib	Wait				; venter vi
	move.l	d0,(gotbits,NodeBase)		; husker de vi fikk

2$	bsr	testdoconsole
	beq.b	3$
	bsr	doconsole
	beq.b	1$				; det var ikke noe
	bsr	testclosestatus
	bpl.b	1$				; Kun F taster..
	cmp.b	#2,(in_waitforcaller,NodeBase)	; Skal vi sove ?
	beq.b	1$				; jepp. dropp input
	cmpi.b	#9,d0				; F10 - shutdown
	beq	21$
	cmpi.b	#19,d0				; s F10 - shutdown w/ busy
	beq.b	22$
	btst	#DoDivB_Sleep,(DoDiv,NodeBase)	; sleep igang ?
	bne.b	1$				; jepp.. dropp input
	bsr	wf_doconkeys
	bra.b	1$				; loop'er...
22$	moveq.l	#0,d0
21$	bsr	wf_shutdown
	moveq.l	#0,d0
	bra	exitwaitforcaller

3$	bsr	testdoserial
	beq.b	4$
	bsr	doserial
	bne.b	31$
	bmi.b	1$		; n -> loop.
31$	cmp.b	#2,(in_waitforcaller,NodeBase)	; Skal vi sove ?
	beq.b	1$				; jepp. dropp input
	btst	#DoDivB_Sleep,(DoDiv,NodeBase)	; har vi sleep
	bne.b	1$				; da vil vi ikke ha noe
	bsr	wf_trytoconnect
	beq	32$
	moveq.l	#1,d0
	bra	exitwaitforcaller
32$	bsr	initwaitforcaller1
	bra	1$


4$	bsr	testdointuition
	beq.b	5$
	bsr	dointuition
	bra	1$				; kan ikke bli kastet ut her..

5$	move.l	(intersigbit,NodeBase),d0	; sletter dette bit'et
	or.l	(timer2sigbit,NodeBase),d0	; timer
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)

	bsr	testdopublicport
	beq.b	6$
	bsr	handlepublicport
	beq.b	51$
	moveq.l	#0,d0
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	notz
	bne	1$				; fortsetter
	bra.b	52$
51$	btst	#DoDivB_ExitWaitforCaller,(DoDiv,NodeBase) ; skal vi ned ?
	beq	1$				; fortsetter
	bclr	#DoDivB_ExitWaitforCaller,(DoDiv,NodeBase) ; disarmerer
	moveq.l	#0,d0
	tst.b	(ShutdownNode,NodeBase)		; skal vi ned ?
	bne.b	52$				; ja, ut.
	moveq.l	#1,d0
52$	bra	exitwaitforcaller

6$	bsr	testshowwinsig
	beq	1$
	bsr	closeshowuserwindow
	bra	1$

testclosestatus
	move.l	d0,a0			; husker d0
	jsrlib	GetCC
	move.b	(RealCommsPort,NodeBase),d1
	beq	1$			; ingen port
	cmp.b	#-1,d1
	beq.b	1$			; ingen port..
	move.l	(sreadreq,NodeBase),a1
	move.l	(IO_DEVICE,a1),d1
	bne.b	1$			; fortsett som før
	move.w	d0,ccr
	bpl.b	2$			; prøver og åpne
	move.l	a0,d0
	cmpi.b	#9,d0			; er det F10 ?
	beq.b	3$			; jepp
	cmpi.b	#19,d0			; eller shift F10 ?
	bne.b	2$			; nope, åpner
3$	move.b	#-1,(RealCommsPort,NodeBase)	; Gjør noden "lokal".
	moveq.l	#1,d0				; no busy (kan ikke ta busy)
	bsr	wf_shutdown
	moveq.l	#0,d0
	bra	exitwaitforcaller

2$	bsr	tmpopenserport
	cmpi.b	#-1,(RealCommsPort,NodeBase)	; gikk det bra ?
	bne.b	4$				; jepp
	push	a6
	move.l	(intbase),a6
	jsrlib	DisplayBeep
	pop	a6
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Vi prøver en gang til.
	move.b	d0,(RealCommsPort,NodeBase)
	tst.b	(Tinymode,NodeBase)
	bne.b	5$
	lea	(ureopensertext),a0
	bsr	writecontext
	bra.b	5$
4$	move.b	(RealCommsPort,NodeBase),(CommsPort+Nodemem,NodeBase)		; setter tilbake
	bsr	aapnemodem
	bsr	initwaitforcaller1
5$	clrz					; får oss til å loop'e igjen.
	bra.b	9$

1$	move.w	d0,ccr
	exg.l	d0,a0
9$	rts

;d0 = key number
wf_doconkeys
	cmpi.b	#0,d0				; F1 ? - User login
	bne.b	1$				; nei..
	bsr	wf_makenodelocal
	moveq.l	#1,d0
	bra	exitwaitforcaller

1$	cmpi.b	#1,d0				; F2 ? - Sysop login
	beq.b	11$
	cmpi.b	#11,d0				; s F2 ? - Sysop login quick
	bne.b	2$				; nei.
	bset	#DIVB_QuickMode,(Divmodes,NodeBase) ; enabler Quick Mode!! (TADA) :-)
11$	lea	(SYSOPname+CStr,MainBase),a0
	lea	(CU,NodeBase),a1
	jsr	(loaduser)
	bne.b	12$				; error loading user
	bsr	wf_makenodelocal
	bsr	initrunlate
	move.w	#-1,(linesleft,NodeBase)	; forhindrer more prompt
	move.b	#0,(in_waitforcaller,NodeBase)
	move.l	(waitforcallerstack,NodeBase),sp
	move.l	#sysoploginjmp,(a7)		; Forandrer returverdi..
	rts					; .... og bruker
12$	lea	(usernotfountext),a0
	bsr	writeerroro
	moveq.l	#0,d0
	bra	exitwaitforcaller

2$	cmpi.b	#2,d0				; F3 ? - Stealth login
	beq.b	21$				; nei.
	cmpi.b	#12,d0				; s F3 ? - Stealth login quick
	bne.b	3$				; nei.
	bset	#DIVB_QuickMode,(Divmodes,NodeBase) ; enabler Quick Mode!! (TADA) :-)
21$	bset	#DIVB_StealthMode,(Divmodes,NodeBase) ; enabler Stealth Mode!! (TADA) :-)
	move.l	(nodenoden,NodeBase),a0
	ori.b	#NDSF_Stealth,(Nodedivstatus,a0)	; marker for andre også
	bra.b	11$				; utfører så vanelig sysop login

3$	cmpi.b	#7,d0				; F8 ? - hack connect
	bne.b	4$				; nei.
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal ?
	beq	9$				; meningsløst..
	bra	wf_trytoconnectatadir		; hopper på ATA
	ELSE
	bra.b	9$
	ENDC

4$	cmpi.b	#8,d0				; F9 - release serial port
	beq.b	41$
	cmpi.b	#18,d0				; with busy
	bne.b	9$				; ukjennt tast, ut
	moveq.l	#1,d0				; husker at det er busy
	bra.b	43$
41$	moveq.l	#0,d0
43$	bsr	wf_makenodelocal1
	beq.b	9$				; lokal node, ut
42$	bsr	tmpcloseserport
	lea	(preskreopentext),a0
	tst.b	(Tinymode,NodeBase)
	bne.b	9$
	bsr	writecontext
;	bra.b	9$
9$	rts

; d0 = true -> no busy
wf_shutdown
	move.b	#1,(ShutdownNode,NodeBase)
	tst.l	d0
	bne.b	9$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal ?
	beq.b	9$				; ja
	bsr	stengmodem			; stenger noden
	ENDC
9$	moveq.l	#0,d0
	bra	exitwaitforcaller

wf_initmodem
	tst.b	(Tinymode,NodeBase)		; tiny ?
	bne.b	1$				; jepp, ingen output
	lea	(initmodemtext),a0		; sier hva vi gjør
	bsr	writecontext
1$	move.l	(NodeBaud+Nodemem,NodeBase),d0
	moveq.l	#1,d1				; send AT
	bsr	setserialspeed
	bsr	sendinitstr
	rts

wf_trytoconnectatadir
	setz
	bra	wf_trytoconnect1
wf_trytoconnect
	clrz
wf_trytoconnect1
	beq	3$				; vi skal rett til ATA
	move.w	(Setup+Nodemem,NodeBase),d1
	btst	#SETUPB_NullModem,d1		; Nullmodem ?
	beq.b	1$				; Nei, vanelig innlogging

	move.l	d2,-(sp)
	move.l	(NodeBaud+Nodemem,NodeBase),d2	; Setter opp baud
	move.l	d2,d0
	divu.w	#10,d0
	move.w	d0,(cpsrate,NodeBase)
	move.l	d2,d0
	bsr	changenodestatusspeed
	bsr	initserread
	move.l	(sp)+,d2
	clrz
	bra	9$				; vi klarte det!! :-)

1$	cmp.b	(ModemRingString+Nodemem,NodeBase),d0	; passer det ?
	beq.b	2$				; jepp
	lea	(tmptext,NodeBase),a0
	moveq.l	#-1,d0				; Les 1 tegn. Ignorer CD
	moveq.l	#0,d1
	bsr	serreadt
	cmpi.b	#1,d0				; fikk vi et ?
	bne	8$				; nope, timeout
	move.b	(tmptext,NodeBase),d0
	bra.b	1$
2$	move.l	#1000000,d1			; 1 sek timeout mellom tegnene
	jsr	(serreadword)
	beq	9$				; gir opp.
	move.l	d0,-(sp)
	lea	(ModemRingString+Nodemem,NodeBase),a1
	exg	a0,a1
	bsr	strlen
	move.l	(sp)+,d1
	cmp.l	d0,d1
	bne	8$				; feil lengde, gir opp
	lea	(ModemRingString+Nodemem,NodeBase),a0
	bsr	comparestringsfull
	bne	8$				; ligner ikke...

	tst.b	(Tinymode,NodeBase)		; tiny ?
	bne.b	3$				; ja
	lea	(ringdetecttext),a0		; sier ifra
	bsr	writecontext

3$	moveq.l	#1,d0				; delay
	bsr	waitsecs
	lea	(ModemAnswerString+Nodemem,NodeBase),a0 ; Sender ATA
	bsr	serwritestringdo
	lea	(transnltext),a0			; sender bare CR
	moveq.l	#1,d0
	bsr	serwritestringlendo

	push	d2/d3/a2/d4
	moveq.l	#0,d2
	moveq.l	#0,d4					; mnp/v42bis status
	move.b	(ConnectWait+Nodemem,NodeBase),d2	; Wait time
	cmp.b	#10,d2
	bhi.b	4$
	moveq.l	#30,d2					; Ingen. Tar default

4$	tst.b	(Tinymode,NodeBase)			; Skriver ut sek igjen.
	bne.b	5$
	lea	(waitconnecttext),a0
	bsr	writecontext
	move.l	d2,d0
	bsr	connrtotext
	bsr	writecontextlen
	move.b	#' ',d0
	bsr	writeconchar
5$	moveq.l	#1,d0					; venter 1 sek
	bsr	waitsecs
6$	lea	(tmptext,NodeBase),a0			; sjekker om det er et
	moveq.l	#-1,d0					; tegn klar for lesing,
	moveq.l	#0,d1					; og leser i så fall det.
	bsr	serreadt
	cmpi.b	#1,d0
	beq.b	7$					; ja, det var et tegn
	subq.l	#1,d2					; teller ned sekundene,
	bne.b	4$					; looper hvis det er flere
	bra	99$					; eller avbryter hvis ikke.

7$	move.b	(tmptext,NodeBase),d0			; henter ut lest tegn
	move.l	#1000000,d1				; 1 sek timeout pr tegn
	bsr	serreadstring				; Leser en string
	move.l	a0,a2
	bsr	writecontext				; skriver den ut
	move.l	a2,a0

	lea	(nocarriertext),a1			; NO CONNECT ?
	bsr	findtextinstring
	beq	99$					; ikke connect, ut
	move.l	a2,a0
	move.b	d4,d0
	bsr	parsemnpsub
	move.b	d0,d4					; husker ny mnp/v42bis status
	move.l	a2,a0
	lea	(ModemConnectString+Nodemem,NodeBase),a1
	bsr	findtextinstring
	bne.b	6$					; ikke connect, loop
	move.l	a0,a2					; huske etter connect

	tst.b	(Tinymode,NodeBase)
	bne.b	10$
	lea	(connectdetetext),a0
	bsr	writecontext

10$	cmp.b	#' ',(a2)+
	beq.b	10$
	subq.l	#1,a2

	move.l	a2,a0					; get connect speed
	bsr	atoi
	move.l	d0,d2
	move.l	a2,a0
	move.b	d4,d0
	bsr	parsemnpsub
	bsr	setmnpstat

	moveq.l	#2,d0
	bsr	waitsecs
	bsr	checkcarrier
	lea	(nocdsignaltext),a0
	beq.b	991$				; Nei, "NoCarrier"
	tst.l	d2				; noen hastighet ?
	bne.b	11$				; ja
	move.l	#300,d2				; nei, det betyr 300baud
11$	cmp.l	(MinBaud+Nodemem,NodeBase),d2	; Er det fort nok ?
	bcc.s	12$				; ja
	lea	(toslowtext1),a0
	bsr	writetext
	move.l	(MinBaud+Nodemem,NodeBase),d0
	bsr	skrivnr
	lea	(toslowtext2),a0
	bsr	writetexto
	lea	toslowconectext,a0
	bra.b	991$
12$	move.l	d2,d0
	divu.w	#10,d0
	move.w	d0,(cpsrate,NodeBase)
	move.l	d2,d0
	bsr	changenodestatusspeed
	move.l	d2,d0
	moveq.l	#0,d1				; ikke send AT
	bsr	setserialspeed
	bsr	initserread
	pop	d2/d3/d4/a2
	setz
8$	notz
9$	rts

99$	lea	(faildconnectext),a0
991$	pop	d2/d3/d4/a2
	bsr	writelogtexttime
	bsr	hangup
	setz
	bra	9$

wf_makenodelocal
	moveq.l	#1,d0
; d0 = TRUE -> set busy
wf_makenodelocal1
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal ?
	beq.b	9$				; jepp. nop
	move.b	#0,(CommsPort+Nodemem,NodeBase)	; Gjør noden lokal.
	tst.l	d0
	beq.b	1$
	bsr	stengmodem
1$	moveq.l	#0,d0				; lokal.
	bsr	changenodestatusspeed
	ENDC
	clrz
9$	rts

; a0 = string
; d0 = forige mnp/v42bis stat
parsemnpsub
	push	a2/d2
	move.l	a0,a2
	move.b	d0,d2
	cmp.b	#NECSF_V42BIS,d2	; allerede v42bis ?
	beq.b	9$			; Ja, parser ikke mere

	lea	(v42bistext),a1
	bsr	findtextinstring
	beq.b	1$			; V42bis
	move.l	a2,a0
	lea	(v42shorttext),a1
	bsr	findtextinstring
	beq.b	1$			; V42bis

	move.l	a2,a0			; Hack for gamle USR modemer.
	lea	(hsthsttext),a1		; er det 9600, og vi har /HST/HST, så
	bsr	findtextinstring	; er det egentlig 14400 baud.
	bne.b	4$			; Nope. Ikke /HST/HST
	move.l	(nodenoden,NodeBase),a0
	move.l	(Nodespeed,a0),d0
	cmpi.l	#9600,d0
	bne.b	4$			; nope, ikke 9600
	move.l	#14400,d0		; gjør om til 14400.
	bsr	changenodestatusspeed
	move.w	#1440,(cpsrate,NodeBase)

4$	move.l	a2,a0
	lea	(mnptext),a1
	bsr	findtextinstring
	beq.b	2$			; MNP
	move.l	a2,a0
	lea	(arqtext),a1
	bsr	findtextinstring
	beq.b	2$			; MNP
	move.l	a2,a0
	lea	(reltext),a1
	bsr	findtextinstring
	bne.b	9$			; MNP
2$	move.b	#NECSF_MNP,d2
	bra.b	9$
1$	move.b	#NECSF_V42BIS,d2
9$	move.b	d2,d0
	pop	a2/d2
	rts

; d0 = mnp/v42bis status
setmnpstat
	move.l	(nodenoden,NodeBase),a0
	bset	#NECSB_UPDATED,d0			; Sier at den er updated ?
	move.b	d0,(NodeECstatus,a0)
	rts

checkintermsgs			; race fare ... Ikke helt god.
	jsrlib	Forbid
	move.l	(nodenoden,NodeBase),a0
	move.w	(InterMsgread,a0),d0
	move.w	(InterMsgwrite,a0),d1
	jsrlib	Permit
	sub.w	d0,d1
	beq.b	9$					; ingen node meldinger.
	bcc.b	1$					; ingen wrap
	addi.w	#MaxInterNodeMsg,d1
	beq.b	9$					; ingen node meldinger.
1$	push	a2/a3/d2/d3/d4/d5/d6
	move.l	d0,d2					; d2 - startpos
	move.l	d1,d3					; d3 - antall meldinger
	move.l	a0,a2
	lea	(InterNodeMsg,a2),a3			; skriver ut alle
	moveq.l	#InterNodeMsgsiz,d4
	move.l	d2,d5
	mulu.w	d4,d5
	moveq.l	#0,d6					; har ikke skrevet ut noen
	subi.w	#1,d3
4$	lea	(0,a3,d5.w),a0
	bsr	writeintermsg
	beq.b	5$
	moveq.l	#1,d6					; har skrevet ut
5$	addq.l	#1,d2
	cmpi.w	#MaxInterNodeMsg,d2
	bcs.b	2$
	moveq.l	#0,d2					; wrap'er rundt
	moveq.l	#0,d5
	bra.b	3$
2$	add.w	d4,d5
3$	dbf	d3,4$
	move.l	(nodenoden,NodeBase),a0
	move.w	(InterMsgwrite,a0),(InterMsgread,a0)	 ; nullstiller
	move.l	d6,d0
	pop	a2/a3/d2/d3/d4/d5/d6
9$	rts

;type
; 0	20	From #1: Login <name>
; 1	20	From #1: Logout <name>
; 2	40	From #1: <tekst>
; 3a	10	From #1: <conf> message <nr> to <to name> entered by <from name>.
; 3b	10	From #1: You have mail! (from <navn>)
; 4	50	From #1: Chat request. Answer with chat <g> 1
writeintermsg
	push	a2/d2
	link.w	a3,#-100
	move.l	a0,a2
	move.w	(i_franode,a2),d1
	move.w	(NodeNumber,NodeBase),d0
	cmp.w	d0,d1			; Fra denne noden ?
	beq	9$			; Ja. Fy. (skal egentlig ikke skje, men ...)
	move.b	(userok,NodeBase),d0	; er brukeren inne ?
	beq	9$			; nei, dropper disse.

	moveq.l	#0,d1
	move.b	(i_pri,a2),d0		; er det en prioritet melding ?
	bne.b	5$			; ja, ikke noe filternivå da..
	move.b	(MessageFilterV+CU,NodeBase),d1	; henter filternivået

5$	move.b	(i_type,a2),d0
	beq	0$			; login
	subq.b	#1,d0
	beq	1$			; logout
	subq.b	#1,d0
	beq	2$			; node melding
	subq.b	#1,d0
	beq	3$			; melding melding
	subq.b	#1,d0
	bne	9$			; ukjent melding. Vi hopper ut.

	cmpi.b	#50,d1			; for høyt nivå ?
	bcc	9$			; ja
	bsr	outimage		; newline først
	beq	9$
	lea	(ansilbluetext),a0	; Sikrer blå skrift
	bsr	writetext
	move.l	sp,a1
	bsr	10$			; chat request
	lea	(chatreqanswtext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	a1,a0
	moveq.l	#0,d0
	move.w	(i_franode,a2),d0
	bsr	konverter
	bra	8$

3$	cmpi.b	#10,d1			; for høyt nivå ?
	bcc	9$			; ja
	move.w	(i_conf,a2),d0
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Read,d0		; Er vi medlem her ?
	beq	9$			; nei. ikke mere..
	bsr	outimage		; newline først
	beq	9$
	lea	(ansilbluetext),a0	; Sikrer blå skrift
	bsr	writetext
	move.l	sp,a1
	bsr	10$			; melding melding
	move.l	(i_usernr2,a2),d0
	cmp.l	(Usernr+CU,NodeBase),d0	; er det melding til oss ???
	bne.b	31$			; Nei, da er det vanelig
	lea	(youhavemailtext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(i_Name,a2),a0
	bsr	strcopy
	move.b	#')',(-1,a1)
	move.b	#' ',(a1)+
	move.w	(i_conf,a2),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
	bsr	strcopy
	move.b	#0,(a1)
	bra	8$
31$	move.w	(i_conf,a2),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
	bsr	strcopy
	subq.l	#1,a1
	lea	(msgtext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	(i_msgnr,a2),d0
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	lea	(tonoansitext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(i_Name2,a2),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(enteredbytext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(i_Name,a2),a0
	bsr	strcopy
	move.b	#'.',(-1,a1)
	move.b	#0,(a1)
	bra	8$

2$	cmpi.b	#40,d1			; for høyt nivå ?
	bcc	9$			; ja
	bsr	outimage		; newline først
	beq.b	9$
	lea	(ansilbluetext),a0	; Sikrer blå skrift
	bsr	writetext
	move.l	sp,a1
	bsr.b	10$			; node melding
	lea	(i_msg,a2),a0
	bsr	strcopy
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Lokal node ?
	bne.b	21$				; ja, da er carrier ok :-)
	ENDC
	move.l	(intbase),a6
	suba.l	a0,a0
	jsrlib	DisplayBeep
	move.l	(exebase),a6
21$	bra.b	8$

1$	lea	(interlogouttext),a0	; logout
	bra.b	101$
0$	lea	(interlogintext),a0	; login
101$	cmpi.b	#20,d1			; for høyt nivå ?
	bcc.b	9$			; ja
	move.l	a0,d2
	bsr	outimage		; newline først
	beq.b	9$
	lea	(ansilbluetext),a0	; Sikrer blå skrift
	bsr	writetext
	move.l	sp,a1
	bsr.b	10$
	move.l	d2,a0
	bsr	strcopy
	subq.l	#1,a1
	move.b	#'-',(a1)+
	move.b	#' ',(a1)+
	lea	(i_Name,a2),a0
	bsr	strcopy
;	bra.b	8$

8$	move.l	sp,a0
	bsr	writetexti
	clrz
	bra.b	99$
9$	setz
99$	unlk	a3
	pop	a2/d2
	rts

10$	lea	(fromhashtext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.w	(i_franode,a2),d0
	move.l	a1,a0
	bsr	konverterw
	move.l	a0,a1
	lea	(kolonspacetext),a0
	bsr	strcopy
	subq.l	#1,a1
	rts

; a0 = msgheader
; d0 = confnr
; a1 = msgtext hvis det er net melding
sendintermsgmsg
	push	a2/d2/a3
	move.l	a0,a3
	move.l	a1,d2				; husker msgtext'en
	btst	#DIVB_StealthMode,(Divmodes,NodeBase) ; er Stealth Mode på ?
	bne.b	9$				; jepp. dropper den node meldingen.
	move.l	(Tmpusermem,NodeBase),a1
	move.l	(Number,a3),(i_msgnr,a1)
	move.w	d0,(i_conf,a1)
	move.l	(MsgFrom,a3),(i_usernr,a1)
	move.l	(MsgTo,a3),(i_usernr2,a1)
	move.l	a1,a2
	move.l	a3,a0
	move.l	d2,a1
	bsr	getfromname
	bne.b	1$				; ikke net navn
	moveq.l	#-1,d0
	move.l	d0,(i_usernr,a2)		; setter fra all, for å forhindre at noen får to yo..
1$	lea	(i_Name,a2),a1
	bsr	strcopy
	move.l	a3,a0
	move.l	d2,a1
	bsr	gettoname
	bne.b	2$				; ikke net navn
	moveq.l	#-1,d0
	move.l	d0,(i_usernr2,a2)		; setter fra all, for å forhindre at noen får to yo..
2$	lea	(i_Name2,a2),a1
	bsr	strcopy
	move.l	a2,a0
	move.b	#3,(i_type,a0)				; enter msg
	move.w	(NodeNumber,NodeBase),(i_franode,a0)
	moveq.l	#0,d0					; Alle noder.
	move.b	#0,(i_pri,a0)
	bsr	sendintermsg
9$	pop	a2/d2/a3
	rts

docookie
	cmpi.b	#NoCarrier,(readcharstatus,NodeBase)
	beq	9$			; srkiver ikke noe da ..
	bsr	outimage
	lea	(cookiefilename),a0
	bsr	getfilelen
	beq	9$			; Ingen cookiefil.
	movem.l	d2-d4,-(a7)
	move.l	d0,d3
	move.l	(dosbase),a6
	lea	(tmptext,NodeBase),a0
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	#cookiefilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	3$
	moveq.l	#0,d2
	move.l	($dff004),d2
	lsl.l	#8,d2
	lea	(tmptext,NodeBase),a0
	add.l	(a0),d2
	add.l	(4,a0),d2
	add.l	(8,a0),d2
	move.l	d2,d0
	move.l	d3,d1
	bsr	divl
	move.l	d1,d2
;1$	cmp.l	d2,d3
;	bhi.b	2$
;	sub.l	d3,d2
;	bra.b	1$
2$	move.l	d4,d1
	moveq.l	#OFFSET_BEGINNING,d3
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d1,d0
	beq.b	5$
	move.l	d4,d1
	move.l	(tmpmsgmem,NodeBase),d2
	move.l	#4096,d3
	jsrlib	Read
	move.l	d0,d3
	beq.b	5$
	move.l	(tmpmsgmem,NodeBase),a0
7$	subq.l	#1,d3
	beq.b	5$
	andi.b	#$7f,(a0)
	cmpi.b	#$c,(a0)+
	bne.b	7$
	move.l	a0,a1		; a0 = cookie start
	moveq.l	#0,d0		; d0 = cookie len
6$	subq.l	#1,d3
	bcs.b	5$
	addq.l	#1,d0
	andi.b	#$7f,(a1)
	cmpi.b	#$c,(a1)+
	bne.b	6$
	movem.l	d0/a0,-(a7)
	move.l	d4,d1
	jsrlib	Close
	movem.l	(a7)+,d0/a0
	subq.l	#1,d0
	bcs.b	3$
	move.l	(exebase),a6
	moveq.l	#0,d1
	bsr	writetextmemi
	bra.b	99$
5$	move.l	d4,d1
	jsrlib	Close
3$	lea	(nocookietext),a0
	move.l	(exebase),a6
	bsr	writetexto
99$	movem.l	(a7)+,d2-d4
9$	rts

*****************************************************************
*			hi level i/o				*
*****************************************************************
;#b
;#c
; a0 = prompt
; a1 = helpfilename (null == nohelp)
; a2 = novoice ekstra help (0 = nohelp)
readlinepromptwhelpflush
	clr.b	(readlinemore,NodeBase)
readlinepromptwhelp
	push	a2/a3/d2/d3
	link.w	a3,#-160
	move.l	a3,d2
	move.l	a1,a3
	move.l	a2,d3			; husker evnt. ekstra hjelp
	lea	sp,a1
	jsr	(strcopy)
	subq.l	#1,a1
	tst.l	d3			; har vi lang text ?
	beq.b	3$			; nope
	move.b	(XpertLevel+CU,NodeBase),d0; skal de ha lang text ?
	cmpi.b	#2,d0
	bcc.b	3$			; Nope
	move.b	#' ',(a1)+
	move.l	d3,a0
	jsr	(strcopy)
	subq.l	#1,a1
3$	lea	kolonspacetext,a0
	jsr	(strcopy)
	move.l	sp,a2			; husker promptet.
	move.l	sp,a0
0$	bsr	readlineprompt
	beq.b	9$
	move.b	(a0),d0
	cmpi.b	#'?',d0
	bne.b	9$
	move.l	a3,d0
	lea	(sorrynohelptext),a0
	beq.b	1$
	move.l	d0,a0
	moveq.l	#0,d0			; både con og ser
	bsr	typefilemaybeall
	bra.b	2$
1$	bsr	writetexto
2$	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$
	move.l	a2,a0
	bra.b	0$
9$	move.l	d2,a3
	unlk	a3
	pop	a2/a3/d2/d3
	rts

;#c
readlinepromptflush
	clr.b	(readlinemore,NodeBase)
readlineprompt
	move.l	a0,(curprompt,NodeBase)
	tst.b	(readlinemore,NodeBase)
	bne.b	1$
	tst.b	Tinymode(NodeBase)
	bne.b	3$
	move.l	a0,-(a7)
	move.b	#15,d0					; skriver ut en CTRL-O (reset av tegnsett)
	bsr	writeconchar
	move.l	(a7)+,a0
3$	move.w	(linesleft,NodeBase),d0			; henter antall linjer før more
	cmpi.w	#2,d0					; Er det plass til prompt'et ?
	bhi.b	2$					; Ja
	move.w	#2,(linesleft,NodeBase)			; forhindrer more før prompt'et
2$	bsr	writetexti
1$	bsr	readline
	clr.l	(curprompt,NodeBase)
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	tst.w	d0
9$	rts

;#c
; d0 = 0, både ser og con, d0 != 0 bare con
typefilemaybeall
	push	d0
	bsr	getbestfilename
	pop	d0
	beq	typefile
	subq.l	#1,d1
	beq	typefileansi
	subq.l	#1,d1
	bra	typefileraw

;#c
	IFND DEMO
snumberrot	dc.l	snrcoded
snumber		dc.l	2
	ENDC

; a0 = filename
; d0 = 
;#c
typefilemaybeansi
	move.l	d0,-(a7)
	bsr	getbestfilename
	bne.b	1$
	move.w	(Userbits+CU,NodeBase),d0	; var det det at vi ikke ville ha noe annet?
	andi.w	#USERF_RAW|USERF_ANSIMenus,d0
	beq.b	1$			; ja. Da skriver plain tekst
	move.l	a0,a1
	move.l	a0,(a7)
	lea	(lognofiletext),a0
	bsr	writelogtexttimed
	lea	(filenotfountext),a0	; skriver ut feil
	bsr	writetext
	move.b	#' ',d0
	bsr	writechar
	move.l	(a7)+,a0
	bsr	writetext
	lea	(pltellsysoptext),a0
	bsr	writetexto
	bra.b	9$
1$	move.l	(a7)+,d0
	subq.l	#1,d1
	bcs	typefile
	beq	typefileansi
	subq.l	#1,d1
	bra	typefileraw
9$	rts

;#c
typefileraw
	move.l	d2,-(a7)
	move.b	(Charset+CU,NodeBase),d2		; hack som slår av oversetting
	move.b	#0,(Charset+CU,NodeBase)
	bsr	typefile
	sne	d0
	move.b	d2,(Charset+CU,NodeBase)
	move.l	d0,d2
	lea	(NormAtttext),a0		; sender ANSI reset.
	bsr	writetexti
	move.l	d2,d0
	move.l	(a7)+,d2
	tst.b	d0
	rts

;#c
typefileansi
	bsr	typefile
	sne	d0
	move.l	d0,-(a7)
	lea	(NormAtttext),a0		; sender ANSI reset.
	bsr	writetexti
	move.l	(a7)+,d0
	tst.b	d0
	rts

;#c
;a0 = filename
getbestfilename
	lea	(tmptext,NodeBase),a1
;a0 = filename
;a1 = buffer
getbestfilenamebuffer
	push	a2/d3/d4/d2/a3
	move.l	a0,a2
	move.l	a1,a3
	move.w	(Userbits+CU,NodeBase),d3
	btst	#USERB_RAW,d3			; raw ?
	beq.b	2$
	lea	(rawextension),a1
	move.l	a2,a0
	moveq.l	#2,d4				; husker raw
	bsr	10$
	move.l	a3,a0
	bne.b	1$
2$	btst	#USERB_ANSIMenus,d3		; ANSI ?
	beq.b	3$				; nei, feiler
	lea	(ansiextension),a1
	move.l	a2,a0
	moveq.l	#1,d4				; husker ansi
	bsr	10$
	move.l	a3,a0
	bne.b	1$
3$	move.l	a2,a0
	moveq.l	#0,d4				; ikke noe spes
1$	move.l	d4,d1
	pop	a2/d3/d4/d2/a3
	rts

10$	move.l	a1,-(a7)
	move.l	a3,a1
	bsr	strcopy
	subq.l	#1,a1
	move.l	(a7)+,a0
	bsr	strcopy
	move.l	a3,a0
	move.l	a0,d1
	move.l	(dosbase),a6
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.b	11$
	jsrlib	UnLock
	clrz
11$	move.l	(exebase),a6
	rts

;a0 = filename
;d0 : 1 , only con.
typefilenoerror
	push	a2/d2/d3
	move.l	a0,a2
	move.l	d0,d3

	move.l	(dosbase),a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	tst.l	d0
	beq.b	1$
	move.l	d0,d1
	jsrlib	UnLock
	move.l	(exebase),a6
	move.l	a2,a0
	move.l	d3,d0
	bsr	typefile
1$	move.l	(exebase),a6
	pop	a2/d2/d3
	rts

;a0 = filename
;d0 : 1 , only con.
typefile
	movem.l	d2-d6/a2,-(sp)
	cmpi.b	#NoCarrier,(readcharstatus,NodeBase)
	beq	9$			; skriver ikke noe da ..
	move.l	d0,d5
	beq.b	1$			; ikke bare con
	tst.b	(Tinymode,NodeBase)	; tinymode ?
	bne	9$			; ja, da er vi ferdige
1$	move.l	a0,a2			; husker navnet
	bsr	getfilelen
	bne.b	2$			; vi fant en fil
	lea	(filenotfountext),a0	; skriver ut feil
	bsr	writetext
	move.b	#' ',d0
	bsr	writechar
	move.l	a2,a0
	bsr	writetexti
	lea	(pltellsysoptext),a0
	bsr	writetexto
	sne	d2
	lea	(lognofiletext),a0
	move.l	a2,a1
	bsr	writelogtexttimed
	tst.b	d2
	bra.b	9$
2$	move.l	d0,d3
	move.l	(msgmemsize,NodeBase),d1
	cmp.l	d3,d1
	bcs.b	3$			; vi har for lite minne
	move.l	(tmpmsgmem,NodeBase),d4	; Bruker tmpmsgmem til copy space
	moveq.l	#0,d6			; Nei, vi har ikke allokert minne.
	bra.b	4$
3$	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	move.l	d0,d4
	beq.b	9$			; vi fikk inne noe mem
	move.l	d3,d6			; vi har allokert minne ..
4$	move.l	(dosbase),a6		; leser inn fil
	move.l	a2,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d4,d2
	move.l	d0,d4
	beq.b	7$
	move.l	d0,d1
	jsrlib	Read
	move.l	d4,d1
	move.l	d0,d4			; husker verdien
	jsrlib	Close
	cmp.l	d3,d4
	bne.b	8$			; error
	move.l	(exebase),a6
	move.l	d3,d0
	move.l	d2,a0
	move.l	d5,d1
	bsr	writetextmemi
	bne.b	7$
	bsr.b	10$
8$	setz
	bra.b	9$
7$	move.l	(exebase),a6
	bsr.b	10$
	clrz
9$	movem.l	(sp)+,d2-d6/a2
	rts

10$	move.l	d6,d0
	beq.b	11$
	move.l	d2,a1
	jmplib	FreeMem
11$	rts

writeerror
	clr.b	(readlinemore,NodeBase)		; flush'er input
	bsr	writetext
	rts

; OBS : Dropper tekst over 80 tegn !!!
writeerrori
	clr.b	(readlinemore,NodeBase)		; flush'er input
	bsr	writetext
	bra	breakoutimage

;#c
; OBS : Dropper tekst over 80 tegn !!!
writeerroro
	clr.b	(readlinemore,NodeBase)		; flush'er input
	bsr	writetext
	bra	outimage

;#c
writechar
	lea	(outtextbuffer,NodeBase),a0
	move.w	(outtextbufferpos,NodeBase),d1
	move.b	d0,(0,a0,d1.w)
	addq.w	#1,d1
	move.w	d1,(outtextbufferpos,NodeBase)
	cmpi.w	#160,d1
	bls.b	9$
	bra	breakoutimage
9$	rts


	XREF	_Hebbe
	XREF	_CheckTextMode

;#c
; OBS : Dropper tekst over 160 tegn !!!
writetextmsg
	move.l	a0,a1
	moveq.l	#-1,d0
1$	tst.b	(a1)+
	dbeq	d0,1$
	not.w	d0
	ext.l	d0
writetextlenmsg
;	jsr (_Hebbe)
	push	a2/d2/d3			; a2 er ansitext, d2 er mode
	subq.w	#1,d0
	move.w	d0,d3
	bcs	9$	; for kort!
	moveq	#0,d1
	lea	(outtextbuffer,NodeBase),a1
	move.w	(outtextbufferpos,NodeBase),d1
	cmpi.w	#160,d1
	bhi	2$
	adda.l	d1,a1

1$	cmpi.b	#'_',(a0)		; Underline
	bne	1000$			; nei
1006$	cmp.b	#1,(Underlinetab)	; Har vi på fra før?
	bne.b	1001$			; Nei

	move.b	#0,(Underlinetab)	; Ja. Vi slår av
	lea	(Plaintext),a2		; Ja
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	addq.w	#4,d1

	cmp.b	#2,(Quotingmode)	; Har vi quota >>?
	bne.b	1003$			; Nei
	lea	(ansiredtext),a2	; Da setter vi rød
	bra.b	1010$
1003$	cmp.b	#1,(Quotingmode)	; Har vi quota >?
	bne.b	1004$			; Nei
	lea	(ansilbluetext),a2	; Da setter vi lyseblå
	bra.b	1010$
1004$	lea	(ansigreentext),a2	; Da må vi ha grønn!
	bra.b	1010$

1001$	move.b	#'_',d2
	jsr	(_CheckTextMode)	; Sjekker om vi skal ha på
	beq.b	1000$			; Nei
	lea	(Underlinetext),a2	; Da setter vi på
	move.b	#1,(Underlinetab)
	bra.b	1002$
1010$	move.b	(a2)+,(a1)+		; Må ha med 1 ekstra pga farge
	addq.w	#1,d1
1002$	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	move.b	(a2)+,(a1)+
	addq.w	#4,d1
	move.b	(a0)+,(a1)	; Hopper over tegnet
	subq.w	#1,d1
;	bra	1000$

1000$	move.b	(a0)+,(a1)+	

; kopiere a0 til a1 og plusser på.
	addq.w	#1,d1
	cmpi.w	#160,d1
	bhi.b	2$
	dbf	d3,1$
2$	move.w	d1,(outtextbufferpos,NodeBase)
9$	pop	a2/d2/d3
	rts

;#c
; OBS : Dropper tekst over 160 tegn !!!
writetext
	move.l	a0,a1
	moveq.l	#-1,d0
1$	tst.b	(a1)+
	dbeq	d0,1$
	not.w	d0
	ext.l	d0
writetextlen
	subq.w	#1,d0
	bcs.b	9$	; for kort!
	moveq	#0,d1
	lea	(outtextbuffer,NodeBase),a1
	move.w	(outtextbufferpos,NodeBase),d1
	cmpi.w	#160,d1
	bhi.b	2$
	adda.l	d1,a1
1$	move.b	(a0)+,(a1)+	; kopiere a0 til a1 og plusser på.
	addq.w	#1,d1
	cmpi.w	#160,d1
	bhi.b	2$
	dbf	d0,1$
2$	move.w	d1,(outtextbufferpos,NodeBase)
9$	rts

;#c
newlinei
	move.b	#10,d0
writechari
	bsr	writechar
	tst.w	(outtextbufferpos,NodeBase)	; Har vi allerede tatt outimage?
	beq.b	1$				; ja.
	bra	breakoutimage
1$	rts

;#c	JEO2
; OBS : Dropper tekst over 80 tegn !!!
writetexti
	bsr	writetext
	bra	breakoutimage

;#c
; OBS : Dropper tekst over 80 tegn !!!
writetexto
	bsr	writetext
	bra	outimage

;#c
writetextleni
	bsr	writetextlen
	bra	breakoutimage

;#c
writetextlenimsg
	bsr	writetextlen	; writetextlenmsg
	bra	breakoutimage

;#c
outimage
	lea	(outtextbuffer,NodeBase),a0
	move.w	(outtextbufferpos,NodeBase),d0
	move.b	#10,(0,a0,d0.w)
	addq.w	#1,(outtextbufferpos,NodeBase)
;	bra	breakoutimage

breakoutimage
	push	a2/d2/a3

	lea	(outtextbuffer,NodeBase),a2
	move.w	(outtextbufferpos,NodeBase),d1		; legger til en null på slutten
	clr.b	(0,a2,d1.w)
	clr.w	(outtextbufferpos,NodeBase)
	tst.b	(active,NodeBase)			; Har vi noen aktive ?
	beq.b	1$					; Nei, da er det ansi tid
	tst.b	(FSEditor,NodeBase)			; Vi er i FSE. Ingen ANSI strip'ing
	bne.b	1$
	move.w	(Userbits+CU,NodeBase),d0			; Vil vi ha ansi text ?
	andi.w	#USERF_ANSI,d0
	bne.b	1$					; ja.
	move.l	a2,a0
	bsr	disposeansistuff
1$	move.l	a2,a0					; skriver ut sakene
	bsr	50$
	tst.b	(FSEditor,NodeBase)			; Vi er i FSE.
	bne	10$					; Ingen more saker
	move.l	(nodenoden,NodeBase),a0
	move.w	(Nodestatus,a0),d0
	cmpi.w	#8,d0					; chat'er vi ?
	beq	10$					; jepp.
	cmpi.w	#44,d0					; sysop chat'er vi ?
	beq	10$					; Jepp.
	move.l	a2,a0					; Var det noen NL i teksten ?
2$	move.b	(a0)+,d0
	beq	10$					; Nei, da dropper vi moresaker
	cmpi.b	#10,d0
	bne.b	2$
	move.w	(PageLength+CU,NodeBase),d0		; Skal vi droppe more ?
	beq	10$					; ja
	move.w	(linesleft,NodeBase),d0			; henter antall linjer før more
	cmpi.w	#1,d0
	bls.b	3$					; det var ingen igjen.
	cmpi.w	#-1,d0					; Har vi valgt "c" ?
	beq	10$					; ja
	subq.w	#1,(linesleft,NodeBase)	;,d0		; minker med en (overflow er umulig her)
	bra	10$
3$	lea	(moretext),a0
	move.b	(XpertLevel+CU,NodeBase),d0		; skal de ha lang text ?
	cmpi.b	#2,d0
	bcs.b	14$					; ja
	lea	(morenohelptext),a0
14$	move.l	a0,a3
	bsr	50$
	bsr	startsleepdetect
4$	bsr	readchar
	beq	12$
	bmi.b	4$			; Dropper spesial tegn.
	bsr	upchar
	cmpi.b	#' ',d0			; space ?
	beq.b	5$
	cmpi.b	#13,d0			; return ?
	beq.b	6$			; gi en linje til
	cmpi.b	#10,d0			; LF ?
	beq.b	5$
	cmpi.b	#'Y',d0			; ja ?
	beq.b	5$
	cmpi.b	#3,d0			; Sjekker etter CTLR C
	beq.b	13$
	cmpi.b	#11,d0			; Sjekker etter CTLR K
	beq.b	13$
	cmpi.b	#'Q',d0
	beq.b	13$
	cmpi.b	#'N',d0			; nei ?
	bne.b	11$
13$	lea	(newlinetext+1),a0	; Avslutter
	bsr	50$
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase) ; Ny side..
	clr.b	(dosleepdetect,NodeBase)
;	setz					; clr'en gjør dette
	bra.b	9$
11$	cmpi.b	#'C',d0
	bne.b	4$
	move.w	#-1,(linesleft,NodeBase)		; Vi skal ta continous
	bra.b	6$
5$	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)
6$	clr.b	(dosleepdetect,NodeBase)
	move.l	a3,a0					; sletter More saken
	bsr	strlen
	move.l	d2,-(a7)
	move.w	d0,d2
7$	subq.w	#1,d2
	bcs.b	8$
	lea	(deltext),a0
	bsr	50$
	bra.b	7$
8$	move.l	(a7)+,d2
10$	clrz
9$	pop	a2/d2/a3
	rts
12$	clr.b	(dosleepdetect,NodeBase)
	bra.b	9$

50$	push	a2/a3
	move.l	a0,a2
	move.l	a0,a3
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)		; internal node ??
	beq.b	53$					; Yepp. no serial action.

	bsr	waitseroutput				; Venter til ser er ferdig

; Translate string

	lea	(transouttextbuffer,NodeBase),a0
	moveq.l	#0,d1
51$	move.b	(a2)+,d0
	beq.b	52$
	bsr	translateseroutstring
	bra.b	51$
52$	clr.b	(a0)

; Write string						(d1 = len (sting))
	lea	(transouttextbuffer,NodeBase),a0
	move.l	d1,d0
	bsr	serwritestringlen
	ENDC
53$	tst.b	(Tinymode,NodeBase)			; Tiny mode ?
	bne.b	59$					; Yessir.
	move.b	(Cflags+CStr,MainBase),d0			; kjører vi med 8
	btst	#CflagsB_8Col,d0			; farver ?
	bne.b	54$					; ja
	move.l	a3,a0					; nei, da fjerner vi
	bsr	disposeansicolor			; farve kodene
	bra.b	58$
54$	move.l	#160,d0					; maks lengde...
	move.l	a3,a0					; Legger til en ;37
	bsr	addansiwhite				; etter hver esc[0..m
58$	move.l	a3,a2					; Oversetter for console
	lea	(conouttextbuffer,NodeBase),a0
	moveq.l	#0,d1
55$	move.b	(a2)+,d0
	beq.b	56$
;	cmp.b	#7,d0		; BELL ??
;	beq.b	55$		; Ja. det vil vi ikke ha her.
	cmpi.b	#10,d0
	bne.b	57$
	move.b	#13,(a0)+
	addq.l	#1,d1
57$	move.b	d0,(a0)+
	addq.l	#1,d1
	bra.b	55$
56$	clr.b	(a0)
	lea	(conouttextbuffer,NodeBase),a0
	move.l	d1,d0
	bsr	writecontextlen			; write to console
59$	pop	a2/a3
	rts

;#c
dubbelnewline
	moveq.l	#2,d0
	lea	(newlinetext),a0
	bra	writetextlen

;#c
; a0 = text
; d0 = len
; d1 = 1 -> Bare con
; d1 = 2 -> ikke breake, (både con og ser).
; d1 : bit 31 satt : quoting på.
writetextmemi
	push	a2/d2/d3/d4/d5
	link.w	a3,#-250
	moveq.l	#0,d5				; siste ESC
	move.b	#0,Underlinetab
	btst	#31,d1				; skal vi quote ?
	beq.b	101$				; nei
	move.w	(Userbits+CU,NodeBase),d2	; Vil vi ha ansi text ?
	andi.w	#USERF_ColorMessages,d2
	beq.b	101$				; nei.
	bset	#30,d5				; ja, husker
101$	move.l	d1,d3
	beq.b	6$				; ikke bare con
	cmpi.b	#2,d1				; er det ikke break ?
	bne.b	61$				; nope
	bset	#31,d5				; setter flagg så vi husker
	moveq.l	#0,d3				; og retter opp d3
	bra.b	6$

61$	tst.b	(Tinymode,NodeBase)		; har vi tinymode ?
	bne	999$				; ja, da er vi ferdige
6$	move.l	a0,a2
	move.l	d0,d2
	lea	(CursorOffData),a0		; slår av cursor
	bsr	writecontext
3$	moveq.l	#0,d0
	move.l	a2,a0
2$	move.b	(a2)+,d1
	addq.l	#1,d0
	subq.l	#1,d2				; ferdig ?
	beq.b	1$				; ja
	cmpi.b	#10,d1				; NL ?
	beq.b	1$				; jepp. ut med linja
	cmpi.b	#27,d1				; ESC ?
	bne.b	4$
	move.w	d0,d5				; husker siste ESC.
4$	cmpi.w	#80,d0				; 80 tegn ?
	bcs.b	2$				; nope. continue
	cmpi.w	#72,d5				; er vi i en ESC sekvens ? (hack)
	bls.b	1$				; nei. alt ok.
	sub.w	d5,d0
	andi.l	#$ffff,d0
	addq.l	#1,d0
	suba.l	d0,a2				; peker tilbake på starten av ESC
	add.l	d0,d2				; fikser opp size'n igjen
	move.w	d5,d0
	subq.l	#1,d0				; skriv ut til ESC (ikke med)
1$	tst.b	d3
	beq.b	5$
	move.b	(Cflags+CStr,MainBase),d1	; kjører vi med 8
	btst	#CflagsB_8Col,d1		; farver ?
	bne.b	8$				; ja
	move.l	sp,a1				; nei, da fjerner vi
	bsr	strcopylen			; farve kodene
	move.b	#0,(a1)
	move.l	sp,a0
	bsr	disposeansicolor
	move.l	sp,a0
	bsr	writecontext
	bra.b	7$
8$	bsr	10$				; på med quotefarve (?)
	bsr	writecontextlen
	bra.b	73$
5$	bsr	10$				; på med quitefarve (?)
	bsr	writetextlenimsg
	bne.b	73$
;	tst.b	readcharstatus(NodeBase)	; Har det skjedd noe ?
;	notz
	bra.b	9$
73$	bsr	20$				; quotefarven på ? av med den
7$	tst.l	d2
	beq.b	99$
	move.w	#0,d5				; siste ESC
	btst	#31,d5				; skal vi ta breake? JEO JEO
	beq.b	71$				; ja.
	bsr	testbreak
	bra.b	72$
71$	bsr	testbreakspes
72$	bne	3$
	bsr	outimage
	setz
	bra.b	9$
99$	clrz
9$	sne	d2
	lea	(CursorOnData),a0			; slår på cursor
	bsr	writecontext
	tst.b	d2
999$	unlk	a3
	pop	a2/d2/d3/d4/d5
	rts

; JEO
10$	move.b	#0,Quotingmode
	btst	#30,d5				; skal vi ha ansi ?
	beq.b	19$				; nei.
	cmpi.b	#'>',(a0)			; quoting ?
	bne.b	19$				; nei
	bset	#29,d5				; ja
	push	a0/d0
	cmpi.b	#'>',(1,a0)			; dobbel quiting ?
	beq.b	12$				; nei
	lea	(ansilbluetext),a0		; ja
	move.b	#1,Quotingmode
	bra.b	11$
12$	lea	(ansiredtext),a0
	move.b	#2,Quotingmode
11$	bsr	writetext			; writetextmsg
	pop	a0/d0
19$	rts

20$	btst	#29,d5				; satte vi på quote farve ?
	beq.b	29$				; nei
	bclr	#29,d5				; slår av flagget
	push	a0/d0
	lea	(ansigreentext),a0
	bsr	writetext			; writetetmsg
	pop	a0/d0
29$	rts

testbreakspes
	IFD	nobreak
	clrz
	rts
	ENDC
	bsr	testbreak
	beq.b	9$
	move.b	(XpertLevel+CU,NodeBase),d0		; er vi novice?
	notz
	bne.b	9$				;: ja, ingen break
	move.l	(creadreq,NodeBase),d0
	beq.b	1$				; ingen console..
	move.l	d0,a1
	jsrlib	CheckIO				; console ferdig ?
	tst.l	d0
	bne.b	8$				; Ja, vi har et tegn
1$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Skal denne noden være serial ?
	beq.b	7$
	move.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	bne.b	8$				; Ja, vi har et tegn
	ENDC
7$	clrz
	bra.b	9$
8$	setz					; nope. Ikke noe tegn
9$	rts

;#c
; d0 = maks linje
readlineall
	tst.b	(readlinemore,NodeBase)
	bne.b	1$
	bsr	getline
	rts
1$	lea	(readlinebuffer,NodeBase),a0
	lea	(intextbuffer,NodeBase),a1
	moveq.l	#0,d1
	move.w	(intextchar,NodeBase),d1
	adda.l	d1,a1
	move.l	d0,d1				; maks antall tegn
	moveq.l	#-1,d0
2$	addq.l	#1,d0
	subq.l	#1,d1
	bcs.b	3$
	move.b	(a1)+,(a0)+
	bne.b	2$
3$	move.b	#0,(a0)
	clr.b	(readlinemore,NodeBase)
	lea	(readlinebuffer,NodeBase),a0
	tst.w	d0
	rts

;obs: front_dologin skriver inn i intextbuffer
;#c
;readlineflush
;	clr.b	(readlinemore,NodeBase)
readline
	tst.b	(readlinemore,NodeBase)
	bne.b	5$
	move.w	#80,d0
	bsr	getline
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	moveq.l	#1,d0
	move.b	d0,(readlinemore,NodeBase)
5$	move.l	d2,-(sp)
	moveq.l	#0,d0
	lea	(readlinebuffer,NodeBase),a0
	lea	(intextbuffer,NodeBase),a1
	move.w	(intextchar,NodeBase),d1
0$	addq.l	#1,d1
	move.b	(-1,a1,d1.w),d2			; filtrerer vekk space i starten
	cmpi.b	#' ',d2
	beq.b	0$
	bra.b	8$
1$	addq.l	#1,d1
8$	move.b	(-1,a1,d1.w),d2
	beq.b	3$
	cmpi.b	#';',d2
	beq.b	2$
	cmpi.b	#',',d2
	beq.b	2$
	cmpi.b	#' ',d2
	bne.b	6$
	cmpi.b	#',',(0,a1,d1.w)
	beq.b	7$
	cmpi.b	#';',(0,a1,d1.w)
	bne.b	2$
7$	addq.l	#1,d1
	bra.b	2$
6$	move.b	d2,(0,a0,d0.w)
	addq.l	#1,d0
	bra.b	1$
2$	move.b	(0,a1,d1.w),d2
	beq.b	3$
	addq.l	#1,d1
	cmpi.b	#' ',d2
	beq.b	2$
	subq.l	#1,d1
	bra.b	4$
3$	clr.b	(readlinemore,NodeBase)
4$	move.w	d1,(intextchar,NodeBase)
	move.b	#0,(0,a0,d0.w)
	move.l	(sp)+,d2
	tst.w	d0
9$	rts

;#e
*****************************************************************
*			sub rutiner				*
*****************************************************************

; a0 = prompt
; a1 = allerede lest input (= NULL hvis ingen)
; d0 = 0  : gottar ikke all
; d0 = 2  : må ha ALL for å sende all tilbake
; d1 != 0 : Tillater nettnavn
; returnerer -1 ved ALL, bare return
; z = 1 hvis no carrier
; n = 1, det var bare return
;(Prog/C) Read Ref Command: e sdf
;
;Please enter both the first AND the last name!
;Send message to (CR for ALL): SDF sdf
;Sorry, that name is not registered!
;Scanning user register...
;   SIGURD STENERSEN
getname	push	d2/a2/d3/d4
	move.l	a0,a2			; husker prompt
	moveq.l	#0,d2
	move.b	d0,d2			; husker all status
	tst.l	d1
	beq.b	0$
	bset	#31,d2			; vi tillater nett navn
0$	move.l	a1,d0			; er det input her ?
	bne.b	1$			; jepp, tar edline
	tst.b	(readlinemore,NodeBase)	; er det mere innput ?
	beq.b	3$			; nei
	bsr	readline
	bne.b	2$
	bra.b	4$
3$	lea	(nulltext),a1
1$	moveq.l	#Sizeof_NameT,d0		; size
	move.l	a2,a0				; prompt
	jsr	(mayedlinepromptfull)
	bne.b	2$
4$	tst.b	(readcharstatus,NodeBase)	; sjedde det noe spes ?
	notz
	clrn
	beq	9$				; jepp, ut
	moveq	#-1,d0
	cmp.b	#1,d2
	notz
	setn					; det var bare return
	bra	9$

2$	move.w	d0,d3
	lea	(tmptext,NodeBase),a1
	move.l	a1,d4				; husker stringen
	bsr	strcopy
	cmpi.w	#3,d3				; 3 tegn ? sizeof("ALL")
	bne.b	5$				; nope
	lea	(alltext),a1			; sjekker om det var ALL
	move.l	d4,a0
	bsr	comparestringsifull
	bne	6$				; nope (heller ikke sysop)
	moveq	#-1,d0				; returnerer -1 hvis vi godtar ALL
	tst.b	d2
	clrn
	bne	9$				; det gjorde vi
	lea	(noallheretext),a0		; klage
21$	bsr	writeerroro
	bra.b	3$

5$	cmpi.w	#5,d3				; sizeof("SYSOP") ?
	bne.b	6$				; nope
	lea	(plainsysoptext),a1		; sjekker om det er sysop
	move.l	d4,a0
	bsr	comparestringsifull
	bne.b	6$				; nope
	lea	(SYSOPname+CStr,MainBase),a0		; henter sysop navnet
	lea	(tmptext,NodeBase),a1
	bsr	strcopy
	lea	(tmptext,NodeBase),a0
	bra	7$
11$	move.b	#0,(readlinemore,NodeBase)
	bra	3$

10$	tst.b	(readlinemore,NodeBase)	; er det mere innput ?
	beq.b	12$			; nei
	bsr	readline
	bne.b	13$
	tst.b	(readcharstatus,NodeBase)	; sjedde det noe spes ?
	notz
	clrn
	beq	9$				; jepp, ut
	bra.b	12$
13$	move.l	d4,a1
14$	move.b	(a1)+,d0
	bne.b	14$
	move.b	#' ',(-1,a1)
	bsr	strcopy
	bra.b	6$
12$	lea	(entlastnametext),a0
15$	bsr	writeerroro
	move.l	d4,a1
	bra	1$

6$	move.l	d4,a0				; finner ut om vi har fornavn
	cmp.b	#' ',(a0)			; og etternavn.
	beq.b	11$
61$	move.b	(a0)+,d0
	beq.b	10$
	cmp.b	#'@',d0
	bne.b	64$
	btst	#31,d2				; tillater vi netnavn ?
	bne.b	63$				; jepp, da er vi ferdige..
	lea	(nonetnametext),a0
	bra.b	15$
64$	cmp.b	#' ',d0
	bne.b	61$
	move.b	(a0),d0
	beq.b	10$
62$	move.b	(a0)+,d0
	beq.b	63$
	cmp.b	#'@',d0
	bne.b	65$
	btst	#31,d2				; tillater vi netnavn ?
	bne.b	63$				; jepp, da er vi ferdige..
	lea	(nonetnametext),a0
	bra.b	15$
65$	cmp.b	#' ',d0
	bne.b	62$
	move.b	#0,(-1,a0)
63$	move.l	d4,a0
	bsr	strlen
	cmpi.w	#Sizeof_NameT,d0
	lea	(nametolongtext),a0	
	bhi	21$
	move.l	d4,a0
7$	move.l	a0,a1
	moveq.l	#-1,d0
71$	tst.b	(a1)+
	dbeq	d0,71$
	addi.w	#Sizeof_NameT+1,d0
	bmi.b	73$
72$	move.b	#0,(a1)+
	dbf	d0,72$
73$	move.b	#0,(a1)

8$	moveq	#1,d0				; z = 0, n = 0, d0 != -1
9$	pop	d2/a2/d3/d4
	rts

; a0 = prompt
; d0 != 0 : bruk edlineprompt isteden.
; d1 = 0  : gottar ikke all
; d1 = 2  : må ha ALL for å sende all tilbake
; returnerer -1 ved ALL, bare return
; z = 1 hvis no carrier
; n = 1, det var bare return
;	IFD	sdfasdq3
;getname
;	push	d2/a2/d3/d4
;	move.l	d0,d1
;	move.l	a1,d0
;	beq.b	101$
;	move.l	a0,a2
;	move.l	a1,a0
;	lea	(intextbuffer,NodeBase),a1
;	bsr	strcopy
;	moveq.l	#Sizeof_NameT,d0
;	move.l	a2,a0
;101$	move.l	d0,d3
;	move.l	d1,d4
;	move.l	a0,a2
;4$	move.l	a2,a0
;	move.l	d3,d0				; bruke edlineprompt ?
;	bne.b	5$				; jepp
;	bsr	readlineprompt
;	bra.b	6$
;5$	bsr	edlinepromptword
;6$	beq.b	0$				; det skjedde noe spes.
;	move.l	d0,d2				; tegn lest
;	bsr	upword
;	cmpi.w	#3,d2				; 3 tegn ? sizeof("ALL")
;	bne.b	1$				; nope
;	lea	(alltext),a1			; sjekker om det var ALL
;	move.l	a0,-(sp)
;	bsr	comparestringsfull
;	move.l	(sp)+,a0
;	bne.b	2$				; nope
;	moveq	#-1,d0				; returnerer -1 hvis vi godtar ALL
;	tst.l	d4
;	clrn
;	bne	9$				; det gjorde vi
;	lea	(noallheretext),a0		; klage
;61$	bsr	writeerroro
;	bra.b	4$
;0$	tst.b	(readcharstatus,NodeBase)	; sjedde det noe spes ?
;	notz
;	clrn
;	beq	9$				; jepp, ut
;	moveq	#-1,d0
;	cmp.b	#1,d4
;	notz
;	setn					; det var bare return
;	bra	9$
;1$	cmpi.w	#5,d2				; sizeof("SYSOP") ?
;	bne.b	2$				; nope
;	lea	(plainsysoptext),a1		; sjekker om det er sysop
;	move.l	a0,-(sp)
;	bsr	comparestringsfull
;	move.l	(sp)+,a0
;	bne.b	2$				; nope
;	lea	(SYSOPname+CStr,MainBase),a0		; henter sysop navnet
;	lea	(tmptext,NodeBase),a1
;	bsr	strcopy
;	lea	(tmptext,NodeBase),a0
;	bra.b	3$
;2$	cmpi.w	#Sizeof_NameT-2,d2		; for langt ?
;	bls.b	21$				; nope
;22$	lea	(nametolongtext),a0
;	bra.b	61$
;21$	lea	(tmptext,NodeBase),a1
;	bsr	strcopy
;	move.b	#' ',(-1,a1)
;	addq.l	#1,d2
;71$	lea	(entlastnametext),a0
;	bsr	readlineprompt
;	bne.b	12$
;	tst.b	(readcharstatus,NodeBase)
;	notz
;	bne.b	71$
;	clrn
;	bra.b	9$
;12$	bsr	upword
;	lea	(tmptext,NodeBase),a1
;	adda.l	d2,a1
;	add.l	d0,d2
;	cmpi.w	#Sizeof_NameT,d2
;	bhi	22$
;	bsr	strcopylen
;	move.b	#0,(a1)
;	lea	(tmptext,NodeBase),a0
;3$	move.l	a0,a1
;	moveq.l	#-1,d0
;8$	tst.b	(a1)+
;	dbeq	d0,8$
;	addi.w	#Sizeof_NameT+1,d0
;	bmi.b	10$
;11$	move.b	#0,(a1)+
;	dbf	d0,11$
;10$	moveq	#1,d0				; z = 0, n = 0, d0 != -1
;9$	pop	d2/a2/d3/d4
;	rts
;	ENDC

; d0 = usernr
; ret:	a0 = username
;	d0 = death status
getusername
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	1$
	lea	(alltext),a0
	moveq.l	#0,d0
	bra.b	9$
1$	move.l	(msg,NodeBase),a1
	move.w	#Main_getusername,(m_Command,a1)
	move.l	d0,(m_UserNr,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.l	(m_Name,a1),a0
	move.w	(m_Data,a1),d0
;	move.w	m_Error(a1),d1
;	cmp.w	#Error_OK,d1
9$	rts

getloginname
	push	d2/a2/d3
; Vil trolig aldri brukes
;	bsr	handlenetlogin		; Ber den ta seg av innlogging
;	beq	99$			; Vi skal ut (feil, eller net session foretatt.)
	move.b	#0,(Charset+CU,NodeBase)	; Sørger for at brukeren har ISO
	bra.b	1$

0$	clr.b	(readlinemore,NodeBase)
1$	lea	(Name+CU,NodeBase),a0	; Sletter.
	moveq.l	#Sizeof_NameT,d0
	bsr	memclr
	lea	(tmptext,NodeBase),a0	; Sletter.
	moveq.l	#Sizeof_NameT,d0
	bsr	memclr

	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)
	beq.b	2$
	bsr	checkcarrier		; har vi carrier ?
	beq	99$			; Nei, "NoCarrier"
	bsr	flushserialbuffer
	ENDC
2$	bsr	outimage
	lea	(whatisfirstname),a0
	bsr	readlineprompt
	bne.b	7$
	tst.b	(readcharstatus,NodeBase) ; no carrier ?
	notz
	beq	99$			; ja, ut
	bra.b	2$			; nei, tilbake igjen.
7$	move.w	d0,d2
	cmpi.w	#Sizeof_NameT-2,d2	; sjekker om fornavet er for klangt
	bhi.b	11$			; har ikke plass til space og etternavn.
	move.l	a0,a2
	lea	(plainsysoptext),a1		; er det sysop ?
	bsr	comparestringsicase
	bne.b	4$			; nope
	lea	(SYSOPname+CStr,MainBase),a0	; fyller i sysops navn
	lea	(Name+CU,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen
	bra.b	9$			; og ferdig
4$	move.l	a2,a0
	move.l	d2,d0
	lea	(tmptext,NodeBase),a1	; kopierer inn fornavnet
	bsr	strcopymaxlen
	lea	(whatislastname),a0
	bsr	readlineprompt
	bne.b	8$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	99$
	bra	0$
8$	move.w	d2,d1
	add.w	d0,d1
	cmpi.w	#Sizeof_NameT,d1
	bcs.b	10$
11$	lea	(nametolongtext),a0
	bsr	writetexti
	bra	0$
10$	move.l	a0,a2
	move.w	d0,d3
	move.w	d2,d0
	ext.l	d0
	lea	(tmptext,NodeBase),a1	; kopierer inn fornavnet
	adda.l	d0,a1
	move.b	#' ',(a1)+
	move.w	d3,d0
	bsr	strcopylen
	lea	(tmptext,NodeBase),a0	; kopierer inn navnet på riktig sted
	lea	(Name+CU,NodeBase),a1
	bsr	strcopy

	lea	(Name+CU,NodeBase),a0
	bsr	FixloginIBN
9$	clrz
99$	pop	d2/a2/d3
	lea	(Name+CU,NodeBase),a0
	rts

FixloginIBN
	push	a2
	lea	(ibnnortext),a1
	lea	(isonortext),a2
1$	move.b	(a0)+,d0
	beq.b	9$			; ferdig
	moveq.l	#5,d1			; antall tegn - 1
2$	cmp.b	(a1,d1.w),d0
	dbeq	d1,2$
	bne.b	1$			; fant ikke
	move.b	(a2,d1.w),(-1,a0)	; konverterer.
	bra.b	1$
9$	pop	a2
	rts

; retur:
; Z = ferdig (Z = 1: Ferdig, logout, Z = 0, be om nanv osv)
handlenetlogin
	clrz
	rts
	IFD	OLD_NETLOGIN
	link	a3,#-30
	lea	(sp),a1				; bygger opp port navnet "ABBSnetX.port"
	lea	(netportname),a0
	move.w	(NodeNumber,NodeBase),d0
	jsr	(fillinnodenr)
	lea	(sp),a1				; sjekker om det er noe vits i å gjøre mere
	jsrlib	FindPort
	tst.l	d0
	beq.b	8$				; oops, ingen port
	move.l	(msg,NodeBase),a1
	move.w	#Net_DoLogin,(pm_Command,a1)
	move.l	(nodepublicport,NodeBase),(pm_Data,a1)
	lea	(sp),a0				; Port navnet
	jsr	(handlemsgspesport)		; ingen error fra denne
	beq.b	8$				; oops, ingen port
	bset	#DIVB_InNetLogin,(Divmodes,NodeBase)

1$	move.l	(publicsigbit,NodeBase),d0
	jsrlib	Wait
	jsr	(handlepublicport)
	bne.b	1$
	bclr	#DIVB_InNetLogin,(Divmodes,NodeBase)
	lea	(tmptext,NodeBase),a0
	move.b	(a0),d0
	beq.b	9$
	lea	(intextbuffer,NodeBase),a1		; HACK!
	bsr	strcopy
	move.b	#1,(readlinemore,NodeBase)
	move.w	#0,(intextchar,NodeBase)
8$	notz
9$	unlk	a3
	rts
	ENDC	; OLD_NETLOGIN

; må beholde a0
convertfirstnltoend
	push	a0
1$	move.b	(a0)+,d0
	beq.b	9$
	cmp.b	#10,d0
	bne.b	1$
	move.b	#0,(-1,a0)
9$	pop	a0
	rts

******************************
;removespaces (streng)
;		 a0.l
;Removes spaces before string,
;and places a 0 byte at end of word
******************************
removespaces
1$	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#' ',d0
	beq.b	1$
	subq.l	#1,a0
	move.l	a0,a1
2$	move.b	(a0)+,d0
	beq.b	8$
	cmpi.b	#' ',d0
	bne.b	2$
	move.b	#0,(-1,a0)
8$	move.l	a1,a0
	clrz
9$	rts

******************************
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
;obs: Må ikke ødelegge registre
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.b	1$
	rts

******************************
;strcat (fromstreng,tostreng1)
;	 a0.l	     a1.l
;appends fromstring after tostring
******************************
strcat
1$	tst.b	(a1)+
	bne.b	1$
	subq.l	#1,a1
2$	move.b	(a0)+,(a1)+
	bne.b	2$
	rts

typefileinfoheader
	lea	(ansigreentext),a0
	bsr	writetexti
	lea	(fileiheadertext),a0
	bsr	strlen
	lea	(fileiheadertext),a0
	moveq.l	#0,d1
	bsr	writetextmemi		; skriver header.
	beq.b	9$
	bsr	outimage		; nl.
9$	rts

; a0 = string
; returns with a0 pointing at the terminating 0 of the string
addendofpath
1$	move.b	(a0)+,d0
	bne.b	1$
	subq.l	#1,a0
	move.b	(-1,a0),d0
	cmp.b	#':',d0			; already correct ?
	beq.b	9$			; yes
	cmp.b	#'/',d0
	beq.b	9$			; yes
	move.b	#'/',(a0)+		; add path end
	move.b	#0,(a0)
9$	rts

checkfilename
	move.l	a2,-(sp)
	move.l	a0,a2
	bsr	testfilename
	beq	1$
	move.l	a2,a0
	bsr	strlen
	cmpi.w	#Sizeof_FileName,d0
	bhi.b	3$
	clrz
9$	move.l	(sp)+,a2
	rts
3$	lea	(only18charatext),a0
	bsr	writeerroro
	bra.b	2$
1$	lea	(nopathallowtext),a0
	bsr	writeerroro
2$	clr.b	(readlinemore,NodeBase)
	bra.b	9$

; a0 = filename
; d0 = dirnr (*1)
; a1 = string
buildfilepath
	move.l	a0,-(sp)
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	mulu.w	#FileDirRecord_SIZEOF,d0
	lea	(n_DirPaths,a0,d0.l),a0
	bsr	strcopy
	subq.l	#1,a1
	cmpi.b	#':',(-1,a1)		; er det filpathslutt der ?
	beq.b	1$			; jepp
	cmpi.b	#'/',(-1,a1)		; er det filpathslutt der ?
	beq.b	1$			; jepp
	move.b	#'/',(a1)+		; nei, legger på
1$	move.l	(sp)+,a0
	bra	strcopy

; a0 = name
; a1 = fileinfo buffer
; d0 = vil ha nesten navn (true/false)
findfileinfo
	push	d2/a2/a3/d3/d4
	move.l	a1,a2
	move.l	d0,d4			; husker om vi vil ha nesten navn
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	move.l	(msg,NodeBase),a1
	move.w	#Main_findfile,(m_Command,a1)
	move.l	a0,(m_Name,a1)
	lea	(tmplargestore,NodeBase),a0
	move.l	a0,(m_arg,a1)		; gir med plass til nesten match.
	move.b	#0,(8,a0)		; sletter nesten navnet

	moveq.l	#0,d2			; filedir nr
	moveq.l	#0,d3			; antall fildir'er vi har sjekket
1$	move.b	(n_DirName,a3),d0
	bne.b	4$
	lea	(FileDirRecord_SIZEOF,a3),a3 ; peker til neste navn
	addq.l	#1,d2
	bra.b	1$
4$	move.l	d2,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_Not_Found,d1
	bne.b	2$
3$	addq.l	#1,d2			; loop'er igjennom alle dir'er.
	addq.l	#1,d3
	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	cmp.w	(ActiveDirs+CStr,MainBase),d3
	bcs.b	1$
	tst.l	d4			; vil vi ha nesten navn ?
	beq.b	2$			; nei.
	lea	(tmplargestore,NodeBase),a0
	move.b	(8,a0),d0		; har vi fått et nesten navn ?
	beq.b	2$			; nei

	move.l	(msg,NodeBase),a1	; load'er nesten navnet
	move.w	#Main_loadfileentry,(m_Command,a1)
	move.l	(a0)+,d2
	move.l	d2,(m_UserNr,a1)	; filedir
	move.l	(a0),(m_arg,a1)		; fil nr
	move.l	a2,(m_Data,a1)		; buffer
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
2$	move.l	d2,d0
	cmpi.w	#Error_OK,d1
	bne.b	9$
	move.w	(Filestatus,a2),d1	; vil ikke slå ut for nesten navn (allerede sjekket)
	andi.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d1
	bne.b	3$
9$	notz
	pop	d2/a2/a3/d3/d4
	rts

; a0 = funksjon
; a1 = dirnavn på de som skal match'es
; d0 = data
; d1 (bool) vis mere info
loopalldirs
	push	d2/a3/d3/d4/d5/d6/d7
	move.l	d1,d2
	move.l	a0,d6			; Funksjon å utføre på filentry'ene
	move.l	d0,d3			; Data til denne funksjonen
	move.l	a1,d7			; husker mach'en
	move.l	a1,a0
	bsr	upstring		; gjør om til store navn
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	moveq.l	#-1,d4			; confnr. Private først.
	moveq.l	#0,d5			; teller for antall dir'er
1$	addq.l	#1,d4			; Øker dir nr
	moveq.l	#0,d0
	move.l	d4,d1
	mulu.w	#FileDirRecord_SIZEOF,d1
	move.w	(n_FileOrder,a3,d1.l),d0		; henter ut dirnr
	subq.l	#1,d0
	move.l	d0,d1
	mulu.w	#FileDirRecord_SIZEOF,d1
	lea	(n_DirName,a3,d1.l),a0	; er det en fildir her ?
	move.b	(a0),d1
	beq.b	1$			; nope
	move.l	d7,a1
	bsr	10$			; skal vi ta denne ?
	beq.b	3$			; nope
	move.l	d6,a0
	move.l	d3,d1
	bsr	loopdir
	beq.b	9$
	bsr	testbreak
	beq.b	9$
3$	addq.l	#1,d5
	cmp.w	(ActiveDirs+CStr,MainBase),d5
	blo.b	1$
9$	pop	d2/d3/a3/d4/d5/d6/d7
	rts

10$	push	d0
11$	move.b	(a1)+,d1		; henter neste tegn i match'en
	beq.b	18$			; ferdig, vi tar'n
	cmpi.b	#'*',d1			; stjerne ?
	beq.b	18$			; jepp, da tar vi'n
	move.b	(a0)+,d0
	beq.b	19$			; slutt, ikke denne
	bsr	upchar
	cmp.b	d0,d1			; stemmer det videre ?
	beq.b	11$			; jepp.
18$	notz
19$	pop	d0
	rts

; a0 = funksjon
; d0 = dirnr
; d1 = data
; d2 (bool) vis mere info
loopdir	push	a2/a3/d2/d3/d4/d5/d6
	move.l	d0,d3
	move.l	a0,a3
	move.l	d1,d5
	move.l	d2,d6
	lea	(tmpfileentry,NodeBase),a2
	moveq.l	#0,d4				; Har vi skrevet ut header ? Nei.
	moveq.l	#1,d2				; starter på første fil.

	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	4$				; nope
	jsr	(setuptmpbrowse)
	bne.b	43$				; ok
	bclr	#DIVB_Browse,(Divmodes,NodeBase) ; error, dropper browse
	bra.b	4$
43$	lea	(ansiclearscreen),a0
	bsr	writetexti
	bra.b	41$
4$	move.b	#'(',d0				; Skriver ut fildir navn
	bsr	writechar
41$	move.l	(firstFileDirRecord+CStr,MainBase),a0
	move.l	d3,d0
	mulu.w	#FileDirRecord_SIZEOF,d0
	lea	(n_DirName,a0,d0.l),a0
	bsr	writetext
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	bne.b	42$				; jepp
	move.b	#')',d0
	bsr	writechar
42$	bsr	outimage
	beq	9$

1$	move.l	(msg,NodeBase),a1
	move.w	#Main_loadfileentry,(m_Command,a1)
	move.l	d3,(m_UserNr,a1)
	move.l	d2,(m_arg,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_EOF,d0
	beq.b	7$
	cmpi.w	#Error_OK,d0
	bne.b	6$
	move.l	a2,a0
	bsr	allowtypefileinfo
	beq.b	2$
	move.l	d5,d0			; Plasere data.
	move.l	a2,a0
	jsr	(a3)			; Skal denne skrives ut ??
	beq.b	2$			; Nei

	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	8$				; nope
	move.l	a2,a0
	move.l	d2,d0
	jsr	(addtmpbrowse)
	beq.b	7$			; full, "ferdig", hopper til valg
	bra.b	2$
8$	tst.l	d4
	bne.b	3$
	bsr	typefileinfoheader
	beq.b	9$
	moveq.l	#1,d4
3$	move.l	a2,a0
	move.l	d6,d0
	bsr	typefileinfo
	beq.b	9$
2$	addq.l	#1,d2
	bsr	testbreak
	beq.b	9$
	bsr	checkcarriercheckser
	beq.b	9$
	bra.b	1$
6$	tst.l	d4
	beq.b	9$
	bsr	outimage
	setz
	bra.b	9$
7$	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	71$				; nope
	move.l	d3,d0
	jsr	(dobrowseselect)
	beq.b	9$

71$	tst.l	d4
	beq.b	5$
	bsr	outimage
	beq.b	9$
5$	clrz
9$	sne.b	d2
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	91$				; nope
	jsr	(cleanuptmpbrowse)
91$	tst.b	d2
	pop	a2/a3/d2/d3/d4/d5/d6
	rts

; a0 : filentry
; d0 : skal vi vise 2. linje hvis det er sysop ?
typefileinfo
	push	d2/a2
	link.w	a3,#-160
	move.l	d0,d2			; husker 2. linje status
	move.l	a0,a2
	lea	sp,a1			; string
	bsr	dofileinfoline1
	lea	sp,a0
	bsr	writetexto
	beq.b	9$

	tst.l	d2				; skal vi ha mere ?
	notz
	bne.b	9$				; nei
	move.l	a2,a0
	lea	sp,a1
	bsr	dofileinfoline2
	lea	sp,a0
	bsr	writetexto
9$	unlk	a3
	pop	d2/a2
	rts

	XREF	_Check_Preview

; a0 = fileinfo
; a1 = string
dofileinfoline1
	push	a2/d2/d3/a3
	move.l	a0,a2			; fileinfo
	move.l	a1,a3			; string

; skriver ut debug verdier..
;	IFEQ	sn-13
;	move.l	a3,a0
;	move.l	(Uploader,a2),d0
;	bsr	konverter
;	move.b	#':',(a0)+
;	move.l	(AntallDLs,a2),d0
;	bsr	konverter
;	move.b	#':',(a0)+
;	move.l	a0,a3
;	ENDC

	lea	(minusstext),a0
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(uc_Access,a0),d0
	btst	#ACCB_Download,d0
	beq.b	11$
	lea	(nulltext),a0		; Nuller ut a0
	move.l	(Infomsgnr,a2),d0	; har vi en fileinfo?
	beq.b	13$			; nei vi hopper
	lea	(itext),a0
11$	move.l	a0,d3
	lea	(ansiyellowtext),a0	; skifter til gul
	move.l	a3,a1
	bsr	strcopy
	lea	(-1,a1),a3		; oppdaterer string pointer
	move.l	d3,a0
13$	move.l	a3,a1			; hadde ikke fileinfo
	moveq.l	#2,d0
	bsr	strcopylfill
	lea	(-1,a1),a3

	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_Preview,d0
	beq.b	555$
	lea	(previewtext),a0
	moveq.l	#6,d0
	move.l	a3,a1
	bsr	strcopylfill

555$	lea	(ansilbluetext),a0
	move.w	(Filestatus,a2),d0	; for bruk i browse...
	btst	#FILESTATUSB_Selected,d0
	beq.b	14$
	lea	(ansiredtext),a0
14$	bsr	strcopy
	lea	(-1,a1),a3
	lea	(Filename,a2),a0
	moveq.l	#Sizeof_FileName+1,d0
	move.l	a3,a1
	bsr	strcopylfill
	lea	(ansiwhitetext),a0
	bsr	strcopy
	lea	(-1,a1),a3
	lea	(ULdate,a2),a0
	bsr	datestampetodate
	move.l	d1,d3
	tst.l	d0
	beq.b	7$
	divu.w	#100,d0			; Er bare interesert i tiåret.
	move.w	#0,d0
	swap	d0
7$	move.l	a3,a0
	bsr	nr2tostr
	move.l	d3,d0
	bsr	nr2tostr
	move.l	d2,d0
	bsr	nr2tostr
	move.b	#' ',(a0)+
	move.l	a0,a3				; oppdaterer strptr

	move.l	(Fsize,a2),d2
	move.l	d2,d0
	beq.b	6$
	moveq.l	#10,d1
	lsr.l	d1,d0
6$	bsr	connrtotext
	moveq.l	#4,d0
	move.l	a3,a1
	bsr	strcopyrfill
	move.b	#' ',(a1)+
	move.l	a1,a3

; dl tid.
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq.b	2$				; Yepp. no time.
	move.l	#0,d0
	moveq.l	#0,d1
	move.w	(cpsrate,NodeBase),d1
	beq.b	21$
	move.l	d2,d0
	beq.b	21$
	divu.w	d1,d0
	andi.l	#$ffff,d0
	divu.w	#60,d0
	andi.l	#$ffff,d0
21$	bsr	connrtotext
	moveq.l	#3,d0
	move.l	a3,a1
	bsr	strcopyrfill
	bra.b	3$
	ENDC
2$	lea	(minustext),a0
	moveq.l	#3,d0
	bsr	strcopylen
3$	move.b	#'m',(a1)+
	move.l	a1,a3

	move.l	(AntallDLs,a2),d2
	cmpi.l	#999,d2
	bhi.b	4$
	move.b	#' ',(a3)+
4$	move.l	d2,d0
	bsr	connrtotext
	moveq.l	#3,d0
	move.l	a3,a1
	bsr	strcopyrfill
	move.b	#' ',(a1)+

	lea	(Filedescription,a2),a0
	bsr	strlen
	cmpi.w	#Sizeof_FileDescription,d0
	bls.b	1$
	moveq.l	#Sizeof_FileDescription,d0
1$	lea	(Filedescription,a2),a0
	bsr	strcopylen
	move.b	#0,(a1)
	pop	a2/d2/d3/a3
	rts

; a0 = fileinfo
; a1 = string
dofileinfoline2
	push	a2/a3
	move.l	a0,a2
	tst.b	(tmpsysopstat,NodeBase)
	bne.b	12$
	move.w	(confnr,NodeBase),d0		; har vi en conf ?
	cmpi.w	#-1,d0
	beq	9$				; nei.
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Sysop,d0
	beq	9$				; nei

12$	lea	(fromktext),a0
	bsr	strcopy
	lea	(-1,a1),a3			; oppdaterer string pointer
	move.l	(Uploader,a2),d0
	bsr	getusername
	move.l	a3,a1
	bsr	strcopy
	subq.l	#1,a1
	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_PrivateUL+FILESTATUSF_PrivateConfUL,d0
	beq.b	10$
	lea	(tonoansitext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.w	(Filestatus,a2),d1		; til en person ?
	andi.w	#FILESTATUSF_PrivateUL,d1
	beq.b	5$				; nei.
	lea	(userspacetext),a0
	bsr	strcopy
	lea	(-1,a1),a3			; oppdaterer string pointer
	move.l	(PrivateULto,a2),d0
	bsr	getusername
	move.l	a3,a1
	bsr	strcopy
	subq.l	#1,a1
	bra.b	10$
5$	lea	(confspacetext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	(PrivateULto,a2),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
	bsr	strcopy
	subq.l	#1,a1
10$	move.w	(Filestatus,a2),d0
	andi.w	#FILESTATUSF_FreeDL,d0		; Free DL ?
	beq.b	9$
	lea	freedltext,a0
	bsr	strcopy
	subq.l	#1,a1
9$	move.b	#0,(a1)
	pop	a2/a3
	rts

; a0 = message header
; d0 = msgbuffer size
; a1 = msgbuffer
; d1 = realmsgbuffer start
calleditor
	push	a2/a3/d2
	move.l	a0,a2
	move.l	a1,a3
	move.l	d0,d2
	move.l	d1,a1
	move.l	(MsgTo,a0),d0
	moveq.l	#-1,d1
	cmp.l	d1,d0
	bne.b	1$
	lea	(alltext),a0
	bra.b	2$
1$	setn
	bsr	gettoname1
	move.w	(NrLines,a2),d0
	bpl.b	2$			; ikke negativ
	neg.w	d0
	move.w	d0,(NrLines,a2)		; Later som om det ikke er net melding videre
2$	lea	(maintmptext,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen
	move.l	a2,a0
	cmpi.b	#2,(FSEditor,NodeBase)	; skal vi includere ?
	beq.b	5$			; Ja
	move.w	#0,(NrLines,a0)
	bra.b	6$
5$	move.l	a3,a1
	moveq.l	#0,d0
	move.w	(NrBytes,a0),d0
	adda.l	d0,a1
	move.b	#0,(a1)				; kan være farlig (vi kan være
	move.b	#0,(1,a1)			; på enden allerede (FIX ME)
6$	move.w	(confnr,NodeBase),d1
	lea	(n_FirstConference+CStr,MainBase),a1	; tvinger privat hvis post conf..
	mulu	#ConferenceRecord_SIZEOF/2,d1
	move.w	(n_ConfSW,a1,d1.l),d1
	btst	#CONFSWB_PostBox,d1
	beq.b	4$
	move.b	#SECF_SecReceiver,(Security,a0)
4$	move.l	a2,a0
	move.l	a3,a1
	move.l	d2,d0
	move.w	(Userbits+CU,NodeBase),d1
	btst	#USERB_FSE,d1
	bne.b	3$
	bsr	editor
	bra.b	9$
3$	move.w	#78,d1				; WindowWith
	bsr	fseeditor
9$	pop	a2/a3/d2
	rts

; a0 = script
; a1 = param
executedosscriptparam
	push	d2/d3
	move.l	a0,d2
	move.l	a1,d3
	move.l	(tmpmsgmem,NodeBase),a1		; kan bli for lang for tmptext..
	lea	(executestring),a0		; Bygger opp exec string
	bsr	strcopy
	subq.l	#1,a1
	move.l	d2,a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	d3,a0
	bsr	strcopy
	tst.b	(Tinymode,NodeBase)
	bne.b	2$
	lea	(nyconfgrabtext),a0
	moveq.l	#3,d0
	bsr	writecontextlen
	move.l	(tmpmsgmem,NodeBase),a0
	bsr	writecontext
	bsr	newconline
2$
	move.l	(tmpmsgmem,NodeBase),a0		; kjører scriptet
	move.l	a0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.l	(dosbase),a6
	jsrlib	Execute
	move.l	(exebase),a6
	pop	d2/d3
	rts

executedosscript
	push	d2/d3
	move.l	(dosbase),a6
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d2
	beq.b	9$
	move.l	#nulltext,d1
	moveq.l	#0,d3
	jsrlib	Execute
8$	move.l	d2,d1
	jsrlib	Close
9$	move.l	(exebase),a6
	pop	d2/d3
	rts

;fyller i <confnavn><tall>
; a0 = buffer
; d0.w = bullet nr, d1.w = conf nr. * 1 (OBS)
getkonfbulletnamenopath
	exg	d0,d1
	movem.l	d0/d1,-(sp)
	move.l	a0,a1
	bra.b	getkonfbulletname1

;fyller i <path><confnavn><tall>
; a0 = buffer
; d0.w = bullet nr, d1.w = conf nr. * 1 (OBS)
getkonfbulletname
	exg	d0,d1
	movem.l	d0/d1,-(sp)
	move.l	a0,a1
	lea	(bulletinpath),a0
	bsr	strcopy
	subq.l	#1,a1
getkonfbulletname1
	move.l	(sp)+,d0		; henter ut konf navn.
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
1$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	2$
	move.b	d0,(a1)+
	cmpi.b	#'/',d0
	bne.b	1$
	move.b	#' ',(-1,a1)
	bra.b	1$
2$	move.l	(sp)+,d0		; henter ut bullet nr.
	move.l	a1,a0
	andi.l	#$ffff,d0
	bra	konverter

;fyller i <path><confnavn>bl i buffer
; a0 = buffer
; d0 = conf nr. * 1 (OBS)
getkonfbulletlist
	move.l	a0,a1
	move.w	d0,-(sp)
	lea	(bulletinpath),a0
	bsr	strcopy
	subq.l	#1,a1
	move.w	(sp)+,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
1$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	2$
	move.b	d0,(a1)+
	cmpi.b	#'/',d0
	bne.b	1$
	move.b	#' ',(-1,a1)
	bra.b	1$
2$	lea	(bulletlisttext),a0
	bra	strcopy

*****************************************************************
*	JEO3		Log file rutiner			*
*****************************************************************

writelogtexttimedd
	move.l	a1,-(sp)
	lea	(tmpmsgheader,NodeBase),a1
	bsr	strcopy			; fra a0 til a1 Navnet
	move.b	#' ',(-1,a1)
	move.l	(sp)+,a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
;	move.l	a2,a0			; Skriver ikke ut passord i loggen
;	bsr	strcopy
	lea	(tmpmsgheader,NodeBase),a0
	bra	writelogtexttime

writelogtexttimed
	move.l	a1,-(sp)
	lea	(tmpmsgheader,NodeBase),a1
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	(sp)+,a0
	bsr	strcopy
	lea	(tmpmsgheader,NodeBase),a0
	bra.b	writelogtexttime

writelogstartup
	movem.l	d2/d3/a2,-(sp)
	move.l	a0,a2
	lea	(tmptext,NodeBase),a0
	move.l	a0,d1

	move.l	a6,-(a7)
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(a7)+,a6
	lea	(tmptext,NodeBase),a0
	bsr	datestampetodate
	move.l	d1,d3
	lea	(tmpmsgheader,NodeBase),a0
	exg	d2,d0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#'/',(a0)+
	move.l	d3,d0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#'-',(a0)+
	move.l	d2,d0
	andi.l	#$ffff,d0
	divu.w	#100,d0
	swap	d0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#' ',(a0)+
	move.l	a2,a1
	exg	a0,a1
	bsr	strcopy
	lea	(tmpmsgheader,NodeBase),a0
	movem.l	(sp)+,d2/d3/a2

writelogtexttime
	push	a2/d2
	link.w	a3,#-80
	move.l	a0,a2
	move.l	sp,a0
	move.l	a0,d1
	move.l	a6,d2
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	d2,a6
	move.l	(ds_Minute,sp),d0
	divu.w	#60,d0
	move.l	d0,d2
	move.l	sp,a0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#':',(a0)+
	move.l	d2,d0
	move.w	#0,d0
	swap	d0
	bsr	nr2tostr
	move.b	#' ',(a0)+
	move.l	a0,a1
	move.l	a2,a0
	bsr	strcopy
	move.l	sp,a0
	lea	(logfilename,NodeBase),a1
	bsr.b	writelogtextline
	unlk	a3
	pop	a2/d2
	rts


; a0 - linje å skrive,
; a1 - filnavn
writelogtextline
	push	d2-d4/a2/a6
	move.l	a0,a2
	move.l	(dosbase),a6
	move.l	a1,a0
	bsr	openreadseekend
	beq.b	9$
	move.l	d0,d4
	move.l	a2,a0
	bsr	strlen
	move.l	d0,d1
	neg.l	d0
	move.l	a2,a1
	moveq.l	#70,d3
	cmp.l	d1,d3				; for lang ?
	bhi.b	1$				; nei
	move.l	d3,d1				; ja, kutter
	adda.l	d1,a1
	bra.b	2$
1$	adda.l	d1,a1
	add.l	d3,d0
	subq.l	#1,d0
	lea	(spacetext),a0
	bsr	strcopylen
2$	move.b	#10,(a1)
	move.b	#0,(1,a1)
	move.l	a2,d2
	move.l	d4,d1
	jsrlib	Write
;	cmp.l	d0,d3
;	bne.b	7$
8$	move.l	d4,d1
	jsrlib	Close
9$	pop	d2-d4/a6/a2
	rts

; a0 - text 1
; a1 - text 2
writetosysoptextd
	move.l	a1,-(sp)
	lea	(tmpmsgheader,NodeBase),a1
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	(sp)+,a0
	bsr	strcopy
	lea	(tmpmsgheader,NodeBase),a0
	lea	(tosysopfname),a1
	bra.b	writelogtextline

openreadseekend
	push	d2/d3/d4/a2
	move.l	a0,a2
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2	; finnes filen ?
	jsrlib	Open
	move.l	d0,d4
	bne.b	1$			; alt ok, går videre
	move.l	a2,d1			; da prøver vi en newfile
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
1$	moveq.l	#0,d2
	moveq.l	#OFFSET_END,d3
	move.l	d4,d1
	jsrlib	Seek
	exg	d0,d4
	moveq.l	#-1,d1
	cmp.l	d4,d1
	bne.b	9$
	move.l	d0,d1
	jsrlib	Close
	setz
9$	pop	d2/d3/d4/a2
	rts

*****************************************************************
*			string.h++				*
*****************************************************************

	XDEF	_msprintf
_msprintf:	; ( ostring, format, {values} )
sprintf:
	push	a2/a3/a6/a4
	move.l	(5*4,sp),a3       ;Get the output string pointer
	move.l	(6*4,sp),a0       ;Get the FormatString pointer
	lea.l	(7*4,sp),a1       ;Get the pointer to the DataStream
	lea.l	(stuffChar,pc),a2
	move.l	exebase,a6
	jsrlib	RawDoFmt
	pop	a2/a3/a6/a4	; May trash a4 if IPrefs is not run
	rts

;------ PutChProc function used by RawDoFmt -----------
stuffChar:
	move.b	d0,(a3)+        ;Put data to output string
	rts

******************************
;memclr	(from,length)
;	 a0.l d0.w
******************************
memclr	moveq	#0,d1
	subq.w	#1,d0
	bcs.b	9$
1$	move.b	d1,(a0)+
	dbf	d0,1$
9$	rts

******************************
;ptr = strrchr (string,char)
;d0		a0	d0
******************************
strrchr	sub.l	a1,a1
1$	move.b	(a0)+,d1
	beq.b	9$
	cmp.b	d0,d1
	bne.b	1$
	lea	-1(a0),a1
	bra.b	1$
9$	move.l	a1,d0
	rts

******************************
;ptr = strchr (string,char)
;d0		a0	d0
******************************
strchr	sub.l	a1,a1
1$	move.b	(a0)+,d1
	beq.b	9$
	cmp.b	d0,d1
	bne.b	1$
	lea	-1(a0),a1
9$	move.l	a1,d0
	rts

******************************
;len = strlen (string)
;d0		a0
;Må ikke røre a1...
******************************
strlen	move.l	a0,d0
1$	tst.b	(a0)+
	bne.b	1$
	subq.l	#1,a0
	suba.l	d0,a0
	move.l	a0,d0
	rts

******************************
;result = findtextinstring (streng,text)
;returns with next char after streng in a0, if found
;Z = 1 if found		    a0.l   a1.l
******************************
findtextinstring
	move.l	a2,-(a7)
	move.l	a1,a2				; husker søkeord
1$	move.l	a2,a1
2$	move.b	(a1)+,d0			; slutt på søker ordet ?
	beq.b	9$				; vi fant!
	bsr	upchar
	move.b	(a0)+,d1
	beq.b	8$				; slutt på stringen. not found
	exg	d0,d1
	bsr	upchar
	cmp.b	d1,d0
	bne.b	1$
	bra.b	2$
8$	notz
9$	move.l	(a7)+,a2
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
;result = comparestringsifull (streng,streng1,length)
;Zero bit		       a0.l   a1.l    d0.w
******************************
comparestringsifull
	push	d2
	move.w	d0,d2
	subq.w	#1,d2
1$	move.b	(a0)+,d0
	bsr	upchar
	move.b	d0,d1
	move.b	(a1)+,d0
	bsr	upchar
	cmp.b	d0,d1
	dbne	d2,1$
	pop	d2
	rts

******************************
;result = comparestrings (streng,streng1)
;Zero bit		  a0.l   a1.l
******************************
comparestrings
1$	move.b	(a0)+,d0
	beq.b	2$
	move.b	(a1)+,d1
	beq.b	3$
	cmp.b	d0,d1
	bne.b	9$
	bra.b	1$
2$	tst.b	(a1)
	rts
3$	clrz
9$	rts

******************************
;result = comparestringsicase (streng,streng1)
;Zero bit		       a0.l   a1.l
******************************
comparestringsicase
1$	move.b	(a0)+,d0
	beq.b	2$
	bsr	upchar
	move.b	d0,d1
	move.b	(a1)+,d0
	beq.b	3$
	bsr	upchar
	cmp.b	d0,d1
	bne.b	9$
	bra.b	1$
2$	tst.b	(a1)
	rts
3$	clrz
9$	rts

******************************
;strcopylen (fromstreng,tostreng1,length)
;memcopylen (fromstreng,tostreng1,length)
;	     a0.l	a1.l	  d0.w
******************************
strcopylen
memcopylen
	subq.l	#1,d0
	bcs.b	9$
1$	move.b	(a0)+,(a1)+
	dbf	d0,1$
9$	rts

******************************
;strcopyrlen (fromstreng,tostreng1,length)
;memcopyrlen (fromstreng,tostreng1,length)
;	      a0.l	 a1.l	   d0.w
******************************
strcopyrlen
memcopyrlen
	move.b	(a0),(a1)
	subq.w	#1,d0
	bcs.b	9$
1$	move.b	-(a0),-(a1)
	dbf	d0,1$
9$	rts


******************************
;strcopymaxlen (fromstreng,tostreng1,length)
;		a0.l	   a1.l	     d0.w
;Fyller ut med 0'er på slutten.
******************************
strcopymaxlen
	subq.w	#1,d0
2$	move.b	(a0)+,(a1)+
	beq.b	3$
	dbf	d0,2$
	move.b	#0,(a1)
	bra.b	9$
1$	move.b	#0,(a1)+
3$	dbf	d0,1$
9$	rts

******************************
;strcopylfill  (fromstreng,tostreng1,length)
;		a0.l	   a1.l	      d0.w
;Fyller ut med space'r på slutten.
******************************
strcopylfill
2$	move.b	(a0)+,(a1)+
	beq.b	3$
	dbf	d0,2$
	bra.b	9$
3$	subq.l	#1,a1
	subq.l	#1,d0
	bcs.b	9$
1$	move.b	#' ',(a1)+
	dbf	d0,1$
9$	rts

******************************
;strcopyrfill  (fromstreng,tostreng1,length)
;		a0.l	   a1.l	      d0.w
;Fyller ut med space'r på starten.
******************************
strcopyrfill
	push	d2/a2
	move.l	d0,d2
	move.l	a0,a2
	bsr	strlen
	sub.l	d0,d2
	exg	d0,d2
	tst.l	d0
	bmi.b	1$
	beq.b	1$
	lea	(spacetext),a0		; .. og jevner ut med space
	bsr	strcopylen
1$	move.l	a2,a0
	move.l	d2,d0
	bsr	strcopylen
	pop	d2/a2
	rts

******************************
;strrcopy (fromstreng,tostreng1)
;	  a0.l	     a1.l
;copys until end of fromstring in reverse order
******************************
strrcopy
	move.l	a2,-(a7)
	move.l	a0,a2
	bsr	strlen			; rører ikke a1 ...
	adda.l	d0,a1
	adda.l	d0,a2
	move.b	#0,(a1)			; Markerer slutten..
	subq.l	#1,d0
	bcs.b	9$
1$	move.b	-(a2),-(a1)
	dbf	d0,1$
9$	move.l	(a7)+,a2
	rts

******************************
;strrcopylen (fromstreng,tostreng1,length)
;	      a0.l	 a1.l	   d0
;copys until end of fromstring in reverse order
******************************
strrcopylen
	adda.l	d0,a1
	adda.l	d0,a0
	move.b	#0,(a1)			; Markerer slutten..
	subq.l	#1,d0
	bcs.b	9$
1$	move.b	-(a0),-(a1)
	dbf	d0,1$
9$	rts

******************************
;char = upchar (char)
;d0.b		d0.b
******************************

upchar	cmpi.b	#'a',d0
	bcs.b	1$
	cmpi.b	#'z',d0
	bhi.b	2$
	subi.b	#'a'-'A',d0
1$	rts
2$	cmpi.b	#224,d0		; Starten på utenlandske tegn (små)
	bcs.b	3$
	subi.b	#32,d0		; Forskjellen på Store og små ISO tegn.
3$	rts

******************************
;string = upstring (string)
;a0		    a0
;does a upchar on every char in string
******************************

upstring
	push	a0/d0
	move.l	a0,a1
3$	move.b	(a0)+,d0
	beq.b	1$
	bsr.b	upchar
	move.b	d0,(a1)+
	bra.b	3$
1$	pop	a0/d0
	rts

******************************
;string = upword (string)
;a0		  a0
;does a upchar on every char in the first
;word of string (space or null separates words)
******************************
upword	movem.l	a0/d0,-(sp)
	move.l	a0,a1
3$	move.b	(a0)+,d0
	beq.b	1$
	cmpi.b	#' ',d0
	beq.b	1$
	bsr.b	upchar
2$	move.b	d0,(a1)+
	bra.b	3$
1$	movem.l	(sp)+,a0/d0
	rts

;*****************************************************************************
;
;*****************************************************************************

	IFND DEMO
;d0 = conf nr.
;d1 = filhandler
;a0 = msgheader
;returner neg hvis error.
doscratchmsg
	push	a2/a3/d2/d3/d4
	move.l	d1,d2
	move.l	a0,a2
	move.w	d0,d4			; confnr
	move.l	(tmpmsgmem,NodeBase),a3	; text Buffer
	move.l	a3,a0
	move.l	a2,a1
	jsr	(loadmsgtext)
	setn
	bne	99$
	move.l	a2,a0
	move.w	d4,d0
	bsr	kanskrive		; Kan vi skrive ut denne ???
	bne	9$			; Nei.
	lea	(dubblecrtext),a0
	move.l	d2,d0
	bsr	writefileln
	beq	98$
	move.l	d2,d0
	move.l	a2,a0
	move.w	d4,d1
	move.l	a3,a1			; gir msgtext også for netnavn
	bsr	filemsgheader
	beq	98$
	move.w	(NrBytes,a2),d0
	move.b	#0,(0,a3,d0.w)		; Legger på en null på slutten.
	move.w	(NrLines,a2),d3
	beq.b	9$
	bpl.b	1$			; normal melding uten nett navn
	neg.w	d3			; gjør om til posetiv
	move.l	a3,a0
	bsr	skipnetnames		; increases a0, and decreases d0 to skip netuser names
	move.l	a0,a3
1$	move.l	a3,a0
2$	move.b	(a3)+,d0
	beq.b	3$
	cmpi.b	#10,d0
	bne.b	2$
	move.b	#0,(-1,a3)
3$	move.l	d2,d0
	bsr	doscratchline
	beq.b	98$			; Error
	subq.w	#1,d3
	bne.b	1$
;	lea	(newlinetext+1),a0	; legger på to NL etter meldingen
	lea	(nulltext),a0		; legger på en NL etter meldingen
	move.l	d2,d0
	bsr	doscratchline
	beq.b	98$			; Error
	moveq.l	#1,d0
	add.l	d0,(MsgaGrab+CU,NodeBase)	; opdaterer antall meldinger som er grab'a
	add.w	d0,(tmsgsdumped,NodeBase)
	move.l	(MsgTo,a2),d0		; er den til oss ?
	cmp.l	(Usernr+CU,NodeBase),d0
	bne.b	9$			; nei.
	move.b	(MsgStatus,a2),d0	; Har vi lest den ?
	btst	#MSTATB_MsgRead,d0
	bne.b	9$
	bset	#MSTATB_MsgRead,d0	; Setter read flag'et
	move.b	d0,(MsgStatus,a2)
	move.l	a2,a0
	move.w	d4,d0
	jsr	(savemsgheader)		; lagrer oppdatert header
9$	clrn
99$	pop	a2/a3/d2/d3/d4
	rts
98$	setn
	bra.b	99$

; a1 = msgtext (for netnavn)
; d0 = filehandle
; a0 = msgheader
; d1 = conf nr.
filemsgheader
	push	a2/d2/d3/d4
	link.w	a3,#-1024
	move.l	a0,a2
	move.l	d0,d2
	move.l	a1,d4				; husker msgtext

	move.w	d1,d0
	move.l	sp,a0
	move.l	#400,d1				; maks lengde på navn
	bsr	do1headerline
	beq	99$
	move.l	sp,a0
	move.l	d2,d0
	bsr	doscratchline
	beq	99$

	move.l	sp,a0
	bsr	do2headerline
	move.l	sp,a0
	bne.b	1$
	move.l	d2,d0
	bsr	doscratchline
	bra.b	99$
1$	move.l	d2,d0
	bsr	doscratchline
	beq.b	99$

	move.l	sp,a0
	bsr	do3headerline
	beq.b	2$
	move.l	sp,a0
	move.l	d2,d0
	bsr	doscratchline
	beq.b	99$

2$	move.l	sp,a0
	bsr	do4headerline
	beq.b	3$
	move.l	sp,a0
	move.l	d2,d0
	bsr	doscratchline
	beq.b	99$

3$	move.l	sp,a0
	move.b	#10,(a0)+			; NL mellom header og subj.
	move.l	d4,a1
	bsr	do5headerline
	move.l	d0,d3
	move.l	sp,a0
	move.l	d2,d0
	bsr	doscratchline
	beq.b	99$

	move.l	d3,d0
	move.l	sp,a0
	bsr	do6headerline
	move.b	#10,(-1,a0)			; NL mellom subj og text
	move.b	#0,(a0)
	move.l	sp,a0
	move.l	d2,d0
	bsr	doscratchline
	beq.b	99$

9$	clrz
99$	unlk	a3
	pop	a2/d2/d3/d4
	rts
	ENDC

;a0 = instring
doscratchline
	push	a2/d2
	link.w	a3,#-1024
	move.l	d0,d2
	move.l	a0,a2				; Gjør om til brukers tegnsett
	bsr	disposeansistuff
	move.l	sp,a0
	moveq.l	#0,d1				; output length
1$	move.b	(a2)+,d0
	beq.b	2$
	bsr	translateseroutstring
	cmp.w	#1020,d1			; sjekker maks lengde..
	bcs.b	1$
2$	move.b	#10,d0
	bsr	translateseroutstring
	clr.b	(a0)				; terminerer.
	move.l	sp,a0
	move.l	d2,d0
	bsr.b	writefileln
	unlk	a3
	pop	a2/d2
	rts

writefileln
	push	d2/d3/a6
	move.l	d0,d1
	move.l	a0,d2
	bsr	strlen
	move.l	d0,d3
	move.l	(dosbase),a6
	jsrlib	Write
	cmp.l	d3,d0
	notz
	pop	d2/d3/a6
	rts

; d0 = confnr
; a0 = msg header struct
; a1 = msgtext (for netnames)
typemsgheader
	push	a2/a3/d2
	move.l	a0,a2
	move.l	a1,a3
	lea	(tmptext,NodeBase),a0		; Kan skrive over i maintmptext også.
	moveq.l	#Sizeof_NameT,d1		; maks lengde på navn
	bsr	do1headerline			; får a1 som parameter
	beq	9$
	lea	(tmptext,NodeBase),a0
	bsr	writetexto
	beq	9$

	lea	(tmptext,NodeBase),a0		; Kan skrive over i maintmptext også.
	bsr	do2headerline
	lea	(tmptext,NodeBase),a0
	bne.b	1$
	bsr	writetexto
	bra.b	9$
1$	bsr	writetexto
	beq.b	9$

	lea	(tmptext,NodeBase),a0
	bsr	do3headerline
	beq.b	2$
	lea	(tmptext,NodeBase),a0
	bsr	writetexto
	beq.b	9$

2$	lea	(tmptext,NodeBase),a0
	bsr	do4headerline
	beq.b	3$
	lea	(tmptext,NodeBase),a0
	bsr	writetexto
	beq.b	9$

3$	bsr	outimage
	beq.b	9$
	lea	(tmptext,NodeBase),a0
	move.l	a3,a1
	bsr	do5headerline
	move.l	d0,d2
	lea	(tmptext,NodeBase),a0
	bsr	writetexto
	beq.b	9$

	move.l	d2,d0
	lea	(tmptext,NodeBase),a0
	bsr	do6headerline
	lea	(tmptext,NodeBase),a0
	bsr	writetexto

9$	pop	a2/a3/d2
	rts

; a0 = string to put line in
; a1 = msgtext (for netnavn)
; d0 = confnr
; d1 = maks lengde på utnavn...
do1headerline
	push	a3/d2/d3
	move.l	a0,a3
	move.l	a1,d2				; husker i d2
	move.l	d1,d3				; husker navn lengde
	btst	#MSTATB_Dontshow,(MsgStatus,a2)	; kan vi vise denne meldingen ?
	bne	99$				; nei.
	move.l	a0,a1
	lea	(msgstarttext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
	bsr	strcopy
	subq.l	#1,a1
	lea	(msgtext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	a1,a0
	move.l	(Number,a2),d0
	bsr	konverter
	move.l	a0,a1
	lea	(fromtext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.w	(NrLines,a2),d0
	bpl.b	6$			; normal melding
	move.l	d2,a0
	move.b	(a0)+,d0
	cmp.b	#Net_FromCode,d0	; from string her ?
	bne.b	6$			; nei... Tar vanelig navn
	move.l	d3,d1			; navn lengde
7$	move.b	(a0)+,d0
	move.b	d0,(a1)+
	subq.l	#1,d1
	bcs.b	71$			; kutter, slik at den ikke skal bli for lang
	cmp.b	#10,d0			; kommet til slutten ?
	bne.b	7$			; nei, fortsetter
71$	subq.l	#1,a1			; korigerer a1
	bra.b	1$			; går videre
6$	move.l	a1,-(a7)
	move.l	(MsgFrom,a2),d0
	bsr	getusername
	move.l	(a7)+,a1
	move.w	d0,-(sp)
	bsr	strcopy
	subq.l	#1,a1
	move.w	(sp)+,d0
	btst	#USERB_Killed,d0
	beq.b	1$
	lea	(deadtext),a0
	bsr	strcopy
	subq.l	#1,a1
1$	lea	(totext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(ansiwhitetext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	(MsgTo,a2),d0
	moveq.l	#-1,d1
	cmp.l	d1,d0
	bne.b	2$
	lea	(alltext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(ansilbluetext),a0
	bsr	strcopy
	subq.l	#1,a1
	bra	9$

2$	move.w	(NrLines,a2),d1
	bpl.b	10$			; normal melding
	move.l	d2,a0
	move.b	(a0)+,d1
	cmp.b	#Net_ToCode,d1		; to string ?
	beq.b	12$			; Ja, tar det
	cmp.b	#Net_FromCode,d1	; from string her ?
	bne.b	10$			; nei... Tar vanelig navn
	move.l	d3,d1			; navn lengde
11$	move.b	(a0)+,d0		; søker til neste linje
	cmp.b	#10,d0
	bne.b	11$
	move.b	(a0)+,d0
	cmp.b	#Net_ToCode,d0		; to string nå da ?
	bne.b	101$			; nei... Tar vanlig navn
12$	move.b	(a0)+,d0
	move.b	d0,(a1)+
	subq.l	#1,d1
	bcs.b	13$			; kutter, slik at den ikke skal bli for lang
	cmp.b	#10,d0			; kommet til slutten ?
	bne.b	12$			; nei, fortsetter
13$	subq.l	#1,a1			; korigerer a1
	bra.b	3$			; går videre

101$	move.l	(MsgTo,a2),d0
10$	move.l	a1,-(a7)
	bsr	getusername
	move.l	(a7)+,a1
	move.w	d0,-(sp)
	bsr	strcopy
	subq.l	#1,a1
	move.w	(sp)+,d0
	btst	#USERB_Killed,d0
	beq.b	3$
	lea	(deadtext),a0
	bsr	strcopy
	subq.l	#1,a1
3$	lea	(ansilbluetext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.b	(Security,a2),d0
	btst	#SECB_SecReceiver,d0
	beq.b	4$
	lea	(privatemsgtext),a0
	bsr	strcopy
	subq.l	#1,a1
4$	move.b	(MsgStatus,a2),d0
	btst	#MSTATB_MsgRead,d0
	beq.b	9$
	lea	(readmsgtext),a0
	bsr	strcopy
	subq.l	#1,a1
9$	lea	(dottext),a0
	bsr	strcopy
	move.b	#0,(a1)
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	bne.b	5$
	move.l	a3,a0
	bsr	disposeansistuff
5$	setz
99$	notz
	pop	a3/d2/d3
	rts

do2headerline
	push	a3
	move.l	a0,a3
	move.l	a0,a1
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	beq.b	1$
	lea	(msgkilledbytext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.b	(MsgStatus,a2),d0
	btst	#MSTATB_KilledByAuthor,d0
	beq.b	2$
	lea	(usertext),a0
	bra.b	4$
2$	btst	#MSTATB_KilledBySigop,d0
	beq.b	3$
	lea	(plainsigoptext),a0
	bra.b	4$
3$	lea	(plainsysoptext),a0
4$	bsr	strcopy
	setz
	bra.b	9$
1$	lea	(enteredontext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(MsgTimeStamp,a2),a0
	bsr	gettimestr
	addq.l	#5,a1
	move.b	#',',(a1)+
	move.b	#' ',(a1)+
	move.l	a1,a0
	move.w	(NrLines,a2),d0				; retter opp negative linjer (for netbrukere)
	bpl.b	6$
	neg.w	d0
6$	bsr	konverterw
	move.l	a0,a1
	move.b	#' ',(a1)+
	lea	(linesdottext),a0
	bsr	strcopy
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	bne.b	5$
	move.l	a3,a0
	bsr	disposeansistuff
5$	clrz
9$	pop	a3
	rts

do3headerline
	push	a3
	move.l	a0,a3
	move.l	a0,a1
	lea	(replytomsgntext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	(RefTo,a2),d0
	beq.b	9$
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	move.b	#'.',(a1)+
	move.b	#' ',(a1)+
	lea	(nomorereplytext),a0
	move.l	(RefNxt,a2),d0
	beq.b	1$
	lea	(morereplyhbtext),a0
1$	bsr	strcopy
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	bne.b	2$
	move.l	a3,a0
	bsr	disposeansistuff
2$	clrz
9$	pop	a3
	rts


do4headerline
	push	a3
	move.l	a0,a3
	move.l	a0,a1
	move.l	(RefBy,a2),d0
	beq.b	9$
	lea	(therearereptext),a0
	bsr	strcopy
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	bne.b	1$
	move.l	a3,a0
	bsr	disposeansistuff
1$	clrz
9$	pop	a3
	rts

; a0 = string to put line in
; a1 = msgtext (for netnavn)
do5headerline
	push	d2/d3
	move.l	a1,d2
	move.l	a0,a1
	move.l	a0,d3
	lea	(ansiyellowtext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(subjecttext),a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(Subject,a2),a0
	move.w	(NrLines,a2),d0
	bpl.b	2$			; normal melding
	move.b	(a0),d0
	bne.b	2$			; ikke nett subject
	move.l	d2,a0
	bsr	getnetsubject
	beq.b	3$
	move.w	#69,d1
6$	move.b	(a0)+,d0		; litt modifisert strcopymaxlen
	beq.b	7$
	move.b	d0,(a1)+
	cmp.b	#10,d0
	beq.b	7$
	dbf	d1,6$
7$	move.b	#0,(-1,a1)
	bra.b	5$

3$	lea	(Subject,a2),a0
2$	move.w	#Sizeof_NameT+1,d0
	bsr	strcopymaxlen
5$	move.l	d3,a0
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	bne.b	1$
	bsr	disposeansistuff
1$	move.l	d3,a0
	pop	d2/d3
	bra	strlen

do6headerline
	move.w	(Userbits+CU,NodeBase),d1
	andi.w	#USERF_ColorMessages,d1
	beq.b	1$			; ansi tegn fjerna
	subq.l	#5,d0			; fjerner ANSI tegnene
1$	move.b	#'=',(a0)+
	dbf	d0,1$
	move.b	#0,(-1,a0)
	rts

logoutsaveuser
	bsr	updatetime
	moveq.l	#0,d0
	move.w	(TimeUsed+CU,NodeBase),d0
	sub.w	(OldTimelimit,NodeBase),d0		; trekker fra minutter i forige session
	bcs.b	2$					; underflow.. Egentlig umulig..
	add.l	d0,(Totaltime+CU,NodeBase)
2$
	move.w	(FTimeUsed+CU,NodeBase),d0
	sub.w	(minul,NodeBase),d0
	bcc.b	1$
	moveq.l	#0,d0
1$	move.w	d0,(FTimeUsed+CU,NodeBase)

	lea	(u_startsave+CU,NodeBase),a0
	move.l	#u_almostendsave-u_startsave,d0
	bsr.b	saveuserarea
	bsr	savelastread
	rts

; a0 = området
; d0 = size
saveuserarea
	moveq.l	#0,d1		; ikke noe område nr 2
	suba.l	a1,a1

; a0 = oprådet 1
; d0 = size for 1
; a1 = oprådet 2
; d1 = size for 2
saveuserareas
	push	a2/d2/d4/d5/d6/a3
	move.l	a0,a2
	move.l	d0,d2
	move.l	a1,d4
	move.l	d1,d5
	move.l	(UserrecordSize+CStr,MainBase),d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	move.l	d0,a3
	tst.l	d0
	beq.b	8$				; error

	lea	(CU,NodeBase),a0		; finner offset
	move.l	a0,d6

	move.l	a3,a0
	move.l	(Usernr+CU,NodeBase),d0
	jsr	(loadusernr)
	beq.b	8$		; error
	move.l	a2,a0		; source
	move.l	a2,a1
	suba.l	d6,a1		; beregner offset
	adda.l	a3,a1		; finner dest
	move.l	d2,d0
	bsr	memcopylen

	move.l	d4,a0		; source
	move.l	d4,a1
	suba.l	d6,a1		; beregner offset
	adda.l	a3,a1		; finner dest
	move.l	d5,d0
	beq.b	1$		; ikke noe område nr 2.
	bsr	memcopylen

1$	move.l	(Usernr+CU,NodeBase),d0
	move.l	a3,a0
	jsr	(saveusernr)
	bne.b	9$
8$	lea	(saveusererrtext),a0
	bsr	writetexto
	setz
9$	move.l	a3,d0
	beq.b	99$			; ikke noe memory
	move.l	(UserrecordSize+CStr,MainBase),d0
	move.l	a3,a1
	jsrlib	FreeMem
99$	pop	a2/d2/d4/d5/d6/a3
	rts

savelastread
	push	a2
	move.l	(Tmpusermem,NodeBase),a2
	move.l	a2,a0
	move.l	(Usernr+CU,NodeBase),d0
	jsr	(loadusernr)
	beq.b	8$		; error

	moveq.l	#0,d0
	move.w	(Maxconferences+CStr,MainBase),d0
	lea	(u_almostendsave+CU,NodeBase),a0
	lea	(u_almostendsave,a2),a1
	moveq.l	#Userconf_seizeof,d1
1$	move.l	(uc_LastRead,a0),(uc_LastRead,a1)
	add.l	d1,a0
	add.l	d1,a1
	subq.l	#1,d0
	bne.b	1$

	move.l	(Usernr+CU,NodeBase),d0
	move.l	a2,a0
	jsr	(saveusernr)
	bne.b	9$
8$	lea	(saveusererrtext),a0
	bsr	writetexto
	setz
9$	pop	a2
	rts

	IFND DEMO
; d0 = baud
; d1 = skal sende AT etter på (bool)
setserialspeed
	push	d2
	move.l	d1,d2
	move.w	(Setup+Nodemem,NodeBase),d1
	btst	#SETUPB_Lockedbaud,d1
	bne.b	9$
	move.l	d0,-(sp)			; husker baud'en
	bsr	waitseroutput
	move.l	(sreadreq,NodeBase),a1		; avbryter read req'en
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	move.w	#SDCMD_SETPARAMS,(IO_COMMAND,a1)	; setter baud + spes parametre
	move.l	(sp)+,(IO_BAUD,a1)
	move.w	(Setup+Nodemem,NodeBase),d1
	move.b	#0,(IO_SERFLAGS,a1)		; Null stiller.
;	btst	#SETUPB_XonXoff,d1		; Vi tillater ikke XonXoff lenger
;	bne.b	2$
	move.b	#SERF_XDISABLED|SERF_RAD_BOOGIE,(IO_SERFLAGS,a1)
2$	btst	#SETUPB_RTSCTS,d1
	beq.b	3$
	ori.b	#SERF_7WIRE,(IO_SERFLAGS,a1)
3$	jsrlib	DoIO
	tst.l	d2				; skal vi sende AT ?
	beq.b	9$				; nei.
	lea	(ModemATString+Nodemem,NodeBase),a0	; Sender at string.
	bsr	serwritestringdo
	moveq.l	#2,d0
	lea	(transnltext),a0
	bsr	serwritestringlendo
9$	pop	d2
	rts

stopserreadcheck
	move.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	stopserread
	move.l	(sreadreq,NodeBase),a1			; henter eventuell msg
	move.l	(MN_REPLYPORT,a1),a0
	jmplib	GetMsg

stopserread
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jmplib	WaitIO

initserread
	btst	#DoDivB_Sleep,(DoDiv,NodeBase)	; sleep igang ?
	bne.b	9$				; jepp.. nop
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	lea	(ser_tegn,NodeBase),a0
	moveq.l	#1,d0
	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a0,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	jmplib	SendIO
9$	rts

flushserialbuffer
	bsr	waitseroutput
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	move.w	#CMD_CLEAR,(IO_COMMAND,a1)
	jsrlib	DoIO
	bra.b	initserread
	ENDC

initcsreadcheck
	move.l	(creadreq,NodeBase),d0
	beq.b	1$					; no console
	move.l	d0,a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	1$
	move.l	(creadreq,NodeBase),a1
	jsrlib	WaitIO
	bsr	initconread
1$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)
	beq.b	9$
	move.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	9$
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	bsr	initserread
	ENDC
9$	rts

stopconreadcheck
	move.l	(creadreq,NodeBase),d0
	beq.b	9$					; no console
	move.l	d0,a1
	jsrlib	CheckIO
	tst.l	d0
	bne.b	1$
	move.l	(creadreq,NodeBase),a1
	jsrlib	AbortIO
1$	move.l	(creadreq,NodeBase),a1
	jmplib	WaitIO
9$	rts

initconread
	move.l	(creadreq,NodeBase),d0
	beq.b	9$					; no console
	move.l	d0,a1
	lea	(con_tegn,NodeBase),a0
	moveq.l	#1,d0
	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a0,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	jmplib	SendIO
9$	rts

waitsecs
	move.l	(timer1req,NodeBase),a1
	move.l	d0,(TV_SECS+IOTV_TIME,a1)
	moveq.l	#0,d0
	move.l	d0,(TV_MICRO+IOTV_TIME,a1)
	move.w	#TR_ADDREQUEST,(IO_COMMAND,a1)
	jmplib	DoIO

waitmicros
	move.l	(timer1req,NodeBase),a1
	move.l	d0,(TV_MICRO+IOTV_TIME,a1)
	moveq.l	#0,d0
	move.l	d0,(TV_SECS+IOTV_TIME,a1)
	move.w	#TR_ADDREQUEST,(IO_COMMAND,a1)
	jmplib	DoIO

; d0 = antall minutter
starttimeouttimer
	mulu.w	#60,d0				; gjør om til sekunder
	bne.b	1$
	moveq.l	#10,d0				; For sikkerhets skyld
1$
; d0 = antall sekunder
starttimeouttimersec
	move.l	(timer2req,NodeBase),a1
	move.l	d0,(TV_SECS+IOTV_TIME,a1)
	moveq.l	#0,d0
	move.l	d0,(TV_MICRO+IOTV_TIME,a1)
	move.w	#TR_ADDREQUEST,(IO_COMMAND,a1)
	jmplib	SendIO

stoptimeouttimer
	move.l	(timer2req,NodeBase),a1		; er det en req i gang ?
	jsrlib	CheckIO
	tst.l	d0
	bne.b	1$				; nei. Sletter bit'et (paranoid)
	move.l	(timer2req,NodeBase),a1
	jsrlib	AbortIO
	move.l	(timer2req,NodeBase),a1
	jsrlib	WaitIO
	bra.b	2$
1$	move.l	(timer2req,NodeBase),a1		; henter eventuell msg
	move.l	(MN_REPLYPORT,a1),a0
	jsrlib	GetMsg
2$	move.l	(timer2sigbit,NodeBase),d1	; sletter dette bit'et
	move.l	d1,d0
	not.l	d0
	and.l	d0,(gotbits,NodeBase)		; virkerlig
	moveq.l	#0,d0
	jsrlib	SetSignal
9$	rts

testiso
1$	move.b	(a0)+,d0		; Tester om vi har ascii 128-160
	beq.b	9$			; eller {|}[\], som er 7bits tegn
	cmpi.b	#'[',d0
	bcs.b	1$
	cmpi.b	#']',d0
	bls.b	8$			; a >= b
	cmpi.b	#'{',d0
	bcs.b	1$
	cmpi.b	#'}',d0
	bls.b	8$			; a >= b
	cmpi.b	#128,d0
	bcs.b	1$
	cmpi.b	#160,d0
	bhi.b	1$
8$	clrz
9$	rts

;a0 = source file
;a1 = dest file
movedosfile
	push	a0/a1/d2/d3/d4/a6
	move.l	a0,d3
	move.l	a1,d4
	bsr	comparestringsicase		; samme sted ?
	beq.b	8$				; ja, move "ferdig"

	move.l	d3,d1				; Prøver rename
	move.l	d4,d2
	move.l	(dosbase),a6
	jsrlib	Rename
	tst.l	d0
	bne.b	9$				; rename gikk bra. Alt ok

	move.l	d3,a0				; prøver copy
	move.l	d4,a1
	bsr	copyfile
	beq.b	9$
	move.l	d3,a0
	bsr	deletefile
8$	clrz
9$	pop	a0/a1/d2/d3/d4/a6
	rts

; a0 - source
; a1 - destination
copyfile
	push	a2/a3/d2-d7
	link.w	a3,#-160
	move.l	a3,d6
	move.l	a0,a2
	move.l	a1,a3
	move.l	a2,a0
	move.l	a3,a1
	bsr	comparestringsicase
	notz
	bne	99$

	move.l	sp,a1			; prøver copy <source> <dest>
	lea	copystring,a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	a2,a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.l	a3,a0
	bsr	strcopy

	lea	(nilstring),a0
	move.l	a0,d1
	move.l	#MODE_READWRITE,d2
	move.l	(dosbase),a6
	jsrlib	Open
	move.l	(exebase),a6
	move.l	d0,d7
	beq.b	3$				; klarte ikke åpne nil fil

	tst.b	(Tinymode,NodeBase)		; tiny mode ?
	bne.b	1$				; ja, ingen console output
	move.l	(exebase),a6
	lea	(nyconfgrabtext),a0		; skriver copy string til con
	moveq.l	#3,d0
	jsr	(writecontextlen)
	move.l	sp,a0
	jsr	(writecontext)
	jsr	(newconline)
1$	move.l	sp,a0
	move.l	a0,d1
	moveq.l	#0,d2
	move.l	d7,d3
	move.l	(dosbase),a6
	jsrlib	Execute				; utfører selve copy'n
	move.l	d7,d1
	jsrlib	Close				; lukker NIL fil igjen.
	move.l	(exebase),a6
	move.l	a3,a0
	bsr	getfilelen			; kom det en fil dit ?
	bne	99$				; jepp.

;	move.l	a0,d1
;	move.l	(systemtagsnow),a0
;	move.l	d7,(4,a0)
;	move.l	a0,d2
;	move.l	(dosbase),a6
;	jsrlib	SystemTagList
;	move.l	d7,d1
;	jsrlib	Close				; lukker NIL fil igjen.
;	move.l	(exebase),a6
;	move.l	a3,a0
;	bsr	getfilelen			; kom det en fil dit ?
;	bne.b	99$				; jepp.

3$	moveq.l	#0,d7			; ikke ok (enda)
	move.l	(dosbase),a6
	move.l	a2,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d5
	beq.b	9$

	move.l	a3,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	8$

	move.l	(tmpmsgmem,NodeBase),a0
	move.l	a0,d2
2$	move.l	d5,d1
	move.l	(msgmemsize,NodeBase),d3
	jsrlib	Read
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	7$			; File error
	tst.l	d0
	beq.b	6$			; EOF, ferdig.
	move.l	d4,d1
	move.l	d0,d3
	jsrlib	Write
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	7$			; File error
	cmp.l	d3,d0			; Sjekker mot buffer
	beq.b	2$
	bra.b	7$			; write error
6$	moveq.l	#1,d7			; Gikk ok
7$	move.l	d4,d1
	jsrlib	Close
8$	move.l	d5,d1
	jsrlib	Close
	move.l	a2,a0
	bsr	getfilelen
	move.l	a3,d1
	move.l	(infoblock,NodeBase),a0
	lea	(fib_Comment,a0),a0
	move.b	(a0),d2				; er det noe der ?
	beq.b	9$				; nei, dropper setcomment
	move.l	a0,d2
	move.l	(dosbase),a6
	jsrlib	SetComment			; prøver å sette description som file comment.
9$	tst.l	d7
99$	move.l	d6,a3
	unlk	a3
	pop	a2/a3/d2-d7
	move.l	(exebase),a6
	rts
98$	setz
	bra.b	99$

systemtagsnow
	dc.l	SYS_Output,0
	dc.l	TAG_DONE,0

registeruser
	lea	(Name+CU,NodeBase),a0
	lea	banfilename,a1
	jsr	(checkbanfile)
	bne.b	5$
	lea	(namebannedtext),a0
	bsr	writeerroro
	move.b	#Thrownout,(readcharstatus,NodeBase)
	setz
	bra	9$
5$	bsr	stoptimeouttimer		; stanser timeout'en
	move.w	(SleepTime+CStr,MainBase),d0		; får sleeptime * 3 minutter til jobben
	add.w	d0,d0
	add.w	(SleepTime+CStr,MainBase),d0
	bsr	starttimeouttimer
	move.w	#24,(PageLength+CU,NodeBase)
	move.w	#24,(linesleft,NodeBase)
	lea	(register1finame),a0
	moveq.l	#0,d0
	bsr	typefile
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
4$	lea	(pass_10+CU,NodeBase),a0		; Skal slette alt untatt navnet.
	move.l	(UserrecordSize+CStr,MainBase),d0
	sub.l	#Sizeof_NameT,d0
	lea	(0,a0,d0.l),a1
	moveq.l	#0,d0
1$	move.w	d0,(a0)+
	cmpa.l	a0,a1
	bhi.b	1$
	moveq.l	#-1,d0
	move.l	d0,(Usernr+CU,NodeBase)		; Forhinrer reloaduser av supersysop
	move.w	d0,(linesleft,NodeBase)		; Vi vil ikke ha noen more her..
	move.w	#24,(PageLength+CU,NodeBase)

	lea	(Name+CU,NodeBase),a0			; oppdaterer Who's on
	bsr	changenodestatusname
	moveq.l	#64,d0			; Status = Newuser regestration.
	jsr	(changenodestatus)

	moveq.l	#Sizeof_PassT,d0
	lea	(logonpasswdtext),a0
	lea	(Password+CU,NodeBase),a1
	moveq.l	#0,d1
	bsr	getregisterinput
	beq	9$
	lea	(Password+CU,NodeBase),a0
	lea	(CU,NodeBase),a1
	bsr	insertpasswd

	moveq.l	#29,d0
	lea	(addresstext),a0
	lea	(Address+CU,NodeBase),a1
	moveq.l	#0,d1
	bsr	getregisterinput
	beq	9$

	moveq.l	#29,d0
	lea	(postalcodetext),a0
	lea	(CityState+CU,NodeBase),a1
	moveq.l	#0,d1
	bsr	getregisterinput
	beq	9$

	moveq.l	#15,d0
	lea	(hometlfnumbtext),a0
	lea	(HomeTelno+CU,NodeBase),a1
	moveq.l	#0,d1
	bsr	getregisterinput
	beq	9$

	moveq.l	#15,d0
	lea	(worktlfnumbtext),a0
	lea	(WorkTelno+CU,NodeBase),a1
	moveq.l	#0,d1
	bsr	getregisterinput
	beq	9$

	lea	(satisfiedtext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	bne.b	3$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bra	4$

3$	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase) ; Ny side..
	lea	(register2finame),a0
	moveq.l	#0,d0
	bsr	typefile
	moveq.l	#0,d0
	lea	(CU,NodeBase),a0
	bsr	newgetpasswd
	bne	2$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
	bra	4$
2$	bsr	outimage
	beq	9$

	move.w	(NewUserTimeLimit+CStr,MainBase),(TimeLimit+CU,NodeBase)
	move.w	(NewUserFileLimit+CStr,MainBase),(FileLimit+CU,NodeBase)
	move.b	(DefaultCharSet+CStr,MainBase),(Charset+CU,NodeBase)
	move.w	#28,(PageLength+CU,NodeBase)
	move.w	#SAVEBITSF_ReadRef,(Savebits+CU,NodeBase)
	move.b	#1,(ScratchFormat+CU,NodeBase)			; setter ARC som default pakker

	bset	#DIVB_InNewuser,(Divmodes,NodeBase)
	lea	(newuserscrname),a0
	sub.l	a1,a1					; ingen feilmelding
	jsr	(doarexxdoor)
	bclr	#DIVB_InNewuser,(Divmodes,NodeBase)
	bsr	(checkcarriercheckser)
	beq	9$					; carrier borte
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$

	bsr	registerconferencesnewuser

	move.l	(msg,NodeBase),a1
	move.w	#Main_createuser,(m_Command,a1)
	lea	(CU,NodeBase),a0
	move.l	a0,(m_Data,a1)
	lea	(Name,a0),a0
	move.l	a0,(m_Name,a1)
	jsr	(handlemsg)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0

	cmpi.w	#Error_OK,d0
	beq.b	8$
	jsr	skrivnrw
	jsr	outimage
	move.l	(dosbase),a6
	move.l	#10*50,d1
	jsrlib	Delay
	move.l	(exebase),a6

;	cmp.w	#Error_Found,d0
;	beq.b	8$
;	#Error_Open_File
	moveq	#-1,d0
	rts
8$	lea	(Name+CU,NodeBase),a1		; skriver til log'en.
	lea	(logregusertext),a0
	bsr	writelogtexttimed
	lea	(tosysopnewuser),a0
	lea	(Name+CU,NodeBase),a1		; skriver til ToSysop
	bsr	writetosysoptextd
	clrzn
9$	rts

registerconferencesnewuser
	move.w	#ACCF_Read,d0			; setter news access etter
	move.b	(Cflags+CStr,MainBase),d1	; hva som er instillt i
	btst	#CflagsB_Download,d1		; config'en (om nye brukere
	beq.b	1$				; får DL/UL status med en gang)
	ori.w	#ACCF_Download,d0
1$	btst	#CflagsB_Upload,d1
	beq.b	2$
	ori.w	#ACCF_Upload,d0
2$	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	d0,(uc_Access,a0)
	lea	(Userconf_seizeof,a0),a0
	move.w	#ACCF_Read+ACCF_Write,(uc_Access,a0)	; Joiner Post.
	lea	(ConferenceRecord_SIZEOF+n_FirstConference+CStr,MainBase),a1
	move.l	(n_ConfDefaultMsg,a1),(uc_LastRead,a0)	; Setter Last read i POST.
	lea	(yaaamotfcontext),a0
	bsr	11$
	push	a2/a3/d2/d3
	lea	(2*Userconf_seizeof+u_almostendsave+CU,NodeBase),a3
	lea	(n_FirstConference+CStr,MainBase),a2
	lea	(n_ConfName,a2),a0		; skriver ut news
	bsr	10$
	lea	(ConferenceRecord_SIZEOF,a2),a2
	lea	(n_ConfName,a2),a0		; post
	bsr	10$
	lea	(ConferenceRecord_SIZEOF,a2),a2
	moveq.l	#0,d2
	move.w	(Maxconferences+CStr,MainBase),d2
	subq.l	#2,d2				; har tatt to allerede
3$	subq.l	#1,d2
	bcs	9$				; vi er ferdige
	move.b	(n_ConfName,a2),d0		; er det en konferanse her ?
	beq.b	4$				; nei..
	move.w	(n_ConfSW,a2),d3		; henter conf access
	btst	#CONFSWB_VIP,d3			; vip ?
	bne.b	4$				; ja
	btst	#CONFSWB_ImmRead,d3		; er det autojoin ?
	beq.b	4$				; nei

	move.w	#ACCF_Read,d0			; melder bruker inn i conf'en
	btst	#CONFSWB_ImmWrite,d3
	beq.b	5$
	ori.w	#ACCF_Write,d0
5$	move.w	d0,(uc_Access,a3)
	lea	(n_ConfName,a2),a0
	bsr	10$

	btst	#CONFSWB_PostBox,d3		; Er dette en post conf ?
	bne.b	6$				; jepp
	moveq.l	#0,d0
	move.w	(n_ConfMaxScan,a2),d0		; henter maks scan verdien
	move.l	(n_ConfDefaultMsg,a2),d1
	cmp.l	d1,d0				; er det mere enn maks scan ?
	bcc.b	4$				; nei
	sub.l	d0,d1
	move.l	d1,(uc_LastRead,a3)			; justerer
	bra.b	4$
6$	move.l	(n_ConfDefaultMsg,a2),(uc_LastRead,a3)	; Setter Last read til max
4$	lea	(ConferenceRecord_SIZEOF,a2),a2
	lea	(Userconf_seizeof,a3),a3
	bra	3$
9$	pop	a2/a3/d2/d3
	rts

10$	move.l	a0,-(a7)
	lea	(spacetext),a0
	moveq.l	#3,d0
	bsr	writetextlen
	move.l	(a7)+,a0
11$	bsr	writetext
	bra	outimage

getregisterinput
	push	d3/d2/a2/a3
	move.l	d0,d2
	move.l	d1,d3
	move.l	a0,a2
	move.l	a1,a3
1$	bsr	outimage
	moveq.l	#42,d0
	lea	(spacetext),a0
	bsr	writetextlen
	move.l	d2,d0
	addq.l	#1,d0
	lea	(bordertext),a0
	bsr	writetextlen
	move.b	#'>',d0
	bsr	writechar
	bsr	outimage
	lea	(pleaseentertext),a0
	bsr	writetext
	move.l	a2,a0
	moveq.l	#24,d0
	bsr	writetextlfill
	bsr	breakoutimage
	move.l	d2,d0
	addq.l	#1,d0
	tst.l	d3
	beq.b	3$
	push	d0
	move.l	a3,a0
	lea	(intextbuffer,NodeBase),a1
	bsr	strcopy
	pop	d0
	bsr	edline
	bra.b	4$
3$	bsr	getline
4$	bne.b	2$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq.b	9$
	lea	(youmustenttext),a0
	bsr	writetexti
	bra.b	1$
2$	move.l	a3,a1
	move.l	d2,d0
	bsr	strcopymaxlen
	move.l	a3,a0
	bsr	testiso
	beq.b	8$
	lea	(musthaveisotext),a0
	bsr	writeerroro
	bra	1$
8$	clrz
9$	pop	d3/d2/a2/a3
	rts

;a0 - passord
;d0 - antall forsøk - 1
;a1 - passordtext
getpasswd
	lea	(pleaseepasstext),a1
	push	a2/d2/a3/d3/d4
	move.l	a1,d3
	move.b	#0,(readlinemore,NodeBase) ; flusher input'en for sikkerhets skyld
	move.l	a0,a2			; husker passordet
	move.l	d0,d2
	beq.b	1$			; ved login prøver vi 3 ganger. Ellers
	bset	#31,d2			; bare 0. Husker at dette er under login
1$	move.l	d3,a0			; Please text
	bsr	writetexti
	move.b	#1,(readingpassword,NodeBase)
	move.w	#Sizeof_PassT,d0
	bsr	getline
	bne.b	4$
	clr.b	(readingpassword,NodeBase)
	tst.b	(readcharstatus,NodeBase)
	bne	5$
4$	clr.b	(readingpassword,NodeBase)
	move.l	a2,a1
	move.l	a0,a3
	moveq.l	#7,d0
3$	move.b	(a0)+,d1
	cmp.b	(a1)+,d1
	dbne	d0,3$
	beq.b	9$
	lea	(wrongtext),a0	; Wrong!
	bsr	writetexto
	move.l	a3,a1
	btst	#31,d2
	beq.b	6$
	move.l	a2,d4
	move.l	a1,a2
	lea	(failedpaswdtext),a1	; Failed password
	lea	(Name+CU,NodeBase),a0	; Brukerens navn
	bsr	writelogtexttimedd
	move.l	d4,a2
6$	dbf	d2,1$
5$	clrn				; Galt passord
	setz
	bra.b	99$
9$	clrzn				; Riktig passord
99$	pop	a2/d2/a3/d3/d4
	rts

;a0 - userrecord
;d0 - antall forsøk - 1
;a1 - passordtext
newgetpasswd
	lea	(pleaseepasstext),a1
newgetpasswdtext
	push	a2/d2/a3/d3/d4
	move.l	a1,d3
	move.b	#0,(readlinemore,NodeBase) ; flusher input'en for sikkerhets skyld
	move.l	a0,a2			; husker userrecord
	move.l	d0,d2
	beq.b	1$			; ved login prøver vi 3 ganger. Ellers
	bset	#31,d2			; bare 0. Husker at dette er under login
1$	move.l	d3,a0
	bsr	writetexti
	move.b	#1,(readingpassword,NodeBase)
	move.w	#Sizeof_PassT,d0
	bsr	getline
	bne.b	4$
	clr.b	(readingpassword,NodeBase)
	tst.b	(readcharstatus,NodeBase)
	bne	5$
4$	clr.b	(readingpassword,NodeBase)
	move.l	a2,a1
	move.l	a0,a3			; husker input
	bsr	checkpasswd
	beq.b	9$
	lea	(wrongtext),a0
	bsr	writetexto
	move.l	a3,a1
	btst	#31,d2
	beq.b	6$
	move.l	a2,d4
	move.l	a1,a2
	lea	(failedpaswdtext),a1
	lea	(Name+CU,NodeBase),a0
	bsr	writelogtexttimedd
	move.l	d4,a2
6$	dbf	d2,1$
5$	clrn				; Galt passord
	setz
	bra.b	99$
9$	clrzn				; Riktig passord
99$	pop	a2/d2/a3/d3/d4
	rts

;a0 = passord
;a1 = userrecord
insertpasswd
	push	a2
	link.w	a3,#-20
	move.l	a1,a2
	move.l	sp,a1
	pea	(Name,a2)	; navn
	move.l	a0,-(a7)	; passord
	move.l	a1,-(a7)	; buffer
	IFND	_ACrypt
	XREF	_ACrypt
	ENDC
	jsr	_ACrypt
	lea	(12,sp),sp	; fjerner parametrene igjen
	lea	(Password,a2),a1
	move.l	sp,a0
	moveq.l	#Sizeof_PassT+1-1,d0
1$	move.b	(a0)+,(a1)+
	dbf	d0,1$
	move.b	(a0)+,(pass_10,a2)
	move.b	(a0)+,(pass_11,a2)
	unlk	a3
	pop	a2
	rts

;a0 = passord
;a1 = userrecord
checkpasswd
	push	a2
	link.w	a3,#-20
	move.l	a1,a2
	move.l	sp,a1
	pea	(Name,a2)	; navn
	move.l	a0,-(a7)	; passord
	move.l	a1,-(a7)	; buffer
	IFND	_ACrypt
	XREF	_ACrypt
	ENDC
	jsr	_ACrypt
	lea	(12,sp),sp	; fjerner parametrene igjen
	lea	(Password,a2),a1
	move.l	sp,a0
	moveq.l	#Sizeof_PassT+1-1,d0
1$	move.b	(a0)+,d1
	cmp.b	(a1)+,d1
	bne.b	9$
	dbf	d0,1$
	move.b	(pass_10,a2),d1
	cmp.b	(a0)+,d1
	bne.b	9$
	move.b	(pass_11,a2),d1
	cmp.b	(a0)+,d1
9$	unlk	a3
	pop	a2
	rts

inputnr	moveq.l	#0,d0
	move.l	d2,-(sp)
	move.l	d0,d1
	move.l	d1,d2
2$	move.b	(a0)+,d1
	subi.b	#'0',d1
	bcs.b	1$
	cmpi.b	#10,d1
	bcc.b	1$
	mulu.w	#10,d0
	add.l	d1,d0
	addq.l	#1,d2
	bra.b	2$
1$	move.l	d2,d1
	move.l	(sp)+,d2
	andi.l	#$ffff,d0
	rts

;a0 = intext (obs, intext bør sansyneligvis gjøres til uppercase)
;a1 = chtext
; retur :
; d0 : valg nr
; d1 : antall tegn som matcher.


; FOo	- orginal
; F	- nei
; FO	- ja
; FOO	- ja
; FOl	- nei
; FOOXxcvxc - ja

scanchoices
	push	d2/d3/d4/d5
	moveq.l	#0,d3			; tegn som matcher (siste som matchet)
	moveq.l	#0,d4			; valg nr (siste som matchet)
	moveq.l	#1,d1			; valg nr
3$	moveq.l	#0,d2			; tegn vi sjekker
	moveq.l	#0,d5			; tegn som matcher
4$	move.b	(a1)+,d0		; henter neste tegn
	beq.b	9$			; Null, vi er på slutten
	cmpi.b	#'a',d0			; Lite tegn ?
	bcs.b	7$			; nei.
	bsr	upchar			; gjør om til stort
	bra.b	71$
7$	addq.l	#1,d5
71$	cmp.b	(0,a0,d2.w),d0
	bne.b	8$
	addq.w	#1,d2
	move.b	(a1),d0
	cmpi.b	#',',d0
	beq.b	5$
	cmpi.b	#'.',d0
	beq.b	5$
	cmpi.b	#'>',d0			; for bruk i scanning av prompt input
	beq.b	5$
	bra.b	4$
5$	cmp.w	d5,d3			; flere machende tegn enn forrige ?
	bcc.b	6$			; nei
	move.l	d5,d3			; ja, lagrer disse verdiene isteden
	move.l	d1,d4
6$	addq.l	#1,d1			; øker søkeordet med 1
	addq.l	#1,a1			; Hopper over komma'et
	bra.b	3$			; søker på neste kommando

8$	move.b	(-1,a1),d0		; henter tegnet vi ikke klarte
	cmpi.b	#'a',d0			; Lite tegn ?
	bcs.b	2$			; nei, klarte det ikke
	move.b	(0,a0,d2.w),d0		; var det slutten på input'en ?
	bne.b	2$			; nei, passer ikke
1$	move.b	(a1)+,d0		; spoler til neste ord
	cmpi.b	#'.',d0
	beq.b	5$			; oops. kom til slutten
	cmpi.b	#'>',d0
	beq.b	5$			; oops. kom til slutten
	cmpi.b	#',',d0
	bne.b	1$
	bra.b	5$

2$	move.b	(a1)+,d0		; spoler til neste ord
	beq.b	9$			; oops. kom til slutten
	cmpi.b	#'.',d0
	beq.b	9$			; oops. kom til slutten
	cmpi.b	#',',d0
	bne.b	2$
	addq.l	#1,d1			; øker søkeordet med 1
	bra.b	3$
9$	move.l	d3,d1
	move.l	d4,d0
	pop	d2/d3/d4/d5
	rts

typestat
	push	d2
	addq.w	#1,(TimesOn+CU,NodeBase)	; øker antall ganger online,
	move.w	(Savebits+CU,NodeBase),d0
	and.w	#SAVEBITSF_Browse,d0		; browse på ?
	beq.b	6$				; nope.
	move.w	(Userbits+CU,NodeBase),d0
	btst	#USERB_FSE,d0			; har vi FSE ?
	beq.b	6$				; nope
	bset	#DIVB_Browse,(Divmodes,NodeBase) ; Slår på browse
6$	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne.b	4$
	bsr	outimage
	lea	(Timesonsystext),a0		; og skriver ut hvor mange det er.
	bsr	10$
	move.w	(TimesOn+CU,NodeBase),d0
	bsr	skrivnrw
	move.l	(ds_Days+LastAccess+CU,NodeBase),d0	; Har brukeren vært her før ?
	beq.b	1$				; Nei, ikke noe lasttime on system ..
	lea	(lasttimeontext),a0		; Skriver ut info om last time info
	bsr	10$
	lea	(LastAccess+CU,NodeBase),a0
	bsr	writetime
1$	lea	(filesupltext),a0
	bsr	10$
	move.w	(Uploaded+CU,NodeBase),d0
	bsr	skrivnrw
	lea	(filesdownltext),a0
	bsr	10$
	move.w	(Downloaded+CU,NodeBase),d0
	bsr	skrivnrw

4$	lea	(LastAccess+CU,NodeBase),a0	; Lagrer nye last time on system.
	move.l	(ds_Days,a0),d2			; husker siste dag man var innom
	move.l	d2,(lastdayonline,NodeBase)	; husker dag for forige login
	move.l	(ds_Minute,a0),d0
	move.w	d0,(lastminonline,NodeBase)	; og minuttet...

	move.l	a0,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	lea	(LastAccess+CU,NodeBase),a0
	move.l	(ds_Minute,a0),d0
	move.w	d0,(loginmin,NodeBase)
	move.w	(TimeUsed+CU,NodeBase),(OldTimelimit,NodeBase)
	move.w	(FTimeUsed+CU,NodeBase),(OldFilelimit,NodeBase)
	move.w	#-1,(joinfilemin,NodeBase)
	cmp.l	(ds_Days,a0),d2			; Har vi vært på før i dag ?
	beq.b	2$				; Ja, behold TimeUsed.
	move.w	#0,d0
	move.w	d0,(OldTimelimit,NodeBase)
	move.w	d0,(OldFilelimit,NodeBase)
	move.w	d0,(FTimeUsed+CU,NodeBase)
	move.w	d0,(TimeUsed+CU,NodeBase)
2$	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne.b	5$
	lea	(timeusedtdtext),a0
	bsr	10$
	move.w	(TimeUsed+CU,NodeBase),d0
	bsr	skrivnrw
	lea	(minutestext),a0
	bsr	writetexti
	lea	(ftimeusedtdtext),a0
	bsr	10$
	move.w	(FTimeUsed+CU,NodeBase),d0
	bsr	skrivnrw
	lea	(minutestext),a0
	bsr	writetexti
	bsr	outimage
5$	move.w	#0,d1
	move.w	(TimeLimit+CU,NodeBase),d0
	sub.w	(TimeUsed+CU,NodeBase),d0
	bcs	3$
	bsr	getnextwarningtime
	move.w	d0,d1
3$	move.b	d1,(warningtineindex,NodeBase)
	move.w	#0,(menunr,NodeBase)		;Skifter til Main menu
	bsr	typetosysop
	jsr	_CheckInvited
	bsr	loginlistprivate
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	notz
	beq	9$				; ja
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne.b	9$
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_Dontshowconfs,d0
	bne.b	9$
	jsr	(loginshowconferences)
9$	pop	d2
	rts

10$	move.l	a0,-(a7)
	lea	(ansilbluetext),a0
	bsr	writetext
	move.l	(a7)+,a0
	moveq.l	#28,d0
	bsr	writetextlfill
	lea	(ansiwhitetext),a0
	bra	writetexti

getnextwarningtime
	lea	(warningtimearr),a0
	moveq	#7,d1
1$	cmp.b	(0,a0,d1.w),d0		; cmp a,b
	bhi.b	9$			; Hopper hvis a =< b
	subq.l	#1,d1
	bne.b	1$
9$	move.l	d1,d0
	rts

writetime
	lea	(tmptext,NodeBase),a1
	bsr	gettimestr
	lea	(tmptext,NodeBase),a0
	bra	writetext
;	moveq.l	#8,d0
;	bra	writetextlen

;a0 = datestamp	JEO SHOW
;a1 = ut string
gettimestr
	movem.l	d3/d2/a2,-(sp)
	move.l	a0,a2
	move.l	a1,-(a7)
	bsr	datestampetodate
	move.l	(a7)+,a1
	movem.l	d0/d1,-(sp)
	mulu.w	#10,d3
	lea	(daytext),a0
	adda.l	d3,a0
	bsr	strcopy
	move.b	#',',(-1,a1)
	move.b	#' ',(a1)+
	move.l	a1,a0		; dag
	move.l	d2,d0
	bsr	konverter
	move.l	a0,a1
	move.b	#' ',(a1)+

	move.l	(4,sp),d0		; Month
	subq.l	#1,d0
	mulu.w	#10,d0
	lea	(monthtext),a0
	adda.l	d0,a0
	bsr	strcopy
	move.b	#' ',(-1,a1)

	move.l	(sp),d0			; Year
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	moveq.l	#8,d0
	adda.l	d0,sp
	lea	(attext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	a2,a0
	movem.l	(sp)+,d3/d2/a2
	move.l	(ds_Minute,a0),d0
	move.l	(ds_Tick,a0),d1
	move.l	a1,a0
	bra	timetostring1

; a0 = datestamp
timetostring
	move.l	(ds_Minute,a0),d0
	move.l	(ds_Tick,a0),d1
	lea	(tmptext,NodeBase),a0
timetostring1
	movem.l	a0/d2,-(sp)
	move.l	d0,d2
	divu.w	#60,d2
	move.w	d2,d0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#':',(a0)+
	swap	d2
	move.w	d2,d0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#':',(a0)+
	move.l	d1,d0
	divu.w	#TICKS_PER_SECOND,d0
	andi.l	#$ffff,d0
	bsr	nr2tostr
	move.b	#0,(a0)
	movem.l	(sp)+,d2/a0
	rts

strtonr2
	moveq.l	#0,d0
	moveq.l	#0,d1
	bsr	10$
	bmi.b	99$
	bsr	10$
	bmi.b	99$
9$	tst.w	d0
99$	rts

10$	move.b	(a0)+,d1
	beq.b	18$
	subi.b	#'0',d1
	bcs.b	18$
	cmpi.b	#9,d1
	bhi.b	18$
	mulu.w	#10,d0
	add.l	d1,d0
	clrn
	rts
18$	setn
	rts

nr2tostr
	divu.w	#10,d0
	addi.b	#'0',d0
	move.b	d0,(a0)+
	swap	d0
	addi.b	#'0',d0
	move.b	d0,(a0)+
	rts

skriv2nr			; Skriver ut et tall <100 med to siffer
	lea	(tmptext,NodeBase),a0
	bsr	nr2tostr
	move.b	#0,(a0)+
	lea	(tmptext,NodeBase),a0
	bra	writetext

skrivminst2nr
	lea	(tmptext,NodeBase),a0
	bsr	konverter
	tst.b	(1+tmptext,NodeBase)
	bne.b	1$
	move.b	#'0',d0
	bsr	writechar
1$	lea	(tmptext,NodeBase),a0
	bra	writetexti

;a0 = første tekst
;a1 = andre tekst (hvis noen)
;d0 = 1: Y = def. d0 = 0: N = def
getyorn	push	a2/a3/d2
	move.l	a0,a2
	move.l	a1,a3
	move.l	d0,d2
1$	tst.b	(readlinemore,NodeBase)		; er det noe mere i lese køen ?
	bne.b	7$				; ja, ikke skriv ut teksten(e)
	move.l	a2,a0
	bsr	writetext
	move.l	a3,d0				; er det en tekst nr 2 ?
	beq.b	4$				; nei.
	move.l	a3,a0
	bsr	writetext
4$	lea	(byslashntext),a0			; velger rette default valg
	tst.l	d2
	bne.b	8$
	lea	(yslashbntext),a0
8$	bsr	writetext
	lea	(quistspacetext),a0
	bsr	writetext
	bsr	breakoutimage
7$	bsr	readline
	bne.b	5$
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	notz
	beq	3$				; ja
	tst.l	d2				; setter z flagget etter om det er
	bra.b	3$				; y eller n som er defailt
5$	bsr	upstring
	move.b	(a0),d0
	cmpi.b	#'N',d0
	beq.b	3$
	cmpi.b	#'Y',d0
	bne.b	2$
6$	clrz
3$	pop	a2/a3/d2
	rts
2$	lea	(enteryorntext),a0
	bsr	writeerroro
	bra.b	1$

checkcarriercheckser
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Lokal node ?
	beq.b	9$				; ja, da er carrier ok :-)
	bsr.b	checkcarrier
	bra.b	99$
	ENDC
9$	clrz
99$	rts

	IFND DEMO

;z = 1 -> No carrier
; OBS mister tegn som er lest !
checkcarrier
	IFD	nocarrier
	clrz
	rts
	ENDC
;alwayscheckcarrier
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0	; Nullmodem ?
	bne.b	9$			; jepp, no CD checking.
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	move.w	#SDCMD_QUERY,(IO_COMMAND,a1)
	jsrlib	DoIO			; Sjekke flagg
	move.l	(sreadreq,NodeBase),a1
	move.w	(IO_STATUS,a1),-(sp)	; Henter serial.status
	bsr	initserread
	move.w	(sp)+,d0
	btst	#5,d0			; Har vi CD ?
	notz
	bne.b	9$
	move.b	#NoCarrier,(readcharstatus,NodeBase)
	lea	(nocarriertext),a0
	bsr	writetexto
	setz				; No carrier, Logoff !!
9$	rts

stengmodem
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	lea	(ModemOffHookString+Nodemem,NodeBase),a0	; Sender ATH1.
	bsr	serwritestringdo
	moveq.l	#2,d0
	lea	(transnltext),a0
	bra	serwritestringlendo

aapnemodem
	move.l	(sreadreq,NodeBase),a1
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	lea	(ModemOnHookString+Nodemem,NodeBase),a0	; Sender ATH0.
	bsr	serwritestringdo
	moveq.l	#2,d0
	lea	(transnltext),a0
	bra	serwritestringlendo

sendinitstr
	IFND	NOINIT
	btst	#DoDivB_NoInit,(DoDiv,NodeBase)
	beq.b	10$
	bclr	#DoDivB_NoInit,(DoDiv,NodeBase)
	ENDC
	setz
	rts

10$	push	d2/d3/a2/d4
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0			; Nullmodem ?
	notz
	beq	9$					; Ja, dropp init
	moveq.l	#0,d3
	moveq	#1,d0					; kjapp pause
	bsr	waitsecs
	bsr	serclear				; flusher input

2$	move.w	#4,d2					; 4 firsøk
3$	subq.w	#1,d2
	bcs.b	4$					; Gir opp med init str.
	lea	(ModemInitString+Nodemem,NodeBase),a0	; Sender init string.
	lea	(tmptext,NodeBase),a2			; buffer til init stringen
	move.l	a2,a1
	bsr	strcopy

1$	moveq.l	#0,d4					; antall pauser (= sek)
	move.l	a2,a0					; leter etter pause tegn
7$	move.b	(a0)+,d0
	beq.b	6$					; ferdig, skriver ut det vi har
	cmpi.b	#'~',d0
	bne.b	7$
	move.b	#0,(-1,a0)				; deler opp stringen
8$	addq.l	#1,d4					; teller antall ! tegn
	move.b	(a0)+,d0
	beq.b	6$					; gir blaffen i pauser på slutten
	cmpi.b	#'~',d0
	beq.b	8$
	exg	a2,a0
	subq.l	#1,a2					; fortsettelses stedet
	bsr	serwritestringdo			; skriver teksten frem til
	moveq.l	#2,d0					; ! tegnet
	lea	(transnltext),a0				; pg nl
	bsr	serwritestringlendo
	move.l	d4,d0					; tar pausen
	bsr	waitsecs
	bra.b	1$					; fortsetter
6$	move.l	a2,a0					; skriver ut det som er igjen
	bsr	serwritestringdo
	moveq.l	#2,d0
	lea	(transnltext),a0
	bsr	serwritestringlendo

	moveq.l	#6,d0					; Venter 6 sek maks.
	bsr	getmodemok
	beq.b	3$
	bra.b	5$
4$	moveq.l	#1,d3
5$	bsr	serclear
	bsr	initserread
	move.l	d3,d0
9$	pop	d2/d3/a2/d4
	rts

getmodemok
	movem.l	d2/d3/a2,-(sp)
	lea	(ModemOKString+Nodemem,NodeBase),a2
	move.w	d0,d2
1$	moveq.l	#1,d0
	bsr	waitsecs
2$	moveq.l	#0,d3
5$	lea	(tmptext,NodeBase),a0
	moveq.l	#-1,d0
	moveq.l	#0,d1
	bsr	serreadt
	cmpi.b	#1,d0
	beq.b	3$
4$	subq.w	#1,d2
	bne.b	1$
	bra.b	99$
3$	move.b	(tmptext,NodeBase),d0
	cmp.b	(0,a2,d3.w),d0
	bne.b	2$
	addq.l	#1,d3
	tst.b	(0,a2,d3.w)
	bne.b	5$
	clrz
99$	movem.l	(sp)+,d2/d3/a0
	rts

; Setter opp serialporten riktig.
setserparam
	move.l	(sreadreq,NodeBase),a1
	move.w	#SDCMD_SETPARAMS,(IO_COMMAND,a1)
	move.l	#4096,(IO_RBUFLEN,a1)
	move.w	(Setup+Nodemem,NodeBase),d1
	move.l	(NodeBaud+Nodemem,NodeBase),(IO_BAUD,a1)	; Setter opp init baud
	move.b	#8,(IO_READLEN,a1)
	move.b	#8,(IO_WRITELEN,a1)
	move.b	#1,(IO_STOPBITS,a1)
	moveq.l	#0,d0
	move.l	d0,(IO_EXTFLAGS,a1)
	move.w	(Setup+Nodemem,NodeBase),d1
	move.b	#0,(IO_SERFLAGS,a1)		; Null stiller.
;	btst	#SETUPB_XonXoff,d1		; Vi tillater ikke XonXoff lenger
;	bne.b	2$
	ori.b	#SERF_XDISABLED|SERF_RAD_BOOGIE|SERF_SHARED,(IO_SERFLAGS,a1)
2$	btst	#SETUPB_RTSCTS,d1
	beq.b	3$
	ori.b	#SERF_7WIRE,(IO_SERFLAGS,a1)
3$	jsrlib	DoIO
	move.l	(sreadreq,NodeBase),a1
	move.b	(IO_ERROR,a1),d0
	rts
	ENDC

fillinnodenr
	andi.l	#$ffff,d0
	move.l	d0,-(sp)
	bsr	strcopy
	subq.l	#1,a1
	move.l	(sp)+,d0
	move.l	a0,-(sp)
	move.l	a1,a0
	bsr	konverter
	move.l	a0,a1
	move.l	(sp)+,a0
	bra	strcopy

;skrivnrwrfill
;	andi.l	#$ffff,d0
skrivnrrfill
	move.l	d1,-(a7)
	bsr.b 	connrtotext
	move.l	(a7)+,d0
	bra	writetextrfill

skrivnrw
	andi.l	#$ffff,d0
skrivnr	bsr.b 	connrtotext
	bra	writetextlen

connrtotext
	lea	(tmptext,NodeBase),a0
	bsr	konverter
	lea	(tmptext,NodeBase),a0
	rts

; d0 = tall
; a0 = inn streng.
konverterw
	andi.l	#$ffff,d0
konverter
	link.w	a5,#-12
	move.l	sp,a1
1$	moveq.l	#10,d1
	bsr	divspes
	addi.w	#'0',d1
	move.b	d1,(a1)+
	tst.l	d0
	bne.b	1$
	move.l	a1,d1
	moveq.l	#0,d0
2$	move.b	-(a1),(a0)+
	addq.l	#1,d0
	cmpa.l	a1,sp
	bne.b	2$
	clr.b	(a0)
	sub.l	sp,d1
	unlk	a5
	rts

divspes	move.l	d2,-(sp)
	swap	d1
	move.w	d1,d2
	bne.b	9$
	swap	d0
	swap	d1
	swap	d2
	move.w	d0,d2
	beq.b	1$
	divu.w	d1,d2
	move.w	d2,d0
1$	swap	d0
	move.w	d0,d2
	divu.w	d1,d2
	move.w	d2,d0
	swap	d2
	move.w	d2,d1
9$	move.l	(sp)+,d2
	rts

; a0 = tekst
; returnerer N hvis error, Z hvis 0
atoi	push	d2/a2		; d2-d3/a2
	move.l	a0,a2
	moveq.l	#0,d1
	move.l	d1,d0
;	move.l	d1,d3
;	cmpi.b	#'+',(a0)
;	beq.b	1$
;	cmpi.b	#'-',(a0)
;	bne.b	2$
;	moveq.l	#1,d3
;1$	addq.l	#1,a0
2$	move.b	(a0)+,d0
	subi.b	#'0',d0
	blt.b	3$
	cmpi.b	#9,d0
	bhi.b	3$
	move.l	d1,d2
	asl.l	#2,d1
	add.l	d2,d1
	add.l	d1,d1
;	tst.b	d3
;	bne.b	4$
	add.l	d0,d1
	bra.b	2$
;4$	sub.l	d0,d1
;	bra.b	2$
3$	move.l	d1,d0
	move.l	a0,d1
	sub.l	a2,d1
	subq.l	#2,d1
	bmi.b	9$
	tst.l	d0
	clrn
9$	pop	d2/a2		; d2-d3/a2
	rts

deletefile
	move.l	a6,-(sp)
	move.l	(dosbase),a6
	move.l	a0,d1
	jsrlib	DeleteFile
	move.l	(sp)+,a6
	tst.l	d0
	rts

; a0 = filename
getfilelen
	movem.l	d2/d3,-(sp)
	move.l	(dosbase),a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.b	9$
	move.l	d0,d3
	move.l	(infoblock,NodeBase),d2
	jsrlib	Examine
	move.l	d0,d2
	beq.b	2$
	move.l	(infoblock,NodeBase),a0
	move.l	(fib_Size,a0),d2
2$	move.l	d3,d1
	jsrlib	UnLock
	move.l	d2,d0
9$	move.l	(exebase),a6
	movem.l	(sp)+,d2/d3
	rts

;a0 = en eller annen fil på disken
getdiskfree
	push	d2/d3/d4
	moveq.l	#-1,d4				; setter opp for feil
	move.l	(dosbase),a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.b	1$
	move.l	d0,d3
	move.l	(infoblock,NodeBase),d2
	jsrlib	Info
	move.l	d0,d2
	bne.b	4$
	moveq.l	#-1,d4				; setter error
	bra.b	2$
4$	move.l	(infoblock,NodeBase),a0		; beregner antall kb ledig
	move.l	(id_NumBlocks,a0),d0
	sub.l	(id_NumBlocksUsed,a0),d0
	move.l	(id_BytesPerBlock,a0),d1
	cmpi.l	#65535,d0			; er det flere enn 65535 blokker ?
	bhi.b	3$				; ja
	mulu.w	d1,d0				; k = (free * size)/1024
	moveq.l	#10,d1
	lsr.l	d1,d0
	bra.b	2$
3$	moveq.l	#10,d2				; k = free/1024 * size
	lsr.l	d2,d0
	mulu.w	d1,d0
2$	move.l	d0,d4
	move.l	d3,d1
	jsrlib	UnLock
1$	move.l	d4,d0				; enten -1 eller antall kb
	move.l	(exebase),a6
	pop	d2/d3/d4
	rts

;a0 = pattern
;a1 = dirname
deletepattern
	push	a2
	link.w	a3,#-80
	move.l	a1,a2
	move.l	sp,a1
	bsr	parsepattern
	beq.b	9$
	move.l	a0,d0
	move.l	a2,a0
	move.l	a0,(tmpval,NodeBase)
	lea	(deleteallfunc),a1
	bsr	dodirname
9$	unlk	a3
	pop	a2
	rts

;a0 = dirname
deleteall
	move.l	a0,(tmpval,NodeBase)
	lea	(deleteallfunc),a1
	moveq.l	#0,d0
	bsr	dodirname
9$	rts

deleteallfunc
	link.w	a2,#-80
	move.l	(ed_Name,a0),d0
	move.l	sp,a1
	move.l	a1,d1
	move.l	(tmpval,NodeBase),a0
	bsr	strcopy
	subq.l	#1,a1
	move.l	d0,a0
	bsr	strcopy
	jsrlib	DeleteFile
	unlk	a2
	rts

writetinystatus
	tst.b	(Tinymode,NodeBase)
	beq.b	9$
	push	a2
	link.w	a3,#-60
	lea	(clearwindowtext),a0
	bsr	writecontext
	move.l	(nodenoden,NodeBase),a2
	lea	(Nodeuser,a2),a0
	bsr	writecontext
	bsr	newconline
	move.l	sp,a0
	bsr	getstatustext
	move.l	sp,a0
	bsr	writecontext
	unlk	a3
	pop	a2
9$	rts

; a0 = textbuffer
getstatustext
	push	a2
	move.l	a0,a1
	move.l	(nodenoden,NodeBase),a2
	move.w	(Nodestatus,a2),d0
	cmp.w	#68,d0			; er det arexx sak ?
	bne.b	1$			; nei.
	move.l	(NodesubStatus,a2),a0
	bra.b	2$
1$	lea	(statustext),a0
	move.l	(0,a0,d0.w),a0
2$	bsr	strcopy
	cmpi.w	#36,d0			; I door ?
	beq.b	3$			; ja
	cmpi.w	#52,d0			; DL'er han hold ?
	beq.b	3$			; ja
	cmpi.w	#24,d0			; DL'er han ?
	bne.b	9$			; nei.
3$	subq.l	#1,a1
	move.l	(NodesubStatus,a2),d0
	move.l	a1,a0
	bsr	konverter
	move.w	(Nodestatus,a2),d0
	cmpi.w	#36,d0			; I door ?
	beq.b	9$			; Ja, da kutter vi ut K'en.
	move.b	#'K',(a0)+
	move.b	#0,(a0)
9$	pop	a2
	rts

updatenodestatustext
	push	a2/d2
	link.w	a3,#-80
	move.l	(nodenoden,NodeBase),a0		; starter på hoved strengen
	move.w	(Nodenr,a0),d0			; har vi ikke node nummer ? (er vi på vei ut?)
	bne.b	4$
	move.w	(NodeNumber,NodeBase),d0	; bruker kopi foreløpig
4$	move.l	sp,a0
	bsr	(konverterw)

	jsrlib	Forbid				; to prevent GadTools to use the text...
	move.l	(nodenoden,NodeBase),a2		; starter på hoved strengen
	move.l	(LN_NAME,a2),a1
	move.b	#'#',(a1)+
	move.l	sp,a0
	moveq.l	#3,d0
	bsr	strcopylfill

	move.w	(Nodenr,a2),d0			; har vi ikke node nummer ? (er vi på vei ut?)
	bne.b	7$				; nei, forsett normalt
	lea	(nodeshutdowntxt),a0
	bsr	strcopy
	bra	3$

7$	move.l	a1,d2
	move.l	(Nodespeed,a2),d0
	bne.b	1$
	lea	(localtext),a0
	bra.b	2$
1$	move.l	sp,a0
	bsr	(konverter)
	move.b	(NodeECstatus,a2),d1	; legger inn V/M info rett etter baud'en hvis det er noen
	move.b	#'V',d0
	btst	#NECSB_V42BIS,d1
	bne.b	5$
	move.b	#'M',d0
	btst	#NECSB_MNP,d1
	beq.b	6$
5$	move.b	#' ',(a0)+
	move.b	d0,(a0)+
	move.b	#0,(a0)
6$	move.l	sp,a0
2$	move.l	d2,a1
	moveq.l	#8,d0
	bsr	strcopylfill
	move.l	a1,d2
	move.l	sp,a0
	bsr	getstatustext
	move.l	sp,a0
	move.l	d2,a1
	moveq.l	#24,d0
	bsr	strcopylfill
	lea	(Name+CU,NodeBase),a0
	move.b	(a0),d0
	beq.b	3$
	bsr	strcopy
	move.b	#',',(-1,a1)
	lea	(CityState+CU,NodeBase),a0
	bsr	strcopy
3$	jsrlib	Permit
	move.l	MainTask,a1
	move.l	#SIGBREAKF_CTRL_E,d0
	jsrlib	Signal
	unlk	a3
	pop	a2/d2
	rts

;#3  14400   Newuser registration    123456789012345678901234567890,123456789012

; a0 = confname
testconfname
	moveq.l	#0,d1			; vi tester confnavn
	bra.b	testfilename1

; ret: z = error
testfilename
	moveq.l	#1,d1			; vi tester filnavn
testfilename1
	push	a0
1$	move.b	(a0)+,d0
	beq.b	8$
	cmpi.b	#':',d0
	beq.b	9$
	cmpi.b	#'(',d0
	beq.b	9$
	cmpi.b	#')',d0
	beq.b	9$
	cmpi.b	#'|',d0
	beq.b	9$
	cmpi.b	#'~',d0
	beq.b	9$
	cmpi.b	#'#',d0
	beq.b	9$
	cmpi.b	#'?',d0
	beq.b	9$
	cmpi.b	#',',d0
	beq.b	9$
	cmpi.b	#"`",d0
	beq.b	9$
	cmpi.b	#'"',d0
	beq.b	9$
	cmpi.b	#'%',d0
	beq.b	9$
	cmpi.b	#'*',d0
	beq.b	9$
	tst.l	d1
	beq.b	1$			; det er confnavn vi tester, så / er lov
	cmpi.b	#'/',d0
	beq.b	9$
	bra.b	1$
8$	pop	a0
	tst.l	d1
	beq.b	81$			; det er confnavn vi tester, ingen banfile
	jsr	(checkfilebanfile)
	bne.b	99$			; ok, ikke i banfile
	lea	(namebannedtext),a0
	bsr	writeerroro
	setz
	bra.b	99$
81$	clrz
	bra.b	99$
9$	pop	a0
99$	rts

; a0 = confname
; ret: z = error
testfilenameallowwild
1$	move.b	(a0)+,d0
	beq.b	8$
	cmpi.b	#':',d0
	beq.b	9$
	cmpi.b	#'/',d0
	beq.b	9$
	cmpi.b	#',',d0
	beq.b	9$
	cmpi.b	#"`",d0
	beq.b	9$
	cmpi.b	#'"',d0
	beq.b	9$
	cmpi.b	#'%',d0
	beq.b	9$
	bra.b	1$
8$	clrz
9$	rts

; a0 = filename
; ret : Z=1 not found
findfile
	move.l	d2,-(sp)
	move.l	(dosbase),a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	tst.l	d0
	beq.b	9$
	move.l	d0,d1
	jsrlib	UnLock
	move.l	(sp)+,d2
	clrz
	bra.b	99$
9$	move.l	(sp)+,d2
	setz
99$	move.l	(exebase),a6
	rts

setupa4a5
	move.l	(exebase),MainBase
	move.l	(ThisTask,MainBase),MainBase
	move.l	(TC_Userdata,MainBase),NodeBase
	move.l	(mainmemoryblock),MainBase
	rts

changenodestatusspeed
	move.l	(nodenoden,NodeBase),a0
	move.l	d0,(Nodespeed,a0)
	bsr	updatenodestatustext
	bra	writetinystatus

changenodestatusname
	move.l	(nodenoden,NodeBase),a1
	lea	(Nodeuser,a1),a1
	moveq.l	#30,d0
	bsr	strcopymaxlen
	lea	(CityState+CU,NodeBase),a0
	move.l	(nodenoden,NodeBase),a1
	lea	(NodeuserCityState,a1),a1
	moveq.l	#29,d0
	bsr	strcopymaxlen
	move.l	(nodenoden,NodeBase),a1
	move.l	(Usernr+CU,NodeBase),(Nodeusernr,a1)	; Lagrer usernummeret i nodenoden
	jsr	(updatewindowtitle)
	lea	(Nodetaskname,NodeBase),a0
	bsr	strlen
	move.b	d0,(Nodetaskname_BCPL,NodeBase)
	move.l	(exebase),a6
	bsr	updatenodestatustext
	bra	writetinystatus

changenodestatus
	move.w	d0,(PrevNodestatus,NodeBase)
	move.l	d1,(PrevNodesubStatus,NodeBase)
changenodestatusnostore
	move.l	(nodenoden,NodeBase),a0
	move.w	d0,(Nodestatus,a0)
	move.l	d1,(NodesubStatus,a0)
	bsr	updatenodestatustext
	bra	writetinystatus

initrun	moveq.l	#0,d0
	move.b	d0,(userok,NodeBase)
	move.b	d0,(Charset+CU,NodeBase)			; Setter tegnsett til ISO
	move.w	d0,(PageLength+CU,NodeBase)
	move.b	d0,(active,NodeBase)
	move.l	d0,(Name+CU,NodeBase)			; sletter navnet for show user
	move.b	d0,(readcharstatus,NodeBase)
	move.b	d0,(Divmodes,NodeBase)
	move.w	d0,(tmsgsread,NodeBase)
	move.w	d0,(tmsgsdumped,NodeBase)
	move.b	d0,(tmpsysopstat,NodeBase)		; clearer sysop chat for sikkerhetsskyld
	move.w	d0,(minchat,NodeBase)
	move.w	d0,(minul,NodeBase)
	move.w	d0,(Historyoffset,NodeBase)
	move.b	d0,(serescstat,NodeBase)			; reseter esc tolkningen
	move.b	d0,(noglobal,NodeBase)
	move.b	d0,(activesysopchat,NodeBase)
	move.l	(nodenoden,NodeBase),a0
	andi.b	#~(NDSF_Notavail+NDSF_Stealth),(Nodedivstatus,a0) ; Slår av ikke avail flagget
	bclr	#NECSB_UPDATED,(NodeECstatus,a0)		; Sier at den ikke er updated
	bsr	changenodestatus
	move.w	#-1,(confnr,NodeBase)			;Ingen konf nå
	lea	(historybuffer,NodeBase),a0		; tømmer historybufferet
	move.w	#1024,d0
	bsr	memclr
	bsr	initconread				; fyrer opp read requestene
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)
	beq.b	2$
	bsr	initserread
	ENDC
2$	lea	(ansiwhitetext),a0
	bra	writetexti

initrunlate
	move.b	#0,(readcharstatus,NodeBase)
	move.l	(nodenoden,NodeBase),a0
	move.w	(InterMsgwrite,a0),(InterMsgread,a0)	; flush'er intermsg'ene
	move.l	(dosbase),a6
	lea	(lastchartime,NodeBase),a0		; lagrer "siste tastetrykk"
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	(nodenoden,NodeBase),a0
	move.b	(NodeECstatus,a0),d0
	btst	#NECSB_UPDATED,d0			; er den updated ?
	bne.b	1$					; ja
	move.b	#0,(NodeECstatus,a0)			; slår av eventuell MNP/V42bis status
1$	rts

;d0 = TRUE -> Full logout, reply frontmsg osv.
endrun	push	d2
	move.l	d0,d2
	bsr	stoptimeouttimer
	jsr	freepastemem				; sikrer at pastemem blir frigjort
	clr.b	(readlinemore,NodeBase)			; flusher input'en
	move.w	#-1,(linesleft,NodeBase)
	move.b	#0,(XpertLevel+CU,NodeBase)		; forhindrer breake av nodemenyen
	tst.l	d2					; skal vi ta full logout ?
	beq.b	1$					; nei, hopper over dette
	bclr	#DoDivB_NoInit,(DoDiv,NodeBase)		; sletter-> funker hvis ingen front msg.
	move.l	(FrontDoorMsg,NodeBase),d0		; Har vi en melding som frontdoor skal ha ?
	beq.b	1$					; nei.
	move.l	d0,a1
	move.w	(f_Flags,a1),d0				; skal vi ta init ?
	andi.w	#f_flagsF_NoInit,d0
	beq.b	2$					; ja...
	bset	#DoDivB_NoInit,(DoDiv,NodeBase)
2$	jsrlib	ReplyMsg				; Tar reply
	moveq.l	#0,d0					; sletter, så det ikke skal skje igjen
	move.l	d0,(FrontDoorMsg,NodeBase)
1$	pop	d2
	rts

registerlogin
	lea	(maintmptext,NodeBase),a0	; skriver til log'en
	move.b	#'-',d0
	moveq.l	#60,d1
4$	move.b	d0,(a0)+
	dbf	d1,4$
	move.b	#0,(a0)
	lea	(maintmptext,NodeBase),a0
	lea	(logfilename,NodeBase),a1
	bsr	writelogtextline	; Linje med masse minus tegn i før login.
	lea	(maintmptext,NodeBase),a1
	lea	(loglogintext),a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	lea	(Name+CU,NodeBase),a0
	bsr	strcopy
	move.b	#' ',(-1,a1)
	moveq	#0,d0
	move.l	(nodenoden,NodeBase),a0
	move.l	(Nodespeed,a0),d0	; Skriver ut nodespeeden
	bne.b	1$
	lea	(localtext),a0		; Hvis speed = 0 => lokalnode
	bra.b	2$
1$	move.l	a1,-(sp)
	bsr 	connrtotext		; Ekstern node, skriv ut baud hastighet
	move.l	(sp)+,a1
2$	bsr	strcopy

	move.l	(nodenoden,NodeBase),a0
	move.b	(NodeECstatus,a0),d0
	beq.b	5$
	and.b	#~NECSF_UPDATED,d0
	beq.b	5$
	lea	(fullv42bistext),a0
	btst	#NECSB_V42BIS,d0
	bne.b	6$
	lea	(mnptext),a0
6$	move.b	#' ',(-1,a1)
	bsr	strcopy
5$	lea	(maintmptext,NodeBase),a0
	bsr	writelogstartup

	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)
	move.b	#1,(userok,NodeBase)
	move.b	#1,(active,NodeBase)
	lea	(Name+CU,NodeBase),a0
	bsr	changenodestatusname
	moveq.l	#4,d0
	bsr	changenodestatus
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Lokal node ?
	bne.b	3$				; nei, speed er riktig.
	moveq.l	#0,d0
	bsr	changenodestatusspeed		; setter baud'en til lokal
	ENDC
3$	lea	(u_almostendsave+CU,NodeBase),a0
	move.l	(Loginlastread,NodeBase),a1
	moveq.l	#0,d0
	move.w	(Maxconferences+CStr,MainBase),d0
	subq.l	#1,d0
	bcs.b	8$				; egentlig umulig..
7$	move.l	(uc_LastRead,a0),(a1)+		; husker loginstate
	lea	(Userconf_seizeof,a0),a0
	dbf	d0,7$
8$	bsr	updateshowuserwindow
	btst	#DIVB_StealthMode,(Divmodes,NodeBase) ; er Stealth Mode på ?
	bne.b	9$				; jepp. dropper den node meldingen.
	lea	(tmptext,NodeBase),a1		; sier ifra til alle at vi er her
	lea	(Name+CU,NodeBase),a0
	lea	(i_Name,a1),a1
	bsr	strcopy
	lea	(tmptext,NodeBase),a0
	move.b	#0,(i_type,a0)				; login melding
	move.w	(NodeNumber,NodeBase),(i_franode,a0)
	moveq.l	#0,d0					; Alle noder.
	move.b	#0,(i_pri,a0)
	bsr	sendintermsg
	move.b	(MessageFilterV+CU,NodeBase),d0
	cmpi.b	#50,d0			; 50 eller mere ?
	bcs.b	9$			; nei
	move.l	(nodenoden,NodeBase),a0
	ori.b	#NDSF_Notavail,(Nodedivstatus,a0)	; Slår på ikke avail flagget
9$	rts

getprompttext
	lea	(ansiwhitetext),a0
	lea	(maintmptext,NodeBase),a1
	bsr	strcopy
	move.b	#'(',(-1,a1)
	move.w	(confnr,NodeBase),d0		; conf nr
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0		; Har konferanse navnet.
	bsr	strcopy
	move.b	#')',(-1,a1)
	move.b	#' ',(a1)+
	move.w	(menunr,NodeBase),d0
	cmpi.w	#4,d0
	bne.b	2$
	move.w	(Savebits+CU,NodeBase),d1
	btst	#SAVEBITSB_ReadRef,d1
	beq.b	2$
	lea	(readreftext),a0
	bra.b	1$
2$	lea	(menutexts),a0
	move.l	(0,a0,d0.w),a0
1$	bsr	strcopy
	subq.l	#1,a1
	lea	(commandtext),a0
	bsr	strcopy
	move.b	(XpertLevel+CU,NodeBase),d0
	bne.b	3$
	subq.l	#1,a1
	lea	(qmformenutext),a0
	bsr	strcopy
3$	move.b	#':',(-1,a1)
	move.b	#' ',(a1)+
	move.b	#0,(a1)
	lea	(maintmptext,NodeBase),a0
	rts

checktime
	bsr	updatetime
	move.l	(ds_Minute+tmptext,NodeBase),d0

	IFND DEMO
	lea	(snumberrot),a0			; Beregner serial nummer
	move.l	(a0),d1
	eori.l	#snrrotverdi,d1
	move.l	d1,(4,a0)
	ENDC

	cmpi.w	#16,(menunr,NodeBase)		; Er vi i File menu ?
	bne.b	2$				; Nei.
	move.w	(FileLimit+CU,NodeBase),d1		; Har vi limit ?
	beq.b	2$				; Nei.
	add.w	(minul,NodeBase),d1		; gir ekstra tid for UL
	add.w	(minchat,NodeBase),d1		; gir ekstra tid for chat

	cmp.w	(FTimeUsed+CU,NodeBase),d1
	bhi.b	2$
	lea	(ftimexpiredtext),a0
	bsr	writetexto
	move.w	#0,(menunr,NodeBase)		;Skifter til Main menu

2$	move.w	(TimeLimit+CU,NodeBase),d0		; har vi limit ?
	beq	9$				; nei. Sjekker ikke
	lea	(tmptext,NodeBase),a0
	move.l	(dosbase),a6
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	(exebase),a6
	lea	(tmptext,NodeBase),a0
	move.l	(ds_Minute,a0),d0
	divu	#60,d0
	sub.w	#1,d0
	bcc.b	4$
	move.w	#23,d0
4$	lea	(HourMaxTime+Nodemem,NodeBase),a0
	moveq.l	#0,d1
	move.b	(a0,d0.w),d1
	move.w	(TimeLimit+CU,NodeBase),d0
	cmp.w	#60,d1
	bcc.b	3$				; ingen time limit
	cmp.w	d0,d1				; timelimit,hourlimit
	bcc.b	3$
	move.w	d1,d0				; bruker hourlimit isteden
3$	sub.w	(TimeUsed+CU,NodeBase),d0
	bcs	99$
	lea	(warningtimearr),a0
	moveq.l	#0,d1
	move.b	(warningtineindex,NodeBase),d1
	adda.l	d1,a0
	move.b	(a0),d1
	cmp.w	d1,d0
	bhi.b	9$				; Ingen warning nå.
	tst.w	d0
	beq.b	99$
	move.w	d0,-(sp)
	bsr	getnextwarningtime
	move.b	d0,(warningtineindex,NodeBase)

	lea	(totonlinetitext),a0		; Skriver tid online.
	bsr	writetext
	move.w	(TimeUsed+CU,NodeBase),d0
	bsr	skrivnrw
	bsr	breakoutimage

	lea	(timeremaindtext),a0		; Skriver tid igjen.
	bsr	writetext
	move.w	(sp)+,d0
	bsr	skrivnrw
	bsr	outimage

	lea	(nextwarntext1),a0
	bsr	writetext
	lea	(warningtimearr),a0
	moveq.l	#0,d1
	move.l	d1,d0
	move.b	(warningtineindex,NodeBase),d1
	move.b	(0,a0,d1.w),d0
	bsr	skrivnrw
	lea	(nextwarntext2),a0
	bsr	writetexto
9$	clrz
999$	rts

99$	lea	(timexpiredtext),a0
	bsr	writetexti
	setz
	bra.b	999$

; a0 = navn å finne
; a1 = start på navnliste.
; d0 = maks antall*2.
; d1 = size pr element
findnameicase
	moveq.l	#Sizeof_NameT,d1
findnameicase1
	push	d2/d3/d4/d5
	move.w	d0,d3
	move.l	d1,d5
	moveq.l	#0,d2
1$	move.b	(a1),d0
	beq.b	3$
	moveq.l	#0,d1
2$	move.b	(0,a0,d1.w),d0
	beq.b	8$
	bsr	upchar
	move.b	d0,d4
	move.b	(0,a1,d1.w),d0
	bsr	upchar
	addq.w	#1,d1
	cmp.b	d0,d4
	beq.b	2$
3$	add.l	d5,a1
	addq.w	#2,d2
	cmp.w	d3,d2
	bhi	9$
	bra.b	1$
8$	move.w	d2,d0
	clrz
	bra.b	99$
9$	setz
99$	pop	d2/d3/d4/d5
	rts

; a0 = navn å finne
finddir
	move.l	(firstFileDirRecord+CStr,MainBase),a1
	move.w	(MaxfileDirs+CStr,MainBase),d0
	add.w	d0,d0
	moveq.l	#FileDirRecord_SIZEOF,d1
	bra.b	findnameicase1

; a0 = navn å finne
finddirfull
	move.l	(firstFileDirRecord+CStr,MainBase),a1
	move.w	(MaxfileDirs+CStr,MainBase),d0
	add.w	d0,d0
	moveq.l	#FileDirRecord_SIZEOF,d1
	bra.b	findfullnameicase1

; a0 = navn å finne
findconferencefull
	lea	(n_FirstConference+CStr,MainBase),a1
	move.w	(Maxconferences+CStr,MainBase),d0
	add.w	d0,d0
	moveq.l	#ConferenceRecord_SIZEOF,d1
	bra.b	findfullnameicase1

; a0 = navn å finne
; a1 = start på navnliste.
; d0.w = maks antall *2.
; d1 = size pr element
findfullnameicase
	moveq.l	#Sizeof_NameT,d1
findfullnameicase1
	push	d2/d3/d4/d5
	move.w	d0,d3
	move.l	d1,d5
	move.w	#0,d2			; nr
1$	move.b	(a1),d0			; er det noen her ?
	beq.b	7$			; nei, hopper til neste
	moveq.l	#0,d1			; tegn nr vi tester
2$	move.b	(0,a0,d1.w),d0
	beq.b	8$			; slutten på stringen
	bsr	upchar
	move.b	d0,d4
	move.b	(0,a1,d1.w),d0
	bsr	upchar
	cmp.b	d0,d4			; like ?
	bne.b	7$			; nei, tar neste
	addq.w	#1,d1			; øker index'en i stringen
	bra.b	2$
7$	add.l	d5,a1			; oppdaterer for neste
	addq.w	#2,d2
	cmp.w	d3,d2			; søkt i alle ?
	bcc.b	9$			; jepp
	bra.b	1$			; nei, fortsetter
8$	move.b	(0,a1,d1.w),d0		; slutt på søke stringen også ?
	bne.b	7$			; nei, da tar vi neste
	move.l	d2,d0			; returnerer nummeret,
	clrz				; og sier vi fant
	bra.b	99$
9$	setz
99$	pop	d2/d3/d4/d5
	rts

; Bare de som har ACCB_Write kan skrive i denne konferansen.
; ret : z = 1 : ikke lov
sjekklovtilaaskrive
	bsr	sjekklovtilaaskrivesub
	bne.b	9$
	bsr	outimage
	beq.b	9$
	lea	(readonlycontext),a0
	bsr	writeerror
	lea	(usejtogetcltext),a0
	bsr	writeerroro
	setz
9$	rts

; ret : z = 1 : ikke lov
sjekklovtilaaskrivesub
	move.w	(confnr,NodeBase),d0		; conf nr
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0		; Har vi Write access ?
	andi.b	#ACCF_Write,d0
	rts

; a0 : msgheader
; d0 : conf nr (* 2!)
_kanskrive
	bsr.b	kanskrive
	beq.b	1$				; ja ...
	moveq.l	#1,d0
	bra.b	9$
1$	moveq.l	#0,d0
9$	rts

kanskrive
	move.b	(MsgStatus,a0),d1
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop+MSTATF_Dontshow,d1
	bne.b	9$
	bsr	allowtype
	bne.b	9$			; Nei. "Jump, for my love"
	setz
9$	rts

;sjekker om denne melding kan skrives ut. Kriterier er :
; hvis dontshow er satt, ikke i det hele tatt
;SecNone: alle kan lese denne.
;SecReceiver: Sysop,sigop, sender, motager kan lese.
; a0 : msgheader
; d0 : conf nr (* 2!)
allowtype
	move.l	d0,a1			; husker i a1
	btst	#MSTATB_Dontshow,(MsgStatus,a0)	; kan vi vise denne meldingen ?
	bne.b	7$				; nei.
	move.b	(Security,a0),d0
	btst	#SECB_SecNone,d0
	bne.b	9$
;	btst	#SECB_SecReceiver,d0
;	beq.b	8$
	move.l	(Usernr+CU,NodeBase),d1
	cmp.l	(MsgFrom,a0),d1
	beq.b	9$
	cmp.l	(MsgTo,a0),d1
	beq.b	9$
; Bare sysop og sigop igjen. Er vi det ??
	tst.b	(tmpsysopstat,NodeBase)
	bne.b	9$
8$	move.l	a1,d0				; henter frem conf nr
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.w	#ACCF_Sigop+ACCF_Sysop,d0
	bne.b	9$
7$	clrz			; Nei, ikke det.
	rts
9$	setz			; Ja,  skriv ut
	rts

; samme kriterier som for allowkill
allowmove
	move.b	(MsgStatus,a0),d1
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop+MSTATF_Dontshow,d1
	bne.b	9$
	bsr	allowkill
9$	rts

;sjekker om denne melding kan killes. Kriterier er :
;Sender, mottager (bare hvis meldingen er privat) ,Sysop, sigop, kan kille.
allowkill
	move.l	(Usernr+CU,NodeBase),d1
	cmp.l	(MsgFrom,a0),d1
	beq.b	99$
	cmp.l	(MsgTo,a0),d1
	bne.b	1$
	move.b	(Security,a0),d0			; er den privat ?
	btst	#SECB_SecReceiver,d0
	bne.b	9$					; ja, tillat sletting
; Bare sysop og sigop igjen. Er vi det ??
1$	tst.b	(tmpsysopstat,NodeBase)
	bne.b	9$
	move.w	(confnr,NodeBase),d0		; conf nr
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.w	#ACCF_Sigop+ACCF_Sysop,d0
	bne.b	9$
	clrz			; Nei, ikke det.
	rts
9$	setz			; Ja,  skriv ut
99$	rts

;sjekker om denne melding kan unkilles. Kriterier er :
;Sysop, sigop, kan unkille. User kan bare unkille hvis han kill'a meldingen
allowunkill
	move.b	(MsgStatus,a0),d0
	btst	#MSTATB_Dontshow,d0		; kan vi vise denne meldingen ?
	bne.b	8$				; nei.
	andi.b	#MSTATF_KilledByAuthor,d0	; ble den killa av forfatteren ?
	beq.b	1$				; Nei, da kan bare sysop/sigop unkille
	move.l	(Usernr+CU,NodeBase),d1
	cmp.l	(MsgFrom,a0),d1
	beq.b	9$
; Bare sysop og sigop igjen. Er vi det ??
	tst.b	(tmpsysopstat,NodeBase)
	bne.b	9$
1$	move.w	(confnr,NodeBase),d0		; conf nr
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	andi.w	#ACCF_Sigop+ACCF_Sysop,d0
	bne.b	9$
8$	clrz			; Nei, ikke det.
	rts
9$	setz			; Ja,  skriv ut
	rts

; sjekker om denne fila kan skrives ut. Kriteriene er :
; Ingen utskrift : Filen er flyttet eller slettet
; Sysop, Sigop og fokl med DL og read acces i conferansen den er privat til
; Kun personen den er til og sysoper, hvis det er en PU.
allowtypefileinfo
	move.w	(Filestatus,a0),d0		; er det noen status ?
	andi.w	#~(FILESTATUSF_FreeDL|FILESTATUSF_Selected),d0	; filtrerer ut freedl bit'et
	beq.b	9$				; nei, alle kan
	move.w	d0,d1
	andi.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d1
	bne.b	9$				; er den flyttet/slettet ? ja -> nope
	btst	#FILESTATUSB_PrivateUL,d0
	beq.b	1$
	move.l	(Usernr+CU,NodeBase),d1		; er den til oss ?
	cmp.l	(PrivateULto,a0),d1
	beq.b	9$				; ja
	bsr	(justchecksysopaccess)
	bra.b	99$
1$	btst	#FILESTATUSB_PrivateConfUL,d0
	beq.b	99$				; ukjent bit. Ingen utskrift
	tst.b	(tmpsysopstat,NodeBase)		; tmpsysop ?
	bne.b	99$				; ja
	move.l	(PrivateULto,a0),d0

	lea	(u_almostendsave+CU,NodeBase),a1
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a1,d0.l),d0		; Henter conf access
;	btst	#ACCB_Read,d0			; R og D uavhengig
;	beq.b	99$
	andi.w	#ACCF_Download+ACCF_Sigop+ACCF_Sysop,d0
	bra.b	99$
9$	notz
99$	rts

alloweditinfo
	moveq.l	#1,d0				; motager skal ikke slå ut
	bra.b	allowretract1

; Sjekker om denne fila kan retract'es. Kriteriene er :
; Sysop og UL'er kan alltid slette.
; Er fila Privat UL kan DL'er slette.
; Er fila Privat UL til konferanse kan sigop i konferansen slette.
; z = 0 -> har lov til å slette
; d0 = 0 -> Mottager skal få lov. = 1 -> Mottager får ikke lov (brukes til alloweditinfo..)
; a0 = fileentry
allowretract
	moveq.l	#0,d0				; tillat mottager også
allowretract1
	push	a2
	move.l	a0,a2
	move.l	(Usernr+CU,NodeBase),d1		; er det uploader ?
	cmp.l	(Uploader,a2),d1
	beq.b	9$				; jepp. ok
	jsr	(justchecksysopaccess)		; er vi sysop ?
	bne.b	99$				; ja, ok
	move.w	(Filestatus,a2),d1
	andi.w	#~FILESTATUSF_FreeDL,d1		; filtrerer ut freedl bit'et
	btst	#FILESTATUSB_PrivateUL,d1	; er den privat til person ?
	beq.b	1$				; nope
	tst.l	d0
	bne.b	1$				; vi skal ikke sjekke om mottager har lov
	move.l	(Usernr+CU,NodeBase),d0
	cmp.l	(PrivateULto,a2),d0		; til denne brukeren ?
	beq.b	9$				; ja, ok
1$	btst	#FILESTATUSB_PrivateConfUL,d1	; er den privat til en konf ?
	beq.b	99$				; ukjent, da sier vi nei
	move.l	(PrivateULto,a2),d0		; Henter conferanse nr.
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0		; Henter access byten for denne conf'en
	andi.w	#ACCF_Sysop+ACCF_Sigop,d0	; har bruker sysop/sigop access ??
	bra.b	99$				; Ja, hopp.
9$	notz
99$	pop	a2
	rts


; Sjekker om denne fila kan DL'es. Kriteriene er :
; Ingen security, alle kan DL'e
; PrivateUL, kun den som den er privat til kan DL'e
; Privat til conf, bare de med DL access i konfen kan DL'e den.
; sysop'er kan DL'e alt
allowdownload
	push	a2
	move.l	a0,a2
	jsr	(justchecksysopaccess)		; er vi sysop ?
	bne.b	99$				; ja, ok
	move.w	(Filestatus,a2),d1
	andi.w	#~FILESTATUSF_FreeDL,d1		; filtrerer ut freedl bit'et
	beq.b	9$
	btst	#FILESTATUSB_PrivateUL,d1
	beq.b	1$
	move.l	(Usernr+CU,NodeBase),d0
	cmp.l	(PrivateULto,a2),d0
	bra.b	9$
1$	btst	#FILESTATUSB_PrivateConfUL,d1
	beq.b	99$
	move.l	(PrivateULto,a2),d0
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0		; Henter access byten for denne conf'en
	andi.w	#ACCF_Download,d0		; har bruker DL access ??
	bra.b	99$				; Ja, hopp.
9$	notz
99$	pop	a2
	rts

	IFND DEMO
sjekkdltid
	move.l	(Fsize,a0),d0
sjekkdltidbytes
	push	d0				; husker size'n
	bsr	updatetime
	pop	d0
	move.w	(FileLimit+CU,NodeBase),d1
	beq.b	8$
	move.w	(cpsrate,NodeBase),d1
	divu.w	d1,d0
	andi.l	#$ffff,d0
	divu.w	#60,d0
	andi.l	#$ffff,d0
	move.w	(FileLimit+CU,NodeBase),d1
	sub.w	(FTimeUsed+CU,NodeBase),d1
	bls.b	9$			; Har ikke mere filtid.
	cmp.w	d0,d1
	bcs.b	9$
	move.w	(TimeLimit+CU,NodeBase),d1
	beq.b	8$			; Vi har ingen begrensning
	sub.w	(TimeUsed+CU,NodeBase),d1
	bls.b	9$			; Har ikke mere tid.
	cmp.w	d0,d1
	bcs.b	9$
8$	clrz
	rts
9$	setz
	rts
	ENDC

; d0 = msgnr
; d1 = confnr
typemsg	push	a2/a3/d2/d3
	tst.b	(readlinemore,NodeBase)		; er det mere input ?
	bne	99$				; jepp, skriver ikke meldingen

	lea	(tmpmsgheader,NodeBase),a2
	move.l	(tmpmsgmem,NodeBase),a3	; text Buffer
	move.l	a3,a0
	move.l	a2,a1
	move.l	d1,d3
	jsr	(loadmsg)
	bne	6$
	move.l	a2,a0
	move.w	d3,d0			; confnr
	bsr	allowtype		; Kan vi skrive ut denne ???
	bne	7$			; Nei. "Jump, for my love"
	move.l	(Number,a2),d0
	bsr	removefromqueue
	move.w	(Userbits+CU,NodeBase),d0	; har det vært ANSI ?
	btst	#USERB_ClearScreen,d0	; skal vi slette skjermen ?
	beq.b	2$			; nei.
	lea	(ansiclearsctext),a0	; sletter skjermen
	bsr	writetexti
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)	; ny skjerm
2$	move.l	a2,a0
	move.l	d3,d0
	move.l	a3,a1			; gir msgtext også for netnavn
	bsr	typemsgheader
	beq	99$
	bsr	outimage
	beq	99$
	move.l	a2,a0
	move.b	(MsgStatus,a2),d0
	andi.b	#MSTATF_KilledByAuthor+MSTATF_KilledBySigop+MSTATF_KilledBySysop,d0
	bne.b	8$
	move.w	(Userbits+CU,NodeBase),d0
	andi.w	#USERF_ColorMessages,d0
	beq.b	3$
	lea	(ansigreentext),a0
	bsr	writetexti
3$	move.l	a3,a0
	moveq.l	#0,d0
	move.w	(NrBytes,a2),d0
	notz
	bne.b	1$			; 0 bytes ? Bull... Fy..
	move.w	(NrLines,a2),d1
	bpl.b	4$			; normal melding
					; det er net navn i meldingen. Vekk med dem.
	bsr	skipnetnames		; increases a0, and decreases d0 to skip netuser names
4$	moveq.l	#2,d1			; ikke break, fremdeles både ser og con
	bset	#31,d1			; vi skal ha quiting
	bsr	writetextmemi
	beq.b	1$
	bsr	dubbelnewline
	bsr	breakoutimage
1$	sne	d2
	moveq.l	#1,d0
	add.l	d0,(MsgsRead+CU,NodeBase)	; opdaterer antall meldinger som er lest
	add.w	d0,(tmsgsread,NodeBase)
	move.l	(MsgTo,a2),d0
	cmp.l	(Usernr+CU,NodeBase),d0
	bne.b	8$
	move.b	(MsgStatus,a2),d0
	btst	#MSTATB_MsgRead,d0
	bne.b	8$
	bset	#MSTATB_MsgRead,d0
	move.b	d0,(MsgStatus,a2)
	move.l	a2,a0
	move.w	(confnr,NodeBase),d0
	jsr	(savemsgheader)
8$	tst.b	d2
	clrn
	bra.b	99$
6$	jsr	(skrivnrw)
7$	setn
9$	notz
99$	pop	a2/a3/d2/d3
	rts

;a0 = msgheader
;a1 = msgtext
;returnerer z=1 hvis det var et net navn
isfromnetname
	move.w	(NrLines,a0),d0			; net message ?
	bpl.b	1$				; Nope
	move.b	(a1)+,d0
	cmp.b	#Net_FromCode,d0		; har vi from ?
	bra.b	9$				; z flagget er riktig nå
1$	clrz
9$	rts

;a0 = msgheader
;a1 = msgtext
;returnerer z=1 hvis det var et net navn
istonetname
	move.w	(NrLines,a0),d0			; net message ?
	bpl.b	1$				; Nope
	move.b	(a1)+,d0
	cmp.b	#Net_ToCode,d0
	beq.b	9$				; ja, vi har to net navn
	cmp.b	#Net_FromCode,d0		; har vi from ?
	bne.b	9$				; vi har ikke
2$	move.b	(a1)+,d0			; søker forbi fromnavne
	cmp.b	#10,d0
	bne.b	2$
	move.b	(a1)+,d0
	cmp.b	#Net_ToCode,d0				; Enten er det to navn her, ellers har vi ikke
	bra.b	9$				; z flagget er riktig nå
1$	clrz
9$	rts

;a0 = msgheader
;a1 = msgtext
;returnerer z=1 hvis det var et net subject
getsubject
	push	a2
	move.l	a0,a2
	move.l	a1,a0
	bsr	getnetsubject
	beq.b	9$
	lea	(Subject,a2),a0
9$	pop	a2
	rts

;a0 = msgheader
;a1 = msgtext
;returnerer z=1 hvis det var et net navn
getfromname
	move.w	(NrLines,a0),d0			; net message ?
	bpl.b	1$				; Nope
	move.b	(a1)+,d0
	cmp.b	#Net_FromCode,d0		; har vi from ?
	bne.b	1$				; nope
	moveq.l	#78,d1				; safety length
	lea	(tmpnametext,NodeBase),a0
2$	move.b	(a1)+,d0
	cmp.b	#10,d0
	beq.b	3$
	move.b	d0,(a0)+
	dbf	d1,2$
3$	move.b	#0,(a0)
	lea	(tmpnametext,NodeBase),a0
	moveq.l	#0,d0
	bra.b	9$
1$	move.l	(MsgFrom,a0),d0
	bsr	getusername
	clrz
9$	rts

;a0 = msgheader
;a1 = msgtext
;returnerer z=1 hvis det var et net navn
gettoname
	move.w	(NrLines,a0),d0			; net message ?
; entry point for CallEditor (nrLines er ikke negativ her..)
gettoname1
	bpl.b	2$				; Nope
	move.b	(a1)+,d0
	cmp.b	#Net_ToCode,d0				; har vi to ?
	beq.b	1$				; jepp
	cmp.b	#Net_FromCode,d0		; har vi from ?
	bne.b	2$				; nope
3$	move.b	(a1)+,d0
	cmp.b	#10,d0
	bne.b	3$
	move.b	(a1)+,d0
	cmp.b	#Net_ToCode,d0				; har vi to ?
	bne.b	2$				; nope
	moveq.l	#78,d1				; safety length
1$	lea	(tmpnametext,NodeBase),a0
4$	move.b	(a1)+,d0
	cmp.b	#10,d0
	beq.b	5$
	move.b	d0,(a0)+
	dbf	d1,4$
5$	move.b	#0,(a0)
	lea	(tmpnametext,NodeBase),a0
	moveq.l	#0,d0
	bra.b	9$
2$	move.l	(MsgTo,a0),d0
	bsr	getusername
	clrz
9$	rts

;They must be in this order...
;$1e - From		= Terminert av newline
;$1f - To		= Terminert av newline
;$1d - Subject		= Terminert av newline
;$1c - ExtData		= Terminert av $FF byte

;a0 = msgtext
; ret : Z for ingen net subject.
getnetsubject
	move.b	(a0),d1
	cmp.b	#Net_FromCode,d1		; from navn ?
	bne.b	2$				; nei, sjekker videre
1$	move.b	(a0)+,d1
	cmp.b	#10,d1				; newline ?
	bne.b	1$				; nei, looper videre
	move.b	(a0),d1				; henter ny start

2$	cmp.b	#Net_ToCode,d1				; to navn ?
	bne.b	4$				; nei, sjekker videre
3$	move.b	(a0)+,d1
	cmp.b	#10,d1				; newline ?
	bne.b	3$				; nei, looper videre
	move.b	(a0),d1				; henter ny start

4$	addq.l	#1,a0
	moveq.l	#1,d0
	cmp.b	#Net_SubjCode,d1		; Subject ?
	notz
	bne.b	9$
	moveq.l	#0,d0
9$	rts


; increases a0, and decreases d0 to skip netuser names
skipnetnames
	move.b	(a0),d1
	cmp.b	#Net_FromCode,d1		; from navn ?
	bne.b	2$				; nei, sjekker videre
1$	move.b	(a0)+,d1
	subq.l	#1,d0				; minker d0
	cmp.b	#10,d1				; newline ?
	bne.b	1$				; nei, looper videre
	move.b	(a0),d1				; henter ny start


2$	cmp.b	#Net_ToCode,d1				; to navn ?
	bne.b	4$				; nei, sjekker videre
3$	move.b	(a0)+,d1
	subq.l	#1,d0				; minker d0
	cmp.b	#10,d1				; newline ?
	bne.b	3$				; nei, looper videre
	move.b	(a0),d1				; henter ny start

4$	cmp.b	#Net_SubjCode,d1		; Subject ?
	bne.b	6$				; nei, sjekker videre
5$	move.b	(a0)+,d1
	subq.l	#1,d0				; minker d0
	cmp.b	#10,d1				; newline ?
	bne.b	5$				; nei, looper videre
	move.b	(a0),d1				; henter ny start

6$	cmp.b	#Net_ExtDCode,d1		; Ext data ?
	bne.b	9$				; nei, ut
7$	move.b	(a0)+,d1
	subq.l	#1,d0				; minker d0
	cmp.b	#$ff,d1				; $ff ?
	bne.b	7$				; nei, looper videre

9$	rts

; a0 = første tid
; a1 = andre tid
calctime
	move.l	(ds_Days,a1),d0
	sub.l	(ds_Days,a0),d0
	bcc.b	3$
	moveq.l	#0,d0				; oops, returnerer 0. feil..
	bra.b	9$
3$	move.l	(ds_Minute,a1),d1
	sub.l	(ds_Minute,a0),d1
	mulu.w	#24*60,d0
	add.l	d0,d1
	bpl.b	1$
	moveq.l	#0,d0				; oops, returnerer 0. feil..
	bra.b	9$
1$	move.l	d1,d0
	mulu.w	#60,d0				; vi skal returnere sekunder
	move.l	(ds_Tick,a1),d1
	sub.l	(ds_Tick,a0),d1
	bcc.b	2$				; ikke wrap
	addi.l	#TICKS_PER_SECOND*60,d1
2$	divu.w	#TICKS_PER_SECOND,d1
	andi.l	#$ffff,d1
	add.l	d1,d0
9$	rts

updatetime
	move.l	(dosbase),a6
	lea	(tmptext,NodeBase),a0			; finner tiden nå
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	(ds_Minute+tmptext,NodeBase),d0		; minuttet nå
	sub.w	(loginmin,NodeBase),d0			; minutter siden login
	bcc.b	1$					; gikk ikke over et døgn
	addi.w	#24*60,d0				; legger til for døgnet
1$	add.w	(OldTimelimit,NodeBase),d0		; minutter i forige session
	sub.w	(minchat,NodeBase),d0			; trekker ifra for chat
	bcc.b	5$
	moveq.l	#0,d0
5$	sub.w	(minul,NodeBase),d0			; og upload
	bcc.b	6$
	moveq.l	#0,d0
6$	move.w	d0,(TimeUsed+CU,NodeBase)			; minutter brukt i dag

	cmpi.w	#16,(menunr,NodeBase)			; Er vi i File menu ?
	bne.b	8$					; Nei.
	move.l	(ds_Minute+tmptext,NodeBase),d0
	cmpi.w	#-1,(joinfilemin,NodeBase)
	bne.b	2$
	move.w	d0,(joinfilemin,NodeBase)
2$	sub.w	(joinfilemin,NodeBase),d0
	bcc.b	3$
	addi.w	#24*60,d0
3$	add.w	(OldFilelimit,NodeBase),d0
	move.w	d0,(FTimeUsed+CU,NodeBase)
	bra.b	9$
8$	cmpi.w	#-1,(joinfilemin,NodeBase)		; nettopp byttet ?
	beq.b	9$					; nope
	move.l	(ds_Minute+tmptext,NodeBase),d0		; tiden nå
	sub.w	(joinfilemin,NodeBase),d0		; husker hvor mye vi brukte
	bcc.b	4$					; denne "sessionen"
	addi.w	#24*60,d0
4$
;	sub.w	(minul,NodeBase),d0			; tar ikke  med ul tid
	add.w	d0,(OldFilelimit,NodeBase)
	move.w	#-1,(joinfilemin,NodeBase)
9$	rts

*****************************************************************
*			level 2 IO rutiner			*
*****************************************************************

writetextlfill
	push	d2/a2
	move.l	d0,d2
	move.l	a0,a2
	bsr	strlen
	sub.l	d0,d2
	move.l	a2,a0
	cmpi.b	#10,(a0)			; starter det med en nl ?
	bne.b	1$				; nei
	addq.l	#1,d2				; ja, kompenserer
1$	bsr	writetextlen
	move.l	d2,d0
	bmi.b	9$
	beq.b	9$
	lea	(spacetext),a0		; .. og jevner ut med space
	bsr	writetextlen
9$	pop	d2/a2
	rts

; a0 = text
; d0 = totalt plasser
writetextrfill
	movem.l	d2/a2,-(sp)
	move.l	d0,d2
	move.l	a0,a2
	bsr	strlen
	sub.l	d0,d2
	exg	d0,d2
	tst.l	d0
	bmi.b	1$
	beq.b	1$
	lea	(spacetext),a0		; .. og jevner ut med space
	bsr	writetextlen
1$	move.l	a2,a0
	move.l	d2,d0
	bsr	writetextlen
	movem.l	(sp)+,d2/a2
	rts

writecontextrfill
	movem.l	d2/a2,-(sp)
	move.l	d0,d2
	move.l	a0,a2
	bsr	strlen
	sub.l	d0,d2
	exg	d0,d2
	tst.l	d0
	bmi.b	1$
	beq.b	1$
	lea	(spacetext),a0		; .. og jevner ut med space
	bsr	writecontextlen
1$	move.l	a2,a0
	move.l	d2,d0
	bsr	writecontextlen
	movem.l	(sp)+,d2/a2
	rts

	IFD	notyet
writecontextlfill
	push	d2/a2
	move.l	d0,d2
	move.l	a0,a2
	bsr	strlen
	sub.l	d0,d2
	move.l	a2,a0
	bsr	writecontextlen
	move.l	d2,d0
	bmi.b	9$
	beq.b	9$
	lea	(spacetext),a0		; .. og jevner ut med space
	bsr	writecontextlen
9$	pop	d2/a2
	rts
	ENDC

; d0 = nr, d1 = antall siffer
writenrrfill
	push	d2/a2
	move.l	d1,d2
	lea	(tmptext,NodeBase),a2
	move.l	a2,a0
	bsr	konverter
	move.l	a2,a0
	bsr	strlen
	sub.l	d0,d2
	bmi.b	1$
2$	subq.l	#1,d2
	bcs.b	1$
	move.b	#'0',d0
	bsr	writechar
	bra.b	2$
1$	move.l	a2,a0
	bsr	writetext
	movem.l	(sp)+,d2/a2
	rts

; a0 = prompt
; a1 = gammel tekst
; d0 = antall tegn
mayedlinepromptfull
	moveq.l	#1,d1				; skal ta readlineall
	bra.b	mayedlineprompt1
mayedlineprompt
	moveq.l	#0,d1				; skal ikke ta readlineall
mayedlineprompt1
	push	a2/a3/d2/d3
	move.l	d1,d3				; husker stat
	move.l	a0,a2
	move.l	a1,a3
	move.l	d0,d2
	tst.b	(readlinemore,NodeBase)		; er det noe mere i lese køen ?
	beq.b	1$				; ja, ikke skriv ut teksten(e)
	tst.l	d3
	beq.b	3$
	bsr	readlineall
	bra.b	4$
3$	bsr	readline
4$	beq.b	1$				; ja, ikke skriv ut teksten(e)
	move.l	a0,a2
	bsr	strlen
	move.l	a2,a0
	cmp.w	d2,d0
	bls.b	2$
	move.b	#'0',(0,a0,d2.w)			; sletter formange tegn
2$	clrz
	bra.b	9$

1$	move.l	a2,(curprompt,NodeBase)
	move.l	a3,a0
	move.l	d2,d0
	lea	(intextbuffer,NodeBase),a1
	bsr	strcopymaxlen
	move.l	a2,a0
	bsr	writetexti
	move.l	d2,d0
	bsr	edline
	clr.l	(curprompt,NodeBase)
	tst.l	d0
9$	pop	a2/a3/d2/d3
	rts

* Obs * Hack'er oss inn på getline..
edline	push	d2-d6/a2/a3
	move.l	d0,d2
	bsr	startsleepdetect
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)
	lea	(intextbuffer,NodeBase),a2
	move.l	a2,a0
	bsr	strlen
	move.l	a2,a0
	move.l	d0,d3
	move.l	d0,d4
	bsr	writetextleni
	move.w	#0,(intextchar,NodeBase)
	bra.b	getline2

getline	push	a2/a3/d2-d6
	move.w	d0,d2			; maks antall tegn vi vil ha
	bsr	startsleepdetect
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)
	lea	(intextbuffer,NodeBase),a2
	moveq.l	#0,d3			; antall tegn i buffer
	moveq.l	#0,d4			; cursorpos i stringen
	moveq.l	#80,d0
	move.l	a2,a0
	bsr	memclr			; tømmer stringen helt
	move.w	d3,(intextchar,NodeBase)
getline2				; her hopper edline inn
	bclr	#31,d5			; kan ikke ha ansi
	move.w	(Userbits+CU,NodeBase),d0	; bruker han fse ?
	andi.w	#USERF_FSE,d0
	beq.b	0$
	bset	#31,d5
0$	moveq.l	#0,d6			; peker i bufferet der current linje er
	move.l	d6,(SerTotOut,NodeBase)	; sletter ut teller

	move.w	(Historyoffset,NodeBase),d6 ; (forandres med pil opp/ned)
	lea	(historybuffer,NodeBase),a3
1$	move.b	d4,(cursorpos,NodeBase)
	bsr	readchar
	bmi	2$			; spesial taster
	move.b	(readcharstatus,NodeBase),d1	; noe spess ?
	bne	7$			; ja, kast'n ut
	cmpi.b	#13,d0			; return ?
	beq	3$			; ja, ferdig
	cmpi.b	#10,d0			; linefeed ?
	beq	3$			; ja, ferdig
	cmpi.b	#24,d0			; CTRL-X
	beq	4$
	cmpi.b	#8,d0			; backspace ?
	beq.b	5$
	cmpi.b	#$7f,d0
	beq.b	6$			; del
	cmpi.b	#9,d0			; Tab ?
	beq.b	1$			; ja, dropper

	cmp.w	d3,d2			; er det plass ?
	bls.b	1$			; nei, glemmer tegnet
	move.w	d3,d1			; lengden
11$	move.b	(0,a2,d1.w),(1,a2,d1.w)	; flytter alle tegnene etter
	subi.w	#1,d1
	cmp.w	d4,d1			; pos, len-n
	bge.b	11$			; ikke flyttet alle enda
14$	move.b	d0,(1,a2,d1.w)
	addi.w	#1,d3			; len
	addi.w	#1,d4			; pos

	btst	#31,d5
	beq.b	13$
	cmp.w	d4,d3			; er vi på enden ?
	beq.b	13$			; jepp. ikke insertchar.
	move.b	d0,d5
	lea	(ansiinschartext),a0
	bsr	getline110
	move.b	d5,d0
13$	tst.b	(readingpassword,NodeBase) ; gir ekko
	beq.b	12$
	move.b	#'.',d0			; men bare '.' hvis det er passord
12$	bsr	writechari
	bra	1$

6$	cmp.w	d4,d3			; er vi på enden ?
	beq	1$			; jepp. nop
	move.w	d4,d0
61$	move.b	(1,a2,d0.w),(0,a2,d0.w)
	addi.w	#1,d0
	cmp.w	d3,d0
	bls.b	61$
	subi.w	#1,d3
	lea	(ansidelchartext),a0
	bsr	getline110
	bra	1$

5$	move.w	d4,d0			; backspace
	beq	1$			; er i enden
51$	move.b	(0,a2,d0.w),(-1,a2,d0.w)
	addi.w	#1,d0
	cmp.w	d3,d0
	bls.b	51$
	subi.w	#1,d3
	subi.w	#1,d4
	cmp.w	d3,d4
	bne.b	52$
	lea	(deltext),a0
	moveq.l	#3,d0
	bsr	writetextleni
	bra	1$

52$	lea	(ansilefttext),a0		; flytter til venstre
	bsr	writetext
	lea	(ansidelchartext),a0
	bsr	getline110
	bra	1$

4$	moveq.l	#80,d0			; behandler CTRL-X
	move.l	a2,a0
	bsr	memclr			; tømmer stringen helt
	move.w	d3,d5
	bsr	70$
	moveq.l	#0,d3			; strlen
	moveq.l	#0,d4			; pos
	bra	1$


2$	cmpi.w	#20,d0			; er det funksjonstaster ?
	bcs	1$			; ja, vil ikke ha dem.
	bhi.b	21$			; 20 = opp
;	tst.b	readingpassword(NodeBase) ; ikke hvis vi leser passord
;	bne	1$
	bsr	80$			; finner forige
	beq	26$			; fant ingen
	move.w	d0,d6
	bsr	60$
	bsr	100$
	bsr	71$
	move.l	a2,a0
	bsr	writetexti
	bra	1$

21$	cmpi.w	#21,d0			; 21 = ned
	bne.b	22$
;	tst.b	readingpassword(NodeBase) ; ikke hvis vi leser passord
;	bne	1$
	bsr	90$			; finner forige
	beq	26$			; fant ingen
	move.w	d0,d6
	bsr	60$
	bsr	100$
	bsr	71$
	move.l	a2,a0
	bsr	writetexti
	bra	1$

26$	tst.l	d3			; har vi en string ?
	beq	1$			; nei, nop
	bra	4$

22$	cmpi.w	#22,d0			; 22 = høyre
	bne.b	23$
	cmp.w	d3,d4
	bcc	1$			; er på enden
	addi.w	#1,d4			; øker med en
	lea	(ansirighttext),a0
	bsr	getline110
	bra	1$

23$	cmpi.w	#23,d0			; 23 = venstre
	bne.b	24$
	tst.w	d4
	beq	1$			; er på starten
	btst	#31,d5			; fse ?
	beq	5$			; nei, da tar vi det som backspace
	subi.w	#1,d4			; minker med en
	lea	(ansilefttext),a0		; flytter til venstre
	bsr	getline110
	bra	1$

24$	cmpi.w	#24,d0			; 24 = shift høyre
	bne.b	25$
	cmp.w	d3,d4
	bcc	1$			; er på enden
	move.w	d3,d0
	sub.w	d4,d0
	move.b	#'C',d1
	bsr	stepcursor
	move.w	d3,d4
	bra	1$

25$	cmpi.w	#25,d0			; 25 = shift venstre
	bne	1$			; ukjent
	tst.w	d4
	beq	1$			; er på starten
	btst	#31,d5			; fse ?
	beq	4$			; nei, da tar vi det som ctrl-x
	move.w	d4,d0
	move.b	#'D',d1
	bsr	stepcursor
	moveq.l	#0,d4
	bra	1$

3$	bsr	outimage		; sender return tilbake
	clr.b	(dosleepdetect,NodeBase)
	tst.w	d3
	beq.b	31$			; ingen tegn
32$	move.b	(-1,a2,d3.w),d0		; fjerner space på slutten
	cmp.b	#' ',d0
	bne.b	33$
	subq.w	#1,d3
	bne.b	32$

33$	move.b	#0,(a2,d3.w)
31$	move.l	a2,a0			; returnerer string
	move.l	a3,a1
	bsr	insertinhistory
;	move.l	a3,a0
;	bsr	writestringspes
	move.l	a2,a0			; returnerer string
	move.w	d3,d0			; og lengde
	bra.b	9$

7$	clr.b	(dosleepdetect,NodeBase)
	moveq.l	#0,d0
;	bra.b	9$
9$
	pop	a2/a3/d2-d6
	rts

60$	cmp.w	d3,d4			; len,pos
	bcc.b	62$			; er på enden
	addi.w	#1,d4			; øker med en
	lea	(ansirighttext),a0
	bsr	getline110
	bra.b	60$
62$	rts


70$	move.l	(curprompt,NodeBase),d0	; har vi noe prompt å skrive ut ?
	beq.b	71$			; nei
	bsr	outimage		; ja, ut med det (nl først)
	move.l	(curprompt,NodeBase),a0
	bsr	writetexti
	bra.b	72$			; ferdig
71$	subi.w	#1,d5			; sletter alle tegnene på skjermen
	bcs.b	72$			; ferdig
	lea	(deltext),a0
	moveq.l	#3,d0
	bsr	writetextleni
	bra.b	71$
72$	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)
	rts

80$	move.w	d6,d1			; søker til forige kommando
81$	subi.w	#1,d1
	and.w	#$3ff,d1
	cmp.w	d1,d6
	beq.b	89$			; fant ingen
	tst.b	(0,a3,d1.w)		; først til vi kommer til en kommando
	beq.b	81$

82$	subi.w	#1,d1			; så til begynnelsen
	and.w	#$3ff,d1
	cmp.w	d1,d6
	beq.b	89$			; fant ingen
	tst.b	(0,a3,d1.w)
	bne.b	82$
	addi.w	#1,d1
	and.w	#$3ff,d1
	move.w	d1,d0
	clrz				; fant en
89$	rts


90$	move.w	d6,d1			; søker til neste kommando
91$	addi.w	#1,d1
	and.w	#$3ff,d1
	cmp.w	d1,d6
	beq.b	99$			; fant ingen
	tst.b	(0,a3,d1.w)		; først til vi kommer til en slutten av denne
	bne.b	91$

92$	addi.w	#1,d1			; så til begynnelsen av neste
	and.w	#$3ff,d1
	cmp.w	d1,d6
	beq.b	99$			; fant ingen
	tst.b	(0,a3,d1.w)
	beq.b	92$
	move.w	d1,d0
	clrz				; fant en
99$	rts

100$	moveq.l	#0,d1
	move.l	a2,a0
	move.w	d6,d0
101$	move.b	(0,a3,d0.w),(a0)+
	beq.b	102$
	addi.w	#1,d0
	and.w	#$3ff,d0
	addq.l	#1,d1
	cmp.w	d1,d2			; Er det for mye ?
	bhi.b	101$			; nei
102$	move.w	d3,d5			; husker gammel strlen
	move.l	d1,d3			; strlen
	move.l	d1,d4			; pos
	move.w	d1,d0			; sletter resten
	neg.w	d0
	addi.w	#80,d0
	bmi.b	109$
	bsr	memclr
109$	rts

getline110
	move.l	d2,-(a7)
	move.b	(FSEditor,NodeBase),d2
	move.b	#1,(FSEditor,NodeBase)
	bsr	writetexti
	move.b	d2,(FSEditor,NodeBase)
	move.l	(a7)+,d2
	rts

; d0.w = numsteps
; d1.b = 'D'/'C'
stepcursor
	push	d3
	move.b	d1,d3
	link.w	a3,#-20
	move.l	sp,a0
	move.b	#'',(a0)+
	move.b	#'[',(a0)+
	bsr	konverterw
	move.b	d3,(a0)+
	move.b	#0,(a0)
	move.l	sp,a0
	bsr	getline110
	unlk	a3
	pop	d3
	rts

; a0 = string
; a1 = historybuffer
insertinhistory
	push	a3
	move.l	a1,a3
	tst.b	(readingpassword,NodeBase) ; ikke hvis vi leser passord
	bne.b	9$
	tst.b	(userok,NodeBase)	; er brukeren inne ?
	beq.b	9$			; nei.

	moveq.l	#0,d0			; setter opp offseten
	move.w	(Historyoffset,NodeBase),d0

	move.b	(a0)+,d1
	beq.b	9$			; ikke noe i det hele tatt. Ut
	bra.b	2$

1$	move.b	(a0)+,d1		; kopierer inn på riktig sted
	beq.b	3$
2$	move.b	d1,(0,a3,d0.w)
	addi.w	#1,d0
	and.w	#$3ff,d0
	bra.b	1$

3$	move.b	(0,a3,d0.w),d1		; fyller ut med 0'er til neste 0
	beq.b	4$
	move.b	#0,(0,a3,d0.w)
	addi.w	#1,d0
	and.w	#$3ff,d0
	bra.b	3$
4$	addi.w	#1,d0
	and.w	#$3ff,d0
	move.w	d0,(Historyoffset,NodeBase)
9$	pop	a3
	rts

	IFD	notyet
writestringspes
	push	a2/d2
	move.w	#256,d2
	move.l	a0,a2
	bsr	outimage

1$	move.b	(a2)+,d0
	bne.b	2$
	move.b	#'_',d0
2$	bsr	writechar
	subi.w	#1,d2
	bne.b	1$

	bsr	outimage
	pop	a2/d2
	rts
	ENDC

testbreak
	IFD	nobreak
	clrz
	rts
	ENDC
	move.b	(con_tegn,NodeBase),d0
	cmpi.b	#27,d0			; Sjekker etter ESC
	beq.b	9$
	cmpi.b	#3,d0			; Sjekker etter CTLR C
	beq.b	9$
	cmpi.b	#11,d0			; Sjekker etter CTLR K
	IFND DEMO
	beq.b	9$
	move.b	(ser_tegn,NodeBase),d0
	cmpi.b	#27,d0			; Sjekker etter ESC
	beq.b	9$
	cmpi.b	#3,d0			; Sjekker etter CTLR C
	beq.b	9$
	cmpi.b	#11,d0			; Sjekker etter CTLR K
	ENDC
9$	rts


startsleepdetect
	move.b	(userok,NodeBase),d0
	bne.b	startsleepdetect1
	rts
startsleepdetect1
	tst.w	(SleepTime+CStr,MainBase)		; Har vi sleepgrense ?
	beq.b	9$				; nei ..
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal ?
	beq.b	9$				; ja -> ingen sleeptimer
	ENDC
	move.w	(Setup+Nodemem,NodeBase),d1
	and.w	#SETUPF_NoSleepTime+SETUPF_NullModem,d1		; Nullmodem eller ingen sleeptime ?
	bne.b	9$				; Ja, da har vi ikke sleep
	push	d0/d1/a0/a1/a6
	move.b	#1,(dosleepdetect,NodeBase)
	move.l	(dosbase),a6
	lea	(lastchartime,NodeBase),a0	; lagrer dette som tid for
	move.l	a0,d1				; siste tastetrykk
	jsrlib	DateStamp
	move.l	(exebase),a6
	bsr	stoptimeouttimer
	move.w	(SleepTime+CStr,MainBase),d0
	bsr	starttimeouttimer
8$	pop	d0/d1/a0/a1/a6
9$	rts

*****************************************************************
*				IO rutiner			*
*****************************************************************

***************************************
* Hoved vente løkke. Venter på tegn fra serial og keyboard,
* timer msg, intuition msg'er og public porten
***************************************

readchar
	move.l	(gotbits,NodeBase),d0		; har vi noe fra før ?
	bne.b	0$				; ja
	moveq.l	#0,d0
	move.l	(pastetext,NodeBase),d1		; sjekker om det ligger tegn og venter
	bne.b	0$				; det gjorde det. 
	move.l	(waitbits,NodeBase),d0		; det hadde vi ikke, så da
	jsrlib	Wait				; venter vi
	move.l	d0,(gotbits,NodeBase)		; husker de vi fikk

0$	bsr	testdoconsole
	beq.b	1$
	bsr	doconsole
	beq.b	readchar
	rts

1$	bsr	testdoserial
	beq.b	2$
	bsr	doserial
	bne.b	11$
	bmi.b	readchar
11$	rts

2$	bsr	testdointuition
	beq.b	3$
	bsr	dointuition
	bne.b	readchar
	rts

3$	bsr	testdointernode
	beq.b	4$
	bsr	dointernode
	beq.b	readchar
	notz
	clrn
	rts

4$	bsr	testdopublicport
	beq.b	5$
	bsr	handlepublicport
	beq.b	41$
	tst.b	(readcharstatus,NodeBase)	; noe galt ?
	notz
	bne	readchar			; fortsetter
41$	rts

5$	bsr	testdotimer
	beq.b	6$
	bsr	dotimer
	beq	readchar
	setz
	rts

6$	bsr	testshowwinsig
	beq	readchar
	bsr	closeshowuserwindow
	bra	readchar

; input d0 = signaler. Må ikke ødelegge d0 (hvis den ikke slår til)
testshowwinsig
	move.l	d0,d1				; console
	and.l	(showwinsigbit,NodeBase),d1
	beq.b	9$
	move.l	(showwinsigbit,NodeBase),d0
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

testdoconsole
	move.l	(pastetext,NodeBase),d1		; sjekker om det ligger tegn og venter
	bne.b	9$				; det gjorde det. 
	move.l	(cwritereq,NodeBase),d1		; get write structure
	bne.b	1$
	move.l	(consigbit,NodeBase),d1		; sletter dette bit'et
	not.l	d1				; fra de vi fikk fra Wait
	and.l	d1,(gotbits,NodeBase)
	setz
	bra.b	9$				; no console
1$	move.l	d0,d1				; console
	and.l	(consigbit,NodeBase),d1
	beq.b	9$
	move.l	(consigbit,NodeBase),d0		; sletter dette bit'et
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

; input d0 = signaler. Må ikke ødelegge d0
testdoserial
	move.l	d0,d1				; serial
	and.l	(sersigbit,NodeBase),d1
	beq.b	9$
	move.l	(sersigbit,NodeBase),d0		; sletter dette bit'et
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

; input d0 = signaler. Må ikke ødelegge d0
testdointuition
	move.l	d0,d1				; intuition
	and.l	(intsigbit,NodeBase),d1
	beq.b	9$
	move.l	(windowadr,NodeBase),d1
	bne.b	1$				; vi har vindu
	move.l	(intsigbit,NodeBase),d1		; sletter dette bit'et
	not.l	d1				; fra de vi fikk fra Wait
	and.l	d1,(gotbits,NodeBase)
	setz
	bra.b	9$				; no window
1$	move.l	(intsigbit,NodeBase),d0		; sletter dette bit'et
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

; input d0 = signaler. Må ikke ødelegge d0
testdointernode
	move.l	d0,d1				; internode
	and.l	(intersigbit,NodeBase),d1
	beq.b	9$
	move.l	(intersigbit,NodeBase),d0	; sletter dette bit'et
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

; input d0 = signaler. Må ikke ødelegge d0
testdopublicport
	move.l	d0,d1				; public port
	and.l	(publicsigbit,NodeBase),d1
	beq.b	9$
	and.l	(publicsigbit,NodeBase),d0	; sletter dette bit'et
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

; input d0 = signaler. Må ikke ødelegge d0
testdotimer
	move.l	d0,d1
	and.l	(timer2sigbit,NodeBase),d1	; timer
	beq.b	9$
	move.l	(timer2sigbit,NodeBase),d0	; sletter dette bit'et
	not.l	d0				; fra de vi fikk fra Wait
	and.l	d0,(gotbits,NodeBase)
	clrz
9$	rts

doconsole
	move.l	(creadreq,NodeBase),d0
	beq	9$				; ikke noe console...
	move.l	(pastetext,NodeBase),d0		; sjekker om det ligger tegn og venter
	beq.b	13$				; det gjorde det ikke, vanelig console.
	jsr	(getnextsnipchar)
	beq	104$				; siste tegnet (console read er i gang)
	bsr	20$				; behandler tegnet
	bne	104$
	bra	101$
13$	move.l	(creadreq,NodeBase),a1		; Console
	move.l	(MN_REPLYPORT,a1),a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$				; fake

	move.l	(dosbase),a6
	lea	(lastchartime,NodeBase),a0	; lagrer tid for siste
	move.l	a0,d1				; tastetrykk
	jsrlib	DateStamp
	move.l	(exebase),a6
	lea	(con_tegn,NodeBase),a0
	moveq.l	#0,d0
	move.b	(a0),d0
	tst.b	(FSEditor,NodeBase)		; Vi er i FSE. Ingen dekoding
	bne	1$
	cmpi.b	#$9b,d0				; ansi sekvens ?
	bne	2$				; nope

	moveq.l	#0,d1
5$	move.w	d1,-(a7)
	moveq.l	#1,d0				; Spesial sekvens. Les neste
	move.l	(creadreq,NodeBase),a1
	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a0,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	jsrlib	DoIO
	move.w	(a7)+,d1
	lea	(con_tegn,NodeBase),a0
	move.b	(a0),d0
	cmp.w	#-1,d1
	beq.b	10$				; holder på med shift-pil
	cmpi.b	#'~',d0
	beq.b	6$
	cmpi.b	#'A',d0				; piltaster eller noe annet rart.
	bcc.b	7$
	cmp.b	#' ',d0				; space
	bne.b	8$
	moveq.l	#-1,d1
	bra.b	5$				; leser neste

8$	subi.b	#'0',d0
	bcs	4$				; Ikke tall
	cmpi.b	#9,d0
	bhi	4$				; Ikke tall
	mulu.w	#10,d1
	andi.w	#$f,d0
	add.w	d0,d1
	bra.b	5$
7$	subi.b	#'A',d0
	bcs	4$
	cmpi.b	#4,d0
	bcc	4$
	addi.w	#20,d0				; legger til for piltaster
11$	move.w	d0,d1
6$	move.w	d1,-(sp)
	lea	(con_tegn,NodeBase),a0
	move.b	#0,(con_tegn,NodeBase)		; tømmer for sikkerhetsskyld
	bsr	initconread
	move.b	#1,(tegn_fra,NodeBase)		; Siste tegnet fra con, spesialtegn.
	move.w	(sp)+,d0
	clrz
	setn
	bra.b	9$

10$	cmp.b	#'v',d0
	bne.b	12$
	tst.b	(in_waitforcaller,NodeBase)
	bne.b	4$				; ikke noe snip'ing her
	jsr	dosnip
	beq.b	4$
	bra.b	2$
12$	subi.b	#'@',d0
	bcs.b	4$
	cmpi.b	#2,d0
	bcc.b	4$
	addi.w	#24,d0				; legger til for shift-piltaster
	bra.b	11$

2$	bsr	20$
	bne.b	4$
1$	move.w	d0,-(sp)
	bsr	initconread
	move.w	(sp)+,d0
101$	move.b	#1,(tegn_fra,NodeBase)		; Siste tegnet fra con.
	clrzn
	bra.b	9$

4$	move.b	#0,(con_tegn,NodeBase)		; tømmer for sikkerhetsskyld
	bsr	initconread
	bra.b	105$
104$	move.b	#0,(con_tegn,NodeBase)		; tømmer for sikkerhetsskyld
105$	setz

9$	rts

20$	cmpi.b	#31,d0				; kontroll kode ?
	bhi.b	21$				; nope
	cmpi.b	#8,d0				; Back space
	beq.b	21$
	cmpi.b	#24,d0				; ctrl-x
	beq.b	21$
	cmpi.b	#21,d0				; ctrl-u
	bne.b	23$
	move.b	#24,d0				; forvanler til ctrl-x
	bra.b	21$
23$	cmpi.b	#9,d0				; TAB
	beq.b	21$
	cmpi.b	#13,d0				; Carrige return
	beq.b	21$
	cmpi.b	#10,d0				; Line Feed
	bra.b	29$
21$	setz
29$	rts

	IFND DEMO
doserial
	move.l	(sreadreq,NodeBase),a1		; Serial
	move.l	(MN_REPLYPORT,a1),a0
	jsrlib	GetMsg
	tst.l	d0
	setn
	beq	9$				; lure signal. Ut
	move.l	(dosbase),a6
	lea	(lastchartime,NodeBase),a0	; lagrer tid for siste
	move.l	a0,d1				; tastetrykk
	jsrlib	DateStamp
	move.l	(exebase),a6
	move.l	(sreadreq,NodeBase),a1
	move.w	#SDCMD_QUERY,(IO_COMMAND,a1)
	jsrlib	DoIO				; Sjekke flagg
	moveq.l	#0,d0
	move.b	(ser_tegn,NodeBase),d0		; Henter lest tegn
	tst.b	(FSEditor,NodeBase)		; Vi er i FSE. Ingen dekoding
	bne	1$

	move.b	(serescstat,NodeBase),d1		; parser ESC sekvenser
	bne.b	3$
	cmpi.b	#27,d0				; esc ?
	bne	1$				; nope
	move.b	#1,(serescstat,NodeBase)
	bra.b	2$

3$	cmpi.b	#1,d1
	bne.b	4$
	cmpi.b	#'[',d0
	bne	5$
	move.b	#2,(serescstat,NodeBase)
	bra.b	2$

4$	cmp.b	#'K',d0				; shift høyre
	bne.b	41$
	moveq.l	#24,d0				; shift høyre	= 24
	bra.b	43$
41$	cmp.b	#'H',d0				; shift venstre
	bne.b	42$
	moveq.l	#25,d0				; shift venstre	= 25
	bra.b	43$
42$	subi.b	#'A',d0
	bcs.b	7$
	cmpi.b	#4,d0
	bcc.b	7$
	addi.w	#20,d0				; legger til for piltaster
43$	move.b	#0,(serescstat,NodeBase)
	move.w	d0,-(sp)			; og lagrer
	move.b	#0,(ser_tegn,NodeBase)		; tømmer for sikkerhetsskyld
	bsr	initserread
	move.w	(sp)+,d0			; Henter ut lest tegn
	move.b	#2,(tegn_fra,NodeBase)		; Siste tegnet fra ser.
	IFND	nocarrier
	move.w	(Setup+Nodemem,NodeBase),d1
	btst	#SETUPB_NullModem,d1		; Nullmodem ?
	bne.b	62$				; jepp, no CD checking.
	move.l	(sreadreq,NodeBase),a1
	move.w	(IO_STATUS,a1),d1		; Henter serial.status
	btst	#5,d1				; Har vi CD ?
	bne.b	8$				; Nei, "NoCarrier"
	ENDC
62$	clrz
	setn
	bra.b	9$

7$	move.b	#0,(serescstat,NodeBase)
2$	bsr	initserread
	IFND	nocarrier
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0	; Nullmodem ?
	bne.b	61$			; jepp, no CD checking.
	move.l	(sreadreq,NodeBase),a1
	move.w	(IO_STATUS,a1),d1		; Henter serial.status
	btst	#5,d1				; Har vi CD ?
	bne.b	8$				; Nei, "NoCarrier"
	ENDC
61$	setzn
	bra.b	9$				; nulltegn. Les neste

5$	move.b	#0,(serescstat,NodeBase)
1$	move.w	d0,-(sp)		; og lagrer
	move.b	#0,(ser_tegn,NodeBase)	; tømmer for sikkerhetsskyld
	bsr	initserread
	move.w	(sp)+,d0		; Henter ut lest tegn
	move.b	#2,(tegn_fra,NodeBase)	; Siste tegnet fra ser.
	move.l	(sreadreq,NodeBase),a1

	IFND	nocarrier
	move.w	(Setup+Nodemem,NodeBase),d1
	btst	#SETUPB_NullModem,d1	; Nullmodem ?
	bne.b	6$			; jepp, no CD checking.
	move.w	(IO_STATUS,a1),d1	; Henter serial.status
	btst	#5,d1			; Har vi CD ?
	bne.b	8$			; Nei, "NoCarrier"
	ENDC
6$	bsr	translateserinchar	; fra tegnsett x til ISO
	clrn
	bne.b	9$
	setn				; nulltegn. Les neste
	bra.b	9$

8$	move.b	#NoCarrier,(readcharstatus,NodeBase)
	setz				; No carrier, Logoff !!
	clrn
9$	rts
	ENDC

; må ikke legge ting på stack'en. handleintuition pop'er return adressen hit
dointuition
	bsr	handleintuition
	btst	#DoDivB_HideNode,(DoDiv,NodeBase)
	beq.b	1$
	bclr	#DoDivB_HideNode,(DoDiv,NodeBase)
	bsr	hidenode
1$	move.b	(readcharstatus,NodeBase),d0
	notz
	rts

dointernode
	move.l	(nodenoden,NodeBase),a0
	move.w	(Nodestatus,a0),d0
	cmpi.w	#8,d0				; chat'er vi ?
	beq.b	1$				; Jepp.
	cmpi.w	#60,d0				; privat chat'er vi ?
	beq.b	1$				; Jepp.
	cmpi.w	#44,d0				; sysop chat'er vi ?
	beq.b	1$				; Jepp.
	tst.l	(curprompt,NodeBase)
	beq.b	9$				; Kan ikke behandle nå
	bsr	checkintermsgs			; skriver ut intermsg's
	beq.b	9$				; Det var ikke noe til oss
	bsr	outimage
	move.l	(curprompt,NodeBase),a0
	bsr	writetexti
	lea	(intextbuffer,NodeBase),a0	; oppdatere de vi har skrevet ...
	bsr	writetexti
	lea	(intextbuffer,NodeBase),a0
	bsr	strlen
	beq.b	2$				; ingen lengde
	moveq.l	#0,d1
	move.b	(cursorpos,NodeBase),d1
	sub.l	d1,d0
	beq.b	2$
	bcs.b	2$
	move.b	#'D',d1
	bsr	stepcursor
2$	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)	; nustiller more faren
	setz
	bra.b	9$
1$	move.l	(tmpstore,NodeBase),d0		; vi sysop chat'er, så vi vil	*TROLIG BUG. Andre ting bruker også tmpstore. FIX ME *
	notz					; ikke få rapportert intersig
9$	rts

dotimer	move.l	(timer2req,NodeBase),a1		; henter melding
	move.l	(MN_REPLYPORT,a1),a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$
	move.l	(nodenoden,NodeBase),a0		; chat'er vi ?
	move.w	(Nodestatus,a0),d1
	cmpi.w	#28,d1				; Paging ?
	notz
	bne	9$				; ja, Returnerer
	move.w	(SleepTime+CStr,MainBase),d0		; Har vi sleepgrense ?
	beq	9$				; nei ..
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Lokal node ?
	beq	9$				; ja, da har vi ikke sleep
	ENDC
	move.w	(Setup+Nodemem,NodeBase),d1
	and.w	#SETUPF_NoSleepTime+SETUPF_NullModem,d1		; Nullmodem eller ingen sleeptime ?
	notz
	beq.b	9$				; Ja, da har vi ikke sleep

	move.l	(nodenoden,NodeBase),a0		; chat'er vi ?
	move.w	(Nodestatus,a0),d1
	cmpi.w	#8,d1				; nodestatus = Chatting
	beq.b	9$				; ja, glemmer
	cmpi.w	#44,d1				; nodestatus = Sysop Chatting
	beq.b	9$				; ja, glemmer

	move.b	(userok,NodeBase),d0		; det er logintimer
	beq.b	1$
	tst.b	(dosleepdetect,NodeBase)		; skal vi reagere ?
	beq.b	9$				; nei
	move.l	(dosbase),a6			; finner tiden nå
	lea	(tmplargestore,NodeBase),a0
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	(exebase),a6
	lea	(tmplargestore,NodeBase),a1
	lea	(lastchartime,NodeBase),a0	; tiden for siste tastetrykk
	bsr	calcminsnoround			; d0 = minutter siden siste tast
	moveq.l	#0,d1
	move.w	(SleepTime+CStr,MainBase),d1		; sjekker mot sleepgrensen
	cmp.l	d1,d0
	bcc.b	1$				; oops. Han har sovna.
	addq.l	#1,d0				; legger til et minutt for å
	bsr	starttimeouttimer		; være på den sikre siden
	setz
	bra.b	9$
1$	move.w	#-1,(linesleft,NodeBase)		; Dropper all more saker ..
	lea	(lfellasleeptext),a0
	bsr	writetexti
	move.b	#Timeout,(readcharstatus,NodeBase)
	clrz					; timeout ....
9$	rts

;handleintuition1			; hack for å unslippe kræsj med eject
;	bsr	handleintuition		; user mens brukeren pager sysop
;	rts

handleintuition
	move.l	(windowadr,NodeBase),d0
	beq.b	9$			; no port
0$	move.l	(intmsgport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$
	move.l	d0,a1
	move.l	(im_Class,a1),d0
	cmpi.l	#IDCMP_MENUPICK,d0
	beq.b	1$
	cmpi.l	#IDCMP_REFRESHWINDOW,d0
	beq.b	10$
	cmpi.l	#IDCMP_NEWSIZE,d0
	beq.b	20$
4$	jsrlib	ReplyMsg
	bra.b	0$
1$	move.w	(im_Code,a1),-(a7)
	jsrlib	ReplyMsg
	move.w	(a7)+,d0
3$	cmpi.w	#MENUNULL,d0
	beq.b	0$
	bsr	handlemenu
	bmi.b	999$			; Vi skal ut. Vekk med 
	beq.b	99$
	bra.b	3$
9$	clrz
	bra.b	99$
999$	addq.l	#4,a7			; fjerner retur adressen
	clrn
99$	rts

10$	push	a1/a6
	move.l	(intbase),a6
	move.l	(windowadr,NodeBase),a0
	jsrlib	BeginRefresh
	move.l	(windowadr,NodeBase),a0
	jsrlib	EndRefresh
	pop	a1/a6
	bra.b	4$

20$	jsrlib	ReplyMsg
	move.l	(windowadr,NodeBase),a0
	move.w	(wd_Width,a0),d0
	cmpi.w	#minwindowx,d0
	bhi.b	21$
	move.w	(wd_Height,a0),d0
	cmpi.w	#minwindowy,d0
	bhi.b	21$
	move.b	#1,(Tinymode,NodeBase)
	bsr	writetinystatus
	bra.b	29$
21$	move.b	(Tinymode,NodeBase),d0
	beq.b	29$
	move.b	#0,(Tinymode,NodeBase)
	move.b	(in_waitforcaller,NodeBase),d0	; er vi i waitforcaller ?
	beq.b	22$
	bsr	drawwaitforcallerscreen
	bra.b	29$
22$	lea	(NormAtttext),a0		; sender ANSI reset.
	bsr	writecontext
	lea	(clearwindowtext),a0
	bsr	writecontext
29$	bra	0$

handlemenu
	push	d2
	move.l	d0,d2				; husker menukode
	move.l	d0,d1
	lsr.l	#5,d1
	andi.w	#$3f,d1				; finner item nummeret
	andi.w	#$1f,d0				; finner menu nummeret
	bne	1$				; ikke menu 0
	move.w	d1,d0
	bne.b	2$				; ikke item 0

	move.w	d2,d0				; item 00 (sysopchat)
	jsr	(sysopchat)
	setz
	bmi	9$				; vi skal avslutte chat
	bra	6$

2$	cmpi.w	#1,d0				; menuitem 1 (user info)
	bne.b	3$
	jsr	(menu_showuser)
	bra	6$

3$	cmpi.w	#2,d0				; menuitem 2 (eject user)
	bne	103$
	move.l	(Name+CU,NodeBase),d0		; eject. Men er det noen inne ?
	beq	6$				; nei ... Da dropper vi saken..
	move.w	#-1,(linesleft,NodeBase)		; Dropper all more saker ..
	lea	(throwouttext1),a0
	bsr	writetexti
	lea	(throwouttext2),a0
	bsr	writetexti
	move.b	#Thrownout,(readcharstatus,NodeBase)
	setzn
	bra	9$

103$	cmpi.w	#3,d0				; menuitem 3 (Kill user)
	bne	105$
	move.l	(Name+CU,NodeBase),d0		; Kill Men er det noen inne ?
	beq	6$				; nei ... Da dropper vi saken..
	move.l	(Usernr+CU,NodeBase),d0		; Er vi supersysop ?
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq	6$				; ja, ikke kille denne..
	lea	(killathrowntext),a0
	bsr	writetexti
	lea	(Userbits+CU,NodeBase),a0
	ori.w	#USERF_Killed,(a0)
	moveq.l	#2,d0
	bsr	saveuserarea
	move.b	#Thrownout,(readcharstatus,NodeBase)
	setzn
	bra	9$

105$	cmpi.w	#5,d0				; menuitem 5 (Zoom window)
	bne.b	106$
	move.l	(intbase),a6
	move.l	(windowadr,NodeBase),a0
	jsrlib	ZipWindow
	move.l	(windowadr,NodeBase),a0
	jsrlib	WindowToFront
	move.l	(exebase),a6
	bra	6$

106$	cmpi.w	#7,d0				; menuitem 7 (Hode node)
	bne	6$				; ikke flere item'er i meny 0
	bset	#DoDivB_HideNode,(DoDiv,NodeBase)
	bra	6$

1$	cmpi.w	#1,d0
	bne	6$				; ikke menu 1
	move.w	d1,d0
	bne.b	4$				; ikke item 0
	tst.b	(userok,NodeBase)		; er user inne ?
	beq	6$				; nei.
	move.w	(TimeLimit+CU,NodeBase),d0		; item 10, add 5 min
	beq	6$
	addi.w	#5,d0
	bra.b	41$

4$	cmpi.w	#1,d0
	bne.b	5$
	tst.b	(userok,NodeBase)		; er user inne ?
	beq	6$				; nei.
	move.w	(TimeLimit+CU,NodeBase),d0		; item 11, sub 5 min
	beq	6$				; 0 dvs uendelig tid
	subi.w	#5,d0
	bhi.b	41$				; gikk bra.
	move.w	#1,d0				; minimumm er 1..
41$	move.w	d0,(TimeLimit+CU,NodeBase)
	bra.b	6$

5$	cmpi.w	#2,d0
	bne.b	51$
	tst.b	(userok,NodeBase)		; er user inne ?
	beq.b	6$				; nei.
	move.w	(FileLimit+CU,NodeBase),d0		; item 12, add 5 f min
	beq.b	6$
	addi.w	#5,d0
	bra.b	58$

51$	cmpi.w	#3,d0
	bne.b	52$
	tst.b	(userok,NodeBase)		; er user inne ?
	beq.b	6$				; nei.
	move.w	(FileLimit+CU,NodeBase),d0		; item 13, sub 5 f min
	beq.b	6$				; 0 dvs uendelig tid
	subi.w	#5,d0
	bhi.b	58$				; gikk bra.
	move.w	#1,d0				; minimumm er 1..
58$	move.w	d0,(FileLimit+CU,NodeBase)
	bra.b	6$

52$	cmpi.w	#5,d0				; 4 = barlabel
	bne.b	6$				; ikke flere itemer i meny 1
	move.b	(Cflags+CStr,MainBase),d0		; Tillater vi tmp  sysop acc ?
	andi.b	#CflagsF_AllowTmpSysop,d0
	beq.b	6$				; nope
	tst.b	(userok,NodeBase)		; er user inne ?
	beq.b	6$				; nei.
	lea	(tmpsysopacctext),a0
	bsr	writetext
	lea	(takenawaytext),a0
	eori.b	#1,(tmpsysopstat,NodeBase)
	beq.b	53$
	lea	(giventext),a0
53$	bsr	writetexto
;	bra.b	6$

6$	move.l	(intbase),a6
	move.w	d2,d0
	move.l	(a7),d2				; henter ut menyverdien
	move.l	(node_menu,NodeBase),a0
	jsrlib	ItemAddress
	tst.l	d0
	bne.b	7$
	move.w	#MENUNULL,d0
	bra.b	8$
7$	move.l	d0,a0
	move.w	(mi_NextSelect,a0),d0
	clrz
8$	clrn
9$	pop	d2
	move.l	(exebase),a6
	rts

setsysopcheckmark
	moveq.l	#1,d0
	bra.b	remsysopcheckmark1
remsysopcheckmark
	moveq.l	#0,d0
remsysopcheckmark1
	push	a6/d2
	move.l	d0,d2
	move.l	(intbase),a6
	move.l	(windowadr,NodeBase),d0
	beq.b	9$
	move.l	d0,a0
	jsrlib	ClearMenuStrip

	move.l	(node_menu,NodeBase),a0
	move.l	(mu_FirstItem,a0),a0
	andi.w	#~CHECKED,(mi_Flags,a0)
	tst.l	d2
	beq.b	1$
	or.w	#CHECKED,(mi_Flags,a0)
1$
	move.l	(node_menu,NodeBase),a1
	move.l	(windowadr,NodeBase),a0
	jsrlib	ResetMenuStrip
9$	pop	a6/d2
	rts

handlepublicport
	push	d2/a2/d3/d4/a3
	moveq.l	#0,d2
0$	move.l	(nodepublicport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$			; ferdig
	move.l	d0,a2			; husker meldingen (front_login er avhengig av at denne ligger i a2)
	move.l	d0,a0
	XREF	CheckRexxMsg
	jsr	(CheckRexxMsg)		; arexx melding ??
	tst.w	d0
	beq.b	1$			; nope, vanelig
	move.l	(ARG0,a2),a0		; arexx meldinger...
	bsr	doarexxcmd
	move.l	d0,a1			; gjemmer retur koden, må ikke røre CC'ene
	jsrlib	GetCC
	move.l	d1,d3			; Retur verdi (til prosedyren her i abbs)
	move.w	d0,d2			; CC reg
	move.l	a1,d4			; retur koden (til arexx kalleren)
	move.l	a0,a3			; husker strengen
	move.l	(nodepublicport,NodeBase),a0	; er det flere meldinger til oss?
	move.l	(MP_MSGLIST+LH_HEAD,a0),d0
	beq.b	2$				; nope
	move.l	(publicsigbit,NodeBase),d0	; setter signalet igjen
	move.l	d0,d1
	jsrlib	SetSignal

2$	move.l	a2,a1			; tar reply
	tst.l	(MN_REPLYPORT,a1)	; har vi reply port ?
	beq.b	3$			; nope
	move.b	(readcharstatus,NodeBase),d0
	beq.b	7$
	moveq.l	#20,d4			; noe har skjedd. Sett RC til 20
7$	moveq.l	#0,d0
	move.l	d0,(rm_Result2,a2)
	move.l	d4,(rm_Result1,a2)	; setter RC
	bne.b	4$			; error
	move.l	a3,d0			; har vi en streng ?
	beq.b	4$			; nope
	move.l	(ACTION,a2),d0		; vil han ha en string ?
	btst	#RXFB_RESULT,d0
	beq.b	4$			; nope
	move.l	(rexbase),d0		; henter libbase
	beq.b	4$			; har ingen!
	move.l	d0,a6
	move.l	a3,a0
	bsr	strlen
	move.l	a3,a0
	jsrlib	CreateArgstring
	move.l	a2,a1
	move.l	d0,(rm_Result2,a1)
	move.l	(exebase),a6
4$	jsrlib	ReplyMsg		; tar reply
3$	move.l	d3,d0
	bra.b	9$

1$	move.l	a2,a0
	move.w	#Error_IllegalCMD,(m_Error,a0)
	lea	(nodemsgportjumps),a1
	move.w	(m_Command,a0),d0
	bpl.b	6$
	bclr	#15,d0
	lea	(privatenodemsgportjumps),a1
	cmp.w	#Node_LASTPRIVCOMM,d0		; lovlig kommando ?
	bra.b	61$
6$	cmpi.w	#Node_LASTCOMM,d0		; lovlig kommando ?
61$	bcc.b	8$				; nei
	asl.w	#2,d0
	move.l	(0,a1,d0.w),a1
	jsr	(a1)
	jsrlib	GetCC
	move.l	d1,d3				; Retur verdi (til prosedyren her i abbs)
	move.w	d0,d2				; husker CC reg

8$	move.l	a2,d0				; har vi fremdeles melding ? (front_login fjerner meldingen)
	beq.b	82$
	move.l	a2,a1
	tst.l	(MN_REPLYPORT,a1)		; har vi reply port ?
	beq	5$				; nope
	jsrlib	ReplyMsg			; tar reply
	bra.b	82$
5$	moveq.l	#ABBSmsg_SIZE,d0
	jsrlib	FreeMem
82$	move.w	d2,ccr
	bne	0$				; ikke ut, looper og tar alle meldingene
	move.l	(nodepublicport,NodeBase),a0	; er det flere meldinger til oss?
	move.l	(MP_MSGLIST+LH_HEAD,a0),d0
	beq.b	81$				; nope
	move.l	(publicsigbit,NodeBase),d0	; setter signalet igjen
	move.l	d0,d1
	jsrlib	SetSignal
81$	move.l	d3,d0
9$	move.w	d2,ccr
	pop	d2/a2/d3/d4/a3
	rts

; vanelige userport funksjoner.
; kalles med msg'en i a0.
; z = 1 - hopp ut av readchar
; d1 - retur verdi til amiga procedyren (hvis vi skal dit)
front_getserdev
	move.w	#F_Error_NoSerial,(pm_Error,a0)
	move.b	(RealCommsPort,NodeBase),d0		; Setter tilbake comport
;	beq	9$					; har ingen
	setz
	rts

front_sleepser
	move.w	#F_Error_UserOnline,(pm_Error,a0)
	move.b	(in_waitforcaller,NodeBase),d0
	beq.b	9$
	move.w	#F_Error_NoSerial,(pm_Error,a0)
	move.b	(CommsPort+Nodemem,NodeBase),d0		; Lokal node ?
	beq.b	9$					; Fy...
	move.w	#F_Error_OK,(pm_Error,a0)
	move.b	#0,(CommsPort+Nodemem,NodeBase)		; Gjør noden lokal.
	bsr	stopserread				; avbryter read req'en
	bset	#DoDivB_Sleep,(DoDiv,NodeBase)		; sett sleep
	jsr	(updatewindowtitle)
9$	clrz
	rts

front_awakeser
	move.w	#F_Error_NoSerial,(pm_Error,a0)
	btst	#DoDivB_Sleep,(DoDiv,NodeBase)		; har vi sleep
	beq.b	9$					; nope
	move.b	(RealCommsPort,NodeBase),d0		; Setter tilbake comport
	beq	9$					; har ingen
	move.b	#-1,d1
	cmp.b	d0,d1
	beq	9$					; har aldri hatt
	bclr	#DoDivB_Sleep,(DoDiv,NodeBase)		; slett sleep
	push	a0/d0
	jsr	(updatewindowtitle)
	pop	a0/d0
	move.w	#F_Error_OK,(pm_Error,a0)
	cmp.b	(CommsPort+Nodemem,NodeBase),d0		; ble den disablet ?
	beq.b	9$					; nei, ikke start igjen
	move.b	d0,(CommsPort+Nodemem,NodeBase)
	bsr	initserread				; starter opp en read request
9$	clrz
	rts

front_dologin
	move.w	#F_Error_UserOnline,(pm_Error,a0)
	move.b	(in_waitforcaller,NodeBase),d0
	beq	9$					; bruker er på
	move.w	#F_Error_NoSerial,(pm_Error,a0)
	move.b	(RealCommsPort,NodeBase),d0		; Setter tilbake comport
	beq	9$					; har ingen
	move.b	#-1,d1
	cmp.b	d0,d1
	beq	9$					; har aldri hatt

	push	a2/a3
	move.l	a0,a2
	bclr	#DoDivB_Sleep,(DoDiv,NodeBase)		; slett sleep
	jsr	(updatewindowtitle)
	move.b	(RealCommsPort,NodeBase),d0
	cmp.b	(CommsPort+Nodemem,NodeBase),d0		; ble den disablet ?
	beq.b	1$					; nei, ikke start igjen
	move.b	d0,(CommsPort+Nodemem,NodeBase)
1$	move.l	(f_Connect,a2),a3
	move.l	(cm_baud,a3),d0
	divu.w	#10,d0
	move.w	d0,(cpsrate,NodeBase)
	move.l	(cm_baud,a3),d0
	bsr	changenodestatusspeed
	move.l	(cm_baud,a3),d0
	moveq.l	#0,d1					; ikke send AT
	bsr	setserialspeed
	bsr	initserread				; starter opp en read request
	move.b	#0,d0					; ingen MNP/V42bis status
	move.l	(cm_compression,a3),d1
	beq.b	2$
	move.l	d1,a0
	bsr	parsemnpsub
2$	move.l	(cm_connect,a3),d1
	beq.b	3$
	move.l	d1,a0
	bsr	parsemnpsub
3$	bsr	setmnpstat
	lea	(nulltext),a0
	move.l	(f_LoginString,a2),d0
	beq.b	4$
	move.l	d0,a0
4$	lea	(intextbuffer,NodeBase),a1		; HACK!
	bsr	strcopy
	move.b	#1,(readlinemore,NodeBase)
	move.w	#0,(intextchar,NodeBase)
	move.w	#F_Error_OK,(pm_Error,a2)
	move.l	a2,(FrontDoorMsg,NodeBase)		; Lagrer meldingen
	pop	a2/a3
	suba.l	a2,a2					; Hack for at handlepublicmsg ikke skal ta replymsg
	bset	#DoDivB_ExitWaitforCaller,(DoDiv,NodeBase)
	clrz
9$	notz
	rts

front_droppcarrier
	move.w	#F_Error_UserOnline,(pm_Error,a0)
	move.b	(in_waitforcaller,NodeBase),d0
	beq.b	9$					; bruker er på
	move.w	#F_Error_NoSerial,(pm_Error,a0)
	move.b	(CommsPort+Nodemem,NodeBase),d0		; Lokal node ?
	beq.b	9$					; Fy..
	move.w	#F_Error_OK,(pm_Error,a0)
	bsr	dohangup
9$	clrz
	rts

front_replyNOW
	move.w	#F_Error_NoMsgtoReply,(pm_Error,a0)
	move.l	(FrontDoorMsg,NodeBase),d0
	beq.b	9$
	move.l	d0,a1
	tst.l	(MN_REPLYPORT,a1)		; har vi reply port ?
	beq.b	9$				; nope
	move.w	#F_Error_OK,(pm_Error,a0)
	jsrlib	ReplyMsg
	moveq.l	#0,d0
	move.l	d0,(FrontDoorMsg,NodeBase)	; ikke en gang til nei!
9$	clrz
	rts


;msg_quitlogin
;	IFD	OLD_NETLOGIN
;	btst	#DIVB_InNetLogin,(Divmodes,NodeBase)
;	notz
;	bne.b	9$
;	lea	(tmptext,NodeBase),a1
;	move.b	#0,(a1)
;	move.l	(pm_Arg,a0),d0
;	beq.b	9$
;	move.l	(pm_Data,a0),a0
;	moveq.l	#60,d0
;	bsr	strcopymaxlen
;	setz
;	ELSE
;	clrz
;	ENDC	; OLD_NETLOGIN
;9$	rts
;
;msg_writeserlen
;	push	a0
;	bsr	waitseroutput
;	pop	a0
;	move.w	#PError_OK,(pm_Error,a0)
;	move.l	(pm_Arg,a0),d0
;	move.l	(pm_Data,a0),a0
;	bsr	serwritestringlen
;	clrz
;	rts
;
;msg_readser
;	push	a2
;	move.l	a0,a2
;
;1$	move.l	(sersigbit,NodeBase),d0
;	jsrlib	Wait
;	bsr	doserial
;	bmi.b	1$				; ikke noe
;
;	move.b	d0,(3+pm_Data,a2)		; return character read
;	move.w	#PError_OK,(pm_Error,a2)
;	move.b	(readcharstatus,NodeBase),d0
;	beq.b	9$
;	move.w	#PError_NoCarrier,(pm_Error,a2)
;9$	pop	d2
;	clrz
;	rts
;
;msg_readserlen
;	push	a2
;	move.l	a0,a2
;	move.l	(pm_Data,a2),a0
;	move.l	(pm_Arg,a2),d0
;	move.l	(pm_Arg2,a2),d1
;	bsr	serreadt
;	move.l	d0,(pm_Arg,a2)			; return characters read
;	move.w	#PError_OK,(pm_Error,a2)
;	move.b	(readcharstatus,NodeBase),d0
;	beq.b	9$
;	move.w	#PError_NoCarrier,(pm_Error,a2)
;9$	pop	d2
;	clrz
;	rts
;
;msg_flushser
;	move.w	#PError_OK,(pm_Error,a0)
;	bsr	serclear
;	clrz
;	rts
;
;msg_writetext
;	move.w	#PError_OK,(pm_Error,a0)
;	move.l	(pm_Data,a0),a0
;	bsr	writetexti
;	clrz
;	rts
;
;msg_writetexto
;	push	a2
;	move.l	a0,a2
;	move.w	#PError_OK,(pm_Error,a2)
;	move.l	(pm_Data,a0),a0
;	bsr	writetexto
;	bne.b	9$
;	move.w	#PError_NoCarrier,(pm_Error,a2)
;	move.b	(readcharstatus,NodeBase),d0
;	bne.b	9$
;	move.w	#PError_NoMore,(pm_Error,a2)
;9$	pop	a2
;	clrz
;	rts

; private userport funksjoner.
; kalles med msg'en i a0.
; z = 1 - hopp ut av readchar
; d1 - retur verdi til amiga procedyren (hvis vi skal dit)
OffHook
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal ?
	beq.b	9$				; meningsløst..
	move.b	(in_waitforcaller,NodeBase),d1	; er vi i waitforcaller ?
	beq.b	9$				; nope. fy
	bsr	stengmodem
9$	clrzn
	rts

InitModem
	move.b	(in_waitforcaller,NodeBase),d1	; er vi i waitforcaller ?
	beq.b	9$				; nope. fy
	move.b	(RealCommsPort,NodeBase),d1
	beq	9$			; ingen port
	cmp.b	#-1,d1
	beq.b	9$			; ingen port..
	move.l	(sreadreq,NodeBase),a1
	move.l	(IO_DEVICE,a1),d1
	bne.b	1$			; vi har porten..
	jsr	tmpopenserport
	cmpi.b	#-1,(RealCommsPort,NodeBase)	; gikk det bra ?
	bne.b	4$				; jepp
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Vi prøver en gang til.
	move.b	d0,(RealCommsPort,NodeBase)
	bra.b	9$				; og ut.
4$	move.b	(RealCommsPort,NodeBase),(CommsPort+Nodemem,NodeBase)		; setter tilbake
1$	bsr	initwaitforcaller1		; tar init..
9$	clrzn
	rts

ReleasePort
	tst.b	(CommsPort+Nodemem,NodeBase)	; lokal ?
	beq.b	9$				; meningsløst..
	move.b	(in_waitforcaller,NodeBase),d1	; er vi i waitforcaller ?
	beq.b	9$				; nope. fy
	moveq.l	#0,d0
	bsr	wf_makenodelocal1		; jepp, dvs nobusy
;	beq.b	9$				; lokal node, ut. Umulig
	jsr	(tmpcloseserport)
	tst.b	(Tinymode,NodeBase)
	bne.b	9$
	lea	(preskreopentext),a0
	bsr	writecontext
9$	clrzn
	rts

gotosleep
	move.w	#Error_User_Active,(m_Error,a0)
	move.b	(in_waitforcaller,NodeBase),d0
	beq.b	9$
	move.w	#Error_OK,(m_Error,a0)
	cmp.b	#2,d0					; allerede sovna ?
	beq.b	9$					; ja (2 == sovna)
	move.b	#2,(in_waitforcaller,NodeBase)		; husker at vi sovner
	lea	(nodeputsleptext),a0
	bsr	writecontext
9$	clrzn
	rts

wakeupagain
	move.w	#Error_OK,(m_Error,a0)
	move.b	(in_waitforcaller,NodeBase),d0
	cmp.b	#2,d0
	bne.b	9$
	move.b	#1,(in_waitforcaller,NodeBase)		; husker at vi er våkne igjen.
	lea	(nodeawakentext),a0
	bsr	writecontext
9$	clrzn
	rts

ejectuser
	move.w	#Error_No_Active_User,(m_Error,a0)
	move.l	(Name+CU,NodeBase),d1			; eject. Men er det noen inne ?
	beq.b	9$					; nei ... Da dropper vi saken..
	move.w	#Error_OK,(m_Error,a0)
	move.w	#-1,(linesleft,NodeBase)		; Dropper all more saker ..
	lea	(throwouttext1),a0
	bsr	writetexti
	lea	(throwouttext2),a0
	bsr	writetexti
	move.b	#Thrownout,(readcharstatus,NodeBase)
9$	clrzn
	rts

; a0 = msg
reloaduser
	push	a2/a3
	move.l	a0,a2
	move.l	(UserrecordSize+CStr,MainBase),d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	move.l	d0,a3
	tst.l	d0				; ok ?
	beq.b	99$				; nei

	move.w	#Error_OK,(m_Error,a2)
	move.l	(Name+CU,NodeBase),d0		; Er det noen inne ?
	beq.b	9$				; nope
	move.l	(Usernr+CU,NodeBase),d0		; henter inn ny kopi
	cmp.l	(m_UserNr,a2),d0		; er det denne brukeren ??
	bne.b	9$				; nope

	move.l	a3,a0
	jsr	(loadusernr)
	move.w	d0,(m_Error,a2)			; gir feilmelding videre
	bne.b	9$

	move.l	a3,a0				; kopierer inn ny informasjon
	lea	(CU,NodeBase),a1
	move.l	#u_startsave,d0
	bsr	memcopylen
9$	move.l	a3,d0
	beq.b	99$			; ikke noe memory
	move.l	(UserrecordSize+CStr,MainBase),d0
	move.l	a3,a1
	jsrlib	FreeMem
99$	pop	a2/a3
	clrzn
	rts

shownode
	move.l	(windowadr,NodeBase),d0		; allerede åpent ?
	beq.b	3$				; nei, åpner.
	move.l	intbase,a6			; ja, får noden frem i lyset
	move.l	d0,a0
	jsrlib	WindowToFront
	move.l	(windowadr,NodeBase),a0
	move.l	(wd_WScreen,a0),a0
	jsrlib	ScreenToFront
	bra.b	8$

3$	bsr	openwindow			; vindu, menyer osv
	beq.b	1$
	bsr	openconsole			; åpner console
	beq.b	2$
	bsr	initconread
	move.l	(windowadr,NodeBase),a0
	move.l	(wd_WScreen,a0),a0
	move.l	(sc_RastPort+rp_BitMap,a0),a1
	lea	(ansiwhitetext),a0		; setter utskrift til hvitw
	move.b	(bm_Depth,a1),d0
	cmp.b	#2,d0
	bhi.b	4$
	lea	(ansiredtext),a0		; 2 farver, setter til farve #1
4$	bsr	writecontext
	move.b	(in_waitforcaller,NodeBase),d0	; er vi i waitforcaller ?
	beq.b	9$
	bsr	drawwaitforcallerscreen
	bra.b	9$

2$	bsr	closewindow
1$	move.l	intbase,a6
	suba.l	a0,a0
	jsrlib	DisplayBeep
8$	move.l	exebase,a6
9$	clrzn
	rts

hidenode
	bsr	closeconsole
	bsr	closewindow
	clrzn
	rts

doshutdownnode
	move.b	#1,(ShutdownNode,NodeBase)		; markerer at vi skal ned
	move.b	#Thrownout,(readcharstatus,NodeBase)	; virkelig..
	tst.b	(in_waitforcaller,NodeBase)		; er vi i waitforcaller ?
	notz
	bne.b	9$					; nope
	bset	#DoDivB_ExitWaitforCaller,(DoDiv,NodeBase)
	moveq.l	#9,d1
	clrzn
9$	rts

getregs	move.l	NodeBase,(m_Data,a0)
	move.l	MainBase,(m_arg,a0)
	clrz
	rts

local_showuser
	push	a6
	move.l	(Name+CU,NodeBase),d1			; eject. Men er det noen inne ?
	beq.b	9$					; nei ... Da dropper vi saken..
	move.l	(intbase),a6
	move.l	(showuserwindowadr,NodeBase),d0		; har vi vindu ?
	bne.b	1$					; jepp, da åpner vi ikke neste
	suba.l	a0,a0
	lea	(shouserwindowtags),a1
	jsrlib	OpenWindowTagList
	move.l	d0,(showuserwindowadr,NodeBase)		; Lagrer
	beq.b	9$					; klarte ikke åpne
	move.l	d0,a0
	move.l	(wd_UserPort,a0),a0
	moveq	#0,d1
	move.b	(MP_SIGBIT,a0),d1
	moveq.l	#0,d0
	bset	d1,d0
	move.l	d0,(showwinsigbit,NodeBase)
	or.l	d0,(waitbits,NodeBase)
1$	bsr	updateshowuserwindow
9$	clrz
	pop	a6
	rts

closeshowuserwindow
	push	a6
	move.l	(showuserwindowadr,NodeBase),d0		; har vi vindu ?
	beq.b	9$					; Nei, ferdig
	move.l	d0,a0
	move.l	(intbase),a6				; ja, lukker
	jsrlib	CloseWindow
	move.l	(showwinsigbit,NodeBase),d0
	not.l	d0
	and.l	d0,(waitbits,NodeBase)			; sletter bit'et
	moveq.l	#0,d0
	move.l	d0,(showwinsigbit,NodeBase)
	move.l	d0,(showuserwindowadr,NodeBase)
9$	pop	a6
	rts

updateshowuserwindow
	push	a2
	link.w	a3,#-30
	move.l	(showuserwindowadr,NodeBase),d0		; har vi vindu ?
	beq.b	9$					; Nei, skip
	move.l	(gfxbase),a6
	move.l	d0,a0
	move.l	(wd_RPort,a0),a2
	move.l	a2,a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	jsrlib	Move
	move.l	a2,a1
	jsrlib	ClearScreen
	move.l	(exebase),a6
	move.b	#1,(it_FrontPen,sp)
	move.b	#0,(it_BackPen,sp)
	move.b	#RP_JAM1,(it_DrawMode,sp)
	moveq.l	#0,d0
	move.l	d0,(it_LeftEdge,sp)			; tar it_TopEdge også.
	move.l	d0,(it_ITextFont,sp)
	move.l	d0,(it_NextText,sp)
	move.l	a0,(it_IText,sp)
	move.w	d0,(tmpword,NodeBase)
	move.l	sp,(ParamPass,NodeBase)
	lea	(CU,NodeBase),a2
	lea	(10$),a0
;	moveq.l	#0,d0					; ikke vis passord (d0 er allerede 0)
	jsr	(doshowuser)
9$	unlk	a3
	pop	a2
	rts

10$	push	a6/a3/d2/d3
	move.l	(intbase),a6
	move.l	(ParamPass,NodeBase),a1
	move.l	a0,(it_IText,a1)
	moveq.l	#1,d0
	moveq.l	#1,d1
	move.l	(showuserwindowadr,NodeBase),a0
	move.l	(wd_RPort,a0),a0
	move.w	(tmpword,NodeBase),d2
	add.w	d2,d1
	move.w	(rp_TxHeight,a0),d3
	add.w	d3,d2					; og øker
	move.w	d2,(tmpword,NodeBase)
	move.l	(showuserwindowadr,NodeBase),a3
	cmp.w	(wd_Height,a3),d2			; er vinduet stort nok ?
	bcs.b	11$					; ja
	push	a0/a1/d0/d1				; utvider vinduet
	move.l	a3,a0
	moveq.l	#0,d0
	move.w	d3,d1
	jsrlib	SizeWindow
	pop	a0/a1/d0/d1
11$	jsrlib	PrintIText
	clrz
	pop	a6/a3/d2/d3
	rts

nodemsgportjumps	dc.l	front_sleepser,front_dologin,front_droppcarrier,front_replyNOW
			dc.l	front_awakeser
;			dc.l	msg_writetext,msg_writetexto,msg_flushser,msg_writeserlen
;			dc.l	msg_readserlen,msg_quitlogin,msg_readser

privatenodemsgportjumps	dc.l	reloaduser,ejectuser,gotosleep,wakeupagain,shownode,shownode,shownode
			dc.l	hidenode,shownode,local_showuser,doshutdownnode,getregs
			dc.l	InitModem,ReleasePort,OffHook

; a0 = cmdline
doarexxcmd
;	push	all
;	bsr	writetexto
;	pop	all
	lea	(arexxcomtxt),a1
	moveq.l	#0,d0			; vi kaller parserexxcmd ifra noden
	bsr	parserexxcmd
	beq.b	1$			; ikke kjennt
	lea	(arexxjmp),a0		; utfører kommandoen
	adda.l	d0,a0
	move.l	(a0),a0
	jsr	(a0)			; utfører
	bra.b	9$
1$	moveq.l	#0,d0
	suba.l	a0,a0
	clrz
9$	rts

; a0 = cmdline
; a1 = cmdlist
; d0 = 1 : from main task, = 0, from node.
parserexxcmd
	push	a2/d2/d3/d4
	move.l	d0,d4			; husker hvor vi kommer ifra
	move.l	a0,a2
	moveq.l	#0,d2			; funksjon nr * 4
	moveq.l	#0,d3			; antall parametre
	move.l	a1,a0
1$	move.l	a2,a1
6$	move.b	(a1)+,d0		; neste bokstav i søke ord
	beq.b	2$			; alt passet, sjekker at de er like lange
	cmpi.b	#' ',d0
	beq.b	2$
	move.b	(a0)+,d1
	beq.b	9$			; ferdig, fant ikke
	cmpi.b	#',',d1			; ferdig med dette ordet
	beq.b	5$			; jepp, gikk ikke
	cmp.b	d0,d1
	bhi.b	9$			; mindre, ikke mulighet for andre
	beq.b	6$			; like, tester neste tegn

4$	move.b	(a0)+,d0		; spoler til neste ord
	beq.b	9$			; ikke en arexx commando
	cmpi.b	#',',d0			; spolt ferdig ?
	bne.b	4$			; nei
5$	addq.l	#4,d2			; øke antall ord
	bra.b	1$			; prøver neste ord

2$	lea	(tmplargestore,NodeBase),a2
	tst.l	d4
	beq.b	7$
	lea	(txtbuffer,MainBase),a2
7$	move.b	(a0)+,d1
	beq.b	3$			; funnet
	cmpi.b	#',',d1
	bne.b	4$			; ikke funnet, spoler til neste ord
3$	tst.b	d0			; noen parametre ?
	beq.b	8$			; nei, ferdig
	move.l	a1,a0
	bsr	10$

8$	move.l	d2,d0
	move.l	d3,d1			; antall parametre
	move.l	d1,(rx_NumParam,a2)
	clrz
	bra.b	99$
9$	setz
99$	pop	a2/d2/d3/d4
	rts

10$	moveq.l	#rx_ptr1,d1		; offset for å lagre adressen
	moveq.l	#0,d3			; antall parametre
11$	move.l	a0,(0,a2,d1.w)		; lagrer starten
	move.b	(a0)+,d0		; ferdig ?
	beq.b	19$			; jepp.
	addq.l	#1,d3			; vi har et parameter!! :-)
	addq.l	#4,d1			; oppdaterer offset
	cmpi.b	#'"',d0			; quote ?
	beq.b	12$			; jepp
	cmpi.b	#"'",d0			; quote ?
	beq.b	16$			; jepp
13$	move.b	(a0)+,d0		; ferdig ?
	beq.b	19$			; ja, helt
	cmpi.b	#' ',d0			; ferdig ?
	bne.b	13$			; nope.
	move.b	#0,(-1,a0)		; skiller
	bra.b	11$			; one more time

12$	move.l	a0,(-4,a2,d1.w)		; lagrer ny start
14$	move.b	(a0)+,d0		; ferdig ?
	beq.b	19$			; ja, helt
	cmpi.b	#'"',d0			; ferdig ?
	bne.b	14$			; nope.
	move.b	#0,(-1,a0)		; skiller
	bra.b	11$			; one more time

16$	move.l	a0,(-4,a2,d1.w)		; lagrer ny start
17$	move.b	(a0)+,d0		; ferdig ?
	beq.b	19$			; ja, helt
	cmpi.b	#"'",d0			; ferdig ?
	bne.b	17$			; nope.
	move.b	#0,(-1,a0)		; skiller
	bra.b	11$			; one more time
19$	rts

	IFND DEMO
; d0 - input tegn
; result : d0 - translated character
; Z = 1 - char supressed
translateserinchar
	cmpi.b	#31,d0
	bls	7$				; Controll tegn
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq.b	9$				; Yepp. no futher tranlation.
	moveq.l	#0,d1
	move.b	(Charset+CU,NodeBase),d1		; Henter inn brukerens tegnsett
	beq.b	9$				; ISO ?, jepp, ferdig.
	cmpi.b	#3,d1				; 7 bits ?
	bcs.b	1$				; nei
	cmpi.b	#12,d1				; MAC ?
	beq.b	4$
	cmpi.b	#128,d0				; 7 bits translation
	bcc	88$				; truncate'r alle tegn over 127

	cmpi.b	#27,(lastchar,NodeBase)		; var siste tegn esc ?
	bne.b	3$				; nei, alt som før
	cmpi.b	#'[',d0				; er det en ansi sekvens ?
	beq.b	9$				; jepp, da oversetter vi ikke
3$	move.b	d0,(lastchar,NodeBase)		; Lagrer siste tegnet
	lea	(fraISO7tilISO8),a0		; henter tabell
	subi.w	#3,d1				; justerer for starten
	mulu.w	#11,d1
	adda.l	d1,a0				; har nå riktig tabell
	moveq.l	#0,d1				; index
	cmpi.b	#'#',d0
	bcs.b	9$
	beq.b	2$
	addq.l	#1,d1
	cmpi.b	#'@',d0
	bcs.b	9$
	beq.b	2$
	lea	(transwhat7bitchar),a1
	andi.w	#$ff,d0
	move.w	d0,d1
	subi.b	#'[',d1
	bcs.b	9$
	move.b	(0,a1,d1.w),d1
	beq.b	9$
2$	move.b	(0,a0,d1.w),d0
9$	clrzn
	rts

4$	moveq.l	#3,d1				; jukser litt..
1$	cmpi.b	#128,d0				; std ASCII
	bcs.b	9$				; No translation. Std. ASCII
	andi.w	#$ff,d1				; Safety
	andi.w	#$ff,d0				; Safety
	subi.b	#128,d0				; Skip the 128 first std ASCII chars
	lsl.w	#2,d1
	lea	(convertxxxtoISO),a0		; Main translation table
	move.l	(0,a0,d1.w),a0			; Get users translation table
	move.b	(0,a0,d0.w),d0			; Use char-128 as an index into
	clrn					; the trans. table, to obtain new.
	rts					; ;Finished. Return Zero if no char

8$	move.w	#13,d0
7$	move.b	d0,(lastchar,NodeBase)		; Lagrer siste tegnet
	tst.b	(FSEditor,NodeBase)
	bne.b	9$
	cmpi.b	#8,d0				; Back space
	beq.b	9$
	cmpi.b	#9,d0				; TAB
	beq.b	9$
	cmpi.b	#24,d0				; ctrl-x
	beq.b	9$
	cmpi.b	#13,d0				; Carrige return
	beq.b	9$
	cmpi.b	#10,d0				; Line Feed, Converterer til CR
	beq.b	8$
88$	setz					; Controll code truncated.
	rts
	ENDC

; inputs : char (d0)
; adds outputlen to d1, updates a0.
translateseroutstring
;	tst.b	CommsPort+Nodemem(NodeBase)	; internal node ??
;	beq.b	9$			; Yepp. no tranlation.
	cmpi.b	#10,d0
	beq.b	7$			; LF
	push	d1/a0
	moveq.l	#0,d1
	move.b	(Charset+CU,NodeBase),d1	; Henter inn brukerens tegnsett
	beq.b	99$			; ISO ?, jepp, ferdig.
	cmpi.b	#3,d1			; 7 bits ?
	bcs.b	1$			; nei
	cmp.b	#12,d1			; MAC ?
	beq.b	1$			; jepp.
	cmpi.b	#128,d0			; 7 bits translation
	bcs.b	99$			; alle under 127 er ok
	lea	(fraISO8tilISO7),a0	; henter tabell
	subi.w	#3,d1			; justerer for starten
	mulu.w	#11,d1
	adda.l	d1,a0			; har nå riktig tabell
	moveq.l	#0,d1			; index
3$	cmp.b	(a0)+,d0
	beq.b	2$
	addq.l	#1,d1
	cmpi.b	#11,d1
	bcs.b	3$
	bra.b	66$			; ulovelig tegn over #128..
2$	lea	(fraISO7tilISO8),a0
	move.b	(0,a0,d1.w),d0
	bra.b	99$
4$	moveq.l	#3,d1			; jukser litt..
1$	cmpi.b	#128,d0			; std ASCII
	bcs.b	99$			; No translation. Std. ASCII
	andi.w	#$ff,d1			; Safety
	andi.w	#$ff,d0			; Safety
	subi.b	#128,d0			; Skip the 128 first std ASCII chars
	lsl.w	#2,d1
	lea	(convertISOtoxxx),a0	; Main translation table
	move.l	(0,a0,d1.w),a0		; Get users translation table
	move.b	(0,a0,d0.w),d0		; Use char-128 as an index into
	bne.b	99$			; the trans. table, to obtain new.
66$	pop	d1/a0
6$	setz
	rts				; ;Finished. Return Zero if imposible.
7$	move.b	#13,(a0)+
	move.b	d0,(a0)+
	addq.l	#2,d1
	rts
99$	pop	d1/a0
9$	move.b	d0,(a0)+
	addq.l	#1,d1
	rts

	IFND DEMO
; d0 = første tegnet i stringen. 0 hvis ingen.
; d1 = timout mellom hvert tegn
; returnerer d0 og Z. d0 = antall tegn lest, Z = 1 -> string full, timeout.
; OBS !! Gir blaffen i CD. (brukes bare i Waitforcaller, og i docheckGogR..)
; string, bryter ved timeout, return og newline
; word, bryter ved timeout, return og newline og space
serreadstring
	push	a2/d3/d2/d4
	moveq.l	#1,d4
	bra.b	serreadword1

serreadword
	push	a2/d3/d2/d4
	moveq.l	#0,d4
serreadword1
	lea	(tmptext,NodeBase),a2
	move.l	d1,d3
	tst.b	d0
	beq.b	4$
	move.b	d0,(a2)
	moveq.l	#1,d2
	bra.b	2$
4$	moveq.l	#0,d2			; antall tegn i stringen
2$	move.l	a2,a0
	adda.l	d2,a0
	moveq.l	#-1,d0
	move.l	d3,d1
	move.l	a0,-(sp)
	bsr	serreadt
	move.l	(sp)+,a0
	cmpi.b	#1,d0
	bne.b	3$
	move.b	(a0),d0
	cmpi.b	#13,d0
	beq.b	1$
	cmpi.b	#10,d0
	beq.b	1$
	tst.b	d4			; er det string ?
	bne.b	5$			; ja, da skal vi ikke bryte ved space
	cmpi.b	#' ',d0
	beq.b	1$
5$	addq.l	#1,d2
	cmpi.w	#80,d2
	bcs.b	2$
3$	move.b	#0,(a0)
	move.l	d2,d0
	setz
	bra.b	8$
1$	move.b	#0,(a0)
	move.l	d2,d0
8$	move.l	a2,a0
	pop	a2/d2/d3/d4
	rts

; a0 = buffer
; d0 = len, hvis negativ, glemm CD
; d1 = timeout. Hvis 0, les alle tegn som har kommet.
serreadt
	movem.l	d2/d3/d4/d5/a2,-(sp)
	moveq.l	#0,d4			; antall tegn lest
	move.l	a0,a2			; Buffer
	moveq.l	#0,d5			; Bruk CD
	move.l	d0,d2			; lengde vi skal lese
	bpl.b	7$
	neg.l	d2			; Negativ, gjør posetiv
	moveq.l	#1,d5			; Og husk at vi skal droppe CD test
7$	move.l	d1,d3			; timeout
	move.l	(sreadreq,NodeBase),a1		; Aborterer current read req.
	jsrlib	AbortIO
	move.l	(sreadreq,NodeBase),a1		; Venter på at den blir ferdig.
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	tst.l	(IO_ACTUAL,a1)
	beq.b	0$			; Io ikke ferdig.
	moveq.l	#0,d0			; Har behandlet denne.
	move.l	d0,(IO_ACTUAL,a1)
	move.b	(ser_tegn,NodeBase),(a2)+
	moveq.l	#1,d4
	subq.l	#1,d2
	bne.b	0$
	moveq.l	#1,d3
	bra	9$

0$	tst.l	d3			; Har vi timeout ?
	bne.b	1$
	moveq.l	#0,d3
	move.l	(sreadreq,NodeBase),a1		; Leser alle tegn i inn buffer
	move.w	#SDCMD_QUERY,(IO_COMMAND,a1)
	jsrlib	DoIO			; Sjekke flagg
	move.l	(sreadreq,NodeBase),a1
	IFND	nocarrier
	tst.l	d5
	bne.b	2$
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0	; Nullmodem ?
	bne.b	2$			; jepp, no CD checking.
	move.w	(IO_STATUS,a1),d1	; Henter serial.status
	btst	#5,d1			; Har vi CD ?
	beq.b	2$			; Ja, hopp
	move.b	#NoCarrier,(readcharstatus,NodeBase)
	bra	9$			; No carrier, Logoff !!
	ENDC
2$	move.l	(IO_ACTUAL,a1),d0
	beq	9$
	cmp.l	d0,d2
	bcc.b	3$
	move.l	d2,d0			; Vi har flere uleste bytes enn len.
3$	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a2,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	jsrlib	DoIO
	move.l	(sreadreq,NodeBase),a1
	move.l	(IO_ACTUAL,a1),d3
	add.l	d4,d3
	bra	9$

1$	move.l	(sreadreq,NodeBase),a1		; Setter igang ny request
	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a2,(IO_DATA,a1)
	move.l	d2,(IO_LENGTH,a1)
	jsrlib	SendIO
	move.l	d3,d0
	move.l	#1000000,d1
	bsr	divl
	move.l	(timer1req,NodeBase),a1
	move.l	d0,(TV_SECS+IOTV_TIME,a1)
	move.l	d1,(TV_MICRO+IOTV_TIME,a1)
	move.w	#TR_ADDREQUEST,(IO_COMMAND,a1)
	jsrlib	SendIO				; Starter timeout'en.
10$	move.l	(timer1sigbit,NodeBase),d0
	or.l	(sersigbit,NodeBase),d0
	jsrlib	Wait
	move.l	d0,d2
	and.l	(sersigbit,NodeBase),d0
	beq.b	4$
	move.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	4$
	move.l	(timer1req,NodeBase),a1
	bra.b	5$
4$	and.l	(timer1sigbit,NodeBase),d2
	beq.b	10$
	move.l	(timer1req,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	10$
	move.l	(sreadreq,NodeBase),a1
5$	jsrlib	AbortIO
	move.l	(timer1req,NodeBase),a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO

	move.l	(sreadreq,NodeBase),a1
	move.l	(IO_ACTUAL,a1),d3
	add.l	d4,d3
	tst.l	d5
	bne.b	9$
	move.w	#SDCMD_QUERY,(IO_COMMAND,a1)
	jsrlib	DoIO			; Sjekke flagg
	move.l	(sreadreq,NodeBase),a1
	IFND	nocarrier
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0	; Nullmodem ?
	bne.b	9$			; jepp, no CD checking.
	move.w	(IO_STATUS,a1),d1	; Henter serial.status
	btst	#5,d1			; Har vi CD ?
	beq.b	9$			; Ja, hopp
	move.b	#NoCarrier,(readcharstatus,NodeBase)
	moveq.l	#0,d3			; No carrier, Logoff !!
	ENDC
9$	bsr	initserread
	move.l	d3,d0
	movem.l	(sp)+,d2/d3/d4/d5/a2
	rts

; clear serial buffer
serclear
	move.l	(swritereq,NodeBase),a1		; get write structure
	jsrlib	WaitIO
	move.l	(swritereq,NodeBase),a1		; get write structure
	move.w	#CMD_CLEAR,(IO_COMMAND,a1)	; Flush'es serial buffers
	jmplib	DoIO
	ENDC

***************************************************************************
***			Virkelig Low level rutiner for skriving		***
***************************************************************************

	IFND DEMO

waitseroutput
	move.l	(swritereq,NodeBase),a1
	jmplib	WaitIO

serwritestringdo
	push	a0
	bsr.b	waitseroutput
	pop	a0
	bsr	serwritestring
	bra.b	waitseroutput

serwritestringlendo
	push	d0/a0
	bsr.b	waitseroutput
	pop	d0/a0
	bsr	serwritestringlen
	bra.b	waitseroutput

serwritestring
	move.l	a0,a1
	bsr	strlen
	move.l	a1,a0
serwritestringlen
	move.l	(swritereq,NodeBase),a1		; get write structure
	move.w	#CMD_WRITE,(IO_COMMAND,a1)	; stuff data
	move.l	a0,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	add.l	d0,(SerTotOut,NodeBase)
	jmplib	DoIO				; write to serial port.
	ENDC

writecontext
	move.l	a0,a1
	move.l	a0,d0
1$	tst.b	(a0)+
	bne.b	1$
	subq.l	#1,a0
	suba.l	d0,a0
	move.l	a0,d0
	move.l	a1,a0
writecontextlen
;	tst.b	Tinymode(NodeBase)		; Dette må man sjekke før dette..
	move.l	(cwritereq,NodeBase),d1		; get write structure
	beq.b	9$				; no console. Skip
	move.l	d1,a1
	move.w	#CMD_WRITE,(IO_COMMAND,a1)	; stuff data
	move.l	a0,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	jmplib	DoIO				; write to console device
9$	rts

newconline
	move.b	#10,d0
writeconchar
;	tst.b	Tinymode(NodeBase)		; Sjekkes før dette
;	move.w	d0,-(a7)
;	move.l	cwritereq(NodeBase),a1
;	jsrlib	WaitIO
;	move.w	(a7)+,d0

	move.l	(cwritereq,NodeBase),d1
	beq.b	9$				; no console
	move.l	d1,a1
	lea	(con_tegn,NodeBase),a0
	move.b	d0,(a0)
	moveq.l	#1,d0
	move.w	#CMD_WRITE,(IO_COMMAND,a1)
	move.l	a0,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
;	jmplib	SendIO
	jmplib	DoIO
9$	rts

*****************************************************************
*			Div rutiner				*
*****************************************************************

checktimeinbetweenlogins
	push	d2
	link.w	a3,#-30
	move.l	sp,d1
	move.l	(dosbase),a6
	jsrlib	DateStamp
	move.l	(exebase),a6
	lea	(LastAccess+CU,NodeBase),a0
	move.l	sp,a1
	bsr	calctime
	beq.b	9$				; feil, ut
	divu	#60,d0
	moveq.l	#0,d2
	move.w	d0,d2				; d2 = minutter i mellom
	move.l	(ds_Minute,sp),d0
	divu	#60,d0
	sub.w	#1,d0
	bcc.b	1$
	move.w	#23,d0
1$	lea	(HourMinWait+Nodemem,NodeBase),a0
	moveq.l	#0,d1
	move.b	(a0,d0.w),d1
	beq.b	9$				; ingen tid, ut
	cmp.l	d2,d1				; tid i mellom, min tid
	bcs.b	9$
	lea	(toclosetlsetext),a0
	bsr	writetexto
	setz
	bra.b	99$
9$	clrz
99$	unlk	a3
	pop	d2
	rts

; d0.w = confnr (* 2 !)
; ret : d0 = unread, d1 = til bruker
getconfunreadmsgs
	push	d2/d3/d4/d5/d6/a2/a3
	moveq.l	#0,d2				; nye meldinger
	moveq.l	#0,d3				; Til oss
	moveq.l	#0,d4
	move.w	d0,d4				; konferansen
	lea	(tmpmsgheader,NodeBase),a2
	lea	(u_almostendsave+CU,NodeBase),a3
	mulu	#Userconf_seizeof/2,d0
	add.l	d0,a3
	move.w	(uc_Access,a3),d1
	btst	#ACCB_Read,d1			; Er vi medlem her ?
	beq	2$				; Nei, hopp
	move.w	d4,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.l	(n_ConfDefaultMsg,a0,d0.l),d6
	move.l	(uc_LastRead,a3),d5
	sub.l	d5,d6
	bpl.b	1$
	moveq.l	#0,d6				; negativt. Feil ... rette opp.
1$	beq.b	2$

3$	addq.l	#1,d5				; sjekker alle nye meldinger
	subq.l	#1,d6
	bcs.b	2$				; Vi er ferdige
	move.w	d5,d0				; leser inn meldingsheader
	move.l	d4,d1
	move.l	a2,a0
	jsr	(loadmsgheader)
;	bne.b	5$
	move.l	a2,a0				; kan vi lese denne meldingen ?
	move.w	d4,d0				; henter frem conf nr
	jsr	(kanskrive)
	bne.b	3$				; nei ...
	addq.l	#1,d2				; øker antallet nye meldinger
	move.l	(Usernr+CU,NodeBase),d0		; er den til oss ?
	cmp.l	(MsgTo,a2),d0
	bne.b	3$				; nei
	addq.l	#1,d3				; øker antall meldinger til oss
	bra.b	3$

2$	move.l	d2,d0
	move.l	d3,d1
	pop	d2/d3/d4/d5/d6/a2/a3
	rts

fjernpath
	move.l	a0,a1
1$	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#':',d0
	beq.b	2$
	cmpi.b	#'/',d0
	bne.b	1$
2$	move.l	a0,a1			; Vi fant et path tegn, husker tegnet etter.
	bra.b	1$
9$	move.l	a1,a0
	rts

getextension
	move.l	a0,a1
1$	move.b	(a0)+,d0
	bne.b	1$			; finner slutten
2$	cmp.l	a0,a1
	move.b	-(a0),d0
	bcs.b	9$			; fant ingen, returnerer hele stringen
	cmp.b	#'.',d0
	bne.b	2$
	bra.b	99$
9$	move.l	a1,a0
99$	rts

;a0 - navn
;return - z = 1: navn har fodbudte tegn
checkillegalnamechar
	push	a2
	move.l	a0,a2
	move.b	#"`",d0
	bsr	strchr
	bne.b	1$
	move.l	a2,a0
	move.b	#'@',d0
	bsr	strchr
	beq.b	8$
1$	lea	(charnallowdtext),a0
	bsr	writeerroro
	clrz
8$	pop	a2
	notz
	rts

;a0 - sjekk navn
;return - z = 1: navn er i ban fil
checkfilebanfile
	push	a2/d2/d3/d4/d5/d6/a6
	link.w	a3,#-200
	move.l	a0,a2				; husker navnet
	moveq.l	#1,d5				; funnet status (dvs ikke funnet)

	move.l	(dosbase),a6
	move.l	#filebanfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4				; husker filptr
	notz
	bne.b	9$				; ingen fil, kan ikke sjekke

1$	move.l	d4,d1
	move.l	sp,d2
	moveq.l	#79,d3
	jsrlib	FGets
	tst.l	d0
	beq.b	2$
	move.l	d0,a0
	cmp.b	#';',(a0)			; komentar ?
	beq.b	1$				; ja, loop
	bsr	strlen
	beq.b	1$				; tom
	subq.l	#1,d0
	lea	(sp),a0
	add.l	d0,a0
	move.b	#0,(a0)				; fjerner cr

	move.l	sp,d1
	lea	(80,sp),a0
	move.l	a0,d2
	moveq.l	#200-80-2,d3
	jsrlib	ParsePatternNoCase
	moveq.l	#-1,d1
	cmp.l	d1,d0
	beq.b	1$				; error, prøver neste
	move.l	d0,d1

	lea	(80,sp),a0
	move.l	a0,d1
	move.l	a2,d2
	jsrlib	MatchPatternNoCase
	tst.l	d0
	beq.b	1$				; ingen match
; funnet

4$	moveq.l	#0,d5				; vi fant navnet
2$	move.l	d4,d1
	jsrlib	Close
6$	move.l	d5,d0
9$	unlk	a3
	pop	a2/d2/d3/d4/d5/d6/a6
	rts

;a0 - sjekk navn
;a1 - ban filenavn
;return - z = 1: navn er i ban fil
checkbanfile
	push	a2/d2/d3/d4/d5/d6/a6
	link.w	a3,#-80
	move.l	a0,a2
	move.l	a1,d3
	moveq.l	#1,d5				; funnet status (dvs ikke funnet)
	move.b	#' ',d0
	bsr	strchr
	move.l	d0,d6				; husker hvor spacen var i navnet
	notz
	bne	9$				; skulle være umulig, men ...
	move.l	(dosbase),a6
	move.l	d3,d1				; henter filnavnet
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	notz
	bne.b	9$				; ingen fil, kan ikke sjekke

1$	move.l	d4,d1
	move.l	sp,d2
	moveq.l	#79,d3
	jsrlib	FGets
	tst.l	d0
	beq.b	2$
	move.l	d0,a0
	cmp.b	#';',(a0)			; komentar ?
	beq.b	1$				; ja, loop
	bsr	strlen
	beq.b	1$				; tom
	subq.l	#1,d0
	lea	(sp),a0
	add.l	d0,a0
	move.b	#0,(a0)				; fjerner cr

	lea	(sp),a0				; er det space ?
	move.b	#' ',d0
	bsr	strchr
	lea	(sp),a0
	beq.b	3$				; nei
	move.l	a2,a1
	bsr	comparestringsicase
	bne.b	1$				; ikke lik
	bra.b	4$
3$	move.l	a2,a1
	move.l	d6,d0
	sub.l	a1,d0
	bsr	comparestringsifull
	beq.b	4$
	move.l	d6,a1
	lea	(1,a1),a1
	lea	(sp),a0
	bsr	comparestringsicase
	bne.b	1$				; ikke lik

4$	moveq.l	#0,d5				; vi fant navnet
2$	move.l	d4,d1
	jsrlib	Close
6$	move.l	d5,d0
9$	unlk	a3
	pop	a2/d2/d3/d4/d5/d6/a6
	rts

cleanupfiles
	jsr	(deletereadpointersfile)	; Sletter read pointers, safety
	lea	(maintmptext,NodeBase),a1	; sletter hold dir'en
	lea	(deletestring),a0		; Delete <holddir>/#? all force
	bsr	strcopy
	lea	(-1,a1),a0
	lea	(nulltext),a1
	jsr	getholddirfilename
	lea	(maintmptext,NodeBase),a0
1$	move.b	(a0)+,d0
	bne.b	1$				; finner slutten
	lea	(-1,a0),a1
	lea	(allforcestring),a0
	bsr	strcopy
	lea	(maintmptext,NodeBase),a0
	moveq.l	#0,d0				; ingen output
	jsr	(doexecutestring)
	rts

; d0 - nr updated
typenrupdated
	push	d2
	move.l	d0,d2
	move.b	#'<',d0
	bsr	writechar
	move.l	d2,d0
	bsr	skrivnr
	lea	usersupdatetext,a0
	bsr	writetext
	moveq.l	#1,d0
	cmp.l	d0,d2
	bne.b	1$
	move.b	#'s',d0
	bsr	writechar
1$	lea	(usersupdat2text),a0
	bsr	writetexto
	pop	d2
	rts

;d0 = access byte
;a0 = string to put text in
getaccbittext
	push	a0
	lea	(accessbitstext),a1
	moveq	#0,d1
1$	btst	d1,d0
	beq.b	2$
	move.b	(0,a1,d1.w),(a0)+
2$	addq.w	#1,d1
	cmpi.w	#7,d1
	bls.b	1$
	move.b	#0,(a0)
	pop	a0
	rts

checkreadptrs
	push	d2/a2

	IFD	NOMINBAUDCHECKNOW
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Lokal node ?
	beq.b	2$				; Ja, da er det ok.
	move.l	#300,d0
	cmp.l	(MinBaud+Nodemem,NodeBase),d0
	beq.b	2$
	lea	(25$),a0
	bsr	writetexto
	lea	(24$),a0
	bsr	writetexto
2$
	ENDC
0$	moveq.l	#0,d2
1$	move.l	d2,d0
	bsr	getnextconfnr
	move.l	d0,d2
	beq.b	9$			; ferdig
	lea	(u_almostendsave+CU,NodeBase),a0
	mulu	#Userconf_seizeof/2,d0
	add.l	d0,a0
	move.l	(uc_LastRead,a0),d1
	move.l	d2,d0

	lea	(n_FirstConference+CStr,MainBase),a1
	mulu	#ConferenceRecord_SIZEOF/2,d0
	add.l	d0,a1
	move.l	(n_ConfDefaultMsg,a1),d0
	cmp.l	d0,d1			; a >= b
	bls.b	1$			; denne er ok.
	move.l	d0,(uc_LastRead,a0)	; fixer.
	lea	(n_ConfName,a1),a2	; Har konferanse navnet.
	lea	(20$),a0
	bsr	writetext
	move.l	a2,a0
	bsr	writetexto
	lea	(21$),a0
	bsr	writetexto
	lea	(22$),a0
	bsr	writetexto
9$	pop	d2/a2
	rts

20$	dc.b	'Problems with conference : ',0
21$	dc.b	'(Last read is to high). Fixing now. Please tell sysop what you just did,',0
22$	dc.b	'so the problem can be corrected.',0
24$	dc.b	'Please tell the sysop what you just did,',0
	IFD	nominbaudcheckingnow
25$	dc.b	'Min baud was trashed (not 300)',0
	ENDC
	even

; a0 - text1
; a1 - text2
writetextformatted
	push	a2/d2
	moveq.l	#0,d2			; pos = 0
	move.l	a1,a2
	bsr	10$
	move.l	a2,a0
	bsr	10$
	bsr	outimage
	pop	a2/d2
	rts

10$	push	a2/d3/d4
	move.l	d2,d4			; husker initiell pos
	move.l	a0,a2			; husker starten
14$	moveq.l	#0,d3			; pos for siste komma
11$	move.b	(a0)+,d0
	beq.b	17$
	addq.l	#1,d2			; øker teller
	cmpi.b	#79,d2
	bcc.b	12$			; for mange tegn
	cmpi.b	#',',d0
	bne.b	11$
	move.l	d2,d3			; husker siste komma.
	bra.b	11$
12$	move.l	a2,a0
	sub.l	d4,d3			; trekker ifra initiell pos
	bcc.b	13$
	moveq.l	#79,d3			; skal egentlig ikke kunne skje, men ..
13$	move.l	d3,d0
	bsr	writetextlen
	bsr	outimage
	moveq.l	#0,d2			; pos = 0
	moveq.l	#0,d4			; dropper initiell pos
	lea	(0,a2,d3.w),a2
	move.l	a2,a0
	bra.b	14$
17$	move.l	a2,a0
	bsr	writetext
	pop	a2/d3/d4
	rts

checkscratchpad
	push	d2/a6
	move.l	(dosbase),a6
	jsr	(getscratchpadfname)		; har vi en scratchpad ?
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.b	8$				; nei, alt ok.
	jsrlib	UnLock
	move.l	(exebase),a6
	lea	(nottransscrtext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	beq	1$				; nei, eller noe galt
	moveq.l	#0,d2				; Retur verdi
	jsr	(sendscratch)
	beq.b	2$				; error, abort (restore)!
	moveq.l	#1,d2				; retur ok
	bra.b	7$

1$	move.b	(readcharstatus,NodeBase),d0	; Har det skjedd noe ?
	notz
	beq.b	9$				; ja
	moveq.l	#1,d2				; Retur verdi
	lea	(resetreaptrtext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	beq	7$				; nei, eller noe galt
	moveq.l	#1,d2				; retur ok
2$	jsr	(restorereadpointers)

7$	jsr	(getscratchpaddelfname)		; sletter scratchpad
	bsr	deletepattern
	jsr	(deletereadpointersfile)
	tst.l	d2
	beq.b	9$
8$	move.b	(readcharstatus,NodeBase),d0	; Har det skjedd noe ?
	notz
9$	pop	d2/a6
	rts

; d0 = message nr
; a0 = subject vi skal test mot
; retur : z = 0, ikke samme, n = error
samesubject
	push	a2/a3
	move.l	a0,a2
	lea	(tmpmsgheader,NodeBase),a3
	move.l	a3,a0
	move.w	(confnr,NodeBase),d1
	jsr	(loadmsgheader)
	lea	(errloadmsghtext),a0
	bne	8$
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	bsr	kanskrive			; Kan vi skrive ut denne ???
	notz
	beq	9$				; Nei. "Jump, for my love"
	move.l	a3,a0
	jsr	(isnetmessage)
	setn
	beq	9$				; ut

	lea	(Subject,a3),a0			; til uppercase
	bsr	upstring
	lea	(Subject,a3),a0
	bsr	removesubjectstart

1$	move.b	(a2)+,d0
	beq.b	2$
	cmp.b	(a0)+,d0
	beq.b	1$
	bra.b	9$				; ikke de samme

2$	move.b	(a0),d0
	cmpi.b	#'Y',d0				; fjerner include y'en
	bne.b	3$
	addq.l	#1,a0
3$	move.b	(a0),d0
	beq.b	9$				; ferdig, de var like
	cmpi.b	#' ',d0
	beq.b	3$				; gjerner space på slutten
	bra.b	9$				; noe annet etterpå. Ikke like

8$	bsr	writeerroro
	setn
9$	pop	a2/a3
	rts

; a0 : string med subject
; retur a0 : ny string start
removesubjectstart
1$	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#' ',d0			; skiper space i starten
	beq.b	1$

	lea	(sretext),a1
	bsr	10$
	bne.b	2$
	bra.b	1$			; har skipp'a 'Re:' Tar space, og en gang til

2$	lea	(ssubjecttext),a1
	bsr	10$
	beq.b	1$

9$	lea	(-1,a0),a0
	rts

10$	move.l	a0,-(a7)
	cmp.b	(a1)+,d0
	bne.b	18$
11$	move.b	(a1)+,d1
	beq.b	17$
	cmp.b	(a0)+,d1
	bne.b	18$
	bra.b	11$
17$	addq.l	#4,a7
	bra.b	19$
18$	move.l	(a7)+,a0
19$	rts

groupheaderscommon2
	move.b	#'<',d0
	bsr	writechar
	move.l	d4,d0
	bsr	skrivnr
	move.b	#'>',d0
	bsr	writechar
	lea	(newmsgfoundtext),a0
	bsr	writetexto
	rts

groupheaderscommon
	move.w	(confnr,NodeBase),d0
	jsr	(getfrommsgnr)
	beq.b	9$
	move.l	d0,d3
	move.l	d0,d1
	move.w	(confnr,NodeBase),d0
	jsr	(gettomsgnr)
	beq.b	9$
	move.l	d0,d2
	lea	(texttsearchtext),a0
	lea	(nulltext),a1
	moveq.l	#30,d0
	jsr	(mayedlinepromptfull)
	beq.b	9$
	move.l	a0,a2
	lea	(searchmsgtext),a0
	bsr	writetext
	move.w	d3,d0
	jsr	(skrivnrw)
	lea	(tonoansitext),a0
	bsr	writetext
	move.w	d2,d0
	jsr	(skrivnrw)
	lea	(fortext),a0
	bsr	writetext
	move.l	a2,a0
	bsr	writetext
	move.b	#'.',d0
	bsr	writechar
	bsr	outimage
9$	rts

; d0 = confnr (*2)
typeconfinfo
	move.w	d0,-(a7)
	lea	(maintmptext,NodeBase),a1
	lea	(conftextpath),a0
	bsr	strcopy
	subq.l	#1,a1
	move.w	(a7)+,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0
1$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	2$			; ferdig
	move.b	d0,(a1)+
	cmpi.b	#'/',d0
	bne.b	1$
	move.b	#' ',(-1,a1)
	bra.b	1$
2$	move.b	#0,(a1)+
	lea	(maintmptext,NodeBase),a0
	moveq.l	#0,d0				; ser og con
	bsr	typefilemaybeall
	rts

disposeansistuff
	move.l	a0,a1
1$	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#27,d0		; Ansi start ?
	bne.b	8$		; nei
	move.b	(a0),d1
	cmpi.b	#'[',d1		; Ansi start ?
	bne.b	8$		; nei
	addq.l	#1,a0
2$	move.b	(a0)+,d0	; Sletter alt frem til en bokstav
	beq.b	9$
	cmpi.b	#'A',d0
	bcs.b	2$
	cmpi.b	#'z',d0
	bhi.b	2$
	bra.b	1$
8$	move.b	d0,(a1)+
	bra.b	1$
9$	move.b	#0,(a1)
	rts

; Legger til ansihvit etter en ESC+[0..m
;a0 = in text (forandrer denne)
;d0 = max lengde
addansiwhite
	push	a2/a3
	move.l	a0,a3
	subq.l	#2,d0
	add.l	d0,a3			; har nå slutten
1$	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#27,d0			; ESC ?
	bne.b	1$
	move.b	(a0)+,d0
	beq.b	9$
	cmpi.b	#'[',d0			; [ ?
	bne.b	1$
	move.l	a0,a1

2$	move.b	(a1)+,d0
	beq.b	9$
	cmpi.b	#'A',d0			; venter paa en bokstav
	bcs.b	2$			; for liten
	cmpi.b	#'m',d0			; m ?
	beq.b	31$			; jepp.
	move.l	a1,a0			; har sjekket denne, fortsetter
	bra.b	1$

31$	move.b	(a0),d0
	cmpi.b	#'m',d0			; ESC[m ?
	beq.b	5$			; jepp

3$	move.b	(a0)+,d0
	cmpi.b	#'m',d0			; Er vi ferdige ?
	beq.b	1$			; jepp
	cmpi.b	#'0',d0			; 0 ?
	beq.b	5$			; jepp.

6$	move.b	(a0)+,d0		; looper til neste mulige spot
	cmpi.b	#'m',d0			; Er vi ferdige ?
	beq.b	1$			; jepp
	cmpi.b	#';',d0
	beq.b	3$
	bra.b	6$

5$	move.b	(a0)+,d0
	cmpi.b	#';',d0			; bare 0 ?
	beq.b	4$			; jepp
	cmpi.b	#'m',d0
	bne.b	3$			; nope
4$	lea	(-1,a0),a0
	move.l	a0,a2			; husker pos'en
	lea	(3,a0),a1		; gør plass
	bsr	strrcopy
	move.b	#0,(a3)			; terminerer, så vi ikke går for langt...
	move.l	a2,a0
	move.b	#';',(a0)+		; legger inn ;37
	move.b	#'3',(a0)+
	move.b	#'7',(a0)+
	bra.b	3$			; fortsetter

9$	pop	a2/a3
	rts

; fjerner ANSI farve meldinger a0 = in text (forandrer denne)
disposeansicolor
	push	a2/d2
	move.l	a0,a1			; setter opp dest (skriver oppaa)
1$	move.b	(a0)+,d0		; henter neste tegn
	beq	9$			; null = ferdig -> ut
	cmpi.b	#27,d0			; start paa ansi sekvens ?
	bne.b	2$			; nei
	cmpi.b	#'[',(a0)
	beq.b	4$			; ja! :-)
2$	move.b	d0,(a1)+		; ingen ansi sekvens, saa vi
	bra.b	1$			; bare kopierer over
4$	move.b	d0,(a1)+		; kopierer ut starten pa ANSI'n
	move.b	(a0)+,(a1)+
	move.l	a0,a2			; husker starten paa sekvensen
3$	move.b	(a0)+,d0		; soker etter slutten pa sekvensen
	beq.b	13$			; opps. slutt. kopierer, og ut
	cmpi.b	#'A',d0			; venter paa en bokstav
	bcs.b	3$			; for liten
	cmpi.b	#'z',d0
	bhi.b	3$			; for stor, dvs ikke noen bokstav
	cmpi.b	#'m',d0			; var det en farve komando ?
	bne.b	14$			; nei, da kopierer vi, og fortsetter
	moveq.l	#0,d2			; flagg. Fatt noe annet enn farver ?
	move.l	a2,a0			; henter tilbake starten
5$	move.b	(a0)+,d0
10$	cmpi.b	#'m',d0			; funnet m'en enda ?
	beq.b	8$			; ja, ut herfra
	cmpi.b	#'3',d0			; er det en farve komando ?
	beq.b	6$			; kanskje ...
	cmpi.b	#'4',d0			; (de er 3x eller 4x)
	bne.b	7$			; nei
6$	move.b	(a0),d1			; sjekker neste tegn
	subi.b	#'0',d1			; er det et siffer ?
	bcs.b	7$			; nei
	cmpi.b	#9,d1
	bhi.b	7$			; nei
	addq.l	#1,a0			; glemmer disse tegnene
	move.b	(a0)+,d0		; er det et semi kolon her ?
	cmpi.b	#';',d0
	bne.b	10$			; nei, da fortsetter vi
	bra.b	5$			; ja, vi glemmer tegnet
7$	moveq.l	#1,d2			; vi har fatt noe annet
	move.b	d0,(a1)+
	bra.b	5$
13$	move.b	(a2)+,(a1)+
	cmpa.l	a2,a0
	bhi.b	13$
	bra.b	9$
14$	move.b	(a2)+,(a1)+
	cmpa.l	a2,a0
	bhi.b	14$
	bra.b	1$
8$	cmpi.b	#';',(-1,a1)		; har vi en ';' før m'en ?
	bne.b	11$			; nei
	move.b	d0,(-1,a1)		; ja, da fjerner vi den
	bra.b	12$
11$	move.b	d0,(a1)+		; skriver ut m'en
12$	tst.b	d2			; fikk vi noe annet en farver ?
	bne	1$			; ja
	subq.l	#3,a1			; glemmer esc+[+m tegnene.
	bra	1$
9$	move.b	#0,(a1)
	pop	a2/d2
	rts
; a0 = datestamp
; retur:
; d0 = århundre (eg 1993)
; d1 = mnd
; d2 = mnddag
; d3 = ukedag
datestampetodate
	link.w	a2,#-CD_SIZE

	move.l	(ds_Days,a0),d0
	mulu.w	#60*60,d0
	move.l	(utibase),a6
	moveq.l	#24,d1
	jsrlib	UMult32
	move.l	sp,a0
	jsrlib	Amiga2Date
	move.l	sp,a0
	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.w	(year,a0),d0
	move.w	(month,a0),d1
	move.w	(mday,a0),d2
	move.w	(wday,a0),d3
	subi.w	#1,d3
	bcc.b	3$
	moveq.l	#6,d3
3$	move.l	(exebase),a6
	unlk	a2
	rts

; StrToDate
; inn     : d0 = år, d1 = mnd, d2 = dag.
; reultat : d0 = antall dager siden 1/1-1978
datetodays
	push	d4-d5

	move.l	(utibase),a6
	lea	(tmplargestore,NodeBase),a0

	move.b	d0,D5
	moveq	#78,D4	// Er vi over 78? Da lager vi 2000
	cmp.w	D4,D5	 // er d5 > d4???
	BCC.B	1$ // Hopper til 1900
	addi.w	#2000,d5
	bra.b	2$
1$	addi.w	#1900,D5	// Kun denne som var fra før...
2$	moveq	#00,D4
	move.w	D5,D0

	move.w	d0,(year,a0)
	move.w	d1,(month,a0)
	move.w	d2,(mday,a0)
	moveq.l	#0,d0
	move.w	d0,(hour,a0)
	move.w	d0,(min,a0)
	move.w	d0,(sec,a0)
	jsrlib	CheckDate
	tst.l	d0
	beq.b	29$
	move.l	#60*60*24,d1		; gjør om til dager
	jsrlib	UDivMod32
29$	move.l	(exebase),a6
	pop	d4-d5
	rts

	cnop	0,2

*****************************************************************
*			Setup rutiner				*
*****************************************************************

; a0 - errormelding
shownodeerror
	push	d0-d2/a0/a1/a2/a6/a3
	link.w	a3,#-20			; ess_SIZEOF
	move.l	a3,d2
	move.l	#20,(es_StructSize,sp)	; ess_SIZEOF
	moveq.l	#0,d0
	move.l	d0,(es_Flags,sp)
	move.l	#abbserrortext,(es_Title,sp)
	move.l	a0,(es_TextFormat,sp)
	move.l	#oktext,(es_GadgetFormat,sp)
	move.l	(intbase),a6
	sub.l	a0,a0
	move.l	sp,a1
	sub.l	a2,a2
	sub.l	a3,a3
	jsrlib	EasyRequestArgs
	move.l	d2,a3
9$	unlk	a3
	pop	d0-d2/a0/a1/a2/a6/a3
	rts

doallsetup
	suba.l	NodeBase,NodeBase		; vi har ikke noe nodebase enda
	bsr	setup				; skaffer minne ++
	beq	setup_error
	btst	#NodeSetupB_DontShow,(NodeSetup+Nodemem,NodeBase)
	bne.b	2$				; vi skal ikke vis noden ved oppstart
	bsr	shownode
2$	bsr	opentimer			; åpner timer
	beq.b	no_timer
	IFND DEMO
	move.b	#0,(RealCommsPort,NodeBase)	; clearer for sikkerhets skyld
	tst.b	(CommsPort+Nodemem,NodeBase)	; Skal denne noden være serial ?
	beq.b	1$				; nei
	bsr	openserial			; åpner serial
	beq.b	no_serial
	ENDC
1$	bsr	setupnode
	beq.b	setupnode_error
	bsr	cleanupfiles
	clrz					; temp
	rts

doallshutdown
	move.b	#'a',d0
	jsr	(writeconchar)
	clr.b	(NodeError,NodeBase)		; alt gikk bra
	bsr	shutdownnode
setupnode_error
	IFND DEMO
	cmpi.b	#-1,(RealCommsPort,NodeBase)	; vi hadde en, men.. rydder opp
	beq.b	1$
	tst.b	(CommsPort+Nodemem,NodeBase)	; er vi en ekstern node ?
	beq.b	no_serial			; nei
1$	move.b	#'q',d0
	bsr	writeconchar
	bsr	closeserial			; lukker serial
	ENDC
no_serial
	move.b	#'w',d0
	bsr	writeconchar
	bsr	closetimer			; lukker timer
no_timer
	move.b	#'e',d0
	bsr	writeconchar
	bsr	closeconsole			; lukker console

	IFEQ	sn-13
	move.l	(windowadr,NodeBase),d0
	beq.b	1$					; no window
	move.l	d0,a0
	lea	(consolename),a1
	moveq.l	#-1,d0
	move.l	d0,a2
	move.l	intbase,a6
	jsrlib	SetWindowTitles
	move.l	exebase,a6
1$
	ENDC

no_console
	bsr	closewindow			; lukker vindu
no_window
	moveq.l	#0,d0
	move.b	(NodeError,NodeBase),d0		; husker error status
	move.w	d0,-(sp)
	move.l	(msg,NodeBase),-(a7)
	bsr	closedown			; frigir minne +++
	move.l	(A7)+,a1
	move.w	(sp)+,d0			; henter frem status
	bra.b	setup_error1
setup_error
	suba.l	a1,a1
	jsrlib	FindTask
	move.l	nodelist+LH_HEAD,a0		; Finner vår nodenode
0$	move.l	(LN_SUCC,a0),d1
	beq.b	1$				; skal egentlig alltid ta denne, men..
	cmp.l	(NodeTask,a0),d0		; Vi har alltid satt inn vår task
	beq.b	1$				; adresse der.
	move.l	d1,a0
	bra.b	0$				; loop'e
1$	clr.w	(Nodenr,a0)			; Vi finnes ikke lenger
	lea	(Nodemsg,a0),a1			; henter frem meldingen
	moveq.l	#100,d0				; fatal error
setup_error1
	jsrlib	Forbid				; tar forbid resten av livet
	move.l	(mainmsgport),a0			; porten vi skal sende til
	move.w	d0,(m_Error,a1)			; legger ved feilnummeret
	move.w	#Main_shutdown,(m_Command,a1)
	move.l	(MN_REPLYPORT,a1),-(sp)		; husker reply port
	jsrlib	PutMsg				; sender melding
	move.l	(sp)+,d0			; henter fram replyport
	beq.b	3$				; det var ingen. To bad. Ut.
	move.l	d0,-(sp)			; husker en gang til
	move.l	d0,a0
	jsrlib	WaitPort			; venter på svar
	move.l	(sp)+,a0			; henter frem...
	jsrlib	GetMsg				; henter meldingen
3$	jsrlib	Permit
	setz					; returnerer error, i tifelle
	rts					; ;vi havnet her fra doallsetup

setup	move.l	(4,a5),d0		; tmp stacksize
	subi.l	#4*6,d0			; tmp fyller stack'en med en pattern
	lsr.l	#2,d0			; tmp deler på longword's
	move.l	a7,a0			; tmp
	move.l	#$12345678,d1		; tmp
1234$	move.l	d1,-(a0)		; tmp
	subq.l	#1,d0			; tmp
	bne.b	1234$			; tmp

	move.l	nodelist+LH_HEAD,d0
4$	move.l	d0,a0
	move.l	(LN_SUCC,a0),d0
	beq.b	41$			; siste, egentlig umulig, men ..
	move.l	(NodeTask,a0),d1	; er det vår ?
	bne.b	4$			; nei, sommer! :-)
41$	move.l	a0,a4			; husker nodenoden vår
	suba.l	a1,a1
	jsrlib	FindTask
	move.l	d0,(NodeTask,a4)	; lagrer vår adresse her.
	jsrlib	Permit			; nå kan andre noder starte

	lea	(NodeStatusText,a4),a0	; setter opp nodestatus teksten
	move.l	a0,(LN_NAME,a4)
	move.w	(Nodenr,a4),d0
	add.b	#'0',d0
	move.b	d0,(a0)

	move.l	#ramblocks_SIZE,d0
	move.l	(mainmemoryblock),a0
	add.l	(UserrecordSize+CStr,a0),d0
	add.l	(UserrecordSize+CStr,a0),d0
	moveq.l	#0,d1
	move.w	(Maxconferences+CStr,a0),d1
	lsl.l	#2,d1
	add.l	d1,d0			; plass til loginlastread
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocVec
	tst.l	d0
	bne.b	6$
	suba.l	a4,a4			; sletter igjen
	lea	(nomemoryerror),a0
	bsr	shownodeerror
	bra	1$
6$	move.l	a4,a0			; nodenoden
	move.l	d0,NodeBase
	move.l	a5,(nodestack,NodeBase)
	move.l	(mainmemoryblock),MainBase

	move.b	#100,(NodeError,NodeBase)
	lea	(3+infoblockmem,NodeBase),a1
	move.l	a1,d0
	andi.l	#$fffffffc,d0
	move.l	d0,(infoblock,NodeBase)

	move.w	(MaxLinesMessage+CStr,MainBase),d0
	mulu.w	#LinesSize,d0
	move.l	d0,(msgmemsize,NodeBase)

	lea	(CU,NodeBase),a1
	add.l	(UserrecordSize+CStr,MainBase),a1
	move.l	a1,(Tmpusermem,NodeBase)
	add.l	(UserrecordSize+CStr,MainBase),a1
	move.l	a1,(Loginlastread,NodeBase)

	move.l	a0,(nodenoden,NodeBase)
	move.w	(Nodenr,a0),(NodeNumber,NodeBase)
	lea	(Nodemsg,a0),a1
	move.l	a1,(msg,NodeBase)

	lea	(Nodenode_SIZEOF,a0),a1
	move.l	a1,(tmpmsgmem,NodeBase)

	movem.l	d2-d4,-(sp)
	move.l	(dosbase),a6
	move.l	a0,d4

	move.l	#abbsrootname,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	bne.b	61$
	lea	(noabbsdirerror),a0
	bsr	shownodeerror
	bra	21$

61$	jsrlib	CurrentDir
	move.l	d0,d1
	jsrlib	UnLock

	move.l	d4,a0
	move.l	(NodeTask,a0),a0
	move.l	(LN_NAME,a0),d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	63$
	move.l	d4,d1
	lea	(Nodemem,NodeBase),a0
	move.l	a0,d2
	move.l	#NodeRecord_SIZEOF,d3
	jsrlib	Read
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d2,d3
	beq.b	62$

63$	lea	(nodeconfigerror),a0
	bra	2$

62$	move.l	(exebase),a6
	jsr	checkforduplicatetmpdirs
	lea	(sametmpdirerror),a0
	beq	2$
	lea	(Nodetaskname,NodeBase),a1
	lea	(nodetaskname),a0
	move.w	(NodeNumber,NodeBase),d0
	bsr	fillinnodenr
	subq.l	#1,a1
	move.l	a1,(windowtitleptr,NodeBase)
	jsr	(updatewindowtitle)

	suba.l	a1,a1
	jsrlib	FindTask
	move.l	d0,a1
	lea	(Nodetaskname,NodeBase),a0
	move.l	a0,(LN_NAME,a1)
	move.l	(pr_CLI,a1),d0
	beq.b	65$
	lsl.l	#2,d0
	exg	d0,a0
	subq.l	#1,d0
	lsr.l	#2,d0
	move.l	(cli_CommandName,a0),(oldcliname,NodeBase)
	move.l	d0,(cli_CommandName,a0)
	lea	(Nodetaskname,NodeBase),a0
	bsr	strlen
	move.b	d0,(Nodetaskname_BCPL,NodeBase)
65$	move.l	NodeBase,(TC_Userdata,a1)
	moveq.l	#-1,d0
	move.l	d0,(pr_WindowPtr,a1)		; Fjerner alle requestere for noden
	move.l	(TC_TRAPCODE,a1),d0		; check current exception
	move.l	a1,-(a7)
	move.l	d0,a1
	jsrlib	TypeOfMem
	move.l	(a7)+,a1
	IFD	exceptionhandler
	tst.l	d0				; Er det null ? dvs ROM eller ingenting
	bne.b	5$				; somebody else (debugger?) has vector
	move.l	#Exception,(TC_TRAPCODE,a1)	; install pointers to code
	move.l	NodeBase,(TC_TRAPDATA,a1)	; ...and data
	ENDC

5$	move.l	(nodenoden,NodeBase),a0
	move.l	a1,(NodeTask,a0)
	moveq.l	#-1,d0
	move.l	d0,d2
	jsrlib	AllocSignal
	cmp.l	d2,d0
	bne.b	64$
	lea	(nosignalerror),a0
	bra	2$
64$	moveq.l	#1,d1
	lsl.l	d0,d1
	move.l	(nodenoden,NodeBase),a0
	move.l	d1,(InterMsgSig,a0)
	move.l	d1,(intersigbit,NodeBase)
	or.l	d1,(waitbits,NodeBase)
	move.b	d0,(intersigbitnr,NodeBase)

	suba.l	a0,a0				; ikke public name
	moveq.l	#0,d0
	bsr	CreatePort
	move.l	d0,(nodeport,NodeBase)
	beq	7$
	move.l	(msg,NodeBase),a1
	move.l	d0,(MN_REPLYPORT,a1)

	suba.l	a0,a0				; ikke public name
	moveq.l	#0,d0
	bsr	CreatePort
	move.l	d0,(rexxport,NodeBase)
	beq.b	8$
	move.l	d0,a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d0
	move.l	d0,(rexxsigbit,NodeBase)

	move.l	(dosbase),a6
	moveq.l	#DOS_EXALLCONTROL,d1
	moveq.l	#0,d2
	jsrlib	AllocDosObject
	move.l	(exebase),a6
	move.l	d0,(exallctrl,NodeBase)
	beq.b	32$
31$	clrz
3$	movem.l	(sp)+,d2-d4
1$	rts

32$	lea	(nomemoryerror),a0
	bsr	shownodeerror
	move.l	(rexxport,NodeBase),a0
	jsr	DeletePort
	bra.b	33$
8$	lea	(noporterror),a0
	bsr	shownodeerror
33$	move.l	(nodeport,NodeBase),a0
	jsr	DeletePort
	bra.b	81$
7$	lea	(noporterror),a0
2$	bsr	shownodeerror
81$	move.l	(dosbase),a6
	moveq.l	#0,d1
	jsrlib	CurrentDir
	move.l	d0,d1
	jsrlib	UnLock
21$	move.l	(exebase),a6
	move.l	NodeBase,a1
	jsrlib	FreeVec
	setz
	bra.b	3$

closedown
	move.l	NodeBase,d0			; Har vi satt opp noden ?
	beq	9$				; Nei, da er vi ferdige
	move.l	(nodenoden,NodeBase),d0
	beq.b	4$
	move.l	d0,a0				; Setter nodenr til 0 i kjeden.
	clr.w	(Nodenr,a0)			; dvs, vi finnes ikke lenger.
	bsr	(updatenodestatustext)
4$	move.l	(exallctrl,NodeBase),d0
	move.l	(dosbase),a6
	push	d2
	move.l	d0,d2				; frigir ExAllControl
	moveq.l	#DOS_EXALLCONTROL,d1
	jsrlib	FreeDosObject
	pop	d2
	move.l	(exebase),a6
6$	move.l	(rexxport,NodeBase),d0		; Har vi port ?
	beq.b	5$				; Nei.
	move.l	d0,a0
	jsr	DeletePort
5$	move.l	(nodeport,NodeBase),d0		; Har vi port ?
	beq.b	1$				; Nei.
	move.l	d0,a0
	jsr	DeletePort
	move.l	(msg,NodeBase),a1
	moveq.l	#0,d0				; sletter porten herfra
	move.l	d0,(MN_REPLYPORT,a1)
1$	moveq.l	#0,d0
	move.b	(intersigbitnr,NodeBase),d0
	beq.b	2$
	jsrlib	FreeSignal
2$	suba.l	a1,a1
	jsrlib	FindTask
	move.l	d0,a1
	move.l	(pr_CLI,a1),d0
	beq.b	21$
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	(oldcliname,NodeBase),(cli_CommandName,a0)
21$	move.l	(dosbase),a6
	moveq.l	#0,d1
	jsrlib	CurrentDir
	move.l	d0,d1
	beq.b	3$
	jsrlib	UnLock
3$	move.l	(exebase),a6
	suba.l	a1,a1
	exg	a1,NodeBase
	jmplib	FreeVec
9$	rts

openwindow
	link.w	a3,#-windowtagssize
	move.l	(windowadr,NodeBase),d0
	bne	9$				; allerede åpent
	btst	#NodeSetupB_UseABBScreen,(NodeSetup+Nodemem,NodeBase)
	beq.b	11$				; vi skal ikke ha abbs skjermen
	jsr	(askopenscreen)
11$	move.l	(intbase),a6

	moveq.l	#0,d0
	move.l	d0,(curprompt,NodeBase)		; sletter for sikkerhets skyld

	lea	(sp),a1
	lea	windowtags,a0
	move.l	#windowtagssize,d0
	bsr	memcopylen

	lea	(Nodetaskname,NodeBase),a1
	move.l	a1,(windowtitleoff,sp)
	moveq.l	#0,d0
	move.w	(win_big_width+Nodemem,NodeBase),d0
	move.l	d0,(windowwidthoff,sp)
	move.w	(win_big_height+Nodemem,NodeBase),d0
	move.l	d0,(windowheightoff,sp)

	move.w	(win_big_x+Nodemem,NodeBase),d0
	move.l	d0,(windowleftoff,sp)
	move.w	(win_big_y+Nodemem,NodeBase),d0
	move.l	d0,(windowtopoff,sp)

	move.b	(NodeSetup+Nodemem,NodeBase),d1
	btst	#NodeSetupB_TinyMode,d1
	beq.b	1$				; ikke tiny

	move.w	(windowleftoff+2,sp),firstzoom+0
	move.w	(windowtopoff+2,sp),firstzoom+2
	move.w	(windowwidthoff+2,sp),firstzoom+4
	move.w	(windowheightoff+2,sp),firstzoom+6

	move.w	#minwindowx,(windowwidthoff+2,sp)
	move.w	#minwindowy,(windowheightoff+2,sp)
	move.w	(win_tiny_x+Nodemem,NodeBase),d0
	move.l	d0,(windowleftoff,sp)
	move.w	(win_tiny_y+Nodemem,NodeBase),d0
	move.l	d0,(windowtopoff,sp)
	move.b	#1,(Tinymode,NodeBase)

1$	lea	(windowsizepos,NodeBase),a0
	moveq.l	#0,d0
	move.w	(4,a0),d0			; har vi lagret størrelse ? (henter wd_Width)
	beq.b	4$				; nei
	move.l	d0,(windowwidthoff,sp)		; ja, bruker tidligere
	move.w	(0,a0),d0
	move.l	d0,(windowleftoff,sp)
	move.w	(2,a0),d0
	move.l	d0,(windowtopoff,sp)
	move.w	(6,a0),d0
	move.l	d0,(windowheightoff,sp)
4$	moveq.l	#0,d0
	move.l	d0,(pubscreenadr,NodeBase)
	move.l	(mainscreenadr),d0
	btst	#NodeSetupB_UseABBScreen,(NodeSetup+Nodemem,NodeBase)
	bne.b	12$				; skal bruke abbs skjermen
	lea	(PublicScreenName+Nodemem,NodeBase),a0
	move.b	(a0),d0
	bne.b	15$				; vi har navn
	suba.l	a0,a0				; NULL ==  default public screen
15$	jsrlib	LockPubScreen
	move.l	d0,(pubscreenadr,NodeBase)
12$	move.l	d0,(windowpubscreenoff,sp)
	btst	#NodeSetupB_BackDrop,(NodeSetup+Nodemem,NodeBase)
	beq.b	14$				; vi skal ikke ha backdrop
	move.l	(windowflagsoff,sp),d1
	and.l	#~(WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_SIZEGADGET),d1
	or.l	#WFLG_BACKDROP|WFLG_BORDERLESS,d1
	move.l	d1,(windowflagsoff,sp)
	move.l	d0,a1
	move.w	(sc_Width,a1),(windowwidthoff+2,sp) ; Samme bredde som skjermen
	moveq.l	#0,d0
	move.l	d0,(windowleftoff,sp)
	move.b	(sc_BarHeight,a1),d0		; Justerer starten etter
	addq.l	#1,d0
	move.l	d0,(windowtopoff,sp)		; Høyden på skjermens titlebar
	moveq.l	#0,d1
	move.w	(sc_Height,a1),d1
	sub.l	d0,d1
	subq.l	#1,d1				; lager plass for å klikke på skjermen
	move.l	d1,(windowheightoff,sp)		; Og justerer høyden på vinduet
14$	suba.l	a0,a0
	move.l	sp,a1
	jsrlib	OpenWindowTagList
	move.l	d0,(windowadr,NodeBase)
	bne.b	2$
	lea	(nowindowerror),a0
	bsr	shownodeerror
	bra	9$
2$
	lea	(maintmptext,NodeBase),a0	; bruker denne som en textaddr structur
	lea	(Font+Nodemem,NodeBase),a1
	move.b	(a1),d0				; har vi en font ?
	beq.b	13$				; nei, dropper den
	move.l	a1,(ta_Name,a0)
	move.w	(FontSize+Nodemem,NodeBase),(ta_YSize,a0)
	move.b	#FS_NORMAL,(ta_Style,a0)
	move.b	#0,(ta_Flags,a0)
	move.l	(dfobase),a6
	jsrlib	OpenDiskFont
	move.l	(gfxbase),a6
	move.l	d0,(fontadr,NodeBase)
	beq.b	13$
	move.l	(windowadr,NodeBase),a0
	move.l	(wd_RPort,a0),a1
	move.l	d0,a0
	jsrlib	SetFont
13$	move.l	(intbase),a6

	bsr	setupmenu
	lea	(setupmenuerror),a0
	beq.b	5$
	move.l	(node_menu,NodeBase),a1
	move.l	(windowadr,NodeBase),a0
	jsrlib	SetMenuStrip
	tst.l	d0
	bne.b	7$
	bsr	freemenu
	lea	(nomenuerror),a0
5$	bsr	shownodeerror
	bra.b	8$

7$	move.b	(activesysopchat,NodeBase),d0
	beq.b	71$
	bsr	setsysopcheckmark
71$	move.l	(windowadr,NodeBase),a0
	move.l	(wd_UserPort,a0),a0
	moveq	#0,d1
	move.b	(MP_SIGBIT,a0),d1
	moveq.l	#0,d0
	bset	d1,d0
	move.l	d0,(intsigbit,NodeBase)
	or.l	d0,(waitbits,NodeBase)
	move.l	a0,(intmsgport,NodeBase)


	move.l	(aslbase),d0			; har vi asl ?
	beq.b	6$				; nope
	move.b	(Cflags+CStr,MainBase),d1		; Tillater vi ASL ?
	andi.b	#CflagsF_UseASL,d1
	bne.b	10$				; jepp
	move.l	d0,a1				; lukker asl.library igjen.
	move.l	(exebase),a6
	jsrlib	CloseLibrary
	moveq.l	#0,d0
	move.l	d0,(aslbase)			; slår av bruken
	bra.b	6$
10$	move.l	d0,a6
	moveq.l	#ASL_FileRequest,d0
	lea	(filereqtags),a0
	move.l	(windowadr,NodeBase),(4,a0)
	jsrlib	AllocAslRequest
	move.l	d0,(filereqadr,NodeBase)
6$	move.l	(exebase),a6
	clrz

9$	move.l	(exebase),a6
	unlk	a3
	rts
8$	move.l	(windowadr,NodeBase),a0
	jsrlib	CloseWindow
	moveq.l	#0,d0
	move.l	d0,(windowadr,NodeBase)
;	setz
	bra.b	9$

closewindow
	move.l	(showuserwindowadr,NodeBase),d0	; har vi user vindu ?
	beq.b	1$				; nei, går videre
	bsr	closeshowuserwindow		; ja, lukker
1$	move.l	(windowadr,NodeBase),d0
	beq.b	9$				; ikke noe vindu oppe, så det så!!
	move.l	(filereqadr,NodeBase),d0	; har vi fått requester ?
	beq.b	5$				; nope
	move.l	d0,a0
	move.l	(aslbase),a6			; vi har asl
	jsrlib	FreeAslRequest
5$	move.l	(intbase),a6
	move.l	(windowadr,NodeBase),a0
	jsrlib	ClearMenuStrip
	bsr	freemenu
	move.l	(windowadr,NodeBase),a0
	lea	(windowsizepos,NodeBase),a1
	move.l	(wd_LeftEdge,a0),(0,a1)		; tar wd_TopEdge også
	move.l	(wd_Width,a0),(4,a1)		; tar wd_Height også
	jsrlib	CloseWindow
	move.l	(pubscreenadr,NodeBase),d0
	beq.b	2$
	move.l	d0,a1
	suba.l	a0,a0
	jsrlib	UnlockPubScreen
2$	move.l	(fontadr,NodeBase),d0
	beq.b	3$
	move.l	(gfxbase),a6
	move.l	d0,a1
	jsrlib	CloseFont
3$	move.l	(exebase),a6
	jsr	(askclosescreen)
	moveq.l	#0,d0
	move.l	d0,(windowadr,NodeBase)
	move.l	(intsigbit,NodeBase),d0
	beq.b	9$				; ikke noe bit
	not.l	d0
	and.l	d0,(waitbits,NodeBase)		; fjerner window bit'et
	moveq.l	#0,d0
	move.l	d0,(intsigbit,NodeBase)		; her også
9$	rts

setupmenu
	push	a6
	move.l	(gadbase),a6
	move.l	(windowadr,NodeBase),a0
	move.l	(wd_WScreen,a0),a0
	suba.l	a1,a1
	jsrlib	GetVisualInfoA
	move.l	d0,(visualinfo,NodeBase)
	beq.b	9$
	lea.l	(Project0NewMenu0),a0
	lea	(createmenutags),a1
	move.b	(Cflags+CStr,MainBase),d1
	btst	#CflagsB_8Col,d1
	bne.b	1$
	move.l	#1,(4,a1)
1$	jsrlib	CreateMenusA
	move.l	d0,(node_menu,NodeBase)
	beq.b	freemenu2
	move.l	d0,a0
	push	a2
	lea	(MenuTags),a2
	move.l	(visualinfo,NodeBase),a1
	jsrlib	LayoutMenusA
	pop	a2
	tst.l	d0
	beq.b	freemenu1
9$	pop	a6
	rts

freemenu
	push	a6
	move.l	(gadbase),a6
freemenu1
	move.l	(node_menu,NodeBase),a0
	jsrlib	FreeMenus
freemenu2
	move.l	(visualinfo,NodeBase),a0
	jsrlib	FreeVisualInfo
	pop	a6
	setz
	rts

	IFND	GTMN_NewLookMenus
GTMN_NewLookMenus	EQU	GT_TagBase+67 ; ti_Data is boolean
	ENDC
MenuTags
;	DC.L    GTMN_NewLookMenus,1
	DC.L    TAG_DONE,0

createmenutags
	dc.l	GTMN_FrontPen,4
	dc.l    TAG_DONE,0

openconsole
	push	a2
	move.l	(cwritereq,NodeBase),d0
	bne	9$
	suba.l	a0,a0
	moveq.l	#0,d0
	bsr	CreatePort
	bne.b	2$
	lea	(noporterror),a0
	bsr	shownodeerror
	bra	no_cwport
2$	move.l	d0,a0
	move.l	d0,a2
	bsr	CreateStdIO
	bne.b	3$
	lea	(noioreqerror),a0
	bsr	shownodeerror
	bra	no_cwio
3$	move.l	d0,(cwritereq,NodeBase)

	suba.l	a0,a0
	moveq.l	#0,d0
	bsr	CreatePort
	bne.b	4$
	lea	(noporterror),a0
	bsr	shownodeerror
	bra	no_crport
4$	move.l	d0,a0
	move.l	d0,a2
	bsr	CreateStdIO
	bne.b	5$
	lea	(noioreqerror),a0
	bsr	shownodeerror
	bra	no_crio
5$	move.l	d0,(creadreq,NodeBase)

	move.l	(cwritereq,NodeBase),a1
	move.l	(windowadr,NodeBase),(IO_DATA,a1)
	move.l	#wd_Size,(IO_LENGTH,a1)
	lea	(consolename),a0
	moveq.l	#CONU_SNIPMAP,d0
	moveq.l	#0,d1
	jsrlib	OpenDevice
	tst.l	d0
	beq.b	6$
	lea	(nocondeverror),a0
	bsr	shownodeerror
	bra	no_cdev
6$	move.l	(cwritereq,NodeBase),a0
	move.l	(creadreq,NodeBase),a1
	move.l	(MN_REPLYPORT,a1),a2		; husker msgport'en
	moveq.l	#IOSTD_SIZE,d0
	bsr	memcopylen
	move.l	(creadreq,NodeBase),a1
	move.l	a2,(MN_REPLYPORT,a1)		; setter tilbake

	move.l	(MN_REPLYPORT,a1),a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,a0),d1
	bset	d1,d0
	move.l	d0,(consigbit,NodeBase)
	or.l	d0,(waitbits,NodeBase)
	move.l	(creadreq,NodeBase),a1			; kjører io'ene en gang
	move.w	#CMD_INVALID,(IO_COMMAND,a1)		; for å forhindre guru
	jsrlib	DoIO					; under closeconsole
	move.l	(cwritereq,NodeBase),a1
	move.w	#CMD_INVALID,(IO_COMMAND,a1)
	jsrlib	DoIO
	clrz
9$	pop	a2
	rts

closeconsole
	push	a2
	move.l	exebase,a6
	move.l	(cwritereq,NodeBase),d0			; er vi oppe ?
	beq	closeconret				; nei, allerede lukket
	move.l	(creadreq,NodeBase),d0
	beq.b	closeconret				; nei, allerede lukket
	move.l	d0,a1					; er det en read igang ?
	jsrlib	CheckIO
	tst.l	d0
	bne.b	1$					; nei
	move.l	(creadreq,NodeBase),a1			; Ja, tar og aborterer den
	jsrlib	AbortIO
1$	move.l	(creadreq,NodeBase),a1			; fjerner
	jsrlib	WaitIO
	move.l	(cwritereq,NodeBase),a1			; fjerner
	jsrlib	WaitIO

	IFEQ	sn-13
	move.l	#$fffff,d1
3$	move.w	#$fff,($dff180)
	subq.l	#1,d1
;	bne.b	3$
	ENDC

	move.l	(cwritereq,NodeBase),a1			; stenger
	jsrlib	CloseDevice
no_cdev	move.l	(creadreq,NodeBase),a0			; frigir
	move.l	(MN_REPLYPORT,a0),a2
	bsr	DeleteStdIO
no_crio	move.l	a2,a0
	jsr	DeletePort
no_crport
	move.l	(cwritereq,NodeBase),a0
	move.l	(MN_REPLYPORT,a0),a2
	bsr	DeleteStdIO
no_cwio	move.l	a2,a0
	jsr	DeletePort
no_cwport
	moveq.l	#0,d0
	move.l	d0,(cwritereq,NodeBase)			; husker at vi ikke har
	move.l	d0,(creadreq,NodeBase)			; husker at vi ikke har
	move.l	(consigbit,NodeBase),d0
	beq.b	closeconret
	not.l	d0
	and.l	d0,(waitbits,NodeBase)
closeconret
;	setz
	pop	a2
	rts

opentimer
	move.l	d2,-(a7)
	lea	(timername),a0
	suba.l	a1,a1				; ikke noe navn
	moveq.l	#UNIT_VBLANK,d0
	moveq.l	#0,d1
	moveq.l	#IOTV_SIZE,d2
	bsr	IOpenDevice
	bne.b	1$
	lea	(notimerdeverror),a0
	bsr	shownodeerror
	bra.b	8$
1$	move.l	a0,(timer1req,NodeBase)

	lea	(timername),a0
	suba.l	a1,a1				; ikke noe navn
	moveq.l	#UNIT_VBLANK,d0
	moveq.l	#0,d1
	moveq.l	#IOTV_SIZE,d2
	bsr	IOpenDevice
	bne.b	2$
	lea	(notimerdeverror),a0
	bsr	shownodeerror
	bra.b	9$
2$	move.l	a0,(timer2req,NodeBase)
	move.l	(a7)+,d2
	move.l	(timer1req,NodeBase),a1
	move.l	(MN_REPLYPORT,a1),a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d0
	move.l	d0,(timer1sigbit,NodeBase)
	move.l	(timer2req,NodeBase),a1
	move.l	(MN_REPLYPORT,a1),a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d0
	move.l	d0,(timer2sigbit,NodeBase)
	or.l	d0,(waitbits,NodeBase)
	rts

8$	move.l	(timer1req,NodeBase),a0
	bsr	ICloseDevice
9$	move.l	(a7)+,d2
	setz
	rts

closetimer
	move.l	(timer2req,NodeBase),a0
	bsr	ICloseDevice
	move.l	(timer1req,NodeBase),a0
	bra	ICloseDevice

	IFND DEMO
openserial
	suba.l	a0,a0
	moveq.l	#0,d0
	bsr	CreatePort
	bne.b	10$
	lea	(noporterror),a0
	bsr	shownodeerror
	bra	1$
10$	move.l	d0,a0
	move.l	a0,-(sp)
	moveq.l	#IOEXTSER_SIZE,d0
	bsr	CreateExtIO
	move.l	(sp)+,a1
	bne.b	12$
	lea	(noioreqerror),a0
	bsr	shownodeerror
	bra	2$
12$	move.l	d0,(swritereq,NodeBase)
	suba.l	a0,a0
	moveq.l	#0,d0
	bsr	CreatePort
	bne.b	11$
	lea	(noporterror),a0
	bsr	shownodeerror
	bra	3$
11$	move.l	d0,a0
	move.l	a0,-(sp)
	moveq.l	#IOEXTSER_SIZE,d0
	bsr	CreateExtIO
	move.l	(sp)+,a1
	bne.b	14$
	lea	(noioreqerror),a0
	bsr	shownodeerror
	bra	4$
14$	move.l	d0,(sreadreq,NodeBase)
	move.l	(sreadreq,NodeBase),a1
	lea	(Serialdevicename+Nodemem,NodeBase),a0
	moveq.l	#0,d0
	move.b	(CommsPort+Nodemem,NodeBase),d0
	move.b	d0,(RealCommsPort,NodeBase)
	subq.l	#1,d0

	move.w	(Setup+Nodemem,NodeBase),d1
	move.b	#0,(IO_SERFLAGS,a1)		; Null stiller.
;	btst	#SETUPB_XonXoff,d1		; Vi tillater ikke XonXoff lenger
;	bne.b	8$
	move.b	#SERF_XDISABLED|SERF_RAD_BOOGIE|SERF_SHARED,(IO_SERFLAGS,a1)
8$	btst	#SETUPB_RTSCTS,d1
	beq.b	9$
	ori.b	#SERF_7WIRE,(IO_SERFLAGS,a1)
9$	moveq.l	#0,d1
	jsrlib	OpenDevice
	tst.l	d0

	beq.b	15$
	lea	(noserdeverror),a0
	bsr	shownodeerror
	bra	5$
15$	bsr	setserparam
	beq.b	16$
	lea	noserparamerro1,a0
	jsr	(konverterw)
	lea	(noserparamerror),a0
	bsr	shownodeerror
	bra	7$
16$	move.l	(sreadreq,NodeBase),a1
	move.w	#CMD_CLEAR,(IO_COMMAND,a1)	; flush'er bufferen
	jsrlib	DoIO
	move.l	(MN_REPLYPORT,a1),a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d0
	move.l	d0,(sersigbit,NodeBase)
	or.l	d0,(waitbits,NodeBase)
	move.l	(swritereq,NodeBase),a2
	move.l	(MN_REPLYPORT,a2),d1
	moveq.l	#IOEXTSER_SIZE/4,d0
6$	move.l	(a1)+,(a2)+
	dbf	d0,6$
	move.l	(swritereq,NodeBase),a2
	move.l	d1,(MN_REPLYPORT,a2)
	clrz
	rts

7$	move.l	(sreadreq,NodeBase),a1
	jsrlib	CloseDevice
5$	move.l	(sreadreq,NodeBase),a0
	move.l	(MN_REPLYPORT,a0),a2
	bsr	DeleteExtIO
	move.l	a2,a0
4$	jsr	DeletePort
3$	move.l	(swritereq,NodeBase),a0
	move.l	(MN_REPLYPORT,a0),a2
	bsr	DeleteExtIO
	move.l	a2,a0
2$	jsr	DeletePort
1$	setz
	rts

closeserial
	move.l	a2,-(sp)
	move.l	(swritereq,NodeBase),a2
	cmpi.b	#-1,(RealCommsPort,NodeBase)
	beq.b	1$
	move.l	(sreadreq,NodeBase),a1
	move.l	(IO_DEVICE,a1),d0
	beq.b	1$				; ikke noe device..
	move.l	a2,a1
	jsrlib	AbortIO
	move.l	a2,a1
	jsrlib	WaitIO
	move.l	(sreadreq,NodeBase),a1
	move.l	a1,a2
	jsrlib	AbortIO
	move.l	a2,a1
	jsrlib	WaitIO
	move.l	a2,a1
	jsrlib	CloseDevice
1$	move.l	(sreadreq,NodeBase),a2
	move.l	(MN_REPLYPORT,a2),a0
	jsr	DeletePort
	move.l	a2,a0
	bsr	DeleteExtIO
	move.l	(swritereq,NodeBase),a2
	move.l	(MN_REPLYPORT,a2),a0
	jsr	DeletePort
	move.l	a2,a0
	bsr	DeleteExtIO
	move.l	(sp)+,a2
	rts
	ENDC

setupnode
	lea	(logfilename,NodeBase),a1
	lea	(logfilenameo),a0
	move.w	(NodeNumber,NodeBase),d0
	bsr	fillinnodenr

	move.l	(dosbase),a6			; sørger for at vi har en
	lea	(TmpPath+Nodemem,NodeBase),a1	; node dir
	move.l	a1,d1
	push	d2
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	pop	d2
	move.l	d0,d1
	bne.b	2$
	lea	(TmpPath+Nodemem,NodeBase),a1
	move.l	a1,d1
	jsrlib	CreateDir
	move.l	d0,d1
	bne.b	2$
	lea	(notmpdirerror),a0
	bsr	shownodeerror
	bra.b	9$
2$	jsrlib	UnLock

3$	move.l	(exebase),a6
	lea	(Publicportname,NodeBase),a1
	lea	(publicportname),a0
	move.w	(NodeNumber,NodeBase),d0
	bsr	fillinnodenr
	lea	(Publicportname,NodeBase),a0
	moveq.l	#0,d0
	bsr	CreatePort
	move.l	d0,(nodepublicport,NodeBase)
	bne.b	4$
	lea	(noporterror),a0
	bsr	shownodeerror
	bra.b	9$

4$	move.l	d0,a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d0
	move.l	d0,(publicsigbit,NodeBase)
	or.l	d0,(waitbits,NodeBase)

	move.l	(msg,NodeBase),a1
	move.w	#Main_startnode,(m_Command,a1)
	move.w	#Error_OK,(m_Error,a1)
	jsr	(handlemsg)
	clrz
	lea	(startupmsgtext),a0		; Skriver i log'en at vi er oppe
	bsr	writelogstartup
	clrz
9$	move.l	(exebase),a6
	rts

shutdownnode
	move.l	(nodepublicport,NodeBase),a0
	jsr	DeletePort
	move.l	(dosbase),a6
	lea	(TmpPath+Nodemem,NodeBase),a1	; Sletter nodedir'en
	move.l	a1,d1
	push	d2
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	pop	d2
	move.l	d0,d1
	beq.b	1$
	push	d1
;	bsr	deleteall			; friker ut. Sletter ting i ABBS: (tror jeg)
	pop	d1
	jsrlib	UnLock
1$	lea	(TmpPath+Nodemem,NodeBase),a1
	move.l	a1,d1
	jsrlib	DeleteFile
	move.l	(exebase),a6

	move.l	(nodestack,NodeBase),a0		; tmp
	move.l	#$12345678,d1			; tmp
	moveq.l	#0,d0				; tmp
2$	addq.l	#4,d0				; tmp
	cmp.l	-(a0),d1			; tmp
	bne.b	2$				; tmp
	lea	(maintmptext,NodeBase),a0	; tmp
	bsr	konverter			; tmp
	lea	(maintmptext,NodeBase),a1	; tmp
	lea	(3$),a0				; tmp
	bsr	writelogtexttimed		; tmp

	lea	(shutdownsgtext),a0
	bra	writelogstartup

3$	dc.b	'stack used:',0			; tmp
	cnop	0,4				; tmp

;*****************************************************************************
; Line editor.
;*****************************************************************************

;a0 = msgheader
;a1 = buffer
;d0 = max size
editor	push	d2/d3/d4/d5/a2/a3
	move.l	a0,a3
	move.l	a1,a2			; Buffer
	move.l	d0,d5			; husker mak size
	divu	#80,d5			; gjør om til max linje nr
	bsr	outimage
	moveq.l	#0,d4			; msglen (in bytes)
	moveq.l	#1,d2			; Linenr
0$	cmp.w	d5,d2
	bcc	6$			; Vi er på siste linje. To bad.
	bsr	outimage		; Tegner border
	lea	(spacetext),a0
	moveq.l	#3,d0
	bsr	writetextlen
	lea	(bordertext),a0
	moveq.l	#73,d0
	bsr	writetextlen
	move.b	#'>',d0
	bsr	writechar
	bsr	outimage
1$	move.l	d2,d0			; Skriver <linenr>:
	divu	#100,d0
	clr.w	d0
	swap	d0
	bsr	skrivminst2nr
	move.b	#':',d0
	bsr	writechar
	bsr	breakoutimage
	moveq.l	#0,d3			; Charpos (in line)
2$	bsr	readchar		; må tåle CTRL-X. FIX ME
	bmi.b	2$
	bne.b	7$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	99$
7$	cmpi.b	#13,d0			; Return
	beq	31$
	cmpi.b	#10,d0			; Return
	beq	31$
	cmpi.b	#8,d0			; Del
	beq	41$
	cmpi.b	#9,d0			; Tab
	beq	51$
	cmpi.b	#72,d3			; Word-wrap ?
	bls	21$			; Nei, hopp

	cmp.w	d5,d2
	bcc	6$			; Vi er på siste linje. To bad.
	move.w	d0,-(sp)		; husk tegnet
	lea	(0,a2,d4.w),a0		; ptr til slutten av buffer
	move.b	#0,(a0)			; en eot for sikkerhetsskyld
	subq.l	#1,a0
	moveq.l	#71,d0			; scanner siste linje
3$	cmpi.b	#' ',-(a0)		; Etter siste space'et
	dbeq	d0,3$			; Looper til funnet, eller eol.
	beq.b	4$			; Jepp, vi fant et space. Hopp.
	move.b	#10,(0,a2,d4.w)		; Legger til NL
	addq.l	#1,d4
	addq.l	#1,d2			; Neste linje
	bsr	outimage
	move.l	d2,d0			; Skriver <linenr>:
	divu	#100,d0
	clr.w	d0
	swap	d0
	bsr	skrivminst2nr
	move.b	#':',d0
	bsr	writechar
	bsr	breakoutimage
	moveq.l	#0,d3
	bra.b	5$			; Fortsett på ny linje
4$	move.b	#10,(a0)		; Slenger inn en newline der.
	addq.l	#1,a0			; Hvor mange tegn skal flyttes ??
	neg.w	d0
	addi.w	#72,d0
	ext.l	d0			; Svaret i d0.
	bpl.b	22$			; Sikrer at vi ikke får noe negativt.
	moveq.l	#0,d0
22$	movem.l	d0/a0,-(sp)
	move.l	d0,d3
	beq.b	23$			; Ikkenoe å slette. Hopp
	lea	(deletetext),a0		; Flytter cursor til venstre
	bsr	writetextleni
	move.l	d3,d0
	lea	(spacetext),a0		; Sletter tegn (skriver space oppå)
	bsr	writetextleni
23$	addq.l	#1,d2			; Ny linje
	bsr	outimage
	move.l	d2,d0			; Skriver <linenr>:
	bsr	skriv2nr
	move.b	#':',d0
	bsr	writechar
	movem.l	(sp)+,d0/a0		; skriver det som skal på neste linje
	bsr	writetextlen
	bsr	breakoutimage
5$	move.w	(sp)+,d0		; Og tegnet var ...

21$	move.b	d0,(0,a2,d4.w)		; inn i bufferet
	addq.l	#1,d4			; øke bufferptr
	addq.l	#1,d3			; øker antall tegn på denne linja
	bsr	writechari		; echo
	bra	2$			; les neste tegn

31$	tst.l	d3			; Return (egentlig lf)
	beq.b	6$			; return på tom linje => end
	move.b	#10,(0,a2,d4.w)		; inn i buffer
	addq.l	#1,d4			; ptr
	moveq.l	#0,d3
	addq.l	#1,d2
	bsr	outimage			; ny linje
	bra	1$			; skriv ut linjenr ..

41$	tst.l	d3			; Del
	beq.b	49$			; ikke noe å slette.
	lea	(deltext),a0		; sletter et tegn
	moveq.l	#3,d0
	bsr	writetextleni
	subq.l	#1,d4			; fra bufferet også
	subq.l	#1,d3
49$	bra	2$

51$	;addq.l	#8,d3			; tab. Kva gjer me ??
	bra	2$			; truncate ??

6$	clr.b	(1,a2,d4.w)
	move.w	d2,(NrLines,a3)
	move.w	d4,(NrBytes,a3)
	lea	(editorchoicetxt),a0
	bsr	writetexti
	moveq.l	#1,d0
	bsr	getline
	bne	87$
	tst.b	(readcharstatus,NodeBase)
	notz
	bra	9$
87$	move.b	(a0),d0
	bsr	upchar
	cmpi.b	#'S',d0
	beq	9$
	cmpi.b	#'A',d0
	beq	8$
	cmpi.b	#'C',d0
	beq	0$
	cmpi.b	#'P',d0
	beq	10$
	cmpi.b	#'U',d0
	beq	12$
	cmpi.b	#'L',d0
	bne.b	6$
	bsr	dubbelnewline
	bsr	breakoutimage
	move.l	a3,a0
	move.w	(confnr,NodeBase),d0
	suba.l	a1,a1				; ingen netnavn her...
	bsr	typemsgheader
	bsr	outimage
	move.l	a2,a0
	move.l	d4,d0
	beq.b	6$
	moveq.l	#0,d1
	bsr	writetextmemi
	beq	99$
	bra	6$
10$	move.l	(MsgTo,a3),d0
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	15$
	move.w	(confnr,NodeBase),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.w	(n_ConfSW,a0,d0.l),d0
	andi.w	#CONFSWF_PostBox+CONFSWF_Private,d0
	bne.b	11$
15$	lea	(msgcantprivatxt),a0
	bsr	writetexti
	bra	6$
11$	move.b	#SECF_SecReceiver,(Security,a3)
	lea	(msgmadprivattxt),a0
	bsr	writetexti
	bra	6$
12$	move.w	(confnr,NodeBase),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.w	(n_ConfSW,a0,d0.l),d0
	btst	#CONFSWB_PostBox,d0
	beq.b	13$
	lea	(msgcantpublicxt),a0
	bsr	writetexti
	bra	6$
13$	move.b	#SECF_SecNone,(Security,a3)
	lea	(msgmadpublictxt),a0
	bsr	writetexti
	bra	6$
; Mangler edit !

8$	lea	(shuabortmsgtext),a0
	suba.l	a1,a1
	moveq.l	#1,d0				; y er default
	bsr	getyorn
	beq	6$
99$	moveq.l	#0,d4
9$	bsr	outimage
	subq.w	#1,(NrLines,a3)			; fjerner den siste linja
	move.l	a2,a0
	move.l	d4,d0
	beq.b	19$
	subq.l	#1,d0
	move.w	d0,(NrBytes,a3)
19$	pop	d2/d3/d4/d5/a2/a3
	rts


*******************************************************************************
*******************************************************************************
* * * * * * * * * * * * * * Kode for Noden(e) slutt * * * * * * * * * * * * * *
*******************************************************************************
*******************************************************************************

*****************************************************************
*			div smårutiner				*
*****************************************************************

******************************
;svar:rest = divl a/b
;d0   d1	   d0 d0
;Does a 32 bit div. Perhaps signed.
******************************
divl	tst.l	d0
	bpl.b	1$
	neg.l	d0
	tst.l	d1
	bpl.b	2$
	neg.l	d1
	bsr.b	3$
	neg.l	d1
	rts
2$	bsr.b	3$
	neg.l	d0
	neg.l	d1
	rts
1$	tst.l	d1
	bpl.b	3$
	neg.l	d1
	bsr.b	3$
	neg.l	d0
	rts
3$	move.l	d2,-(sp)
	swap	d1
	move.w	d1,d2
	bne.b	8$
	swap	d0
	swap	d1
	swap	d2
	move.w	d0,d2
	beq.b	9$
	divu.w	d1,d2
	move.w	d2,d0
9$	swap	d0
	move.w	d0,d2
	divu.w	d1,d2
	move.w	d2,d0
	swap	d2
	move.w	d2,d1
	move.l	(sp)+,d2
	rts
8$	move.l	d3,-(sp)
	moveq	#$10,d3
	cmpi.w	#$80,d1
	bcc.b	10$
	rol.l	#8,d1
	subq.w	#8,d3
10$	cmpi.w	#$800,d1
	bcc.b	4$
	rol.l	#4,d1
	subq.w	#4,d3
4$	cmpi.w	#$2000,d1
	bcc.b	5$
	rol.l	#2,d1
	subq.w	#2,d3
5$	tst.w	d1
	bmi.b	6$
	rol.l	#1,d1
	subq.w	#1,d3
6$	move.w	d0,d2
	lsr.l	d3,d0
	swap	d2
	clr.w	d2
	lsr.l	d3,d2
	swap	d3
	divu.w	d1,d0
	move.w	d0,d3
	move.w	d2,d0
	move.w	d3,d2
	swap	d1
	mulu.w	d1,d2
	sub.l	d2,d0
	bcc.b	7$
	subq.w	#1,d3
	add.l	d1,d0
;	bcc.b	*
7$	moveq	#0,d1
	move.w	d3,d1
	swap	d3
	rol.l	d3,d0
	swap	d0
	exg	d0,d1
	move.l	(sp)+,d3
	move.l	(sp)+,d2
	rts


;a0 devnavn
;a1 portnavn
;d0 = unitnum
;d1 = flagg
;d2 = sizeof iostruct
IOpenDevice
	movem.l	a0/d0/d1,-(a7)
	moveq.l	#0,d0
	move.l	a1,a0
	bsr	CreatePort
	beq.b	99$
	move.l	d0,a0
	move.l	d2,d0
	move.l	a0,-(a7)
	bsr	CreateExtIO
	move.l	(a7)+,a0
	beq.b	98$
	move.l	d0,a1
	movem.l	(a7)+,a0/d0/d1
	move.l	a1,-(a7)
	jsrlib	OpenDevice
	move.l	(a7)+,a0
	tst.l	d0
	beq.b	9$
	move.l	(MN_REPLYPORT,a0),-(a7)
	bsr	DeleteExtIO
	move.l	(a7)+,a0
	jsr	DeletePort
	bra.b	97$
98$	jsr	DeletePort
99$	lea	(12,a7),a7
97$	clrz
9$	notz
	rts

ICloseDevice
	move.l	a0,a1
	move.l	a1,-(a7)
	jsrlib	CloseDevice
	move.l	(a7)+,a0
	move.l	(MN_REPLYPORT,a0),-(a7)
	bsr	DeleteExtIO
	move.l	(a7)+,a0
	jsr	DeletePort
	rts

******************************
;CreatePort
;inputs : name,priority (a0,d0) (hvis name er null, så blir det en privat port)
;outputs: msgport (d0)
******************************
CreatePort
	push	a2/d2
	move.l	a0,a2
	move.l	d0,d2
	jsrlib	CreateMsgPort
	tst.l	d0
	beq.b	9$
	move.l	d0,a1
	move.b	d2,(LN_PRI,a1)
	move.l	a2,(LN_NAME,a1)		; Navn (skal den addes til portlista) ?
	beq.b	1$			; nei
	move.l	a1,a2
	jsrlib	AddPort
	move.l	a2,a1
1$	move.l	a1,d0
9$	pop	a2/d2
	rts

******************************
;DeletePort
;inputs : msgport (a0)
;outputs: none
******************************
DeletePort
	move.l	a2,-(a7)
	move.l	a0,a2
	jsrlib	Forbid
	move.l	(LN_NAME,a2),d0		; Er den add'a ?
	beq.b	1$			; nei.
	move.l	a2,a1
	jsrlib	RemPort
1$	move.l	a2,a0
	jsrlib	GetMsg
	tst.l	d0
	beq.b	2$
	move.l	d0,a1
	tst.l	(MN_REPLYPORT,a1)		; har vi reply port ?
	beq.b	1$				; nope
	jsrlib	ReplyMsg
	bra.b	1$	; 3$
3$	moveq.l	#ABBSmsg_SIZE,d0
	jsrlib	FreeMem
	bra.b	1$
2$	move.l	a2,a0
	jsrlib	DeleteMsgPort
	jsrlib	Permit
	move.l	(a7)+,a2
	rts

******************************
;StdIO = CreateStdIO (msgport)
;a0.l			a0.l
;eallocates an standard IO requestor block
******************************
CreateStdIO
	moveq.l	#IOSTD_SIZE,d0

******************************
;extIO = createExtIO (msgport,size)
;a0			a0.l	d0.l
;allocates an Extenden IO requestor block
******************************
CreateExtIO
;	move.l	d0,-(a7)
;	move.l	a0,-(a7)
;	XREF	_CreateExtIO
;	jsr	_CreateExtIO
;	addq.l  #8,a7
;	tst.l	d0
;	rts

	movem.l	d2/a2,-(sp)
	move.l	a0,a2
	move.l	d0,d2
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	beq.b	1$
	move.l	d0,a1
;	move.b	#NT_MESSAGE,LN_TYPE(a1)
	move.b	#NT_REPLYMSG,(LN_TYPE,a1)
	move.w	d2,(MN_LENGTH,a1)
	move.l	a2,(MN_REPLYPORT,a1)
1$	movem.l	(sp)+,d2/a2
	rts

******************************
;DeleteStdIO/DeleteExtIO
;inputs : StdIO/ExtIO (a0)
;outputs: none
;deallocates IO requestor block
******************************

DeleteStdIO
DeleteExtIO
;	move.l	a0,-(a7)
;	XREF	_DeleteExtIO
;	jsr	_DeleteExtIO
;	addq.l  #4,a7
;	rts

	move.l	a0,a1
	moveq.l	#-1,d0
	move.l	d0,(IO_UNIT,a1)
	move.l	d0,(IO_DEVICE,a1)
	moveq.l	#0,d0
	move.w	(MN_LENGTH,a1),d0
	jmplib	FreeMem

***************************************************************************
***				DATA					***
***************************************************************************

		section data,data

consolename	dc.b	'console.device',0
timername	dc.b	'timer.device',0

tosysopfname	dc.b	'ABBS:ToSysop',0
logfilenameo	dc.b	'ABBS:node',0,'logfile',0
schatfilenameo	dc.b	'node',0,'sysopchat',0
miscdirname	dc.b	'ABBS:Misc/',0
banfilename	dc.b	'ABBS:Config/banfile',0
filebanfilename	dc.b	'ABBS:Config/filebanfile',0

shellfnameetext	dc.b	'/shell-output',0
fifoshellntext	dc.b	'FIFO:'
shellsfnametext	dc.b	'abbs #',0,'_s',0
shellmfnametext	dc.b	'abbs #',0,'_m',0
newshelstext	dc.b	'NewShell "FIFO:abbs #',0,'/rwkecs" from ',0
newsheletext	dc.b	'ABBS:sys/shell-startup',0
readptrfname	dc.b	'Read pointers',0

publicportname	dc.b	'ABBS node #',0,' port',0
nodetaskname	dc.b	'ABBS node #',0,' - User: ',0
rexxportname	dc.b	'REXX',0
paragonportname	dc.b	'DoorControl',0,0
netportname	dc.b	'ABBSnet',0,'.port',0

bulletinpath	dc.b	'bulletins/',0
filespath	dc.b	'F1:',0
doorspath	dc.b	'ABBS:Doors/',0
conftextpath	dc.b	'ABBS:Text/Conf_text/',0
textpath	dc.b	'text/',0
bulletlisttext	dc.b	'bl',0
repextension	dc.b	'.REP',0
msgextension	dc.b	'.MSG',0
qwkextension	dc.b	'.QWK',0
hippoextension	dc.b	'.HD',0
allqwksendfiles	dc.b	'(#?.dat|BLT-#?)',0
allhipsendfiles	dc.b	'(#?.HD)',0
qwkmsgdatfile	dc.b	'messages.dat',0
qwkbullfilename	dc.b	'BLT-',0

grabformattexts	dc.b	'MBBS',0,0
		dc.b	'QWK',0,0,0
		dc.b	'HIPPO',0

longpacknames	dc.b	'Text',0,0
		dc.b	'Arc',0,0,0
		dc.b	'Lzh',0,0,0
		dc.b	'Zip',0,0,0
		dc.b	'Lharc',0
		dc.b	'Arj',0,0,0
		dc.b	'Zoo',0,0,0
		dc.b	'Lzx',0,0,0

packchars	dc.b	'T',0				; koden forutsetter 2 tegn
		dc.b	'A',0
		dc.b	'L',0
		dc.b	'Z',0
		dc.b	'H',0
		dc.b	'J',0
		dc.b	'O',0
		dc.b	'X',0
		dc.b	0,0

		even
packexctstrings	dc.l	txtextension
		dc.l	arcextension
		dc.l	lzhextension
		dc.l	zipextension
		dc.l	lhaextension
		dc.l	arjextension
		dc.l	zooextension
		dc.l	lzxextension

nilstring	dc.b	'NIL:',0
copystring	dc.b	'copy clone ',0
executestring	dc.b	'Execute ',0
deletestring	dc.b	'Delete ',0
allforcestring	dc.b	'#? all force',0
packstring	dc.b	'ABBS:sys/pack',0
extractstring	dc.b	'ABBS:sys/extract',0
viewstring	dc.b	'ABBS:sys/View ',0
checkarcstring	dc.b	'ABBS:sys/Check ',0

txtextension	dc.b	'.txt',0	; t
arcextension	dc.b	'.arc',0	; a
lzhextension	dc.b	'.lzh',0	; l
zipextension	dc.b	'.zip',0	; z
lhaextension	dc.b	'.lha',0	; h
arjextension	dc.b	'.arj',0	; j
zooextension	dc.b	'.zoo',0	; o
lzxextension	dc.b	'.lzx',0	; x

loginscrname	dc.b	'ABBS:sys/LoginScript.abbs',0
logoutscrname	dc.b	'ABBS:sys/LogoutScript.abbs',0
logutscriptname	dc.b	'ABBS:sys/logout.script',0
pagescriptname	dc.b	'ABBS:sys/sysoppage.abbs',0
uloadscriptname	dc.b	'ABBS:sys/upload.script',0
downloadscrname	dc.b	'ABBS:sys/Download.abbs',0
newuserscrname	dc.b	'ABBS:sys/Newuser.abbs',0
ploginscrname	dc.b	'ABBS:sys/Login/',0
helpscriptname	dc.b	'ABBS:sys/Help.abbs',0
miscmenuscrname	dc.b	'ABBS:sys/Miscmenu.abbs',0
namechanscrname	dc.b	'ABBS:sys/namechange.script',0

questinarefname	dc.b	'ABBS:sys/Questionnaire'
dotabbstext	dc.b	'.abbs',0
doorconfigfname	dc.b	'Doors/Node',0,'Config',0
doormenufilname	dc.b	'Doors/Node',0,'Menu',0

loginfilename	dc.b	'text/loginfile',0
failedpwfname	dc.b	'text/failedpassword',0
postloginfname	dc.b	'text/postloginfile',0
uploadfname	dc.b	'text/upload',0
downloadfname	dc.b	'text/download',0

register1finame	dc.b	'text/logintxt1',0
register2finame	dc.b	'text/logintxt2',0
logoutfilename	dc.b	'text/logoutfile',0

conmenufile	dc.b	'text/nodemenu',0
boardstatfilena	dc.b	'text/Boardstat',0

globalmenufile	dc.b	'text/globalmenu',0
mainmenufile	dc.b	'text/mainmenu',0
readmenufile	dc.b	'text/readmenu',0
sysopmenufile	dc.b	'text/sysopmenu',0
utilitymenufile	dc.b	'text/utilitymenu',0
filemenufile	dc.b	'text/filemenu',0
sigopmenufile	dc.b	'text/sigopmenu',0
markmenufile	dc.b	'text/markmenu',0
chatmenufile	dc.b	'text/chatmenu',0
searchmenufile	dc.b	'text/searchmenu',0
maintenmenufile	dc.b	'text/maintenance',0
smaintemenufile	dc.b	'text/sigopmaintenance',0
miscmenufile	dc.b	'text/Miscmenu',0
grabformenufile	dc.b	'text/GrabFormat',0
bulletihelpfile	dc.b	'text/BulletinHelp',0
BrowseMhelpfile	dc.b	'text/BrowseModeHelp',0
sysoponlinetext	dc.b	'text/sysoponline',0
sysopoflinetext	dc.b	'text/sysopoffline',0

ansiextension	dc.b	'.ansi',0
rawextension	dc.b	'.raw',0
abbsextension	dc.b	'abbs',0

conflistfilname	dc.b	'text/conferencelist',0
filelistfilname	dc.b	'text/filelist',0
charsetlfilname	dc.b	'text/charsetlist',0		; bare .raw
scrformlfilname	dc.b	'text/scrformatlist',0
protoclifilname	dc.b	'ABBS:text/protocolslist',0	; grab skifter cd, så vi må ha en full path
experthlfilname	dc.b	'text/expertmodehelp',0
msgfilterhfname	dc.b	'text/messagefilterhelp',0
cookiefilename	dc.b	's:cookies',0

systemtext1	dc.b	'[33mABBS '
		version
		dc.b	' [32mNode #',0
systemtext2	dc.b	':8N1',0
localtext	dc.b	'(local)',0

;serime	dc.b	'text/conferencelist',0

serialnrtext	dc.b	'[0msn: #',0

transnltext	dc.b	13,10,0
newlinetext	dc.b	10,10,0
newlinestext	dc.b	10,0
deltext		dc.b	8,32,8		;,0
nulltext	dc.b	0
ytext		dc.b	'Y',0
ntext		dc.b	'N',0
itext		dc.b	'I',0
previewtext	dc.b	'[32m·',0
minusstext	dc.b	'-',0
oktext		dc.b	'OK',0,0

;node init feilmeldinger
abbserrortext	dc.b	'ABBS error message',0
notmpdirerror	dc.b	'Error creating tmp dir',0
noserparamerror	dc.b	'Error setting serial parameters ('
noserparamerro1	dc.b	'xxxxx)',0
noserdeverror	dc.b	'Error opening Serial device',0
notimerdeverror	dc.b	'Error opening Timer.device',0
nocondeverror	dc.b	'Error opening Concole.device',0
noioreqerror	dc.b	'Error creating IO requester',0
setupmenuerror	dc.b	'Error while setting up menu',0
nomenuerror	dc.b	'Error attaching menu',0
nowindowerror	dc.b	'Error opening window',0
noporterror	dc.b	'Error creating port',0
nosignalerror	dc.b	'Error allocating signal bit',0
sametmpdirerror	dc.b	'Mulitple nodes with same tmpdir/hold dir',0
nodeconfigerror	dc.b	'Error reading node config file',0
noabbsdirerror	dc.b	'Error obtaining lock on ABBS:',0
nomemoryerror	dc.b	'Error allocating memory',0


whatisfirstname	dc.b	'What is your FIRST name? ',0
whatislastname	dc.b	'What is your LAST name? ',0
nametolongtext	dc.b	10,'Name is too long (max 30 chars total)!',0
nametolong2text	dc.b	10,'Name is too long!',0
isnotregtext	dc.b	' is not registered as a user of this BBS.',0
typernltext	dc.b	'Type R to Register, N to retype your Name, or L to Log off <Reg/Name/Lgff>: ',0
pleaseepasstext	dc.b	'Please enter your password (dots will echo): ',0
wrongtext	dc.b	'Wrong!',0
namebannedtext	dc.b	'This name is banned!',0

tuserkilledtext	dc.b	10,'This user is killed!. Bye!',0
shukillusertext	dc.b	'Sure you want to kill user: ',0
userkilledtext	dc.b	'User killed.',0
useralreadykill	dc.b	'User is already killed!',0
userukilledtext	dc.b	'User unkilled.',0
killthiusertext	dc.b	'Kill this user ',0
killedtext	dc.b	' killed.',0

pltellsysoptext	dc.b	10,'Please tell sysop.',0
notransfertext	dc.b	'File transfer not allowed on local nodes!',0
filenotfountext	dc.b	'File not found!',0
filefountext	dc.b	'File exists already!',0
filefounondtext	dc.b	'File exists already (on disk)!',0
startdescwstext	dc.b	10,'(Start description with ''/'' if file is for SYSOP only)',0
pleaseentfdtext	dc.b	'Please enter description of file: ',0
startyourtext	dc.b	10,'Start your ',0
receivetext	dc.b	' receive now.',0
sendtext	dc.b	' send now.',0
trfstatl1text	dc.b	'block     bytes    elapsed   expected rate timo errors              error msg',10,13,0
trfstatl2text	dc.b	'---- ---------- ---------- ---------- ---- ---- ---- ------------------------',10,13,0
errorstext	dc.b	'err',0

errorreceivtext	dc.b	10,'Error receiving file.',0
errorsendtext	dc.b	10,'Error sending file.',0
shuabortmsgtext	dc.b	10
abortmsgtext	dc.b	'Abort message <Y/N> ',0
cnftmovemsgtext	dc.b	10,'Conference to move message to: ',0
msgmovedtext	dc.b	10,'Msg moved.',0
msgupdatedtext	dc.b	'Msg updated',0
cmmovtoconftext	dc.b	10,'You can''t move a message to that conference!',0
notallmoveftext	dc.b	10,'You are not allowed to move this file.',0
notallomovetext	dc.b	10,'You are not allowed to move this msg.',0
notallokilltext	dc.b	10,'You are not allowed to kill this msg.',0
notallukilltext	dc.b	10,'You are not allowed to unkill this msg.',0
msgalkilledtext	dc.b	10,'Msg already killed.',0
msgnokilledtext	dc.b	10,'Msg not killed.',0
msgkilledtext	dc.b	10,'Msg killed',0
msgunkilledtext	dc.b	10,'Msg unkilled',0
msgkilledbytext	dc.b	'Msg withdrawn by ',0

errloadmsghtext	dc.b	10,'Error reading msg header',0
errloadmsgttext	dc.b	10,'Error reading msg text',0
onlydupownmtext	dc.b	'You may only DUPlicate your own messages!',0
changetoadrtext	dc.b	'Change TO address (enter=no change): ',0
changefradrtext	dc.b	'Change FROM address (enter=no change): ',0
allnotallowtext	dc.b	'ALL not allowed here',0

loginattext	dc.b	10,'Login at:',0
timenowtext	dc.b	10,'Time now:',0
timeallowed	dc.b	10,'Time allowed  : ',0
timeremaintext	dc.b	10,'Time remaining: ',0
ftimelefttext	dc.b	10,'File time left: ',0
timeonlinetext	dc.b	10,'Time online   : ',0
timeusedsestext	dc.b	10,'Time used this session:',0
deductfchattext	dc.b	10,'Deducting for CHAT time :',0
deductforultext	dc.b	10,'Deducting for UPLOAD time:',0

timeusedtodtext	dc.b	10,'Time used today:',0
totonlinetitext	dc.b	10,'Total online time today : ',0
timeremaindtext	dc.b	10,'Time remaining          : ',0

nextwarntext1	dc.b	'Next warning when ',0
nextwarntext2	dc.b	' min remain.',0
newtimelimtext	dc.b	'New time limit (0=no limit): ',0
newfilelimtext	dc.b	'New file limit (0=no limit): ',0
currtimelimtext	dc.b	'Current time limit: ',0
currfilelimtext	dc.b	'Current file limit: ',0
timexpiredtext	dc.b	10,'Your time limit has expired.',0
ftimexpiredtext	dc.b	10,'Your filetime limit has expired.',0

alreamembertext	dc.b	10,'User is already member of this conference!',0
sureinviteatext	dc.b	10,'Sure you want to invite everybody ',0
nobulletinstext	dc.b	'No bulletins on this board.',0
entinbullnrtext	dc.b	'Enter bulletin nr to replace, or return for new: ',0
bulletininstext	dc.b	10,'Bulletin installed',0
nobulletstctext	dc.b	10,'No bulletins to clear!',0
errorrenbultext	dc.b	'Error renaming  bulletins',0
sureclearbtext	dc.b	'Sure you want to clear all bulletins in this conference ? ',0
bulletscleatext	dc.b	10,'Bulletins cleared.',0
enterffnametext	dc.b	'Enter full file name: ',0
filenotavaltext	dc.b	'File not available, please check with sysop.',0
enterkeywortext	dc.b	10,'Enter keyword: ',0
datetoscanftext	dc.b	'Date to scan for YYMMDD (Enter=',0
sparakolontext	dc.b	'): ',0
invaliddatetext	dc.b	'Invalid date: try again!',0
enterdoscomtext	dc.b	10,'Enter DOS command: ',0
errordoscmdtext	dc.b	10,'Error while executing dos command.',0
detailelisttext	dc.b	'Detailed list ',0
browsmpromptext	dc.b	'Browse mode status',0
browsmpromhtext	dc.b	'<Active,Inactive>',0

browseacttext	dc.b	'Browse mode active.',0
browseinacttext	dc.b	'Browse mode inactive.',0
browsenalowtext	dc.b	'You need to have Full Screen Editor enabled to use Browse mode.',0
filetablfultext	dc.b	'File table full. List truncated.',0

interlogintext	dc.b	'Login  ',0
interlogouttext	dc.b	'Logout ',0
fromhashtext	dc.b	'From #',0
youhavemailtext	dc.b	'You have mail! (from ',0
chatreqanswtext	dc.b	'Chat request. Answer with chat ',0

; Log file tekster.
startupmsgtext	dc.b	'Node setup ok.',0
shutdownsgtext	dc.b	'Node shut down.',0
nocdsignaltext	dc.b	'No CD signal after Connect.',0
faildconnectext	dc.b	'Failed connect.',0
toslowconectext	dc.b	'To slow connect.',0
loglogintext	dc.b	'Login:',0
loglogouttext	dc.b	'Logout: ',0
lostcarriertext	dc.b	'Lost carrier: ',0
logthrownoutext	dc.b	'Thrown out: ',0
logfellasletext	dc.b	'Fell asleep: ',0
failedpaswdtext	dc.b	'Failed password: ',0
newusermsgtext	dc.b	'- - - - NEWUSER - - - -',0
pagedsysoptext	dc.b	'Paged sysop.',0
loggrabedtext	dc.b	'Grab''ed messages.',0
logdlmsgtext	dc.b	'Downloaded:',0
logulmsgtext	dc.b	'Uploaded file:',0
logfdlmsgtext	dc.b	'Failed downloading file:',0
logfulmsgtext	dc.b	'Failed uploaded file:',0
logboottext	dc.b	'Machine booted.',0
lognamechantext	dc.b	'Changed name to:',0
logchatedtext	dc.b	'Chatted with:',0
logreadbultext	dc.b	'Read bulletin',0
logdksearchtext	dc.b	'Did keyword search on',0
logscannedftext	dc.b	'Scanned for',0
;logsnodemsgtext	dc.b	'Sent node msg to node',0
logresconftext	dc.b	'Resigned from conference',0
logjoinedctext	dc.b	'Joined conference',0
logregusertext	dc.b	'Registered new user: ',0
lognofiletext	dc.b	'File not found: ',0
logkiledmsgtext	dc.b	'Killed msg:',0
logentermsgtext	dc.b	'Wrote msg:',0
logreplymsgtext	dc.b	'Replied msg:',0
logmsgreadtext	dc.b	'messages read.',0
logmsgdumedtext	dc.b	'messages dumped.',0
logtimeusedtext	dc.b	'Time used:',0
logftimeusedtxt	dc.b	'Time in files:',0
cpstext		dc.b	'cps, ',0
logopendoortext	dc.b	'Opened door:',0
loggotholdtext	dc.b	'Downloaded hold.',0
logfdlholdtext	dc.b	'Failed downloading hold.',0
logaddfiletext	dc.b	'Added file: ',0
logexitodostext	dc.b	'Exited to dos.',0
logdoscmdtext	dc.b	'Dos:',0
logleftcomment	dc.b	'Left comment:',0
logdidmisctext	dc.b	'Used Misc command:',0

; tosysop tekster
tosysopnewuser	dc.b	'NewUser:',0
toaysopupload	dc.b	'Uploaded:',0

traprotocoltext	dc.b	'Transfer protocol (? for menu): ',0
unknowtraprtext	dc.b	'Unknown transfer protocol!',0
nobatchtrantext	dc.b	'current transfer protocol does not support batch download!',0
unknowcarsetext	dc.b	'Unknown charset!',0
musthaveisotext	dc.b	'You must use ISO (or standard ASCII) at login prompt',0
charnallowdtext	dc.b	'The ''@'' character is not allowed in user names!!',0
nopathallowtext	dc.b	'No path allowed in filename!',0
only18charatext	dc.b	'Only 18 characters allowed in file name!',0
saveusererrtext	dc.b	'Error saving user.',0
loadusererrtext	dc.b	'Error loading user.',0

dumpmsgpromtext	dc.b	'<C>onf, <A>ll, <M>essage, <CLEAR>, <Enter>=quit: ',0
scratchpdeltext	dc.b	'Scratchpad deleted!',0
scratchpemptext	dc.b	10,'Scratchpad emptied.',0

lmsgreadrestext	dc.b	'Last message read has been reset in dumped conferences!',0
usesendtotrtext	dc.b	'Use <SE>nd to transfer scratchpad to your machine.',0
msgaddtoscrtext	dc.b	' messages added to scratchpad.',0
cleartext	dc.b	'CLEAR',0
dumpingtext	dc.b	'Dumping ',0
erropenscratext	dc.b	'Error opening scratchfile',0
errwritscratext	dc.b	'Error writing to scratchfile',0
scrstillavatext	dc.b	'(Scratchpad is still available for SEnd)',0
nottransscrtext	dc.b	'You have not transferred your scratchpad! Want it now ',0
resetreaptrtext	dc.b	'Want to reset last message read to previous state ',0

wantqwknbultext	dc.b	'Do you want new Bulletins sent in your QWK package ',0
mbbsnomsguptext	dc.b	'MBBS format has no message upload.',0
qwkcantdumptext	dc.b	'QWK can''t handle this dump command',0
hipcantdumptext	dc.b	'Hippo can''t handle this dump command',0
hippnomsguptext	dc.b	'Hippo format has no message upload (yet).',0
errorpackintext	dc.b	'Error packing!',0
errorextrintext	dc.b	'Error extracting!',0
pleaswaitwptext	dc.b	'Please wait while I pack the file',0
grabgoodfortext	dc.b	'GRABbing is good for your health!',0
cantfinpacktext	dc.b	10,'Can''t find the pack progam, using txt instead.',0
cantfinextrtext	dc.b	'Can''t find the extract progam. Cannot unpack.',0
packformatutext	dc.b	10,'Pack format is unavailable.',0
archiveformtext	dc.b	10,'Format choice (? for menu): ',0
unknowformatext	dc.b	10,'Unknown format!',0
msgfilterletext	dc.b	'Message filter level, <0-50> (Enter=no change): ',0
expertmodeptext	dc.b	'Enter mode ',0
expertmodehtext	dc.b	'<Novice, Junior, Expert, Superexpert>',0
Novicetext	dc.b	'Novice',0
Juniortext	dc.b	'Junior',0
Experttext	dc.b	'Expert',0
SuperExperttext	dc.b	'Super Expert',0
		even
experttexts	dc.l	Novicetext,Juniortext,Experttext,SuperExperttext

modeselectetext	dc.b	'mode selected.',0
confstatnshtext	dc.b	'Conference status will not be shown at logon.',0
confstatshotext	dc.b	'Conference status will be shown at logon.',0
noisefiltentext	dc.b	'Noise filter enabled.',0
noisefiltditext	dc.b	'Noise filter disabled.',0
userprofsavtext	dc.b	'User profile updated.',0

reenewpasstext	dc.b	'Reenter your new password (dots will echo): ',0
enewpasstext	dc.b	'Enter your new password (dots will echo): ',0
eoldpasstext	dc.b	'Enter your old password (dots will echo): ',0
elogonpasstext	dc.b	'Enter your login password (dots will echo): ',0
passwordwtext	dc.b	'An error occured. Your password might be wrong. Please tell sysop',0
moretext	dc.b	'--more-- (y/n/c):',0
morenohelptext	dc.b	'--more--',0
linesprpagetext	dc.b	10,'Lines per page: <enter>=no change, <0>=continuous: ',0
min10linestext	dc.b	10,'Minimum 10 lines!',0
musthavenrtext	dc.b	'You must enter a number!',0
invalidnrtext	dc.b	'Invalid nr!',0
msgunreadtext	dc.b	' messages unread',0
foryoutext	dc.b	' for you',0
updatedbultext	dc.b	' (updated bulletins)',0
showconfopttext	dc.b	'<U>nread messages or <A>ll conferences: ',0
invalidcmdtext	dc.b	'Invalid command!',0

Membertext	dc.b	'Member',0
READONLYtext	dc.b	'READ ONLY',0
Obligatorytext	dc.b	'Obligatory',0
Nonmembertext	dc.b	'Non-member',0
Privateallotext	dc.b	'Private allowed',0
Networkconftext	dc.b	'Network',0
USERINFOtext	dc.b	'USER INFO',0
FILEINFOtext	dc.b	'FILE INFO',0
Mailtext	dc.b	'MAIL',0
Bulletinstext	dc.b	' (Bulletins)',0
joinnoreadtext	dc.b	'Joined, nothing read',0

confstatustext	dc.b	10,'Conference Status',0
cconfstatustext	dc.b	' conference status:',0
Lastmsgtext	dc.b	10,'Last message : ',0
Lastmsgyourtext	dc.b	10,'Last you read: ',0
nmesgaavailtext	dc.b	' new message',0
nmesgaavai2text	dc.b	's are ',0
nmesgaavai3text	dc.b	' is ',0
nmesgaavai4text	dc.b	'available',0
smallalltext	dc.b	'all',0
nomoremsgictext	dc.b	10,'No more unread. Press <ENTER> for next conference.',0
checkfmsgictext	dc.b	'Checking for messages in conferences you are a member of...',0
nonewiacmsgtext	dc.b	'No unread messages in conferences!',0
confbullacttext	dc.b	10,'Conference bulletins are active.',0
sigopcomacttext	dc.b	10,'Sigop commands are active.',0
bullhasbupdtext	dc.b	'Bulletins have been updated since your last logon.',0

mloginstatetext	dc.b	'Message pointers reset to login state',0
allmbresettext	dc.b	10,'All marks have been reset',0
msgmarkedtext	dc.b	' Messages marked',0
cantmarkmsgtext	dc.b	10,'You can''t mark this message.',0
unmarkingtext	dc.b	10,'Unmarking :',0
markingtext	dc.b	10,'Marking :',0
msgsfoundtext	dc.b	10,'Messages found :',0
markmsgfromtext	dc.b	10,'Mark messages from date (YYMMDD): ',0
msgtosetasltext	dc.b	'Message to be marked as last read: ',0

frommsgtext	dc.b	'From message <',0
tomsgtext	dc.b	'  To message <',0
ftmsgconttext	dc.b	'>, <Enter=',0
wantmsggrwotext	dc.b	10,'Want messages grouped with originals ',0
detaledlisttext	dc.b	'Detailed list (N gives subjects only) ',0

enteryorntext	dc.b	'Please answer yes or no (Y or n)',0
pleaseentertext	dc.b	'Please enter your ',0
logonpasswdtext	dc.b	'Logon password: ',0
addresstext	dc.b	'Street address: ',0
postalcodetext	dc.b	'Postal code and town: ',0
hometlfnumbtext	dc.b	'Home telephone number: ',0
worktlfnumbtext	dc.b	'Work telephone number: ',0
hometext	dc.b	'Home: ',0
worktext	dc.b	'Work: ',0
uploadstext	dc.b	'Uploads: ',0
dloadtext	dc.b	'D''loads: ',0
timesontext	dc.b	'Times on: ',0
lastontext	dc.b	'Last on: ',0
passwdtext	dc.b	'Passwd: ',0
timektext	dc.b	'Time: ',0
filektext	dc.b	'File: ',0
Pagektext	dc.b	'Page:',0
Protktext	dc.b	'Prot:',0
Menuktext	dc.b	'Menu:',0
ANSIktext	dc.b	'ANSI:',0
FSEktext	dc.b	'FSE:',0
Termktext	dc.b	'Term:',0
Chrsktext	dc.b	'Chrs:',0
scfktext	dc.b	'Scf:',0
bytetext	dc.b	'byte:',0
plainfiletext	dc.b	'file:',0
accesstext	dc.b	' access: ',0
lastreadtext	dc.b	'Last Read: ',0
msgreadtext	dc.b	'Messages read=',0
msgdumpedtext	dc.b	', messages dumped=',0
msgenteredtext	dc.b	', messages entered=',0

satisfiedtext	dc.b	10,'            Satisfied with your answers ',0
youmustenttext	dc.b	10,'You MUST enter something, sensible or not!',0
yourcharsettext	dc.b	'New charset (type ? for help): ',0
Timesonsystext	dc.b	10,'Times on this system:',0
lasttimeontext	dc.b	10,'Last time on this system:',0
filesupltext	dc.b	10,'Files Uploaded:',0
filesdownltext	dc.b	10,'Files Downloaded:',0
timeusedtdtext	dc.b	10,'Time used today:',0
ftimeusedtdtext	dc.b	10,'File time used today:',0
minutestext	dc.b	' minutes.',0
tfprivfwtdltext	dc.b	10,'The following private file(s) are waiting for you to download:',0
errloadfilhtext	dc.b	'Error reading file header',0
errsavefilhtext	dc.b	'Error saving file header',0

youhfinholdtext	dc.b	'You have files in HOLD! Return to BBS to collect them ',0
filesinholdtext	dc.b	'You have the following files in hold:',0
nofileiholdtext	dc.b	'No files found in hold!',0
erasingtext	dc.b	'Erasing: ',0
novalidname	dc.b	'Sorry, that''s not a valid name!',0
holdtext	dc.b	'Hold',0
nopriviholdtext	dc.b	'[31mPrivate files may not be moved to HOLD!',0
arcivenametext	dc.b	'Archive name',0
filetoextract	dc.b	'File to extract (Enter = #?)',0

memheadertext	dc.b	10,'Type  Available    In-Use   Maximum   Largest',0
mem1text	dc.b	10,'chip ',0
mem2text	dc.b	10,'fast ',0
mem3text	dc.b	10,'total',0
surewtobootext	dc.b	10,'Sure you want to boot the system ',0
bootingsysttext	dc.b	10,'Booting the system...',0
suredellogtext	dc.b	10,'Sure you want to delete the log file ',0
logdeletedtext	dc.b	10,'Log deleted.',0
surepackusrtext	dc.b	'REALLY sure you want to pack the user file ',0
takenbackuptext	dc.b	'Have you taken a backup of the system ',0
younotalonetext	dc.b	'You''re not alone on the system!',0
thismaytaketext	dc.b	'This may take a while. Please wait.',0
stablefullctext	dc.b	'Sorry, table full, can''t remove all killed users at once',0
errwpackingtext	dc.b	'Error while packing users',0

cleanuser1text	dc.b	'Enter selection criteria for users to select',0
cleanuser2text	dc.b	'Press enter if you want to ignore the question!',0
cleanuser3text	dc.b	'Only users with MORE logons than: ',0
cleanuser4text	dc.b	'Only users with LESS logons than: ',0
cleanuser5text	dc.b	'Only users with MORE downloads than: ',0
cleanuser6text	dc.b	'Only users with LESS downloads than: ',0
cleanuser7text	dc.b	'Only users with MORE messages read than: ',0
cleanuser8text	dc.b	'Only users with LESS messages read than: ',0
cleanuser9text	dc.b	'Only users NOT logged on after (yymmdd): ',0
cleanuser10text	dc.b	'Only users logged on after (yymmdd): ',0
cleanuser11text	dc.b	'Restrict to users without general download access: ',0
cleanuser12text	dc.b	'Restrict to users *with* general download access: ',0
cleanuser13text	dc.b	'K)ill S)top N)ext: ',0

commandtext	dc.b	' Command[0;37m',0
qmformenutext	dc.b	' (? for menu)',0
doyearealyltext	dc.b	'Sure you want to log off',0
doyearealyhtext	dc.b	'<Yes, No, Again (new login) (Enter=Yes)>',0
tmpsysopacctext	dc.b	10,'***** Temporary SYSOP privileges ',0
giventext	dc.b	'granted *****',0
takenawaytext	dc.b	'removed *****',0

anerrorocctext	dc.b	'An Error has occoured (',0,')',0
doserrortext	dc.b	'Dos Error',0
diskerrortext	dc.b	'Disk Error!',0
diskfulltext	dc.b	'Disk full!',0

nalviewupprtext	dc.b	'You are not allowed to view files in upload or private fildirs',0
youarenottext	dc.b	10,'You are NOT allowed to do that!',0
newacctext	dc.b	'New access: ',0
suregivenatext	dc.b	10,'Sure you want to give everybody this access ',0
invalidacctext	dc.b	'Invalid access type specified!',0
accessbitstext	dc.b	'RWUDFISZ'
accesstypetext	dc.b	'Access type <RWUDFISZ>: ',0
sigopaccesstypetext	dc.b	'Access type <RWUDFI>: ',0
rtext		dc.b	'R',0
allconferentext	dc.b	'All conferences ',0

passwdnotchtext	dc.b	'Password is NOT changed.',0
passwdchtext	dc.b	10,'Password is changed.',0
enteruserntext	dc.b	'Enter user name: ',0
usernotfountext	dc.b	'Sorry, that name is not registered!',0
scanuserregtext	dc.b	10,'Scanning user register...',0
sorryusnmoctext	dc.b	'Sorry! That user is not a member of this conference!',0
onlythelasttext	dc.b	'NB! Only the last ',0
msgaautscantext	dc.b	' messages are automatically scanned',0
wantdetlisttext	dc.b	'Want detailed list ',0

noallyettext	dc.b	'Cannot handle ALL yet',0
sorrynohelptext	dc.b	'Sorry, no help available',0
Notvalidcomtext	dc.b	'[31mThis is not a valid command! Valid commands are:[0m',0
userrecupdatext	dc.b	'User updated.',0
usernotupdatext	dc.b	'User not updated!',0
usersupdatetext	dc.b	'> user',0
usersupdat2text	dc.b	' updated.',0
userslistedtext	dc.b	' user(s) listed.',0
updatedtext	dc.b	'Updated: ',0

whoheader	dc.b	10,'[36mNode  Speed    Status                   Caller',10
		dc.b	'----  -----    ------                   ------',10,0
fileiheadertext	dc.b	10
fileihnorettext	dc.b	'  File name          Date     Kb Min  Dls File description',10
		dc.b	'  ---------          ----     -- ---  --- ----------------',0
entbulletnrtext	dc.b	10,'Bulletin number',0
entbullhelptext	dc.b	'<List, Download, Add, Enter for none>',0
ymchosebulltext	dc.b	'You must choose a bulletin by reading it!',0

nobullettext	dc.b	'There is no bulletin by that number (L for listing.)',0

editorchoicetxt	dc.b	10,'Save, Continue, Abort, Private, pUblic or List msg (S,C,A,P,U,L) [S] ? ',0
msgmadpublictxt	dc.b	10,'Msg made public.',0
msgmadprivattxt	dc.b	10,'Msg made private.',0
msgcantprivatxt	dc.b	10,'Msg can''t be made private.',0
msgcantpublicxt	dc.b	10,'Msg can''t be made public.',0
skipnextmsgtext	dc.b	'Skipping to next unread message.',10,0

newnametext	dc.b	'New name: ',0
noallheretext	dc.b	'Sorry, ALL is not allowed here!',0
nameusedtext	dc.b	10,'Sorry, that name has already been used!',0
oktochangentext	dc.b	10,'OK to change name ',0

viewsetheadtext	dc.b	10,'[32mCurrent user profile',10
minustext	dc.b	'--------------------',0
viewsetnametext	dc.b	10,'Your name:',0
viewsetadrtext	dc.b	10,'Street Address:',0
viewsetposttext	dc.b	10,'Postal Code and Town:',0
viewsethometext	dc.b	10,'Home phone number:',0
viewsetworktext	dc.b	10,'Work phone number:',0
viewsetplentext	dc.b	10,'Page length:',0
viewsetdefptext	dc.b	10,'Default protocol:',0
viewsettermtext	dc.b	10,'Terminal type:',0
viewsetarcftext	dc.b	10,'Archive Format:',0
viewsetchartext	dc.b	10,'Character set:',0
viewsetautotext	dc.b	10,'Auto quote:',0
viewsetansitext	dc.b	10,'ANSI graphic menus:',0
viewsetg_rttext	dc.b	10,'Auto file transfer:',0
viewsetfsetext	dc.b	10,'Screen editor:',0
viewsetcolmtext	dc.b	10,'Colours in messages:',0
viewsetmlevtext	dc.b	10,'Menu level:',0

viewsetULtext	dc.b	10,'Upload:',0
viewsetDLtext	dc.b	10,'Download:',0
kbtext		dc.b	'Kb',0
viewsetfrattext	dc.b	10,'File ratio:',0
viewsetbrattext	dc.b	10,'Byte ratio:',0
viewsetgrabtext	dc.b	10,'Grab format:',0

ansitesttext	dc.b	10,'[3;4mThis line should be underlined and in italics on an ANSI terminal[0;37m',0
autoquotetxt	dc.b	'Do you want to auto quote messages ',0
doyouhaansitext	dc.b	'Do you have an ANSI terminal ',0
wanansimenutext	dc.b	'Do you want menus with ANSI graphics ',0
wancolormsgtext	dc.b	'Do you want colours in messages ',0
explainfsetext	dc.b	'To use the full screen editor to enter messages, you must be using'
		dc.b	10,'a terminal or program that supports VT100 or VIP mode!',0
wantfsetext	dc.b	'Do you want to use the screen editor ',0
wantGandRtext	dc.b	'Does your program accept G&R file transfer commands ',0
clsbforemsgtext	dc.b	'Clear screen before every message ',0
keepownmsgtext	dc.b	'Review your own messages ',0
wantrawfiletext	dc.b	'Do you want raw files if they exist ',0

yestext		dc.b	'Yes',0
notext		dc.b	'No',0
nonetext	dc.b	'None',0
vansitext	dc.b	'ANSI',0
vtexttext	dc.b	'Text',0

byslashntext	dc.b	'(Enter=Y): ',0	;	'(Y/n) ',0
yslashbntext	dc.b	'(Enter=N): ',0	;	'(y/N) ',0
quistspacetext	dc.b	'? ',0

sendmsgtotext	dc.b	'Send message to (CR for ALL): ',0
sendmsgtouatext	dc.b	'Send message to: ',0
entersubjectext	dc.b	'Subject of message: ',0
entlastnametext	dc.b	'Please enter both the first AND the last name!',0
nonetnametext	dc.b	'Net names are not allowed here.',0
includeomsgtext	dc.b	'Include original message ',0
privatemsgetext	dc.b	'Private message ',0
msgtext1	dc.b	'Msg #',0
noinfoonnettext	dc.b	'No information availible on net users',0

kkommaspacetext	dc.b	'K, ',0
endparatext	dc.b	')',0
spaceparatext	dc.b	' (',0
mparatext	dc.b	'm)',0
fortext		dc.b	' for ',0
confspacetext	dc.b	'conf ',0
userspacetext	dc.b	'user ',0
fromktext	dc.b	'From: ',0
msgstarttext	dc.b	'[36m',0
msgtext		dc.b	' message #',0
fromtext	dc.b	' from [37m',0
totext		dc.b	'[36m'
tonoansitext	dc.b	' to ',0
rekolontext	dc.b	' re: ',0
deadtext	dc.b	' (R.I.P.)',0
dottext		dc.b	'.',0
starttext	dc.b	'*',0
subjecttext	dc.b	'Subject: ',0
privatemsgtext	dc.b	' (PRIVATE)',0
readmsgtext	dc.b	' [31m(R)[36m',0
enteredontext	dc.b	'   Entered on ',0
enteredbytext 	dc.b	' entered by ',0
nomorereplytext	dc.b	'(There are no more replies.)',0
morereplyhbtext	dc.b	'(More replies have been made.)',0
replytomsgntext	dc.b	'   Reply to msg # ',0		; hack for å ligne mbbs
therearereptext	dc.b	'   (There are replies to this message.)',0
sretext		dc.b	'RE:',0
ssubjecttext	dc.b	'SUBJECT:',0
linesdottext	dc.b	'lines.',0

abortedtext	dc.b	' aborted!',0
savedtext	dc.b	' saved.',0
cnotsavemsgtext	dc.b	10,'Couldn''t save msg!',0
cntsavemsghtext	dc.b	10,'Couldn''t save msgheader!',0
msgnotfoundtext	dc.b	'Message not found!',0
msgnotavailfrep	dc.b	'Message is not available for reply.',0
joinconftext	dc.b	10,'Join conference: ',0
topicsaretext	dc.b	10,'Topics are: ',0
topictext	dc.b	10,'Topic? ',0
checkconfstext	dc.b	'Checking conferences...',0
conferecetext	dc.b	'Conference: ',0
wanttojoinctext	dc.b	'Do you want to join this conference ',0
wanttoskipltext	dc.b	'Do you want to skip to the last message in the conference ',0

sorrymaxconftxt	dc.b	10,'Sorry, this version of ABBS can only handle ',0
conferencestext	dc.b	' conferences.',0
directorystext	dc.b	' directories.',0

nodenrtext	dc.b	'Node nr: ',0
texttext	dc.b	'Text: ',0
errnodemsgtext	dc.b	'Error sending node msg.',0
nactiveusertext	dc.b	'No active user on that node!',0
cantsendtoytext	dc.b	'You cannot send a message to yourself!',0
unknownnodetext	dc.b	'Unknown node!',0
grpchatfulltext	dc.b	'Sorry, this group chat is full.',0
thusernomsgtext	dc.b	'This user is not accepting messages.',0

yaaamotfcontext	dc.b	10,'You are automatically a member of the following conferences:',0
confnametxt	dc.b	'Conference name: ',0
suredelconftext	dc.b	'Sure you want to delete this conference ',0
sureclconftext	dc.b	'Sure you want to clean this conference ',0
confdeletedtext	dc.b	'Conference deleted',0
confcleanedtext	dc.b	'Conference cleaned',0
confrenamedtext	dc.b	'Conference renamed',0
connotfoundtext	dc.b	'Invalid conference selection!',0
nmembofconftext	dc.b	'You are not a member of this conference!',0
confsamenametxt	dc.b	'Can''t have two conferences with same name!',0
dirssamenametxt	dc.b	'Can''t have two directories with same name!',0
ycantresigntext	dc.b	'You can''t resign from this conference.',0
sureywresfctext	dc.b	'Sure you want to resign from this conference ',0
resigningartext	dc.b	'Resigning from conference, and returning to ',0
dirnametext	dc.b	'Directory name: ',0
suredeldirtext	dc.b	'Sure you want to delete this directory ',0
dirdeletedtext	dc.b	'Directory deleted',0
dirrenamedtext	dc.b	'Directory renamed',0
dirnotfoundtext	dc.b	'Directory not found!',0
filealindirtext	dc.b	'File already in that directory!',0
enterdirnametxt	dc.b	'Enter directory name, <?>=list, <*>=ALL, <Enter>=none',0
filepathnametxt	dc.b	'Full directory path (ret = ABBS:files): ',0
unownstatusbtxt	dc.b	10,'Unknown status bit: ',0
econfstatustext	dc.b	10,'R=Read',10,'W=Write',10,'V=VIP',10,'A=Allow private'
		dc.b	10,'E=rEsignable',10,'P=Post conference',10,'N=Network'
		dc.b	10,10,'Enter conference status bits (R,W,P,V,A,E,N): ',0
confacsbitstext	dc.b	'RWPAVEN',0

confinstedtext	dc.b	10,'Conference installed.',0
ninstalconftext	dc.b	10,'Couldn''t install conference!',0
illconfnatext	dc.b	'Illegal characters in conference name!',0
illfdirfnatext	dc.b	'Illegal characters in filedir name!',0
dirinstsledtext	dc.b	10,'Directory installed.',0
filenametext	dc.b	'File name: ',0
newfilenametext	dc.b	'New file name: ',0
movefilnametext	dc.b	'File to move: ',0
retracfnametext	dc.b	'File to delete: ',0
suredelfiletext	dc.b	'Sure you want to delete this file ',0
remfilfdisktext	dc.b	'Remove file from disk ',0
remfilfflistext	dc.b	'Remove file from filelist ',0
modifyfnametext	dc.b	'File to modify: ',0
doloadfnametext	dc.b	'File to download: ',0
fileretracetext	dc.b	'File deleted.',0
filemovedtext	dc.b	'File moved.',0
Fileprivulftext	dc.b	'File is private upload for: ',0
fileprivtcotext	dc.b	'Private to conference ',0
filefreedltext	dc.b	'Should this file be a free DL file ',0
filemodifydtext	dc.b	'File modified.',0
filerenamedtext	dc.b	'File renamed.',0
searchingtext	dc.b	'Searching...',0
enterdeinfotext	dc.b	10,'Enter detailed description ',0
touchfdatetext	dc.b	'Touch filedate ',0
waeditfinfotext	dc.b	'Do you want to edit fileinfo ',0

texttsearchtext	dc.b	'Text to search for: ',0
searchmsgtext	dc.b	'Searching messages ',0
newmsgfoundtext	dc.b	' new messages found and marked for retrieval.',0
msgstilmarktext	dc.b	' messages now still marked.',0

nodoronsystext	dc.b	'Open door command is not available on this system!',0
erropendoortext	dc.b	'Error while opening door.',0
nrdoortopentext	dc.b	'Number of door to open: ',0
noquestionatext	dc.b	'Sorry, script is not available!',0

Insuftimeremtxt	dc.b	10,'Insufficient time remaining',0
wayaatndisptext	dc.b	10,'Want your address and telephone number displayed ',0
userlnoinfotext	dc.b	10,'This user has not left any info!',0

wantolcomentext	dc.b	'Want to leave a comment ',0
commenttext	dc.b	'Comment',0
sysopnavailtext	dc.b	10,'[33mSorry, Sysop is not available. Use COMment instead.',10,0
ulcompletedtext	dc.b	10,'Upload completed.',0
dlcompletedtext	dc.b	10,'Download completed.',0
checkratiotext	dc.b	'Checking Up/Down ratio...',0
dlacclosttext	dc.b	'Download Access temporarily lost. Upload more files to regain it.',0
dlaccgainedtext	dc.b	'Download Access regained.',0
noratioforttext	dc.b	'You don''t have enough files/bytes left to download this!',0
freedltext	dc.b	' Free DL',0
uploadfilestext	dc.b	'Upload files: ',0
uploadkbytetext	dc.b	'Upload Kbytes: ',0
downloadfiltext	dc.b	'Download files: ',0
downloadkbytext	dc.b	'Download Kbytes: ',0
fileratiotext	dc.b	'File ratio: ',0
byteratiotext	dc.b	'Byte ratio: ',0
prescriptname	dc.b	'Note: Script must reside in ',0
scriptname	dc.b	'Enter scriptname (ret = none): ',0
scripttext	dc.b	'Script: ',0

nocurentmsgtext	dc.b	'No current message!',0
lastmsgtext	dc.b	'Last message!',0
firstmsgtext	dc.b	'First message!',0
noreplytext	dc.b	'No reply!',0
nomreplytext	dc.b	'No more replies!',0
msgnotreplytext	dc.b	'This message is not a reply!',0
orgnotavailtext	dc.b	'Original not available.',0
readonlycontext	dc.b	'This is a READ ONLY conference.',0
usejtogetcltext	dc.b	' Use J to get a conference list.',0
logouttext	dc.b	10,'Logout',0
lfellasleeptext	dc.b	10,'Looks like you fell asleep. Disconnecting...',0
throwouttext1	dc.b	10,'Sorry, SYSOP has to log you out of the system.',0
throwouttext2	dc.b	10,'Please try again later.',0
killathrowntext	dc.b	10,'Sysop is booting you out of the system, please do *not* call back!',0
toslowtext1	dc.b	10,'This board don''t accept connect speeds below ',0
toslowtext2	dc.b	' baud. Disconnecting...',0
toclosetlsetext	dc.b	'Too close to previous session. You must wait some more. Disconnecting...',0


userejectedtext	dc.b	'User ejected!',0

sysopiscomitext	dc.b	10,'>>>>>>>>>>> SYSOP is coming online!',0
sysopisgointext	dc.b	10,'>>>>>>>>>>> SYSOP is going offline!',0
attext		dc.b	' at ',0
kolonspacetext	dc.b	': ',0
toyoutext	dc.b	'to you!',0
kommaspacetext	dc.b	', ',0
clearwindowtext	dc.b	12,27,'[1;1H',0
bordertext	dc.b	'<---+----1----+----2----+----3----'
		dc.b	'+----4----+----5----+----6----+----7->--+----8>'
spacetext	dc.b	'                                                  '
		dc.b	'                              '
deletetext	dc.b	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
		dc.b	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
		dc.b	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
arrowrtext	dc.b	'->',0
plussplussptext	dc.b	'+++',0
nyconfgrabtext	dc.b	'>>>>>',0
nysubjgrabtext	dc.b	'*****',0
dubblecrtext	dc.b	13,13,10,0
allwildcardtext	dc.b	'#?',0
freedlcomment	dc.b	' *0 0',0

		cnop	0,4

statustext	dc.l	loggedofftext
		dc.l	activetext
		dc.l	chattingtext
		dc.l	enteringmsgtext
		dc.l	replyingmsgtext
		dc.l	uploadmsgtext
		dc.l	downloadmsgtext
		dc.l	pagingsysoptext
		dc.l	grabingtext
		dc.l	usingdoortext
		dc.l	exitedtodostext
		dc.l	chattingwsytext
		dc.l	enterresumetext
		dc.l	getingholdtext
		dc.l	Noavailabletext
		dc.l	prichattingtext
		dc.l	regerstratitext
		dc.l	nulltext			; arexx utbyttbar tekst
		dc.l	browsingtext
		dc.l	packingtext
		dc.l	unpackingtext
		dc.l	unpackingtext

loggedofftext	dc.b	'Logged off',0			; 0
activetext	dc.b	'Active',0			; 4
chattingtext	dc.b	'Chatting',0			; 8
enteringmsgtext	dc.b	'Entering msg',0		;12
replyingmsgtext	dc.b	'Replying msg',0		;16
uploadmsgtext	dc.b	'Uploading file',0		;20
downloadmsgtext	dc.b	'Downloading file ',0		;24
pagingsysoptext	dc.b	'Paging sysop',0		;28
grabingtext	dc.b	'Collecting scratchpad',0	;32
usingdoortext	dc.b	'Using DOOR ',0			;36
exitedtodostext	dc.b	'Exited to dos',0		;40
chattingwsytext	dc.b	'Chatting with Sysop',0		;44
enterresumetext	dc.b	'Entering Resume',0		;48
getingholdtext	dc.b	'Downloading Hold ',0		;52
Noavailabletext	dc.b	'Not available',0		;56
prichattingtext	dc.b	'Chatting privatly',0		;60
regerstratitext	dc.b	'Newuser registration',0	;64
;arexxchangeabletext					;68
browsingtext	dc.b	'Browsing files',0		;72
packingtext	dc.b	'Packing file(s)',0		;76
unpackingtext	dc.b	'Unpacking file(s)',0		;80
		dc.b	0,0

nodeshutdowntxt	dc.b	'Node shut down',0
notavailfchtext	dc.b	'Not '
availforchatext	dc.b	'available for chat',0
nodencafchatext	dc.b	'Node not currently available for chat requests!',0
nodenodebtntext	dc.b	'No node by that number!',0
wafontreplytext	dc.b	'Waiting for the other node to reply ',0
contactestatext	dc.b	'Contact established with ',0
contactest2text	dc.b	'. Press CTRL+Z to end chat.',0
joinedchattext	dc.b	' joined the chat.',0
pagngsysop2text	dc.b	10,'Paging sysop (CTRL-X TO QUIT PAGER)',0
nosysopheretext	dc.b	'SYSOP may not be used here!',0

nodeputsleptext	dc.b	10,'Node is put to sleep',0
nodeawakentext	dc.b	10,'Node is awaken again',0
ureopensertext	dc.b	10,'Unable to reopen ser port.',0
preskreopentext	dc.b	10,'Press any key to reopen ser port, or F10 to shutdown',0
initmodemtext	dc.b	13,'Initializing modem',27,'[K',0
failedtoinitext	dc.b	13,'Failed to init modem',27,'[K',10
waitforcalltext	dc.b	13,'Waiting for caller'
cleartoEOLtext	dc.b	27,'[K',0
ringdetecttext	dc.b	13,'Ring detected',27,'[K',10,0
waitconnecttext	dc.b	13,'Waiting for connect ',27,'[K',0
connectdetetext	dc.b	13,10,'Connect detected',27,'[K',0
nocarriertext	dc.b	'NO CARRIER',0
dohanguptext	dc.b	'Executing Hangup',0
nocookietext	dc.b	'No cookie today!',0

alltext		dc.b	'ALL',0
netusertext	dc.b	'Net ',0
usertext	dc.b	'user',0

msysoptext	dc.b	'[1;31m'
plainsysoptext	dc.b	'SYSOP',0
maintext	dc.b	'[1;37mMain',0
readtext	dc.b	'[1;36mRead',0
utilitytext	dc.b	'[1;33mUtility',0
filetext	dc.b	'[1;35mFile',0
sigoptext	dc.b	'[1;31m'
plainsigoptext	dc.b	'SIGOP',0
marktext	dc.b	'[1;37mMark',0
readreftext	dc.b	'[1;32mRead Ref',0
chattext	dc.b	'[1;36mChat',0
searchtext	dc.b	'[1;36mSearch',0	; bold, hvit
usermaintantext	dc.b	'[1;33mUser Maintenance',0
misctext	dc.b	'[1;33mMisc',0
grabforamttext	dc.b	'[1;35mGrab Format',0

CursorOffData	dc.b	$9b,'0 p',0
CursorOnData	dc.b	$9b,'1 p',0

Plaintext	dc.b	'[0m',0
Boldtext	dc.b	'[1m',0
Kursivtext	dc.b	'[3m',0
Underlinetext	dc.b	'[4m',0

Plaintab	dc.b	0
Boldtab		dc.b	0
Kursivtab	dc.b	0
Underlinetab	dc.b	0

Quotingmode	dc.b	0

ansiclearscreen	dc.b	'[1;1H[2J',0

ansicolors
ansiblacktext	dc.b	'[30m',0
ansiredtext	dc.b	'[31m',0
ansigreentext	dc.b	'[32m',0
ansiyellowtext	dc.b	'[33m',0
ansidbluetext	dc.b	'[34m',0
ansilillatext	dc.b	'[35m',0
ansilbluetext	dc.b	'[36m',0
ansiwhitetext	dc.b	'[37m',0

ansiblack = 0*6
ansired = 1*6
ansigreen = 2*6
ansiyellow = 3*6
ansidblue = 4*6
ansililla = 5*6
ansilblue = 6*6
ansiwhite = 7*6

		even
groupchatcolors	dc.w	ansigreen,ansiyellow,ansililla,ansidblue

;0 - sort
;1 - rød
;2 - grønn
;3 - gul
;4 - mørk blå
;5 - lilla ??
;6 - lys blå
;7 - hvit

ansiinschartext	dc.b	'[@',0
ansidelchartext	dc.b	'[P',0
ansirighttext	dc.b	'[C',0
ansilefttext	dc.b	'[D',0

		cnop	0,4

reltext		dc.b	'REL',0
arqtext		dc.b	'ARQ',0
mnptext		dc.b	'MNP',0
fullv42bistext	dc.b	'V'
v42bistext	dc.b	'42BIS',0
v42shorttext	dc.b	'V42',0
hsthsttext	dc.b	'/HST/HST',0

		cnop	0,4

		even
menus		dc.l	mainmenuchtxt
		dc.l	readmenuchtxt
		dc.l	sysopmenuchtxt
		dc.l	utilitymenuchtxt
		dc.l	filemenuchtxt
		dc.l	sigopmenuchtxt
		dc.l	markmenuchtxt
		dc.l	chatmenuchtxt
		dc.l	searchmenuchtxt
		dc.l	usermaintachtxt
		dc.l	susermaintchtxt
		dc.l	miscmenuchtxt
		dc.l	grabfomenuchtxt

menutexts	dc.l	maintext
		dc.l	readtext
		dc.l	msysoptext
		dc.l	utilitytext
		dc.l	filetext
		dc.l	sigoptext
		dc.l	marktext
		dc.l	chattext
		dc.l	searchtext
		dc.l	usermaintantext
		dc.l	usermaintantext
		dc.l	misctext
		dc.l	grabforamttext

menujmps	dc.l	mainjmptable
		dc.l	readjmptable
		dc.l	sysopjmptable
		dc.l	utilityjmptable
		dc.l	filejmptable
		dc.l	sigopjmptable
		dc.l	markjmptable
		dc.l	chatjmptable
		dc.l	searchjmptable
		dc.l	usermaijmptable
		dc.l	susermajmptable
		dc.l	miscjmptable
		dc.l	grabforjmptable

menufiles	dc.l	mainmenufile
		dc.l	readmenufile
		dc.l	sysopmenufile
		dc.l	utilitymenufile
		dc.l	filemenufile
		dc.l	sigopmenufile
		dc.l	markmenufile
		dc.l	chatmenufile
		dc.l	searchmenufile
		dc.l	maintenmenufile
		dc.l	smaintemenufile
		dc.l	miscmenufile
		dc.l	grabformenufile

nomenuinputch	dc.l	readmenu
		dc.l	readmsg
		dc.l	mainmenu
		dc.l	readmenu
		dc.l	readmenu
		dc.l	mainmenu
		dc.l	readmenu
		dc.l	readmenu
		dc.l	readmenu
		dc.l	UQuit
		dc.l	UQuit
		dc.l	mainmenu
		dc.l	grabformatquit

notchoiceschoic	dc.l	0
		dc.l	readmenunotchoices
		dc.l	0
		dc.l	0
		dc.l	0
		dc.l	0
		dc.l	markmenunotchoices
		dc.l	chatmenunotchoices
		dc.l	0
		dc.l	0
		dc.l	0
		dc.l	miscmenunotchoices
		dc.l	0			; grab format menu

godbyechtext	dc.b	'Yes,No,Again.',0
notavailable	dc.b	'N/A',0

globalchtext	dc.b	'?,Help,Goodbye,Read,!,Util,File,Join,Quit,Who,Enter,'
		dc.b	'Bulletin,SHow,COM,GRAB,NOde,TIMe,CHAT,OPEN,MJoin,Xpert,'
		dc.b	'NExt,MISC,MUpload,CB,VErsion.',0
		even
globaljmptable	dc.l	help,dohelp,godbye,readmenu,sysopmenu,utilitymenu
		dc.l	filemenu,join,mainmenu,Whos_on,entermsg
		dc.l	bulletins,showconferences,comment,grab,nodemessage
		dc.l	time,chatmenu,opendoor,multijoin,expertmode,Next
		dc.l	miscmenu,ungrab,_Conference_browser,_ABBS_version

mainmenuchtxt	dc.b	'Show,EDIT,INFO,Answer,',0
		even
mainjmptable	dc.l	_ShowUsers_c,edit,info,answerquestionare

chatmenuchtxt	dc.b	'Avail,Notavail,Sysop,GRoup,',0
		even
chatjmptable	dc.l	SetchatAvail,SetchatNAvail,Chatsysop,Groupchat

searchmenuchtxt	dc.b	'Group,Headers,Marked,',0
		even
searchjmptable	dc.l	searchgroup,searchheaders,searchmarked

readsecretchtxt	dc.b	'Z,USER.',0
		even
readsecrettable	dc.l	changesendrec,getuserinfofrommsg

readmenuchtxt	dc.b	'REply,Orig,.,-,+,>,<,Kill,RECov,MODE,Mark,RESign,'
		dc.b	'=,MOVE,INFO,View,DUP,Search,Dump,SEnd,',0 ;Prev,',0
		even
readjmptable	dc.l	replymsg,originalmsg,readcurrentmsg
		dc.l	previusmsg,nextmsg,readreply,readbackinthread,killmsg
		dc.l	unkillmsg,readmode,markmenu,resignconference,readotherreply
		dc.l	movemsg,readmenyinfo,view,duplicatemessage,searchmenu
		dc.l	dump,sendscratch,recentlyread

utilitymenuchtxt
		dc.b	'Pass,Addr,View,Select,Lines,Tran,Mode,Name,AForm,MFilt,'
		dc.b	'Conf,SPecial,FILT,GFormat,',0
		even
utilityjmptable	dc.l	passwdchange,adresschange,viewsettings,charsetchange
		dc.l	linesprpage,changeprotocol,modechange,namechange
		dc.l	scratchpadformat,messagefilter,confshow,modespecial,filter,grabformatmenu

grabfomenuchtxt	dc.b	'?,Mbbs,Qwk,Hippo,Bulletins.',0
		EVEN
grabforjmptable
		dc.l	help,grabformatmbbs,grabformatqwk,grabformathippo
		dc.l	dosendbulletins

sysopmenuchtxt	dc.b	'Ac,CI,S,T,BI,BC,IF,FI,MOVE,DOS,KILL,UNKILL,MEM,DELCONF,'
		dc.b	'RENCONF,BOOT,D,L,M,DELDIR,RENDIR,ZAP,FT,INV,RESCONF,'
		dc.b	'RENFILE,EJect,EXit,PUS,CLean,CZap,',0
;		dc.b	'PF,PC,
		even
sysopjmptable	dc.l	acceschange,conferenceinstall,showuser,changetimelimit
		dc.l	bulletinstall,clearbulletins,installfiledir,fileinstall
		dc.l	movefile,doscmd,killuser,recoveruser,mem
		dc.l	conferencedelete,conferencerename,boot,deletelogfile
		dc.l	listcallerslog,modifyfile,deletedir,renamedir,zapfile
		dc.l	changefiletimelimit,invite,cleanconference,renamefile
		dc.l	ejectnode,exittodos,packuserfile,cleanuserfile,czapfile
;		dc.l	packfiledirs,packconference

filemenuchtxt	dc.b	'UPload,Down,LPr,Newf,Key,List,Scan,RET,PUpl,Info,View,'
		dc.b	'ADD,ARC,DEL,DIR,EXT,GET,REN,SHOw,TYPe,LPConf,Browse,'
		dc.b	'BUpload,BROwse,',0
		even
filejmptable	dc.l	uploadfile,downloadfile,listprivate,newfiles,keywordsearch
		dc.l	listfiles,scanfiles,retractfile,privateupload,infofiles
		dc.l	viewarchive,addfile,archivehold,deleteholdfile
		dc.l	holddirectory,extract,gethold,renameholdfile,showhold
		dc.l	typeholdfile,listprivatetoconf,togglebrowesemode
		dc.l	batchupload,brosemodeonoff

sigopmenuchtxt	dc.b	'Show,BInst,Access,INVite,Modfile,MOVEfile,',0
		even
sigopjmptable	dc.l	showuser,bulletinstall,acceschange,invite,modifyfile
		dc.l	movefile

markmenuchtxt	dc.b	'Reset,.,Number,Undo,Thread,First,Zap,Onlymine,Author,'
		dc.b	'Personal,Group,Date,Set,USubject,LOGIN,',0
		even
markjmptable	dc.l	markreset,markcurrmsg,markednow,unmarkthread
		dc.l	markthread,minefirst,unmarkauthor,unmarkallbutmine
		dc.l	markfromperson,markmsgstome,markgroup,markmsgafterdate
		dc.l	markset,unmarksubject,marklogin

usermaintachtxt	dc.b	'?,Access,Conf,Find,FTime,Kill,Next,Previous,Quit,SCript,'
		dc.b	'Time,Bytes,Ratio,.,PAssword.',0
		even
usermaijmptable	dc.l	help,Uaccess,Uconf,UFind,UFTime,UKill,UNext,UPrevious
		dc.l	UQuit,USCript,UTime,UBytes,URatio,Udot,UPasswd

susermaintchtxt	dc.b	'?,Access,Conf,Find,Next,Previous,Quit.',0
		even
susermajmptable	dc.l	help,Uaccess,Uconf,UFind2,UNext,UPrevious,UQuit

miscmenuchtxt	dc.b	',',0
		even
miscjmptable	dc.l	mainmenu		; as safety

; locale variables:
localefullname	dc.b	'Fullname',0
localenodenr	dc.b	'Nodenr',0
localetimeleft	dc.b	'Timeleft',0
		even

; JEO stuff


; different taglists

shouserwindowtags
	dc.l	WA_Left,0
	dc.l	WA_Top,60
	dc.l	WA_Width,630
	dc.l	WA_Height,82
	dc.l	WA_IDCMP,IDCMP_CLOSEWINDOW
	dc.l	WA_Flags,WFLG_DRAGBAR!WFLG_DEPTHGADGET!WFLG_CLOSEGADGET!WFLG_SMART_REFRESH!WFLG_GIMMEZEROZERO
;	dc.l	WA_Title,showusertitle
	dc.l	TAG_DONE,0

ibnnortext	dc.b	145,155,134,146,157,143
isonortext	dc.b	'æ','ø','å','Æ','Ø','Å'

		END		; That's all Folks !!!
