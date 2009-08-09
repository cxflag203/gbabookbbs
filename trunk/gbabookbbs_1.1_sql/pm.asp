<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "HALTED")
End If

Dim Action, IfSaved
Action = Request.QueryString("action")
Select Case Action
	Case "send"
		Call Send()
	Case "sendpost"
		Call SendPost()
	Case "reply"
		Call Reply()
	Case "save"
		Call Save()
	Case "showfavor"
		Call ShowFavor()
	Case "deletefavor"
		Call DeleteFavor()
	Case "deleteallfavor"
		Call DeleteAllFavor()
	Case "saveignorepm"
		Call SaveIgnorePm()
	Case "ignorepm"
		Call IgnorePm()
	Case Else
		Call ShowPm()
End Select

'========================================================
'发送传呼
'========================================================
Sub Send()
	If IntCode(RQ.User_Settings(6)) > 0 And RQ.UserCredits < IntCode(RQ.User_Settings(6)) And RQ.DisablePmCtrl = 0 Then
		Call Confirm(RQ.Other_Settings(0) &"达到"& RQ.User_Settings(6) &"就可以发送传呼了哟。")
	End If

	Dim UserName
	UserName = SafeRequest(3, "u", 1, "", 1)

	RQ.PageTitle = "发送传呼"
	RQ.Header()
%>
<body class="blankbg">
<form method="post" action="?action=sendpost" name="post" onKeyDown="fastpost('btnsubmit', event);" onSubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="username" value="<%= UserName %>" />
  <span class="bluebg" style="color: #FFF;">发送信息给<%= UserName %></span><br />
  <textarea rows="5" name="message" cols="35"></textarea><br />
  <input type="submit" name="btnsubmit" id="btnsubmit" value="确定" class="button" />
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'发送传呼(提交)
'========================================================
Sub SendPost()
	If IntCode(RQ.User_Settings(6)) > 0 And RQ.UserCredits < IntCode(RQ.User_Settings(6)) And RQ.DisablePmCtrl = 0 Then
		Call RQ.showTips(RQ.Other_Settings(0) &"达到"& RQ.User_Settings(6) &"就可以发送传呼了哟。", "", "")
	End If

	Dim UserName, UserInfo,  Message, PostTime
	Dim TEMP, TargetUserName
	Dim EffectRowcount, Refer

	UserName = SafeRequest(2, "username", 1, "", 0)
	If Len(CheckContent(UserName)) = 0 Then
		Call RQ.showTips("请填写传呼接收人。", "", "")
	End If

	Message = SafeRequest(2, "message", 1, "", 0)
	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写传呼内容。", "", "")
	End If

	Message = Replace(Message, vbCrLf, "<br />")
	PostTime = SafeRequest(2, "posttime", 2, Now(), 0)
	Refer = Request.QueryString("r")

	'如果输入的接收人包含","字符则判断为批量发送
	If InStr(UserName, ",") > 0 Then
		'联盟盟主和不收传呼限制的人才能批量发传呼
		If RQ.DisablePmCtrl = 0 Then
			Call RQ.showTips("您不能给多人发送传呼。", "", "")
		End If

		TEMP = Split(UserName, ",")
		For i = 0 To UBound(TEMP)
			If Len(TEMP(i)) > 0 And Len(TEMP(i)) <= 20 Then
				TargetUserName = TargetUserName & "N'"& TEMP(i) &"',"
			End If
		Next

		'去除多余的连接符号
		If Right(TargetUserName, 1) = "," Then
			TargetUserName = Left(TargetUserName, Len(TargetUserName) - 1)
		End If

		'批量发送(不检查目标用户的“不接收某人的PM”设置)
		If Len(TargetUserName) > 0 Then
			EffectRowcount = RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message, posttime) SELECT N'"& RQ.UserName &"', "& RQ.UserID &", uid, N'"& Message &"', '"& PostTime &"' FROM "& TablePre &"members WHERE username IN("& TargetUserName &")")
		End If

		Call closeDatabase()

		'返回结果
		If EffectRowcount > 0 Then
			Call RQ.showTips("传呼发送成功。", "membercp.asp", "")
		Else
			Call RQ.showTips("传呼接收人不存在。", "", "")
		End If
	Else
		UserInfo = RQ.Query("SELECT m.uid, mf.ignorepm FROM "& TablePre &"members m INNER JOIN "& TablePre &"memberfields mf ON m.uid = mf.uid WHERE m.username = N'"& UserName &"'")
		If Not IsArray(UserInfo) Then
			Call RQ.showTips("传呼接收人不存在。", "", "")
		End If

		'当前用户是否被接收用户忽略
		If UCase(UserInfo(1, 0)) = "{ALL}" Or InStr(","& UserInfo(1, 0) &",", ","& RQ.UserName &",") > 0 Then
			Call RQ.showTips(UserName &"无法接收您的短信。", "", "")
		End If

		RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message, posttime) VALUES (N'"& RQ.UserName &"', "& RQ.UserID &", "& UserInfo(0, 0) &", N'"& Message &"', '"& PostTime &"')")

		Call closeDatabase()

		If Refer = "mcp" Then
			Call RQ.showTips("传呼发送成功。", "membercp.asp", "")
		Else
			Response.Write "<script type=""text/javascript"">window.close();</script>"
		End If
	End If
