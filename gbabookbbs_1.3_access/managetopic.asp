<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("您没有权限访问管理页面。", "", "HALTED")
End If

If RQ.ForumID = 0 Then
	Call RQ.showTips("无效的操作。", "", "")
End If

Dim Action
Action = Request("action")
Select Case Action
	Case "edittopic"
		Call EditTopic()
	Case "deletetopic"
		Call DeleteTopic()
	Case "show_typeid"
		Call Show_TypeID()
	Case "show_content"
		Call Show_Content()
	Case "manageposts"
		Call ManagePosts()
	Case "managepostssubmit"
		Call ManagePostsSubmit()
	Case "deleteposts"
		Call DeletePosts()
	Case "editpost"
		Call EditPost()
	Case "updatepost"
		Call UpdatePost()
	Case Else
		Call Main()
End Select

'========================================================
'验证权限
'========================================================
Sub ValidatePermission()
	If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
		Exit Sub
	End If

	Dim PermissionTips
	If RQ.AdminGroupID = 3 Then
		PermissionTips = "该贴是属于“"& RQ.Get_Forum_Settings(RQ.ForumID, 1) &"”的帖子，而您不是“"& RQ.Get_Forum_Settings(RQ.ForumID, 1) &"”的管理员。"
	Else
		PermissionTips = "您无权对帖子进行编辑。"
	End If

	Call RQ.showTips(PermissionTips, "", "")
End Sub

'========================================================
'帖子设置
'========================================================
Sub EditTopic()
	If Len(Request.Form("btnsave")) > 0 Then
		Call SaveTopic()
	ElseIf Len(Request.Form("btnupdate")) > 0 Then
		Call UpTopic()
	End If
End Sub

'========================================================
'保存帖子设置
'========================================================
Sub SaveTopic()
	Dim TopicInfo, TypeInfo
	Dim Title, NewForumID, TypeID, clicks, UserName, UserShow, DisplayOrder, OverTime, Price, IfLocked, DisableModify, Types, IfElite, IfTask

	TopicInfo = RQ.Query("SELECT displayorder, uid, username, title, posts, iftask FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'验证管理权限
	Call ValidatePermission()

	Title = SafeRequest(2, "title", 1, "", 1)
	NewForumID = SafeRequest(2, "newfid", 0, 0, 0)
	TypeID = SafeRequest(2, "typeid", 0, 0, 0)
	clicks = SafeRequest(2, "clicks", 0, 0, 0)
	UserName = SafeRequest(2, "username", 1, "", 0)
	UserShow = SafeRequest(2, "usershow", 1, "", 1)
	DisplayOrder = SafeRequest(2, "displayorder", 0, 0, 0)
	OverTime = SafeRequest(2, "overtime", 1, "", 0)
	Price = SafeRequest(2, "price", 0, 0, 0)
	IfLocked = SafeRequest(2, "iflocked", 0, 0, 0)
	DisableModify = SafeRequest(2, "disablemodify", 0, 0, 0)
	Types = SafeRequest(2, "types", 0, 0, 0)
	IfElite = SafeRequest(2, "ifelite", 0, 0, 0)

	'验证是否为正确的帖子分类
	If TypeID > 0 Then
		TypeInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topictypes WHERE fid = "& NewForumID &" AND typeid = "& TypeID)
		If Not IsArray(TypeInfo) Then
			TypeID = 0
		End If
	End If

	If RQ.Get_Forum_Settings(NewForumID, 12) = 1 And TypeID = 0 Then
		Call RQ.showTips("请选择好帖子分类。", "", "")
	End If

	If Len(Title) = 0 Then
		Call RQ.showTips("请填写好标题。", "", "")
	End If

	'词语过滤
	Title = WordsFilter(Title)

	If Len(UserName) = 0 Then
		Call ShowTips("请填写好真实用户名。", "", "")
	End If

	If Len(UserShow) = 0 Then
		Call ShowTips("请填写好显示用户名。", "", "")
	End If

	Title = IIF(Len(Title) > 255, Left(Title, 255), Title)
	Username = IIF(Len(Username) > 20, Left(UserName, 20), UserName)
	UserShow = IIF(Len(UserShow) > 100, Left(UserShow, 100), UserShow)
	DisplayOrder = IIF(DisplayOrder > 3, 0, DisplayOrder)
	IfLocked = IIF(IfLocked > 2, 0, IfLocked)
	DisableModify = IIF(DisableModify > 2, 0, DisableModify)
	Types = IIF(Types > 5, 0, Types)
	IfElite = IIF(IfElite > 1, 0, IfElite)

	If IsDate(OverTime) Then
		OverTime = CDate(OverTime)
		If DateDiff("n", OverTime, Now()) >= 0 Then
			OverTime = Empty
		End If
	End If

	'如果转移了帖子
	If RQ.ForumID <> NewForumID Then
		'转移回复到新版面
		RQ.Execute("UPDATE "& TablePre &"posts SET fid = "& NewForumID &" WHERE tid = "& RQ.TopicID)

		'更新原版面的帖子统计
		RQ.Execute("UPDATE "& TablePre &"forums SET topics = topics - 1, posts = posts - ("& TopicInfo(4, 0) + 1 &") WHERE fid = "& RQ.ForumID)

		'更新新版面的帖子和回复统计
		RQ.Execute("UPDATE "& TablePre &"forums SET topics = topics + 1, posts = posts + ("& TopicInfo(4, 0) + 1 &") WHERE fid = "& NewForumID)

		'更新缓存中新版面的帖子统计
		Call RQ.Update_TopicNum(NewForumID, RQ.Get_Forum_Settings(NewForumID, 6) + 1)

		'更新缓存中原版面的帖子统计
		Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics - 1)
	End If

	'是否有置顶权限
	If RQ.AllowStickTopic = 1 Then
		'版主只能在当前版面置顶帖子
		If DisplayOrder > 1 Then
			DisplayOrder = IIF(InArray(Array(1, 2), RQ.AdminGroupID), DisplayOrder, 1)
		End If

		RQ.Execute("UPDATE "& TablePre &"topics SET fid = "& NewForumID &", typeid = "& TypeID &", displayorder = "& DisplayOrder &", username = '"& UserName &"', usershow = '"& UserShow &"', title = '"& Title &"', clicks = "& clicks &", types = "& Types &", price = "& Price &", iflocked = "& IfLocked &", ifelite = "& IfElite &", disablemodify = "& DisableModify &" WHERE tid = "& RQ.TopicID)

		'更新置顶帖
		If RQ.ForumID <> NewForumID Or TopicInfo(0, 0) <> DisplayOrder Then
			Call RQ.UpdateStickTopic(NewForumID, RQ.TopicID, DisplayOrder)

			If TopicInfo(0, 0) <> DisplayOrder Then
				If DisplayOrder = 0 Then
					RQ.Execute("UPDATE "& TablePre &"topics SET iftask = 0 WHERE tid = "& RQ.TopicID)
					RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
				End If
			End If
		End If

		'设置置顶帖过期时间
		If DisplayOrder > 0 Then
			If IsDate(OverTime) Then
				If TopicInfo(5, 0) = 0 Then
					RQ.Execute("UPDATE "& TablePre &"topics SET iftask = 1 WHERE tid = "& RQ.TopicID)
					RQ.Execute("INSERT INTO "& TablePre &"topictask (tid, expirytime, theaction) VALUES ("& RQ.TopicID &", #"& OverTime &"#, 'STICK')")
				Else
					RQ.Execute("UPDATE "& TablePre &"topictask SET expirytime = #"& OverTime &"# WHERE tid = "& RQ.TopicID)
				End If
			Else
				RQ.Execute("UPDATE "& TablePre &"topics SET iftask = 0 WHERE tid = "& RQ.TopicID)
				RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
			End If
		End If
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET fid = "& NewForumID &", typeid = "& TypeID &", username = '"& UserName &"', usershow = '"& UserShow &"', title = '"& Title &"', clicks = "& clicks &", types = "& Types &", price = "& Price &", iflocked = "& IfLocked &", ifelite = "& IfElite &", disablemodify = "& DisableModify &" WHERE tid = "& RQ.TopicID)
	End If

	RQ.Execute("UPDATE "& TablePre &"posts SET username = '"& UserName &"', usershow = '"& UserShow &"' WHERE tid = "& RQ.TopicID &" AND iffirst = 1")

	Call closeDatabase()
	Call RQ.showTips("帖子编辑完毕。", "viewtopic.asp?fid="& NewForumID &"&tid="& RQ.TopicID, "")
