// RedSnow HomePage JavaScript Tools
// rsTipBox - Dec. 24, 1999
// Author: Fu Hung-ming
// WebSite: http://www.tacocity.com.tw/redsnow/index.htm

var bV=parseInt(navigator.appVersion);
var NN4=(document.layers) ? true : false;
var IE4=((document.all)&&(bV>=4))?true:false;
var moveFlag=false;

var fntSize=9;					// 訊息框內的字型大小
var tipBgColor="FFFF00";		// 訊息框的底色
var tipBorderColor="000000";	// 訊息框的邊框顏色
var tipTextColor="000000";		// 訊息框內文字的顏色


function setReload(){
  window.location.reload()
}

function showTip(msg){
  var obj = 'TipBox';

  moveFlag=true;
  if(NN4){
	with (document[obj].document){
	  open();
	  write('<layer ID=TipBox bgColor=#'+tipBgColor+' style="border:1px solid #'+tipBorderColor+'; font-size:'+fntSize+'pt;"><font color=#'+tipTextColor+' lang="GB3210" face="宋体">'+msg+'</font></layer>');
	  close();
	}
    document.layers[obj].visibility = 'visible';
  }else if(IE4){
	IE_MouseMove();
    document.all[obj].innerHTML = msg;
    document.all[obj].style.visibility = 'visible';
  }
}

function hideTip(){
  var obj = 'TipBox';

  moveFlag=false;
  if(NN4){
    if(document.layers[obj] != null) document.layers[obj].visibility = 'hidden';
  }else if(IE4)
    document.all[obj].style.visibility = 'hidden';
}

function IE_MouseMove(){
  if(moveFlag){
	var x = event.x;                   // 取得滑鼠指標目前的 x 位置
	var y = event.y;                   // 取得滑鼠指標目前的 y 位置


	var objp = document.all.TipBox.style;
	var xx = (document.body.scrollLeft+x);
	var yy = (document.body.scrollTop+y);

	objp.pixelLeft = xx+20;
	objp.pixelTop = yy;
  }
} 

function NN_MouseMove(e){
  if(moveFlag){
	var objp = document.layers.TipBox;
	objp.moveTo(e.x+20, e.y);
  }
}

if(IE4){
  document.write("<DIV ID=TipBox STYLE='position:absolute; visibility: hidden; padding: 0.2em 0.2em 0.2em 0.2em; color: #"+tipTextColor+"; background-color: #"+tipBgColor+"; border:1px solid #"+tipBorderColor+"; font-size: "+fntSize+"pt'></DIV>");
  document.onmousemove = IE_MouseMove;
}else{
  document.write("<DIV ID=TipBox STYLE='position:absolute; visibility: hidden; background-color: #"+tipBgColor+"; border:1px solid #"+tipBorderColor+"; font-size: "+fntSize+"pt'></DIV>");
  document.captureEvents(Event.MOUSEMOVE);
  document.onmousemove = NN_MouseMove;
  setTimeout("window.onresize=setReload",500)
}

