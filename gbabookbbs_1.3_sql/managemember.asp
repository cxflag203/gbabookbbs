<!--#include file="include/inc.asp"-->
<!--#include file="include/md5.inc.asp"-->
<%
If RQ.AllowEditUser = 0 And RQ.AllowPunishUser = 0 Then
	Call RQ.showTips("您没有权限访问管理页面。", "", "")
End If

Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "members"
		Call Members()
	Case "update_usergroup"
		Call Update_UserGroup()
	Case "remove_restricted"
		Call Remove_Restricted()
	Case "detail"
		Call Detail()
	Case "update_detail"
		Call Update_Detail()
	Case "viewlogs"
		Call ViewLogs()
	Case "viewitemlogs"
		Call ViewItemLogs()
	Case "view_topics"
		Call View_Topics()
	Case "delete_topics"
		Call Delete_Topics()
	Case "view_posts"
		Call View_Posts()
	Case "delete_posts"
		Call Delete_Posts()
	Case Else
		Call HeadNav()
End Select

'========================================================
'修改用户所属的用户组(提交后的处理)
'========================================================
Sub Update_UserGroup()
	'验证权限
	If RQ.AllowPunishUser = 0 Then
		Call RQ.showTips("您没有处罚用户的权限。", "", "")
	End If

	Dim UserID, GroupID, ExpiryTime, Reason, Subtract_Credits, strOperation, eUserGroupID, eAdminGroupID
	Dim UserInfo, GroupInfo
	Dim strSQL

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	GroupID = SafeRequest(2, "gid", 0, 0, 0)
	ExpiryTime = SafeRequest(2, "expirytime", 2, Date(), 0)
	Reason = SafeRequest(2, "reason", 1, "", 0)
	Subtract_Credits = SafeRequest(2, "subtract_credits", 0, 0, 0)

	If GroupID = 0 Then
		Call RQ.showTips("请选择要转换的用户组。", "", "")
	End If

	If Len(CheckContent(Reason)) = 0 Then
		Call RQ.showTips("请填写好处罚原因。", "", "")
	End If

	'查询用户当前信息
	UserInfo = RQ.Query("SELECT m.username, m.usergroupid, m.admingroupid, g.name, g.types FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("该用户不存在或者已经被删除。", "", "")
	End If

	'查询被设置后的用户组信息
	GroupInfo = RQ.Query("SELECT name, types FROM "& TablePre &"usergroups WHERE gid = "& GroupID &" AND types = 'restricted' AND gid IN(6,7,8,9)")
	If Not IsArray(GroupInfo) Then
		Call RQ.showTips("用户组不正确。", "", "")
	End If

	'异动报告内容
	strOperation = strOperation &"<span style=""color: #FF0080;"">列入"& GroupInfo(0, 0) &"。</span>"

	'设置用户组过期时间
	If ExpiryTime > Date() Then
		strSQL = strSQL &", groupexpiry = "& DatetoNum(ExpiryTime)
	Else
		strSQL = strSQL &", groupexpiry = 0"
	End If

	'扣除金钱
	If Subtract_Credits > 0 Then
		strSQL = strSQL &", credits = credits - "& Subtract_Credits
		strOperation = strOperation &"<span style=""color: #FF0080;"">，扣除"& RQ.Other_Settings(0) & Subtract_Credits &"点。</span>"
	End If

	eAdminGroupID = UserInfo(2, 0)
	eUserGroupID = IIF(eAdminGroupID > 0, eAdminGroupID, 4)

	'更新用户组信息
	RQ.Execute("UPDATE "& TablePre &"members SET usergroupid = "& GroupID & strSQL &" WHERE uid = "& UserID)
	RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)

	If ExpiryTime > Date() Then
		RQ.Execute("INSERT INTO "& TablePre &"groupexpiry (uid, usergroupid, admingroupid) VALUES ("& UserID &", "& eUserGroupID &", "& eAdminGroupID &")")
	End If

	'记入异动内容
	Call RQ.SetLog(UserID, UserInfo(0, 0), strOperation, Reason)

	Call closeDatabase()
	Call RQ.showTips("用户组设置成功。", "?action=detail&uid="& UserID, "")
End Sub

