*****************************************************************
*			Browse rutiner				*
*****************************************************************

;browsedebug = 1

 *****************************************************************
 *
 * NAME
 *	Browse.asm
 *
 * DESCRIPTION
 *	Browse rutiner
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: Browse.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: Browse.asm $
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
	include	'msg.pro'

	XDEF	setupbrowse
	XDEF	setuptmpbrowse
	XDEF	cleanuptmpbrowse
	XDEF	addtmpbrowse
	XDEF	dobrowseselect
	XDEF	sendbrowsefiles
	XDEF	setbrowsenodestatus
	XDEF	clearbrowsenodestatus

	XREF	dofileinfoline1
	XREF	writetext
	XREF	writetexto
	XREF	writetexti
	XREF	writetextlen
	XREF	writetextrfill
	XREF	writechari
	XREF	readchar
	XREF	breakoutimage
	XREF	upchar
	XREF	skrivnr
	XREF	skrivnrw
	XREF	konverter
	XREF	konverterw
	XREF	memcopylen
	XREF	dotypeinfofile
	XREF	doviewarchive
	XREF	writeerroro
	XREF	justchecksysopaccess
	XREF	downloadfile1
	XREF	addfilesub1
	XREF	changenodestatus
	XREF	deletefilefromabbs
	XREF	buildfilepath
	XREF	getyorn
	XREF	readlinepromptwhelp
	XREF	findnameicase
	XREF	movefileinabbs
	XREF	strcopy
	XREF	readlinepromptwhelpflush
	XREF	upword
	XREF	strlen
	XREF	getdirnamesub

	XREF	nodehook

	XREF	errsavefilhtext
	XREF	dirnotfoundtext
	XREF	filelistfilname
	XREF	filetablfultext
	XREF	fileihnorettext
	XREF	ansilbluetext
	XREF	ansiclearscreen
	XREF	errloadfilhtext
	XREF	exebase
	XREF	dosbase
	XREF	ansiredtext
	XREF	ansiwhitetext

LINELENGTH	equ	96
BROWSETOP	equ	4
MAXLINES	equ	60

	STRUCTURE	browseblock,0
	UWORD		b_Y		; current line in message
	UWORD		b_P		; line number of first line on screen
	UWORD		NumFiles
	UWORD		Numtagged
	ULONG		TotTaggedKb
	UWORD		TotNumtagged
	ULONG		TaggedKb
	UWORD		b_dirnr
	UBYTE		b_updatetop
	UBYTE		b_Mode
	UWORD		b_lines
	STRUCT		b_Update,MAXLINES
	LABEL		browseblock_SIZEOF

	STRUCTURE	storedfiles,0
	UWORD		s_dirnum
	ULONG		s_filenum
	LABEL		storedfiles_SIZEOF

	STRUCTURE	confinfo,0
	STRUCT		c_confname,Sizeof_NameT
	UBYTE		c_Selected
	LABEL		confinfo_SIZEOF
	

buffersize	equ	480000 ; 5000 linjer...

; d0 = mode (0 = file, 1 = conferences)
setupbrowse
	move.l	(Tmpusermem,NodeBase),a0
	move.w	#-1,(a0)
	lea	(xpriomem,NodeBase),a0			; browsestruktur
	move.b	d0,(b_Mode,a0)				; husker mode
	moveq.l	#0,d0
	move.w	d0,(TotNumtagged,a0)			; sletter totalt filestats
	move.l	d0,(TotTaggedKb,a0)
	clrz
	rts

setbrowsenodestatus
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	9$
	moveq.l	#72,d0
	jsr	(changenodestatus)
9$	rts

clearbrowsenodestatus
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq.b	9$
	moveq.l	#4,d0
	jsr	(changenodestatus)
9$	rts

setuptmpbrowse
	move.l	#buffersize,d0
	moveq.l	#0,d1
	jsrlib	AllocMem
	move.l	d0,(tmpstore,NodeBase)
	beq.b	9$
	move.l	d0,a0
	move.l	#buffersize,d0
	subq.l	#2,d0				; plass til nummer
	divu	#LINELENGTH,d0			; 98 = 93+1 for linje, og 4 for filnr
	move.w	d0,(a0)
	lea	(2,a0),a0
	move.l	a0,(tmpval,NodeBase)
	moveq.l	#-1,d0
	move.l	d0,(a0)
9$	rts

cleanuptmpbrowse
	move.l	(tmpstore,NodeBase),d0
	beq.b	9$
	move.l	d0,a1
	move.l	#buffersize,d0
	jmplib	FreeMem
9$	rts

; a0 = tmpfileentry
; d0 = filenr
; ret: z = 1, array full
addtmpbrowse
	move.l	a0,a1				; husker fileinfo
	move.l	(tmpstore,NodeBase),a0
	move.w	(a0),d1
	bne.b	1$
	lea	(filetablfultext),a0
	jsr	(writetexto)
	setz
	bra.b	9$				; fullt
1$	subq.w	#1,d1
	move.w	d1,(a0)
	move.l	a1,d1				; flytter fileinfo
	move.l	(tmpval,NodeBase),a1
	move.l	d0,(a1)+			; lagrer filummer
	lea	(LINELENGTH-4,a1),a0		; finner addressen til neste (94+4)
	move.l	a0,(tmpval,NodeBase)
	moveq.l	#-1,d0
	move.l	d0,(a0)				; legger ut en markering for siste (skrives over hvis ikke)
	move.l	d1,a0				; endelig er fileinfo riktig!! (tada! :-)
	moveq.l	#Fileentry_SIZEOF,d0
	jsr	(memcopylen)
	clrz
9$	rts

