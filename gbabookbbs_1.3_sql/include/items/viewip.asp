<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim UserName, UserInfo, SqlWhere, MemberListArray
	Dim strResult

	UserName = SafeRequest(2, "username", 1, "", 0)
	If Len(UserName) = 0 Then
		Call RQ.showTips("请填写好用户名。", "", "")
	End If

	UserInfo = RQ.Query("SELECT uid, username, lastloginip, loginip FROM "& TablePre &"members WHERE username = N'"& UserName &"'")
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("该用户不存在或者已经被删除。", "", "")
	End If

	If UserInfo(2, 0) <> UserInfo(3, 0) Then
		SqlWhere = "(lastloginip = '"& UserInfo(2, 0) &"' OR loginip = '"& UserInfo(3, 0) &"')"
	Else
		SqlWhere = "loginip = '"& UserInfo(3, 0) &"'"
	End If

	MemberListArray = RQ.Query("SELECT username FROM "& TablePre &"members WHERE uid <> "& UserInfo(0, 0) &" AND "& SqlWhere)

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, UserInfo(0, 0), UserInfo(1, 0), "查看用户IP")
	End If

	Call closeDatabase()

	strResult = UserName &"最近一次登陆的IP是："& UserInfo(3, 0)

	If IsArray(MemberListArray) Then
		strResult = strResult &"，同一IP登录的用户还有：<br />"
		For i = 0 To UBound(MemberListArray, 2)
			strResult = strResult & MemberListArray(0, i) &"<br />"
		Next
	End If

	Call RQ.showTips(strResult, "", "HALTED")
	RQ.Footer()
Else
	Response.Write "<table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"">"& ItemName &"</td></tr><tr><td width=""30%"">要查看的用户名：</td><td><input type=""text"" name=""username"" size=""20"" class=""inputgrey"" /></td></tr><tr><td></td><td><input type=""submit"" id=""btnsubmit"" value=""确定"" class=""button"" /></td></tr></table>"
End If
%>