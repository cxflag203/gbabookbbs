<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "set_group"
		Call Set_Group()
	Case "edit_usergroup"
		Call Edit_UserGroup()
	Case "update_usergroup"
		Call Update_UserGroup()
	Case "edit_admingroup"
		Call Edit_AdminGroup()
	Case "update_admingroup"
		Call Update_AdminGroup()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'保存管理组的设置
'========================================================
Sub Update_AdminGroup()
	Dim GroupID, GroupInfo
	Dim AllowManageTopic, AllowEditPoll, AllowStickTopic, AllowAuditingTopic, AllowViewIP
	Dim AllowBanIP, AllowEditUser, AllowPunishUser, DisablePostCtrl, AllowDelItemMsg, DisablePmCtrl, AllowViewLog

	GroupID = SafeRequest(2, "gid", 0, 0, 0)
	GroupInfo = RQ.Query("SELECT 1 FROM "& TablePre &"admingroups WHERE gid = "& GroupID)
	If Not IsArray(GroupInfo) Then
		Call AdminshowTips("管理组不存在或者已经被删除。", "")
	End If

	AllowManageTopic = SafeRequest(2, "allowmanagetopic", 0, 0, 0)
	AllowEditPoll = SafeRequest(2, "alloweditpoll", 0, 0, 0)
	AllowStickTopic = SafeRequest(2, "allowsticktopic", 0, 0, 0)
	AllowAuditingTopic = SafeRequest(2, "allowauditingtopic", 0, 0, 0)
	AllowViewIP = SafeRequest(2, "allowviewip", 0, 0, 0)
	AllowBanIP = SafeRequest(2, "allowbanip", 0, 0, 0)
	AllowEditUser = SafeRequest(2, "allowedituser", 0, 0, 0)
	AllowPunishUser = SafeRequest(2, "allowpunishuser", 0, 0, 0)
	DisablePostCtrl = SafeRequest(2, "disablepostctrl", 0, 0, 0)
	AllowDelItemMsg = SafeRequest(2, "allowdelitemmsg", 0, 0, 0)
	DisablePmCtrl = SafeRequest(2, "disablepmctrl", 0, 0, 0)
	AllowViewLog = SafeRequest(2, "allowviewlog", 0, 0, 0)

	RQ.Execute("UPDATE "& TablePre &"admingroups SET allowmanagetopic = "& AllowManageTopic &", alloweditpoll = "& AllowEditPoll &", allowsticktopic = "& AllowStickTopic &", allowauditingtopic = "& AllowAuditingTopic &", allowviewip = "& AllowViewIP &", allowbanip = "& AllowBanIP &", allowedituser = "& AllowEditUser &", allowpunishuser = "& AllowPunishUser &", disablepostctrl = "& DisablePostCtrl &", allowdelitemmsg = "& AllowDelItemMsg &", disablepmctrl = "& DisablePmCtrl &", allowviewlog = "& AllowViewLog &" WHERE gid = "& GroupID)

	Call RQ.Reload_AdminGroup_Settings(GroupID)

	Call closeDatabase()
	Call AdminshowTips("管理组更新成功。", "?")
End Sub

'========================================================
'编辑管理组的设置
'========================================================
Sub Edit_AdminGroup()
	Dim GroupID, GroupInfo, GroupName
	Dim AllowManageTopic, AllowEditPoll, AllowStickTopic, AllowAuditingTopic, AllowViewIP
	Dim AllowBanIP, AllowEditUser, AllowPunishUser, DisablePostCtrl, AllowDelItemMsg, DisablePmCtrl, AllowViewLog

	GroupID = SafeRequest(3, "gid", 0, 0, 0)
	GroupInfo = RQ.Query("SELECT g.name, a.* FROM "& TablePre &"admingroups a INNER JOIN "& TablePre &"usergroups g ON a.gid = g.gid WHERE a.gid = "& GroupID)

	If Not IsArray(GroupInfo) Then
		Call AdminshowTips("管理组不存在或者已经被删除。", "")
	End If

	GroupName = GroupInfo(0, 0)
	AllowManageTopic = GroupInfo(2, 0)
	AllowEditPoll = GroupInfo(3, 0)
	AllowStickTopic = GroupInfo(4, 0)
	AllowAuditingTopic = GroupInfo(5, 0)
	AllowViewIP = GroupInfo(6, 0)
	AllowBanIP = GroupInfo(7, 0)
	AllowEditUser = GroupInfo(8, 0)
	AllowPunishUser = GroupInfo(9, 0)
	DisablePostCtrl = GroupInfo(10, 0)
	AllowDelItemMsg = GroupInfo(11, 0)
	DisablePmCtrl = GroupInfo(12, 0)
	AllowViewLog = GroupInfo(13, 0)
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<a href="?">用户组</a>&nbsp;&raquo;&nbsp;编辑管理组</td>
  </tr>
