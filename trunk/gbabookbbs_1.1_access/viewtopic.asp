﻿<!--#include file="include/inc.asp"-->
<%
Dim TopicInfo, ViewAuthorID
Dim strSQL, strPre, strAddon, PostListArray, CountArray
Dim Page, PageCount, RecordCount
Dim strErrTips, FloorAddtion, theFloorNumber
Dim Dic, regExpSearch

TopicInfo = RQ.Query("SELECT fid, displayorder, uid, username, usershow, title, posttime, lastupdate, posts, special, price, ifanonymity, iflocked, iftask, ifattachment FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID)

If Not IsArray(TopicInfo) Then
	Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
End If

'检查版面id是否正确
If TopicInfo(0, 0) <> RQ.ForumID Then
	Call closeDatabase()
	Response.Redirect "?fid="& TopicInfo(0, 0) &"&tid="& RQ.TopicID
	Response.End()
End If

Select Case TopicInfo(1, 0)
	Case -1
		'未通过审核的帖子只有管理员和楼主可以浏览和回复
		If RQ.UserID = 0 Or (Not RQ.IsModerator And RQ.UserID <> TopicInfo(2, 0)) Then 
			Call RQ.showTips("该帖还没有通过审核，请等待管理员审核帖子。", "", "NOPERM")
		End If
	Case -2
		If Not RQ.IsModerator Then
			Call RQ.showTips("帖子已经被删除。", "", "")
		End If
End Select

'如果帖子设置了金钱限制,则检查金钱是否足够
If TopicInfo(10, 0) > 0 Then
	If Not RQ.IsModerator Then
		If RQ.UserCredits < TopicInfo(10, 0) And RQ.UserID <> TopicInfo(2, 0) Then 
			Call RQ.showTips(RQ.Other_Settings(0) &"达到"& TopicInfo(10, 0) &"才能查看该帖。", "", "NOPERM")
		End If
	End If
End If

'检查置顶是否到期
If TopicInfo(13, 0) = 1 Then
	Dim TaskInfo
	TaskInfo = RQ.Query("SELECT expirytime FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)

	If IsArray(TaskInfo) Then			
		If TaskInfo(0, 0) < Now() Then
			'去除置顶
			Call RQ.UpdateStickTopic(RQ.ForumID, RQ.TopicID, 0)

			RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 0, iftask = 0 WHERE tid = "& RQ.TopicID)
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
		End If
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET iftask = 0 WHERE tid = "& RQ.TopicID)
	End If
End If

'只看作者
ViewAuthorID = SafeRequest(3, "authorid", 0, 0, 0)
If ViewAuthorID = 0 Then
	RecordCount = TopicInfo(8, 0)
Else
	RecordCount = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" AND uid = "& ViewAuthorID &" AND ifanonymity = 0")(0)
	strAddon = " AND p.uid = "& ViewAuthorID &" AND p.ifanonymity = 0"
End If

RecordCount = IIF(RecordCount = 0, 1, RecordCount)
Page = SafeRequest(3, "page", 0, 1, 0)
PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(4)))))
Page = IIF(Page > PageCount, PageCount, Page)
RQ.UserViewTopicStyle = IIF(RQ.UserViewTopicStyle > 0, RQ.UserViewTopicStyle, IntCode(RQ.Topic_Settings(5)))

'根据显示样式读取数据库
If RQ.UserViewTopicStyle = 0 Then
	strPre = " p.pid, p.iffirst, p.uid, p.username, p.usershow, p.message, p.posttime, p.ifanonymity, p.ratemark, p.ifattachment FROM gb_posts p"
Else
	strPre = " p.pid, p.iffirst, p.uid, p.username, p.usershow, p.message, p.posttime, p.ifanonymity, p.ratemark, p.ifattachment, m.designation, m.avatar FROM "& TablePre &"posts p LEFT JOIN "& TablePre &"memberfields m ON p.uid = m.uid"
End If

'连接sql语句
If Page = 1 Then
	strSQL = "SELECT TOP "& IntCode(RQ.Topic_Settings(4)) + 1 & strPre &" WHERE p.tid = "& RQ.TopicID & strAddon &" ORDER BY p.posttime ASC"
	FloorAddtion = 0
Else
	strSQL = "SELECT TOP "& RQ.Topic_Settings(4) & strPre &" WHERE p.tid = "& RQ.TopicID & strAddon &" AND p.posttime > (SELECT MAX(posttime) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(4)) * (Page - 1) + 1 &" posttime FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID & strAddon &" ORDER BY posttime ASC) AS tblTemp) ORDER BY p.posttime ASC"
	FloorAddtion = 1