sendbrowsefiles
	push	d2/a2/a3/d7
	jsr	(nodehook)
	link.w	a2,#-160
	move.l	a2,d7
	btst	#DIVB_Browse,(Divmodes,NodeBase) ; er browse aktiv ?
	beq	9$
	moveq.l	#0,d2			; ikke add
	move.l	(Tmpusermem,NodeBase),a0
	move.w	(s_dirnum,a0),d1			; henter fildir*1
	cmp.w	#-1,d1
	beq.b	9$			; vi har ikke valgt noe... ut.
0$	lea	(browsedoprompt),a0
	suba.l	a1,a1
	lea	(browsedoprompth),a2
	jsr	(readlinepromptwhelpflush)
	beq.b	2$			; bare return, eller no carrier
	bsr	upword
	move.b	(a0),d0
	cmp.b	#'D',d0
	beq.b	2$
	cmp.b	#'X',d0
	beq.b	9$
	cmp.b	#'A',d0
	beq.b	3$
	lea	(unknwoncomtext),a0
	jsr	writeerroro
	bra.b	0$

3$	moveq.l	#1,d2					; Vi skal ha add
2$	move.l	(Tmpusermem,NodeBase),a2
	lea	(tmpfileentry,NodeBase),a3
1$	move.w	(s_dirnum,a2),d1			; henter fildir*1
	cmp.w	#-1,d1
	beq.b	9$
	move.l	(s_filenum,a2),d0			; henter filnr
	tst.l	d2					; skal vi ta add ?
	beq.b	4$					; nope
	jsr	(addfilesub1)
	bra.b	5$
4$	bsr	downloadfile1
5$	move.b	(readcharstatus,NodeBase),d0
	bne.b	9$
	lea	(storedfiles_SIZEOF,a2),a2
	bra.b	1$
 
	jsr	writeerroro
9$	move.l	d7,a2
	unlk	a2
	pop	d2/a2/a3/d7
	rts	

	XREF	_Handle_Preview

; d0 = dirnr
dobrowseselect
	push	d2/a3
	IFD	browsedebug
	bsr	opendebug
	ENDC
	bset	#DIVB_InBrowse,(Divmodes,NodeBase)
	lea	(xpriomem,NodeBase),a3			; browsestruktur
	move.w	d0,(b_dirnr,a3)				; husker dirnr
	move.w	#1,(b_Y,a3)
	move.w	#-1,(linesleft,NodeBase)		; Vi vil ikke ha noen more her..
	moveq.l	#0,d0
	move.w	d0,(Numtagged,a3)
	move.l	d0,(TaggedKb,a3)
	move.b	d0,(readlinemore,NodeBase)	; flush'er input
	move.w	d0,(NumFiles,a3)

	move.w	#14,d0				; minimums høyde, var 20
	move.w	(PageLength+CU,NodeBase),d1
	sub.w	#4,d1				; for liten skjerm. Bruker min.
	bcs.b	6$
	cmp.w	d0,d1				; for liten skjerm. Bruker min.
	bls.b	6$
	move.w	d1,d0
	cmpi.w	#MAXLINES,d0			; For mange linjer ?
	bls.b	6$				; nope
	move.w	#MAXLINES,d0			; jepp, bruker max
6$	move.w	d0,(b_lines,a3)

	moveq.l	#1,d2
	move.l	(tmpstore,NodeBase),a0
	lea	(2,a0),a0
	moveq.l	#-1,d1
	move.l	(a0),d0
	cmp.l	d0,d1
	beq	9$					; ingen filer funnet

	moveq.l	#0,d2
	moveq.l	#0,d0
0$	addq.l	#1,d0
	lea	(LINELENGTH,a0),a0
	cmp.l	(a0),d1
	bne.b	0$
	move.w	d0,(NumFiles,a3)
	bsr	drawheader
	bsr	redrawscreen

1$	move.b	(readcharstatus,NodeBase),d1	; noe spess ?
	bne	9$			; ja, kast'n ut
	IFD	browsedebug
	bsr	writedebuginfo
	ENDC
	bsr	updatescreenmaybe
	bsr	readchar
	bmi	2$			; spesial taster
	move.b	(readcharstatus,NodeBase),d1	; noe spess ?
	bne	9$			; ja, kast'n ut

	jsr	(upchar)
	cmp.b	#'P',d0			; JEO Preview?
	bne.b	100$
	bsr	handlepreview
	bra.b	1$

100$	cmp.b	#'N',d0			; next dir ?
	bne.b	5$
	moveq.l	#1,d2
	bra	9$

5$	cmp.b	#'Q',d0			; exit ?
	beq	9$

	cmp.b	#' ',d0			; space ?
	bne.b	3$
	bsr	handlespace
	bra	215$			; går en ned også.. Hvis ikke til 1$

3$	cmp.b	#'V',d0			; View ?
	bne.b	4$
	bsr	handleview
	beq	99$
	bra.b	1$

4$	cmp.b	#'I',d0			; Info ?
	bne.b	7$
	bsr	handleinfo
	beq	99$
	bra.b	1$

7$	cmp.b	#'U',d0			; Untag all ?
	bne.b	8$
	bsr	handleuntag
	bra.b	1$

8$	cmp.b	#'M',d0			; Move ?
	bne.b	10$
	bsr	handlemove
	beq	99$
	bra	1$

10$	cmp.b	#'Z',d0			; Zap ?
	bne	11$
	moveq.l	#0,d0			; vi er ikke CZap
	bsr	handlezap
	bne	1$
	moveq.l	#1,d2			; vi skal videre hvis vi kan
	bra	99$

11$	cmp.b	#'C',d0			; CZap ?
	bne	12$
	moveq.l	#1,d0			; vi er CZap
	bsr	handlezap
	bne	1$
	moveq.l	#1,d2			; vi skal videre hvis vi kan
	bra	99$