'========================================================
'解除用户处罚
'========================================================
Sub Remove_Restricted()
	'验证权限
	If RQ.AllowPunishUser = 0 Then
		Call RQ.showTips("您没有解除处罚的权限。", "", "")
	End If

	Dim UserID, UserInfo, strReason, UserGroupID

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	strReason = SafeRequest(2, "reason", 1, "", 0)

	If Len(strReason) = 0 Then
		Call RQ.showTips("请填写好解除处罚的原因。", "", "")
	End If

	strReason = IIF(Len(strReason) > 255, Left(strReason, 255), strReason)

	UserInfo = RQ.Query("SELECT m.username, m.admingroupid, g.name, g.types FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
	End If

	If UserInfo(3, 0) = "restricted" Then
		UserGroupID = IIF(UserInfo(1, 0) > 0, UserInfo(1, 0), 4)

		'恢复用户组信息
		RQ.Execute("UPDATE "& TablePre &"members SET usergroupid = "& UserGroupID &", groupexpiry = 0 WHERE uid = "& UserID)

		'删除用户组过期信息
		RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)

		'记入异动内容
		Call RQ.SetLog(UserID, UserInfo(0, 0), "<span style=""color: #FF0080;"">解除"& UserInfo(2, 0) &"。</span>", strReason)
	End If

	Call closeDatabase()
	Call RQ.showTips("用户状态已经恢复正常。", "?action=detail&uid="& UserID, "")
End Sub

'========================================================
'显示用户详细资料
'========================================================
Sub Detail()
	Dim UserID, UserInfo, strReadonly
	Dim ItemListArray, MarketListArray, GroupListArray
	Dim eGroupInfo, ExpiryTime

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT m.username, m.admingroupid, m.usergroupid, m.credits, m.regtime, m.regip, m.lastlogintime, m.lastloginip, m.logintime, m.loginip, m.logincount, m.newtopictime, m.topics, m.posts, m.groupexpiry, mf.designation, mf.signature, mf.ignorepm, g.types FROM "& TablePre &"members m INNER JOIN "& TablePre &"memberfields mf ON m.uid = mf.uid INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call RQ.showTips("该用户不存在或者已经被删除。", "", "")
	End If

	ItemListArray = RQ.Query("SELECT mi.num, i.name FROM "& TablePre &"memberitems mi INNER JOIN "& TablePre &"items i ON mi.itemid = i.itemid WHERE mi.uid = "& UserID)

	MarketListArray = RQ.Query("SELECT im.price, im.num, i.name FROM "& TablePre &"itemmarket im INNER JOIN "& TablePre &"items i ON im.itemid = i.itemid WHERE im.uid = "& UserID)

	GroupListArray = RQ.Query("SELECT gid, name FROM "& TablePre &"usergroups WHERE types = 'restricted' AND gid IN(6,7,8,9) ORDER BY gid ASC")

	If UserInfo(14, 0) > 0 Then
		eGroupInfo = RQ.Query("SELECT 1 FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)

		If Not IsArray(eGroupInfo) Then
			RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)
			RQ.Execute("UPDATE "& TablePre &"members SET groupexpiry = 0 WHERE uid = "& UserID)
		Else
			ExpiryTime = NumtoDate(UserInfo(14, 0))
		End If
	End If

	Call HeadNav()
