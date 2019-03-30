
	IFD	__ArgAsm
	opt	L+,D+,O+	; linkable, debuginfo, optimize (?)
	ENDC

	include	'exec/types.i'
	include	'exec/memory.i'

	include	'asm.i'

start	move.l	4,a6
	moveq.l	#-1,d0		; Allokerer 4 giga bytes.
	moveq.l	#0,d1
	jsrlib	AllocMem
	tst.l	d0		; Fikk vi minne ?
	beq.s	9$		; Nei, trodde ikke det ...
	move.l	d0,a1		; For sikkerhets skyld, frigi minnet hvis vi
	moveq.l	#-1,d0		; fikk noe.
	jsrlib	FreeMem
9$	rts
	END
