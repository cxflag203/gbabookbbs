<!--
function MM_initTimelines() { //v4.0
//MM_initTimelines() Copyright 1997 Macromedia, Inc. All rights reserved.
var ns = navigator.appName == "Netscape";
var ns4 = (ns && parseInt(navigator.appVersion) == 4);
var ns5 = (ns && parseInt(navigator.appVersion) > 4);
var macIE5 = (navigator.platform ? (navigator.platform == "MacPPC") : false) && (navigator.appName == "Microsoft Internet Explorer") && (parseInt(navigator.appVersion) >= 4);
document.MM_Time = new Array(1);
document.MM_Time[0] = new Array(4);
document.MM_Time["Timeline1"] = document.MM_Time[0];
document.MM_Time[0].MM_Name = "Timeline1";
document.MM_Time[0].fps = 60;
document.MM_Time[0][0] = new String("sprite");
document.MM_Time[0][0].slot = 1;
if (ns4)
document.MM_Time[0][0].obj = document["floater"] ? document["floater"].document["Layer1"] : document["Layer1"];
else if (ns5)
document.MM_Time[0][0].obj = document.getElementById("Layer1");
else
document.MM_Time[0][0].obj = document.all ? document.all["Layer1"] : null;
document.MM_Time[0][0].keyFrames = new Array(1, 30, 45);
document.MM_Time[0][0].values = new Array(4);
if (ns5 || macIE5)
document.MM_Time[0][0].values[0] = new Array("-750px", "-724px", "-698px", "-672px", "-647px", "-621px", "-595px", "-569px", "-543px", "-517px", "-491px", "-466px", "-440px", "-414px", "-388px", "-362px", "-336px", "-310px", "-284px", "-259px", "-233px", "-207px", "-181px", "-155px", "-129px", "-103px", "-78px", "-52px", "-26px", "0px", "-50px", "-100px", "-150px", "-200px", "-250px", "-300px", "-350px", "-400px", "-450px", "-500px", "-550px", "-600px", "-650px", "-700px", "-750px");
else
document.MM_Time[0][0].values[0] = new Array(-750,-724,-698,-672,-647,-621,-595,-569,-543,-517,-491,-466,-440,-414,-388,-362,-336,-310,-284,-259,-233,-207,-181,-155,-129,-103,-78,-52,-26,0,-50,-100,-150,-200,-250,-300,-350,-400,-450,-500,-550,-600,-650,-700,-750);
document.MM_Time[0][0].values[0].prop = "left";
if (ns5 || macIE5)
document.MM_Time[0][0].values[1] = new Array("-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px", "-165px");
else
document.MM_Time[0][0].values[1] = new Array(-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165,-165);
document.MM_Time[0][0].values[1].prop = "top";
if (!ns4) {
document.MM_Time[0][0].values[0].prop2 = "style";
document.MM_Time[0][0].values[1].prop2 = "style";
}
if (ns5 || macIE5)
document.MM_Time[0][0].values[2] = new Array("350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px", "350px");
else
document.MM_Time[0][0].values[2] = new Array(350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350,350);
document.MM_Time[0][0].values[2].prop = "width";
if (!ns4)
document.MM_Time[0][0].values[2].prop2 = "style";
document.MM_Time[0][0].values[3] = new Array("2","2","2");
document.MM_Time[0][0].values[3].prop = "zIndex";
if (!ns4)
document.MM_Time[0][0].values[3].prop2 = "style";
document.MM_Time[0][1] = new String("behavior");
document.MM_Time[0][1].frame = 30;
document.MM_Time[0][1].value = "MM_timelineStop()";
document.MM_Time[0][2] = new String("behavior");
document.MM_Time[0][2].frame = 45;
document.MM_Time[0][2].value = "MM_timelineStop()";
document.MM_Time[0][3] = new String("behavior");
document.MM_Time[0][3].frame = 46;
document.MM_Time[0][3].value = "MM_timelineGoto('Timeline1','1')";
document.MM_Time[0].lastFrame = 46;
for (i=0; i<document.MM_Time.length; i++) {
document.MM_Time[i].ID = null;
document.MM_Time[i].curFrame = 0;
document.MM_Time[i].delay = 1000/document.MM_Time[i].fps;
}
}

function MM_timelineStop(tmLnName) { //v1.2
//Copyright 1997 Macromedia, Inc. All rights reserved.
if (document.MM_Time == null) MM_initTimelines(); //if *very* 1st time
if (tmLnName == null) //stop all
for (var i=0; i<document.MM_Time.length; i++)
document.MM_Time[i].ID = null;
else 
document.MM_Time[tmLnName].ID = null; //stop one
}

