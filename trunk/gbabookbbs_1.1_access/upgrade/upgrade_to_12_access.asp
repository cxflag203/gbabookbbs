<!--#include file="../include/common.inc.asp"-->
<% Response.Charset = "utf-8" %>
<!--#include file="../include/gbl.fun.asp"-->
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<title>GBABOOK BBS 1.2 for Access安装程序</title>
<link rel="stylesheet" href="../images/common/common.css" />
<script type="text/javascript" src="../js/common.js"></script>
</head>
<%
Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "upgrade"
		Call Upgrade()
	Case Else
		Call Main()
End Select

'========================================================
'执行升级操作
'========================================================
Sub Upgrade()
	Execute("ALTER TABLE "& TablePre &"members ADD viewtopicstyle tinyint DEFAULT 0")
	Execute("UPDATE "& TablePre &"members SET viewtopicstyle = 0")
	Execute("ALTER TABLE "& TablePre &"members ALTER COLUMN viewtopicstyle tinyint NOT NULL")

	Execute("ALTER TABLE "& TablePre &"memberfields ADD avatar varchar(100) DEFAULT """"")
	Execute("UPDATE "& TablePre &"memberfields SET avatar = ''")
	Execute("ALTER TABLE "& TablePre &"memberfields ALTER COLUMN avatar varchar(100) NOT NULL")

	Execute("SELECT * INTO "& TablePre &"settings_tmp FROM "& TablePre &"settings")

	Execute("DROP TABLE "& TablePre &"settings")

	Execute("CREATE TABLE "& TablePre &"settings(base_settings ntext NOT NULL,time_settings ntext NOT NULL,login_settings ntext NOT NULL,user_settings ntext NOT NULL,topic_settings ntext NOT NULL,other_settings ntext NOT NULL,chat_settings ntext NOT NULL,wap_settings ntext NOT NULL,item_settings ntext NOT NULL,wordsfilter ntext NOT NULL DEFAULT """",banip text NOT NULL DEFAULT """",banner ntext NOT NULL DEFAULT """",todayposts int NOT NULL DEFAULT 0,invatenum int NOT NULL DEFAULT 0)")

	Dim MyDB, MyTable
	Set MyDB = Server.CreateObject("ADOX.Catalog")
	Set MyTable = Server.CreateObject("ADOX.Table")

	MyDB.ActiveConnection = Conn
	Set MyTable = MyDB.Tables(TablePre &"settings")
	MyTable.Columns("wordsfilter").Properties("Jet OLEDB:Allow Zero Length") = True
	MyTable.Columns("banip").Properties("Jet OLEDB:Allow Zero Length") = True
	MyTable.Columns("banner").Properties("Jet OLEDB:Allow Zero Length") = True
	Set MyTable = Nothing
	Set MyDB = Nothing

	Dim SettingsInfo, Settings
	Dim Base_Settings(4), Time_Settings(3), Login_Settings(6), User_Settings(7), Topic_Settings(17), Other_Settings(5), Chat_Settings(8)

	SettingsInfo = Query("SELECT site_settings, item_settings, wordsfilter, banip, banner, todayposts, invatenum FROM "& TablePre &"settings_tmp")
	If Not IsArray(SettingsInfo) Then
		Call showTips("错误的站点设置。", "", "")
	End If

	Settings = Split(SettingsInfo(0, 0), "_____SETTINGS_____")
	For i = 0 To 4
		Base_Settings(i) = Settings(i)
	Next

	For i = 0 To 3
		Time_Settings(i) = Settings(i + 5)
	Next

	For i = 0 To 6
		Login_Settings(i) = Settings(i + 9)
	Next

	For i = 0 To 7
		User_Settings(i) = Settings(i + 17)
	Next

	For i = 0 To 4
		Topic_Settings(i) = Settings(i + 25)
	Next
	Topic_Settings(5) = "2"
	For i = 6 To 17
		Topic_Settings(i) = Settings(i + 24)
	Next

	For i = 0 To 5
		Other_Settings(i) = Settings(i + 42)
	Next

	For i = 0 To 8
		Chat_Settings(i) = Settings(i + 48)
	Next

	SettingsInfo(1, 0) = Replace(SettingsInfo(1, 0), "_____SETTINGS_____", "{settings}")

	Execute("INSERT INTO "& TablePre &"settings (base_settings, time_settings, login_settings, user_settings, topic_settings, other_settings, chat_settings, wap_settings, item_settings, wordsfilter, banip, banner, todayposts, invatenum) VALUES ('"& Join(base_settings, "{settings}") &"', '"& Join(time_settings, "{settings}") &"', '"& Join(login_settings, "{settings}") &"', '"& Join(user_settings, "{settings}") &"', '"& Join(topic_settings, "{settings}") &"', '"& Join(other_settings, "{settings}") &"', '"& Join(chat_settings, "{settings}") &"', '1{settings}0{settings}0{settings}10{settings}10{settings}500', '"& SettingsInfo(1, 0) &"', '"& SettingsInfo(2, 0) &"', '"& SettingsInfo(3, 0) &"', '"& SettingsInfo(4, 0) &"', "& SettingsInfo(5, 0) &", "& SettingsInfo(6, 0) &")")

	Execute("DROP TABLE "& TablePre &"settings_tmp")

	'更新缓存
	SettingsInfo = Query("SELECT TOP 1 * FROM "& TablePre &"settings")
	If Not IsArray(SettingsInfo) Then
		Call Tips("错误的站点设置。", True)
	End If

	Call setCache(CacheName &"_site_settings", SettingsInfo)

	Call closeDatabase()

	Dim strCommon
	strCommon = LoadFile("../include/common.inc.asp")
	strCommon = Preg_Replace(strCommon, "Const SHOWVERSION = ""(.*?)""", "Const SHOWVERSION = ""1.2""")
	strCommon = Preg_Replace(strCommon, "Const ROOTPATH = ""(.*?)""", "")
	strCommon = Preg_Replace(strCommon, "dbSource = Server.MapPath\(ROOTPATH &""(.*?)""\)", "dbSource = ""$1""")
	strCommon = Preg_Replace(strCommon, "Data Source=""& dbSource", "Data Source=""& Server.MapPath(dbSource)")
	Call MakeFile(strCommon, "../include/common.inc.asp")

	On Error Resume Next
	Dim Fso
	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	Call Fso.DeleteFolder(Server.MapPath("../upgrade"))
	Set Fso = Nothing

	Call Tips("升级完毕。<span class=""red"">请登陆FTP，如果发现upgrade目录还存在，请务必手动删除。</span><br /><a href=""../index.asp"" class=""bluelink"">点击这里进入论坛</a>", TRUE)
