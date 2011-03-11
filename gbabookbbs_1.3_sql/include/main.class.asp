<%
Class Cls_Forum
	
	Public UserInfo, UserCode, UserID, Username, UserPassword, AdminGroupID, UserGroupID, UserCredits
	Public UserRegTime, UserLoginTime, UserLastLoginIP, UserLoginIP, UserNewTopicTime
	Public UserPostFloodCtrl, UserAccessMasks, UserGroupExpiry, UserNewPm, UserLeagueGroupID, UserViewTopicStyle
	Public UserIP, UserSessionID

	Public Base_Settings, Time_Settings, Login_Settings, User_Settings, Topic_Settings, Other_Settings
	Public Chat_Settings, Wap_Settings, Item_Settings, Attach_Settings, WM_Settings, WordsFilter_Settings, Gbl_Banner
	Public UserGroupName, IsModerator

	'版面内容
	Public ForumInfo, Forum_Name, Forum_ParentID, Forum_Childs, Forum_RootFID, Forum_Topics
	Public Forum_Posts, Forum_Moderators, Forum_ViewPerm, Forum_PostTopicPerm, Forum_PostReplyPerm
	Public Forum_PostAttachPerm, Forum_GetAttachPerm, Forum_TopicType

	'联盟内容
	Public LeagueID, L_UserGroupID
	
	'版面权限
	Public F_AllowPost, F_AdultingPost, F_ShowTopicType, F_ChooseTopicType, F_AllowPollTopic, F_AutoClose
	Public F_RecycleBin, F_VisitNdCredits, F_PostNdCredits, F_ReplyNdCredits, F_AnonymityNdCredits, F_HtmlNdCredits

	'用户组权限
	Public AllowVisit, DisablePeriodCtrl, AllowPost, AllowDirectPost, AllowReply, AnonymitySuc, AllowPostPoll
	Public AllowPoll, AllowSearch, AllowGetAttach, AllowPostAttach, MaxAttachSize, AttachExtensions
	Public AllowViewUserInfo, AllowUseItem, AllowHTML, AllowChat, SpecialInterface
	Public AllowInvate, InvatePrice, InvateMaxNum, InvateExpiryDay

	'管理组权限
	Public AllowManageTopic, AllowEditPoll, AllowStickTopic, AllowAuditingTopic, AllowViewIP
	Public AllowBanIP, AllowEditUser, AllowPunishUser, DisablePostCtrl, AllowDelItemMsg, DisablePmCtrl, AllowViewLog

	Public ForumID, TopicID, PageTitle, PageBaseTarget

	'========================================================
	'类加载，初始化变量
	'========================================================
	Private Sub Class_Initialize()
		UserID = 0
		UserCode = strFilter(Request.Cookies(CacheName &"uc"))
		If Len(Request.QueryString("uc")) > 0 Then
			UserCode = Request.QueryString("uc")
		End If
		UserName = strFilter(Request.Cookies(CacheName &"un"))
		UserSessionID = strFilter(Request.Cookies(CacheName &"sid"))

		'获取用户IP
		If Len(Request.ServerVariables("HTTP_X_FORWARDED_FOR")) = 0 Or InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), "unknown") > 0 Then
			UserIP = Request.ServerVariables("REMOTE_ADDR")
		ElseIf InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ",") > 0 Then
			UserIP = Mid(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), 1, InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ",") - 1)
		ElseIf InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ";") > 0 Then
			UserIP = Mid(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), 1, InStr(Request.ServerVariables("HTTP_X_FORWARDED_FOR"), ";") - 1)
		Else
			UserIP = Request.ServerVariables("HTTP_X_FORWARDED_FOR")
		End If

		UserIP = Trim(strFilter(UserIP))
		UserIP = IIF(Len(UserIP) > 15, Left(UserIP, 15), UserIP)

		ForumID = SafeRequest(1, "fid", 0, 0, 0)
		TopicID = SafeRequest(1, "tid", 0, 0, 0)
		LeagueID = SafeRequest(1, "lid", 0, 0, 0)
	End Sub

	'========================================================
	'类结束，销毁对象
	'========================================================
	Private Sub Class_Terminate()
		Set RQ = Nothing
	End Sub

	'========================================================
	'查询SQL语句(写操作使用)
	'========================================================
	Public Function Execute(sql)
	 	'Response.Write sql &"<br />"
		Dim n
		If Not IsObject(Conn) Then
			Call connectDatabase()
		End If
		Conn.Execute(sql), n
		dbQueryNum = dbQueryNum + 1
		Execute = n
	End Function

	'========================================================
	'查询SQL语句(读操作使用)
	'========================================================
	Public Function Query(sql)
		'Response.write sql &"<br />"
		If Not IsObject(Conn) Then
			Call connectDatabase()
		End If
		Set Rs = Conn.Execute(sql)
		If Not Rs.EOF And Not Rs.BOF Then 
			Query = Rs.GetRows()
		Else
			Query = 0
		End If
		Rs.Close
		Set Rs = Nothing
		dbQueryNum = dbQueryNum + 1
	End Function

	'========================================================
	'读取版面信息
	'========================================================
	Public Sub Get_ForumSettings()
		If Not IsArray(Application(CacheName &"_site_settings")) Then 
			Call Reload_Site_Settings()
		End If

		Dim SettingsInfo
		SettingsInfo = Application(CacheName &"_site_settings")

		Base_Settings = Split(SettingsInfo(0, 0), "{settings}")
		Time_Settings = Split(SettingsInfo(1, 0), "{settings}")
		Login_Settings = Split(SettingsInfo(2, 0), "{settings}")
		User_Settings = Split(SettingsInfo(3, 0), "{settings}")
		Topic_Settings = Split(SettingsInfo(4, 0), "{settings}")
		Other_Settings = Split(SettingsInfo(5, 0), "{settings}")
		Chat_Settings = Split(SettingsInfo(6, 0), "{settings}")
		Wap_Settings = Split(SettingsInfo(7, 0), "{settings}")
		Item_Settings = Split(SettingsInfo(8, 0), "{settings}")
		Attach_Settings = Split(SettingsInfo(9, 0), "{settings}")
		WM_Settings = Split(SettingsInfo(10, 0), "{settings}")
		WordsFilter_Settings = SettingsInfo(11, 0)
		Gbl_Banner = SettingsInfo(13, 0)

		Erase SettingsInfo

		'BanIp检验
		Call IpBanned()

		'论坛是否关闭
		If Base_Settings(4) = "1" And Not (ScriptName = "login" Or AdminGroupID = 1) Then
			Call ClearCookies()
			Call showTips(Base_Settings(5), "", "NOPERM")
		End If

		'检查版面是否有时间设定
		If CheckTimeSetting(Time_Settings(0)) And Not (ScriptName = "login" Or DisablePeriodCtrl = 1) Then
			Call showTips("在以下的时间段里，论坛处于关闭状态：<br />"& Replace(Time_Settings(0), "_", "<br />") &"<br />请择时再来。", "", "NOPERM")
		End If

		'当前的用户组是否允许访问
		If AllowVisit = 0 And Not (ScriptName = "login" Or ScriptName = "pwdsafe" Or AdminGroupID = 1) Then
			If UserID = 0 Then
				Call closeDatabase()
				Response.Redirect Login_Settings(1)
			Else
				Call showTips("抱歉，您当前的身份("& UserGroupName &")无法浏览当前页面。(<a href="""& Login_Settings(1) &"?action=clearcookies"">退出本站</a>)", "", "NOPERM")
			End If
		End If

		'读取版面设置
		If ForumID > 0 Then
			If Not IsArray(Application(CacheName &"_foruminfo_"& ForumID)) Then
				Reload_Forum_Settings(ForumID)
			End If

			ForumInfo = Application(CacheName &"_foruminfo_"& ForumID)

			Forum_Name = ForumInfo(1, 0)
			Forum_ParentID = ForumInfo(2, 0)
			Forum_Childs = ForumInfo(3, 0)
			Forum_RootFID = ForumInfo(4, 0)
			Forum_Topics = ForumInfo(6, 0)
			Forum_Moderators = ForumInfo(22, 0)
			Forum_ViewPerm = ForumInfo(23, 0)
			Forum_PostTopicPerm = ForumInfo(24, 0)
			Forum_PostReplyPerm = ForumInfo(25, 0)
			Forum_PostAttachPerm = ForumInfo(26, 0)
			Forum_GetAttachPerm = ForumInfo(27, 0)
			Forum_TopicType = ForumInfo(28, 0)

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

			'检查当前用户的浏览权限
			If Len(Forum_ViewPerm) > 0 And Not InStr(","& Forum_ViewPerm &",", ","& UserGroupID &",") > 0 Then
				Call showTips("抱歉，您当前的用户身份("& UserGroupName &")还不能浏览该版面。", "", "NOPERM")
			End If

			'版面是否设置了金钱达到某一数值才能浏览
			If F_VisitNdCredits > 0 And UserCredits < F_VisitNdCredits And UserGroupID <> 1 Then
				Call showTips(Other_Settings(0) &"达到"& F_VisitNdCredits &"就可以进入了哟，加油！", "", "NOPERM")
			End If

			'检查版主是否有当前版面的权限
			If AdminGroupID = 3 Then
				If Conn.Execute("SELECT 1 FROM "& TablePre &"moderators WHERE fid = "& ForumID &" AND uid = "& UserID).EOF Then
					IsModerator = False
				End If
				dbQUeryNum = dbQueryNum + 1
			End If

			'当前用户是否能够上传附件
			If Len(Forum_PostAttachPerm) > 0 Then
				AllowPostAttach = (InStr(","& Forum_PostAttachPerm &",", ","& UserGroupID &",") > 0 And AllowPostAttach)
			ElseIf UserID = 0 Then
				AllowPostAttach = False
			End If

			'当前用户是否能够下载附件
			If Len(Forum_GetAttachPerm) > 0 Then
				AllowGetAttach = (InStr(","& Forum_GetAttachPerm &",", ","& UserGroupID &",") > 0 And AllowGetAttach)
			End If
		End If

		'读取联盟用户组
		If LeagueID > 0 And UserID > 0 Then
			Dim L_GroupInfo
			L_GroupInfo = Query("SELECT groupid FROM "& TablePre &"leaguemembers WHERE uid = "& UserID &" AND leagueid = "& LeagueID)

			If IsArray(L_GroupInfo) Then
				L_UserGroupID = L_GroupInfo(0, 0)
			Else
				L_UserGroupID = 0
			End If
		End If
	End Sub

	'========================================================
	'如果版面有时间设定，检查是否在当前时间是否符合条件
	'========================================================
	Public Function CheckTimeSetting(str)
		CheckTimeSetting = False

		If Len(str) = 0 Then
			Exit Function
		End If

		Dim Temp, SettingTime
		Temp = Split(str, "_")

		For i = 0 To UBound(Temp)
			SettingTime = Split(Temp(i), "-")
			SettingTime(0) = CDate(Date() &" "& SettingTime(0) &":00")
			SettingTime(1) = CDate(Date() &" "& SettingTime(1) &":00")

			If SettingTime(0) >= SettingTime(1) Then 
				SettingTime(1) = DateAdd("d", 1, SettingTime(0))
			End If

			If Now() > SettingTime(0) And Now() < SettingTime(1) Then
				CheckTimeSetting = True
				Exit For
			End If
		Next

		Erase SettingTime
		Erase Temp
	End Function

	'========================================================
	'BANIP设置
	'========================================================
	Private Sub IpBanned()
		Dim BanIP
		BanIP = Application(CacheName &"_site_settings")(12, 0)

		If Len(BanIP) = 0 Then
			Exit Sub
		End If

		If RegExpTest("^("& BanIP &")$", UserIP) Then
			Call showTips("您目前无法访问网站。", "", "HALTED")
		End If
	End Sub

	'========================================================
	'重新读取版面设置,并放入Application
	'========================================================
	Public Sub Reload_Site_Settings()
		Dim SettingsInfo
		SettingsInfo = Query("SELECT TOP 1 * FROM "& TablePre &"settings")

		If Not IsArray(SettingsInfo) Then
			Call showTips("站点配置错误。", "", "")
		End If

		Call setCache(CacheName &"_site_settings", SettingsInfo)
		Erase SettingsInfo
	End Sub

	'========================================================
	'重新读取用户组设置,并放入Application
	'========================================================
	Public Sub Reload_UserGroup_Settings(GroupID)
		Dim GroupInfo
		GroupInfo = Query("SELECT * FROM "& TablePre &"usergroups WHERE gid = "& GroupID)

		If Not IsArray(GroupInfo) Then
			Call showTips("用户组错误。", "", "")
		End If

		Call setCache(CacheName &"_usergroup_"& GroupID, GroupInfo)
		Erase GroupInfo
	End Sub

	'========================================================
	'重新读取管理组设置,并放入Application
	'========================================================
	Public Sub Reload_AdminGroup_Settings(GroupID)
		Dim GroupInfo
		GroupInfo = Query("SELECT * FROM "& TablePre &"admingroups WHERE gid = "& GroupID)

		If Not IsArray(GroupInfo) Then
			Call showTips("管理组错误。", "", "")
		End If

		Call setCache(CacheName &"_admingroup_"& GroupID, GroupInfo)
		Erase GroupInfo
	End Sub

	'========================================================
	'重新读取版面设置,并放入Application
	'========================================================
	Public Sub Reload_Forum_Settings(ForumID)
		Dim ForumInfo
		ForumInfo = Query("SELECT f.*, ff.* FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid WHERE f.fid = "& ForumID)

		If Not IsArray(ForumInfo) Then
			Call showTips("这个版面还没有呢。", "", "")
		End If

		Call setCache(CacheName &"_foruminfo_"& ForumID, ForumInfo)
		Erase ForumInfo
	End Sub

	'========================================================
	'更新Application中版面的帖子数量(发贴时会调用)
	'========================================================
	Public Sub Update_TopicNum(ForumID, n)
		If Not IsArray(Application(CacheName &"_foruminfo_"& ForumID)) Then
			Reload_Forum_Settings(ForumID)
		End If

		Dim ForumInfo
		ForumInfo = Application(CacheName &"_foruminfo_"& ForumID)
		ForumInfo(6, 0) = n

		Call setCache(CacheName &"_foruminfo_"& ForumID, ForumInfo)
		Erase ForumInfo
	End Sub

	'========================================================
	'传入版面ID获取版面名字
	'========================================================
	Public Function Get_Forum_Settings(ForumID, col)
		If Not IsArray(Application(CacheName &"_foruminfo_"& ForumID)) Then
			Reload_Forum_Settings(ForumID)
		End If

		Get_Forum_Settings = Application(CacheName &"_foruminfo_"& ForumID)(col, 0)
	End Function

	'========================================================
	'传入用户组ID获取用户组名字
	'========================================================
	Public Function Get_GroupName(GroupID)
		If Not IsArray(Application(CacheName &"_usergroup_"& GroupID)) Then 
			Reload_UserGroup_Settings(GroupID)
		End If

		Get_GroupName = Application(CacheName &"_usergroup_"& GroupID)(1, 0)
	End Function

	'========================================================
	'检测用户是否登陆
	'========================================================
	Public Sub CheckUserLogin()
		Dim AuthString, AryAuth
		If Len(UserCode) > 0 Then
			AuthString = XXTEA.decrypt(UserCode, PrivateKey)
			If Not IsNull(AuthString) Then
				AryAuth = Split(AuthString, Chr(9))
				If UBound(AryAuth) = 1 Then
					UserID = IntCode(AryAuth(0))
					UserPassword = strFilter(AryAuth(1))
				End If
			End If
		End If

		If UserID > 0 Then
			UserInfo = Query("SELECT username, admingroupid, usergroupid, credits, regtime, lastloginip, logintime, loginip, newtopictime, postfloodctrl, accessmasks, groupexpiry, newpm, leaguegid, viewtopicstyle FROM "& TablePre &"members WHERE uid = "& UserID &" AND thepassword = '"& UserPassword &"'")
			If Not IsArray(UserInfo) Then
				Call ClearCookies()
			End If
		End If

		'读取用户各项属性
		Call Get_UserDetails()

		'读取用户组设置
		Call Get_UserGroup_Settings()

		'读取管理组设置
		Call Get_Admin_Settings()

		If Len(UserSessionID) <> 10 Then
			UserSessionID = Rand(10)'生成随机的10位字符串
			Response.Cookies(CacheName &"sid") = UserSessionID
			Response.Cookies(CacheName &"sid").Expires = Date() + 5
		End If
	End Sub
	
	'========================================================
	'获取用户信息并赋值给变量
	'========================================================
	Public Sub Get_UserDetails()
		If IsArray(UserInfo) Then
			UserName = UserInfo(0, 0)
			AdminGroupID = UserInfo(1, 0)
			UserGroupID = UserInfo(2, 0)
			UserCredits = UserInfo(3, 0)
			UserRegTime = UserInfo(4, 0)
			UserLastLoginIP = Trim(UserInfo(5, 0))
			UserLoginTime = UserInfo(6, 0)
			UserLoginIP = Trim(UserInfo(7, 0))
			UserNewTopicTime = UserInfo(8, 0)
			UserPostFloodCtrl = UserInfo(9, 0)
			UserAccessMasks = UserInfo(10, 0)
			UserGroupExpiry = UserInfo(11, 0)
			UserNewPm = UserInfo(12, 0)
			UserLeagueGroupID = UserInfo(13, 0)
			UserViewTopicStyle = UserInfo(14, 0)

			'处理过期的用户组
			If UserGroupExpiry > 0 And UserGroupExpiry <= DatetoNum(Now()) Then
				Call Process_GroupExpiry()
			End If
			
			Erase UserInfo
		Else
			AdminGroupID = 0
			UserGroupID = 5
			UserCredits = 0
			UserRegTime = Now()
			UserLoginTime = Now()
			UserNewTopicTime = 0
			UserPostFloodCtrl = 0
			UserAccessMasks = 0
			UserGroupExpiry = 0
			UserNewPm = 0
			UserLeagueGroupID = 0
			UserViewTopicStyle = 0
		End If
	End Sub

	'========================================================
	'用户组到期处理
	'========================================================
	Private Sub Process_GroupExpiry()
		Dim ExpiryInfo
		ExpiryInfo = Query("SELECT usergroupid, admingroupid FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)

		If IsArray(ExpiryInfo) Then
			UserGroupID = ExpiryInfo(0, 0)
			AdminGroupID = ExpiryInfo(1, 0)
			Execute("UPDATE "& TablePre &"members SET admingroupid = "& AdminGroupID &", usergroupid = "& UserGroupID &", groupexpiry = 0 WHERE uid = "& UserID)
			Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserID)
		Else
			Execute("UPDATE "& TablePre &"members SET groupexpiry = 0 WHERE uid = "& UserID)
		End If
	End Sub

	'========================================================
	'得到用户组设置
	'========================================================
	Public Sub Get_UserGroup_Settings()

		If Not IsArray(Application(CacheName &"_usergroup_"& UserGroupID)) Then
			Call Reload_UserGroup_Settings(UserGroupID)
		End If

		Dim Settings, PermissionInfo

		If UserAccessMasks = 1 Then
			PermissionInfo = Query("SELECT * FROM "& TablePre &"access WHERE uid = "& UserID)
			If Not IsArray(PermissionInfo) Then
				Execute("UPDATE "& TablePre &"members SET accessmasks = 0 WHERE uid = "& UserID)
			End If
		Else
			Settings = Application(CacheName &"_usergroup_"& UserGroupID)
		End If

		UserGroupName = Application(CacheName &"_usergroup_"& UserGroupID)(1, 0)

		'当前用户是否有单独的权限设置
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
			AllowGetAttach = (PermissionInfo(10, 0) = 1)
			AllowPostAttach = (PermissionInfo(11, 0) = 1)
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
			AllowVisit = Settings(4, 0)
			DisablePeriodCtrl = Settings(5, 0)
			AllowPost = Settings(6, 0)
			AllowDirectPost = Settings(7, 0)
			AllowReply = Settings(8, 0)
			AnonymitySuc = Settings(9, 0)
			AllowPostPoll = Settings(10, 0)
			AllowPoll = Settings(11, 0)
			AllowSearch = Settings(12, 0)
			AllowGetAttach = (Settings(13, 0) = 1)
			AllowPostAttach = (Settings(14, 0) = 1)
			MaxAttachSize = Settings(15, 0)
			AttachExtensions = Settings(16, 0)
			AllowViewUserInfo = Settings(17, 0)
			AllowUseItem = Settings(18, 0)
			AllowHTML = Settings(19, 0)
			AllowChat = Settings(20, 0)
			SpecialInterface = Settings(21, 0)
			AllowInvate = Settings(22, 0)
			InvatePrice = Settings(23, 0)
			InvateMaxNum = Settings(24, 0)
			InvateExpiryDay = Settings(25, 0)
		End If
	End Sub

	'========================================================
	'得到管理组设置
	'========================================================
	Public Sub Get_Admin_Settings()
		If AdminGroupID > 0 Then
			If Not IsArray(Application(CacheName &"_admingroup_"& AdminGroupID)) Then
				Call Reload_AdminGroup_Settings(AdminGroupID)
			End If

			Dim GroupInfo
			GroupInfo = Application(CacheName &"_admingroup_"& AdminGroupID)

			IsModerator = True

			AllowManageTopic = GroupInfo(1, 0)
			AllowEditPoll = GroupInfo(2, 0)
			AllowStickTopic = GroupInfo(3, 0)
			AllowAuditingTopic = GroupInfo(4, 0)
			AllowViewIP = GroupInfo(5, 0)
			AllowBanIP = GroupInfo(6, 0)
			AllowEditUser = GroupInfo(7, 0)
			AllowPunishUser = GroupInfo(8, 0)
			DisablePostCtrl = GroupInfo(9, 0)
			AllowDelItemMsg = GroupInfo(10, 0)
			DisablePmCtrl = GroupInfo(11, 0)
			AllowViewLog = GroupInfo(12, 0)
		Else
			AllowManageTopic = 0
			AllowEditPoll = 0
			AllowStickTopic = 0
			AllowAuditingTopic = 0
			AllowViewIP = 0
			AllowBanIP = 0
			AllowEditUser = 0
			AllowPunishUser = 0
			DisablePostCtrl = 0
			AllowDelItemMsg = 0
			DisablePmCtrl = 0
			AllowViewLog = 0
		End If
	End Sub

	'========================================================
	'判断用户是否允许使用html代码
	'========================================================
	Function blnAllowHTML(fid)
		If ForumID > 0 Then
			blnAllowHTML = ((UserCredits >= F_HtmlNdCredits Or F_HtmlNdCredits = 0) And AllowHTML = 1)
		ElseIf fid > 0 Then
			F_HtmlNdCredits = Get_Forum_Settings(fid, 20)
			blnAllowHTML = ((UserCredits >= F_HtmlNdCredits Or F_HtmlNdCredits = 0) And AllowHTML = 1)
		Else
			blnAllowHTML = (AllowHTML = 1)
		End If
	End Function

	'========================================================
	'清除Cookies
	'========================================================
	Public Sub ClearCookies()
		Response.Cookies(CacheName &"uc") = ""
		Response.Cookies(CacheName &"uc").Expires = Now() - 365
		UserID = 0
		UserGroupID = 5
	End Sub

	'========================================================
	'记录异动报告
	'========================================================
	Public Sub SetLog(TargetUID, TargetUserName, Operation, Reason)
		Execute("INSERT INTO "& TablePre &"logs (targetuid, targetusername, uid, username, userip, operation, reason) VALUES ("& TargetUID &", N'"& TargetUserName &"', "& UserID &", N'"& UserName &"', '"& UserIP &"', N'"& Operation &"', N'"& Reason &"')")
	End Sub

	'========================================================
	'记录异动报告
	'========================================================
	Public Sub SetItemUserLog(ItemID, TargetUID, TargetUserName, Operation)
		Execute("INSERT INTO "& TablePre &"itemuselogs (itemid, tid, uid, username, userip, targetuid, targetusername, operation) VALUES ("& ItemID &", "& TopicID &", "& UserID &", N'"& UserName &"', '"& UserIP &"', "& TargetUID &", N'"& TargetUserName &"', N'"& Operation &"')")
	End Sub

	'========================================================
	'用户使用道具, 返回道具消耗结果
	'========================================================
	Public Function CheckItem(ItemID, Num, blnUserItem)
		Dim ItemInfo
		ItemInfo = Query("SELECT id, num FROM "& TablePre &"memberitems WHERE uid = "& UserID &" AND itemid = "& ItemID &" AND num >= "& Num)

		If IsArray(ItemInfo) Then
			'是否使用道具还是只是查询
			If blnUserItem Then
				If ItemInfo(1, 0) > Num Then
					Execute("UPDATE "& TablePre &"memberitems SET num = num - "& Num &" WHERE id = "& ItemInfo(0, 0))
				ElseIf ItemInfo(1, 0) = Num Then
					Execute("DELETE FROM "& TablePre &"memberitems WHERE id = "& ItemInfo(0, 0))
				End If
			End If
			CheckItem = True
		Else
			CheckItem = False
		End If
	End Function

	'========================================================
	'更新用户在联盟中的最高等级
	'========================================================
	Public Sub UpdateLGroupID(strUserID)
		Execute("UPDATE m SET m.leaguegid = ISNULL((SELECT TOP 1 groupid FROM "& TablePre &"leaguemembers WHERE uid = m.uid AND groupid > 0 ORDER BY groupid ASC), 0) FROM "& TablePre &"members m WHERE m.uid IN("& strUserID &")")
	End Sub

	'========================================================
	'定时清理过期的置顶帖子
	'========================================================
	Public Sub ClearStickTopic()
		Dim RefreshTime, TopicListArray

		If Not IsDate(Application(CacheName &"task_clearsticktopic")) Then
			Call setCache(CacheName &"task_clearsticktopic", Now())
		End If

		RefreshTime = Application(CacheName &"task_clearsticktopic")
		If DateDiff("n", RefreshTime, Now()) < 30 Then
			Exit Sub
		End If

		TopicListArray = Query("SELECT TOP 1 1 FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"topictask WHERE expirytime < GETDATE())")

		If IsArray(TopicListArray) Then
			Execute("DELETE FROM "& TablePre &"sticktopics WHERE tid IN(SELECT tid FROM "& TablePre &"topictask WHERE expirytime < GETDATE())")
			Execute("UPDATE "& TablePre &"topics SET displayorder = 0, iftask = 0 WHERE tid IN(SELECT tid FROM "& TablePre &"topictask WHERE expirytime < GETDATE())")
			Execute("DELETE FROM "& TablePre &"topictask WHERE expirytime < GETDATE()")
		End If

		Call setCache(CacheName &"task_clearsticktopic", Now())
	End Sub

	'========================================================
	'获取有浏览权限的版面
	'========================================================
	Function Get_Accessable_ForumID()
		Dim ForumListArray, strForumID
		strForumID = "0,"

		ForumListArray = Query("SELECT f.fid, f.visitndcredits, ff.viewperm FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid ORDER BY f.displayorder ASC")
		If IsArray(ForumListArray) Then
			For i = 0 To UBound(ForumListArray, 2)
				If (ForumListArray(1, i) = 0 Or UserCredits >= ForumListArray(1, i)) And (Len(ForumListArray(2, i)) = 0 Or InStr(","& ForumListArray(2, i) &",", ","& UserGroupID &",") > 0) Then
					strForumID = strForumID & ForumListArray(0, i) &","
				End If
			Next
		End If

		Get_Accessable_ForumID = Left(strForumID, Len(strForumID) - 1)
	End Function

	'========================================================
	'得到指定版面的所属根版面id
	'========================================================
	Private Function Get_RootForumID(ForumID)
		If Not IsArray(Application(CacheName &"_foruminfo_"& ForumID)) Then
			Call Reload_Forum_Settings(ForumID)
		End If

		Get_RootForumID = Application(CacheName &"_foruminfo_"& ForumID)(4, 0)
	End Function

	'========================================================
	'置顶帖子相关操作
	'========================================================
	Public Sub UpdateStickTopic(ForumID, TopicID, DisplayOrder)
		Execute("DELETE FROM "& TablePre &"sticktopics WHERE tid = "& TopicID)
		Select Case DisplayOrder
			Case 3
				Execute("INSERT INTO "& TablePre &"sticktopics (tid, fid) SELECT "& TopicID &", fid FROM "& TablePre &"forums")
			Case 2
				Execute("INSERT INTO "& TablePre &"sticktopics (tid, fid) SELECT "& TopicID &", fid FROM "& TablePre &"forums WHERE fid IN("& Get_RootForumID(ForumID) &")")
			Case 1
				Execute("INSERT INTO "& TablePre &"sticktopics (tid, fid) VALUES ("& TopicID &", "& ForumID &")")
		End Select
	End Sub

	'========================================================
	'页面头部内容
	'========================================================
	Public Sub Header()
		Response.Write "<html><head><meta http-equiv=""Content-Type"" content=""text/html; charset="& Response.Charset &""" /><meta name=""keywords"" content="""& Base_Settings(1) &""" /><meta name=""description"" content="""& Base_Settings(2) &""" /><title>"& IIF(Len(PageTitle) > 0, PageTitle &" - ", "") & IIF(Len(Forum_Name) > 0, Forum_Name &" - ", "") & Base_Settings(0) &" - Powered by GBABook</title><link rel=""stylesheet"" href=""images/common/common.css"" /><script type=""text/javascript"">var bbsidentify = '"& CacheName &"';</script><script type=""text/javascript"" src=""js/common.js""></script>"& IIF(Len(PageBaseTarget) > 0, "<base target="""& PageBaseTarget &""" />", "") &"</head>"
	End Sub

	'========================================================
	'页面尾部内容
	'========================================================
	Public Sub Footer()
		Response.Write "<div class=""copyright"">Powered by <a href=""http://www.gbabook.com/"" target=""_blank"" class=""bluelink"">GBABook Board "& SHOWVERSION &"</a> &copy; 2004-2011<br />Processed in "& FormatNumber(Timer() - StartTime, 6, -1) &" second(s), "& dbQueryNum &" queries</div>"& SpecialInterface & Base_Settings(3) &"</body></html>"
	End Sub

	'========================================================
	'页面提示信息内容
	'========================================================
	Public Sub showTips(Message, URL, Action)
		If ScriptName <> "wap" Then
			Header()
			Response.Write "<body><table class=""tipsborder"" cellSpacing=""0"" cellPadding=""0"" align=""center""><tr><td class=""transborder"" width=""8"">&nbsp;</td><td class=""transborder"">&nbsp;</td><td class=""transborder"" width=""8"">&nbsp;</td></tr><tr><td class=""transborder"" width=""8"">&nbsp;</td><td class=""tipstd""><div class=""mainarea""><div class=""tipstd_bottom""></div><div class=""tips_header""><h1>提示信息</h1></div><div class=""tips_content"">"& IIF(Len(URL) > 0 Or Action = "HALTED", Message, "<span class=""pink"">"& Message &"</span>") &"<p>"

			Select Case Action
				Case "NOPERM"
					If UserID = 0 Then
						Response.Write "<form name=""login"" method=""post"" action="""& Login_Settings(1) &"?action=login""><table border=""0""><tr><td>用户名：</td><td><input type=""text"" name=""username"" size=""20"" tabindex=""1"" /> "& IIF(Login_Settings(0) = "2", "<a href=""login.asp"">注册新用户</a>", "") &"</td></tr><tr><td>密　码：</td><td><input type=""password"" name=""password"" size=""20"" tabindex=""2"" /> <a href=""pwdsafe.asp"">忘记密码</a></td></tr><tr><td></td><td><input type=""submit"" value="""& IIF(Login_Settings(0) = "0", "注册/登陆", "登陆") &""" class=""button"" /></td></tr></table></form>"
					End If

				Case "HALTED"

				Case Else
					If Len(URL) > 0 Then
						Response.Write "<a href="""& URL &""" target=""_self"">如果您的浏览器没有跳转，请点击这里。</a><script type=""text/javascript"">setTimeout(""self.location.replace('"& URL &"');"", 1000);</script>"
					Else
						Call closeDatabase()
						Response.Write "<a href=""javascript:history.go(-1);"" target=""_self"">点击这里返回上一页</a>"
					End If
			End Select

			Response.Write "</p></div></div></td><td class=""transborder"" width=""8"">&nbsp;</td></tr><tr><td class=""transborder"" width=""8"">&nbsp;</td><td class=""transborder"">&nbsp;</td><td class=""transborder"" width=""8"">&nbsp;</td></tr></table>"
			Footer()
		Else
			WapHeader()
			Call WapMessage(Message, "")
		End If
		Response.End()
	End Sub
End Class
%>