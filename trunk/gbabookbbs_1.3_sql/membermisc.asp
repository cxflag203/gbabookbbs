<!--#include file="include/inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")

RQ.PageBaseTarget = CacheName &"right"
RQ.Header()

Call Main()

If RQ.UserID = 0 Then
	Call ShowErr("您还没有登陆，请先<a href="""& RQ.Login_Settings(1) &""" class=""underline"" target=""_top"">登陆</a>。")
End If

Select Case Action
	Case "download", "creation", "callin", "useful"
		Call TopicTypeList()
	Case "elitetopics", "newtopics", "favorites", "leaguetopics"
		Call EliteNewFavorLeague()
	Case "mytopics"
		Call MyTopics()
	Case "myposts"
		Call MyPosts()
	Case "deletepost"
		Call DeletePost()
End Select
RQ.Footer()

'========================================================
'帖子类型:下载/原创/召集/实用
'========================================================
Sub TopicTypeList()
	Dim Types, TopicListArray

	Select Case Action
		Case "download"
			Types = 2
		Case "creation"
			Types = 3
		Case "callin"
			Types = 4
		Case "useful"
			Types = 5
	End Select

	TopicListArray = RQ.Query("SELECT tid, fid, title, usershow, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE types = "& Types &" AND displayorder >= 0 ORDER BY lastupdate DESC")
	Call closeDataBase()

	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""">◆</a>"
			Else
				Response.Write "◆"
			End If

			Response.Write " <a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""" title="""& TopicListArray(6, i) &""">"& TopicListArray(2, i) &" ("& TopicListArray(5, i) &"/"& TopicListArray(4, i) &")</a>"

			'如果打开了道具功能则显示使用道具的链接
			If RQ.Item_Settings(0) = "1" Then
				Response.Write "【<a href=""item.asp?action=topicitem&tid="& TopicListArray(0, i) &""" onclick=""return shows(this.href)"">道具</a>】"
			End If

			Response.Write "("& TopicListArray(3, i) &")<br />"
		Next

		Erase TopicListArray
	End If
End Sub

'========================================================
'显示精彩帖子/最新帖子/收藏帖子/联盟帖子
'========================================================
Sub EliteNewFavorLeague()
	Dim TopicListArray, strSQL

	Select Case Action
		'精彩帖
		Case "elitetopics"
			strSQL = "SELECT tid, fid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE ifelite = 1 AND displayorder >= 0 ORDER BY lastupdate DESC"

		'最新帖
		Case "newtopics"
			strSQL = "SELECT TOP 50 tid, fid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE displayorder >= 0 AND fid IN("& RQ.Get_Accessable_ForumID() &") ORDER BY tid DESC"
		
		'收藏帖
		Case "favorites"
			strSQL = "SELECT tid, fid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID &") AND displayorder >= 0 ORDER BY lastupdate DESC"

		'联盟帖
		Case "leaguetopics"
			strSQL = "SELECT tid, fid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"leaguetopics WHERE leagueid IN(SELECT leagueid FROM "& TablePre &"leaguefavorites WHERE uid = "& RQ.UserID &")) AND displayorder >= 0 ORDER BY lastupdate DESC"
	End Select

	'查询
	TopicListArray = RQ.Query(strSQL)
	Call closeDataBase()

	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""">◆</a>"
			Else
				Response.Write "◆"
			End If

			Response.Write " <a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""" title="""& TopicListArray(6, i) &""">"& TopicListArray(3, i) &" ("& TopicListArray(5, i) &"/"& TopicListArray(4, i) &")</a>"

			'如果打开了道具功能则显示使用道具的链接
			If RQ.Item_Settings(0) = "1" Then
				Response.Write "【<a href=""item.asp?action=topicitem&tid="& TopicListArray(0, i) &""" onclick=""return shows(this.href)"">道具</a>】"
			End If

			Response.Write "("& TopicListArray(2, i) &")<br />"
		Next

		Erase TopicListArray
	End If
End Sub

'========================================================
'显示自己发布的帖子
'========================================================
Sub MyTopics()
	Dim RecordCount, PageCount, Page, strSQL
	Dim TopicListArray

	RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE uid = "& RQ.UserID)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(2)))))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP "& RQ.Topic_Settings(2) &" tid, fid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE uid = "& RQ.UserID
		If Page > 1 Then
			strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(2)) * (Page - 1) &" lastupdate FROM "& TablePre &"topics WHERE uid = "& RQ.UserID &" ORDER BY lastupdate DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY lastupdate DESC"

		TopicListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()

	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""">◆</a>"
			Else
				Response.Write "◆"
			End If

			Response.Write " <a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""" title="""& TopicListArray(6, i) &""">"& TopicListArray(3, i) &" ("& TopicListArray(5, i) &"/"& TopicListArray(4, i) &")</a>"

			'如果打开了道具功能则显示使用道具的链接
			If RQ.Item_Settings(0) = "1" Then
				Response.Write "【<a href=""item.asp?action=topicitem&tid="& TopicListArray(0, i) &""" onclick=""return shows(this.href)"">道具</a>】"
			End If

			Response.Write "("& TopicListArray(2, i) &")<br />"
		Next

		Erase TopicListArray
	End If

	If PageCount > 1 Then
		Call ShowPageInfo(Page, PageCount, RecordCount, "&action=mytopics")
	End If
End Sub

'========================================================
'显示自己发布的回复
'========================================================
Sub MyPosts()
	Dim RecordCount, PageCount, Page, strSQL
	Dim PostListArray

	RecordCount = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE uid = "& RQ.UserID &" AND iffirst = 0")(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(4)))))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP "& RQ.Topic_Settings(4) &" pid, fid, tid, message FROM "& TablePre &"posts WHERE uid = "& RQ.UserID &" AND iffirst = 0"
		If Page > 1 Then
			strSQL = strSQL &" AND pid < (SELECT MIN(pid) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(4)) * (Page - 1) &" pid FROM "& TablePre &"posts WHERE uid = "& RQ.UserID &" AND iffirst = 0 ORDER BY pid DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY pid DESC"

		PostListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()

	If IsArray(PostListArray) Then
		For i = 0 To UBound(PostListArray, 2)
			Response.Write "[<a href=""###"" onclick=""postvalue('?action=deletepost', 'pid', '"& PostListArray(0, i) &"')"" target=""_self"">删除</a>]"
			Response.Write "<a href=""topicmisc.asp?action=redirectpost&pid="& PostListArray(0, i) &""">"& Left(dfc(PostListArray(3, i)), 170) &"</a><hr color=""black"" />"
		Next
		Erase PostListArray
	End If

	If PageCount > 1 Then
		Call ShowPageInfo(Page, PageCount, RecordCount, "&action=myposts")
	End If
End Sub

'========================================================
'快捷删除回复
'========================================================
Sub DeletePost()
	Dim PostID, PostInfo
	Dim AttachListArray

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT tid, ifattachment FROM "& TablePre &"posts WHERE pid = "& PostID &" AND uid = "& RQ.UserID)
	If Not IsArray(PostInfo) Then
		Call RQ.showTips("回复不存在或者已经被删除.", "", "")
	End If

	'删除指定回复，更新帖子回复数量
	RQ.Execute("DELETE FROM "& TablePre &"posts WHERE pid = "& PostID)
	RQ.Execute("UPDATE "& TablePre &"topics SET posts = (SELECT COUNT(pid) - 1 FROM "& TablePre &"posts WHERE tid = "& PostInfo(0, 0) &") WHERE tid = "& PostInfo(0, 0))

	'如果回复中有附件则同时删除附件
	If PostInfo(1, 0) = 1 Then
		'读取附件
		AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE pid = "& PostID)

		'删除附件
		If IsArray(AttachListArray) Then
			For i = 0 To UBound(AttachListArray, 2)
				Call DeleteFile("./attachments/"& AttachListArray(0, i))
			Next
			RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE pid = "& PostID)
		End If
	End If

	Call closeDatabase()
	Response.Redirect "?action=myposts"
End Sub

'========================================================
'顶部菜单
'========================================================
Sub Main()
%>
<body class="forumdisplay">
<form action="search.asp" method="get" target="_self" onsubmit="chgthisfrm();">
  <input type="hidden" name="action" value="search" />
  <input name="keyword" size="10" onBlur="if(this.value=='')this.value='输入关键字';" onFocus="if(this.value=='输入关键字')this.value='';" value="输入关键字" /><select name="searchtype">
    <option value="title">帖子标题</option>
    <option value="author">发言人</option>
  </select><input type="submit" value="搜索" class="button" />
  [<a target="_self" href="?action=elitetopics" onclick="chgthisfrm();">精彩</a> <a target="_self" href="?action=download" onclick="chgthisfrm();">下载</a> <a target="_self" href="?action=creation" onclick="chgthisfrm();">原创</a> <a target="_self" href="?action=callin" onclick="chgthisfrm();">召集</a> <a target="_self" href="?action=useful" onclick="chgthisfrm();">实用</a>] <br />
  [<a target="_self" href="?action=newtopics" onclick="chgthisfrm();">最新</a> <a target="_self" href="?action=favorites" onclick="chgthisfrm();">收藏</a> <a target="_self" href="?action=mytopics" onclick="chgthisfrm();">自发</a> <a target="_self" href="?action=myposts" onclick="chgthisfrm();">自回</a> <a href="membercp.asp">功能</a> <a href="post.asp?fid=<%= RQ.Other_Settings(3) %>">发帖</a> <a target="_self" href="?action=leaguetopics" onclick="chgthisfrm();">联盟帖</a> <a href="leaguelist.asp">联盟表</a>]
</form>
<script type="text/javascript">
function chgthisfrm(){
	if (parent.$('<%= CacheName %>leftsearch').rows){
		if (parent.$('<%= CacheName %>leftsearch').rows == '*,50'){
			parent.$('<%= CacheName %>leftsearch').rows = '*,355';
		}
	}
}
</script>
<p>
<%
End Sub
%>
