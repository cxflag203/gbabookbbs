document.write("<div id=\"elFader\" style=\"position:relative;visibility:hidden\" onClick=\"FDRreplay()\">论坛公告</div>");
document.close();

//宽
var FDRboxWid = 400;
//高
var FDRboxHgt = 18;
//边框
var FDRborWid = 0;
//边框色
var FDRborCol = "";
//边框样式
var FDRborSty = "solid";
//背景色
var FDRbackCol = "";
//边距
var FDRboxPad = 4;
//内容文本对齐方式
var FDRtxtAln = "left";
//行高
var FDRlinHgt = "9pt";
//文本字体
var FDRfntFam = "Verdana,Arial,宋体";
//文本字体大小
var FDRfntSiz = "12px";
//文本字体样式
var FDRfntWgh = "bold";
var FDRfntSty = "normal";

//Dummy图像url
var FDRgifSrc = "images/fade.gif";
var FDRgifInt = 60;

//循环时间(s)
var FDRblendInt = 5;
//循环变换时间(s)
var FDRblendDur = 0;
//循环次数，0为无限循环
var FDRmaxLoops = 10;

//循环结束时，用户点击后是否允许再次循环
var FDRreplayOnClick = false;
   
var FDRjustFlip = false;
var FDRhdlineCount = 0;

var newsCount;
var loopCount;

var NS4 = (document.layers);
var IE4 = (document.all);

var appVer = navigator.appVersion;
var IEmac = (IE4 && appVer.indexOf("Mac") != -1);
var IE4mac = (IEmac && appVer.indexOf("MSIE 4") != -1);
var IE40mac = (IE4mac && appVer.indexOf("4.0;") != -1);
var IE45mac = (IE4mac && appVer.indexOf("4.5;") != -1);
var NSpre401 = (NS4 && (parseFloat(appVer) <= 4.01));
var NSpre403 = (NS4 && (parseFloat(appVer) <= 4.03));

var FDRjustFlip = (window.FDRjustFlip) ? FDRjustFlip : false;
var FDRhdlineCount = (window.FDRhdlineCount) ? FDRhdlineCount : 1;

var FDRfinite = (FDRmaxLoops > 0);
var FDRisOver = false;
var FDRloadCount = 0;

var blendTimer = null;

window.onload = FDRcountLoads;

if (NS4) {
	if(FDRjustFlip || NSpre403) {
		totalLoads = 1;
		FDRfadeImg = new Object();
		FDRfadeImg.width = FDRboxWid - (FDRborWid*2);;
	}
	else {
		totalLoads = 2;
		FDRfadeImg = new Image();
		FDRfadeImg.onload = FDRcountLoads;
		FDRfadeImg.onerror = FDRcountLoads;
		FDRfadeImg.src = FDRgifSrc;
	}
}

function FDRcountLoads(e) {
	if (IE4) {
		setTimeout("FDRinit()",1);
	}
	else {
		if(e.type == "error") FDRjustFlip = true; 
		FDRloadCount++;
		if (FDRloadCount==totalLoads) {
			origWidth = innerWidth;
			origHeight = innerHeight;
			window.onresize = function(){
				if (innerWidth==origWidth && innerHeight==origHeight) return;
				location.reload();
			}
			FDRinit();
		}
	}
}

