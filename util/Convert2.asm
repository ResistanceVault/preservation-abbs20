	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/dos.i'

	include	'asm.i'
	include	'bbs.i'

	section kode,code

;Filelen	=	NodeRecord_SIZEOF
Filelen	=	ConfigRecord_SIZEOF

filename	MACRO
		dc.b	'abbs:Config/ConfigFile',0
;		dc.b	'abbs:Config/nullmodem.config',0
;		dc.b	'ram:node.config',0
		ENDM

PatchCode	MACRO

	move.l	a2,a0
	move.l	d5,d0
	subq.l	#1,d0
	beq.b	1113$
	bcc.b	1111$
1113$	lea	(nopasswdtext),a0
	bsr	writedostext
	bra.b	no_file
1111$	cmp.w	#Sizeof_PassT,d0
	bls.b	1112$
	move.w	#Sizeof_PassT,d0
1112$	add.l	d0,a0
	move.b	#0,(a0)
	move.l	a2,a0
	bsr	writedostext
	lea	(newlinetext),a0
	bsr	writedostext
	move.l	a2,a0
	lea	(dosPassword,MainBase),a1
	bsr	strcopy

;	move.b	#60,ConnectWait(MainBase)
;	or.w	#SETUPF_NullModem,Setup(MainBase)
		ENDM

start	move.l	a0,a2
	move.l	d0,d5
	move.l	4,a6
	openlib	dos

	lea	(patchingtext),a0
	bsr	writedostext
	lea	(configfilename),a0
	bsr	writedostext
	lea	(patchendtext),a0
	bsr	writedostext

	move.l	#Filelen,d0			; allokerer minne
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	bne.s	2$
	lea	nomem,a0
	bsr	writedostext
	bra	no_mem
2$	move.l	d0,MainBase

	move.l	dosbase,a6			; leser filen
	move.l	#configfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	bne.s	3$
	lea	erropenfiletext,a0
	bsr	writedostext
	bra	no_file
3$	move.l	d4,d1
	move.l	MainBase,d2
	move.l	#Filelen,d3
	jsrlib	Read
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d3,d2
	lea	errorreadftext,a0
	bne	9$

	PatchCode

	move.l	dosbase,a6
	move.l	#configfilename,d1
	move.l	#MODE_READWRITE,d2
	jsrlib	Open
	lea	(eropenofiletext),a0
	move.l	d0,d4
	beq.s	9$
	move.l	d4,d1
	move.l	MainBase,d2
	move.l	#Filelen,d3
	jsrlib	Write
	lea	altoktext,a2
	cmp.l	d0,d3
	beq.b	4$
	lea	(errorwriteftext),a2
4$	move.l	d4,d1
	jsrlib	Close
	move.l	a2,a0

9$	bsr	writedostext
no_file	move.l	4,a6
	move.l	#Filelen,d0
	move.l	MainBase,a1
	jsrlib	FreeMem
no_mem	closlib	dos
no_dos	rts

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

copymemrev
	subq.l	#1,d0
	bcs.s	9$
	add.l	d0,a0
	add.l	d0,a1
	move.b	(a0),(a1)
	sub.w	#1,d0
	bcs.s	9$
1$	move.b	-(a0),-(a1)
	dbf	d0,1$
9$	rts

******************************
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.s	1$
	rts

	section bdata,BSS

dosbase		ds.l	1
paramfilename	ds.b	80

	section data,DATA

nopasswdtext	dc.b	'No password entered!',10
		dc.b	'Usage: MakePasswd <password>',10,0
patchingtext	dc.b	10,'[33mPathing: [4m',0
patchendtext	dc.b	'[0m',10,0
errorreadftext	dc.b	'Error reading input file.'
newlinetext	dc.b	10,0
errorwriteftext	dc.b	'Error writing output file.',10,0
altoktext	dc.b	'Conversion sucessfull',10,0
erropenfiletext	dc.b	'Error opening input file',10,0
eropenofiletext	dc.b	'Error opening output file',10,0
nomem		dc.b	'Can''t get memory',10,0
dosname		dc.b	'dos.library',0
configfilename	filename

		END
