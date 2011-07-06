<!--#include file="include/common.inc.asp"-->
<% ScriptName = "login" %>
<!--#include file="include/sinc.asp"-->
<!--#include file="include/md5.inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "login"
		Call Login()
	Case "clearcookies"
		Call ClearCookies()
	Case Else
		Call Main()
End Select

'=======================================
'用户登陆
'=======================================
Sub Login()
	If RQ.UserID > 0 Then 
		Response.Redirect "index.asp"
		Exit Sub
	End If

	'检查用户是否由于多次登陆失败被锁定
	Call CheckFailedLogins()

	Dim UserID, UserName, Password, InvateCode
	Dim UserInfo

	UserName = SafeRequest(2, "username", 1, "", 0)
	Password = SafeRequest(2, "password", 1, "", 0)
	InvateCode = SafeRequest(2, "invatecode", 1, "", 0)

	'如果没有填写用户名或者密码则跳回登陆页面
	If Len(CheckContent(UserName)) = 0 Or Len(CheckContent(Password)) = 0 Then
		Call Main()
		Exit Sub
	End If

	'如果填写了推荐码则转向推荐码处理
	If Len(CheckContent(InvateCode)) > 0 Then
		Call InvateRegist()
		Exit Sub
	End If

	If Len(Password) > 20 Then
		Call RQ.showTips("密码未免也太长了吧？请控制在20个字符以内。", "", "")
	End If

	Password = MD5(Password)
	UserInfo = RQ.Query("SELECT uid, thepassword FROM "& TablePre &"members WHERE username = '"& UserName &"'")

	'如果用户名有效
	If IsArray(UserInfo) Then
		If UserInfo(1, 0) = Password Then'判断密码是否正确
			UserID = UserInfo(0, 0)
		Else
			Call RecordFailedLogins()'如果密码错误则记录登陆失败
			Call RQ.showTips("该用户已被占用或者密码输入错误。您最多有"& RQ.Login_Settings(6) &"次尝试。", "", "")
		End If
	Else
		Select Case RQ.Login_Settings(0)
			Case "1"'停止注册状态
				Call RQ.showTips("该用户不存在，目前站点已经关闭注册。", "", "HALTED")
			Case "2"'使用推荐码注册
				Call RQ.showTips("该用户不存在，如果您要注册，请输入推荐码。", "", "")
		End Select

		If RQ.Base_Settings(3) = "1" Or RQ.CheckTimeSetting(RQ.Time_Settings(0)) Then
			Call RQ.showTips("目前站点处于关闭状态，不允许注册新用户。", "", "")
		End If

		If Len(UserName) < IntCode(RQ.Login_Settings(3)) Or Len(UserName) > IntCode(RQ.Login_Settings(4)) Then
			Call RQ.showTips("用户名长度应该在"& RQ.Login_Settings(3) &"-"& RQ.Login_Settings(4) &"个字符之间。", "", "")
		End If

		If RegExpTest("(^\{all\}$)|[%,#;:&【】\*\""\s\n\t\\\|\/\^]", UserName) Then
			Call RQ.showTips("注册用户名中包含非法字符，请重新输入。", "", "")
		End If

		If Len(RQ.Login_Settings(2)) > 0 And RegExpTest("^"& Replace(Replace(RQ.Login_Settings(2), vbCrLf, "|"), "*", ".*") &"$", UserName) Then
			Call RQ.showTips("注册用户名中包含系统保留字符，请重新输入。", "", "")
		End If

		RQ.Execute("INSERT INTO "& TablePre &"members (username, thepassword, usergroupid, credits, regip, loginip, lastloginip) VALUES ('"& UserName &"', '"& Password &"', 4, "& RQ.Login_Settings(5) &", '"& RQ.UserIP &"', '"& RQ.UserIP &"', '"& RQ.UserIP &"')")

		UserID = Conn.Execute("SELECT uid FROM "& TablePre &"members WHERE username = '"& UserName &"'")(0)
		dbQueryNum = dbQueryNum + 1

		RQ.Execute("INSERT INTO "& TablePre &"memberfields (uid) VALUES ("& UserID &")")
	End If

	Call closeDataBase()

	Response.Cookies(CacheName &"uc") = XXTEA.encrypt(UserID & Chr(9) & Password, PrivateKey)
	Response.Cookies(CacheName &"uc").Expires = Date() + 365
	'Response.Redirect "index.asp"
	'用js跳转，防止登陆页面在框架里跳转时版面乱掉
	Response.Write "<script type=""text/javascript"">top.location.href='index.asp';</script>"
