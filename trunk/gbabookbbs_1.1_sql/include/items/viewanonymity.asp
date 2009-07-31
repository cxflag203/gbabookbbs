<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim PostID, PostInfo

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.tid, p.uid, p.username, p.ifanonymity FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.displayorder >= 0")

	RQ.TopicID = PostInfo(0, 0)

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, PostInfo(1, 0), PostInfo(2, 0), "对回复使用道具")
	End If

	Call closeDatabase()

	If Not IsArray(PostInfo) Then
		Call Confirm("回复不存在或者已经被删除。")
	End If

	If PostInfo(3, 0) = 1 Then
		Call Confirm("该回复的发言人是:"& PostInfo(2, 0))
	End If
End If
%>