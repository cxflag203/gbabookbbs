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

	strSQL = SafeRequest(2, "sql", 1, "", 0)
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
    <td><a href="?" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;执行SQL语句</td>
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
	Dim dbListArray
	dbListArray = RQ.Query("SELECT groupid, size, maxsize, name FROM dbo.sysfiles")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="?" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;数据库信息和清除日志</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>如果您发现数据库日志文件较大，需要清除日志，那么在清除日志前请<span class="red">务必做好数据库备份</span>，以防不测。</td>
  </tr>
</table>
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
  <p align="center"><input type="submit" id="btndelete" value="截断并清空日志" class="button" /></p>
</form>
<%
End Sub
%>