</table>
<br />
<form method="post" name="form1" action="?action=update_admingroup" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="gid" value="<%= GroupID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>管理组权限 - <%= GroupName %></strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否允许管理帖子/回复:</strong></td>
      <td width="70%"><input type="checkbox" name="allowmanagetopic" id="allowmanagetopic" class="radio" value="1"<% If AllowManageTopic = 1 Then Response.Write " checked" End If %> /><label for="allowmanagetopic">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许编辑投票:</strong></td>
      <td width="70%"><input type="checkbox" name="alloweditpoll" id="alloweditpoll" class="radio" value="1"<% If AllowEditPoll = 1 Then Response.Write " checked" End If %> /><label for="alloweditpoll">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许置顶帖子:</strong></td>
      <td width="70%"><input type="checkbox" name="allowsticktopic" id="allowsticktopic" class="radio" value="1"<% If AllowStickTopic = 1 Then Response.Write " checked" End If %> /><label for="allowsticktopic">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许审核帖子:</strong></td>
      <td width="70%"><input type="checkbox" name="allowauditingtopic" id="allowauditingtopic" class="radio" value="1"<% If AllowAuditingTopic = 1 Then Response.Write " checked" End If %> /><label for="allowauditingtopic">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许查看用户IP:</strong></td>
      <td width="70%"><input type="checkbox" name="allowviewip" id="allowviewip" class="radio" value="1"<% If AllowViewIP = 1 Then Response.Write " checked" End If %> /><label for="allowviewip">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许禁止用户IP:</strong></td>
      <td width="70%"><input type="checkbox" name="allowbanip" id="allowbanip" class="radio" value="1"<% If AllowBanIP = 1 Then Response.Write " checked" End If %> /><label for="allowbanip">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许编辑用户:</strong></td>
      <td width="70%"><input type="checkbox" name="allowedituser" id="allowedituser" class="radio" value="1"<% If AllowEditUser = 1 Then Response.Write " checked" End If %> /><label for="allowedituser">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许处罚用户:</strong></td>
      <td width="70%"><input type="checkbox" name="allowpunishuser" id="allowpunishuser" class="radio" value="1"<% If AllowPunishUser = 1 Then Response.Write " checked" End If %> /><label for="allowpunishuser">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>发帖/回帖是否不受限制:</strong><br />一旦选中该项，那么任何发帖、回帖的限制(如审核、字数、防灌水等)都将无效</td>
      <td width="70%"><input type="checkbox" name="disablepostctrl" id="disablepostctrl" class="radio" value="1"<% If DisablePostCtrl = 1 Then Response.Write " checked" End If %> /><label for="disablepostctrl">是的</label></td>
    </tr>
	<tr height="25">
      <td class="altbg1"><strong>是否允许管理道具产生的信息:</strong><br />例如点歌栏</td>
      <td width="70%"><input type="checkbox" name="allowdelitemmsg" id="allowdelitemmsg" class="radio" value="1"<% If AllowDelItemMsg = 1 Then Response.Write " checked" End If %> /><label for="allowdelitemmsg">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发送传呼不收限制:</strong></td>
      <td width="70%"><input type="checkbox" name="disablepmctrl" id="disablepmctrl" class="radio" value="1"<% If DisablePmCtrl = 1 Then Response.Write " checked" End If %> /><label for="disablepmctrl">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否允许查看日志:</strong></td>
      <td width="70%"><input type="checkbox" name="allowviewlog" id="allowviewlog" class="radio" value="1"<% If AllowViewLog = 1 Then Response.Write " checked" End If %> /><label for="allowviewlog">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1">&nbsp;</td>
      <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'保存用户组的设置
