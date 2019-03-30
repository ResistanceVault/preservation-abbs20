******************************************************************************
******									******
******		      ABBS - Amiga Bulletin Board System		******
******			 Written By Geir Inge Høsteng			******
******									******
******************************************************************************

 *****************************************************************
 *
 * NAME
 *	exeption.asm
 *
 * DESCRIPTION
 *	Exeption code for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: exeption.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: exeption.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST

	include	'exec/types.i'
	include	'exec/tasks.i'
	include	'exec/execbase.i'
	include	'exec/memory.i'
	include	'exec/lists.i'
	include	'dos/dos.i'

	include	'asm.i'
	include "first.i"
	include "bbs.i"
	include "fse.i"
	include "node.i"


	LIST

	section	gurustuff,code

	XDEF	Exception

	XREF	first
	XREF	dosbase
	XREF	mainstack
	XREF	mainmemoryblock

	XDEF	Environment

***************************************************************************
***				Guru traping				***
***************************************************************************

	SUPER
Exception
	move.l	(a7)+,d0		; get exception # from stack
	move.l	d0,(GURUNum)		; and save it
	cmpi.l	#3,d0			; ADDRESS or BUS error?
	bgt.b	2$			; no, skip adjustment
	btst	#0,(Environment+3)	; is it 68010 or 68020?
	beq.b	1$			; 0 means NO
	bset	#7,(8,a7)		; set Rerun flag
	bra.b	2$

1$	addq.l	#8,a7			; adjust for 68000
2$	move.l	(2,a7),d0		; get PC at crash
	move.l	d0,(GURUAddr)		; and save it
	move.l	#$1fffff,d1
3$	move.w	d1,($dff180)
	subq.l	#1,d1
;	bne.b	3$
	bra.b	3$
	tst.l	d0
	move.l	#GURUExit,(2,a7)		; use our own exit point
	rte

GURUExit
	movem.l	d0-d7/a0-a7,-(sp)	; save all registers
	move.l	4,a6			; make sure we are working with Exec
	jsrlib	GetCC			; safe way - works with all CPUs
	movea.l	(ThisTask,a6),a3
	movea.l	(TC_TRAPDATA,a3),a4	; make sure we have a valid # in a4
	move.l	d0,(Flags)		; save area
	movem.l	(sp)+,d0-d7
	movem.l	d0-d7,(DDump)		; save data reg contents
	movem.l	(sp)+,d0-d7
	movem.l	d0-d7,(ADump)		; save address reg contents
	tst.l	(StackPtr)		; if there's something there
	bne	GExit1			; ...we've been here before!
	move.l	(A7Store),d0		; make sure we have proper TOS
	move.l	d0,(StackPtr)		; ...and save it

	movea.l	(LN_NAME,a3),a0
	moveq.l	#-1,d0			; strlen
4$	tst.b	(a0)+
	dbeq	d0,4$
	not.w	d0
	andi.l	#$ffff,d0
	movea.l	(LN_NAME,a3),a0
	addq.l	#4,d0			; adjust for shift
	lsr.l	#2,d0
	move.l	d0,(NameLen)		; store length
	add.l	d0,(FAILlen)		; and sub-chunk total

	moveq	#0,d0			; clear d0 for use
	lea	(VBlankFrequency,a6),a0	; set up a0 to find correct data
	move.b	(a0)+,d0		; get just in case
	move.l	d0,(VBlankFreq)		; ...so we can figure what
	move.b	(a0),d0			; ...type of machine
	move.l	d0,(PowerSupFreq)		; ...we're working on

	lea	(first-4),a0		; get seglist ptr
	moveq	#-1,d0			; always at least 1
2$	addq.l	#1,d0
	move.l	(a0),d1			; find end of list
	beq.b	3$
	lsl.l	#2,d1			; BPTR!!!!!
	movea.l	d1,a0
	bra.b	2$

