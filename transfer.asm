 *****************************************************************
 *
 * NAME
 *	transfer.asm
 *
 * DESCRIPTION
 *	transfer rutines
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: transfer.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: transfer.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'

;	IFND	__M68
	include	'exec/types.i'
	include	'devices/serial.i'
	include	'intuition/intuition.i'
;	ENDC
	include	'asm.i'
	include	'bbs.i'
	include	'fse.i'
	include	'node.i'


	XDEF	sendfile
	XDEF	dosendGogR
	XDEF	doreciveGogR
	XDEF	receivefile
	XDEF	shortprotocname
	XDEF	protoclname
	XDEF	protocolisbatch
	XDEF	docheckGogR

	XREF	deletefile
	XREF	dosbase
	XREF	exebase
	XREF	findcleanup
	XREF	initserread
	XREF	parseprotocol
	XREF	protocolinitstr
	XREF	protokollbaser
	XREF	readlineprompt
	XREF	setupa4a5
	XREF	startyourtext
	XREF	stopserread
	XREF	strcopy
	XREF	traprotocoltext
	XREF	writecontext
	XREF	writetext
	XREF	writetexto
	XREF	receivetext
	XREF	trfstatl1text
	XREF	trfstatl2text
	XREF	logdlmsgtext
	XREF	fjernpath
	XREF	calctime
	XREF	getfilelen
	XREF	konverter
	XREF	konverterw
	XREF	errorstext
	XREF	writelogtexttimed
	XREF	cpstext
	XREF	serwritestringdo
	XREF	sendtext
	XREF	logulmsgtext
	XREF	toaysopupload
	XREF	writetosysoptextd
	XREF	findfirst
	XREF	findnext
	XREF	waitseroutput
	XREF	memcopylen
	XREF	serwritestringlen
	XREF	divl
	XREF	writeconchar
	XREF	cleartoEOLtext
	XREF	writecontextrfill
	XREF	serreadstring

;nocarrier = 1

	IFND DEMO
; a0 = filename
sendfile
	push	a2/a3/d2
	movea.l	a0,a2
	move.b	#-1,(DlUlstatus,NodeBase)
	moveq.l	#0,d2
	move.w	d2,(tmpword,NodeBase)		; sletter antall errors
	move.l	d2,(tmpwhilenotinparagon,NodeBase) ; sletter antall bytes
	tst.b	(readlinemore,NodeBase)		; er det mere innput ?
	bne.b	8$				; jepp. da er det protokoll
	move.b	(Protocol+CU,NodeBase),d2
	beq.b	8$
	subq.l	#1,d2
	bra.b	5$				; Vi har en protokoll
8$	lea	(traprotocoltext),a0
	bsr	readlineprompt
	beq	9$
	bsr	parseprotocol
	beq.b	8$
	move.l	d0,d2
5$	lsl.l	#2,d2
	lea	(startyourtext),a0
	bsr	writetext
	lea	(protoclname),a0
	movea.l	(0,a0,d2.w),a0
	bsr	writetext
	lea	(receivetext),a0
	bsr	writetexto
	move.w	(Userbits+CU,NodeBase),d0
	btst	#USERB_G_R,d0
	beq.b	4$
	movea.l	a2,a0
	move.l	d2,d0
	lsr.l	#2,d0
	bsr	dosendGogR
4$	move.b	#0,(DlUlstatus,NodeBase)	; Setter error
	lea	(protokollinitstr),a0		; init string
	movea.l	(0,a0,d2.w),a0
	bsr	setup_xprio
;	beq.s	9$				; kan aldri forekomme
	movea.l	d0,a3
	bsr	stopserread
	movea.l	(dosbase),a6
	lea	(tmpdatestamp,NodeBase),a0	; lagrer start tiden
	move.l	a0,d1
	jsrlib	DateStamp
	lea	(protokollbaser),a0
	adda.l	d2,a0
	movea.l	(a0),a6
	movea.l	a3,a0
	push	d2-d7/a2-a6
	jsr	(_LVOXProtocolSetup,a6)
	pop	d2-d7/a2-a6
	tst.l	d0
	beq	1$
	tst.b	(Tinymode,NodeBase)		; skriver ut header (hvis ikke
	bne.b	6$				; tiny mode)
	move.l	a6,-(a7)
	movea.l	(exebase),a6
	lea	(trfstatl1text),a0
	bsr	writecontext
	lea	(trfstatl2text),a0
	bsr	writecontext
	movea.l	(a7)+,a6
6$	moveq.l	#0,d0				; sletter lagringsstedet
	move.l	d0,(tmpval,NodeBase)
	movea.l	a3,a0
	move.l	a2,(xpr_filename,a0)
	push	d2-d7/a2-a6
	jsr	(_LVOXProtocolSend,a6)
	pop	d2-d7/a2-a6
	move.l	a6,-(sp)
	tst.l	d0
	beq.b	2$
	move.b	#1,(DlUlstatus,NodeBase)
	movea.l	(dosbase),a6			; Sjekker tiden nu
	lea	(lastchartime,NodeBase),a0
	move.l	a0,d1
	jsrlib	DateStamp
	movea.l	(exebase),a6
	lea	(logdlmsgtext),a0
	moveq.l	#0,d0				; dette er Download
	bsr	skrivuldllog
