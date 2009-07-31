<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	'清除过期的置顶帖
	Call RQ.ClearStickTopic()

	Dim TopicInfo, FloatTime

	TopicInfo = RQ.Query("SELECT t.fid, t.displayorder, t.uid, t.username, t.lastupdate, t.iftask, IIF(tt.expirytime IS NULL, '"& Now() &"', tt.expirytime) FROM "& TablePre &"topics t LEFT JOIN "& TablePre &"topictask tt ON t.tid = tt.tid WHERE t.tid = "& RQ.TopicID &" AND t.displayorder >= 0")

	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子不存在或者还没有通过审核。")
	End If

	FloatTime = DateAdd("h", IntCode(RQ.Item_Settings(3)), Now())

	'只有普通帖子和被有版面置顶限制的的帖子才生效
	If TopicInfo(1, 0) = 0 Or (TopicInfo(1, 0) = 1 And TopicInfo(5, 0) = 1) Then

		If TopicInfo(5, 0) = 0 Then
			RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 1, iftask = 1 WHERE tid = "& RQ.TopicID)
			RQ.Execute("INSERT INTO "& TablePre &"topictask (tid, expirytime, theaction, itemid) VALUES ("& RQ.TopicID &", #"& FloatTime &"#, 'STICK', "& ItemID &")")
			Call RQ.UpdateStickTopic(TopicInfo(0, 0), RQ.TopicID, 1)

		ElseIf FloatTime > TopicInfo(6, 0) Then
			RQ.Execute("UPDATE "& TablePre &"topictask SET expirytime = #"& FloatTime &"# WHERE tid = "& RQ.TopicID)
		End If
	End If

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, TopicInfo(2, 0), TopicInfo(3, 0), "对帖子使用道具")
	End If

	Call closeDatabase()
	Call Confirm("帖子已经浮上来了。")
End If
%>