%>
<br />
<form name="detail" method="post" action="?action=update_detail" onsubmit="$('btnupdatedetail').value='正在提交,请稍后...';$('btnupdatedetail').disabled=true;">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="4"><strong>用户详细信息</strong></td>
    </tr>
    <tr>
      <td width="40%">用户名:</td>
      <td><%= UserInfo(0, 0) %>
	    <span style="padding-left: 20px;">[<a href="?action=viewlogs&uid=<%= UserID %>" class="bluelink">异动报告</a>]
        <% If UserInfo(12, 0) > 0 Then %>[<a href="?action=view_topics&uid=<%= UserID %>" class="bluelink">发帖</a>]<% End If %>
        <% If UserInfo(13, 0) > 0 Then %>&nbsp;[<a href="?action=view_posts&uid=<%= UserID %>" class="bluelink">回帖</a>]<% End If %></span>
      </td>
    </tr>
	<% If RQ.AdminGroupID = 1 Or (RQ.AdminGroupID = 2 And RQ.AllowEditUser = 1) Then %>
    <tr>
	  <td>新密码:<br />如果不修改密码此处请留空</td>
      <td><input type="text" name="password" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td><%= RQ.Other_Settings(0) %>:</td>
      <td><input type="text" name="credits" value="<%= UserInfo(3, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>注册时间:</td>
      <td><input type="text" name="regtime" value="<%= UserInfo(4, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>注册IP:</td>
	  <td><input type="text" name="regip" value="<%= Trim(UserInfo(5, 0)) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>上次登陆时间:</td>
	  <td><input type="text" name="lastlogintime" value="<%= UserInfo(6, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>上次登陆IP:</td>
	  <td><input type="text" name="lastloginip" value="<%= Trim(UserInfo(7, 0)) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>最后登陆时间:</td>
      <td><input type="text" name="logintime" value="<%= UserInfo(8, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>最后登陆IP:</td>
      <td><input type="text" name="loginip" value="<%= Trim(UserInfo(9, 0)) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>登陆次数:</td>
      <td><input type="text" name="logincount" value="<%= UserInfo(10, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>最后发帖时间:</td>
      <td><input type="text" name="newtopictime" value="<%= NumtoDate(UserInfo(11, 0)) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>发帖数量:</td>
      <td><input type="text" name="topics" value="<%= UserInfo(12, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>回帖数量:</td>
	  <td><input type="text" name="posts" value="<%= UserInfo(13, 0) %>" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>称号:</td>
	  <td><input type="text" name="designation" value="<%= strFilter(UserInfo(15, 0)) %>" size="20" maxlength="100" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>签名:</td>
	  <td style="padding: 8px 10px;"><textarea name="signature" rows="5" cols="40" class="textareagrey"><%= strFilter(Preg_Replace(UserInfo(16, 0), "<br(.*?)>", vbCrLf)) %></textarea></td>
    </tr>
    <tr>
	  <td>屏蔽某人的短消息:</td>
	  <td style="padding: 8px 10px;"><textarea name="ignorepm" rows="5" cols="40" class="textareagrey"><%= UserInfo(17, 0) %></textarea></td>
    </tr>
	<% If IsArray(ItemListArray) Then %>
    <tr>
      <td>该用户的道具:</td>
	  <td><select>
	    <% For i = 0 To UBound(ItemListArray, 2) %>
	    <option><%= ItemListArray(1, i) %>(<%= ItemListArray(0, i) %>)</option>
	    <% Next %>
	  </select></td>
    </tr>
	<% End If %>
	<% If IsArray(MarketListArray) Then %>
    <tr>
	  <td>道具市场(价格*数量):</td>
	  <td><select>
	    <% For i = 0 To UBound(MarketListArray, 2) %>
	    <option><%= MarketListArray(2, i) %>(<%= MarketListArray(0, i) %> * <%= MarketListArray(1, i) %>)</option>
	    <% Next %>
	  </select></td>
    </tr>
	<% End If %>
    <tr>
	  <td>&nbsp;</td>
	  <td><input type="submit" id="btnupdatedetail" value="更新用户资料" class="button" /></td>
    </tr>
	<% Else %>
    <tr>
	  <td><%= RQ.Other_Settings(0) %>:</td>
      <td><%= UserInfo(3, 0) %></td>
    </tr>
    <tr>
      <td>注册时间:</td>
      <td><%= UserInfo(4, 0) %></td>
    </tr>
    <tr>
	  <td>注册IP:</td>
	  <td><%= Trim(UserInfo(5, 0)) %></td>
    </tr>
    <tr>
      <td>上次登陆时间:</td>
	  <td><%= UserInfo(6, 0) %></td>
    </tr>
    <tr>
	  <td>上次登陆IP:</td>
	  <td><%= Trim(UserInfo(7, 0)) %></td>
    </tr>
    <tr>
      <td>最后登陆时间:</td>
      <td><%= UserInfo(8, 0) %></td>
    </tr>
    <tr>
	  <td>最后登陆IP:</td>
      <td><%= UserInfo(9, 0) %></td>
    </tr>
    <tr>
      <td>登陆次数:</td>
      <td><%= UserInfo(10, 0) %></td>
    </tr>
    <tr>
	  <td>最后发帖时间:</td>
      <td><%= NumtoDate(UserInfo(11, 0)) %></td>
    </tr>
    <tr>
      <td>发帖数量:</td>
      <td><%= UserInfo(12, 0) %></td>
    </tr>
    <tr>
	  <td>回帖数量:</td>
	  <td><%= UserInfo(13, 0) %></td>
    </tr>
	<% If RQ.AllowEditUser = 1 Then %>
    <tr>
	  <td>称号:</td>
	  <td><input type="text" name="designation" value="<%= strFilter(UserInfo(15, 0)) %>" size="20" maxlength="100" class="inputgrey" /></td>
    </tr>
    <tr>
	  <td>签名:</td>
	  <td style="padding: 8px 10px;"><textarea name="signature" rows="5" cols="40" class="textareagrey"><%= strFilter(Preg_Replace(UserInfo(16, 0), "<br(.*?)>", vbCrLf)) %></textarea></td>
    </tr>
	<% Else %>
    <tr>
	  <td>称号:</td>
	  <td><%= strFilter(UserInfo(15, 0)) %></td>
    </tr>
    <tr>
	  <td>签名:</td>
	  <td><%= strFilter(UserInfo(16, 0)) %></td>
    </tr>
	<% End If %>
    <tr>
	  <td>屏蔽某人的短消息:</td>
	  <td><%= UserInfo(17, 0) %></td>
    </tr>
    <tr>
      <td>该用户的道具:</td>
	  <td>
	    <% If IsArray(ItemListArray) Then %>
	    <select>
	      <% For i = 0 To UBound(ItemListArray, 2) %>
	      <option><%= ItemListArray(1, i) %>(<%= ItemListArray(0, i) %>)</option>
	      <% Next %>
	    </select>
		<% Else %>
		<em>无</em>
	    <% End If %>
	  </td>
    </tr>
    <tr>
	  <td>道具市场(价格*数量):</td>
	  <td>
	    <% If IsArray(MarketListArray) Then %>
	    <select>
	      <% For i = 0 To UBound(MarketListArray, 2) %>
	      <option><%= MarketListArray(2, i) %>(<%= MarketListArray(0, i) %> * <%= MarketListArray(1, i) %>)</option>
	      <% Next %>
	    </select>
		<% Else %>
		<em>无</em>
		<% End If %>
	  </td>
    </tr>
	<% If RQ.AllowEditUser = 1 Then %>
    <tr>
	  <td>&nbsp;</td>
	  <td><input type="submit" id="btnupdatedetail" value="更新用户资料" class="button" /></td>
    </tr>
	<% End If %>
	<% End If %>
  </table>
