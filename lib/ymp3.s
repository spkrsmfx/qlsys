PSGMOD	equ 0				; adapt the ym reg dump to compensate for different soundchp
PSGMOD_FACTOR	equ 7		; 7 = zx spectrum 8 = atari
; -----------------------------------------------------------------------
;	YNP PLAYER CODE
; -----------------------------------------------------------------------
; The number of packed data streams in the file.
; This is one less than the number of YM registers, since
; the Mixer register is encoded into the "volume" register
; streams.
; Bit 7 of the volume stream value is the noise channel enable/disable.
; Bit 6 of the volume stream value is the square channel enable/disable.
; Bits 4-0 of the volume stream value are the natural "volume/envelope" bits.
NUM_STREAMS		equ	13
							; KEEP THESE 3 IN ORDER
ymunp_match_read_ptr	equ	0			; X when copying, the src pointer (either in cache or in original stream)
ymunp_copy_count_w	equ	4			; number of bytes remaining to copy. Decremented at start of update.
ymunp_size		equ	6			; structure size

ymset_cache_base_ptr:	equ	0			; bottom location of where to write the data
ymset_cache_offset:	equ	4			; added to base_ptr for first write ptr
ymset_size:		equ	6
;
			rsreset
ymp_sets_ptr:		rs.l	1
ymp_register_list_ptr:	rs.l	1
ymp_streams_state:	rs.b	ymunp_size*NUM_STREAMS
ymp_sets_state:		rs.b	ymset_size*NUM_STREAMS	; max possible number of sets
ymp_vbl_countdown:	rs.w	1			; number of VBLs left to restart
ymp_stream_read_ptr	rs.l	1			; position in packed data we are reading from
ymp_tune_ptr:		rs.l	1
ymp_cache_ptr:		rs.l	1
ymp_output_buffer:	rs.b	NUM_STREAMS
			even
ymp_size:		rs.b	1

read_extended_number macro
	tst.b	d0
	bne.s	.valid_count\@
	move.b	(a1)+,d0
	lsl.w	#8,d0
	move.b	(a1)+,d0
.valid_count\@
	endm

; -----------------------------------------------------------------------
; a0 = player state (ds.b ymp_size)
; a1 = start of packed ym data
; a2 = start of player cache (ds.b memory)
ymp_player_init:
	; Save addresses of buffers
	move.l	a1,ymp_tune_ptr(a0)
	move.l	a2,ymp_cache_ptr(a0)
ymp_player_restart:
	lea	ymp_streams_state(a0),a3
	; a3 = state data
	addq.l	#4,a1					; skip header (2 bytes ID + 2 bytes cache size)
	move.w	(a1)+,ymp_vbl_countdown(a0)

	move.l	a1,ymp_register_list_ptr(a0)
	; skip the register list and padding
	lea	NUM_STREAMS+1(a1),a1

	; Prime the read addresses for each reg
	moveq.l	#NUM_STREAMS-1,d0
.fill:
	; a1 = input data (this moves for each channel)
	clr.l	ymunp_match_read_ptr(a3)		; setup ymunp_match_read_ptr
	move.w	#1,ymunp_copy_count_w(a3)		; setup ymunp_copy_count_w
	lea	ymunp_size(a3),a3			; next stream state
	dbf	d0,.fill

	; Calculate the set data
	move.l	a1,ymp_sets_ptr(a0)
	lea	ymp_sets_state(a0),a3			; a3 = set information
	move.l	ymp_cache_ptr(a0),a2			; a2 = curr cache write point
.read_set:
	move.w	(a1)+,d1				; d1 = size of set - 1
	bpl.s	.sets_done
	move.l	a1,ymp_stream_read_ptr(a0)		; setup packed data ptr
	rts
.sets_done:
	move.l	a2,ymset_cache_base_ptr(a3)
	clr.w	ymset_cache_offset(a3)
	move.w	(a1)+,d2				; d2 = cache size per reg
	; Move the cache pointer onwards
.inc_cache_ptr:
	add.w	d2,a2
	dbf	d1,.inc_cache_ptr
	addq.l	#ymset_size,a3				; on to next
	bra.s	.read_set

