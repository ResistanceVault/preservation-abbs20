 *****************************************************************
 *
 * NAME
 *	NodeSupport.asm
 *
 * DESCRIPTION
 *	Misc support routines
 *	
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: NodeSupport.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: NodeSupport.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	include	'first.i'

	include	'exec/types.i'

	include	'asm.i'
	include	'bbs.i'
	include	'NodeSupportdefs.i'
	include	'fse.i'
	include	'node.i'

	XREF	nodehook

;d0 - confnr (* 1)
;a0 - new name
; må returnerer en ok kode
renameconfbulletins
	push	d2/a2/d3/d4/d5/d6
	move.l	a0,a2
	move.l	d0,d4

	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF,d0
	moveq.l	#0,d3
	move.w	(n_ConfBullets,a0,d0.l),d3	; har denne konfen bulletiner ?
	beq	9$				; nei, alt ok
	lea	(maintmptext,NodeBase),a0	; fyller i navnet til bl filen
	move.l	d4,d0
	jsr	(getkonfbulletlist)
	bsr	10$
	lea	(bulletlisttext),a0
	jsr	(strcopy)
	move.l	(dosbase),a6

	lea	(maintmptext,NodeBase),a1
	lea	(tmptext,NodeBase),a0
	move.l	a0,d1
	move.l	a1,d2
	jsrlib	Rename
	tst.l	d0
	beq.b	4$

1$	move.l	d3,d0
	move.l	d4,d1
	lea	(maintmptext,NodeBase),a0
	jsr	(getkonfbulletname)
	bsr	10$
	move.l	d3,d0
	move.l	a1,a0
	andi.l	#$ffff,d0
	jsr	(konverter)

	lea	(maintmptext,NodeBase),a1	; new name
	lea	(tmptext,NodeBase),a0		; old name
	move.l	a0,d1
	move.l	a1,d2
	jsrlib	Rename
	tst.l	d0
	beq.b	4$


; rename .ansi og .raw filer også...

	subq.l	#1,d3
	bne.b	1$
	bra.b	8$
4$	move.l	(exebase),a6
	lea	(errorrenbultext),a0
	jsr	(writeerroro)
	setz
	bra.b	99$
8$	move.l	(exebase),a6
9$	clrz
99$	pop	d2/a2/d3/d4/d5/d6
	rts

10$	lea	(tmptext,NodeBase),a1
	lea	(bulletinpath),a0
	jsr	(strcopy)
	subq.l	#1,a1
	move.l	a2,a0
11$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	19$
	move.b	d0,(a1)+
	cmpi.b	#'/',d0
	bne.b	11$
	move.b	#' ',(-1,a1)
	bra.b	11$
19$	rts

; a0 - source
; a1 - dest
makehardlink
	push	a6/d2/d3
	move.l	(dosbase),a6
	move.l	a1,d3
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d2
	beq.b	9$				; error.. Ut.
	move.l	d3,d1
	moveq.l	#0,d3				; Hard links..
	jsrlib	MakeLink
	move.l	d0,d3				; husker status
	move.l	d2,d1
	jsrlib	UnLock				; frigir lock'en igjen
	move.l	d3,d0
9$	pop	a6/d2/d3
	rts

checkforduplicatetmpdirs
	clrz
	rts
;	suba.l	a1,a1
;	jsrlib	FindTask
;	jsrlib	Forbid
;	move.l	d0,d1		; vår task
;	move.l	nodelist+LH_HEAD,d0
;1$	move.l	d0,a0
;	move.l	(LN_SUCC,a0),d0
;	beq.b	2$			; siste.
;	cmp.l	(NodeTask,a0),d1	; er det vår ?
;	beq.b	1$			; ja, skipp'er
;
;
;	bne.b	1$			; nei, sommer! :-)
;
;
;2$	move.l	a0,a4			; husker nodenoden vår
;	suba.l	a1,a1
;	jsrlib	FindTask
;	move.l	d0,(NodeTask,a4)	; lagrer vår adresse her.
;	jsrlib	Permit			; nå kan andre noder starte
;
;
;	rts

;Sjekk navnene før prompt, og tell gyldige navn etterpå...
;Bare 1 navn, velg det automatiskt.
;Ingen navn, bare type fila
;ingen fil, som før
;2 eller flere navn: "Comment to who: " og hotkey på navnene
; - Navn er av typen:
;	!GGeir Inge
;	^Id
;	 ^Hot Key
;	  ^Fullt navn.

GetCommentUserNr
	push	d2-d6/a2/a3
	link.w	a3,#-80
	move.l	a3,d6
	move.l	(SYSOPUsernr+CStr,MainBase),d5	; default retur verdi
	lea	commentfilename,a0
	move.l	sp,a1
	jsr	getbestfilenamebuffer
	bne.b	1$
	lea	commentfilename,a0
