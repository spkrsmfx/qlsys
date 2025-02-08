SCAN_WIDTH	equ 128
NUM_SPRITES equ 8
BOB_WIDTH	equ 28
BOB_HEIGHT	equ 34

	org	 $30100
unzx0Ptr		equ $40000-256-4
screenpointer2	equ	$40000-256-12
screenptr2		equ	$40000-256-12
screenpointer1	equ	$40000-256-16
screenptr1		equ	$40000-256-16
swapscreensPtr	equ $40000-256-20
waitvbl			equ $40000-256-24
frame_vbl		equ $40000-256-28
frame_main		equ $40000-256-32
sintablePtr		equ $40000-256-36
wait_for_vbl	macro
.w\@
	tst.w	waitvbl
	beq		.w\@ 
	move.w	#0,waitvbl
	endm

; here we make 4 routs that do the draw
	opt o-
	jmp		bobs_init(pc)
	jmp		bobs_vbl(pc)
	jmp		bobs_main(pc)
	jmp		bobs_main_out(pc)
	opt o+
bobs_init	

	lea		memSpace,a6

	lea		bob1,a0
	lea		sprite1Tab,a5
	jsr		generateSprites

	lea		bob2,a0
	lea		sprite2Tab,a5
	jsr		generateSprites

	lea		bob2_1,a0
	lea		sprite21Tab,a5
	jsr		generateSprites

	lea		bob2_2,a0
	lea		sprite22Tab,a5
	jsr		generateSprites

	lea		bob2_3,a0
	lea		sprite23Tab,a5
	jsr		generateSprites

	lea		bob2_4,a0
	lea		sprite24Tab,a5
	jsr		generateSprites



	move.w	#$4e75,bobs_init
	rts
;.space	dc.l	0


bobs_vbl
	addq.w	#1,frame_vbl
	rts

bobs_main
;			wait_for_vbl
	jsr		clearSprites
;	jsr		reStoreSprites
	movem.l	object_x,d0-d3
	movem.l	d0-d3,object_x2
	movem.l	object_y,d0-d3
	movem.l	d0-d3,object_y2
	jsr		moveObject

	jsr		drawSprites
	addq.w	#1,frame_main
	move.l	swapscreensPtr,a0
	jsr		(a0)
	rts

bobs_main_out
	jsr		clearSprites
;	jsr		reStoreSprites
	movem.l	object_x,d0-d3
	movem.l	d0-d3,object_x2
	movem.l	object_y,d0-d3
	movem.l	d0-d3,object_y2
	move.l	swapscreensPtr,a0
	jsr		(a0)
	rts

sizeList
	dc.w	0
	dc.w	16
	dc.w	32
	dc.w	48
	dc.w	64
	dc.w	48
	dc.w	32
	dc.w	16
	dc.w	0
sizeListEnd
	dc.w	0
	dc.w	16
	dc.w	32
	dc.w	48
	dc.w	64
	dc.w	48
	dc.w	32
	dc.w	16
	dc.w	0
sizeListOff	dc.w	0

drawSprites
	subq.w	#1,.wtt
	bge		.nn
		move.w	#3,.wtt
		add.w	#2,sizeListOff
		cmp.w	#sizeListEnd-sizeList,sizeListOff
		bne		.nn
			move.w	#0,sizeListOff
.nn
	; so here we make some wave based on

	lea		object_x,a4
	lea		object_y,a5
	move.w	#NUM_SPRITES-1-1,d7
	move.w	#%11,d3
	lea		sprite2Tab,a3
	move.l	screenpointer1,a6
	add.l	#56+110*128,a6
	move.l	a6,usp
	lea		sizeList,a2
	add.w	sizeListOff,a2
.ok
.dosprite
		move.l	usp,a6
		move.w	(a4)+,d0
		move.w	d0,d1
		and.w	d3,d1
		asl.w	#2,d1

		asr.w	#2,d0

		move.w	(a5)+,d2
		asl.w	#6,d2
		add.w	d2,d0
		add.w	d0,d0
		add.w	d0,a6
		add.w	(a2)+,d1
		move.l	(a3,d1.w),a0
		jsr		(a0)
	dbra	d7,.dosprite


		move.l	usp,a6
		move.w	(a4)+,d0
		move.w	d0,d1
		and.w	d3,d1
		asl.w	#2,d1

		asr.w	#2,d0

		move.w	(a5)+,d2
		asl.w	#6,d2
		add.w	d2,d0
		add.w	d0,d0
		add.w	d0,a6

		lea		sprite1Tab,a0
		move.l	(a0,d1.w),a0
		jsr		(a0)
	rts