End Sub

'========================================================
'提升帖子
'========================================================
Sub UpTopic()
	Dim TopicInfo

	TopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'验证管理权限
	Call ValidatePermission()

	RQ.Execute("UPDATE "& TablePre &"topics SET lastupdate = #"& Now() &"# WHERE tid = "& RQ.TopicID)

	Call closeDatabase()
	Call RQ.showTips("帖子已经提升到顶部。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& RQ.TopicID, "")
End Sub

'========================================================
'删除帖子
'========================================================
Sub DeleteTopic()
	Dim TopicInfo, AttachListArray
	Dim strReason, strOperation, DeductCredits

	TopicInfo = RQ.Query("SELECT displayorder, uid, username, title, special, leagueid, iftask, ifattachment FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'验证管理权限
	Call ValidatePermission()

	strReason = SafeRequest(2, "reason", 1, "", 0)
	DeductCredits = SafeRequest(2, "deductcredits", 0, 0, 0)

	If Len(CheckContent(strReason)) = 0 Then
		Call RQ.showTips("请填写好删除原因。", "", "")
	End If

	'删帖是否放入回收站
	If RQ.F_RecycleBin = 0 Then
		'删除帖子
		RQ.Execute("DELETE FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID)

		'删除回复
		RQ.Execute("DELETE FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID)

		'删除用户收藏贴记录
		RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE tid = "& RQ.TopicID)

		'删除置顶帖记录
		If TopicInfo(0, 0) > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"sticktopics WHERE tid = "& RQ.TopicID)
		End If

		Select Case TopicInfo(4, 0)
			'投票帖子
			Case 1
				RQ.Execute("DELETE FROM "& TablePre &"polls WHERE tid = "& RQ.TopicID)
				RQ.Execute("DELETE FROM "& TablePre &"polloptions WHERE tid = "& RQ.TopicID)
		End Select

		'删除联盟贴记录
		If TopicInfo(5, 0) > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE tid = "& RQ.TopicID)
		End If

		'删除限时置顶的记录
		If TopicInfo(6, 0) > 0 Then
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
		End If

		'如果有附件标记则读取附件
		If Topicinfo(7, 0) = 1 Then
			AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE tid = "& RQ.TopicID)
			'删除附件
			If IsArray(AttachListArray) Then
				For i = 0 To UBound(AttachListArray, 2)
					Call DeleteFile("./attachments/"& AttachListArray(0, i))
				Next
				RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE tid = "& RQ.TopicID)
			End If
		End If

		'更新版面缓存中的帖子总数
		RQ.Forum_Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder >= 0")(0)
		dbQueryNum = dbQueryNum + 1

		RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& RQ.Forum_Topics &" WHERE fid = "& RQ.ForumID)
		Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics)
	Else
		'放入回收站
		RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = -2 WHERE tid = "& RQ.TopicID)
	End If

	'操作记录
	strOperation = "删贴："& dfc(TopicInfo(3, 0))

	'扣除金钱
	If DeductCredits > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& DeductCredits &" WHERE uid = "& TopicInfo(1, 0))
		strOperation = strOperation &"，<span class=""pink"">扣除"& RQ.Other_Settings(0) & Deductcredits &"点。</span>"
	End If

	'记录异动报告
	Call RQ.SetLog(TopicInfo(1, 0), TopicInfo(2, 0), strOperation, strReason)

	Call closeDatabase()
	Call RQ.showTips("帖子删除完毕。", "", "HALTED")
End Sub