2$	move.l	(tmpval,NodeBase),d1		; lukker filen hvis den er åpen
	beq.b	3$
	movea.l	(dosbase),a6
	jsrlib	Close
3$	moveq.l	#0,d0				; sletter igjen
	move.l	d0,(tmpval,NodeBase)
	movea.l	(sp)+,a6
	movea.l	a3,a0
	move.l	#0,(xpr_filename,a0)
	push	d2-d7/a2-a6
	jsr	(_LVOXProtocolCleanup,a6)
	pop	d2-d7/a2-a6
1$	movea.l	(exebase),a6
;	move.l	a3,a0
;	bsr	clear_xprio			(ingenting å gjøre...)
9$	pop	a2/a3/d2
	bsr	initserread
	moveq.l	#0,d0
	move.l	d0,(SerTotOut,NodeBase)		; empty counter
	move.b	(batch,NodeBase),d1
	beq.b	91$
	move.b	d0,(batch,NodeBase)
	bsr	findcleanup
91$	tst.b	(DlUlstatus,NodeBase)
	rts


	XREF _Write_user_CPS

;skrivr feks:
;09:35 Downloaded file: (Z) thor21_bbs.lha   (1719 cps 1100 s 100 err)
;a2 = filename
;a0 = logfile text
;d0 = 0 -> Download, 1 = upload, 2 = ungrab (ikke skriv i tosysop fila)
skrivuldllog
	push	d3/a3/d4/d5
	link.w	a3,#-160
	move.l	a3,d4
	move.l	d0,d5				; husker hva det var
	movea.l	a0,a3
	move.l	sp,a1				; bruker dette til å lagre str'en i

	move.b	#'(',(a1)+
	lea	(shortprotocname),a0
	adda.l	d2,a0
	bsr	strcopy
	move.b	#')',(-1,a1)
	move.b	#' ',(a1)+
	movea.l	a2,a0
	move.l	a1,d3
	bsr	fjernpath
	movea.l	d3,a1
	bsr	strcopy
	move.b	#' ',(-1,a1)
	move.b	#0,(a1)				; avslutter srtringen for sikkerhetsskyld
	move.l	a1,d3				; husker hvor vi var i str'en
	lea	(lastchartime,NodeBase),a1	; tiden nå
	lea	(tmpdatestamp,NodeBase),a0	; tiden for start av DL.
	bsr	calctime			; beregner antall sekunder
	move.l	d0,d2				; husker antall sek.
	beq	3$				; egentlig umulig, men..
	move.b	(batch,NodeBase),d0		; er det batch ?
	beq.b	5$				; nei, finn størrelsen
	move.l	(tmpwhilenotinparagon,NodeBase),d0
	beq.b	3$				; egentlig umulig, men ...
	bra.b	4$
5$	movea.l	a2,a0
	move.l	(ULfilenamehack,NodeBase),d0
	beq.b	2$
	movea.l	d0,a0
2$	bsr	getfilelen
	beq.b	3$
4$	movea.l	d3,a0				; henter ut igjen
	move.b	#'(',(a0)+
	divu.w	d2,d0				; beregner cps'en
	bsr	konverterw
	movea.l	a0,a1
	move.b	#' ',(a1)+
	lea	(cpstext),a0
	bsr	strcopy
	subq.l	#1,a1
	movea.l	a1,a0
	move.l	d2,d0
	bsr	konverter
	movea.l	a0,a1
;	move.b	#' ',(a1)+
;	move.b	#'s',(a1)+
	lea	(secstext),a0
	bsr	strcopy
	subq.l	#1,a1
	move.w	(tmpword,NodeBase),d0		; noen error's ?
	beq.b	1$				; nei, ikke noen utskrift
	move.b	#' ',(-1,a1)
	movea.l	a1,a0
	jsr	(konverterw)
	move.b	#' ',(a0)+
	movea.l	a0,a1
	lea	(errorstext),a0
	bsr	strcopy
	subq.l	#1,a1
1$	move.b	#')',(a1)+
	move.b	#0,(a1)
3$	movea.l	a3,a0
	move.l	sp,a1
	bsr	writelogtexttimed
	cmp.b	#1,d5				; vanlig upload ?
	bne.b	6$				; nei
	move.l	sp,a1				; skriver til tosysop fila
	lea	(toaysopupload),a0
	bsr	writetosysoptextd
6$	move.l	d4,a3

;	jsr	(_Write_user_CPS)
	unlk	a3
	pop	d3/a3/d4/d5
	rts

