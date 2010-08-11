<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action, ForumID
Action = Request.QueryString("action")
ForumID = SafeRequest(1, "forumid", 0, 0, 0)

Select Case Action
	Case "updatecache"
		Call UpdateCache()
	Case "add_forum", "edit_forum"
		Call Add_Forum()
	Case "save_forum", "update_forum"
		Call Save_Forum()
	Case "moderators"
		Call Moderators()
	Case "update_moderators"
		Call Update_Moderators()
	Case "topictypes"
		Call TopicTypes()
	Case "update_topictypes"
		Call Update_TopicTypes()
	Case "merge"
		Call Merge()
	Case "update_merge"
		Call Update_Merge()
	Case "delete"
		Call Delete()
	Case "deleteconfirm"
		Call DeleteConfirm()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'更新版面帖子统计
'========================================================
Sub UpdateCache()
	Dim DisplayOrder
	Dim ForumListArray, Topics, Posts

	'更新版面排序
	If Request.Form("forumid").Count > 0 Then
		For i = 1 To Request.Form("forumid").Count
			ForumID = IntCode(Request.Form("forumid")(i))
			DisplayOrder = IntCode(Request.Form("displayorder")(i))

			If ForumID > 0 Then
				RQ.Execute("UPDATE "& TablePre &"forums SET displayorder = "& DisplayOrder &" WHERE fid = "& ForumID)
			End If
		Next
	End If

	'更新帖子统计
	ForumListArray = RQ.Query("SELECT fid FROM "& TablePre &"forums")
	If IsArray(ForumListArray) Then
		For i = 0 To UBound(ForumListArray, 2)
			'更新帖子统计
			Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& ForumListArray(0, i) &" AND displayorder >= 0")(0)
			Posts = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE fid = "& ForumListArray(0, i) &") AND iffirst = 0")(0)
			RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &", posts = "& Posts &" WHERE fid = "& ForumListArray(0, i))

			Call RQ.Reload_Forum_Settings(ForumListArray(0, i))
		Next
	End If

	Call closeDatabase()
	Call AdminshowTips("版面帖子统计更新完毕。", "?")
End Sub

