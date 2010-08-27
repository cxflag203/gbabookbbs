<!--#include file="wap.inc.asp"-->
<%
WapHeader()

Dim TopicInfo, PostInfo, PostID
Dim Page, PageCount, RecordCount, strSQL
Dim PostListArray, CountArray, FloorAddtion, theFloorNumber, blnBreakString, Offset, FirstMessage
Dim blnAllowReply, strError, fPage

TopicInfo = RQ.Query("SELECT fid, displayorder, uid, username, usershow, title, posttime, lastupdate, posts, price, ifanonymity, iflocked, iftask FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")

If Not IsArray(TopicInfo) Then
	Call WapMessage("帖子不存在或者已经被删除。", "")
End If

'检查版面id是否正确
If TopicInfo(0, 0) <> RQ.ForumID Then
	Call closeDatabase()
	Response.Redirect "viewtopic.asp?fid="& TopicInfo(0, 0) &"&amp;tid="& RQ.TopicID
	Response.End()
End If

'如果帖子设置了金钱限制,则检查金钱是否足够
If TopicInfo(9, 0) > 0 Then
	If Not RQ.IsModerator Then
		If RQ.UserCredits < TopicInfo(9, 0) And RQ.UserID <> TopicInfo(2, 0) Then 
			Call WapMessage(RQ.Other_Settings(0) &"达到"& TopicInfo(9, 0) &"才能查看该帖。", "")
		End If
	End If
End If