; -----------------------------------------------------------------------
; a0 = input structure
ymp_player_update:
	lea	ymp_streams_state(a0),a3		; a3 = streams state
	lea	ymp_output_buffer(a0),a6		; a6 = YM buffer
	move.w	#ymunp_size,d2				; d2 = stream structure size (constant)

	; Update single stream here
	lea	ymp_sets_state(a0),a5			; a5 = set current data
	move.l	ymp_sets_ptr(a0),a4			; a4 = static set info
	move.l	ymp_stream_read_ptr(a0),d6		; d6 = packed data stream
	moveq	#0,d3					; d3 = clear to ensure add.l later works
ymp_set_loop:
	move.w	(a4)+,d1				; d1 = registers/loop (dbf size)
	bmi	ymp_sets_done				; check end
ymp_set_loopi:
	move.w	(a4)+,d3				; d3 = cache size for set

	; TODO can use (a5)+ here in future?
	move.l	ymset_cache_base_ptr(a5),a2
	move.l	a2,d5

	add.w	ymset_cache_offset(a5),a2		; a2 = register's current cache write ptr
	add.l	d3,d5					; d5 = register's cache end ptr
ymp_register_loop:
	moveq	#0,d4					; d4 = temp used for decoding

	; a3	= ymunp struct
	subq.w	#1,ymunp_copy_count_w(a3)
	bne.s	.stream_copy_one			; still in copying state

	; Set up next ymunp_match_read_ptr and ymunp_copy_count_w here
	move.l	d6,a1					; a1 = packed data stream
	moveq	#0,d0
	move.b	(a1)+,d0
	; Match or reference?
	bclr	#7,d0
	bne.s	.literals

	; Match code
	; a1 is the stream read ptr
	; d0 is the pre-read count value
			read_extended_number
	move.w	d0,ymunp_copy_count_w(a3)

	; Now read offset
	moveq	#0,d0
.read_offset_b:
	move.b	(a1)+,d4
	bne.s	.read_offset_done
.loop
	add.w	#255,d0
	move.b	(a1)+,d4
	beq		.loop
.read_offset_done:
	add.w	d4,d0					; add final non-zero index

	move.l	a1,d6					; remember stream ptr now, before trashing a1

	; Apply offset backwards from where we are writing
	move.l	a2,a1					; current cache write ptr
	add.w	d3,a1					; add cache size
							; this value is still modulo "cache offset"
	sub.l	d0,a1					; apply reverse offset
	cmp.l	d5,a1					; past cache end?
	blt.s	.ptr_ok
	sub.w	d3,a1					; subtract cache size again
.ptr_ok:
	move.l	a1,ymunp_match_read_ptr(a3)
	bra.s	.stream_copy_one
.literals:
	; Literals code -- just a count
	; a1 is the stream read ptr
	; d0 is the pre-read count value
			read_extended_number
	move.w	d0,ymunp_copy_count_w(a3)
	move.l	a1,ymunp_match_read_ptr(a3)		; use the current packed stream address
	add.l	d0,a1					; skip bytes in input stream
	move.l	a1,d6
	; Falls through to do the copy

.stream_copy_one:
	; Copy byte from either the cache or the literals in the stream
	move.l	ymunp_match_read_ptr(a3),a1		; a1 = match read
	; a2 = cache write, d5 = loop addr
	move.b	(a1)+,d0				; d0 = output result
	move.b	d0,(a2)					; add to cache. Don't need to increment

	; Handle the *read* pointer hitting the end of the cache
	; The write pointer check is done in one single go since all sizes are the same
	; This check is done even if literals are copied, it just won't ever pass the check
	cmp.l	d5,a1					; has match read ptr hit end of cache?
	bne.s	.noloop_cache_read
		sub.w	d3,a1					; move back in cache
.noloop_cache_read:
	move.l	a1,ymunp_match_read_ptr(a3)

	; d0 is "output" here
	move.b	d0,(a6)+				; write to output buffer

	; Move on to the next register
	add.w	d3,a2					; next ymp_cache_write_ptr
	add.w	d3,d5					; next cache_end ptr
	add.w	d2,a3					; next stream structure
	dbf	d1,ymp_register_loop
	;---------------------------------------------

	; Update and wrap the set offset
	move.w	ymset_cache_offset(a5),d4
	addq.w	#1,d4
	cmp.w	d3,d4					; hit the cache size?
	bne.s	.no_cache_loop
	moveq	#0,d4
