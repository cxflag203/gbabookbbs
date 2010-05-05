<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim PostID, PostInfo, rndNumber, UserShow

	PostID = SafeRequest(1, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.tid, p.iffirst, p.uid, p.username, p.usershow, p.ifanonymity FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.displayorder >= 0")

	If Not IsArray(PostInfo) Then
		Call Confirm("回复不存在或者已经被删除。")
	End If

	If PostInfo(5, 0) <= 0 Then
		Call RQ.showTips("只能对普通匿名使用"& ItemName &"。", "", "")
	End If

	'随机取2-20之间的数字作为需要消耗的镜子数量
	Randomize
	rndNumber = Int(Rnd * 19 + 2)

	UserShow = IIF(Len("<b>有面子的"& dfc(PostInfo(4, 0)) &"</b>") > 100, PostInfo(4, 0), "<b>有面子的"& dfc(PostInfo(4, 0)) &"</b>")

	RQ.Execute("UPDATE "& TablePre &"posts SET usershow = '"& UserShow &"', ifanonymity = "& rndNumber &" WHERE pid = "& PostID)

	'如果是发帖人则同时也更新帖子作者
	If PostInfo(1, 0) = 1 Then
		RQ.Execute("UPDATE "& TablePre &"topics SET usershow = '"& UserShow &"', ifanonymity = "& rndNumber &" WHERE tid = "& PostInfo(0, 0))
	End If

	If ItemIflog = 1 Then
		RQ.TopicID = PostInfo(0, 0)
		Call RQ.SetItemUserLog(ItemID, PostInfo(2, 0), PostInfo(3, 0), "对回复使用道具")
	End If

	Call closeDatabase()
	Call Confirm(ItemName &"使用成功。")
End If
%>