<% @LANGUAGE="VBSCRIPT" CODEPAGE = 65001 EnableSessionState = False %>
<% Option Explicit %>
<!--#include file="../include/gbl.fun.asp"-->
<!--#include file="../include/md5.inc.asp"-->
<%
Response.Buffer = True
Response.CharSet = "utf-8"
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<title>GBABOOK BBS V1.2 安装程序</title>
<link rel="stylesheet" href="../images/common/common.css" />
<script type="text/javascript" src="../js/common.js"></script>
<script type="text/javascript">var bbsidentify = 'gbabook';</script>
</head>

<body>
<%
Dim Action, Rs, Conn, i

Action = Request.QueryString("action")
Select Case Action
	Case "install"
		Call Install()
	Case Else
		Call Main()
End Select

'========================================================
'连接数据库
'========================================================
Public Sub connectDatabase(dbSource)
	On Error Resume Next
	Set Conn = Server.CreateObject("ADODB.Connection")
	Conn.Open("Provider=Microsoft.Jet.OLEDB.4.0;Data Source="& Server.MapPath(dbSource))
	If Err <> 0 Then
		Set Conn = Nothing
		Call WarnBack("数据库连接错误，返回信息为："& vbCrLf & vbCrLf & Err.Description)
		Err.Clear
		Response.End()
	End If
End Sub

'========================================================
'关闭数据库
'========================================================
Public Sub closeDatabase()
	On Error Resume Next
	Rs.Close
	Set Rs = Nothing
	Conn.Close
	Set Conn = Nothing
End Sub

'========================================================
'随机生成长度为n的字符串
'========================================================
Public Function Randc(n)
	Dim str, length, hash, i
	str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	length = Len(str)
	Randomize
	For i = 1 To n
		hash = hash & Mid(str, Int((length * Rnd) + 1), 1)
	Next
	Randc = hash
End Function

