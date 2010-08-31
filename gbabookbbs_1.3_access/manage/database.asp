<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminShowTips("您无权进行访问。", "")
End If

Dim Action, dbFullPath
Action = Request.QueryString("action")
dbFullPath = Server.MapPath(dbSource)

Select Case Action
	Case "sql"
		Call SQL()
	Case "executesql"
		Call ExecuteSQL()
	Case "prepare"
		Call PrePare()
	Case "compressdatabase"
		Call CompressDatabase()
	Case "backupdatabase"
		Call BackupDatabase()
	Case "deletebackup"
		Call DeleteBackup()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'执行SQL语句
'========================================================
Sub ExecuteSQL()
	Dim strSQL, n

	strSQL = Trim(Request.Form("sql"))
	If Len(strSQL) = 0 Then
		Call AdminShowTips("请输入要执行的SQL语句。", "")
	End If

	On Error Resume Next
	n = RQ.Execute(strSQL)
	If Err Then
		Call AdminShowTips("执行SQL语句出现错误，错误信息为：<br /><span class=""red"">"& Err.Description &"</span>", "")
		Err.Clear
	End If

	Call closeDatabase()
	Call AdminShowTips("SQL语句执行成功，共有"& n &"行受到影响。", "")
End Sub

'========================================================
'关闭站点并准备执行
'========================================================
Sub PrePare()
	Dim Dosth
	Dosth = SafeRequest(2, "do", 1, "", 0)

	If Not InArray(Array("compressdatabase", "backupdatabase"), Dosth) Then
		Call AdminShowTips("未定义操作。", "")
	End If

	'关闭站点
	Dim SettingsInfo
	SettingsInfo = Application(CacheName &"_site_settings")
	RQ.Base_Settings(3) = "1"
	RQ.Base_Settings(4) = "站点正在维护数据，请5分钟后再来。"
	SettingsInfo(0, 0) = Join(RQ.Base_Settings, "{settings}")
	Call setCache(CacheName &"_site_settings", SettingsInfo)

	Call closeDatabase()

	Response.Write "<form id=""fmdosth"" method=""post"" action=""?action="& Dosth &"""><input type=""hidden"" name=""do"" value=""confirm"" /></form><table width=""100%"" border=""0"" cellpadding=""2"" cellspacing=""6""><tr><td><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p><table width=""500"" border=""0"" cellpadding=""0"" cellspacing=""0"" align=""center"" class=""tableborder""><tr class=""header""><td>提示</td></tr><tr><td class=""altbg2""><div align=""center""><br /><br /><br />正在关闭站点并执行操作，请不要离开本页……<br /><br /><br /><script type=""text/javascript"">setTimeout(""$('fmdosth').submit();"", 3000);</script><p>&nbsp;</p><p>&nbsp;</p></div></td></tr></table><p>&nbsp;</p><p>&nbsp;</p></td></tr></table>"
End Sub

'========================================================
'获取数据库大小
'========================================================
Function GetdbSize(path)
	Dim Fso, File
	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	Set File = Fso.GetFile(path)
	GetdbSize = FormatNumber(File.Size / (1024 * 1024), 2) &" MB"
	Set File = Nothing
	Set Fso = Nothing
End Function

'========================================================
'压缩数据库
'========================================================
Sub CompressDatabase()
	Dim dbEngine, Fso
	Dim OrgdbSize, CompdbSize, blnCompressError, strTips

	If Request.Form("do") <> "confirm" Then
		Call AdminShowTips("未定义操作。", "")
	End If

	On Error Resume Next

	'关闭数据库
	Conn.Close
	Set Conn = Nothing

	'获取原始数据库大小，在提示信息中显示
	OrgdbSize = GetdbSize(dbFullPath)

	Set dbEngine = Server.CreateObject("JRO.JetEngine")
	'执行压缩，保存为tmp文件
	dbEngine.CompactDatabase "Provider=Microsoft.Jet.OLEDB.4.0;Data Source="& dbFullPath, "Provider=Microsoft.Jet.OLEDB.4.0;Data Source="& dbFullPath &".tmp"
	If Err Then
		strTips = "数据库压缩失败，原因是："& Err.Description
		blnCompressError = True
		Err.Clear
	End If
	Set dbEngine = Nothing

	If Not blnCompressError Then
		'把压缩后的临时文件替换为网站使用的数据库
		Set Fso = Server.CreateObject("Scripting.FileSystemObject")
		Fso.CopyFile dbFullPath &".tmp", dbFullPath
		If Err Then
			strTips = "数据库压缩完毕，但是压缩后的临时文件无法替换目前的数据库，临时文件所在的路径是：<br />"& dbFullPath &".tmp"
			Err.Clear
		Else
			'删除临时文件
			Fso.DeleteFile dbFullPath &".tmp"
			If Err Then
				strTips "数据库压缩完毕，但是系统无法删除数据库临时文件，请登陆FTP手动删除，文件路径是：<br />"& dbFullPath &".tmp"
			Else
				'获取压缩后的数据库大小
				CompdbSize = GetdbSize(dbFullPath)
				strTips = "数据库压缩完毕，压缩前数据库大小为"& OrgdbSize &"，压缩后数据库大小为"& CompdbSize &"。"
			End If
		End If
		Set Fso = Nothing
	End If

	'打开数据库
	Call connectDatabase()

	'开始站点访问
	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call AdminShowTips(strTips, "?")
End Sub

'========================================================
'执行备份数据库操作
'========================================================
Sub BackupDatabase()
	Dim dbBakFolder, Fso, BakFileName
	Dim blnBackupError, strTips

	If Request.Form("do") <> "confirm" Then
		Call AdminShowTips("未定义操作。", "")
	End If

	dbBakFolder = Left(dbFullPath, InstrRev(dbFullPath, "\")) &"backup\"

	On Error Resume Next

	'关闭数据库
	Conn.Close
	Set Conn = Nothing

	'打开Fso组件，验证备份目录
	Set Fso = CreateObject("Scripting.FileSystemObject")
	If Not Fso.FolderExists(dbBakFolder) Then
		Fso.CreateFolder(dbBakFolder)
		If Err Then
			strTips = "备份目录创建失败，原因是："& Err.Description
			blnBackupError = True
		End If
	End If

	If Not blnBackupError Then
		'备份文件名字
		BakFileName = "backup_"& Year(Now()) & Right("0"& Month(Now()), 2) & Right("0"& Day(Now()), 2) & Right("0"& Hour(Now()), 2) & Right("0"& Minute(Now()), 2) & Right("0"& Second(Now()), 2) &"_"& Rand(10) &".rar"

		'复制当前数据库到备份目录
		Fso.CopyFile dbFullPath, dbBakFolder & BakFileName
		If Err Then
			strTips = "复制数据库失败，原因是："& Err.Description
			blnBackupError = True
		Else
			strTips = "数据库备份完毕。"
		End If
		Set Fso = Nothing
	End If

	'打开数据库
	Call connectDatabase()

	'开始站点访问
	Call RQ.Reload_Site_Settings()

	Call closeDatabase()

	If blnBackupError Then
		Call AdminShowTips(strTips, "")
	Else
		Call AdminShowTips(strTips, "?")
	End If
End Sub

'========================================================
'删除备份的数据库
'========================================================
Sub DeleteBackup()
	Dim dbBakFolder, FileName
	Dim Fso

	If Request.Form("filename").Count = 0 Then
		Call AdminShowTips("请选中要删除的备份。", "")
	End If

	'获得当前目录完整路径以及数据库所在的目录
	dbBakFolder = Left(dbFullPath, InstrRev(dbFullPath, "\")) &"backup\"
	Set Fso = CreateObject("Scripting.FileSystemObject")
	For i = 1 To Request.Form("filename").Count
		FileName = Request.Form("filename")(i)
		If InStr(FileName, "\") > 0 Or InStr(FileName, "/") > 0 Then
			Call AdminShowTips("文件错误。", "")
		End If

		If Fso.FileExists(dbBakFolder & FileName) Then
			Fso.DeleteFile dbBakFolder & FileName, False
		End If
	Next
	Set Fso = Nothing

	Call closeDatabase()
	Call AdminShowTips("操作完毕。", "?")
End Sub

'========================================================
'SQL语句执行界面
'========================================================
Sub SQL()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="?" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;执行SQL语句</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>执行SQL语句是危险操作，并且无法恢复，强烈建议您在<a href="?">备份数据库</a>之后进行操作。如果您对SQL语句不熟悉，请不要执行。
	  <br />该处只支持UPDATE、DELETE操作。</td>
  </tr>
</table>
<br />
<form method="post" name="executesql" action="?action=executesql" onsubmit="javascript:if(!confirm('是否确定执行输入的SQL语句？'))return false;$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellspacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>执行SQL语句</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>输入SQL语句:</strong></td>
      <td width="70%"><textarea name="sql" rows="5" cols="50"></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btnsubmit" value="确定执行" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'数据库压缩、备份界面
'========================================================
Sub Main()
	Dim dbBakFolder, dbFolder, TEMP
	Dim Fso, bakFolder, bakFiles, CurrentDbSize, File, Files

	'获得当前目录完整路径以及数据库所在的目录
	dbBakFolder = Left(dbFullPath, InstrRev(dbFullPath, "\")) &"backup\"
	TEMP = Split(dbFullPath, "\")
	dbFolder = TEMP(UBound(TEMP) - 1)

	'打开Fso组件，读取备份文件夹
	Set Fso = CreateObject("Scripting.FileSystemObject")

	Set File = Fso.GetFile(dbFullPath)
	CurrentDbSize = FormatNumber(File.Size / (1024 * 1024), 2) &" MB"
	Set File = Nothing

	If Not Fso.FolderExists(dbBakFolder) Then
		Fso.CreateFolder(dbBakFolder)
	End If

	Set bakFolder = Fso.GetFolder(dbBakFolder)
	Set bakFiles = bakFolder.Files
	Set bakFolder = Nothing
	Set Fso = Nothing
	i = 0
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="?" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;数据库压缩和备份</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>在执行压缩数据库操作前，强烈建议您先<span class="red">备份数据库</span>，以防不测。
	  <br />压缩、备份数据库时，网站会自动暂时关闭，直到执行完成。<span class="red">执行操作时，请不要关闭浏览器。</span></td>
  </tr>
</table>
<br />
<form method="post" name="compress" action="?action=prepare" onsubmit="$('btncompress').value='正在提交,请稍后...';$('btncompress').disabled=true;">
  <input type="hidden" name="do" value="compressdatabase" />
  <table width="98%" class="tableborder" cellspacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>压缩数据库</strong>(当前数据库大小：<%= CurrentDbSize %>)</td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btncompress" value="确定执行" class="button" /></td>
    </tr>
  </table>
</form>
<br />
<form method="post" name="compress" action="?action=prepare" onsubmit="$('btnbackup').value='正在提交,请稍后...';$('btnbackup').disabled=true;">
  <input type="hidden" name="do" value="backupdatabase" />
  <table width="98%" class="tableborder" cellspacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>备份数据库</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btnbackup" value="确定执行" class="button" /></td>
    </tr>
  </table>
</form>
<br />
<form name="dblist" method="post" action="?action=deletebackup" onsubmit="javascript:if(!confirm('是否确定要删除选中的备份？'))return false;$('btndelete').value='正在提交,请稍后...';$('btndelete').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="4">已备份的数据库列表(点击文件名下载数据库，下载后请将文件后缀名改为mdb)</td>
    </tr>
    <tr class="category">
      <td width="8%">删?</td>
      <td>文件名</td>
      <td>文件大小</td>
      <td>备份时间</td>
    </tr>
	<% For Each Files In bakFiles %>
	<% i = i + 1 %>
    <tr>
      <td><input type="checkbox" name="filename" value="<%= Files.Name %>" class="radio" /></td>
	  <td><a href="../<%= dbFolder %>/backup/<%= Files.Name %>"><%= Files.Name %></a></td>
	  <td><%= FormatNumber(Files.Size / (1024 * 1024), 2) %> MB</td>
	  <td><%= Files.DateCreated %></td>
	</tr>
	<% Next %>
	<% Set bakFiles = Nothing %>
	<% If i = 0 Then %>
	<tr>
      <td colspan="4"><em>暂无</em></td>
	</tr>
	<% End If %>
  </table>
  <% If i > 0 Then %><p align="center"><input type="submit" id="btndelete" value="删除选中的备份" class="button" /></p><% End If %>
</form>
<%
End Sub
%>