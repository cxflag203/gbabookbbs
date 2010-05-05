<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 And RQ.AdminGroupID <> 2 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "deletechoosed"
		Call DeleteChoosed()
	Case "dosearchordel"
		Call DoSearchOrDelete()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'删除附件
'========================================================
Sub DeleteChoosed()
	Dim AttachID, AttachListArray, TopicListArray, PostListArray
	Dim TopicIDs, PostIDs, Attachments

	AttachID = NumberGroupFilter(Replace(SafeRequest(2, "attachid", 1, "", 0), " ", ""))
	If Len(AttachID) = 0 Then
		Call AdminshowTips("请选中要删除的附件。", "")
	End If

	AttachListArray = RQ.Query("SELECT tid, pid, savepath FROM "& TablePre &"attachments WHERE aid IN("& AttachID &")")
	If IsArray(AttachListArray) Then
		For i = 0 To UBound(AttachListArray, 2)
			TopicIDs = TopicIDs & AttachListArray(0, i)
			PostIDs = PostIDs & AttachListArray(1, i)
			If i <> UBound(AttachListArray, 2) Then
				TopicIDs = TopicIDs &","
				PostIDs = PostIDs &","
			End If
			Call DeleteFile("../attachments/"& AttachListArray(2, i))
		Next
		RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE aid IN("& AttachID &")")

		TopicListArray = RQ.Query("SELECT tid FROM "& TablePre &"topics WHERE tid IN("& TopicIDs &")")
		If IsArray(TopicListArray) Then
			For i = 0 To UBound(TopicListArray, 2)
				Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE tid = "& TopicListArray(0, i))(0)
				Attachments = IIF(Attachments = 0, 0, 1)
				RQ.Execute("UPDATE "& TablePre &"topics SET ifattachment = "& Attachments &" WHERE tid = "& TopicListArray(0, i))
			Next
		End If

		PostListArray = RQ.Query("SELECT pid FROM "& TablePre &"posts WHERE pid IN("& PostIDs &")")
		If IsArray(PostListArray) Then
			For i = 0 To UBound(PostListArray, 2)
				Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE pid = "& PostListArray(0, i))(0)
				Attachments = IIF(Attachments = 0, 0, 1)
				RQ.Execute("UPDATE "& TablePre &"posts SET ifattachment = "& Attachments &" WHERE pid = "& PostListArray(0, i))
			Next
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("选中的附件已经清理完毕。", "?")
End Sub

'========================================================
'默认页面的提交操作
'========================================================
Sub DoSearchOrDelete()
	If Len(Request.Form("btnsearch")) > 0 Then
		Call Search()
	ElseIf Len(Request.Form("deleteinvalid")) > 0 Then
		Call DeleteInvalid()
	End If
End Sub

'========================================================
'清理无效附件
'========================================================
Sub DeleteInvalid()
	Dim AttachListArray
	AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE pid = 0 AND posttime < #"& DATEADD("d", -1, Now()) &"#")
	If IsArray(AttachListArray) Then
		For i = 0 To UBound(AttachListArray, 2)
			Call DeleteFile("../attachments/"& AttachListArray(0, i))
		Next
		RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE pid = 0 AND posttime < #"& DATEADD("d", -1, Now()) &"#")
	End If

	Call closeDatabase()
	Call AdminshowTips("发表于一天前没有和帖子关联的附件已经清理完毕。", "?")
End Sub

'========================================================
'列出附件
'========================================================
Sub Search()
	Dim MinSize, MaxSize, MinDownloads, MaxDownloads, DaysBefore, FileName, FileExt, UserName
	Dim strSQL, SqlWhere, SqlPage, Page, PageCount, RecordCount
	Dim AttachListArray, Fso

	MinSize = SafeRequest(2, "minsize", 0, 0, 0)
	MaxSize = SafeRequest(2, "maxsize", 0, 0, 0)
	MinDownloads = SafeRequest(2, "mindownloads", 0, 0, 0)
	MaxDownloads = SafeRequest(2, "maxdownloads", 0, 0, 0)
	DaysBefore = SafeRequest(2, "daysbefore", 0, 0, 0)
	FileName = SafeRequest(2, "filename", 1, "", 0)
	UserName = SafeRequest(2, "username", 1, "", 0)

	If MinSize < MaxSize Then
		SqlWhere = SqlWhere &" AND a.filesize >= "& MinSize * 1024 &" AND a.filesize <= "& MaxSize * 1024
		SqlPage = SqlPage &" AND filesize >= "& MinSize * 1024 &" AND filesize <= "& MaxSize * 1024
	End If

	If MinDownloads < MaxDownloads Then
		SqlWhere = SqlWhere &" AND a.downloads >= "& MinDownloads &" AND a.downloads <= "& MaxDownloads
		SqlPage = SqlPage &" AND downloads >= "& MinDownloads &" AND downloads <= "& MaxDownloads
	End If

	If DaysBefore > 0 Then
		SqlWhere = SqlWhere &" AND a.posttime <= #"& DATEADD("d", -DaysBefore, Now()) &"#"
		SqlPage = SqlPage &" AND posttime <= #"& DATEADD("d", -DaysBefore, Now()) &"#"
	End If

	If Len(FileName) > 0 Then
		SqlWhere = SqlWhere &" AND a.filename LIKE '%"& FileName &"%'"
		SqlPage = SqlPage &" AND filename LIKE '%"& FileName &"%'"
	End If

	If Len(UserName) > 0 Then
		SqlWhere = SqlWhere &" AND a.uid = (SELECT uid FROM "& TablePre &"members WHERE username = '"& UserName &"')"
		SqlPage = SqlPage &" AND uid = (SELECT uid FROM "& TablePre &"members WHERE username = '"& UserName &"')"
	End If

	RecordCount = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE 1 = 1"& SqlPage)(0)
	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 50)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP 50 a.aid, a.pid, a.filename, a.filesize, a.savepath, a.downloads, a.ifimage, a.posttime, IIF(t.tid IS NULL, 0, t.tid), IIF(t.title IS NULL, '', t.title), IIF(m.username IS NULL, '', m.username) FROM ("& TablePre &"attachments a LEFT JOIN "& TablePre &"topics t ON a.tid = t.tid) LEFT JOIN "& TablePre &"members m ON a.uid = m.uid WHERE 1 = 1"& SqlWhere
		If Page > 1 Then
			strSQL = strSQL &" AND aid < (SELECT MIN(aid) FROM (SELECT TOP "& 50 * (Page - 1) &" aid FROM "& TablePre &"attachments WHERE 1 = 1"& SqlWhere &") AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY a.aid DESC"

		AttachListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()

	If IsArray(AttachListArray) Then
		Set Fso = Server.CreateObject("Scripting.FileSystemObject")
		Call Include("../include/attachment.inc.asp")
	End If

	Call Main()