12$	cmp.b	#'T',d0			; Touch ?
	bne.b	13$
	bsr	handletouch
	beq	99$
	bra	1$

13$	cmp.b	#'*',d0			; Comment ? JEO
	bne	1$
	bsr	handlecomment
	beq	99$
	bra	1$

2$	cmpi.w	#20,d0			; er det funksjonstaster ?
	bcs	1$			; ja, vil ikke ha dem.
	bhi.b	21$			; 20 = opp
	move.w	(b_Y,a3),d0
	subq.w	#1,d0
	bne.b	201$
	move.w	#1,d0
201$	move.w	d0,(b_Y,a3)
;	add.w	#3,d0
;	bsr	gotoline
	bra	1$

21$	cmpi.w	#21,d0				; 21 = ned
	bne	1$
215$	move.w	(b_Y,a3),d0
	addq.w	#1,d0
	move.w	(NumFiles,a3),d1
	cmp.w	(b_lines,a3),d1			; har vi færre filer en en skjermside ?
	bcc.b	214$
	cmp.w	d0,d1				; ja.
	bcs.b	213$
	bra.b	211$
214$	addq.w	#1,d1				; nei. Gjør plass til <end>
	cmp.w	d1,d0				; numfiles,y
	bcs.b	211$
213$	subq.w	#1,d0
211$	move.w	d0,(b_Y,a3)
	bra	1$

9$	move.w	#BROWSETOP+1,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	move.w	(TotNumtagged,a3),d0
	add.w	(Numtagged,a3),d0
	move.w	d0,(TotNumtagged,a3)
	move.l	(TotTaggedKb,a3),d0
	add.l	(TaggedKb,a3),d0
	move.l	d0,(TotTaggedKb,a3)
	bsr.b	func

99$	bclr	#DIVB_InBrowse,(Divmodes,NodeBase)
	tst.l	d2					; skal vi forstette ?
	pop	d2/a3
	rts

func	push	d2/a2
	move.l	(Tmpusermem,NodeBase),a1
	moveq.l	#-1,d0
2$	cmp.w	(a1),d0
	beq.b	1$
	lea	(storedfiles_SIZEOF,a1),a1
	bra.b	2$
 
1$	move.l	(tmpstore,NodeBase),a0
	lea	2(a0),a0	; Hopper over antallet vi har plass til
	move.w	(NumFiles,a3),d2
	beq.b	9$		; ingen filer
	move.w	(b_dirnr,a3),d0
4$	move.w	(4+Filestatus,a0),d1
	btst	#FILESTATUSB_Selected,d1
	beq.b	3$
	move.w	d0,(s_dirnum,a1)
	move.l	(a0),(s_filenum,a1)
	lea	(storedfiles_SIZEOF,a1),a1
	move.l	(Tmpusermem,NodeBase),d1
	add.l	(UserrecordSize+CStr,MainBase),d1
	sub.l	#storedfiles_SIZEOF+2,d1
	cmp.l	a1,d1
	bcs.b	8$
3$	lea	(LINELENGTH,a0),a0
	subq.w	#1,d2
	bne.b	4$
8$	move.w	#-1,(a1)
9$
	IFD	browsedebug
	bsr	closedebug
	ENDC
	pop	d2/a2
	rts

handlezap
	push	d2
	move.l	d0,d2
	jsr	(justchecksysopaccess)
	beq.b	9$				; ikke lov, glemm komandoen
	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	move.b	#0,(readlinemore,NodeBase)	; Flush'er eventuell input
	lea	(surezaptext),a0
	sub.l	a1,a1
	moveq.l	#0,d0
	jsr	(getyorn)
	beq.b	1$
	lea	(zapfunc),a0
	move.l	d2,d0				; CZap status
	bsr	loopselectedfiles
	move.w	(NumFiles,a3),d0
	beq.b	99$				; ingen filer igjen, ut.
1$	bsr	redrawscreenfull
	bsr	mayfixY
	setz
9$	notz
99$	pop	d2
	rts

zapfunc	push	a2/d3
	link.w	a3,#-160
	move.l	a0,a2
	move.l	d1,d3
	bsr	deletefilefromabbs
	lea	(sp),a1
	lea	(Filename,a2),a0
	move.l	d3,d0
	jsr	(buildfilepath)
	move.l	(dosbase),a6
	move.l	sp,d1
	jsrlib	DeleteFile
	tst.l	d2				; er vi CZap ?
	beq.b	1$				; nope
	subq.w	#1,(Uploaded+CU,NodeBase)		; Oppdaterer Uploaded telleren
	bcc.b	2$
	move.w	#0,(Uploaded+CU,NodeBase)		; ingen underflow..
2$	move.l	(Fsize,a2),d0
	moveq.l	#0,d1
	move.w	#1023,d1
	add.l	d1,d0
	moveq.l	#10,d1
	lsr.l	d1,d0
	sub.l	d0,(KbUploaded+CU,NodeBase)
	bcc.b	1$
	moveq.l	#0,d0
	move.l	d0,(KbUploaded+CU,NodeBase)	; ikke her heller
1$	move.l	(exebase),a6
	setz
	clrn
	unlk	a3
	pop	a2/d3
	rts

; a0 = func to call with the fileentry in a0, filepos in d0, dirnum in d1
; d0 = data to the function (received in d2)
loopselectedfiles
	push	d5/a2/d3/d4/d2
	move.l	a0,d4
	move.l	d0,d2			; stores data
	moveq.l	#0,d3			; har ikke slettet noen fileentry's enda.

	move.l	(tmpstore,NodeBase),a2
	lea	2(a2),a2		; Hopper over antallet vi har plass til
	move.w	(NumFiles,a3),d5
	beq	9$			; ingen filer, ferdig

