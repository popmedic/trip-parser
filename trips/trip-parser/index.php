<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=480" />
<title>TripParser</title>
<script src="http://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
<style>
body{
	background-color:#000;
	color:#FFF;
}
a{
	color:#FF6;
}
a:hover{
	color:#FF0;
}
#canvas{
	display:block;
	position:absolute;
	width:400px;
	/*height:600px;*/
	top:10px;
	left:10px;
	background-color:#FFF;
	color:#000;
	font-family:Arial, Helvetica, sans-serif;
	font-size:16px;
	border-radius:12px;
	padding: 8px;
	padding-top:16px;
	padding-bottom:16px;
	text-align:center;
}
#trip-parse-box {
	background-color:#FFF;
	border:#666 1px solid;
	border-radius:8px;
	margin-top:4px;
	margin-bottom:4px;
	padding-top:4px;
	padding-bottom:4px;
	padding-left:12px;
	padding-right:12px;
	display:inline-block;
	width:200px;
}
#status-box {
	background-color:#FFF;
	color:#000;
	height:86px;
	overflow:auto;
	border:#666 1px solid;
	border-radius:8px;
	margin-top:4px;
	margin-bottom:4px;
	padding-top:8px;
	/*padding-bottom:8px;*/
	padding-left:12px;
	padding-right:12px;
	text-align:left;
	display:none;
}
#status-box pre{
	font-size:12px;
}
/*#trip-parse-box #parse_btn {*/
button{
	width:78px;
	height:42px;
	border:#666 1px solid;
	border-radius:12px;
	background-color:#CCC;
	color:#000;
	cursor:pointer;
	opacity:0.9;
}
button:hover{
	opacity:1.0;	
}
button:disabled{
	opacity:0.75;
	cursor:default;	
}
#trip-parse-box input[type=text],
#trip-parse-box input[type=password] {
	border-radius:4px;
	padding-top:4px;
	padding-bottom:4px;
	padding-right:6px;
	padding-left:6px;
	border:#666 1px solid;	
	width:160px;
}
#progress-bar{
	border:#666 1px solid;
	border-radius:6px;
	margin-top:8px;
	margin-bottom:8px;
	width:360px;
	padding:0px;
	display:block;
	font-size:12px;
	text-align:center;
}
#progress-bar td,
#progress-bar table{
	border-radius:6px;
	margin:0px;	
	padding:0px;
	height:16px;
}
#reports-box{
	vertical-align:bottom;
	text-align:center;
	margin-top:16px;
}
#details-btn{
	cursor:pointer;
	text-align:left;
	margin-left:12px;
}
</style>
</head>

<body>
	<div id="canvas">
	<div id="trip-parse-box">
    	<p>
		<input type="text" id="email" placeholder="Email Address (gmail only)" />
        </p>
        <p>
        <input type="password" id="pass" placeholder="Password" />
        </p>
        <p>
        <button id="parse_btn">Create<br />Reports</button>
		</p>
    </div>
    <center>
    <div id="progress-bar"><table width="100%"><tr><td width="0%" bgcolor="#FFFF00"></td><td>&nbsp;</td></tr></table></div>
    </center>
    <div id="details-btn">Details</div>
    <div id="status-box"><pre>
    	
    </pre></div>
    <div id="reports-box">
    	<button id="html-report-btn" disabled="disabled">HTML</button>
    	<button id="xml-report-btn" disabled="disabled">XML</button>
    	<button id="txt-report-btn" disabled="disabled">Text</button>
    	<button id="csp-report-btn" disabled="disabled">Comma</button>
    </div>
    </div>