function MM_timelineGoto(tmLnName, fNew, numGotos) { //v2.0
//Copyright 1997 Macromedia, Inc. All rights reserved.
var i,j,tmLn,props,keyFrm,sprite,numKeyFr,firstKeyFr,lastKeyFr,propNum,theObj;
if (document.MM_Time == null) MM_initTimelines(); //if *very* 1st time
tmLn = document.MM_Time[tmLnName];
if (numGotos != null)
if (tmLn.gotoCount == null) 
tmLn.gotoCount = 1;
else if (tmLn.gotoCount++ >= numGotos) {
tmLn.gotoCount=0; 
return;
}
jmpFwd = (fNew > tmLn.curFrame);
for (i = 0; i < tmLn.length; i++) {
sprite = (jmpFwd)? tmLn[i] : tmLn[(tmLn.length-1)-i]; //count bkwds if jumping back
if (sprite.charAt(0) == "s") {
numKeyFr = sprite.keyFrames.length;
firstKeyFr = sprite.keyFrames[0];
lastKeyFr = sprite.keyFrames[numKeyFr - 1];
if ((jmpFwd && fNew<firstKeyFr) || (!jmpFwd && lastKeyFr<fNew)) 
continue; //skip if untouchd
for (keyFrm=1; keyFrm<numKeyFr && fNew>=sprite.keyFrames[keyFrm]; keyFrm++);
for (j=0; j<sprite.values.length; j++) {
props = sprite.values[j];
if (numKeyFr == props.length) 
propNum = keyFrm-1 //keyframes only
else 
propNum = Math.min(Math.max(0,fNew-firstKeyFr),props.length-1); //or keep in legal range
if (sprite.obj != null) {
if (props.prop2 == null) 
sprite.obj[props.prop] = props[propNum];
else 
sprite.obj[props.prop2][props.prop] = props[propNum];
} 
}
} else if (sprite.charAt(0)=='b' && fNew == sprite.frame) 
eval(sprite.value);
}
tmLn.curFrame = fNew;
if (tmLn.ID == 0) eval('MM_timelinePlay(tmLnName)');
}

function MM_timelinePlay(tmLnName, myID)
{
//v1.2
//Copyright 1997 Macromedia, Inc. All rights reserved.
var i, j, tmLn, props, keyFrm, sprite, numKeyFr, firstKeyFr, propNum,
theObj, firstTime = false;
if (document.MM_Time == null)
MM_initTimelines();
//if *very* 1st time
tmLn = document.MM_Time[tmLnName];
if (myID == null)
{
myID = ++tmLn.ID;
firstTime = true;
} //if new call, incr ID
if (myID == tmLn.ID)
{
//if Im newest
setTimeout('MM_timelinePlay("' + tmLnName + '",' + myID + ')',
tmLn.delay);
fNew = ++tmLn.curFrame;
for (i = 0; i < tmLn.length; i++)
{
sprite = tmLn[i];
if (sprite.charAt(0) == 's')
{
if (sprite.obj)
{
numKeyFr = sprite.keyFrames.length;
firstKeyFr = sprite.keyFrames[0];
if (fNew >= firstKeyFr && fNew <= sprite.keyFrames[numKeyFr
- 1])
{
//in range
keyFrm = 1;
for (j = 0; j < sprite.values.length; j++)
{
props = sprite.values[j];
if (numKeyFr != props.length)
{
if (props.prop2 == null)
sprite.obj[props.prop] = props[fNew -
firstKeyFr];
else
sprite.obj[props.prop2][props.prop] =
props[fNew - firstKeyFr];
}
else
{
while (keyFrm < numKeyFr && fNew >=
sprite.keyFrames[keyFrm])
keyFrm++;
if (firstTime || fNew ==
sprite.keyFrames[keyFrm - 1])
{
if (props.prop2 == null)
sprite.obj[props.prop] = props[keyFrm -
	1];
else
sprite.obj[props.prop2][props.prop] =
	props[keyFrm - 1];
}
}
}
}
}
}
else if (sprite.charAt(0) == 'b' && fNew == sprite.frame)
eval(sprite.value);
if (fNew > tmLn.lastFrame)
tmLn.ID = 0;
}
}
}

