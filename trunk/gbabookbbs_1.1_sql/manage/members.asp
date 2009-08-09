<!--#include file="include/admininc.asp"-->
<!--#include file="../include/md5.inc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 And (RQ.AdminGroupID <> 2 Or RQ.AllowEditUser = 0) Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action, GroupListArray
Action = Request.QueryString("action")

Select Case Action
	Case "deletemembers"
		Call DeleteMembers()
	Case "listmembers"
		Call ListMembers()
	Case "usergroup"
		Call UserGroup()
	Case "update_usergroup"
		Call Update_UserGroup()
	Case "detail"
		Call Detail()
	Case "update_detail"
		Call Update_Detail()
	Case "view_logs"
		Call View_Logs()
	Case "view_topics"
		Call View_Topics()
	Case "delete_topics"
		Call Delete_Topics()
	Case "view_posts"
		Call View_Posts()
	Case "delete_posts"
		Call Delete_Posts()
	Case "set_credits"
		Call Set_Credits()
	Case "update_credits"
		Call Update_Credits()
	Case "permission"
		Call Permission()
	Case "savepermission"
		Call SavePermission()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'删除用户
'========================================================
Sub DeleteMembers()
	Dim d_UserID, MemberInfo, n
	d_UserID = NumberGroupFilter(Replace(SafeRequest(2, "d_uid", 1, "", 0), " ", ""))

	If Len(d_UserID) > 0 Then
		MemberInfo = RQ.Query("SELECT TOP 1 1 FROM "& TablePre &"members WHERE uid IN("& d_UserID &") AND admingroupid > 0")
		If IsArray(MemberInfo) Then
			Call AdminshowTips("您要删除的用户中有管理组成员，如要删除，请先把管理组成员改为普通成员。", "")
		End If

		n = RQ.Execute("DELETE FROM "& TablePre &"members WHERE uid IN("& d_UserID &")")
		If n > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"memberfields WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"access WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"itemmarket WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"memberitems WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"leaguemembers WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"leaguefavorites WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"memberprofiles WHERE uid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"pm WHERE msgtoid IN("& d_UserID &")")
			RQ.Execute("DELETE FROM "& TablePre &"pms WHERE uid IN("& d_UserID &")")
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("删除完毕。", "?")
End Sub

'========================================================
'修改用户所属的用户组(提交后的处理)
'========================================================
Sub Update_UserGroup()
	Dim UserID, GroupID, ExpiryTime, ExpiryGroupID, Reason, SubTract_Credits, Restore_AdminGroupID, strOperation
	Dim UserInfo, GroupInfo, Expiry_GroupInfo
	Dim strSQL

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	GroupID = SafeRequest(2, "gid", 0, 0, 0)
	ExpiryTime = SafeRequest(2, "expirytime", 2, Date(), 0)
	ExpiryGroupID = SafeRequest(2, "expirygid", 0, 0, 0)
	Reason = Trim(SafeRequest(2, "reason", 1, "", 0))
	SubTract_Credits = SafeRequest(2, "subtract_credits", 0, 0, 0)

	UserInfo = RQ.Query("SELECT m.uid, m.username, m.usergroupid, m.admingroupid, g.name, g.types FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("该用户不存在或者已经被删除。", "")
	End If

	If UserInfo(0, 0) = 1 Then
		Call AdminshowTips("该用户是创始人，不允许进行用户组的更改。", "")
	End If

	If GroupID = 0 Then
		Call AdminshowTips("请选择要转换的用户组。", "")
	End If

	GroupInfo = RQ.Query("SELECT name, types FROM "& TablePre &"usergroups WHERE gid = "& GroupID)
	If Not IsArray(GroupInfo) Then
		Call AdminshowTips("用户组不存在或者已经被删除。", "")
	End If

	If Len(Reason) > 0 Then
		If GroupInfo(1, 0) = "restricted" Then
			strOperation = strOperation &"<span style=""color: #FF0080;"">列入"& GroupInfo(0, 0) &"</span>"
		Else
			If UserInfo(5, 0) = "restricted" And GroupInfo(1, 0) <> "restricted" Then
				strOperation = strOperation &"<span style=""color: #FF0080;"">解除"& UserInfo(4, 0) &"</span>"
			Else
				strOperation = strOperation &"设置为"& GroupInfo(0, 0)
			End If
		End If
	End If

	ExpiryTime = CDate(ExpiryTime)
	If ExpiryTime > Date() Then
		If ExpiryGroupID = 0 Then 
			Call AdminshowTips("如果设置了用户组到期时间，那么请设置好到期后恢复的用户组。", "")
		Else
			Expiry_GroupInfo = RQ.Query("SELECT name, types FROM "& TablePre &"usergroups WHERE gid = "& ExpiryGroupID)
			If Not IsArray(Expiry_GroupInfo) Then
				Call AdminshowTips("到期恢复的用户组不存在或者已经被删除。", "")
			End If

			If Expiry_GroupInfo(1, 0) = "moderator" Then
				Restore_AdminGroupID = ExpiryGroupID
			Else
				Restore_AdminGroupID = 0
			End If

			strSQL = strSQL &", groupexpiry = "& DatetoNum(ExpiryTime)
		End If
	Else
		strSQL = strSQL &", groupexpiry = 0"
	End If

	Select Case GroupInfo(1, 0)
		Case "moderator"
			strSQL = strSQL &", admingroupid = "& GroupID
		Case "restricted"
			strSQL = strSQL &", admingroupid = "& UserInfo(3, 0)
		Case Else
			strSQL = strSQL &", admingroupid = 0"
	End Select

	If SubTract_Credits > 0 Then
		strSQL = strSQL &", credits = credits - "& SubTract_Credits

		If Len(Reason) > 0 Then
			strOperation = strOperation &"<span style=""color: #FF0080;"">, 扣除"& RQ.Other_Settings(0) & SubTract_Credits &"点.</span>"
		End If
	End If

	RQ.Execute("UPDATE "& TablePre &"members SET usergroupid = "& GroupID & strSQL &" WHERE uid = "& UserID)
	RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)

	If ExpiryTime > Date() Then
		RQ.Execute("INSERT INTO "& TablePre &"groupexpiry (uid, usergroupid, admingroupid) VALUES ("& UserID &", "& ExpiryGroupID &", "& Restore_AdminGroupID &")")
	End If

	If Len(Reason) > 0 Then
		Call RQ.SetLog(UserID, UserInfo(1, 0), strOperation, Reason)
	End If

	Call closeDatabase()
	Call AdminshowTips("用户组设置成功。", "?action=usergroup&uid="& UserID)
End Sub