'========================================================
Sub Update_UserGroup()
	Dim GroupID, Name, GroupInfo
	Dim AllowVisit, DisablePeriodCtrl, AllowPost, AllowDirectPost, AllowReply, AnonymitySuc, AllowPostPoll
	Dim AllowPoll, AllowSearch, AllowGetAttach, AllowPostAttach, MaxAttachSize, AttachExtensions
	Dim AllowViewUserInfo, AllowUseItem, AllowHTML, AllowChat, SpecialInterface
	Dim AllowInvate, InvatePrice, InvateMaxNum, InvateExpiryDay

	Name = SafeRequest(2, "name", 1, "", 0)
	GroupID = SafeRequest(2, "gid", 0, 0, 0)
	
	If Len(Name) = 0 Then
		Call AdminshowTips("请填写好用户组名称。", "")
	End If

	GroupInfo = RQ.Query("SELECT 1 FROM "& TablePre &"usergroups WHERE gid = "& GroupID)
	If Not IsArray(GroupInfo) Then
		Call AdminshowTips("用户组不存在或者已经被删除。", "")
	End If
	
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
	SpecialInterface = Replace(Request.Form("specialinterface"), "'", "")
	AllowInvate = SafeRequest(2, "allowinvate", 0, 0, 0)
	InvatePrice = SafeRequest(2, "invateprice", 0, 1, 0)
	InvateMaxNum = SafeRequest(2, "invatemaxnum", 0, 1, 0)
	InvateExpiryDay = SafeRequest(2, "invateexpiryday", 0, 1, 0)

	AnonymitySuc = IIF(AnonymitySuc > 100, 0, AnonymitySuc)
	MaxAttachSize = IIF(MaxAttachSize > 100000, 100000, MaxAttachSize)
	AttachExtensions = LCase(Replace(AttachExtensions, ".", ""))

	RQ.Execute("UPDATE "& TablePre &"usergroups SET allowvisit = "& AllowVisit &", disableperiodctrl = "& DisablePeriodCtrl &", allowpost = "& AllowPost &", allowdirectpost = "& AllowDirectPost &", allowreply = "& AllowReply &", anonymitysuc = "& AnonymitySuc &", allowpostpoll = "& AllowPostPoll &", allowpoll = "& AllowPoll &", allowsearch = "& AllowSearch &", allowgetattach = "& AllowGetAttach &", allowpostattach = "& AllowPostAttach &", maxattachsize = "& MaxAttachSize &", attachextensions = '"& AttachExtensions &"', allowviewuserinfo = "& AllowViewUserInfo &", allowuseitem = "& AllowUseItem &", allowhtml = "& AllowHTML &", allowchat = "& AllowChat &", specialinterface = N'"& SpecialInterface &"', allowinvate = "& AllowInvate &", invateprice = "& InvatePrice &", invatemaxnum = "& InvateMaxNum &", invateexpiryday = "& InvateExpiryDay &" WHERE gid = "& GroupID)

	Call RQ.Reload_UserGroup_Settings(GroupID)

	Call closeDatabase()
	Call AdminshowTips("用户组设置更新成功。", "?")
End Sub

'========================================================
'编辑用户组的设置
'========================================================
Sub Edit_UserGroup()
	Dim GroupID, GroupInfo
	Dim AllowVisit, DisablePeriodCtrl, AllowPost, AllowDirectPost, AllowReply, AnonymitySuc, AllowPostPoll
	Dim AllowPoll, AllowSearch, AllowGetAttach, AllowPostAttach, MaxAttachSize, AttachExtensions
	Dim AllowViewUserInfo, AllowUseItem, AllowHTML, AllowChat, SpecialInterface
	Dim AllowInvate, InvatePrice, InvateMaxNum, InvateExpiryDay

	GroupID = SafeRequest(3, "gid", 0, 0, 0)
	GroupInfo = RQ.Query("SELECT * FROM "& TablePre &"usergroups WHERE gid = "& GroupID)
	If Not IsArray(GroupInfo) Then
		Call AdminshowTips("用户组不存在或者已经被删除。", "")
	End If

	AllowVisit = GroupInfo(4, 0)
	DisablePeriodCtrl = GroupInfo(5, 0)
	AllowPost = GroupInfo(6, 0)
	AllowDirectPost = GroupInfo(7, 0)
	AllowReply = GroupInfo(8, 0)
	AnonymitySuc = GroupInfo(9, 0)
	AllowPostPoll = GroupInfo(10, 0)
	AllowPoll = GroupInfo(11, 0)
	AllowSearch = GroupInfo(12, 0)
	AllowGetAttach = GroupInfo(13, 0)
	AllowPostAttach = GroupInfo(14, 0)
	MaxAttachSize = GroupInfo(15, 0)
	AttachExtensions = GroupInfo(16, 0)
	AllowViewUserInfo = GroupInfo(17, 0)
	AllowUseItem = GroupInfo(18, 0)
	AllowHTML = GroupInfo(19, 0)
	AllowChat = GroupInfo(20, 0)
	SpecialInterface = GroupInfo(21, 0)
	AllowInvate = GroupInfo(22, 0)
	InvatePrice = GroupInfo(23, 0)
	InvateMaxNum = GroupInfo(24, 0)
	InvateExpiryDay = GroupInfo(25, 0)

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<a href="?">用户组</a>&nbsp;&raquo;&nbsp;编辑用户组</td>
  </tr>
