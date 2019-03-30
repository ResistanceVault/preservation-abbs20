******************************************************************************
******									******
******		      ABBS - Amiga Bulletin Board System		******
******			 Written By Geir Inge Høsteng			******
******									******
******************************************************************************

 *****************************************************************
 *
 * NAME
 *	FSE.asm
 *
 * DESCRIPTION
 *	FullScreen editor for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: FSE.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: FSE.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST

	include	'exec/types.i'
	include	'dos/dos.i'

	include	'asm.i'
	include	'bbs.i'
	include	'fse.i'
	include	'node.i'

	LIST

	XDEF	fseeditor

	XREF	dosbase
	XREF	exebase
	XREF	getfullnamewithreq
	XREF	getline
	XREF	konverter
	XREF	konverterw
	XREF	readchar
	XREF	skrivnr
	XREF	strcopy
	XREF	strcopymaxlen
	XREF	strlen
	XREF	strrcopy
	XREF	upchar
	XREF	writechar
	XREF	writechari
	XREF	writetexti
	XREF	writetextleni
	XREF	writetextmemi
	XREF	writetext
	XREF	nodehook
	XREF	dosnip
	XREF	justchecksysopaccess

	XREF	spacetext
	XREF	enterffnametext
	XREF	privatemsgtext
	XREF	tonoansitext
	XREF	bordertext
	XREF	subjecttext
	XREF	abortmsgtext
	XREF	ansiyellowtext
	XREF	ansiredtext

	XDEF	NormAtttext
	XDEF	ansiclearsctext


;*****************************************************************************
; Full Screen editor.
;*****************************************************************************


;d0 - x
;d1 - y
MoveCursor
	cmp.w	(FizzX,a3),d0
	bne.b	1$
	cmp.w	(FizzY,a3),d1
	beq.b	9$
1$	move.w	d0,(FizzX,a3)
	move.w	d1,(FizzY,a3)
	bsr	ControlCursor
9$	rts

InsertLines
	movem.l	d2/d3/d4,-(a7)
	move.w	d0,d2
	move.w	d1,d3
; d2 = L
; d3 = N
; d4 = I
	move.w	#1,d0
	move.w	(WindowEnd,a3),d1
	sub.w	d3,d1
	addq.w	#1,d1
	bsr.b	MoveCursor
	move.w	d3,d0
	bsr	ControlDelete
	move.w	#1,d0
	move.w	d2,d1
	bsr.b	MoveCursor
	move.w	d3,d0
	bsr	ControlInsert
	move.w	(WindowEnd,a3),d4
	lea	(ScreenUpd,a3),a0
	lea	(ScreenClr,a3),a1
1$	move.w	d2,d0
	add.w	d3,d0
	cmp.w	d4,d0
	bhi.b	3$
	move.w	d4,d0
	sub.w	d3,d0
	move.b	(0,a0,d0.w),(0,a0,d4.w)
	move.b	(0,a1,d0.w),(0,a1,d4.w)
	bra.b	2$
3$	move.b	#1,(0,a0,d4.w)
	move.b	#1,(0,a1,d4.w)
2$	subq.w	#1,d4
	cmp.w	d4,d2
	bls.b	1$
	movem.l	(a7)+,d2/d3/d4
	rts

DeleteLines
	movem.l	d2/d3/d4,-(a7)
	move.w	d0,d2
	move.w	d1,d3
; d2 = L
; d3 = N
; d4 = I
	move.w	#1,d0
	move.w	d2,d1
	bsr	MoveCursor
	move.w	d3,d0
	bsr	ControlDelete
	move.w	d2,d4
	lea	(ScreenUpd,a3),a0
	lea	(ScreenClr,a3),a1
1$	move.w	(WindowEnd,a3),d0
	sub.w	d3,d0
	cmp.w	d4,d0
	bcs.b	3$
	move.w	d4,d0
	add.w	d3,d0
	move.b	(0,a0,d0.w),(0,a0,d4.w)
	move.b	(0,a1,d0.w),(0,a1,d4.w)
	bra.b	2$
3$	move.b	#1,(0,a0,d4.w)
	move.b	#1,(0,a1,d4.w)
2$	addq.w	#1,d4
	cmp.w	(WindowEnd,a3),d4
	bls.b	1$
	movem.l	(a7)+,d2/d3/d4
	rts

PadLine		; ensure that all chars lower than X exist
	move.l	(FSEbuffer,a3),a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a0
	move.l	a0,-(a7)
	bsr	strlen
	movea.l	(a7)+,a0
	move.w	(X,a3),d1
	subq.w	#1,d1
	cmp.w	d1,d0
	bcc.b	9$
	adda.l	d0,a0
1$	move.b	#' ',(a0)+
	addq.l	#1,d0
	cmp.w	d0,d1
	bcc.b	1$
	move.b	#0,(a0)
9$	rts

UnPadLine	; strip trailing blanks
	move.l	(FSEbuffer,a3),a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a0
	move.l	a0,-(a7)
	bsr	strlen
	movea.l	(a7)+,a0
	beq.b	9$
	adda.l	d0,a0
1$	cmpi.b	#' ',-(a0)
	bne.b	2$
	subq.l	#1,d0
	bne.b	1$
	subq.l	#1,a0
2$	move.b	#0,(1,a0)
9$	rts

; d0 = pos
MarkIt	movem.l	d2/d3,-(a7)	; remember to update from current position
	move.w	d0,d2
; d2 - pos
; d3 - Z
	move.w	(Y,a3),d3
	cmp.w	(NrLines,a2),d3
	bls.b	1$
	move.w	d3,(NrLines,a2)
1$	sub.w	(P,a3),d3
	addq.w	#WindowTop,d3	; Z = Y-P+WindowTop
	move.w	(Y,a3),d0
	cmp.w	(P,a3),d0
	bcs.b	9$
	move.w	(P,a3),d1
	add.w	(WindowSiz,a3),d1
	cmp.w	d0,d1
	bcs.b	9$
	lea	(ScreenUpd,a3),a0
	moveq.l	#0,d0
	move.b	(0,a0,d3.w),d0
	cmp.w	d0,d2
	bcc.b	9$
	move.b	d2,(0,a0,d3.w)
9$	movem.l	(a7)+,d2/d3
	rts

DoLineDelete
	movem.l	d2/d3/d4/d5,-(a7)
	move.l	a2,-(a7)
	move.w	d0,d2
; d2 = N
; d3 = I
; d5 = LinesSize
	move.l	(FSEbuffer,a3),a2
	moveq.l	#0,d5
	move.b	#LinesSize,d5
	move.w	(MaxFSEbufferlines,a3),d4
	subq.w	#1,d4
	mulu.w	d5,d4
	move.w	d2,d3
	subq.w	#1,d3
	mulu.w	d5,d3
1$	lea	(0,a2,d3.l),a1
	add.l	d5,d3
	lea	(0,a2,d3.l),a0
	bsr	strcopy
	cmp.l	d3,d4
	bcc.b	1$
	move.w	(MaxFSEbufferlines,a3),d0
	subq.w	#1,d0
	mulu.w	d5,d0
	move.b	#0,(0,a2,d0.l)
	cmp.w	(P,a3),d2
	bcs.b	2$
	move.w	(P,a3),d0
	add.w	(WindowSiz,a3),d0
	cmp.w	d0,d2
	bhi.b	2$
	move.w	d2,d0
	sub.w	(P,a3),d0
	addq.w	#WindowTop,d0
	move.w	#1,d1
	bsr	DeleteLines
2$	movea.l	(a7)+,a2
	cmp.w	(NrLines,a2),d2
	bhi.b	9$			; Mike har bcc her.
	subq.w	#1,(NrLines,a2)
9$	movem.l	(a7)+,d2/d3/d4/d5
	rts

DoLineInsert
	movem.l	d2/d3/d4/d5,-(a7)
	move.l	a2,-(a7)
	move.w	d0,d2
; d2 = N
; d3 = I
; d5 - linsesize.l
	moveq.l	#0,d5
	move.b	#LinesSize,d5
	move.l	(FSEbuffer,a3),a2
	move.w	(MaxFSEbufferlines,a3),d3
	subq.w	#1,d3
	mulu.w	d5,d3			; MaxFSEbufferlines * linsesize
	move.w	d2,d4
;	add.w	#1,d4			; N + 1
	mulu.w	d5,d4			; N + 1 * linsesize
1$	lea	(0,a2,d3.l),a1
	sub.l	d5,d3
	lea	(0,a2,d3.l),a0
	bsr	strcopy
	cmp.l	d3,d4
	bls.b	1$
	move.w	d2,d0
	subq.w	#1,d0
	mulu.w	d5,d0
	move.b	#0,(0,a2,d0.l)

	cmp.w	(P,a3),d2
	bcs.b	2$
	move.w	(P,a3),d0
	add.w	(WindowSiz,a3),d0
	cmp.w	d0,d2
	bhi.b	2$
	move.w	d2,d0
	sub.w	(P,a3),d0
	addq.w	#WindowTop,d0
	move.w	#1,d1
	bsr	InsertLines
2$	movea.l	(a7)+,a2
	move.w	(MaxFSEbufferlines,a3),d0
	cmp.w	(NrLines,a2),d0
	bls.b	9$
	addq.w	#1,(NrLines,a2)
9$	movem.l	(a7)+,d2/d3/d4/d5
	rts

