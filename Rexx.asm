 *****************************************************************
 *
 * NAME
 *	Rexx.asm
 *
 * DESCRIPTION
 *	Rexx routines for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: rexx.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: rexx.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	include	'exec/memory.i'

	include	'asm.i'
	include	'bbs.i'
	include	'xpr.i'
	include	'fse.i'
	include	'node.i'
	include	'msg.pro'

	XDEF	arexxcomtxt
	XDEF	arexxjmp

	XREF	atoi
	XREF	readchar
	XREF	getline
	XREF	writetext
	XREF	writetexto
	XREF	writetexti
	XREF	strcopymaxlen
	XREF	getaccbittext
	XREF	writechar
	XREF	justchecksysopaccess
	XREF	outimage
	XREF	breakoutimage
	XREF	writecontext
	XREF	writeconchar
	XREF	konverter
	XREF	inputnr
	XREF	typefilemaybeall
	XREF	updatetime
	XREF	changenodestatusnostore
	XREF	getconfunreadmsgs
	XREF	v42bistext
	XREF	mnptext
	XREF	nonetext
	XREF	strcopy
	XREF	strlen
	XREF	throwouttext1
	XREF	throwouttext2
	XREF	parseaccessbitssub
	XREF	saveuserarea
	XREF	stopserread
	XREF	initserread
	XREF	updatewindowtitle
	XREF	readline
	XREF	stengmodem
	XREF	aapnemodem
	XREF	wf_makenodelocal1
	XREF	tmpcloseserport
	XREF	tmpopenserport
	XREF	preskreopentext
	XREF	initwaitforcaller1

	section	rexx,code

; Arexx kommandoene
; de skal returnere :
; a0 - retur string til arexx programmet, 0 for ingen
; d0 - retur verdi til arexx programmet (RC)
; d1 - retur verdi til amiga procedyren (hvis vi skal dit)
; z = 1 - hopp ut av readchar
rexx_getloginscript
	push	a2/a3/d2/d3
	moveq.l	#10,d2				; error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi parametre ?
	beq	1$				; nope. current user.
	moveq.l	#15,d2
	move.l	(rx_ptr1,a0),a0			; navnet
	lea	(tmptext,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)
	bsr	getuserstruct
	beq.b	9$
	move.l	a0,a2				; user struct
	lea	(tmptext,NodeBase),a1
	exg	a1,a0
	jsr	(loaduser)
	bne.b	9$
	lea	(UserScript,a2),a0		; string vi skal ha
	lea	(tmptext,NodeBase),a1
	bsr	strcopy
	move.l	a2,a0
	bsr	freeuserstruct
	bra.b	2$

1$	moveq.l	#5,d2
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	lea	(UserScript+CU,NodeBase),a0	; string å lese fra
	lea	(tmptext,NodeBase),a1
	bsr	strcopy
2$	moveq.l	#0,d2

9$	move.l	d2,d0
	lea	(tmptext,NodeBase),a0
	clrz
	pop	a2/a3/d2/d3
	rts

rexx_setloginscript
	push	a2/a3/d2/d3
	moveq.l	#10,d2				; error
	suba.l	a2,a2
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi parametre ?
	beq	9$				; nope.
	lea	(UserScript+CU,NodeBase),a3	; string å lagre i
	moveq.l	#15,d2
	subq.l	#1,d0
	beq.b	1$				; bare 1 param, current user
	move.l	(rx_ptr2,a0),a0			; navnet
	lea	(tmptext,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)
	bsr	getuserstruct
	beq.b	9$
	move.l	a0,a2				; user struct
	lea	(tmptext,NodeBase),a1
	exg	a1,a0
	jsr	(loaduser)
	lea	(UserScript,a2),a3		; string å lagre i
	bmi.b	9$
	lea	(tmplargestore,NodeBase),a0
	bra.b	2$
1$	moveq.l	#5,d2
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
2$	moveq.l	#10,d2				; for lang/kort
	move.l	(rx_ptr1,a0),d3			; henter parameter.
	move.l	d3,a0
	jsr	strlen				; finner lengden.
	beq.b	9$				; tom...
	cmp.w	#Sizeof_loginscript-1,d0
	bhi.b	9$				; for lang
	move.l	d3,a0
	move.l	a3,a1
	jsr	(strcopy)			; lagrer
	moveq.l	#15,d2
	move.l	a2,d0				; har vi bruker ?
	bne.b	3$				; jepp.
	move.l	a3,a0				; lagrer denne forandringen
	moveq.l	#Sizeof_loginscript,d0
	jsr	(saveuserarea)
	beq.b	9$
	bra.b	8$