1$	move.w	(4+Filestatus,a2),d1	; looper igjennom alle filer
	btst	#FILESTATUSB_Selected,d1
	beq.b	2$			; hopper over de som ikke er valgt

	move.w	(b_dirnr,a3),d1
	move.l	(a2),d0
	lea	(4,a2),a0
	move.l	d4,a1
	jsr	(a1)			; kaller prosedyren
	bmi.b	9$
	bne.b	2$			; skal ikke slette info'n

	sub.w	#1,(NumFiles,a3)
	sub.w	#1,(Numtagged,a3)

	move.l	(4+Fsize,a2),d1
	beq.b	4$
	moveq.l	#10,d0
	lsr.l	d0,d1
4$	sub.l	d1,(TaggedKb,a3)
	move.l	a2,a1			; fjerner den fra lista
	lea	(LINELENGTH,a2),a0
	move.l	d5,d0
	mulu	#LINELENGTH,d0
	jsr	(memcopylen)
	moveq.l	#1,d3
	bra.b	3$

2$	lea	(LINELENGTH,a2),a2
3$	subq.w	#1,d5
	bne.b	1$

	tst.l	d3			; har vi slettet noen ?
	beq.b	9$
	move.w	#1,(b_Y,a3)
;	bsr	redrawscreenfull	; ja, da tar vi full redraw
9$	pop	d5/a2/d4/d3/d2
	rts

handlemove
	push	a2
	jsr	(justchecksysopaccess)
	notz
	bne.b	9$			; ikke lov, glemm komandoen
	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	lea	(movetowhdirtext),a0
	lea	(filelistfilname),a1
	suba.l	a2,a2				; ingen ekstra help
	bsr	readlinepromptwhelp
	bne.b	2$
	move.w	#-1,(linesleft,NodeBase)
	setz
	bra.b	9$
2$	move.w	#-1,(linesleft,NodeBase)	; Vi vil ikke ha more lenger..
	bsr	getdirnamesub
	bne.b	1$
	jsr	readchar
	beq.b	9$
	bra.b	8$

1$	lsr.w	#1,d0
	and.l	#$ffff,d0			; fjerner høye bits..
	lea	(movefunc),a0
	bsr	loopselectedfiles
	move.w	(NumFiles,a3),d0
	beq.b	9$				; ingen filer igjen, ut.

8$	bsr	redrawscreenfull
	bsr	mayfixY
	clrz
9$	pop	a2
	rts

movefunc
	push	a2/d2/d3
	move.l	a0,a2
	move.l	d1,d3
	moveq.l	#0,d1				; not to set private to conf
	exg	d2,d3				; swap to correct place
	jsr	(movefileinabbs)
	bne.b	1$
	exg	a2,a0
	lea	(Filename,a0),a0
	bsr	writetexto
	move.l	a2,a0
	bsr	writeerroro
	jsr	readchar
	bne.b	9$
	setn					; ut av loopen
	bra.b	99$
1$	setz					; fila skal slettes fra fillista
9$	clrn
99$	pop	a2/d2/d3
	rts

handletouch
	jsr	(justchecksysopaccess)
	notz
	bne.b	9$			; ikke lov, glem komandoen
	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	move.b	#0,(readlinemore,NodeBase)	; Flush'er eventuell input
	lea	(suretouchtext),a0
	sub.l	a1,a1
	moveq.l	#0,d0
	jsr	(getyorn)
	beq.b	1$
	lea	(touchfunc),a0
	bsr	loopselectedfiles
1$	bsr	redrawscreenfull
	bsr	mayfixY
	setz
9$	notz
99$	rts

touchfunc
	push	a2/d2/d3
	move.l	a0,a2
	move.l	d0,d2
	move.l	d1,d3
	move.l	dosbase,a6
	lea	(ULdate,a2),a0			; opdaterer dato
	move.l	a0,d1
	jsrlib	DateStamp
	move.l	(exebase),a6
	andi.w	#~(FILESTATUSF_Selected),(Filestatus,a2)
	move.l	(msg,NodeBase),a1		; updater retractee.
	move.w	#Main_savefileentry,(m_Command,a1)
	move.l	d2,(m_arg,a1)		; filpos.
	move.l	d3,(m_UserNr,a1)
	move.l	a2,(m_Data,a1)
	jsr	(handlemsg)
	ori.w	#FILESTATUSF_Selected,(Filestatus,a2)
	move.l	(msg,NodeBase),a1
	move.w	(m_Error,a1),d1
	cmpi.w	#Error_OK,d1
	beq.b	9$
	lea	(Filename,a2),a0
	bsr	writetexto
	lea	(errsavefilhtext),a0
	bsr	writeerroro
	jsr	readchar
	bne.b	9$
	setn					; ut av loopen
	bra.b	99$
9$	clrn
99$	clrz
	pop	a2/d2/d3
	rts

handleuntag
	move.l	(tmpstore,NodeBase),a0
	lea	(2,a0),a0		; Hopper over antallet vi har plass til
	move.w	(NumFiles,a3),d0
	beq.b	9$			; ingen filer
	move.b	(b_Mode,a3),d1		; hvilken mode ?
	bne.b	2$			; ikke fileinfo


1$	move.w	(4+Filestatus,a0),d1
	bclr	#FILESTATUSB_Selected,d1
	move.w	d1,(4+Filestatus,a0)
	lea	(LINELENGTH,a0),a0
	subq.w	#1,d0
	bne.b	1$
	bra.b	3$

2$	bclr	#0,(c_Selected+4,a0)
	lea	(LINELENGTH,a0),a0
	subq.w	#1,d0
	bne.b	2$

