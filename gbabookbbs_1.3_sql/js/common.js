document.onkeydown=function(){
	if(event.keyCode==27) 
		return false;
}

function $(id) {
	return document.getElementById(id);
}

function shows(htmlurl){
	var newwin = window.open(htmlurl, "_blank", "scrollbars=yes,top="+ (window.screen.availHeight / 2 - 105) +",left="+ (window.screen.availWidth / 2 - 160) +",width=340,height=230");
	newwin.focus();
	return false;
}

function shows2(htmlurl){ 
	var newwin = window.open(htmlurl, "_blank", "toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=no,top=10000,left=10000,width=1,height=1"); 
	newwin.focus(); 
	return false; 
}

function shows3(htmlurl){
	var newwin = window.open(htmlurl, "_blank", "toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=no,top="+ (window.screen.availHeight / 2 - 225) +",left="+ (window.screen.availWidth / 2 - 160) +",width=700,height=600"); 
	newwin.focus();
	return false;
}

function preview_face(){
	var face_1 = parseInt($('face1').value);
	var face_2 = parseInt($('face2').value);
	var face_3 = parseInt($('face3').value);
	$('face_preview').innerHTML = parseInt(face_1 + face_2 + face_3) > 0 ? '<img src="face/'+ face_1 + face_2 + face_3 +'.gif" border="0" />' : '';
}

function fastpost(btn, event) {
	if ((event.altKey && event.keyCode == 83) || (event.ctrlKey && event.keyCode == 13)){
		$(btn).click();
	}
}

function getPos(obj){
	this.Left = 0;
	this.Top = 0;
	var TempLeft;
	var tempObj = document.getElementById(obj)
	while (tempObj.tagName.toLowerCase() != "body"){
		this.Left += tempObj.offsetLeft;
		this.Top += tempObj.offsetTop;
		tempObj = tempObj.offsetParent;
		TempLeft += tempObj.offsetLeft + ",";
	}
}

function displayeditor(editorwidth){
	var s = $('message').value;

	editorwidth = editorwidth == undefined ? '400' : editorwidth;
	$('editorzone').innerHTML = '<input type="hidden" id="message" name="message" style="display:hidden" /><input type="hidden" id="content___Config" value="" style="display:none" /><iframe id="content___Frame" src="include/editor/editor/fckeditor.html?InstanceName=message" width="'+editorwidth+'" height="200" frameborder="0" scrolling="no"></iframe>'; 
	$('message').value = s.replace(/\n/g, '<br />');
	$('disable_autowap').checked = true;
}

function showquot(pid, f){
	if(!$('quot')){
		return false;
	}
	ajax_get('topiccp.asp?action=ajaxquot&pid='+ pid +'&f='+ f, 'quot');
}

function f_autowap(){
	if($('message').type == 'hidden')
		$('disable_autowap').checked = true;
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

function insert_attach(aid){
	if($('message').type == 'hidden'){
		var oEditor = FCKeditorAPI.GetInstance('message');
		if (oEditor.EditMode == FCK_EDITMODE_WYSIWYG){
			oEditor.InsertHtml('[attach]'+ aid +'[/attach]') ;
		}
		else{
			alert('请把编辑器切换到编辑模式再插入附件。') ;
		}
	}
	else{
		$('message').focus();
		if (document.all){
			document.selection.createRange().text = '[attach]'+ aid +'[/attach]';
		}else {
			var rangeStart = $('message').selectionStart;
			var rangeEnd = $('message').selectionEnd;
			var tempStr1 = $('message').value.substring(0,rangeStart);
			var tempStr2 = $('message').value.substring(rangeEnd);
			$('message').value = tempStr1 + '[attach]'+ aid +'[/attach]' + tempStr2; 
		}
	}
}

function postvalue(action, name, value){
	var deleteform = document.createElement("form");
	deleteform.id = 'deleteform';
	deleteform.method = 'post';
	deleteform.action = action;
	deleteform.target = '_self';
	var deleteforminput = document.createElement('input');
	deleteforminput.type= 'hidden';
	deleteforminput.name = name;
	deleteforminput.value = value;
	deleteform.appendChild(deleteforminput);
	document.body.appendChild(deleteform);
	deleteform.submit();
}