End Sub

'========================================================
'接收到传呼后的操作(回复; 延时重发; 批量删除; 删除)
'========================================================
Sub Reply()
	Dim PmID, PmInfo
	Dim Message, PostTime

	PmID = SafeRequest(2, "pmid", 0, 0, 0)
	PmInfo = RQ.Query("SELECT msgfromid, message FROM "& TablePre &"pm WHERE pmid = "& PmID &" AND msgtoid = "& RQ.UserID)

	'验证传呼
	If Not IsArray(PmInfo) Then
		Call RQ.showTips("传呼不存在或者已经被删除。", "", "")
	End If

	'回复
	If Len(Request.Form("btnreply")) > 0 Then
		Message = SafeRequest(2, "message", 1, "", 0)
		If Len(CheckContent(Message)) = 0 Then
			Call RQ.showTips("请填写好回复内容。", "", "")
		End If

		Message = Replace(Message, vbCrLf, "<br />")
		PostTime = SafeRequest(2, "posttime", 2, Now(), 0)

		RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message, remessage, posttime) VALUES (N'"& RQ.UserName &"', "& RQ.UserID &", "& PmInfo(0, 0) &", N'"& Message &"', N'"& PmInfo(1, 0) &"', '"& PostTime &"')")

		RQ.Execute("DELETE FROM "& TablePre &"pm WHERE pmid = "& PmID)
	
	'延时重发
	ElseIf Len(Request.Form("btnresend")) > 0 Then
		PostTime = SafeRequest(2, "posttime", 2, Now(), 0)
		If DateDiff("s", PostTime, Now()) > 0 Then
			PostTime = DateAdd("n", 10, Now())
		End If

		RQ.Execute("UPDATE "& TablePre &"pm SET posttime = '"& PostTime &"' WHERE pmid = "& PmID)

	'批量删除
	ElseIf Len(Request.Form("btndeleteall")) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID &" AND msgfromid = "& PmInfo(0, 0))

	'删除
	ElseIf Len(Request.Form("btndelete")) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"pm WHERE pmid = "& PmID)
	End If

	Call ShowPm()
End Sub

'========================================================
'保存收到的传呼
'========================================================
Sub Save()
	Dim PmID, PmInfo, Message

	PmID = SafeRequest(3, "pmid", 0, 0, 0)
	PmInfo = RQ.Query("SELECT pm.msgfrom, pm.message, pm.remessage, pm.posttime, ISNULL(pms.pmid, 0) FROM "& TablePre &"pm pm LEFT JOIN "& TablePre &"pms pms ON pm.pmid = pms.pmid WHERE pm.pmid = "& PmID &" AND pm.msgtoid = "& RQ.UserID)
	If Not IsArray(PmInfo) Then
		Call RQ.showTips("传呼不存在或者已经被删除。", "", "")
	End If

	If PmInfo(4, 0) = 0 Then
		Message = RQ.UserName &":"& PmInfo(2, 0) &"<br />"& PmInfo(0, 0) &":"& PmInfo(1, 0)
		RQ.Execute("INSERT INTO "& TablePre &"pms (pmid, uid, message, posttime) VALUES ("& PmID &", "& RQ.UserID &", N'"& Message &"', '"& PmInfo(3, 0) &"')")
	End If
	
	IfSaved = True
	Call ShowPm()
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
		PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(2)))))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP "& IntCode(RQ.Topic_Settings(2)) &" pmid, message, posttime FROM "& TablePre &"pms WHERE uid = "& RQ.UserID
		If Page > 1 Then
			strSQL = strSQL &" AND posttime < (SELECT MIN(posttime) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(2)) * (Page - 1) &" posttime FROM "& TablePre &"pms WHERE uid = "& RQ.UserID &" ORDER BY posttime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY posttime DESC"

		PmListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
	RQ.Header()

	If IsArray(PmListArray) Then
		Response.Write "<a href=""###"" onclick=""if(!confirm('所有的传呼记录都将被删除，并且无法恢复。\n\n是否确定？'))return false;postvalue('?action=deleteallfavor', 'do', 'confirm')"">删除全部记录</a><hr color=""black"" />"
		For i = 0 To UBound(PmListArray, 2)
			Response.Write PmListArray(2, i) &" 【<a href=""###"" onclick=""postvalue('?action=deletefavor', 'pmid', '"& PmListArray(0, i) &"');"">删除</a>】<br />"& PmListArray(1, i) &"<hr color=""black"" />"
		Next

		If PageCount > 1 Then
			Call ShowPageInfo(Page, PageCount, RecordCount, "&action=showfavor")
		End If
	End If

	RQ.Footer()
