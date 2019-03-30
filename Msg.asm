 *****************************************************************
 *
 * NAME
 *	Msg.asm
 *
 * DESCRIPTION
 *	Misc msg routines for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: Msg.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: Msg.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'

;	IFND	__M68
	include	'exec/types.i'
	include	'intuition/intuition.i'
;	ENDC
	include	'asm.i'
	include	'bbs.i'
	include	'fse.i'
	include	'node.i'

	XDEF	savemsgheader
	XDEF	loadmsgheader
	XDEF	loadmsgtext
	XDEF	loadmsg
	XDEF	savemsg
	XDEF	sendintermsg
	XDEF	doallusers
	XDEF	handlemsg
	XDEF	handlemsgspesport
	XDEF	sendmsgspesport
	XDEF	getnamenrmatch
	XDEF	getusernumber
	XDEF	loadusernrnr
	XDEF	saveusernrnr
	XDEF	loadusernr
	XDEF	saveusernr
	XDEF	loaduser
	XDEF	saveuser
	XDEF	saveconfig
	XDEF	lockoutallothernodes
	XDEF	unlockoutallothernodes
	XDEF	askopenscreen
	XDEF	askclosescreen
	XDEF	checkformsgerror
	XDEF	@clearmsgerror

	XREF	mainmsgport
	XREF	getname
	XREF	writetexto
	XREF	writeerroro
	XREF	strcopy
	XREF	usernotfountext
	XREF	scanuserregtext
	XREF	nodelist
	XREF	publicportname
	XREF	fillinnodenr

; ret: z = 1, ok
askopenscreen
	movea.l	(msg,NodeBase),a1
	move.w	#Main_OpenScreen,(m_Command,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	rts

askclosescreen
	movea.l	(msg,NodeBase),a1
	move.w	#Main_CloseScreen,(m_Command,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	rts

lockoutallothernodes
	push	a2/d2
	move.l	nodelist+LH_HEAD,a2	; finner ut om alle er logget ut (untatt vår)
	move.w	(NodeNumber,NodeBase),d2; henter vår node nummer
1$	move.w	(Nodenr,a2),d0
	beq.b	2$			; Hopper over noder som er nede
	cmp.b	d2,d0			; vår node ?
	beq.b	2$			; jepp, hopper over den.
	move.w	(Nodestatus,a2),d0	; henter nodestatusen
	notz
	beq.b	9$			; alle må ha 0, dvs logg'et av
2$	move.l	(LN_SUCC,a2),a2		; Henter ptr til nestenode
	move.l	(LN_SUCC,a2),d0
	bne.b	1$			; flere noder. Same prosedure as last year
; kommer vi hit, er alle nodene "log'ed ut, bortsett fra vår

; går igjennom en gang til, for å sende melding om at de skal være "døde"
	move.l	nodelist+LH_HEAD,a2
3$	move.w	(Nodenr,a2),d0
	beq.b	4$			; Hopper over noder som er nede
	cmp.b	d2,d0			; vår node ?
	beq.b	4$			; jepp, hopper over den.

	lea	(tmptext,NodeBase),a1	; ber noden sove
	lea	publicportname,a0
	jsr	(fillinnodenr)		; bygger opp navnet til porten
	movea.l	(msg,NodeBase),a1
	move.w	#Node_Gotosleep,(m_Command,a1)
	lea	(tmptext,NodeBase),a0
	bsr	handlemsgspesport
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmp.w	#Error_OK,d0
	beq.b	4$			; ok
	bsr.b	unlockoutallothernodes	; noe gikk galt.. Vekker alle igjen
	setz
	bra.b	9$
4$	move.l	(LN_SUCC,a2),a2		; Henter ptr til nestenode
	move.l	(LN_SUCC,a2),d0
	bne.b	3$			; flere noder. Same prosedure as last year
	clrz
9$	pop	a2/d2
	rts

unlockoutallothernodes
	push	a2/d2
	move.w	(NodeNumber,NodeBase),d2; henter vår node nummer
	move.l	nodelist+LH_HEAD,a2