%>
<br />
<form name="attlist" method="post" action="?action=deletechoosed">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">附件列表</td>
    </tr>
    <tr class="category">
      <td>删?</td>
      <td>附件名称</td>
      <td>附件大小</td>
      <td>相关帖子</td>
      <td>下载次数</td>
      <td>上传者</td>
      <td>上传时间</td>
      <td>状态</td>
    </tr>
    <% If IsArray(AttachListArray) Then %>
	<% For i = 0 To UBound(AttachListArray, 2) %>
	<% If InStr(AttachListArray(2, i), ".") > 0 Then %>
	<% FileExt = LCase(Right(AttachListArray(2, i), Len(AttachListArray(2, i)) - InstrRev(AttachListArray(2, i), "."))) %>
	<% End If %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="attachid" class="radio" value="<%= AttachListArray(0, i) %>" /></td>
      <td class="altbg2"><img src="../images/attachicons/<%= ShowFileType(FileExt) %>" align="bottom" />
	    <% If AttachListArray(6, i) = 1 Then %><a href="../attachments/<%= AttachListArray(4, i) %>" target="_blank"><% Else %><a href="../attachment.asp?action=get&aid=<%= AttachListArray(0, i) %>" target="_blank"><% End If %><%= AttachListArray(2, i) %></a></td>
      <td class="altbg1"><%= ShowFileSize(AttachListArray(3, i)) %></td>
      <td class="altbg2"><% If AttachListArray(8, i) > 0 Then %><a href="../topicmisc.asp?action=redirectpost&pid=<%= AttachListArray(1, i) %>" target="_blank"><%= dfc(AttachListArray(9, i) )%></a><% Else %><em>该附件还没有关联到任何帖子</em><% End If %></td>
      <td class="altbg1"><%= AttachListArray(5, i) %></td>
      <td class="altbg2"><%= AttachListArray(10, i) %></td>
      <td class="altbg1"><%= AttachListArray(7, i) %></td>
      <td class="altbg2"><% If Fso.FileExists(Server.MapPath("../attachments/"& AttachListArray(4, i))) Then %>正常<% Else %><span class="red">丢失</span><% End If %></td>
    </tr>
	<% Next %>
	<% Set Fso = Nothing %>
	<% Else %>
	<tr>
      <td colspan="8"><em>还没有附件呢。</em></td>
	</tr>
	<% End If %>
  </table>
  <% If IsArray(AttachListArray) Then %><p align="center"><input type="submit" id="btndelete" value="删除选中的附件" class="button" /></p><% End If %>
</form>
<%
End Sub

'========================================================
'显示搜索界面
'========================================================
Sub Main()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;附件管理</td>
  </tr>
</table>
<br />
<form method="post" name="search" action="?action=dosearchordel">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>搜索附件</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>附件大小范围：</strong><br />单位：KB</td>
      <td><input type="text" name="minsize" size="15" value="<%= SafeRequest(2, "minsize", 0, "", 0) %>" /> - <input type="text" name="maxsize" size="15" value="<%= SafeRequest(2, "maxsize", 0, "", 0) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1" width="30%"><strong>下载次数范围：</strong></td>
      <td><input type="text" name="mindownloads" size="15" value="<%= SafeRequest(2, "mindownloads", 0, "", 0) %>" /> - <input type="text" name="maxdownloads" size="15" value="<%= SafeRequest(2, "maxdownloads", 0, "", 0) %>" /></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>上传于多少天以前：</strong></td>
      <td><input type="text" name="daysbefore" size="34" value="<%= SafeRequest(2, "daysbefore", 0, "", 0) %>" /></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>文件名：</strong></td>
      <td><input type="text" name="filename" size="34" value="<%= SafeRequest(2, "filename", 1, "", 0) %>" /></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>上传者：</strong></td>
      <td><input type="text" name="username" size="34" value="<%= SafeRequest(2, "username", 1, "", 0) %>" /></td>
    </tr>
	<tr height="25">
      <td class="altbg1" width="30%">&nbsp;</td>
      <td><input type="submit" id="btnsearch" name="btnsearch" value="提交搜索" class="button" />
	    <input type="submit" id="btnclear" name="deleteinvalid" value="清理无效附件" class="button" /> (无效附件是指：附件已上传，但是没有和任何帖子关联)</td>
    </tr>
  </table>
</form>
<%
End Sub
%>