</form>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
  <tr class="header">
    <td colspan="4"><strong>用户组信息</strong></td>
  </tr>
  <tr>
    <td width="40%"><span class="underline"><%= UserInfo(0, 0) %></span>当前所在的用户组:</td>
    <td><%= RQ.Get_GroupName(UserInfo(2, 0)) %><% If IsDate(ExpiryTime) Then %><em>(有效期至<%= ExpiryTime %>)</em><% End If %></td>
  </tr>
  <% If UserInfo(1, 0) > 0 Then %>
  <tr>
    <td><span class="underline"><%= UserInfo(0, 0) %></span>当前所在的管理组:</td>
    <td><%= RQ.Get_GroupName(UserInfo(1, 0)) %></td>
  </tr>
  <% End If %>
</table>
<% If RQ.AllowPunishUser = 1 Then %>
<% If UserInfo(18, 0) = "restricted" Then %>
<br />
<form method="post" name="remove_restricted" action="?action=remove_restricted" onsubmit="$('btnrestore').value='正在提交,请稍后...';$('btnrestore').disabled=true;">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="2"><strong>解除处罚</strong></td>
    </tr>
	<tr>
	  <td width="40%">操作原因:<br />这里必须填写好解除原因</td>
	  <td><input type="text" name="reason" size="40" class="inputgrey" /></td>
	</tr>
	<tr>
	  <td>&nbsp;</td>
	  <td><input type="submit" id="btnrestore" value="提交设置" class="button" /></td>
	</tr>
  </table>
</form>
<% End If %>
<br />
<script type="text/javascript" src="js/calendar.js"></script>
<form method="post" name="change_usergroup" action="?action=update_usergroup" onsubmit="$('btnupdategroup').value='正在提交,请稍后...';$('btnupdategroup').disabled=true;">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="2"><strong>处罚用户</strong></td>
    </tr>
	<tr>
	  <td width="40%">将该用户设为:</td>
	  <td><select name="gid">
	    <option value="0">--</option>
	    <% If IsArray(GroupListArray) Then %>
		<% For i = 0 To UBound(GroupListArray, 2) %>
        <option value="<%= GroupListArray(0, i) %>"<% If UserInfo(1, 0) = GroupListArray(0, i) Then Response.Write " selected" End If %>><%= GroupListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
	</tr>
	<tr>
	  <td>有效期至:<br />不填则为长期</td>
	  <td><input type="text" id="expirytime" name="expirytime" size="20" value="<%= Date() + 3 %>" onclick="calendar.showCalendar(['expirytime'],['expirytime'])" class="inputgrey" /></td>
	</tr>
	<tr>
	  <td>操作原因:<br />这里必须填写好处罚原因</td>
	  <td><input type="text" name="reason" size="40" class="inputgrey" /></td>
	</tr>
	<tr>
	  <td>扣除<%= RQ.Other_Settings(0) %>:<br />直接填写需要扣除的数量即可</td>
	  <td><input type="text" name="subtract_credits" size="20" class="inputgrey" /></td>
	</tr>
	<tr>
	  <td>&nbsp;</td>
	  <td><input type="submit" id="btnupdategroup" value="提交设置" class="button" /></td>
	</tr>
  </table>
</form>
<% End If %>
<%
	Call closeDatabase()
	RQ.Footer()
End Sub

