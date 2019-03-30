	XREF	exebase
	XREF	intbase
	XREF	gfxbase
	XREF	gadbase
	XREF	nodelist

_SysBase	equ	exebase
_IntuitionBase	equ	intbase
_GfxBase	equ	gfxbase
_GadToolsBase	equ	gadbase

	XDEF	OpenABBSAppWindowWindow
	XDEF	CloseABBSAppWindowWindow
	XDEF	SetupScreen
	XDEF	CloseDownScreen
	XDEF	ABBSAppWindowRender
	XDEF	ABBSAppWindowWnd
	XDEF	ABBSAppWindowGadgets
	XDEF	ABBSAppWindowMenus
	XDEF	ABBSAppWindowLeft
	XDEF	ABBSAppWindowTop

	IFND GT_Underscore
GT_Underscore	EQU	GT_TagBase+64	; ti_Data points to the symbol
	ENDC