</body>
<script language="javascript">
var status_timer = 0;
function resizeCanvas(){
	cw = $('#canvas').width()+16;
	ch = $('#canvas').height()+16;
	ww = $(window).width();
	wh = $(window).height();
	nl = ww/2 - cw/2;
	nt = wh/2 - ch/2;
	$('#canvas').css('left', String(nl)+'px');
	$('#canvas').css('top',  String(nt)+'px');	
}
$(document).ready(function(e) {
    resizeCanvas();
	$(window).resize(function(e) {
        resizeCanvas();
    });
	$("#trip-parse-box input:first").focus();
	$("#details-btn").click(function(){
		if($("#status-box").css('display') == 'none'){
			$("#status-box").show(400, function(){
				resizeCanvas();
			});
		}
		else{
			$("#status-box").hide(400, function(){
				resizeCanvas();
			});
		}
	});
	$("#email").keydown(function(e) {
        if(e.which == 13){
			$("#pass").focus();
		}
    });
	$("#pass").keydown(function(e) {
        if(e.which == 13){
			$("#parse_btn").click();
		}
    });
	$('#trip-parse-box #parse_btn').click(function(e) {
		$('#trip-parse-box #parse_btn').attr('disabled', 'true');
        $('#trip-parse-box #parse_btn').text('|');
		$.post('trip-parser.php', { email:$('#trip-parse-box #email').val(), pass:salting($('#trip-parse-box #pass').val(), $('#trip-parse-box #email').val()) }, function(data){
			status_timer = setInterval(function(){
				ct = $('#trip-parse-box #parse_btn').text();
				if(ct == '|') $('#trip-parse-box #parse_btn').text('/');
				else if(ct == '/') $('#trip-parse-box #parse_btn').text('-');
				else if(ct == '-') $('#trip-parse-box #parse_btn').text('\\');
				else if(ct == '\\') $('#trip-parse-box #parse_btn').text('|');
				//url = data.split('\n')[0];
				url = data.trim();
				$("#status-box pre").load(url, function(data2, sts){
					if (sts == "error"){
						alert("Done Due to ERROR!");
						clearInterval(status_timer);
						$('#trip-parse-box #parse_btn').html("Create<br />Reports");
						$('#trip-parse-box #parse_btn').removeAttr('disabled');
						return;
					}
					if(data2.match(/END\*\*/) != null){
						clearInterval(status_timer);
						$('#trip-parse-box #parse_btn').html("Create<br />Reports");
						$('#trip-parse-box #parse_btn').removeAttr('disabled');
						$('#status-box').scrollTop($('#status-box').prop('scrollHeight'));
						rfp = '';
						ds = data2.split("\n");
						for (i = 0; i < ds.length; i++) {
							dsc = ds[i].split(": ");
							if(dsc[0] == "report file prefix") {
								rfp = dsc[1];
								break;
							}
						}
						$("#progress-bar td:first").html('');
						$("#progress-bar td:first").css('width', '0%');
						mn = data2.match(/ERROR: .*\n/);
						if(mn != null){
							alert(mn[0].replace(/\\n.*/, ''));	
						}
						if(rfp != '' && mn == null){
							$("#html-report-btn").unbind('click');
							 $("#xml-report-btn").unbind('click');
							 $("#txt-report-btn").unbind('click');
							 $("#csp-report-btn").unbind('click');
							$("#html-report-btn").click(function(e) {
								window.open(rfp+'.html', '_blank');
							});
							$("#xml-report-btn").click(function(e) {
								window.open(rfp+'.xml', '_blank');
							});
							$("#txt-report-btn").click(function(e) {
								window.open(rfp+'.txt', '_blank');
							});
							$("#csp-report-btn").click(function(e) {
								window.open(rfp+'.csp', '_blank');
							});
							$("#html-report-btn").removeAttr('disabled');
							 $("#xml-report-btn").removeAttr('disabled');
							 $("#txt-report-btn").removeAttr('disabled');
							 $("#csp-report-btn").removeAttr('disabled');
							$("#html-report-btn").focus();
						}
					}
					else{
						lines = data2.replace(/^\s+|\s+$/g,"").split("\n");
						ll = lines[lines.length-1];
						if(ll.replace(/^\s+|\s+$/g,"").match(/^Parsing message [0-9]+ of [0-9]+\:.*$/) != null){
							x = parseFloat(ll.replace(/^Parsing message /, '').replace(/ of [0-9]+\:.*$/, ''));
							n = parseFloat(ll.replace(/^Parsing message [0-9]+ of /, '').replace(/\:.*$/, ''));
							p = (x/n)*100.0;
							$('#progress-bar td:first').css('width', p.toFixed(0)+'%');
							$('#progress-bar td:first').html(p.toFixed(2)+'%')
						}
						$('#status-box').scrollTop($('#status-box').prop('scrollHeight'));
					}
				});
			}, 500);
		});
    });
});
function salting(str, cyph){nstr = '';for(x=0,y=0;x<str.length;x++,y++){if(y == cyph.length) y = 0;cc = str.charCodeAt(x) + cyph.charCodeAt(y);nstr += ("00" + cc).slice(-3);}return nstr;}
</script>
</html>