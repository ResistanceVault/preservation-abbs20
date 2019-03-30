

NewWindowStructure1:
	dc.w	0,19
	dc.w	640,200
	dc.b	0,1
	dc.l	GADGETUP
	dc.l	WINDOWDRAG+WINDOWDEPTH+ACTIVATE+NOCAREREFRESH
	dc.l	GadgetList1
	dc.l	NULL
	dc.l	NewWindowName1
	dc.l	NULL
	dc.l	NULL
	dc.w	5,5
	dc.w	-1,-1
	dc.w	WBENCHSCREEN
NewWindowName1:
	dc.b	'Config node',0
	cnop 0,2
UNDOBUFFER:
	dcb.b 61,0
	cnop 0,2
GadgetList1:
Gadget1:
	dc.l	Gadget2
	dc.w	6,14
	dc.w	87,10
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border1
	dc.l	NULL
	dc.l	IText1
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Border1:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors1
	dc.l	NULL
BorderVectors1:
	dc.w	0,0
	dc.w	88,0
	dc.w	88,11
	dc.w	0,11
	dc.w	0,0
IText1:
	dc.b	3,0,RP_JAM2,0
	dc.w	4,1
	dc.l	NULL
	dc.l	ITextText1
	dc.l	NULL
ITextText1:
	dc.b	'Local node',0
	cnop 0,2
Gadget2:
	dc.l	Gadget3
	dc.w	6,27
	dc.w	76,10
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border2
	dc.l	NULL
	dc.l	IText2
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Border2:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors2
	dc.l	NULL
BorderVectors2:
	dc.w	0,0
	dc.w	77,0
	dc.w	77,11
	dc.w	0,11
	dc.w	0,0
IText2:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText2
	dc.l	NULL
ITextText2:
	dc.b	'Tiny Mode',0
	cnop 0,2
Gadget3:
	dc.l	Gadget4
	dc.w	232,14
	dc.w	26,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT
	dc.w	STRGADGET
	dc.l	Border3
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget3SInfo
	dc.w	1
	dc.l	NULL
Gadget3SInfo:
	dc.l	Gadget3SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	3
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget3SIBuff:
	dc.b	'0',0
PWstringlen	set	*-Gadget3SIBuff
	dcb.b 3-PWstringlen,0
	cnop 0,2
Border3:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors3
	dc.l	NULL
BorderVectors3:
	dc.w	0,0
	dc.w	27,0
	dc.w	27,9
	dc.w	0,9
	dc.w	0,0
Gadget4:
	dc.l	Gadget5
	dc.w	232,25
	dc.w	320,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border4
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget4SInfo
	dc.w	NULL
	dc.l	2
Gadget4SInfo:
	dc.l	Gadget4SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	41
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget4SIBuff:
	dc.b	'serial.device',0
PWstringlen	set	*-Gadget4SIBuff
	dcb.b 41-PWstringlen,0
	cnop 0,2
Border4:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors4
	dc.l	NULL
BorderVectors4:
	dc.w	0,0
	dc.w	321,0
	dc.w	321,9
	dc.w	0,9
	dc.w	0,0
Gadget5:
	dc.l	Gadget6
	dc.w	179,40
	dc.w	456,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border5
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget5SInfo
	dc.w	3
	dc.l	NULL
Gadget5SInfo:
	dc.l	Gadget5SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	61
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget5SIBuff:
	dc.b	'AT&FS0=0&C1&D2H0E0&G0+C0+M2',0
PWstringlen	set	*-Gadget5SIBuff
	dcb.b 61-PWstringlen,0
	cnop 0,2
Border5:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors5
	dc.l	NULL
BorderVectors5:
	dc.w	0,0
	dc.w	457,0
	dc.w	457,9
	dc.w	0,9
	dc.w	0,0
Gadget6:
	dc.l	Gadget7
	dc.w	179,52
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border6
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget6SInfo
	dc.w	4
	dc.l	NULL
