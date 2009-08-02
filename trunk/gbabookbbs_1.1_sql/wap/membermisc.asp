<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/sinc.asp"-->
<!--#include file="wap.fun.asp"-->
<%
WapHeader()
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "newtopic"
		Call NewTopic()
	Case "elitetopic"
		Call EliteTopic()
	Case Else
		Call Main()
End Select
WapFooter()

'========================================================
'查看新帖
'========================================================
Sub NewTopic()
	Dim TopicListArray
	TopicListArray = RQ.Query("SELECT TOP 10 tid, fid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE displayorder >= 0 ORDER BY tid DESC")

	Call closeDatabase()

	Call Append("最新的10个帖子:<br /><br />")

	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			TopicListArray(2, i) = WapCode(TopicListArray(2, i))
			Call Append("<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&amp;tid="& TopicListArray(0, i) &""">"& IIF(Len(TopicListArray(2, i)) > 15, Left(TopicListArray(2, i), 15) &"...", TopicListArray(2, i)) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a>"& IIF(TopicListArray(5, i) = 1, "[精]", "") &"<br />")
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

	Call Append("精华帖:<br /><br />")
	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			TopicListArray(2, i) = WapCode(TopicListArray(2, i))
			Call Append("<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&amp;tid="& TopicListArray(0, i) &""">"& IIF(Len(TopicListArray(2, i)) > 15, Left(TopicListArray(2, i), 15) &"...", TopicListArray(2, i)) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a>"& IIF(TopicListArray(5, i) = 1, "[精]", "") &"<br />")
		Next
	End If
End Sub

'========================================================
'我的帖子和收藏
'========================================================
Sub Main()
	Dim TopicListArray, PostListArray, FavorListArray
	TopicListArray = RQ.Query
End Sub
%>