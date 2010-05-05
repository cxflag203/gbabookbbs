<%
If Not INGBABOOK Then
	Call ShowErr("ACCESS DENIED")
End If

If Action = "useitem" Then
	Dim UserName, UserInfo, OnlineInfo, ItemListArray

	UserName = SafeRequest(2, "username", 1, "", 0)
	If Len(UserName) = 0 Then
		Call RQ.showTips("请填写好用户名。", "", "")
	End If

	UserInfo = RQ.Query("SELECT m.uid, username, m.usergroupid, m.admingroupid, m.credits, m.regtime, m.logintime, m.logincount, m.topics, m.posts, mf.designation, g.allowdirectpost, g.allowreply, g.allowhtml FROM "& TablePre &"members m INNER JOIN "& TablePre &"memberfields mf ON m.uid = mf.uid INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.username = N'"& UserName &"'")

	If Not IsArray(UserInfo) Then
		Call RQ.showTips("用户不存在或者已经被删除。", "", "HALTED")
	End If

	OnlineInfo = RQ.Query("SELECT 1 FROM "& TablePre &"online WHERE uid = "& UserInfo(0, 0))
	ItemListArray = RQ.Query("SELECT mi.num, i.name FROM "& TablePre &"memberitems mi INNER JOIN "& TablePre &"items i ON mi.itemid = i.itemid WHERE mi.uid = "& UserInfo(0, 0) &" ORDER BY i.displayorder ASC")

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, UserInfo(0, 0), UserInfo(1, 0), "查看用户资料")
	End If

	Call closeDatabase()

	RQ.Header()
	Response.Write "<body class=""blankbg""><table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"" style=""height:30px""><strong>用户信息</strong></td></tr><tr><td width=""50%"">用户名</td><td>"& UserInfo(1, 0) & IIF(Len(UserInfo(10, 0)) > 0, "【"& UserInfo(10, 0) &"】", "") &"</td></tr><tr><td>ID登记时间</td><td>"& UserInfo(5, 0) &"</td></tr><tr><td>目前"& RQ.Other_Settings(0) &"</td><td>"& UserInfo(4, 0) &" ("& CLng(RQ.UserCredits / IIF(UserInfo(4, 0) = 0, 1, UserInfo(4, 0))) &")</td></tr><tr><td>忠诚度</td><td>"& FormatPercent(UserInfo(7, 0) / (DateDiff("d", UserInfo(5, 0), Now()) + 1), 0) &"</td></tr><tr><td>有无管理权限</td><td>"& IIF(UserInfo(3, 0) > 0, "有", "无") &"</td></tr><tr><td>是否处于黑名单</td><td>"& IIF(UserInfo(2, 0) = 6, "是", "否") &"</td></tr><tr><td>是否处于发帖审核</td><td>"& IIF(UserInfo(11, 0) = 0, "是", "否") &"</td></tr><tr><td>回帖状态</td><td>"& IIF(UserInfo(12, 0) = 1, "正常", "禁止") &"</td></tr><tr><td>Html状态</td><td>"& IIF(UserInfo(13, 0) = 1, "正常", "禁止") &"</td></tr><tr><td>发帖</td><td>"& UserInfo(8, 0) &"</td></tr><tr><td>回帖</td><td>"& UserInfo(9, 0) &"</td></tr><tr><td>最近一次访问时间</td><td>"& UserInfo(6, 0) &"</td></tr><tr><td colspan=""2"" align=""center"">目前"& IIF(IsArray(OnlineInfo), "在线", "不在线") &"</td></tr></table>"

	If IsArray(ItemListArray) Then
		Response.Write "<br /><table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"" style=""height:30px""><strong>用户道具</strong></td></tr>"
		For i = 0 To UBound(ItemListArray, 2)
			Response.Write "<tr><td width=""50%"">"& ItemListArray(1, i) &"</td><td>"& ItemListArray(0, i) &"</td></tr>"
		Next
		Response.Write "</table>"
	End If
	RQ.Footer()
Else
	Response.Write "<table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"">"& ItemName &"</td></tr><tr><td width=""30%"">想TK谁？</td><td><input type=""text"" name=""username"" size=""20"" class=""inputgrey"" /></td></tr><tr><td></td><td><input type=""submit"" id=""btnsubmit"" value=""确定"" class=""button"" /></td></tr></table>"
End If
%>