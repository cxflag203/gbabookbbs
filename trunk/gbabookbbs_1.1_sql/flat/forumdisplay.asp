<!--#include file="../include/inc.asp"-->
<%
If RQ.ForumID = 0 Then
	Call RQ.showTips("指定的版面不存在，请返回。", "", "")
End If

Dim TypeID, TopicsPerPage, PostsPerPage, Dict
TopicsPerPage = IntCode(RQ.Topic_Settings(2))
PostsPerPage = IntCode(RQ.Topic_Settings(4))

Call Main()

'========================================================
'列出帖子分类并放入字典对象
'========================================================
Function ReadTopicTypes()
	Dim TypeListArray, blnCorrectTypeID, str

	TypeListArray = eval(RQ.Forum_TopicType)
	blnCorrectTypeID = False

	For i = 0 To UBound(TypeListArray)
		If TypeID = TypeListArray(i)(1) Then 
			blnCorrectTypeID = True
			str = str & "<strong>"& TypeListArray(i)(0) &"</strong>"
		Else
			str = str & "<a href=""?fid="& RQ.ForumID &"&filter=type&typeid="& TypeListArray(i)(1) &""">"& TypeListArray(i)(0) &"</a>"
		End If

		'把帖子分类编号和名称加入字典对象
		Call Dict.Add(TypeListArray(i)(1), TypeListArray(i)(0))
	Next

	'验证typeid是否正确
	If Not blnCorrectTypeID Then
		TypeID = 0
	End If

	ReadTopicTypes = str
End Function

'========================================================
'帖子列表显示帖子内容的分页
'========================================================
Function ListMorePage(tid, posts)
	Dim Pages, n, strPage
	Pages = ABS(Int(-(posts / PostsPerPage)))
	For n = 1 To Pages
		If n > 6 Or n > Pages Then
			Exit For
		End If
		strPage = strPage &"<a href=""viewtopic.asp?fid="& RQ.ForumID &"&tid="& tid &"&page="& n &""">"& n &"</a> "
	Next

	If Pages > 6 Then
		strPage = strPage &" .. <a href=""viewtopic.asp?fid="& RQ.ForumID &"&tid="& tid &"&page="& Pages &""">"& Pages &"</a>"
	End If

	ListMorePage = "<span class=""threadpages""> &nbsp; "& strPage &"</span>"
End Function

'========================================================
'子版面和帖子列表
'========================================================
Sub Main()
	Dim f_ListArray, subForumListArray, AryModerators, AryLastPost
	Dim StickListArray, TopicListArray
	Dim Page, PageCount, RecordCount, strSQL, strAddition
	Dim strTopicTypes, strModerators, strNav, t, n
	Dim Cmd, tFilter

	'读取子版面
	If RQ.Forum_Childs > 0 Then
		f_ListArray = RQ.Query("SELECT f.fid, f.name, f.topics, f.posts, f.todayposts, f.lastpost, f.visitndcredits, ff.description, ff.icon, ff.moderators, ff.viewperm FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid WHERE f.parentid = "& RQ.ForumID &" ORDER BY f.displayorder ASC")
		If IsArray(f_ListArray) Then
			ReDim subForumListArray(9, 0) : t = 0
			For i = 0 To UBound(f_ListArray, 2)
				If Len(f_ListArray(10, i)) = 0 Or InStr(","& f_ListArray(10, i) &",", ","& RQ.UserGroupID &",") > 0 Then
					ReDim Preserve subForumListArray(9, t)
					For n = 0 To 9
						subForumListArray(n, t) = f_ListArray(n, i)
					Next
					t = t + 1
				End If
			Next

			If t = 0 Then
				subForumListArray = Null
			End If
		Else
			RQ.Execute("UPDATE "& TablePre &"forums SET childs = 0 WHERE fid = "& RQ.ForumID)
		End If
	End If

	'读取版面帖子分类
	TypeID = SafeRequest(3, "typeid", 0, 0, 0)
	If Len(RQ.Forum_TopicType) > 0 And RQ.F_ShowTopicType = 1 Then
		Set Dict = Server.CreateObject("Scripting.Dictionary")
		strTopicTypes = ReadTopicTypes()
	Else
		TypeID = 0
	End If

	'显示版主
	If Len(RQ.Forum_Moderators) > 0 Then
		AryModerators = Split(RQ.Forum_Moderators, Chr(9))
		For i = 0 To UBound(AryModerators)
			strModerators = strModerators &"<a href=""space.asp?username="& Server.URLEncode(AryModerators(i)) &""">"& AryModerators(i) &"</a>"& IIF(i <> UBound(AryModerators), ", ", "")
		Next
	End If

	Page = SafeRequest(3, "page", 0, 1, 0)
	tFilter = Request.QueryString("filter")

	If tFilter = "digest" Then
		strAddition = " AND ifelite = 1"
	ElseIf tFilter = "poll" Then
		strAddition = " AND special = 1"
	Else
		strAddition = ""
	End If

	'第一页读取置顶帖子
	If Page = 1 Then
		StickListArray = RQ.Query("SELECT tid, fid, typeid, displayorder, uid, username, usershow, title, posttime, lastupdate, lastposter, clicks, posts, special, price, ifelite, iflocked, ifanonymity, ifattachment FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"sticktopics WHERE fid = "& RQ.ForumID &") AND displayorder > 0"& IIF(TypeID > 0, " AND typeid = "& TypeID, "") & strAddition &" ORDER BY displayorder DESC, lastupdate DESC")

		'如果有置顶帖则清除过期的置顶帖
		If IsArray(StickListArray) Then
			Call RQ.ClearStickTopic()
		End If
	End If

	'计算普通帖子的数量
	If TypeID > 0 Then
		RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND typeid = "& TypeID &" AND displayorder = 0")(0)
		dbQueryNum = dbQueryNum + 1
	ElseIf Len(strAddition) > 0 Then
		RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = 0"& SqlAddition)(0)
		dbQueryNum = dbQueryNum + 1
	Else
		RecordCount = RQ.Forum_Topics
	End If

	'如果版面设置了只读取n页内的帖子则检查帖子总数量够不够
	If IntCode(RQ.Topic_Settings(3)) > 0 Then
		If RecordCount > TopicsPerPage * IntCode(RQ.Topic_Settings(3)) Then
			RecordCount = TopicsPerPage * IntCode(RQ.Topic_Settings(3))
		End If
	End If

	PageCount = ABS(Int(-(RecordCount / TopicsPerPage)))
	Page = IIF(Page > PageCount, PageCount, Page)

	'读取普通帖子数量
	Set Cmd = Server.CreateObject("ADODB.Command")
	With Cmd
		.ActiveConnection = Conn
		.CommandType = 4
		.CommandText = TablePre &"sp_topiclist"
		.Prepared = True
		.Parameters.Item("@fid").Value = RQ.ForumID
		.Parameters.Item("@page").Value = Page
		.Parameters.Item("@pagesize").Value = TopicsPerPage
		.Parameters.Item("@typeid").Value = typeid
		Set Rs = .Execute

		If Not Rs.EOF And Not Rs.BOF Then
			TopicListArray = Rs.GetRows()
		Else
			TopicListArray = 0
		End If
	End With
	Set Cmd = Nothing
	dbQueryNum = dbQueryNum + 1

	'导航路径
	If RQ.Forum_ParentID = RQ.Forum_RootFID Then
		strNav = " &raquo; "& RQ.Forum_Name
	Else
		strNav = " &raquo; <a href=""?fid="& RQ.Forum_ParentID &""">"& RQ.Get_Forum_Settings(RQ.Forum_ParentID, 1) &"</a> &raquo; "& RQ.Forum_Name
	End If

	Call closeDatabase()
	RQ.FlatHeader()
%>
<div id="foruminfo">
<div id="headsearch">
<p><span id="rules_link" style="display: none"><a href="###" onclick="$('rules_link').style.display = 'none';toggle_collapse('rules', 1);">本版规则</a> |&nbsp;</span> <a href="my.php?item=favorites&amp;fid=2" id="ajax_favorite" onclick="ajaxmenu(event, this.id)">收藏本版</a> | <a href="my.php?item=threads&amp;srchfid=2">我的话题</a> <a href="rss.php?fid=2&amp;auth=ad3%2Bv2pcouahNLK4V4S%2BcCBZ8UM" target="_blank"><img src="images/common/xml.gif" border="0" class="absmiddle" alt="RSS 订阅全部版块" /></a> </p>
</div>
<div id="nav">
<p><a id="forumlist" href="index.asp"><%= RQ.Base_Settings(0) %></a><%= strNav %></p>
<% If Len(strModerators) > 0 Then %><p>版主: <%= strModerators %></p><% End If %>
</div>
</div>
<% If Len(RQ.Forum_Rules) > 0 Then %>
<table summary="Rules and Recommend" class="portalbox" cellpadding="0" cellspacing="1">
<tr>
<td id="rules" style=""><span class="headactions recommendrules"><img id="rules_img" src="images/default/collapsed_no.gif" title="收起/展开" alt="收起/展开" onclick="$('rules_link').style.display = '';toggle_collapse('rules', 1);" /></span>
<h3>本版规则</h3>
<%= RQ.Forum_Rules %>
</td>
</tr>
</table>
<% End If %>
<% If IsArray(subForumListArray) Then %>
<div class="mainbox forumlist"><span class="headactions"><img id="subforum_2_img" src="images/default/collapsed_no.gif" title="收起/展开" alt="收起/展开" onclick="toggle_collapse('subforum_2');" /></span>
<h3>子版块</h3>
<table id="subforum_2" summary="subform" cellspacing="0" cellpadding="0" style="">
<thead class="category">
<tr>
<th>版块</th>
<td class="nums">主题</td>
<td class="nums">帖数</td>
<td class="lastpost">最后发表</td>
</tr>
</thead>
<% For i = 0 To UBound(subForumListArray, 2) %>
<tbody>
<tr>
<th><% If Len(subForumListArray(8, i)) > 0 Then %><a href="?fid=<%= subForumListArray(0, i) %>"><img style="margin-right: 10px" src="<%= subForumListArray(8, i) %>" align="left" alt="" border="0" /></a><% End If %><h2><a href="?fid=<%= subForumListArray(0, i) %>"><%= subForumListArray(1, i) %></a><% If subForumListArray(4, i) > 0 Then %><em> (今日: <%= subForumListArray(4, i) %>)</em><% End If %></h2>
<% If Len(subForumListArray(7, i)) > 0 Then %><p><%= subForumListArray(7, i) %></p><% End If %>
<% If Len(subForumListArray(9, i)) > 0 Then %><p>版主: <% AryModerators = Split(subForumListArray(9, i), Chr(9)) : For n = 0 To UBound(AryModerators) %><a href="space.asp?username=<%= Server.URLEncode(AryModerators(n)) %>"><%= AryModerators(n) %></a><% If n <> UBound(AryModerators) Then %>, <% End If %><% Next %></p><% End If %>
</th>
<td class="nums"><%= subForumListArray(2, i) %></td>
<td class="nums"><%= subForumListArray(3, i) %></td>
<td class="lastpost"><% If RQ.UserCredits >= subForumListArray(6, i) Or subForumListArray(6, i) = 0 Then %><% If Len(subForumListArray(5, i)) > 0 Then %><% AryLastPost = Split(subForumListArray(5, i), Chr(9)) %><a href="redirect.asp?tid=<%= AryLastPost(0) %>&goto=lastpost#lastpost"><%= CutString(AryLastPost(1), 34) %></a> <cite>by <% If Len(aryLastPost(3)) > 0 Then %><a href="space.asp?username=<%= Server.URLEncode(AryLastPost(3)) %>"><%= aryLastPost(3) %></a><% Else %>匿名<% End If %> - <%= CDate(AryLastPost(2)) %></cite> <% Else %>从未<% End If %><% Else %>私密论坛<% End If %></td>
</tr>
</tbody>
<% Next %>
</table>
</div>
<% End If %>
<div id="ad_text"></div>
<div class="pages_btns">
<div class="pages"><em>&nbsp;21&nbsp;</em><strong>1</strong><a href="forumdisplay.php?fid=2&amp;page=2">2</a><a href="forumdisplay.php?fid=2&amp;page=2" class="next">&rsaquo;&rsaquo;</a></div>
<span class="postbtn" id="newspecial" onmouseover="$('newspecial').id = 'newspecialtmp';this.id = 'newspecial';showMenu(this.id)"><a href="post.php?action=newthread&amp;fid=2&amp;extra=page%3D1" title="发新话题"><img src="images/default/newtopic.gif" alt="发新话题" /></a></span>
</div>
<ul class="popupmenu_popup newspecialmenu" id="newspecial_menu" style="display: none">
<li><a href="post.asp?action=newtopic&fid=<%= RQ.ForumID %>&extra=page%3D1">发新话题</a></li>
<li class="poll"><a href="post.asp?action=newtopic&fid=<%= RQ.ForumID %>&special=1&extra=page%3D1">发布投票</a></li>
</ul>
<div id="headfilter">
<ul class="tabs">
<li<% If len(tFilter) = 0 Then %> class="current"<% End If %>><a href="?fid=<%= RQ.ForumID %>">全部</a></li>
<li<% If tFilter = "digest" Then %> class="current"<% End If %>><a href="?fid=<%= RQ.ForumID %>&filter=digest">精华</a></li>
<li<% If tFilter = "poll" Then %> class="current"<% End If %>><a href="?fid=<%= RQ.ForumID %>&filter=poll">投票</a></li>
</ul>
</div>
<div class="mainbox threadlist">
<div class="headactions"><%= strTopicTypes %></div>
<h1><a href="forumdisplay.asp?fid=<%= RQ.ForumID %>" class="bold"><%= RQ.Forum_Name %></a></h1>
<form method="post" name="moderate" action="topicadmin.php?action=moderate&amp;fid=<%= RQ.ForumID %>">
<table summary="forum_<%= RQ.ForumID %>"<% If Not IsArray(StickListArray) Then %> id="forum_<%= RQ.ForumID %>"<% End If %> cellspacing="0" cellpadding="0">
<thead class="category">
<tr>
<td class="folder">&nbsp;</td>
<td class="icon">&nbsp;</td>
<th>标题</th>
<td class="author">作者</td>
<td class="nums">回复/查看</td>
<td class="lastpost">最后发表</td>
</tr>
</thead>
<% If IsArray(StickListArray) Then %>
<% For i = 0 To UBound(StickListArray, 2) %>
<tbody id="stickthread_<%= StickListArray(0, i) %>" >
<tr>
<td class="folder"><a href="viewthread.asp?fid=<%= StickListArray(1, i) %>&tid=<%= StickListArray(0, i) %>&extra=page%3D1" title="新窗口打开" target="_blank"><img src="images/default/folder_common.gif" /></a></td>
<td class="icon">&nbsp;</td>
<th class="common"  ondblclick="ajaxget('modcp.asp?action=editsubject&tid=<%= StickListArray(0, i) %>', 'thread_<%= StickListArray(0, i) %>', 'specialposts');doane(event);"><label><img src="images/default/pin_<%= StickListArray(3, i) %>.gif" alt="本版置顶" /> &nbsp;</label>
<input class="checkbox" type="checkbox" name="topicid" value="<%= StickListArray(0, i) %>" />
<span id="thread_<%= StickListArray(0, i) %>"><a href="viewthread.asp?fid=<%= StickListArray(1, i) %>&tid=<%= StickListArray(0, i) %>&extra=page%3D1"><%= StickListArray(7, i) %></a></span>
<% If StickListArray(12, i) > PostsPerPage Then %><%= ListMorePage(StickListArray(0, i), StickListArray(12, i)) %><% End If %></th>
<td class="author"> <cite><% If StickListArray(4, i) = 0 Or StickListArray(17, i) = 1 Then %>匿名<% Else %><a href="space.asp?action=viewpro&uid=<%= StickListArray(4, i) %>"><%= StickListArray(5, i) %></a><% End If %></cite> <em><%= FormatDateTime(StickListArray(8, i), 2) %></em></td>
<td class="nums"><strong><%= StickListArray(12, i) %></strong> / <em><%= StickListArray(11, i) %></em></td>
<td class="lastpost"><em><a href="redirect.asp?tid=<%= StickListArray(0, i) %>&goto=lastpost#lastpost"><%= StickListArray(9, i) %></a></em> <cite>by <% If Len(StickListArray(10, i)) > 0 Then %><a href="space.asp?action=viewpro&username=<%= Server.URLEncode(StickListArray(10, i)) %>"><%= StickListArray(10, i) %></a><% Else %>匿名<% End If %></cite> </td>
</tr>
</tbody>
<% Next %>
</table>
<table summary="forum_<%= RQ.ForumID %>" id="forum_<%= RQ.ForumID %>" cellspacing="0" cellpadding="0">
<thead class="separation">
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td colspan="4">版块主题</td>
</tr>
</thead>
<% End If %>
<!-- topics loop begin -->
<% If IsArray(TopicListArray) Then %>
<% For i = 0 To UBound(TopicListArray, 2) %>
<tbody id="normalthread_<%= TopicListArray(0, i) %>" >
<tr>
<td class="folder"><a href="viewthread.asp?fid=<%= RQ.ForumID %>&tid=<%= TopicListArray(0, i) %>&extra=page%3D1" title="新窗口打开" target="_blank"><img src="images/default/folder_common.gif" /></a></td>
<td class="icon">&nbsp;</td>
<th class="common" ondblclick="ajaxget('modcp.asp?action=editsubject&tid=<%= TopicListArray(0, i) %>', 'thread_<%= TopicListArray(0, i) %>', 'specialposts');doane(event);"> <label> &nbsp;</label>
<input class="checkbox" type="checkbox" name="topicid" value="<%= TopicListArray(0, i) %>" />
<span id="thread_<%= TopicListArray(0, i) %>"><a href="viewthread.asp?fid=<%= RQ.ForumID %>&tid=<%= TopicListArray(0, i) %>&extra=page%3D1"><%= TopicListArray(6, i) %></a></span>
<% If TopicListArray(11, i) > PostsPerPage Then %><%= ListMorePage(TopicListArray(0, i), TopicListArray(11, i)) %><% End If %></th>
<td class="author"> <cite><% If TopicListArray(3, i) = 0 Or TopicListArray(16, i) = 1 Then %>匿名<% Else %><a href="space.amsp?action=viewpro&uid=<%= TopicListArray(3, i) %>"><%= TopicListArray(4, i) %></a><% End If %></cite> <em><%= FormatDateTime(TopicListArray(7, i), 2) %></em></td>
<td class="nums"><strong><%= TopicListArray(11, i) %></strong> / <em><%= TopicListArray(10, i) %></em></td>
<td class="lastpost"><em><a href="redirect.asp?tid=<%= TopicListArray(0, i) %>&goto=lastpost#lastpost"><%= TopicListArray(8, i) %></a></em> <cite>by <% If Len(TopicListArray(9, i)) > 0 Then %><a href="space.asp?action=viewpro&username=<%= Server.URLEncode(TopicListArray(9, i)) %>"><%= TopicListArray(9, i) %></a><% End If %></cite> </td>
</tr>
</tbody>
<% Next %>
<% End If %>
<!-- topics loop end -->
</table>
<div class="footoperation">
<input type="hidden" name="operation" />
<label>
<input class="checkbox" type="checkbox" name="chkall" onclick="checkall(this.form, 'topicid')" />
全选</label>
<button onclick="modthreads('delete')">删除主题</button>
<button onclick="modthreads('move')">移动主题</button>
<button onclick="modthreads('highlight')">高亮显示</button>
<button onclick="modthreads('type')">主题分类</button>
<button onclick="modthreads('close')">关闭/打开主题</button>
<button onclick="modthreads('bump')">提升/下沉主题</button>
<button onclick="modthreads('stick')">置顶/解除置顶</button>
<button onclick="modthreads('digest')">加入/解除精华</button>
<script type="text/javascript">
function modthreads(operation) {
document.moderate.operation.value = operation;
document.moderate.submit();
}
</script>
</div>
</form>
</div>
<div class="pages_btns">
<div class="pages"><em>&nbsp;21&nbsp;</em><strong>1</strong><a href="forumdisplay.php?fid=2&amp;page=2">2</a><a href="forumdisplay.php?fid=2&amp;page=2" class="next">&rsaquo;&rsaquo;</a></div>
<span class="postbtn" id="newspecialtmp" onmouseover="$('newspecial').id = 'newspecialtmp';this.id = 'newspecial';showMenu(this.id)"><a href="post.php?action=newthread&amp;fid=2&amp;extra=page%3D1" title="发新话题"><img src="images/default/newtopic.gif" alt="发新话题" /></a></span> </div>
<script src="include/javascript/post.js" type="text/javascript"></script>
<script type="text/javascript">
var postminchars = parseInt('10');
var postmaxchars = parseInt('10000');
var disablepostctrl = parseInt('1');
var typerequired = parseInt('');
function validate(theform) {
if (theform.typeid && theform.typeid.options[theform.typeid.selectedIndex].value == 0 && typerequired) {
alert("请选择主题对应的分类。");
theform.typeid.focus();
return false;
} else if (theform.subject.value == "" || theform.message.value == "") {
alert("请完成标题或内容栏。");
theform.subject.focus();
return false;
} else if (theform.subject.value.length > 80) {
alert("您的标题超过 80 个字符的限制。");
theform.subject.focus();
return false;
}
if (!disablepostctrl && ((postminchars != 0 && theform.message.value.length < postminchars) || (postmaxchars != 0 && theform.message.value.length > postmaxchars))) {
alert("您的帖子长度不符合要求。\n\n当前长度: "+theform.message.value.length+" 字节\n系统限制: "+postminchars+" 到 "+postmaxchars+" 字节");
return false;
}
if(!fetchCheckbox('parseurloff')) {
theform.message.value = parseurl(theform.message.value, 'bbcode');
}
theform.topicsubmit.disabled = true;
return true;
}
</script>
<form method="post" id="postform" action="post.php?action=newthread&amp;fid=2&amp;extra=page%3D1&amp;topicsubmit=yes" onSubmit="return validate(this)">
<input type="hidden" name="formhash" value="cc2271da" />
<div id="quickpost" class="box"> <span class="headactions"><a href="member.php?action=credits&amp;view=forum_post&amp;fid=2" target="_blank">查看积分策略说明</a></span>
<h4>快速发新话题</h4>
<div class="postoptions">
<h5>选项</h5>
<p>
<label><input class="checkbox" type="checkbox" name="parseurloff" id="parseurloff" value="1" />
禁用 URL 识别</label>
</p>
<p>
<label><input class="checkbox" type="checkbox" name="isanonymous" value="1" />
使用匿名发帖</label>
</p>
<p>
<label><input class="checkbox" type="checkbox" name="usesig" value="1"  />
使用个人签名</label>
</p>
</div>
<div class="postform">
<h5>
<label for="subject">标题</label>
<input type="text" id="subject" name="subject" tabindex="1" />
</h5>
<div id="threadtypes"></div>
<p>
<label>内容</label>
<textarea rows="7" cols="80" class="autosave" name="message" id="message" onKeyDown="ctlent(event);" tabindex="2"></textarea>
</p>
<p class="btns">
<button type="submit" name="topicsubmit" id="postsubmit" tabindex="3">发表帖子</button>
[完成后可按 Ctrl+Enter 发布]&nbsp; <a href="#">使用编辑器</a></p>
</div>
<div class="smilies">
<div id="smilieslist"></div>
<script type="text/javascript">ajaxget('post.php?action=smilies', 'smilieslist');</script>
</div>
</div>
</form>
<div class="legend">
<label><img src="images/default/folder_new.gif" alt="有新回复" />有新回复</label>
<label><img src="images/default/folder_common.gif" alt="无新回复" />无新回复</label>
<label><img src="images/default/folder_hot.gif" alt="热门主题" />热门主题</label>
<label><img src="images/default/folder_lock.gif" alt="关闭主题" />关闭主题</label>
</div>
<%
	Set Dict = Nothing
	RQ.FlatFooter()
End Sub
%>