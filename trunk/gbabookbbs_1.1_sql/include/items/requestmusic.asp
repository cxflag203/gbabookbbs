<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

If Action = "useitem" Then
	Dim URL, Name, Sendto, Message
	Dim ItemMessage, RecordCount, MessageListArray, TEMP, CacheMessage

	URL = SafeRequest(2, "url", 1, "", 0)
	Name = SafeRequest(2, "name", 1, "", 0)
	Sendto = SafeRequest(2, "sendto", 1, "", 0)
	Message = SafeRequest(2, "message", 1, "", 0)

	If Len(CheckContent(URL)) = 0 Or Len(URL) > 200 Then
		Call RQ.showTips("请填写好歌曲地址，字符长度请控制在200个以内。", "", "")
	End If

	If Len(CheckContent(Name)) = 0 Or Len(Name) > 50 Then
		Call RQ.showTips("请填写好歌曲名字，字符长度请控制在50个字以内。", "", "")
	End If

	ItemMessage = URL &"{music}"& Name &"{music}"& Sendto &"{music}"& Message

	'保存
	RQ.Execute("INSERT INTO "& TablePre &"itemmessages (itemid, uid, username, message) VALUES ("& ItemID &", "& RQ.UserID &", N'"& RQ.UserName &"', N'"& ItemMessage &"')")

	'统计总数
	RecordCount = Conn.Execute("SELECT COUNT(messageid) FROM "& TablePre &"itemmessages WHERE itemid = "& ItemID)(0)

	'只保留最新的30条
	If RecordCount > 30 Then
		RQ.Execute("DELETE FROM "& TablePre &"itemmessages WHERE itemid = "& ItemID &" AND posttime < (SELECT MIN(posttime) FROM (SELECT TOP 30 posttime FROM "& TablePre &"itemmessages WHERE itemid = "& ItemID &" ORDER BY posttime DESC) AS tblTEMP)")
	End If

	'更新列表
	MessageListArray = RQ.Query("SELECT username, message FROM "& TablePre &"itemmessages WHERE itemid = "& ItemID &" ORDER BY posttime DESC")

	If ItemIflog = 1 Then
		Call RQ.SetItemUserLog(ItemID, RQ.UserID, RQ.UserName, "设置音乐栏")
	End If

	Call closeDatabase()

	For i = 0 To UBound(MessageListArray, 2)
		TEMP = Split(MessageListArray(1, i), "{music}")

		CacheMessage = CacheMessage &"mkList("""& TEMP(0) &""","""& MessageListArray(0, i) &"点一首《"& TEMP(1) &"》"

		If Len(TEMP(2)) > 0 Then
			CacheMessage = CacheMessage &"送给"& TEMP(2)
		End If

		If Len(TEMP(3)) > 0 Then
			CacheMessage = CacheMessage &"，"& TEMP(3)
		End If

		CacheMessage = CacheMessage &""");"& vbCrLf
	Next

	Call MakeFile(CacheMessage, "cache/1_song.js")
	Call RQ.showTips(ItemName &"使用成功。", "", "HALTED")
Else
	Response.Write "<table width=""98%"" border=""0"" cellpadding=""0"" cellspacing=""0"" class=""tblborder""><tr class=""header""><td colspan=""2"">"& ItemName &"</td></tr><tr><td width=""30%"">歌曲地址：</td><td><input type=""text"" name=""url"" maxlength=""200"" class=""inputgrey"" /> (支持wma/mp3，必填)</td></tr><tr><td width=""30%"">歌曲名字：</td><td><input type=""text"" name=""name"" maxlength=""50"" class=""inputgrey"" /> (必填)</td></tr><tr><td width=""30%"">接收人：</td><td><input type=""text"" name=""sendto"" maxlength=""50""  class=""inputgrey""/></td></tr><tr><td width=""30%"">祝福的话：</td><td><input type=""text"" name=""message"" maxlength=""50"" class=""inputgrey"" /></td></tr><tr><td></td><td><input type=""submit"" id=""btnsubmit"" value=""确定"" class=""button"" /></td></tr></table>"
End If
%>