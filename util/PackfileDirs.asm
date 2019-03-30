******************************************************************************
******									******
******	    Packfiledirs - Removes all dummy files from .fl files	******
******									******
******	Usage : Packfiledirs						******
******									******
******************************************************************************

	include 'abbs:first.i'

	include	'exec/types.i'
	include	'exec/ports.i'
	include	'exec/io.i'
	include	'exec/memory.i'
	include	'exec/tasks.i'
	include	'libraries/dos.i'

	include	'asm.i'
	include	'bbs.i'

start	move.l	4,a6
	openlib	dos
	moveq.l	#0,d7				; abbs er ikke oppe
	lea	mainmsgportname,a1
	jsrlib	FindPort
	lea	noporttext,a0
	tst.l	d0
	bne.s	1$				; abbs er oppe

	move.l	#ConfigRecord_SIZEOF,d0		; ikke oppe
	move.l	#MEMF_CLEAR,d1
	jsrlib	AllocMem
	move.l	d0,MainBase
	tst.l	d0
	lea	notenoughramtxt,a0
	bne.s	2$
	bsr	writedostext
	bra	9$
2$	lea	configfilename,a0
	move.l	MainBase,a1
	move.l	#ConfigRecord_SIZEOF,d0
	bsr	readfile
	beq	8$
	bra.s	3$

1$	lea	abbsuptext,a0
	bsr	writedostext
	bra	9$
	
	moveq.l	#1,d7				; abbs er oppe
	lea	tmpportname,a0
	moveq.l	#0,d0
	bsr	CreatePort
	beq.s	4$
	move.l	d0,port
	lea	msg,a0
	move.l	d0,MN_REPLYPORT(a0)
	bsr	testconfig
	bne	3$
4$	lea	abbsnosetuptext,a0
	bsr	writedostext
	bra	8$

3$	move.w	#MaxFileDirs,d6
	lea	DirNames(MainBase),a4
	moveq.l	#0,d4
5$	tst.b	(a4)				; er det en fildir her ?
	beq.s	6$
	move.l	a4,a0
	move.l	d4,d0
	bsr	readflfile
	beq.s	6$				; tom fil, ikke noe å gjøre
	bpl.s	7$
	lea	errprocfdirtext,a0		; skriver feilmelding
10$	bsr	writedostext
	move.l	a4,a0
	bsr	writedostext
	bsr	nl
	bra.s	8$				; og ut

7$	move.l	a4,a0
	move.l	d4,d0
	bsr	writeflfile
	lea	errwritfdirtext,a0
	beq.s	10$

6$	addq.l	#1,d4
	lea	Sizeof_NameT(a4),a4
	sub.w	#1,d6
	bne.s	5$

8$	tst.l	d7				; har vi brukt abbs ?
	bne.s	81$				; ja. da frigir vi ikke
	move.l	MainBase,a1
	move.l	#ConfigRecord_SIZEOF,d0
	jsrlib	FreeMem
	bra.s	9$
81$	move.l	port,a0
	bsr	DeletePort
9$	closlib	dos
no_dos	rts

writeflfile
	push	a2/d2-d5
	bsr	makefname
	move.l	flbuffersize,d5
	moveq.l	#Fileentry_SIZEOF,d3
	divu	d3,d5
	move.l	flbuffer,a2

	lea	tmptext,a0			; har det
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	move.l	dosbase,a6
	jsrlib	Open
	move.l	d0,d4
	bne.s	1$
	bsr	11$				; cleanup
	bra.s	9$

1$	move.w	Filestatus(a2),d0		; hopper over alle som er slettet
	and.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d0
	bne.s	2$				; vi vil ikke ha denne

	lea	39+Filedescription(a2),a0	; Sikrer at description ikker er for lang
	move.b	#0,(a0)

	move.l	d4,d1
	move.l	a2,d2
	jsrlib	Write
	cmp.l	d0,d3
	beq.s	2$
	bsr	10$
	bra.s	9$

2$	lea	Fileentry_SIZEOF(a2),a2
	sub.w	#1,d5
	bne.s	1$

	bsr	10$
	clrz
9$	pop	a2/d2-d5
	rts

10$	move.l	d4,d1
	jsrlib	Close
11$	move.l	4,a6
	move.l	flbuffersize,d0
	move.l	flbuffer,a1
	jsrlib	FreeMem
	setz
	rts