3$	move.l	a2,a0
	move.l	(Usernr,a0),d0
	jsr	(saveusernr)
	beq.b	9$
8$	moveq.l	#0,d2				; RC = 0
9$	move.l	a2,a0
	move.l	a2,d0				; har vi user struct ?
	beq.b	91$				; nope
	bsr	freeuserstruct			; Ja, frigi
91$	move.l	d2,d0
	suba.l	a0,a0				; ingen retur sting
	clrz
	pop	a2/a3/d2/d3
	rts

rexx_getnextparam
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	moveq.l	#1,d0
	tst.b	(readlinemore,NodeBase)		; er det mere input ?
	beq.b	9$				; nei, ingen parametre..
	jsr	(readline)
	beq.b	1$
	moveq.l	#0,d0
	bra.b	99$
1$	moveq.l	#20,d0
9$	suba.l	a0,a0				; ingen return string
99$	clrz
	rts

rexx_listen
	push	d2
	moveq.l	#10,d2
	move.b	(RealCommsPort,NodeBase),d0		; Setter tilbake comport
	beq	9$					; har ingen
	move.b	#-1,d1
	cmp.b	d0,d1
	beq	9$					; har aldri hatt
	moveq.l	#0,d2					; ok.
	bclr	#DoDivB_Sleep,(DoDiv,NodeBase)		; slett sleep
	jsr	(updatewindowtitle)
	move.b	(RealCommsPort,NodeBase),d0
	cmp.b	(CommsPort+Nodemem,NodeBase),d0		; ble den disablet ?
	beq.b	9$					; nei, ikke start igjen
	move.b	d0,(CommsPort+Nodemem,NodeBase)
	bsr	initserread				; starter opp en read request
9$	suba.l	a0,a0
	move.l	d2,d0
	pop	d2
	clrz
	rts

rexx_unlisten
	moveq.l	#10,d0
	move.b	(CommsPort+Nodemem,NodeBase),d1		; Er det en serial node ?
	beq.b	9$					; nope, error
	moveq.l	#5,d0					; error, user online
	move.b	(in_waitforcaller,NodeBase),d0
	beq.b	9$
	move.b	#0,(CommsPort+Nodemem,NodeBase)		; Gjør noden lokal.
	bset	#DoDivB_Sleep,(DoDiv,NodeBase)		; sett sleep
	jsr	(updatewindowtitle)
	bsr	stopserread				; avbryter read req'en
	moveq.l	#0,d0					; ok
9$	suba.l	a0,a0
	clrz
	rts

rexx_login
	moveq.l	#5,d0
	suba.l	a0,a0
	clrz
	rts

rexx_readbits
	push	d2/a2
	suba.l	a2,a2
	moveq.l	#20,d2
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d0		; har vi parameter ?
	beq.b	1$				; nei, tar current user
	move.l	(rx_ptr1,a0),a0
	lea	(tmptext,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)
	bsr	getuserstruct
	beq.b	9$
	move.l	a0,a2
	lea	(tmptext,NodeBase),a1
	exg	a1,a0
	jsr	(loaduser)
	beq.b	2$				; alt ok
	bmi.b	9$
	move.l	#10,d0				; user not found
	bra.b	9$
2$	lea	(u_almostendsave,a2),a0
	move.w	(uc_Access,a0),d0
	bra.b	3$
1$	moveq.l	#5,d2
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(uc_Access,a0),d0
3$	lea	(tmptext,NodeBase),a0
	jsr	(getaccbittext)
	moveq.l	#0,d2
9$	exg	a2,a0
	bsr	freeuserstruct
	move.l	a2,a0
	move.l	d2,d0
	pop	d2/a2
	clrz
	rts

getuserstruct
	move.l	(UserrecordSize+CStr,MainBase),d0
	moveq.l	#MEMF_PUBLIC,d1
	jsrlib	AllocVec
	move.l	d0,a0
	tst.l	d0
	rts

