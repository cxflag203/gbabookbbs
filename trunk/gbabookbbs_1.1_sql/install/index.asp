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
<title>GBABOOK BBS 1.2 for SQL Server安装程序</title>
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
Public Sub connectDatabase(dbSource, dbName, dbUser, dbPwd)
	On Error Resume Next
	Set Conn = Server.CreateObject("ADODB.Connection")
	Conn.Open("Provider=SQLOLEDB;Data Source="& dbSource &";Initial Catalog="& dbName &";User ID="& dbUser &";Password="& dbPwd)
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
	Dim dbSource, dbPort, dbName, dbUser, dbPwd, TablePre, BBSName
	Dim strSQL, TEMP, Fso
	Dim UserName, Password, rePassword, UserID, UserIP
	Dim CacheName, PrivateKey, ROOTPATH, strConfig

	dbSource = SafeRequest(2, "dbsource", 1, "", 0)
	dbPort = SafeRequest(2, "dbport", 0, 1433, 0)
	dbName = SafeRequest(2, "dbname", 1, "", 0)
	dbUser = SafeRequest(2, "dbuser", 1, "", 0)
	dbPwd = SafeRequest(2, "dbpwd", 1, "", 0)
	TablePre = SafeRequest(2, "tablepre", 1, "", 0)
	BBSName = SafeRequest(2, "bbsname", 1, "", 0)
	UserName = SafeRequest(2, "username", 1, "", 0)
	Password = SafeRequest(2, "password", 1, "", 0)
	rePassword = SafeRequest(2, "repassword", 1, "", 0)

	If Len(dbSource) = 0 Then
		Call WarnBack("请填写好数据库地址。")
	End If

	If Len(dbName) = 0 Then
		Call WarnBack("请填写好数据库名称。")
	End If

	If Len(dbUser) = 0 Then
		Call WarnBack("请填写好数据库用户。")
	End If

	If Len(dbPwd) = 0 Then
		Call WarnBack("请填写好数据库密码。")
	End If

	If Len(TablePre) = 0 Then
		Call WarnBack("请填写好表前缀，例如：gb_")
	End If

	If Len(UserName) = 0 Then
		Call WarnBack("请填写好论坛管理员用户名。")
	End If

	If Len(Password) = 0 Then
		Call WarnBack("请填写好论坛管理员密码。")
	End If

	If Password <> rePassword Then
		Call WarnBack("两次输入的管理员密码应该相同。")
	End If

	dbSource = IIF(dbPort = 1433, dbSource, dbSource &","& dbPort)
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

	Call connectDatabase(dbSource, dbName, dbUser, dbPwd)

	On Error Resume Next
	Err.Clear

	strSQL = LoadFile("./database.sql")
	strSQL = Replace(strSQL, "{tablepre}", TablePre)
	strSQL = Replace(strSQL, "{bbsname}", BBSName)

	TEMP = Split(strSQL, "{next}")
	For i = 0 To UBound(TEMP)
		If Len(TEMP(i)) > 0 Then
			Conn.Execute(TEMP(i))
			If Err.Number <> 0 Then
				Call WarnBack("数据库连接错误，返回信息为："& vbCrLf & vbCrLf & Err.Description)
				Err.Clear
			End If
		End If
	Next

	Password = MD5(Password)

	'新增论坛管理员
	Conn.Execute("INSERT INTO "& TablePre &"members (username, thepassword, admingroupid, usergroupid, credits, regip, lastloginip, loginip) VALUES (N'"& UserName &"', '"& Password &"', 1, 1, 9999, '"& UserIP &"', '"& UserIP &"', '"& UserIP &"')")

	'获得userid
	UserID = Conn.Execute("SELECT uid FROM "& TablePre &"members WHERE username = N'"& UserName &"'")(0)

	'插入附表
	Conn.Execute("INSERT INTO "& TablePre &"memberfields (uid) VALUES ("& UserID &")")

	'给管理员添加道具，以免重复操作
	Conn.Execute("INSERT INTO "& TablePre &"memberitems (uid, itemid, num) SELECT "& UserID &", itemid, 9999 FROM "& TablePre &"items")

	Call closeDatabase()

	CacheName = Randc(6)
	PrivateKey = Randc(10)
	ROOTPATH = Preg_Replace(Request.ServerVariables("PATH_INFO"), "install/", "")
	ROOTPATH = Preg_Replace(ROOTPATH, "index.asp", "")

	strConfig = LoadFile("common.tpl")
	strConfig = Replace(strConfig, "{cachename}", CacheName)
	strConfig = Replace(strConfig, "{tablepre}", TablePre)
	strConfig = Replace(strConfig, "{privatekey}", PrivateKey)
	strConfig = Replace(strConfig, "{dbsource}", dbSource)
	strConfig = Replace(strConfig, "{dbname}", dbName)
	strConfig = Replace(strConfig, "{dbuser}", dbUser)
	strConfig = Replace(strConfig, "{dbpwd}", dbPwd)

	Call MakeFile(strConfig, "../include/common.inc.asp")

	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	Fso.DeleteFolder Server.MapPath("../install")
	Set Fso = Nothing
	
	Call Tips("安装完成，<a href=""../index.asp"" class=""bluelink"">点击这里进入论坛</a>。<span class=""red"">请登录FTP，如果发现install目录还存在，请手动删除。</span><img src=""http://stat.gbabook.net/stat.asp?url=http://"& Request.ServerVariables("SERVER_NAME") & ROOTPATH &""" width=""0"" height=""0"" border=""0"" />", True)
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
      <td height="25" colspan="2"><strong>安装GBABOOK BBS V1.2(SQL Server版)</strong></td>
    </tr>
    <tr height="25">
      <td width="50%"><strong>数据库地址:</strong><br />如果数据库和论坛程序在一台服务器，则该处填写(local)，否则填写数据库服务器的IP地址。</td>
      <td><input type="text" name="dbsource" size="20" value="(local)" /></td>
    </tr>
    <tr height="25">
      <td width="50%"><strong>数据库端口:</strong><br />默认1433，如果您不清楚该项，请不要改动。</td>
      <td><input type="text" name="dbport" size="20" value="1433" /></td>
    </tr>
	<tr height="25">
      <td><strong>数据库名称:</strong><br />使用的数据库名称，一般由服务商提供。</td>
      <td><input type="text" name="dbname" size="20" /></td>
    </tr>
	<tr height="25">
      <td><strong>数据库用户:</strong><br />访问该数据库的用户名，一般由服务商提供。</td>
      <td><input type="text" name="dbuser" size="20" /></td>
    </tr>
	<tr height="25">
      <td><strong>数据库密码:</strong><br />访问该数据库的密码，一般由服务商提供。</td>
      <td><input type="password" name="dbpwd" size="20" /></td>
    </tr>
	<tr height="25">
      <td><strong>表前缀:</strong><br />GBABOOK BBS使用了数据表前缀的设置，在一个数据库中可以安装多套GBABOOK BBS，如果您不清楚该项，请勿修改。</td>
      <td><input type="text" name="tablepre" size="20" value="gb_" /></td>
    </tr>
  </table>
  <br />
  <table width="600" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0px auto;">
    <tr class="header">
      <td height="25" colspan="2"><strong>设置论坛信息</strong></td>
    </tr>
	<tr height="25">
      <td><strong>论坛名称:</strong></td>
      <td><input type="text" name="bbsname" size="20" value="GBABOOK BBS" /></td>
    </tr>
    <tr height="25">
      <td width="50%"><strong>管理员帐号:</strong></td>
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
<%
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
%>
</body>
</html>