3$	moveq.l	#0,d0
	move.w	d0,(Numtagged,a3)
	move.l	d0,(TaggedKb,a3)
	bsr	redrawscreenfull
	bsr	mayfixY
9$	rts

handlepreview
	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	move.w	(b_Y,a3),d0
	subq.w	#1,d0
	move.l	(tmpstore,NodeBase),a0
	move.l	a0,a2
	lea	(2+4,a0),a0
	mulu	#LINELENGTH,d0
	add.l	d0,a0
	move.w	(b_dirnr,a3),d0
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)	; enabler more igjen
	move.b	(CommsPort+Nodemem,NodeBase),d1	; internal node
	push	d2-d6/a1-a3
	jsr	_Handle_Preview
	pop	d2-d6/a1-a3
	beq.b	9$
	move.w	#-1,(linesleft,NodeBase)			; Vi vil ikke ha noen more her..
	lea	(endtext),a0
	bsr	writetexto
	beq.b	9$
	jsr	readchar
	beq.b	9$
	bsr	redrawscreenfull
	bsr	mayfixY
	clrz
9$	rts

handleinfo
	push	a2
	move.w	(b_Y,a3),d0
	subq.w	#1,d0
	move.l	(tmpstore,NodeBase),a2
	lea	(2+4,a2),a2
	mulu	#LINELENGTH,d0
	add.l	d0,a2
	jsr	justchecksysopaccess
	bne.b	1$
	move.l	(Infomsgnr,a2),d0
	notz
	bne.b	9$
1$	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)	; enabler more igjen
	move.l	a2,a0
	jsr	(dotypeinfofile)
	move.w	#-1,(linesleft,NodeBase)			; Vi vil ikke ha more lenger..
	move.b	(readcharstatus,NodeBase),d0	; noe galt ?
	notz
	beq.b	9$				; jepp.
	lea	(endtext),a0
	bsr	writetexto
	beq.b	9$
	jsr	readchar
	beq.b	9$
	bsr	redrawscreenfull
	bsr	mayfixY
	clrz
9$	pop	a2
	rts

handlecomment	; JEO
	push	a2
	move.w	(b_Y,a3),d0
	subq.w	#1,d0
	move.l	(tmpstore,NodeBase),a2
	lea	(2+4,a2),a2
	mulu	#LINELENGTH,d0
	add.l	d0,a2
	jsr	justchecksysopaccess
	bne.b	1$
	move.l	(Filedescription,a2),a2
	notz
	bne.b	9$
1$	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
;	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)	; enabler more igjen
	move.l	a2,a0
	jsr	(writetexto)
;	move.w	#-1,(linesleft,NodeBase)			; Vi vil ikke ha more lenger..
	move.b	(readcharstatus,NodeBase),d0	; noe galt ?
	notz
	beq.b	9$				; jepp.
	lea	(endtext),a0
	bsr	writetexto
	beq.b	9$
	jsr	readchar
	beq.b	9$
	bsr	redrawscreenfull
	bsr.b	mayfixY
	clrz
9$	pop	a2
	rts

handleview
	move.w	#BROWSETOP+2,d0
	add.w	(b_lines,a3),d0
	bsr	gotoline
	move.w	(b_Y,a3),d0
	subq.w	#1,d0
	move.l	(tmpstore,NodeBase),a0
	move.l	a0,a2
	lea	(2+4,a0),a0
	mulu	#LINELENGTH,d0
	add.l	d0,a0
	move.w	(b_dirnr,a3),d0
	move.w	(PageLength+CU,NodeBase),(linesleft,NodeBase)	; enabler more igjen
	jsr	(doviewarchive)
	beq.b	9$
	move.w	#-1,(linesleft,NodeBase)			; Vi vil ikke ha noen more her..
	lea	(endtext),a0
	bsr	writetexto
	beq.b	9$
	jsr	readchar
	beq.b	9$
	bsr	redrawscreenfull
	bsr.b	mayfixY
	clrz
9$	rts

mayfixY	move.w	(NumFiles,a3),d0
	sub.w	(b_P,a3),d0
	bcs.b	1$
	cmp.w	(b_lines,a3),d0
	bcc.b	9$
1$	addq.w	#1,(b_Y,a3)
9$	rts

updatescreenmaybe
	push	d2/a2/d3
	link.w	a2,#-160
	move.l	a2,d3
	bsr	20$			; har vi input ?
	bne	9$			; jepp, da skip'er vi

	move.w	(b_P,a3),d0		; har vi scrollet oppover ?
	move.w	(b_Y,a3),d1
	cmp.w	d0,d1			; er p mindre eller lik y ?
	bcc.b	2$			; ja, alt ok
	sub.w	d1,d0			;
	cmpi.w	#6,d0			; er forskjellen større en 6 ?
	bls.b	4$			; nope
	bsr	redrawscreen		; ja, redraw'er alt.
	bra.b	3$

4$	move.w	d0,d1
	move.w	#BROWSETOP,d0
	bsr	InsertLines
	move.w	(b_Y,a3),(b_P,a3)
	bsr	test_p
	bra.b	3$

2$	add.w	(b_lines,a3),d0
	subq.w	#1,d0
	cmp.w	d0,d1
	bls.b	3$
	sub.w	d0,d1
	cmpi.w	#6,d1
	bls.b	5$
	bsr	redrawscreen
	bra.b	3$

5$	move.w	#BROWSETOP,d0
	bsr	DeleteLines
	move.w	(b_Y,a3),d0
	sub.w	(b_lines,a3),d0
	addq.w	#1,d0
	move.w	d0,(b_P,a3)
	bsr	test_p
3$	lea	(b_Update,a3),a2
	move.w	#0,d2

