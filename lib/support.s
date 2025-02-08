;----------------------------------------------
; REMAINING SUPPORT FUNCTIONS
;----------------------------------------------
resetScreens
	move.l	#$20000,screenptr1
	move.l	#$28000,screenptr2
	move.b	#8,scr
	move.b	#0,scr+1
	move.b	#8,$18063
	rts

swapscreens								; always display screenptr1
	lea		screenptr1,a0				; get screen ptr address
	move.l	(a0),d0						; save it
	move.l	4(a0),(a0)+					; rotate screenbuffers
	move.l	d0,(a0)						; write back
	lea		scr,a0						; get flipbit
	move.b	(a0),$18063					; write flipbit
	eor.b	#128,(a0)					; flip the bit
	rts
scr			dc.b	8			;1000
			dc.b	0
;screenpointer1
;screenptr1	dc.l	$20000
;screenpointer2
;screenptr2	dc.l	$28000

fillScreen
	move.w	#32768/4/32-1,d7
.l
	REPT 32
		move.l	d0,(a0)+
	ENDR
	dbra	d7,.l
	rts
	
	IFNE	RELEASE
numbers	incbin	'lib/assets/numbers.bin'	; 140 per

draw
	ext.l	d0
	muls	#14,d0
	tst.w	d0
	bge		.k
		moveq	#0,d0
.k
	cmp.w	#9,d0
	bge		.k2
		moveq	#0,d0
.k2
	lea		numbers,a2
	add.w	d0,a2
.y set 0

	REPT 7
.x set .y
		REPT 2
			move.b	(a2)+,d0
			move.b	d0,.x(a0)
.x set .x+2
		ENDR
.y set .y+128
	ENDR
	rts

drawNumbers
; draw 1000
	move.l	d0,d1						; local copy
	divs	#1000,d0					; divide by 1000, d0= nr of thousands
	move.w	d0,d3						; 
	muls	#1000,d3					
	sub.l	d3,d1						; %1000; remainder
	jsr		draw						; draw number in d0

	add.w	#4,a0						; skip 8 pixels
	add.w	#4,a1						; skip 8 pixels
; draw 100
	move.l	d1,d0						
	divs	#100,d0
	move.w	d0,d3
	muls	#100,d3
	sub.l	d3,d1
	jsr		draw

	add.w	#4,a0
	add.w	#4,a1
; draw 10
	move.l	d1,d0
	divs	#10,d0
	move.w	d0,d3
	muls	#10,d3
	sub.l	d3,d1
	jsr		draw

	add.w	#4,a0
	add.w	#4,a1
; draw 1's
	move.l	d1,d0
	jsr		draw
	rts
	ENDC
