<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 And RQ.AdminGroupID <> 2 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "leagueop"
		Call LeagueOp()
	Case "changemaster"
		Call ChangeMaster()
	Case "add", "edit"
		Call Add()
	Case "save", "update"
		Call Save()
	Case "listmembers"
		Call ListMembers()
	Case "deletemembers"
		Call DeleteMembers()
	Case "listnews"
		Call ListNews()
	Case "editnews"
		Call EditNews()
	Case "updatenews"
		Call UpdateNews()
	Case "deletenews"
		Call DeleteNews()
	Case "listtopics"
		Call ListTopics()
	Case "deletetopics"
		Call DeleteTopics()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'联盟操作(更新联盟统计/删除联盟)
'========================================================
Sub LeagueOp()
	If Len(Request.Form("btnupdate")) > 0 Then
		RQ.Execute("UPDATE l SET l.members = (SELECT COUNT(joinid) FROM "& TablePre &"leaguemembers WHERE leagueid = l.leagueid AND groupid > 0), l.news = (SELECT COUNT(articleid) FROM "& TablePre &"leaguenews WHERE leagueid = l.leagueid), l.topics = (SELECT COUNT(*) FROM "& TablePre &"leaguetopics WHERE leagueid = l.leagueid) FROM "& TablePre &"leagues l")

	ElseIf Len(Request.Form("btndelete")) > 0 Then
		Dim d_LeagueID
		d_LeagueID = NumberGroupFilter(Replace(SafeRequest(2, "d_leagueid", 0, 0, 0), " ", ""))

		If Len(d_LeagueID) > 0 Then
			'删除联盟
			RQ.Execute("DELETE FROM "& TablePre &"leagues WHERE leagueid IN("& d_LeagueID &")")

			'删除联盟成员
			RQ.Execute("DELETE FROM "& TablePre &"leaguemembers WHERE leagueid IN("& d_LeagueID &")")

			'删除联盟精华帖
			RQ.Execute("DELETE FROM "& TablePre &"leagueelite WHERE leagueid IN("& d_LeagueID &")")

			'删除永固收藏的联盟
			RQ.Execute("DELETE FROM "& TablePre &"leaguefavorites WHERE leagueid IN("& d_LeagueID &")")

			'删除联盟日志
			RQ.Execute("DELETE FROM "& TablePre &"leaguelogs WHERE leagueid IN("& d_LeagueID &")")

			'删除联盟新闻
			RQ.Execute("DELETE FROM "& TablePre &"leaguenews WHERE leagueid IN("& d_LeagueID &")")

			'删除联盟贴
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE leagueid IN("& d_LeagueID &")")

			'更新原属于该联盟的帖子
			RQ.Execute("UPDATE "& TablePre &"topics SET leagueid = 0 WHERE leagueid IN("& d_LeagueID &")")
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("联盟操作成功。", "?")
End Sub

