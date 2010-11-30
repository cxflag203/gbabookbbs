<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "sql"
		Call SQL()
	Case "executesql"
		Call ExecuteSQL()
	Case "backupdatabase"
		Call BackupDatabase()
	Case "deletebackup"
		Call DeleteBackup()
	Case "deletelog"
		Call DeleteLog()
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
		Call AdminshowTips("请输入要执行的SQL语句。", "")
	End If

	On Error Resume Next
	n = RQ.Execute(strSQL)
	If Err Then
		Call AdminshowTips("执行SQL语句出现错误，错误信息为：<br /><span class=""red"">"& Err.Description &"</span>", "")
		Err.Clear
	End If

	Call closeDatabase()
	Call AdminshowTips("SQL语句执行成功，共有"& n &"行受到影响。", "")
End Sub

'========================================================
'备份数据库
'========================================================
Sub BackupDatabase()
	If Request.Form("do") <> "backupdatabase" Then
		Call AdminShowTips("未定义操作。", "")
	End If

	On Error Resume Next

	RQ.Execute("BACKUP DATABASE ["& dbName &"] TO DISK=N'"& Server.MapPath("../database_backup/") &"\backup_"& Year(Now()) & Right("0"& Month(Now()), 2) & Right("0"& Day(Now()), 2) & Right("0"& Hour(Now()), 2) & Right("0"& Minute(Now()), 2) & Right("0"& Second(Now()), 2) &"_"& Rand(10) &".rar'")

	If Err Then
		Call closeDatabase()
		Call AdminshowTips("备份数据库时发生错误，原因为：<br />"& Err.Description, "")
		Err.Clear
	End If

	Call closeDatabase()
	Call AdminshowTips("数据库备份完成。", "?")
End Sub