Gadget6SInfo:
	dc.l	Gadget6SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget6SIBuff:
	dc.b	'ATH1',0
PWstringlen	set	*-Gadget6SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border6:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors6
	dc.l	NULL
BorderVectors6:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget7:
	dc.l	Gadget8
	dc.w	179,64
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border7
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget7SInfo
	dc.w	5
	dc.l	NULL
Gadget7SInfo:
	dc.l	Gadget7SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget7SIBuff:
	dc.b	'ATH0',0
PWstringlen	set	*-Gadget7SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border7:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors7
	dc.l	NULL
BorderVectors7:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget8:
	dc.l	Gadget9
	dc.w	179,76
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border8
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget8SInfo
	dc.w	6
	dc.l	NULL
Gadget8SInfo:
	dc.l	Gadget8SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget8SIBuff:
	dc.b	'ATDT',0
PWstringlen	set	*-Gadget8SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border8:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors8
	dc.l	NULL
BorderVectors8:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget9:
	dc.l	Gadget10
	dc.w	179,88
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border9
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget9SInfo
	dc.w	7
	dc.l	NULL
Gadget9SInfo:
	dc.l	Gadget9SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget9SIBuff:
	dc.b	'RING',0
PWstringlen	set	*-Gadget9SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border9:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors9
	dc.l	NULL
BorderVectors9:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget10:
	dc.l	Gadget11
	dc.w	179,100
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border10
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget10SInfo
	dc.w	8
	dc.l	NULL
Gadget10SInfo:
	dc.l	Gadget10SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget10SIBuff:
	dc.b	'ATA',0
PWstringlen	set	*-Gadget10SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border10:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors10
	dc.l	NULL
BorderVectors10:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget11:
	dc.l	Gadget12
	dc.w	179,112
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border11
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget11SInfo
	dc.w	9
	dc.l	NULL
Gadget11SInfo:
	dc.l	Gadget11SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget11SIBuff:
	dc.b	'CONNECT',0
PWstringlen	set	*-Gadget11SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border11:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors11
	dc.l	NULL
BorderVectors11:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget12:
	dc.l	Gadget13
	dc.w	179,-29
	dc.w	456,8
	dc.w	GRELBOTTOM
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border12
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget12SInfo
	dc.w	12
	dc.l	NULL
Gadget12SInfo:
	dc.l	Gadget12SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	61
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget12SIBuff:
	dc.b	'node1.config',0
PWstringlen	set	*-Gadget12SIBuff
	dcb.b 61-PWstringlen,0
	cnop 0,2
Border12:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors12
	dc.l	NULL
BorderVectors12:
	dc.w	0,0
	dc.w	457,0
	dc.w	457,9
	dc.w	0,9
	dc.w	0,0
Gadget13:
	dc.l	Gadget14
	dc.w	14,-15
	dc.w	91,10
	dc.w	GRELBOTTOM
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border13
	dc.l	NULL
	dc.l	IText3
	dc.l	NULL
	dc.l	NULL
	dc.w	-3
	dc.l	NULL
Border13:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors13
	dc.l	NULL
BorderVectors13:
	dc.w	0,0
	dc.w	92,0
	dc.w	92,11
	dc.w	0,11
	dc.w	0,0
IText3:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText3
	dc.l	NULL
ITextText3:
	dc.b	'Save config',0
	cnop 0,2
Gadget14:
	dc.l	Gadget15
	dc.w	113,-15
	dc.w	91,10
	dc.w	GRELBOTTOM
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border14
	dc.l	NULL
	dc.l	IText4
	dc.l	NULL
	dc.l	NULL
	dc.w	-2
	dc.l	NULL
Border14:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors14
	dc.l	NULL
BorderVectors14:
	dc.w	0,0
	dc.w	92,0
	dc.w	92,11
	dc.w	0,11
	dc.w	0,0
IText4:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText4
	dc.l	NULL
ITextText4:
	dc.b	'Load config',0
	cnop 0,2
