	IFND	EXEC_TYPES_I
	include 'exec/types.i'
	ENDC

WindowTop	equ	6
MaxScreen	equ	100
NrSavedLines	equ	10
FSETabSize	equ	8

	STRUCTURE	fseblock,0
	UWORD		FizzX
	UWORD		FizzY
	UWORD		WindowEnd
	UWORD		WindowSiz
	UWORD		WindowWith
	UBYTE		ZapEcho
	UBYTE		ShiftStatus
	UBYTE		HaveCR
	UBYTE		CharIn
	UBYTE		CSInum
	UBYTE		fsepad
	UWORD		X		; current column in message
	UWORD		Y		; current line in message
	UWORD		P		; line number of first line on screen
	UWORD		LastSave
	UWORD		LastN
	UWORD		LastY
	UWORD		LastX
	UWORD		CurColor
	UWORD		MaxFSEbufferlines
	APTR		FSEbuffer
	STRUCT		LongLine,256
	STRUCT		SavedLines,NrSavedLines*LinesSize
	STRUCT		ScreenUpd,MaxScreen-WindowTop+1
					; first updated position in line
	STRUCT		ScreenClr,MaxScreen-WindowTop+1
					; first cleared position in line
	LABEL		fseblock_SIZE

;ShiftStatus'er
NoShift equ 0
ESCshift equ 1
CSIshift equ 2
CtrlKshift equ 3
VT100shift equ 4
CSIspaceshift equ 5
