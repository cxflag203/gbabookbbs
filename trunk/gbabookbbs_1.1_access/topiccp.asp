<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "HALTED")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "ajaxquot"
		Call AjaxQuot()
	Case "savereport"
		Call SaveReport()
	Case "favorites"
		Call Favorites()
	Case "leagueelite"
		Call LeageueElite()
	Case "saveleagueelite"
		Call SaveLeagueElite()
	Case "leaguetopic"
		Call LeagueTopic()
	Case "saveleaguetopic"
		Call SaveLeagueTopic()
	Case Else
		Call Main()
End Select

'========================================================
'Ajax读取引用内容
'========================================================
Sub AjaxQuot()
	Dim PostID, PostInfo, strQuotMessage, theFloorNumber
	PostID = SafeRequest(3, "pid", 0, 0, 0)
	theFloorNumber = SafeRequest(3, "f", 0, 0, 0)
	If PostID > 0 Then
		PostInfo = RQ.Query("SELECT username, usershow, message, ifanonymity FROM "& TablePre &"posts WHERE pid = "& PostID)
		Call closeDatabase()
		If IsArray(PostInfo) Then
			strQuotMessage = PostInfo(2, 0)
			If InStr(strQuotMessage, "[/hide]") > 0 Then
				strQuotMessage = Preg_Replace(strQuotMessage, "\[hide\](.+?)\[\/hide\]", "***隐藏内容***")
				strQuotMessage = Preg_Replace(strQuotMessage, "\[hide=(\d+)\](.+?)\[\/hide\]", "***隐藏内容***")
			End If
			strQuotMessage = "<div class=""quotetop"">引用"& IIF(theFloorNumber > 0, theFloorNumber &"楼", "") & IIF(PostInfo(3, 0) = 0, PostInfo(0, 0), PostInfo(1, 0)) &"的回复：</div><div class=""quotemain"">"& strQuotMessage &"</div>"
			Response.Write "<br />"& strQuotMessage &"<span style=""float: right;""><a href=""###"" onclick=""javascript:$('quot').innerHTML = $('quot_message').value = '';"" class=""bluelink"">取消引用</a></span><script type=""text/javascript"">$('quot_message').value='"& strQuotMessage &"'</script>"
		End If
	End If
End Sub

