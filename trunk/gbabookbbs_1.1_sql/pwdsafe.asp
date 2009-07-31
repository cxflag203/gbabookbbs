<!--#include file="include/common.inc.asp"-->
<% ScriptName = "pwdsafe" %>
<!--#include file="include/sinc.asp"-->
<!--#include file="include/md5.inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "chk_guestquestion"
		Call Chk_GuestQuestion()
	Case "set_secques"
		Call Set_Secques()
	Case "updatepassword"
		Call UpdatePassword()
	Case Else
		Call Main()
End Select

'========================================================
'检查是否设置了密码保护(游客)
'========================================================
Sub Chk_GuestQuestion()
	Dim UserName, UserInfo

	UserName = SafeRequest(2, "username", 1, "", 0)
	
	If Len(CheckContent(UserName)) = 0 Then
		Call RQ.showTips("请填写好用户名。", "", "")
	End If

	UserInfo = RQ.Query("SELECT secques FROM "& TablePre &"members WHERE username = N'"& UserName &"'")
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("该用户不存在或者已经被删除。", "", "")
	End If

	If Len(UserInfo(0, 0)) = 0 Then 
		Call RQ.showTips("该用户尚未申请密码保护，不能重设密码。", "", "")
	End If

	Call closeDatabase()
	Call Show_ChangePwdPanel()
End Sub

'========================================================
'已登录用户,检查是否设置了密码保护
'========================================================
Sub Check_Question()
	Dim UserInfo
	
	UserInfo = RQ.Query("SELECT secques FROM "& TablePre &"members WHERE uid = "& RQ.UserID)
	Call closeDataBase()

	If IsArray(UserInfo) Then
		If Len(UserInfo(0, 0)) = 0 Then
			Call Show_SetSecquePanel()
		Else
			Call Show_ChangePwdPanel()
		End If
	Else
		RQ.ClearCookies()
		Call RQ.showTips("您的用户信息错误，请重新登陆。", "login.asp", "")
	End If
End Sub

'========================================================
'显示设置密码保护界面
'========================================================
Sub Show_SetSecquePanel()
	RQ.Header()
%>
<body>
<span class="red">您尚未申请密码保护，不能重设密码，请立即申请密码保护。</span>
<p>
<form method="post" action="?action=set_secques">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
	  <td colspan="2"><strong>设置密码保护</strong></td>
    </tr>
	<tr>
	  <td>密码保护问题</td>
	  <td><select name="questionid">
	    <option value="0">--</option>
		<option value="1">小时候梦想长大后的职业是？</option>
		<option value="2">最喜欢的游戏角色是？</option>
		<option value="3">最喜欢动漫中的哪个人物？</option>
		<option value="4">还记得初恋情人的生日吗？</option>
	  </select></td>
	</tr>
	<tr>
	  <td width="40%">回答(20字以内)</td>
	  <td><input type="text" name="answer" size="25" /></td>
	</tr>
	<tr>
	  <td>当前的登陆密码</td>
	  <td><input type="password" name="password" size="25" /></td>
	</tr>
	<tr>
	  <td>&nbsp;</td>
	  <td><input type="submit" name="btnsubmit" value="提交" class="button" /></td>
	</tr>
  </table>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'设置密码保护
'========================================================
Sub Set_Secques()
	Dim QuestionID, Answer, Password
	Dim UserInfo

	QuestionID = SafeRequest(2, "questionid", 1, "", 0)
	Answer = SafeRequest(2, "answer", 1, "", 0)
	Password = SafeRequest(2, "password", 1, "", 0)

	If QuestionID = 0 Then
		Call RQ.showTips("请选择密码保护问题。", "", "")
	End If

	If Len(CheckContent(Answer)) = 0 Then
		Call RQ.showTips("请填写好密码保护的答案。", "", "")
	End If

	If Len(Answer) > 20 Then
		Call RQ.showTips("密码保护的答案不要超过20个字。", "", "")
	End If

	If Len(CheckContent(Password)) = 0 Then
		Call RQ.showTips("请填写好登录密码。", "", "")
	End If

	Password = MD5(Password)

	If Password <> RQ.UserPassword Then
		Call RQ.showTips("您填写的登陆密码错误。", "", "")
	End If
	
	Answer = MD5(QuestionID & Answer)
	RQ.Execute("UPDATE "& TablePre &"members SET secques = '"& Answer &"' WHERE uid = "& RQ.UserID)

	Call closeDatabase()
	Call RQ.showTips("密码保护设置成功。", "?", "")