'========================================================
'新增/更新版面设置
'========================================================
Sub Save_Forum()
	Dim Forum_Name, F_AllowPost, F_AdultingPost, F_ShowTopicType, F_ChooseTopicType, F_AllowPollTopic, F_AutoClose
	Dim F_AutoClose_Day, F_RecycleBin, F_VisitNdCredits, F_PostNdCredits, F_ReplyNdCredits, F_AnonymityNdCredits, F_HtmlNdCredits
	Dim Forum_ViewPerm, Forum_PostTopicPerm, Forum_PostReplyPerm, Forum_PostAttachPerm, Forum_GetAttachPerm
	Dim TopicTypeInfo, ForumInfo, DisplayOrder

	Forum_Name = SafeRequest(2, "forum_name", 1, "", 0)
	If Len(Forum_Name) = 0 Then
		Call AdminshowTips("请填写好版面名称。", "")
	End If

	F_AllowPost = SafeRequest(2, "f_allowpost", 0, 0, 0)
	F_AdultingPost = SafeRequest(2, "f_adultingpost", 0, 0, 0)
	F_ShowTopicType = SafeRequest(2, "f_showtopictype", 0, 0, 0)
	F_ChooseTopicType = SafeRequest(2, "f_choosetopictype", 0, 0, 0)
	F_AllowPollTopic = SafeRequest(2, "f_allowpolltopic", 0, 0, 0)
	F_AutoClose = SafeRequest(2, "f_autoclose", 0, 0, 0)
	F_AutoClose_Day = SafeRequest(2, "f_autoclose_day", 0, 0, 0)

	If F_AutoClose > 0 And F_AutoClose_Day > 0 Then
		Select Case F_AutoClose
			Case 1
				F_AutoClose = -F_AutoClose_Day
			Case 2
				F_AutoClose = F_AutoClose_Day
		End Select
	Else
		F_AutoClose = 0
	End If
			
	F_RecycleBin = SafeRequest(2, "f_recyclebin", 0, 0, 0)
	F_VisitNdCredits = SafeRequest(2, "f_visitndcredits", 0, 0, 0)
	F_PostNdCredits = SafeRequest(2, "f_postndcredits", 0, 0, 0)
	F_ReplyNdCredits = SafeRequest(2, "f_replyndcredits", 0, 0, 0)
	F_AnonymityNdCredits = SafeRequest(2, "f_anonymityndcredits", 0, 0, 0)
	F_HtmlNdCredits = SafeRequest(2, "f_htmlndcredits", 0, 0, 0)

	Forum_ViewPerm = Replace(SafeRequest(2, "viewperm", 1, "", 0), " ", "")
	Forum_PostTopicPerm = Replace(SafeRequest(2, "posttopicperm", 1, "", 0), " ", "")
	Forum_PostReplyPerm = Replace(SafeRequest(2, "postreplyperm", 1, "", 0), " ", "")
	Forum_PostAttachPerm = Replace(SafeRequest(2, "postattachperm", 1, "", 0), " ", "")
	Forum_GetAttachPerm = Replace(SafeRequest(2, "getattachperm", 1, "", 0), " ", "")

	'验证版面是否存在帖子分类
	TopicTypeInfo = RQ.Query("SELECT TOP 1 1 FROM "& TablePre &"topictypes WHERE fid = "& ForumID)
	If Not IsArray(TopicTypeInfo) Then
		F_ShowTopicType = 0
		F_ChooseTopicType = 0
	End If

	If Action = "save_forum" Then
		DisplayOrder = Conn.Execute("SELECT IIF(MAX(displayorder) IS NULL, 0, MAX(displayorder)) + 1 FROM "& TablePre &"forums WHERE parentid = 0")(0)
		'保存版面
		RQ.Execute("INSERT INTO "& TablePre &"forums (name, displayorder, allowpost, adultingpost, showtopictype, choosetopictype, allowpolltopic, autoclose, recyclebin, visitndcredits, postndcredits, replyndcredits, anonyndmitycredits, htmlndcredits) VALUES ('"& Forum_Name &"', "& DisplayOrder &", "& F_AllowPost &", "& F_AdultingPost &", "& F_ShowTopicType &", "& F_ChooseTopicType &", "& F_AllowPollTopic &", "& F_AutoClose &", "& F_RecycleBin &", "& F_VisitNdCredits &", "& F_PostNdCredits &", "& F_ReplyNdCredits &", "& F_AnonymityNdCredits &", "& F_HtmlNdCredits &")")

		'获得版面编号
		ForumID = Conn.Execute("SELECT MAX(fid) FROM "& TablePre &"forums")(0)

		'保存版面附表
		RQ.Execute("INSERT INTO "& TablePre &"forumfields (fid, viewperm, posttopicperm, postreplyperm, postattachperm, getattachperm) VALUES ("& ForumID &", '"& Forum_ViewPerm &"', '"& Forum_PostTopicPerm &"', '"& Forum_PostReplyPerm &"', '"& Forum_PostAttachPerm &"', '"& Forum_GetAttachPerm &"')")

		'更新全局置顶帖
		RQ.Execute("INSERT INTO "& TablePre &"sticktopics (tid, fid) SELECT tid, "& ForumID &" FROM "& TablePre &"topics WHERE displayorder = 3")
	Else
		ForumInfo = RQ.Query("SELECT 1 FROM "& TablePre &"forums WHERE fid = "& ForumID)
		If Not IsArray(ForumInfo) Then
			Call AdminShowTips("版面不存在或者已经被删除。", "")
		End If

		RQ.Execute("UPDATE "& TablePre &"forums SET name = '"& Forum_Name &"', allowpost = "& F_AllowPost &", adultingpost = "& F_AdultingPost &", showtopictype = "& F_ShowTopicType &", choosetopictype = "& F_ChooseTopicType &", allowpolltopic = "& F_AllowPollTopic &", autoclose = "& F_AutoClose &", recyclebin = "& F_RecycleBin &", visitndcredits = "& F_VisitNdCredits &", postndcredits = "& F_PostNdCredits &", replyndcredits = "& F_ReplyNdCredits &", anonyndmitycredits = "& F_AnonymityNdCredits &", htmlndcredits = "& F_HtmlNdCredits &" WHERE fid = "& ForumID)

		RQ.Execute("UPDATE "& TablePre &"forumfields SET viewperm = '"& Forum_ViewPerm &"', posttopicperm = '"& Forum_PostTopicPerm &"', postreplyperm = '"& Forum_PostReplyPerm &"', postattachperm = '"& Forum_PostAttachPerm &"', getattachperm = '"& Forum_GetAttachPerm &"' WHERE fid = "& ForumID)
	End If
	
	Call RQ.Reload_Forum_Settings(ForumID)

	Call closeDatabase()
	Call AdminshowTips("版面设置成功。", "?")
End Sub