dosendGogR
	movem.l	d0,-(a7)
	bsr	fjernpath
	move.l	a0,-(a7)
	lea	(tmptext,NodeBase),a1
	lea	(vipparamkode),a0
	bsr	strcopy
	subq.l	#1,a1
	movea.l	(a7)+,a0
	bsr	strcopy
	move.b	#13,(-1,a1)
	move.l	(a7)+,d0
	mulu.w	#6,d0
	lea	(recivefilekoder),a0
	adda.l	d0,a0
	bsr	strcopy
	lea	(tmptext,NodeBase),a0
	bsr	serwritestringdo
	rts

doreciveGogR
	movem.l	d0,-(a7)
	bsr	fjernpath
	move.l	a0,-(a7)
	lea	(tmptext,NodeBase),a1
	lea	(vipparamkode),a0
	bsr	strcopy
	subq.l	#1,a1
	movea.l	(a7)+,a0
	bsr	strcopy
	move.b	#13,(-1,a1)
	move.l	(a7)+,d0
	mulu.w	#6,d0
	lea	(sendfilekoder),a0
	adda.l	d0,a0
	bsr	strcopy
	lea	(tmptext,NodeBase),a0
	bra	serwritestringdo

docheckGogR
	tst.w	(CommsPort+Nodemem,NodeBase)
	beq.b	9$
	lea	(checkG_Rkode),a0
	bsr	serwritestringdo
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
	move.l	#1000000,d1			; 1 sek timeout mellom tegnene
	jsr	(serreadstring)
	movea.l	a0,a1
	lea	(logfilemenutext),a0
	bsr	writelogtexttimed
9$	rts

; a0 = filename
; d0 = 1, ungrab (ikke skriv i tosysop fila)
receivefile
	push	a2/a3/d2/d3
	movea.l	a0,a2
	move.l	d0,d3				; skal vi skrive i tosysop fila ? (1 = nei)
	moveq.l	#0,d2
	move.w	d2,(tmpword,NodeBase)		; sletter antall errors
	tst.b	(readlinemore,NodeBase)		; er det mere innput ?
	bne.b	8$				; jepp. da er det protokoll
	move.b	(Protocol+CU,NodeBase),d2
	beq.b	8$
	subq.l	#1,d2
	bra.b	5$				; Vi har en protokoll
8$	lea	(traprotocoltext),a0
	bsr	readlineprompt
	beq	9$
	bsr	parseprotocol
	beq.b	8$
	move.l	d0,d2
5$	lsl.l	#2,d2
	lea	(startyourtext),a0
	bsr	writetext
	lea	(protoclname),a0
	movea.l	(0,a0,d2.w),a0
	bsr	writetext
	lea	(sendtext),a0
	bsr	writetexto
	move.w	(Userbits+CU,NodeBase),d0
	btst	#USERB_G_R,d0
	beq.b	4$
	movea.l	a2,a0
	move.l	d2,d0
	lsr.l	#2,d0
	bsr	doreciveGogR
4$	move.b	#0,(DlUlstatus,NodeBase)		; Setter error
	lea	(protokollinitstr),a0		; init string
	movea.l	(0,a0,d2.w),a0
	bsr	setup_xprio
;	beq.s	9$				; kan aldri forekomme
	movea.l	d0,a3
	bsr	stopserread
	movea.l	(dosbase),a6
	lea	(tmpdatestamp,NodeBase),a0	; lagrer start tiden
	move.l	a0,d1
	jsrlib	DateStamp

	lea	(protokollbaser),a0
	adda.l	d2,a0
	movea.l	(a0),a6
	movea.l	a3,a0
	movem.l	d2-d7/a2-a6,-(sp)
	jsr	(_LVOXProtocolSetup,a6)
	movem.l	(sp)+,d2-d7/a2-a6
	tst.l	d0
	beq	1$
	tst.b	(Tinymode,NodeBase)		; skriver ut header (hvis ikke
	bne.b	6$				; tiny mode)
	move.l	a6,-(a7)
	movea.l	(exebase),a6
	lea	(trfstatl1text),a0
	bsr	writecontext
	lea	(trfstatl2text),a0
	bsr	writecontext
	movea.l	(a7)+,a6
6$	moveq.l	#0,d0
	move.l	d0,(tmpval,NodeBase)		; sikrer at verdien er riktig
	move.l	a2,(xpr_filename,a3)
	movea.l	a3,a0
	movem.l	d2-d7/a2-a6,-(sp)
	jsr	(_LVOXProtocolReceive,a6)
	movem.l	(sp)+,d2-d7/a2-a6
	move.l	a6,-(sp)
	tst.l	d0
	beq.b	2$
	move.b	#1,(DlUlstatus,NodeBase)
	movea.l	(dosbase),a6			; Sjekker tiden nu
	lea	(lastchartime,NodeBase),a0
	move.l	a0,d1
	jsrlib	DateStamp
	movea.l	(exebase),a6
	lea	(logulmsgtext),a0
	moveq.l	#1,d0				; dette er Upload
	tst.l	d3
	beq.b	7$				; vanelig upload
	moveq.l	#2,d0				; dette er ungrab
