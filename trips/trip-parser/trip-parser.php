<?php
	$status_filepath = "cache/status.".time().".txt";
	print $status_filepath."\n";
	$file = fopen($status_filepath, "w");
	if(!isset($_REQUEST['email'])){
		fprintf($file, "**START\nERROR: no email specified\nEND**");
	}
	else if(!isset($_REQUEST['pass'])){
		fprintf($file, "**START\nERROR: no password specified\nEND**");
	}
	else if($_REQUEST['email'] == ''){
		fprintf($file, "**START\nERROR: no email specified\nEND**");
	}
	else if($_REQUEST['pass'] == ''){
		fprintf($file, "**START\nERROR: no password specified\nEND**");
	}
	else{
		fclose($file);
		$cmd = "ruby trip-parser.rb \"".$_REQUEST['email']."\" \"".$_REQUEST['pass']."\" -no_stdout:".$status_filepath." -salt > /dev/null &";
		//print $cmd."\n";
		exec($cmd);
		exit(0);
	}
	fclose($file);
?>