<!--
var messages=new Array()
 messages[0]='<a href="http://www.gbabook.com/topic/200510/200510112963017.htm" style="color:#FF6666">国庆快乐</a>';
function roll(i){
document.all.top.innerHTML=messages[i];
if (i<1) {i=i+1;}
else i=0;
setTimeout("roll("+i+")",3000);
}
document.write('&nbsp;<span id=top>-------</span>');
roll(0);
//-->