freeuserstruct
	move.l	a0,d0
	beq.b	9$
	move.l	a0,a1
	jsrlib	FreeVec
9$	rts

rexx_setbits
	push	d2/a2/a3/d7
	suba.l	a2,a2
	moveq.l	#11,d2
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d0		; har vi parameter ?
	beq	91$				; nei, error
	moveq.l	#20,d2
	subq.l	#1,d0
	beq.b	1$				; bare 1 param, current user
	move.l	(rx_ptr2,a0),a0			; navnet
	lea	(tmptext,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)
	bsr	getuserstruct
	beq.b	9$
	move.l	a0,a2
	lea	(tmptext,NodeBase),a1
	exg	a1,a0
	jsr	(loaduser)
	lea	(u_almostendsave,a2),a3
	beq.b	2$				; alt ok
	bmi.b	9$
	move.l	#10,d0				; user not found
	bra.b	9$
1$	moveq.l	#5,d2
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	lea	(u_almostendsave+CU,NodeBase),a3 ; a3 er nå word'et som skal forandres
2$	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_ptr1,a0),a0
	moveq.l	#1,d0				; ikke sjekk sigop/sysop
	moveq.l	#0,d7
	move.l	#15,d2				; unknown bits
	jsr	(parseaccessbitssub)
	beq.b	9$
	and.b	#ACCF_Read|ACCF_Write|ACCF_Upload|ACCF_Download|ACCF_FileVIP|ACCF_Sigop,d7
	move.w	(a3),d0
	and.w	#ACCF_Invited|ACCF_Sysop,d0
	or.w	d0,d7
	move.w	d7,(a3)
	move.l	#20,d2				; error
	move.l	a2,d0
	beq.b	3$				; vi har ikke bruker
	move.l	a2,a0
	move.l	(Usernr,a0),d0
	jsr	(saveusernr)
	beq.b	9$
	bra.b	8$
3$	move.l	a3,a0				; lagrer denne forandringen
	move.b	#2,d0				; bare 1 word..
	jsr	(saveuserarea)
	beq.b	9$
8$	moveq.l	#0,d2				; alt ok
9$	exg	a2,a0
	bsr	freeuserstruct
	move.l	a2,a0
91$	move.l	d2,d0
	pop	d2/a2/a3/d7
	clrz
	rts

rexx_sigop
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	jsr	(justchecksysopaccess)
	bne.b	1$
	lea	(u_almostendsave+CU,NodeBase),a0
	move.w	(confnr,NodeBase),d0
	cmp.w	#-1,d0
	bne.b	2$
	moveq.l	#0,d0
2$	mulu	#Userconf_seizeof/2,d0
	move.w	(uc_Access,a0,d0.l),d0
	btst	#ACCB_Sigop,d0			; har bruker sigop access ??
	bne.b	1$				; ja
	moveq.l	#0,d0				; ingen access
	bra.b	9$
1$	moveq.l	#1,d0				; sysop access
9$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_sysop
	moveq.l	#5,d0				; ERROR
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	jsr	(justchecksysopaccess)
	bne.b	1$
	moveq.l	#0,d0				; ingen access
	bra.b	9$
1$	moveq.l	#1,d0				; sysop access
9$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_setstatustext
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	bne.b	1$				; Ja..
	move.w	(PrevNodestatus,NodeBase),d0
	move.l	(PrevNodesubStatus,NodeBase),d1
	bra.b	2$
1$	move.l	(rx_ptr1,a0),a0
	lea	(tmpnodestatustext,NodeBase),a1
	moveq.l	#23,d0
	jsr	(strcopymaxlen)
	lea	(tmpnodestatustext,NodeBase),a1
	move.l	a1,d1
	moveq.l	#68,d0
2$	jsr	(changenodestatusnostore)
	moveq.l	#0,d0				; RC = 0
	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_sysopname
	lea	(SYSOPname+CStr,MainBase),a0
	moveq.l	#0,d0
	clrz
	rts

rexx_bbsname
	lea	(BaseName+CStr,MainBase),a0
	moveq.l	#0,d0
	clrz
	rts

