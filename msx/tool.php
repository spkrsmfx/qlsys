<?php
	// take frame based dump
	// and generate it into 14 seperate parts
	// prepend "YM3!"

	$filesize = filesize($argv[1]);
	if($filesize % 14 != 0){
		echo "file not multiple of 14!\n";
		exit();
	}
	$fp = fopen($argv[1], 'rb');
	$binary = fread($fp, $filesize);
	$binary = unpack('C*',$binary);

	fclose($fp);

	// now we make 14 seperate streams
	$length = $filesize/14;
	echo "Length:" . $length . "\n";
	$rl = array();
	for($i=0;$i<14;$i++){
		$rl[$i] = "";
	}

	for($r=0;$r<14;$r++){
		for($i=0;$i<$length;$i++){
			$rl[$r] .= pack('C',$binary[$r+$i*14+1]);
		}
	}	
	$result = "";	// = pack('c*',"YM3!");
	for($i=0;$i<14;$i++){		
		$result .= $rl[$i];
	}

	$result = "YM3!" . $result;

    $fpx = fopen( $argv[2], 'w');
	fwrite($fpx, $result);
    fclose($fpx);

?>