'========================================================
'更新用户资料
'========================================================
Sub Update_Detail()
	If RQ.AllowPunishUser = 0 And RQ.AdminGroupID <> 1 Then
		Call RQ.showTips("您没有编辑用户的权限。", "", "")
	End If

	Dim UserID, UserInfo, strSQL
	Dim Password, Credits, RegTime, RegIP, LastLoginTime, LastLoginIP, LoginTime, LoginIP, LoginCount, NewTopicTime, Topics, Posts, Designation, Signature, Ignorepm

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call RQ.showTips("该用户不存在或者已经被删除。", "", "")
	End If

	Password = SafeRequest(2, "password", 1, "", 0)
	Credits = Request.Form("credits")
	RegTime = SafeRequest(2, "regtime", 2, Now(), 0)
	RegIP = SafeRequest(2, "regip", 1, "", 0)
	LastLoginTime = SafeRequest(2, "lastlogintime", 2, Now(), 0)
	LastLoginIP = SafeRequest(2, "lastloginip", 1, "", 0)
	LoginTime = SafeRequest(2, "logintime", 2, Now(), 0)
	LoginIP = SafeRequest(2, "loginip", 1, "", 0)
	LoginCount = SafeRequest(2, "logincount", 0, 1, 0)
	NewTopicTime = SafeRequest(2, "newtopictime", 2, Now(), 0)
	Topics = SafeRequest(2, "topics", 0, 0, 0)
	Posts = SafeRequest(2, "posts", 0, 0, 0)
	Designation = SafeRequest(2, "designation", 1, "", 1)
	Signature = SafeRequest(2, "signature", 1, "", 1)
	Ignorepm = Replace(SafeRequest(2, "ignorepm", 1, "", 0), vbCrLf, "")

	Credits = IIF(Not IsNumeric(Credits), 0, CLng(Credits))
	RegIP = IIF(Len(RegIP) > 15, Left(RegIP, 15), RegIP)
	LastLoginIP = IIF(Len(LastLoginIP) > 15, Left(LastLoginIP, 15), LastLoginIP)
	LoginIP = IIF(Len(LoginIP) > 15, Left(LoginIP, 15), LoginIP)
	Signature = IIF(Len(Signature) > 100, Left(Signature, 100), Signature)

	NewTopicTime = DatetoNum(NewTopicTime)

	If Len(Password) > 0 Then
		strSQL = ", thepassword = '"& MD5(Password) &"'"
	End If

	If RQ.AdminGroupID = 1 Or RQ.AdminGroupID = 2 Then
		RQ.Execute("UPDATE "& TablePre &"members SET credits = "& Credits &", regtime = '"& RegTime &"', regip = '"& RegIP &"', lastlogintime = '"& LastLoginTime &"', lastloginip = '"& LastLoginIP &"', logintime = '"& LoginTime &"', loginip = '"& LoginIP &"', logincount = "& LoginCount &", newtopictime = "& NewTopicTime &", topics = "& Topics &", posts = "& Posts & strSQL &" WHERE uid = "& UserID)

		RQ.Execute("UPDATE "& TablePre &"memberfields SET designation = N'"& Designation &"', signature = N'"& Signature &"', ignorepm = N'"& Ignorepm &"' WHERE uid = "& UserID)
	Else
		RQ.Execute("UPDATE "& TablePre &"memberfields SET designation = N'"& Designation &"', signature = N'"& Signature &"' WHERE uid = "& UserID)
	End If

	Call closeDatabase()
	Call RQ.showTips("用户资料更新成功。", "?action=detail&uid="& UserID, "")
End Sub

'========================================================
'显示用户的异动报告
'========================================================
Sub ViewLogs()
	Dim UserID, UserInfo
	Dim LogListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username FROM "& TablePre &"members WHERE uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call RQ.showTips ("该用户不存在或者已经被删除。", "", "")
	End If

	LogListArray = RQ.Query("SELECT uid, username, userip, targetuid, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE uid = "& UserID &" UNION SELECT uid, username, userip, targetuid, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE targetuid = "& UserID &" ORDER BY posttime DESC")

	Call HeadNav()
	Call closeDatabase()
%>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
  <tr class="header">
    <td colspan="9"><strong><%= UserInfo(0, 0) %>的异动报告</strong><span style="padding-left: 20px;"><a href="?action=viewitemlogs&uid=<%= UserID %>" class="bluelink">查看道具转让记录</a></span></td>
  </tr>
  <% If IsArray(LogListArray) Then %>
  <% For i = 0 To UBound(LogListArray, 2) %>
  <tr>
    <td><%= LogListArray(7, i) &" 被修改人:<a href=""?action=detail&uid="& LogListArray(3, i) &""" class=""underline"">"& LogListArray(4, i) &"</a> 修改人:<a href=""?action=detail&uid="& LogListArray(0, i) &""" class=""underline"">"& LogListArray(1, i) &"</a> 异动内容:"& LogListArray(5, i) &"<br />异动原因:"& LogListArray(6, i) %></td>
  </tr>
  <% Next %>
  <% End If %>
</table>
<p align="center"><input type="button" value="返回用户资料" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" /></p>
<%
	RQ.Footer()
End Sub

