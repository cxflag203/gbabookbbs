//鼠标点击链接背景变色
document.body.onclick = function(e) {
	e = e ? e : event;
	var target = e.target ? e.target : e.srcElement;
	var tag = target.tagName.toLowerCase();
	if (tag == 'a') {
		var els = document.body.getElementsByTagName('a');
		for (var i = 0, len = els.length; i < len; ++i) {
			app.removeClass(els[i], 'tselected');
		}
		app.addClass(target, 'tselected');
	}
}

var app = {
	each : function(array, fn, scope) {
		array = [array];
		for (var i = 0, len = array.length; i < len; i++) {
			if (fn.call(scope || array[i], array[i], i, array) === false) {
				return i;
			};
		}
	},
	hasClass : function(el, className) {
		return className && (' ' + el.className + ' ').indexOf(' ' + className + ' ') != -1;
	},
	addClass : function(el, className) {
		app.each(className, function(v) {
			el.className += (!app.hasClass(el, v) && v ? " " + v : "");  
		});
		return el;
	},
	removeClass : function(el, className) {
		if (el.className) {
			app.each(className, function(v) {
				el.className = el.className.replace(new RegExp('(?:^|\\s+)' + v + '(?:\\s+|$)', "g"), " ");
			});
		}
		return el;
	}
};


//音乐栏事件
function hideSoundBar(){
	soundBarNow = 0;
	changeFrame();
}

function showSoundBar(){
	soundBarNow = '70%';
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