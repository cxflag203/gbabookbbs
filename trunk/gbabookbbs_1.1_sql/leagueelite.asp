<!--#include file="include/inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "view"
		Call View()
	Case "edit"
		Call Edit()
	Case "save"
		Call Save()
	Case Else
		Call Main()
End Select

'========================================================
'浏览联盟精华帖
'========================================================
Sub View()
	Dim EliteID, EliteInfo

	EliteID = SafeRequest(3, "eliteid", 0, 0, 0)
	EliteInfo = RQ.Query("SELECT tid, title, message FROM "& TablePre &"leagueelite WHERE eliteid = "& EliteID &" AND leagueid = "& RQ.LeagueID)

	If Not IsArray(EliteInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	Call closeDatabase()

	RQ.PageTitle = EliteInfo(1, 0)
	RQ.Header()

	'标题
	Response.Write EliteInfo(1, 0)

	'联盟盟主或者联盟管理员可以更新精华帖
	If RQ.L_UserGroupID = 1 Or RQ.L_UserGroupID = 2 Then
		Response.Write " [<a href=""###"" onclick=""postvalue('topiccp.asp?action=saveleagueelite&lid="& RQ.LeagueID &"&r=le', 'topicid', '"& EliteInfo(0, 0) &"')"" class=""underline"">更新回复</a>]"
	End If

	Response.Write "<hr color=""black"" />"& EliteInfo(2, 0) &"<hr color=""black"" />"
	RQ.Footer()
End Sub

'========================================================
'编辑精华帖
'========================================================
Sub Edit()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能编辑精华帖。", "", "")
	End If

	Dim EliteID, EliteInfo

	EliteID = SafeRequest(3, "eliteid", 0, 0, 0)
	EliteInfo = RQ.Query("SELECT title, message FROM "& TablePre &"leagueelite WHERE eliteid = "& EliteID &" AND leagueid = "& RQ.LeagueID)

	Call closeDatabase()

	If Not IsArray(EliteInfo) Then
		Call RQ.showTips("精华帖不存在或者已经被删除。", "", "")
	End If

	RQ.Header()
%>
<body>
<form name="superaddition" method="post" action="?action=save" onkeydown="fastpost('btnsave');">
  <input type="hidden" name="lid" value="<%= RQ.LeagueID %>" />
  <input type="hidden" name="eliteid" value="<%= EliteID %>" />
  <table class="tipsborder" cellspacing="0" cellpadding="0" align="center">
    <tr>
      <td class="transborder" width="8">&nbsp;</td>
      <td class="transborder">&nbsp;</td>
      <td class="transborder" width="8">&nbsp;</td>
    </tr>
    <tr>
      <td class="transborder" width="8">&nbsp;</td>
      <td class="tipstd"><div class="mainarea">
          <div class="tipstd_bottom"></div>
          <div class="tips_header">
            <h1>编辑精华帖</h1>
          </div>
          <table width="100%" cellspacing="0" cellpadding="0" class="tbborder">
            <tr>
              <td width="20%">帖子标题:</td>
              <td><input type="text" name="title" maxlength="255" size="50" class="inputgrey" value="<%= strFilter(EliteInfo(0, 0)) %>" /></td>
            </tr>
            <tr>
              <td width="20%">帖子内容:</td>
              <td style="padding: 8px 10px;"><% If InStr(RQ.Topic_Settings(17), "edit") > 0 Then %><input type="hidden" id="message" name="message" value="<%= strFilter(EliteInfo(1, 0)) %>" style="display:hidden" /><input type="hidden" id="content___Config" value="" style="display:none" /><iframe id="content___Frame" src="include/editor/editor/fckeditor.html?InstanceName=message" width="100%" height="200" frameborder="0" scrolling="no"></iframe><% Else %><span id="editorzone"><textarea name="message" id="message" rows="10" class="textareagrey"><%= strFilter(Preg_Replace(EliteInfo(1, 0), "<br(.*?)>", vbCrLf)) %></textarea><a href="javascript:displayeditor('550');" class="bluelink">编辑器</a></span><% End If %></td>
            </tr>
            <tr>
              <td width="20%">选项:</td>
              <td><input name="disable_autowap" id="disable_autowap" type="checkbox" value="1" onclick="f_autowap();" /><label for="disable_autowap">不自动换行</label></td>
            </tr>
            <tr>
              <td width="20%">&nbsp;</td>
              <td><input type="submit" id="btnsave" name="btnsave" value="保存帖子" class="button" />
			    <input type="submit" id="btndelete" name="btndelete" value="删除精华帖" onclick="if(!confirm('是否确定要从联盟精华区删除这篇帖子？'))return false;" class="button" /></td>
            </tr>
            <tr>
          </table>
        </div></td>
      <td class="transborder" width="8">&nbsp;</td>
    </tr>
    <tr>
      <td class="transborder" width="8">&nbsp;</td>
      <td class="transborder">&nbsp;</td>
      <td class="transborder" width="8">&nbsp;</td>
    </tr>
  </table>
</form>
<script type="text/javascript">f_autowap();</script>
<%
	RQ.Footer()
End Sub

'========================================================
'编辑/删除精华帖
'========================================================
Sub Save()
	Dim EliteID, EliteInfo, Title, Message, Disable_Autowap

	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能编辑精华帖。", "", "")
	End If

	EliteID = SafeRequest(2, "eliteid", 0, 0, 0)
	EliteInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leagueelite WHERE eliteid = "& EliteID &" AND leagueid = "& RQ.LeagueID)
	
	If Not IsArray(EliteInfo) Then
		Call RQ.showTips("精华帖不存在或者已经被删除。", "", "")
	End If

	'保存
	If Len(Request.Form("btnsave")) > 0 Then
		Title = SafeRequest(2, "title", 1, "", 1)
		Message = SafeRequest(2, "message", 1, "", 1)

		If Len(CheckContent(Title)) = 0 Then
			Call RQ.showTips("请填写好帖子标题。", "", "")
		End If

		Title = IIF(Len(Title) > 255, Left(Title, 255), Title)

		If Len(Message) = 0 Then
			Call RQ.showTips("请填写好帖子内容。", "", "")
		End If

		'词语过滤
		Message = WordsFilter(Message)

		'帖子内容是否换行
		Disable_Autowap = SafeRequest(2, "disable_autowap", 0, 0, 0)
		If Disable_Autowap = 0 Then 
			Message = Replace(Message, vbCrLf, "<br />")
		Else
			Message = Replace(Message, vbCrLf, "")
		End If

		RQ.Execute("UPDATE "& TablePre &"leagueelite SET title = N'"& Title &"', message = N'"& Message &"' WHERE eliteid = "& EliteID)

		Call closeDatabase()
		Call RQ.showTips("精华帖子已经更新。", "?action=view&lid="& RQ.LeagueID &"&eliteid="& EliteID, "")

	'删除
	ElseIf Len(Request.Form("btndelete")) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"leagueelite WHERE eliteid = "& EliteID)

		Call closeDatabase()
		Call RQ.showTips("精华帖已经删除。", "", "HALTED")
	End If