Wrap	move.l	d2,-(a7)	; called with text in LongLine, not CurrText^...
;d2 - savedy
	move.w	(Y,a3),d2	; SavedY
1$	lea	(LongLine,a3),a0
	bsr	strlen
	move.w	(WindowWith,a3),d1
	subq.w	#1,d1
	cmp.w	d1,d0
	bls.b	2$
	bsr.b	10$			; WrapLine
	bra.b	1$
2$	lea	(LongLine,a3),a0
	move.l	(FSEbuffer,a3),a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a1
	bsr	strcopy
	move.w	d2,(Y,a3)
	move.w	(WindowWith,a3),d0
	cmp.w	(X,a3),d0
	bcc.b	9$
	move.w	d0,(X,a3)
	bsr	ControlAlarm
9$	move.l	(a7)+,d2
	rts

10$	movem.l	d3-d7/a6,-(a7)	; WrapLine
; d6 = I
; d3 = J
; d4 = P
; d5 = Q
; d2 = SavedY
	move.l	(FSEbuffer,a3),a0
	move.l	a0,d7
	move.w	(MaxFSEbufferlines,a3),d0
	cmp.w	(Y,a3),d0
	bhi.b	11$
	move.w	(WindowWith,a3),d0
	lea	(LongLine,a3),a0
	move.b	#0,(-1,a0,d0.w)
	bra	19$
11$	bsr	20$			; Findsplit
	lea	(LongLine,a3),a0
	movea.l	d7,a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a1
	movea.l	a1,a6
	moveq.l	#0,d0
	move.b	#1,d0
	move.w	d3,d1
	bsr	copy
	move.w	d6,d0
	subq.w	#1,d0
	bsr	MarkIt
	cmp.w	(Y,a3),d2
	bne.b	12$
	cmp.w	(X,a3),d6
	bhi.b	12$
	addq.w	#1,d2
	sub.w	d6,(X,a3)
	addq.w	#1,(X,a3)
12$	move.w	#1,d4
	movea.l	a6,a0
	bsr	strlen
13$	cmp.w	d0,d4
	bhi.b	14$
	move.b	(-1,a6,d4.w),d1
	cmpi.b	#' ',d1
	bne.b	14$
	addq.w	#1,d4
	bra.b	13$
14$	addq.w	#1,(Y,a3)
	lea	(LongLine,a3),a0
	movea.l	a0,a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.w	d6,d0
	move.b	#99,d1
	bsr	copy

	movea.l	d7,a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a6
	tst.b	(a6)
	bne.b	15$
	move.w	(Y,a3),d0

	move.l	a6,-(a7)
	movea.l	(24,a7),a6
	bsr	DoLineInsert
	movea.l	(a7)+,a6

15$	lea	(LongLine,a3),a0
	tst.b	(a0)
	beq.b	16$
	tst.b	(a6)
	beq.b	16$
17$	tst.b	(a0)+
	bne.b	17$
	move.b	#' ',(-1,a0)
	move.b	#0,(a0)
16$	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEAutoIndent,d0
	beq.b	110$
	movea.l	d7,a0
	move.w	(Y,a3),d0
	subq.w	#2,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	cmp.w	d0,d4
	bhi.b	110$
	subq.w	#1,d4
	move.w	#1,d5
111$	cmp.w	d5,d4
	bcs.b	110$
	cmp.w	(Y,a3),d2
	bne.b	112$
	addq.w	#1,(X,a3)
112$	lea	(LongLine,a3),a0
	move.b	#' ',d0
	moveq.l	#1,d1
	bsr	insert
	tst.b	(a6)
	beq.b	113$
	cmpi.b	#' ',(1,a6)
	bne.b	113$
	movea.l	a6,a0
	moveq.l	#1,d0
	move.w	#1,d1
	bsr	delete
113$	addq.w	#1,d5
	bra.b	111$
110$	lea	(LongLine,a3),a1
18$	tst.b	(a1)+
	bne.b	18$
	subq.l	#1,a1
	movea.l	a6,a0
	bsr	strcopy
130$	move.w	#1,d0
	bsr	MarkIt
19$	movem.l	(a7)+,d3-d7/a6
	rts

; d6 = I
; d3 = J
20$	move.w	(WindowWith,a3),d3	; FindSplit
	lea	(LongLine,a3),a0
21$	move.b	(-1,a0,d3.w),d0
	cmpi.b	#' ',d0
	bne.b	22$
	move.w	d3,d6
	addq.w	#1,d6
	subq.w	#1,d3
	bra.b	29$
22$	cmpi.b	#'-',d0
	bne.b	23$
	cmp.w	(WindowWith,a3),d3
	beq.b	23$
	move.w	d3,d6
	addq.w	#1,d6
	bra.b	29$
23$	subq.w	#1,d3
	bne.b	21$
	move.w	(WindowWith,a3),d6
	move.w	d6,d3
	subq.w	#1,d3
29$	rts

DoBackspace
	cmpi.w	#1,(X,a3)
	bgt	1$
	cmpi.w	#1,(Y,a3)
	bgt.b	3$
	bsr	ControlAlarm
	bra	9$
3$	move.l	d2,-(a7)
	lea	(LongLine,a3),a1
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	move.l	a0,d2
	bsr	strcopy
	move.w	(Y,a3),d0
	bsr	DoLineDelete
	subq.w	#1,(Y,a3)
	subi.l	#LinesSize,d2
	movea.l	d2,a0
	bsr	strlen
	addi.w	#1,d0
	move.w	d0,(X,a3)
	bsr	MarkIt

	lea	(LongLine,a3),a0
	tst.b	(a0)
	beq.b	4$
	movea.l	d2,a1
	tst.b	(a1)
	beq.b	4$
	addq.w	#1,(X,a3)
	move.b	#' ',d0
	moveq.l	#0,d1
	bsr	insert
	lea	(LongLine,a3),a0
4$	lea	(tmptext,NodeBase),a1
	bsr	strcopy
	lea	(LongLine,a3),a1
	movea.l	d2,a0
	bsr	strcopy
	subq.l	#1,a1
	lea	(tmptext,NodeBase),a0
	bsr	strcopy
	bsr	Wrap
	move.l	(a7)+,d2
	bra	9$

1$	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	move.l	a0,-(a7)
	bsr	strlen
	movea.l	(a7)+,a0
	addq.l	#1,d0
	cmp.w	(X,a3),d0
	bcs.b	2$

	moveq.l	#0,d0
	move.w	(X,a3),d0
	subq.w	#1,d0
	move.w	#1,d1
	bsr	delete
	move.w	(X,a3),d0
	subq.w	#1,d0
	bsr	MarkIt
2$	subq.w	#1,(X,a3)
9$	rts

DoDelCharacter
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	cmp.w	(X,a3),d0
	bcc.b	1$
	move.w	(NrLines,a2),d0
	cmp.w	(Y,a3),d0
	bls.b	9$
	addq.w	#1,(Y,a3)
	move.w	#0,(X,a3)
1$	addq.w	#1,(X,a3)
	bsr	DoBackspace
9$	rts

DoReturn
	movem.l	d2/d3,-(a7)
; d2 - I
; d3 - P
	move.w	(MaxFSEbufferlines,a3),d0
	cmp.w	(Y,a3),d0
	bhi.b	1$
	bsr	ControlAlarm
	bra	9$
1$	move.w	(Y,a3),d0
	addq.w	#1,d0
	bsr	DoLineInsert
	bsr	PadLine

	move.l	(FSEbuffer,a3),a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a0
	addi.l	#LinesSize,d0
	lea	(0,a1,d0.l),a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.w	(X,a3),d0
	move.b	#99,d1
	move.l	a0,-(a7)
	bsr	copy
	movea.l	(a7)+,a0
	movea.l	a0,a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.b	#1,d0
	move.w	(X,a3),d1
	subq.w	#1,d1
	move.l	a0,-(a7)
	bsr	copy
	bsr	UnPadLine
	move.w	(X,a3),d0
	bsr	MarkIt
	move.w	#1,d3
	movea.l	(a7),a0
	bsr	strlen
	movea.l	(a7)+,a0
4$	cmp.w	d0,d3
	bhi.b	3$
	move.b	(-1,a0,d3.w),d1
	cmpi.b	#' ',d1
	bne.b	3$
	addq.w	#1,d3
	bra.b	4$
3$	move.w	#1,(X,a3)
	addq.w	#1,(Y,a3)
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEAutoIndent,d0
	beq.b	9$
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#2,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	movea.l	a0,a1
	bsr	strlen
	cmp.w	d0,d3
	bhi.b	9$
	lea	(LinesSize,a1),a1
	move.w	#1,d2
	subq.w	#1,d3
2$	cmp.w	d2,d3
	bcs.b	9$
	addq.w	#1,(X,a3)
	moveq.l	#0,d1
	move.b	#' ',d0
	movea.l	a1,a0
	bsr	insert
	addq.w	#1,d2
	bra.b	2$
9$	movem.l	(a7)+,d2/d3
	rts

DoTAB	move.w	(X,a3),d0
	move.w	(WindowWith,a3),d1
	andi.w	#$fff8,d1
	cmp.w	d0,d1
	bhi.b	1$
	bra	ControlAlarm
1$	addq.w	#7,d0
	andi.w	#$fff8,d0
	addq.w	#1,d0
3$	move.w	d0,(X,a3)
	rts

DoNewLine
	move.w	(Y,a3),d0
	cmp.w	(NrLines,a2),d0
	bcs.b	1$
	tst.b	(HaveCR,a3)
	beq	DoReturn
	bra	ControlAlarm