'========================================================
'发送举报内容
'========================================================
Sub SaveReport()
	Dim TopicInfo, Message

	TopicInfo = RQ.Query("SELECT fid FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子已经被删除或者未通过审核。", "", "")
	End If

	Message = SafeRequest(2, "message", 1, "", 0)
	If Len(CheckContent(Message)) = 0 Then
		Call RQ.showTips("请填写好举报内容。", "", "")
	End If

	Message = Replace(Message, vbCrLf, "<br />")
	Message = "向您举报以下的帖子，详细内容请访问：<br /><a href=""viewtopic.asp?fid="& TopicInfo(0, 0) &"&tid="& RQ.TopicID &""" class=""underline"" target=""_blank"">viewtopic.asp?fid="& TopicInfo(0, 0) &"&tid="& RQ.TopicID &"</a><p>举报内容是："& Message

	RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message) SELECT '"& RQ.UserName &"', "& RQ.UserID &", uid, '"& Message &"' FROM "& TablePre &"members WHERE (uid IN(SELECT uid FROM "& TablePre &"moderators WHERE fid = "& TopicInfo(0, 0) &")) OR (usergroupid IN(1,2))")

	Call closeDatabase()
	Call Confirm("举报信息已经成功提交。")
End Sub

'========================================================
'收藏(去除)帖子
'========================================================
Sub Favorites()
	Dim TopicInfo, FavorNum, FavorInfo

	TopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子已经被删除或者未通过审核。")
	End If

	'普通用户的收藏数量限制
	If IntCode(RQ.User_Settings(4)) > 0 And Not RQ.IsModerator Then
		FavorNum = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID)(0)

		If FavorNum > IntCode(RQ.User_Settings(4)) Then
			Call Confirm("您的收藏夹已经达到"& RQ.User_Settings(4) &"条帖子的限制。")
		End If
	End If

	'帖子是否已经被收藏
	FavorInfo = RQ.Query("SELECT 1 FROM "& TablePre &"favorites WHERE tid = "& RQ.TopicID &" AND uid = "& RQ.UserID)

	If Not IsArray(FavorInfo) Then
		RQ.Execute("INSERT INTO "& TablePre &"favorites (uid, tid) VALUES ("& RQ.UserID &", "& RQ.TopicID &")")
		Call Confirm("该帖子已经添加到收藏夹。")
	Else
		'已经被收藏过则删除收藏
		RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID &" AND tid = "& RQ.TopicID)
		Call Confirm("该帖子已经从收藏夹移除。")
	End If
End Sub

'========================================================
'设为联盟精华帖
'========================================================
Sub LeageueElite()
	Dim TopicInfo, LeagueListArray

	TopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子已经被删除或者未通过审核。", "", "")
	End If

	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND lm.groupid = 1 ORDER BY l.leagueid ASC")

	'如果不是联盟盟主则更新用户在联盟的最高职位
	If Not IsArray(LeagueListArray) Then
		Call RQ.UpdateLGroupID(RQ.UserID)
		Call Confirm("只有联盟盟主才能进行此操作。")
	End If

	Call closeDatabase()
	RQ.Header()
%>
<body class="blankbg">
<form id="leagueelite" method="post" action="?action=saveleagueelite">
  <input type="hidden" name="topicid" value="<%= RQ.TopicID %>" />
  <select name="lid">
    <% If IsArray(LeagueListArray) Then %>
    <% For i = 0 To UBound(LeagueListArray, 2) %>
    <option value="<%= LeagueListArray(0, i) %>"><%= LeagueListArray(1, i) %></option>
    <% Next %>
    <% End If %>
  </select>
  <input type="submit" id="btnsubmit" value="加入精华区" class="button" />
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'保存联盟精华帖
'========================================================
Sub SaveLeagueElite()
	If RQ.L_UserGroupID <> 1 Then
		Call Confirm("只有联盟盟主才能进行此操作。")
	End If

	Dim TopicID, TopicInfo, EliteInfo, LeagueTopicInfo, PostListArray
	Dim blnSaveTopic, s, Refer

	TopicID = SafeRequest(2, "topicid", 0, 0, 0)
	TopicInfo = RQ.Query("SELECT uid, username, title, lastupdate, leagueid FROM "& TablePre &"topics WHERE tid = "& TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call Confirm("帖子已经被删除或者未通过审核。")
	End If

	'帖子如果不是联盟贴则同时也加入联盟帖
	LeagueTopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leaguetopics WHERE leagueid = "& RQ.LeagueID &" AND tid = "& TopicID)
	If Not IsArray(LeagueTopicInfo) Then
		If TopicInfo(4, 0) = 0 Then
			RQ.Execute("UPDATE "& TablePre &"topics SET leagueid = "& RQ.LeagueID &" WHERE tid = "& TopicID)
		End If

		RQ.Execute("INSERT INTO "& TablePre &"leaguetopics (leagueid, tid) VALUES ("& RQ.LeagueID &", "& TopicID &")")

		'更新联盟帖子统计
		RQ.Execute("UPDATE "& TablePre &"leagues SET topics = topics + 1 WHERE leagueid = "& RQ.LeagueID)
	End If

	EliteInfo = RQ.Query("SELECT eliteid, lastupdate FROM "& TablePre &"leagueelite WHERE leagueid = "& RQ.LeagueID &" AND tid = "& TopicID)
	If IsArray(EliteInfo) Then
		If DateDiff("s", EliteInfo(1, 0), TopicInfo(3, 0)) <> 0 Then
			blnSaveTopic = True
		End If			
	Else
		blnSaveTopic = True
	End If

	If blnSaveTopic Then
		'读取帖子内容
		PostListArray = RQ.Query("SELECT uid, usershow, message, posttime, ifanonymity FROM "& TablePre &"posts WHERE tid = "& TopicID &" ORDER BY posttime ASC")
		If IsArray(PostListArray) Then
			For i = 0 To UBound(PostListArray, 2)
				If i = 0 Then
					s = s & PostListArray(2, i)
				Else
					If PostListArray(4, i) = 0 And TopicInfo(0, 0) = PostListArray(0, i) Then
						s = s &"<span class=""red""><strong>【楼主】</strong></span>"
					End If
					s = s &"回复("& i &"):<span title="""& PostListArray(3, i) &""">"& PostListArray(2, i) &"</span>"
				End If

				s = s & "<br />---"

				'游客用斜体显示
				If PostListArray(0, i) = 0 Then
					s = s & "<em>"& PostListArray(1, i) &"</em>"
				Else
					s = s & PostListArray(1, i)
				End If

				s = s &"<p>"
			Next

			Erase PostListArray

			'加入/更新联盟精华帖
			If IsArray(EliteInfo) Then
				RQ.Execute("UPDATE "& TablePre &"leagueelite SET uid = "& TopicInfo(0, 0) &", username = '"& TopicInfo(1, 0) &"', title = '"& TopicInfo(2, 0) &"', message = '"& s &"', lastupdate = '"& TopicInfo(3, 0) &"' WHERE eliteid = "& EliteInfo(0, 0))
			Else
				RQ.Execute("INSERT INTO "& TablePre &"leagueelite (tid, leagueid, uid, username, title, message, lastupdate) VALUES ("& TopicID &", "& RQ.LeagueID &", "& TopicInfo(0, 0) &", '"& TopicInfo(1, 0) &"', '"& TopicInfo(2, 0) &"', '"& s &"', '"& TopicInfo(3, 0) &"')")

				'写入联盟日志
				RQ.Execute("INSERT INTO "& TablePre &"leaguelogs (leagueid, typeid, username, operation) VALUES ("& RQ.LeagueID &", 2, '"& RQ.UserName &"', '联盟添加精华帖子:"& TopicID &"("& RQ.UserIP &")')")
			End If

			s = Empty
		End If
	End If

	Call closeDatabase()

	'根据提交来源返回
	Refer = SafeRequest(3, "r", 1, "", 0)
	Select Case Refer
		Case "le"'浏览精华帖
			Call RQ.showTips("精华帖已经更新。", "leagueelite.asp?action=view&lid="& RQ.LeagueID &"&eliteid="& EliteInfo(0, 0), "")
		Case "ln"'联盟贴
			Call WarnBack("帖子成功加入精华区。")
		Case Else'浏览帖子
			Call Confirm("帖子成功加入精华区。")
	End Select
End Sub

'========================================================
'联盟贴设置
'========================================================
Sub LeagueTopic()
	Dim TopicInfo, LeagueListArray

	TopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子已经被删除或者未通过审核。", "", "")
	End If

	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND lm.groupid IN(1,2) ORDER BY l.leagueid ASC")

	'如果不是联盟盟主则更新用户在联盟的最高职位
	If Not IsArray(LeagueListArray) Then
		Call RQ.UpdateLGroupID(RQ.UserID)
		Call Confirm("只有联盟盟主和联盟管理员才能进行此操作。")
	End If

	Call closeDatabase()
	RQ.Header()
%>
<body class="blankbg">
<form id="leaguetopic" method="post" action="?action=saveleaguetopic">
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>" />
  <select name="lid">
    <% For i = 0 To UBound(LeagueListArray, 2) %>
    <option value="<%= LeagueListArray(0, i) %>"><%= LeagueListArray(1, i) %></option>
    <% Next %>
  </select>
  <input type="submit" name="addtopic" value="加入" class="button" /><input type="submit" name="removetopic" value="去除" class="button" />
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'保存(去除)联盟贴
'========================================================
Sub SaveLeagueTopic()
	If RQ.L_UserGroupID <> 1 And RQ.L_UserGroupID <> 2 Then
		Call Confirm("只有联盟盟主和联盟管理员才能进行此操作。")
	End If

	Dim TopicInfo, LeagueInfo

	TopicInfo = RQ.Query("SELECT leagueid FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子已经被删除或者未通过审核。", "", "")
	End If

	'帖子是否已经是该联盟的联盟贴
	LeagueInfo = RQ.Query("SELECT 1 FROM "& TablePre &"leaguetopics WHERE leagueid = "& RQ.LeagueID &" AND tid = "& RQ.TopicID)

	'加入联盟贴
	If Len(Request.Form("addtopic")) > 0 Then
		If Not IsArray(LeagueInfo) Then
			'加入联盟
			RQ.Execute("INSERT INTO "& TablePre &"leaguetopics (leagueid, tid) VALUES ("& RQ.LeagueID &", "& RQ.TopicID &")")

			'帖子是否还没有联盟标记
			If TopicInfo(0, 0) = 0 Then
				RQ.Execute("UPDATE "& TablePre &"topics SET leagueid = "& RQ.LeagueID &" WHERE tid = "& RQ.TopicID)
			End If

			'更新联盟帖子统计
			RQ.Execute("UPDATE "& TablePre &"leagues SET topics = topics + 1 WHERE leagueid = "& RQ.LeagueID)

			'写日志
			RQ.Execute("INSERT INTO "& TablePre &"leaguelogs (leagueid, typeid, username, operation) VALUES ("& RQ.LeagueID &", 1, '"& RQ.UserName &"', '联盟添加帖子:"& RQ.TopicID &"("& RQ.UserIP &")')")
		End If

		Call Confirm("帖子已经加入到联盟。")

	'帖子从联盟去除
	ElseIf Len(Request.Form("removetopic")) > 0 Then
		If IsArray(LeagueInfo) Then
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE leagueid = "& RQ.LeagueID &" AND tid = "& RQ.TopicID)

			'帖子的联盟标记如果是该联盟则清除
			If TopicInfo(0, 0) = RQ.LeagueID Then
				RQ.Execute("UPDATE "& TablePre &"topics SET leagueid = 0 WHERE tid = "& RQ.TopicID)
			End If

			'更新联盟帖子统计
			RQ.Execute("UPDATE "& TablePre &"leagues SET topics = topics - 1 WHERE leagueid = "& RQ.LeagueID)

			'写日志
			RQ.Execute("INSERT INTO "& TablePre &"leaguelogs (leagueid, typeid, username, operation) VALUES ("& RQ.LeagueID &", 3, '"& RQ.UserName &"', '联盟去除帖子:"& RQ.TopicID &"("& RQ.UserIP &")')")
		End If

		Call Confirm("帖子已经从联盟去除。")
	End If
End Sub

'========================================================
'举报帖子
'========================================================
Sub Main()
	Dim TopicInfo
	TopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")

	Call closeDatabase()

	If Not IsArray(TopicInfo) Then
		Call RQ.showTips("帖子已经被删除或者未通过审核。", "", "")
	End If

	RQ.Header()
%>
<body class="blankbg">
<form id="report" method="post" action="?action=savereport" onKeyDown="fastpost('btnsubmit');" onSubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>" />
  如果您发现不良行为或不良信息可通过该功能通知管理员，请不要乱用。 <br />
  <span style="background: #F00; color: #FFF">举报范围</span>：涉及反动，色情(含有色情倾向的图片)，宣扬邪教，泄露国家机密，破坏安定团结(含谣言与煽动性的言论)，破坏国家领导人形象，以及任何国家法律法规禁止发布的内容。破坏其他用户正常浏览的行为(如不良Html代码，不完整的Html代码，大面积的重复问题或图片，名目张胆的抢楼行为)。 <br />
  <textarea rows="5" name="message" cols="35"></textarea>
  <br />
  <input type="submit" id="btnsubmit" value="确定" class="button" />
</form>
<%
	RQ.Footer()
End Sub
%>