6$	bsr	20$				; er det input på gang  ?
	bne	9$				; jepp, da avbryter vi
	move.b	(a2)+,d1			; skal den oppdateres ?
	beq	7$				; nei.
	move.w	d2,d0
	addq.w	#4,d0
	bsr	gotolinenoout
	move.w	d2,d0
	add.w	(b_P,a3),d0
	subq.w	#1,d0
	move.l	(tmpstore,NodeBase),a0
	lea	(2+4,a0),a0
	mulu	#LINELENGTH,d0
	add.l	d0,a0
	move.l	(-4,a0),d0
	moveq.l	#-1,d1
	cmp.l	d0,d1
	bne.b	8$
	subq.w	#1,(b_Y,a3)
	bne.b	801$
	move.w	#1,(b_Y,a3)
801$	lea	(endtext),a0
	bra.b	61$

8$	lea	sp,a1
	bsr	getlinestring
	lea	sp,a0
	move.b	(-1,a2),d0
; Tilbake til gammel browse
;	cmp.b	#3,d0
;	bne.b	603$
;	lea	(deltoeoltext),a0
;	bra.b	61$
603$	subq.b	#1,d0				; full update ?
	bne.b	61$				; jepp
	move.l	a0,a1
60$	move.b	(a1)+,d0
	cmp.b	#' ',d0
	bne.b	60$
601$	move.b	(a1)+,d0
	cmp.b	#' ',d0
	beq.b	601$
602$	move.b	(a1)+,d0
	cmp.b	#' ',d0
	bne.b	602$

	move.l	a1,d0
	sub.l	a0,d0
	subq.l	#1,d0
	jsr	(writetextlen)
	jsr	(breakoutimage)
	bra.b	62$
61$	jsr	(writetexti)

62$	move.b	#0,(-1,a2)			; clear'er oppdaterings requesten

7$	addq.w	#1,d2
	cmp.w	(b_lines,a3),d2
	bcs	6$

	bsr.b	20$				; er det input på gang  ?
	bne.b	9$				; jepp, da avbryter vi
	bsr	updatetopheader

	move.w	(b_Y,a3),d0
	sub.w	(b_P,a3),d0
	bcc.b	71$
	move.w	#0,d0
	addq.w	#1,(b_Y,a3)
71$	addq.w	#4,d0
	bsr	gotoline

9$	move.l	d3,a2
	unlk	a2
	pop	d2/a2/d3
	rts

20$			; CheckInput
; returnerer Z = 0, når vi har nytt tegn
	move.l	(creadreq,NodeBase),d0
	beq.b	22$
	move.l	d0,a1
	jsrlib	CheckIO
	tst.l	d0
	bne.b	28$				; Ja, vi har et tegn
22$
	IFND DEMO
	tst.b	(CommsPort+Nodemem,NodeBase)	; Skal denne noden være serial ?
	beq.b	21$
	movea.l	(sreadreq,NodeBase),a1
	jsrlib	CheckIO
	tst.l	d0
	bne.b	28$				; Ja, vi har et tegn
	ENDC
21$	setz					; nope. Ikke noe tegn
28$	clrn
	rts

handlespace
	push	a2/d2
	move.w	(b_Y,a3),d0
	subq.w	#1,d0
	move.l	(tmpstore,NodeBase),a2
	lea	(2,a2),a2
	mulu	#LINELENGTH,d0
	add.l	d0,a2

	move.b	(b_Mode,a3),d0			; hvilken mode ?
	beq.b	1$				; fileinfo
	bchg	#0,(c_Selected+4,a2)
	bra.b	3$

1$	lea	(4,a2),a2
	move.l	(Fsize,a2),d1
	beq.b	5$
	moveq.l	#10,d0
	lsr.l	d0,d1
5$	move.w	(Filestatus,a2),d0
	bchg	#FILESTATUSB_Selected,d0
	bne.b	2$				; ikke valgt

	move.w	d0,(Filestatus,a2)
	addq.w	#1,(Numtagged,a3)		; velger
	add.l	d1,(TaggedKb,a3)
	bra.b	3$

2$	move.w	d0,(Filestatus,a2)		; velger bort igjen
	subq.w	#1,(Numtagged,a3)
	sub.l	d1,(TaggedKb,a3)

3$	move.w	(b_Y,a3),d0
	sub.w	(b_P,a3),d0
	move.b	#1,(b_updatetop,a3)
	move.b	(b_Update,a3,d0.w),d1
	bne.b	4$
	move.b	#1,(b_Update,a3,d0.w)
4$	pop	a2/d2
	rts

redrawscreenfull
	move.b	(readcharstatus,NodeBase),d0		; skjedd noe ?
	bne.b	9$					; ja, ut
	push	d2
	lea	(ansiclearscreen),a0
	bsr	writetext
	move.b	(b_Mode,a3),d0				; hvilken mode ?
	bne.b	1$					; ikke fileinfo ..
	move.w	(b_dirnr,a3),d0
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	mulu.w	#FileDirRecord_SIZEOF,d0
	lea	(n_DirName,a0,d0.l),a0
	bsr	writetext
1$	bsr	drawheader
	move.w	(b_P,a3),d2
	bsr.b	redrawscreen
	move.w	d2,(b_P,a3)
	bsr	test_p
	pop	d2
9$	rts

redrawscreen
	lea	(b_Update,a3),a0
	move.w	(b_lines,a3),d0
	lea	(0,a0,d0.w),a1			; slutten
	move.w	(NumFiles,a3),d1
