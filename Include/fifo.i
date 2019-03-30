	IFND	FIFO_I
FIFO_I	SET	1
**
**	FIFO.I
**

FIFOLIBNAME	MACRO
		dc.b	'fifo.library',0
		ENDM

FIFOF_READ EQU $100	  ;  intend to read from fifo	  */
FIFOF_WRITE EQU $200	  ;  intend to write to fifo	  */
FIFOF_RESERVED EQU $FFFF0000	  ;  reserved for internal use   */
FIFOF_NORMAL EQU $400	  ;  request blocking/sig support*/
FIFOF_NBIO EQU $800	  ;  non-blocking IO		  */

FIFOF_KEEPIFD EQU $2000	  ;  keep fifo alive if data pending */
FIFOF_EOF EQU $4000	  ;  EOF on close		      */
FIFOF_RREQUIRED EQU $8000	;  reader required to exist	  */

FREQ_RPEND EQU 1
FREQ_WAVAIL EQU 2
FREQ_ABORT EQU 3

;typedef void *FifoHan;			  ;  returned by OpenFifo()  */

;#ifndef IN_LIBRARY

_LVOOpenFifo	EQU	-30
_LVOCloseFifo	EQU	-36
_LVOReadFifo	EQU	-42
_LVOWriteFifo	EQU	-48
_LVORequestFifo	EQU	-54
_LVOBufSizeFifo	EQU	-60

;#endif


	ENDC	; FIFO_I