End Sub

'=======================================
'用户通过推荐码注册
'=======================================
Sub InvateRegist()
	If RQ.Base_Settings(3) = "1" Or RQ.CheckTimeSetting(RQ.Time_Settings(0)) Then
		Call RQ.showTips("目前站点处于关闭状态，不允许注册新用户。", "", "")
	End If
	
	Dim UserID, UserName, Password, InvateCode
	Dim CodeInfo, UserInfo

	UserName = Trim(SafeRequest(2, "username", 1, "", 0))
	Password = Trim(SafeRequest(2, "password", 1, "", 0))
	InvateCode = Trim(SafeRequest(2, "invatecode", 1, "", 0))

	If Len(UserName) < IntCode(RQ.Login_Settings(3)) Or Len(UserName) > IntCode(RQ.Login_Settings(4)) Then
		Call RQ.showTips("用户名长度应该在"& RQ.Login_Settings(3) &"-"& RQ.Login_Settings(4) &"个字符之间。", "", "")
	End If

	If RegExpTest("{all}$|[%,#;:&【】\*\""\s\t\\\|\/\^\$]", UserName) Then
		Call RQ.showTips("注册用户名中包含非法字符，请重新输入。", "", "")
	End If

	If Len(RQ.Login_Settings(2)) > 0 And RegExpTest("^"& Replace(Replace(RQ.Login_Settings(2), vbCrLf, "|"), "*", ".*") &"$", UserName) Then
		Call RQ.showTips("注册用户名中包含系统保留字符，请重新输入。", "", "")
	End If

	CodeInfo = RQ.Query("SELECT 1 FROM "& TablePre &"invate WHERE invatecode = '"& InvateCode &"' AND expirytime >= #"& Now() &"# AND status = 0")
	If Not IsArray(CodeInfo) Then
		Call RQ.showTips("推荐码无效或者已经过期。", "", "")
	End If

	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE username = '"& UserName &"'")
	If IsArray(UserInfo) Then
		Call RQ.showTips("该用户已经被占用，请返回重新输入。", "", "")
	End If

	Password = MD5(Password)

	'新增用户信息
	RQ.Execute("INSERT INTO "& TablePre &"members (username, thepassword, usergroupid, credits, regip, loginip, lastloginip) VALUES ('"& UserName &"', '"& Password &"', 4, "& RQ.Login_Settings(5) &", '"& RQ.UserIP &"', '"& RQ.UserIP &"', '"& RQ.UserIP &"')")

	'获取uid
	UserID = Conn.Execute("SELECT uid FROM "& TablePre &"members WHERE username = '"& UserName &"'")(0)
	dbQueryNum = dbQueryNum + 1

	'更新推荐码状态
	RQ.Execute("UPDATE "& TablePre &"invate SET status = 1, reguid = "& UserID &", regtime = "& DatetoNum(Now()) &" WHERE invatecode = '"& InvateCode &"'")

	'新增用户附表信息
	RQ.Execute("INSERT INTO "& TablePre &"memberfields (uid) VALUES ("& UserID &")")

	'删除已过期的推荐码
	RQ.Execute("DELETE FROM "& TablePre &"invate WHERE expirytime < #"& Now() &"# AND status = 0")

	Call closeDataBase()

	Response.Cookies(CacheName &"uc") = XXTEA.encrypt(UserID & Chr(9) & Password, PrivateKey)
	Response.Cookies(CacheName &"uc").Expires = Date() + 365
	'Response.Redirect "index.asp"
	'用js跳转，防止登陆页面在框架里跳转时版面乱掉
	Response.Write "<script type=""text/javascript"">top.location.href='index.asp';</script>"
End Sub

