<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim TopicInfo, NewTitle, Color

	TopicInfo = RQ.Query("SELECT uid, username, title FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子不存在或者已经被删除。")
	End If

	Color = SafeRequest(2, "color", 1, "", 0)

	If RegExpTest("^#([0-9a-fA-F]{6}$)", Color) Then'正则表达式验证颜色代码

		NewTitle = Preg_Replace(TopicInfo(2, 0), "<font color=(.*?)>(.*?)</font>", "$2")'提取标题
		NewTitle = "<font color="""& Color &""">"& Left(NewTitle, 200) &"</font>"

		RQ.Execute("UPDATE "& TablePre &"topics SET title = '"& NewTitle &"' WHERE tid = "& RQ.TopicID)
	End If

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, TopicInfo(0, 0), TopicInfo(1, 0), "对帖子使用道具")
	End If

	Call closeDatabase()
	Call Confirm(ItemName &"使用成功")
End If
%>