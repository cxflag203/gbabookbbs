<!--#include file="include/inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "submitpoll"
		Call SubmitPoll()
	Case "redirectpost"
		Call RedirectPost()
	Case "upload"
		Call UploadAttachment()
End Select

'========================================================
'提交投票
'========================================================
Sub SubmitPoll()
	If RQ.AllowPoll = 0 Then
		Call RQ.showTips("您还不能参与投票。", "", "")
	End If

	Dim TopicInfo, PollInfo, OptionID, OptionListArray
	Dim TEMP, UserID, VoteUids

	OptionID = NumberGroupFilter(Replace(SafeRequest(2, "optionid", 1, "", 0), " ", ""))

	TopicInfo = RQ.Query("SELECT fid, iflocked FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	If TopicInfo(1, 0) > 0 Then
		Call RQ.showTips("帖子已经关闭，投票无效。", "", "")
	ElseIf Len(OptionID) = 0 Then
		Call RQ.showTips("请选择投票选项。", "", "")
	End If

	TEMP = Split(OptionID, ",")

	PollInfo = RQ.Query("SELECT maxchoices, expirytime FROM "& TablePre &"polls WHERE tid = "& RQ.TopicID)
	If Not IsArray(PollInfo) Then
		Call RQ.showTips("投票不存在或者已经被删除。", "", "NOPERM")
	End If

	'是否过期
	If PollInfo(1, 0) > 0 And PollInfo(1, 0) - DatetoNum(Now()) < 0 Then
		Call RQ.showTips("投票已经过期。", "", "")
	'是否超过允许选择的数量
	ElseIf PollInfo(0, 0) < UBound(TEMP) + 1 Then
		Call RQ.showTips("该投票只允许选择"& PollInfo(0, 0) &"项。", "", "")
	End If

	'根据当前用户的身份来确定验证项目
	UserID = IIF(RQ.UserID > 0, RQ.UserID, RQ.UserIP)

	OptionListArray = RQ.Query("SELECT optionid, voteuids FROM "& TablePre &"polloptions WHERE tid = "& RQ.TopicID)
	If IsArray(OptionListArray) Then
		ReDim ArrayOptionID(UBound(OptionListArray, 2))
		For i = 0 To UBound(OptionListArray, 2)
			If InStr(","& OptionListArray(1, i) &",", ","& UserID &",") > 0 Then
				Call RQ.showTips("您已经投过票了。", "", "")
			End If

			ArrayOptionID(i) = OptionListArray(0, i)
		Next
	End If

	'验证投票选项
	For i = 0 To UBound(TEMP)
		If Not InArray(ArrayOptionID, IntCode(TEMP(i))) Then
			Call RQ.showTips("投票选项无效。", "", "")
		End If
	Next

	'更新选项选择数量，并记录投票人
	OptionListArray = RQ.Query("SELECT optionid, voteuids FROM "& TablePre &"polloptions WHERE optionid IN("& OptionID &")")
	For i = 0 To UBound(OptionListArray, 2)
		VoteUids = IIF(Len(OptionListArray(1, i)) = 0, UserID, OptionListArray(1, i) &","& UserID)
		RQ.Execute("UPDATE "& TablePre &"polloptions SET votes = votes + 1, voteuids = '"& VoteUids &"' WHERE optionid = "& OptionListArray(0, i))
	Next

	RQ.Execute("UPDATE "& TablePre &"polls SET totalpoll = totalpoll + 1 WHERE tid = "& RQ.TopicID)
	RQ.Execute("UPDATE "& TablePre &"topics SET lastupdate = #"& Now() &"# WHERE tid = "& RQ.TopicID)

	Call closeDatabase()
	Response.Redirect "viewtopic.asp?fid="& TopicInfo(0, 0) &"&tid="& RQ.TopicID
End Sub

'========================================================
'定位回复内容在帖子中的位置(查看自回帖时)
'========================================================
Sub RedirectPost()
	Dim PostID, PostInfo, PreRecordCount, RedirectInfo, gotoPage

	PostID = SafeRequest(3, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT fid, tid, posttime FROM "& TablePre &"posts WHERE pid = "& PostID)

	If Not IsArray(PostInfo) Then
		Call RQ.showTips("回复不存在或者已经被删除。", "", "")
	End If

	PreRecordCount = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE tid = "& PostInfo(1, 0) &" AND posttime < #"& PostInfo(2, 0) &"#")(0)
	dbQueryNum = dbQueryNum + 1

	Call closeDatabase()

	gotoPage = ABS(Int(-(PreRecordCount / IntCode(RQ.Topic_Settings(4)))))

	Response.Redirect "viewtopic.asp?fid="& PostInfo(0, 0) &"&tid="& PostInfo(1, 0) &"&page="& gotoPage &"#pid"& PostID
End Sub
%>