'========================================================
'显示版面的帖子分类(AJAX输出)
'========================================================
Sub Show_TypeID()
	Dim ForumID, TypeID, TypeListArray
	
	ForumID = SafeRequest(3, "fid", 0, 0, 0)
	TypeID = SafeRequest(3, "typeid", 0, 0, 0)

	TypeListArray = RQ.Query("SELECT typeid, name FROM "& TablePre &"topictypes WHERE fid = "& ForumID &" ORDER BY displayorder ASC")
	Call closeDatabase()

	If IsArray(TypeListArray) Then
		Response.Write "<select name=""typeid"" id=""typeid""><option value=""0"">--</option>"
		For i = 0 To UBound(TypeListArray, 2)
			Response.Write "<option value="""& TypeListArray(0, i) &""""& IIF(TypeID = TypeListArray(0, i), " selected", "") &">"& TypeListArray(1, i) &"</option>"
		Next
	End If
End Sub

'========================================================
'回复管理(提交)
'========================================================
Sub ManagePostsSubmit()
	If Len(Request.Form("btnsubmit")) > 0 Then
		Call SavePosts()
	ElseIf Len(Request.Form("btndelete")) > 0 Then
		Call DeleteTopic()
	ElseIf Len(Request.Form("btnappraisal")) > 0 Then
		Call AppraisalTopic()
	End If
End Sub

'========================================================
'回复管理(保存对帖子属性的设置)
'========================================================
Sub SavePosts()
	Dim TopicInfo, Types, Price, IfElite

	TopicInfo = RQ.Query("SELECT uid, username, title FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)

	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'验证管理权限
	Call ValidatePermission()

	Types = SafeRequest(2, "types", 0, 0, 0)
	Price = SafeRequest(2, "price", 0, 0, 0)
	IfElite = SafeRequest(2, "ifelite", 0, 0, 0)

	Types = IIF(Types > 5, 0, Types)
	IfElite = IIF(IfElite > 1, 0, IfElite)

	RQ.Execute("UPDATE "& TablePre &"topics SET types = "& Types &", price = "& Price &", ifelite = "& IfElite &" WHERE tid = "& RQ.TopicID)

	Call closeDatabase()
	Call RQ.showTips("帖子设置成功。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& RQ.TopicID, "")
End Sub

'========================================================
'回复管理(鉴定帖子)
'========================================================
Sub AppraisalTopic()
	Dim TopicInfo, Appraisal, DisableModify, NewTitle
	Dim SqlAddon

	TopicInfo = RQ.Query("SELECT title, disablemodify FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'验证管理权限
	Call ValidatePermission()

	Appraisal = SafeRequest(2, "appraisal", 1, "", 1)
	If Len(Appraisal) = 0 Then
		Call RQ.showTips("请填写好帖子鉴定内容。", "", "")
	End If

	'词语过滤
	Appraisal = WordsFilter(Appraisal)

	DisableModify = SafeRequest(2, "disablemodify", 0, 0, 0)
	DisableModify = IIF(DisableModify > 1, 0, DisableModify)

	Appraisal = "(被<u>"& RQ.UserName &"</u>鉴定为"& Appraisal &")"
	NewTitle = TopicInfo(0, 0)

	'如果加上鉴定内容标题超长则截取原标题
	If Len(TopicInfo(0, 0) & Appraisal) > 255 Then
		NewTitle = Left(TopicInfo(0, 0), 255 - Len(Appraisal))
	End If

	NewTitle = NewTitle & Appraisal

	'被鉴定后的帖子是否允许编辑(如果之前被设置为不允许编辑帖子和回复那么此选项无效)
	If TopicInfo(1, 0) <> 2 Then
		SqlAddon = ", disablemodify = "& DisableModify
	End If

	RQ.Execute("UPDATE "& TablePre &"topics SET title = '"& NewTitle &"'"& SqlAddon &" WHERE tid = "& RQ.TopicID)

	Call closeDatabase()
	Call RQ.showTips("帖子鉴定完毕。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& RQ.TopicID, "")
End Sub

'========================================================
'回复管理(删除回复)
'========================================================
Sub DeletePosts()
	Dim TopicInfo, PostID, Posts
	Dim AttachListArray

	TopicInfo = RQ.Query("SELECT uid FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'如果不是管理员或者楼主则禁止访问
	If Not RQ.IsModerator Or RQ.AllowManageTopic = 0 Then
		If RQ.UserID <> TopicInfo(0, 0) Then
			If RQ.AdminGroupID = 3 Then
				PermissionTips = "该贴是属于“"& RQ.Get_Forum_Settings(TopicInfo(0, 0), 1) &"”的帖子，而您不是“"& RQ.Get_Forum_Settings(TopicInfo(0, 0), 1) &"”的管理员。"
			Else
				PermissionTips = "您无权对帖子进行编辑。"
			End If
			Call RQ.showTips(PermissionTips, "", "NOPERM")
		End If
	End If

	PostID = NumberGroupFilter(Replace(SafeRequest(2, "pid", 1, "", 0), " ", ""))
	If Len(PostID) = 0 Then
		Call RQ.showTips("请选中需要删除的回复。", "", "")
	End If

	'删除回复
	RQ.Execute("DELETE FROM "& TablePre &"posts WHERE pid IN("& PostID &") AND iffirst = 0 AND tid = "& RQ.TopicID)

	'读取附件
	AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE pid IN("& PostID &") AND tid = "& RQ.TopicID)

	'删除附件
	If IsArray(AttachListArray) Then
		For i = 0 To UBound(AttachListArray, 2)
			Call DeleteFile("./attachments/"& AttachListArray(0, i))
		Next
		RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE pid IN("& PostID &") AND tid = "& RQ.TopicID)
	End If

	'统计并更新帖子剩余回复数量
	Posts = Conn.Execute("SELECT COUNT(pid) - 1 FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID)(0)
	dbQueryNum = dbQueryNum + 1

	RQ.Execute("UPDATE "& TablePre &"topics SET posts = "& Posts &" WHERE tid = "& RQ.TopicID)

	Call closeDatabase()
	Call RQ.showTips("选中的回复已经删除完毕。", "?action=manageposts&fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&page="& SafeRequest(2, "page", 0, 1, 0), "")
End Sub

'========================================================
'编辑帖子/回复内容
'========================================================
Sub EditPost()
	Call ValidatePermission()

	Dim PostID, PostInfo
	Dim AttachListArray

	PostID = SafeRequest(3, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT p.iffirst, p.username, p.message, p.ifattachment, t.tid, t.disablemodify FROM "& TablePre &"posts p INNER JOIN "& TablePre &"topics t ON p.tid = t.tid WHERE p.pid = "& PostID &" AND t.fid = "& RQ.ForumID)

	If Not IsArray(PostInfo) Then
		Call RQ.showTips("回复不存在或者已经被删除。", "", "")
	End If

	'帖子(回复)是否允许被编辑
	Select Case PostInfo(5, 0)
		Case 1
			If PostInfo(0, 0) = 1 Then
				Call RQ.showTips("由于帖子被鉴定或者其他方面的原因，该帖子不允许编辑。", "", "HALTED")
			End If

		Case 2
			Call RQ.showTips("由于帖子类型特殊(例如悬赏贴)或者其他方面的原因，该帖子不允许编辑。", "", "HALTED")
	End Select

	'如果回复有附件标记则读取附件
	If PostInfo(3, 0) = 1 Then
		AttachListArray = RQ.Query("SELECT aid, filename, filesize, savepath, downloads, description FROM "& TablePre &"attachments WHERE pid = "& PostID &" ORDER BY posttime ASC")
		Call Include("./include/attachment.inc.asp")
	End If

	Call closeDatabase()
	RQ.Header()
%>
<body class="blankbg" style="margin: 0px; padding: 0px;">
<script type="text/javascript">
function closelightbox(id){
	parent.$('l_box').style.display = 'none';
	parent.$('lb_cont').src = 'about:blank';
	parent.$('post_'+ id).innerHTML = FCKeditorAPI.GetInstance('message').GetXHTML(true);
}
</script>
<form name="editpost" method="post" action="?action=updatepost" onsubmit="return closelightbox('<%= PostID %>');">
  <input type="hidden" name="pid" value="<%= PostID %>" />
  <input type="hidden" name="fid" value="<%= RQ.ForumID %>" />
  <table border="0" cellspacing="0" cellpadding="0" width="95%" align="center" style="margin: 0 auto; margin-top: 10px;">
    <tr>
      <td><input type="hidden" id="message" name="message" style="display:hidden" value="<%= strFilter(PostInfo(2, 0)) %>" />
        <input type="hidden" id="content___Config" value="" style="display:none" />
        <iframe id="content___Frame" src="include/editor/editor/fckeditor.html?InstanceName=message" width="100%" height="200" frameborder="0" scrolling="no"></iframe>
      </td>
    </tr>
    <tr>
      <td height="30"><input type="submit" id="btnsubmit" value="提交修改" class="button" />&nbsp;&nbsp;<span id="spanButtonPlaceholder"></span></td>
    </tr>
  </table>
  <% If IsArray(AttachListArray) Then %>
  <table width="95%" border="0" cellpadding="0" cellspacing="0" class="tblborder" align="center" style="margin: 0 auto;">
    <tr class="header">
      <td colspan="6"><strong>附件列表</strong></td>
    </tr>
    <tr class="category">
      <td>删</td>
      <td>编号</td>
      <td>附件名称</td>
      <td>描述</td>
    </tr>
    <% For i = 0 To UBound(AttachListARray, 2) %>
    <tr>
      <td><input type="checkbox" name="d_aid" value="<%= AttachListArray(0, i) %>" />
        <input type="hidden" name="aid" value="<%= AttachListArray(0, i) %>" /></td>
      <td><%= AttachListArray(0, i) %></td>
      <td><a href="javascript:insert_attach(<%= AttachListArray(0, i) %>);" class="underline">[插入]</a>
        <img src="images/attachicons/<%= ShowFileType(AttachListArray(1, i)) %>" align="absmiddle" />
        <a href="attachment.asp?action=get&aid=<%= AttachListArray(0, i) %>" class="underline" title="<%= AttachListArray(1, i) %>" target="_blank"><%= Left(AttachListArray(1, i), 12) %></a></td>
      <td><input type="text" name="description" value="<%= AttachListArray(5, i) %>" size="15" class="inputgrey" /></td>
    </tr>
    <% Next %>
  </table>
  <% End If %>
  <table width="95%" border="0" cellpadding="0" cellspacing="0" align="center" style="margin: 0 auto;">
    <tr>
      <td><div id="fsUploadProgress"></div></td>
    </tr>
  </table>
</form>
<% If RQ.AllowPostAttach Then %>
<link href="js/swfupload/default.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="js/ajax.js"></script>
<script type="text/javascript" src="js/swfupload/swfupload.js"></script>
<script type="text/javascript" src="js/swfupload/swfupload.queue.js"></script>
<script type="text/javascript">
var upload;
window.onload = function() {
	upload = new SWFUpload({
		upload_url: "attachment.asp?action=upload&uc=<%= RQ.UserCode %>",
		file_size_limit : "<%= IIF(RQ.MaxAttachSize = 0, 100 * 1024, RQ.MaxAttachSize) %>",
		file_types : "<%= IIF(Len(RQ.AttachExtensions) = 0, "*.*", Replace("*."& RQ.AttachExtensions, ",", ";*.")) %>",
		file_types_description : "附件文件",
		file_upload_limit : "10",
		file_queue_limit : "10",
		file_dialog_start_handler : fileDialogStart,
		file_queued_handler : fileQueued,
		file_queue_error_handler : fileQueueError,
		file_dialog_complete_handler : fileDialogComplete,
		upload_start_handler : uploadStart,
		upload_progress_handler : uploadProgress,
		upload_error_handler : uploadError,
		upload_success_handler : uploadSuccess,
		upload_complete_handler : uploadComplete,
		button_placeholder_id : "spanButtonPlaceholder",
		button_width: 140,
		button_height: 18,
		button_text : '<span class="underline">上传附件(<%= IIF(RQ.MaxAttachSize = 0, "100MB", RQ.MaxAttachSize &"KB") %>以内)</span>',
		button_text_style : '.underline{text-decoration:underline;color:#0099ff;}',
		button_window_mode: SWFUpload.WINDOW_MODE.TRANSPARENT,
		button_cursor: SWFUpload.CURSOR.HAND,
		flash_url : "js/swfupload/swfupload.swf",
		custom_settings : {
			progressTarget : "fsUploadProgress",
			cancelButtonId : "btnCancel"
		},
		debug: false
	});
 }
</script>
<% End If %>
</body>
</html>
<%
End Sub

'========================================================
'更新帖子/回复内容
'========================================================
Sub UpdatePost()
	Call ValidatePermission()

	Dim PostID, PostInfo, Message, Attachments, IfAttachment
	Dim d_AttachID, AttachID, Description, NewAttachID, NewDescription, AttachListArray

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	Message = Replace(Replace(SafeRequest(2, "message", 1, "", 1), Chr(10), ""), Chr(13), "")

	If Len(Message) = 0 Then
		Call RQ.showTips("请填写好内容。", "", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	PostInfo = RQ.Query("SELECT tid FROM "& TablePre &"posts WHERE pid = "& PostID &" AND fid = "& RQ.ForumID)
	If Not IsArray(PostInfo) Then
		Call RQ.showTips("帖子/回复不存在或者已经被删除。", "", "")
	End If

	'删除附件
	d_AttachID = NumberGroupFilter(Replace(SafeRequest(2, "d_aid", 1, "", 0), " ", ""))
	If Len(d_AttachID) > 0 Then
		AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE aid IN("& d_AttachID &") AND pid = "& PostID)
		If IsArray(AttachListArray) Then
			For i = 0 To UBound(AttachListArray, 2)
				Call DeleteFile("./attachments/"& AttachListArray(0, i))
			Next
			RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE aid IN("& d_AttachID &") AND pid = "& PostID)
		End If
	End If

	'更新描述
	If Request.Form("aid").Count > 0 Then
		For i = 1 To Request.Form("aid").Count
			AttachID = IntCode(Request.Form("aid")(i))
			Description = strFilter(Request.Form("description")(i))
			Description = IIF(Len(Description) > 255, Left(Description, 255), Description)

			If AttachID > 0 And Not InStr(","& d_AttachID &",", ","& AttachID &",") > 0 Then
				RQ.Execute("UPDATE "& TablePre &"attachments SET description = '"& Description &"' WHERE aid = "& AttachID &" AND pid = "& PostID)
			End If
		Next
	End If

	'新增附件
	If Request.Form("newaid").Count > 0 Then
		For i = 1 To Request.Form("newaid").Count
			NewAttachID = IntCode(Request.Form("newaid")(i))
			NewDescription = strFilter(Request.Form("newdescription")(i))
			NewDescription = IIF(Len(NewDescription) > 255, Left(NewDescription, 255), NewDescription)

			If NewAttachID > 0 Then
				RQ.Execute("UPDATE "& TablePre &"attachments SET tid = "& PostInfo(0, 0) &", pid = "& PostID &", description = '"& NewDescription &"' WHERE aid = "& NewAttachID)
			End If
		Next
	End If

	'发言是否有附件
	Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE pid = "& PostID)(0)
	IfAttachment = IIF(Attachments = 0, 0, 1)

	'更新回复内容
	RQ.Execute("UPDATE "& TablePre &"posts SET message = '"& Message &"', ifattachment = "& IfAttachment &" WHERE pid = "& PostID)

	'帖子是否有附件
	Attachments = Conn.Execute("SELECT COUNT(aid) FROM "& TablePre &"attachments WHERE tid = "& PostInfo(0, 0))(0)
	IfAttachment = IIF(Attachments = 0, 0, 1)

	'更新帖子附件信息
	RQ.Execute("UPDATE "& TablePre &"topics SET ifattachment = "& IfAttachment &" WHERE tid = "& PostInfo(0, 0))

	Call closeDatabase()
End Sub

'========================================================
'回复管理(管理员显示帖子分类、鉴定、删除)
'========================================================
Sub ManagePosts()
	Dim TopicInfo, html
	Dim Page, PageCount, RecordCount, FloorAddtion, ArrayPosition, CountArray, AryCredits
	Dim PostListArray, strSQL, PermissionTips

	TopicInfo = RQ.Query("SELECT fid, uid, title, posts, types, price, ifelite, disablemodify FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID)

	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'检验版面id
	If TopicInfo(0, 0) <> RQ.ForumID Then
		Call closeDatabase()
		Response.Redirect "?action=manageposts&fid="& TopicInfo(0, 0) &"&tid="& RQ.TopicID
		Response.End()
	End If

	'如果不是管理员或者楼主则禁止访问
	If Not RQ.IsModerator Or RQ.AllowManageTopic = 0 Then
		If RQ.UserID <> TopicInfo(1, 0) Then
			If RQ.AdminGroupID = 3 Then
				PermissionTips = "该贴是属于“"& RQ.Get_Forum_Settings(TopicInfo(0, 0), 1) &"”的帖子，而您不是“"& RQ.Get_Forum_Settings(TopicInfo(0, 0), 1) &"”的管理员。"
			Else
				PermissionTips = "您无权对帖子进行编辑。"
			End If
			Call RQ.showTips(PermissionTips, "", "NOPERM")
		End If
	End If

	'HTML开关
	html = SafeRequest(3, "html", 0, 0, 0)

	'获得页数
	RecordCount = TopicInfo(3, 0)
	RecordCount = IIF(RecordCount = 0, 1, RecordCount)

	Page = SafeRequest(3, "page", 0, 1, 0)
	PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(4)))))
	Page = IIF(Page > PageCount, PageCount, Page)

	AryCredits = Array(1, 5, 10, 15, 30, 50, 80, 100, 150, 200, 250, 300, 500, 800, 1000, 1200, 1500, 1800, 2000, 2500, 5000, 9999, 100000, 1000000)

	'连接SQL语句
	If Page = 1 Then
		strSQL = "SELECT TOP "& IntCode(RQ.Topic_Settings(4)) + 1 &" pid, uid, username, usershow, message, posttime, userip, ifanonymity, ratemark FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID

		FloorAddtion = 0
		ArrayPosition = 1
	Else
		strSQL = "SELECT TOP "& RQ.Topic_Settings(4) &" pid, uid, username, usershow, message, posttime, userip, ifanonymity, ratemark FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" AND posttime > (SELECT MAX(posttime) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(4)) * (Page - 1) + 1 &" posttime FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" ORDER BY posttime ASC) AS tblTemp)"

		FloorAddtion = 1
		ArrayPosition = 0
	End If
	strSQL = strSQL &" ORDER BY posttime ASC"

	'查询回复
	PostListArray = RQ.Query(strSQL)
	If Not IsArray(PostListArray) Then
		Call RQ.showTips("帖子出错。", "", "")
	End If

	Call closeDatabase()
	RQ.Header()
%>
<body>
<a href="viewtopic.asp?fid=<%= RQ.ForumID %>&tid=<%= RQ.TopicID %>&page=<%= Page %>"><%= TopicInfo(2, 0) %></a>
<hr color="black" />
<% 
	If RQ.IsModerator And RQ.AllowManageTopic = 1 And Page = 1 Then
		Response.Write "<span id=""post_"& PostListArray(0, 0) &""">"& ShowHtml(PostListArray(4, 0), html) &"</span><br /><em>(发帖时间:"& PostListArray(5, 0) &")</em><br /><br />---<span id=""editlink_"& PostListArray(0, 0) &"""></span>"

		If PostListArray(1, 0) > 0 Then
			Response.Write PostListArray(2, 0) &"&nbsp;&nbsp;"

			'匿名则显示提示
			If PostListArray(7, 0) > 0 Then
				Response.Write "<a href=""item.asp?action=topicitem&op=anonymity&pid="& PostListArray(0, 0) &""" onclick=""return shows3(this.href);"" class=""bluelink"">匿名道具</a>&nbsp;"
			End If

			Response.Write "<a href=""pm.asp?action=send&u="& Server.URLEncode(PostListArray(2, 0)) &""" class=""bluelink"" onclick=""return shows(this.href);"">传呼</a>"

			'是否有处罚用户的权限
			If RQ.AllowPunishUser = 1 Or RQ.AllowEditUser = 1 Then
				Response.Write "&nbsp;&nbsp;<a href=""managemember.asp?action=detail&uid="& PostListArray(1, 0) &""" class=""bluelink"">编辑用户</a>"
			End If
		Else
			Response.Write "<em>"& PostListArray(2, 0) &"</em>&nbsp;&nbsp;"
		End If

		Response.Write "&nbsp;&nbsp;<a href=""###"" onclick=""showlightbox('editlink_"& PostListArray(0, 0) &"', '?action=editpost&fid="& RQ.ForumID &"&pid="& PostListArray(0, 0) &"');"" class=""bluelink"">编辑内容</a>"

		'是否允许查看用户IP
		If RQ.AllowViewIP = 1 Then
			Response.Write "&nbsp;&nbsp;<a href=""managemember.asp?query_userip="& Trim(PostListArray(6, 0)) &""" style=""color:#00f;"" class=""underline"">"& Trim(PostListArray(6, 0)) &"</a>"
		End If
