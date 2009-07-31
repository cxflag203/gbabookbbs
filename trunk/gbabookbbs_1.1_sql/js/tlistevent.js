//鼠标点击链接背景变色
var curObj = null;
function document_onclick(){
	if(window.event.srcElement.tagName == 'A'){
		if(curObj !== null)
		curObj.style.background = '';
		curObj = window.event.srcElement;
		curObj.style.background = '#eff9d0';
	}
}

//音乐栏事件
function hideSoundBar(){
	soundBarNow = 0;
	changeFrame();
}

function showSoundBar(){
	soundBarNow = 570;
	changeFrame();
}

function changeFrame(){
	parent.$(bbsidentify +'rightmessage').rows = '*,'+soundBarNow;
}

function showsound(b){
	var url = b.src;
	if(parent.$(bbsidentify +'rightmessage').rows=='*,0'){
		if(parent.$(bbsidentify +'frame_sound').src == 'about:blank'){
			parent.$(bbsidentify +'frame_sound').src = "htmls/player/exobud.htm";
		}
		showSoundBar();
		b.src = "images/common/music_no.gif";
		b.alt = "关闭音乐栏";
	}else{
		hideSoundBar()
		b.src = "images/common/music.gif";
		b.alt = "打开音乐栏";
	}
}