1$	move.l	(dosbase),a6
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	9$				; ingen fil, superuser
	move.l	(tmpmsgmem,NodeBase),a2
	move.l	d4,d1
	move.l	a2,d2
	move.l	(msgmemsize,NodeBase),d3
	jsrlib	Read
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq	8$			; File error
	tst.l	d0
	beq	8$			; EOF, tom
	move.l	d0,d3
	move.b	#0,(a2,d3.l)		; terminerer
	move.l	d4,d1			; lukker
	jsrlib	Close
	move.l	(exebase),a6
	move.l	a2,a3
2$	move.b	(a2)+,d0
	cmp.b	#'!',d0
	bne.b	3$
	move.b	(a2)+,d0
	bsr	upchar
	move.b	d0,(a3)
	move.l	sp,a1			; kopierer navnet over i stack
	moveq.l	#Sizeof_NameT,d1
4$	subq.l	#1,d1			; sjekker for overflow
	bcs.b	5$
	move.b	(a2)+,d0
	move.b	d0,(a1)+
	beq.b	6$
	cmp.b	#10,d0
	bne.b	4$
	move.b	#0,(-1,a1)
6$	subq.l	#1,d1			; sjekker for overflow
	bcs.b	5$
	move.b	#0,(a1)+
	bra.b	6$
5$	move.l	sp,a0
	jsr	(getusernumber)
	bne.b	7$			; error
	move.l	d0,(2,a3)		; lagrer usernr'et
	lea	(6,a3),a3
7$	move.b	#0,(a3)			; Terminerer/sletter tegnet.
	bra.b	2$

3$	lea	(-1,a2),a2
	move.l	a2,a0
	bsr	strlen
	beq.b	10$
	move.l	a2,a0
	moveq.l	#0,d1
	jsr	(writetextmemi)
10$	move.l	(tmpmsgmem,NodeBase),a2
	move.b	(a2),d0			; har vi noen ?
	beq.b	9$			; nope. ferdig
	move.l	(2,a2),d5		; bare en, bruker han i såfall
	move.b	(6,a2),d0		; mere enn 1 ?
	beq.b	9$			; nope. ferdig
	jsr	(startsleepdetect)
11$	bsr	readchar
	beq	12$			; error
	cmpi.b	#24,d0			; CTRL-X ??
	beq.b	12$			; Ja, ut
	bmi.b	11$			; Dropper spesial tegn.
	bsr	upchar
	lea	(-6,a2),a0
14$	lea	(6,a0),a0
	move.b	(a0),d1
	beq.b	11$			; fant ikke. Les neste tegn
	cmp.b	d0,d1
	bne.b	14$
	move.l	(2,a0),d5		; til bruker
	bra.b	9$

12$	move.l	#-1,d5
	clr.b	(dosleepdetect,NodeBase)
	bra.b	9$
8$	move.l	d4,d1
	jsrlib	Close
9$	move.l	(exebase),a6
	move.l	d5,d0
	move.l	d6,a3
	unlk	a3
	pop	d2-d6/a2/a3
	rts

;a0 = message header
;ret = Z if net message
isnetmessage
	bsr.b	doisnetmessage
	bne.b	9$
	lea	(dontsupnettext),a0
	bsr	writeerroro
	setz
9$	rts

;a0 = message header
;ret = Z if net message
doisnetmessage
	move.w	(NrLines,a0),d0
	bpl.b	1$
	setz
	bra.b	9$
1$	clrz
9$	rts

updatewindowtitle
	push	a2/a6
	move.l	(nodenoden,NodeBase),a1
	lea	(Nodeuser,a1),a0
	move.b	(a0),d0
	bne.b	2$
	lea	(nonetext),a0
2$	move.l	(windowtitleptr,NodeBase),a1
	jsr	(strcopy)
	btst	#DoDivB_Sleep,(DoDiv,NodeBase)		; har vi sleep
	beq.b	1$
	lea	(sleeptext),a0
	subq.l	#1,a1
	jsr	(strcopy)

1$	move.l	(intbase),a6
	move.l	(windowadr,NodeBase),d0
	beq.b	9$					; no window
	move.l	d0,a0
	lea	(Nodetaskname,NodeBase),a1
	moveq.l	#-1,d0
	move.l	d0,a2
	jsrlib	SetWindowTitles
9$	pop	a2/a6
	rts

;a0 = string
skiptonewline
1$	move.b	(a0)+,d0
	beq.b	2$			; oops.
	cmp.b	#10,d0
	bne.b	1$
	bra.b	9$