'========================================================
'删除数据库备份
'========================================================
Sub DeleteBackup()
	Dim Fso, bakFolder, FileName

	If Request.Form("filename").Count = 0 Then
		Call AdminShowTips("请选中要删除的备份。", "")
	End If

	bakFolder = Server.MapPath("../database_backup/") &"\"

	Set Fso = CreateObject("Scripting.FileSystemObject")
	For i = 1 To Request.Form("filename").Count
		FileName = Request.Form("filename")(i)
		If InStr(FileName, "\") > 0 Or InStr(FileName, "/") > 0 Then
			Call AdminShowTips("文件错误。", "")
		End If

		If Fso.FileExists(bakFolder & FileName) Then
			On Error Resume Next
			Fso.DeleteFile bakFolder & FileName, False
			If Err Then
				Set Fso = Nothing
				Call AdminShowTips("删除备份文件失败，请赋予database_backup目录的写入和删除权限。", "")
			End If
		End If
	Next
	Set Fso = Nothing

	Call closeDatabase()
	Call AdminShowTips("操作完毕。", "?")
End Sub

'========================================================
'截断并清除数据库日志
'========================================================
Sub DeleteLog()
	Dim DoSth
	DoSth = SafeRequest(2, "do", 1, "", 0)
	If DoSth <> "shirklog" Then
		Call AdminShowTips("未定义操作。", "")
	End If

	On Error Resume Next
	RQ.Execute("BACKUP LOG "& dbName &" WITH NO_LOG")
	If Err Then
		Call AdminshowTips("截断日志时发生错误，原因为：<br />"& Err.Description, "")
		Err.Clear
	Else
		RQ.Execute("DBCC SHRINKFILE("& dbName &"_Log,1)")
		If Err Then
			Call AdminshowTips("清除日志时发生错误，原因为：<br />"& Err.Description, "")
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("日志截断并清除完毕。", "?")
End Sub

'========================================================
'SQL语句执行界面
'========================================================
Sub SQL()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;执行SQL语句</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>执行SQL语句是危险操作，并且无法恢复，强烈建议您在<span class="red">备份数据库</span>之后进行操作。如果您对SQL语句不熟悉，请不要执行。
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
'数据库压缩界面
'========================================================
Sub Main()
	Dim dbVersion, dbBakFolder, Fso, bakFolder, bakFiles, Files
	Dim dbListArray, VersionInfo

	'读取数据库版本
	VersionInfo = RQ.Query("SELECT SERVERPROPERTY('ProductVersion')")
	dbVersion = CLng(Split(VersionInfo(0, 0), ".")(0))

	'读取数据库信息
	dbListArray = RQ.Query("SELECT groupid, size, maxsize, name FROM dbo.sysfiles")
	Call closeDatabase()

	'打开Fso组件，读取数据库备份文件夹
	dbBakFolder = Server.MapPath("../database_backup")
	Set Fso = CreateObject("Scripting.FileSystemObject")
	If Not Fso.FolderExists(dbBakFolder) Then
		On Error Resume Next
		Fso.CreateFolder(dbBakFolder)
		If Err Then
			Set Fso = Nothing
			Call AdminShowTips("自动创建备份目录失败。<br />请在bbs所在的目录下手动创建database_backup目录，并赋予该目录写入和删除权限。", "")
		End If
	End If

	i = 0
	Set bakFolder = Fso.GetFolder(dbBakFolder)
	Set bakFiles = bakFolder.Files
	Set bakFolder = Nothing
	Set Fso = Nothing
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;数据库信息和备份</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>
	  1. 只有数据库和网站在一台服务器上才能进行备份；<br />
	  2. 备份数据库最好在“基本设置”中关闭论坛后进行，如果一定要联机备份，请尽量选择在访问人数较少的时段进行；<br />
	  3. 如果您发现数据库日志文件较大，需要清除日志，那么在清除日志前请<span class="red">务必做好数据库备份</span>，以防不测；<br />
	  4. 清除日志功能不支持SQL Server 2008以及以上版本。
	</td>
  </tr>
</table>
<br />
<form method="post" name="compress" action="?action=backupdatabase" onsubmit="$('btnbackup').value='正在提交,请稍后...';$('btnbackup').disabled=true;">
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
<br /><br />
<form name="dblist" method="post" action="?action=deletebackup" onsubmit="javascript:if(!confirm('是否确定要删除选中的备份？'))return false;$('btndelete').value='正在提交,请稍后...';$('btndelete').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="4">已备份的数据库列表(点击文件名下载数据库，下载后请将文件后缀名改为bak)</td>
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
	  <td><a href="../database_backup/<%= Files.Name %>"><%= Files.Name %></a></td>
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
<br />
<br />
<form name="dblist" method="post" action="?action=deletelog" onsubmit="javascript:if(!confirm('是否确定要清除数据库日志？'))return false;$('btndelete').value='正在提交,请稍后...';$('btndelete').disabled=true;">
  <input type="hidden" name="do" value="shirklog" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="4">SQL数据库信息</td>
    </tr>
    <tr class="category">
      <td width="12%">文件组标识</td>
      <td>文件名称</td>
      <td>当前文件大小</td>
      <td>最大文件大小</td>
    </tr>
	<% If IsArray(dbListArray) Then %>
	<% For i = 0 To UBound(dbListArray, 2) %>
    <tr>
      <td><%= dbListArray(0, i) %></td>
	  <td><%= Trim(dbListArray(3, i)) %> (<%= IIF(dbListArray(0, i) = 1, "可能是数据文件", "可能是日志文件") %>)</td>
	  <td><%= FormatNumber(dbListArray(1, i) * 8 / 1024, 2) %> MB</td>
	  <td><%
		Select Case dbListArray(2, i)
			Case 0
				Response.Write "无增长"
			Case -1
				Response.Write "不限制"
			Case Else
				Response.Write dbListArray(2, i) * 8 / 1024 &" MB"
		End Select
	  %></td>
	</tr>
	<% Next %>
	<% End If %>
  </table>
  <p align="center"><% If dbVersion < 10 Then %><input type="submit" id="btndelete" value="截断并清空日志" class="button" /><% End If %></p>
</form>
<%
End Sub
%>