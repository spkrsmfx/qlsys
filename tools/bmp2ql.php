#!/opt/homebrew/bin/php
<?php
	if(isset($argv[2])){
		$twoPlan = false;
	}
	else{
		$twoPlan = true;
	}
	// assumption:
	// 0; black
	// 1; blue
	// 2; red
	// 3; magenta
	// 4; green
	// 5; cyan
	// 6; yellow
	// 7; white

	// open file, and include as image
	$im = imagecreatefrombmp($argv[1]);
	// determine width and height
	$width = imagesx($im);
	$height = imagesy($im);

	echo "; Height: " . $height . "\n";
	echo "; Width: " . $width . "\n";

	// if width is not a factor of 4, then burp
	if($width % 4 != 0){
		echo "; Width is not %4; exiting...\n";
		exit(0);
	}


	$bitList = array(
		0 => array("00","00"),			// black
		1 => array("00","01"),			// blue
		2 => array("00","10"),			// red
		3 => array("00","11"),			// magenta
		4 => array("10","00"),			// green
		5 => array("10","01"),			// cyan
		6 => array("10","10"),			// yellow
		7 => array("10","11")			// white
	);

	// iterate through all pixels, and order in 2 byte segments to output
	$res = array();
	for($y=0;$y<$height;$y++){
		$line = array();
		for($x=0;$x<$width;$x+=4){
			$byte1 = "";
			$byte2 = "";
			$color0 = imagecolorat($im, $x, $y);
			$color1 = imagecolorat($im, $x+1, $y);
			$color2 = imagecolorat($im, $x+2, $y);
			$color3 = imagecolorat($im, $x+3, $y);
			if($color0 > 7){
				$color0 = 0;
			}
			if($color1 > 7){
				$color1 = 0;
			}
			if($color2 > 7){
				$color2 = 0;
			}
			if($color3 > 7){
				$color3 = 0;
			}

			$val0 = $bitList[$color0];
			$val1 = $bitList[$color1];
			$val2 = $bitList[$color2];
			$val3 = $bitList[$color3];

			$byte1 = "%" . $val0[0] . $val1[0] . $val2[0] . $val3[0];
			$byte2 = "%" . $val0[1] . $val1[1] . $val2[1] . $val3[1];
			if($twoPlan){
				$line[] = $byte1;
			}
			$line[] = $byte2;
		}
		$res[] = $line;
	}
	// output data
	foreach($res as $line){
		echo "\tdc.b\t" . implode(',',$line) . "\n";
	}


?>