'========================================================
'更换联盟盟主
'========================================================
Sub ChangeMaster()
	Dim LeagueID, UserName
	Dim LeagueInfo, UserInfo, LeagueMemberInfo, LeagueJoinInfo

	LeagueID = SafeRequest(2, "leagueid", 0, 0, 0)
	UserName = SafeRequest(2, "username", 1, "", 0)

	LeagueInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)

	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	UserInfo = RQ.Query("SELECT uid, username FROM "& TablePre &"members WHERE username = N'"& UserName &"'")

	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	LeagueMemberInfo = RQ.Query("SELECT joinid, uid FROM "& TablePre &"leaguemembers WHERE leagueid = "& LeagueID &" AND groupid = 1")

	LeagueJoinInfo = RQ.Query("SELECT joinid, groupid FROM "& TablePre &"leaguemembers WHERE leagueid = "& LeagueID &" AND uid = "& UserInfo(0, 0))

	'如果该用户在加入了此联盟
	If IsArray(LeagueJoinInfo) Then
		'并且不是联盟盟主
		If LeagueJoinInfo(1, 0) <> 1 Then
			'如果此联盟有别的盟主
			If IsArray(LeagueMemberInfo) Then
				RQ.Execute("UPDATE "& TablePre &"leaguemembers SET groupid = 2 WHERE joinid = "& LeagueMemberInfo(0, 0))

				Call RQ.UpdateLGroupID(LeagueMemberInfo(1, 0))
			End If

			RQ.Execute("UPDATE "& TablePre &"leaguemembers SET groupid = 1 WHERE joinid = "& LeagueJoinInfo(0, 0))
		End If
	Else
		'该用户没有加入联盟，并且此联盟有别的盟主
		If IsArray(LeagueMemberInfo) Then
			RQ.Execute("UPDATE "& TablePre &"leaguemembers SET groupid = 2 WHERE joinid = "& LeagueMemberInfo(0, 0))

			Call RQ.UpdateLGroupID(LeagueMemberInfo(1, 0))
		End If

		RQ.Execute("INSERT INTO "& TablePre &"leaguemembers (uid, leagueid, groupid, username, designation) VALUES ("& UserInfo(0, 0) &", "& LeagueID &", 1, N'"& UserInfo(1, 0) &"', N'<strong>联盟盟主</strong>')")
	End If

	Call RQ.UpdateLGroupID(UserInfo(0, 0))

	Call closeDatabase()
	Call AdminshowTips("盟主操作成功。", "?")
End Sub

'========================================================
'保存/更新联盟设置
'========================================================
Sub Save()
	Dim LeagueID, LeagueInfo, UserInfo
	Dim Name, Description, UserName, ifAdulting

	LeagueID = SafeRequest(2, "leagueid", 0, 0, 0)
	Name = SafeRequest(2, "name", 1, "", 0)
	Description = SafeRequest(2, "description", 1, "", 0)
	UserName = SafeRequest(2, "username", 1, "", 0)
	ifAdulting = SafeRequest(2, "ifadulting", 1, "", 0)

	If Len(CheckContent(Name)) = 0 Then
		Call AdminshowTips("请填写好联盟的名称。", "")
	End If

	If Len(CheckContent(ifAdulting)) = 0 Then
		Call AdminshowTips("请选择联盟是否需要审核。", "")
	End If

	If Len(Description) > 1000 Then
		Description = Left(Description, 1000)
	End If

	Description = Replace(Description, vbCrLf, "<br />")

	Select Case ifAdulting
		Case "joindirect"
			ifAdulting = 0
		Case "adulting"
			ifAdulting = 1
		Case Else
			Call AdminshowTips("请选择联盟是否需要审核。", "")
	End Select

	If Action = "save" Then
		If Len(CheckContent(UserName)) = 0 Then
			Call AdminshowTips("请填写好新联盟的盟主用户名。", "")
		End If

		UserInfo = RQ.Query("SELECT uid, username FROM "& TablePre &"members WHERE username = N'"& UserName &"'")
		If Not IsArray(UserInfo) Then
			Call AdminshowTips("该用户不存在。", "")
		End If

		RQ.Execute("INSERT INTO "& TablePre &"leagues (ifadulting, name, description) VALUES ("& ifAdulting &", N'"& Name &"', N'"& Description &"')")
		LeagueID = Conn.Execute("SELECT SCOPE_IDENTITY()")(0)
		RQ.Execute("INSERT INTO "& TablePre &"leaguemembers (uid, leagueid, groupid, username, designation) VALUES ("& UserInfo(0, 0) &", "& LeagueID &", 1, N'"& UserInfo(1, 0) &"', N'联盟盟主')")

		Call RQ.UpdateLGroupID(UserInfo(0, 0))
	Else
		RQ.Execute("UPDATE "& TablePre &"leagues SET ifadulting = "& ifAdulting &", name = N'"& Name &"', description = N'"& Description &"' WHERE leagueid = "& LeagueID)
	End If

	Call closeDatabase()
	Call AdminshowTips("联盟更新成功。", "?")
End Sub

