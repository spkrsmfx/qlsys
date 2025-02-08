; QLSys 0.01 by spkr/smfx
; use at own risk
; 0 = true
; 1 = false
;
; 


ORG_LOC			equ $28100				; where the demo is relocated to upon loading
QSoundRegs		equ $40000-256+14		; location where sound driver buffers AY regs 

DO_BREAK		equ 0					; Qemulator breakpoint; enables breaking using $aadf
DETECT_ROM		equ 0					; toggles 
FFWD			equ 1					; fast forward to demopart set by ffwdPoint
RELEASE			equ 1					; excludes some routs like framecounter display
USE_YMP			equ 0					; use YMP (ay/ym packer + player)
; fixed shared memory locations
unzx0Ptr		equ $40000-256-4		; pointer for unzx0 routs
screenpointer2	equ	$40000-256-12		; pointer for screen2
screenptr2		equ	$40000-256-12		; pointer for screen2
screenpointer1	equ	$40000-256-16		; pointer for screen1
screenptr1		equ	$40000-256-16		; pointer for screen1
swapscreensPtr	equ $40000-256-20		; pointer for screenswapping rout
waitvbl			equ $40000-256-24		; shared memory for waiting for vblank to occur
frame_vbl		equ $40000-256-28		; shared counting vbl frames
frame_main		equ $40000-256-32		; shared counting effect frames
sintablePtr		equ $40000-256-36		; pointer for shared sinetable

wait_for_vbl	macro
.w\ 
	tst.w	waitvbl
	beq		.w\ 
	move.w	#0,waitvbl
	endm

dobreak	macro
.\@ 	dc.w	$aadf
	move.w	#$4e71,.\@ 
	endm
	section text

;----------------------------------------------
; BOOTSTRAP RELOCATION CODE - relocate the relocator!
;----------------------------------------------
; demo setup:
; $20000 - $28000 screen1
; $28000 - $28080 - reserved for vblank vector (at $2803c)
; $28100 - safe for running the demo
; $40000-4 - stack, grorws towards $0 ~240 bytes size
; $40000-256 - start of shared variables, growing down

	trap	#0								; get into supervisor mode

	IFEQ	DETECT_ROM						; JS @ $2803c, Minerva @ $3803c
	moveq	#0,d0							; get rom version
	trap	#1								; get rom version trap call
	cmp.w	#$3130,d2						; check for JSROM
	beq		.isjs
.ismin
		move.w	#-1,QSoundRegs				; -1 if minerva
		jmp	.cont
.isjs
		move.w	#0,QSoundRegs				; 0 if jsrom
.cont
	ENDC

	or.w    #$700,sr						; shut down all interrupts
	move.l	#$40000-4,sp					; correct the stack at end of 128k boundary
	lea		reloc_start(pc),a0				; start of reloc code
	lea		$40000-128,a1					; target of reloc code
	move.l	#(reloc_end-reloc_start)/4,d7	; size of relocator code
.c		move.l	(a0)+,(a1)+					; reloc the reloc code!
	dbra	d7,.c
	lea		code_start(pc),a5				; prep values, a5 is start of program to actually relocate
	move.l	#ORG_LOC,a6						; a6 is destination of relocation code
	jmp		$40000-128						; jump to the relocation code, that will relocate the code, and in turn jump to start of relocated code
;----------------------------------------------
; Relocation code
;----------------------------------------------
reloc_start
	move.l	#(code_end-code_s2),d0			; size of demo code
	asr.l	#2,d0							; longword copying
reloc_loop:	
	move.l	(a5)+,(a6)+						; relocate the demo code
	dbra	d0,reloc_loop					; iter
	jmp		ORG_LOC							; run demo
reloc_end

;----------------------------------------------
; START DEMO CODE
;----------------------------------------------
code_start									; label outside ORG for copying
	org ORG_LOC								; ORG for the demo
code_s2
	jmp		demo_entry						; entry point after relocation
;----------------------------------------------
; DEMO PARTS HERE
;----------------------------------------------
	ds.b	5000							; we dont want our effect to overwrite itself just yet :)

splash_code	incbin	'splash/code.zx0'		; demosystem part/payload
	even
splash_org			equ		$28100			; where the payload should be unpacked to
splash_smfx_intro	equ 	splash_org		; routs exposed from part to demosystem 
splash_presents		equ 	splash_org+4	; 
splash_qlsys		equ 	splash_org+8	; 
init_splash	
	lea		splash_code,a0					; load code
	lea		splash_org,a1					; target of unpacked code
	jsr		unzx0							; unpack
	move.w	#$4e75,init_splash				; run only once
	rts


	ds.b	27000							; lets make some space to ensure 2nd screen is free

reveal_code	incbin	'reveal/code.zx0'
	even