'========================================================
'添加/编辑版面界面
'========================================================
Sub Add_Forum()
	Dim ForumInfo, Forum_Name
	Dim F_AllowPost, F_AdultingPost, F_ShowTopicType, F_ChooseTopicType, F_AllowPollTopic, F_AutoClose
	Dim F_RecycleBin, F_VisitNdCredits, F_PostNdCredits, F_ReplyNdCredits, F_AnonymityNdCredits, F_HtmlNdCredits
	Dim Forum_ViewPerm, Forum_PostTopicPerm, Forum_PostReplyPerm, Forum_PostAttachPerm, Forum_GetAttachPerm
	Dim GroupListArray
	Dim strMenu, strAction

	If Action = "edit_forum" Then
		ForumInfo = RQ.Query("SELECT f.*, ff.* FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid WHERE f.fid = "& ForumID)
		If Not IsArray(ForumInfo) Then
			Call AdminShowTips("版面不存在或者已经被删除。", "")
		End If

		Forum_Name = ForumInfo(1, 0)
		F_AllowPost = ForumInfo(9, 0)
		F_AdultingPost = ForumInfo(10, 0)
		F_ShowTopicType = ForumInfo(11, 0)
		F_ChooseTopicType = ForumInfo(12, 0)
		F_AllowPollTopic = ForumInfo(13, 0)
		F_AutoClose = ForumInfo(14, 0)
		F_RecycleBin = ForumInfo(15, 0)
		F_VisitNdCredits = ForumInfo(16, 0)
		F_PostNdCredits = ForumInfo(17, 0)
		F_ReplyNdCredits = ForumInfo(18, 0)
		F_AnonymityNdCredits = ForumInfo(19, 0)
		F_HtmlNdCredits = ForumInfo(20, 0)
		Forum_ViewPerm = ForumInfo(23, 0)
		Forum_PostTopicPerm = ForumInfo(24, 0)
		Forum_PostReplyPerm = ForumInfo(25, 0)
		Forum_PostAttachPerm = ForumInfo(26, 0)
		Forum_GetAttachPerm = ForumInfo(27, 0)
		strMenu = "编辑版面"
		strAction = "update_forum"
	Else
		F_AllowPost = 1
		strMenu = "添加版面"
		strAction = "save_forum"
	End If

	GroupListArray = RQ.Query("SELECT gid, name FROM "& TablePre &"usergroups ORDER BY gid ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<a href="?">版面设置</a>&nbsp;&raquo;&nbsp;<%= strMenu %></td>
  </tr>
</table>
<br />
<form method="post" name="form1" action="?action=<%= strAction %>" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="forumid" value="<%= ForumID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>版面名称</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>版面名称:</strong></td>
      <td width="70%"><input type="text" name="forum_name" size="20" value="<%= Forum_Name %>" /></td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>版面基本设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>版面允许发言:</strong><br />版主或者管理员不受此限制</td>
      <td width="70%"><input type="checkbox" name="f_allowpost" id="f_allowpost" class="radio" value="1"<% If F_AllowPost = 1 Then Response.Write " checked" End If %> /><label for="f_allowpost">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>审核新帖子:</strong><br />版主或者管理员不受此限制</td>
      <td width="70%"><input type="checkbox" name="f_adultingpost" id="f_adultingpost" class="radio" value="1"<% If F_AdultingPost = 1 Then Response.Write " checked" End If %> /><label for="f_adultingpost">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>在帖子列表显示帖子分类:</strong><br />如果本版启用了帖子分类，是否在帖子列表显示帖子分类名称</td>
      <td width="70%"><input type="checkbox" name="f_showtopictype" id="f_showtopictype" class="radio" value="1"<% If F_ShowTopicType = 1 Then Response.Write " checked" End If %> /><label for="f_showtopictype">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发帖必须选择帖子分类:</strong><br />如果本版启用了帖子分类，发帖时是否必须选择帖子分类</td>
      <td width="70%"><input type="checkbox" name="f_choosetopictype" id="f_choosetopictype" class="radio" value="1"<% If F_ChooseTopicType = 1 Then Response.Write " checked" End If %> /><label for="f_choosetopictype">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>允许发表投票帖子:</strong></td>
      <td width="70%"><input type="checkbox" name="f_allowpolltopic" id="f_allowpolltopic" class="radio" value="1"<% If F_AllowPollTopic = 1 Then Response.Write " checked" End If %> /><label for="f_allowpolltopic">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>帖子自动关闭:</strong></td>
      <td width="70%">
	    <input type="radio" name="f_autoclose" id="f_autoclose_0" class="radio" value="0"<% If F_AutoClose = 0 Then Response.Write " checked" End If %> onclick="javascript: $('autoclose_days').style.display = 'none';" /><label for="f_autoclose_0">不自动关闭</label>
		<br />
        <input type="radio" name="f_autoclose" id="f_autoclose_1" class="radio" value="1"<% If F_AutoClose < 0 Then Response.Write " checked" End If %> onclick="javascript: $('autoclose_days').style.display = ''; $('mk_autoclose').innerHTML = '发帖时间';" /><label for="f_autoclose_1">按照发帖时间自动关闭</label>
		<br />
        <input type="radio" name="f_autoclose" id="f_autoclose_2" class="radio" value="2"<% If F_AutoClose > 0 Then Response.Write " checked" End If %> onclick="javascript: $('autoclose_days').style.display = ''; $('mk_autoclose').innerHTML = '最后回复时间';" /><label for="f_autoclose_2">按照最后回复时间自动关闭</label>
	  </td>
    </tr>
    <tr height="25" id="autoclose_days">
      <td class="altbg1"><strong>帖子自动关闭的时间(天):</strong></td>
      <td width="70%">距离<span id="mk_autoclose"></span> <input type="text" name="f_autoclose_day" size="5" value="<%= ABS(F_AutoClose) %>" /> 天后的帖子自动关闭回复
	    <script type="text/javascript">$('autoclose_days').style.display = $('f_autoclose_0').checked ? 'none' : ''; $('mk_autoclose').innerHTML = $('f_autoclose_1').checked ? '发帖时间' : '最后回复时间';</script></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>删帖设置:</strong></td>
      <td width="70%">
        <input type="radio" name="f_recyclebin" id="f_recyclebin_0" class="radio" value="0"<% If F_RecycleBin = 0 Then Response.Write " checked" End If %> /><label for="f_recyclebin_0">直接删除</label>
		<br />
        <input type="radio" name="f_recyclebin" id="f_recyclebin_1" class="radio" value="1"<% If F_RecycleBin = 1 Then Response.Write " checked" End If %> /><label for="f_recyclebin_1">放入回收站</label>
	  </td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>特殊权限设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>浏览限制:</strong><br />不填或者设为0则为不限制</td>
      <td width="70%"><%= RQ.Other_Settings(0) %>达到 <input type="text" name="f_visitndcredits" size="5" value="<%= F_VisitNdCredits %>" /> 才能进入该版</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发帖限制:</strong><br />不填或者设为0则为不限制</td>
      <td width="70%"><%= RQ.Other_Settings(0) %>达到 <input type="text" name="f_postndcredits" size="5" value="<%= F_PostNdCredits %>" /> 才能发帖</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>回帖限制:</strong><br />不填或者设为0则为不限制</td>
      <td width="70%"><%= RQ.Other_Settings(0) %>达到 <input type="text" name="f_replyndcredits" size="5" value="<%= F_ReplyNdCredits %>" /> 才能回帖</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>匿名限制:</strong><br />不填或者设为0则为不限制</td>
      <td width="70%"><%= RQ.Other_Settings(0) %>达到 <input type="text" name="f_anonymityndcredits" size="5" value="<%= F_AnonymityNdCredits %>" /> 才能匿名</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>使用HTML限制:</strong><br />不填或者设为0则为不限制</td>
      <td width="70%"><%= RQ.Other_Settings(0) %>达到 <input type="text" name="f_htmlndcredits" size="5" value="<%= F_HtmlNdCredits %>" /> 才能使用HTML</td>
    </tr>
  </table>
  <br />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>关于“版面权限设置”</td>
    </tr>
    <tr class="altbg2">
      <td>某权限如果全部未选中，那么默认权限为：该版面允许所有用户组访问；允许除了游客之外的用户组发帖、回帖；允许所有用户组下载附件；允许除游客外的用户组上传附件。</td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td width="16%">版面权限设置</td>
      <td width="16%"><input type="checkbox" id="check_viewperm" class="radio" onclick="col_checked('viewperm')" />浏览版面</td>
      <td width="16%"><input type="checkbox" id="check_posttopicperm" class="radio" onclick="col_checked('posttopicperm')" />发表帖子</td>
      <td width="16%"><input type="checkbox" id="check_postreplyperm" class="radio" onclick="col_checked('postreplyperm')" />回复帖子</td>
      <td width="16%"><input type="checkbox" id="check_postattachperm" class="radio" onclick="col_checked('postattachperm')" />上传附件</td>
      <td width="16%"><input type="checkbox" id="check_getattachperm" class="radio" onclick="col_checked('getattachperm')" />下载附件</td>
    </tr>
	<% If IsArray(GroupListArray) Then %>
	<% For i = 0 To UBound(GroupListArray, 2) %>
	<tr>
      <td class="altbg1"><input type="checkbox" id="groupctrl_<%= GroupListArray(0, i) %>" onclick="row_checked(<%= GroupListArray(0, i) %>)" class="radio" /><%= GroupListArray(1, i) %></td>
      <td class="altbg2"><input type="checkbox" name="viewperm" id="viewperm_<%= GroupListArray(0, i) %>" class="radio" value="<%= GroupListArray(0, i) %>"<% If InStr(","& Forum_ViewPerm &",", ","& GroupListArray(0, i) &",") > 0 Then Response.Write " checked" End If %> /></td>
      <td class="altbg1"><input type="checkbox" name="posttopicperm" id="posttopicperm_<%= GroupListArray(0, i) %>" class="radio" value="<%= GroupListArray(0, i) %>"<% If InStr(","& Forum_PostTopicPerm &",", ","& GroupListArray(0, i) &",") > 0 Then Response.Write " checked" End If %> /></td>
      <td class="altbg2"><input type="checkbox" name="postreplyperm" id="postreplyperm_<%= GroupListArray(0, i) %>" class="radio" value="<%= GroupListArray(0, i) %>"<% If InStr(","& Forum_PostReplyPerm &",", ","& GroupListArray(0, i) &",") > 0 Then Response.Write " checked" End If %> /></td>
      <td class="altbg1"><input type="checkbox" name="postattachperm" id="postattachperm_<%= GroupListArray(0, i) %>" class="radio" value="<%= GroupListArray(0, i) %>"<% If InStr(","& Forum_PostAttachPerm &",", ","& GroupListArray(0, i) &",") > 0 Then Response.Write " checked" End If %> /></td>
      <td class="altbg2"><input type="checkbox" name="getattachperm" id="getattachperm_<%= GroupListArray(0, i) %>" class="radio" value="<%= GroupListArray(0, i) %>"<% If InStr(","& Forum_GetAttachPerm &",", ","& GroupListArray(0, i) &",") > 0 Then Response.Write " checked" End If %> /></td>
	</tr>
	<% Next %>
	<% End If %>
  </table>
  <p style="text-align: center;"><input type="submit" id="btnsubmit" class="button" value="提交设置" /></p>
</form>
<script type="text/javascript">
function col_checked(colpre){
	var len = document.getElementsByName(colpre).length;
	for (i = 1; i <= len; i++)
		$(colpre +'_'+ i).checked = $('check_'+ colpre).checked ? true : false;
}

function row_checked(row){
	var rows = ['viewperm', 'posttopicperm', 'postreplyperm', 'postattachperm', 'getattachperm'];
	for (i = 0; i <= rows.length - 1; i++)
		$(rows[i] +'_'+ row).checked = $('groupctrl_'+ row).checked ? true : false;
}
</script>
<%
End Sub

'========================================================
'保存版面版主设置
'========================================================
Sub Update_Moderators()
	Dim UserID, ModeratorListArray, strModerators
	Dim New_Moderator, MemberInfo, ModeratorInfo, ForumInfo

	ForumInfo = RQ.Query("SELECT 1 FROM "& TablePre &"forums WHERE fid = "& ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminShowTips("版面不存在或者已经被删除。", "")
	End If

	'删除版主
	UserID = Replace(SafeRequest(2, "uid", 1, "", 0), " ", "")
	If Len(UserID) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"moderators WHERE fid = "& ForumID &" AND uid IN("& UserID &")")
	End If
	
	'添加版主
	New_Moderator = SafeRequest(2, "new_moderator", 1, "", 0)
	If Len(New_Moderator) > 0 Then
		MemberInfo = RQ.Query("SELECT uid, admingroupid FROM "& TablePre &"members WHERE username = '"& New_Moderator &"'")
		If IsArray(MemberInfo) Then
			If MemberInfo(1, 0) = 0 Then
				RQ.Execute("UPDATE "& TablePre &"members SET admingroupid = 3, usergroupid = 3 WHERE uid = "& MemberInfo(0, 0))
			End If

			ModeratorInfo = RQ.Query("SELECT 1 FROM "& TablePre &"moderators WHERE fid = "& ForumID &" AND uid = "& MemberInfo(0, 0))
			If Not IsArray(ModeratorInfo) Then
				RQ.Execute("INSERT INTO "& TablePre &"moderators (fid, uid) VALUES ("& ForumID &", "& MemberInfo(0, 0) &")")
			End If
		End If
	End If
	
	'更新版面缓存
	ModeratorListArray = RQ.Query("SELECT mo.uid, m.username FROM "& TablePre &"moderators mo INNER JOIN "& TablePre &"members m ON mo.uid = m.uid WHERE mo.fid = "& ForumID)
	If IsArray(ModeratorListArray) Then
		For i = 0 To UBound(ModeratorListArray, 2)
			strModerators = strModerators & ModeratorListArray(1, i)
			If i <> UBound(ModeratorListArray, 2) Then
				strModerators = strModerators &"_____SPLIT_____"
			End If
		Next
	End If

	RQ.Execute("UPDATE "& TablePre &"forumfields SET moderators = '"& strModerators &"' WHERE fid = "& ForumID)
	
	Call RQ.Reload_Forum_Settings(ForumID)
	Call closeDatabase()

	Call AdminshowTips("版主设置更新成功。", "?action=moderators&forumid="& ForumID)
End Sub

'========================================================
'版面版主设置界面
'========================================================
Sub Moderators()
	Dim ForumInfo, ModeratorListArray

	ForumInfo = RQ.Query("SELECT name FROM "& TablePre &"forums WHERE fid = "& ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminShowTips("版面不存在或者已经被删除。", "")
	End If

	ModeratorListArray = RQ.Query("SELECT mo.uid, m.username FROM "& TablePre &"moderators mo INNER JOIN "& TablePre &"members m ON mo.uid = m.uid WHERE mo.fid = "& ForumID)
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<a href="?">版面设置</a>&nbsp;&raquo;&nbsp;版主设置</td>
  </tr>
</table>
<br />
<form name="form1" action="?action=update_moderators" method="post" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="forumid" value="<%= ForumID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="2">编辑版主 - <%= ForumInfo(0, 0) %></td>
    </tr>
    <tr class="category">
      <td width="8%">删?</td>
      <td>用户名</td>
    </tr>
	<% If IsArray(ModeratorListArray) Then %>
	<% For i = 0 To UBound(ModeratorListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="uid" class="radio" value="<%= ModeratorListArray(0, i) %>" /></td>
      <td class="altbg2"><%= ModeratorListArray(1, i) %></td>
    </tr>
	<% Next %>
	<% End If %>
    <tr>
      <td class="altbg1">新增:</td>
      <td class="altbg2"><input type="text" name="new_moderator" size="20" /></td>
    </tr>
  </table>
  <p align="center"><input type="submit" id="btnsubmit" class="button" value="提交设置" />
</form>
<%
End Sub

'========================================================
'保存版面帖子分类设置
'========================================================
Sub Update_TopicTypes()
	Dim ForumInfo, d_TypeID
	Dim TypeID, Name, Description, DisplayOrder
	Dim New_Name, New_Description, New_DisplayOrder
	Dim TypeListArray, TopicTypeID, TopicTypeName, TopicType

	ForumInfo = RQ.Query("SELECT 1 FROM "& TablePre &"forums WHERE fid = "& ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminShowTips("版面不存在或者已经被删除。", "")
	End If
	
	'删除帖子分类
	d_TypeID = Replace(SafeRequest(2, "d_typeid", 1, "", 0), " ", "")
	If Len(d_TypeID) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"topictypes WHERE fid = "& ForumID &" AND typeid IN("& d_TypeID &")")
		RQ.Execute("UPDATE "& TablePre &"topics SET typeid = 0 WHERE fid = "& ForumID &" AND typeid IN("& d_TypeID &")")
	End If
	
	'更新帖子分类
	If Request.Form("typeid").Count > 0 Then
		For i = 1 To Request.Form("typeid").Count
			TypeID = IntCode(Request.Form("typeid")(i))
			Name = HtmlFilter(Replace(Request.Form("name")(i), """", """"""))
			Description = strFilter(Request.Form("description")(i))
			DisplayOrder = IntCode(Request.Form("displayorder")(i))
			If TypeID > 0 And Len(Name) > 0 Then
				RQ.Execute("UPDATE "& TablePre &"topictypes SET name = '"& Name &"', description = '"& Description &"', displayorder = '"& DisplayOrder &"' WHERE typeid = "& TypeID)
			End If
		Next
	End If
	
	'添加帖子分类
	New_Name = Replace(SafeRequest(2, "new_name", 1, "", 1), """", """""")
	New_Description = SafeRequest(2, "new_description", 1, "", 0)
	New_DisplayOrder = SafeRequest(2, "new_displayorder", 0, 0, 0)

	If Len(New_Name) > 0 Then
		New_DisplayOrder = Conn.Execute("SELECT IIF(MAX(displayorder) IS NULL, 0, MAX(displayorder)) + 1 FROM "& TablePre &"topictypes WHERE fid = "& ForumID)(0)

		RQ.Execute("INSERT INTO "& TablePre &"topictypes (fid, name, description, displayorder) VALUES ("& ForumID &", '"& New_Name &"', '"& New_Description &"', "& New_DisplayOrder &")")
	End If
	
	'更新版面缓存
	TypeListArray = RQ.Query("SELECT typeid, name FROM "& TablePre &"topictypes WHERE fid = "& ForumID &" ORDER BY displayorder ASC")

	If IsArray(TypeListArray) Then
		TopicType = "Array("

		For i = 0 To UBound(TypeListArray, 2)
			TopicType = TopicType &"Array("""& TypeListArray(1, i) &""", "& TypeListArray(0, i) &")"
			If i <> UBound(TypeListArray, 2) Then
				TopicType = TopicType &", "
			End If
		Next

		TopicType = TopicType &")"
	End If

	RQ.Execute("UPDATE "& TablePre &"forumfields SET topictype = '"& TopicType &"' WHERE fid = "& ForumID)
	
	Call RQ.Reload_Forum_Settings(ForumID)

	Call closeDatabase()
	Call AdminshowTips("帖子分类编辑成功。", "?action=topictypes&forumid="& ForumID)
End Sub

'========================================================
'编辑版面帖子分类界面
'========================================================
Sub TopicTypes()
	Dim ForumInfo, TypeListArray

	ForumInfo = RQ.Query("SELECT name FROM "& TablePre &"forums WHERE fid = "& ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminShowTips("版面不存在或者已经被删除。", "")
	End If

	TypeListArray = RQ.Query("SELECT typeid, name, description, displayorder FROM "& TablePre &"topictypes WHERE fid = "& ForumID &" ORDER BY displayorder ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<a href="?">版面设置</a>&nbsp;&raquo;&nbsp;帖子分类设置</td>
  </tr>
</table>
<br />
<form name="form1" action="?action=update_topictypes" method="post" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="forumid" value="<%= ForumID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="4">编辑帖子分类 - <%= ForumInfo(0, 0) %></td>
    </tr>
    <tr class="category">
      <td width="8%">删?</td>
      <td width="25%">分类名称</td>
      <td width="30%">分类说明</td>
      <td>分类排序</td>
    </tr>
	<% If IsArray(TypeListArray) Then %>
	<% For i = 0 To UBound(TypeListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_typeid" class="radio" value="<%= TypeListArray(0, i) %>" />
	    <input type="hidden" name="typeid" value="<%= TypeListArray(0, i) %>" /></td>
      <td class="altbg2"><input type="text" name="name" size="20" value="<%= strFilter(Replace(TypeListArray(1, i), """""", """")) %>" /></td>
      <td class="altbg1"><input type="text" name="description" size="25" value="<%= TypeListArray(2, i) %>" /></td>
      <td class="altbg2"><input type="text" name="displayorder" size="5" value="<%= TypeListArray(3, i) %>" /></td>
    </tr>
	<% Next %>
	<% End If %>
    <tr>
      <td class="altbg1">新增:</td>
      <td class="altbg2"><input type="text" name="new_name" size="20" /></td>
      <td class="altbg1"><input type="text" name="new_description" size="25" /></td>
      <td class="altbg2"><input type="text" name="new_displayorder" size="5" /></td>
    </tr>
  </table>
  <p align="center"><input type="submit" id="btnsubmit" class="button" value="提交设置" /></p>
</form>
<%
End Sub

'========================================================
'版面帖子转移
'========================================================
Sub Update_Merge()
	Dim s_ForumID, d_ForumID
	Dim ForumInfo, Topics, Posts
	
	s_ForumID = SafeRequest(2, "s_fid", 0, 0, 0)
	d_ForumID = SafeRequest(2, "d_fid", 0, 0, 0)

	If s_ForumID = 0 Or d_ForumID = 0 Or s_ForumID = d_ForumID Then
		Call Merge()
		Exit Sub
	End If

	ForumInfo = RQ.Query("SELECT 1 FROM "& TablePre &"forums WHERE fid = "& s_ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminShowTips("发生错误：源版面不存在。", "")
	End If

	ForumInfo = RQ.Query("SELECT 1 FROM "& TablePre &"forums WHERE fid = "& d_ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminshowTips("发生错误：目标版面不存在。", "")
	End If

	'转移帖子和回复
	RQ.Execute("UPDATE "& TablePre &"posts SET fid = "& d_ForumID &" WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE fid = "& s_ForumID &")")
	RQ.Execute("UPDATE "& TablePre &"topics SET fid = "& d_ForumID &", typeid = 0 WHERE fid = "& s_ForumID)
	RQ.Execute("UPDATE "& TablePre &"sticktopics SET fid = "& d_ForumID &" WHERE fid = "& s_ForumID)

	'统计目标版面的帖子
	Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& d_ForumID &" AND displayorder >= 0")(0)

	'统计目标版面的回复
	Posts = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE fid = "& d_ForumID &")")(0)

	'更新目标版面统计
	RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &", posts = "& Posts &" WHERE fid = "& d_ForumID)

	'统计原版面的帖子
	Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& s_ForumID &" AND displayorder >= 0")(0)

	'统计原版面的回复
	Posts = Conn.Execute("SELECT COUNT(pid) FROM "& TablePre &"posts WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE fid = "& s_ForumID &")")(0)

	'更新原版面统计
	RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &", posts = "& Posts &" WHERE fid = "& s_ForumID)

	'更新目标版面缓存
	Call RQ.Reload_Forum_Settings(d_ForumID)

	'更新原版面缓存
	Call RQ.Reload_Forum_Settings(s_ForumID)

	Call closeDatabase()
	Call AdminshowTips("帖子转移完毕。", "?")
End Sub

'========================================================
'版面帖子转移界面
'========================================================
Sub Merge()
	Dim ForumListArray
	ForumListArray = RQ.Query("SELECT fid, name FROM "& TablePre &"forums")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;<a href="?">版面设置</a>&nbsp;&raquo;&nbsp;帖子分类设置</td>
  </tr>
</table>
<br />
<form method="post" name="merge" action="?action=update_merge"  onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>合并版面</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>源版面:</strong></td>
      <td width="70%"><select name="s_fid">
	    <option value="0">--</option>
	    <% If IsArray(ForumListArray) Then %>
		<% For i = 0 To UBound(ForumListArray, 2) %>
        <option value="<%= ForumListArray(0, i) %>"><%= ForumListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>目标版面:</strong></td>
      <td width="70%"><select name="d_fid">
	    <option value="0">--</option>
	    <% If IsArray(ForumListArray) Then %>
		<% For i = 0 To UBound(ForumListArray, 2) %>
        <option value="<%= ForumListArray(0, i) %>"><%= ForumListArray(1, i) %></option>
		<% Next %>
		<% End If %>
	  </select></td>
    </tr>
    <tr height="25">
	  <td class="altbg1"></td>
	  <td width="70%"><input type="submit" id="btnsubmit" class="button" value="提交设置" /></td>
	</tr>
  </table>
</form>
<%
End Sub

'========================================================
'版面删除提示
'========================================================
Sub Delete()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;删除版面</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>如果删除版面，那么所有属于该版面的内容都将被删除（帖子、回复等）。</td>
  </tr>
</table>
<br />
<form method="post" name="deleteforum" action="?action=deleteconfirm"  onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="dosth" value="deleteconfirm" />
  <input type="hidden" name="forumid" value="<%= ForumID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>删除版面</strong></td>
    </tr>
    <tr height="25">
	  <td class="altbg1"></td>
	  <td width="70%"><input type="submit" id="btnsubmit" class="button" value="确定删除" /></td>
	</tr>
  </table>
</form>
<%
End Sub

'========================================================
'删除版面
'========================================================
Sub DeleteConfirm()
	Dim DoSth, ForumInfo
	Dim AttachListArray

	DoSth = SafeRequest(2, "dosth", 1, "", 0)
	If DoSth <> "deleteconfirm" Then
		Call AdminshowTips("无效的操作。", "")
	End If

	ForumInfo = RQ.Query("SELECT childs FROM "& TablePre &"forums WHERE fid = "& ForumID)
	If Not IsArray(ForumInfo) Then
		Call AdminshowTips("版面不存在或者已经被删除。", "")
	End If

	If ForumInfo(0, 0) > 0 Then
		Call AdminshowTips("该版面还有子版面，不允许删除。", "")
	End If

	'删除附件
	AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE fid = "& ForumID &")")
	If IsArray(AttachListArray) Then
		For i = 0 To UBound(AttachListArray, 2)
			Call DeleteFile("../attachments/"& AttachListArray(0, i))
		Next
		RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE fid = "& ForumID &")")
	End If

	RQ.Execute("DELETE FROM "& TablePre &"forums WHERE fid = "& ForumID)
	RQ.Execute("DELETE FROM "& TablePre &"forumfields WHERE fid = "& ForumID)
	RQ.Execute("DELETE FROM "& TablePre &"topics WHERE fid = "& ForumID)
	RQ.Execute("DELETE FROM "& TablePre &"posts WHERE fid = "& ForumID)
	RQ.Execute("DELETE FROM "& TablePRe &"sticktopics WHERE fid = "& ForumID)
	RQ.Execute("DELETE FROM "& TablePre &"moderators WHERE fid = "& ForumID)

	Application.Lock
	Application.Contents.Remove(CacheName &"_foruminfo_"& ForumID)
	Application.UnLock

	Call closeDatabase()
	Call AdminshowTips("版面已经成功删除。", "?")