Gadget15:
	dc.l	Gadget16
	dc.w	209,-15
	dc.w	51,10
	dc.w	GRELBOTTOM
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border15
	dc.l	NULL
	dc.l	IText5
	dc.l	NULL
	dc.l	NULL
	dc.w	-1
	dc.l	NULL
Border15:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors15
	dc.l	NULL
BorderVectors15:
	dc.w	0,0
	dc.w	52,0
	dc.w	52,11
	dc.w	0,11
	dc.w	0,0
IText5:
	dc.b	3,0,RP_JAM2,0
	dc.w	2,1
	dc.l	NULL
	dc.l	ITextText5
	dc.l	NULL
ITextText5:
	dc.b	'Cancel',0
	cnop 0,2
Gadget16:
	dc.l	Gadget17
	dc.w	179,124
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border16
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget16SInfo
	dc.w	10
	dc.l	NULL
Gadget16SInfo:
	dc.l	Gadget16SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget16SIBuff:
	dc.b	'AT',0
PWstringlen	set	*-Gadget16SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border16:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors16
	dc.l	NULL
BorderVectors16:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget17:
	dc.l	Gadget18
	dc.w	179,136
	dc.w	136,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border17
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget17SInfo
	dc.w	11
	dc.l	NULL
Gadget17SInfo:
	dc.l	Gadget17SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	17
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget17SIBuff:
	dc.b	'OK',0
PWstringlen	set	*-Gadget17SIBuff
	dcb.b 17-PWstringlen,0
	cnop 0,2
Border17:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors17
	dc.l	NULL
BorderVectors17:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,9
	dc.w	0,9
	dc.w	0,0
Gadget18:
	dc.l	Gadget19
	dc.w	389,107
	dc.w	136,10
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border18
	dc.l	NULL
	dc.l	IText6
	dc.l	NULL
	dc.l	NULL
	dc.w	20
	dc.l	NULL
Border18:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors18
	dc.l	NULL
BorderVectors18:
	dc.w	0,0
	dc.w	137,0
	dc.w	137,11
	dc.w	0,11
	dc.w	0,0
IText6:
	dc.b	3,0,RP_JAM2,0
	dc.w	4,1
	dc.l	NULL
	dc.l	ITextText6
	dc.l	NULL
ITextText6:
	dc.b	'Locked baud rate',0
	cnop 0,2
Gadget19:
	dc.l	Gadget20
	dc.w	557,108
	dc.w	56,8
	dc.w	GADGDISABLED
	dc.w	RELVERIFY+LONGINT
	dc.w	STRGADGET
	dc.l	Border19
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	Gadget19SInfo
	dc.w	0
	dc.l	NULL
Gadget19SInfo:
	dc.l	Gadget19SIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	7
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
Gadget19SIBuff:
	dc.b	'2400',0
PWstringlen	set	*-Gadget19SIBuff
	dcb.b 7-PWstringlen,0
	cnop 0,2
Border19:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors19
	dc.l	NULL
BorderVectors19:
	dc.w	0,0
	dc.w	57,0
	dc.w	57,9
	dc.w	0,9
	dc.w	0,0
Gadget20:
	dc.l	Gadget21
	dc.w	389,121
	dc.w	70,10
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border20
	dc.l	NULL
	dc.l	IText7
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Border20:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors20
	dc.l	NULL
BorderVectors20:
	dc.w	0,0
	dc.w	71,0
	dc.w	71,11
	dc.w	0,11
	dc.w	0,0
IText7:
	dc.b	3,0,RP_JAM2,0
	dc.w	4,1
	dc.l	NULL
	dc.l	ITextText7
	dc.l	NULL
ITextText7:
	dc.b	'Xon/Xoff',0
	cnop 0,2
Gadget21:
	dc.l	Gadget22
	dc.w	389,135
	dc.w	70,10
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border21
	dc.l	NULL
	dc.l	IText8
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Border21:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors21
	dc.l	NULL
