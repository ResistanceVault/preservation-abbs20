******************************************************************************
******									******
******		Broadcast - Adds a file to a file dir.			******
******									******
******		     Broadcast <nodenr> <text>				******
******									******
******************************************************************************

RamBlock	equr	a4

	include 'abbs:first.i'

	include	'exec/types.i'
	include	'exec/ports.i'
	include	'exec/io.i'
	include	'exec/memory.i'
	include	'exec/tasks.i'

	include	'asm.i'
	include	'bbs.i'

	STRUCTURE	ramblocks,0
	STRUCT		msg,ABBSmsg_SIZE
	STRUCT		tmptext,160
	LABEL		ramblocks_SIZE

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
	move.l	#ramblocks_SIZE,d0
	move.l	#MEMF_CLEAR,d1
	jsrlib	AllocMem
	move.l	d0,RamBlock
	tst.l	d0
	bne.s	3$
	lea	notenoughramtxt,a0
	bsr	writedostext
	bra	9$

3$	lea	tmpportname,a0
	moveq.l	#0,d0
	bsr	CreatePort
	bne.s	4$
	lea	nocporttext,a0
	bsr	writedostext
	bra	8$
4$	move.l	d0,port
	lea	msg(RamBlock),a0
	move.l	d0,MN_REPLYPORT(a0)

	move.l	nodenr,a0
	bsr	inputnr
	bpl.s	2$
	lea	illigalnrtext,a0
	bra.s	6$

2$	move.l	d0,d2
	lea	tmptext(RamBlock),a2
	lea	i_msg(a2),a1
	move.l	text,a0
	moveq.l	#80,d0
	bsr	strcopymaxlen
	move.b	#2,i_type(a2)
	move.w	#0,i_franode(a2)
	move.l	a2,a0					; sender meldingen
	move.l	d2,d0
	bsr	sendintermsg
	beq.s	7$
	lea	nactiveusertext,a0
	cmp.w	#Error_No_Active_User,d1
	beq.s	6$
	lea	errnodemsgtext,a0
6$	bsr	writedostext

7$	move.l	port,a0
	bsr	DeletePort
8$	move.l	RamBlock,a1
	move.l	#ramblocks_SIZE,d0
	jsrlib	FreeMem
9$	closlib	dos
no_dos	moveq.l	#0,d0					; returverdi ?
	rts

inputnr	push	d3
	moveq.l	#0,d0
	moveq.l	#0,d3					; ingen feil
	move.l	d0,d1
2$	move.b	(a0)+,d1
	beq.s	9$
	sub.b	#'0',d1
	bcs.s	1$
	cmp.b	#10,d1
	bcc.s	1$
	mulu	#10,d0
	add.l	d1,d0
	bra.s	2$
1$	moveq.l	#-1,d3
9$	and.l	#$ffff,d0
	move.l	d3,d1
	pop	d3
	tst.l	d1
	rts

parsecomandline
	move.l	a2,a0

	cmp.b	#' ',(a0)
	bne.s	1$
	addq.l	#1,a0
	subq.l	#1,d2
	bcs.s	8$
	
1$	move.b	(a0)+,d0
	beq.s	8$
	subq.l	#1,d2
	bcs.s	8$
	cmp.b	#' ',d0
	bne.s	1$
	move.b	#0,-1(a0)
	move.l	a2,nodenr
	move.l	a0,a2

3$	move.b	(a0)+,d0
	beq.s	4$
	subq.l	#1,d2
	bcs.s	4$
	cmp.b	#10,d0
	bne.s	3$
; text kan ha spaces..
4$	move.b	#0,-1(a0)
	move.l	a2,text
	clrz
	rts
8$	lea	usagetext,a0
	bsr	writedostext
	setz
	rts

; sendintermsg (intermsgstruct,receivenode)
;		a0.l		d0.l
sendintermsg
	lea	msg(RamBlock),a1
	move.w	#Main_BroadcastMsg,m_Command(a1)
	move.l	a0,m_Data(a1)
	move.l	d0,m_UserNr(a1)
	bsr	handlemsg
	lea	msg(RamBlock),a1
	move.w	m_Error(a1),d1
	cmp.w	#Error_OK,d1
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
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.s	1$
	rts

strcopymaxlen
2$	move.b	(a0)+,(a1)+
	beq.s	1$
	dbf	d0,2$
	bra.s	9$
1$	move.b	#0,(a1)+
	dbf	d0,1$
9$	rts

	DATA

nodenr		dc.l	0
text		dc.l	0
port		dc.l	0
dosbase		dc.l	0
tmpportname	dc.b	'Broadcast port',0
noporttext	dc.b	'Can''t find abbs !',10,0
nocporttext	dc.b	'Couldn''t create port.',10,0
notenoughramtxt	dc.b	'Not enough ram.',10,0
illigalnrtext	dc.b	'Illegal nodenumber.',10,0
errnodemsgtext	dc.b	'Error sending node msg.',10,0
nactiveusertext	dc.b	'No active user on that node!',10,0
usagetext	dc.b	'Usage : Broadcast <nodenr> <text>',10,0
dosname		dc.b	'dos.library',0
mainmsgportname	dc.b	'ABBS mainport',0

	END