1$	addq.w	#1,(Y,a3)
	move.w	#1,(X,a3)
	rts

DoForward
	move.w	(X,a3),d0
	cmp.w	(WindowWith,a3),d0
	bcc.b	1$
	addq.w	#1,(X,a3)
	rts
1$	move.w	(Y,a3),d0
	cmp.w	(NrLines,a2),d0
	bcc	ControlAlarm
	addq.w	#1,(Y,a3)
	move.w	#1,(X,a3)
	rts

DoBackward
	cmpi.w	#1,(X,a3)
	bls.b	1$
	subq.w	#1,(X,a3)
	bra.b	9$
1$	cmpi.w	#1,(Y,a3)
	bhi.b	2$
	bsr	ControlAlarm
	bra.b	9$
2$	subq.w	#1,(Y,a3)
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	addq.w	#1,d0
	move.w	d0,(X,a3)
9$	rts

DoWordLeft
	subq.w	#1,(X,a3)
	move.w	#0,d0
	bsr	10$		; Find
	move.w	#1,d0
	bsr	10$		; Find
	addq.w	#1,(X,a3)
	rts

10$	move.l	d2,-(a7)	; Find
	move.w	d0,d2
11$	cmpi.w	#1,(X,a3)
	bcc.b	12$
	tst.w	d2
	bne.b	19$
	cmpi.w	#1,(Y,a3)
	bls.b	19$
	subq.w	#1,(Y,a3)
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	addq.w	#1,d0
	move.w	d0,(X,a3)
12$	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	moveq.l	#0,d1
	move.w	(X,a3),d1
	add.l	d1,d0
	cmpi.b	#' ',(-1,a0,d0.l)
	beq.b	13$		; true = hopp
	tst.w	d2
	beq.b	19$
	bra.b	14$
13$	tst.w	d2
	bne.b	19$
14$	subq.w	#1,(X,a3)
	bra.b	11$
19$	move.l	(a7)+,d2
	rts

DoWordRight
	subq.w	#1,(X,a3)
	move.w	#1,d0
	bsr	10$		; Find
	move.w	#0,d0
	bsr	10$		; Find
	rts

10$	movem.l	d4/d2/d3,-(a7)
	move.w	d0,d2
	move.l	a2,d4
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a2
	movea.l	a2,a0
	bsr	strlen
	move.l	d0,d3
11$	cmp.w	(X,a3),d3
	bcc.b	12$
	tst.w	d2
	bne.b	19$
	move.w	(Y,a3),d0
	movea.l	d4,a0
	cmp.w	(NrLines,a0),d0
	bcc.b	19$
	addq.w	#1,(Y,a3)
	move.w	#0,(X,a3)
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a2
	movea.l	a2,a0
	bsr	strlen
	move.l	d0,d3
12$	addq.w	#1,(X,a3)
	move.w	(X,a3),d0
	cmpi.b	#' ',(-1,a2,d0.w)
	beq.b	13$		; True = hopp
	tst.w	d2
	beq.b	19$
	bra.b	11$
13$	tst.w	d2
	beq.b	11$
19$	movea.l	d4,a2
	movem.l	(a7)+,d4/d2/d3
	rts

DoUpward
	cmpi.w	#1,(Y,a3)
	bhi.b	1$
	bra	ControlAlarm
1$	subq.w	#1,(Y,a3)
	rts

DoPageUp
	move.w	(Y,a3),d0
	cmpi.w	#1,d0
	bhi.b	1$
	bra	ControlAlarm
1$	sub.w	(WindowSiz,a3),d0
	cmpi.w	#1,d0
	bge.b	2$
	move.w	#1,d0
2$	move.w	d0,(Y,a3)
	rts

DoDownward
	move.w	(NrLines,a2),d0
	cmp.w	(Y,a3),d0
	bhi.b	1$
	bra	ControlAlarm
1$	addq.w	#1,(Y,a3)
	rts

DoPageDown
	move.w	(Y,a3),d1
	move.w	(NrLines,a2),d0
	cmp.w	d0,d1
	bcc	ControlAlarm
	add.w	(WindowSiz,a3),d1
	cmp.w	d0,d1
	bls.b	2$
	move.w	d0,d1
2$	move.w	d1,(Y,a3)
	rts

DoHomeward
	cmpi.w	#1,(X,a3)
	bls.b	1$
	move.w	#1,(X,a3)
	bra.b	9$
1$	move.w	(P,a3),d0
	cmp.w	(Y,a3),d0
	beq.b	2$
	move.w	d0,(Y,a3)
	bra.b	9$
2$	move.w	#1,(Y,a3)
9$	rts

DoEndward
	move.l	d2,-(a7)
	move.w	(P,a3),d2
	add.w	(WindowSiz,a3),d2
	move.w	(NrLines,a2),d0
	cmp.w	d2,d0
	bcc.b	1$
	move.w	d0,d2
1$	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	addq.w	#1,d0
	cmp.w	(X,a3),d0
	bhi.b	2$
	cmp.w	(Y,a3),d2
	beq.b	3$
	move.w	d2,(Y,a3)
	bra.b	4$
3$	move.w	(NrLines,a2),(Y,a3)
4$	bne.b	5$
	move.w	#1,(Y,a3)
5$	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	tst.w	d0
	bne.b	2$
	moveq.l	#1,d0
2$	move.w	d0,(X,a3)
	move.l	(a7)+,d2
	rts

showfsemode
	move.w	#-1,(FizzY,a3)
	move.w	#31,d0
	move.w	#2,d1
	bsr	MoveCursor
	bsr	ControlNormAtt
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEOverwritemode,d0
	beq.b	1$
	lea	(overwritetext),a0
	bra.b	2$
1$	lea	(inserttext),a0
2$	bsr	writetexti
	move.w	#42,d0
	move.w	#2,d1
	bsr	MoveCursor
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEAutoIndent,d0
	beq.b	3$
	lea	(autoindenttext),a0
	bra.b	4$
3$	lea	(noindenttext),a0
4$	bsr	writetexti
9$	rts

RedrawScreen
; d0 = I
	lea	(ScreenUpd,a3),a0
	moveq.l	#WindowTop,d0
1$	move.b	#1,(0,a0,d0.w)
	addq.l	#1,d0
	cmp.w	(WindowEnd,a3),d0
	bls.b	1$
	move.w	(Y,a3),d0
	subq.w	#7,d0
	cmpi.w	#1,d0
	bge.b	2$
	move.w	#1,d0
2$	move.w	d0,(P,a3)
	rts

UpdateScreenMaybe
	push	d2/d3/d4
;d2 = I
;d3 = J
	tst.b	(ZapEcho,a3)
	bne	72$
	bsr	20$
	bne	72$
	move.w	(P,a3),d0
	move.w	(Y,a3),d1
	cmp.w	d0,d1
	bcc.b	2$
	sub.w	d1,d0
	cmpi.w	#6,d0
	bls.b	4$
	bsr.b	RedrawScreen
	bra.b	3$
4$	move.w	d0,d1
	move.w	#WindowTop,d0
	bsr	InsertLines
	move.w	(Y,a3),(P,a3)
	bra.b	3$
2$	add.w	(WindowSiz,a3),d0
	cmp.w	d0,d1
	bls.b	3$
	sub.w	d0,d1
	cmpi.w	#6,d1
	bls.b	5$
	bsr.b	RedrawScreen
	bra.b	3$

5$	move.w	#WindowTop,d0
	bsr	DeleteLines
	move.w	(Y,a3),d0
	sub.w	(WindowSiz,a3),d0
	move.w	d0,(P,a3)

3$	move.w	#WindowTop,d2
6$
	bsr	20$
	bne	72$
	lea	(ScreenUpd,a3),a0
	move.w	#0,d0
	move.b	(0,a0,d2.w),d0
	move.w	(WindowWith,a3),d1
	cmp.b	d1,d0
	bcc	7$
	move.w	d2,d1
	bsr	MoveCursor
	move.w	d2,d3
	add.w	(P,a3),d3
	subq.w	#WindowTop,d3
	move.w	(MaxFSEbufferlines,a3),d0
	cmp.w	d0,d3
	bhi.b	8$
	move.l	(FSEbuffer,a3),a0
	move.w	d3,d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	moveq.l	#0,d4				; ikke quoting
	cmpi.b	#'>',(a0)			; er det et quote tegn ?
	bne.b	61$
	moveq.l	#1,d4				; vi skal quote denne linja
;	cmpi.b	#'>',(1,a0)			; er det et quote tegn ?
;	bne.b	61$
;	moveq.l	#2,d4				; rød
61$	moveq.l	#0,d0
	moveq.l	#0,d1
	lea	(ScreenUpd,a3),a1
	move.b	(0,a1,d2.w),d0
	move.b	#99,d1
	lea	(tmptext,NodeBase),a1
	bsr	copy
	lea	(tmptext,NodeBase),a0
	bsr	strlen
	move.w	d0,-(a7)
	lea	(tmptext,NodeBase),a0
	move.l	d4,d1
	bsr	maywritequotetext
	move.w	(a7)+,d0
	add.w	d0,(FizzX,a3)
	lea	(ScreenClr,a3),a0
	move.w	(FizzX,a3),d0
	cmp.b	(0,a0,d2.w),d0
	bls.b	8$
	move.b	d0,(0,a0,d2.w)
