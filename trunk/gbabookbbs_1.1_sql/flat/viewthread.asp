<!--#include file="../include/inc.asp"-->
<%
Call Main()

'========================================================
'显示帖子内容
'========================================================
Sub Main()
	Dim TopicInfo, PostListArray
	Dim TopicTitle, ViewAuthorID, CountArray
	Dim Page, PageCount, RecordCount, strSQL, SqlAddition
	Dim strErrTips, strNav, FloorAddtion, theFloorNumber
	Dim Cmd, Dic, regExpSearch

	TopicInfo = RQ.Query("SELECT fid, displayorder, uid, username, usershow, title, posttime, lastupdate, posts, special, price, ifanonymity, iflocked, iftask, ifattachment FROM "& TablePre &"topics WITH(NOLOCK) WHERE tid = "& RQ.TopicID)

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

	TopicTitle = dfc(TopicInfo(5, 0))

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
	Page = SafeRequest(3, "page", 0, 1, 0)
	FloorAddtion = IIF(Page = 1, 0, 1)

	'读取帖子内容
	Set Cmd = Server.CreateObject("ADODB.Command")
	With Cmd
		.ActiveConnection = Conn
		.CommandType = 4
		.CommandText = TablePre &"sp_postlist"
		.Prepared = True
		.Parameters.Item("@tid").Value = RQ.TopicID
		.Parameters.Item("@viewauthorid").Value = ViewAuthorID
		.Parameters.Item("@viewstyle").Value = 1
		.Parameters.Item("@page").Value = Page
		.Parameters.Item("@posts").Value = TopicInfo(8, 0)
		.Parameters.Item("@pagesize").Value = IntCode(RQ.Topic_Settings(4))
		Set Rs = .Execute

		If Not Rs.EOF And Not Rs.BOF Then
			PostListArray = Rs.GetRows()
		Else
			PostListArray = 0
		End If
		RecordCount = .Parameters.Item(0)
		PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(4)))))
	End With
	Set Cmd = Nothing
	dbQueryNum = dbQueryNum + 1

	If Not IsArray(PostListArray) Then
		Call RQ.showTips("帖子出错。", "", "")
	End If

	'读取投票信息
	If TopicInfo(9, 0) = 1 And Page = 1 Then
		Call Include("../include/poll.inc.asp")
		PostListArray(5, 0) = PostListArray(5, 0) & getPollContent()
	End If

	'读取附件内容
	If TopicInfo(14, 0) = 1 Then
		Call Include("../include/attachment.inc.asp")
		Call ReadAttachments()
	End If

	'导航路径
	If RQ.Forum_ParentID = RQ.Forum_RootFID Then
		strNav = " &raquo; <a href=""forumdisplay.asp?fid="& RQ.ForumID &""">"& RQ.Forum_Name &"</a> &raquo; "& TopicTitle
	Else
		strNav = " &raquo; <a href=""forumdisplay.asp?fid="& RQ.Forum_ParentID &""">"& RQ.Get_Forum_Settings(RQ.Forum_ParentID, 1) &"</a> &raquo; <a href=""forumdisplay.asp?fid="& RQ.ForumID &""">"& RQ.Forum_Name &"</a> &raquo; "& TopicTitle
	End If

	Call closeDatabase()
	RQ.FlatHeader()
