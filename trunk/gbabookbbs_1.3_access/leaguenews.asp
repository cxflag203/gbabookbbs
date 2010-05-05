<!--#include file="include/inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "topics"
		Call ShowTopics()
	Case "deletenews"
		Call DeleteNews()
	Case Else
		Call Main()
End Select

'========================================================
'联盟贴子列表
'========================================================
Sub ShowTopics()
	Dim LeagueInfo, TopicListArray

	LeagueInfo = RQ.Query("SELECT name, description, news FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	TopicListArray = RQ.Query("SELECT t.tid, t.fid, t.usershow, t.title, t.clicks, t.posts, t.lastupdate FROM "& TablePre &"leaguetopics lt INNER JOIN "& TablePre &"topics t ON lt.tid = t.tid WHERE lt.leagueid = "& RQ.LeagueID &" AND t.displayorder >= 0 ORDER BY t.lastupdate DESC")

	Call closeDataBase()
	RQ.Header()
%>
<body>
<strong><%= LeagueInfo(0, 0) %></strong>
<hr size="1" />
<%= LeagueInfo(1, 0) %>
<p>
[<a href="?lid=<%= RQ.LeagueID %>" class="bluelink">联盟消息</a>][<a href="?action=topics&lid=<%= RQ.LeagueID %>" class="bluelink">联盟帖</a>][<a href="leagueelite.asp?lid=<%= RQ.LeagueID %>" class="bluelink" target="<%= CacheName %>left">精华区</a>][<a href="post.asp?fid=<%= RQ.Other_Settings(3) %>" class="bluelink">发帖</a>][<a href="leaguemembers.asp?lid=<%= RQ.LeagueID %>" class="bluelink">申请加盟</a>][<a href="leaguecp.asp?lid=<%= RQ.LeagueID %>" class="bluelink">联盟功能</a>][<a href="leaguelist.asp" class="bluelink">联盟列表</a>]
<p>
<%
	If IsArray(TopicListArray) Then

		For i = 0 To UBound(TopicListArray, 2)

			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""">◆</a>"
			Else
				Response.Write "◆"
			End If

			Response.Write " <a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""" title='【"& TopicListArray(6, i) &" "& TopicListArray(2, i) &"】'>"& TopicListArray(3, i) &"("& TopicListArray(5, i) &"/"& TopicListArray(4, i) &")</a>"

			'联盟盟主和联盟管理员可推荐帖子至联盟精华区
			If RQ.L_UserGroupID = 1 Then
				Response.Write " <a href=""###"" style=""color:#00f;"" onclick=""postvalue('topiccp.asp?action=saveleagueelite&lid="& RQ.LeagueID &"&r=ln', 'topicid', '"& TopicListArray(0, i) &"')"" title=""推荐至精华区"">★</a>"
			End If

			Response.Write "<br />"
		Next

		Erase TopicListArray
	End If

	RQ.Footer()
End Sub

'========================================================
'删除联盟新闻
'========================================================
Sub DeleteNews()
	Dim ArticleID, ArticleInfo, News

	ArticleID = SafeRequest(2, "articleid", 0, 0, 0)
	ArticleInfo = RQ.Query("SELECT uid FROM "& TablePre &"leaguenews WHERE articleid = "& ArticleID &" AND leagueid = "& RQ.LeagueID)

	If Not IsArray(ArticleInfo) Then
		Call RQ.showTips("联盟消息不存在或者已经被删除。", "", "")
	End If

	'验证身份
	If RQ.L_UserGroupID <> 1 And (RQ.L_UserGroupID <> 2 Or ArticleInfo(0, 0) <> RQ.UserID) Then
		Call RQ.showTips("只有联盟盟主和发表该消息的联盟管理员可以删除联盟消息。", "", "")
	End If

	RQ.Execute("DELETE FROM "& TablePre &"leaguenews WHERE articleid = "& ArticleID)

	'重新统计联盟消息数量
	News = Conn.Execute("SELECT COUNT(articleid) FROM "& TablePre &"leaguenews WHERE leagueid = "& RQ.LeagueID)(0)
	dbQueryNum = dbQueryNum + 1

	'更新联盟消息统计
	RQ.Execute("UPDATE "& TablePre &"leagues SET news = news - 1 WHERE leagueid = "& RQ.LeagueID)

	Call closeDatabase()
	Call RQ.showTips("联盟消息删除完毕。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'联盟新闻
'========================================================
Sub Main()
	Dim LeagueInfo
	Dim RecordCount, PageCount, Page
	Dim NewsListArray, strSQL

	LeagueInfo = RQ.Query("SELECT name, description, news FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)

	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	RecordCount = LeagueInfo(2, 0)

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 10)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP 10 articleid, uid, username, title, message, posttime FROM "& TablePre &"leaguenews WHERE leagueid = "& RQ.LeagueID

		If Page > 1 Then
			strSQL = strSQL &" AND articleid < (SELECT MIN(articleid) FROM (SELECT TOP "& 10 * (Page - 1) &" articleid FROM "& TablePre &"leaguenews WHERE leagueid = "& RQ.LeagueID &" ORDER BY articleid DESC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY articleid DESC"

		NewsListArray = RQ.Query(strSQL)
	End If

	Call closeDataBase()
	RQ.Header()
%>
<body>
<strong><%= LeagueInfo(0, 0) %></strong>
<hr size="1" />
<%= LeagueInfo(1, 0) %>
<p>
[<a href="?lid=<%= RQ.LeagueID %>" class="bluelink">联盟消息</a>][<a href="?action=topics&lid=<%= RQ.LeagueID %>" class="bluelink">联盟帖</a>][<a href="leagueelite.asp?lid=<%= RQ.LeagueID %>" class="bluelink" target="<%= CacheName %>left">精华区</a>][<a href="post.asp?fid=<%= RQ.Other_Settings(3) %>" class="bluelink">发帖</a>][<a href="leaguemembers.asp?lid=<%= RQ.LeagueID %>" class="bluelink">申请加盟</a>][<a href="leaguecp.asp?lid=<%= RQ.LeagueID %>" class="bluelink">联盟功能</a>][<a href="leaguelist.asp" class="bluelink">联盟列表</a>]
<p>
<%
	If IsArray(NewsListArray) Then
		For i = 0 To UBound(NewsListArray, 2)

			Response.Write NewsListArray(5, i) &" "& NewsListArray(3, i) &" ["& NewsListArray(2, i) &"]"

			'如果是联盟管理员自己发的新闻或者联盟盟主则显示“删除”链接
			If RQ.L_UserGroupID = 1 Or (RQ.L_UserGroupID = 2 And RQ.UserID = NewsListArray(1, i)) Then
				Response.Write " [<a href=""###"" class=""bluelink"" onclick=""if(!confirm('确定删除这篇联盟消息吗？'))return false;postvalue('?action=deletenews&lid="& RQ.LeagueID &"', 'articleid', '"& NewsListArray(0, i) &"');"">删除</a>]"
			End If

			Response.Write "<hr color=""black"" />"& NewsListArray(4, i) &"<p>"
		Next

		'如果总页数大于1则显示翻页列表
		If PageCount > 1 Then
			Call ShowPageInfo(Page, PageCount, RecordCount, "&lid="& RQ.LeagueID)
		End If

	End If

	RQ.Footer()
End Sub
%>