8$	lea	(ScreenClr,a3),a0
	move.w	(FizzX,a3),d0
	cmp.b	(0,a0,d2.w),d0
	bcc.b	88$
	move.b	d0,(0,a0,d2.w)
	bsr	ControlErase
88$	lea	(ScreenUpd,a3),a0
	move.w	(WindowWith,a3),d0
	move.b	d0,(0,a0,d2.w)
7$	addq.w	#1,d2
	cmp.w	(WindowEnd,a3),d2
	bls	6$
	bsr	20$
	bne.b	72$
	bsr	10$
72$	bsr	readchar
	bne.b	73$
	tst.b	(readcharstatus,NodeBase)
	notz
	bne.b	73$
	setn
	bra.b	9$
73$	move.b	d0,(CharIn,a3)
	clrn
9$	pop	d2/d3/d4
	rts

10$	move.w	(NrLines,a2),d0
	cmp.w	(LastN,a3),d0
	beq.b	11$
	move.w	#20,d0
	move.w	#2,d1
	bsr	MoveCursor
	bsr	ControlNormAtt
	lea	(tmptext,NodeBase),a0
	moveq.l	#0,d0
	move.w	(NrLines,a2),d0
	move.w	d0,(LastN,a3)
	bsr	konverter
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#0,(a0)
	lea	(tmptext,NodeBase),a0
	bsr	writetexti
11$	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEXYon,d0
	beq	12$
	move.w	(Y,a3),d0
	cmp.w	(LastY,a3),d0
	beq.b	13$
	move.w	#69,d0
	move.w	#2,d1
	bsr	MoveCursor
	bsr	ControlNormAtt
	cmpi.w	#100,(Y,a3)
	bcc.b	14$
	move.b	#' ',d0
	bsr	writechar
	cmpi.w	#10,(Y,a3)
	bcc.b	14$
	move.b	#' ',d0
	bsr	writechar
14$	moveq.l	#0,d0
	move.w	(Y,a3),d0
	bsr	skrivnr
	move.b	#':',d0
	bsr	writechar
	move.w	(WindowWith,a3),(FizzX,a3)
	move.w	(Y,a3),(LastY,a3)

13$	move.w	(X,a3),d0
	cmp.w	(LastX,a3),d0
	beq.b	12$
	move.w	#73,d0
	move.w	#2,d1
	bsr	MoveCursor
	bsr	ControlNormAtt
	moveq.l	#0,d0
	move.w	(X,a3),d0
	bsr	skrivnr
	move.b	#' ',d0
	jsr	(writechar)
	move.w	(X,a3),(LastX,a3)
12$	move.w	(X,a3),d0
	move.w	(Y,a3),d1
	sub.w	(P,a3),d1
	addq.w	#WindowTop,d1
	bra	MoveCursor

20$			; CheckInput
; returnerer N satt, når vi ikke har carrier (Carrier testing er fjernet.)
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
29$	rts

IncludeFile
	push	d2-d5
	move.b	(userok,NodeBase),d0		; nekter hvis han ikke er logget inn ordentelig
	beq	9$
	move.w	#0,d5
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq.b	1$				; Yepp.
	jsr	(justchecksysopaccess)		; sysop ?
	beq	9$				; nei, ut
1$	bsr	ControlHeadAtt
2$	suba.l	a1,a1				; ikke noe filnavn
	lea	(tmptext,NodeBase),a0		; Her vil vi ha filnavnet
	bsr	getfullnamewithreq
	bmi.b	12$				; ikke noen asl. tar vanelig
	bne.b	11$
	bra	99$
12$	move.w	#1,d0
	move.w	#4,d1
	bsr	MoveCursor
	bsr	ControlErase
	move.w	#-1,(FizzY,a3)
	lea	(enterffnametext),a0
	jsr	(writetexti)
	move.w	#30,d0
	bsr	getline
	beq	99$
11$	move.l	a0,d1
	movea.l	(dosbase),a6
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	movea.l	(exebase),a6
	move.l	d0,d4
	bne.b	3$
	bsr	ControlAlarm
	bra.b	2$
3$	move.w	(MaxFSEbufferlines,a3),d0
	cmp.w	(NrLines,a2),d0
	bls	4$			; for mange linjer. Ferdig
	tst.w	d5
	bne	4$			; EOF ?? Jepp, ut

	movea.l	(dosbase),a6
	lea	(tmptext,NodeBase),a0
	move.l	a0,d2
7$	moveq.l	#77,d3			; max len
	move.l	d4,d1
	jsrlib	FGets
	tst.l	d0
	bne.b	10$			; Vi har en linje
6$	move.w	#1,d5			; ferdig/error
	movea.l	d2,a0
	move.b	#0,(a0)
	bra.b	8$
10$	move.l	d2,a0
	bsr	strlen
	move.l	d2,a0
14$	move.b	(-1,a0,d0.l),d1
	cmp.b	#10,d1
	beq.b	13$
	cmp.b	#13,d1
	bne.b	8$
13$	move.b	#0,(-1,a0,d0.l)
	subq.l	#1,d0
	bcc.b	14$
8$	movea.l	(exebase),a6
	bsr	expandtabsstring
;	bsr	PadLine
	lea	(LongLine,a3),a1
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strcopy
	lea	(LongLine,a3),a0
	lea	(tmptext,NodeBase),a1
	moveq.l	#0,d0
	move.w	(X,a3),d0
	bsr	insertstr
	move.w	(X,a3),d0
	bsr	MarkIt
	lea	(tmptext,NodeBase),a0
	bsr	strlen
	add.w	d0,(X,a3)
	lea	(LongLine,a3),a0
	bsr	strlen
	addq.w	#1,d0
	cmp.w	(X,a3),d0
	bcc.b	5$
	move.w	d0,(X,a3)
5$	bsr	Wrap
	bsr	DoReturn
	bra	3$
4$	move.l	d4,d1
	movea.l	(dosbase),a6
	jsrlib	Close
	movea.l	(exebase),a6
99$	bsr	ControlNormAtt
9$	pop	d2-d5
	rts

;	move.w	(X,a3),d1
expandtabsstring
	move.l	a0,a1
	moveq.l	#0,d1			; Char-Counter
1$	move.b	(a0)+,d0
	beq.b	8$			; End of the string?
	addq.w	#1,d1			; One more char in the string now
	cmp.b	#9,d0			; TAB?
	bne.b	1$			; no, continue loop

; It's a tab - compute how many spaces are needed and put it on stack.
	bset	#16,d1			; Mark that we've found a tab...
	move.w	d1,d0
	neg.w	d0
	and.w	#FSETabSize-1,d0
	add.w	d0,d1
	move.w	d0,-(a7)		; (number of spaces-1) On stack...
	bra.b	1$

8$	btst	#16,d1			; Finished scanning the string for tabs - have we discovered any?
	bne.b	10$
9$	rts				; quit

10$	subq.w	#1,a0			; Yepp - we have some tabs in the string - now copy it from end to start.
	lea	(a1,d1.w),a1		; Destination-pointer.
	sf	(a1)			; Null-termitation.
14$	move.b	-(a0),d0
	cmp.b	#9,d0               ; TAB?
	bne.b	11$
; It's a tab - replace it with spaces instead.
	move.w	(a7)+,d0
	beq.b	12$		; Only one space.
	sub.w	d0,d1
	subq.w	#1,d0
13$	move.b	#' ',-(a1)
	dbra	d0,13$
12$	move.b	#' ',d0
11$	move.b	d0,-(a1)
	subq.w	#1,d1
	bne.b	14$
	bra.b	9$

WriteFile
	movem.l	d2-d5,-(a7)
	move.b	(userok,NodeBase),d0		; nekter hvis han ikke er logget inn ordentelig
	beq	9$
	tst.b	(CommsPort+Nodemem,NodeBase)	; internal node ??
	beq.b	1$			; Yepp.
	jsr	(justchecksysopaccess)		; sysop ?
	beq	9$				; nei, ut
1$	bsr	ControlHeadAtt
2$	suba.l	a1,a1				; ikke noe filnavn
	lea	(tmptext,NodeBase),a0		; Her vil vi ha filnavnet
	bsr	getfullnamewithreq
	bmi.b	12$				; ikke noen asl. tar vanelig
	bne.b	11$
	bra	99$
12$	move.w	#1,d0
	move.w	#4,d1
	bsr	MoveCursor
	bsr	ControlErase
	move.w	#-1,(FizzY,a3)
	lea	(enterffnametext),a0
	jsr	(writetexti)
	move.w	#30,d0
	bsr	getline
	beq	99$
11$	move.l	a0,d1
	movea.l	(dosbase),a6
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	movea.l	(exebase),a6
	move.l	d0,d4
	bne.b	3$
	bsr	ControlAlarm
	bra.b	2$
3$	move.w	#0,d5
4$	move.w	d5,d0
	mulu.w	#LinesSize,d0
	move.l	(FSEbuffer,a3),a0
	lea	(0,a0,d0.l),a0
	move.l	a0,d2
	bsr	strlen
	movea.l	d2,a0
	move.l	d0,d3
	addq.l	#1,d3
	move.b	#10,(-1,a0,d3.w)
	move.l	d4,d1
	movea.l	(dosbase),a6
	jsrlib	Write
	movea.l	(exebase),a6
	movea.l	d2,a0
	move.b	#0,(-1,a0,d3.w)
	cmp.l	d3,d0
	beq.b	5$
	move.l	d4,d1
	movea.l	(dosbase),a6
	jsrlib	Close
	movea.l	(exebase),a6
	bra.b	99$
