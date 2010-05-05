<!--#include file="wap.inc.asp"-->
<%
WapHeader()

If RQ.ForumID = 0 Then
	Call WapMessage("版面信息不正确。", "")
End If

Dim Action
Action = LCase(Request.QueryString("action"))
Select Case Action
	Case "newtopic"
		Call NewTopic()
	Case "newreply"
		Call NewReply()
	Case "reply"
		Call Reply()
	Case Else
		Call Main()
End Select
WapFooter()

'========================================================
'保存发帖
'========================================================
Sub NewTopic()
	'发帖检查当前用户状态
	Call Check_Status_Topic()

	'如果是游客则检查游客名称
	If RQ.UserID = 0 Then 
		CheckGuestAccount()
	End If

	Dim Title, Message, DisplayOrder, UserShow, UserInfo
	Dim strTips

	Title = SafeRequest(2, "title", 1, "", 0)
	If Len(CheckContent(Title)) = 0 Then
		Call WapMessage("请填写好帖子标题。", "")
	End If

	'词语过滤
	Title = WordsFilter(Title)

	If Len(Title) > IntCode(RQ.Topic_Settings(0)) Then
		Title = Left(Title, IntCode(RQ.Topic_Settings(0)))
	End If

	Message = SafeRequest(2, "message", 1, "", 0)

	'检查内容长度
	If Len(CheckContent(Message)) = 0 Then
		Call WapMessage("请填写好帖子内容。", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	If Len(Message) > IntCode(RQ.Topic_Settings(1)) And RQ.DisablePostCtrl = 0 Then
		Call WapMessage("内容太长啦，请控制在"& RQ.Topic_Settings(1) &"个字以内。目前内容字数为"& Len(Message), "")
	End If

	Message = Replace(Message, vbCrLf, "<br />")
	Message = Message &"<br /><em>(发帖时间:"& Now() &")</em><br />"

	'如果是登录用户则读取称号和签名
	If RQ.UserID > 0 Then
		UserInfo = RQ.Query("SELECT designation FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)
		If IsArray(UserInfo) Then
			'是否使用称号
			If Len(UserInfo(0, 0)) > 0 Then
				UserShow = RQ.UserName &"【"& UserInfo(0, 0) &"】"
			Else
				UserShow = RQ.UserName
			End If

			Erase UserInfo
		End If
	Else
		'游客
		UserShow = RQ.UserName
	End If

	DisplayOrder = 0

	'所在的用户组发帖是否需要审核
	If RQ.AllowDirectPost = 0 Then
		DisplayOrder = -1

	'版面发帖是否需要审核
	ElseIf RQ.F_AdultingPost = 1 And RQ.DisablePostCtrl = 0 Then 
		DisplayOrder = -1

	'整站发帖是否需要审核
	ElseIf RQ.CheckTimeSetting(RQ.Time_Settings(2)) And RQ.DisablePeriodCtrl = 0 Then 
		DisplayOrder = -1

	'标题和内容中是否有关键词需要审核
	ElseIf WordsAdulting(Title) Or WordsAdulting(Message) Then
		DisplayOrder = -1
	End If

	'如果游客可以发帖则需要验证数据库是否连接
	If Not IsObject(Conn) Then
		Call connectDatabase()
	End If

	'保存主题信息
	RQ.Execute("INSERT INTO "& TablePre &"topics (fid, typeid, displayorder, uid, username, usershow, title, types, special, price, leagueid, iflocked, ifanonymity, ifattachment) VALUES ("& RQ.ForumID &", 0, "& DisplayOrder &", "& RQ.UserID &", N'"& RQ.UserName &"', N'"& UserShow &"', N'"& Title &"', 0, 0, 0, 0, 0, 0, 0)")

	'获取主题编号
	RQ.TopicID = Conn.Execute("SELECT SCOPE_IDENTITY()")(0)
	dbQueryNum = dbQueryNum + 1

	'保存主题内容
	RQ.Execute("INSERT INTO "& TablePre &"posts (fid, tid, iffirst, uid, username, usershow, message, userip, ifanonymity, ifattachment) VALUES ("& RQ.ForumID &", "& RQ.TopicID &", 1, "& RQ.UserID &", N'"& RQ.UserName &"', N'"& UserShow &"', N'"& Message &"', '"& RQ.UserIP &"', 0, 0)")

	'更新版面主题数量统计
	If DisplayOrder = 0 Then
		RQ.Execute("UPDATE "& TablePre &"forums SET topics = topics + 1 WHERE fid = "& RQ.ForumID)
	End If

	'如果是注册用户发言，则更新用户发表的主题统计
	If RQ.UserID > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET topics = topics + 1, newtopictime = "& DateDiff("s", "1970-01-01 0:00:00", Now()) &" WHERE uid = "& RQ.UserID)
	End If

	'如果不需要审核则更新版面帖子数量统计
	If DisplayOrder = 0 Then
		Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics + 1)
	End If

	Call closeDatabase()

	If DisplayOrder = -1 Then
		strTips = "您的帖子已经发布，管理员审核后会出现在帖子列表中。"
	Else
		strTips = "您的帖子已经成功发布。"
	End If

	Call WapMessage(strTips &"<br /><a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &""">进入刚才发表的帖子</a><br /><a href=""forumdisplay.asp?fid="& RQ.ForumID &""">返回帖子列表</a>", "")
End Sub

'========================================================
'发表回复
'========================================================
Sub NewReply()
	'回帖检查当前用户状态
	Call Check_Status_Post()

	'如果是游客则检查游客名称
	If RQ.UserID = 0 Then 
		Call CheckGuestAccount()
	End If

	Dim TopicInfo, UserInfo
	Dim Message, UserShow, PostFloodCtrl, PageCount

	TopicInfo = RQ.Query("SELECT displayorder, uid, posttime, lastupdate, posts, iflocked, ifattachment FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	If Not IsArray(TopicInfo) Then
		Call WapMessage("帖子不存在或者已经被删除。", "")
	End If

	'未通过审核的帖子只有管理员和楼主可以回复
	Select Case TopicInfo(0, 0)
		Case -1
			If RQ.UserID = 0 Or (Not RQ.IsModerator And RQ.UserID <> TopicInfo(1, 0)) Then 
				Call WapMessage("该帖未待审核，请等待管理员审核帖子。", "")
			End If
		Case -2
			Call WapMessage("帖子已经被删除。", "")
	End Select

	If TopicInfo(5, 0) > 0 Then
		Call WapMessage("该帖子被设为不接受回复。", "")
	End If

	'帖子如果过期则不允许回复
	If ABS(RQ.F_AutoClose) > 0 And RQ.DisablePostCtrl = 0 Then
		If RQ.F_AutoClose < 0 Then
			If DateDiff("d", TopicInfo(2, 0), Now()) > ABS(RQ.F_AutoClose) Then
				Call WapMessage("该帖子已经过期，禁止回复。", "")
			End If
		Else
			If DateDiff("d", TopicInfo(3, 0), Now()) > RQ.F_AutoClose Then
				Call WapMessage("该帖子已经过期，禁止回复。", "")
			End If
		End If
	End If

	Message = SafeRequest(2, "message", 1, "", 0)

	'检查内容长度
	If Len(CheckContent(Message)) = 0 Then
		Call WapMessage("请填写好回复内容。", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	'提交内容长度验证
	If Len(Message) > IntCode(RQ.Topic_Settings(1)) And RQ.DisablePostCtrl = 0 Then
		Call WapMessage("内容太长啦，请控制在"& RQ.Topic_Settings(1) &"个字以内。目前内容字数为"& Len(Message), "")
	End If

	'回复防灌水识别
	If Len(CheckContent(Message)) < IntCode(RQ.Topic_Settings(9)) And IntCode(RQ.Topic_Settings(10)) > 0 Then
		PostFloodCtrl = DatetoNum(DateAdd("n", IntCode(RQ.Topic_Settings(10)), Now()))
	Else
		PostFloodCtrl = 0
	End If

	Message = Replace(Message, vbCrLf, "<br />")

	'在回复中显示的名称(匿名、称号、正常)
	If RQ.UserID > 0 Then
		UserInfo = RQ.Query("SELECT designation FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)
		If IsArray(UserInfo) Then
			'是否使用称号
			If Len(UserInfo(0, 0)) > 0 Then
				UserShow = RQ.UserName &"【"& UserInfo(0, 0) &"】"
			Else
				UserShow = RQ.UserName
			End If

			Erase UserInfo
		End If
	Else
		'游客
		UserShow = RQ.UserName
	End If

	'保存回复内容
	RQ.Execute("INSERT INTO "& TablePre &"posts(fid, tid, uid, username, usershow, message, userip, ifanonymity, ratemark, ifattachment) VALUES("& RQ.ForumID &", "& RQ.TopicID &", "& RQ.UserID &", N'"& RQ.UserName &"', N'"& UserShow &"', N'"& Message &"', '"& RQ.UserIP &"', 0, 0, 0)")

	'更新帖子回复数量; 是否更新帖子
	RQ.Execute("UPDATE "& TablePre &"topics SET lastupdate = GETDATE(), posts = posts + 1 WHERE tid = "& RQ.TopicID)

	'更新版面回帖数量统计
	RQ.Execute("UPDATE "& TablePre &"forums SET posts = posts + 1 WHERE fid = "& RQ.ForumID)

	'更新用户回帖统计; 是否回帖灌水
	If RQ.UserID > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET postfloodctrl = "& PostFloodCtrl &", posts = posts + 1 WHERE uid = "& RQ.UserID)
	End If

	'获取回复帖子后的跳转页数
	PageCount = ABS(Int(-(TopicInfo(4, 0) / IntCode(RQ.Topic_Settings(4)))))

	Call closeDatabase()
	Call WapMessage("您的回复已经成功发布。<br /><a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;page="& PageCount &""">进入刚才发表的帖子</a><br /><a href=""forumdisplay.asp?fid="& RQ.ForumID &""">返回帖子列表</a>", "")
End Sub

'========================================================
'发帖检查用户状态和版面状态
'========================================================
Sub Check_Status_Topic()
	'用户组是否能够发帖
	If RQ.AllowPost = 0 Then
		Call WapMessage("您现在的身份（"& RQ.UserGroupName &"）还不能发帖子哟。", "")
	End If

	'用户组是否有本版的发帖权限
	If Len(RQ.Forum_PostTopicPerm) = 0 Then
		If RQ.UserID = 0 Then
			Call WapMessage("登录之后才能发帖。", "")
		End If
	Else
		If Not InStr(","& RQ.Forum_PostTopicPerm &",", ","& RQ.UserGroupID &",") > 0 Then
			Call WapMessage("您现在的身份（"& RQ.UserGroupName &"）还不能在本版发帖子哟。", "")
		End If

		'版面是否设置了金钱达到某一数值才能发帖
		If RQ.F_PostNdCredits > 0 And RQ.UserCredits < RQ.F_PostNdCredits And RQ.DisablePostCtrl = 0 Then 
			Call WapMessage(RQ.Other_Settings(0) &"达到"& RQ.F_PostNdCredits &"就可以发帖了哟，加油！", "")
		End If
	End If

	'版面只读
	If RQ.F_AllowPost = 0 And RQ.DisablePostCtrl = 0 Then
		Call WapMessage("当前版面为只读状态……", "")
	End If

	'整站只读
	If RQ.CheckTimeSetting(RQ.Time_Settings(1)) And RQ.DisablePeriodCtrl = 0 Then
		Call WapMessage("在以下的时间段里，论坛处于只读状态:<br />"& Replace(RQ.Time_Settings(1), "_", "<br />"), "")
	End If

	'发帖防灌水控制
	If DateDiff("s", NumtoDate(RQ.UserNewTopicTime), Now()) < IntCode(RQ.Topic_Settings(8)) * 60 And RQ.DisablePostCtrl = 0 Then
		Call WapMessage("再等"& IntCode(RQ.Topic_Settings(8)) * 60 - DateDiff("s", NumtoDate(RQ.UserNewTopicTime), Now()) &"秒钟就可以继续发帖啦。", "")
	End If
End Sub

'========================================================
'回帖检查用户状态和版面状态
'========================================================
Sub Check_Status_Post()
	'用户组是否能够回帖
	If RQ.AllowReply = 0 Then
		Call WapMessage("您现在的身份（"& RQ.UserGroupName &"）还不能回帖子哟。", "")
	End If

	'用户组是否有本版的回帖权限
	If Len(RQ.Forum_PostReplyPerm) = 0 Then
		If RQ.UserID = 0 Then
			Call WapMessage("您现在是游客，登录之后才能回帖。", "")
		End If
	Else
		If Not InStr(","& RQ.Forum_PostReplyPerm &",", ","& RQ.UserGroupID &",") > 0 Then
			Call WapMessage("您现在的身份（"& RQ.UserGroupName &"）还不能在本版回帖哟。", "")
		End If
	End If

	'版面是否设置了金钱达到某一数值才能回帖
	If RQ.F_ReplyNdCredits > 0 And RQ.UserCredits < RQ.F_ReplyNdCredits And RQ.DisablePostCtrl = 0 Then 
		Call WapMessage(RQ.Other_Settings(0) &"达到"& RQ.F_ReplyNdCredits &"就可以回帖了哟，加油！", "")
	End If

	'版面只读
	If RQ.F_AllowPost = 0 And RQ.DisablePostCtrl = 0 Then
		Call WapMessage("当前版面为只读状态……", "")
	End If

	'整站只读
	If RQ.CheckTimeSetting(RQ.Time_Settings(1)) And RQ.DisablePeriodCtrl = 0 Then
		Call WapMessage("在以下的时间段里，论坛处于只读状态：<br />"& Replace(RQ.Time_Settings(1), "_", "<br />"), "")
	End If

	'回帖防灌水控制
	If IntCode(RQ.Topic_Settings(10)) > 0 And DateDiff("s", NumtoDate(RQ.UserPostFloodCtrl), Now()) < 0 And RQ.DisablePostCtrl = 0 Then
		Call WapMessage("现在的时间是："& Now() &"，允许回帖的时间是："& NumtoDate(RQ.UserPostFloodCtrl) &"，请先看看别的帖子……", "")
	End If
End Sub

'========================================================
'回帖界面
'========================================================
Sub Reply()
	Call Check_Status_Topic()

	Dim TopicInfo
	TopicInfo = RQ.Query("SELECT displayorder, uid, posttime, lastupdate, iflocked FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)
	
	Call closeDatabase()

	If Not IsArray(TopicInfo) Then
		Call WapMessage("帖子不存在或者已经被删除。", "")
	End If

	'未通过审核的帖子只有管理员和楼主可以回复
	Select Case TopicInfo(0, 0)
		Case -1
			If RQ.UserID = 0 Or (Not RQ.IsModerator And RQ.UserID <> TopicInfo(1, 0)) Then 
				Call WapMessage("该帖未待审核，请等待管理员审核帖子。", "")
			End If
		Case -2
			Call WapMessage("帖子已经被删除。", "")
	End Select

	If TopicInfo(4, 0) > 0 Then
		Call WapMessage("该帖子被设为不接受回复。", "")
	End If

	'帖子如果过期则不允许回复
	If ABS(RQ.F_AutoClose) > 0 And RQ.DisablePostCtrl = 0 Then
		If RQ.F_AutoClose < 0 Then
			If DateDiff("d", TopicInfo(2, 0), Now()) > ABS(RQ.F_AutoClose) Then
				Call WapMessage("该帖子已经过期，禁止回复。", "")
			End If
		Else
			If DateDiff("d", TopicInfo(3, 0), Now()) > RQ.F_AutoClose Then
				Call WapMessage("该帖子已经过期，禁止回复。", "")
			End If
		End If
	End If

	Call Append("内容:<input type=""text"" name=""message"" value="""" format=""M*m"" /><br /><anchor title=""提交"">提交<go method=""post"" href=""post.asp?action=newreply&amp;fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"""><postfield name=""message"" value=""$(message)"" /></go></anchor><br /><br /><a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &""">返回帖子</a><br /><a href=""forumdisplay.asp?fid="& RQ.ForumID &""">返回版块</a>")
End Sub

'========================================================
'发帖界面
'========================================================
Sub Main()
	Call Check_Status_Topic()
	Call closeDatabase()

	Call Append("标题:<input type=""text"" name=""title"" value="""" maxlength=""80"" format=""M*m"" /><br />内容:<input type=""text"" name=""message"" value="""" format=""M*m"" /><br /><anchor title=""提交"">提交<go method=""post"" href=""post.asp?action=newtopic&amp;fid="& RQ.ForumID &"""><postfield name=""title"" value=""$(title)"" /><postfield name=""message"" value=""$(message)"" /></go></anchor><br /><br /><a href=""forumdisplay.asp?fid="& RQ.ForumID &""">返回版块</a>")
End Sub
%>