rexx_unread
	suba.l	a0,a0				; ingen return string (enda)
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	moveq.l	#0,d0				; conf = 0
	jsr	(getconfunreadmsgs)
	lea	(tmptext,NodeBase),a0
	jsr	konverter
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
9$	clrz
	rts

rexx_getconstat
	push	a2
	move.l	(nodenoden,NodeBase),a2
	lea	(tmptext,NodeBase),a0
	move.l	(Nodespeed,a2),d0
	jsr	(konverter)
	move.l	a0,a1
	move.b	#' ',(a1)+
	move.b	(NodeECstatus,a2),d1
	lea	(v42bistext),a0
	btst	#NECSB_V42BIS,d1
	bne.b	1$
	lea	(mnptext),a0
	btst	#NECSB_MNP,d1
	bne.b	1$
	lea	nulltext,a0
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0		; Nullmodem ?
	bne.b	1$				; Ja, da sier vi det
	lea	(nonetext),a0
1$	jsr	(strcopy)
	lea	(tmptext,NodeBase),a0		; ret string
	moveq.l	#0,d0
	pop	a2
	clrz
	rts

rexx_usersetup
	push	d2
	moveq.l	#5,d2				; setter opp feiltid error
	btst	#DIVB_InNewuser,(Divmodes,NodeBase)
	beq	9$				; ikke fra newuser.abbs
	moveq.l	#10,d2				; setter opp for param error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	beq	9$				; nope.
	move.l	(rx_ptr1,a0),a0
	jsr	(atoi)
	bmi.b	9$				; Ikke tall
	swap	d0				; format : cppstdd
	moveq.l	#0,d1				; c  = charset
	move.b	d0,d1				; pp = pagelen
	move.w	d1,(PageLength+CU,NodeBase)	; s  = scratchpadformat
	lsr.w	#8,d0				; t  = transferprotocol
	and.b	#$f,d0				; dd = div bits
	cmp.b	#12,d0
	bls.b	4$
	move.b	#0,d0
4$	move.b	d0,(Charset+CU,NodeBase)
	swap	d0
	move.w	(Savebits+CU,NodeBase),d1
	bclr	#SAVEBITSB_ReadRef,d1
	btst	#7,d0
	beq.b	1$
	bset	#SAVEBITSB_ReadRef,d1
1$	move.w	d1,(Savebits+CU,NodeBase)
	asl.b	#1,d0
	move.b	d0,d1
	asl.w	#1,d1
	and.b	#%00011110,d0
	and.w	#%111000000,d1
	or.b	d0,d1
	move.w	d1,(Userbits+CU,NodeBase)
	lsr.w	#8,d0
	move.b	d0,d1
	lsr.w	#4,d0
	and.b	#$f,d1
	and.b	#$f,d0
	cmp.b	#7,d0
	bls.b	2$
	move.b	#0,d0
2$	move.b	d0,(ScratchFormat+CU,NodeBase)
	cmp.b	#6,d0
	bls.b	3$
	move.b	#0,d0
3$	move.b	d1,(Protocol+CU,NodeBase)
	moveq.l	#0,d2
9$	suba.l	a0,a0				; ingen return string
	move.l	d2,d0
	pop	d2
	clrz
	rts

rexx_readusersetup
	push	d2
	suba.l	a0,a0				; ingen return string (enda)
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	move.b	(Charset+CU,NodeBase),d0
	and.b	#$f,d0				; nå er bits 32-24 ok, bare på feil plass
	lsl.l	#8,d0
	move.w	(PageLength+CU,NodeBase),d1
	or.b	d1,d0				; 32-16 ok (feil plass)
	lsl.l	#8,d0
	move.b	(ScratchFormat+CU,NodeBase),d1
	and.b	#$f,d1
	lsl.w	#4,d1
	move.b	(Protocol+CU,NodeBase),d0
	and.b	#$f,d0
	or.b	d1,d0				; 32-8
	lsl.l	#8,d0
	move.w	(Savebits+CU,NodeBase),d1
	btst	#SAVEBITSB_ReadRef,d1
	beq.b	1$
	bset	#7,d0
1$	move.w	(Userbits+CU,NodeBase),d2
	move.w	d2,d1
	lsr.w	#2,d1
	and.b	#%1110000,d1
	lsr.b	#1,d2
	and.b	#%00001111,d2
	or.b	d2,d0
	or.b	d1,d0
	lea	(tmptext,NodeBase),a0
	jsr	(konverter)
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
9$	pop	d2
	clrz
	rts