BorderVectors21:
	dc.w	0,0
	dc.w	71,0
	dc.w	71,11
	dc.w	0,11
	dc.w	0,0
IText8:
	dc.b	3,0,RP_JAM2,0
	dc.w	7,1
	dc.l	NULL
	dc.l	ITextText8
	dc.l	NULL
ITextText8:
	dc.b	'CTS/RST',0
	cnop 0,2
Gadget22:
	dc.l	NULL
	dc.w	389,60
	dc.w	88,10
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border22
	dc.l	NULL
	dc.l	IText9
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Border22:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors22
	dc.l	NULL
BorderVectors22:
	dc.w	0,0
	dc.w	89,0
	dc.w	89,11
	dc.w	0,11
	dc.w	0,0
IText9:
	dc.b	3,0,RP_JAM2,0
	dc.w	4,1
	dc.l	NULL
	dc.l	ITextText9
	dc.l	NULL
ITextText9:
	dc.b	'+++ hangup',0
	cnop 0,2
IntuiTextList1:
IText10:
	dc.b	3,0,RP_JAM2,0
	dc.w	100,15
	dc.l	NULL
	dc.l	ITextText10
	dc.l	IText11
ITextText10:
	dc.b	'Serial port unit',0
	cnop 0,2
IText11:
	dc.b	3,0,RP_JAM2,0
	dc.w	40,40
	dc.l	NULL
	dc.l	ITextText11
	dc.l	IText12
ITextText11:
	dc.b	'Modem init string',0
	cnop 0,2
IText12:
	dc.b	3,0,RP_JAM2,0
	dc.w	23,99
	dc.l	NULL
	dc.l	ITextText12
	dc.l	IText13
ITextText12:
	dc.b	'Modem answer string',0
	cnop 0,2
IText13:
	dc.b	3,0,RP_JAM2,0
	dc.w	7,51
	dc.l	NULL
	dc.l	ITextText13
	dc.l	IText14
ITextText13:
	dc.b	'Modem off hook string',0
	cnop 0,2
IText14:
	dc.b	3,0,RP_JAM2,0
	dc.w	15,63
	dc.l	NULL
	dc.l	ITextText14
	dc.l	IText15
ITextText14:
	dc.b	'Modem on hook string',0
	cnop 0,2
IText15:
	dc.b	3,0,RP_JAM2,0
	dc.w	39,75
	dc.l	NULL
	dc.l	ITextText15
	dc.l	IText16
ITextText15:
	dc.b	'Modem call string',0
	cnop 0,2
IText16:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,170
	dc.l	NULL
	dc.l	ITextText16
	dc.l	IText17
ITextText16:
	dc.b	'Config filename',0
	cnop 0,2
IText17:
	dc.b	3,0,RP_JAM2,0
	dc.w	100,25
	dc.l	NULL
	dc.l	ITextText17
	dc.l	IText18
ITextText17:
	dc.b	'Serial device',0
	cnop 0,2
IText18:
	dc.b	3,0,RP_JAM2,0
	dc.w	39,87
	dc.l	NULL
	dc.l	ITextText18
	dc.l	IText19
ITextText18:
	dc.b	'Modem RING string',0
	cnop 0,2
IText19:
	dc.b	3,0,RP_JAM2,0
	dc.w	15,111
	dc.l	NULL
	dc.l	ITextText19
	dc.l	IText20
ITextText19:
	dc.b	'Modem CONNECT string',0
	cnop 0,2
IText20:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,124
	dc.l	NULL
	dc.l	ITextText20
	dc.l	IText21
ITextText20:
	dc.b	'Modem AT string',0
	cnop 0,2
IText21:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,136
	dc.l	NULL
	dc.l	ITextText21
	dc.l	IText22
ITextText21:
	dc.b	'Modem OK string',0
	cnop 0,2
IText22:
	dc.b	3,0,RP_JAM2,0
	dc.w	529,108
	dc.l	NULL
	dc.l	ITextText22
	dc.l	NULL
ITextText22:
	dc.b	'-->',0
	cnop 0,2
