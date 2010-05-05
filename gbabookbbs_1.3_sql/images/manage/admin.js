function $(id) {
	return document.getElementById(id);
}

function showsubmenu(sid){
	whichEl = eval("submenu" + sid);
	if (whichEl.style.display == "none"){
		eval("submenu" + sid + ".style.display=\"\";");
		eval("menuimg_" + sid + ".src=\"../images/manage/menu_reduce.gif\";");
	}
	else{
		eval("submenu" + sid + ".style.display=\"none\";");
		eval("menuimg_" + sid + ".src=\"../images/manage/menu_add.gif\";");
	}
}

var curObj= null;
function document_onclick()
{
	if(window.event.srcElement.tagName=='A')
	{
		if(curObj!=null)
		curObj.style.background='';
		curObj=window.event.srcElement;
		curObj.style.background='#FFDEAD';
	}
}

function checkall(frm, name){
	var es= frm.elements[name];
	if (!es)
		return;

	if (es.length)
		for(var i=0,e;e = es[i],i<es.length;i++)
		e.checked=!e.checked;
	else
		es.checked=!es.checked;
}