'========================================================
'添加/编辑联盟
'========================================================
Sub Add()
	Dim LeagueID, LeagueInfo
	Dim ifAdulting, Name, Description
	Dim strAction, strNav

	If Action = "edit" Then
		LeagueID = SafeRequest(3, "leagueid", 0, 0, 0)
		LeagueInfo = RQ.Query("SELECT ifadulting, name, description FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)

		Call closeDatabase()

		If Not IsArray(LeagueInfo) Then
			Call AdminshowTips("联盟不存在或者已经被删除。", "")
		End If

		ifAdulting = LeagueInfo(0, 0)
		Name = LeagueInfo(1, 0)
		Description = LeagueInfo(2, 0)
		strAction = "update"
		strNav = "编辑联盟"
	Else
		strAction = "save"
		strNav = "添加新联盟"
		ifAdulting = -1
	End If
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<%= strNav %></td>
  </tr>
</table>
<br />
<form method="post" name="leagueinfo" action="?action=<%= strAction %>" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="leagueid" value="<%= LeagueID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong><%= strNav %></strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>联盟名称:</strong></td>
      <td width="70%"><input type="text" name="name" size="25" value="<%= Name %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>联盟简介:</strong><br />1000字以内</td>
      <td width="70%"><textarea name="description" rows="5" cols="40"><%= Preg_Replace(Description, "<br(.*?)>", vbCrLf) %></textarea></td>
    </tr>
	<% If Action = "add" Then %>
    <tr height="25">
      <td class="altbg1"><strong>联盟盟主:</strong></td>
      <td width="70%"><input type="text" name="username" size="25" /></td>
    </tr>
	<% End If %>
    <tr height="25">
      <td class="altbg1"><strong>新成员加入是否需要审核:</strong></td>
      <td width="70%"><select name="ifadulting">
	    <option value="">--</option>
		<option value="joindirect"<% If ifAdulting = 0 Then Response.Write " selected" End If %>>无需审核直接加入</option>
		<option value="adulting"<% If ifAdulting = 1 Then Response.Write " selected" End If %>>需要审核</option>
	  </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btnsubmit" value="提交" class="button" /></td>
    </tr>
  </table>
</form>
<% If Action = "edit" Then %>
<br />
<form method="post" name="changemaster" action="?action=changemaster" onsubmit="$('btnchange').value='正在提交,请稍后...';$('btnchange').disabled=true;">
  <input type="hidden" name="leagueid" value="<%= LeagueID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>更换盟主</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>请输入新盟主的用户名:</strong></td>
      <td width="70%"><input type="text" name="username" size="25" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btnchange" value="提交" class="button" /></td>
    </tr>
  </table>
</form>
<% End If %>
<%
End Sub

'========================================================
'联盟成员列表
'========================================================
Sub ListMembers()
	Dim LeagueID, LeagueInfo, Keyword, LeagueGroup
	Dim Page, PageCount, RecordCount, strSQL, SqlWhere
	Dim MemberListArray

	LeagueID = SafeRequest(3, "leagueid", 0, 0, 0)
	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	LeagueGroup = SafeRequest(3, "leaguegroup", 1, "", 0)

	LeagueInfo = RQ.Query("SELECT name FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	If Len(Keyword) > 0 Then
		SqlWhere = SqlWhere &" AND username LIKE N'%"& Keyword &"%'"
	End If

	Select Case LeagueGroup
		Case "leaguemaster"
			SqlWhere = SqlWhere &" AND groupid = 1"
		Case "leaguemanagers"
			SqlWhere = SqlWhere &" AND groupid = 2"
		Case "leaguemembers"
			SqlWhere = SqlWhere &" AND groupid = 3"
		Case "leagueadulting"
			SqlWhere = SqlWhere &" AND groupid = -1"
	End Select

	RecordCount = Conn.Execute("SELECT COUNT(joinid) FROM "& TablePre &"leaguemembers WHERE leagueid = "& LeagueID & SqlWhere)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)

		If Page > PageCount Then
			Page = PageCount
		End If

		strSQL = "SELECT TOP 30 joinid, uid, groupid, username, designation, jointime FROM "& TablePre &"leaguemembers WHERE leagueid = "& LeagueID & SqlWhere

		If Page > 1 Then
			strSQL = strSQL &" AND joinid < (SELECT MIN(joinid) FROM (SELECT TOP "& 30 * (Page - 1) &" joinid FROM "& TablePre &"leaguemembers WHERE leagueid = "& LeagueID & SqlWhere &" ORDER BY joinid DESC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY joinid DESC"

		MemberListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;联盟成员</td>
  </tr>
</table>
<br />
<form name="fmsearch" id="fmsearch" action="?" method="get">
  <input type="hidden" name="action" value="listmembers" />
  <input type="hidden" name="leagueid" value="<%= LeagueID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td><%= LeagueInfo(0, 0) %></td>
    </tr>
    <tr class="altbg2">
      <td>按用户名搜索:
        <input type="text" name="keyword" size="20" value="<%= Keyword %>">
		<select name="leaguegroup" onchange="$('fmsearch').submit();">
          <option value="">--</option>
		  <option value="leaguemaster"<% If LeagueGroup = "leaguemaster" Then Response.Write " selected" End If %>>联盟盟主</option>
		  <option value="leaguemanagers"<% If LeagueGroup = "leaguemanagers" Then Response.Write " selected" End If %>>联盟管理员</option>
		  <option value="leaguemembers"<% If LeagueGroup = "leaguemembers" Then Response.Write " selected" End If %>>联盟成员</option>
		  <option value="leagueadulting"<% If LeagueGroup = "leagueadulting" Then Response.Write " selected" End If %>>未审核成员</option>
		</select>
        <input type="submit" value="搜索" style="height: 20px;" class="button"></td>
    </tr>
  </table>
</form>
<br />
<form name="leaguemembers" method="post" action="?action=deletemembers" onsubmit="if(confirm('是否确定要删除选中的联盟成员？')){$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;}else{return false;}">
  <input type="hidden" name="leagueid" value="<%= LeagueID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%">删?</td>
      <td>联盟用户</td>
      <td width="17%">身份</td>
	  <td width="25%">联盟称号</td>
      <td width="20%">加入时间</td>
    </tr>
	<% If IsArray(MemberListArray) Then %>
	<% For i = 0 To UBound(MemberListArray, 2) %>
	<tr>
	  <td class="altbg1"><input type="checkbox" name="joinid" value="<%= MemberListArray(0, i) %>" class="radio" /></td>
	  <td class="altbg2"><a href="members.asp?action=detail&uid=<%= MemberListArray(1, i) %>"><%= MemberListArray(3, i) %></a></td>
	  <td class="altbg1"><% Select Case MemberListArray(2, i)
	    Case -1
			Response.Write "待审核用户"
		Case 1
			Response.Write "联盟盟主"
		Case 2
			Response.Write "联盟管理员"
		Case 3
			Response.Write "联盟成员"
	  End Select %></td>
      <td class="altbg2"><%= MemberListArray(4, i) %></td>
	  <td class="altbg1"><%= MemberListArray(5, i) %></td>
	</tr>
	<% Next %>
	<% Else %>
	<tr>
	  <td colspan="5">暂无用户</td>
	</tr>
	<% End If %>
  </table>
<% If PageCount > 1 Then %>
<div align="center">
  <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=listmembers&leagueid="& LeagueID &"&keyword="& Server.URLEncode(Keyword) &"&leaguegroup="& LeagueGroup) %>
</div>
<% End If %>
<p align="center"><input type="submit" name="btnsubmit" id="btnsubmit" value="删除选中的联盟成员" class="button" /></p>
</form>
<%
End Sub

'========================================================
'删除联盟成员
'========================================================
Sub DeleteMembers()
	Dim LeagueID, LeagueInfo, JoinID

	LeagueID = SafeRequest(2, "leagueid", 0, 0, 0)
	JoinID = NumberGroupFilter(Replace(SafeRequest(2, "joinid", 0, 0, 0), " ", ""))

	LeagueInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	If Len(JoinID) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"leaguemembers WHERE joinid IN("& JoinID &") AND leagueid = "& LeagueID)
		RQ.Execute("UPDATE "& TablePre &"leagues SET members = (SELECT COUNT(joinid) FROM "& TablePre &"leaguemembers WHERE leagueid = "& LeagueID &" AND groupid > 0) WHERE leagueid = "& LeagueID)
	End If

	Call closeDatabase()
	Call AdminshowTips("成功删除了选中的成员。", "?action=listmembers&leagueid="& LeagueID)
