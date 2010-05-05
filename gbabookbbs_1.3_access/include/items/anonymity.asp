<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim PostID, PostInfo, UserShow

	PostID = SafeRequest(3, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.fid, p.tid, p.iffirst, p.uid, p.username, p.ifanonymity FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.displayorder >= 0")

	If Not IsArray(PostInfo) Then
		Call RQ.showTips("回复不存在或者已经被删除。", "", "")
	End If

	If PostInfo(3, 0) > 0 And PostInfo(5, 0) = 0 Then
		UserShow = "<b>"& RQ.Topic_Settings(12) & Get_AnonymityCode() &"</b>"

		RQ.Execute("UPDATE "& TablePre &"posts SET usershow = '"& UserShow &"', ifanonymity = 1 WHERE pid = "& PostID)

		If PostInfo(2, 0) = 1 Then
			RQ.Execute("UPDATE "& TablePre &"topics SET usershow = '"& UserShow &"', ifanonymity = 1 WHERE tid = "& PostInfo(1, 0))
		End If
	End If

	If ItemIflog = 1 Then
		RQ.TopicID = PostInfo(1, 0)
		Call RQ.SetItemUserLog(ItemID, PostInfo(3, 0), PostInfo(4, 0), "对回复使用道具")
	End If

	Call closeDataBase()
	Response.Redirect "viewtopic.asp?fid="& PostInfo(0, 0) &"&tid="& PostInfo(1, 0)
End If

'========================================================
'匿名时后面的数字表现形式
'========================================================
Function Get_AnonymityCode()
	Dim IpArray, Number

	If RQ.Topic_Settings(13) = "1" Then
		IpArray = Split(RQ.UserIP, ".")
		For i = 0 To UBound(IpArray)
			Number = (Number + 1) * 7 + IpArray(i) * 6
		Next
	Else
		Randomize
		Number = (Number + Int((874 - 253 + 1) * Rnd + 253)) * 874
	End If

	Get_AnonymityCode = Number
End Function
%>