'========================================================
'修改用户所属的用户组
'========================================================
Sub UserGroup()
	Dim UserID, UserInfo
	Dim GroupExpiryInfo, ExpiryGroupID, ExpiryTime

	UserID = SafeRequest(3, "uid", 0, 0, 0)

	UserInfo = RQ.Query("SELECT username, admingroupid, usergroupid, groupexpiry FROM "& TablePre &"members WHERE uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call AdminshowTips("该用户不存在或者已经被删除。", "")
	End If

	If UserInfo(3, 0) > 0 Then
		GroupExpiryInfo = RQ.Query("SELECT usergroupid FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)

		If Not IsArray(GroupExpiryInfo) Then
			RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)
			RQ.Execute("UPDATE "& TablePre &"members SET groupexpiry = 0 WHERE uid = "& UserID)
			ExpiryGroupID = UserInfo(2, 0)
		Else
			ExpiryGroupID = GroupExpiryInfo(0, 0)
			ExpiryTime = NumtoDate(UserInfo(3, 0))
		End If
	End If

	Call Main()
%>
<div id="append_parent"></div>
<script type="text/javascript" src="../js/calendar.js"></script>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td colspan="4">用户信息</td>
  </tr>
  <tr>
    <td class="altbg1" width="30%"><strong><span class="underline"><%= UserInfo(0, 0) %></span>当前所在的用户组:</strong></td>
    <td class="altbg2"><%= RQ.Get_GroupName(UserInfo(2, 0)) %><%= IIF(IsDate(ExpiryTime), "<em>(有效期至"& ExpiryTime &")</em>", "") %></td>
  </tr>
  <% If UserInfo(1, 0) > 0 Then %>
  <tr>
    <td class="altbg1" width="30%"><strong><span class="underline"><%= UserInfo(0, 0) %></span>当前所在的管理组:</strong></td>
    <td class="altbg2"><%= RQ.Get_GroupName(UserInfo(1, 0)) %></td>
  </tr>
  <% End If %>
</table>
<br />
<form method="post" name="change_usergroup" action="?action=update_usergroup">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="2">编辑用户组</td>
    </tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>将该用户设置为:</strong></td>
	  <td class="altbg2"><select name="gid">
	    <option value="0">--</option>
	    <% If IsArray(GroupListArray) Then %>
		<% For i = 0 To UBound(GroupListArray, 2) %>
        <option value="<%= GroupListArray(0, i) %>"<% If UserInfo(2, 0) = GroupListArray(0, i) Then Response.Write " selected" End If %>><%= GroupListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>有效期至:</strong><br />不填则为长期</td>
	  <td class="altbg2"><input type="text" id="expirytime" name="expirytime" size="20" value="<%= ExpiryTime %>" onclick="calendar.showCalendar(['expirytime'],['expirytime'])" /></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>到期后用户组恢复为:</strong></td>
	  <td class="altbg2"><select name="expirygid">
	    <option value="0">--</option>
	    <% If IsArray(GroupListArray) Then %>
		<% For i = 0 To UBound(GroupListArray, 2) %>
        <option value="<%= GroupListArray(0, i) %>"<% If ExpiryGroupID = GroupListArray(0, i) Then Response.Write " selected" End If %>><%= GroupListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>操作原因:</strong><br />如果是处罚用户，可以在这里填写好填写原因(非必填)</td>
	  <td class="altbg2"><input type="text" name="reason" size="40" /></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>扣除<%= RQ.Other_Settings(0) %>:</strong><br />直接填写需要扣除的数量即可</td>
	  <td class="altbg2"><input type="text" name="subtract_credits" size="20" /></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%">&nbsp;</td>
	  <td class="altbg2"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
	</tr>
  </table>
</form>
<%
	Call closeDatabase()
End Sub

'========================================================
'显示用户详细资料
'========================================================
Sub Detail()
	Dim UserID, UserInfo
	Dim ItemListArray, MarketListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)

	UserInfo = RQ.Query("SELECT m.username, m.credits, m.regtime, m.regip, m.lastlogintime, m.lastloginip, m.logintime, m.loginip, m.logincount, m.newtopictime, m.topics, m.posts, mf.designation, mf.signature, mf.ignorepm FROM "& TablePre &"members m INNER JOIN "& TablePre &"memberfields mf ON m.uid = mf.uid WHERE m.uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call AdminshowTips("该用户不存在或者已经被删除。", "")
	End If

	ItemListArray = RQ.Query("SELECT mi.num, i.name FROM "& TablePre &"memberitems mi INNER JOIN "& TablePre &"items i ON mi.itemid = i.itemid WHERE mi.uid = "& UserID)

	MarketListArray = RQ.Query("SELECT im.price, im.num, i.name FROM "& TablePre &"itemmarket im INNER JOIN "& TablePre &"items i ON im.itemid = i.itemid WHERE im.uid = "& UserID)

	Call Main()
	Call closeDatabase()
%>
<br />
<form name="detail" method="post" action="?action=update_detail" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="4">用户详细信息</td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>用户名:</strong></td>
      <td class="altbg2"><%= UserInfo(0, 0) %>
	    <span style="padding-left: 20px;"><a href="?action=view_logs&uid=<%= UserID %>">[异动报告]</a>
        <% If UserInfo(10, 0) > 0 Then %><a href="?action=view_topics&uid=<%= UserID %>">[发帖]</a><% End If %>
        <% If UserInfo(11, 0) > 0 Then %>&nbsp;<a href="?action=view_posts&uid=<%= UserID %>">[回帖]</a><% End If %></span>
      </td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>新密码:</strong><br />如果不修改密码此处请留空</td>
      <td class="altbg2"><input type="text" name="password" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong><%= RQ.Other_Settings(0) %>:</strong></td>
      <td class="altbg2"><input type="text" name="credits" value="<%= UserInfo(1, 0) %>" size="20" /></td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>注册时间:</strong></td>
      <td class="altbg2"><input type="text" name="regtime" value="<%= UserInfo(2, 0) %>" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>注册IP:</strong></td>
	  <td class="altbg2"><input type="text" name="regip" value="<%= Trim(UserInfo(3, 0)) %>" size="20" /></td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>上次登陆时间:</strong></td>
	  <td class="altbg2"><input type="text" name="lastlogintime" value="<%= UserInfo(4, 0) %>" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>上次登陆IP:</strong></td>
	  <td class="altbg2"><input type="text" name="lastloginip" value="<%= Trim(UserInfo(5, 0)) %>" size="20" /></td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>最后登陆时间:</strong></td>
      <td class="altbg2"><input type="text" name="logintime" value="<%= UserInfo(6, 0) %>" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>最后登陆IP:</strong></td>
      <td class="altbg2"><input type="text" name="loginip" value="<%= Trim(UserInfo(7, 0)) %>" size="20" /></td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>登陆次数:</strong></td>
      <td class="altbg2"><input type="text" name="logincount" value="<%= UserInfo(8, 0) %>" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>最后发帖时间:</strong></td>
      <td class="altbg2"><input type="text" name="newtopictime" value="<%= NumtoDate(UserInfo(9, 0)) %>" size="20" /></td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>发帖数量:</strong></td>
      <td class="altbg2"><input type="text" name="topics" value="<%= UserInfo(10, 0) %>" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>回帖数量:</strong></td>
	  <td class="altbg2"><input type="text" name="posts" value="<%= UserInfo(11, 0) %>" size="20" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>称号:</strong></td>
	  <td class="altbg2"><input type="text" name="designation" value="<%= strFilter(UserInfo(12, 0)) %>" size="20" maxlength="100" /></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>签名:</strong></td>
	  <td class="altbg2"><textarea name="signature" rows="5" cols="40"><%= strFilter(Preg_Replace(UserInfo(13, 0), "<br(.*?)>", vbCrLf)) %></textarea></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>屏蔽某人的短消息:</strong></td>
	  <td class="altbg2"><textarea name="ignorepm" rows="5" cols="40"><%= UserInfo(14, 0) %></textarea></td>
    </tr>
    <tr>
      <td class="altbg1" width="30%"><strong>该用户的道具:</strong></td>
	  <td class="altbg2"><% If IsArray(ItemListArray) Then %><select>
	    <% For i = 0 To UBound(ItemListArray, 2) %>
	    <option><%= ItemListArray(1, i) %>(<%= ItemListArray(0, i) %>)</option>
	    <% Next %>
	  </select><% Else %><em>无</em>
	  <% End If %></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%"><strong>道具市场(价格*数量):</strong></td>
	  <td class="altbg2"><% If IsArray(MarketListArray) Then %><select>
	    <% For i = 0 To UBound(MarketListArray, 2) %>
	    <option><%= MarketListArray(2, i) %>(<%= MarketListArray(0, i) %> * <%= MarketListArray(1, i) %>)</option>
	    <% Next %>
	  </select><% Else %><em>无</em>
	  <% End If %></td>
    </tr>
    <tr>
	  <td class="altbg1" width="30%">&nbsp;</td>
	  <td class="altbg2"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'更新用户资料
'========================================================
Sub Update_Detail()
	Dim UserID, UserInfo, strSQL
	Dim Password, Credits, RegTime, RegIP, LastLoginTime, LastLoginIP, LoginTime, LoginIP, LoginCount, NewTopicTime, Topics, Posts, Designation, Signature, Ignorepm

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("该用户不存在或者已经被删除。", "")
	End If
	
	Password = SafeRequest(2, "password", 1, "", 0)
	Credits = Request.Form("credits")
	RegTime = SafeRequest(2, "regtime", 2, Now(), 0)
	RegIP = SafeRequest(2, "regip", 1, "", 0)
	LastLoginTime = SafeRequest(2, "lastlogintime", 2, Now(), 0)
	LastLoginIP = SafeRequest(2, "lastloginip", 1, "", 0)
	LoginTime = SafeRequest(2, "logintime", 1, Now(), 0)
	LoginIP = SafeRequest(2, "loginip", 1, "", 0)
	LoginCount = SafeRequest(2, "logincount", 0, 1, 0)
	NewTopicTime = SafeRequest(2, "newtopictime", 2, Now(), 0)
	Topics = SafeRequest(2, "topics", 0, 0, 0)
	Posts = SafeRequest(2, "posts", 0, 0, 0)
	Designation = SafeRequest(2, "designation", 1, "", 1)
	Signature = SafeRequest(2, "signature", 1, "", 1)
	Ignorepm = Replace(SafeRequest(2, "ignorepm", 1, "", 0), vbCrLf, "")

	If IsNumeric(Credits) Then
		If Credits > 2147483647 Then
			Credits = 2147483647
		End If
	Else
		Credits = 0
	End If
	RegIP = IIF(Len(RegIP) > 15, Left(RegIP, 15), RegIP)
	LastLoginIP = IIF(Len(LastLoginIP) > 15, Left(LastLoginIP, 15), LastLoginIP)
	LoginIP = IIF(Len(LoginIP) > 15, Left(LoginIP, 15), LoginIP)
	Signature = IIF(Len(Signature) > 100, Left(Signature, 100), Signature)

	NewTopicTime = DatetoNum(NewTopicTime)

	If Len(Password) > 0 Then
		strSQL = ", thepassword = '"& MD5(Password) &"'"
	End If

	RQ.Execute("UPDATE "& TablePre &"members SET credits = "& Credits &", regtime = '"& RegTime &"', regip = '"& RegIP &"', lastlogintime = '"& LastLoginTime &"', lastloginip = '"& LastLoginIP &"', logintime = '"& LoginTime &"', loginip = '"& LoginIP &"', logincount = "& LoginCount &", newtopictime = "& NewTopicTime &", topics = "& Topics &", posts = "& Posts & strSQL &" WHERE uid = "& UserID)

	RQ.Execute("UPDATE "& TablePre &"memberfields SET designation = N'"& Designation &"', signature = N'"& Signature &"', ignorepm = N'"& Ignorepm &"' WHERE uid = "& UserID)

	Call closeDatabase()
	Call AdminshowTips("用户资料更新成功。", "?action=detail&uid="& UserID)
End Sub

'========================================================
'显示用户的异动报告和道具转让报告
'========================================================
Sub View_Logs()
	Dim UserID, UserInfo, ShowType
	Dim LogListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("该用户不存在或者已经被删除。", "")
	End If

	ShowType = SafeRequest(3, "showtype", 1, "", 0)
	
	If ShowType = "itemlogs" Then 
		LogListArray = RQ.Query("SELECT lg.uid, lg.username, lg.userip, lg.targetuid, lg.targetusername, lg.num, lg.price, lg.posttime, it.name FROM "& TablePre &"itemmarketlogs lg INNER JOIN "& TablePre &"items it ON lg.itemid = it.itemid WHERE lg.uid = "& UserID &" OR lg.targetuid = "& UserID &" ORDER BY lg.posttime DESC")
	Else
		LogListArray = RQ.Query("SELECT uid, username, userip, targetuid, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE uid = "& UserID &" OR targetuid = "& UserID &" ORDER BY posttime DESC")
	End If

	Call Main()
	Call closeDatabase()
%>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td colspan="9"><%= UserInfo(0, 0) %>的<% If ShowType = "itemlogs" Then %>道具转让记录<% Else %>异动报告<% End If %><span style="padding-left: 20px;"><% If ShowType = "itemlogs" Then %><a href="?action=view_logs&uid=<%= UserID %>">查看异动报告</a><% Else %><a href="?action=view_logs&showtype=itemlogs&uid=<%= UserID %>">查看道具转让记录</a><% End If %></span></td>
  </tr>
  <% If ShowType = "itemlogs" Then %>
  <tr class="category">
    <td>道具名称</td>
    <td width="14%">接收人</td>
    <td width="14%">转让人</td>
    <td width="15%">转让人IP</td>
    <td width="7%">数量</td>
    <td width="10%">总价格</td>
    <td width="19%">操作时间</td>
  </tr>
  <% If IsArray(LogListArray) Then %>
  <% For i = 0 To UBound(LogListArray, 2) %>
  <tr>
    <td class="altbg1"><%= LogListArray(8, i) %></td>
    <td class="altbg2"><a href="?action=detail&uid=<%= LogListArray(3, i) %>"><%= LogListArray(4, i) %></a></td>
    <td class="altbg1"><a href="?action=detail&uid=<%= LogListArray(0, i) %>"><%= LogListArray(1, i) %></a></td>
    <td class="altbg2"><%= LogListArray(2, i) %></td>
    <td class="altbg1"><%= LogListArray(5, i) %></td>
    <td class="altbg2"><%= LogListArray(6, i) %></td>
    <td class="altbg1"><%= LogListArray(7, i) %></td>
  </tr>
  <% Next %>
  <% Else %>
  <tr>
    <td colspan="7"><em>该用户还没有道具交易记录</em></td>
  </tr>
  <% End If %>
  <% Else %>
  <tr class="category">
    <td>被修改人</td>
    <td>修改人</td>
    <td>修改人IP</td>
    <td>异动内容</td>
    <td>异动原因</td>
    <td width="19%">操作时间</td>
  </tr>
  <% If IsArray(LogListArray) Then %>
  <% For i = 0 To UBound(LogListArray, 2) %>
  <tr>
    <td class="altbg1"><a href="?action=detail&uid=<%= LogListArray(3, i) %>"><%= LogListArray(4, i) %></a></td>
    <td class="altbg2"><a href="?action=detail&uid=<%= LogListArray(0, i) %>"><%= LogListArray(1, i) %></a></td>
    <td class="altbg1"><%= LogListArray(2, i) %></td>
    <td class="altbg2"><%= LogListArray(5, i) %></td>
    <td class="altbg1"><%= LogListArray(6, i) %></td>
    <td class="altbg2"><%= LogListArray(7, i) %></td>
  </tr>
  <% Next %>
  <% Else %>
  <tr>
    <td colspan="6"><em>该用户还没有异动报告信息</em></td>
  </tr>
  <% End If %>
  <% End If %>
</table>
<p align="center"><input type="button" value="返回" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" /></p>
<%
End Sub

'========================================================
'显示用户发表的帖子
'========================================================
Sub View_Topics()
	Dim UserInfo, UserID
	Dim Page, PageCount, RecordCount, strSQL
	Dim TopicListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username, posts FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE uid = "& UserID)(0)

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		If Page > PageCount Then Page = PageCount

		strSQL = "SELECT TOP 30 tid, fid, title, lastupdate, clicks, posts FROM "& TablePre &"topics WHERE uid = "& UserID
		If Page > 1 Then strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& 30 * (Page - 1) &" lastupdate FROM "& TablePre &"topics WHERE uid = "& UserID &" ORDER BY lastupdate DESC) AS tblTemp)"
		strSQL = strSQL &" ORDER BY lastupdate DESC"
		
		TopicListArray = RQ.Query(strSQL)
	End If

	Call Main()
	Call closeDatabase()
%>
<br />
<form name="delete_topics" method="post" action="?action=delete_topics">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="4"><%= UserInfo(0, 0) %>的发帖<% If UserInfo(1, 0) > 0 Then %><span style="padding-left: 20px;"><a href="?action=view_posts&uid=<%= UserID %>">查看<%= UserInfo(0, 0) %>的回帖</a></span><% End If %></td>
    </tr>
    <tr class="category">
      <td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'tid')" /></td>
      <td>标题</td>
      <td width="14%">回复</td>
      <td width="15%">浏览</td>
    </tr>
    <% If IsArray(TopicListArray) Then %>
    <% For i = 0 To UBound(TopicListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="tid" value="<%= TopicListArray(0, i) %>" class="radio" /></td>
      <td class="altbg2"><a href="../viewtopic.asp?fid=<%= TopicListArray(1, i) %>&tid=<%= TopicListArray(0, i) %>" target="_blank" title="最后更新: <%= TopicListArray(3, i) %>"><%= dfc(TopicListArray(2, i)) %></a></td>
      <td class="altbg1"><%= TopicListArray(5, i) %></td>
      <td class="altbg2"><%= TopicListArray(4, i) %></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="4"><em>该用户还没有发帖</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center">
    <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=view_topics&uid="& UserID) %>
  </div>
  <% End If %>
  <p align="center">
    <input type="button" value="返回" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" />
    <input type="submit" value="删除选中的帖子" class="button" />
  </p>
</form>
<%
End Sub

'========================================================
'删除用户发表的帖子
'========================================================
Sub Delete_Topics()
	Dim UserID, UserInfo
	Dim TopicID, ForumListArray, AttachListArray, Topics

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	TopicID = NumberGroupFilter(Replace(SafeRequest(2, "tid", 1, "", 0), " ", ""))
	If Len(TopicID) > 0 Then
		ForumListArray = RQ.Query("SELECT fid, COUNT(tid) FROM "& TablePre &"topics WHERE tid IN("& TopicID &") GROUP BY fid")
		If IsArray(ForumListArray) Then
			RQ.Execute("DELETE FROM "& TablePre &"topics WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"posts WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"sticktopics WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"polls WHERE tid IN("& TopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"polloptions WHERE tid IN("& TopicID &")")

			'删除附件
			AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE tid IN("& TopicID &")")
			If IsArray(AttachListArray) Then
				For i = 0 To UBound(AttachListArray, 2)
					Call DeleteFile("../attachments/"& AttachListArray(0, i))
				Next
				RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE tid IN("& TopicID &")")
			End If

			For i = 0 To UBound(ForumListArray, 2)
				Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& ForumListArray(0, i) &" AND displayorder >= 0")(0)
				RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &" WHERE fid = "& ForumListArray(0, i))

				Call RQ.Update_TopicNum(ForumListArray(0, i), Topics)
			Next
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("帖子删除成功。", "?action=view_topics&uid="& UserID)
End Sub

'========================================================
'显示用户发表的回复
'========================================================
Sub View_Posts()
	Dim UserID, UserInfo
	Dim Page, PageCount, RecordCount, strSQL
	Dim PostListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username, topics FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	RecordCount = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE uid = "& UserID &" AND iffirst = 0")(0)
	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		If Page > PageCount Then Page = PageCount

		strSQL = "SELECT TOP 30 pid, tid, fid, tid, message, posttime FROM "& TablePre &"posts WHERE uid = "& UserID &" AND iffirst = 0"
		If Page > 1 Then strSQL = strSQL &" AND pid < (SELECT MIN(pid) FROM (SELECT TOP "& 30 * (Page - 1) &" pid FROM "& TablePre &"posts WHERE uid = "& UserID &" AND iffirst = 0 ORDER BY pid DESC) AS tblTemp)"
		strSQL = strSQL &" ORDER BY pid DESC"

		PostListArray = RQ.Query(strSQL)
	End If

	Call Main()
	Call closeDatabase()
%>
<br />
<form name="delete_posts" method="post" action="?action=delete_posts">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="2"><%= UserInfo(0, 0) %>的回帖<% If UserInfo(1, 0) > 0 Then %><span style="padding-left: 20px;"><a href="?action=view_topics&uid=<%= UserID %>">查看<%= UserInfo(0, 0) %>的发帖</a></span><% End If %></td>
    </tr>
    <tr class="category">
      <td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'pid')" /></td>
      <td>内容</td>
    </tr>
    <% If IsArray(PostListArray) Then %>
    <% For i = 0 To UBound(PostListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="pid" value="<%= PostListArray(0, i) %>" class="radio" /></td>
      <td class="altbg2"><a href="../topicmisc.asp?action=redirectpost&pid=<%= PostListArray(0, i) %>" target="_blank" title="发表时间: <%= PostListArray(5, i) %>"><%= Left(dfc(PostListArray(4, i)), 50) %>...</a></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="2"><em>该用户还没有回帖</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center">
    <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=view_posts&uid="& UserID) %>
  </div>
  <% End If %>
  <p align="center">
    <input type="button" value="返回" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" />
    <input type="submit" value="删除选中的回帖" class="button" />
  </p>
</form>
<%
End Sub

'========================================================
'删除用户发表的回复
'========================================================
Sub Delete_Posts()
	Dim UserID, UserInfo
	Dim PostID, AttachListArray

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	PostID = NumberGroupFilter(Replace(SafeRequest(2, "pid", 1, "", 0), " ", ""))
	If Len(PostID) > 0 Then
		RQ.Execute("UPDATE t SET posts = posts - p.num FROM "& TablePre &"topics AS t INNER JOIN (SELECT tid, COUNT(1) AS num FROM "& TablePre &"posts WHERE pid IN("& PostID &") AND iffirst = 0 GROUP BY tid) AS p ON t.tid = p.tid")

		RQ.Execute("DELETE FROM "& TablePre &"posts WHERE pid IN("& PostID &") AND iffirst = 0")

		'删除附件
		AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE pid IN("& PostID &")")
		If IsArray(AttachListArray) Then
			For i = 0 To UBound(AttachListArray, 2)
				Call DeleteFile("../attachments/"& AttachListArray(0, i))
			Next
			RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE pid IN("& PostID &")")
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("回复删除成功。", "?action=view_posts&uid="& UserID)
End Sub

'========================================================
'给用户增加金钱和道具
'========================================================
Sub Set_Credits()
	Dim UserID, UserInfo
	Dim ItemListArray, MemberItemListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username, credits FROM "& TablePre &"members WHERE uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	ItemListArray = RQ.Query("SELECT itemid, name FROM "& TablePre &"items")
	MemberItemListArray = RQ.Query("SELECT mi.num, i.name FROM "& TablePre &"memberitems mi INNER JOIN "& TablePre &"items i ON mi.itemid = i.itemid WHERE mi.uid = "& UserID)

	Call Main()
	Call closeDatabase()
%>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td colspan="4">用户信息</td>
  </tr>
  <tr>
    <td class="altbg1" width="30%"><strong><span class="underline"><%= UserInfo(0, 0) %></span>的<%= RQ.Other_Settings(0) %>:</strong></td>
    <td class="altbg2"><%= UserInfo(1, 0) %></td>
  </tr>
  <tr>
    <td class="altbg1" width="30%"><strong><span class="underline"><%= UserInfo(0, 0) %></span>的道具:</strong></td>
    <td class="altbg2"><% If IsArray(MemberItemListArray) Then %><select>
	  <% For i = 0 To UBound(MemberItemListArray, 2) %>
	  <option><%= MemberItemListArray(1, i) %>(<%= MemberItemListArray(0, i) %>)</option>
	  <% Next %>
	</select><% Else %><em>没有道具</em><% End If %></td>
  </tr>
</table>
<br />
<form name="set_credits" method="post" action="?action=update_credits" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="2">赠予<%= RQ.Other_Settings(0) %>和道具</td>
    </tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>请选择要赠予的道具:</strong><br />按住ctrl不放可以多选</td>
	  <td class="altbg2"><select name="itemid" style="width: 200px; height: 200px;" multiple>
	    <% If IsArray(ItemListArray) Then %>
		<% For i = 0 To UBound(ItemListArray, 2) %>
		<option value="<%= ItemListArray(0, i) %>"><%= ItemListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>填写赠予道具的数量:</strong></td>
	  <td class="altbg2"><input type="text" name="item_num" size="20" /></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%"><strong>赠予<%= RQ.Other_Settings(0) %>:</strong></td>
	  <td class="altbg2"><input type="text" name="credits_num" size="20" /></td>
	</tr>
	<tr>
	  <td class="altbg1" width="30%">&nbsp;</td>
	  <td class="altbg2"><input type="submit" name="btnsubmit" id="btnsubmit" value="提交设置" class="button" /></td>
	</tr>
  </table>
</form>
<%
End Sub

'========================================================
'给用户增加金钱和道具(提交处理)
'========================================================
Sub Update_Credits()
	Dim UserID, UserInfo
	Dim ItemID, Item_Num, Credits_Num, ItemInfo

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username, credits FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	Item_Num = SafeRequest(2, "item_num", 0, 0, 0)
	If Item_Num > 0 And Request.Form("itemid").Count > 0 Then
		For i = 1 To Request.Form("itemid").Count
			ItemID = IntCode(Request.Form("itemid")(i))
			If ItemID > 0 Then
				ItemInfo = RQ.Query("SELECT id, num FROM "& TablePre &"memberitems WHERE uid = "& UserID &" AND itemid = "& ItemID)
				If IsArray(ItemInfo) Then
					RQ.Execute("UPDATE "& TablePre &"memberitems SET num = num + "& Item_Num &" WHERE id = "& ItemInfo(0, 0))
				Else
					RQ.Execute("INSERT INTO "& TablePre &"memberitems (uid, itemid, num) VALUES ("& UserID &", "& ItemID&", "& Item_Num &")")
				End If 
			End If
		Next
	End If

	Credits_Num = SafeRequest(2, "credits_num", 0, 0, 0)
	If Credits_Num > 0 Then
		Credits_Num = IIF(Credits_Num + UserInfo(1, 0) > 2147483647, 2147483647, Credits_Num + UserInfo(1, 0))
		RQ.Execute("UPDATE "& TablePre &"members SET credits = "& Credits_Num &" WHERE uid = "& UserID)
	End If

	Call closeDatabase()
	Call AdminshowTips("操作成功。", "?action=set_credits&uid="& UserID)
End Sub

'========================================================
'设置单独的权限
'========================================================
Sub Permission()
	Dim UserID, UserInfo, PermissionInfo, GroupSettings
	Dim AllowVisit, DisablePeriodCtrl, AllowPost, AllowDirectPost, AllowReply, AnonymitySuc, AllowPostPoll
	Dim AllowPoll, AllowSearch, AllowGetAttach, AllowPostAttach, MaxAttachSize, AttachExtensions
	Dim AllowViewUserInfo, AllowUseItem, AllowHTML, AllowChat, SpecialInterface
	Dim AllowInvate, InvatePrice, InvateMaxNum, InvateExpiryDay

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT m.username, m.usergroupid, g.name FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	PermissionInfo = RQ.Query("SELECT * FROM "& TablePre &"access WHERE uid = "& UserID)
	If IsArray(PermissionInfo) Then
		AllowVisit = PermissionInfo(1, 0)
		DisablePeriodCtrl = PermissionInfo(2, 0)
		AllowPost = PermissionInfo(3, 0)
		AllowDirectPost = PermissionInfo(4, 0)
		AllowReply = PermissionInfo(5, 0)
		AnonymitySuc = PermissionInfo(6, 0)
		AllowPostPoll = PermissionInfo(7, 0)
		AllowPoll = PermissionInfo(8, 0)
		AllowSearch = PermissionInfo(9, 0)
		AllowGetAttach = PermissionInfo(10, 0)
		AllowPostAttach = PermissionInfo(11, 0)
		MaxAttachSize = PermissionInfo(12, 0)
		AttachExtensions = PermissionInfo(13, 0)
		AllowViewUserInfo = PermissionInfo(14, 0)
		AllowUseItem = PermissionInfo(15, 0)
		AllowHTML = PermissionInfo(16, 0)
		AllowChat = PermissionInfo(17, 0)
		SpecialInterface = PermissionInfo(18, 0)
		AllowInvate = PermissionInfo(19, 0)
		InvatePrice = PermissionInfo(20, 0)
		InvateMaxNum = PermissionInfo(21, 0)
		InvateExpiryDay = PermissionInfo(22, 0)
	Else
		If Not IsArray(Application(CacheName &"_usergroup_"& UserInfo(1, 0))) Then
			Call RQ.Reload_UserGroup_Settings(UserInfo(2, 0))
		End If

		GroupSettings = Application(CacheName &"_usergroup_"& UserInfo(1, 0))

		AllowVisit = GroupSettings(4, 0)
		DisablePeriodCtrl = GroupSettings(5, 0)
		AllowPost = GroupSettings(6, 0)
		AllowDirectPost = GroupSettings(7, 0)
		AllowReply = GroupSettings(8, 0)
		AnonymitySuc = GroupSettings(9, 0)
		AllowPostPoll = GroupSettings(10, 0)
		AllowPoll = GroupSettings(11, 0)
		AllowSearch = GroupSettings(12, 0)
		AllowGetAttach = GroupSettings(13, 0)
		AllowPostAttach = GroupSettings(14, 0)
		MaxAttachSize = GroupSettings(15, 0)
		AttachExtensions = GroupSettings(16, 0)
		AllowViewUserInfo = GroupSettings(17, 0)
		AllowUseItem = GroupSettings(18, 0)
		AllowHTML = GroupSettings(19, 0)
		AllowChat = GroupSettings(20, 0)
		SpecialInterface = GroupSettings(21, 0)
		AllowInvate = GroupSettings(22, 0)
		InvatePrice = GroupSettings(23, 0)
		InvateMaxNum = GroupSettings(24, 0)
		InvateExpiryDay = GroupSettings(25, 0)
	End If

	Call Main()
	Call closeDatabase()
%>
<br />
<form method="post" name="savepermission" action="?action=savepermission" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>给用户“<%= UserInfo(0, 0) %>”设置单独的权限</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>所在用户组:</strong></td>
      <td width="70%"><%= UserInfo(2, 0) %></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否使用默认权限设置</strong></td>
      <td width="70%"><input type="checkbox" id="ifdefault" name="ifdefault" value="1" class="radio" onclick="showpermission();"<%= IIF(IsArray(PermissionInfo), " ", "checked") %> /><label for="ifdefault">是的</label></td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0" id="p_permission">
    <tr class="header">
      <td height="25" colspan="2"><strong>权限设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否允许访问论坛:</strong></td>
      <td width="70%"><input type="checkbox" name="allowvisit" id="allowvisit" class="radio" value="1"<% If AllowVisit = 1 Then Response.Write " checked" End If %> /><label for="allowvisit">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否不受时间段的限制:</strong></td>
      <td width="70%"><input type="checkbox" name="disableperiodctrl" id="disableperiodctrl" class="radio" value="1"<% If DisablePeriodCtrl = 1 Then Response.Write " checked" End If %> /><label for="disableperiodctrl">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许发帖:</strong></td>
      <td width="70%"><input type="checkbox" name="allowpost" id="allowpost" class="radio" value="1"<% If AllowPost = 1 Then Response.Write " checked" End If %> /><label for="allowpost">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许直接发帖不需审核:</strong></td>
      <td width="70%"><input type="radio" name="allowdirectpost" id="allowdirectpost_0" value="0" class="radio"<% If AllowDirectPost = 0 Then Response.Write " checked" End If %>><label for="allowdirectpost_0">在任何版面发帖都需要审核</label><br />
	    <input type="radio" name="allowdirectpost" id="allowdirectpost_1" value="1" class="radio"<% If AllowDirectPost = 1 Then Response.Write " checked" End If %>><label for="allowdirectpost_1">如果没有时间段和版面的限制条件，发帖无需审核</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许回帖:</strong></td>
      <td width="70%"><input type="checkbox" name="allowreply" id="allowreply" class="radio" value="1"<% If AllowReply = 1 Then Response.Write " checked" End If %> /><label for="allowreply">是的</label></td>
    </tr>
	<% If RQ.Topic_Settings(14) = "1" Then %>
	<tr height="25">
      <td class="altbg1"><strong>发帖/回帖时如果匿名，则成功率为:</strong><br />如果要限制用户组匿名的成功率，请填写1-100之间的数字。不填或者填写0则根据全局的匿名设置。</td>
      <td width="70%"><input type="text" name="anonymitysuc" size="5" value="<%= AnonymitySuc %>" />%</td>
    </tr>
	<% End If %>
	<tr height="25">
      <td class="altbg1"><strong>是否允许发投票帖:</strong></td>
      <td width="70%"><input type="checkbox" name="allowpostpoll" id="allowpostpoll" class="radio" value="1"<% If AllowPostPoll = 1 Then Response.Write " checked" End If %> /><label for="allowpostpoll">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许参与投票:</strong></td>
      <td width="70%"><input type="checkbox" name="allowpoll" id="allowpoll" class="radio" value="1"<% If AllowPoll = 1 Then Response.Write " checked" End If %> /><label for="allowpoll">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许搜索帖子:</strong></td>
      <td width="70%"><input type="checkbox" name="allowsearch" id="allowsearch" class="radio" value="1"<% If AllowSearch = 1 Then Response.Write " checked" End If %> /><label for="allowsearch">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许下载、浏览附件:</strong></td>
      <td width="70%"><input type="checkbox" name="allowgetattach" id="allowgetattach" class="radio" value="1"<% If AllowGetAttach = 1 Then Response.Write " checked" End If %> /><label for="allowgetattach">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许发布附件:</strong></td>
      <td width="70%"><input type="checkbox" name="allowpostattach" id="allowpostattach" class="radio" value="1" onclick="showattach();"<% If AllowPostAttach = 1 Then Response.Write " checked" End If %> /><label for="allowpostattach">是的</label></td>
    </tr>
	<tr height="25" id="p_attachextensions">
      <td class="altbg1"><strong>最大附件尺寸:</strong><br />上传单个附件的最大尺寸，设置为0则限制在100MB以内。</td>
      <td width="70%"><input type="text" name="maxattachsize" size="10" value="<%= MaxAttachSize %>" /> KB</td>
    </tr>
	<tr height="25" id="p_maxattachsize">
      <td class="altbg1"><strong>允许附件类型:</strong><br />多个扩展名用英文逗号","隔开。留空则为不限制</td>
      <td width="70%"><input type="text" name="attachextensions" size="40" value="<%= AttachExtensions %>"/ ></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>允许查看用户资料:</strong></td>
      <td width="70%"><input type="checkbox" name="allowviewuserinfo" id="allowviewuserinfo" class="radio" value="1"<% If AllowViewUserInfo = 1 Then Response.Write " checked" End If %> /><label for="allowviewuserinfo">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>允许使用道具功能:</strong></td>
      <td width="70%"><input type="checkbox" name="allowuseitem" id="allowuseitem" class="radio" value="1"<% If AllowUseItem = 1 Then Response.Write " checked" End If %> /><label for="allowuseitem">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>发帖回帖的内容允许使用HTML代码:</strong></td>
      <td width="70%"><input type="checkbox" name="allowhtml" id="allowhtml" class="radio" value="1"<% If AllowHTML = 1 Then Response.Write " checked" End If %> /><label for="allowhtml">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>允许在聊天室发言:</strong></td>
      <td width="70%"><input type="checkbox" name="allowchat" id="allowchat" class="radio" value="1"<% If AllowChat = 1 Then Response.Write " checked" End If %> /><label for="allowchat">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>特殊显示界面:</strong><br />该段代码将被加到&lt;/body&gt;的标签前面，可以对该用户组实现一些特殊显示效果，例如“黑名单”用户看到的界面都是黑色的。</td>
      <td width="70%"><textarea name="specialinterface" rows="5" cols="40"><%= strFilter(SpecialInterface) %></textarea></td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0" id="p_invate">
    <tr class="header">
      <td height="25" colspan="2"><strong>推荐码设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否允许购买推荐码:</strong></td>
      <td width="70%"><input type="checkbox" name="allowinvate" id="allowinvate" value="1" class="radio" onclick="showinvate();"<% If AllowInvate = 1 Then Response.Write " checked" End If %> /><label for="allowinvate">是的</label></td>
    </tr>
    <tr height="25" id="p_invateprice" style="display: none;">
      <td class="altbg1"><strong>推荐码的价格:</strong></td>
      <td width="70%"><input type="text" name="invateprice" size="20" value="<%= InvatePrice %>" />&nbsp;<%= RQ.Other_Settings(0) %></td>
    </tr>
    <tr height="25" id="p_invatemaxnum" style="display: none;">
      <td class="altbg1"><strong>推荐码限购数量:</strong></td>
      <td width="70%"><input type="text" name="invatemaxnum" size="20" value="<%= InvateMaxNum %>" />&nbsp;个</td>
    </tr>
    <tr height="25" id="p_invateexpiryday" style="display: none;">
      <td class="altbg1"><strong>推荐码有效期:</strong></td>
      <td width="70%"><input type="text" name="invateexpiryday" size="20" value="<%= InvateExpiryDay %>" />&nbsp;天</td>
    </tr>
  </table>
  <p align="center"><input type="submit" id="btnsubmit" class="button" value="提交设置" /></p>
  <script type="text/javascript">
	function showpermission() {
		$('p_permission').style.display = $('p_invate').style.display = $('ifdefault').checked ? 'none' : '';
	}
	function showattach(){
		$('p_attachextensions').style.display = $('p_maxattachsize').style.display = $('allowpostattach').checked ? '' : 'none';
	}
    function showinvate(){
		$('p_invateprice').style.display = $('p_invatemaxnum').style.display = $('p_invateexpiryday').style.display = $('allowinvate').checked ? '' : 'none';
	}
	showpermission();
	showattach();
	showinvate();
  </script>
</form>
<%
End Sub

'========================================================
'保存权限设置
'========================================================
Sub SavePermission()
	Dim UserID, UserInfo, IfDefault
	Dim AllowVisit, DisablePeriodCtrl, AllowPost, AllowDirectPost, AllowReply, AnonymitySuc, AllowPostPoll
	Dim AllowPoll, AllowSearch, AllowGetAttach, AllowPostAttach, MaxAttachSize, AttachExtensions
	Dim AllowViewUserInfo, AllowUseItem, AllowHTML, AllowChat, SpecialInterface
	Dim AllowInvate, InvatePrice, InvateMaxNum, InvateExpiryDay

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT m.uid, ISNULL(a.uid, 0) FROM "& TablePre &"members m LEFT JOIN "& TablePre &"access a ON m.uid = a.uid WHERE m.uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call AdminshowTips("用户不存在或者已经被删除。", "")
	End If

	IfDefault = SafeRequest(2, "ifdefault", 0, 0, 0)

	If IfDefault = 0 Then
		AllowVisit = SafeRequest(2, "allowvisit", 0, 0, 0)
		DisablePeriodCtrl = SafeRequest(2, "disableperiodctrl", 0, 0, 0)
		AllowPost = SafeRequest(2, "allowpost", 0, 0, 0)
		AllowDirectPost = SafeRequest(2, "allowdirectpost", 0, 0, 0)
		AllowReply = SafeRequest(2, "allowreply", 0, 0, 0)
		AnonymitySuc = SafeRequest(2, "anonymitysuc", 0, 0, 0)
		AllowPostPoll = SafeRequest(2, "allowpostpoll", 0, 0, 0)
		AllowPoll = SafeRequest(2, "allowpoll", 0, 0, 0)
		AllowSearch = SafeRequest(2, "allowsearch", 0, 0, 0)
		AllowGetAttach = SafeRequest(2, "allowgetattach", 0, 0, 0)
		AllowPostAttach = SafeRequest(2, "allowpostattach", 0, 0, 0)
		MaxAttachSize = SafeRequest(2, "maxattachsize", 0, 0, 0)
		AttachExtensions = SafeRequest(2, "attachextensions", 1, "", 0)
		AllowViewUserInfo = SafeRequest(2, "allowviewuserinfo", 0, 0, 0)
		AllowUseItem = SafeRequest(2, "allowuseitem", 0, 0, 0)
		AllowHTML = SafeRequest(2, "allowhtml", 0, 0, 0)
		AllowChat = SafeRequest(2, "allowchat", 0, 0, 0)
		SpecialInterface = SafeRequest(2, "specialinterface", 1, "", 1)
		AllowInvate = SafeRequest(2, "allowinvate", 0, 0, 0)
		InvatePrice = SafeRequest(2, "invateprice", 0, 1, 0)
		InvateMaxNum = SafeRequest(2, "invatemaxnum", 0, 1, 0)
		InvateExpiryDay = SafeRequest(2, "invateexpiryday", 0, 1, 0)

		AnonymitySuc = IIF(AnonymitySuc > 100, 0, AnonymitySuc)
		MaxAttachSize = IIF(MaxAttachSize > 100000, 100000, MaxAttachSize)
		AttachExtensions = LCase(Replace(AttachExtensions, ".", ""))

		If UserInfo(1, 0) = 0 Then
			RQ.Execute("INSERT INTO "& TablePre &"access (uid, allowvisit, disableperiodctrl, allowpost, allowdirectpost, allowreply, anonymitysuc, allowpostpoll, allowpoll, allowsearch, allowgetattach, allowpostattach, maxattachsize, attachextensions, allowviewuserinfo, allowuseitem, allowhtml, allowchat, specialinterface, allowinvate, invateprice, invatemaxnum, invateexpiryday) VALUES ("& UserID &", "& AllowVisit &", "& DisablePeriodCtrl &", "& AllowPost &", "& AllowDirectPost &", "& AllowReply &", "& AnonymitySuc &", "& AllowPostPoll &", "& AllowPoll &", "& AllowSearch &", "& AllowGetAttach &", "& AllowPostAttach &", "& MaxAttachSize &", '"& AttachExtensions &"', "& AllowViewUserInfo &", "& AllowUseItem &", "& AllowHTML &", "& AllowChat &", N'"& SpecialInterface &"', "& AllowInvate &", "& InvatePrice &", "& InvateMaxNum &", "& InvateExpiryDay &")")
		Else
			RQ.Execute("UPDATE "& TablePre &"access SET allowvisit = "& AllowVisit &", disableperiodctrl = "& DisablePeriodCtrl &", allowpost = "& AllowPost &", allowdirectpost = "& AllowDirectPost &", allowreply = "& AllowReply &", anonymitysuc = "& AnonymitySuc &", allowpostpoll = "& AllowPostPoll &", allowpoll = "& AllowPoll &", allowsearch = "& AllowSearch &", allowgetattach = "& AllowGetAttach &", allowpostattach = "& AllowPostAttach &", maxattachsize = "& MaxAttachSize &", attachextensions = '"& AttachExtensions &"', allowviewuserinfo = "& AllowViewUserInfo &", allowuseitem = "& AllowUseItem &", allowhtml = "& AllowHTML &", allowchat = "& AllowChat &", specialinterface = N'"& SpecialInterface &"', allowinvate = "& AllowInvate &", invateprice = "& InvatePrice &", invatemaxnum = "& InvateMaxNum &", invateexpiryday = "& InvateExpiryDay &" WHERE uid = "& UserID)
		End If
		RQ.Execute("UPDATE "& TablePre &"members SET accessmasks = 1 WHERE uid = "& UserID)
	Else
		'使用默认的用户组权限
		RQ.Execute("UPDATE "& TablePre &"members SET accessmasks = 0 WHERE uid = "& UserID)
		RQ.Execute("DELETE FROM "& TablePre &"access WHERE uid = "& UserID)
	End If

	Call closeDatabase()
	Call AdminshowTips("权限设置完毕。", "?action=permission&uid="& UserID)
End Sub

'========================================================
'根据查询条件显示用户列表
'========================================================
Sub ListMembers()
	Dim strSQL, sqlwhere, tbCol
	Dim RecordCount, PageCount, Page
	Dim show, GroupID, Query_UserName, Query_UserIP, Fuzzy_Query
	Dim MemberListArray

	show = SafeRequest(3, "show", 1, "", 0)
	GroupID = SafeRequest(3, "gid", 0, 0, 0)
	Query_UserName = Replace(Replace(Replace(SafeRequest(3, "query_username", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Query_UserIP = Replace(Replace(Replace(SafeRequest(3, "query_userip", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Fuzzy_Query = SafeRequest(3, "fuzzyquery", 0, 0, 0)

	Select Case show
		Case "reguser"
			sqlwhere = " AND m.regtime >= DATEADD(d, -3, GETDATE())"
			tbCol = "regtime"
		Case "loginuser"
			sqlwhere = " AND m.logintime >= DATEADD(d, -3, GETDATE())"
			tbCol = "logintime"
		Case "creditstop"
			tbCol = "credits"
		Case "topictop"
			tbCol = "topics"
		Case "replytop"
			tbCol = "posts"
		Case Else
			If GroupID > 0 Then
				sqlwhere = sqlwhere &" AND usergroupid = "& GroupID
			End If

			If Len(Query_UserName) > 0 Then
				If Fuzzy_Query = 1 Then
					sqlwhere = sqlwhere &" AND CHARINDEX(N'"& Query_UserName &"', username) > 0"
				Else
					sqlwhere = sqlwhere &" AND username = N'"& Query_UserName &"'"
				End If
			End If

			If Len(Query_UserIP) > 0 Then
				If Fuzzy_Query = 1 Then
					sqlwhere = sqlwhere &" AND (CHARINDEX('"& Query_UserIP &"', regip) > 0 OR CHARINDEX('"& Query_UserIP &"', lastloginip) > 0 OR CHARINDEX('"& Query_UserIP &"', loginip) > 0)"
				Else
					sqlwhere = sqlwhere &" AND (regip = '"& Query_UserIP &"' OR lastloginip = '"& Query_UserIP &"' OR loginip = '"& Query_UserIP &"')"
				End If
			End If
	
			tbCol = "uid"
	End Select

	If InArray(Array("creditstop", "topictop", "replytop"), show) Then
		MemberListArray = RQ.Query("SELECT TOP 50 m.uid, m.username, m.usergroupid, m.credits, m.regtime, m.logintime, m.topics, m.posts, g.name FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid ORDER BY m."& tbCol &" DESC")
	Else
		RecordCount = Conn.Execute("SELECT COUNT("& tbCol &") FROM "& TablePre &"members m WHERE 1 = 1"& sqlwhere)(0)
		dbQueryNum = dbQueryNum + 1

		If RecordCount > 0 Then
			PageCount = ABS(Int(-(RecordCount / 50)))
			Page = SafeRequest(3, "page", 0, 1, 0)
			Page = IIF(Page > PageCount, Page = PageCount, Page)

			strSQL = "SELECT TOP 50 m.uid, m.username, m.usergroupid, m.credits, m.regtime, m.logintime, m.topics, m.posts, g.name FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE 1 = 1"& sqlwhere
			If Page > 1 Then
				strSQL = strSQL &" AND m."& tbCol &" < (SELECT MIN("& tbCol &") FROM (SELECT TOP "& 50 * (Page - 1) &" "& tbCol &" FROM "& TablePre &"members WHERE 1 = 1"& sqlwhere &" ORDER BY "& tbCol &" DESC) AS tblTemp)"
			End If
			strSQL = strSQL &" ORDER BY m."& tbCol &" DESC"

			MemberListArray = RQ.Query(strSQL)
		End If
	End If

	Call Main()
	Call closeDatabase()
%>
<br />
<form name="deletemembers" method="post" action="?action=deletemembers" onsubmit="javascript:if(!confirm('您是否确定删除用户？')) return false;$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">用户列表</td>
    </tr>
    <tr class="category">
      <td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'd_uid');" />删?</td>
      <td>用户名</td>
      <td>用户组</td>
      <td><%= RQ.Other_Settings(0) %></td>
      <td>发帖</td>
      <td>回帖</td>
      <td>最后登陆</td>
      <td>操作</td>
    </tr>
    <% If IsArray(MemberListArray) Then %>
    <% For i = 0 To UBound(MemberListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_uid" class="radio" value="<%= MemberListArray(0, i) %>"<%= IIF(MemberListArray(2, i) = 1, " disabled", "") %> /></td>
      <td class="altbg2"><a href="?action=detail&uid=<%= MemberListArray(0, i) %>"><%= MemberListArray(1, i) %></a></td>
      <td class="altbg1"><%= MemberListArray(8, i) %></td>
      <td class="altbg2"><%= MemberListArray(3, i) %></td>
      <td class="altbg1"><%= MemberListArray(6, i) %></td>
      <td class="altbg2"><%= MemberListArray(7, i) %></td>
      <td class="altbg1"><%= FormatDateTime(MemberListArray(5, i), 2) %></td>
      <td class="altbg2"><a href="?action=usergroup&uid=<%= MemberListArray(0, i) %>">[用户组]</a><a href="?action=permission&uid=<%= MemberListArray(0, i) %>">[权限]</a><a href="?action=set_credits&uid=<%= MemberListArray(0, i) %>">[<%= RQ.Other_Settings(0) %>和道具]</a><a href="?action=detail&uid=<%= MemberListArray(0, i) %>">[详情]</a></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="8"><em>没有找到符合条件的用户</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center">
    <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action="& Action &"&gid="& GroupID &"&query_username="& Query_UserName &"&query_userip="& Query_UserIP) %>
  </div>
  <% End If %>
  <p align="center"><input type="submit" id="btnsubmit" value="删除选中的用户" class="button" /></p>
</form>
<%
End Sub

'========================================================
'头部信息(查询条件)
'========================================================
Sub Main()
	GroupListArray = RQ.Query("SELECT gid, name, types FROM "& TablePre &"usergroups WHERE gid <> 5")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;用户管理</td>
  </tr>
</table>
<br />
<form method="get" name="list_members" action="?" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="action" value="listmembers" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>列出用户</strong></td>
    </tr>
    <tr height="25" class="category">
      <td colspan="2">快捷查询:
        [<a href="?action=listmembers&show=all">所有用户</a>]
        [<a href="?action=listmembers&show=reguser">3天内注册</a>]
        [<a href="?action=listmembers&show=loginuser">3天内登陆</a>]
        [<a href="?action=listmembers&show=creditstop"><%= RQ.Other_Settings(0) %> TOP50</a>]
        [<a href="?action=listmembers&show=topictop">发帖TOP50</a>]
        [<a href="?action=listmembers&show=replytop">回帖TOP50</a>]
	  </td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>按用户组列出:</strong></td>
      <td width="80%"><select name="gid" onchange="this.form.submit();">
	    <option value="0">--</option>
		<% If IsArray(GroupListArray) Then %>
		<% For i = 0 To UBound(GroupListArray, 2) %>
        <option value="<%= GroupListArray(0, i) %>"<% If SafeRequest(3, "gid", 0, 0, 0) = GroupListArray(0, i) Then Response.Write " selected" End If %>><%= GroupListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1" width="30%"><strong>查找用户:</strong></td>
      <td><input type="text" name="query_username" size="20" value="<%= SafeRequest(3, "query_username", 1, "", 0) %>" /></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>查找IP:</strong></td>
      <td><input type="text" name="query_userip" size="20" value="<%= SafeRequest(3, "query_userip", 1, "", 0) %>" /></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>查询方式:</strong></td>
      <td><input type="checkbox" name="fuzzyquery" id="fuzzyquery" value="1" class="radio"<% If SafeRequest(3, "fuzzyquery", 0, 0, 0) = 1 Then Response.Write " checked" End If %> /><label for="fuzzyquery">模糊查询</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1">&nbsp;</td>
      <td><input type="submit" id="btnsubmit" value="提交" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub
%>