.wtt	dc.w	0

clearSprites
	lea		object_x2,a4
	lea		object_y2,a5

	move.l	#$00aa00aa,d2	;8		
	move.l	d2,d3			;16
	move.l	d2,d4			;24
	move.l	d2,d5			;32

	move.l	#%00000000010101010000000001010101,d6
;	move.l	#$00aa00aa,d6	;8		
	move.l	d6,a0
	move.l	d6,a1
	move.l	d6,a2

	move.l	screenpointer1,a3
	add.l	#56+110*128,a3

	moveq	#NUM_SPRITES-1-1,d7
.cl
		move.l	a3,a6
		move.w	(a4)+,d0
		asr.w	#2,d0
		move.w	(a5)+,d1
		btst	#0,d1
		beq		.l
			asl.w	#6,d1
			add.w	d1,d0
			add.w	d0,d0
			add.w	d0,a6
.y set 3*128
		REPT 28/2
			movem.l	d2-d5,.y(a6)
.y set .y+128
			movem.l	d6/a0/a1/a2,.y(a6)
.y set .y+128
		ENDR
	dbra	d7,.cl
	jmp		.ccc
.l	
			asl.w	#6,d1
			add.w	d1,d0
			add.w	d0,d0
			add.w	d0,a6
.y set 3*128
		REPT 28/2
			movem.l	d6/a0/a1/a2,.y(a6)
.y set .y+128
			movem.l	d2-d5,.y(a6)
.y set .y+128
		ENDR
	dbra	d7,.cl

.ccc
		move.l	a3,a6
		move.w	(a4)+,d0
		asr.w	#2,d0
		move.w	(a5)+,d1
		btst	#0,d1
		beq		.l2

			asl.w	#6,d1
			add.w	d1,d0
			add.w	d0,d0
			add.w	d0,a6
.y set 0
	REPT BOB_HEIGHT/2
		movem.l	d6/a0/a1/a2,.y(a6)
.y set .y+128
		movem.l	d2-d5,.y(a6)
.y set .y+128
	ENDR
	rts
.l2
			asl.w	#6,d1
			add.w	d1,d0
			add.w	d0,d0
			add.w	d0,a6

.y set 0
	REPT BOB_HEIGHT/2
		movem.l	d2-d5,.y(a6)
.y set .y+128
		movem.l	d6/a0/a1/a2,.y(a6)
.y set .y+128
	ENDR
	rts

; in a0 sprite
; in a5 sprite list
; in a6 memspace
generateSprites
	move.l	a0,a4							; save sprite list
	move.w	#4-1,d4							; number of shifts
.doSprite
		move.l	a6,(a5)+					; pointer to used memspace
		move.l	a4,a0						; restore sprite list pointer to a0
		jsr		parseMask					; parse the mask
		move.l	a4,a0
		jsr		generateFromMask
		; and then we shift
		tst.w	d4
		beq		.no
			move.l	a4,a0
			jsr		shiftRightBobs
.no
	dbra	d4,.doSprite
	rts

sprite1Tab	ds.l	4
sprite2Tab	ds.l	4
sprite21Tab	ds.l	4
sprite22Tab	ds.l	4
sprite23Tab	ds.l	4
sprite24Tab	ds.l	4

shiftRightBobs
	; we need to shift all bytes right twice
	move.l	a0,a2
	move.b	#$80,d1

	move.w	#BOB_HEIGHT-1,d7
.doLine
.x set 0
		move.b	.x(a0),d0
		ror.b	d0				; this bit needs to go into the byte
		roxr.b	d0				; this bit needs to go into the byte
		move.b	d0,.x(a0)
.x set .x+2
	REPT BOB_WIDTH/4-1
		move.b	.x(a0),d0
		ror.b	d0				; this bit needs to go into the byte
		roxr.b	d0				; this bit needs to go into the byte
		move.b	d0,.x(a0)
		; 
.x set .x+2
	ENDR
	add.w	#BOB_WIDTH/2,a0
	dbra	d7,.doLine

	move.w	#BOB_HEIGHT-1,d7