End Sub

'========================================================
'版面列表
'========================================================
Sub Main()
	Dim ForumListArray, TEMP, TypeListArray, n
	ForumListArray = RQ.Query("SELECT f.fid, f.name, f.displayorder, f.topics, f.posts, ff.moderators, ff.topictype FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;版面设置</td>
  </tr>
</table>
<br />
<form id="updatecache" method="post" action="?action=updatecache" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%">编号</td>
      <td>版面名称</td>
	  <td>排序编号</td>
	  <td>帖子</td>
	  <td>回复</td>
      <td>当前版主</td>
      <td>当前帖子分类</td>
      <td>操作</td>
    </tr>
    <% If IsArray(ForumListArray) Then %>
    <% For i = 0 To UBound(ForumListArray, 2) %>
    <tr>
      <td class="altbg1"><%= ForumListArray(0, i) %></td>
      <td class="altbg2"><a href="../index.asp?fid=<%= ForumListArray(0, i) %>" target="_blank"><%= ForumListArray(1, i) %></a></td>
      <td class="altbg1"><input type="text" name="displayorder" value="<%= ForumListArray(2, i) %>" size="5" /><input type="hidden" name="forumid" value="<%= ForumListArray(0, i) %>" /></td>
      <td class="altbg2"><%= ForumListArray(3, i) %></td>
      <td class="altbg1"><%= ForumListArray(4, i) %></td>
      <td class="altbg2">
<%
If Len(ForumListArray(5, i)) > 0 Then
	Response.Write "<select>"
	TEMP = Split(ForumListArray(5, i), "_____SPLIT_____")
	For n = 0 To UBound(TEMP)
		Response.Write "<option>"& TEMP(n	) &"</option>"
	Next
	Response.Write "</select>"
Else
	Response.Write "<em>无</em>"
End If
%>
      </td>
      <td class="altbg1">
<%
If Len(ForumListArray(6, i)) > 0 Then
	Response.Write "<select>"
	TypeListArray = eval(ForumListArray(6, i))
	For n = 0 To UBound(TypeListArray)
		Response.Write "<option>"& TypeListArray(n)(0) &"</option>"
	Next
	Response.Write "</select>"
Else
	Response.Write "<em>无</em>"
End If
%>
      </td>
      <td class="altbg2"><a href="?action=moderators&forumid=<%= ForumListArray(0, i) %>">版主</a> | <a href="?action=topictypes&forumid=<%= ForumListArray(0, i) %>">帖子分类</a> | <a href="?action=edit_forum&forumid=<%= ForumListArray(0, i) %>">版面设置</a> | <a href="?action=delete&forumid=<%= ForumListArray(0, i) %>">删除</a></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
	  <td colspan="7">目前还没有版面呢，<a href="?action=add_forum">点击这里添加一个</a>（添加版面后请到“站点设置” -> “搜索和其他设置”中设置默认显示的版面）。</td>
	</tr>
    <% End If %>
  </table>
  <% If IsArray(ForumListArray) Then %><p align="center"><input type="submit" id="btnsubmit" value="更新版面排序和帖子统计" class="button" /></p><% End If %>
</form>
<%
End Sub
%>