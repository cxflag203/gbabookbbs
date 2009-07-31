<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "league_authen"
		Call League_Authen()
	Case "postnews"
		Call PostNews()
	Case "savenews"
		Call SaveNews()
	Case "savebatchpm"
		Call SaveBatchPm()
	Case "sendbatchpm"
		Call SendBatchPm()
	Case "editdesignation"
		Call EditDesignation()
	Case "updatedesignation"
		Call UpdateDesignation()
	Case "batcheditde"
		Call BatchEditDe()
	Case "batchupdatede"
		Call BatchUpdateDe()
	Case "viewmembers"
		Call ViewMembers()
	Case "editleague"
		Call EditLeague()
	Case "updateintro"
		Call UpdateIntro()
	Case "updatename"
		Call UpdateName()
	Case "viewlogs"
		Call ViewLogs()
	Case Else
		Call Main()
End Select

'========================================================
'保存联盟消息
'========================================================
Sub SaveNews()
	If RQ.L_UserGroupID <> 1 And RQ.L_UserGroupID <> 2 Then
		Call RQ.showTips("只有联盟盟主和联盟管理员才能发布新闻。", "", "")
	End If

	Dim Title, Message, ImgLink, AboutLink, TopicLink

	Title = SafeRequest(2, "title", 1, "", 0)
	Message = SafeRequest(2, "message", 1, "", 1)
	ImgLink = SafeRequest(2, "imglink", 1, "", 0)
	AboutLink = SafeRequest(2, "aboutlink", 1, "", 0)
	TopicLink = SafeRequest(2, "topiclink", 1, "", 0)

	If Len(CheckContent(Title)) = 0 Then
		Call RQ.showTips("请填写好标题。", "", "")
	End If

	'词语过滤
	Title = WordsFilter(Title)

	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写好内容。", "", "")
	End If

	If Len(Title) > 255 Then
		Title = Left(Title, 255)
	End If

	If Len(Message) > 500 Then
		Message = Left(Message, 500)
	End If

	If Len(ImgLink) > 0 And ImgLink <> "http://" Then
		Message = Message &"<p><img src="""& ImgLink &""" border=""0"" />"
	End If

	If Len(AboutLink) > 0 And AboutLink <> "http://" Then
		Message = Message &"<p>相关链接: <a href="""& AboutLink &""" target=""_blank"" class=""underline"">"& AboutLink &"</a>"
	End If

	If Len(TopicLink) > 0 And TopicLink <> "http://" Then
		Message = Message &"<p>相关帖: <a href="""& TopicLink &""" class=""underline"">"& TopicLink &"</a>"
	End If

	'词语过滤
	Message = WordsFilter(Message)
	Message = Replace(Message, vbCrLf, "<br />")

	RQ.Execute("INSERT INTO "& TablePre &"leaguenews (leagueid, uid, username, title, message) VALUES ("& RQ.LeagueID &", "& RQ.UserID &", N'"& RQ.UserName &"', N'"& Title &"', N'"& Message &"')")
	RQ.Execute("UPDATE "& TablePre &"leagues SET news = news + 1 WHERE leagueid = "& RQ.LeagueID)

	Call closeDatabase()
	Call RQ.showTips("联盟新闻发表完毕。", "leaguenews.asp?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'发布联盟消息
'========================================================
Sub PostNews()
	If RQ.UserLeagueGroupID <> 1 And RQ.UserLeagueGroupID <> 2 Then
		Call RQ.showTips("只有联盟盟主和联盟管理员才能发布消息。", "", "")
	End If

	Dim LeagueListArray

	'读取当前用户担任盟主或者联盟管理员的联盟
	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND lm.groupid IN(1,2) ORDER BY l.leagueid ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body>
<form id="postnews" method="post" action="?action=savenews" onkeydown="fastpost('btnsubmit');" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table border="0" class="tdpadding1">
    <tr>
      <td>标题&nbsp; </td>
      <td><input type="text" name="title" size="40" /></td>
    </tr>
    <tr>
      <td>内容<br />
      (500字内)</td>
      <td><textarea rows="3" name="message" cols="35"></textarea></td>
    </tr>
    <tr>
      <td>联盟</td>
      <td><select name="lid">
	  <% If IsArray(LeagueListArray) Then %>
      <% For i = 0 To UBound(LeagueListArray, 2) %>
      <option value="<%= LeagueListArray(0, i) %>"><%= LeagueListArray(1, i) %></option>
	  <% Next %>
	  <% End If %>
	  </select></td>
    </tr>
    <tr>
      <td>图片</td>
      <td><input type="text" name="imglink" size="40" value="http://" /></td>
    </tr>
    <tr>
      <td>链接</td>
      <td><input type="text" name="aboutlink" size="40" value="http://" /></td>
    </tr>
    <tr>
      <td>相关帖</td>
      <td><input type="text" name="topiclink" size="40" value="http://" /></td>
    </tr>
  </table>
  <p><input type="submit" id="btnsubmit" value="提交" class="button" />
  [<a href="javascript:history.go(-1);">返回</a>]
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'保存批量传呼
'========================================================
Sub SaveBatchPm()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能批量发送传呼。", "", "")
	End If

	Dim Target, Message

	Target = SafeRequest(2, "target", 1, "", 0)
	Message = SafeRequest(2, "message", 1, "", 0)

	If Not InArray(Array("forall", "formoderators"), Target) Then
		Call RQ.showTips("未定义操作。", "", "")
	End If

	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写好传呼内容。", "", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	If Len(Message) > 500 Then
		Message = Left(Message, 500)
	End If

	Message = Replace(Message, vbCrLf, "<br />")

	If Target = "forall" Then
		RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message) SELECT N'"& RQ.UserName &"', "& RQ.UserID &", uid, N'"& Message &"' FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid > 0")
	Else
		RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message) SELECT N'"& RQ.UserName &"', "& RQ.UserID &", uid, N'"& Message &"' FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid IN(1,2)")
	End If

	Call closeDatabase()
	Call RQ.showTips("传呼批量发送成功。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'批量发送传呼界面
'========================================================
Sub SendBatchPm()
	If RQ.UserLeagueGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能批量发送传呼。", "", "")
	End If

	Dim LeagueListArray

	'读取当前用户担任盟主的联盟
	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND lm.groupid = 1 ORDER BY l.leagueid ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body>
<form id="postnews" method="post" action="?action=savebatchpm">
  <table border="0" class="tdpadding1">
    <tr>
      <td>联盟</td>
      <td><select name="lid">
	  <% If IsArray(LeagueListArray) Then %>
      <% For i = 0 To UBound(LeagueListArray, 2) %>
      <option value="<%= LeagueListArray(0, i) %>"><%= LeagueListArray(1, i) %></option>
	  <% Next %>
	  <% End If %>
	  </select></td>
    </tr>
    <tr>
      <td>接收用户</td>
      <td><select name="target">
	    <option value="forall">全体成员</option>
		<option value="formoderators">联盟管理员</option>
	  </select></td>
    </tr>
    <tr>
      <td>内容<br />
      (500字内)</td>
      <td><textarea rows="5" name="message" cols="35"></textarea></td>
    </tr>
  </table>
  <p><input type="submit" value="提交" class="button" />
  [<a href="javascript:history.go(-1);">返回</a>]
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'修改用户联盟称号
'========================================================
Sub EditDesignation()
	If RQ.UserLeagueGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能修改称号。", "", "")
	End If

	Dim JoinID, LeagueID, UserInfo, UserName, Designation
	Dim LeagueListArray

	JoinID = SafeRequest(3, "joinid", 0, 0, 0)

	'如果是在“联盟成员管理”里点击进入则读取该成员的信息
	If JoinID > 0 Then
		UserInfo = RQ.Query("SELECT leagueid, username, designation FROM "& TablePre &"leaguemembers WHERE joinid = "& JoinID &" AND groupid > 0")
		If IsArray(UserInfo) Then
			LeagueID = UserInfo(0, 0)
			UserName = UserInfo(1, 0)
			Designation = UserInfo(2, 0)
		Else
			LeagueID = 0
		End If
	End If

	'读取当前用户担任盟主的联盟
	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND lm.groupid = 1 ORDER BY l.leagueid ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body>
<form id="editdesignation" method="post" action="?action=updatedesignation">
  <input type="hidden" name="r" value="<%= Request.QueryString("r") %>" />
  <table border="0" class="tdpadding1">
    <tr>
      <td>用户名</td>
      <td>
      <input type="text" name="username" size="20" value="<%= UserName %>" /></td>
    </tr>
    <tr>
      <td>称号</td>
      <td><input type="text" name="designation" size="20" maxlength="12" value="<%= Designation %>" /></td>
    </tr>
    <tr>
      <td>联盟</td>
      <td><select name="lid">
	    <% If IsArray(LeagueListArray) Then %>
        <% For i = 0 To UBound(LeagueListArray, 2) %>
        <option value="<%= LeagueListArray(0, i) %>"<%= IIF(LeagueID = LeagueListArray(0, i), " selected", "") %>><%= LeagueListArray(1, i) %></option>
	    <% Next %>
	    <% End If %>
	  </select></td>
    </tr>
  </table>
  <p><input type="submit" id="btnsubmit" value="提交" class="button" />
  [<a href="javascript:history.go(-1)">返回</a>]</p>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'更新用户的联盟称号
'========================================================
Sub UpdateDesignation()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能发布修改成员称号。", "", "")
	End If

	Dim UserName, UserInfo, Designation

	UserName = SafeRequest(2, "username", 1, "", 0)
	Designation = SafeRequest(2, "designation", 1, "", 0)

	If Len(UserName) = 0 Then
		Call RQ.showTips("请填写好用户名。", "", "")
	End If

	If Len(Designation) = 0 Then
		Call RQ.showTips("请填写好称号。", "", "")
	End If

	UserInfo = RQ.Query("SELECT lm.joinid FROM "& TablePre &"members m INNER JOIN "& TablePre &"leaguemembers lm ON m.uid = lm.uid WHERE m.username = N'"& UserName &"' AND lm.leagueid = "& RQ.LeagueID &" AND groupid > 0")
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("该用户没有加入该联盟或者还处于待审核状态。", "", "")
	End If

	'词语过滤
	Designation = WordsFilter(Designation)
	Designation = Left(Designation, 12)

	RQ.Execute("UPDATE "& TablePre &"leaguemembers SET designation = N'"& Designation &"' WHERE joinid = "& UserInfo(0, 0))

	Call closeDatabase()

	If Request.Form("r") = "m" Then
		Call Confirm("联盟称号修改完毕。")
	Else
		Call RQ.showTips("联盟称号修改完毕。", "?lid="& RQ.LeagueID, "")
	End If
End Sub

'========================================================
'批量修改联盟称号
'========================================================
Sub BatchEditDe()
	If RQ.UserLeagueGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能修改称号.", "", "")
	End If

	Dim LeagueListArray

	'读取当前用户担任盟主的联盟
	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND lm.groupid = 1 ORDER BY l.leagueid ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body>
将同一称号的用户称号统一修改为另一称号，例如将<span style="color:#008000">见习成员</span>称号修改为<span style="color:#008000">XX联盟见习成员</span>。
<p>
<form id="batcheditde" method="post" action="?action=batchupdatede">
  <table border="0" class="tdpadding1">
    <tr>
      <td>原称号</td>
      <td><input type="text" name="odesignation" size="20" /></td>
    </tr>
    <tr>
      <td>修改后称号</td>
      <td><input type="text" name="ndesignation" size="20" maxlength="12" /></td>
    </tr>
    <tr>
      <td>联盟</td>
      <td><select name="lid">
	    <% If IsArray(LeagueListArray) Then %>
        <% For i = 0 To UBound(LeagueListArray, 2) %>
        <option value="<%= LeagueListArray(0, i) %>"><%= LeagueListArray(1, i) %></option>
	    <% Next %>
	    <% End If %>
	  </select></td>
    </tr>
  </table>
  <p><input type="submit" id="btnsubmit" value="批量修改" class="button" />
  [<a href="javascript:history.go(-1)">返回</a>]</p>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'批量更新联盟称号
'========================================================
Sub BatchUpdateDe()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能发布修改成员称号。", "", "")
	End If

	Dim oDesignation, nDesignation

	oDesignation = SafeRequest(2, "odesignation", 1, "", 0)
	nDesignation = SafeRequest(2, "ndesignation", 1, "", 0)

	If Len(CheckContent(oDesignation)) = 0 Then
		Call RQ.showTips("请填写好原联盟称号。", "", "")
	End If

	If Len(CheckContent(nDesignation)) = 0 Then
		Call RQ.showTips("请填写好新联盟称号。", "", "")
	End If

	'词语过滤
	nDesignation = WordsFilter(nDesignation)
	nDesignation = Left(nDesignation, 12)

	RQ.Execute("UPDATE "& TablePre &"leaguemembers SET designation = N'"& nDesignation &"' WHERE leagueid = "& RQ.LeagueID &" AND designation = N'"& oDesignation &"'")

	Call closeDatabase()
	Call RQ.showTips("称号更新完毕。", "leaguemembers.asp?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'列出联盟成员
'========================================================
Sub ViewMembers()
	Dim LeagueInfo, MemberListArray
	Dim Page, PageCount, RecordCount, strSQL

	LeagueInfo = RQ.Query("SELECT name, members FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)

	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("该联盟不存在或者已经被删除。", "", "")
	End If

	RecordCount = LeagueInfo(1, 0)
	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 50)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP 50 uid, username, groupid, jointime FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID

		If Page > 1 Then
			strSQL = strSQL &" AND joinid > (SELECT MAX(joinid) FROM (SELECT TOP "& 50 * (Page - 1) &" joinid FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" ORDER BY joinid ASC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY joinid ASC"

		MemberListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
	RQ.Header()
%>
<body>
<table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
  <tr class="header">
    <td height="25" colspan="3"><strong><%= LeagueInfo(0, 0) %></strong> - 成员名单</td>
  </tr>
  <tr height="25">
    <td><strong>用户名</strong></td>
    <td width="30%"><strong>联盟身份</strong></td>
    <td width="30%"><strong>加入时间</strong></td>
  </tr>
  <% If IsArray(MemberListArray) Then %>
  <% For i = 0 To UBound(MemberListArray, 2) %>
  <tr height="25">
    <td><a href="profile.asp?uid=<%= MemberListArray(0, i) %>" onclick="return shows3(this.href);" class="bluelink"><%= MemberListArray(1, i) %></a></td>
	<td><% Select Case MemberListArray(2, i) 
		Case -1
			Response.Write "<em>待审核成员</em>"
		Case 1
			Response.Write "联盟盟主"
		Case 2
			Response.Write "联盟管理员"
		Case 3
			Response.Write "联盟成员"
	End Select %></td>
	<td><%= MemberListArray(3, i) %></td>
  </tr>
  <% Next %>
  <% End If %>
</table>
<%
If PageCount > 1 Then
	Call ShowPageInfo(Page, PageCount, RecordCount, "&action=viewmembers&lid="& RQ.LeagueID)
End If
%>
<p>
[<a href="leaguecp.asp?lid=<%= RQ.LeagueID %>">返回</a>]
<%
	RQ.Footer()
End Sub

'========================================================
'联盟相关修改
'========================================================
Sub EditLeague()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能进行此操作。", "", "")
	End If

	Dim LeagueInfo
	LeagueInfo = RQ.Query("SELECT ifadulting, name, description FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)

	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	Call closeDatabase()
	RQ.Header()
%>
<body>
<strong><%= LeagueInfo(1, 0) %></strong>
<p>
<form id="editintro" method="post" action="?action=updateintro">
  <input type="hidden" name="lid" value="<%= RQ.LeagueID %>" />
  联盟简介
  <br />
  <textarea rows="5" name="description" cols="40"><%= Preg_Replace(LeagueInfo(2, 0), "<br(.*?)>", vbCrLf) %></textarea>
  <br />
  <input type="checkbox" name="ifadulting" id="ifadulting" value="1"<%= IIF(LeagueInfo(0, 0) = 1, " checked", "") %> /><label for="ifadulting">新成员加入需要审核</label>
  <br />
  <input id="btnsubmit" type="submit" value="提交" class="button" />
</form>
<p>
<p>
<form id="editname" method="post" action="?action=updatename">
  <input type="hidden" name="lid" value="<%= RQ.LeagueID %>">
  联盟新名称
  <br />
  <input type="text" name="name" size="20" maxlength="20" />
  <input id="btnsubmit" type="submit" value="联盟改名" class="button" />
</form>
<p>[<a href="javascript:history.go(-1)">返回</A>]</p>
<%
	RQ.Footer()
End Sub

'========================================================
'更新联盟介绍
'========================================================
Sub UpdateIntro()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能进行此操作。", "", "")
	End If

	Dim Description, IfAdulting

	Description = SafeRequest(2, "description", 1, "", 0)
	Description = Replace(Description, vbCrLf, "<br />")
	'词语过滤
	Description = WordsFilter(Description)

	IfAdulting = SafeRequest(2, "ifadulting", 0, 0, 0)
	IfAdulting = IIF(IfAdulting > 1, 0, IfAdulting)

	RQ.Execute("UPDATE "& TablePre &"leagues SET ifadulting = "& IfAdulting &", description = N'"& Description &"' WHERE leagueid = "& RQ.LeagueID)

	Call closeDatabase()
	Call RQ.showTips("联盟简介更新完毕。", "leaguenews.asp?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'更新联盟名称
'========================================================
Sub UpdateName()
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能进行此操作。", "", "")
	End If

	Dim Name
	Name = SafeRequest(2, "name", 1, "", 0)

	If Len(CheckContent(Name)) = 0 Then
		Call RQ.showTips("请填写好联盟新名称。", "", "")
	End If

	'词语过滤
	Name = WordsFilter(Name)
	Name = IIF(Len(Name) > 50, Left(Name, 50), Name)

	RQ.Execute("UPDATE "& TablePre &"leagues SET name = N'"& Name &"' WHERE leagueid = "& RQ.LeagueID)

	Call closeDatabase()
	Call RQ.showTips("联盟名称更新完毕。", "leaguenews.asp?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'查看成员操作
'========================================================
Sub ViewLogs()
	Dim LeagueInfo, LogListArray

	LeagueInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	'删除已过期的记录
	RQ.Execute("DELETE FROM "& TablePre &"leaguelogs WHERE posttime < DATEADD(d, -7, GETDATE())")

	'读取该联盟所有日志
	LogListArray = RQ.Query("SELECT typeid, username, operation, posttime FROM "& TablePre &"leaguelogs WHERE leagueid = "& RQ.LeagueID &" ORDER BY posttime DESC")

	Call closeDatabase()
	RQ.Header()
%>
<body>
近一周来联盟成员的操作记录，可根据此对联盟成员的表现予以评价。[<a href="javascript:history.go(-1);">返回</a>]
<%
	Response.Write "<p><strong>联盟发帖</strong><p>"
	If IsArray(LogListArray) Then
		For i = 0 To UBound(LogListArray, 2)
			If LogListArray(0, i) = 0 Then
				Response.Write LogListArray(3, i) &" 操作人:"& LogListArray(1, i) &" 操作内容:"& LogListArray(2, i) &"<hr color=""black"" />"
			End If
		Next
	End If

	Response.Write "<p><strong>联盟添加</strong><p>"
	If IsArray(LogListArray) Then
		For i = 0 To UBound(LogListArray, 2)
			If LogListArray(0, i) = 1 Then
				Response.Write LogListArray(3, i) &" 操作人:"& LogListArray(1, i) &" 操作内容:"& LogListArray(2, i) &"<hr color=""black"" />"
			End If
		Next
	End If

	Response.Write "<p><strong>加入精华</strong><p>"
	If IsArray(LogListArray) Then
		For i = 0 To UBound(LogListArray, 2)
			If LogListArray(0, i) = 2 Then
				Response.Write LogListArray(3, i) &" 操作人:"& LogListArray(1, i) &" 操作内容:"& LogListArray(2, i) &"<hr color=""black"" />"
			End If
		Next
	End If

	Response.Write "<p><strong>联盟去除</strong><p>"
	If IsArray(LogListArray) Then
		For i = 0 To UBound(LogListArray, 2)
			If LogListArray(0, i) = 3 Then
				Response.Write LogListArray(3, i) &" 操作人:"& LogListArray(1, i) &" 操作内容:"& LogListArray(2, i) &"<hr color=""black"" />"
			End If
		Next
	End If

	RQ.Footer()
End Sub

'========================================================
'联盟控制面板
'========================================================
Sub Main()
	If RQ.LeagueID = 0 Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	RQ.Header()
%>
<body>
<table border="0" width="100%" class="tdpadding1">
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=postnews">发布联盟消息</a></td>
    <td bgcolor="#FFF9E1">所发布的消息将在联盟的首页显示，可以此向其他用户发布联盟动态，联盟通知，联盟情况等。</td>
  </tr>
  <% If RQ.L_UserGroupID = 1 Then %>
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=sendbatchpm">批量发送传呼</a></td>
    <td bgcolor="#FFF9E1">联盟盟主给联盟成员批量发送群呼。</td>
  </tr>
  <% End If %>
  <tr>
    <td bgcolor="#CCFFCC" nowrap>
    <a href="leaguemembers.asp?lid=<%= RQ.LeagueID %>">联盟成员管理</a></td>
    <td bgcolor="#FFF9E1">任免成员职位，修改联盟称号。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=editdesignation">修改联盟称号</a></td>
    <td bgcolor="#FFF9E1">为联盟成员设置的称号可以在发言中使用。[<a href="membercp.asp?action=designation">使用联盟称号</a>]</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=batcheditde">批量修改称号</a></td>
    <td bgcolor="#FFF9E1">对特殊情况下的联盟称号进行批量的修改。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=viewmembers&lid=<%= RQ.LeagueID %>">列出成员名单</a></td>
    <td bgcolor="#FFF9E1">可在此获得联盟成员名单。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=editleague&lid=<%= RQ.LeagueID %>">联盟相关修改</a></td>
    <td bgcolor="#FFF9E1">可进行联盟简介，名称修改，联盟简介是让他人了解联盟的必要资料，请好好利用，字数请控制在1000字内。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC" nowrap><a href="?action=viewlogs&lid=<%= RQ.LeagueID %>">查看成员操作</a></td>
    <td bgcolor="#FFF9E1">一周内联盟成员的操作记录，可作为联盟成员参与联盟事务的判断依据。</td>
  </tr>
</table>
<p>
<strong>其他功能说明</strong>
<p>
收入精华区
<br />
每个联盟都有一个默认的精华区供联盟收录精彩帖,联盟盟主或联盟管理在显示联盟帖的页面上点击标题后的<span style="color:#00F;">★</span>即可,同一帖子如有新回复可再次收入进行更新.
<p>
精华区管理
<br />
联盟盟主进入相应精华区帖子后点击发贴人ID即可对该帖进行管理.
<p>
[<a href="leaguelist.asp">返回</a>]
<%
	RQ.Footer()
End Sub
%>