7$	bsr	skrivuldllog
2$	move.l	(tmpval,NodeBase),d1		; lukker filen hvis den er åpen
	beq.b	3$
	movea.l	(dosbase),a6
	jsrlib	Close
3$	moveq.l	#0,d0				; sletter igjen
	move.l	d0,(tmpval,NodeBase)
	movea.l	(sp)+,a6
	movea.l	a3,a0
	move.l	#0,(xpr_filename,a0)
	movem.l	d2-d7/a2-a6,-(sp)
	jsr	(_LVOXProtocolCleanup,a6)
	movem.l	(sp)+,d2-d7/a2-a6
1$	movea.l	(exebase),a6
;	move.l	a3,a0
;	bsr	clear_xprio			(ingenting å gjøre...)
9$	pop	a3/a2/d2/d3
	bsr	initserread
	moveq.l	#0,d0
	move.l	d0,(SerTotOut,NodeBase)		; empty counter
	tst.b	(DlUlstatus,NodeBase)
	rts

setup_xprio
	push	a2
	movea.l	a0,a2
	lea	(xpriomem,NodeBase),a0		; clear'er minnet (for sikkerhets skyld)
	moveq.l	#XPR_IO_SIZEOF,d0
	moveq.l	#0,d1
	subq.l	#1,d0
1$	move.b	d1,(a0)+
	dbf	d0,1$

	lea	(xpriomem,NodeBase),a0
	move.l	a2,(xpr_filename,a0)
	move.l	#fopen,(xpr_fopen,a0)
	move.l	#fclose,(xpr_fclose,a0)
	move.l	#fread,(xpr_fread,a0)
	move.l	#fwrite,(xpr_fwrite,a0)
	move.l	#sread,(xpr_sread,a0)
	move.l	#swrite,(xpr_swrite,a0)
	move.l	#sflush,(xpr_sflush,a0)
	move.l	#update,(xpr_update,a0)
	move.l	#chkabort,(xpr_chkabort,a0)
	move.l	d1,(xpr_chkmisc,a0)
	move.l	#gets,(xpr_gets,a0)
	move.l	d1,(xpr_setserial,a0)
;	move.l	#setserial,xpr_setserial(a0)
	move.l	#ffirst,(xpr_ffirst,a0)
	move.l	#fnext,(xpr_fnext,a0)
	move.l	#finfo,(xpr_finfo,a0)
	move.l	#fseek,(xpr_fseek,a0)
	move.l	#XPR_EXTENSION,(xpr_extension,a0)
	move.l	d1,(xpr_data,a0)
	move.l	d1,(xpr_options,a0)
	move.l	#unlink,(xpr_unlink,a0)
	move.l	d1,(xpr_squery,a0)
	move.l	d1,(xpr_getptr,a0)
	move.l	a0,d0
	pop	a2
	rts

ffirst	push	a4/a5/a6
	bsr	setupa4a5
	move.b	(batch,NodeBase),d0
	beq.b	1$
	bsr	findfirst
	beq.b	8$
	move.l	(tmpmsgmem,NodeBase),d0
	addq.l	#3,d0
	and.l	#$fffffffc,d0
	move.l	d0,a0					; findfile struct
	lea	(ff_full,a0),a0
	move.l	a0,(ULfilenamehack,NodeBase)
	bsr	getfilelen
	beq.b	2$					; error, den kommer vi over senere også..
	add.l	d0,(tmpwhilenotinparagon,NodeBase)	; husker størrelsen
2$	moveq.l	#1,d0
	bra.b	9$
1$	exg	a0,a1
	bsr	strcopy
	moveq.l	#1,d0
	bra.b	9$
8$	moveq.l	#0,d0
9$	pop	a4/a5/a6
	rts

fnext	push	a4/a5/a6
	bsr	setupa4a5
	moveq.l	#0,d0
	move.b	(batch,NodeBase),d0
	beq.b	9$
	bsr	findnext
	beq.b	8$
	move.l	(tmpmsgmem,NodeBase),d0
	addq.l	#3,d0
	and.l	#$fffffffc,d0
	move.l	d0,a0				; findfile struct
	lea	(ff_full,a0),a0
	move.l	a0,(ULfilenamehack,NodeBase)
	bsr	getfilelen
	beq.b	2$					; error, den kommer vi over senere også..
	add.l	d0,(tmpwhilenotinparagon,NodeBase)	; husker størrelsen
2$	moveq.l	#1,d0
	bra.b	9$
8$	moveq.l	#0,d0
9$	pop	a4/a5/a6
	rts

fopen	movem.l	d2/d3/a4/a5/a6,-(sp)
	move.l	a0,d1
	bsr	setupa4a5
	move.l	(ULfilenamehack,NodeBase),d0	; Hack for å forhindre filnavn
	beq.b	5$				; overide som Zmodem har.
	move.l	d0,d1				; Ja, vi hadde filnavn, bytt.