End Sub

'========================================================
'显示更改密码界面
'========================================================
Sub Show_ChangePwdPanel()
	Dim UserName
	UserName = SafeRequest(2, "username", 1, "", 0)

	RQ.Header()
%>
<body>
<form method="post" action="?action=updatepassword" onkeydown="fastpost('btnsubmit');" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="username" value="<%= UserName %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
	  <td colspan="2"><strong>修改密码</strong></td>
    </tr>
	<tr>
	  <td>密码保护问题</td>
	  <td><select name="questionid">
	    <option value="0">--</option>
		<option value="1">小时候梦想长大后的职业是？</option>
		<option value="2">最喜欢的游戏角色是？</option>
		<option value="3">最喜欢动漫中的哪个人物？</option>
		<option value="4">还记得初恋情人的生日吗？</option>
	  </select></td>
	</tr>
	<tr>
	  <td width="40%">回答(20字以内)</td>
	  <td><input type="text" name="answer" size="25" /></td>
	</tr>
	<tr>
	  <td>新密码</td>
	  <td><input type="password" name="newpassword" size="25" /></td>
	</tr>
	<tr>
	  <td>再输入一次新密码</td>
	  <td><input type="password" name="renewpassword" size="25" /></td>
	</tr>
	<tr>
	  <td>&nbsp;</td>
	  <td><input type="submit" id="btnsubmit" name="btnsubmit" value="提交" class="button" /></td>
	</tr>
  </table>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'修改密码
'========================================================
Sub UpdatePassword()

	Dim QuestionID, Answer, NewPassword, reNewPassword
	Dim UserName, UserInfo

	QuestionID = SafeRequest(2, "questionid", 0, 0, 0)
	Answer = SafeRequest(2, "answer", 1, "", 0)
	NewPassword = SafeRequest(2, "newpassword", 1, "", 0)
	reNewPassword = SafeRequest(2, "renewpassword", 1, "", 0)

	If RQ.UserID > 0 Then
		UserName = RQ.UserName
	Else
		UserName = SafeRequest(2, "username", 1, "", 0)
	End If

	If Len(UserName) = 0 Then
		Call RQ.showTips("用户名错误。", "", "")
	End If

	If QuestionID = 0 Then
		Call RQ.showTips("请选择密码保护的问题。", "", "")
	End If

	If Len(CheckContent(Answer)) = 0 Then
		Call RQ.showTips("请填写好密码保护的答案。", "", "")
	End If

	If Len(Answer) > 20 Then
		Call RQ.showTips("密码保护的答案不要超过20个字。", "", "")
	End If

	If Len(CheckContent(NewPassword)) = 0 Then
		Call RQ.showTips("请填写好新密码。", "", "")
	End If

	If Len(NewPassword) > 20 Then
		Call RQ.showTips("密码不得超过20个字。", "", "")
	End If

	If NewPassword <> reNewPassword Then
		Call RQ.showTips("两次输入的密码应该一致。", "", "")
	End If

	'If LCase(NewPassword) = LCase(UserName) Then
	'	Call RQ.showTips("密码不得和用户名相同。", "", "")
	'End If

	UserInfo = RQ.Query("SELECT uid, secques FROM "& TablePre &"members WHERE username = N'"& UserName &"'")

	If Not IsArray(UserInfo) Then
		RQ.ClearCookies()
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
	End If

	If MD5(QuestionID & Answer) <> UserInfo(1, 0) Then
		Call RQ.showTips("密码保护问题的回答错误。", "", "")
	End If

	NewPassword = MD5(NewPassword)

	RQ.Execute("UPDATE "& TablePre &"members SET thepassword = '"& NewPassword &"' WHERE uid = "& UserInfo(0, 0))

	Call closeDataBase()
	Call RQ.showTips("您的密码已经成功修改，请重新登陆。", "login.asp", "")
End Sub

'========================================================
'默认页面
'========================================================
Sub Main()
	If RQ.UserID > 0 Then
		Call Check_Question()
		Exit Sub
	End If

	RQ.Header()
%>
<body>
<form method="post" action="?action=chk_guestquestion">
  <b>重置密码</b>
  <br />
  请输入您的用户名：<input type="text" name="username" size="20" />
  <input type="submit" value="确定" class="button" />
</form>
<%
	RQ.Footer()
End Sub
%>