function FDRinit(){
	if(!window.arNews) {
		if(!window.arTXT || !window.arURL) return;
		if(arTXT.length != arURL.length) return;
		arNews = [];
		for (i=0;i<arTXT.length;i++){
			arNews[arNews.length] = arTXT[i];
			arNews[arNews.length] = arURL[i];
		}
	}

	if (NS4) {
		if (!document.elFader) return;
		with(document.classes.nolink.P) {
			fontWeight = FDRfntWgh;
			fontSize = FDRfntSiz;
			fontStyle = FDRfntSty;
			fontFamily = FDRfntFam;
			lineHeight = FDRlinHgt;
			textAlign = FDRtxtAln;
		}
		elFader = document.elFader;
		with (elFader) {
			document.write(" ");
			document.close();
			bgColor = FDRborCol;
			clip.width = FDRboxWid;
			clip.height = FDRboxHgt;
		}

		contWidth = FDRboxWid - (FDRborWid*2);
		contHeight = FDRboxHgt - (FDRborWid*2);
		elCont = new Layer(contWidth,elFader);
		with (elCont) {
			top = FDRborWid;
			left = FDRborWid;
			clip.width = contWidth;
			clip.height = contHeight;
			bgColor = FDRbackCol;
			visibility = "inherit";
		}

		newsWidth = contWidth - (FDRboxPad*2);
		newsHeight = contHeight - (FDRboxPad*2);
		elNews = new Layer(newsWidth,elCont);
		with (elNews) {
			top = FDRboxPad;
			left = FDRboxPad;
			clip.width = newsWidth ;
			clip.height = newsHeight;
		}

		if (!FDRjustFlip) {
			elGif = new Layer(contWidth,elCont); 
			imStr = "<IMG SRC='" + FDRgifSrc +"' WIDTH="+ Math.max(FDRfadeImg.width,(FDRboxWid - (FDRborWid*2)));
			imStr += (NSpre403) ? " onError='window.FDRjustFlip = true'>" : ">";
			with (elGif) {
				document.write(imStr);
				document.close();
				moveAbove(elNews);
			}

			imgHeight = elGif.document.height;
			slideInc = (imgHeight/(FDRblendDur*1000/FDRgifInt));
			startTop = -(imgHeight - FDRboxHgt);
		}
		
		elFader.visibility =  "show";
	}
	else {
		if (!window.elFader) return;
		elFader.innerHTML ="";
		if(IE4mac) {
			document.body.insertAdjacentHTML("BeforeBegin","<STYLE></STYLE>");
		}
		else {
			if (!document.styleSheets.length) document.createStyleSheet();
		}

		with (elFader.style) {
			errorOffset = (IE4mac) ? (FDRboxPad + FDRborWid) : 0;
			width = FDRboxWid - (errorOffset * 2);
			height = FDRboxHgt - (errorOffset * 2);
			if(IE4mac && !IE45mac){
				pixelLeft = elFader.offsetLeft + errorOffset;
				pixelTop = elFader.offsetTop + errorOffset;
			}

			backgroundColor = FDRbackCol;
			overflow = "hidden";
			fontWeight = FDRfntWgh;
			fontSize = FDRfntSiz;
			fontStyle = FDRfntSty;
			fontFamily = FDRfntFam;
			lineHeight = FDRlinHgt;
			textAlign = FDRtxtAln;
			cursor = "default";
			visibility = "visible";
			borderWidth = FDRborWid;
			borderStyle = FDRborSty;
			borderColor = FDRborCol;
			padding  = FDRboxPad;
			
			if(!FDRjustFlip) filter = "blendTrans(duration=" + FDRblendDur + ")";
		}
		elFader.onselectstart = function(){return false};
		
		IEhasFilters = (elFader.filters.blendTrans) ? true : false;
	}

	if (!NSpre401) {
		elFader.onmouseover = function (){
			FDRisOver = true;
		}
		elFader.onmouseout = function(){
			FDRisOver = false;
			status = "";
		}
	}

	FDRstart(0);
}

function FDRstart(ind){
	newsCount = ind;
	if (FDRfinite) loopCount = 0;
	FDRdo();
	blendTimer = setInterval("FDRdo()",FDRblendInt*1000)
}

function FDRdo() {
	if(!blendTimer && loopCount>0) return;

	if (FDRfinite && loopCount>=FDRmaxLoops) {
		FDRend();
		return;
	}
	FDRfade();

	if (newsCount == arNews.length) {
		newsCount = 0;
		if (FDRfinite) loopCount++;
	}
}

function FDRmakeStr(){
	tempStr = "";
	for (i=0;i<FDRhdlineCount;i++){
		if(newsCount>=arNews.length)break;
		dispStr = arNews[newsCount];
		tempStr+=((NS4) ? "<P CLASS=nolink>" : "<P>") +dispStr+"</P>";
		if(IE40mac) tempStr +="<BR>";
		newsCount += 1;
	}
	return tempStr;
}

function FDRfade(){
	newsStr = FDRmakeStr();

	if (NS4) {
		if (!FDRjustFlip) {
			elGif.top = startTop;
			elGif.visibility = "inherit";
		}
	
		elNews.visibility = "hide";
		with (elNews.document) {
			write(newsStr);
			close();
		}
		elNews.visibility = "inherit";
	}
	else {
		if(IEhasFilters)elFader.filters.blendTrans.Apply();
		elFader.innerHTML = newsStr;
		if(IEhasFilters)elFader.filters.blendTrans.Play();
	}

	if (NS4 && !FDRjustFlip) FDRslide();
}

function FDRslide(){
	elGif.top += slideInc;
	if (elGif.top >= 0) {elGif.visibility = "hide";return}
	setTimeout("FDRslide()",FDRgifInt);
}

function FDRend(){
	clearInterval(blendTimer);
	blendTimer = null;
	loopCount++;
}
function FDRreplay(){
	if(FDRreplayOnClick && FDRfinite && null==blendTimer){
		FDRstart(0);
	}
}