5$	moveq.l	#0,d0
	move.b	(a1),d3
	cmpi.b	#'r',d3
	bne.b	1$
	move.l	#MODE_OLDFILE,d2
	bra.b	4$
1$	cmpi.b	#'w',d3
	bne.b	2$
	move.l	#MODE_NEWFILE,d2
	bra.b	4$
2$	cmpi.b	#'a',d3
	bne.b	9$
	move.l	#MODE_OLDFILE,d2
4$	movea.l	(dosbase),a6
	jsrlib	Open
;	tst.l	d0
	move.l	d0,(tmpval,NodeBase)	; husker fileptr (for å sikre at den er i bruk)
	beq.b	9$
	cmpi.b	#'a',d3
	bne.b	9$
;	move.l	d0,-(a7)
	move.l	d0,d1
	moveq.l	#0,d2
	moveq.l	#OFFSET_END,d3
	jsrlib	Seek
;	move.l	(a7)+,d0
	move.l	(tmpval,NodeBase),d0		; henter fileptr
9$	movem.l	(sp)+,a6/d2/d3/a4/a5
	rts

fclose	push	a4/a5/a6
	bsr	setupa4a5
	move.l	a0,d1
	movea.l	(dosbase),a6
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,(tmpval,NodeBase)		; husker at den er stengt
	pop	a4/a5/a6
	rts

fread	movem.l	d2/d3/d4/a6,-(sp)
	move.l	d0,d4				; block size
	beq.b	9$
	move.l	d0,d3
	mulu.w	d1,d3
	move.l	a1,d1
	move.l	a0,d2
	movea.l	(dosbase),a6
	jsrlib	Read
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	8$
	moveq.l	#0,d0
	bra.b	9$
8$	divu.w	d4,d0
	andi.l	#$ffff,d0
9$	movem.l	(sp)+,a6/d2/d3/d4
	rts

fwrite	movem.l	d2/d3/d4/a6,-(sp)
	move.l	d0,d4				; block size
	beq.b	9$
	move.l	d0,d3
	mulu.w	d1,d3
	move.l	a1,d1
	move.l	a0,d2
	movea.l	(dosbase),a6
	jsrlib	Write
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	8$
	moveq.l	#0,d0
	bra.b	9$
8$	divu.w	d4,d0
	andi.l	#$ffff,d0
9$	movem.l	(sp)+,a6/d2/d3/d4
	rts

fseek	movem.l	d2/d3/a6,-(sp)
	move.l	d0,d2
	moveq.l	#-1,d0
	move.l	d1,d3
	bne.b	1$
	moveq.l	#OFFSET_BEGINNING,d3
	bra.b	4$
1$	subq.l	#1,d3
	bne.b	2$
	moveq.l	#OFFSET_CURRENT,d3
	bra.b	4$
2$	subq.l	#1,d3
	bne.b	9$
	moveq.l	#OFFSET_END,d3
4$	move.l	a0,d1
	movea.l	(dosbase),a6
	jsrlib	Seek
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	9$
	moveq.l	#0,d0
9$	movem.l	(sp)+,a6/d2/d3
	rts

finfo	moveq.l	#2,d1
	cmp.l	d1,d0
	bne.b	1$
	moveq.l	#1,d0				; Filtype. Alltid binær.
	rts
1$	moveq.l	#1,d1
	cmp.l	d1,d0
	beq.b	2$
	moveq.l	#0,d0				; ukjent. returner error.
	rts
2$	movem.l	a6/a4/a5,-(sp)
	bsr	setupa4a5
	move.l	(ULfilenamehack,NodeBase),d0	; Hack for å forhindre filnavn
	beq.b	3$				; overide som Zmodem har.
	movea.l	d0,a0				; Ja, vi hadde filnavn, bytt.
3$	bsr	getfilelen
	movem.l	(sp)+,a6/a4/a5
	rts

swrite	push	a6/a4/a5/d2/d3
	movea.l	(exebase),a6
	bsr	setupa4a5
	move.l	d0,d3
	move.l	a0,d2
	bsr	waitseroutput
	move.l	(tmpmsgmem,NodeBase),a1		; Bruker tmpmsgmem til copy space
	lea	($400,a1),a1
	move.l	d2,a0
	move.l	d3,d0
	bsr	memcopylen
	move.l	(tmpmsgmem,NodeBase),a0
	lea	($400,a0),a0
	move.l	d3,d0
	bsr	serwritestringlen
;	bsr	serwritestringlendo
	pop	a6/a4/a5/d2/d3
	rts

;a0 = buffer
;d0 = len
;d1 = timeout
sread	movem.l	d2/d3/a2/a6/a4/a5,-(sp)
	movea.l	(exebase),a6
	bsr	setupa4a5
	movea.l	a0,a2				; Buffer
	move.l	d0,d2				; lengde vi skal lese
	move.l	d1,d3				; timeout