reveal_org			equ $30100				; put right after 2nd screen
reveal				equ reveal_org
reveal_out			equ reveal_org+4
init_reveal
	lea		reveal_code,a0					; code
	lea		reveal_org,a1					; target
	jsr		unzx0							; unpack
	move.w	#$4e75,init_reveal				; only once
	rts

	ds.b	20000							; ensure that we actually have space for bobs
bobs_code	incbin	'bobs/code.zx0'
	even
bobs_org			equ $30100
bobs_init			equ bobs_org
bobs_vbl			equ bobs_org+4
bobs_main			equ bobs_org+8
bobs_main_out		equ bobs_org+12
init_bots
	lea		bobs_code,a0					; code
	lea		bobs_org,a1						; target
	jsr		unzx0							; unpack
	jsr		bobs_init						; call init code of unpacked code
	move.w	#$4e75,init_bots
	rts

;----------------------------------------------
; DEMO ENTRY PART
;----------------------------------------------
demo_entry
	move.l	#$40000-4,sp					; correct the stack, for use of double buffer
	IFEQ	DO_BREAK
		MOVEQ    #-26,D0					; 
		MOVEQ    #5,D1						;
		TRAP     #1							; enable breakpoints in qemulator		
;		dc.w	$aadf						; actual trigger debugger in qemulator
	ENDC
;----------------------------------------------
; CLEAR THE SCREEN SPACE
;----------------------------------------------
	move.l	#$20000,a0						; get pointer to screen
	moveq	#0,d0							; mask
	jsr		fillScreen						; fill the screen with mask
;----------------------------------------------
; INITIALIZATION
;----------------------------------------------
	jsr		setDemoSysPtrs					; init the intial shared demosystem pointers
	IFEQ	USE_YMP
		jsr		ymp_init					; init the mimimyzer 
	ENDC


	IFEQ	FFWD
;----------------------------------------------
; FAST FORWARD THROUGH DEMOSCRIPT
;----------------------------------------------
		jsr		ffwdDemoScriptAndYMP
	ENDC

;----------------------------------------------
; FAST FORWARD THROUGH DEMOSCRIPT
;----------------------------------------------
	jsr		initInterrupt					; take control of the vertical blank vector and enable interrupts
	move.b	#%1000,$18063					; set the 256x256 screen mode
;----------------------------------------------------------------
; MAIN DEMO LOOP WRAPPER
;----------------------------------------------------------------
mainLoopWrapper
	lea		demoScript,a0					; list of demo parts
	add.w	demoScriptOff,a0				; offset into the parts
	move.l	8(a0),a0						; get the mainloop address
	jsr		(a0)							; run the mainloop
	jmp		mainLoopWrapper					; loop-di-loop
;----------------------------------------------------------------
; MAIN DEMO SCRIPT
;	1.	part duration in vblanks
;	2.	part vblank address
;	3.	part mainrout address
;----------------------------------------------------------------
demoScript

		dc.l	5,dummy,init_splash
		dc.l	30,dummy,splash_smfx_intro
		dc.l	200,dummy,splash_presents
		dc.l	5,dummy,splash_qlsys
		dc.l	250,dummy,init_reveal
		dc.l	100,dummy,reveal_out
ffwdPoint
		dc.l	25,dummy,init_bots
			IFNE	RELEASE
			dc.l	5,dummy,reset_count
			ENDC
		dc.l	750,bobs_vbl,bobs_main
			IFNE	RELEASE
			dc.l	500,dummy,count_main
			ENDC
		dc.l	-1,dummy,dummy
;----------------------------------------------
; INIT SHARED MEMORY BETWEEN DEMOSYS & PARTS
;----------------------------------------------
setDemoSysPtrs								; this sets shared pointers for unpacked shit
	move.l	#unzx0,unzx0Ptr
	move.l	#$20000,screenpointer1
	move.l	#$28000,screenpointer2
	move.l	#swapscreens,swapscreensPtr
	move.l	#_sintable,sintablePtr
	rts

demoScriptOff	dc.w	0
vblRoutList		dc.l	0
				dc.l	demoScriptHandler

dummy
dummy_vbl
	rts
;----------------------------------------------
; ACTUAL SPECIFIC DEMO SHELL CODE
;----------------------------------------------
initInterrupt
	moveq	#0,d0
	move.l	#$28000,a0
	moveq	#256/4-1,d7
.l
		move.l	d0,(a0)+
	dbra	d7,.l
	move.w	#$4e71,initInterrupt
	move.w	#$2700,sr

	IFNE	DETECT_ROM						; if no rom detection, only JSROM support
		move.l	#vblRoutList,$2803c			; write VBLANK pointer to JSROM location
		move.w	#$2100,sr					; enable interrupts
		rts	
	ELSE
		tst.w	QSoundRegs					; check detected rom version
		bne		.doMin						; -1 = minerva, 0 =jsrom
.doJS
		move.l	#vblRoutList,$2803c			; write vblank address to jsrom vector
		move.w	#$2100,sr
		rts	