End Sub

'========================================================
'联盟消息列表
'========================================================
Sub ListNews()
	Dim LeagueID, LeagueInfo
	Dim Page, PageCount, RecordCount, strSQL
	Dim ArticleListArray

	LeagueID = SafeRequest(3, "leagueid", 0, 0, 0)
	LeagueInfo = RQ.Query("SELECT name FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	RecordCount = Conn.Execute("SELECT COUNT(articleid) FROM "& TablePre &"leaguenews WHERE leagueid = "& LeagueID)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)

		If Page > PageCount Then
			Page = PageCount
		End If

		strSQL = "SELECT TOP 30 articleid, uid, username, title, posttime FROM "& TablePre &"leaguenews WHERE leagueid = "& LeagueID
		If Page > 1 Then
			strSQL = strSQL &" AND posttime < (SELECT MIN(posttime) FROM (SELECT TOP "& 30 * (Page - 1) &" posttime FROM "& TablePre &"leaguenews WHERE leagueid = "& LeagueID &" ORDER BY posttime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY posttime DESC"

		ArticleListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;联盟消息</td>
  </tr>
</table>
<br />
<form name="leaguenews" method="post" action="?action=deletenews" onsubmit="if(confirm('是否确定要删除选中的联盟消息？')){$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;}else{return false;}">
  <input type="hidden" name="leagueid" value="<%= LeagueID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%">删?</td>
      <td>标题</td>
      <td width="19%">发表人</td>
      <td width="20%">发表时间</td>
	  <td width="8%">操作</td>
    </tr>
	<% If IsArray(ArticleListArray) Then %>
	<% For i = 0 To UBound(ArticleListArray, 2) %>
	<tr>
	  <td class="altbg1"><input type="checkbox" name="articleid" value="<%= ArticleListArray(0, i) %>" class="radio" /></td>
	  <td class="altbg2"><%= ArticleListArray(3, i) %></td>
      <td class="altbg1"><%= ArticleListArray(2, i) %></td>
	  <td class="altbg2"><%= ArticleListArray(4, i) %></td>
	  <td class="altbg1"><a href="?action=editnews&articleid=<%= ArticleListArray(0, i) %>">[编辑]</a></td>
	</tr>
	<% Next %>
	<% Else %>
	<tr>
	  <td colspan="5">暂无消息</td>
	</tr>
	<% End If %>
  </table>
<% If PageCount > 1 Then %>
<div align="center">
  <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=listnews&leagueid="& LeagueID) %>
</div>
<% End If %>
<p align="center"><input type="submit" name="btnsubmit" id="btnsubmit" value="删除选中的联盟消息" class="button" /></p>
</form>
<%
End Sub

'========================================================
'编辑联盟消息
'========================================================
Sub EditNews()
	Dim ArticleID, ArticleInfo

	ArticleID = SafeRequest(3, "articleid", 0, 0, 0)
	ArticleInfo = RQ.Query("SELECT leagueid, title, message FROM "& TablePre &"leaguenews WHERE articleid = "& ArticleID)

	Call closeDatabase()

	If Not IsArray(ArticleInfo) Then
		Call AdminshowTips("联盟消息不存在或者已经被删除。", "")
	End If
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;编辑联盟信息</td>
  </tr>
</table>
<br />
<form method="post" name="leagueinfo" action="?action=updatenews" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="articleid" value="<%= ArticleID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>编辑联盟消息</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>标题:</strong></td>
      <td width="70%"><input type="text" name="title" size="30" value="<%= ArticleInfo(1, 0) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>内容:</strong></td>
      <td width="70%"><textarea name="message" rows="7" cols="45"><%= Preg_Replace(ArticleInfo(2, 0), "<br(.*?)>", vbCrLf) %></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btnsubmit" name="btnsubmit" value="提交更改" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'编辑联盟消息(保存)
'========================================================
Sub UpdateNews()
	Dim ArticleID, ArticleInfo, Title, Message

	ArticleID = SafeRequest(2, "articleid", 0, 0, 0)
	Title = SafeRequest(2, "title", 1, "", 0)
	Message = SafeRequest(2, "message", 1, "", 1)

	ArticleInfo = RQ.Query("SELECT leagueid FROM "& TablePre &"leaguenews WHERE articleid = "& ArticleID)
	If Not IsArray(ArticleInfo) Then
		Call AdminshowTips("消息不存在或者已经被删除。", "")
	End If

	If Len(CheckContent(Title)) = 0 Then
		Call AdminshowTips("请填写好标题。", "")
	End If

	If Len(CheckContent(Message)) = 0 Then
		Call AdminshowTips("请填写好内容。", "")
	End If

	Message = Replace(Message, vbCrLf, "<br />")

	RQ.Execute("UPDATE "& TablePre &"leaguenews SET title = N'"& Title &"', message = N'"& Message &"' WHERE articleid = "& ArticleID)

	Call closeDatabase()
	Call AdminshowTips("联盟消息已经成功更改。", "?action=listnews&leagueid="& ArticleInfo(0, 0))
End Sub

'========================================================
'删除联盟消息
'========================================================
Sub DeleteNews()
	Dim LeagueID, LeagueInfo, ArticleID

	LeagueID = SafeRequest(2, "leagueid", 0, 0, 0)
	ArticleID = NumberGroupFilter(Replace(SafeRequest(2, "articleid", 1, "", 0), " ", ""))

	LeagueInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	If Len(ArticleID) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"leaguenews WHERE articleid IN("& ArticleID &")")
		RQ.Execute("UPDATE "& TablePre &"leagues SET news = (SELECT COUNT(articleid) FROM "& TablePre &"leaguenews WHERE leagueid = "& LeagueID &") WHERE leagueid = "& LeagueID)
	End If

	Call closeDatabase()
	Call AdminshowTips("选中的联盟消息已经成功删除。", "?action=listnews&leagueid="& LeagueID)
