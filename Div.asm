******************************************************************************
******									******
******		      ABBS - Amiga Bulletin Board System		******
******			 Written By Geir Inge Høsteng			******
******									******
******************************************************************************

 *****************************************************************
 *
 * NAME
 *	Div.asm
 *
 * DESCRIPTION
 *	Misc support routines
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: Div.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: Div.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'

;	IFND	__M68
	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/iffparse.i'
;	ENDC

	include	'asm.i'
	include	'bbs.i'
	include	'fse.i'
	include	'node.i'

	section kode,code

	XREF	iffbase
	XREF	exebase

	XDEF	dosnip
	XDEF	getnextsnipchar
	XDEF	freepastemem

; z = 1 => ingen flere tegn
getnextsnipchar
	lea	(pastetext,NodeBase),a0
	cmp.w	#$00ff,(a0)			; er det minneblokk ?
	bne.b	1$				; nei
	move.l	(8,a0),a0			; henter buffer adr
1$	move.b	(a0),d0				; henter byte'n
	bne.b	3$
	bsr	freepastemem
	move.b	#0,d0
	bra.b	9$
3$	lea	(1,a0),a1
2$	move.b	(a1)+,(a0)+			; flytter resten
	bne.b	2$
	tst.b	d0
9$	rts

; leser tekst ut fra clipboard'et, og legger det i abbs's paste buffer
; retur z = 0 => tegn i buffer, returnerer første tegnet
dosnip	push	a2/d2/a6
	moveq.l	#0,d2			; ok status
	move.l	iffbase,d0		; har vi iffparse.library ?
	beq	9$			; nope, nocando
	move.l	d0,a6
	jsrlib	AllocIFF		; div setup av IFF struct for bruk mot console
	tst.l	d0
	beq.b	9$
	move.l	d0,a2			; struct iff

	moveq.l	#PRIMARY_CLIP,d0
	jsrlib	OpenClipboard
	move.l	d0,(iff_Stream,a2)
	beq.b	91$

	move.l	a2,a0
	jsrlib	InitIFFasClip

	move.l	a2,a0
	moveq.l	#IFFF_READ,d0
	jsrlib	OpenIFF
	tst.l	d0
	bne.b	92$

	move.l	a2,a0
	move.l	#'FTXT',d0
	move.l	#'CHRS',d1
	jsrlib	StopChunk
	tst.l	d0
	bne.b	93$

	move.l	a2,a0
	moveq.l	#IFFPARSE_SCAN,d0
	jsrlib	ParseIFF
	tst.l	d0
	bne.b	93$

	move.l	a2,a0
	jsrlib	CurrentChunk
	tst.l	d0
	beq.b	93$
	move.l	d0,a0
	move.l	#'FTXT',d0
	cmp.l	(cn_Type,a0),d0
	bne.b	93$
	move.l	#'CHRS',d0
	cmp.l	(cn_ID,a0),d0
	bne.b	93$

	bsr.b	10$

93$	move.l	a2,a0
	jsrlib	CloseIFF
92$	move.l	(iff_Stream,a2),a0
	jsrlib	CloseClipboard
91$	move.l	a2,a0
	jsrlib	FreeIFF
9$	move.l	d2,d0
	pop	a2/d2/a6
	rts

10$	push	a3
	bsr.b	freepastemem
	lea	(pastetext,NodeBase),a1
	move.w	#$0000,(a1)			; markerer ikke noe i paste buffer
	move.l	(cn_Size,a0),d0
	beq.b	19$
	cmp.l	#78,d0				; Plass i pastetext stringen ?
	bls.b	11$				; jepp, dropper alloc
	move.l	d0,(4,a1)			; husker alloc size (i pastetext stringen)
	addq.l	#1,d0				; legger til for null byte
	move.l	exebase,a6
	move.l	#MEMF_CLEAR,d1
	jsrlib	AllocMem
	move.l	iffbase,a6
	lea	(pastetext,NodeBase),a1
	move.l	d0,(8,a1)			; alloc failed
	bne.b	12$
	moveq.l	#78,d0				; tar bare første string'en
	bra.b	11$
12$	move.w	#$00ff,(a1)			; markerer at det er en minne blokk her.
	move.l	(4,a1),a1			; size
	exg	d0,a1				; bytter slik at det blir riktig (d0 = size, a1 = adr)
11$	move.l	a2,a0
	move.l	a1,a3
	jsrlib	ReadChunkBytes			; leser antall bytes
	tst.l	d0
	bmi.b	18$				; error
	beq.b	18$				; 0 bytes
	move.b	#0,(a3,d0.l)
	bsr	getnextsnipchar
	move.b	d0,d2
	bra.b	19$
18$	bsr.b	freepastemem
19$	pop	a3
	rts

;deallokerer minne blokk hvis det er noen der
freepastemem
	push	a6
	lea	(pastetext,NodeBase),a1
	cmp.w	#$00ff,(a1)			; er det minneblokk ?
	bne.b	29$				; nei
	move.w	#$0000,(a1)
	move.l	exebase,a6			; ja, frigir gammel blokk
	move.l	(4,a1),d0			; alloc size
	addq.l	#1,d0				; legger til for null byte
	move.l	(8,a1),a1			; alloc adr
	jsrlib	FreeMem
29$	pop	a6
	rts

;strcopy1line
;1$	move.b	(a0)+,d0
;	cmp.b	#10,d0
;	beq.b	2$
;	cmp.b	#13,d0
;	beq.b	2$
;	move.b	d0,(a1)+
;	bra.b	1$
;2$	move.b	#0,(a1)
;	rts

;	section data,data

	END
