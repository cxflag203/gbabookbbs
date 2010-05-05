<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim TopicInfo
	TopicInfo = RQ.Query("SELECT uid, username, iflocked FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")

	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子不存在或者已经被删除。")
	End If

	'验证帖子是否已经被管理员设置为无法打开回复的状态
	If TopicInfo(2, 0) <> 2 Then
		RQ.Execute("UPDATE "& TablePre &"topics SET iflocked = 1 WHERE tid = "& RQ.TopicID)
	End If

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, TopicInfo(0, 0), TopicInfo(1, 0), "对帖子使用道具")
	End If

	Call closeDatabase()
	Call Confirm(ItemName &"使用成功。")
End If
%>