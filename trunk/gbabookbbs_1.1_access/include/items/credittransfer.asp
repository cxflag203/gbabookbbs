<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim Credits, UserName, Password
	Dim UserInfo, LogMessage, Result

	Credits = SafeRequest(2, "credits", 0, 0, 0)
	UserName = SafeRequest(2, "username", 1, "", 0)
	Password = SafeRequest(2, "password", 1, "", 0)

	If Credits = 0 Then
		Call RQ.showTips("请填写好要转让的"& RQ.Other_Settings(0) &"数量。", "", "")
	End If

	If Len(UserName) = 0 Then
		Call RQ.showTips("请填写好接收人。", "", "")
	End If

	If Len(Password) = 0 Then
		Call RQ.showTips("请填写好您的登陆密码。", "", "")
	End If

	'验证密码
	Call Include("./include/md5.inc.asp")
	Password = MD5(Password)
	If Password <> RQ.UserPassword Then
		Call RQ.showTips("密码错误。", "", "")
	End If

	'读取接收人的相关信息
	UserInfo = RQ.Query("SELECT uid, username, credits FROM "& TablePre &"members WHERE username = '"& UserName &"'")

	If Not IsArray(UserInfo) Then
		Call RQ.showTips("输入错误：接收人不存在。", "", "")
	End If

	'减去当前转让人的金币
	RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& Credits &" WHERE uid = "& RQ.UserID)

	'转让数量正确以及接收人的金钱达到15则转让成功
	If RQ.UserCredits >= Credits And UserInfo(2, 0) >= IntCode(RQ.User_Settings(7)) Then
		'判断接收人的金钱数量是否超出上限
		If UserInfo(2, 0) + Credits > 2147483647 Then
			RQ.Execute("UPDATE "& TablePre &"members SET credits = 0 WHERE uid = "& UserInfo(0, 0))
			LogMessage = "转让"& RQ.Other_Settings(0) & Credits &"点，导致"& UserInfo(1, 0) &"的id被爆。("& RQ.UserIP &")"
			Result = RQ.Other_Settings(0) &"转让成功。"
		Else
			RQ.Execute("UPDATE "& TablePre &"members SET credits = credits + "& Credits &" WHERE uid = "& UserInfo(0, 0))
			LogMessage = "转让"& RQ.Other_Settings(0) & Credits &"点。("& RQ.UserIP &")"
			Result = RQ.Other_Settings(0) &"转让成功。"
		End If

		'发送pm通知
		PmMsg = "<strong>系统通知：</strong><p>"& RQ.UserName &"于"& Now() &"向您转让了"& Credits & RQ.Other_Settings(0) &"。<p><em>如果回复此消息，"& RQ.UserName &"将会收到。</em>"
		RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message) VALUES ('"& RQ.UserName &"', "& RQ.UserID &", "& UserInfo(0, 0) &", '"& PmMsg &"')")
	Else 
		LogMessage = "丢失"& RQ.Other_Settings(0) & Credits &"点。("& RQ.UserIP &")"
		Result = RQ.Other_Settings(0) &"转让失败，原因可能是输入的"& RQ.Other_Settings(0) &"数量超过了你持有的数量，或者接收人的"& RQ.Other_Settings(0) &"不足"& IntCode(RQ.User_Settings(7)) &"点。"
	End If

	'记录异动报告
	Call RQ.SetLog(UserInfo(0, 0), UserName, LogMessage, "使用"& ItemName)

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, UserInfo(0, 0), UserInfo(1, 0), Result &"("& Credits &")")
	End If

	Call closeDatabase()
	Call RQ.showTips(Result, "", "HALTED")
Else
	Response.Write "<div class=""warning"">1.转让输入的"& RQ.Other_Settings(0) &"数量不要超过额度，否则您的"& RQ.Other_Settings(0) &"会变成负数，对方也收不到"& RQ.Other_Settings(0) &"。<br />2.如果对方目前"& RQ.Other_Settings(0) &"未达到"& RQ.User_Settings(7) &"将无法收到"& RQ.Other_Settings(0) &"。</div><br /><table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"">"& ItemName &"</td></tr><tr><td width=""30%"">转让数量：</td><td><input type=""text"" name=""credits"" size=""10"" maxlength=""8"" class=""inputgrey"" /> "& RQ.Other_Settings(0) &"</td></tr><tr><td>接收人：</td><td><input type=""text"" name=""username"" size=""20""  class=""inputgrey""/></td></tr><tr><td>您的登陆密码：</td><td><input type=""password"" name=""password"" size=""20""  class=""inputgrey""/></td></tr><tr><td></td><td><input type=""submit"" id=""btnsubmit"" value=""确定"" class=""button"" /></td></tr></table>"
End If
%>