.no_cache_loop:
	move.w	d4,ymset_cache_offset(a5)
	addq.l	#ymset_size,a5

	move.w	(a4)+,d1					; d1 = registers/loop (dbf size)
	bge		ymp_set_loopi				; check end

ymp_sets_done:
	move.l	d6,ymp_stream_read_ptr(a0)		; recrod stream ptr for next time

ym_write:
	; We could write these in reverse order and reuse a6?
	lea	ymp_output_buffer(a0),a6
	move.l	ymp_register_list_ptr(a0),a5
	moveq	#0,d0

	; Generate the mixer register
	; We need channels 8, 9, 10
	; These are 7,8,9 in the packed stream.
	move.b	7(a5),d0
	move.b	(a6,d0.w),d1				; d1 = mixer A
	move.b	8(a5),d0
	move.b	(a6,d0.w),d2				; d2 = mixer B
	move.b	9(a5),d0
	move.b	(a6,d0.w),d3				; d3 = mixer C

	; Accumulate mixer by muxing each channel volume top bits
	; Repeat twice, the first time for noise enable bits,
	; the second time for square
	moveq	#0,d4
	rept	2
	add.b	d3,d3
	addx.w	d4,d4					; shift in top bit channel C
	add.b	d2,d2
	addx.w	d4,d4					; shift in top bit channel B
	add.b	d1,d1
	addx.w	d4,d4					; shift in top bit channel A
	endr

;	lea	$ffff8800.w,a3
;	lea	$ffff8802.w,a1
	lea	QSoundRegs,a1
	; Write registers 0-6 inclusive
r	set	0
	rept	7
	move.b	(a5)+,d0				; fetch depack stream index for this reg
;	move.b	#r,(a3)
	move.b	(a6,d0.w),(a1)+
r	set	r+1
	endr

	; Now mixer
;	move.b	#7,(a3)
;	move.b	(a3),d1
	move.b	(a1),d1
	and.b	#$c0,d1					; preserve top 2 bits (port A/B direction)
	or.b	d1,d4
	move.b	d4,(a1)+

	; Now 8,9,10,11,12
	rept	5
	move.b	(a5)+,d0				; fetch depack stream index for this reg
;	move.b	#r+1,(a3)
	move.b	(a6,d0.w),(a1)+
r	set	r+1
	endr

	; Reg 13 - buzzer envelope
	move.b	(a5)+,d0				; fetch depack stream index for this reg
	move.b	(a6,d0.w),(a1)				; Buzzer envelope register is special case,
;	bmi.s	.skip_write
;	move.b	#13,(a3)				; only write if value is not -1
;	move.b	d0,(a1)					; since writing re-starts the envelope
.skip_write:

	; Check for tune restart
	subq.w	#1,ymp_vbl_countdown(a0)
	bne.s	.no_tune_restart
;		lea		tune_data_endpart,a1
;		move.l	a1,ymp_tune_ptr(a0)
		move.l	ymp_tune_ptr(a0),a1
		bsr	ymp_player_restart
.no_tune_restart:
	rts


ymp_init
;	move.l	#ymp_player_update,playerRoutPtr
; a0 = player state (ds.b ymp_size)
; a1 = start of packed ym data
; a2 = start of player cache (ds.b memory)	lea		tune,a0
	lea		player_state,a0
	lea		tune_data,a1
	lea		player_cache,a2
	jsr		ymp_player_init
	rts



;playerRoutPtr	dc.l	ymp_player_update	
	IFEQ	PSGMOD
psgSetting		dc.l	3*65536/PSGMOD_FACTOR				;8 is atari, 7 is zx
	ENDC

psgReplay
	lea		QSoundRegs,a0
	moveq	#0,d4
	lea		$c2000,a5
	lea		$c2002,a6
	moveq	#10,d0
	moveq	#15,d1
	moveq	#14,d3
	moveq	#0,d2		; reg
	
	IFEQ	PSGMOD	
	move.l	psgSetting,d6
	move.l	#$8000,d7
	ENDC