'检查置顶是否到期
If TopicInfo(12, 0) = 1 Then
	Dim TaskInfo
	TaskInfo = RQ.Query("SELECT expirytime FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)

	If IsArray(TaskInfo) Then			
		If TaskInfo(0, 0) < Now() Then
			'去除置顶
			Call RQ.UpdateStickTopic(RQ.ForumID, RQ.TopicID, 0)

			RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 0, iftask = 0 WHERE tid = "& RQ.TopicID)
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid = "& RQ.TopicID)
		End If
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET iftask = 0 WHERE tid = "& RQ.TopicID)
	End If
End If

PostID = SafeRequest(3, "pid", 0, 0, 0)
Offset = SafeRequest(3, "offset", 0, 0, 0)
Page = SafeRequest(3, "page", 0, 1, 0)
fPage = SafeRequest(3, "fpage", 0, 1, 0)

'验证当前用户状态是否允许回帖
Call Check_Status_Post()

If PostID = 0 Then
	RecordCount = TopicInfo(8, 0)
	RecordCount = IIF(RecordCount = 0, 1, RecordCount)
	PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Wap_Settings(4)))))
	Page = IIF(Page > PageCount, PageCount, Page)
	FloorAddtion = IIF(Page = 1, 0, 1)

	'拼接sql语句
	If Page = 1 Then
		strSQL = "SELECT TOP "& IntCode(RQ.Wap_Settings(4)) + 1 &" pid, iffirst, uid, username, usershow, message, posttime, ifanonymity, ratemark FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" ORDER BY posttime ASC"
	Else
		strSQL = "SELECT TOP "& RQ.Wap_Settings(4) &" pid, iffirst, uid, username, usershow, message, posttime, ifanonymity, ratemark FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" AND posttime > (SELECT MAX(posttime) FROM (SELECT TOP "& IntCode(RQ.Wap_Settings(4)) * (Page - 1) + 1 &" posttime FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" ORDER BY posttime ASC) AS tblTemp) ORDER BY posttime ASC"
	End If

	'查询回复
	PostListArray = RQ.Query(strSQL)
	If Not IsArray(PostListArray) Then
		Call WapMessage("帖子出错。","")
	End If

	Call closeDatabase()

	Call Append("标题:"& WapCode(TopicInfo(5, 0), 0) &"("& TopicInfo(8, 0) &"条回复)<br /><br />")

	CountArray = UBound(PostListArray, 2)
	For i = 0 To CountArray
		PostListArray(5, i) = TopicCode(PostListArray(5, i))
		If PostListArray(1, i) = 1 Then
			FirstMessage = PostListArray(5, i)

			If Offset > Len(FirstMessage) Then
				Offset = 0
			End If

			If Offset > 0 Then
				FirstMessage = Mid(FirstMessage, Offset)
			End If

			If Len(FirstMessage) > IntCode(RQ.Wap_Settings(5)) Then
				FirstMessage = Left(FirstMessage, IntCode(RQ.Wap_Settings(5))) &"..."
				blnBreakString = True
			End If

			Call Append(ReverseCode(FirstMessage) &"<br />---")

			If PostListArray(2, i) > 0 And PostListArray(7, i) = 0 Then
				Call Append("<a href=""pm.asp?action=sendpm&amp;u="& Server.URLEncode(PostListArray(3, i)) &""">"& PostListArray(3, i) &"</a>")
			Else
				Call Append(PostListArray(4, i))
			End If

			Call Append(" ("& PostListArray(6, i) &")")

			If blnBreakString Then
				Call Append(" <a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;offset="& Offset + IntCode(RQ.Wap_Settings(5)) &""">下页</a>")
			End If

			If Offset > 0 Then
				Call Append(" <a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;offset="& Offset - IntCode(RQ.Wap_Settings(5)) &""">上页</a>")
			End If 

			Call Append("<br /><br />")
			
			If blnAllowReply Or (RQ.AllowPost And RQ.F_AllowPost = 1) Or RQ.DisablePostCtrl = 1 Then
				If blnAllowReply Then
					Call Append("<a href=""post.asp?action=reply&amp;fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &""">回复本贴</a>")
				End If

				If (RQ.AllowPost And RQ.F_AllowPost = 1) Or RQ.DisablePostCtrl = 1 Then
					Call Append("|<a href=""post.asp?fid="& RQ.ForumID &""">发表帖子</a>")
				End If

				Call Append("<br /><br />")
			End If
		Else
			'楼层数字
			theFloorNumber = IntCode(RQ.Wap_Settings(4)) * (Page - 1) + i + FloorAddtion

			Call Append("回复("& theFloorNumber &"):")

			If Len(PostListArray(5, i)) > IntCode(RQ.Wap_Settings(5)) Then
				Call Append("<a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;pid="& PostListArray(0, i) &"&amp;f="& theFloorNumber &"&amp;page="& Page &""">"& ReverseCode(Left(Replace(PostListArray(5, i), Chr(12), " "), IntCode(RQ.Wap_Settings(5)))) &"...</a>")
			Else
				Call Append(ReverseCode(PostListArray(5, i)))
			End If

			Call Append("<br />---")

			If PostListArray(2, i) > 0 And PostListArray(7, i) = 0 Then
				Call Append("<a href=""pm.asp?action=sendpm&amp;u="& Server.URLEncode(PostListArray(3, i)) &""">"& PostListArray(3, i) &"</a>")
			Else
				Call Append(PostListArray(4, i))
			End If

			Call Append(IIF(PostListArray(8, i) > 0, " +"& PostListArray(8, i), "") &" ("& PostListArray(6, i) &")<br /><br />")
		End If
	Next

	'显示分页
	If PageCount > 1 Then
		Call ShowWapPage(Page, PageCount, RecordCount, "viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID)
		Call Append("<br /><br />")
	End If
Else
	PostInfo = RQ.Query("SELECT uid, username, usershow, message, posttime, ifanonymity, ratemark FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" AND pid="& PostID)
	If Not IsArray(TopicInfo) Then
		Call WapMessage("该回复内容不存在或者已经被删除。", "")
	End If

	Call closeDatabase()

	theFloorNumber = SafeRequest(3, "f", 0, 0, 0)
	Call Append("帖子:<a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;page="& Page &""">"& TopicCode(TopicInfo(5, 0)) &"</a><br /><br />回复("& IIF(theFloorNumber = 0, "*", theFloorNumber) &"):")

	FirstMessage = TopicCode(PostInfo(3, 0))

	If Offset > Len(FirstMessage) Then
		Offset = 0
	End If

	If Offset > 0 Then
		FirstMessage = Mid(FirstMessage, Offset)
	End If

	If Len(FirstMessage) > IntCode(RQ.Wap_Settings(5)) Then
		FirstMessage = Left(FirstMessage, IntCode(RQ.Wap_Settings(5))) &"..."
		blnBreakString = True
	End If

	Call Append(ReverseCode(FirstMessage))

	If blnBreakString Then
		Call Append("<br /><a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;pid="& PostID &"&amp;f="& theFloorNumber &"&amp;offset="& Offset + IntCode(RQ.Wap_Settings(5)) &"&amp;page="& Page &""">下页</a>")
	End If

	If Offset > 0 Then
		Call Append(" <a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"&amp;pid="& PostID &"&amp;f="& theFloorNumber &"&amp;offset="& Offset - IntCode(RQ.Wap_Settings(5)) &"&amp;page="& Page &""">上页</a>")
	End If

	Call Append("<br /><br />")
End If

If blnAllowReply Then
	Call Append("<input type=""text"" name=""message"" value="""" size=""10"" emptyok=""true""/><anchor title=""提交"">快速回复<go method=""post"" href=""post.asp?action=newreply&amp;fid="& RQ.ForumID &"&amp;tid="& RQ.TopicID &"""><postfield name=""message"" value=""$(message)""/></go></anchor><br />")
End If

If RQ.UserID > 0 Then
	Call Append("<a href=""membermisc.asp?action=savefavor&amp;tid="& RQ.TopicID &""">设为我的收藏</a><br /><br />")
End If

Call Append("&gt;&gt;<a href=""redirect.asp?action=next&amp;tid="& RQ.TopicID &""">下一帖</a><br />&lt;&lt;<a href=""redirect.asp?action=previous&amp;tid="& RQ.TopicID &""">上一帖</a><br /><a href=""forumdisplay.asp?fid="& RQ.ForumID &"&amp;page="& fPage &""">返回帖子列表</a>")

'========================================================
'判断是否允许回帖
'========================================================
Sub Check_Status_Post()
	blnAllowReply = False

	'当前用户组是否允许回帖
	If RQ.AllowReply = 0 Then
		strError = "您目前的身份是"& RQ.UserGroupName &"，还不能回帖子哟。"
		Exit Sub
	End If

	'当前用户组在当前版面是否允许回帖
	If Len(RQ.Forum_PostReplyPerm) = 0 Then
		If RQ.UserID = 0 Then
			strError = "您现在是游客，登录之后才能回帖。"
			Exit Sub
		End If
	Else
		If Not InStr(","& RQ.Forum_PostReplyPerm &",", ","& RQ.UserGroupID &",") > 0 Then
			strError = "您当前的身份("& RQ.UserGroupName &")不能在“"& RQ.Forum_Name &"”版回帖……"
			Exit Sub
		End If
	End If

	'当前版面对回帖子要求的最低金钱限制
	If RQ.F_ReplyNdCredits > 0 And RQ.UserCredits < RQ.F_ReplyNdCredits And RQ.DisablePostCtrl = 0 Then
		strError = RQ.Other_Settings(0) &"达到"& RQ.F_ReplyNdCredits &"就可以回帖了哟，加油！"
		Exit Sub
	End If

	'当前版面是否允许回帖
	If RQ.F_AllowPost = 0 And RQ.DisablePostCtrl = 0 Then
		strError = "当前版面为只读……"
		Exit Sub
	End If

	'帖子是否允许回复
	If TopicInfo(11, 0) > 0 Then 
		strError = "该帖被设为不允许回复。"
		Exit Sub
	End If

	'站点是否允许回帖
	If RQ.CheckTimeSetting(RQ.Time_Settings(1)) And RQ.DisablePeriodCtrl = 0 Then
		strError = "在以下的时间段里，论坛处于只读状态：<br />"& Replace(RQ.Time_Settings(1), "_", "<br />")
		Exit Sub
	End If

	'帖子是否过期
	If ABS(RQ.F_AutoClose) > 0 And RQ.DisablePostCtrl = 0 Then
		If RQ.F_AutoClose < 0 Then
			If DateDiff("d", TopicInfo(6, 0), Now()) > ABS(RQ.F_AutoClose) Then
				strError = "该帖子已经过期，禁止回复。"
				Exit Sub
			End If
		Else
			If DateDiff("d", TopicInfo(7, 0), Now()) > RQ.F_AutoClose Then
				strError = "该帖子已经过期，禁止回复。"
				Exit Sub
			End If
		End If
	End If

	'是否连续灌水
	If IntCode(RQ.Topic_Settings(10)) > 0 And DateDiff("s", NumtoDate(RQ.UserPostFloodCtrl), Now()) < 0 And RQ.DisablePostCtrl = 0 Then
		strError = "现在的时间："& FormatDateTime(Now(), 3) &"，可发言时间："& FormatDateTime(NumtoDate(RQ.UserPostFloodCtrl), 3) &"，请先看看别的帖子……"
		Exit Sub
	End If

	blnAllowReply = True
End Sub

'========================================================
'帖子内容转义和处理特殊内容
'========================================================
Function TopicCode(str)
	Dim regEx

	Set regEx = New Regexp
	regEx.IgnoreCase = True
	regEx.Global = True
	regEx.Pattern = "<br(.*?)>"
	str = regEx.Replace(str, Chr(12))
	regEx.Pattern = "\[hide\](.+?)\[\/hide\]"
	str = regEx.Replace(str, "[隐藏内容]")
	regEx.Pattern = "\[hide=(\d+)\](.+?)\[\/hide\]"
	str = regEx.Replace(str, "[隐藏内容]")
	regEx.Pattern = "\[attach\](\d+)\[\/attach\]"
	str = regEx.Replace(str, "")
	regEx.Pattern = "<(.[^>]*)>"
	str = regEx.Replace(str, "")
	Set regEx = Nothing

	str = Replace(str, "&amp;", "&")
	str = Replace(str, "&#39;", "'")
	str = Replace(str, "&quot;", """")
	str = Replace(str, "&lt;", "<")
	str = Replace(str, "&gt;", ">")
	str = Replace(str, "&nbsp;", " ")

	TopicCode = str
End Function

'========================================================
'再次转义
'========================================================
Function ReverseCode(str)
	str = Replace(str, "&", "&amp;")
	str = Replace(str, """", "&quot;")
	str = Replace(str, "<", "&lt;")
	str = Replace(str, ">", "&gt;")
	str = Replace(str, Chr(12), "<br />")
	ReverseCode = str
End Function

WapFooter()
%>