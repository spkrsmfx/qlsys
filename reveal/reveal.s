; this does a 8x8 block copy from screen 2 to screen 1 with fade
unzx0Ptr		equ $40000-256-4
screenpointer2	equ	$40000-256-12
screenptr2		equ	$40000-256-12
screenpointer1	equ	$40000-256-16
screenptr1		equ	$40000-256-16
swapscreensPtr	equ $40000-256-20
waitvbl			equ $40000-256-24
frame_vbl		equ $40000-256-28
frame_main		equ $40000-256-32
sintable		equ $40000-256-36
polyfillPtr		equ $40000-256-40
wait_for_vbl	macro
.w\@
	tst.w	waitvbl
	beq		.w\@ 
	move.w	#0,waitvbl
	endm
	ORG $30100
	opt o-
	jmp		reveal(pc)
	jmp		reveal_out2(pc)
	opt o+

; blue
; magenta
; yellow
; white 
maskList
;	dc.b	%00000000,%01010101,%00000000,%01010101
;	dc.b	%00000000,%11111111,%00000000,%11111111
;	dc.b	%10101010,%10101010,%10101010,%10101010
	dc.b	%10101010,%11111111,%10101010,%11111111
maskListEnd
maskListOff	dc.w	0



reveal_out2
	wait_for_vbl
	move.w	#0,.again
	move.l	screenpointer2,a0	; source
	move.l	screenpointer1,a1	; dest
	add.w	#128,a0
	add.w	#128,a1
	move.w	horoff3,d0
	add.w	d0,a0
	add.w	d0,a1
	move.w	d0,d7
	asr.w	#2,d7				; this is the loop counter

	cmp.w	#31,d7
	ble		.lll
		move.w	#-1,.again
.lll
	cmp.w	#30,d7
	ble		.ok
		move.w	#30,d7
.ok	
	move.l	#%00000000101010100000000010101010,d0
	move.l	#%00000000010101010000000001010101,d1
;	moveq	#0,d0

.doBlock
	; this needs some checking on bounds
		move.l	a0,d6
		and.w	#255,d6
		cmp.w	#124,d6
		bgt		.next
.x set 0
		REPT 4
			move.l	d0,.x(a1)
			move.l	d0,.x(a0)
.x set .x+128
			move.l	d1,.x(a1)
			move.l	d1,.x(a0)
.x set .x+128
		ENDR
.next
		add.w	#-4+8*128,a0
		add.w	#-4+8*128,a1
	dbra	d7,.doBlock

	tst.w	.again
	beq		.nn
		move.l	a0,d6
		and.w	#255,d6
		cmp.w	#124,d6
		bgt		.nextx
.x set 0
		REPT 3
			move.l	d0,.x(a1)
			move.l	d0,.x(a0)
.x set .x+128
			move.l	d1,.x(a1)
			move.l	d1,.x(a0)
.x set .x+128
		ENDR
.nextx
.nn	
		add.w	#4,horoff3
		subq.w	#1,.times
		bge		.okk
			move.w	#$4e75,reveal_out2
.okk
	rts
.times	dc.w	94
.again	dc.w	0
horoff3	dc.w	0


reveal	
	wait_for_vbl
	move.w	#0,.again
	move.l	#$28000,a0	; source
	move.l	#$20000,a1	; dest
	add.w	#128,a0
	add.w	#128,a1
	move.w	horoff,d0
	add.w	d0,a0
	add.w	d0,a1
	move.w	d0,d7
	asr.w	#2,d7				; this is the loop counter

	cmp.w	#31,d7
	ble		.lll
		move.w	#-1,.again
.lll
	cmp.w	#30,d7
	ble		.ok
		move.w	#30,d7
.ok	

.doBlock
	; this needs some checking on bounds
		move.l	a0,d6
		and.w	#255,d6
		cmp.w	#124,d6
		bgt		.next
.x set 0
		REPT 8
			move.l	.x(a0),.x(a1)
.x set .x+128
		ENDR
.next
		add.w	#-4+8*128,a0
		add.w	#-4+8*128,a1
	dbra	d7,.doBlock

	tst.w	.again
	beq		.nn
		move.l	a0,d6
		and.w	#255,d6
		cmp.w	#124,d6
		bgt		.nextx
.x set 0
		REPT 6
			move.l	.x(a0),.x(a1)
.x set .x+128
		ENDR
.nextx
.nn
	
		add.w	#4,horoff
		move.w	#0,maskListOff
		subq.w	#1,.times
		bge		.okk
			move.w	#$4e75,reveal
.okk
	rts
.times	dc.w	94
.again	dc.w	0
horoff	dc.w	0
horoff2	dc.w	0