%>
<br />
<br />
<form action="?action=managepostssubmit" method="post" name="managepostssubmit">
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>">
  <input type="hidden" name="fid" value="<%= RQ.ForumID %>">
  <span style="background: #cbe4cb">修改帖子为:
  <select name="types">
    <option value="0">--</option>
    <option value="1"<% If TopicInfo(4, 0) = 1 Then Response.Write " selected" End If %>>转载</option>
    <option value="2"<% If TopicInfo(4, 0) = 2 Then Response.Write " selected" End If %>>下载</option>
    <option value="3"<% If TopicInfo(4, 0) = 3 Then Response.Write " selected" End If %>>原创</option>
    <option value="4"<% If TopicInfo(4, 0) = 4 Then Response.Write " selected" End If %>>召集</option>
    <option value="5"<% If TopicInfo(4, 0) = 5 Then Response.Write " selected" End If %>>实用</option>
  </select>
  <select name="ifelite">
    <option value="0">--</option>
    <option value="1"<% If TopicInfo(6, 0) = 1 Then Response.Write " selected" End If %>>精彩</option>
  </select>
  ,看帖<%= RQ.Other_Settings(0) %>为
  <select name="price">
    <option value="0">不限制</option>
    <% For i = 0 To UBound(AryCredits) %>
	<option value="<%= AryCredits(i) %>"<%= IIF(TopicInfo(5, 0) = AryCredits(i), " selected", "") %>><%= AryCredits(i) %></option>
	<% Next %>
  </select>
  </span>
  <input type="submit" name="btnsubmit" value="确定" class="button" />
  <input type="button" name="button" value="删帖" onClick="$('p_delete').style.display='';$('p_appraisal').style.display='none'" class="button" />
  <input type="button" name="button" value="鉴定" onClick="$('p_appraisal').style.display='';$('p_delete').style.display='none'" class="button" />
  <p>
  <div style="display:none" id="p_delete">删除原因：<input type="text" name="reason" size="40" />
    <br />
    扣除<%= RQ.Other_Settings(0) %>：<input type="text" name="deductcredits" size="10" />
    <input type="submit" value="确定删帖" name="btndelete" class="button" />
    <p>
  </div>
  <div style="display:none" id="p_appraisal">鉴定为:
    <input type="text" name="appraisal" size="30" value="<%= RQ.Topic_Settings(7) %>" />
    <input type="checkbox" name="disablemodify" id="disablemodify" value="1"<%= IIF(TopicInfo(7, 0) = 1, " checked", "") %> /><label for="disablemodify">不允许楼主修改帖子</label>
    <input type="submit" value="提交鉴定" name="btnappraisal" class="button" />
    <p> 注意鉴定信息不要过长，整个标题长度最大为255个字符，如加上鉴定信息超出限定长度，则从标题里减去相应的字符数量。
    <p>
  </div>