;	tst.l	d3				; Har vi timeout ?
	bne.b	1$
	movea.l	(sreadreq,NodeBase),a1		; Leser alle tegn i inn buffer
	move.w	#SDCMD_QUERY,(IO_COMMAND,a1)
	jsrlib	DoIO				; Sjekke flagg
	movea.l	(sreadreq,NodeBase),a1
	IFND	nocarrier
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0		; Nullmodem ?
	bne.b	2$				; jepp, no CD checking.
	move.w	(IO_STATUS,a1),d1		; Henter serial.status
	btst	#5,d1				; Har vi CD ?
	beq.b	2$				; Ja, hopp
	move.b	#NoCarrier,(readcharstatus,NodeBase)
	bra	9$				; No carrier, Logoff !!
	ENDC
2$	move.l	(IO_ACTUAL,a1),d0
	beq	9$
	cmp.l	d0,d2
	bcc.b	3$
	move.l	d2,d0				; Vi har flere uleste bytes enn len.
3$	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a2,(IO_DATA,a1)
	move.l	d0,(IO_LENGTH,a1)
	jsrlib	DoIO
	movea.l	(sreadreq,NodeBase),a1
	move.l	(IO_ACTUAL,a1),d3
	bra	9$

1$	movea.l	(sreadreq,NodeBase),a1		; Setter igang ny request
	move.w	#CMD_READ,(IO_COMMAND,a1)
	move.l	a2,(IO_DATA,a1)
	move.l	d2,(IO_LENGTH,a1)
	jsrlib	SendIO
	move.l	d3,d0
	move.l	#1000000,d1
	bsr	divl
	movea.l	(timer1req,NodeBase),a1
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
	movea.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	4$
	movea.l	(timer1req,NodeBase),a1
	bra.b	5$