</table>
<br />
<form method="post" name="form1" action="?action=update_usergroup" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="gid" value="<%= GroupID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>基本设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>用户组名称:</strong></td>
      <td width="70%"><input type="text" name="name" size="25" value="<%= GroupInfo(1, 0) %>" /></td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
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
	<tr height="25" id="p_maxattachsize">
      <td class="altbg1"><strong>最大附件尺寸:</strong><br />上传单个附件的最大尺寸，设置为0则限制在100MB以内。</td>
      <td width="70%"><input type="text" name="maxattachsize" size="10" value="<%= MaxAttachSize %>" /> KB</td>
    </tr>
	<tr height="25" id="p_attachextensions">
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
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
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
	<tr height="25">
      <td class="altbg1">&nbsp;</td>
      <td width="70%"><input type="submit" id="btnsubmit" class="button" value="提交设置" /></td>
    </tr>
  </table>
  <script type="text/javascript">
    function showattach(){
		$('p_attachextensions').style.display = $('p_maxattachsize').style.display = $('allowpostattach').checked ? '' : 'none';
	}
    function showinvate(){
		$('p_invateprice').style.display = $('p_invatemaxnum').style.display = $('p_invateexpiryday').style.display = $('allowinvate').checked ? '' : 'none';
	}
	showattach();
	showinvate();
  </script>
</form>
<%
End Sub

'========================================================
'用户组列表的提交处理(添加/删除)
'========================================================
Sub Set_Group()
	Dim d_GroupID, GroupListArray
	Dim GroupID, Name
	Dim New_Name, Types

	Types = SafeRequest(2, "types", 1, "", 0)
	If Not InArray(Array("moderator", "member", "restricted"), Types) Then
		Call AdminShowTips("未定义操作。", "")
	End If

	'删除用户组
	d_GroupID = NumberGroupFilter(Replace(SafeRequest(2, "d_gid", 1, "", 0), " ", ""))
	If Len(d_GroupID) > 0 Then
		GroupListArray = RQ.Query("SELECT gid, types FROM "& TablePre &"usergroups WHERE gid IN("& d_GroupID &") AND initialize = 0")
		If IsArray(GroupListArray) Then
			For i = 0 To UBound(GroupListArray, 2)
				RQ.Execute("DELETE FROM "& TablePre &"usergroups WHERE gid = "& GroupListArray(0, i))
				RQ.Execute("UPDATE "& TablePre &"members SET admingroupid = 0, usergroupid = 4 WHERE usergroupid = "& GroupListArray(0, i))
				If GroupListArray(1, i) = "moderator" Then
					RQ.Execute("DELETE FROM "& TablePre &"admingroups WHERE gid = "& GroupListArray(0, i))
				End If
				Application.Lock
				Application.Contents.Remove(CacheName &"_usergroup_"& GroupListArray(0, i))
				Application.UnLock
			Next
		End If
	End If

	'更新用户组名称
	If Request.Form("gid").Count > 0 Then
		For i = 1 To Request.Form("gid").Count
			GroupID = IntCode(Request.Form("gid")(i))
			Name = Trim(strFilter(Request.Form("name")(i)))
			If GroupID > 0 And Len(Name) > 0 Then
				RQ.Execute("UPDATE "& TablePre &"usergroups SET name = N'"& Name &"' WHERE gid = "& GroupID)
			End If
		Next
	End If

	'新增用户组
	New_Name = Trim(SafeRequest(2, "new_name", 1, "", 0))
	If Len(New_Name) > 0 And Len(Types) > 0 Then
		RQ.Execute("INSERT INTO "& TablePre &"usergroups (name, types) VALUES (N'"& New_Name &"', '"& Types &"')")
		If Types = "moderator" Then
			GroupID = Conn.Execute("SELECT SCOPE_IDENTITY()")(0)
			RQ.Execute("INSERT INTO "& TablePre &"admingroups (gid) VALUES ("& GroupID &")")
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("用户组更新成功。", "?")
End Sub

Sub Main()
	Dim GroupListArray
	GroupListArray = RQ.Query("SELECT gid, name, types, initialize FROM "& TablePre &"usergroups")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;用户组</td>
  </tr>
