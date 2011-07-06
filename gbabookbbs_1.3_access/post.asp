<!--#include file="include/inc.asp"-->
<%
If RQ.ForumID = 0 Then
	Call RQ.showTips("版面不存在或者已经被删除。", "", "")
End If

Dim Action
Dim gblAnonymityResult

Action = Request.QueryString("action")
gblAnonymityResult = 0

Select Case Action
	Case "newtopic"
		Call NewTopic()
	Case "newreply"
		Call NewReply()
	Case "gettopictype"
		Call GetTopicType()
	Case Else
		Call Main()
End Select

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

	Dim TypeID, Title, Message, AboutLink, ImgLink, Types, IfLocked, Disable_Autowap, Face
	Dim IfParseURL, LeagueJoinID, IfAnonymity, Price, DisplayOrder, IfAttachment
	Dim Special, PollOptions, ValidDate, Multiple, MaxChoices, Visible, n
	Dim Temp_AboutLink, Temp_ImgLink, UserShow, UserInfo, TypeInfo, LeagueInfo, LeagueID
	Dim NewPostID

	TypeID = SafeRequest(2, "typeid", 0, 0, 0)

	'验证是否为正确的帖子分类
	If TypeID > 0 Then
		TypeInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topictypes WHERE fid = "& RQ.ForumID &" AND typeid = "& TypeID)
		If Not IsArray(TypeInfo) Then
			TypeID = 0
		End If
	End If

	If RQ.F_ChooseTopicType = 1 And TypeID = 0 Then
		Call RQ.showTips("请选择好帖子分类。", "", "")
	End If

	Title = SafeRequest(2, "title", 1, "", 0)
	If Len(CheckContent(Title)) = 0 Then
		Call RQ.showTips("请填写好帖子标题。", "", "")
	End If

	'词语过滤
	Title = WordsFilter(Title)

	If Len(Title) > IntCode(RQ.Topic_Settings(0)) Then
		Title = Left(Title, IntCode(RQ.Topic_Settings(0)))
	End If

	'是否允许使用HTML
	If RQ.blnAllowHTML(0) Then
		Message = SafeRequest(2, "message", 1, "", 1)
	Else
		Message = SafeRequest(2, "message", 1, "", 0)
	End If

	'检查内容长度
	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写好帖子内容。", "", "")
	End If

	If Len(Message) > IntCode(RQ.Topic_Settings(1)) And RQ.DisablePostCtrl = 0 Then
		Call RQ.showTips("内容太长啦，请控制在"& RQ.Topic_Settings(1) &"个字以内。目前内容字数为"& Len(Message), "", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	'识别网址和图片
	IfParseURL = SafeRequest(2, "ifparseurl", 0, 0, 0)
	If IfParseURL = 1 Then
		Message = ParseURL(Message)
	End If

	'帖子内容是否换行
	Disable_Autowap = SafeRequest(2, "disable_autowap", 0, 0, 0)
	If Disable_Autowap = 0 Then 
		Message = Replace(Message, vbCrLf, "<br />")
	Else
		Message = Replace(Replace(Message, Chr(10), ""), Chr(13), "")
	End If

	'投票帖处理
	Special = SafeRequest(2, "special", 0, 0, 0)
	If Special = 1 Then
		If RQ.F_AllowPollTopic = 0 Or RQ.AllowPostPoll = 0 Then
			Call RQ.showTips("您还不能发表投票帖子。", "", "")
		End If

		PollOptions = SafeRequest(2, "polloptions", 1, "", 0)
		ValidDate = SafeRequest(2, "validdate", 0, 0, 0)
		Multiple = SafeRequest(2, "multiple", 0, 0, 0)
		MaxChoices = SafeRequest(2, "maxchoices", 0, 1, 0)
		Visible = SafeRequest(2, "visible", 0, 0, 0)

		PollOptions = Split(PollOptions, vbCrLf)
		For i = 0 To UBound(PollOptions)
			If Len(CheckContent(PollOptions(i))) > 0 Then
				n = n + 1
			End If
		Next

		If n < 2 Or n > 40 Then
			Call RQ.showTips("请填写好投票选项，选项数量控制在2-40个之间。", "", "")
		End If

		If ValidDate > 0 Then
			If ValidDate > 3650 Then
				ValidDate = 0
			Else
				ValidDate = DatetoNum(DateAdd("d", ValidDate, Now()))
			End If
		End If

		Multiple = IIF(Multiple > 1, 0, Multiple)

		If Multiple = 0 Then
			MaxChoices = 1
		ElseIf MaxChoices = 1 Then
			Multiple = 0
		ElseIf MaxChoices > 40 Then
			MaxChoices = 40
		End If

		Visible = IIF(Visible > 1, 0, Visible)
	End If

	Types = SafeRequest(2, "types", 0, 0, 0)
	Types = IIF(Types > 5, 0, Types)

	Select Case Types
		Case 1
			Title = Title &"【转载】"
		Case 2
			Title = Title &"【下载】"
		Case 3
			Title = Title &"【原创】"
		Case 4
			Title = Title &"【召集】"
		Case 5
			Title = Title &"【实用】"
	End Select

	IfLocked = SafeRequest(2, "iflocked", 0, 0, 0)
	IfLocked = IIF(IfLocked > 1, 0, IfLocked)

	'表情
	Face = SafeRequest(2, "face1", 0, 0, 0) & SafeRequest(2, "face2", 0, 0, 0) & SafeRequest(2, "face3", 0, 0, 0)
	If Face > 0 And Face < 1000 Then
		Message = Message & "<img src=""face/"& Face &".gif"" /><br />"
	End If

	'Message = Message &"<br /><em>(发帖时间:"& Now() &")</em><br />"

	Temp_AboutLink = SafeRequest(2, "aboutlink", 1, "", 0)
	Temp_ImgLink = SafeRequest(2, "imglink", 1, "", 0)

	'相关链接
	If Len(Temp_AboutLink) > 0 And Temp_AboutLink <> "http://" Then
		Temp_AboutLink = Split(Temp_AboutLink, ",")
		For i = 0 To UBound(Temp_AboutLink)
			AboutLink = AboutLink & "<a href="""& Temp_AboutLink(i) &""" target=""_blank"" class=""underline""><em>"& Temp_AboutLink(i) &"</em></a><br />"
		Next
		Message = Message &"<br /><em>相关地址</em><br />"& AboutLink
	End If

	'相关图片
	If Len(Temp_ImgLink) > 0 And Temp_ImgLink <> "http://" Then
		Temp_ImgLink = Split(Temp_ImgLink, ",")
		For i = 0 To UBound(Temp_ImgLink)
			ImgLink = ImgLink & "<img src="""& Temp_ImgLink(i) &""" /><br />"
		Next
		Message = Message & "<br />"& ImgLink
	End If

	LeagueJoinID = SafeRequest(2, "leaguejoinid", 0, 0, 0)
	IfAnonymity = SafeRequest(2, "ifanonymity", 0, 0, 0)

	'在帖子中显示的名称(匿名、称号、正常)
	If IfAnonymity = 1 And RQ.UserID > 0 And (RQ.UserCredits >= RQ.F_AnonymityNdCredits Or RQ.F_AnonymityNdCredits = 0) And (IntCode(RQ.Topic_Settings(11)) = 0 Or RQ.UserCredits >= IntCode(RQ.Topic_Settings(11))) Then
		UserShow = Get_AnonymityText()
	Else
		'如果是登录用户则读取称号和签名
		If RQ.UserID > 0 Then
			UserInfo = RQ.Query("SELECT designation, signature FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)
			If IsArray(UserInfo) Then
				'是否使用称号
				If Len(UserInfo(0, 0)) > 0 Then
					UserShow = RQ.UserName &"【"& UserInfo(0, 0) &"】"
				Else
					UserShow = RQ.UserName
				End If

				'是否使用签名
				If Len(UserInfo(1, 0)) > 0 Then	
					Message = Message & "<div class=""signature"">"& UserInfo(1, 0) &"</div>"
				End If

				Erase UserInfo
			End If
		Else
			'游客
			UserShow = RQ.UserName
		End If
	End If

	Price = SafeRequest(2, "price", 0, 0, 0)
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

	'是否有附件上传
	IfAttachment = IIF(Len(NumberGroupFilter(SafeRequest(2, "newaid", 1, "", 0))) > 0 And RQ.AllowPostAttach, 1, 0)

	'如果游客可以发帖则需要验证数据库是否连接
	If Not IsObject(Conn) Then
		Call connectDatabase()
	End If

	LeagueID = 0
	'是否是联盟贴
	If LeagueJoinID > 0 And RQ.UserID > 0 Then
		LeagueInfo = RQ.Query("SELECT lm.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.joinid = "& LeagueJoinID)
		If IsArray(LeagueInfo) Then
			If Len("【"& LeagueInfo(1, 0) &"】"& Title) <= 255 Then
				Title = "【"& LeagueInfo(1, 0) &"】"& Title
			End If
			LeagueID = LeagueInfo(0, 0)
		End If
	End If

	'保存主题信息
	RQ.Execute("INSERT INTO "& TablePre &"topics (fid, typeid, displayorder, uid, username, usershow, title, types, special, price, leagueid, iflocked, ifanonymity, ifattachment) VALUES ("& RQ.ForumID &", "& TypeID &", "& DisplayOrder &", "& RQ.UserID &", '"& RQ.UserName &"', '"& UserShow &"', '"& Title &"', "& Types &", "& Special &", "& Price &", "& LeagueID &", "& IfLocked &", "& gblAnonymityResult &", "& IfAttachment &")")

	'获取主题编号
	RQ.TopicID = Conn.Execute("SELECT MAX(tid) FROM "& TablePre &"topics")(0)
	dbQueryNum = dbQueryNum + 1

	'保存主题内容
	RQ.Execute("INSERT INTO "& TablePre &"posts (fid, tid, iffirst, uid, username, usershow, message, userip, ifanonymity, ifattachment) VALUES ("& RQ.ForumID &", "& RQ.TopicID &", 1, "& RQ.UserID &", '"& RQ.UserName &"', '"& UserShow &"', '"& Message &"', '"& RQ.UserIP &"', "& gblAnonymityResult &", "& IfAttachment &")")

	'获取回复编号
	NewPostID = Conn.Execute("SELECT MAX(pid) FROM "& TablePre &"posts")(0)
	dbQueryNum = dbQueryNum + 1

	'如果是联盟贴则记录联盟相关信息
	If LeagueID > 0 Then
		RQ.Execute("INSERT INTO "& TablePre &"leaguetopics (leagueid, tid) VALUES ("& LeagueID &", "& RQ.TopicID &")")
		RQ.Execute("INSERT INTO "& TablePre &"leaguelogs (leagueid, username, operation) VALUES ("& LeagueID &", '"& RQ.UserName &"', '<b>"& Title &"</b>("& RQ.UserIP &")')")
		RQ.Execute("UPDATE "& TablePre &"leagues SET topics = topics + 1 WHERE leagueid = "& LeagueID)
	End If

	'更新版面主题数量统计
	If DisplayOrder = 0 Then
		RQ.Execute("UPDATE "& TablePre &"forums SET topics = topics + 1 WHERE fid = "& RQ.ForumID)
	End If

	'如果是注册用户发言，则更新用户发表的主题统计
	If RQ.UserID > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET topics = topics + 1, newtopictime = "& DateDiff("s", "1970-01-01 0:00:00", Now()) &" WHERE uid = "& RQ.UserID)
	End If

	'保存投票帖信息
	If Special = 1 Then
		RQ.Execute("INSERT INTO "& TablePre &"polls (tid, multiple, visible, maxchoices, expirytime) VALUES ("& RQ.TopicID &", "& Multiple &", "& Visible &", "& MaxChoices &", "& ValidDate &")")
		For i = 0 To UBound(PollOptions)
			If Len(CheckContent(PollOptions(i))) > 0 Then
				PollOptions(i) = IIF(Len(PollOptions(i)) > 100, Left(PollOptions(i), 100), PollOptions(i))
				RQ.Execute("INSERT INTO "& TablePre &"polloptions (tid, title) VALUES ("& RQ.TopicID &", '"& PollOptions(i) &"')")
			End If
		Next
	End If

	'如果有附件上传则更新附件信息
	If IfAttachment = 1 And RQ.AllowPostAttach Then
		Call UpdateAttach(NewPostID)
	End If

	'如果不需要审核则更新版面帖子数量统计
	If DisplayOrder = 0 Then
		Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics + 1)
	End If

	Call closeDatabase()

	If DisplayOrder = -1 Then
		Call RQ.showTips("您的帖子已经发布，<strong>管理员审核后会出现在左边帖子列表</strong>", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& RQ.TopicID, "")
	Else
		Call RQ.showTips("您的帖子已经发布，现在将进入帖子。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& RQ.TopicID, "")
	End If
End Sub

'========================================================
'更新附件信息
'========================================================
Sub UpdateAttach(pid)
	Dim NewAttachID, NewDescription
	If Request.Form("newaid").Count > 0 Then
		For i = 1 To Request.Form("newaid").Count
			NewAttachID = IntCode(Request.Form("newaid")(i))
			NewDescription = strFilter(Request.Form("newdescription")(i))
			NewDescription = IIF(Len(NewDescription) > 255, Left(NewDescription, 255), NewDescription)
			If NewAttachID > 0 Then
				RQ.Execute("UPDATE "& TablePre &"attachments SET tid = "& RQ.TopicID &", pid = "& pid &", description = '"& NewDescription &"' WHERE aid = "& NewAttachID &" AND uid = "& RQ.UserID)
			End If
		Next
	End If
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

	Dim TopicInfo, UserInfo, AuthorInfo
	Dim Message, Quot_Message, AboutLink, ImgLink, IfAnonymity, Face, Disable_Autowap, Disable_Update, IfParseURL, SendCredits
	Dim Temp_AboutLink, Temp_ImgLink, UserShow, PostFloodCtrl, PageCount, NewAttachID, NewDescription, IfAttachment
	Dim Cmd, NewPostID, TargetUserName, CurrentUserName

	TopicInfo = RQ.Query("SELECT displayorder, uid, username, usershow, posttime, lastupdate, posts, iflocked, ifanonymity, ifattachment FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND fid = "& RQ.ForumID)

	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子不存在或者已经被删除。", "", "")
	End If

	'未通过审核的帖子只有管理员和楼主可以回复
	Select Case TopicInfo(0, 0)
		Case -1
			If RQ.UserID = 0 Or (Not RQ.IsModerator And RQ.UserID <> TopicInfo(1, 0)) Then
				Call RQ.showTips("该帖未待审核，请等待管理员审核帖子。", "", "NOPERM")
			End If
		Case -2
			Call RQ.showTips("帖子已经被删除。", "", "")
	End Select

	If TopicInfo(7, 0) > 0 Then
		Call RQ.showTips("该帖子被设为不接受回复。", "", "")
	End If

	'帖子如果过期则不允许回复
	If ABS(RQ.F_AutoClose) > 0 And RQ.DisablePostCtrl = 0 Then
		If RQ.F_AutoClose < 0 Then
			If DateDiff("d", TopicInfo(4, 0), Now()) > ABS(RQ.F_AutoClose) Then
				Call RQ.showTips("该帖子已经过期，禁止回复。", "", "")
			End If
		Else
			If DateDiff("d", TopicInfo(5, 0), Now()) > RQ.F_AutoClose Then
				Call RQ.showTips("该帖子已经过期，禁止回复。", "", "")
			End If
		End If
	End If

	'是否允许使用HTML
	If RQ.blnAllowHTML(0) Then
		Message = SafeRequest(2, "message", 1, "", 1)
	Else
		Message = SafeRequest(2, "message", 1, "", 0)
	End If

	'检查内容长度
	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写好回复内容。", "", "")
	End If

	'提交内容长度验证
	If Len(Message) > IntCode(RQ.Topic_Settings(1)) And RQ.DisablePostCtrl = 0 Then
		Call RQ.showTips("内容太长啦，请控制在"& RQ.Topic_Settings(1) &"个字以内。目前内容字数为"& Len(Message), "", "")
	End If

	'词语过滤
	Message = WordsFilter(Message)

	'回复防灌水识别
	If Len(CheckContent(Message)) < IntCode(RQ.Topic_Settings(9)) And IntCode(RQ.Topic_Settings(10)) > 0 Then
		PostFloodCtrl = DatetoNum(DateAdd("n", IntCode(RQ.Topic_Settings(10)), Now()))
	Else
		PostFloodCtrl = 0
	End If

	'识别网址和图片
	IfParseURL = SafeRequest(2, "ifparseurl", 0, 0, 0)
	If IfParseURL = 1 And RQ.UserID > 0 Then
		Message = ParseURL(Message)
	End If

	'是否自动换行
	Disable_Autowap = SafeRequest(2, "disable_autowap", 0, 0, 0)
	If Disable_Autowap = 0 Then 
		Message = Replace(Message, vbCrLf, "<br />")
	Else
		Message = Replace(Replace(Message, Chr(10), ""), Chr(13), "")
	End If

	'引用回复
	Quot_Message = SafeRequest(2, "quot_message", 1, "", 1)
	If Len(Quot_Message) > 0 Then
		Message = Quot_Message & Message
	End If

	'表情
	Face = SafeRequest(2, "face1", 0, 0, 0) & SafeRequest(2, "face2", 0, 0, 0) & SafeRequest(2, "face3", 0, 0, 0)
	If Face > 0 And Face < 1000 Then
		Message = Message & "<img src=""face/"& Face &".gif"" /><br />"
	End If

	Temp_AboutLink = SafeRequest(2, "aboutlink", 1, "", 0)
	Temp_ImgLink = SafeRequest(2, "imglink", 1, "", 0)

	'相关链接
	If Len(Temp_AboutLink) > 0 And Temp_AboutLink <> "http://" Then
		Temp_AboutLink = Split(Temp_AboutLink, ",")
		For i = 0 To UBound(Temp_AboutLink)
			AboutLink = AboutLink & "<a href="""& Temp_AboutLink(i) &""" target=""_blank"" class=""underline"">"& Temp_AboutLink(i) &"</a> &nbsp;"
		Next
		Message = Message &"<br />相关地址: "& AboutLink
	End If

	'相关图片
	If Len(Temp_ImgLink) > 0 And Temp_ImgLink <> "http://" Then
		Temp_ImgLink = Split(Temp_ImgLink, ",")
		For i = 0 To UBound(Temp_ImgLink)
			ImgLink = ImgLink & "<img src="""& Temp_ImgLink(i) &""" /><br />"
		Next
		Message = Message & "<br />"& ImgLink
	End If

	IfAnonymity = SafeRequest(2, "ifanonymity", 0, 0, 0)

	'在回复中显示的名称(匿名、称号、正常)
	If IfAnonymity = 1 And RQ.UserID > 0 And (RQ.UserCredits > RQ.F_AnonymityNdCredits Or RQ.F_AnonymityNdCredits = 0) And (IntCode(RQ.Topic_Settings(11)) = 0 Or RQ.UserCredits >= IntCode(RQ.Topic_Settings(11))) Then
		UserShow = Get_AnonymityText()
	Else
		'如果是登录用户则读取称号和签名
		If RQ.UserID > 0 Then
			UserInfo = RQ.Query("SELECT designation, signature FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)
			If IsArray(UserInfo) Then

				'是否使用称号
				If Len(UserInfo(0, 0)) > 0 Then
					UserShow = RQ.UserName &"【"& UserInfo(0, 0) &"】"
				Else
					UserShow = RQ.UserName
				End If
				
				'是否使用签名
				If Len(UserInfo(1, 0)) > 0 Then	
					Message = Message & "<div class=""signature"">"& UserInfo(1, 0) &"</div>"
				End If

				Erase UserInfo
			End If
		Else
			'游客
			UserShow = RQ.UserName
		End If
	End If

	'不UP
	Disable_Update = SafeRequest(2, "disable_update", 0, 0, 0)
	Disable_Update = IIF(Disable_Update > 1, 0, Disable_Update)

	'回帖赠送金钱
	SendCredits = SafeRequest(2, "sendcredits", 0, 0, 0)
	If SendCredits > 0 And TopicInfo(1, 0) > 0 And RQ.UserID > 0 Then
		'查询楼主信息
		AuthorInfo = RQ.Query("SELECT credits FROM "& TablePre &"members WHERE uid = "& TopicInfo(1, 0))
		If IsArray(AuthorInfo) Then
			'扣除当前回复人金钱
			RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& SendCredits &" WHERE uid = "& RQ.UserID)

			'判断发帖人是否匿名
			TargetUserName = IIF(TopicInfo(8, 0) > 0, TopicInfo(3, 0), TopicInfo(2, 0))

			CurrentUserName = RQ.UserName

			'判断当前回复人是否匿名
			If gblAnonymityResult = 1 Then
				RQ.UserName = UserShow
			End If

			'记录异动报告
			If RQ.UserCredits < SendCredits Or AuthorInfo(0, 0) < IntCode(RQ.User_Settings(7)) Then
				Call RQ.SetLog(TopicInfo(1, 0), TargetUserName, "丢失"& RQ.Other_Settings(0) & SendCredits &"点", "回复转让"& RQ.Other_Settings(0) &"失败")
			Else
				RQ.Execute("UPDATE "& TablePre &"members SET credits = credits + "& SendCredits &" WHERE uid = "& TopicInfo(1, 0))
				Call RQ.SetLog(TopicInfo(1, 0), TargetUserName, "转让"& RQ.Other_Settings(0) & SendCredits &"点", "好帖赠送"& RQ.Other_Settings(0))
			End If

			RQ.UserName = CurrentUserName
		End If
	End If

	'是否有附件上传
	IfAttachment = IIF(Len(NumberGroupFilter(SafeRequest(2, "newaid", 1, "", 0))) > 0 And RQ.AllowPostAttach, 1, 0)

	'保存回复内容
	RQ.Execute("INSERT INTO "& TablePre &"posts(fid, tid, uid, username, usershow, message, userip, ifanonymity, ratemark, ifattachment) VALUES("& RQ.ForumID &", "& RQ.TopicID &", "& RQ.UserID &", '"& RQ.UserName &"', '"& UserShow &"', '"& Message &"', '"& RQ.UserIP &"', "& gblAnonymityResult &", "& SendCredits &", "& IfAttachment &")")

	'获取回复编号
	NewPostID = Conn.Execute("SELECT MAX(pid) FROM "& TablePre &"posts")(0)

	If IfAttachment = 0 Then
		IfAttachment = TopicInfo(6, 0)
	End If

	'更新帖子回复数量; 是否更新帖子
	If Disable_Update = 1 Then
		RQ.Execute("UPDATE "& TablePre &"topics SET posts = posts + 1, ifattachment = "& IfAttachment &" WHERE tid = "& RQ.TopicID)
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET lastupdate = #"& Now() &"#, posts = posts + 1, ifattachment = "& IfAttachment &" WHERE tid = "& RQ.TopicID)
	End If

	'更新版面回帖数量统计
	RQ.Execute("UPDATE "& TablePre &"forums SET posts = posts + 1 WHERE fid = "& RQ.ForumID)

	'更新用户回帖统计; 是否回帖灌水
	If RQ.UserID > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET postfloodctrl = "& PostFloodCtrl &", posts = posts + 1 WHERE uid = "& RQ.UserID)
	End If

	'如果有附件上传则更新附件信息
	If IfAttachment = 1 And RQ.AllowPostAttach Then
		Call UpdateAttach(NewPostID)
	End If

	'获取回复帖子后的跳转页数
	PageCount = ABS(Int(-((TopicInfo(4, 0) + 1) / IntCode(RQ.Topic_Settings(4)))))

	Call closeDatabase()
	Call RQ.showTips("您的回复已经发布，现在将进入帖子。", "viewtopic.asp?fid="& RQ.ForumID &"&tid="& RQ.TopicID &"&page="& PageCount &"#pid"& NewPostID, "")
End Sub

'========================================================
'游客发言检查用户名
'========================================================
Sub CheckGuestAccount()
	Dim UserName

	UserName = IIF(Len(RQ.UserName) > 0, RQ.UserName, SafeRequest(2, "username", 1, "", 0))
	UserName = CheckContent(UserName)

	If Len(UserName) = 0 Or Len(UserName) > 10 Then
		Call RQ.showTips("游客请填写好名字再提交，字符长度请控制在10个字符以内。", "", "")
	End If

	If RegExpTest("[%,#;:&\*\""\s\n\\\|\/\^]", UserName) Then
		Call RQ.showTips("用户名中包含非法字符，请重新输入。", "", "")
	End If

	If Len(RQ.Login_Settings(2)) > 0 And RegExpTest("^"& Replace(Replace(RQ.Login_Settings(2), vbCrLf, "|"), "*", ".*") &"$", UserName) Then
		Call RQ.showTips("用户名中包含系统保留字符，请重新输入。", "", "")
	End If

	'词语过滤
	UserName = WordsFilter(UserName)

	Response.Cookies(CacheName &"un") = UserName
	Response.Cookies(CacheName &"un").Expires = Date() + 1

	RQ.UserName = UserName
End Sub

'========================================================
'发帖检查用户状态和版面状态
'========================================================
Sub Check_Status_Topic()
	'用户组是否能够发帖
	If RQ.AllowPost = 0 Then
		Call RQ.showTips("您现在的身份（"& RQ.UserGroupName &"）还不能发帖子哟。", "", "NOPERM")
	End If

	'用户组是否有本版的发帖权限
	If Len(RQ.Forum_PostTopicPerm) = 0 Then
		If RQ.UserID = 0 Then
			Call RQ.showTips("登录之后才能发帖。", "", "NOPERM")
		End If
	Else
		If Not InStr(","& RQ.Forum_PostTopicPerm &",", ","& RQ.UserGroupID &",") > 0 Then
			Call RQ.showTips("您现在的身份（"& RQ.UserGroupName &"）还不能在本版发帖子哟。", "", "NOPERM")
		End If

		'版面是否设置了金钱达到某一数值才能发帖
		If RQ.F_PostNdCredits > 0 And RQ.UserCredits < RQ.F_PostNdCredits And RQ.DisablePostCtrl = 0 Then 
			Call RQ.showTips(RQ.Other_Settings(0) &"达到"& RQ.F_PostNdCredits &"就可以发帖了哟，加油！", "", "")
		End If
	End If

	'整站只读
	If RQ.CheckTimeSetting(RQ.Time_Settings(1)) And RQ.DisablePeriodCtrl = 0 Then
		Call RQ.showTips("在以下的时间段里，论坛处于只读状态:<br />"& Replace(RQ.Time_Settings(1), "_", "<br />"), "", "NOPERM")
	End If

	'版面只读
	If RQ.F_AllowPost = 0 And RQ.DisablePostCtrl = 0 Then
		Call RQ.showTips("当前版面为只读状态……", "", "NOPERM")
	End If

	'发帖防灌水控制
	If DateDiff("s", NumtoDate(RQ.UserNewTopicTime), Now()) < IntCode(RQ.Topic_Settings(8)) * 60 And RQ.DisablePostCtrl = 0 Then
		Call RQ.showTips("再等"& IntCode(RQ.Topic_Settings(8)) * 60 - DateDiff("s", NumtoDate(RQ.UserNewTopicTime), Now()) &"秒钟就可以继续发帖啦。", "", "")
	End If
End Sub

'========================================================
'回帖检查用户状态和版面状态
'========================================================
Sub Check_Status_Post()
	'用户组是否能够回帖
	If RQ.AllowReply = 0 Then
		Call RQ.showTips("您现在的身份（"& RQ.UserGroupName &"）还不能回帖子哟。", "", "NOPERM")
	End If

	'用户组是否有本版的回帖权限
	If Len(RQ.Forum_PostReplyPerm) = 0 Then
		If RQ.UserID = 0 Then
			Call RQ.showTips("您现在是游客，登录之后才能回帖。", "", "NOPERM")
		End If
	Else
		If Not InStr(","& RQ.Forum_PostReplyPerm &",", ","& RQ.UserGroupID &",") > 0 Then
			Call RQ.showTips("您现在的身份（"& RQ.UserGroupName &"）还不能在本版回帖哟。", "", "NOPERM")
		End If
	End If

	'版面是否设置了金钱达到某一数值才能回帖
	If RQ.F_ReplyNdCredits > 0 And RQ.UserCredits < RQ.F_ReplyNdCredits And RQ.DisablePostCtrl = 0 Then 
		Call RQ.showTips(RQ.Other_Settings(0) &"达到"& RQ.F_ReplyNdCredits &"就可以回帖了哟，加油！", "", "")
	End If

	'整站只读
	If RQ.CheckTimeSetting(RQ.Time_Settings(1)) And RQ.DisablePeriodCtrl = 0 Then
		Call RQ.showTips("在以下的时间段里，论坛处于只读状态：<br />"& Replace(RQ.Time_Settings(1), "_", "<br />"), "", "NOPERM")
	End If

	'版面只读
	If RQ.F_AllowPost = 0 And RQ.DisablePostCtrl = 0 Then
		Call RQ.showTips("当前版面为只读状态……", "", "NOPERM")
	End If

	'回帖防灌水控制
	If IntCode(RQ.Topic_Settings(10)) > 0 And DateDiff("s", NumtoDate(RQ.UserPostFloodCtrl), Now()) < 0 And RQ.DisablePostCtrl = 0 Then
		Call RQ.showTips("现在的时间是："& Now() &"，允许回帖的时间是："& NumtoDate(RQ.UserPostFloodCtrl) &"，请先看看别的帖子……", "", "")
	End If
End Sub

'========================================================
'匿名时的表现形式
'========================================================
Function Get_AnonymityText()
	Dim RndNumber, str, AnonySucRatio

	str = "<b>"& RQ.Topic_Settings(12) & Get_AnonymityCode() &"</b>"
	gblAnonymityResult = 1

	If RQ.Topic_Settings(14) = "1" Then
		Randomize

		'生成1-100之间的随机数字
		RndNumber = Int(100 * Rnd() + 1)

		'如果设置了用户组的匿名成功率则以用户组的设置为准，否则以全局设置为准
		AnonySucRatio = IIF(RQ.AnonymitySuc > 0, RQ.AnonymitySuc, IntCode(RQ.Topic_Settings(15)))

		'随机数字如果不在成功几率内则判断为匿名失败
		If RndNumber > AnonySucRatio Then
			str = Replace(RQ.Topic_Settings(16), "{username}", RQ.UserName)
			gblAnonymityResult = 0
		End If
	End If

	'匿名扣除金钱
	If gblAnonymityResult = 1 And IntCode(RQ.Topic_Settings(11)) > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& RQ.Topic_Settings(11) &" WHERE uid = "& RQ.UserID)
	End If

	Get_AnonymityText = str
	str = Empty
End Function

'========================================================
'匿名时后面的数字表现形式
'========================================================
Function Get_AnonymityCode()
	Dim IpArray, Number

	If RQ.Topic_Settings(13) = "1" Then
		IpArray = Split(RQ.UserIP, ".")
		For i = 0 To UBound(IpArray)
			Number = (Number + 1) * 7 + IpArray(i) * 6
		Next
	Else
		Randomize
		Number = (Number + Int((874 - 253 + 1) * Rnd + 253)) * 874
	End If

	Get_AnonymityCode = Number
End Function

'========================================================
'Ajax获取版面帖子分类
'========================================================
Sub GetTopicType()
	Dim TypeListArray
	TypeListArray = RQ.Query("SELECT typeid, name FROM "& TablePre &"topictypes WHERE fid = "& RQ.ForumID &" ORDER BY displayorder ASC")
	Call closeDatabase()

	If IsArray(TypeListArray) Then
		Response.Write "<select name=""typeid"" choosetype="""& RQ.F_ChooseTopicType &"""><option value=""0""></option>"
		For i = 0 To UBound(TypeListArray, 2)
			Response.Write "<option value="""& TypeListArray(0, i) &""">"& TypeListArray(1, i) &"</option>"
		Next
		Response.Write "</select>"
	End If
End Sub

'========================================================
'发帖界面
'========================================================
Sub Main()
	Call Check_Status_Topic()

	Dim TypeID, LeagueListArray, ForumListArray, TypeListArray
	Dim Special, AryCredits

	TypeID = SafeRequest(3, "typeid", 0, 0, 0)
	Special = SafeRequest(3, "special", 0, 0, 0)
	Special = IIF(Special > 1, 0, Special)

	'如果当前用户加入了联盟则读取联盟名称
	If RQ.UserLeagueGroupID > 0 Then
		LeagueListArray = RQ.Query("SELECT lm.joinid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" ORDER BY l.leagueid ASC")
	End If

	'读取版面列表以显示帖子发表在哪个版面
	ForumListArray = RQ.Query("SELECT f.fid, f.name, f.allowpost, f.postndcredits, ff.viewperm, ff.posttopicperm FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid ORDER BY f.displayorder ASC")

	'当前版面是否有帖子分类
	If Len(RQ.Forum_TopicType) > 0 Then
		TypeListArray = eval(RQ.Forum_TopicType)
	End If

	'金钱达到某一数值才能查看帖子
	AryCredits = Array(1, 5, 10, 15, 30, 50, 80, 100, 150, 200, 250, 300, 500, 800, 1000, 1200, 1500, 1800, 2000, 2500, 5000, 9999, 100000, 1000000)

	Call closeDatabase()
	RQ.Header()
%>
<body>
<% If Len(RQ.UserName) > 0 Then %>
<b>论坛广播：<%= RQ.UserName %>屁颠屁颠的来发帖了</b>
<p>
<% End If %>
<script type="text/javascript" src="js/ajax.js"></script>
<script type="text/javascript" src="js/rsTipBox.js"></script>
<form name="newtopic" method="post" action="?action=newtopic" onkeydown="fastpost('btnsubmit', event);" onsubmit="return validinput(this);">
  <% If Len(RQ.UserName) = 0 Then %>
  游客名字:<input type="text" name="username" size="19" maxlength="10" />
  字符长度请控制在10个字以内<br />
  <% End If %>
  所在版面:<select name="fid" onchange="gettopictype(this.options[this.options.selectedIndex].value);">
    <% For i = 0 To UBound(ForumListArray, 2) %>
    <% If ((ForumListArray(2, i) = 1 And (ForumListArray(3, i) = 0 Or RQ.UserCredits >= ForumListArray(3, i))) And (Len(ForumListArray(4, i)) = 0 Or InStr(","& ForumListArray(4, i) &",", ","& RQ.UserGroupID &",") > 0) And (Len(ForumListArray(5, i)) = 0 Or InStr(","& ForumListArray(5, i) &",", ","& RQ.UserGroupID &",") > 0)) Then %>
    <option value="<%= ForumListArray(0, i) %>"<% If RQ.ForumID = ForumListArray(0, i) Then Response.Write " selected" End If %>><%= ForumListArray(1, i) %></option>
    <% End If %>
    <% Next %>
  </select><span id="p_topictype"><% If IsArray(TypeListArray) Then %><select id="typeid" name="typeid" choosetype="<%= RQ.F_ChooseTopicType %>">
    <option value="0"></option>
	<% For i = 0 To UBound(TypeListArray) %>
    <option value="<%= TypeListArray(i)(1) %>"<% If TypeID = TypeListArray(i)(1) Then Response.Write " selected" End If %>><%= TypeListArray(i)(0) %></option>
	<% Next %>
  </select>
  <% End If %>
  </span>
  <br />
  帖子标题:<input name="title" type="text" maxlength="<%= RQ.Topic_Settings(0) %>" size="25" /><select name="types">
    <option value="0" selected>普通帖</option>
    <option value="1">转载帖</option>
    <option value="2">经典内容下载</option>
    <option value="3">自创文学作品</option>
    <option value="4">集体活动,聚会召集</option>
    <option value="5">实用知识</option>
  </select>
  <br />
  <% If RQ.F_AllowPollTopic = 1 And RQ.AllowPostPoll = 1 And Special = 1 Then %>
  <input type="hidden" name="special" value="<%= Special %>" />
  投票选项:<textarea name="polloptions" rows="5" cols="36"></textarea>每行填1个，最多40个。
  <br />
  有效天数:<input type="text" name="validdate" size="5" />天(可不填)
  <input type="checkbox" name="visible" id="visible" value="1" checked /><label for="visible">不投票就可以看结果</label>
  <input type="checkbox" name="multiple" id="multiple" value="1" onclick="javascript:$('panelmaxchoices').style.display = $('multiple').checked == true ? '' : 'none';" /><label for="multiple">多选</label>
  <span id="panelmaxchoices" style="display:none;">最多可选<input type="text" name="maxchoices" size="5" value="10" />个</span>
  <br />
  <% End If %>
  帖子内容:<% If InStr(RQ.Topic_Settings(17), "topic") > 0 And RQ.blnAllowHTML(0) Then %><input type="hidden" id="message" name="message" style="display:hidden" /><input type="hidden" id="content___Config" value="" style="display:none" /><iframe id="content___Frame" src="include/editor/editor/fckeditor.html?InstanceName=message" width="400" height="200" frameborder="0" scrolling="no"></iframe><% Else %><span id="editorzone"><textarea name="message" id="message" style="width: 270px; height: 155px;"></textarea><% If RQ.blnAllowHTML(0) Then %><a href="javascript:displayeditor();" class="bluelink">编辑器</a><% End If %></span><% End If %>
  <% If RQ.UserID > 0 Then %>
  <span id="face_preview"></span>
  <br />
  相关链接:<input type="text" name="aboutlink" maxlength="200" size="43" value="http://" onmouseover="showTip('如果需要张贴多个链接地址,将各地址用逗号隔开即可.')" onmouseout="hideTip();" />
  <br />
  相关图片:<input type="text" name="imglink" maxlength="200" size="43" value="http://" onmouseover="showTip('如果需要张贴多张图片,将各图片地址用逗号隔开即可.')" onmouseout="hideTip();" /><span id="spanButtonPlaceholder"></span>
  <br />
  <a href="htmls/face.htm" target="_blank" class="bluelink">表情</a>
  <select name="face1" id="face1" onChange="preview_face();">
    <option value="0">0</option>
    <option value="1">1</option>
    <option value="2">2</option>
    <option value="3">3</option>
    <option value="4">4</option>
    <option value="5">5</option>
    <option value="6">6</option>
    <option value="7">7</option>
    <option value="8">8</option>
    <option value="9">9</option>
  </select><select name="face2" id="face2" onChange="preview_face();">
    <option value="0">0</option>
    <option value="1">1</option>
    <option value="2">2</option>
    <option value="3">3</option>
    <option value="4">4</option>
    <option value="5">5</option>
    <option value="6">6</option>
    <option value="7">7</option>
    <option value="8">8</option>
    <option value="9">9</option>
  </select><select name="face3" id="face3" onChange="preview_face();">
    <option value="0">0</option>
    <option value="1">1</option>
    <option value="2">2</option>
    <option value="3">3</option>
    <option value="4">4</option>
    <option value="5">5</option>
    <option value="6">6</option>
    <option value="7">7</option>
    <option value="8">8</option>
    <option value="9">9</option>
  </select>
  <% If (RQ.UserCredits >= RQ.F_AnonymityNdCredits Or RQ.F_AnonymityNdCredits = 0) And (IntCode(RQ.Topic_Settings(11)) = 0 Or RQ.UserCredits >= IntCode(RQ.Topic_Settings(11))) Then %>
  <input name="ifanonymity" id="ifanonymity" type="checkbox" value="1"><label for="ifanonymity">匿名</label>
  <% End If %>
  <input type="checkbox" name="iflocked" id="iflocked" value="1" /><label for="iflocked">不接受回复</label>
  <% If RQ.blnAllowHTML(0) Then %><input type="checkbox" name="disable_autowap" id="disable_autowap" value="1" onclick="javascript:if($('message').type=='hidden')this.checked=true;" /><label for="disable_autowap">不自动换行</label><% End If %>
  <input type="checkbox" name="sig" id="sig" value="1" checked /><label for="sig">签名</label><br />
  <% If IsArray(LeagueListArray) Then %>
  联盟
  <select name="leaguejoinid">
    <option value="0">非联盟帖</option>
    <% For i = 0 To UBound(LeagueListArray, 2) %>
    <option value="<%= LeagueListArray(0, i) %>"><%= LeagueListArray(1, i) %></option>
    <% Next %>
  </select>
  <% End If %>
  <select name="price">
    <option selected value="0">看此帖应达到的最低<%= RQ.Other_Settings(0) %></option>
	<% For i = 0 To UBound(AryCredits) %>
    <option value="<%= AryCredits(i) %>"><%= AryCredits(i) %></option>
	<% Next %>
  </select>
  <% End If %>
  <div id="fsUploadProgress"></div>
  <p>
    <input type="submit" name="btnsubmit" id="btnsubmit" value="提交发言" class="button" />
	<% If RQ.UserID = 0 And RQ.AllowPostAttach Then %><span id="spanButtonPlaceholder"></span><% End If %>
  </p>
</form>
<% If RQ.AllowPostAttach Then %>
<link href="js/swfupload/default.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="js/swfupload/swfupload.js"></script>
<script type="text/javascript" src="js/swfupload/swfupload.queue.js"></script>
<script type="text/javascript">
var upload;
window.onload = function() {
	upload = new SWFUpload({
		upload_url: "attachment.asp?action=upload",
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
		button_width: 135,
		button_height: 18,
		button_text : '<span class="underline">上传附件(<%= IIF(RQ.MaxAttachSize = 0, "100MB", RQ.MaxAttachSize &"KB") %>以内)</span>',
		button_text_style : '.underline{text-decoration:underline;}',
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
<script type="text/javascript">
function validinput(form) {
	var choosetopictype = $('typeid') && $('typeid').getAttribute('choosetype') == '1' ? 1 : 0;
	var postmaxlen = <%= RQ.Topic_Settings(1) %>;
	var disablepostctrl = <%= RQ.DisablePostCtrl %>;
	if($('message').type == 'hidden'){
		var oEditor = FCKeditorAPI.GetInstance('message'); 
	    message = oEditor.GetXHTML(true);
	}else{
		message = $('message').value;
	}
	if (form.typeid && form.typeid.options[form.typeid.selectedIndex].value == 0 && choosetopictype) {
		alert("请选择帖子分类");
		form.typeid.focus();
		return false;
	}
	if (form.title.value == "" || message == "") {
		alert("请填写好帖子标题和内容");
		form.title.focus();
		return false;
	}
	if (!disablepostctrl && postmaxlen != 0 && message.length > postmaxlen) {
		alert("您提交的内容有"+ message.length +"个字\n\n帖子内容的长度请控制在"+ postmaxlen +"字以内");
		return false;
	}
	$('btnsubmit').value = '正在提交,请稍后...';
	$('btnsubmit').disabled = true;
	return true;
}
function gettopictype(fid){
	ajax_get('post.asp?action=gettopictype&fid='+ fid, 'p_topictype');
}
f_autowap();
</script>
<p><span class="blue">发帖请遵守本站规则，如果您不是很清楚建议您仔细阅读<a href="htmls/help.html" target="_blank"><span class="blue underline">用户必读</span></a>。</span></p>
<%
	RQ.Footer()
End Sub
%>