function MM_initTimelines()
{
//v4.0
//MM_initTimelines() Copyright 1997 Macromedia, Inc. All rights reserved.
var ns = navigator.appName == "Netscape";
var ns4 = (ns && parseInt(navigator.appVersion) == 4);
var ns5 = (ns && parseInt(navigator.appVersion) > 4);
document.MM_Time = new Array(1);
document.MM_Time[0] = new Array(4);
document.MM_Time["Timeline1"] = document.MM_Time[0];
document.MM_Time[0].MM_Name = "Timeline1";
document.MM_Time[0].fps = 60;
document.MM_Time[0][0] = new String("sprite");
document.MM_Time[0][0].slot = 1;
if (ns4)
document.MM_Time[0][0].obj = document["floater"] ?
document["floater"].document["Layer1"]: document["Layer1"];
else if (ns5)
document.MM_Time[0][0].obj = document.getElementById("Layer1");
else
document.MM_Time[0][0].obj = document.all ? document.all["Layer1"]:
null;
document.MM_Time[0][0].keyFrames = new Array(1, 30, 45);
document.MM_Time[0][0].values = new Array(4);
if (ns5)
document.MM_Time[0][0].values[0] = new Array("-750px", "-724px",
"-698px", "-672px", "-647px", "-621px", "-595px", "-569px",
"-543px", "-517px", "-491px", "-466px", "-440px", "-414px",
"-388px", "-362px", "-336px", "-310px", "-284px", "-259px",
"-233px", "-207px", "-181px", "-155px", "-129px", "-103px", "-78px",
"-52px", "-26px", "0px", "-50px", "-100px", "-150px", "-200px",
"-250px", "-300px", "-350px", "-400px", "-450px", "-500px",
"-550px", "-600px", "-650px", "-700px", "-750px");
else
document.MM_Time[0][0].values[0] = new Array( - 750,  - 724,  - 698,  -
672,  - 647,  - 621,  - 595,  - 569,  - 543,  - 517,  - 491,  - 466,
- 440,  - 414,  - 388,  - 362,  - 336,  - 310,  - 284,  - 259,  -
233,  - 207,  - 181,  - 155,  - 129,  - 103,  - 78,  - 52,  - 26, 0,
- 50,  - 100,  - 150,  - 200,  - 250,  - 300,  - 350,  - 400,  -
450,  - 500,  - 550,  - 600,  - 650,  - 700,  - 750);
document.MM_Time[0][0].values[0].prop = "left";
if (ns5)
document.MM_Time[0][0].values[1] = new Array("-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px", "-165px", "-165px", "-165px", "-165px", "-165px",
"-165px");
else
document.MM_Time[0][0].values[1] = new Array( - 165,  - 165,  - 165,  -
165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,
- 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  -
165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,
- 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  -
165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165,  - 165);
document.MM_Time[0][0].values[1].prop = "top";
if (!ns4)
{
document.MM_Time[0][0].values[0].prop2 = "style";
document.MM_Time[0][0].values[1].prop2 = "style";
}
if (ns5)
document.MM_Time[0][0].values[2] = new Array("350px", "350px", "350px",
"350px", "350px", "350px", "350px", "350px", "350px", "350px",
"350px", "350px", "350px", "350px", "350px", "350px", "350px",
"350px", "350px", "350px", "350px", "350px", "350px", "350px",
"350px", "350px", "350px", "350px", "350px", "350px", "350px",
"350px", "350px", "350px", "350px", "350px", "350px", "350px",
"350px", "350px", "350px", "350px", "350px", "350px", "350px");
else
document.MM_Time[0][0].values[2] = new Array(350, 350, 350, 350, 350,
350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350,
350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350,
350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350, 350,
350);
document.MM_Time[0][0].values[2].prop = "width";
if (!ns4)
document.MM_Time[0][0].values[2].prop2 = "style";
document.MM_Time[0][0].values[3] = new Array("2", "2", "2");
document.MM_Time[0][0].values[3].prop = "zIndex";
if (!ns4)
document.MM_Time[0][0].values[3].prop2 = "style";
document.MM_Time[0][1] = new String("behavior");
document.MM_Time[0][1].frame = 30;
document.MM_Time[0][1].value = "MM_timelineStop()";
document.MM_Time[0][2] = new String("behavior");
document.MM_Time[0][2].frame = 45;
document.MM_Time[0][2].value = "MM_timelineStop()";
document.MM_Time[0][3] = new String("behavior");
document.MM_Time[0][3].frame = 46;
document.MM_Time[0][3].value = "MM_timelineGoto('Timeline1','1')";
document.MM_Time[0].lastFrame = 46;
for (i = 0; i < document.MM_Time.length; i++)
{
document.MM_Time[i].ID = null;
document.MM_Time[i].curFrame = 0;
document.MM_Time[i].delay = 1000 / document.MM_Time[i].fps;
}
}

self.onError=null;
currentX = currentY = 0;  
whichIt = null;           
lastScrollX = 0; lastScrollY = 0;
NS = (document.layers) ? 1 : 0;
IE = (document.all) ? 1: 0;