3$	add.l	d0,(SegCount)		; store # of seglist pointers
	add.l	d0,d0			; multiply by 2 for longword count
	add.l	d0,(FAILlen)		; and sub-chunk length

	move.l	(mainstack),d0
	cmpa.l	(mainmemoryblock),a4
	beq.b	1$
	move.l	(nodestack,a4),d0	; get top of stack
1$	move.l	d0,(StackTop)

	sub.l	(StackPtr),d0		; find number of bytes used
	addq.l	#4,d0			; adjust for longword conversion
	lsr.l	#2,d0			; convert from bytes to long
	move.l	d0,(StackLen)		; and save
	add.l	d0,(s2len)		; and sub-chunk total

	move.l	a5,-(sp)		; save a5 for later
	jsrlib	Forbid			; don't let 'em change while we ask
	move.l	(MemList+LH_HEAD,a6),d0	; first node in MemList
checkchip
	movea.l	d0,a5			; move node address to address reg
	move.w	(MH_ATTRIBUTES,a5),d4	; get node attributes
	btst	#MEMB_CHIP,d4		; is it chip?
	beq.b	checkfast		; no, go on
	lea	(chipAvail),a3
	bsr.w	AddIt
checkfast
	btst	#MEMB_FAST,d4		; is it fast?
	beq.b	next			; no, go on
	lea	(fastAvail),a3
	bsr.w	AddIt
next
	move.l	(LN_SUCC,a5),d0		; get address of next node
	bne.b	checkchip		; ...and loop back if valid
	jsrlib	Permit			; allow others access again
	move.l	#MEMF_CHIP+MEMF_LARGEST,d1 ; to find largest hunk in chip ram
	jsrlib	AvailMem
	move.l	d0,(chipLargest)		; store
	move.l	#MEMF_FAST+MEMF_LARGEST,d1 ; to find largest hunk in fast ram
	jsrlib	AvailMem
	move.l	d0,(fastLargest)		; store
	movea.l	(sp)+,a5		; and restore a5

	movea.l	(dosbase),a6
	lea	(DumpName),a0		; get name of output file
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2	; create new file
	jsrlib	Open
	bne.b	4$
	lea	(DumpPath),a0		; if error in current dir, try DF0:
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	bne.b	4$
	move.b	#'1',(DumpPath+3)		; still error?	Try DF1:
	lea	(DumpPath),a0
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	beq	GExit2			; if no error, continue (finally!)
4$
	move.l	d0,d5			; save file handle for Write
	move.l	d5,d1			; get file handle
	lea	(PGTB),a0			; first part of fixed
	move.l	a0,d2
	move.l	#chunk_len_1,d3 	; length of first
	jsrlib	Write			; ...since it gets written over

	move.l	d5,d1			; get file handle
	move.l	4,a0
	movea.l	(ThisTask,a0),a0
	move.l	(LN_NAME,a0),d2		; get address of program name
	move.l	(NameLen),d3		; get # longs in program name
	lsl.l	#2,d3			; ..and convert to bytes
	jsrlib	Write

	move.l	d5,d1			; get file handle
	lea	(Environment),a0		; second part of fixed
	move.l	a0,d2
	move.l	#chunk_len_2,d3 	; length of second part
	jsrlib	Write

	lea	(first-8),a0		; address of seglist (size of seg)
	move.l	(a0)+,d0		; segsize
	move.l	d0,(TempStore+4)		; save it
	move.l	a0,(TempStore)		; store first number
	move.l	(SegCount),d4
