 *****************************************************************
 *
 * NAME
 *	Tables.asm
 *
 * DESCRIPTION
 *	Misc tables for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: tables.asm 1.1 1995/06/24 10:32:07 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: tables.asm $
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'
	include	'tables.i'
	include	'exec/types.i'
	include	'intuition/intuition.i'
	include	'asm.i'

	section data,data

	XDEF	NewWindowStructure1
	XDEF	windowtags
	XDEF	firstzoom
	XDEF	warningtimearr
	XDEF	daytext
	XDEF	monthtext
	XDEF	xprbaudates
	XDEF	convertISOtoxxx
	XDEF	convertxxxtoISO
	XDEF	charsettext
	XDEF	transwhat7bitchar
	XDEF	fraISO7tilISO8
	XDEF	fraISO8tilISO7
	XDEF	fraISOtilIBN
	XDEF	fraIBNtilISO
	XDEF	fraISOtilMAC
	XDEF	fraMACtilISO
	XDEF	windowtagssize

minwindowx = 272		; obs! også i node.asm!!
minwindowy = 30			; obs! også i node.asm!!

maxwindowx = -1			; obs! også i node.asm!!
maxwindowy = -1			; obs! også i node.asm!!


warningtimearr	dc.b	0,1,3,5,15,30,45,60

daytext	dc.b	'Monday',0,0,0,0
	dc.b	'Tuesday',0,0,0
	dc.b	'Wednesday',0
	dc.b	'Thursday',0,0
	dc.b	'Friday',0,0,0,0
	dc.b	'Saturday',0,0
	dc.b	'Sunday',0

monthtext
	dc.b	'January',0,0,0
	dc.b	'February',0,0
	dc.b	'March',0,0,0,0,0
	dc.b	'April',0,0,0,0,0
	dc.b	'May',0,0,0,0,0,0,0
	dc.b	'June',0,0,0,0,0,0
	dc.b	'July',0,0,0,0,0,0
	dc.b	'August',0,0,0,0
	dc.b	'September',0
	dc.b	'October',0,0,0
	dc.b	'November',0,0
	dc.b	'December',0

	cnop	0,4

xprbaudates
	dc.l	110
	dc.l	300
	dc.l	1200
	dc.l	2400
	dc.l	4800
	dc.l	9600
	dc.l	19200
	dc.l	31250
	dc.l	38400
	dc.l	57600
	dc.l	76800
	dc.l	115200

convertISOtoxxx
	dc.l	0
	dc.l	fraISOtilIBM
	dc.l	fraISOtilIBN
	dc.l	fraISOtilMAC

convertxxxtoISO
	dc.l	0
	dc.l	fraIBMtilISO
	dc.l	fraIBNtilISO
	dc.l	fraMACtilISO

charsettext
	dc.b	'ISO',0
	dc.b	'IBM',0
	dc.b	'IBN',0
	dc.b	'US7',0
	dc.b	'UK7',0
	dc.b	'GE7',0
	dc.b	'FR7',0
	dc.b	'SF7',0
	dc.b	'NO7',0
	dc.b	'DE7',0
	dc.b	'SP7',0
	dc.b	'IT7',0
	dc.b	'MAC',0,0,0

fraISOtilIBM
fraISOtilIBN
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,173,155,156,0,157,124,0,0,0,166,174,0,0,0,0
	dc.b	248,241,253,0,0,230,0,0,0,0,167,175,172,171,0,168
	dc.b	'A','A','A','A',142,143,146,128,'E',144,'E','E','I','I','I','I'
	dc.b	0,165,'O','O','O','O',148,0,157,'U','U','U',154,'Y',0,225
	dc.b	133,160,131,'a',132,134,145,135,138,130,136,137,'i',161,140,139
	dc.b	0,164,149,162,147,'o',148,0,155,151,163,150,129,'y',0,152

fraIBNtilISO
fraIBMtilISO
	dc.b	$c7,$fc,$e9,$e2,$e4,$e0,$e5,$e7,$ea,$eb,$e8,$ef,$ee,$ec,$c4,$c5
	dc.b	$c9,$e6,$c6,$f4,$f6,$f2,$fb,$f9,0,$d6,$dc,$f8,$a3,$d8,0,0
	dc.b	$e1,$ed,$f3,$fa,$f1,$d1,$aa,$ba,$bf,0,0,$bd,$bc,$a1,$ab,$bb
	dc.b	0,$7f,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,$df,0,0,0,0,$b5,0,0,0,0,0,0,0,0,0
	dc.b	0,$b1,0,0,0,0,0,0,$b0,0,0,0,0,$b2,0,0

