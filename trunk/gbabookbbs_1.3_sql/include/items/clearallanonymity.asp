<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim PostID, PostInfo

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.ifanonymity, t.tid, t.fid, t.ifanonymity FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND p.ifanonymity = 1 AND t.displayorder >= 0")

	If IsArray(PostInfo) Then
		RQ.Execute("UPDATE "& TablePre &"posts SET usershow = N'<font color=""#FF0000"">'+ username +'</font>', ifanonymity = 0 WHERE tid = "& PostInfo(1, 0) &" AND ifanonymity = 1")

		'发帖人是否匿名
		If PostInfo(3, 0) = 1 Then
			RQ.Execute("UPDATE "& TablePre &"topics SET usershow = N'<font color=""#FF0000"">'+ username +'</font>', ifanonymity = 0 WHERE tid = "& PostInfo(1, 0))
		End If

		If ItemIflog = 1 Then
			RQ.TopicID = PostInfo(1, 0)
			Call RQ.SetItemUserLog(ItemID, 0, "", "对回复使用道具")
		End If
	End If

	Call closeDatabase()
	Response.Redirect "viewtopic.asp?fid="& PostInfo(2, 0) &"&tid="& PostInfo(1, 0)
End If
%>