5$	addq.w	#1,d5
	cmp.w	(NrLines,a2),d5
	bcs.b	4$
	move.l	d4,d1
	movea.l	(dosbase),a6
	jsrlib	Close
	movea.l	(exebase),a6
99$	bsr	ControlNormAtt
9$	movem.l	(a7)+,d2-d5
	rts

quotemessage
	push	d2/a6
; d2 - I
	move.w	#1,d2
0$	move.w	d2,d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	move.l	(FSEbuffer,a3),a0
	lea	(0,a0,d0.l),a6
	movea.l	a6,a0
	bsr	strlen
	beq.b	1$
	cmp.w	#LinesSize-3,d0
	bcs.b	2$
	move.b	#0,(-1,a6,d0.w)
2$	move.b	#'>',d0
	moveq	#0,d1
	movea.l	a6,a0
	bsr.w	insert
1$	addq.w	#1,d2
	cmp.w	(NrLines,a2),d2
	bls.b	0$
	pop	d2/a6
	bsr.w	RedrawScreen
	rts

TrimMessage
	push	d2/a6
; d2 - I
	move.w	#1,d2
1$	move.w	d2,d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	move.l	(FSEbuffer,a3),a0
	lea	(0,a0,d0.l),a6
	movea.l	a6,a0
	bsr	strlen
	move.w	d0,d0
2$	tst.w	d0
	beq.b	3$
	cmpi.b	#' ',(-1,a6,d0.w)
	bne.b	3$
	subq.w	#1,d0
	bra.b	2$
3$	move.b	#0,(0,a6,d0.w)
	addq.w	#1,d2
	cmp.w	(NrLines,a2),d2
	bls.b	1$
4$	move.w	(NrLines,a2),d0
	beq.b	9$
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	move.l	(FSEbuffer,a3),a0
	lea	(0,a0,d0.l),a0
	bsr	strlen
	bne.b	9$
	subq.w	#1,(NrLines,a2)
	bra.b	4$
9$	pop	d2/a6
	rts

packmessage
	move.l	d2,-(a7)
	moveq.l	#0,d2
	move.l	(FSEbuffer,a3),a1
1$	cmp.w	(NrLines,a2),d2
	bcc.b	2$
	move.w	d2,d0
	mulu.w	#LinesSize,d0
	move.l	(FSEbuffer,a3),a0
	lea	(0,a0,d0.l),a0
	bsr	strcopy
	move.b	#10,(-1,a1)
	addq.l	#1,d2
	bra.b	1$
2$	move.b	#0,(-1,a1)
	move.l	(FSEbuffer,a3),a0
	bsr	strlen
	move.w	d0,(NrBytes,a2)
	move.l	(FSEbuffer,a3),a0
	move.l	(a7)+,d2
	rts

unpackmessage
	push	d2/d3/d4/d5/a2/a3/d6
	move.l	a0,(tmpstore,NodeBase)		; husker msgheader
	moveq.l	#0,d0
	move.w	(NrBytes,a0),d0
	move.w	(MaxFSEbufferlines,a3),d5	; max linjer
	move.l	(FSEbuffer,a3),a2		; a2 = starten på meldingen
	movea.l	a2,a3
	adda.l	d0,a3				; a3 = slutten på meldingen
	moveq.l	#LinesSize,d4
	move.w	(NrLines,a0),d3			; d3 = antall linjer
	cmp.w	d5,d3
	bls.b	4$				; plass
	move.w	d5,d3
	move.w	d3,(NrLines,a0) ; Oppdaterer antall linjer
	move.w	d3,d0				; legger en null på slutten
	mulu.w	d4,d0				; av meldinga..
	move.l	a2,a3
	add.l	d0,a3				; setter ny slutt
	bra.b	5$
4$	move.w	d3,d0				; legger en null på slutten
	mulu.w	d4,d0				; av meldinga..
5$	move.b	#0,(0,a2,d0.l)
	subq.w	#1,d3
	bls.b	9$				; Z = 1, C = 1
	mulu.w	d4,d3
1$	move.b	#0,(a3)				; Stanser linja her
	moveq.l	#0,d6				; antall tegn
2$	cmpa.l	a3,a2				; sikkerhet
	bhi.b	3$				; panic. :-)
	addq.l	#1,d6
	cmp.b	#79,d6
	bhi.b	6$				; 79 < d6
	cmpi.b	#10,-(a3)			; leter etter linefeed
	bne.b	2$
6$	lea	(0,a2,d3.l),a1			; beregner destination
	lea	(1,a3),a0			; alt etter linefeed'et
	bsr	strrcopy
	sub.l	d4,d3
	beq.b	7$
	cmpi.b	#10,(a3)			; Var det NL vi stanset for ?
	beq.b	1$				; jepp.
	lea	(1,a3),a3
	bra.b	1$
7$	move.b	#0,(a3)
3$	movea.l	(tmpstore,NodeBase),a0		; henter msgheader
	move.w	(NrLines,a0),d0			; Sjekker om vi kan øke med en linje
	cmp.w	d5,d0
	bcc.b	9$				; Det kan vi ikke
	addq.w	#1,d0				;: øker med 1
	move.w	d0,(NrLines,a0)
	mulu.w	d4,d0				; Tømmer den nye linja
	move.b	#0,(0,a2,d0.l)
9$	pop	d2/d3/d4/d5/a2/a3/d6
	rts

showfseheader
	move.l	d2,-(a7)
	move.w	d0,d2
	bsr	ControlClear
	move.w	#-1,d0
	move.w	d0,(LastN,a3)
	move.w	d0,(LastX,a3)
	move.w	d0,(LastY,a3)
	move.w	d0,(FizzX,a3)
	move.w	d0,(FizzY,a3)
	move.w	#1,d1
	bsr	10$
	move.w	(confnr,NodeBase),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	lea	(n_ConfName,a0,d0.l),a0	; Har konferanse navnet.
	jsr	(writetext)
	lea	(spacehashtext),a0
	jsr	(writetext)
	move.l	(Number,a2),d0
	bsr	skrivnr
	move.b	(Security,a2),d0
	btst	#SECB_SecReceiver,d0
	beq.b	1$
	lea	(privatemsgtext),a0
	jsr	(writetext)
1$	bsr	ControlHeadAtt
	lea	(tonoansitext),a0
	jsr	(writetext)
	lea	(maintmptext,NodeBase),a0
	jsr	(writetext)
	lea	(spaceresptext),a0
	jsr	(writetext)
	lea	(Subject,a2),a0
	jsr	(writetexti)
	move.w	#2,d1
	bsr	10$
	lea	(linesinmesgtext),a0
	jsr	(writetexti)
	move.w	#3,d1
	bsr	10$
	lea	(fseinfotext),a0
	jsr	(writetexti)
	move.w	#4,d1
	bsr.b	10$
	move.w	#5,d1
	bsr.b	10$
	lea	(bordertext),a0
	move.w	d2,d0
	subq.w	#1,d0
	jsr	(writetextleni)
	move.b	#'>',d0
	jsr	(writechar)
	bsr	ControlNormAtt
	bsr	showfsemode
	move.w	#WindowTop,d0
2$	move.w	d0,d2
	add.w	(P,a3),d2
	subq.w	#WindowTop,d2
	lea	(ScreenClr,a3),a0
	move.b	#1,(0,a0,d0.w)
	lea	(ScreenUpd,a3),a0
	move.w	(WindowWith,a3),d1
	move.b	d1,(0,a0,d0.w)
	move.w	(MaxFSEbufferlines,a3),d1
	cmp.w	d2,d1
	bcs.b	3$
	move.l	(FSEbuffer,a3),a1
	move.w	d2,d1
	subq.w	#1,d1
	mulu.w	#LinesSize,d1
	tst.b	(0,a1,d1.l)
	beq.b	3$
	move.b	#1,(0,a0,d0.w)
3$	addq.w	#1,d0
	cmp.w	(WindowEnd,a3),d0
	bls.b	2$

	move.l	(a7)+,d2
	rts

10$	move.w	d1,-(a7)
	bsr	ControlHeadAtt
	move.w	(a7)+,d1
	move.w	#1,d0
	bsr	MoveCursor
	bra	ControlErase

ShowHelp
	bsr	ControlClear
	lea	(fsehelppagetext),a0
	bsr	strlen
	lea	(fsehelppagetext),a0
	moveq.l	#0,d1
	jsr	(writetextmemi)
	bsr	readchar
	bne.b	1$
	tst.b	(readcharstatus,NodeBase)
	notz
	beq	9$
1$	move.w	(WindowWith,a3),d0
	bsr	showfseheader
	clrz
9$	rts

ChangeSubject
	move.b	(userok,NodeBase),d0		; nekter hvis han ikke er logget inn ordentelig
	beq	ControlAlarm
	move.w	(confnr,NodeBase),d0
	cmpi.w	#4,d0			; userinfo ?
	beq	ControlAlarm
	cmpi.w	#6,d0			; fileinfo ?
	beq	ControlAlarm
	bsr	ControlHeadAtt
	move.w	#1,d0
	move.w	#4,d1
	bsr	MoveCursor
	lea	(subjecttext),a0
	jsr	(writetexti)
	move.b	#0,(FSEditor,NodeBase)	; Vi er ikke i FSE akkuratt nå...
	move.w	#30,d0
	bsr	getline
	beq.b	1$
	moveq.l	#30,d0
	lea	(Subject,a2),a1
	bsr	strcopymaxlen
