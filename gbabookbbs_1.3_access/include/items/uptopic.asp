﻿<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim TopicInfo
	TopicInfo = RQ.Query("SELECT uid, username FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子不存在或者已经被删除。")
	End If

	RQ.Execute("UPDATE "& TablePre &"topics SET lastupdate = #"& Now() &"# WHERE tid = "& RQ.TopicID)

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, TopicInfo(0, 0), TopicInfo(1, 0), "对帖子使用道具")
	End If

	Call closeDatabase()
	Call Confirm("吖噗吖噗。帖子已经浮上来了。")
End If
%>