</form>
<script type="text/javascript">
function showlightbox(id, url){
	var objPos = new getPos(id);
	$('l_box').style.left = objPos.Left;
	$('l_box').style.top = objPos.Top;
	$('l_box').style.display = 'block';
	$('lb_cont').src = url !== '' ? url : 'about:blank';
}

function closelightbox(){
	$('l_box').style.display = 'none';
	$('lb_cont').src = 'about:blank';
}
</script>
<div id="l_box" style="position:absolute; height:300px; width:450px; background-color: #fff; border: 1px solid #000000; display:none; z-index:100;">
  <div align="right"><a href="###" onclick="closelightbox();"><img src="images/common/icon_close.gif" border="0" alt="关闭" /></a></div>
  <iframe id="lb_cont" width="100%" frameborder="0" scrolling="auto" src="about:blank" height="100%" ></iframe>
</div>
<%
	End If

	If (RQ.IsModerator And RQ.AllowManageTopic = 1) Or UBound(PostListArray, 2) > 0 Then
		If html = 1 Then
			Response.Write "[<a href=""?action=manageposts&fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&page="& Page &""" class=""bluelink"">屏蔽Html</a>]"
		Else
			Response.Write "[<a href=""?action=manageposts&fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&html=1&page="& Page &""" class=""bluelink"">恢复Html</a>]"
		End If
	End If

	'显示回复
	If UBound(PostListArray, 2) > -1 Then
		
		Response.Write "<p><form name=""deleteposts"" action=""?action=deleteposts"" method=""post"" onsubmit=""$('btndeleteposts').value='正在提交,请稍后...';$('btndeleteposts').disabled=true;""><input type=""hidden"" name=""tid"" value="""& RQ.TopicID &""" /><input type=""hidden"" name=""fid"" value="""& RQ.ForumID &""" /><input type=""hidden"" name=""page"" value="""& Page &""" />"

		CountArray = UBound(PostListArray, 2)

		For i = ArrayPosition To CountArray
			Response.Write "<input type=""checkbox"" name=""pid"" value="""& PostListArray(0, i) &""" /><span class=""pink"">回复("& IntCode(RQ.Topic_Settings(4)) * (Page - 1) + i + FloorAddtion &")</span>:<span title="""& PostListArray(5, i) &""" id=""post_"& PostListArray(0, i) &""">"& ShowHtml(PostListArray(4, i), html) &"</span><br />---<span id=""editlink_"& PostListArray(0, i) &"""></span>"

			If PostListArray(1, i) > 0 Then
				'管理员则显示真实用户名
				Response.Write IIF(RQ.IsModerator, PostListArray(2, i), PostListArray(3, i))
			Else
				'游客用斜体显示
				Response.Write "<em>"& PostListArray(3, i) &"</em>"
			End If

			'显示赠予的金币数量
			If PostListArray(8, i) > 0 Then
				Response.Write " <span class=""underline"">+"& PostListArray(8, i) &"</span>"
			End If

			'如果是管理员则显示真实用户名并提示
			If RQ.IsModerator And PostListArray(7, i) > 0 Then
				Response.Write "&nbsp;&nbsp;<a href=""item.asp?action=topicitem&op=anonymity&pid="& PostListArray(0, i) &""" onclick=""return shows3(this.href);"" class=""bluelink"">匿名道具</a>"
			End If

			'如果是管理员则显示管理链接
			If RQ.IsModerator Then 
				Response.Write "&nbsp;&nbsp;<a href=""pm.asp?action=send&u="& Server.URLEncode(PostListArray(2, i)) &""" onclick=""return shows(this.href);"" class=""bluelink"">传呼</a>"

				If RQ.AllowPunishUser = 1 Or RQ.AllowEditUser = 1 Then
					Response.Write "&nbsp;&nbsp;<a href=""managemember.asp?action=detail&uid="& PostListArray(1, i) &"&tid="& RQ.TopicID &""" class=""bluelink"">编辑用户</a>"
				End If

				If RQ.AllowManageTopic = 1 Then
					Response.Write "&nbsp;&nbsp;<a href=""###"" onclick=""showlightbox('editlink_"& PostListArray(0, i) &"', '?action=editpost&fid="& RQ.ForumID &"&pid="& PostListArray(0, i) &"&page="& Page &"');"" class=""bluelink"">编辑内容</a>"
				End If

				'是否允许查看用户IP
				If RQ.AllowViewIP = 1 Then
					Response.Write "&nbsp;&nbsp;<a href=""managemember.asp?query_userip="& Trim(PostListArray(6, i)) &""" style=""color:#00f;"" class=""underline"">"& Trim(PostListArray(6, i)) &"</a>"
				End If
			End If

			If i <> CountArray Then
				Response.Write RQ.Topic_Settings(6)
			End If
		Next

		If PageCount > 1 Then
			Call ShowPageInfo(Page, PageCount, RecordCount, "&action=manageposts&html="& html &"&fid="& RQ.ForumID &"&tid="& RQ.TopicID)
		End If

		Response.Write "<p><input type=""submit"" id=""btndeleteposts"" value=""删除回复(先选中回复前的复选框)"" class=""button"" /></form>"
	End If

	RQ.Footer()