; Tilbake til gammel browse
;	add.w	#1,d1
;	sub.w	(b_Y,a3),d1
;	bcc.b	2$
;	moveq.l	#0,d0
2$	cmp.w	d0,d1				; b_lines <= numfiles ?
	bcc.b	1$				; jepp
	move.w	d1,d0				; nei, tar den isteden
	addq.w	#1,d0				; setter av plass til <end> også
1$	move.b	#2,(a0)+			; full redraw
	subq.w	#1,d0
	bcs.b	4$
	bne.b	1$
4$	cmp.l	a0,a1				; er vi ferdige ? (har vi tatt alle ?)
	bls.b	3$				; jepp
	move.b	#0,(a0)+			; nei, resten skal ikke updates
; Tilbake til gammel browse
;	move.b	#3,(a0)+			; nei, resten skal slettes
	bra.b	4$				; sjekk igjen
3$	move.w	(b_Y,a3),(b_P,a3)

	bsr.b	test_p
	move.b	#1,(b_updatetop,a3)
	rts

test_p	move.w	(b_P,a3),d0			; henter p
	add.w	(b_lines,a3),d0			; p + antall linjer
	cmp.w	(NumFiles,a3),d0	
	bls.b	9$				; numfiles er større, ferdig
	move.w	(NumFiles,a3),d0	
	add.w	#2,d0			
	sub.w	(b_lines,a3),d0		
	bcc.b	1$
2$	moveq.l	#1,d0
1$	beq.b	2$
	cmp.w	(b_Y,a3),d0			; safety. Er Y < P ?
	bls.b	3$				; nei
	move.w	(b_Y,a3),d0			; ja, det får den ikke være
3$	move.w	d0,(b_P,a3)			; fikser b_P igjen
9$	rts

gotoline
	bsr.b	gotolinenoout
	jmp	(breakoutimage)

gotolinenoout
	move.w	d0,-(a7)
	lea	(ansipos1text),a0
	jsr	(writetext)
	move.w	(a7)+,d0
	and.l	#$ffff,d0
	jsr	(skrivnr)
	lea	(ansipos2text),a0
	jmp	(writetext)

drawheader
	lea	(ansifilhpostext),a0
	bsr	writetext
	lea	(greentext),a0
	bsr	writetexti
	lea	(fileihnorettext),a0
	move.b	(b_Mode,a3),d0			; hvilken mode ?
	beq.b	3$				; fileinfo
	lea	(conferencetext),a0
3$	bsr	writetexti
	move.w	#BROWSETOP,d0
	add.w	(b_lines,a3),d0
	bsr.b	gotolinenoout
	bsr	getbottomline

2$	bsr	writetexti
	move.b	(b_Mode,a3),d0			; hvilken mode ?
	bne.b	9$				; ikke fileinfo ..
	lea	(topheader1text),a0
	bsr	writetext
	lea	(topheader2text),a0
	bsr	writetexti
9$
;	bra.b	updatetopheader

updatetopheader
	move.b	(b_updatetop,a3),d0		; trengs update ?
	beq.b	9$				; nei
	move.b	(b_Mode,a3),d0			; hvilken mode ?
	bne.b	9$				; ikke fileinfo ..
	move.b	#0,(b_updatetop,a3)
	link.w	a2,#-80
	lea	(ansilbluetext),a0
	bsr	writetext
	lea	(topheader1pos),a0
	bsr	writetext
	move.w	(Numtagged,a3),d0
	add.w	(TotNumtagged,a3),d0
	lea	sp,a0
	jsr	(konverterw)
	lea	sp,a0
	moveq.l	#3,d0
	jsr	(writetextrfill)

	lea	(topheader2pos),a0
	bsr	writetext
	move.l	(TaggedKb,a3),d0
	add.l	(TotTaggedKb,a3),d0
	lea	sp,a0
	jsr	(konverter)
	lea	sp,a0
	moveq.l	#6,d0
	jsr	(writetextrfill)
	move.b	#'K',d0
	bsr	writechari
	unlk	a2
9$	rts

; insert d1 (N) linjer på plass d0 (L)
InsertLines
	push	d2/d3
	move.w	d0,d2
	move.w	d1,d3
; d2 = L
; d3 = N
	move.w	#BROWSETOP,d0
	add.w	(b_lines,a3),d0
	sub.w	d3,d0
;	addq.w	#1,d0
	bsr	gotolinenoout
	move.w	d3,d0
	bsr	ControlDelete
	move.w	d2,d0
	bsr	gotolinenoout
	move.w	d3,d0
	bsr	ControlInsert

	lea	(b_Update,a3),a1
	move.w	(b_lines,a3),d0
	lea	(0,a1,d0.w),a1
	move.l	a1,a0
	and.l	#$ffff,d3
	sub.l	d3,a0

	move.w	(b_lines,a3),d0
	sub.w	d2,d0
	sub.w	d3,d0
	addq.w	#BROWSETOP,d0

1$	move.b	-(a0),-(a1)
	subq.w	#1,d0
	bne.b	1$
	move.w	d3,d0
2$	move.b	#2,-(a1)
	subq.w	#1,d0
	bne.b	2$
	pop	d2/d3
	rts

; delete d1 (N) linjer på plass d0 (L)
DeleteLines
	push	d2/d3
	move.w	d0,d2
	move.w	d1,d3
; d2 = L
; d3 = N
	bsr	gotolinenoout
	move.w	d3,d0
	bsr.b	ControlDelete

	move.w	#BROWSETOP,d0
	add.w	(b_lines,a3),d0
	sub.w	d3,d0
	bsr	gotolinenoout
	move.w	d3,d0
	bsr.b	ControlInsert
	subq.w	#BROWSETOP,d2				; justerer updata data'ene også

	move.w	(b_lines,a3),d0
	sub.w	d2,d0
	sub.w	d3,d0
	lea	(b_Update,a3,d2.w),a0
	add.w	d3,d2
	lea	(b_Update,a3,d2.w),a1