rexx_userinfo
	suba.l	a0,a0				; ingen return string (enda)
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	lea	(tmptext,NodeBase),a0
	move.w	(TimesOn+CU,NodeBase),d0
	bsr.b	userfileinfocommon
	move.w	(MsgsLeft+CU,NodeBase),d0
	bsr.b	userfileinfocommon
	move.l	(MsgsRead+CU,NodeBase),d0
	bsr.b	userfileinfocommon1
	move.l	(MsgaGrab+CU,NodeBase),d0
	bsr.b	userfileinfocommon1
	move.l	(ResymeMsgNr+CU,NodeBase),d0
	bsr.b	userfileinfocommon1
	move.b	#0,-1(a0)
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
9$	clrz
	rts

userfileinfocommon
	andi.l	#$ffff,d0
userfileinfocommon1
	jsr	konverter
	move.b	#' ',(a0)+
	rts

rexx_fileinfo
	suba.l	a0,a0				; ingen return string (enda)
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	lea	(tmptext,NodeBase),a0
	move.w	(Downloaded+CU,NodeBase),d0
	bsr.b	userfileinfocommon
	move.w	(Uploaded+CU,NodeBase),d0
	bsr.b	userfileinfocommon
	move.l	(KbDownloaded+CU,NodeBase),d0
	bsr.b	userfileinfocommon1
	move.l	(KbUploaded+CU,NodeBase),d0
	bsr.b	userfileinfocommon1
	move.b	#0,-1(a0)
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
9$	clrz
	rts

rexx_raw
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	beq.b	1$				; nope.
	move.b	#0,(FSEditor,NodeBase)		; slår på dekoding av tastene
	bra.b	2$
1$	move.b	#1,(FSEditor,NodeBase)		; slår av dekoding av tastene
2$	moveq.l	#0,d0				; RC = 0
9$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_eject
	moveq.l	#5,d0				; setter warning, hvis det ikke er noen der
	move.l	(Name+CU,NodeBase),d1		; eject. Men er det noen inne ?
	notz
	bne.b	9$				; nei ... Da dropper vi saken..
	move.w	#-1,(linesleft,NodeBase)		; Dropper all more saker ..
	lea	(throwouttext1),a0
	jsr	(writetexti)
	lea	(throwouttext2),a0
	jsr	(writetexti)
	move.b	#Thrownout,(readcharstatus,NodeBase)
	moveq.l	#0,d0				; RC = 0
9$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_quick
	moveq.l	#5,d0				; setter warning, just in case
	move.l	(Name+CU,NodeBase),d1		; Men er det noen inne ?
	beq.b	9$				; nei ... Da dropper vi saken..
	moveq.l	#1,d0				; setter quick = 1
	btst	#DIVB_QuickMode,(Divmodes,NodeBase)
	bne.b	9$
	moveq.l	#0,d0				; RC = 0, ikke quick
9$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_resume
	moveq.l	#5,d0				; setter warning, i tilfelle feil
	move.b	(in_waitforcaller,NodeBase),d1	; er vi i waitforcaller ?
	notz
	bne.b	9$				; nope
	moveq.l	#10,d0
	move.b	(RealCommsPort,NodeBase),d1
	beq	9$			; ingen port
	cmp.b	#-1,d1
	beq.b	9$			; ingen port..
	moveq.l	#5,d0
	move.l	(sreadreq,NodeBase),a1
	move.l	(IO_DEVICE,a1),d1
	bne.b	9$			; vi har porten..

	jsr	tmpopenserport
	cmpi.b	#-1,(RealCommsPort,NodeBase)	; gikk det bra ?
	bne.b	4$				; jepp
	move.b	(CommsPort+Nodemem,NodeBase),d0	; Vi prøver en gang til.
	move.b	d0,(RealCommsPort,NodeBase)
	moveq.l	#10,d0
	bra.b	9$				; og ut.
4$	move.b	(RealCommsPort,NodeBase),(CommsPort+Nodemem,NodeBase)		; setter tilbake
	bsr	aapnemodem
	bsr	initwaitforcaller1
	moveq.l	#0,d0				; (RC = 0)