End Sub

'========================================================
'显示金钱达到某数量可见内容
'========================================================
Function ShowCreditsHidden(str)
	Dim regEx, Matches, Match
	Set regEx = New Regexp
	regEx.IgnoreCase = True
	regEx.Global = True
	regEx.Pattern = "\[hide=(\d+)\](.+?)\[\/hide\]"
	Set Matches = regEx.Execute(str)
	regEx.Global = False
	For Each Match In Matches
		If RQ.UserCredits < IntCode(Match.SubMatches(0)) And Not RQ.IsModerator Then
			str = regEx.Replace(str, "<div class=""viewdenied"" style=""width: 300px;"">本帖隐藏的内容需要"& RQ.Other_Settings(0) &"达到$1才可以浏览</div>")
		Else
			str = regEx.Replace(str, "<div class=""viewdenied"">本帖隐藏的内容需要"& RQ.Other_Settings(0) &"达到$1才可以浏览：<br /><span class=""pink"">$2</span></div>")
		End If
	Next
	Set regEx = Nothing
	ShowCreditsHidden = str
End Function

'========================================================
'是否过滤HTML代码
'========================================================
Function ShowHtml(Content, switch)
	If InStr(Content, "[/hide]") > 0 Then
		'处理回复可见内容
		If InStr(Content, "[hide]") > 0 Then
			Content = Preg_Replace(Content, "\[hide\](.+?)\[\/hide\]", "<div class=""viewdenied"">本帖隐藏的内容需要回复才可以浏览：<br /><span class=""pink"">$1</span></div>")
		End If

		'金钱达到某数量可见内容
		If InStr(Content, "[hide=") > 0 Then
			Content = ShowCreditsHidden(Content)
		End If
	End If
	ShowHtml = IIF(switch = 0, strFilter(Content), Content)
