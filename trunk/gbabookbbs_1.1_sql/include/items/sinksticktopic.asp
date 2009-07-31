<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	'清除过期的置顶帖
	Call RQ.ClearStickTopic()

	Dim TopicInfo, ItemInfo, TimeOffset, NewExpiryTime, strTips

	TopicInfo = RQ.Query("SELECT fid, displayorder, uid, username, iftask FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子不存在或者已经被删除。")
	End If

	If TopicInfo(1, 0) = 1 And TopicInfo(4, 0) = 1 Then
		ItemInfo = RQ.Query("SELECT tt.expirytime, it.identifier FROM "& TablePre &"topictask tt INNER JOIN "& TablePre &"items it ON tt.itemid = it.itemid WHERE tt.tid = "& RQ.TopicID)

		If IsArray(ItemInfo) Then
			Select Case ItemInfo(1, 0)
				Case "sticktopic"
					TimeOffset = IntCode(RQ.Item_Settings(3)) * 60 * (IntCode(RQ.Item_Settings(6)) / 100)
					NewExpiryTime = DateAdd("n", -TimeOffset, ItemInfo(0, 0))

				Case "sticktopicplus"
					TimeOffset = IntCode(RQ.Item_Settings(2)) * 60 * (IntCode(RQ.Item_Settings(5)) / 100)
					NewExpiryTime = DateAdd("n", -TimeOffset, ItemInfo(0, 0))
			End Select

			If NewExpiryTime > Now() Then
				RQ.Execute("UPDATE "& TablePre &"topictask SET expirytime = N'"& NewExpiryTime &"' WHERE tid = "& RQ.TopicID)
			Else
				RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 0, iftask = 0 WHERE tid = "& RQ.TopicID)
				RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
				Call RQ.UpdateStickTopic(TopicInfo(0, 0), RQ.TopicID, 0)
			End If
		Else
			RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 0, iftask = 0 WHERE tid = "& RQ.TopicID)
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
		End If
		strTips = "帖子被射中了。"
	Else
		strTips = "帖子由管理员置顶或者根本不是置顶帖。\n\n不好意思，你射偏了-_,-"
	End If

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, TopicInfo(2, 0), TopicInfo(3, 0), "对帖子使用道具")
	End If

	Call closeDatabase()
	Call Confirm(strTips)
End If
%>