'========================================================
'安装论坛
'========================================================
Sub Install()
	Dim dbSource, BBSName
	Dim UserName, Password, rePassword, UserID, UserIP
	Dim CacheName, PrivateKey, ROOTPATH, strConfig
	Dim Fso

	BBSName = SafeRequest(2, "bbsname", 1, "", 0)
	UserName = SafeRequest(2, "username", 1, "", 0)
	Password = SafeRequest(2, "password", 1, "", 0)
	rePassword = SafeRequest(2, "repassword", 1, "", 0)

	If Len(UserName) = 0 Then
		Call WarnBack("请填写好论坛管理员用户名。")
	End If

	If Len(Password) = 0 Then
		Call WarnBack("请填写好论坛管理员密码。")
	End If

	If Password <> rePassword Then
		Call WarnBack("两次输入的管理员密码应该相同。")
	End If

	BBSName = IIF(Len(BBSName) = 0, "默认论坛", BBSName)

	'获取用户IP
	If Len(Request.ServerVariables("HTTP_X_FORWARDED_FOR")) = 0 Or InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), "unknown") > 0 Then
		UserIP = Request.ServerVariables("REMOTE_ADDR")
	ElseIf InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ",") > 0 Then
		UserIP = Mid(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), 1, InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ",") - 1)
	ElseIf InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ";") > 0 Then
		UserIP = Mid(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), 1, InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ";") - 1)
	Else
		UserIP = Request.ServerVariables("HTTP_X_FORWARDED_FOR")
	End If

	UserIP = Trim(strFilter(UserIP))
	UserIP = IIF(Len(UserIP) > 15, Left(UserIP, 15), UserIP)

	ROOTPATH = Preg_Replace(Request.ServerVariables("PATH_INFO"), "install/", "")
	ROOTPATH = Preg_Replace(ROOTPATH, "index.asp", "")
	dbSource = "#"& Randc(20) &".mdb"

	'复制数据库
	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	Fso.CopyFile Server.MapPath("./database.mdb"), Server.MapPath("../database/"& dbSource), False
	Set Fso = Nothing

	Call connectDatabase("../database/"& dbSource)

	Password = MD5(Password)
	'新增论坛管理员
	Conn.Execute("INSERT INTO gb_members (username, thepassword, admingroupid, usergroupid, credits, regip, lastloginip, loginip) VALUES ('"& UserName &"', '"& Password &"', 1, 1, 9999, '"& UserIP &"', '"& UserIP &"', '"& UserIP &"')")

	'获得userid
	UserID = Conn.Execute("SELECT uid FROM gb_members WHERE username = '"& UserName &"'")(0)

	'插入附表
	Conn.Execute("INSERT INTO gb_memberfields (uid) VALUES ("& UserID &")")

	'给管理员添加道具，以免重复操作
	Conn.Execute("INSERT INTO gb_memberitems (uid, itemid, num) SELECT "& UserID &", itemid, 9999 FROM gb_items")

	'插入版面设置
	Conn.Execute("INSERT INTO [gb_settings] ([base_settings], [time_settings], [login_settings], [user_settings], [topic_settings], [other_settings], [chat_settings], [wap_settings], [item_settings], [wordsfilter], [banip], [banner], [todayposts], [invatenum]) VALUES ('"& BBSName &"{settings}{settings}{settings}{settings}0{settings}站点维护中', '{settings}{settings}{settings}', '0{settings}login.asp{settings}{settings}1{settings}20{settings}100{settings}5', '15{settings}3{settings}3{settings}20{settings}200{settings}5{settings}0{settings}15', '100{settings}10000{settings}100{settings}0{settings}100{settings}2{settings}<p>{settings}标题党帖{settings}3{settings}5{settings}3{settings}1{settings}神秘黑衣大哥哥{settings}0{settings}1{settings}60{settings}{username}企图匿名，但是可耻的失败了<img src=""face/846.gif"" />{settings}edit', '金币{settings}60{settings}1000{settings}1{settings}0{settings}1', '1{settings}300{settings}5{settings}15{settings}500{settings}300{settings}20{settings}100{settings}勤劳的家庭主妇{username}把房间打扫得干干净净。', '1{settings}0{settings}0{settings}10{settings}10{settings}500', '1{settings}60{settings}24{settings}72{settings}2{settings}4{settings}100{settings}4700{settings}470{settings}170{settings}17{settings}7', '', '', '当初所坚持的心情，是不是还依然存在', 0, 99)")

	Call closeDatabase()

	CacheName = Randc(6)
	PrivateKey = Randc(10)

	strConfig = LoadFile("common.tpl")
	strConfig = Replace(strConfig, "{cachename}", CacheName)
	strConfig = Replace(strConfig, "{privatekey}", PrivateKey)
	strConfig = Replace(strConfig, "{dbsource}", dbSource)

	Call MakeFile(strConfig, "../include/common.inc.asp")

	On Error Resume Next

	'删除安装目录
	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	Fso.DeleteFolder Server.MapPath("../install")
	Set Fso = Nothing

	Call Tips("安装完成，<a href=""../index.asp"" class=""bluelink"">点击这里进入论坛</a>。<span class=""red"">请登录FTP，如果发现install目录还存在，请手动删除。</span><img src=""http://stat.gbabook.net/stat.asp?url=http://"& Request.ServerVariables("SERVER_NAME") & ROOTPATH &""" width=""0"" height=""0"" border=""0"" />", True)
End Sub

'========================================================
'检查FSO权限
'========================================================
Sub CheckObject()
	On Error Resume Next

	Dim Fso, tFile
	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	If Err <> 0 Then
		Call Tips("您的空间不支持FSO组件，请联系空间提供商。", True)
		Err.Clear
	End If

	'创建文件
	If Not Fso.FileExists(Server.MapPath("../include/delete.me")) Then
		Set tFile = Fso.CreateTextFile(Server.MapPath("../include/delete.me"))
		If Err <> 0 Then
			Call Tips("您的空间支持FSO组件，但是没有文件（目录）的写权限，请联系空间提供商。", True)
			Err.Clear
		End If
		Set tFile = Nothing
	End If

	'删除文件
	Call Fso.DeleteFile(Server.MapPath("../include/delete.me"))
	If Err <> 0 Then
		Call Tips("您的空间支持FSO组件，但是没有文件（目录）的删除权限，您可以继续安装论坛，但是您无法使用论坛的全部功能（例如删除附件）。<br /><span class=""red"">在安装完成后，请务必登陆FTP，删除install目录。</span>", False)
		Err.Clear
	End If

	Set Fso = Nothing
End Sub

'========================================================
'输出提示信息
'========================================================
Sub Tips(str, blnExit)
%>
<table width="600" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0px auto;">
  <tr class="header">
    <td>提示信息</td>
  </tr>
  <tr>
    <td><%= str %></td>
  </tr>
</table>
<%
	If blnExit Then
		Response.End()
	End If
End Sub

'========================================================
'安装界面
'========================================================
Sub Main()
	Call CheckObject()
%>
<br />
<br />
<form method="post" id="install" action="?action=install" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="600" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0px auto;">
    <tr class="header">
      <td height="25" colspan="2"><strong>安装GBABOOK BBS V1.2(ACCESS版)</strong></td>
    </tr>
	<tr height="25">
      <td width="50%"><strong>论坛名称:</strong></td>
      <td><input type="text" name="bbsname" size="20" value="GBABOOK BBS" /></td>
    </tr>
    <tr height="25">
      <td><strong>管理员帐号:</strong></td>
      <td><input type="text" name="username" size="20" /></td>
    </tr>
	<tr height="25">
      <td><strong>管理员密码:</strong></td>
      <td><input type="password" name="password" size="20" /></td>
    </tr>
	<tr height="25">
      <td><strong>确认密码:</strong></td>
      <td><input type="password" name="repassword" size="20" /></td>
    </tr>
	<tr height="25">
      <td>&nbsp;</td>
      <td><input type="submit" id="btnsubmit" value="设置完毕，安装论坛" class="button" /></td>
    </tr>
  </table>
</form>
<% End Sub %>
</body>
</html>