5$
	move.l	d5,d1			; get file handle
	lea	(TempStore),a0
	move.l	a0,d2			; address of write buffer
	moveq	#TempSize,d3		; size of segment pointer
	jsrlib	Write
	movea.l	(TempStore),a0		; retrieve pointer
	move.l	(a0),d0			; get next seg pointer
	lsl.l	#2,d0			; adjust
	move.l	d0,(TempStore)		; ..and save
	movea.l	d0,a0
	move.l	(-4,a0),d0		; get segsize
	move.l	d0,(TempStore+4)		; ...and save it
	subq.l	#1,d4			; done yet?
	bne.b	5$			; no, do next

	move.l	d5,d1
	lea	(subFMEM),a0
	move.l	a0,d2
	move.l	#FMEMlen,d3
	jsrlib	Write

	move.l	d5,d1			; (get the idea?)
	lea	(subREGS),a0		; third part of fixed
	move.l	a0,d2
	move.l	#chunk_len_3,d3 	; length of third
	jsrlib	Write

	move.l	(StackLen),d0		; get length of stack used
	cmpi.l	#2048,d0		; > 8k ?
	bgt.b	6$			; yes, dump two chunks
	move.l	d5,d1
	lea	(STAK2),a0		; whole stack chunk
	move.l	a0,d2
	moveq	#STAK2len,d3		; length of fixed part
	jsrlib	Write

	move.l	d5,d1
	move.l	(StackPtr),d2		; address of stack
	move.l	(StackLen),d3		; get # longwords on stack
	lsl.l	#2,d3			; ..and convert to bytes
	jsrlib	Write
	bra.b	7$

6$	move.l	d5,d1
	lea	(STAK3),a0		; top4k chunk
	move.l	a0,d2
	moveq	#STAK3len,d3		; length of fixed part
	jsrlib	Write

	move.l	d5,d1
	move.l	(StackTop),d2		; find top of stack
	subi.l	#4096,d2		; find top-4k
	move.l	#4096,d3		; # bytes to write
	jsrlib	Write

	move.l	d5,d1
	lea	(STAK4),a0		; bottom4k chunk
	move.l	a0,d2
	moveq	#STAK4len,d3		; length of fixed part
	jsrlib	Write

	move.l	d5,d1
	move.l	(StackPtr),d2		; current stack address
	move.l	#4096,d3		; # bytes to write
	jsrlib	Write
7$
9$
	move.l	d5,d1
	moveq	#0,d2			; offset from EOF
	moveq	#1,d3			; OFFSET_END
	jsrlib	Seek			; Seek returns OLD position
	moveq	#3,d1			; did user write even longwords?
	and.l	d0,d1
	beq.b	10$			; Yep!	Nice Human.
	move.l	d1,d6			; Nope, save for later.
	clr.l	(TempStore)		; clear temp storage
	move.l	d5,d1
	lea	(TempStore),a0
	move.l	a0,d2
	moveq	#4,d3
	sub.l	d6,d3			; find how many NULLs to pad
	jsrlib	Write
	bra.b	9$
10$
	move.l	d5,d1
	moveq	#0,d2			; offset to 'Length' field
	moveq	#1,d3			; OFFSET_END
	jsrlib	Seek			; make sure we are at end of file
	move.l	d5,d1
	moveq	#4,d2			; offset to 'Length' field
	moveq	#-1,d3			; OFFSET_BEGINNING
	jsrlib	Seek
	subq.l	#8,d0			; adjust total length
	lsr.l	#2,d0			; adjust to longwords
	move.l	d0,(TempStore)		; save for write
	move.l	d5,d1
	lea	(TempStore),a0
	move.l	a0,d2
	moveq.l	#4,d3
	jsrlib	Write			; write 'Length' field
GExit1
	move.l	d5,d1
	beq.b	GExit2
	movea.l	(dosbase),a6
	jsrlib	Close

GExit2
;	move.l	4,a6
;1$	moveq.l	#0,d0			; Venter for alltid.
;	jsrlib	Wait
;	bra.s	1$			; Kommer aldri hit, men ...
	movea.l	(mainstack),a7
	cmpa.l	(mainmemoryblock),a4
	beq.b	1$
	movea.l	(nodestack,a4),a7	; get top of stack
1$	rts				; ;Hopper ut...

*-----------------------------------------------------------------------
* AddIt:	routine to add memory parts to variables