End Sub

'========================================================
'删除传呼记录中某条传呼
'========================================================
Sub DeleteFavor()
	Dim PmID
	PmID = SafeRequest(2, "pmid", 0, 0, 0)
	RQ.Execute("DELETE FROM "& TablePre &"pms WHERE pmid = "& PmID &" AND uid = "& RQ.UserID)

	Call closeDatabase()
	Call RQ.showTips("传呼记录删除完毕。", "?action=showfavor", "")
End Sub

'========================================================
'删除传呼记录中所有传呼
'========================================================
Sub DeleteAllFavor()
	If SafeRequest(2, "do", 1, "", 0) = "confirm" Then
		RQ.Execute("DELETE FROM "& TablePre &"pms WHERE uid = "& RQ.UserID)
	End If
	
	Call closeDatabase()
	Call RQ.showTips("传呼记录已经全部删除。", "?action=showfavor", "")
End Sub

'========================================================
'保存传呼黑名单的设置
'========================================================
Sub SaveIgnorePm()
	Dim UserName

	If Request.Form("do") = "confirm" Then
		UserName = CheckContent(SafeRequest(2, "username", 1, "", 0))
		RQ.Execute("UPDATE "& TablePre &"memberfields SET ignorepm = '"& UserName &"' WHERE uid = "& RQ.UserID)
	End If
	
	Call closeDatabase()
	Call RQ.showTips("传呼黑名单设置成功。", "membercp.asp", "")
End Sub

'========================================================
'设置传呼黑名单界面
'========================================================
Sub IgnorePm()
	Dim UserInfo
	UserInfo = RQ.Query("SELECT ignorepm FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)

	Call closeDatabase()
	RQ.Header()
%>
<div class="warning">
  如果您希望不接收某人向您发送的传呼，可以在这里填入其用户名（注意不要包括称号），添加多个用户时用<strong>英文逗号</strong>隔开，例如：张三,李四。如需禁止所有用户发来的短消息，请设置为<strong>{ALL}</strong>
</div>
<br />
<form method="post" action="?action=saveignorepm" onkeydown="fastpost('btnsubmit', event);" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="do" value="confirm" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td height="25" colspan="2"><strong>设置传呼黑名单</strong></td>
    </tr>
    <tr height="25">
      <td width="30%">请输入用户名</td>
      <td style="padding: 8px 10px;"><textarea name="username" rows="5" cols="40" class="textareagrey" style="width: 90%"><%= UserInfo(0, 0) %></textarea></td>
    </tr>
	<tr height="25">
      <td>&nbsp;</td>
      <td><input type="submit" id="btnsubmit" value="确定" class="button" /></td>
    </tr>
  </table>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'查看
'========================================================
Sub ShowPm()
	Dim PmListArray

	PmListArray = RQ.Query("SELECT pmid, msgfrom, message, remessage, posttime FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID &" AND posttime <= '"& Now() &"' ORDER BY posttime DESC")
	Call closeDataBase()

	RQ.PageTitle = "在线传呼"
	RQ.Header()
%>
<body class="blankbg">
<% Response.Write IIF(IfSaved, "保存完毕!<p>", "") %>
<% If IsArray(PmListArray) Then %>
<% For i = 0 To UBound(PmListArray, 2) %>
<span class="pink"><%= PmListArray(1, i) %></span>给您发送的信息 【<%= PmListArray(4, i) %>】【<a href="?pmid=<%= PmListArray(0, i) %>&action=save">保存</a>】
<hr color="black" />
<% If Len(PmListArray(3, i)) > 0 Then %><span class="grey">re:<%= PmListArray(3, i) %></span><% End If %>
<p><%= PmListArray(2, i) %></p>
<br />
<form method="post" action="?action=reply" name="pm_<%= PmListArray(0, i) %>" onkeydown="fastpost('btnreply_<%= PmListArray(0, i) %>', event);">
  <input type="hidden" name="pmid" value="<%= PmListArray(0, i) %>">
  <p>回复:<textarea rows="5" name="message" cols="35"></textarea></p>
  <p>时间:<input type="text" name="posttime" size="20" value="<%= Now() %>" /></p>
  <p><input type="submit" id="btnreply_<%= PmListArray(0, i) %>" name="btnreply" value="回复<%= PmListArray(1, i) %>" class="button" />
    <input type="submit" name="btnresend" value="延时重发" title="可输入重发时间,不输入则默认为10分钟后重发." class="button" />
	<input type="submit" name="btndeleteall" value="<%= PmListArray(1, i) %>" title="删除<%= PmListArray(1, i) %>所发的全部传呼" style="color: #FF0000; text-decoration: line-through" class="button" />
	<input type="submit" name="btndelete" value="删除" class="button" />
  </p>
</form>
<p>
<hr color="black">
<% Next %>
<% Erase PmListArray %>
<% Else %>
<script type="text/javascript">window.close();</script>
<% End If %>
<%
	RQ.Footer()
End Sub
%>