End Sub

'========================================================
'联盟帖子列表
'========================================================
Sub ListTopics()
	Dim LeagueID, LeagueInfo
	Dim TopicListArray

	LeagueID = SafeRequest(3, "leagueid", 0, 0, 0)
	LeagueInfo = RQ.Query("SELECT name FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	TopicListArray = RQ.Query("SELECT tid, fid, username, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"leaguetopics WHERE leagueid = "& LeagueID &") ORDER BY lastupdate DESC")

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;联盟帖子</td>
  </tr>
</table>
<br />
<form name="leaguetopics" method="post" action="?action=deletetopics" onsubmit="if(confirm('是否确定要删除选中的联盟帖子？')){$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;}else{return false;}">
  <input type="hidden" name="leagueid" value="<%= LeagueID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%">删?</td>
      <td>标题</td>
      <td width="17%">发表人</td>
      <td width="8%">浏览</td>
      <td width="8%">回复</td>
      <td width="20%">更新时间</td>
    </tr>
	<% If IsArray(TopicListArray) Then %>
	<% For i = 0 To UBound(TopicListArray, 2) %>
	<tr>
	  <td class="altbg1"><input type="checkbox" name="d_tid" value="<%= TopicListArray(0, i) %>" class="radio" /></td>
	  <td class="altbg2"><a href="../viewtopic.asp?tid=<%= TopicListArray(0, i) %>&fid=<%= TopicListArray(1, i) %>" target="_blank"><%= dfc(TopicListArray(3, i)) %></a></td>
      <td class="altbg1"><%= TopicListArray(2, i) %></td>
	  <td class="altbg2"><%= TopicListArray(4, i) %></td>
	  <td class="altbg1"><%= TopicListArray(5, i) %></td>
	  <td class="altbg2"><%= TopicListArray(6, i) %></td>
	</tr>
	<% Next %>
	<% Else %>
	<tr>
	  <td colspan="5">暂无帖子</td>
	</tr>
	<% End If %>
  </table>
  <p align="center"><input type="submit" name="btnsubmit" id="btnsubmit" value="删除选中的联盟帖子" class="button" /></p>