End If

'查询回复
PostListArray = RQ.Query(strSQL)
If Not IsArray(PostListArray) Then
	Call RQ.showTips("帖子出错。", "", "")
End If

'读取投票信息
If TopicInfo(9, 0) = 1 Then
	Call Include("./include/poll.inc.asp")
	PostListArray(5, 0) = PostListArray(5, 0) & getPollContent()
End If

'读取附件内容
If TopicInfo(14, 0) = 1 Then
	Call Include("./include/attachment.inc.asp")
	Call ReadAttachments()
End If

'更新帖子点击量
RQ.Execute("UPDATE "& TablePre &"topics SET clicks = clicks + 1 WHERE tid = "& RQ.TopicID)

'========================================================
'显示金钱达到某数量可见内容
'========================================================
Function ShowCreditsHidden(str)
	Dim regEx, Matches, Match, TEMP, n
	Set regEx = New Regexp
	regEx.IgnoreCase = True
	regEx.Global = True
	regEx.Pattern = "\[hide=(\d+)\](.+?)\[\/hide\]"
	Set Matches = regEx.Execute(str)
	For Each Match In Matches
		If RQ.UserCredits < IntCode(Match.SubMatches(0)) And Not RQ.IsModerator Then
			str = regEx.Replace(str, "<div class=""viewdenied"" style=""width: 300px;"">本帖隐藏的内容需要"& RQ.Other_Settings(0) &"达到$1才可以浏览</div>")
		Else
			str = regEx.Replace(str, "<div class=""viewdenied"">本帖隐藏的内容需要"& RQ.Other_Settings(0) &"达到$1才可以浏览：<br /><span class=""pink"">$2</span></div>")
		End If
	Next
	Set regEx = Nothing
	ShowCreditsHidden = str
End Function

'显示标题
RQ.PageTitle = TopicInfo(5, 0)
RQ.Header()
%>
<body>
<% If TopicInfo(1, 0) = -1 Then %><div class="warning"><strong>提示：该帖处于待审核状态。</strong></div><% End If %>
<a href="managetopic.asp?action=manageposts&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&page=<%= Page %>"><%= TopicInfo(5, 0) %></a>
<a href="#" target="_blank">【新窗打开】</a>
<hr color="black" />
<%
'计算数组下标
CountArray = UBound(PostListArray, 2)