1$	move.b	(a1)+,(a0)+
	subq.w	#1,d0
	bne.b	1$
	move.w	d3,d0
2$	move.b	#2,(a0)+
	subq.w	#1,d0
	bne.b	2$
	pop	d2/d3
	rts

;d0 = antall linjer
ControlDelete
	move.l	d2,-(a7)
	move.w	d0,d2
1$	lea	(Deletetext),a0
	jsr	(writetexti)
	subq.w	#1,d2
	bne.b	1$
	move.l	(a7)+,d2
	rts

;d0 = antall linjer
ControlInsert
	move.l	d2,-(a7)
	move.w	d0,d2
1$	lea	(Inserttext),a0
	jsr	(writetexti)
	subq.w	#1,d2
	bne.b	1$
	move.l	(a7)+,d2
	rts

; a0 = info
; a1 = string
; a3 = browseblock
getlinestring
	move.b	(b_Mode,a3),d0			; hvilken mode ?
	bne.b	1$				; ikke fileinfo
	move.w	(b_dirnr,a3),d5
	jsr	(dofileinfoline1)		; generer tekst stringen
	bra.b	9$
1$	push	a0				; conf
	move.l	#ansiredtext,d1
	move.b	(c_Selected,a0),d0
	bne.b	11$
	move.l	#ansilbluetext,d1
11$	move.l	d1,a0
	jsr	(strcopy)
	subq.l	#1,a1
	pop	a0
	jsr	(strcopy)

9$	rts

getbottomline
	move.b	(b_Mode,a3),d0			; hvilken mode ?
	bne.b	1$				; ikke fileinfo
	jsr	(justchecksysopaccess)
	beq.b	2$
	lea	(botom1head2text),a0
	bra.b	9$
2$	lea	(botom1head1text),a0
	bra.b	9$

1$	lea	(botom2head2text),a0

9$	rts

	IFD	browsedebug
writedebuginfo
	move.w	(b_Y,a3),d0
	bsr	skrivdebugnrw
	bsr	dospace
	move.w	(b_P,a3),d0
	bsr	skrivdebugnrw
	bsr	dospace
	move.w	(b_lines,a3),d0
	bsr	skrivdebugnrw
	bsr	dospace
	move.w	(NumFiles,a3),d0
	bsr	skrivdebugnrw
	bsr	donl
	rts

skrivdebugnrw
	andi.l	#$ffff,d0

; d0 = tall
skrivdebugnr
	push	d2/d3/a6
	link.w	a2,#-80
	move.l	sp,a0
	jsr	(konverter)
	move.l	sp,a0
	jsr	(strlen)
	move.l	debugwin,d1
	beq.b	9$
	move.l	sp,d2
	move.l	d0,d3
	move.l	dosbase,a6
	jsrlib	Write
9$	unlk	a2
	pop	d2/d3/a6
	rts

dospace	push	d2/d3/a6
	move.l	debugwin,d1
	beq.b	9$
	move.l	#space,d2
	moveq.l	#1,d3
	move.l	dosbase,a6
	jsrlib	Write
9$	pop	d2/d3/a6
	rts

donl	push	d2/d3/a6
	move.l	debugwin,d1
	beq.b	9$
	move.l	#nl,d2
	moveq.l	#1,d3
	move.l	dosbase,a6
	jsrlib	Write
9$	pop	d2/d3/a6
	rts

closedebug
	push	a6
	move.l	debugwin,d1
	beq.b	9$
	move.l	dosbase,a6
	jsrlib	Close
9$	pop	a6
	rts

opendebug
	push	a6/d2
	move.l	#debugwinname,d1
	move.l	#MODE_NEWFILE,d2
	move.l	dosbase,a6
	jsrlib	Open
	move.l	d0,debugwin
	pop	a6/d2
	rts
	ENDC
	section data,data

	IFD	browsedebug
debugwin	dc.l	0
debugwinname	dc.b	'con:0/0/640/200/Yo',0
nl		dc.b	10
space		dc.b	' '
	ENDC

Inserttext	dc.b	'[1L',0
Deletetext	dc.b	'[1M',0
ansifilhpostext	dc.b	'[2;1H[0;36m',0
conferencetext	dc.b	'Conference name',10
		dc.b	'---------------',0
botom1head1text	dc.b	'Space tags/untags,View,Info,Next dir,Quit(exit),Untag all',0
botom1head2text	dc.b	'Space tags/untags,View,Info,Next dir,Quit(exit),Untag all,Zap,Move,Touch,Czap.',0
botom2head1text	dc.b	'Space tags/untags,Info,Next,Quit(exit),Untag all',0
botom2head2text	dc.b	'Space tags/untags,Info,Quit(exit),Untag all',0
topheader1text	dc.b	'[1;30H[0;36mTagged files:',0
topheader2text	dc.b	'[1;54HTagged size:',0
topheader1pos	dc.b	'[1;45H',0
topheader2pos	dc.b	'[1;69H',0
ansipos1text	dc.b	'[',0
ansipos2text	dc.b	';1H',0
endtext		dc.b	'[37m<end>'
deltoeoltext	dc.b	'[K',0
surezaptext	dc.b	'Sure you want to ZAP all marked files ',0
suretouchtext	dc.b	'Sure you want to Touch all marked files ',0
movetowhdirtext	dc.b	'Move to what directory',0
browsedoprompt	dc.b	'<D>ownload, <A>dd to hold or e<X>it',0
browsedoprompth	dc.b	'<Down/Add/X>',0
unknwoncomtext	dc.b	'Unknown command',0
greentext	dc.b	'[32m',0


	END