'========================================================
'显示用户的道具转让记录
'========================================================
Sub ViewItemLogs()
	Dim UserID, UserInfo
	Dim LogListArray

	UserID = SafeRequest(3, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT username FROM "& TablePre &"members WHERE uid = "& UserID)

	If Not IsArray(UserInfo) Then
		Call RQ.showTips ("该用户不存在或者已经被删除。", "", "")
	End If

	LogListArray = RQ.Query("SELECT ml.uid, ml.username, ml.userip, ml.targetuid, ml.targetusername, ml.num, ml.price, ml.posttime, i.name FROM "& TablePre &"itemmarketlogs ml INNER JOIN "& TablePre &"items i ON ml.itemid = i.itemid WHERE ml.uid = "& UserID &" UNION SELECT ml.uid, ml.username, ml.userip, ml.targetuid, ml.targetusername, ml.num, ml.price, ml.posttime, i.name FROM "& TablePre &"itemmarketlogs ml INNER JOIN "& TablePre &"items i ON ml.itemid = i.itemid WHERE ml.targetuid = "& UserID &" ORDER BY ml.posttime DESC")

	Call HeadNav()
	Call closeDatabase()
%>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
  <tr class="header">
    <td colspan="9"><strong><%= UserInfo(0, 0) %>的道具转让记录</strong><span style="padding-left: 20px;"><a href="?action=viewlogs&uid=<%= UserID %>" class="bluelink">查看异动报告</a></span></td>
  </tr>
  <% If IsArray(LogListArray) Then %>
  <% For i = 0 To UBound(LogListArray, 2) %>
  <tr>
    <td><%= LogListArray(7, i) &" "& LogListArray(8, i) &"("& IIF(LogListArray(6, i) > 0, "寄卖"& LogListArray(6, i) & RQ.Other_Settings(0) &" ", "") & Trim(LogListArray(2, i)) &")X"& LogListArray(5, i) &" 转让人:<a href=""?action=detail&uid="& LogListArray(0, i) &""" class=""underline"">"& LogListArray(1, i) &"</a> 接收人:<a href=""?action=detail&uid="& LogListArray(3, i) &""" class=""underline"">"& LogListArray(4, i) &"</a>" %></td>
  </tr>
  <% Next %>
  <% End If %>
</table>
<p align="center"><input type="button" value="返回用户资料" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" /></p>
<%
	RQ.Footer()
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
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
	End If

	RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE uid = "& UserID)(0)

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP 30 tid, fid, title, lastupdate, clicks, posts FROM "& TablePre &"topics WHERE uid = "& UserID

		If Page > 1 Then
			strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& 30 * (Page - 1) &" lastupdate FROM "& TablePre &"topics WHERE uid = "& UserID &" ORDER BY lastupdate DESC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY lastupdate DESC"

		TopicListArray = RQ.Query(strSQL)
	End If

	Call HeadNav()
	Call closeDatabase()
%>
<br />
<form name="delete_topics" method="post" action="?action=delete_topics">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="9"><strong><%= UserInfo(0, 0) %>的发帖</strong><% If UserInfo(1, 0) > 0 Then %><span style="padding-left: 20px;"><a href="?action=view_posts&uid=<%= UserID %>" class="bluelink">查看<%= UserInfo(0, 0) %>的回帖</a></span><% End If %></td>
    </tr>
    <tr class="category">
      <% If RQ.AllowPunishUser = 1 Then %><td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'tid')" /></td><% End If %>
      <td><strong>标题</strong></td>
      <td width="14%"><strong>回复</strong></td>
      <td width="15%"><strong>浏览</strong></td>
    </tr>
    <% If IsArray(TopicListArray) Then %>
    <% For i = 0 To UBound(TopicListArray, 2) %>
    <tr>
      <% If RQ.AllowPunishUser = 1 Then %><td><input type="checkbox" name="tid" value="<%= TopicListArray(0, i) %>" class="radio" /></td><% End If %>
      <td><a href="viewtopic.asp?fid=<%= TopicListArray(1, i) %>&tid=<%= TopicListArray(0, i) %>" target="_blank" title="最后更新: <%= TopicListArray(3, i) %>"><%= dfc(TopicListArray(2, i)) %></a></td>
      <td><%= TopicListArray(5, i) %></td>
      <td><%= TopicListArray(4, i) %></td>
    </tr>
    <% Next %>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center">
    <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=view_topics&uid="& UserID) %>
  </div>
  <% End If %>
  <p align="center">
    <input type="button" value="返回用户资料" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" />
    <% If RQ.AllowPunishUser = 1 Then %><input type="submit" value="删除选中的帖子" class="button" /><% End If %>
  </p>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'删除用户发表的帖子