AddIt
	move.l	(MH_FREE,a5),d0
	add.l	d0,(a3)		 ; add to available
	move.l	(MH_UPPER,a5),d0
	sub.l	(MH_LOWER,a5),d0
	add.l	d0,(4,a3)		; add to Max section
	rts

	section	data,DATA

DumpPath	dc.b	'DF0:'
DumpName	dc.b	'SnapShot.TB',0
TempStore	dc.l	0,0		; Temporary storage for BPTR -> APTR
TempSize	equ	*-TempStore

	cnop	0,4

*--------------------------------------------------------------------------
* New IFF chunk format -
*	PGTB = Program Traceback, header for chunk
*	FAIL = reason for and environment of crash
*	REGS = registers at time of crash, including PC and CCR
*	VERS = version, revision, name of this program
*	STAK = ENTIRE stack at time of crash or, alternately,
*		the top and bottom 4k if the stack used is > 8k
*	UDAT = optional user data dump (if _ONGURU is set to a
*		function pointer in the user's program)
*--------------------------------------------------------------------------

PGTB		dc.b	'PGTB'
Length		dc.l	0		; length of chunk (in longwords)

subFAIL 	dc.b	'FAIL'
FAILlen 	dc.l	9
NameLen 	dc.l	0		; length of program name
chunk_len_1	equ	*-PGTB
Environment	dc.l	0		; CPU (, Math)
VBlankFreq	dc.l	0		;	PAL = 50, NTSC = 60 (approx.)
PowerSupFreq	dc.l	0		; Europe = 50,	USA = 60 (approx.)
Starter 	dc.l	-1		; 0 = WB, -1 = CLI
GURUNum 	dc.l	0		; cause of crash (GURU #)
SegCount	dc.l	1		; # hunks in seglist
chunk_len_2	equ	*-Environment

subFMEM 	dc.b	'FMEM'		; FMEM - free memory at crash
		dc.l	6
chipAvail	dc.l	0		; available chip memory
chipMax 	dc.l	0		;	maximum	chip memory
chipLargest	dc.l	0		;	largest	chip memory
fastAvail	dc.l	0		; available fast memory
fastMax 	dc.l	0		;	maximum	fast memory
fastLargest	dc.l	0		;	largest	fast memory
FMEMlen 	equ	*-subFMEM

subREGS 	dc.b	'REGS'		; REGS - register storage field
REGSlen 	dc.l	18
GURUAddr	dc.l	0		; PC at time of crash
Flags		dc.l	0		; Condition Code Register (CCR)
DDump		dc.l	0,0,0,0,0,0,0,0 ; data registers
ADump		dc.l	0,0,0,0,0,0,0	; address registers
A7Store 	dc.l	0

subVERS 	dc.b	'VERS'		; VERS - program version field
		dc.l	5
		dc.l	VERSION 	; version #
		dc.l	REVISION	; revision #
		dc.l	2		; length of name of program
		dc.b	'ABBS',0,0,0,0	; name

subSTAK 	dc.b	'STAK'		; STAK - stack field
STAKlen 	dc.l	4
Type		dc.l	0		; 0 = Info
StackTop	dc.l	0		; top of stack pointer
StackPtr	dc.l	0		; current Stack Pointer
StackLen	dc.l	0		; # bytes used on stack
chunk_len_3	equ	*-subREGS

STAK2		dc.b	'STAK'
s2len		dc.l	1		; length of subtype
		dc.l	1		; 1 = whole stack
STAK2len	equ	*-STAK2

STAK3		dc.b	'STAK'
		dc.l	1025
		dc.l	2		; 2 = top 4k of stack
STAK3len	equ	*-STAK3

STAK4		dc.b	'STAK'
		dc.l	1025
		dc.l	3		; 3 = bottom 4k of stack
STAK4len	equ	*-STAK4

STAK5		dc.b	'STAK'
_STAKOffset	dc.l	0
		dc.l	4		; 4 = user defined amount
STAK5len	equ	*-STAK5

UDAT		dc.b	'UDAT'
		dc.l	0
UDATlen 	equ	*-UDAT
