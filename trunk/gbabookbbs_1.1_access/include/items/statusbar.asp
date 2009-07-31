<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim Message, MessageListArray, CacheMessage

	Message = SafeRequest(2, "message", 1, "", 0)
	If Len(Message) = 0 Then
		Call RQ.showTips("请填写好要设置的状态栏内容。", "", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	If Len(Message) > 70 Then
		Message = Left(Message, 70)
	End If

	'保存
	RQ.Execute("INSERT INTO "& TablePre &"itemmessages (itemid, uid, username, message) VALUES ("& ItemID &", "& RQ.UserID &", '"& RQ.UserName &"', '"& Message &"')")

	'更新缓存
	MessageListArray = RQ.Query("SELECT TOP 10 username, message FROM "& TablePre &"itemmessages WHERE itemid = "& ItemID &" ORDER BY posttime DESC")

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, RQ.UserID, RQ.UserName, "设置浏览器状态栏信息")
	End If

	Call closeDatabase()

	CacheMessage = "var msge=""---如对状态栏信息感到不适,可在相关功能中将其关闭--- "
	For i = 0 To UBound(MessageListArray, 2)
		CacheMessage = CacheMessage & MessageListArray(0, i) &":"& MessageListArray(1, i) &"　"
	Next
	CacheMessage = CacheMessage &""";var pos=0;function Scrollit(){window.status=msge.substring(pos,msge.length)+msge.substring(0,pos);pos++;if(pos==msge.length)pos=0;window.setTimeout(""Scrollit()"",180);}Scrollit();"

	Call MakeFile(CacheMessage, "cache/1_rose.js")
	Call RQ.showTips(ItemName &"使用成功。", "", "HALTED")
Else
	Response.Write "<table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"">"& ItemName &"</td></tr><tr><td width=""30%"">请输入状态栏内容：</td><td><input type=""text"" name=""message"" size=""30"" maxlength=""70"" class=""inputgrey"" /> (70字内)</td></tr><tr><td></td><td><input type=""submit"" id=""btnsubmit"" value=""确定"" class=""button"" /></td></tr></table>"
End If
%>