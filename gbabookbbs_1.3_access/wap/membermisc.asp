<!--#include file="wap.inc.asp"-->
<%
WapHeader()
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "newtopic"
		Call NewTopic()
	Case "elitetopic"
		Call EliteTopic()
	Case "savefavor"
		Call SaveFavor()
	Case Else
		Call Main()
End Select
WapFooter()

'========================================================
'查看新帖
'========================================================
Sub NewTopic()
	Dim TopicListArray
	TopicListArray = RQ.Query("SELECT TOP 30 tid, fid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE displayorder >= 0 ORDER BY tid DESC")

	Call closeDatabase()

	Call Append("最新的30个帖子<br /><br />")

	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			TopicListArray(2, i) = WapCode(TopicListArray(2, i), 15)
			Call Append("<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&amp;tid="& TopicListArray(0, i) &""">"& TopicListArray(2, i) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a>"& IIF(TopicListArray(5, i) = 1, "[精]", "") &"<br />")
		Next
	End If
End Sub

'========================================================
'查看精华帖
'========================================================
Sub EliteTopic()
	Dim RecordCount, PageCount, Page
	Dim strSQL, TopicListArray

	If Not IsObject(Conn) Then
		Call connectDatabase()
	End If

	RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE ifelite = 1 AND displayorder >= 0")(0)
	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 10)))
	
		Page = IIF(Page > PageCount, PageCount, Page)
		strSQL = "SELECT TOP 10 tid, fid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE ifelite = 1 AND displayorder >= 0"
		If Page > 1 Then
			strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& 10 * (Page - 1) &" lastupdate FROM "& TablePre &"topics WHERE ifelite = 1 AND displayorder >= 0 ORDER BY lastupdate DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY lastupdate DESC"

		TopicListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()

	Call Append("精华帖<br /><br />")
	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			TopicListArray(2, i) = WapCode(TopicListArray(2, i), 15)
			Call Append("<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&amp;tid="& TopicListArray(0, i) &""">"& TopicListArray(2, i) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a>"& IIF(TopicListArray(5, i) = 1, "[精]", "") &"<br />")
		Next
	End If
End Sub

'========================================================
'收藏帖子
'========================================================
Sub SaveFavor()
	If RQ.UserID = 0 Then
		Call WapMessage("登陆后才能使用此功能。", "")
	End If

	Dim TopicInfo, FavorInfo
	Dim strTips

	TopicInfo = RQ.Query("SELECT fid FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call WapMessage("帖子不存在或者已经被删除。", "")
	End If

	FavorInfo = RQ.Query("SELECT 1 FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID &" AND tid = "& RQ.TopicID)
	If IsArray(FavorInfo) Then
		RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID &" AND tid = "& RQ.TopicID)
		strTips = "该帖子已经从您的收藏夹移除。"
	Else
		RQ.Execute("INSERT INTO "& TablePre &"favorites (uid, tid) VALUES ("& RQ.UserID &", "& RQ.TopicID &")")
		strTips = "该帖子已经添加到您的收藏夹。"
	End If

	Call closeDatabase()
	Call Append(strTips &"<br /><a href=""viewtopic.asp?fid="& TopicInfo(0, 0) &"&amp;tid="& RQ.TopicID &""">返回刚才的帖子</a>")
End Sub

'========================================================
'我的帖子和收藏
'========================================================
Sub Main()
	If RQ.UserID = 0 Then
		Call WapMessage("登陆后才能使用此功能。", "")
	End If

	Dim TopicListArray, PostListArray, FavorListArray
	'我发表的帖子
	TopicListArray = RQ.Query("SELECT TOP 3 tid, fid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE uid = "& RQ.UserID &" AND displayorder >= -1 ORDER BY lastupdate DESC")

	'我发表的回复
	PostListArray = RQ.Query("SELECT TOP 3 fid, tid, message FROM "& TablePre &"posts WHERE uid = "& RQ.UserID &" AND iffirst = 0 ORDER BY pid DESC")

	'我收藏的帖子
	FavorListArray = RQ.Query("SELECT TOP 3 tid, fid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID &") AND displayorder >= 0 ORDER BY lastupdate DESC")

	Call closeDatabase()

	Call Append("我的帖子<br />")
	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			TopicListArray(2, i) = WapCode(TopicListArray(2, i), 15)
			Call Append("<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&amp;tid="& TopicListArray(0, i) &""">"& TopicListArray(2, i) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a>"& IIF(TopicListArray(5, i) = 1, "[精]", "") &"<br />")
		Next
	End If

	Call Append("<br />我的回复<br />")
	If IsArray(PostListArray) Then
		For i = 0 To UBound(PostListArray, 2)
			PostListArray(2, i) = WapCode(PostListArray(2, i), 15)
			Call Append("<a href=""viewtopic.asp?fid="& PostListArray(0, i) &"&amp;tid="& PostListArray(1, i) &""">"& PostListArray(2, i) &"</a><br />")
		Next
	End If

	Call Append("<br />我的收藏<br />")
	If IsArray(FavorListArray) Then
		For i = 0 To UBound(FavorListArray, 2)
			FavorListArray(2, i) = WapCode(FavorListArray(2, i), 15)
			Call Append("<a href=""viewtopic.asp?fid="& FavorListArray(1, i) &"&amp;tid="& FavorListArray(0, i) &""">"& FavorListArray(2, i) &" ("& FavorListArray(4, i) &"/"& FavorListArray(3, i) &")</a>"& IIF(FavorListArray(5, i) = 1, "[精]", "") &"<br />")
		Next
	End If
End Sub
%>