1$	move.w	(Nodenr,a2),d0
	beq.b	2$			; Hopper over noder som er nede
	cmp.b	d2,d0			; vår node ?
	beq.b	2$			; jepp, hopper over den.

	lea	(tmptext,NodeBase),a1	; ber noden våkne
	lea	publicportname,a0
	jsr	(fillinnodenr)		; bygger opp navnet til porten
	movea.l	(msg,NodeBase),a1
	move.w	#Node_Wakeupagain,(m_Command,a1)
	lea	(tmptext,NodeBase),a0
	bsr	handlemsgspesport

2$	move.l	(LN_SUCC,a2),a2		; Henter ptr til nestenode
	move.l	(LN_SUCC,a2),d0
	bne.b	1$			; flere noder. Same prosedure as last year
	pop	a2/d2
	rts

;Error = savemsgheader(msgeader,confnr *2)
;d0.w/Zero bit		a0	d0.w
savemsgheader
	movea.l	(msg,NodeBase),a1
	move.w	#Main_savemsgheader,(m_Command,a1)
	move.l	a0,(m_Data,a1)
	moveq.l	#0,d1
	move.w	d0,d1
	move.l	d1,(m_UserNr,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	rts

; loadmsgheader (msgheaderbuf,msgnr,confnr (* 2!))
;		 a0.l	      d0.l  d1.w
loadmsgheader
	movea.l	(msg,NodeBase),a1
	move.w	#Main_loadmsgheader,(m_Command,a1)
	move.l	a0,(m_Data,a1)
	subq.l	#1,d0
	move.l	d0,(m_UserNr,a1)
	move.w	d1,(m_Error,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	rts

; loadmsgtext (msgtextbuf,msgheader,confnr)
;		a0.l	  a1.l	    d0.w
loadmsgtext
	move.l	a1,-(sp)
	movea.l	(msg,NodeBase),a1
	move.w	#Main_loadmsgtext,(m_Command,a1)
	move.l	(msgmemsize,NodeBase),(a0)		; Legger inn størrelsen.
	move.l	a0,(m_Data,a1)
	move.l	(sp)+,(m_Name,a1)
	andi.l	#$ffff,d0
	move.l	d0,(m_UserNr,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	rts

; loadmsg (msgtextbuf,msgheaderbuf,msgnr,confnr)
;	   a0.l	      a1.l	   d0.l	 d1.w
loadmsg	push	a2
	move.l	a1,a2
	movea.l	(msg,NodeBase),a1
	move.w	#Main_loadmsg,(m_Command,a1)
	move.l	(msgmemsize,NodeBase),(a0)		; Legger inn størrelsen.
	move.l	a0,(m_Data,a1)
	exg.l	a2,a0
	move.l	a0,(m_Name,a1)
	subq.l	#1,d0
	move.l	d0,(m_UserNr,a1)
	move.w	d1,(m_Error,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.l	(msgmemsize,NodeBase),d0		
	move.b	#0,(-1,a2,d0.l)				; terminerer melding
	moveq.l	#0,d0
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	pop	a2
	rts

; savemsg (msgtext,msgheader,confnr)
;	   a0.l	   a1.l	     d0.w
savemsg	move.l	a1,-(sp)
	movea.l	(msg,NodeBase),a1
	move.w	#Main_savemsg,(m_Command,a1)
	move.l	a0,(m_Data,a1)
	move.l	(sp)+,(m_Name,a1)
	andi.l	#$ffff,d0
	move.l	d0,(m_UserNr,a1)
	bsr.b	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	rts

; sendintermsg (intermsgstruct,receivenode)
;		a0.l		d0.l
sendintermsg
	movea.l	(msg,NodeBase),a1
	move.w	#Main_BroadcastMsg,(m_Command,a1)
	move.l	a0,(m_Data,a1)
	move.l	d0,(m_UserNr,a1)
	bsr.b	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	rts


;a0 - funksjon - må returnere med set bit'et satt for at forandringen skal lages
;		 hvis de returnerer med N bitet, avbrytes loop'en
;a1 - a-arg
;d0 - d-arg
doallusers
	push	a2/a3/d2/d3/d4
	movea.l	a0,a3
	move.l	a1,d4
	move.l	(Tmpusermem,NodeBase),a2
	move.l	d0,d2
	moveq.l	#0,d3
1$	move.l	d3,d0
	movea.l	a2,a0
	bsr	loadusernrnr
	bmi.b	9$		; Error
	beq.b	9$		; EOF
	movea.l	d4,a0
	move.l	d2,d0
	movea.l	a2,a1
	jsr	(a3)
	bmi.b	9$		; skal avbryte
	bne.b	2$
	move.l	d3,d0
	movea.l	a2,a0
	bsr	saveusernrnr
	beq.b	9$		; Error
2$	addq.l	#1,d3
	bra.b	1$
9$	pop	a2/a3/d2/d3/d4
	rts

handlemsg
	movea.l	(mainmsgport),a0
	jsrlib	PutMsg
1$	movea.l	(nodeport,NodeBase),a0
	jsrlib	WaitPort
	tst.l	d0
	beq.b	1$
	movea.l	(nodeport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq.b	1$
	rts

; a0 = port name
; a1 = msg
; ret: Z = noport
handlemsgspesport
	push	a2
	movea.l	a1,a2
	jsrlib	Forbid
	movea.l	a0,a1
	jsrlib	FindPort
	tst.l	d0
	beq.b	1$				; opps, ingen port
	movea.l	d0,a0
	movea.l	a2,a1
	jsrlib	PutMsg
	jsrlib	Permit
2$	movea.l	(nodeport,NodeBase),a0
	jsrlib	WaitPort
	tst.l	d0
	beq.b	2$
	movea.l	(nodeport,NodeBase),a0
	jsrlib	GetMsg
	tst.l	d0
	beq.b	2$
	bra.b	9$
1$	jsrlib	Permit
	move.w	#Error_NoPort,(m_Error,a2)
	setz
9$	pop	a2
	rts

; a0 = port name
; a1 = msg
; ret: Z = noport
sendmsgspesport
	push	a2
	movea.l	a1,a2
	jsrlib	Forbid
	movea.l	a0,a1
	jsrlib	FindPort
	tst.l	d0
	beq.b	1$				; opps, ingen port
	movea.l	d0,a0
	movea.l	a2,a1
	jsrlib	PutMsg
	jsrlib	Permit
	clrz
	bra.b	9$
1$	jsrlib	Permit
	move.w	#Error_NoPort,(m_Error,a2)
	setz
9$	pop	a2
	rts

; a0 = prompt å skrive
; d0 = 0  : gottar ikke all
; d0 = 2  : må ha ALL for å sende all tilbake
; d1 != 0 : Godta netnavn
; Hvis n=1, returnerer vi et (net)navn i a0, ikke brukernummer i d0
getnamenrmatch
	push	a2/a3/d2/d3/d4/d5/d6
	link	a3,#-80
	move.l	a0,d2				; husker promptet
	move.l	d0,d4
	move.l	d1,d6				; husker om vi vil ha netnavn
	suba.l	a1,a1				; ikke noe til intextbuffer
1$	move.l	d4,d0				; godtar vi all ALL ?
	move.l	d6,d1				; godtar vi netnavn ?
	bsr	getname
	beq	9$
	bpl.b	5$				; ikke bare return
	moveq.l	#-1,d0				; returnerer z = 1, d0 = -1 (for sikkerhets skyld)
	setz
	bra	9$
5$	moveq.l	#-1,d1
	cmp.l	d0,d1
	notz
	clrn
	bne.b	9$
	move.l	a0,d5				; husker inputen
6$	move.b	(a0)+,d0
	beq.b	7$
	cmp.b	#'@',d0
	bne.b	6$
	move.l	d5,a0				; returnerer selve navnet
	moveq.l	#-2,d0				; sier vi returnerer netnavnet, ikke brukernummeret
	bra.b	9$
7$	move.l	d5,a0
	bsr.b	getusernumber
	beq.b	99$
	lea	(usernotfountext),a0
	bsr	writeerroro
	lea	(scanuserregtext),a0
	bsr	writetexto
	movea.l	(msg,NodeBase),a1
	move.w	#Main_MatchName,(m_Command,a1)
	move.l	(tmpmsgmem,NodeBase),(m_Data,a1)
	move.l	d5,(m_Name,a1)
	bsr	handlemsg			; gir ingen feilmelding
	movea.l	(tmpmsgmem,NodeBase),a2
	move.b	(m_poeng,a2),d0			; fant vi noen navn ?
	beq.b	3$				; nei..
	moveq.l	#maksisøkebuffer,d3
	lea	(m_navn,a2),a0			; bruker det første som nytt navn
	move.l	a0,d5
	bra.b	4$	
2$	move.b	(m_poeng,a2),d0
	beq.b	3$
4$	lea	(m_navn,a2),a0
	bsr	writetexto
	lea	(match_sizeof,a2),a2
	subq.l	#1,d3
	bne.b	2$
3$	move.l	d5,a0
	lea	sp,a1
	bsr	strcopy
	movea.l	d2,a0				; prompt
	lea	sp,a1				; til intext
	bra	1$
99$	clrzn
9$	unlk	a3
	pop	a2/a3/d2/d3/d4/d5/d6
	rts

; a0 = navn
getusernumber
	movea.l	(msg,NodeBase),a1
	move.w	#Main_getusernumber,(m_Command,a1)
	move.l	a0,(m_Name,a1)
	moveq.l	#0,d0
	move.l	d0,(m_Data,a1)			; ikke net navn
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.l	(m_UserNr,a1),d0
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	rts

; a0 = data område
; d0 = brukernr (i fil, ikke det vanelige brukernr)
loadusernrnr
	movea.l	(msg,NodeBase),a1
	move.w	#Main_loadusernrnr,(m_Command,a1)
	move.l	d0,(m_UserNr,a1)
	move.l	a0,(m_Data,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	beq.b	9$
	cmpi.w	#Error_EOF,d0
	beq.b	99$
	setn
	bra.b	99$
9$	notz
99$	rts

; a0 = data område
; d0 = brukernr (i fil, ikke det vanelige brukernr)
saveusernrnr
	movea.l	(msg,NodeBase),a1
	move.w	#Main_saveusernrnr,(m_Command,a1)
	move.l	d0,(m_UserNr,a1)
	move.l	a0,(m_Data,a1)
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	move.l	d0,(m_arg,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	notz
	rts

; a0 = data område
; d0 = brukernr
loadusernr
	movea.l	(msg,NodeBase),a1
	move.w	#Main_loadusernr,(m_Command,a1)
	move.l	d0,(m_UserNr,a1)
	move.l	a0,(m_Data,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	notz
	rts

; a0 = data område
; d0 = brukernr
saveusernr
	movea.l	(msg,NodeBase),a1
	move.w	#Main_saveusernr,(m_Command,a1)
	move.l	d0,(m_UserNr,a1)
	move.l	a0,(m_Data,a1)
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	move.l	d0,(m_arg,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	notz
	rts

loaduser
	move.l	a1,-(sp)
	movea.l	(msg,NodeBase),a1
	move.w	#Main_loaduser,(m_Command,a1)
	move.l	a0,(m_Name,a1)
	movea.l	(sp)+,a0
	move.l	a0,(m_Data,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	beq.b	9$
	cmpi.w	#Error_Not_Found,d0
	beq.b	8$
;	#Error_Open_File
	moveq	#-1,d0
	bra.b	9$
8$	moveq	#1,d0
9$	rts

saveuser
	move.l	a1,-(sp)
	movea.l	(msg,NodeBase),a1
	move.w	#Main_saveuser,(m_Command,a1)
	move.l	a0,(m_Name,a1)
	movea.l	(sp)+,a0
	move.l	a0,(m_Data,a1)
	moveq.l	#0,d0
	move.w	(NodeNumber,NodeBase),d0
	move.l	d0,(m_arg,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	beq.b	9$
	cmpi.w	#Error_Not_Found,d0
	beq.b	8$
;	#Error_Open_File
	moveq	#-1,d0
	bra.b	9$
8$	clrz
9$	rts

saveconfig
	movea.l	(msg,NodeBase),a1
	move.w	#Main_saveconfig,(m_Command,a1)
	moveq.l	#0,d0
	move.l	d0,(m_Data,a1)
	bsr	handlemsg
	movea.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d0
	cmpi.w	#Error_OK,d0
	notz
	rts

checkformsgerror
	movea.l	(msg,NodeBase),a1
	moveq.l	#0,d0
	move.w	(m_Error,a1),d0
	rts

@clearmsgerror
	movea.l	(msg,NodeBase),a1
	move.w	#0,(m_Error,a1)
	rts