'=======================================
'查询当前用户是否被列入禁止登陆列表
'=======================================
Sub CheckFailedLogins()
	Dim FailedInfo

	'删除已过期的禁止登陆记录
	RQ.Execute("DELETE FROM "& TablePre &"failedlogins WHERE locktime < #"& Now() &"#")

	FailedInfo = RQ.Query("SELECT 1 FROM "& TablePre &"failedlogins WHERE userip = '"& RQ.UserIP &"' AND falsecount >= "& IntCode(RQ.Login_Settings(6)))
	If IsArray(FailedInfo) Then
		Call RQ.showTips("由于你连续"& RQ.Login_Settings(6) &"次输入密码错误，30分钟内系统禁止登陆。", "", "HALTED")
	End If
End Sub

'=======================================
'记录用户登陆失败的次数
'=======================================
Sub RecordFailedLogins()
	Dim FailedInfo

	FailedInfo = RQ.Query("SELECT 1 FROM "& TablePre &"failedlogins WHERE userip = '"& RQ.UserIP &"'")

	If IsArray(FailedInfo) Then
		RQ.Execute("UPDATE "& TablePre &"failedlogins SET falsecount = falsecount + 1, locktime = #"& DateAdd("n", 30, Now()) &"# WHERE userip = '"& RQ.UserIP &"'")
	Else
		RQ.Execute("INSERT INTO "& TablePre &"failedlogins (userip, locktime) VALUES ('"& RQ.UserIP &"', #"& DateAdd("n", 30, Now()) &"#)")
	End If
End Sub

'=======================================
'退出登陆
'=======================================
Sub ClearCookies()
	RQ.Execute("DELETE FROM "& TablePre &"online WHERE sid = '"& RQ.UserSessionID &"'")

	Call closeDatabase()

	Response.Cookies(CacheName &"un") = ""
	Response.Cookies(CacheName &"un").Expires = Now() - 1
	Response.Cookies(CacheName &"uc") = ""
	Response.Cookies(CacheName &"uc").Expires = Now() - 1
	Response.Cookies(CacheName &"chatroom") = ""
	Response.Redirect "index.asp"
End Sub

'=======================================
'登陆/注册界面
'=======================================
Sub Main()
	If RQ.UserID > 0 Then
		Response.Write "<script type=""text/javascript"">top.location.href='index.asp';</script>"
		'Response.Redirect "index.asp"
		Exit Sub
	End If

	RQ.Header()
%>
<body>
<form name="login" onSubmit="return validinput();" method="post" action="?action=login">
<table border="0" cellpadding="0" cellspacing="0" class="login_dialog" align="center">
<tr><td>
<div class="user_login">
  <div><h1>用户登陆</h1></div>
  <p><h2>用户名</h2>
  <input type="text" name="username" id="username" size="20" maxlength="20" class="input" tabindex="1" />
  <br />
  <h2>密码</h2>
  <input type="password" name="password" id="password" size="20" maxlength="16" class="input" tabindex="2" />
  <br />
  <% If RQ.Login_Settings(0) = "2" Then '推荐码注册 %>
  <h2>推荐码</h2>
  <input type="text" name="invatecode" size="20" class="input" tabindex="3" />
  <br />
  <% End If %>
  <input type="submit" id="btnsubmit" value="确定" class="button" tabindex="4" />
  <% If RQ.Login_Settings(0) = "0" Then '开放注册%>
  (新用户可填写好用户名、密码直接注册)
  <% ElseIf RQ.Login_Settings(0) = "1" Then '关闭注册%>
  (站点已经关闭注册)
  <% ElseIf RQ.Login_Settings(0) = "2" Then '推荐码注册%>
  (新用户请确认用户名、密码无误，并填写好推荐码)
  <% End If %>
  <div class="extras">
    <ul>
	  <li><a href="pwdsafe.asp" class="bluelink">忘记密码</a></li>
	</ul>
  </div>
  </div>
  </td></tr>
</table>
</form>
<script type="text/javascript">
$('username').focus();
function validinput(){
	if ($('username').value.length == 0){
		alert("请输入用户名。");
		$('username').focus();
		return false;
	}
	if ($('password').value.length == 0){
		alert("请输入密码。");
		$('password').focus();
		return false;
	}
}
</script>
<% 
	RQ.Footer()
End Sub 
%>