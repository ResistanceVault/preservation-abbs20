����                                        ;	push	d4-d5
	movem.l	d4-d5,-(SP)

	move.l	#01,d0
	move.b	d0,D5
	moveq	#78,D4	// Er vi over 78? Da lager vi 2000
	cmp.w	D4,D5	 // er d5 > d4???
	BCC.B	Gammelt // Hopper til 1900
	addi.w	#2000,d5
	bra.b	Videre
Gammelt
	addi.w	#1900,D5
Videre
	moveq	#00,D4
	move.w	D5,D0
	movem.l	(sp)+,d4-d5
;	pop	d4-d5
	rts