fraMACtilISO
	dc.b	196,32,199,201,209,214,220,225,224,226,228,227,229,32,233,232
	dc.b	234,235,237,236,238,239,241,243,242,244,246,245,250,249,251,252
	dc.b	32,32,231,163,167,183,182,223,174,169,32,180,168,32,198,187
	dc.b	32,177,32,32,32,181,240,32,32,32,32,170,186,32,230,248
	dc.b	191,161,172,32,32,32,208,171,32,32,32,192,197,213,32,32
	dc.b	32,32,32,32,32,32,247,32,255,32,32,164,32,32,32,32
	dc.b	32,32,32,32,32,194,202,193,203,200,205,206,207,204,211,212
	dc.b	32,210,32,32,32,185,32,32,175,32,32,176,32,32,32,32

fraISOtilMAC
	dc.b	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	dc.b	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	dc.b	32,193,162,163,219,164,124,164,172,169,187,199,194,158,168,248
	dc.b	251,177,32,32,171,181,166,165,44,245,188,175,32,32,32,192
	dc.b	203,231,229,204,128,204,174,130,233,131,230,232,237,234,235,236
	dc.b	198,132,241,238,239,205,133,32,191,157,156,158,134,32,32,167
	dc.b	136,135,137,139,138,140,190,162,143,142,144,145,147,146,148,149
	dc.b	182,150,152,151,153,155,154,214,191,157,156,158,159,32,32,216

; # 23 - 0,@ 40 - 1 taes manuellt
; [ 5b - 2,\ 5c - 3,] 5d - 4,^ 5e - 5,` 60 - 6,{ 7b - 7,| 7c - 8,} 7d - 9,~ 7e - 10
transwhat7bitchar	; starter på $5b
	dc.b	2,3,4,5,0
	dc.b	6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,7,8,9,10,0

fraISO7tilISO8
fraISO8tilISO7
	dc.b	'#','@','[','\',']','^','`','{','|','}','~'	;us7
	dc.b	$A3,'@','[','\',']','^','`','{','|','}','~'	;uk7
	dc.b	'#',$A7,$C4,$D6,$DC,'^','`',$E4,$F6,$FC,$DF	;ge7
	dc.b	$A3,$E0,$B0,$E7,$A7,'^','`',$E9,$F9,$E8,'~'	;fr7
	dc.b	'#',$C9,$C4,$D6,$C5,$DC,$E9,$E4,$F6,$E5,$FC	;sf7
	dc.b	'#','@',$C6,$D8,$C5,'^','`',$E6,$F8,$E5,'~'	;no7
	dc.b	'#','@',$C6,$D8,$C5,$DC,'`',$E6,$F8,$E5,$FC	;de7
	dc.b	$A3,$A7,$A1,$D1,$BF,'^','`',$B0,$F1,$E7,'~'	;sp7
	dc.b	$A3,$A7,$B0,$E7,$E9,'^',$F9,$E0,$F2,$E8,$EC	;it7

NewWindowStructure1
	dc.w	0,11
	dc.w	640,245
	dc.b	0,1
	dc.l	MENUPICK
	dc.l	SIMPLE_REFRESH+BACKDROP+BORDERLESS+ACTIVATE
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	90,40
	dc.w	-1,-1
	dc.w	CUSTOMSCREEN

	IFND	WFLG_NEWLOOKMENUS
WFLG_NEWLOOKMENUS	EQU $00200000	; window has NewLook menus
	ENDC

windowtags
;windowwidthoff	equ	4
	dc.l	WA_Width,640
;windowheightoff	equ	12
	dc.l	WA_Height,245
;windowtitleoff	equ	20
	dc.l	WA_Title,NULL
;windowtopoff	equ	28
	dc.l	WA_Top,0
;windowleftoff	equ	36
	dc.l	WA_Left,0
;windowflagsoff	equ	44
	dc.l	WA_Flags,WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_SIZEGADGET|WFLG_ACTIVATE|WFLG_NEWLOOKMENUS
;windowpubscreenoff	equ	52
	dc.l	WA_PubScreen,0
	dc.l	WA_MinWidth,minwindowx
	dc.l	WA_MinHeight,minwindowy
	dc.l	WA_MaxWidth,maxwindowx
	dc.l	WA_MaxHeight,maxwindowy
	dc.l	WA_SimpleRefresh,1
	dc.l	WA_PubScreenFallBack,1
	dc.l	WA_DetailPen,1
	dc.l	WA_BlockPen,2
	dc.l	WA_IDCMP,IDCMP_MENUPICK+IDCMP_NEWSIZE
	dc.l	WA_Zoom,firstzoom
	dc.l	TAG_DONE,0

	IFNE	windowtagssize-(*-windowtags)
	FAIL 	"windowtagssize er feil!!!!"
	ENDC

firstzoom	dc.w	0,0,minwindowx,minwindowy

	END