.doLinex
.x set 0
		move.b	.x(a0),d0
		ror.b	d0				; this bit needs to go into the byte
		roxr.b	d0				; this bit needs to go into the byte
		or.b	d1,d0
		move.b	d0,.x(a0)
.x set .x+2
	REPT BOB_WIDTH/4-1
		move.b	.x(a0),d0
		ror.b	d0				; this bit needs to go into the byte
		roxr.b	d0				; this bit needs to go into the byte
		move.b	d0,.x(a0)
		; 
.x set .x+2
	ENDR
	add.w	#BOB_WIDTH/2,a0
	dbra	d7,.doLinex


	move.w	#2-1,d6
.doAgain
	move.l	a2,a0
	move.w	#BOB_HEIGHT-1,d7
.doLine2
.x set 1
	REPT BOB_WIDTH/4
		move.b	.x(a0),d0
		roxr.b	d0				; this bit needs to go into the byte
		move.b	d0,.x(a0)
		; 
.x set .x+2
	ENDR
	add.w	#BOB_WIDTH/2,a0
	dbra	d7,.doLine2

	move.w	#BOB_HEIGHT-1,d7
.doLine2x
.x set 1
		move.b	.x(a0),d0
		roxr.b	d0				; this bit needs to go into the byte
		or.b	d1,d0
		move.b	d0,.x(a0)
		; 
.x set .x+2


	REPT BOB_WIDTH/4-1
		move.b	.x(a0),d0
		roxr.b	d0				; this bit needs to go into the byte
		move.b	d0,.x(a0)
		; 
.x set .x+2
	ENDR
	add.w	#BOB_WIDTH/2,a0
	dbra	d7,.doLine2x

	dbra	d6,.doAgain

	rts

; so we have a mask, we have 9 segments
; we do 2 bytes each, so 9*2 bytes
; move over or
; .l over .w

; we this my analyzing the mask


; first parse mask into 34 rows of 9 bytes
; bytes are marked -1 skip, 0 move, 1 mask
; then each line can be parsed 2nd time, and .w, .l logic can be done

; =1 skip
; 0 move
; 1 mask
 opt o-

 ; this analyses the mask so we can then determine how to do the code generation
parseMask
	lea		BOB_HEIGHT*(BOB_WIDTH/2)(a0),a0				;	34 lines of 40 width skipped, 2nd part is the mask; mask is white
	lea		maskTarget,a1				;	a1 is to store the result in
	move.w	#BOB_HEIGHT-1,d7					;	34 lines
.doLine
		moveq	#BOB_WIDTH/4-1,d6				;	10 blocks of 4 pixels
.doblock
		move.w	(a0)+,d0				;	get 4 pixels
		tst.b	d0						;	check bit value of RB bits
		beq		.moveblock				;	if no pixels set, then no draw
		cmp.b	#-1,d0					;	if all pixels set, then move, mark as -1
		beq		.noblock
.orblock
			move.b	#1,(a1)+			;	when we get here, we have some, but not all pixels set, mark as 1
			jmp		.cont				;	next iteration
.moveblock
			move.b	#0,(a1)+			;	when we get here, we have all pixels set, mark as 0
			jmp		.cont				;	next iteration
.noblock
			move.b	#-1,(a1)+			;	when we get here, we have no pixels set, mark as -1
.cont
		dbra	d6,.doblock				;	next iteration horizontally
	dbra	d7,.doLine					;	next iteration vertically
	rts

generateFromMask
	lea		maskTarget,a2				; 	grab the generated mask data, for definition of operations
	lea		BOB_HEIGHT*(BOB_WIDTH/2)(a0),a1				;	a1 is the mask

	moveq	#0,d3						;	accumulated offset of target bytes to skip in screen space
	move.w	#BOB_HEIGHT-1,d7					;	34 lines in the sprite
.doLine
		moveq	#BOB_WIDTH/4-1,d6				;	10 segments of 4 pixels horizontally
.doBlock
		move.b	(a2)+,d0				;	get the code defintion (-1: none, 0: move, 1: or)
		blt		.skipx					;	if < 0, skip
.notskip
		tst.w	d3						;	check if we have pending bytes to skip
		beq		.noskipwrite			;	if not, dont add skipping bytes in screen space
			move.w	.leal,(a6)+			;	write lea opcode, a6 screen reg
			move.w	d3,(a6)+			;	write number of bytes for lea
			moveq	#0,d3				;	reset d3