</form>
<%
End Sub

'========================================================
'删除联盟帖
'========================================================
Sub DeleteTopics()
	Dim LeagueID, LeagueInfo, d_TopicID

	LeagueID = SafeRequest(2, "leagueid", 0, 0, 0)
	d_TopicID = NumberGroupFilter(Replace(SafeRequest(2, "d_tid", 1, "", 0), " ", ""))

	LeagueInfo = RQ.Query("SELECT name FROM "& TablePre &"leagues WHERE leagueid = "& LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call AdminshowTips("联盟不存在或者已经被删除。", "")
	End If

	If Len(d_TopicID) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE tid IN("& d_TopicID &") AND leagueid = "& LeagueID)
		RQ.Execute("UPDATE "& TablePre &"leagues SET topics = (SELECT COUNT(*) FROM "& TablePre &"leaguetopics WHERE leagueid = "& LeagueID &") WHERE leagueid = "& LeagueID)
	End If

	Call closeDatabase()
	Call AdminshowTips("选中的联盟帖已经删除。", "?action=listtopics&leagueid="& LeagueID)
End Sub

'========================================================
'联盟列表
'========================================================
Sub Main()
	Dim LeagueListArray

	LeagueListArray = RQ.Query("SELECT l.leagueid, l.ifadulting, l.name, l.createtime, l.members, l.news, l.topics, lm.username FROM "& TablePre &"leagues l LEFT JOIN (SELECT leagueid, username FROM "& TablePre &"leaguemembers WHERE groupid = 1) lm ON l.leagueid = lm.leagueid ORDER BY l.leagueid ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;联盟管理</td>
  </tr>
</table>
<br />
<form name="leagues" method="post" action="?action=leagueop">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'd_leagueid');" />删?</td>
      <td>联盟名称</td>
      <td>盟主</td>
	  <td>审核新成员</td>
      <td>成员数量</td>
      <td>消息数量</td>
      <td>联盟贴</td>
      <td>创建时间</td>
      <td>操作</td>
    </tr>
	<% If IsArray(LeagueListArray) Then %>
	<% For i = 0 To UBound(LeagueListArray, 2) %>
	<tr>
	  <td class="altbg1"><input type="checkbox" name="d_leagueid" value="<%= LeagueListArray(0, i) %>" class="radio" /></td>
	  <td class="altbg2"><%= LeagueListArray(2, i) %></td>
	  <td class="altbg1"><%= LeagueListArray(7, i) %></td>
	  <td class="altbg2"><% If LeagueListArray(1, i) = 0 Then %>直接加入<% Else %><span class="red">加入需审核</span><% End If %></td>
	  <td class="altbg1"><a href="?action=listmembers&leagueid=<%= LeagueListArray(0, i) %>"><%= LeagueListArray(4, i) %></a></td>
	  <td class="altbg2"><a href="?action=listnews&leagueid=<%= LeagueListArray(0, i) %>"><%= LeagueListArray(5, i) %></a></td>
	  <td class="altbg1"><a href="?action=listtopics&leagueid=<%= LeagueListArray(0, i) %>"><%= LeagueListArray(6, i) %></a></td>
	  <td class="altbg2"><%= FormatDateTime(LeagueListArray(3, i), 2) %></td>
	  <td class="altbg1"><a href="?action=edit&leagueid=<%= LeagueListArray(0, i) %>">[编辑]</a></td>
	</tr>
	<% Next %>
	<% Else %>
	<tr>
	  <td colspan="9">目前还没有联盟呢，<a href="?action=add">点击这里添加一个</a>。</td>
	</tr>
	<% End If %>
  </table>
  <% If IsArray(LeagueListArray) Then %>
  <p align="center"><input type="submit" id="btnupdate" name="btnupdate" value="更新联盟统计" class="button" />
    <input type="submit" id="btndelete" name="btndelete" value="删除选中的联盟" class="button" onclick="javascript:if(!confirm('所有属于该联盟的信息都将被删除，是否确定？')) return false;" /></p>
  <% End If %>
</form>
<%
End Sub
%>