End Sub

'========================================================
'查询SQL语句(写操作使用)
'========================================================
Public Function Execute(sql)
	'Response.Write sql &"<br />"
	Dim n
	If Not IsObject(Conn) Then
		Call connectDatabase()
	End If
	Conn.Execute(sql), n
	dbQueryNum = dbQueryNum + 1
	Execute = n
End Function

'========================================================
'查询SQL语句(读操作使用)
'========================================================
Public Function Query(sql)
	'Response.write sql &"<br />"
	If Not IsObject(Conn) Then
		Call connectDatabase()
	End If
	Set Rs = Conn.Execute(sql)
	If Not Rs.EOF And Not Rs.BOF Then 
		Query = Rs.GetRows()
	Else
		Query = 0
	End If
	Rs.Close
	Set Rs = Nothing
	dbQueryNum = dbQueryNum + 1
End Function

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
		Response.Write "</body></html>"
		Response.End()
	End If
End Sub

'========================================================
'显示升级界面
'========================================================
Sub Main()
%>
<br />
<br />
<table width="600" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0px auto;">
  <tr class="header">
    <td>提示信息</td>
  </tr>
  <tr>
    <td>强烈建议您先关闭网站，再进行升级。如果您在升级过程中遇到任何问题，请到<a href="http://www.gbabook.net/" target="_blank" class="underline">官方论坛</a>求助。</td>
  </tr>
</table>
<br />
<form method="post" id="install" action="?action=upgrade" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="600" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0px auto;">
    <tr class="header">
      <td height="25" colspan="2"><strong>GBABOOK BBS V1.1升级V1.2(Access版)</strong></td>
    </tr>
	<tr height="25">
      <td>&nbsp;</td>
      <td><input type="submit" id="btnsubmit" value="点击运行升级程序" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub
%>
</body>
</html>