%>
<script src="include/javascript/viewthread.js" type="text/javascript"></script>
<script type="text/javascript">zoomstatus = parseInt(1);</script>
<div id="foruminfo">
<div id="nav"><a href="index.asp"><%= RQ.Base_Settings(0) %></a><%= strNav %></div>
<div id="headsearch"></div>
</div>
<div id="ad_text"></div>
<div class="pages_btns">
<div class="threadflow"><a href="redirect.asp?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&goto=nextoldset"> &lsaquo;&lsaquo; 上一主题</a> | <a href="redirect.asp?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&goto=nextnewset">下一主题 &rsaquo;&rsaquo;</a></div>
<% If PageCount > 1 Then Call ShowPageInfo(Page, PageCount, RecordCount, "&fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&authorid="& ViewAuthorID) End If %>
<span class="postbtn" id="newspecial" onmouseover="$('newspecial').id = 'newspecialtmp';this.id = 'newspecial';showMenu(this.id)"><a href="post.asp?action=newtopic&fid=<%= RQ.ForumID %>&extra=page%3D1"><img src="images/default/newtopic.gif" border="0" alt="发新话题" title="发新话题" /></a></span> <span class="replybtn"><a href="post.asp?action=reply&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&extra=page%3D1"><img src="images/default/reply.gif" border="0" alt="" /></a></span></div>
<ul class="popupmenu_popup newspecialmenu" id="newspecial_menu" style="display: none">
<li><a href="post.asp?action=newtopic&fid=<%= RQ.ForumID %>&extra=page%3D1">发新话题</a></li>
<li class="poll"><a href="post.asp?action=newtopic&fid=<%= RQ.ForumID %>&extra=page%3D1&special=1">发布投票</a></li>
</ul>
<form method="post" name="modactions">
<!-- posts loop begin -->
<% If IsArray(PostListArray) Then %>
<% For i = 0 To UBound(PostListArray, 2) %>
<div class="mainbox viewthread">
<% If PostListArray(1, i) = 1 Then %>
<span class="headactions"><a href="my.asp?item=favorites&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>" id="ajax_favorite" onclick="ajaxmenu(event, this.id, 3000, 0)">收藏</a> <a href="my.asp?item=subscriptions&subadd=<%= RQ.TopicID %>" id="ajax_subscription" onclick="ajaxmenu(event, this.id, 3000, null, 0)">订阅</a> <a href="###" target="_blank" class="notabs">道具</a></span>
<h1><%= TopicTitle %></h1>
<% End If %>
<table id="pid<%= PostListArray(0, i) %>" summary="pid<%= PostListArray(0, i) %>" cellspacing="0" cellpadding="0">
<tr>
<td class="postauthor"><cite>
<% If RQ.IsModerator Then %><label><a href="topicadmin.php?action=getip&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&pid=<%= PostListArray(0, i) %>" id="ajax_getip_<%= i %>" onclick="ajaxmenu(event, this.id, 10000, null, 0)" title="查看 IP">IP</a></label><% End If %>
<% If PostListArray(7, i) = 0 And PostListArray(10, i) > 0 Then %>
<a href="space.asp?uid=<%= PostListArray(10, i) %>" target="_blank" id="userinfo<%= i %>" class="dropmenu" onmouseover="showMenu(this.id)"><%= PostListArray(3, i) %></a>
</cite>
<div class="avatar"><img class="avatar" src="images/avatars/noavatar.jpg" alt="" /></div>
<ul>
<li class="space"><a href="space.asp?uid=<%= PostListArray(10, i) %>" target="_blank" title="<%= PostListArray(3, i) %>的个人空间">个人空间</a></li>
<li class="pm"><a href="pm.asp?action=send&uid=<%= PostListArray(10, i) %>" target="_blank" id="ajax_uid_<%= i %>" onclick="ajaxmenu(event, this.id, 9000000, null, 0)">发短消息</a></li>
</ul>
<% Else%>
<%= PostListArray(4, i) %></cite><% If PostListArray(7, i) = 1 Then %>该用户匿名发言<% Else %>游客<% End If %>
<% End If %>
</td>
<td class="postcontent" ondblclick="ajaxget('modcp.asp?action=editmessage&pid=<%= PostListArray(0, i) %>&tid=<%= RQ.TopicID %>', 'postmessage_<%= PostListArray(0, i) %>')"><div class="postinfo"> <strong title="复制帖子链接到剪贴板" id="postnum_<%= PostListArray(0, i) %>" onclick="setcopy('http://localhost/php/discuz6/viewthread.php?tid=<%= RQ.TopicID %>&page=<%= Page %>#pid<%= PostListArray(0, i) %>', '帖子链接已经复制到剪贴板')"><% If PostListArray(1, i) = 1 Then %>楼主<% Else %><%= IntCode(RQ.Topic_Settings(4)) * (Page - 1) + i + FloorAddtion %><sup>#</sup><% End If %></strong> <em onclick="$('postmessage_<%= PostListArray(0, i) %>').className='t_bigfont'">大</em> <em onclick="$('postmessage_<%= PostListArray(0, i) %>').className='t_msgfont'">中</em> <em onclick="$('postmessage_<%= PostListArray(0, i) %>').className='t_smallfont'">小</em> 发表于 <%= PostListArray(6, i) %>&nbsp; <% If ViewAuthorID = 0 Then %><% If PostListArray(7, i) = 0 And PostListArray(10, i) > 0 Then %><a href="?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&page=1&authorid=<%= PostListArray(10, i) %>">只看该作者</a><% End If %><% Else %><a href="?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>">显示全部帖子</a><% End If %></div>
<div id="ad_thread2_<%= i %>"></div>
<div class="postmessage defaultpost"> <span class="postratings"><a href="misc.php?action=viewratings&amp;tid=2&amp;pid=2" title="评分 1"><img src="images/default/agree.gif" border="0" alt="" /></a></span>
<div id="ad_thread3_<%= i %>"></div>
<div id="ad_thread4_<%= i %>"></div>
<% If PostListArray(1, i) = 1 Then %><h2><%= TopicTitle %></h2><% End If %>
<div id="postmessage_<%= PostListArray(0, i) %>" class="t_msgfont"><%= PostListArray(5, i) %></div>
</div>
</div>
</td>
</tr>
<tr>
<td class="postauthor">
<% If PostListArray(7, i) = 0 And PostListArray(10, i) > 0 Then %>
<div class="popupmenu_popup userinfopanel" id="userinfo<%= i %>_menu" style="display: none;">
<p><a href="space.asp?action=viewpro&uid=<%= PostListArray(10, i) %>" target="_blank">查看详细资料</a></p>
<p><a href="admincp.php?action=members&amp;username=admin&amp;searchsubmit=yes&amp;frames=yes" target="_blank">编辑用户</a></p>
<p><a href="admincp.php?action=banmember&amp;uid=1&amp;membersubmit=yes&amp;frames=yes" target="_blank">禁止用户</a></p>
</div>
<% End If %>
</td>
<td class="postcontent"><div class="postactions">
<input type="checkbox" name="pid" value="2" />
<p><a href="post.asp?action=edit&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&pid=<%= PostListArray(0, i) %>&page=<%= Page %>&extra=page%3D1">编辑</a> <a href="post.asp?action=reply&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&repquote=<%= PostListArray(0, i) %>&extra=page%3D1&page=<%= Page %>">引用</a> <a href="misc.asp?action=report&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&pid=<%= PostListArray(0, i) %>&page=<%= Page %>" id="ajax_report_<%= i %>" onclick="ajaxmenu(event, this.id, 9000000, null, 0)">报告</a> <a href="misc.asp?action=rate&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&pid=<%= PostListArray(0, i) %>&page=1" id="ajax_rate_<%= i %>" onclick="ajaxmenu(event, this.id, 9000000, null, 0)">评分</a> <strong onclick="scroll(0,0)" title="顶部">TOP</strong> </p>
<div id="ad_thread1_<%= i %>"></div>
</div></td>
</tr>
</table>
</div>
<% If i = 0 Then %><div id="ad_interthread"></div><% End If %>
<% Next %>
<% End If %>
<!-- posts loop end -->
</form>
<div class="pages_btns">
<div class="threadflow"><a href="redirect.asp?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&goto=nextoldset"> &lsaquo;&lsaquo; 上一主题</a> | <a href="redirect.asp?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&goto=nextnewset">下一主题 &rsaquo;&rsaquo;</a></div>
<% If PageCount > 1 Then Call ShowPageInfo(Page, PageCount, RecordCount, "&fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&authorid="& ViewAuthorID) End If %>
<span class="postbtn" id="newspecialtmp" onmouseover="$('newspecial').id = 'newspecialtmp';this.id = 'newspecial';showMenu(this.id)"><a href="post.asp?action=newtopic&fid=<%= RQ.ForumID %>&extra=page%3D1"><img src="images/default/newtopic.gif" border="0" alt="发新话题" title="发新话题" /></a></span> <span class="replybtn"><a href="post.asp?action=reply&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&extra=page%3D1"><img src="images/default/reply.gif" border="0" alt="" /></a></span></div>
<script src="include/javascript/post.js" type="text/javascript"></script>
<script type="text/javascript">
var postminchars = parseInt('10');
var postmaxchars = parseInt('10000');
var disablepostctrl = parseInt('1');
function validate(theform) {
if (theform.message.value == "" && theform.subject.value == "") {
alert("请完成标题或内容栏。");
theform.message.focus();
return false;
} else if (theform.subject.value.length > 80) {
alert("您的标题超过 80 个字符的限制。");
theform.subject.focus();
return false;
}
if (!disablepostctrl && ((postminchars != 0 && theform.message.value.length < postminchars) || (postmaxchars != 0 && theform.message.value.length > postmaxchars))) {
alert("您的帖子长度不符合要求。\n\n当前长度: "+theform.message.value.length+" 字节\n系统限制: "+postminchars+" 发送到 "+postmaxchars+" 字节");
return false;
}
if(!fetchCheckbox('parseurloff')) {
theform.message.value = parseurl(theform.message.value, 'bbcode');
}
theform.replysubmit.disabled = true;
return true;
}
</script>
<form method="post" id="postform" action="post.asp?action=reply&fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&extra=page%3D1" onSubmit="return validate(this)">
<div id="quickpost" class="box"> <span class="headactions"><a href="member.php?action=credits&amp;view=forum_reply&amp;fid=2" target="_blank">查看积分策略说明</a></span>
<h4>快速回复主题</h4>
<div class="postoptions">
<h5>选项</h5>
<p>
<label>
<input class="checkbox" type="checkbox" name="parseurloff" id="parseurloff" value="1">
禁用 URL 识别</label>
</p>
<p>
<label>
<input class="checkbox" type="checkbox" name="isanonymous" value="1">
使用匿名发帖</label>
</p>
<p>
<label>
<input class="checkbox" type="checkbox" name="usesig" value="1" >
使用个人签名</label>
</p>
</div>
<div class="postform">
<h5></h5>
<p>
<label>内容</label>
<textarea rows="7" cols="80" class="autosave" name="message" id="message" onKeyDown="ctlent(event);" tabindex="2"></textarea>
</p>
<p class="btns">
<button type="submit" name="replysubmit" id="postsubmit" value="replysubmit" tabindex="3">发表帖子</button>
[完成后可按 Ctrl+Enter 发布]
</p>
</div>
<div class="smilies">
<div id="smilieslist"></div>
<script type="text/javascript">ajaxget('post.php?action=smilies', 'smilieslist');</script>
</div>
</div>
</form>
<script type="text/javascript">
function modaction(action) {
if(!action) {
return;
}
if(!in_array(action, ['delpost', 'banpost'])) {
window.location=('topicadmin.php?tid=2&fid=2&action='+ action +'&sid=8peaeb');
} else {
document.modactions.action = 'topicadmin.php?action='+ action +'&fid=2&tid=2&page=1;'
document.modactions.submit();
}
}
</script>
<div id="footfilter" class="box">
<form action="#">
管理选项:
<select name="action" id="action" onchange="modaction(this.options[this.selectedIndex].value)">
<option value="" selected>管理选项</option>
<option value="delpost">删除回帖</option>
<option value="delete">删除主题</option>
<option value="banpost">屏蔽帖子</option>
<option value="close">关闭主题</option>
<option value="move">移动主题</option>
<option value="copy">复制主题</option>
<option value="highlight">高亮显示</option>
<option value="type">主题分类</option>
<option value="digest">设置精华</option>
<option value="stick">主题置顶</option>
<option value="merge">合并主题</option>
<option value="bump">提升主题</option>
</select>
</form>
</div>
<%
	RQ.FlatFooter()
End Sub
%>