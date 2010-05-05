<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim Sig
	Sig = SafeRequest(2, "sig", 1, "", 1)
	'词语过滤
	Sig = WordsFilter(Sig)

	If Len(Sig) > 100 Then
		Call RQ.showTips("签名太长，请控制在100字以内(注意最好不要包含单引号)。", "", "")
	End If

	RQ.Execute("UPDATE "& TablePre &"memberfields SET signature = N'"& Sig &"' WHERE uid = "& RQ.UserID)

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, RQ.UserID, RQ.UserName, "设置签名")
	End If

	Call closeDatabase()
	Call RQ.showTips("签名设置成功。", "", "HALTED")
Else
	Response.Write "<div class=""warning"">支持html，不要超过100个字。留空提交则为删除签名。</div><br /><table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"">"& ItemName &"</td></tr><tr><td width=""30%"">请输入签名：</td><td><input type=""text"" name=""sig"" size=""30"" maxlength=""100""  class=""inputgrey""/></td></tr><tr><td></td><td><input type=""submit"" id=""btnsubmit"" value=""确定"" class=""button"" /></td></tr></table>"
End If
%>