9$	clrzn					; for sikkerhets skyld.
	suba.l	a0,a0				; ingen return string
	rts

rexx_shutdown
	moveq.l	#5,d0				; setter warning, i tilfelle feil
	move.b	#1,(ShutdownNode,NodeBase)	; markerer at vi skal ned
	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	notz
	bne.b	9$				; nope
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d0		; har vi 1 parameter ?
	bne.b	1$				; ja, dvs, nobusy 
	jsr	(stengmodem)
1$	bset	#DoDivB_ExitWaitforCaller,(DoDiv,NodeBase) ; vi shal ut

; denne gir RC 20...
;	move.b	#Thrownout,(readcharstatus,NodeBase)	; for sikkerhet skyld
	moveq.l	#0,d0				; (RC = 0)
	clrn
	setz
9$	suba.l	a0,a0				; ingen return string
	rts

rexx_suspend
	moveq.l	#5,d0				; setter warning, i tilfelle feil
	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	beq.b	9$				; nope
	moveq.l	#10,d0				; setter error, i tilfelle feil
	move.b	(CommsPort+Nodemem,NodeBase),d0	; er vi serielle ?
	beq.b	9$				; nope.
	lea	(tmplargestore,NodeBase),a0
	moveq.l	#0,d0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	bne.b	2$				; nope, dvs nobusy
	moveq.l	#1,d0				; busy.
2$	bsr	wf_makenodelocal1		; jepp, dvs nobusy
;	beq.b	9$				; lokal node, ut. Umulig
	jsr	(tmpcloseserport)
	tst.b	(Tinymode,NodeBase)
	bne.b	1$
	lea	(preskreopentext),a0
	bsr	writecontext
1$	moveq.l	#0,d0				; RC = 0
9$	clrzn
	suba.l	a0,a0				; ingen return string
	rts

rexx_nomore
	move.w	#-1,(linesleft,NodeBase)		; Vi vil ikke ha noen more mere..
	suba.l	a0,a0
	moveq.l	#0,d0				; alltid ok.
	clrz
	rts

rexx_more
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase) ; Ny side..
	suba.l	a0,a0
	moveq.l	#0,d0				; alltid ok.
	clrz
	rts

rexx_username
	btst	#DIVB_InNewuser,(Divmodes,NodeBase)
	bne.b	1$				; i newuser.abbs Da er navnet fyllt ut
	moveq.l	#5,d0
	suba.l	a0,a0
	move.b	(userok,NodeBase),d1
	beq.b	9$
1$	lea	(Name+CU,NodeBase),a0
	moveq.l	#0,d0
9$	clrz
	rts

rexx_timeleft
	moveq.l	#5,d0
	move.b	(userok,NodeBase),d1
	beq.b	9$
	jsr	(updatetime)
	moveq.l	#0,d0
	move.w	(TimeLimit+CU,NodeBase),d0
	sub.w	(TimeUsed+CU,NodeBase),d0
	bcc.b	1$
	moveq.l	#0,d0
1$	lea	(tmptext,NodeBase),a0
	jsr	(konverter)
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
9$	clrz
	rts

rexx_outimage
	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	bne.b	1$				; ja, da tar vi til con..
	jsr	(outimage)
	bne.b	2$
	moveq.l	#20,d0				; noe gikk galt
	tst.b	(readcharstatus,NodeBase)
	bne.b	3$
	moveq.l	#1,d0				; ikke så ille, bare more-nei
	bra.b	3$
1$	move.b	#10,d0
	jsr	(writeconchar)
2$	moveq.l	#0,d0				; RC = 0
3$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_breakoutimage
	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	bne.b	1$				; ja, da er dette en nop
	jsr	(breakoutimage)
1$	moveq.l	#0,d0				; RC = 0
	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_writechar
	moveq.l	#10,d0				; error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	beq.b	9$				; nope.
	move.l	(rx_ptr1,a0),a0
	move.b	(a0),d0
	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	bne.b	1$				; ja, da tar vi til con..
	jsr	(writechar)
	bra.b	2$
1$	jsr	(writeconchar)
2$	moveq.l	#0,d0				; RC = 0
9$	suba.l	a0,a0				; ingen return string
	clrz
	rts

