******************************************************************************
******									******
******		SysopAvail - Sets sysop avail flag.			******
******									******
******			  SysopAvail [off]				******
******									******
******************************************************************************

	include 'abbs:first.i'

	include	'exec/types.i'
	include	'exec/ports.i'
	include	'exec/io.i'
	include	'exec/tasks.i'
	include	'exec/memory.i'

	include	'asm.i'
	include	'bbs.i'

start	move.l	4,a6
	move.l	d0,d2
	move.l	a0,a2
	openlib	dos
	lea	mainmsgportname,a1
	jsrlib	FindPort
	tst.l	d0
	bne.s	1$
	lea	noporttext,a0
	bsr	writedostext
	bra	9$
1$	bsr	parsecomandline
	beq	9$
	lea	tmpportname,a0
	moveq.l	#0,d0
	bsr	CreatePort
	bne.s	4$
	lea	nocporttext,a0
	bsr	writedostext
	bra	9$
4$	move.l	d0,port
	lea	msg,a0
	move.l	d0,MN_REPLYPORT(a0)

; 0 = availible
; 1 = not availible

	lea	msg,a1
	move.w	#Main_NotAvailSysop,m_Command(a1)
	moveq.l	#0,d0
	tst.w	off
	bne.s	2$
	moveq.l	#1,d0
2$	move.l	d0,m_Data(a1)
	bsr	handlemsg

7$	move.l	port,a0
	bsr	DeletePort
9$	closlib	dos
no_dos	moveq.l	#0,d0					; returverdi ?
	rts

parsecomandline
	move.l	a2,a0

	move.b	(a0),d0
	cmp.b	#10,d0
	beq.s	9$		; ingen tekst
	cmp.b	#' ',d0
	bne.s	1$
	addq.l	#1,a0
	subq.l	#1,d2
	bcs.s	9$
1$	move.b	(a0)+,d0
	beq.s	4$
	subq.l	#1,d2
	bcs.s	4$
3$	cmp.b	#' ',d0
	beq.s	8$
	cmp.b	#10,d0
	bne.s	1$

4$	move.b	#0,-1(a0)
	move.l	a2,a0
	bsr	upstring
	moveq.l	#3,d0
	lea	offtext,a1
	bsr	comparestringsfull
	bne.s	8$			; ikke off
	move.w	#1,off
9$	clrz
	rts
8$	lea	usagetext,a0
	bsr	writedostext
	setz
	rts

handlemsg
	move.l	a1,-(a7)
	jsrlib	Forbid
	lea	mainmsgportname,a1
	jsrlib	FindPort
	move.l	(a7)+,a1
	tst.l	d0
	beq.s	9$
	move.l	d0,a0
	jsrlib	PutMsg
	jsrlib	Permit
1$	move.l	port,a0
	jsrlib	WaitPort
	tst.l	d0
	beq.s	1$
	move.l	port,a0
	jsrlib	GetMsg
	tst.l	d0
	beq.s	1$
	rts
9$	jsrlib	Permit
	setz
	rts

******************************
;CreatePort
;inputs : name,priority (a0,d0)
;outputs: msgport (d0)
******************************
CreatePort
	movem.l	d2/d3/a2/a3,-(sp)
	move.l	a0,a2
	move.l	d0,d3
	move.l	#MP_SIZE,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	beq.s	1$
	move.l	d0,a3
	moveq.l	#-1,d0
	move.l	d0,d2
	jsrlib	AllocSignal
	cmp.l	d2,d0
	beq.s	2$
	move.b	d0,MP_SIGBIT(a3)
	sub.l	a1,a1
	jsrlib	FindTask
	move.l	d0,MP_SIGTASK(a3)
	move.l	a2,LN_NAME(a3)
	move.b	d3,LN_PRI(a3)
	move.b	#NT_MSGPORT,LN_TYPE(a3)
	move.b	#PA_SIGNAL,MP_FLAGS(a3)
	move.l	a3,a1
	jsrlib	AddPort
	move.l	a3,d0
	movem.l	(sp)+,a2/a3/d2/d3
	rts

2$	move.l	a3,a1
	move.l	#MP_SIZE,d0
	jsrlib	FreeMem
1$	movem.l	(sp)+,a2/a3/d2/d3
	setz
	rts

******************************
;DeletePort
;inputs : msgport (a0)
;outputs: none
******************************
DeletePort
	move.l	a2,-(sp)
	move.l	a0,a2
	move.l	a0,a1
	jsrlib	RemPort
	move.b	MP_SIGBIT(a2),d0
	jsrlib	FreeSignal
	move.l	a2,a1
	move.l	#MP_SIZE,d0
	jsrlib	FreeMem
	move.l	(sp)+,a2
	rts

writedostext
	movem.l	d2-d3/a6,-(a7)
	move.l	dosbase,a6
	move.l	a0,d2
	bsr	strlen
	move.l	d0,d3
	jsrlib	Output
	move.l	d0,d1
	jsrlib	Write
	movem.l	(a7)+,d2-d3/a6
	rts

******************************
;len = strlen (string)
;d0		a0
******************************
strlen	move.l	a0,d0
1$	tst.b	(a0)+
	bne.s	1$
	subq.l	#1,a0
	sub.l	d0,a0
	move.l	a0,d0
	rts

******************************
;char = upchar (char)
;d0.b		d0.b
******************************

upchar	cmp.b	#'a',d0
	bcs.s	1$
	cmp.b	#'z',d0
	bhi.s	2$
	sub.b	#'a'-'A',d0
1$	rts
2$	cmp.b	#224,d0		; Starten på utenlandske tegn (små)
	bcs.s	3$
	sub.b	#32,d0		; Forskjellen på Store og små ISO tegn.
3$	rts

******************************
;string = upstring (string)
;a0		    a0
;does a upchar on every char in string
******************************

upstring
	movem.l	a0/d0,-(sp)
	move.l	a0,a1
3$	move.b	(a0)+,d0
	beq.s	1$
	bsr	upchar
	move.b	d0,(a1)+
	bra.s	3$
1$	movem.l	(sp)+,a0/d0
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

	BSS

port	ds.l	1
dosbase	ds.l	1
off	ds.w	1
msg	ds.b	ABBSmsg_SIZE

	DATA

offtext		dc.b	'OFF',0
tmpportname	dc.b	'SysopAvail port',0
noporttext	dc.b	'Can''t find abbs !',10,0
nocporttext	dc.b	'Couldn''t create port.',10,0
usagetext	dc.b	'Usage : SysopAvail [OFF]',10,0
dosname		dc.b	'dos.library',0
mainmsgportname	dc.b	'ABBS mainport',0

	END