;reg 0-1 2-3 4-5 + 11-12
	;0,1,2,3,4,5

	; form is abcd, wher a = c2000, b
	;		  

	REPT 3
		moveq	#0,d4			;clear
		move.b	1(a0),d4		;upper byte
		lsl.w	#8,d4			;<<256
		move.b	(a0),d4			;lower byte
		add.w	#2,a0			;.

	IFEQ	PSGMOD
		muls	d6,d4
		add.l	d7,d4
		swap	d4
	ENDC

		move.b		d2,(a5)
		move.b		d1,(a6)
		move.b		d0,(a6)
		move.b		d4,(a5)
		move.b		d3,(a6)
		move.b		d0,(a6)
		addq.w		#1,d2

		lsr.w		#8,d4
		move.b		d2,(a5)
		move.b		d1,(a6)
		move.b		d0,(a6)
		move.b		d4,(a5)
		move.b		d3,(a6)
		move.b		d0,(a6)
		addq.w		#1,d2
	ENDR

	;6	
;		lea			.tab,a1
;		moveq		#0,d4

		move.b		d2,(a5)
		move.b		d1,(a6)
		move.b		d0,(a6)
;		move.b		(a0)+,d4
;		move.b		(a1,d4.w),(a5)
		move.b		(a0)+,(a5)
		move.b		d3,(a6)
		move.b		d0,(a6)
		addq.w		#1,d2

	;7,8,9,10
	REPT 4
		move.b		d2,(a5)			; reg select
		move.b		d1,(a6)			; op
		move.b		d0,(a6)			; op
		move.b		(a0)+,(a5)		; reg value
		move.b		d3,(a6)			; op
		move.b		d0,(a6)			; op
		addq.w		#1,d2
	ENDR
	;11-12
	REPT 1
		moveq	#0,d4			;clear
		move.b	1(a0),d4		;upper byte
		lsl.w	#8,d4			;<<256
		move.b	(a0),d4			;lower byte
		add.w	#2,a0			;.

	IFEQ	PSGMOD
		mulu	d6,d4
		add.l	d7,d4
		swap	d4
	ENDC
		move.b		d2,(a5)
		move.b		d1,(a6)
		move.b		d0,(a6)
		move.b		d4,(a5)
		move.b		d3,(a6)
		move.b		d0,(a6)
		addq.w		#1,d2

		lsr.w		#8,d4
		move.b		d2,(a5)
		move.b		d1,(a6)
		move.b		d0,(a6)
		move.b		d4,(a5)
		move.b		d3,(a6)
		move.b		d0,(a6)
		addq.w		#1,d2
	ENDR

        tst.b	(a0)
        blt     .end
		move.b		d2,(a5)
		move.b		d1,(a6)
		move.b		d0,(a6)
		move.b		(a0),(a5)
		move.b		d3,(a6)
		move.b		d0,(a6)
;		addq.w		#1,d2
		move.b		#-1,(a0)
.end
	rts
.tab
	dc.b	0	; 0
	dc.b	1	; 1
	dc.b	1	; 2
	dc.b	2	; 3
	dc.b	2	; 4
	dc.b	2	; 5
	dc.b	3	; 6
	dc.b	3	; 7
	dc.b	3	; 8
	dc.b	4	; 9
	dc.b	4	; 10
	dc.b	5	; 11
	dc.b	5	; 12
	dc.b	5	; 13
	dc.b	6	; 14
	dc.b	6	; 15
	dc.b	6	; 16
	dc.b	7	; 17
	dc.b	7	; 18
	dc.b	8	; 19
	dc.b	8	; 20
	dc.b	8	; 21
	dc.b	9	; 22
	dc.b	9	; 23
	dc.b	9	; 24
	dc.b	10	; 25
	dc.b	10	; 26
	dc.b	11	; 27
	dc.b	11	; 28
	dc.b	11	; 29
	dc.b	12	; 30
	dc.b	12	; 31


;resetSound
;	lea		$c2000,a5
;	lea		$c2002,a6
;	moveq	#10,d0
;	moveq	#15,d1
;	moveq	#14,d3
;	moveq	#0,d2		; reg
;	moveq	#0,d4
;	lea		QSoundRegs,a3
;	moveq	#14-1,d7
;.l
;		move.b		d2,(a5)
;		move.b		d1,(a6)
;		move.b		d0,(a6)
;		move.b		d4,(a5)
;		move.b		d4,(a3)+
;		move.b		d3,(a6)
;		move.b		d0,(a6)
;		addq.w		#1,d2
;	dbra	d7,.l
;	rts