'========================================================
Sub Delete_Topics()
	'验证权限
	If RQ.AllowPunishUser = 0 Then
		Call RQ.showTips("您没有处罚用户的权限。", "", "")
	End If

	Dim UserID, UserInfo
	Dim TopicID, ForumListArray, ForumInfo, Topics

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
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

			For i = 0 To UBound(ForumListArray, 2)
				
				Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& ForumListArray(0, i) &" AND displayorder >= 0")(0)
				RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &" WHERE fid = "& ForumListArray(0, i))

				Call RQ.Update_TopicNum(ForumListArray(0, i), Topics)
			Next
		End If
	End If

	Call closeDatabase()
	Call RQ.showTips("帖子删除成功。", "?action=view_topics&uid="& UserID, "")
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
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
	End If

	RecordCount = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE uid = "& UserID &" AND iffirst = 0")(0)
	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP 30 pid, tid, fid, tid, message, posttime FROM "& TablePre &"posts WHERE uid = "& UserID &" AND iffirst = 0"

		If Page > 1 Then
			strSQL = strSQL &" AND pid < (SELECT MIN(pid) FROM (SELECT TOP "& 30 * (Page - 1) &" pid FROM "& TablePre &"posts WHERE uid = "& UserID &" AND iffirst = 0 ORDER BY pid DESC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY pid DESC"

		PostListArray = RQ.Query(strSQL)
	End If

	Call HeadNav()
	Call closeDatabase()
%>
<br />
<form name="delete_posts" method="post" action="?action=delete_posts">
  <input type="hidden" name="uid" value="<%= UserID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="9"><strong><%= UserInfo(0, 0) %>的回帖</strong><% If UserInfo(1, 0) > 0 Then %><span style="padding-left: 20px;"><a href="?action=view_topics&uid=<%= UserID %>" class="underline">查看<%= UserInfo(0, 0) %>的发帖</a></span><% End If %></td>
    </tr>
    <tr class="category">
      <% If RQ.AllowPunishUser = 1 Then %><td width="30"><input type="checkbox" class="radio" onclick="checkall(this.form, 'pid')" /></td><% End If %>
      <td><strong>内容</strong></td>
    </tr>
    <% If IsArray(PostListArray) Then %>
    <% For i = 0 To UBound(PostListArray, 2) %>
    <tr>
      <% If RQ.AllowPunishUser = 1 Then %><td><input type="checkbox" name="pid" value="<%= PostListArray(0, i) %>" class="radio" /></td><% End If %>
      <td><a href="topicmisc.asp?action=redirectpost&pid=<%= PostListArray(0, i) %>" target="_blank" title="发表时间: <%= PostListArray(5, i) %>"><%= Left(dfc(PostListArray(4, i)), 50) %>...</a></td>
    </tr>
    <% Next %>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center">
    <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=view_posts&uid="& UserID) %>
  </div>
  <% End If %>
  <p align="center">
    <input type="button" value="返回用户资料" onclick="javascript:location.href='?action=detail&uid=<%= UserID %>';" class="button" />
    <% If RQ.AllowPunishUser = 1 Then %><input type="submit" value="删除选中的回帖" class="button" /><% End If %>
  </p>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'删除用户发表的回复
'========================================================
Sub Delete_Posts()
	'验证权限
	If RQ.AllowPunishUser = 0 Then
		Call RQ.showTips("您没有处罚用户的权限。", "", "")
	End If

	Dim UserID, UserInfo
	Dim PostID

	UserID = SafeRequest(2, "uid", 0, 0, 0)
	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"members WHERE uid = "& UserID)
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
	End If

	PostID = NumberGroupFilter(Replace(SafeRequest(2, "pid", 1, "", 0), " ", ""))
	If Len(PostID) > 0 Then
		RQ.Execute("UPDATE t SET posts = posts - p.num FROM "& TablePre &"topics AS t INNER JOIN (SELECT tid, COUNT(1) AS num FROM "& TablePre &"posts WHERE pid IN("& PostID &") AND iffirst = 0 GROUP BY tid) AS p ON t.tid = p.tid")

		RQ.Execute("DELETE FROM "& TablePre &"posts WHERE pid IN("& PostID &") AND iffirst = 0")
	End If

	Call closeDatabase()
	Call RQ.showTips("回复删除成功。", "?action=view_posts&uid="& UserID, "")
End Sub