.noskipwrite
;-------------- here we move or or
		move.b	(a2),d1					;	get the 2nd opcode
		cmp.b	d0,d1					;	compare current and 2nd opcode
		bne		.do2					;	if they are different, write current segment
.do4
		tst.w	d6						;	check if we are at the end of the scanline to omit last segment + first segment of next line
		beq		.do2					;	if so, do one segment only :)
		subq.w	#1,d6					;	
		addq.w	#1,a2
		tst.b	d0
		beq		.move4
.mask4
		move.l	(a0)+,d5
		beq		.skipor4op
		move.w	.and4op,(a6)+
		move.l	(a1)+,(a6)+
		move.w	.or4op,(a6)+
		move.l	d5,(a6)+
		jmp		.contblock
.move4
		move.w	.move4op,(a6)+
		move.l	(a0)+,(a6)+
		addq.w	#4,a1
		jmp		.contblock
.skipor4op
		move.w	.and4opnoor,(a6)+
		move.l	(a1)+,(a6)+
		jmp		.contblock
.do2
		tst.b	d0
		beq		.move2
.mask2
		move.w	(a0)+,d5
		beq		.skipor2op
		move.w	.and2op,(a6)+
		move.w	(a1)+,(a6)+
			move.w	.or2op,(a6)+
			move.w	d5,(a6)+
			jmp		.contblock
.skipor2op
		move.w	.and2opnoor,(a6)+
		move.w	(a1)+,(a6)+
		jmp		.contblock
.move2
		move.w	.move2op,(a6)+
		move.w	(a0)+,(a6)+
		addq.w	#2,a1
		jmp		.contblock
.skipx
		addq.w	#2,d3
		addq.w	#2,a0
		addq.w	#2,a1
.contblock
		dbra	d6,.doBlock
		add.w	#SCAN_WIDTH-(BOB_WIDTH/2),d3
	dbra	d7,.doLine
	move.w	#$4e75,(a6)+
	rts
	opt o+
.leal			lea		1234(a6),a6
.move2op		move.w	#1234,(a6)+
.move4op		move.l	#$1234,(a6)+
.and2op			and.w	#1234,(a6)
.and2opnoor		and.w	#$1234,(a6)+
.or2op			or.w	#1234,(a6)+
.and4op			and.l	#$1234,(a6)
.and4opnoor		and.l	#$1234,(a6)+
.or4op			or.l	#$1234,(a6)+


maskTarget	ds.b	BOB_HEIGHT*(BOB_WIDTH/4)



moveObject
	move.w	move_x,d5
	move.w	move_y,d6
	lea		object_x,a1
	lea		object_y,a2

	move.l	sintablePtr,a6
	move.w	#1024-2,d4
	move.w	#25,d3
	move.w	#29,d2

	moveq	#NUM_SPRITES-1,d7
.dox
	move.l	a6,a0
	move.w	d5,d0
	and.w	d4,d0
	add.w	d0,a0
	move.w	#180,d0			; amp	80
	muls	(a0),d0
	swap	d0
	move.w	d0,(a1)+
	add.w	d3,d5
	dbra	d7,.dox


	moveq	#NUM_SPRITES-1,d7
.doy
	move.l	a6,a0
	move.w	d6,d0
	and.w	d4,d0
	add.w	d0,a0
	move.w	#170,d0
	muls	(a0),d0
	swap	d0
	move.w	d0,(a2)+
	add.w	d2,d6

	dbra	d7,.doy


	addq.w	#7,move_x
	addq.w	#6,move_y
	rts


	
move_x		dc.w	0
move_y		dc.w	100

object_x	ds.w	NUM_SPRITES+2
object_y	ds.w	NUM_SPRITES+2

object_x2	ds.w	NUM_SPRITES+2
object_y2	ds.w	NUM_SPRITES+2

memSpace
	ds.b	8572-1260+4988		; 8572 / 13560needed

bob1	include	'sprites/sprite1c.s'				;630
bob2	include	'sprites/sprite2c.s'
bob2_1	include	'sprites/sprite2_1.s'
bob2_2	include	'sprites/sprite2_2.s'
bob2_3	include	'sprites/sprite2_3.s'
bob2_4	include	'sprites/sprite2_4.s'

