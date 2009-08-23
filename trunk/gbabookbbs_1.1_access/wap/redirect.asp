<!--#include file="wap.inc.asp"-->
<%
WapHeader()

Dim Action, TopicInfo, RedirectInfo, strOperator

Action = LCase(Request.QueryString("action"))
strOperator = IIF(Action = "next", "<", ">")

TopicInfo = RQ.Query("SELECT fid, lastupdate FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
If Not IsArray(TopicInfo) Then
	Call WapMessage("帖子不存在或者已经被删除。", "")
End If

If Action = "next" Then
	RedirectInfo = RQ.Query("SELECT TOP 1 tid FROM "& TablePre &"topics WHERE fid = "& TopicInfo(0, 0) &" AND lastupdate < #"& TopicInfo(1, 0) &"# AND tid <> "& RQ.TopicID &" AND displayorder >= 0 ORDER BY lastupdate DESC")
	If Not IsArray(RedirectInfo) Then
		Call WapMessage("没有比这个帖子更晚的帖子了。", "")
	End If
Else
	RedirectInfo = RQ.Query("SELECT TOP 1 tid FROM "& TablePre &"topics WHERE fid = "& TopicInfo(0, 0) &" AND lastupdate > #"& TopicInfo(1, 0) &"# AND tid <> "& RQ.TopicID &" AND displayorder >= 0 ORDER BY lastupdate ASC")
	If Not IsArray(RedirectInfo) Then
		Call WapMessage("没有比这个帖子更早的帖子了。", "")
	End If
End If

Call closeDatabase()
Response.Redirect "viewtopic.asp?fid="& TopicInfo(0, 0) &"&tid="& RedirectInfo(0, 0)
%>