</table>
<br />
<form name="form1" method="post" action="?action=set_group" onsubmit="$('btnadmingroup').value='正在提交,请稍后...';$('btnadmingroup').disabled=true;">
  <input type="hidden" name="types" value="moderator" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="3">管理组</td>
    </tr>
    <tr class="category">
      <td width="8%">删?</td>
      <td width="25%">用户组</td>
      <td>操作</td>
    </tr>
    <% If IsArray(GroupListArray) Then %>
    <% For i = 0 To UBound(GroupListArray, 2) %>
	<% If GroupListArray(2, i) = "moderator" Then %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_gid" class="radio" value="<%= GroupListArray(0, i) %>"<% If GroupListArray(3, i) = 1 Then Response.Write "disabled" End If %> />
	    <input type="hidden" name="gid" value="<%= GroupListArray(0, i) %>" /></td>
      <td class="altbg2"><input type="text" name="name" size="25" value="<%= GroupListArray(1, i) %>" /></td>
      <td class="altbg1"><a href="?action=edit_usergroup&gid=<%= GroupListArray(0, i) %>">[用户组设置]</a>
	    <a href="?action=edit_admingroup&gid=<%= GroupListArray(0, i) %>">[管理组设置]</a></td>
    </tr>
	<% End If %>
    <% Next %>
    <% End If %>
	<tr>
	  <td class="altbg1">添加:</td>
	  <td class="altbg2"><input type="text" name="new_name" size="25" /></td>
	  <td class="altbg1">&nbsp;</td>
	</tr>
  </table>
  <p align="center"><input type="submit" id="btnadmingroup" value="提交设置" class="button" /></p>
</form>
<form name="form2" method="post" action="?action=set_group" onsubmit="$('btnmembergroup').value='正在提交,请稍后...';$('btnmembergroup').disabled=true;">
  <input type="hidden" name="types" value="member" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="3">会员组</td>
    </tr>
    <tr class="category">
      <td width="8%">删?</td>
      <td width="25%">用户组</td>
      <td>操作</td>
    </tr>
    <% If IsArray(GroupListArray) Then %>
    <% For i = 0 To UBound(GroupListArray, 2) %>
	<% If GroupListArray(2, i) = "member" Then %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_gid" class="radio" value="<%= GroupListArray(0, i) %>"<% If GroupListArray(3, i) = 1 Then Response.Write "disabled" End If %> />
	    <input type="hidden" name="gid" value="<%= GroupListArray(0, i) %>" /></td>
      <td class="altbg2"><input type="text" name="name" size="25" value="<%= GroupListArray(1, i) %>" /></td>
      <td class="altbg1"><a href="?action=edit_usergroup&gid=<%= GroupListArray(0, i) %>">[用户组设置]</td>
    </tr>
	<% End If %>
    <% Next %>
    <% End If %>
	<tr>
	  <td class="altbg1">添加:</td>
	  <td class="altbg2"><input type="text" name="new_name" size="25" /></td>
	  <td class="altbg1">&nbsp;</td>
	</tr>
  </table>
  <p align="center"><input type="submit" id="btnmembergroup" value="提交设置" class="button" /></p>
</form>
<form name="form3" method="post" action="?action=set_group" onsubmit="$('btnrestrictedgroup').value='正在提交,请稍后...';$('btnrestrictedgroup').disabled=true;">
  <input type="hidden" name="types" value="restricted" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="3">受限组</td>
    </tr>
    <tr class="category">
      <td width="8%">删?</td>
      <td width="25%">用户组</td>
      <td>操作</td>
    </tr>
    <% If IsArray(GroupListArray) Then %>
    <% For i = 0 To UBound(GroupListArray, 2) %>
	<% If GroupListArray(2, i) = "restricted" Then %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_gid" class="radio" value="<%= GroupListArray(0, i) %>"<% If GroupListArray(3, i) = 1 Then Response.Write "disabled" End If %> />
	    <input type="hidden" name="gid" value="<%= GroupListArray(0, i) %>" /></td>
      <td class="altbg2"><input type="text" name="name" size="25" value="<%= GroupListArray(1, i) %>" /></td>
      <td class="altbg1"><a href="?action=edit_usergroup&gid=<%= GroupListArray(0, i) %>">[用户组设置]</td>
    </tr>
	<% End If %>
    <% Next %>
    <% End If %>
	<tr>
	  <td class="altbg1">添加:</td>
	  <td class="altbg2"><input type="text" name="new_name" size="25" /></td>
	  <td class="altbg1">&nbsp;</td>
	</tr>
  </table>
  <p align="center"><input type="submit" id="btnrestrictedgroup" value="提交设置" class="button" /></p>
</form>
<%
End Sub
%>