End Function

'========================================================
'帖子设置
'========================================================
Sub Main()
	Dim TopicInfo, TaskInfo, OverTime
	Dim ForumListArray, AryCredits

	TopicInfo = RQ.Query("SELECT fid, typeid, displayorder, username, usershow, title, clicks, types, special, price, ifelite, iflocked, iftask, disablemodify FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID)

	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'版面编号如果不正确则跳转为正确的编号
	If TopicInfo(0, 0) <> RQ.ForumID Then
		Call closeDatabase()
		Response.Redirect "?fid="& TopicInfo(0, 0) &"&tid="& RQ.TopicID
		Response.End()
	End If

	'验证管理权限
	Call ValidatePermission()

	'如果帖子属于定期置顶则读取过期时间
	If TopicInfo(12, 0) = 1 Then
		TaskInfo = RQ.Query("SELECT expirytime FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)

		If IsArray(TaskInfo) Then
			OverTime = TaskInfo(0, 0)
		Else
			RQ.Execute("UPDATE "& TablePre &"topics SET iftask = 0 WHERE tid = "& RQ.TopicID)
		End If
	End If

	ForumListArray = RQ.Query("SELECT fid, name FROM "& TablePre &"forums WHERE fid IN("& RQ.Get_Accessable_ForumID() &") ORDER BY displayorder ASC")

	AryCredits = Array(1, 5, 10, 15, 30, 50, 80, 100, 150, 200, 250, 300, 500, 800, 1000, 1200, 1500, 1800, 2000, 2500, 5000, 9999, 100000, 1000000)

	Call closeDatabase()
	RQ.Header()
%>
<body>
<script type="text/javascript" src="js/calendar.js"></script>
<script type="text/javascript" src="js/ajax.js"></script>
<form name="edittopic" method="post" action="?action=edittopic">
  <input type="hidden" name="fid" value="<%= RQ.ForumID %>" />
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>" />
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
            <h1>编辑帖子</h1>
          </div>
          <table width="100%" cellspacing="0" cellpadding="0" class="tbborder">
            <tr>
              <td width="30%">帖子标题：</td>
              <td><input type="text" name="title" size="40" value="<%= strFilter(TopicInfo(5, 0)) %>" class="inputgrey" /></td>
            </tr>
            <tr>
              <td>所属版面：</td>
              <td><select name="newfid" id="newfid" onChange="ajax_get('managetopic.asp?action=show_typeid&fid='+ this.options[this.options.selectedIndex].value +'&typeid=<%= TopicInfo(1, 0) %>', 'show_typeid', 'GET');">
                  <% If IsArray(ForumListArray) Then %>
                  <% For i = 0 To UBound(ForumListArray, 2) %>
                  <option value="<%= ForumListArray(0, i) %>"<% If TopicInfo(0, 0) = ForumListArray(0, i) Then Response.Write " selected" End If %>><%= ForumListArray(1, i) %></option>
                  <% Next %>
                  <% End If %>
                </select>
                <span id="show_typeid"></span>
                <script type="text/javascript">ajax_get('managetopic.asp?action=show_typeid&fid=<%= TopicInfo(0, 0) %>&typeid=<%= TopicInfo(1, 0) %>', 'show_typeid');</script>
              </td>
            </tr>
            <tr>
              <td>浏览次数：</td>
              <td><input type="text" name="clicks" size="10" value="<%= TopicInfo(6, 0) %>" class="inputgrey" /></td>
            </tr>
            <tr>
              <td>真实发帖人：</td>
              <td><input type="text" name="username" size="20" value="<%= TopicInfo(3, 0) %>" class="inputgrey" /></td>
            </tr>
            <tr>
              <td>显示发帖人：</td>
              <td><input type="text" name="usershow" size="30" value="<%= strFilter(TopicInfo(4, 0)) %>" class="inputgrey" /></td>
            </tr>
            <% If RQ.AllowStickTopic = 1 Then %>
            <tr>
              <td width="20%">是否置顶：</td>
              <td><select name="displayorder" id="displayorder" onChange="javascript:if(this.options[this.options.selectedIndex].value == 0){$('p_overtime').style.display = 'none';} else{$('p_overtime').style.display = '';}">
                  <option value="0">不置顶</option>
                  <option value="1"<% If TopicInfo(2, 0) = 1 Then Response.Write " selected" End If %>>版面置顶</option>
                  <!--<option value="2"<% If TopicInfo(2, 0) = 2 Then Response.Write " selected" End If %>>分类置顶</option>-->
                  <% If InArray(Array(1, 2), RQ.AdminGroupID) Then %>
                  <option value="3"<% If TopicInfo(2, 0) = 3 Then Response.Write " selected" End If %>>全局置顶</option>
				  <% End If %>
                </select></td>
            </tr>
            <tr id="p_overtime" style="display: none;">
              <td>置顶到期时间：</td>
              <td><input type="text" name="overtime" id="overtime" size="20" value="<%= OverTime %>" class="inputgrey" onclick="calendar.showCalendar(['overtime'],['overtime'])" />
                (不填为长期)
                <script type="text/javascript">$('p_overtime').style.display = $('displayorder').value == 0 ? 'none' : '';</script></td>
            </tr>
            <% End If %>
            <tr>
              <td>看帖限制：</td>
              <td><select name="price">
                  <option value="0">看此贴应达到的最低<%= RQ.Other_Settings(0) %></option>
				  <% For i = 0 To UBound(AryCredits) %>
				  <option value="<%= AryCredits(i) %>"<% If TopicInfo(9, 0) = AryCredits(i) Then Response.Write " selected" End If %>><%= AryCredits(i) %></option>
				  <% Next %>
                </select></td>
            </tr>
            <tr>
              <td>限制回复：</td>
              <td><select name="iflocked">
                  <option value="0"<% If TopicInfo(11, 0) = 0 Then Response.Write " selected" End If %>>接受回复</option>
                  <option value="1"<% If TopicInfo(11, 0) = 1 Then Response.Write " selected" End If %>>不允许回复(楼主可开启回复)</option>
                  <option value="2"<% If TopicInfo(11, 0) = 2 Then Response.Write " selected" End If %>>不允许回复</option>
                </select></td>
            </tr>
            <tr>
              <td>限制编辑帖子/回复：</td>
              <td><select name="disablemodify">
                  <option value="0"<% If TopicInfo(13, 0) = 0 Then Response.Write " selected" End If %>>不限制</option>
                  <option value="1"<% If TopicInfo(13, 0) = 1 Then Response.Write " selected" End If %>>禁止编辑帖子</option>
                  <option value="2"<% If TopicInfo(13, 0) = 2 Then Response.Write " selected" End If %>>禁止编辑帖子和回复</option>
                </select></td>
            </tr>
            <tr>
              <td>帖子类型：</td>
              <td><select name="types">
                  <option value="0"<% If TopicInfo(7, 0) = 0 Then Response.Write " selected" End If %>>--</option>
                  <option value="1"<% If TopicInfo(7, 0) = 1 Then Response.Write " selected" End If %>>转载</option>
                  <option value="2"<% If TopicInfo(7, 0) = 2 Then Response.Write " selected" End If %>>下载</option>
                  <option value="3"<% If TopicInfo(7, 0) = 3 Then Response.Write " selected" End If %>>原创</option>
                  <option value="4"<% If TopicInfo(7, 0) = 4 Then Response.Write " selected" End If %>>召集</option>
                  <option value="5"<% If TopicInfo(7, 0) = 5 Then Response.Write " selected" End If %>>实用</option>
                </select>
                <select name="ifelite">
                  <option value="0">--</option>
                  <option value="1"<% If TopicInfo(10, 0) = 1 Then Response.Write " selected" End If %>>精彩</option>
                </select></td>
            </tr>
            <tr>
              <td>&nbsp;</td>
              <td><input type="submit" name="btnsave" value="提交设置" class="button" />
                <input type="submit" name="btnupdate" value="提升帖子" class="button" />
                <input type="button" value="删除帖子" class="button" onclick="$('p_delete').style.display = '';" /></td>
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
<br />
<form name="deletetopic" method="post" action="?action=deletetopic" onsubmit="$('btndelete').value='正在提交,请稍后...';$('btndelete').disabled=true;">
  <input type="hidden" name="fid" value="<%= RQ.ForumID %>" />
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>" />
  <table id="p_delete" class="tipsborder" cellspacing="0" cellpadding="0" align="center" style="display: none;">
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
            <h1>删除帖子</h1>
          </div>
          <table width="100%" cellspacing="0" cellpadding="0" class="tbborder">
            <tr>
              <td width="20%">删除原因:<br />
                (请务必填写好删除理由,255字内)</td>
              <td><input type="text" name="reason" size="50" class="inputgrey" /></td>
            </tr>
            <tr>
              <td width="20%">扣除<%= RQ.Other_Settings(0) %>:</td>
              <td><input type="text" name="deductcredits" size="10" class="inputgrey" /></td>
            </tr>
            <tr>
              <td width="20%">&nbsp;</td>
              <td><input type="submit" name="btndelete" id="btndelete" value="确定删除" class="button" /></td>
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
<%
	RQ.Footer()
End Sub
%>
