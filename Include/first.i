	IFND FIRST_I
FIRST_I SET 1

;DEMO = 1

sn		EQU	161
snrcoded	EQU	-349967883
snrrotverdi	EQU	$56ca34bf

date	MACRO
	dc.b	' - 21.03.2011'
	ENDM

VERSION		EQU 1 ; Brukes i Snapshot
REVISION	EQU 1

version	MACRO
	dc.b	'v2.15'
	IFD DEMO
	dc.b	' (demo)'
	ENDC
	ENDM

	ENDC	; FIRST_I
