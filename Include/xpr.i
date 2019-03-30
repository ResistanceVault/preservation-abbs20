	IFND	XPR_I
XPR_I	SET	1

	STRUCTURE XPR_IO,0
	APTR	xpr_filename	; File name(s)
	ULONG	xpr_fopen	; Open file
	ULONG	xpr_fclose	; Close file
	ULONG	xpr_fread	; Get char from file
	ULONG	xpr_fwrite	; Put string to file
	ULONG	xpr_sread	; Get char from serial
	ULONG	xpr_swrite	; Put string to serial
	ULONG	xpr_sflush	; Flush serial input buffer
	ULONG	xpr_update	; Print stuff
	ULONG	xpr_chkabort	; Check for abort
	ULONG	xpr_chkmisc 	; Check misc. stuff
	ULONG	xpr_gets	; Get string interactively
	ULONG	xpr_setserial	; Set and Get serial info
	ULONG	xpr_ffirst	; Find first file name
	ULONG	xpr_fnext	; Find next file name
	ULONG	xpr_finfo	; Return file info
	ULONG	xpr_fseek	; Seek in a file
	ULONG	xpr_extension	; Number of extensions
	ULONG	xpr_data	; Initialized by Setup.
	ULONG	xpr_options	; Prompts user for commands or options.
	ULONG	xpr_unlink	; Deletes files by name.
	ULONG	xpr_squery	; Returns actual size of current serial buffer contents.
	ULONG	xpr_getptr	; Gets various pointers from user.
	LABEL	XPR_IO_SIZEOF

XPR_EXTENSION equ	4

_LVOXProtocolCleanup    EQU     -$1E
_LVOXProtocolSetup      EQU     -$24
_LVOXProtocolSend       EQU     -$2A
_LVOXProtocolReceive    EQU     -$30

	STRUCTURE XPR_UPDATE,0
	ULONG	xpru_updatemask
	APTR	xpru_protocol
	APTR	xpru_filename
	ULONG	xpru_filesize
	APTR	xpru_msg
	APTR	xpru_errormsg
	ULONG	xpru_blocks
	ULONG	xpru_blocksize
	ULONG	xpru_bytes
	ULONG	xpru_errors
	ULONG	xpru_timeouts
	ULONG	xpru_packettype
	ULONG	xpru_packetdelay
	ULONG	xpru_chardelay
	APTR	xpru_blockcheck
	APTR	xpru_expecttime
	APTR	xpru_elapsedtime
	ULONG	xpru_datarate
	ULONG	xpru_reserved1
	ULONG	xpru_reserved2
	ULONG	xpru_reserved3
	ULONG	xpru_reserved4
	ULONG	xpru_reserved5
	LABEL	XPR_UPDATE_SIZEOF

*
*   The possible bit values for the xpru_updatemask are:
*

	BITDEF	XPRU,PROTOCOL,0
	BITDEF	XPRU,FILENAME,1
	BITDEF	XPRU,FILESIZE,2
	BITDEF	XPRU,MSG,3
	BITDEF	XPRU,ERRORMSG,4
	BITDEF	XPRU,BLOCKS,5
	BITDEF	XPRU,BLOCKSIZE,6
	BITDEF	XPRU,BYTES,7
	BITDEF	XPRU,ERRORS,8
	BITDEF	XPRU,TIMEOUTS,9
	BITDEF	XPRU,PACKETTYPE,10
	BITDEF	XPRU,PACKETDELAY,11
	BITDEF	XPRU,CHARDELAY,12
	BITDEF	XPRU,BLOCKCHECK,13
	BITDEF	XPRU,EXPECTTIME,14
	BITDEF	XPRU,ELAPSEDTIME,15
	BITDEF	XPRU,DATARATE,16

*
*   The xpro_option structure
*
	STRUCTURE XPR_OPTION,0
	APTR	xpro_description	; description of the option
	ULONG	xpro_type		; type of option
	APTR	xpro_value		; pointer to a buffer with the current value
	ULONG	xpro_length		; buffer size

*
*   Valid values for xpro_type are:
*

XPRO_BOOLEAN	equ	1	; xpro_value is "yes", "no", "on" or "off"
XPRO_LONG	equ	2	; xpro_value is string representing a number
XPRO_STRING	equ	3	; xpro_value is a string

	ENDC	; XPR_I