End Sub

'========================================================
'联盟精华区帖子列表
'========================================================
Sub Main()
	Dim LeagueListArray
	Dim RecordCount, PageCount, Page, strSQL
	Dim EliteListArray

	LeagueListArray = RQ.Query("SELECT leagueid, name FROM "& TablePre &"leagues ORDER BY leagueid ASC")

	RecordCount = Conn.Execute("SELECT COUNT(eliteid) FROM "& TablePre &"leagueelite WHERE leagueid = "& RQ.LeagueID)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(0)))))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP "& RQ.Topic_Settings(0) &" eliteid, username, title, lastupdate FROM "& TablePre &"leagueelite WHERE leagueid = "& RQ.LeagueID

		If Page > 1 Then
			strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(0)) * (Page - 1) &" lastupdate FROM "& TablePre &"leagueelite WHERE leagueid = "& RQ.LeagueID &" ORDER BY lastupdate DESC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY lastupdate DESC"

		EliteListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
	RQ.Header()
%>
<form id="leaguelist" method="get" action="?">
  <select name="lid" onchange="$('leaguelist').submit();">
    <% If IsArray(LeagueListArray) Then %>
    <% For i = 0 To UBound(LeagueListArray, 2) %>
    <option value="<%= LeagueListArray(0, i) %>"<% If RQ.LeagueID = LeagueListArray(0, i) Then Response.Write " selected" End If %>><%= LeagueListArray(1, i) %></option>
	<% Next %>
	<% End If %>
  </select>
</form>
<p>
<%
	If IsArray(EliteListArray) Then
		For i = 0 To UBound(EliteListArray, 2)
			If RQ.L_UserGroupID = 1 Then
				Response.Write "<a href=""?action=edit&lid="& RQ.LeagueID &"&eliteid="& EliteListArray(0, i) &""" target="""& CacheName &"right"">◆</a>"
			Else
				Response.Write "◆"
			End If

			Response.Write " <a href=""?action=view&lid="& RQ.LeagueID &"&eliteid="& EliteListArray(0, i) &""" target="""& CacheName &"right"" title=""【"& EliteListArray(3, i) &" "& EliteListArray(1, i) &" 】"">"& EliteListArray(2, i) &"</a><br />"
		Next

		Erase EliteListArray
	End If

	RQ.Footer()
End Sub
%>