<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "HALTED")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "submitmodify"
		Call SubmitModify()
	Case Else
		Call Main()
End Select

'========================================================
'编辑帖子/删除
'========================================================
Sub SubmitModify()
	If Len(Request.Form("btnsubmit")) > 0 Then
		Call SavePost()
	ElseIf Len(Request.Form("btndelete")) > 0 Then
		Call DeletePost()
	End If
End Sub

'========================================================
'保存编辑的帖子(回复)
'========================================================
Sub SavePost()
	Dim PostID, PostInfo
	Dim Title, Message, IfLocked, Disable_Autowap, IfParseURL, DisplayOrder
	Dim d_AttachID, AttachID, Description, NewAttachID, NewDescription, AttachListArray, Attachments, IfAttachment

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.tid, p.iffirst, p.uid, t.fid, t.displayorder, t.title, t.iflocked, t.disablemodify FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.fid = "& RQ.ForumID &" AND t.displayorder >= 0")

	If Not IsArray(PostInfo) Then
		Call RQ.showTips("内容不存在或者已经被删除。", "", "")
	End If

	If PostInfo(2, 0) <> RQ.UserID Then
		Call RQ.showTips("只有作者自己才能编辑内容。", "", "")
	End If

	'帖子(回复)是否允许被编辑
	Select Case PostInfo(7, 0)
		Case 1
			If PostInfo(1, 0) = 1 Then
				Call RQ.showTips("由于帖子被鉴定或者其他方面的原因，该帖子不允许编辑。", "", "")
			End If
		Case 2
			Call RQ.showTips("由于帖子类型特殊(例如悬赏贴)或者其他方面的原因，该帖子不允许编辑。", "", "")
	End Select

	'是否允许使用HTML
	If RQ.blnAllowHTML(0) Then
		Message = SafeRequest(2, "message", 1, "", 1)
	Else
		Message = SafeRequest(2, "message", 1, "", 0)
	End If

	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写好内容。", "", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	'识别网址和图片
	IfParseURL = SafeRequest(2, "ifparseurl", 0, 0, 0)
	If IfParseURL = 1 And RQ.UserID > 0 Then
		Message = ParseURL(Message)
	End If

	'是否换行
	Disable_Autowap = SafeRequest(2, "disable_autowap", 0, 0, 0)
	If Disable_Autowap = 0 Then 
		Message = Replace(Message, vbCrLf, "<br />")
	Else
		Message = Replace(Replace(Message, Chr(10), ""), Chr(13), "")
	End If

	'需要审核的关键词不允许发表
	If WordsAdulting(Message) Then
		Call RQ.showTips("您提交的内容中含有需要重新审核的敏感字符，所以不允许提交。", "", "")
	End If

	'如果是编辑帖子
	If PostInfo(1, 0) = 1 Then
		Title = SafeRequest(2, "title", 1, "", 1)
		IfLocked = SafeRequest(2, "iflocked", 0, 0, 0)

		If Len(CheckContent(Title)) = 0 Then
			Call RQ.showTips("请填写好帖子标题。", "", "")
		End If

		'需要审核的关键词不允许发表
		If WordsAdulting(Title) Then
			Call RQ.showTips("您提交的标题中含有需要重新审核的敏感字符，所以不允许提交。", "", "")
		End If

		'词语过滤
		Title = WordsFilter(Title)

		If Title <> PostInfo(5, 0) Then
			Title = Replace(Replace(Title, "<", "&lt;"), ">", "&gt;")
		End If

		Title = IIF(Len(Title) > 255, Left(Title, 255), Title)

		If PostInfo(6, 0) = 2 Then
			IfLocked = 2
		ElseIf IfLocked > 1 Then
			IfLocked = 0
		End If

		'如果版面设置了需要审核每个新帖子，那么在编辑帖子后，也应该列入审核
		If RQ.F_AdultingPost = 1 Then
			If PostInfo(4, 0) > 0 Then
				Call RQ.UpdateStickTopic(PostInfo(3, 0), PostInfo(0, 0), 0)
			End If

			Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics - 1)'更新版面帖子数量缓存
			DisplayOrder = -1
		Else
			DisplayOrder = PostInfo(4, 0)
		End If
	End If

	'删除附件
	d_AttachID = NumberGroupFilter(Replace(SafeRequest(2, "d_aid", 1, "", 0), " ", ""))
	If Len(d_AttachID) > 0 Then
		AttachListArray = RQ.Query("SELECT savepath, ifthumb FROM "& TablePre &"attachments WHERE aid IN("& d_AttachID &") AND uid = "& RQ.UserID)
		If IsArray(AttachListArray) Then
			For i = 0 To UBound(AttachListArray, 2)
				Call DeleteFile(RQ.Attach_Settings(0) &"/"& AttachListArray(0, i))

				'删除缩略图
				If AttachListArray(1, i) = 1 Then
					Call DeleteFile(RQ.Attach_Settings(0) &"/"& AttachListArray(0, i) &".thumb."& GetFileExt(AttachListArray(0, i)))
				End If
			Next

			RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE aid IN("& d_AttachID &") AND uid = "& RQ.UserID)
		End If
	End If

	'更新描述
	If Request.Form("aid").Count > 0 Then
		For i = 1 To Request.Form("aid").Count
			AttachID = IntCode(Request.Form("aid")(i))
			Description = strFilter(Request.Form("description")(i))
			Description = IIF(Len(Description) > 255, Left(Description, 255), Description)

			If AttachID > 0 And Not InStr(","& d_AttachID &",", ","& AttachID &",") > 0 Then
				RQ.Execute("UPDATE "& TablePre &"attachments SET description = '"& Description &"' WHERE aid = "& AttachID &" AND uid = "& RQ.UserID)
			End If
		Next
	End If

	'新增附件
	If Request.Form("newaid").Count > 0 Then
		For i = 1 To Request.Form("newaid").Count
			NewAttachID = IntCode(Request.Form("newaid")(i))
			NewDescription = strFilter(Request.Form("newdescription")(i))
			NewDescription = IIF(Len(NewDescription) > 255, Left(NewDescription, 255), NewDescription)

			If NewAttachID > 0 Then
				RQ.Execute("UPDATE "& TablePre &"attachments SET tid = "& PostInfo(0, 0) &", pid = "& PostID &", description = '"& NewDescription &"' WHERE aid = "& NewAttachID &" AND uid = "& RQ.UserID)
			End If
		Next
	End If

	'发言是否有附件
	Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE pid = "& PostID)(0)
	IfAttachment = IIF(Attachments = 0, 0, 1)

	'更新回复内容
	RQ.Execute("UPDATE "& TablePre &"posts SET message = '"& Message &"', ifattachment = "& IfAttachment &" WHERE pid = "& PostID)

	'帖子是否有附件
	Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE tid = "& PostInfo(0, 0))(0)
	IfAttachment = IIF(Attachments = 0, 0, 1)

	'如果修改的是帖子，则更新帖子信息
	If PostInfo(1, 0) = 1 Then
		RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = "& DisplayOrder &", title = '"& Title &"', iflocked = "& IfLocked &", ifattachment = "& IfAttachment &" WHERE tid = "& PostInfo(0, 0))
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET ifattachment = "& IfAttachment &" WHERE tid = "& PostInfo(0, 0))
	End If

	Call closeDatabase()
	Call RQ.showTips("编辑完毕。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& PostInfo(0, 0), "")
End Sub

'========================================================
'删除帖子(回复)
'========================================================
Sub DeletePost()
	Dim PostID, PostInfo, blnDeleteTopic
	Dim AttachListArray, Attachments, IfAttachment, Posts, strSQL

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.tid, p.iffirst, p.uid, p.username, t.displayorder, t.title, t.special, t.leagueid, t.iftask, t.disablemodify FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.fid = "& RQ.ForumID)

	If Not IsArray(PostInfo) Then
		Call RQ.showTips("内容不存在或者已经被删除。", "", "")
	End If

	If PostInfo(2, 0) <> RQ.UserID Then
		Call RQ.showTips("只有作者自己才能编辑内容。", "", "")
	End If

	'帖子(回复)是否允许被编辑
	Select Case PostInfo(9, 0)
		Case 1
			If PostInfo(1, 0) = 1 Then
				Call RQ.showTips("由于帖子被鉴定或者其他方面的原因，该帖子不允许编辑。", "", "")
			End If
		Case 2
			Call RQ.showTips("由于帖子类型特殊(例如悬赏贴)或者其他方面的原因，该帖子不允许编辑。", "", "")
	End Select

	If PostInfo(1, 0) = 1 Then
		'设置读取附件的字段
		strSQL = "tid = "& PostInfo(0, 0)

		'删除帖子
		RQ.Execute("DELETE FROM "& TablePre &"topics WHERE tid = "& PostInfo(0, 0))

		'删除回复
		RQ.Execute("DELETE FROM "& TablePre &"posts WHERE tid = "& PostInfo(0, 0))

		'更新版面的帖子总数
		RQ.Execute("UPDATE "& TablePre &"forums SET topics = topics - 1 WHERE fid = "& RQ.ForumID)

		'删除用户收藏贴记录
		RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE tid = "& PostInfo(0, 0))

		'删除置顶帖记录
		If PostInfo(4, 0) > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"sticktopics WHERE tid = "& PostInfo(0, 0))
		End If

		Select Case PostInfo(6, 0)
			'投票帖子
			Case 1
				RQ.Execute("DELETE FROM "& TablePre &"polls WHERE tid = "& PostInfo(0, 0))
				RQ.Execute("DELETE FROM "& TablePre &"polloptions WHERE tid = "& PostInfo(0, 0))
		End Select

		'删除联盟贴记录
		If PostInfo(7, 0) > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE tid = "& PostInfo(0, 0))
		End If

		'删除限时置顶的记录
		If PostInfo(8, 0) > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& PostInfo(0, 0))
		End If

		'记录操作
		Call RQ.SetLog(PostInfo(2, 0), PostInfo(3, 0), dfc(PostInfo(5, 0)), "自己删帖")

		'更新版面缓存中的帖子总数
		RQ.Forum_Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder >= 0")(0)
		dbQueryNum = dbQueryNum + 1

		RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& RQ.Forum_Topics &" WHERE fid = "& RQ.ForumID)
		Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics)

		blnDeleteTopic = True
	Else
		'设置读取附件的字段
		strSQL = "pid = "& PostID

		'删除回复
		RQ.Execute("DELETE FROM "& TablePre &"posts WHERE pid = "& PostID)

		'重新统计回复数量
		Posts = Conn.Execute("SELECT COUNT(pid) - 1 FROM "& TablePre &"posts WHERE tid = "& PostInfo(0, 0))(0)

		'发言是否有附件
		Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE pid = "& PostID)(0)
		IfAttachment = IIF(Attachments = 0, 0, 1)

		'更新版面回复统计
		RQ.Execute("UPDATE "& TablePre &"topics SET posts = "& Posts &", ifattachment = "& IfAttachment &" WHERE tid = "& PostInfo(0, 0))
	End If

	'读取附件
	AttachListArray = RQ.Query("SELECT savepath, ifthumb FROM "& TablePre &"attachments WHERE "& strSQL)

	'删除附件
	If IsArray(AttachListArray) Then
		For i = 0 To UBound(AttachListArray, 2)
			Call DeleteFile(RQ.Attach_Settings(0) &"/"& AttachListArray(0, i))

			'删除缩略图
			If AttachListArray(1, i) = 1 Then
				Call DeleteFile(RQ.Attach_Settings(0) &"/"& AttachListArray(0, i) &".thumb."& GetFileExt(AttachListArray(0, i)))
			End If
		Next

		RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE "& strSQL)
	End If

	Call closeDatabase()

	'根据删除的是帖子还是回复显示提示页面
	If blnDeleteTopic Then
		Call RQ.showTips("帖子删除完毕。", "", "HALTED")
	Else
		Call RQ.showTips("您的回复已经成功删除。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& PostInfo(0, 0), "")
	End If
End Sub

'========================================================
'编辑帖子/回复界面
'========================================================
Sub Main()
	Dim PostID, PostInfo, AttachListArray, FileExt

	PostID = SafeRequest(3, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.iffirst, p.uid, p.username, p.message, p.ifanonymity, p.ifattachment, t.tid, t.fid, t.title, t.iflocked, t.disablemodify FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.displayorder >= 0")

	If Not IsArray(PostInfo) Then
		Call RQ.showTips("回复不存在或者已经被删除。", "", "")
	End If

	'验证当前用户是否是发言人
	If PostInfo(1, 0) <> RQ.UserID Then
		If PostInfo(4, 0) > 0 Then
			'如果发言用户匿名则显示匿名道具
			Call closeDatabase()
			Response.Redirect "item.asp?action=topicitem&op=anonymity&pid="& PostID
		Else
			'否则显示用户信息
			Call closeDatabase()
			Response.Redirect "profile.asp?uid="& PostInfo(1, 0) &"&pid="& PostID
		End If
	End If

	'如果回复有附件标记则读取附件
	If PostInfo(5, 0) = 1 Then
		AttachListArray = RQ.Query("SELECT aid, filename, filesize, savepath, downloads, description FROM "& TablePre &"attachments WHERE pid = "& PostID &" ORDER BY posttime ASC")
		Call Include("./include/attachment.inc.asp")
	End If

	Call closeDatabase()

	'帖子/回复是否允许被编辑
	Select Case PostInfo(10, 0)
		Case 1
			If PostInfo(0, 0) = 1 Then
				Call RQ.showTips("由于帖子被鉴定或者其他方面的原因，该帖子不允许编辑。", "", "")
			End If
		Case 2
			Call RQ.showTips("由于帖子类型特殊(例如悬赏贴)或者其他方面的原因，该帖子不允许编辑。", "", "")
	End Select

	RQ.Header()
%>
<body>
<form name="tmodify" method="post" action="?action=submitmodify" onKeyDown="fastpost('btnsubmit', event);">
  <input type="hidden" name="fid" value="<%= PostInfo(7, 0) %>" />
  <input type="hidden" name="pid" value="<%= PostID %>" />
  <table class="tipsborder" cellspacing="0" cellpadding="0" align="center">
    <tr>
      <td class="transborder" width="8">&nbsp;</td>
      <td class="transborder">&nbsp;</td>
      <td class="transborder" width="8">&nbsp;</td>
    </tr>
    <tr>
      <td class="transborder" width="8">&nbsp;</td>
      <td class="tipstd"><div class="mainarea">
          <div class="tipstd_bottom"></div>
          <div class="tips_header">
            <h1>编辑帖子/回复</h1>
          </div>
          <table width="100%" cellspacing="0" cellpadding="0" class="tbborder">
		    <% If PostInfo(0, 0) = 1 Then '如果编辑的是帖子则显示标题 %>
            <tr>
              <td width="20%">标题:</td>
              <td><input type="text" name="title" size="50" class="inputgrey" value="<%= strFilter(PostInfo(8, 0)) %>" /></td>
            </tr>
			<% End If %>
            <tr>
              <td width="20%">内容:</td>
              <td style="padding: 8px 10px;"><% If InStr(RQ.Topic_Settings(17), "edit") > 0 And RQ.blnAllowHTML(PostInfo(7, 0)) Then %><input type="hidden" id="message" name="message" value="<%= strFilter(PostInfo(3, 0)) %>" style="display:hidden" /><input type="hidden" id="content___Config" value="" style="display:none" /><iframe id="content___Frame" src="include/editor/editor/fckeditor.html?InstanceName=message" width="100%" height="200" frameborder="0" scrolling="no"></iframe><% Else %><span id="editorzone"><textarea name="message" id="message" rows="10" class="textareagrey"><%= strFilter(Preg_Replace(PostInfo(3, 0), "<br(.*?)>", vbCrLf)) %></textarea><% If RQ.blnAllowHTML(PostInfo(7, 0)) Then %><a href="javascript:displayeditor();" class="bluelink">编辑器</a><% End If %></span><% End If %></td>
            </tr>
            <tr>
              <td width="20%">选项:</td>
              <td><% If PostInfo(9, 0) < 2 And PostInfo(0, 0) = 1 Then %><select name="iflocked">
                  <option value="0"<% If PostInfo(9, 0) = 0 Then Response.Write " selected" End If %>>允许回复</option>
                  <option value="1"<% If PostInfo(9, 0) = 1 Then Response.Write " selected" End If %>>不允许回复</option>
                </select><% End If %>
				<% If RQ.blnAllowHTML(PostInfo(7, 0)) Then %><input type="checkbox" name="disable_autowap" id="disable_autowap" value="1" onclick="f_autowap();" /><label for="disable_autowap">不自动换行</label><% End If %>
				<input type="checkbox" name="ifparseurl" id="ifparseurl" value="1" checked /><label for="ifparseurl">识别网址和图片</label>
				<% If PostInfo(4, 0) > 0 Then %><span style="padding-left: 10px;"><a href="###" onclick="postvalue('item.asp?action=useitem&pid=<%= PostID %>', 'itemid', '22');" class="underline">用个面子</a></span><% End If %>
				<span id="spanButtonPlaceholder"></span></td>
            </tr>
            <tr>
          </table>
        </div></td>
      <td class="transborder" width="8">&nbsp;</td>
    </tr>
    <tr>
      <td class="transborder" width="8">&nbsp;</td>
      <td class="transborder">&nbsp;</td>
      <td class="transborder" width="8">&nbsp;</td>
    </tr>
  </table>
  <% If IsArray(AttachListArray) Then %>
  <br />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0 auto;">
    <tr class="header">
      <td colspan="6"><strong>附件列表</strong></td>
    </tr>
    <tr class="category">
      <td>删</td>
      <td>编号</td>
      <td>附件名称</td>
      <td>附件尺寸</td>
      <td>下载</td>
      <td>描述</td>
    </tr>
    <% For i = 0 To UBound(AttachListArray, 2) %>
	<% If InStr(AttachListArray(1, i), ".") > 0 Then
		FileExt = LCase(Right(AttachListArray(1, i), Len(AttachListArray(1, i)) - InstrRev(AttachListArray(1, i), ".")))
	End If %>
    <tr>
      <td><input type="checkbox" name="d_aid" value="<%= AttachListArray(0, i) %>" />
        <input type="hidden" name="aid" value="<%= AttachListArray(0, i) %>" /></td>
      <td><%= AttachListArray(0, i) %></td>
      <td><a href="javascript:insert_attach(<%= AttachListArray(0, i) %>);" class="underline">[插入]</a>
        <img src="images/attachicons/<%= ShowFileType(FileExt) %>" align="absmiddle" />
        <a href="attachment.asp?action=get&aid=<%= AttachListArray(0, i) %>" class="underline" title="<%= AttachListArray(1, i) %>" target="_blank"><%= Left(AttachListArray(1, i), 20) %></a></td>
      <td><%= ShowFileSize(AttachListArray(2, i)) %></td>
      <td><%= AttachListArray(4, i) %></td>
      <td><input type="text" name="description" value="<%= AttachListArray(5, i) %>" size="15" class="inputgrey" /></td>
    </tr>
    <% Next %>
  </table>
  <% End If %>
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" style="margin: 0 auto;">
    <tr>
      <td><div id="fsUploadProgress"></div></td>
    </tr>
  </table>
  <p align="center"><input type="submit" name="btnsubmit" id="btnsubmit" value="提交修改" class="button" />
    <input type="submit" name="btndelete" id="btndelete" value="删除<%= IIF(PostInfo(0, 0) = 1, "帖子", "回复") %>" class="button" onclick="javascript:if(!confirm('是否确定删除？')) return false;" /></p>
</form>
<% If RQ.AllowPostAttach Then %>
<link href="js/swfupload/default.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="js/ajax.js"></script>
<script type="text/javascript" src="js/swfupload/swfupload.js"></script>
<script type="text/javascript" src="js/swfupload/swfupload.queue.js"></script>
<script type="text/javascript">
var upload;
window.onload = function() {
	upload = new SWFUpload({
		upload_url: "attachment.asp?action=upload&uc=<%= Server.URLEncode(RQ.UserCode) %>",
		file_size_limit : "<%= IIF(RQ.MaxAttachSize = 0, 100 * 1024, RQ.MaxAttachSize) %>",
		file_types : "<%= IIF(Len(RQ.AttachExtensions) = 0, "*.*", Replace("*."& RQ.AttachExtensions, ",", ";*.")) %>",
		file_types_description : "附件文件",
		file_upload_limit : "10",
		file_queue_limit : "10",
		file_dialog_start_handler : fileDialogStart,
		file_queued_handler : fileQueued,
		file_queue_error_handler : fileQueueError,
		file_dialog_complete_handler : fileDialogComplete,
		upload_start_handler : uploadStart,
		upload_progress_handler : uploadProgress,
		upload_error_handler : uploadError,
		upload_success_handler : uploadSuccess,
		upload_complete_handler : uploadComplete,
		button_placeholder_id : "spanButtonPlaceholder",
		button_width: 140,
		button_height: 18,
		button_text : '<span class="underline">上传附件(<%= IIF(RQ.MaxAttachSize = 0, "100MB", RQ.MaxAttachSize &"KB") %>以内)</span>',
		button_text_style : '.underline{text-decoration:underline;color:#0099ff;}',
		button_window_mode: SWFUpload.WINDOW_MODE.TRANSPARENT,
		button_cursor: SWFUpload.CURSOR.HAND,
		flash_url : "js/swfupload/swfupload.swf",
		custom_settings : {
			progressTarget : "fsUploadProgress",
			cancelButtonId : "btnCancel"
		},
		debug: false
	});
 }
</script>
<% End If %>
<script type="text/javascript">f_autowap();</script>
<%
	RQ.Footer()
End Sub
%>