4$	and.l	(timer1sigbit,NodeBase),d2
	beq.b	10$
	movea.l	(timer1req,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	beq.b	10$
	movea.l	(sreadreq,NodeBase),a1
5$	jsrlib	AbortIO
	movea.l	(timer1req,NodeBase),a1
	jsrlib	WaitIO
	movea.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	movea.l	(sreadreq,NodeBase),a1
	move.l	(IO_ACTUAL,a1),d3
	move.w	#SDCMD_QUERY,(IO_COMMAND,a1)
	jsrlib	DoIO				; Sjekke flagg
	movea.l	(sreadreq,NodeBase),a1
	IFND	nocarrier
	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_NullModem,d0		; Nullmodem ?
	bne.b	9$				; jepp, no CD checking.
	move.w	(IO_STATUS,a1),d1		; Henter serial.status
	btst	#5,d1				; Har vi CD ?
	beq.b	9$				; Ja, hopp
	move.b	#NoCarrier,(readcharstatus,NodeBase)
	bra.b	6$
	ENDC
9$	move.l	d3,d0
	tst.b	(readcharstatus,NodeBase)
	notz
	bne.b	99$
6$	moveq.l	#-1,d0
99$	movem.l	(sp)+,d2/d3/a2/a6/a4/a5
	rts

sflush	movem.l	a6/a4/a5,-(sp)
	bsr	setupa4a5
	movea.l	(exebase),a6
	movea.l	(sreadreq,NodeBase),a1
	jsrlib	WaitIO
	movea.l	(sreadreq,NodeBase),a1
	move.w	#CMD_CLEAR,(IO_COMMAND,a1)	; Flush'es serial buffers
	jsrlib	DoIO
	movem.l	(sp)+,a6/a4/a5
	rts

update	push	a2/a6/a4/a5/d2/d3
	movea.l	a0,a2
	bsr	setupa4a5
	movea.l	(exebase),a6
	move.l	(windowadr,NodeBase),d0
	beq	9$					; no window
	move.l	(xpru_updatemask,a2),d0
	move.l	d0,d3
	andi.l	#XPRUF_ERRORMSG+XPRUF_BLOCKS+XPRUF_BYTES+XPRUF_ERRORS+XPRUF_TIMEOUTS+XPRUF_EXPECTTIME+XPRUF_ELAPSEDTIME+XPRUF_DATARATE,d0
	beq	9$
	tst.b	(Tinymode,NodeBase)
	bne	9$
	move.b	#13,d0				; starter først på linjen.
	bsr	writeconchar
	move.l	(xpru_blocks,a2),d0
	moveq.l	#4,d1
	moveq.l	#XPRUB_BLOCKS,d2
	bsr	10$
	move.b	#' ',d0
	bsr	writeconchar
	move.l	(xpru_bytes,a2),d0
	moveq.l	#10,d1
	moveq.l	#XPRUB_BYTES,d2
	bsr	10$
	move.b	#' ',d0
	bsr	writeconchar
	movea.l	(xpru_elapsedtime,a2),a0
	moveq.l	#10,d0
	moveq.l	#XPRUB_ELAPSEDTIME,d2
	bsr	20$
	move.b	#' ',d0
	bsr	writeconchar
	movea.l	(xpru_expecttime,a2),a0
	moveq.l	#10,d0
	moveq.l	#XPRUB_EXPECTTIME,d2
	bsr	20$
	move.b	#' ',d0
	bsr	writeconchar
	move.l	(xpru_datarate,a2),d0
	moveq.l	#4,d1
	moveq.l	#XPRUB_DATARATE,d2
	bsr	10$
	move.b	#' ',d0
	bsr	writeconchar
	move.l	(xpru_timeouts,a2),d0
	moveq.l	#4,d1
	moveq.l	#XPRUB_TIMEOUTS,d2
	bsr	10$
	move.b	#' ',d0
	bsr	writeconchar
	move.l	(xpru_errors,a2),d0
	moveq.l	#4,d1
	moveq.l	#XPRUB_ERRORS,d2
	btst	d2,d3				; er denne gyldig ?
	beq.b	1$				; nei
	move.w	d0,(tmpword,NodeBase)		; lagrer errors
1$	bsr	10$
	move.b	#' ',d0
	bsr	writeconchar
	move.l	(xpru_updatemask,a2),d0		; har vi error melding ?
	andi.l	#XPRUF_ERRORMSG,d0
	beq.b	8$				; nei, ut
	movea.l	(xpru_errormsg,a2),a0		; skriver den ut
	bsr	writecontext
	move.b	#10,d0				; ny linje
	bsr	writeconchar
8$	lea	(cleartoEOLtext),a0		; sletter alt etter
	bsr	writecontext
9$	pop	a2/a6/a4/a5/d2/d3
	rts

10$	btst	d2,d3				; er denne gyldig ?
	bne.b	11$				; ja
	move.l	d1,d0				; nei, hopper over plassene
	bra	30$
11$	move.l	d1,-(a7)			; skriver ut tallet
	lea	(tmptext,NodeBase),a0
	bsr	konverter
	move.l	(a7)+,d0
	lea	(tmptext,NodeBase),a0		; og fyller ut alle plassene
	bra	writecontextrfill

20$	btst	d2,d3				; er denne gyldig ?
	beq.b	30$				; nei, hopper over plassene
	bra	writecontextrfill

; d0 = antall posisjoner
30$	lea	(tmptext,NodeBase),a0
	move.b	#$9b,(a0)+
	bsr	konverter
	move.b	#'C',(a0)+
	move.b	#0,(a0)
	lea	(tmptext,NodeBase),a0
	bra	writecontext

chkabort
	push	a4/a5
	bsr	setupa4a5
	moveq.l	#0,d0
	tst.b	(readcharstatus,NodeBase)
	beq.b	9$
	moveq.l	#-1,d0
9$	pop	a4/a5
	rts

gets	moveq.l	#0,d0
	rts

unlink	movem.l	a6/a4/a5,-(sp)
	movea.l	(exebase),a6
	bsr	setupa4a5
	bsr	deletefile
	tst.w	d0
	bne.b	1$
	moveq.l	#-1,d0
	bra.b	9$
1$	moveq.l	#0,d0
9$	movem.l	(sp)+,a6/a4/a5
	rts

	IFD	notyet
setserial
	movem.l	d2/a6/a4/a5,-(sp)
	move.l	d0,d2
	movea.l	(exebase),a6
	bsr	setupa4a5
	movea.l	(sreadreq,NodeBase),a1
	moveq.l	#12*4,d0
1$	subq.l	#4,d0
	bcs.b	2$
	move.l	(IO_BAUD,a1),d1
	lea	(xprbaudates),a0
	cmp.l	(0,a0,d0.w),d1
	bne.b	1$
	lsr.l	#2,d0
2$	andi.l	#$ff,d0
	swap	d0
	moveq	#0,d1
	move.b	(IO_EXTFLAGS+3,a1),d1
	cmpi.b	#8,(IO_READLEN,a1)
	beq.b	3$
	bset	#3,d1
3$	cmpi.b	#8,(IO_WRITELEN,a1)
	beq.b	4$
	bset	#4,d1
4$	cmpi.b	#1,(IO_STOPBITS,a1)
	beq.b	5$
	bset	#2,d1
5$	lsl.w	#8,d1
	or.w	d1,d0
	move.b	(IO_SERFLAGS,a1),d0
	moveq.l	#-1,d1
	cmp.l	d2,d1
	beq	9$
	move.l	d0,d2

	move.b	(IO_SERFLAGS,a1),-(sp)
	move.b	(IO_READLEN,a1),-(sp)
	move.b	(IO_WRITELEN,a1),-(sp)
	move.b	(IO_STOPBITS,a1),-(sp)
	move.l	(IO_BAUD,a1),-(sp)
	move.b	(IO_EXTFLAGS+3,a1),d1
	move.w	d1,-(sp)

	movea.l	(sreadreq,NodeBase),a1
	move.b	d0,(IO_SERFLAGS,a1)
	swap	d0
	lsl.w	#2,d0

	move.w	(Setup+Nodemem,NodeBase),d1
	btst	#SETUPB_Lockedbaud,d1
	bne.b	10$
	lea	(xprbaudates),a0
	move.l	(0,a0,d0.w),(IO_BAUD,a1)
10$	swap	d0
	lsr.w	#8,d0
	move.b	#8,(IO_READLEN,a1)
	move.b	#8,(IO_WRITELEN,a1)
	move.b	#1,(IO_STOPBITS,a1)
	btst	#3,d0
	beq.b	71$
	move.b	#7,(IO_READLEN,a1)
71$	btst	#4,d0
	beq.b	72$
	move.b	#7,(IO_WRITELEN,a1)
72$	btst	#2,d0
	beq.b	73$
	move.b	#2,(IO_STOPBITS,a1)
73$	andi.w	#$3,d0
	move.b	d0,(IO_EXTFLAGS+3,a1)
	move.w	#SDCMD_SETPARAMS,(IO_COMMAND,a1)
	jsrlib	DoIO
	tst.l	d0
	beq.b	6$
	movea.l	(sreadreq,NodeBase),a1
	move.w	(sp)+,d1
	move.b	(sp)+,(IO_EXTFLAGS+3,a1)

	move.w	(Setup+Nodemem,NodeBase),d0
	btst	#SETUPB_Lockedbaud,d0
	bne.b	12$
	addq.l	#4,sp
	bra.b	11$
12$	move.l	(sp)+,(IO_BAUD,a1)
11$	move.b	(sp)+,(IO_STOPBITS,a1)
	move.b	(sp)+,(IO_WRITELEN,a1)
	move.b	(sp)+,(IO_READLEN,a1)
	move.b	(sp)+,(IO_SERFLAGS,a1)
	move.w	#SDCMD_SETPARAMS,(IO_COMMAND,a1)
	jsrlib	DoIO
	moveq.l	#-1,d0
	bra.b	9$
6$	lea	(10,sp),sp
	move.l	d2,d0
9$	movem.l	(sp)+,a6/a4/a5/d2
	rts
	ENDC

	ENDC
		section data,data

; protokollinfo (koden forutsetter 4 tegn)
shortprotocname	dc.b	'Z',0,0,0
		dc.b	'X',0,0,0
		dc.b	'C',0,0,0
		dc.b	'Y',0,0,0
		dc.b	'YB',0,0
		dc.b	'YG',0,0
		dc.b	0,0

protocolisbatch	dc.b	1,0,0,0,1,0

protokollinitstr
		dc.l	xprzmodeminitst
		dc.l	xprxmodeminitst
		dc.l	xprxcmodeminits
		dc.l	xprymodeminitst
		dc.l	xprybmodeminits
		dc.l	xprygmodeminits

protoclname	dc.l	zmodemtext
		dc.l	xmodemtext
		dc.l	xcmodemtext
		dc.l	ymodemtext
		dc.l	ybmodemtext
		dc.l	ygmodemtext

xprzmodeminitst	dc.b	'TN OS B16 F0 AN DN KN SN RN PABBS:FILES/',0
xprxmodeminitst	dc.b	'YS,Z1,C0,B0',0
xprxcmodeminits	dc.b	'YS,Z1,C1,B0',0
xprymodeminitst	dc.b	'YS,Z1,C1,B1',0
xprybmodeminits	dc.b	'YB,Z1',0
xprygmodeminits	dc.b	'YG,Z1',0

zmodemtext	dc.b	'Zmodem',0
xmodemtext	dc.b	'Xmodem',0
xcmodemtext	dc.b	'Xmodem-CRC',0
ymodemtext	dc.b	'Ymodem',0
ybmodemtext	dc.b	'Ymodem batch',0
ygmodemtext	dc.b	'Ymodem-G',0

checkG_Rkode	dc.b	27,'[97x',0
vipparamkode	dc.b	27,'[17x',0
recivefilekoder	dc.b	27,'[49x',0	; z modem
		dc.b	27,'[29x',0	; x modem
		dc.b	27,'[29x',0	; x modem ikke CRC ...
		dc.b	27,'[39x',0	; y modem
		dc.b	27,'[59x',0	; y modem batch
		dc.b	27,'[89x',0	; y modem-G

sendfilekoder	dc.b	27,'[48x',0	; z modem
		dc.b	27,'[28x',0	; x modem
		dc.b	27,'[28x',0	; x modem ikke CRC ...
		dc.b	27,'[38x',0	; y modem
		dc.b	27,'[58x',0	; y modem batch
		dc.b	27,'[88x',0	; y modem-G

logfilemenutext	dc.b	'Entered file menu:',0
secstext	dc.b	' secs',0

	cnop	0,4

		END