1$	move.b	#1,(FSEditor,NodeBase)	; Vi er i FSE.
	move.w	#-1,(FizzY,a3)
	bsr	ControlNormAtt
	move.w	(WindowWith,a3),d0
	bsr	showfseheader
	rts

ToggleSecurity
	move.b	(Security,a2),d0
	andi.b	#SECF_SecNone,d0
	beq.b	1$
	move.l	(MsgTo,a2),d0
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	3$
	move.w	(confnr,NodeBase),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.w	(n_ConfSW,a0,d0.l),d0
	andi.w	#CONFSWF_PostBox+CONFSWF_Private,d0
	beq.b	3$
	move.b	#SECF_SecReceiver,(Security,a2)
	bra.b	2$
3$	bsr	ControlAlarm
	rts
1$	move.w	(confnr,NodeBase),d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.w	(n_ConfSW,a0,d0.l),d0
	btst	#CONFSWB_PostBox,d0
	bne.b	3$
	move.b	#SECF_SecNone,(Security,a2)
2$ ;	bsr	ControlNormAtt
	move.w	(WindowWith,a3),d0
	bsr	showfseheader
9$	rts

ControlCursor
	exg	d0,d1
	movem.l	d0/d1,-(a7)
	lea	(tmptext,NodeBase),a1
	lea	(escrbrackettext),a0
	bsr	strcopy
	subq.l	#1,a1
	movea.l	a1,a0
	move.l	(a7)+,d0
	bsr	konverterw
	move.b	#';',(a0)+
	move.l	(a7)+,d0
	bsr	konverterw
	move.b	#'H',(a0)+
	move.b	#0,(a0)
	lea	(tmptext,NodeBase),a0
	jmp	(writetexti)

ControlDelete
	move.l	d2,-(a7)
	move.w	d0,d2
1$	lea	(Deletetext),a0
	jsr	(writetexti)
	subq.w	#1,d2
	bne.b	1$
	move.l	(a7)+,d2
	rts

ControlInsert
	move.l	d2,-(a7)
	move.w	d0,d2
1$	lea	(Inserttext),a0
	jsr	(writetexti)
	subq.w	#1,d2
	bne.b	1$
	move.l	(a7)+,d2
	rts

ControlNormAtt
	cmpi.w	#7,(CurColor,a3)
	bne.b	1$
	rts
1$	move.w	#7,(CurColor,a3)
	lea	(NormAtttext),a0
;	bra.b	MayWriteANSI

MayWriteANSI
	move.w	(Userbits+CU,NodeBase),d0		; Vil vi ha ansi text ?
	andi.w	#USERF_ColorMessages,d0
	beq.b	9$					; nei.
	jsr	(writetexti)
9$	rts

MayAutoQuote
	move.w	(Userbits+CU,NodeBase),d0		; Vil brukerene autoquote ?
	andi.w	#USERF_AutoQuote,d0
	beq.b	9$					; nei.
	bsr	quotemessage				; JEO
9$	rts

ControlHeadAtt
	cmpi.w	#6,(CurColor,a3)
	beq.b	9$
	move.w	#6,(CurColor,a3)
	lea	(HeadAtttext),a0
	bra.b	MayWriteANSI
9$	rts

ControlyellowAtt
	cmpi.w	#3,(CurColor,a3)
	beq.b	9$
	move.w	#3,(CurColor,a3)
	lea	(ansiyellowtext),a0
	bra.b	MayWriteANSI
9$	rts

ControlredAtt
	cmpi.w	#3,(CurColor,a3)
	beq.b	9$
	move.w	#3,(CurColor,a3)
	lea	(ansiredtext),a0
	bra.b	MayWriteANSI
9$	rts

ControlWarnAtt
	cmpi.w	#1,(CurColor,a3)
	beq.b	9$
	move.w	#1,(CurColor,a3)
	lea	(WarnAtttext),a0
	bra.b	MayWriteANSI
9$	rts

ControlClear
	lea	(ansiclearsctext),a0
	jmp	(writetexti)

ControlErase
	lea	(ansiclearlntext),a0
	jmp	(writetexti)

ControlAlarm
	move.b	#7,d0
	jmp	(writechari)

fseinserttext
	move.l	d2,-(a7)
	move.l	a0,d2
1$	movea.l	d2,a0
	move.b	(a0)+,d0
	beq.b	9$
	move.l	a0,d2
	bsr.b	fseinsertchar
	bra.b	1$
9$	move.l	(a7)+,d2
	rts

fseinsertchar
	move.l	d2,-(a7)
	move.l	d0,d2
	bsr	PadLine
	lea	(LongLine,a3),a1
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strcopy
	lea	(LongLine,a3),a0
	move.b	d2,d0
	moveq.l	#0,d1
	move.w	(X,a3),d1
	bsr	insert
	move.b	#0,(1,a0)		; paranoia (insert etterlater a0 på slutten.
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEOverwritemode,d0
	beq.b	31$
	lea	(LongLine,a3),a0
	moveq.l	#0,d0
	move.w	(X,a3),d0
	addq.w	#1,d0
	move.w	#1,d1
	bsr	delete
31$	move.w	(X,a3),d0
	bsr	MarkIt
	addq.w	#1,(X,a3)
	bsr	Wrap
	move.l	(a7)+,d2
	rts

; a0 = text
; d0 = length
; d1 = quting (true/false) 0 = ikke, 1 = lys blå, 2 = mørk blå.
maywritequotetext
	push	a0/d0
	tst.w	d1
	beq.b	1$			; nei
	cmpi.w	#1,d1
	beq.b	3$
	bsr	ControlredAtt
	bra.b	2$
3$	bsr	ControlHeadAtt
	bra.b	2$
1$	bsr	ControlNormAtt
2$	pop	a0/d0
	jsr	(writetextleni)
9$	rts

;maywritequotetext
;	move.w	d2,-(a7)
;	move.w	d1,d2			; skal dette quite's ?
;	beq.b	1$			; nei
;	push	a0/d0
;	bsr	ControlHeadAtt
;	pop	a0/d0
;1$	jsr	writetextleni
;	tst.w	d2			; var det quiting ?
;	beq.b	9$			; nope
;	bsr	ControlNormAtt
;9$	move.w	(a7)+,d2
;	rts

;a0 = msgheader
;a1 = buffer
;d0 = max size
;d1 = WindowWith
fseeditor
	movem.l	a2/a3,-(a7)
	movea.l	a0,a2
	move.l	(Tmpusermem,NodeBase),a3
	move.b	#0,(ZapEcho,a3)
	move.b	#0,(HaveCR,a3)
	move.w	d1,(WindowWith,a3)
	move.l	a1,(FSEbuffer,a3)
	divu	#LinesSize,d0
	move.w	d0,(MaxFSEbufferlines,a3)
	move.w	#24,d0
	move.w	(PageLength+CU,NodeBase),d1
	cmp.w	d0,d1
	bls.b	1$
	move.w	d1,d0
	cmpi.w	#MaxScreen,d0
	bls.b	1$
	move.w	#MaxScreen,d0
1$	move.w	d0,(WindowEnd,a3)
	subq.w	#WindowTop,d0
	move.w	d0,(WindowSiz,a3)
	lea	(SavedLines,a3),a0
	moveq.l	#0,d0
2$	move.b	#0,(0,a0,d0.w)		; Nulstiller savedlines
	addi.w	#LinesSize,d0
	cmpi.w	#LinesSize*NrSavedLines,d0
	bcs.b	2$

	cmpi.b	#2,(FSEditor,NodeBase)	; Skal vi includere ?
	bne.b	22$			; Nei.
	movea.l	a2,a0
	bsr	unpackmessage
;	bra.b	24$
	move.w	(NrLines,a2),d0		; Nullstiler resten av bufferet.
	mulu.w	#LinesSize,d0
	move.l	(FSEbuffer,a3),a0
	movea.l	a0,a1
	adda.l	d0,a0
	adda.l	(msgmemsize,NodeBase),a1
	bra.b	23$
22$	move.w	#0,(NrLines,a2)		; Sletter.
	move.l	(FSEbuffer,a3),a0
	movea.l	a0,a1
	adda.l	(msgmemsize,NodeBase),a1
21$	move.b	#0,(a0)			; Nulstiller melding buffer
	lea	(LinesSize,a0),a0
23$	cmpa.l	a1,a0
	bcs.b	21$

24$	bsr	MayAutoQuote;	JEO
	move.b	#1,(FSEditor,NodeBase)	; Vi er i FSE.
	move.w	#0,(LastSave,a3)
	move.b	#0,(LongLine,a3)
	move.w	#1,d0
	move.w	d0,(Y,a3)
	move.w	d0,(X,a3)
	move.w	d0,(P,a3)
	move.b	#NoShift,(ShiftStatus,a3)
	move.w	(WindowWith,a3),d0
	bsr	showfseheader

3$	bsr	UpdateScreenMaybe
	bmi	999$
31$	cmpi.b	#NoShift,(ShiftStatus,a3)
	bne	4$

	move.b	(CharIn,a3),d0
	cmpi.b	#' ',d0
	bcs.b	300$
	cmpi.b	#$7f,d0
	beq	328$
	cmpi.b	#$9b,d0
	beq	329$

	move.b	(CharIn,a3),d0
	bsr	fseinsertchar
	bra	3$

