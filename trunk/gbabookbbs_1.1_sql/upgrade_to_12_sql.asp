<!--#include file="include/common.inc.asp"-->
<!--#include file="gbl.fun.asp"-->
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<title>GBABOOK BBS 1.2 for SQL Server安装程序</title>
<link rel="stylesheet" href="../images/common/common.css" />
<script type="text/javascript" src="../js/common.js"></script>
<script type="text/javascript">var bbsidentify = 'gbabook';</script>
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
	Execute("ALTER TABLE "& TablePre &"members ADD viewtopicstyle tinyint DEFAULT ((0))")
	Execute("UPDATE "& TablePre &"members SET viewtopicstyle = 0")
	Execute("ALTER TABLE "& TablePre &"members ALTER COLUMN viewtopicstyle tinyint NOT NULL")

	Execute("ALTER TABLE "& TablePre &"memberfields ADD avatar varchar(100) DEFAULT ((''))")
	Execute("UPDATE "& TablePre &"memberfields SET avatar = ''")
	Execute("ALTER TABLE "& TablePre &"memberfields ALTER COLUMN avatar varchar(100) NOT NULL")

	Execute("EXEC sp_rename '"& TablePre &"members.[password]', 'thepassword', 'COLUMN'")
	Execute("EXEC sp_rename '"& TablePre &"topictask.[action]', 'theaction', 'COLUMN'")
	Execute("EXEC sp_rename '"& TablePre &"posts.[first]', 'iffirst', 'COLUMN'")

	Execute("ALTER PROCEDURE [dbo].["& TablePre &"sp_newtopic]"& vbCrLf &"@fid smallint,"& vbCrLf &"@typeid tinyint,"& vbCrLf &"@displayorder smallint,"& vbCrLf &"@uid int,"& vbCrLf &"@username nvarchar(20),"& vbCrLf &"@usershow nvarchar(100),"& vbCrLf &"@title nvarchar(255),"& vbCrLf &"@types tinyint,"& vbCrLf &"@special tinyint,"& vbCrLf &"@price int,"& vbCrLf &"@leaguejoinid int,"& vbCrLf &"@iflocked tinyint,"& vbCrLf &"@ifanonymity tinyint,"& vbCrLf &"@ifattachment tinyint,"& vbCrLf &"@message ntext,"& vbCrLf &"@userip char(15),"& vbCrLf &"@tid int output,"& vbCrLf &"@pid int output"& vbCrLf & vbCrLf &"AS"& vbCrLf &"SET NOCOUNT ON"& vbCrLf & vbCrLf &"DECLARE @league_name nvarchar(50)"& vbCrLf &"DECLARE @league_userid int"& vbCrLf &"DECLARE @leagueid smallint"& vbCrLf & vbCrLf &"--验证联盟"& vbCrLf &"SET @leagueid = 0"& vbCrLf &"IF @leaguejoinid > 0 AND @uid > 0"& vbCrLf &"BEGIN"& vbCrLf &"	SELECT @league_userid = lm.uid, @leagueid = lm.leagueid, @league_name = l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.joinid = @leaguejoinid"& vbCrLf &"	IF @league_userid = @uid"& vbCrLf &"		SET @title = N'【' + @league_name + N'】' + @title"& vbCrLf &"END"& vbCrLf & vbCrLf &"--保存帖子信息"& vbCrLf &"INSERT INTO "& TablePre &"topics (fid, typeid, displayorder, uid, username, usershow, title, types, special, price, leagueid, iflocked, ifanonymity, ifattachment)"& vbCrLf &"VALUES (@fid, @typeid, @displayorder, @uid, @username, @usershow, @title, @types, @special, @price, @leagueid, @iflocked, @ifanonymity, @ifattachment)"& vbCrLf & vbCrLf &"--取得新帖子的编号"& vbCrLf &"SELECT @tid = SCOPE_IDENTITY()"& vbCrLf & vbCrLf &"--保存帖子内容"& vbCrLf &"INSERT INTO "& TablePre &"posts (fid, tid, iffirst, uid, username, usershow, message, userip, ifanonymity, ifattachment)"& vbCrLf &"VALUES (@fid, @tid, 1, @uid, @username, @usershow, @message, @userip, @ifanonymity, @ifattachment)"& vbCrLf & vbCrLf &"--取得新回复的编号"& vbCrLf &"SELECT @pid = SCOPE_IDENTITY()"& vbCrLf & vbCrLf &"--如果是联盟贴则进行联盟操作"& vbCrLf &"IF @leagueid > 0"& vbCrLf &"	BEGIN"& vbCrLf &"		INSERT INTO "& TablePre &"leaguetopics (leagueid, tid) VALUES (@leagueid, @tid)"& vbCrLf &"		INSERT INTO "& TablePre &"leaguelogs (leagueid, username, operation) VALUES (@leagueid, @username, N'<b>'+ @title +'</b>('+ @userip +')')"& vbCrLf &"		UPDATE "& TablePre &"leagues SET topics = topics + 1 WHERE leagueid = @leagueid"& vbCrLf &"	END"& vbCrLf & vbCrLf &"--更新版面帖子统计"& vbCrLf &"IF @displayorder = 0"& vbCrLf &"	UPDATE "& TablePre &"forums SET topics = topics + 1 WHERE fid = @fid"& vbCrLf & vbCrLf &"--更新用户帖子统计"& vbCrLf &"IF @uid > 0"& vbCrLf &"	UPDATE "& TablePre &"members SET topics = topics + 1, newtopictime = DateDiff(s, '1970-01-01 0:00:00', GETDATE()) WHERE uid = @uid"& vbCrLf & vbCrLf &"RETURN @tid"& vbCrLf &"RETURN @pid"& vbCrLf &"SET NOCOUNT OFF")

	Execute("ALTER procedure [dbo].["& TablePre &"sp_online_newpm]"& vbCrLf &"@sid char(10),"& vbCrLf &"@uid int,"& vbCrLf &"@username nvarchar(20),"& vbCrLf &"@userip char(15),"& vbCrLf &"@usergroupid smallint,"& vbCrLf &"@onlinehold smallint,"& vbCrLf &"@thetime datetime"& vbCrLf &"AS"& vbCrLf & vbCrLf &"SET NOCOUNT ON"& vbCrLf & vbCrLf &"IF EXISTS(SELECT 1 FROM "& TablePre &"online WHERE sid = @sid AND uid = @uid)"& vbCrLf &"	UPDATE "& TablePre &"online SET uid = @uid, username = @username, userip = @userip, usergroupid = @usergroupid, lastupdate = GetDate() WHERE sid = @sid"& vbCrLf &"ELSE"& vbCrLf &"	BEGIN"& vbCrLf &"		DELETE FROM "& TablePre &"online WHERE sid = @sid OR lastupdate < DATEADD(n, -@onlinehold, GETDATE()) OR (uid > 0 AND uid = @uid) OR (uid = 0 AND userip = @userip AND lastupdate < DATEADD(n, -60, GETDATE()))"& vbCrLf &"		INSERT INTO "& TablePre &"online (sid, uid, username, userip, usergroupid) VALUES (@sid, @uid, @username, @userip, @usergroupid)"& vbCrLf &"	END"& vbCrLf & vbCrLf &"--输出是否有新传呼"& vbCrLf &"IF @uid > 0"& vbCrLf &"	BEGIN"& vbCrLf &"		IF EXISTS(SELECT 1 FROM "& TablePre &"pm WHERE msgtoid = @uid AND posttime <= @thetime)"& vbCrLf &"			RETURN 1"& vbCrLf &"	END"& vbCrLf & vbCrLf &"SET NOCOUNT OFF")

	Execute("CREATE PROCEDURE [dbo].[{tablepre}sp_postlist]"& vbCrLf &"@tid int,"& vbCrLf &"@viewauthorid int,"& vbCrLf &"@viewstyle tinyint,"& vbCrLf &"@page int, "& vbCrLf &"@posts int,"& vbCrLf &"@pagesize smallint"& vbCrLf & vbCrLf &"AS"& vbCrLf &"SET NOCOUNT ON"& vbCrLf & vbCrLf &"DECLARE @recordcount int"& vbCrLf &"DECLARE @pagecount int"& vbCrLf &"DECLARE @sql nvarchar(2000)"& vbCrLf &"DECLARE @sqlpre nvarchar(500)"& vbCrLf &"DECLARE @sqladdon nvarchar(200)"& vbCrLf & vbCrLf &"SET @sqladdon = ''"& vbCrLf & vbCrLf &"IF @viewstyle = 0"& vbCrLf &"	SET @sqlpre = N' p.pid, p.iffirst, p.uid, p.username, p.usershow, p.message, p.posttime, p.ifanonymity, p.ratemark, p.ifattachment FROM {tablepre}posts p'"& vbCrLf &"ELSE"& vbCrLf &"	SET @sqlpre = N' p.pid, p.iffirst, p.uid, p.username, p.usershow, p.message, p.posttime, p.ifanonymity, p.ratemark, p.ifattachment, m.designation, m.avatar FROM {tablepre}posts p LEFT JOIN {tablepre}memberfields m ON p.uid = m.uid'"& vbCrLf & vbCrLf &"IF @viewauthorid = 0"& vbCrLf &"	SET @recordcount = @posts"& vbCrLf &"ELSE"& vbCrLf &"	BEGIN"& vbCrLf &"		SELECT @recordcount = COUNT(pid) FROM {tablepre}posts WHERE tid = @tid AND uid = @viewauthorid AND ifanonymity = 0"& vbCrLf &"		SET @sqladdon = N'AND p.uid = '+ CAST(@viewauthorid AS varchar(10)) +' AND p.ifanonymity = 0'"& vbCrLf &"	END"& vbCrLf & vbCrLf &"IF @recordcount = 0"& vbCrLf &"	SET @recordcount = 1"& vbCrLf &"	"& vbCrLf &"SET @pagecount = CEILING(@recordcount * 1.0 / @pagesize)"& vbCrLf &"IF @page > @pagecount"& vbCrLf &"	SET @page = @pagecount"& vbCrLf & vbCrLf &"IF @page = 1"& vbCrLf &"	SET @sql = N'SELECT TOP '+ CAST((@pagesize + 1) AS varchar(10)) + @sqlpre +' WHERE p.tid = @tid '+ @sqladdon +' ORDER BY p.posttime ASC'"& vbCrLf &"ELSE"& vbCrLf &"	SET @sql = N'SELECT TOP '+ CAST(@pagesize AS varchar(10)) + @sqlpre +' WHERE p.tid = @tid '+ @sqladdon +' AND p.posttime > ("& vbCrLf &"			SELECT MAX(posttime) "& vbCrLf &"			FROM ("& vbCrLf &"					SELECT TOP '+ CAST((@pagesize * (@page - 1) + 1) AS varchar(10))+' posttime"& vbCrLf &"					FROM {tablepre}posts"& vbCrLf &"					WHERE tid = @tid '+ @sqladdon +'"& vbCrLf &"					ORDER BY posttime ASC"& vbCrLf &"				) "& vbCrLf &"			AS tblTemp"& vbCrLf &"		)"& vbCrLf &"		ORDER BY p.posttime ASC'"& vbCrLf & vbCrLf &"EXEC sp_executesql @sql, N'@tid int', @tid = @tid"& vbCrLf & vbCrLf &"UPDATE {tablepre}topics SET clicks = clicks + 1 WHERE tid = @tid"& vbCrLf & vbCrLf &"RETURN @recordcount"& vbCrLf & vbCrLf &"SET NOCOUNT OFF")


	Dim SettingsInfo, Settings
	Dim Base_Settings(4), Time_Settings(3), Login_Settings(6), User_Settings(7), Topic_Settings(17), Other_Settings(5), Chat_Settings(8)

	SettingsInfo = Query("SELECT site_settings FROM "& TablePre &"settings")
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

	Execute("UPDATE "& TablePre &"settings SET base_settings = '"& Join(base_settings, "{settings}") &"', time_settings = '"& Join(time_settings, "{settings}") &"', login_settings = '"& Join(login_settings, "{settings}") &"', user_settings = '"& Join(user_settings, "{settings}") &"', topic_settings = '"& Join(topic_settings, "{settings}") &"', other_settings = '"& Join(other_settings, "{settings}") &"', chat_settings = '"& Join(chat_settings, "{settings}") &"'")

	'更新缓存
	Dim SettingsInfo
	SettingsInfo = Query("SELECT TOP 1 * FROM "& TablePre &"settings")

	If Not IsArray(SettingsInfo) Then
		Call Tips("站点配置错误。", True)
	End If
	Call setCache(CacheName &"_site_settings", SettingsInfo)

	Call closeDatabase()

	Dim strCommon
	strCommon = LoadFile("./include/common.inc.asp")
	strCommon = Preg_Replace(strCommon, "Const SHOWVERSION = ""(.*?)""", "Const SHOWVERSION = ""1.2""")
	Call MakeFile(strCommon, "./include/common.inc.asp")

	On Error Resume Next
	Dim Fso
	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	Call Fso.DeleteFile(Server.MapPath("./upgrade_to_12_sql.asp"))
	Set Fso = Nothing

	Call Tips("升级完毕。<span class=""red"">请登陆FTP，如果发现升级文件还存在，请务必手动删除。</span><br /><a href=""index.asp"" class=""bluelink"">点击这里进入论坛</a>", TRUE)
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
      <td height="25" colspan="2"><strong>GBABOOK BBS V1.01升级V1.1(SQL Server版)</strong></td>
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