rexx_writetext
	push	a2/d2
	moveq.l	#10,d0				; error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	beq.b	9$				; nope.
	move.l	(rx_ptr1,a0),a2

0$	move.l	a2,a0
	moveq.l	#79,d1
	suba.l	a1,a1				; ingen esc enda
1$	move.b	(a0)+,d0
	beq.b	5$
	subq.l	#1,d1
	beq.b	2$
	cmp.b	#$1b,d0				; esc?
	bne.b	1$
	lea	(-1,a0),a1			; siste ESC pos
	bra.b	1$

2$	move.l	a1,d0				; for lang. Må kutte ned
	tst.l	d0
	beq.b	3$				; vi har ikke esc
	sub.l	a2,d0
	cmp.w	#65,d0				; under 15 tegn fra slutten ?
	bcs.b	3$				; nei, da sier vi at vi ikke hadde esc
	move.l	a1,a0				; da skal vi terminere herfra
3$	move.b	(a0),d2				; husker tegnet
	move.b	#0,(a0)				; og terminerer
	exg	a0,a2				; husker hvor vi er, og finner frem starten
	bsr	10$
;	jsr	(breakoutimage)			; og skriver ut...
	move.b	d2,(a2)				; setter tilbake tegnet
	bra.b	0$

5$	move.l	a2,a0
	bsr	10$				; skriver ut
	moveq.l	#0,d0				; RC = 0
9$	suba.l	a0,a0				; ingen retur sting
	clrz
	pop	a2/d2
	rts

10$	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	bne.b	11$				; ja, da tar vi til con..
	jmp	(writetext)
11$	jmp	(writecontext)


rexx_nodenumber
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	lea	(tmptext,NodeBase),a0
	jsr	(konverter)
	lea	(tmptext,NodeBase),a0		; result string
	moveq.l	#0,d0				; RC = 0
	clrz
	rts

rexx_maygetchar
0$	move.l	(creadreq,NodeBase),d0
	beq.b	3$				; no console
	move.l	d0,a1
	jsrlib	CheckIO
	tst.l	d0
	bne.b	1$				; Ja, vi har et tegn
3$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Skal denne noden være serial ?
	beq.b	2$				; nei. Ikke noe tegn
	move.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	2$				; vi har ikke et tegn
	ELSE
	bra.b	2$
	ENDC
1$	jsr	(readchar)
	bmi.b	0$				; ikke spes tegn
	lea	(tmpword,NodeBase),a0		; result string
	move.b	d0,(a0)
	move.b	#0,(1,a0)
	moveq.l	#0,d0				; ikke noe galt har skjedd
	tst.b	(readcharstatus,NodeBase)	; Har det skjedd noe ?
	beq.b	9$				; nope
	moveq.l	#20,d0				; return error
	bra.b	9$
2$	moveq.l	#1,d0				; ikke noe tegn klart
	suba.l	a0,a0				; ingen string
9$	clrz
	rts

rexx_readchar
1$	jsr	(readchar)
	bmi.b	1$				; ingen spesialtegn
	lea	(tmptext,NodeBase),a0		; result string
	move.b	d0,(a0)
	move.b	#0,(1,a0)
	moveq.l	#0,d0				; ikke noe galt har skjedd
	tst.b	(readcharstatus,NodeBase)	; Har det skjedd noe ?
	beq.b	9$				; nope
	moveq.l	#20,d0				; return error
9$	clrz
	rts

rexx_getline
	moveq.l	#10,d0				; setter opp for error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	beq.b	9$				; nope.
	move.l	(rx_ptr1,a0),a0
	jsr	(inputnr)
	bne.b	1$
	moveq.l	#10,d0				; Ikke tall
	bra.b	9$
1$	jsr	(getline)
	moveq.l	#0,d0
	tst.b	(readcharstatus,NodeBase)	; har noe skjedd ?
	beq	9$				; nope. alt ok
	moveq.l	#20,d0				; return error
9$	clrz
	rts

rexx_typefile
	moveq.l	#10,d0				; error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi 1 parameter ?
	beq.b	9$				; nope.
	move.l	(rx_ptr1,a0),a0
	moveq.l	#0,d0				; både ser og con
	tst.b	(in_waitforcaller,NodeBase)	; er vi i waitforcaller ?
	beq.b	1$				; nei
	moveq.l	#1,d0				; ja, da tar vi til con..
