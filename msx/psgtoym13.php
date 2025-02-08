<?php

//zxPSGRout
//	move.l	tunePtr,a0
//	lea		QSoundRegs,a1
//	moveq	#0,d0
//	moveq	#-1,d1	
//	moveq	#13,d2
//	moveq	#0,d3				; this is for psg 14
//
//doreg macro
//		move.b	(a0)+,d0
//		blt		.end
//			cmp.w	d0,d2
//			blt		.error
//			move.b	(a0)+,(a1,d0.w)
//	endm
//	REPT 16
//		doreg
//	ENDR
//;.again
//;	move.b	(a0)+,d0				;
//;	blt		.end
//;		; then d0 is reg value
//;		move.b	(a0)+,(a1,d0.w)			; write value
//;		jmp		.again
//.end
//	move.l	a0,tunePtr
//	cmp.b	#$fe,d0
//	bne		.ok
//		dc.w	$aadf			; actual break
//.ok
//	rts	
//.error
//	dc.w	$aadf
//	nop
//	rts

	if(!isset($argv[1])){
		echo "supply psg file as first argument\n";
		exit();
	}


	$fsize = filesize($argv[1]); 


	$regs = array(0,0,0,0,0,0,0,0,0,0,0,0,0,0);

	// open file
	$handle = fopen($argv[1], "r") or die("Unable to open file!");	
	$contents = fread($handle, $fsize); 
	$byteArray = unpack("c*",$contents); 


	$i=1+17;
	do{
		// start frame
		$regs[13] = -1;
		for($j=0; $j<14; $j++){
			if($byteArray[$i++] >= 0){
				// we have a frame
				$regIndex = $byteArray[$i-1];
				$regs[$regIndex] = $byteArray[$i++];
			}
			else{
				goto end;
			}
		}	
end:
	echo "\tdc.b\t" . implode(",", $regs) . "\n";
	}
	while($i<$fsize-18);

//	print_r($byteArray);
//	echo $fsize . "\n";
	// read file byte by byte
	// for each set of regs, write dc.b
	


?>