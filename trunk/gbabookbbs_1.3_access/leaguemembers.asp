<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "memberop"
		Call MemberOperation()
	Case "staff_transfer"
		Call Staff_Transfer()
	Case Else
		Call Main()
End Select

'========================================================
'用户加入或者退出联盟的按钮判断
'========================================================
Sub MemberOperation()
	If Len(Request.Form("btnjoin")) > 0 Then
		Call JoinLeague()
	ElseIf Len(Request.Form("btnquit")) > 0 Then
		Call QuitLeague()
	End If
End Sub

'========================================================
'加入联盟
'========================================================
Sub JoinLeague()
	Dim LeagueInfo, UserInfo, strTips

	LeagueInfo = RQ.Query("SELECT ifadulting, name FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	'确认该成员是否已加入过联盟
	UserInfo = RQ.Query("SELECT groupid FROM "& TablePre &"leaguemembers WHERE uid = "& RQ.UserID &" AND leagueid = "& RQ.LeagueID)
	If IsArray(UserInfo) Then
		If UserInfo(0, 0) > 0 Then
			Call RQ.showTips("目前您已经是“"& LeagueInfo(1, 0) &"”的成员。", "", "")
		Else
			Call RQ.showTips("目前您已经加入“"& LeagueInfo(1, 0) &"”，请等待盟主审核。", "", "")
		End If
	End If

	'加入联盟是否需要审核
	If LeagueInfo(0, 0) = 1 Then
		RQ.Execute("INSERT INTO "& TablePre &"leaguemembers (uid, leagueid, groupid, username, designation) VALUES ("& RQ.UserID &", "& RQ.LeagueID &", -1, '"& RQ.UserName &"', '待审核成员')")
		strTips = "您已经申请加入“"& LeagueInfo(1, 0) &"”，请等待联盟盟主审核。"
	Else
		RQ.Execute("INSERT INTO "& TablePre &"leaguemembers (uid, leagueid, groupid, username, designation) VALUES ("& RQ.UserID &", "& RQ.LeagueID &", 3, '"& RQ.UserName &"', '见习成员')")
		RQ.Execute("UPDATE "& TablePre &"leagues SET members = members + 1 WHERE leagueid = "& RQ.LeagueID)
		'更新用户在联盟中的最高等级
		Call RQ.UpdateLGroupID(RQ.UserID)
		strTips = "成功加入了“"& LeagueInfo(1, 0) &"”。"
	End If

	Call closeDatabase()
	Call RQ.showTips(strTips, "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'退出联盟
'========================================================
Sub QuitLeague()
	Dim LeagueInfo, LeagueMemberInfo, UserInfo

	LeagueInfo = RQ.Query("SELECT name FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	LeagueMemberInfo = RQ.Query("SELECT joinid, groupid FROM "& TablePre &"leaguemembers WHERE uid = "& RQ.UserID &" AND leagueid = "& RQ.LeagueID)
	If IsArray(LeagueMemberInfo) Then
		RQ.Execute("DELETE FROM "& TablePre &"leaguemembers WHERE joinid = "& LeagueMemberInfo(0, 0))

		If LeagueMemberInfo(1, 0) > 0 Then
			RQ.Execute("UPDATE "& TablePre &"leagues SET members = members - 1 WHERE leagueid = "& RQ.LeagueID)

			'更新用户在联盟中的最高等级
			Call RQ.UpdateLGroupID(RQ.UserID)
		End If
	End If

	Call closeDatabase()
	Call RQ.showTips("您已经退出“"& LeagueInfo(0, 0) &"”……", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'对联盟成员操作
'========================================================
Sub Staff_Transfer()
	Dim LeagueInfo

	LeagueInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	'权限判断
	If RQ.L_UserGroupID <> 1 Then
		Call RQ.showTips("只有联盟盟主才能进行操作。", "", "")
	End If

	Dim strUserID
	strUserID = NumberGroupFilter(Replace(SafeRequest(2, "uid", 1, "", 0), " ", ""))

	If Len(strUserID) = 0 Then
		Call RQ.showTips("请先选中联盟成员。", "", "")
	End If

	If Len(Request.Form("btnremoval")) > 0 Then
		Call Removeal(strUserID)
	ElseIf Len(Request.Form("btnpromotion")) > 0 Then
		Call Promotion(strUserID)
	ElseIf Len(Request.Form("btnfireout")) > 0 Then
		Call FireOut(strUserID)
	ElseIf Len(Request.Form("btnpass")) > 0 Then
		Call PassMembers(strUserID)
	ElseIf Len(Request.Form("btnblock")) > 0 Then
		Call BlockMembers(strUserID)
	End If
End Sub

'========================================================
'对联盟成员操作(联盟管理员免职)
'========================================================
Sub Removeal(strUserID)

	RQ.Execute("UPDATE "& TablePre &"leaguemembers SET groupid = 3 WHERE uid IN("& strUserID &") AND leagueid = "& RQ.LeagueID &" AND groupid = 2")

	'更新用户在联盟中的最高等级
	Call RQ.UpdateLGroupID(strUserID)

	Call closeDatabase()
	Call RQ.showTips("选中的联盟管理员已经被免职。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'对联盟成员操作(提升联盟成员为联盟管理员)
'========================================================
Sub Promotion(strUserID)

	RQ.Execute("UPDATE "& TablePre &"leaguemembers SET groupid = 2 WHERE uid IN("& strUserID &") AND leagueid = "& RQ.LeagueID &" AND groupid = 3")

	'更新用户在联盟中的最高等级
	Call RQ.UpdateLGroupID(strUserID)

	Call closeDatabase()
	Call RQ.showTips("选中的联盟成员已被提升为管理员。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'对联盟成员操作(删除联盟成员)
'========================================================
Sub FireOut(strUserID)
	Dim MembersNum

	'删除成员
	RQ.Execute("DELETE FROM "& TablePre &"leaguemembers WHERE uid IN("& strUserID &") AND leagueid = "& RQ.LeagueID &" AND groupid = 3")

	'更新联盟统计
	RQ.Execute("UPDATE "& TablePre &"leagues SET members = members - 1 WHERE leagueid = "& RQ.LeagueID)

	'更新用户在联盟中的最高等级
	Call RQ.UpdateLGroupID(strUserID)

	Call closeDatabase()
	Call RQ.showTips("选中的联盟成员已经被删除。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'对联盟成员操作(审核通过待审核的联盟成员)
'========================================================
Sub PassMembers(strUserID)
	Dim MembersNum

	'更新联盟成员
	RQ.Execute("UPDATE "& TablePre &"leaguemembers SET groupid = 3, designation = '见习成员' WHERE uid IN("& strUserID &") AND leagueid = "& RQ.LeagueID &" AND groupid = -1")

	'更新联盟统计
	RQ.Execute("UPDATE "& TablePre &"leagues SET members = members + 1 WHERE leagueid = "& RQ.LeagueID)

	'更新用户在联盟中的最高等级
	Call RQ.UpdateLGroupID(strUserID)

	Call closeDatabase()
	Call RQ.showTips("选中的未审核成员已经通过审核。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'对联盟成员操作(审核不通过待审核的联盟成员)
'========================================================
Sub BlockMembers(strUserID)
	RQ.Execute("DELETE FROM "& TablePre &"leaguemembers WHERE uid IN("& strUserID &") AND leagueid = "& RQ.LeagueID &" AND groupid = -1")

	Call closeDatabase()
	Call RQ.showTips("选中的未审核成员已经被删除。", "?lid="& RQ.LeagueID, "")
End Sub

'========================================================
'联盟管理员和联盟成员列表
'========================================================
Sub Main()
	Dim LeagueInfo, MemberNum, AdultingNum, Keyword, j
	Dim AdminListArray, MemberListArray, AdultingListArray

	LeagueInfo = RQ.Query("SELECT ifadulting, name FROM "& TablePre &"leagues WHERE leagueid = "& RQ.LeagueID)
	If Not IsArray(LeagueInfo) Then
		Call RQ.showTips("联盟不存在或者已经被删除。", "", "")
	End If

	'联盟管理员
	AdminListArray = RQ.Query("SELECT joinid, uid, groupid, username, designation FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid IN(1,2) ORDER BY groupid ASC, joinid ASC")

	'搜索成员
	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	
	'普通成员数量
	MemberNum = Conn.Execute("SELECT COUNT(joinid) FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid = 3")(0)
	dbQueryNum = dbQueryNum + 1

	If Len(Keyword) = 0 Then
		If MemberNum > 0 Then
			MemberListArray = RQ.Query("SELECT TOP 50 joinid, uid, username, designation FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid = 3 ORDER BY joinid DESC")
		End If

		'待审核成员
		AdultingNum = Conn.Execute("SELECT COUNT(joinid) FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid = -1")(0)
		dbQueryNum = dbQueryNum + 1

		If AdultingNum > 0 Then
			AdultingListArray = RQ.Query("SELECT joinid, uid, username, designation FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid = -1 ORDER BY joinid DESC")
		End If
	Else
		MemberListArray = RQ.Query("SELECT TOP 50 joinid, uid, username, designation FROM "& TablePre &"leaguemembers WHERE leagueid = "& RQ.LeagueID &" AND groupid = 3 AND username LIKE '%"& Keyword &"%' ORDER BY joinid DESC")
	End If

	Call closeDatabase()
	RQ.Header()
%>
<form id="search" method="get" action="?" onsubmit="$('btnsearch').value='正在提交,请稍后...';$('btnsearch').disabled=true;">
  <input type="hidden" name="lid" value="<%= RQ.LeagueID %>" />
  用户ID:<input type="text" name="keyword" size="10" value="<%= Keyword %>" />
  <input type="submit" id="btnsearch" value="查找" class="button" />
  [<a href="leaguenews.asp?lid=<%= RQ.LeagueID %>">返回</a>]
</form>
<p>
普通成员 可以发布属于联盟的帖子。<br />
管理成员 可以发布属于联盟的帖子，可以将符合联盟内容的帖子收入联盟。<br />
联盟盟主 可以发布属于联盟的帖子，可以将符合联盟内容的帖子收入联盟，管理联盟内人事变动。<p>
<strong><%= LeagueInfo(1, 0) %></strong><% If LeagueInfo(0, 0) = 1 Then %><em>(新成员加入需审核)</em><% End If %>
<p>
<form name="memberop" method="post" action="?action=memberop">
  <input type="hidden" name="lid" value="<%= RQ.LeagueID %>" />
  <input type="submit" name="btnjoin" value="申请加入" class="button" onclick="$('action').value='joinleague';" />
  <input type="submit" name="btnquit" value="退出联盟" onclick="javascript:if(!confirm('您确定退出“<%= LeagueInfo(1, 0) %>”吗？'))return false;$('action').value='quiteleague';" class="button" />
</form>
<p>
<hr color="black" />
<p>
<form name="adminop" method="post" action="?action=staff_transfer">
<input type="hidden" name="lid" value="<%= RQ.LeagueID %>" />
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="tdpadding4">
<%
	i = 0
	If IsArray(AdminListArray) Then
		For i = 0 To UBound(AdminListArray, 2)
			j = j + 1
			j = IIF(j = 4, 1, j)
			Response.Write IIF(j = 1, "<tr>", "") &"<td width=""33%"" nowrap>"

			If AdminListArray(2, i) = 1 Then
				'盟主用粗体显示,并且选择框禁止选择
				Response.Write "<input type=""checkbox"" name=""uid"" value="""& AdminListArray(1, i) &""" disabled /> <strong>"& AdminListArray(3, i) &" (<a href=""leaguecp.asp?action=editdesignation&joinid="& AdminListArray(0, i) &"&r=m"" onclick=""return shows(this.href);"" class=""underline"">"& AdminListArray(4, i) &"</a>)</strong>"
			Else
				Response.Write "<input type=""checkbox"" name=""uid"" value="""& AdminListArray(1, i) &""" /> "& AdminListArray(3, i) &" (<a href=""leaguecp.asp?action=editdesignation&joinid="& AdminListArray(0, i) &"&r=m"" onclick=""return shows(this.href);"" class=""underline"">"& AdminListArray(4, i) &"</a>)"
			End If

			Response.Write "</td>"& IIF(j = 3, "</tr>", "")
		Next

		Erase AdminListArray

		'表格补全
		Select Case j
			Case 1
				Response.Write "<td width=""33%"">&nbsp;</td><td width=""33%"">&nbsp;</td></tr>"
			Case 2
				Response.Write "<td width=""33%"">&nbsp;</td></tr>"
		End Select

	End If
%>
</table>
<p><input type="submit" id="btnremoval" name="btnremoval" value="免职" class="button" /> 此联盟现有管理成员<%= i %>人
<%
	If IsArray(MemberListArray) Then
		j = 0
%>
<p>
最新加盟的50人
<p>
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="tdpadding4">
<%
		For i = 0 To UBound(MemberListArray, 2)
			j = j + 1
			j = IIF(j = 4, 1, j)
			Response.Write IIF(j = 1, "<tr>", "") &"<td width=""33%"" nowrap><input type=""checkbox"" name=""uid"" value="""& MemberListArray(1, i) &""" /> "& MemberListArray(2, i) &" (<a href=""leaguecp.asp?action=editdesignation&joinid="& MemberListArray(0, i) &"&r=m"" onclick=""return shows(this.href);"" style=""text-decoration:underline"">"& MemberListArray(3, i) &"</a>)</td>"& IIF(j = 3, "</tr>", "")
		Next

		Erase MemberListArray

		'表格补全
		Select Case j
			Case 1
				Response.Write "<td width=""33%""></td><td width=""33%""></td></tr>"
			Case 2
				Response.Write "<td width=""33%""></td></tr>"
		End Select
%>
</table>
<p>
<input type="submit" id="btnpromotion" name="btnpromotion" value="加入管理" class="button" />
<input type="submit" id="btnfireout" name="btnfireout" value="开除" class="button" />
此联盟现有普通成员<%= MemberNum %>人
<%
	End If

	If IsArray(AdultingListArray) Then
		j = 0
%>
<p>
待审核成员
<p>
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="tdpadding4">
<%
		For i = 0 To UBound(AdultingListArray, 2)
			j = j + 1
			j = IIF(j = 4, 1, j)
			Response.Write IIF(j = 1, "<tr>", "") &"<td width=""33%"" nowrap><input type=""checkbox"" name=""uid"" value="""& AdultingListArray(1, i) &""" /> "& AdultingListArray(2, i) &" (<span style=""text-decoration:underline"">"& AdultingListArray(3, i) &"</span>)</td>"& IIF(j = 3, "</tr>", "")
		Next

		Erase AdultingListArray

		'表格补全
		Select Case j
			Case 1
				Response.Write "<td width=""33%""></td><td width=""33%""></td></tr>"
			Case 2
				Response.Write "<td width=""33%""></td></tr>"
		End Select
%>
</table>
<p>
<input type="submit" id="btnpass" name="btnpass" value="通过审核" class="button" />
<input type="submit" id="btnblock" name="btnblock" value="不通过审核" class="button" />
此联盟现有待审核成员<%= AdultingNum %>人 
</form>
<%
		End If 
	RQ.Footer()
End Sub
%>