'========================================================
'根据查询条件显示用户列表
'========================================================
Sub Members()
	Dim strSQL, sqlwhere
	Dim RecordCount, PageCount, Page
	Dim GroupID, Query_UserName, Query_UserIP, Fuzzy_Query
	Dim MemberListArray

	GroupID = SafeRequest(3, "gid", 0, 0, 0)
	Query_UserName = Replace(Replace(Replace(SafeRequest(3, "query_username", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Query_UserIP = Replace(Replace(Replace(SafeRequest(3, "query_userip", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Fuzzy_Query = SafeRequest(3, "fuzzyquery", 0, 0, 0)

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

	RecordCount = Conn.Execute("SELECT COUNT(uid) FROM "& TablePre &"members m WHERE 1 = 1"& sqlwhere)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 50)))
		Page = SafeRequest(3, "page", 0, 1, 0)
		Page = IIF(Page > PageCount, PageCount, Page)

		strSQL = "SELECT TOP 50 m.uid, m.username, m.credits, m.regtime, m.logintime, m.topics, m.posts, g.name FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE 1 = 1"& sqlwhere

		If Page > 1 Then
			strSQL = strSQL &" AND m.uid < (SELECT MIN(uid) FROM (SELECT TOP "& 50 * (Page - 1) &" uid FROM "& TablePre &"members WHERE 1 = 1"& sqlwhere &" ORDER BY uid DESC) AS tblTemp)"
		End If

		strSQL = strSQL &" ORDER BY m.uid DESC"

		MemberListArray = RQ.Query(strSQL)
	End If

	Call HeadNav()
	Call closeDatabase()
%>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
  <tr class="header">
    <td colspan="9"><strong>用户列表</strong>(点击用户名查看用户详细信息)</td>
  </tr>
  <tr class="category">
    <td><strong>用户名</strong></td>
    <td><strong>用户组</strong></td>
    <td><strong><%= RQ.Other_Settings(0) %></strong></td>
    <td><strong>发帖</strong></td>
    <td><strong>回帖</strong></td>
    <td><strong>最后登陆</strong></td>
  </tr>
  <% If IsArray(MemberListArray) Then %>
  <% For i = 0 To UBound(MemberListArray, 2) %>
  <tr>
	<td><a href="?action=detail&uid=<%= MemberListArray(0, i) %>" class="underline"><%= MemberListArray(1, i) %></a></td>
	<td><%= MemberListArray(7, i) %></td>
	<td><%= MemberListArray(2, i) %></td>
	<td><%= MemberListArray(5, i) %></td>
	<td><%= MemberListArray(6, i) %></td>
	<td><%= FormatDateTime(MemberListArray(4, i), 2) %></td>
  </tr>
  <% Next %>
  <% Else %>
  <tr>
    <td colspan="6"><em>没有找到符合条件的用户</em></td>
  </tr>
  <% End If %>
</table>
<% If PageCount > 1 Then %>
<div align="center">
  <% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=members&query_username="& Query_UserName &"&query_userip="& Query_UserIP) %>
</div>
<% End If %>
<%
	RQ.Footer()
End Sub

'========================================================
'头部信息(查询条件)
'========================================================
Sub HeadNav()
	Dim GroupID, GroupListArray
	Dim Query_UserName, Query_UserIP, Fuzzy_Query

	GroupListArray = RQ.Query("SELECT gid, name FROM "& TablePre &"usergroups WHERE gid <> 5 ORDER BY gid ASC")

	GroupID = SafeRequest(3, "gid", 0, 0, 0)
	Query_UserName = Replace(SafeRequest(3, "query_username", 1, "", 0), "%", "")
	Query_UserIP = Replace(SafeRequest(3, "query_userip", 1, "", 0), "%", "")
	Fuzzy_Query = SafeRequest(3, "fuzzyquery", 0, 0, 0)

	RQ.Header()
%>
<body class="blankbg">
<form method="get" id="list_members" action="?" onsubmit="$('btnsearch').value='正在提交,请稍后...';$('btnsearch').disabled=true;">
  <input type="hidden" name="action" value="members" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td height="25" colspan="2"><strong>列出用户</strong></td>
    </tr>
    <tr height="25">
      <td width="30%"><strong>按用户组:</strong></td>
      <td><select name="gid" onchange="$('list_members').submit();">
	    <option value="0">--</option>
	    <% If IsArray(GroupListArray) Then %>
		<% For i = 0 To UBound(GroupListArray, 2) %>
		<option value="<%= GroupListArray(0, i) %>"<%= IIF(GroupID = GroupListArray(0, i), " selected", "") %>><%= GroupListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
    </tr>
    <tr height="25">
      <td width="30%"><strong>查找用户:</strong></td>
      <td><input type="text" name="query_username" size="20" value="<%= Query_UserName %>" /></td>
    </tr>
	<tr height="25">
      <td><strong>查找IP:</strong></td>
      <td><input type="text" name="query_userip" size="20" value="<%= Query_UserIP %>" /></td>
    </tr>
	<tr height="25">
      <td><strong>查询方式:</strong></td>
      <td><input type="checkbox" name="fuzzyquery" id="fuzzyquery" value="1"<%= IIF(Fuzzy_Query = 1, " checked", "") %> /><label for="fuzzyquery">模糊查询</label></td>
    </tr>
	<tr height="25">
      <td>&nbsp;</td>
      <td><input type="submit" id="btnsearch" value="提交" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub
%>