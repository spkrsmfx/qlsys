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


wait_for_vbl	macro
.w\ 
	tst.w	waitvbl
	beq		.w\ 
	move.w	#0,waitvbl
	endm


	ORG	$28100
	opt o-
	jmp	splash_smfx_intro(pc)
	jmp	splash_presents(pc)
	jmp	splash_qlsys(pc)
	opt o+

smfx	incbin	'assets/streets.zx0'

splash_smfx_intro
	lea		smfx,a0
	lea		$20000+56*128,a1
	move.l	unzx0Ptr,a2
	jsr		(a2)
	move.w	#$4e75,splash_smfx_intro
	rts

splash_presents
	wait_for_vbl
	lea		$20000+(134+65)*128,a0
	lea		pp,a1
	lea		.mask,a2
	move.w	.counter,d0		; how much to draw
	; pixel to mask:
	move.w	d0,d1
	and.w	#%11,d1
	add.w	d1,d1
	add.w	d1,a2			; mask
	move.w	(a2),d6
	; pixel to segment
	move.w	d0,d1	
	lsr.w	#2,d1
	add.w	d1,d1			; segment
	add.w	d1,a0
	add.w	d1,a1
	move.w	#6-1,d7
.cp
		move.w	(a1),d0
		and.w	d6,d0
		move.w	d0,(a0)
		add.w	#128,a0
		add.w	#128,a1

	dbra	d7,.cp

	add.w	#1,.counter
	cmp.w	#255,.counter
	bne		.ok
		move.w	#$4e75,splash_presents
.ok	

	rts
.counter	dc.w	50
.mask	
	dc.w	%1100000011000000
	dc.w	%1111000011110000
	dc.w	%1111110011111100
	dc.w	%1111111111111111

pp	include	'assets/pp.s'

splash_qlsys
	lea		qlsys,a0
	move.l	#$20000+190*128,a1
	move.w	#27-1,d7
.cp
		REPT 128/4
			move.l	(a0)+,(a1)+
		ENDR
	dbra	d7,.cp
	move.w	#$4e75,splash_qlsys
	rts

qlsys	include	'assets/qlsys.s'
