<!--
//
// ■ 進行動態按鈕圖檔的切換動作
// 
toggleKey = new Object();
toggleKey[0] = "_off";
toggleKey[1] = "_on";
toggleKey[2] = "_ovr";
toggleKey[3] = "_out";
toggleKey[4] = "_mdn";
toggleKey[5] = "_mup";

function imgChange(id,act){
if(document.images){ document.images[id].src = eval("img." + id + toggleKey[act] + ".src");}
}

// 當這段程式碼應用到播放器使用時：
// 以函式 imgChange('按鈕識別名稱',0) 進行的動作即使用 "off" 的圖檔；
// 以函式 imgChange('按鈕識別名稱',1) 進行的動作即使用 "on" 的圖檔。

// 下面的部份就是設定 "off" 與 "on" 的動態按鈕圖檔。
// vmute, pmode, rept, playt, pauzt, stopt 這些都是「按鈕識別名稱」。

if(document.images){
img = new Object();

// 「靜音模式」按鈕的圖檔 (已關閉／已開啟)
img.vmute_off = new Image();
img.vmute_off.src = "./img/btn_mute_off.gif";
img.vmute_on = new Image();
img.vmute_on.src = "./img/btn_mute_on.gif";

// 「播放順序模式」按鈕的圖檔 (循序／隨機)
img.pmode_off = new Image();
img.pmode_off.src = "./img/btn_rndmode_off.gif";
img.pmode_on = new Image();
img.pmode_on.src = "./img/btn_rndmode_on.gif";

// 「是否重複播放」按鈕的圖檔 (不重複／重複)
img.rept_off = new Image();
img.rept_off.src = "./img/btn_rept_off.gif";
img.rept_on = new Image();
img.rept_on.src = "./img/btn_rept_on.gif";

// 「播放」按鈕的圖檔 (非播放中／播放中／滑鼠移至時)
img.playt_off = new Image();
img.playt_off.src = "./img/btn_play.gif";
img.playt_on = new Image();
img.playt_on.src = "./img/btn_play_on.gif";
img.playt_ovr = new Image();
img.playt_ovr.src = "./img/btn_play_ovr.gif";

// 「暫停」按鈕的圖檔 (非暫停中／暫停中／滑鼠移至時)
img.pauzt_off = new Image();
img.pauzt_off.src = "./img/btn_pauz_off.gif";
img.pauzt_on = new Image();
img.pauzt_on.src = "./img/btn_pauz_on.gif";
img.pauzt_ovr = new Image();
img.pauzt_ovr.src = "./img/btn_pauz_ovr.gif";

// 「停止」按鈕的圖檔 (未被停止／已停止／滑鼠移至時)
img.stopt_off = new Image();
img.stopt_off.src = "./img/btn_stop.gif";
img.stopt_on = new Image();
img.stopt_on.src = "./img/btn_stop_on.gif";
img.stopt_ovr = new Image();
img.stopt_ovr.src = "./img/btn_stop_ovr.gif";

// 「上一首曲目」按鈕的圖檔 (一般顯示／滑鼠移至時)
img.prevt_out = new Image();
img.prevt_out.src = "./img/btn_prev.gif";
img.prevt_ovr = new Image();
img.prevt_ovr.src = "./img/btn_prev_ovr.gif";

// 「下一首曲目」按鈕的圖檔 (一般顯示／滑鼠移至時)
img.nextt_out = new Image();
img.nextt_out.src = "./img/btn_next.gif";
img.nextt_ovr = new Image();
img.nextt_ovr.src = "./img/btn_next_ovr.gif";

// 「增加音量」按鈕的圖檔 (一般顯示／滑鼠移至時)
img.vup_out = new Image();
img.vup_out.src = "./img/btn_vup.gif";
img.vup_ovr = new Image();
img.vup_ovr.src = "./img/btn_vup_ovr.gif";

// 「減少音量」按鈕的圖檔 (一般顯示／滑鼠移至時)
img.vdn_out = new Image();
img.vdn_out.src = "./img/btn_vdn.gif";
img.vdn_ovr = new Image();
img.vdn_ovr.src = "./img/btn_vdn_ovr.gif";

// 「顯示播放清單內容」按鈕的圖檔 (一般顯示／滑鼠移至時)
img.plist_out = new Image();
img.plist_out.src = "./img/btn_plist.gif";
img.plist_ovr = new Image();
img.plist_ovr.src = "./img/btn_plist_ovr.gif";

// 顯示播放狀態的 Scope 動態圖檔 (靜止／轉動)
img.scope_off = new Image();
img.scope_off.src = "./img/scope_off.gif";
img.scope_on = new Image();
img.scope_on.src = "./img/scope_on.gif";

}

function imgtog(tg,act){
if(tg=="vmute") { if(act=="2"){imgChange("vmute",1);} else {imgmute("vmute",0);} }
if(tg=="vdn") { if(act=="2"){imgChange("vdn",2);} else {imgChange("vdn",3);} }
if(tg=="vup") { if(act=="2"){imgChange("vup",2);} else {imgChange("vup",3);} }
if(tg=="pmode") { if(act=="2"){imgChange("pmode",1);} else {imgrnd();} }
if(tg=="rept") { if(act=="2"){imgChange("rept",1);} else {imgrept();} }
if(tg=="nextt") { if(act=="2"){imgChange("nextt",2);} else {imgChange("nextt",3);} }
if(tg=="prevt") { if(act=="2"){imgChange("prevt",2);} else {imgChange("prevt",3);} }
if(tg=="pauzt") { if(act=="2"){imgpauz(2);} else {imgpauz();} }
if(tg=="playt") { if(act=="2"){imgplay(2);} else {imgplay();} }
if(tg=="stopt") { if(act=="2"){imgstop(2);} else {imgstop();} }
if(tg=="plist") { if(act=="2"){imgChange("plist",2);} else {imgChange("plist",3);} }
}

function imgmute(){
var ps=Exobud.settings;
if(ps.mute){imgChange("vmute",1);}
else {imgChange("vmute",0);}
}

function imgrnd(){
if(blnRndPlay){imgChange("pmode",1);}
else {imgChange("pmode",0);}
}

function imgrept(){
if(blnRept){imgChange("rept",1);}
else {imgChange("rept",0);}
}

function imgpauz(f){
var wmps=Exobud.playState;
if(f==2){imgChange("pauzt",2);}
else {
if(wmps==2){imgChange("pauzt",1);}
else {imgChange("pauzt",0);}
}
}

function imgplay(f){
var wmps=Exobud.playState;
if(f==2){imgChange("playt",2);}
else {
if(wmps==3){imgChange("playt",1);}
else {imgChange("playt",0);}
}
}

function imgstop(f){
var wmps=Exobud.playState;
if(f==2){imgChange("stopt",2);}
else {
if(wmps==2 || wmps==3){imgChange("stopt",0);}
else {imgChange("stopt",1);}
}
}

//-->

 
