<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim PostID, PostInfo

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.iffirst, p.uid, p.username, p.ifanonymity, t.tid, t.fid FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.displayorder >= 0")

	If Not IsArray(PostInfo) Then
		Call Confirm("回复不存在或者已经被删除")
	End If

	If PostInfo(3, 0) = 1 Then
		RQ.Execute("UPDATE "& TablePre &"posts SET usershow = '<font color=""#FF0000"">'+ username +'</font>', ifanonymity = 0 WHERE pid = "& PostID)

		'是否是发帖人
		If PostInfo(0, 0) = 1 Then
			RQ.Execute("UPDATE "& TablePre &"topics SET usershow = '<font color=""#FF0000"">'+ username +'</font>', ifanonymity = 0 WHERE tid = "& PostInfo(4, 0))
		End If
	End If

	If ItemIflog = 1 Then
		RQ.TopicID = PostInfo(4, 0)
		Call RQ.SetItemUserLog(ItemID, PostInfo(1, 0), PostInfo(2, 0), "对回复使用道具")
	End If

	Call closeDatabase()
	Response.Redirect "viewtopic.asp?fid="& PostInfo(5, 0) &"&tid="& PostInfo(4, 0)
End If
%>