2$	lea	(-1,a0),a0		; returnerer nullen
9$	rts

; a0 = subject (NULL for subject i msgheader)
; a1 = meldingen
; d0 = subject length
; d1 = max length of buffer
; ret: a0 = ny meldings start
packnetmessage
	push	a2/a3/d2/d3/d4/d5/d6
	move.l	a1,a2			; husker melding start
	move.l	a1,d6			; lagrer som default retur verdi også
	move.l	a0,a3			; husker subject
	move.l	d1,d5			; husker max lengde
	moveq.l	#0,d3			; lengde vi har
	move.l	d0,d2			; husker subject length
;	move.l	d2,d2			; lengde vi trenger
	beq.b	10$			; lengde 0, medfører ingen header++
	addq.l	#2,d2			; og øker for header+terminering
10$	moveq.l	#0,d4			; vi har ingen extdata

	move.l	a1,a0			; meldingen
	move.b	(a0),d1
	cmp.b	#Net_FromCode,d1	; from navn ?
	bne.b	2$			; nei, sjekker videre
1$	move.b	(a0)+,d1
	addq.l	#1,d3			; øker bytes vi har
	cmp.b	#10,d1			; newline ?
	bne.b	1$			; nei, looper videre
	move.b	(a0),d1			; henter ny start

2$	cmp.b	#Net_ToCode,d1		; to navn ?
	bne.b	4$			; nei, sjekker videre
3$	move.b	(a0)+,d1
	addq.l	#1,d3			; øker bytes vi har
	cmp.b	#10,d1			; newline ?
	bne.b	3$			; nei, looper videre
	move.b	(a0),d1			; henter ny start

4$	cmp.b	#Net_SubjCode,d1	; Subject ?
	bne.b	6$			; nei, sjekker videre
5$	move.b	(a0)+,d1
	addq.l	#1,d3			; øker bytes vi har
	cmp.b	#10,d1			; newline ?
	bne.b	5$			; nei, looper videre
	move.b	(a0),d1			; henter ny start

6$	cmp.b	#Net_ExtDCode,d1	; Ext data ?
	bne.b	17$			; nei, ut
	move.l	a0,d4			; husker vi har extdata
7$	move.b	(a0)+,d1
	addq.l	#1,d3			; øker bytes vi har
	addq.l	#1,d2			; øker bytes vi trenger
	cmp.b	#$ff,d1			; $ff ?
	bne.b	7$			; nei, looper videre
; d3 og d2 er nå riktige
17$	cmp.l	d3,d2			; har,trenger
	bhi.b	8$			; vi har for lite
	move.l	a2,a1
	move.l	a0,a2			; selve meldings starten
14$	move.l	a3,d0			; har vi subject ?
	beq.b	11$			; nope
	move.b	#Net_SubjCode,(a1)+
	move.l	a3,a0
	bsr	strcopy
	move.b	#10,(-1,a1)
11$	tst.l	d4			; har vi extdata ?
	beq.b	12$			; nope
	move.l	d4,a0			; kopierer ext data
13$	move.b	(a0)+,d0
	move.b	d0,(a1)+
	cmp.b	#$ff,d0
	bne.b	13$
12$	move.l	a2,d0
	beq.b	9$			; har tatt meldingen, ferdig
	move.l	a2,a0			; selve meldingen
	move.l	a1,d6			; husker meldings start i d6
	bsr	strcopy
	bra.b	9$			; ferdig

8$	sub.l	d3,d2			; d2 er nå antall bytes vi trenger
	move.l	a0,d6			; husker meldings start i d6
	bsr	strlen
	move.l	d0,d1
	add.l	d2,d1			; bytes ny melding vil ta
	cmp.l	d5,d1			; max,trenger
	bls.b	15$			; vi har nok
	sub.l	d2,d0			; minker lengden...
	bcc.b	15$			; safety
	moveq.l	#0,d0
15$	move.l	d6,a0
	addq.l	#1,d0			; øker med 1 pga. -(a0) saken
	add.l	d0,a0			; source
	move.l	a0,a1
	add.l	d2,a1			; destination
16$	move.b	-(a0),-(a1)		; flytter
	subq.l	#1,d0
	bcc.b	16$
	move.l	a2,a1
	suba.l	a2,a2			; sier vi har tatt meldingen
	bra.b	14$
9$	move.l	d6,a0
	pop	a2/a3/d2/d3/d4/d5/d6
	rts

		section nodesupdata,data

dontsupnettext	dc.b	'This command doesn''t support net messages yet.',0
sleeptext	dc.b	' (Sleep)',0
commentfilename	dc.b	'abbs:text/Comment',0
commentowhotext	dc.b	'Comment to who: ',0

		END		; That's all Folks !!!