For i = 0 To CountArray
	If InStr(PostListArray(5, i), "[/hide]") > 0 Then
		'回复可见内容
		If InStr(PostListArray(5, i), "[hide]") > 0 Then
			If Not Conn.Execute("SELECT TOP 1 1 FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" AND "& IIF(RQ.UserID > 0, "uid = "& RQ.UserID, "uid = 0 AND userip = '"& RQ.UserIP &"'")).EOF Then
				PostListArray(5, i) = Preg_Replace(PostListArray(5, i), "\[hide\](.+?)\[\/hide\]", "<div class=""viewdenied"">本帖隐藏的内容需要回复才可以浏览：<br /><span class=""pink"">$1</span></div>")
			Else
				PostListArray(5, i) = Preg_Replace(PostListArray(5, i), "\[hide\](.+?)\[\/hide\]", "<div class=""viewdenied"" style=""width: 300px;"">本帖隐藏的内容需要回复才可以浏览</div>")
			End If
			dbQueryNum = dbQueryNum + 1
		End If

		'金钱达到某数量可见内容
		If InStr(PostListArray(5, i), "[hide=") > 0 Then
			PostListArray(5, i) = ShowCreditsHidden(PostListArray(5, i))
		End If
	End If

	'读取附件
	If PostListArray(9, i) = 1 Then
		PostListArray(5, i) = ShowAttachments(PostListArray(0, i), PostListArray(5, i))	
	End If

	'楼层
	theFloorNumber = IntCode(RQ.Topic_Settings(4)) * (Page - 1) + i + FloorAddtion

	'显示样式
	If RQ.UserViewTopicStyle = 0 Then
		'简洁样式
		If PostListArray(1, i) = 0 Then
			If ViewAuthorID = 0 Then
				'是否是楼主回复
				If PostListArray(7, i) = 0 And TopicInfo(2, 0) = PostListArray(2, i) And TopicInfo(2, 0) > 0 Then
					Response.Write "<span class=""red""><strong>【楼主】</strong></span>"
				End If

				Response.Write "<a href=""#quot"" onclick=""showquot('"& theFloorNumber &"', '"& IIF(PostListArray(7, i) = 0, PostListArray(3, i), PostListArray(4, i)) &"', '"& PostListArray(0, i) &"');"" class=""bluelink"">回复</a>("& theFloorNumber &"):"
			Else
				Response.Write "<a href=""#quot"" onclick=""showquot('', '"& PostListArray(3, i) &"', '"& PostListArray(0, i) &"');"" class=""bluelink"">回复</a>(*):"
			End If
			Response.Write "<span title="""& PostListArray(6, i) &""" id=""pid"& PostListArray(0, i) &""">"& PostListArray(5, i) &"</span><br />"
		Else
			Response.Write PostListArray(5, i) &"<br />"
		End If

		'是否游客发言
		If PostListArray(2, i) > 0 Then
			If PostListArray(7, i) = 0 Then
				Response.Write "<a href=""pm.asp?action=send&u="& PostListArray(3, i) &""" onclick=""return shows(this.href);"">---</a><a href=""topicedit.asp?pid="& PostListArray(0, i) &""" class=""showun"" onclick=""return shows3(this.href);"">"& PostListArray(4, i) &"</a>"
			Else
				Response.Write "---<a href=""topicedit.asp?pid="& PostListArray(0, i) &""" class=""showun"" onclick=""return shows3(this.href);"">"& PostListArray(4, i) &"</a>"
			End If
		Else
			Response.Write "---<span class=""showun""><em>"& PostListArray(4, i) &"</em></span>"
		End If

		'只看该人
		If PostListArray(2, i) > 0 And PostListArray(7, i) = 0 Then
			Response.Write " <a href=""?fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&authorid="& PostListArray(2, i) &""" title=""只看该作者"" class=""smile"">J</a>"
		End If

		'如果赠送金钱则显示赠送数量
		If PostListArray(8, i) > 0 Then
			Response.Write " <span class=""underline"">+"& PostListArray(8, i) &"</span>"
		End If

		If i <> CountArray Then
			Response.Write RQ.Topic_Settings(6)
		End If
	Else
		'带头像的样式
		Response.Write "<div class=""thepost"& IIF(i <> CountArray, " btborder", "") &" bg"& i Mod 2 &"""><div class=""floor""><a href=""#quot"" onclick=""showquot('"& theFloorNumber &"', '"& IIF(PostListArray(7, i) = 0, PostListArray(3, i), PostListArray(4, i)) &"', '"& PostListArray(0, i) &"');"">"& IIF(Page = 1 And i = 0, "楼主", theFloorNumber &"楼") &"</a></div>"

		If PostListArray(7, i) = 0 Then
			If PostListArray(2, i) > 0 Then
				Response.Write "<a href=""?fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&authorid="& PostListArray(2, i) &""" class=""avatar""><img src="""& IIF(Len(PostListArray(11, i)) > 0, "avatars/"& PostListArray(11, i), "images/common/noavatar.jpg") &""" class=""avatar"" align=""absmiddle"" /></a> <a href=""topicedit.asp?pid="& PostListArray(0, i) &""" class=""author"" onclick=""return shows3(this.href);"">"& PostListArray(3, i) &"</a>"& IIF(Len(PostListArray(10, i)) > 0, " <span class=""des"">("& PostListArray(10, i) &")</span>", "")
			Else
				Response.Write "<img src=""images/common/noavatar.jpg"" class=""avatar"" align=""absmiddle"" /> <a class=""guest"">"& PostListArray(3, i) &"</a>"
			End If		
		Else
			Response.Write "<img src=""images/common/noavatar.jpg"" class=""avatar"" align=""absmiddle"" />&nbsp;<a href=""topicedit.asp?pid="& PostListArray(0, i) &""" onclick=""return shows3(this.href);"">"& PostListArray(4, i) &"</a>"
		End If

		Response.Write "<div class=""postmsg"" id=""pid"& PostListArray(0, i) &""" title="""& PostListArray(6, i) &""">"& PostListArray(5, i) &"</div></div>"
	End If
Next

Call closeDataBase()

Erase PostListArray
Set Dic = Nothing
Set regExpSearch = Nothing

If PageCount > 1 Then
	Call ShowPageInfo(Page, PageCount, RecordCount, "&fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&authorid="& ViewAuthorID)
End If

If ViewAuthorID > 0 Then
	Response.Write "<div class=""viewauthor"">当前的浏览模式为查看某用户的发言，<a href=""?fid="& RQ.ForumID &"&tid="& RQ.TopicID &""" class=""bluelink"">点击这里查看完整帖子</a></div>"
End If
%>
<p>
<hr color="black" />
<% If RQ.UserID > 0 Then %>
【<a href="topiccp.asp?action=favorites&tid=<%= RQ.TopicID %>" onClick="return shows2(this.href)">收藏</a>&nbsp;<% If RQ.Item_Settings(0) = "1" And RQ.AllowUseItem = 1 Then %><a href="item.asp?action=topicitem&tid=<%= RQ.TopicID %>" onClick="return shows(this.href)">道具</a>&nbsp;<% End If %><a href="topiccp.asp?tid=<%= RQ.TopicID %>" onClick="return shows(this.href);" class="bluelink">举报</a>&nbsp;<a href="#" target="_blank">新窗打开</a>】【<a href="managetopic.asp?action=manageposts&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&page=<%= Page %>">管理回复</a><% If RQ.IsModerator And RQ.AllowManageTopic = 1 Then %>&nbsp;<a href="managetopic.asp?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>">管理帖子</a><% End If %>】
<% If RQ.UserLeagueGroupID = 1 Then %>【<a href="topiccp.asp?action=leagueelite&tid=<%= RQ.TopicID %>" onClick="return shows(this.href);">加入精华区</a>】<% End If %>
<% If RQ.UserLeagueGroupID = 1 Or RQ.UserLeagueGroupID = 2 Then %>【<a href="topiccp.asp?action=leaguetopic&tid=<%= RQ.TopicID %>" onClick="return shows(this.href);">联盟</a>】<% End If %>
<% End If %>
<p>
<script type="text/javascript">
document.body.ondblclick = function(){
	if (parent.$('<%= CacheName %>bodys')){
		parent.$('<%= CacheName %>bodys').cols = parent.$('<%= CacheName %>bodys').cols !== "0,100%" ? "0,100%" : "50%,50%";
	}
}
</script>
<%
'当前用户组是否允许回帖
If RQ.AllowReply = 0 Then
	Call showErr("您目前的身份是"& RQ.UserGroupName &"，还不能回帖子哟。")
End If

'当前用户组在当前版面是否允许回帖
If Len(RQ.Forum_PostReplyPerm) = 0 Then
	If RQ.UserID = 0 Then
		Call showErr("您现在是游客，登录之后才能回帖。")
	End If
Else
	If Not InStr(","& RQ.Forum_PostReplyPerm &",", ","& RQ.UserGroupID &",") > 0 Then
		Call showErr("您当前的身份("& RQ.UserGroupName &")不能在“"& RQ.Forum_Name &"”版回帖……")
	End If
End If

'当前版面对回帖子要求的最低金钱限制
If RQ.F_ReplyNdCredits > 0 And RQ.UserCredits < RQ.F_ReplyNdCredits And RQ.DisablePostCtrl = 0 Then
	Call showErr(RQ.Other_Settings(0) &"达到"& RQ.F_ReplyNdCredits &"就可以回帖了哟，加油！")
End If

'当前版面是否允许回帖
If RQ.F_AllowPost = 0 And RQ.DisablePostCtrl = 0 Then
	Call showErr("当前版面为只读……")
End If

'帖子是否允许回复
If TopicInfo(12, 0) > 0 Then 
	Call showErr("该帖被设为不允许回复。")
End If

'站点是否允许回帖
If RQ.CheckTimeSetting(RQ.Time_Settings(1)) And RQ.DisablePeriodCtrl = 0 Then
	Call showErr("在以下的时间段里，论坛处于只读状态：<br />"& Replace(RQ.Time_Settings(1), "_", "<br />"))
End If

'帖子是否过期
If ABS(RQ.F_AutoClose) > 0 And RQ.DisablePostCtrl = 0 Then
	If RQ.F_AutoClose < 0 Then
		If DateDiff("d", TopicInfo(6, 0), Now()) > ABS(RQ.F_AutoClose) Then
			Call showErr("该帖子已经过期，禁止回复。")
		End If
	Else
		If DateDiff("d", TopicInfo(7, 0), Now()) > RQ.F_AutoClose Then
			Call showErr("该帖子已经过期，禁止回复。")
		End If
	End If
End If

'是否连续灌水
If IntCode(RQ.Topic_Settings(10)) > 0 And DateDiff("s", NumtoDate(RQ.UserPostFloodCtrl), Now()) < 0 And RQ.DisablePostCtrl = 0 Then
	Call showErr("现在的时间："& FormatDateTime(Now(), 3) &"，可发言时间："& FormatDateTime(NumtoDate(RQ.UserPostFloodCtrl), 3) &"，请先看看别的帖子……")
End If
%>
<strong>回帖子</strong>
<div id="quot"></div>
<form name="newreply" method="post" action="post.asp?action=newreply" onkeydown="fastpost('btnsubmit');" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>" />
  <input type="hidden" name="fid" value="<%= RQ.ForumID %>" />
  <input type="hidden" id="quot_message" name="quot_message" value="" />
  <p>
    <% If Len(RQ.UserName) = 0 Then %>
    游客名字:<input type="text" name="username" size="19" maxlength="10">
    限制在10个字符以内<br />
    <% End If %>
	<% If RQ.blnAllowHTML(0) Then %><script type="text/javascript" src="include/editor/fckeditor.js"></script><script type="text/javascript"></script><% End If %>
    回复内容:<% If InStr(RQ.Topic_Settings(17), "reply") > 0 And RQ.blnAllowHTML(0) Then %><input type="hidden" id="message" name="message" /><input type="hidden" id="content___Config" value="" style="display:none" /><iframe id="content___Frame" src="include/editor/editor/fckeditor.html?InstanceName=message" width="400" height="200" frameborder="0" scrolling="no"></iframe><% Else %><span id="editorzone"><textarea name="message" id="message" style="width: 275px; height: 65px;"></textarea><% If RQ.blnAllowHTML(0) Then %><a href="javascript:displayeditor();" class="bluelink">编辑器</a></span><% End If %><% End If %>
    <% If RQ.UserID > 0 Then %>
    <span id="face_preview"></span>
	<br />
    相关链接:<input type="text" name="aboutlink" maxlength="255" size="43" value="http://" />
    <br />
    相关图片:<input type="text" name="imglink" maxlength="255" size="43" value="http://" /><span id="spanButtonPlaceholder"></span>
    <br />
    <a href="htmls/face.htm" target="_blank" class="bluelink">表情</a>
    <select name="face1" id="face1" onChange="preview_face();">
      <option value="0">0</option>
      <option value="1">1</option>
      <option value="2">2</option>
      <option value="3">3</option>
      <option value="4">4</option>
      <option value="5">5</option>
      <option value="6">6</option>
      <option value="7">7</option>
      <option value="8">8</option>
      <option value="9">9</option>
    </select><select name="face2" id="face2" onChange="preview_face();">
      <option value="0">0</option>
      <option value="1">1</option>
      <option value="2">2</option>
      <option value="3">3</option>
      <option value="4">4</option>
      <option value="5">5</option>
      <option value="6">6</option>
      <option value="7">7</option>
      <option value="8">8</option>
      <option value="9">9</option>
    </select><select name="face3" id="face3" onChange="preview_face();">
      <option value="0">0</option>
      <option value="1">1</option>
      <option value="2">2</option>
      <option value="3">3</option>
      <option value="4">4</option>
      <option value="5">5</option>
      <option value="6">6</option>
      <option value="7">7</option>
      <option value="8">8</option>
      <option value="9">9</option>
    </select>
    <% If RQ.UserCredits >= IntCode(RQ.F_AnonymityNdCredits) Or RQ.F_AnonymityNdCredits = 0 Then %>
    <input type="checkbox" name="ifanonymity" id="ifanonymity" value="1" /><label for="ifanonymity">匿名</label>
    <% End If %>
    <input type="checkbox" name="disable_update" id="disable_update" value="1" /><label for="disable_update">不UP!</label>
    <input name="disable_autowap" id="disable_autowap" type="checkbox" value="1" onclick="f_autowap();" /><label for="disable_autowap">不自动换行</label>
    <input type="checkbox" name="sig" id="sig" value="1" checked /><label for="sig">签名</label><br />
    <% If TopicInfo(2, 0) > 0 Then %>
    回帖时送
    <input name="sendcredits" type="text" size="5" />
    <%= RQ.Other_Settings(0) %>给<span class="underline"><%= IIF(TopicInfo(11, 0) > 0, TopicInfo(4, 0), TopicInfo(3, 0)) %></span>
    <% End If %>
    <% End If %>
    <br />
	<div id="fsUploadProgress"></div>
    <br />
    <input type="submit" name="submit" id="btnsubmit" value="提交回复" class="button" />
	<% If RQ.UserID = 0 And RQ.AllowPostAttach Then %><span id="spanButtonPlaceholder"></span><% End If %>
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
		upload_url: "attachment.asp?action=upload",
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
		button_width: 135,
		button_height: 18,
		button_text : '<span class="underline">上传附件(<%= IIF(RQ.MaxAttachSize = 0, "100MB", RQ.MaxAttachSize &"KB") %>以内)</span>',
		button_text_style : '.underline{text-decoration:underline;}',
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
<p><span class="blue">回帖请遵守本站规则，如果您不是很清楚建议您仔细阅读<a href="htmls/help.html" target="_blank"><span class="blue underline">用户必读</span></a>。</span>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<%
RQ.Footer()
%>