function heartBeat() {
if(IE) { diffY = document.body.scrollTop; diffX = document.body.scrollLeft; }
if(NS) { diffY = self.pageYOffset; diffX = self.pageXOffset; }
if(diffY != lastScrollY) {
percent = .1 * (diffY - lastScrollY);
if(percent > 0) percent = Math.ceil(percent);
else percent = Math.floor(percent);
if(IE) document.all.floater.style.pixelTop += percent;
if(NS) document.floater.top += percent; 
lastScrollY = lastScrollY + percent;
}
if(diffX != lastScrollX) {
percent = .1 * (diffX - lastScrollX);
if(percent > 0) percent = Math.ceil(percent);
else percent = Math.floor(percent);
if(IE) document.all.floater.style.pixelLeft += percent;
if(NS) document.floater.left += percent;
lastScrollX = lastScrollX + percent;
}	
}

function checkFocus(x,y) { 
stalkerx = document.floater.pageX;
stalkery = document.floater.pageY;
stalkerwidth = document.floater.clip.width;
stalkerheight = document.floater.clip.height;
if( (x > stalkerx && x < (stalkerx+stalkerwidth)) && (y > stalkery && y < (stalkery+stalkerheight))) return true;
else return false;
}

function grabIt(e) {
if(IE) {
whichIt = event.srcElement;
while (whichIt.id.indexOf("floater") == -1) {
whichIt = whichIt.parentElement;
if (whichIt == null) { return true; }
}
whichIt.style.pixelLeft = whichIt.offsetLeft;
whichIt.style.pixelTop = whichIt.offsetTop;
currentX = (event.clientX + document.body.scrollLeft);
currentY = (event.clientY + document.body.scrollTop); 	
} else { 
window.captureEvents(Event.MOUSEMOVE);
if(checkFocus (e.pageX,e.pageY)) { 
whichIt = document.floater;
StalkerTouchedX = e.pageX-document.floater.pageX;
StalkerTouchedY = e.pageY-document.floater.pageY;
} 
}
return true;
}

function moveIt(e) {
if (whichIt == null) { return false; }
if(IE) {
newX = (event.clientX + document.body.scrollLeft);
newY = (event.clientY + document.body.scrollTop);
distanceX = (newX - currentX);    distanceY = (newY - currentY);
currentX = newX;    currentY = newY;
whichIt.style.pixelLeft += distanceX;
whichIt.style.pixelTop += distanceY;
if(whichIt.style.pixelTop < document.body.scrollTop) whichIt.style.pixelTop = document.body.scrollTop;
if(whichIt.style.pixelLeft < document.body.scrollLeft) whichIt.style.pixelLeft = document.body.scrollLeft;
if(whichIt.style.pixelLeft > document.body.offsetWidth - document.body.scrollLeft - whichIt.style.pixelWidth - 20) whichIt.style.pixelLeft = document.body.offsetWidth - whichIt.style.pixelWidth - 20;
if(whichIt.style.pixelTop > document.body.offsetHeight + document.body.scrollTop - whichIt.style.pixelHeight - 5) whichIt.style.pixelTop = document.body.offsetHeight + document.body.scrollTop - whichIt.style.pixelHeight - 5;
event.returnValue = false;
} else { 
whichIt.moveTo(e.pageX-StalkerTouchedX,e.pageY-StalkerTouchedY);
if(whichIt.left < 0+self.pageXOffset) whichIt.left = 0+self.pageXOffset;
if(whichIt.top < 0+self.pageYOffset) whichIt.top = 0+self.pageYOffset;
if( (whichIt.left + whichIt.clip.width) >= (window.innerWidth+self.pageXOffset-17)) whichIt.left = ((window.innerWidth+self.pageXOffset)-whichIt.clip.width)-17;
if( (whichIt.top + whichIt.clip.height) >= (window.innerHeight+self.pageYOffset-17)) whichIt.top = ((window.innerHeight+self.pageYOffset)-whichIt.clip.height)-17;
return false;
}
return false;
}

function dropIt() {
whichIt = null;
if(NS) window.releaseEvents(Event.MOUSEMOVE);
return true;
}

if(NS) {
window.captureEvents(Event.MOUSEUP|Event.MOUSEDOWN);
window.onmousedown = grabIt;
window.onmousemove = moveIt;
window.onmouseup = dropIt;
}
if(IE) {
document.onmousedown = grabIt;
document.onmousemove = moveIt;
document.onmouseup = dropIt;
}
if(NS || IE) action = window.setInterval("heartBeat()",1);

//-->