readflfile
	push	a2/d2
	bsr	makefname
	lea	tmptext,a0			; har det
	bsr	getfilelen			; fillengde
	clrz
	bmi.s	9$				; error
	move.l	d0,d2				; husker size
	move.l	d0,flbuffersize
	beq.s	9$				; ferdig
	move.l	#MEMF_CLEAR,d1			; allokerer buff'er
	jsrlib	AllocMem
	move.l	d0,flbuffer
	beq.s	8$
	lea	tmptext,a0
	move.l	flbuffer,a1
	move.l	d2,d0
	bsr	readfile
	bne.s	7$				; alt ok, ut
	move.l	flbuffer,a1			; frigir
	move.l	d2,d0
	jsrlib	FreeMem
8$	clrz					; setter error
	setn
	bra.s	9$
7$	clrzn
9$	pop	a2/d2
	rts

makefname
	move.l	a0,-(a7)
	lea	conferancepath,a0		; bygger opp filnavn
	lea	tmptext,a1
	bsr	strcopy
	subq.l	#1,a1
	move.l	(a7)+,a0
	bsr	strcopy
	subq.l	#1,a1
	lea	dotfilelisttext,a0
	bra	strcopy

; a0 = file name.
getfilelen
	push	d2/d3/d4
	moveq.l	#-1,d4
	move.l	dosbase,a6
	move.l	a0,d1
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	move.l	d0,d1
	beq.s	1$
	move.l	d0,d3
	lea	infoblock,a0
	move.l	a0,d2
	jsrlib	Examine
	move.l	d0,d2
	beq.s	2$
	lea	infoblock,a0
	move.l	124(a0),d4
2$	move.l	d3,d1
	jsrlib	UnLock
1$	move.l	d4,d0
	move.l	4,a6
	pop	d2/d3/d4
	rts

testconfig
	lea	msg,a1
	move.w	#Main_testconfig,m_Command(a1)
	bsr	handlemsg
	beq.s	9$
	lea	msg,a0
	move.l	m_Data(a0),MainBase
	move.w	m_UserNr(a0),d0
9$	rts

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

;a0 = filename
;a1 = adr
;d0 = size
readfile
	push	d2-d5/a6/a2
	move.l	a0,a2
	move.l	dosbase,a6
	move.l	d0,d3
	move.l	a1,d5
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.s	2$
	move.l	d4,d1
	move.l	d5,d2
	jsrlib	Read
	cmp.l	d3,d0
	beq.s	1$
	move.l	d4,d1
	jsrlib	Close
2$	lea	errreadingftext,a0
	bsr	writedostext
	move.l	a2,a0
	bsr	writedostext
	bsr	nl
	setz
	bra.s	9$
1$	move.l	d4,d1
	jsrlib	Close
	clrz
9$	pop	d2-d5/a6/a2
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

nl	lea	nltext,a0
;	bra	writedostext

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
strlen	moveq.l	#-1,d0
1$	tst.b	(a0)+
	dbeq	d0,1$
	not.w	d0
	ext.l	d0
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

	section variabler,BSS

infoblock	ds.b	fib_SIZEOF+4
port		ds.l	1
dosbase		ds.l	1
flbuffer	ds.l	1
flbuffersize	ds.l	1
msg		ds.b	ABBSmsg_SIZE
tmpfileentry	ds.b	Fileentry_SIZEOF
tmptext		ds.b	80

	section tekst,DATA

nltext		dc.b	10,0
readerrortext	dc.b	'Read error',10,0
noporttext	dc.b	'Can''t find abbs !',10,0
abbsnosetuptext	dc.b	'ABBS not setup!',10,0
configfilename	dc.b	'abbs:config/configfile',0
tmpportname	dc.b	'Packfiledirs port',0
nocporttext	dc.b	'Couldn''t create port.',10,0
notenoughramtxt	dc.b	'Not enough ram.',10,0
dosname		dc.b	'dos.library',0
mainmsgportname	dc.b	'ABBS mainport',0
errreadingftext	dc.b	'Error reading file : ',0
errprocfdirtext	dc.b	'Error processing filedir : ',0
errwritfdirtext	dc.b	'Error writing filedir : ',0
conferancepath	dc.b	'abbs:conferences/',0
dotfilelisttext	dc.b	'.fl',0
abbsuptext	dc.b	'You must close down abbs first!',10,0
	END