1$	jsr	(typefilemaybeall)
	bne.b	2$
	moveq.l	#1,d0				; bare break
	move.b	(readcharstatus,NodeBase),d1
	beq.b	9$
	moveq.l	#20,d0				; noe alvorlig
	bra.b	9$
2$	moveq.l	#0,d0				; RC = 0
9$	suba.l	a0,a0
	clrz
	rts


;JEO
; Arexx kommandoene
; de skal returnere :
; a0 - retur string til arexx programmet, 0 for ingen
; d0 - retur verdi til arexx programmet (RC)
; d1 - retur verdi til amiga procedyren (hvis vi skal dit)
; z = 1 - hopp ut av readchar
rexx_laston
	push	a2/a3/d2/d3
	moveq.l	#10,d2				; error
	lea	(tmplargestore,NodeBase),a0
	move.l	(rx_NumParam,a0),d1		; har vi parametre ?
	beq	1$				; nope. current user.
	moveq.l	#15,d2
	move.l	(rx_ptr1,a0),a0			; navnet
	lea	(tmptext,NodeBase),a1
	moveq.l	#Sizeof_NameT,d0
	jsr	(strcopymaxlen)
	bsr	getuserstruct
	beq.b	9$
	move.l	a0,a2				; user struct
	lea	(tmptext,NodeBase),a1
	exg	a1,a0
	jsr	(loaduser)
	bne.b	9$
	lea	(UserScript,a2),a0		; string vi skal ha
	lea	(tmptext,NodeBase),a1
	bsr	strcopy
	move.l	a2,a0
	bsr	freeuserstruct
	bra.b	2$

1$	moveq.l	#5,d2
	move.b	(userok,NodeBase),d1
	beq.b	9$				; ingen inne
	lea	(LastAccess+CU,NodeBase),a0	; string å lese fra
	lea	(tmptext,NodeBase),a1
	bsr	strcopy
2$	moveq.l	#0,d2

9$	move.l	d2,d0
	lea	(tmptext,NodeBase),a0
	clrz
	pop	a2/a3/d2/d3
	rts

arexxcomtxt	dc.b	'BBSNAME,BREAKOUTIMAGE,EJECT,FILEINFO,GETCONSTAT,GETLINE,'
		dc.b	'GETLOGINSCRIPT,GETNEXTPARAM,LISTEN,'
		dc.b	'LOGIN,MAYGETCHAR,MORE,NODENUMBER,NOMORE,'
		dc.b	'OUTIMAGE,QUICK,RAW,READBITS,READCHAR,READUSERSETUP,'
		dc.b	'RESUME,SETLOGINSCRIPT,'
		dc.b	'SETBITS,SETSTATUSTEXT,SHUTDOWN,SIGOP,SUSPEND,SYSOP,SYSOPNAME,'
		dc.b	'TIMELEFT,TYPEFILE,UNLISTEN,UNREAD,USERINFO,'
		dc.b	'USERNAME,'
		dc.b	'USERSETUP,'
		dc.b	'WRITECHAR,WRITETEXT,'
		dc.b	'LASTON',0

nulltext	dc.b	'NULL',0
		even
arexxjmp	dc.l	rexx_bbsname,rexx_breakoutimage,rexx_eject,rexx_fileinfo,rexx_getconstat
		dc.l	rexx_getline,rexx_getloginscript,rexx_getnextparam,rexx_listen
		dc.l	rexx_login,rexx_maygetchar,rexx_more
		dc.l	rexx_nodenumber,rexx_nomore,rexx_outimage,rexx_quick
		dc.l	rexx_raw,rexx_readbits
		dc.l	rexx_readchar,rexx_readusersetup,rexx_resume
		dc.l	rexx_setloginscript,rexx_setbits
		dc.l	rexx_setstatustext,rexx_shutdown
		dc.l	rexx_sigop,rexx_suspend,rexx_sysop,rexx_sysopname
		dc.l	rexx_timeleft,rexx_typefile,rexx_unlisten,rexx_unread
		dc.l	rexx_userinfo,rexx_username,rexx_usersetup
		dc.l	rexx_writechar,rexx_writetext
		dc.l	rexx_laston
	END