.doMin
		move.l	#vblRoutList,$3803c			; write vblank address to minerva vector
		move.w	#$2100,sr
		rts	
	ENDC
;----------------------------------------------
; DEMOSYSTEM VBLANK HANDLER
;----------------------------------------------
demoScriptHandler							; instead of OS use this vblank code
	movem.l	d0-a6,-(sp)						; store the regs

	IFEQ	USE_YMP							; YMP
		lea		player_state,a0				; get current player state
		jsr		ymp_player_update			; update the ay regs
		jsr		psgReplay					; replay the ay regs
	ENDC

	lea		demoScript,a0					; get demosystem script
	add.w	demoScriptOff,a0				; get offset in the current script
	subq.l	#1,(a0)+						; reduce timing frames by one
	beq		.nextScript						; if frames == 0, then we want to move to the next script
.doScript
		move.l	(a0),a0						; get the demosystem vbl rout pointer
		jsr		(a0)						; run the vbl rout pointer	

		lea		$28000+11*4,a0				; get the memory area around the vblank vector list in JSROM
		moveq	#0,d0						;
		REPT 2
			move.l	d0,(a0)+				; clear some shit around it
		ENDR
		movem.l	(sp)+,d0-a6					; restore the registers
		add.w	#1,waitvbl					; mark that vbl has occurred
	rts
.nextScript
	add.w	#12,demoScriptOff				; next script offset is +12
	lea		demoScript,a0					; get the demoscript location
	add.w	demoScriptOff,a0				; next offset
	move.l	4(a0),d0						; then get the vblank vector
	blt		.endScript						; -1 means end of demo, then we end
		move.l	d0,a0						; otherwise, use vector as vlbank vector
		jsr		(a0)						; run vblank
		movem.l	(sp)+,d0-a6					; restore registers
		add.w	#1,waitvbl					; mark that vbl has occurred
		rts
.endScript
	illegal									; this should not occur!


;----------------------------------------------
; FFWD THROUGH DEMOSYSTEM + UPDATE MUSIC
;----------------------------------------------
	IFEQ	FFWD
ffwdDemoScriptAndYMP
		move.l	#(ffwdPoint-demoScript)/12-1,d7
		move.w	#12,d0						; demoscript entry size
		moveq	#0,d6						; counter for total fames to skip
		lea		demoScript,a0				; start of the demoscript
.countDuration
			add.l	(a0),d6					; add part duration to total
			add.w	d0,a0					; advance to next part
		dbra	d7,.countDuration

		add.w	#(ffwdPoint-demoScript),demoScriptOff	;set start pointer of the demoscript

		IFEQ	USE_YMP
			move.w	d6,d7					; number of frames to skip
.skipYMPframe	
				lea		player_state,a0		; load player state
				jsr		ymp_player_update	; render/unpack frame
			dbra	d7,.skipYMPframe
		ENDC
	rts
	ENDC

;----------------------------------------------
; FRAME COUNTER STUFF
;----------------------------------------------
	IFNE	RELEASE
reset_count
	move.w	#0,frame_main
	move.w	#0,frame_vbl
	rts

count_main
	moveq	#0,d0
	move.w	frame_vbl,d0
	move.l	screenpointer1,a0
	add.l	#2*128,a0
	jsr		drawNumbers

	moveq	#0,d0
	move.w	frame_vbl,d0
	move.l	screenpointer2,a0
	add.l	#2*128,a0
	jsr		drawNumbers

	moveq	#0,d0
	move.w	frame_main,d0
	move.l	screenpointer1,a0
	add.w	#20*128,a0
	jsr		drawNumbers

	moveq	#0,d0
	move.w	frame_main,d0
	move.l	screenpointer2,a0
	add.w	#20*128,a0
	jsr		drawNumbers
	rts

count_vbl
	addq.w	#1,frame_vbl
	rts
	ENDC


;----------------------------------------------
; DEMOSYSTEM INCLUDES
;----------------------------------------------

_sintable 
	include	'lib/sintable_amp32768_steps512.s'
	include	'lib/support.s'				; support code
	include	'lib/unzx02.s'				; optimized zx0 unpacker - https://git.platon42.de/chrisly42/unzx0_68000
	include	'lib/ymp3.s'				; ay/ym packing & replay - https://github.com/tattlemuss/minymiser

	IFEQ	USE_YMP
;----------------------------------------------
; YMP definitions
;----------------------------------------------

tune_data_cache		equ 2872				; cache needed for replaying the song
tune_data:			incbin	'msx/nr1.psg.ymp'				; packed ay song using minymiser
					even
tune_data_end:
player_state		ds.b	ymp_size			; 
					even
player_cache		ds.b	tune_data_cache		; or whatever size you need
					even
	ENDC
;----------- END OF DEMO SYSTEM -------
code_end								; mark end code for code relocation