300$	cmpi.b	#$01,d0		; ctl/A
	bne.b	301$
	bsr	DoWordLeft
	bra	399$
301$	cmpi.b	#$02,d0		; ctl/B
	bne.b	302$
	move.w	(Y,a3),d0
	bsr	DoLineInsert
	subq.w	#1,(LastSave,a3)
	bcc.b	332$
	move.w	#NrSavedLines-1,(LastSave,a3)
332$	move.l	(FSEbuffer,a3),a1
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a1
	lea	(SavedLines,a3),a0
	move.w	(LastSave,a3),d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	bsr	strcopy
	move.w	#1,d0
	bsr	MarkIt
	bra	399$
302$	cmpi.b	#$03,d0		; ctl/C
	bne.b	303$
3021$	bsr	DoPageDown
	bra	399$
303$	cmpi.b	#$04,d0		; ctl/D
	bne.b	304$
	bsr	DoForward
	bra	399$
304$	cmpi.b	#$05,d0		; ctl/E
	bne.b	305$
	bsr	DoUpward
	bra	399$
305$	cmpi.b	#$06,d0		; ctl/F
	bne.b	306$
	bsr	DoWordRight
	bra	399$
306$	cmpi.b	#$07,d0		; ctl/G
	bne.b	307$
	bsr	DoDelCharacter
	bra	399$
307$	cmpi.b	#$08,d0		; bs
	bne.b	308$
	bsr	DoBackspace
	bra	399$
308$	cmpi.b	#$09,d0		; ht
	bne.b	309$
	bsr	DoTAB
	bra	399$
309$	cmpi.b	#$0A,d0		; lf
	bne.b	310$
	bsr	DoNewLine
	bra	399$
310$	cmpi.b	#$0B,d0		; ctl/K
	bne.b	311$
	move.b	#CtrlKshift,(ShiftStatus,a3)
	move.w	#1,d0
	move.w	#4,d1
	bsr	MoveCursor
	bsr	ControlHeadAtt
	lea	(ctlrktext),a0
	jsr	(writetexti)
	bsr	ControlNormAtt
	move.w	#-1,(FizzY,a3)
	bra	399$
311$	cmpi.b	#$0C,d0		; ctl/L
	bne.b	312$
	eori.w	#SAVEBITSF_FSEXYon,(Savebits+CU,NodeBase)
	move.w	#-1,d0
	move.w	d0,(LastY,a3)
	move.w	d0,(LastX,a3)
	move.w	(Savebits+CU,NodeBase),d0
	andi.w	#SAVEBITSF_FSEXYon,d0
	bne	399$
	move.w	#69,d0
	move.w	#2,d1
	bsr	MoveCursor
	lea	(spacetext),a0
	moveq.l	#7,d0
	jsr	(writetextleni)
	bra	399$
312$	cmpi.b	#$0D,d0		; cr
	bne.b	313$
	bsr	DoReturn
	bra	399$
313$	cmpi.b	#$0E,d0		; ctl/N
	bne.b	314$
	bra	330$
314$	cmpi.b	#$10,d0		; ctl/P
	bne.b	315$
330$	move.w	(WindowWith,a3),d0
	bsr	showfseheader
	clr.b	(ZapEcho,a3)
	bra	399$
315$	cmpi.b	#$0F,d0		; ctl/O
	bne.b	316$
	move.w	(Y,a3),d0
	bsr	DoLineInsert
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	move.b	#0,(0,a0,d0.l)
	move.w	#1,d0
	bsr	MarkIt
	bra	399$
316$	cmpi.b	#$11,d0		; ctl/Q
	bne.b	317$
334$	move.b	#NoShift,(ShiftStatus,a3)
	move.w	#25,d0
	move.w	#4,d1
	bsr	MoveCursor
	bsr	ControlWarnAtt
	lea	(abortmsgtext),a0
	jsr	(writetexti)
	bsr	ControlNormAtt
	bsr	UpdateScreenMaybe
	bmi.b	999$
	move.b	(CharIn,a3),d0
	bsr	upchar
	cmpi.b	#'Y',d0
	bne.b	331$
999$	move.w	#1,d0
	move.w	(WindowEnd,a3),d1
	addq.w	#3,d1
	bsr	MoveCursor
	move.b	#0,(FSEditor,NodeBase)
	setz
	bra	9$
331$	move.w	#-1,(FizzX,a3)
	move.w	#1,d0
	move.w	#4,d1
	bsr	MoveCursor
	bsr	ControlHeadAtt
	bsr	ControlErase
	bsr	ControlNormAtt
	bra	399$
317$	cmpi.b	#$12,d0		; ctl/R
	bne.b	318$
3171$	bsr	DoPageUp
	bra	399$
318$	cmpi.b	#$13,d0		; ctl/S
	bne.b	319$
	bsr	DoBackward
	bra	399$
319$	cmpi.b	#$14,d0		; ctl/T
	bne.b	320$
	movem.l	d2/a2,-(a7)
	moveq.l	#0,d2
	move.l	(FSEbuffer,a3),a2
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a2,d0.l),a2
	move.w	(X,a3),d0
	cmpi.b	#' ',(-1,a2,d0.w)
	bne.b	335$
	bset	#31,D2
335$	bsr	DoDelCharacter
	addq.w	#1,d2
	cmpi.w	#80,d2
	bhi.b	336$
	move.w	(X,a3),d0
	move.b	(-1,a2,d0.w),d0
	btst	#31,d2
	beq.b	338$
	cmpi.b	#' ',d0
	bne.b	336$
	bra.b	339$
338$	cmpi.b	#' ',d0
	beq.b	336$
339$	movea.l	a2,a0
	bsr	strlen
	cmp.w	(X,a3),d0
	bcc.b	335$
336$	movem.l	(a7)+,d2/a2
	bra	399$
320$	cmpi.b	#$15,d0		; ctl/U
	bne.b	321$
	bsr	ShowHelp
	beq	999$		; vi fikk no carrier
	bra	399$
321$	cmpi.b	#$16,d0		; ctl/V
	bne.b	322$
	move.w	(Savebits+CU,NodeBase),d0
	btst	#SAVEBITSB_FSEOverwritemode,d0
	beq.b	337$
	eori.w	#SAVEBITSF_FSEAutoIndent,(Savebits+CU,NodeBase)
337$	eori.w	#SAVEBITSF_FSEOverwritemode,(Savebits+CU,NodeBase)
	bsr	showfsemode
	bra	399$
322$	cmpi.b	#$17,d0		; ctl/W
	bne.b	323$
	bra	399$
323$	cmpi.b	#$18,d0		; ctl/X
	bne.b	324$
	bsr	DoDownward
	bra	399$
324$	cmpi.b	#$19,d0		; ctl/Y
	bne.b	325$
	move.l	(FSEbuffer,a3),a0
	move.w	(Y,a3),d0
	subq.w	#1,d0
	mulu.w	#LinesSize,d0
	lea	(0,a0,d0.l),a0
	lea	(SavedLines,a3),a1
	move.w	(LastSave,a3),d0
	mulu.w	#LinesSize,d0
	lea	(0,a1,d0.l),a1
	bsr	strcopy
	move.w	(LastSave,a3),d0
	addq.w	#1,d0
	cmpi.w	#NrSavedLines,d0
	bcs.b	333$
	move.w	#0,d0
333$	move.w	d0,(LastSave,a3)
	move.w	(Y,a3),d0
	bsr	DoLineDelete
	bra	399$
325$	cmpi.b	#$1A,d0		; ctl/Z
	bne.b	326$
	move.w	#1,d0
	move.w	(WindowEnd,a3),d1
	addq.w	#3,d1
	bsr	MoveCursor
	bsr	TrimMessage
	bsr	packmessage
	move.b	#0,(FSEditor,NodeBase)
	tst.w	(NrLines,a2)
	bra	9$
326$	cmpi.b	#$1B,d0		; esc
	bne.b	398$
	move.b	#ESCshift,(ShiftStatus,a3)
	bra.b	399$

328$	bsr	DoDelCharacter	; del
	bra.b	399$

329$	move.b	#CSIshift,(ShiftStatus,a3)
	bra.b	399$

398$	bsr	ControlAlarm
399$	clr.b	(HaveCR,a3)
	cmpi.b	#13,(CharIn,a3)
	bne	3$
	move.b	#1,(HaveCR,a3)
	bra	3$


4$	cmpi.b	#CtrlKshift,(ShiftStatus,a3)
	bne.b	5$
	move.b	(CharIn,a3),d0
	bsr	upchar
	cmpi.b	#'P',d0
	bne.b	41$
	bsr	ToggleSecurity
	bra.b	49$
41$	cmpi.b	#'Q',d0
	beq	334$
	cmpi.b	#'R',d0
	bne.b	43$
	bsr	IncludeFile
	bra.b	49$
43$	cmpi.b	#'S',d0
	bne.b	44$
	bsr	ChangeSubject
	bra.b	49$
44$	cmpi.b	#'W',d0
	bne.b	45$
	bsr	WriteFile
	bra.b	49$
45$	cmpi.b	#'Z',d0
	bne.b	46$
	eori.b	#$ff,(ZapEcho,a3)
	bra.b	49$
46$	cmpi.b	#'>',d0
	bne.b	49$
	bsr	quotemessage
49$	move.b	#NoShift,(ShiftStatus,a3)
	move.w	#1,d0
	move.w	#4,d1
	bsr	MoveCursor
	bsr	ControlHeadAtt
	bsr	ControlErase
	bsr	ControlNormAtt
	bra	3$

