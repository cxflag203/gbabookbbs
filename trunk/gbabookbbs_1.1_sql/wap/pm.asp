<!--#include file="wap.inc.asp"-->
<%
WapHeader()

If RQ.UserID = 0 Then
	Call WapMessage("登陆后才能使用此功能。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "delete"
		Call Delete()
	Case "save"
		Call Save()
	Case "postreply"
		Call PostReply()
	Case "reply"
		Call Reply()
	Case "postnewpm"
		Call PostNewPm()
	Case "sendpm"
		Call SendPm()
	Case "showfavor"
		Call ShowFavor()
	Case "newpmlist"
		Call NewPmList()
	Case Else
		Call Main()
End Select
WapFooter()

'========================================================
'删除传呼
'========================================================
Sub Delete()
	Dim PmID, PmInfo

	PmID = SafeRequest(3, "pmid", 0, 0, 0)
	PmInfo = RQ.Query("SELECT 1 FROM "& TablePre &"pm WHERE pmid = "& PmID &" AND msgtoid = "& RQ.UserID)
	If Not IsArray(PmInfo) Then
		Call WapMessage("传呼不存在或者已经被删除。", "")
	End If

	RQ.Execute("DELETE FROM "& TablePre &"pm WHERE pmid = "& PmID)

	Call closeDatabase()
	Call Append("指定的传呼已经成功删除。<br /><a href=""pm.asp?action=newpmlist"">返回传呼列表</a><br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'保存传呼
'========================================================
Sub Save()
	Dim PmID, PmInfo, Message

	PmID = SafeRequest(3, "pmid", 0, 0, 0)
	PmInfo = RQ.Query("SELECT pm.msgfrom, pm.message, pm.remessage, pm.posttime, ISNULL(pms.pmid, 0) FROM "& TablePre &"pm pm LEFT JOIN "& TablePre &"pms pms ON pm.pmid = pms.pmid WHERE pm.pmid = "& PmID &" AND pm.msgtoid = "& RQ.UserID)
	If Not IsArray(PmInfo) Then
		Call WapMessage("传呼不存在或者已经被删除。", "")
	End If

	If PmInfo(4, 0) = 0 Then
		Message = RQ.UserName &":"& PmInfo(2, 0) &"<br />"& PmInfo(0, 0) &":"& PmInfo(1, 0)
		RQ.Execute("INSERT INTO "& TablePre &"pms (pmid, uid, message, posttime) VALUES ("& PmID &", "& RQ.UserID &", N'"& Message &"', '"& PmInfo(3, 0) &"')")
	End If
	
	Call closeDatabase()
	Call Append("传呼已经保存，您可以在“传呼记录”中查询。<br /><a href=""pm.asp?action=newpmlist"">返回传呼列表</a><br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'回复传呼
'========================================================
Sub PostReply()
	Dim PmID, PmInfo, Message

	PmID = SafeRequest(3, "pmid", 0, 0, 0)
	PmInfo = RQ.Query("SELECT msgfromid, message FROM "& TablePre &"pm WHERE pmid = "& PmID &" AND msgtoid = "& RQ.UserID)

	'验证传呼
	If Not IsArray(PmInfo) Then
		Call WapMessage("传呼不存在或者已经被删除。", "")
	End If

	Message = SafeRequest(2, "message", 1, "", 0)
	If Len(CheckContent(Message)) = 0 Then
		Call WapMessage("请填写好回复内容。", "")
	End If

	Message = Replace(Message, vbCrLf, "<br />")
	RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message, remessage, posttime) VALUES (N'"& RQ.UserName &"', "& RQ.UserID &", "& PmInfo(0, 0) &", N'"& Message &"', N'"& PmInfo(1, 0) &"', GETDATE())")

	RQ.Execute("DELETE FROM "& TablePre &"pm WHERE pmid = "& PmID)

	Call closeDatabase()
	Call Append("传呼已经成功回复。<br /><a href=""pm.asp?action=newpmlist"">返回传呼列表</a><br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'显示回复传呼的界面
'========================================================
Sub Reply()
	Dim PmID, PmInfo

	PmID = SafeRequest(3, "pmid", 0, 0, 0)
	PmInfo = RQ.Query("SELECT pmid, msgfrom, message, remessage, posttime FROM "& TablePre &"pm WHERE pmid = "& PmID &" AND msgtoid = "& RQ.UserID)

	Call closeDatabase()

	'验证传呼
	If Not IsArray(PmInfo) Then
		Call WapMessage("传呼不存在或者已经被删除。", "")
	End If

	Call Append(PmInfo(1, 0) &"给您发送的信息 ("& PmInfo(4, 0) &")<br />"& IIF(Len(PmInfo(3, 0)) > 0, "re:"& WapCode(PmInfo(3, 0)) &"<br />----------<br />", "") & WapCode(PmInfo(2, 0)) &"<br /><input type=""text"" name=""message"" format=""M*m"" size=""10"" /><anchor title=""回复"">回复<go method=""post"" href=""pm.asp?action=postreply&amp;pmid="& PmInfo(0, 0) &"""><postfield name=""message"" value=""$(message)"" /></go></anchor><br /><a href=""pm.asp?action=delete&amp;pmid="& PmInfo(0, 0) &""">删除</a>|<a href=""pm.asp?action=save&amp;pmid="& PmInfo(0, 0) &""">保存</a><br /><br /><a href=""pm.asp?action=sendpm"">发新传呼</a><br /><a href=""pm.asp?action=newpmlist"">返回传呼列表</a>")
End Sub

'========================================================
'发送新传呼
'========================================================
Sub PostNewPm()
	If IntCode(RQ.User_Settings(6)) > 0 And RQ.UserCredits < IntCode(RQ.User_Settings(6)) And RQ.DisablePmCtrl = 0 Then
		Call WapMessage(RQ.Other_Settings(0) &"达到"& RQ.User_Settings(6) &"就可以发送传呼了哟。", "")
	End If

	Dim UserName, UserInfo,  Message

	UserName = SafeRequest(2, "username", 1, "", 0)
	If Len(CheckContent(UserName)) = 0 Then
		Call WapMessage("请填写传呼接收人。", "")
	End If

	Message = SafeRequest(2, "message", 1, "", 0)
	If Len(CheckContent(Message)) = 0 Then
		Call WapMessage("请填写传呼内容。", "")
	End If

	Message = Replace(Message, vbCrLf, "<br />")

	UserInfo = RQ.Query("SELECT m.uid, mf.ignorepm FROM "& TablePre &"members m INNER JOIN "& TablePre &"memberfields mf ON m.uid = mf.uid WHERE m.username = N'"& UserName &"'")
	If Not IsArray(UserInfo) Then
		Call WapMessage("传呼接收人不存在。", "")
	End If

	'当前用户是否被接收用户忽略
	If UCase(UserInfo(1, 0)) = "{ALL}" Or InStr(","& UserInfo(1, 0) &",", ","& RQ.UserName &",") > 0 Then
		Call WapMessage(UserName &"无法接收您的短信。", "")
	End If

	RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message, posttime) VALUES (N'"& RQ.UserName &"', "& RQ.UserID &", "& UserInfo(0, 0) &", N'"& Message &"', GETDATE())")

	Call closeDatabase()
	Call Append("传呼发送完毕。<br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'发送传呼界面
'========================================================
Sub SendPm()
	If IntCode(RQ.User_Settings(6)) > 0 And RQ.UserCredits < IntCode(RQ.User_Settings(6)) And RQ.DisablePmCtrl = 0 Then
		Call WapMessage(RQ.Other_Settings(0) &"达到"& RQ.User_Settings(6) &"就可以发送传呼了哟。", "")
	End If

	Dim UserName
	UserName = SafeRequest(3, "u", 1, "", 0)

	Call closeDatabase()
	Call Append("接收人:<input type=""text"" name=""username"" value="""& UserName &""" maxlength=""20"" format=""M*m"" /><br />内容:<input type=""text"" name=""message"" value="""" format=""M*m"" /><br /><anchor title=""提交"">提交<go method=""post"" href=""pm.asp?action=postnewpm""><postfield name=""username"" value=""$(username)"" /><postfield name=""message"" value=""$(message)"" /></go></anchor><br /><br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'传呼记录
'========================================================
Sub ShowFavor()
	Dim RecordCount, PageCount, Page
	Dim strSQL, PmListArray

	RecordCount = Conn.Execute("SELECT COUNT(pmid) FROM "& TablePre &"pms WHERE uid = "& RQ.UserID)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Wap_Settings(3)))))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP "& IntCode(RQ.Wap_Settings(3)) &" pmid, message, posttime FROM "& TablePre &"pms WHERE uid = "& RQ.UserID
		If Page > 1 Then
			strSQL = strSQL &" AND posttime < (SELECT MIN(posttime) FROM (SELECT TOP "& IntCode(RQ.Wap_Settings(3)) * (Page - 1) &" posttime FROM "& TablePre &"pms WHERE uid = "& RQ.UserID &" ORDER BY posttime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY posttime DESC"

		PmListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()

	If IsArray(PmListArray) Then
		For i = 0 To UBound(PmListArray, 2)
			Call Append("#"& IntCode(RQ.Wap_Settings(3)) * (Page - 1) + i + 1 &" "& PmListArray(2, i) &"<br />"& WapCode(PmListArray(1, i)) &"<br /><br />")
		Next

		If PageCount > 1 Then
			Call ShowWapPage(Page, PageCount, RecordCount, "&amp;action=showfavor")
		End If
	End If

	Call Append("<br /><br /><a href=""pm.asp?action=sendpm"">发新传呼</a><br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'新传呼列表
'========================================================
Sub NewPmList()
	Dim PmListArray

	PmListArray = RQ.Query("SELECT pmid, msgfrom, message, remessage, posttime FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID &" ORDER BY posttime DESC")
	Call closeDataBase()

	If Not IsArray(PmListArray) Then
		Call WapMessage("您还没有收到新短信。", "")
	End If

	For i = 0 To UBound(PmListArray, 2)
		Call Append("("& i + 1 &"):"& PmListArray(1, i) &"给您发送的信息 ("& PmListArray(4, i) &")<br />"& IIF(Len(PmListArray(3, i)) > 0, "re:"& WapCode(PmListArray(3, i)) &"<br />----------<br />", "") & WapCode(PmListArray(2, i)) &"<br /><a href=""pm.asp?action=reply&amp;pmid="& PmListArray(0, i) &""">回复</a>|<a href=""pm.asp?action=delete&amp;pmid="& PmListArray(0, i) &""">删除</a>|<a href=""pm.asp?action=save&amp;pmid="& PmListArray(0, i) &""">保存</a>")
	
		If i <> UBound(PmListArray, 2) Then
			Call Append("<br /><br />")
		End If
	Next
	Call Append("<br /><br /><a href=""pm.asp?action=sendpm"">发新传呼</a><br /><a href=""pm.asp"">返回传呼首页</a>")
End Sub

'========================================================
'传呼菜单列表
'========================================================
Sub Main()
	Dim NewPmNum
	NewPmNum = Conn.Execute("SELECT COUNT(pmid) FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID)(0)
	Call closeDatabase()

	Call Append("<a href=""pm.asp?action=newpmlist"">未读传呼("& NewPmNum &")</a><br /><a href=""pm.asp?action=showfavor"">传呼记录</a><br /><a href=""pm.asp?action=sendpm"">发送传呼</a>")
End Sub
%>