5$	cmpi.b	#CSIshift,(ShiftStatus,a3)
	beq.b	51$
	cmpi.b	#CSIspaceshift,(ShiftStatus,a3)
	beq	513$
	cmpi.b	#ESCshift,(ShiftStatus,a3)
	bne	6$
51$	move.b	#NoShift,(ShiftStatus,a3)
	move.b	(CharIn,a3),d0
	cmpi.b	#'0',d0
	bcs.b	52$
	cmpi.b	#'?',d0
	bhi.b	52$
	move.b	#CSIshift,(ShiftStatus,a3)
	move.b	d0,(CSInum,a3)
	bra	3$
52$	cmpi.b	#'A',d0
	bne.b	53$
	bsr	DoUpward
	bra	3$
53$	cmpi.b	#'B',d0
	bne.b	54$
	bsr	DoDownward
	bra	3$
54$	cmpi.b	#'C',d0
	bne.b	55$
	bsr	DoForward
	bra	3$
55$	cmpi.b	#'D',d0
	bne.b	56$
	bsr	DoBackward
	bra	3$
56$	cmpi.b	#'H',d0
	bne.b	57$
561$	bsr	DoHomeward
	bra	3$
57$	cmpi.b	#'K',d0
	bne.b	58$
571$	bsr	DoEndward
	bra	3$
58$	cmpi.b	#'O',d0
	bne.b	59$
	move.b	#VT100shift,(ShiftStatus,a3)
	bra	3$
59$	cmpi.b	#'~',d0
	bne.b	510$
	cmpi.b	#1,(tegn_fra,NodeBase)		; var dette ifra console ?
	bne.b	512$				; nei
	moveq.l	#0,d0
	move.b	(CSInum,a3),d0
	subi.b	#'0',d0
	bcs.b	512$
	cmpi.b	#10,d0
	bcc.b	512$
	lsl.l	#2,d0
	lea	(keys,MainBase),a0
	adda.l	d0,a0
	move.l	(a0),d0
	beq	3$
	movea.l	d0,a0
	bsr	fseinserttext
	bra	3$

510$	cmpi.b	#'[',d0
	bne.b	511$
	move.b	#CSIshift,(ShiftStatus,a3)
	bra	3$
511$	cmpi.b	#'T',d0
	beq	3171$
	cmpi.b	#'S',d0
	beq	3021$
	cmpi.b	#' ',d0
	bne.b	512$
	move.b	#CSIspaceshift,(ShiftStatus,a3)
	bra	3$

513$	move.b	#NoShift,(ShiftStatus,a3)
	move.b	(CharIn,a3),d0
	cmpi.b	#'A',d0
	beq	561$
	cmpi.b	#'@',d0
	beq	571$
	cmp.b	#'v',d0			; clipboard paste ?
	beq.b	514$			; ja
512$	bsr	ControlAlarm
	bra	3$

514$	cmp.b	#1,(tegn_fra,NodeBase)
	bne.b	512$			; nekter hvis ikke "<CSI>0 v" kom fra console
	jsr	dosnip			; behandler paste
	beq	3$			; ikke noe tegn, fortsett
	move.b	d0,(CharIn,a3)
	bra	31$			; fortsetter uten en readchar

6$	cmpi.b	#VT100shift,(ShiftStatus,a3)
	bne	7$
	move.b	#NoShift,(ShiftStatus,a3)
	move.b	(CharIn,a3),d0
	cmpi.b	#'P',d0
	bne.b	61$
	eori.w	#SAVEBITSF_FSEOverwritemode,(Savebits+CU,NodeBase)
	bsr	showfsemode
	bra	3$
61$	cmpi.b	#'q',d0
	beq.b	62$
	cmpi.b	#'R',d0
	bne.b	63$
62$	bsr	DoEndward
	bra	3$
63$	cmpi.b	#'r',d0
	bne.b	64$
	bsr	DoDownward
	bra	3$
64$	cmpi.b	#'s',d0
	bne.b	65$
	bsr	DoPageDown
	bra	3$
65$	cmpi.b	#'t',d0
	bne.b	66$
	bsr	DoBackward
	bra	3$
66$	cmpi.b	#'u',d0
	beq	3$
	cmpi.b	#'v',d0
	bne.b	67$
	bsr	DoForward
	bra	3$
67$	cmpi.b	#'w',d0
	bne.b	68$
	bsr	DoHomeward
	bra	3$
68$	cmpi.b	#'x',d0
	bne.b	610$
	bsr	DoUpward
	bra	3$
610$	cmpi.b	#'y',d0
	bne.b	611$
	bsr	DoPageUp
	bra	3$
611$	bsr	ControlAlarm
	bra	3$


7$	move.b	#NoShift,(ShiftStatus,a3)
	bra	3$
9$	movem.l	(a7)+,a2/a3
	rts

; a0 - string
; d0.b - tegn
; d1.l - pos
insert	subq.l	#1,d1
	bcc.b	2$
	moveq.l	#0,d1
2$	adda.l	d1,a0
1$	move.b	(a0),d1
	move.b	d0,(a0)+
	move.b	d1,d0
	bne.b	1$
	move.b	#0,(a0)
	rts

; a0 - dest string
; a1 - source string
; d0.l - pos
insertstr
	movem.l	a2/a3/d2/d3,-(a7)
;a2 - dest
;a3 - source
;d2 - destlen
;d3 - sourcelen
	movea.l	a1,a3
	subq.l	#1,d0
	bcc.b	2$
	moveq.l	#0,d0
2$	adda.l	d0,a0
	movea.l	a0,a2
	bsr	strlen
	move.l	d0,d2
	movea.l	a3,a0
	bsr	strlen
	move.l	d0,d3
	add.l	d2,d0
	move.l	d2,d1
	move.b	#0,(1,a2,d0.w)
1$	move.b	(0,a2,d1.w),(0,a2,d0.w)
	subq.l	#1,d0
	subq.l	#1,d1
	bcc.b	1$
4$	move.b	(a3)+,d0
	beq.b	3$
	move.b	d0,(a2)+
	bra.b	4$
3$	movem.l	(a7)+,a2/a3/d2/d3
	rts

; a0 - string
; d0.l - pos
; d1.w - antall
delete	subq.l	#1,d0
	bcc.b	2$
	moveq.l	#0,d0
2$	adda.l	d0,a0
1$	move.b	(0,a0,d1.w),(a0)+
	bne.b	1$
	rts

; a0 - source
; a1 - dest
; d0.l - startpos
; d1.w - maksantall
copy	subq.w	#1,d1
	bcs.b	4$
	subq.l	#1,d0
	bcc.b	2$
	moveq.l	#0,d0
2$	adda.l	d0,a0
3$	move.b	(a0)+,(a1)+
	beq.b	9$
	dbf	d1,3$
4$	move.b	#0,(a1)
9$	rts

	section	data,DATA

; For FSE (og litt i getline)
WarnAtttext	dc.b	'[5;31m',0
NormAtttext	dc.b	'[0;37m',0
HeadAtttext	dc.b	'[0;36m',0
escrbrackettext	dc.b	'[',0
ansiclearsctext	dc.b	'[0;0H[J',0
ansiclearlntext	dc.b	'[K',0
Inserttext	dc.b	'[1L',0
Deletetext	dc.b	'[1M',0

spacehashtext	dc.b	' #',0
spaceresptext	dc.b	' re: ',0
linesinmesgtext	dc.b	'Lines in message:',0
fseinfotext	dc.b	'Ctrl/Z=done, Ctrl/Q=abort, Ctrl/U=help, move with arrow/Wordstar keys',0
inserttext	dc.b	'Insert   ',0
overwritetext	dc.b	'OverWrite',0
autoindenttext	dc.b	'AutoIndent',0
noindenttext	dc.b	'No Indent ',0
ctlrktext	dc.b	'^K',0

fsehelppagetext	dc.b	'Screen editor help:',10,10
		dc.b	'    Enter = new line                   Backspace = delete prev char',10
		dc.b	'    Home = start line, page, message   Del = delete current char',10
		dc.b	'    End = end line, page, message      TAB = skip 8 columns',10,10
		dc.b	'Ctrl/A back a word       Ctrl/B ins. deleted line Ctrl/C forward a page',10
		dc.b	'Ctrl/D forward one char  Ctrl/E up one character  Ctrl/F forward a word',10
		dc.b	'Ctrl/G delete character  Ctrl/L toggle XY display Ctrl/N rewrite screen',10
		dc.b	'Ctrl/O open new line     Ctrl/Q exit DON''T SAVE   Ctrl/R back a page',10
		dc.b	'Ctrl/S back a character  Ctrl/T delete word       Ctrl/V insert/indent modes',10
		dc.b	'Ctrl/X down a character  Ctrl/Y delete line       CTRL/Z SAVE and EXIT',10
		dc.b	'Ctrl/K,S change subject  Ctrl/K,R or W read/write local file (local/sysop only)',10
		dc.b	'Ctrl/K,P toggle public/private                    Ctrl/K,> quote message',10
		dc.b	'                       Ctrl/K+Q exit DON''T SAVE',10
		dc.b	'     Ctrl/L and Ctrl/V keys are remembered between sessions.',10
		dc.b	'Up to 10 lines are remembered by Ctrl/Y and can be reinserted with Ctrl/B',10,10
		dc.b	'          <<Press any key to return to the editor>>',0

		END		; That's all Folks !!!
