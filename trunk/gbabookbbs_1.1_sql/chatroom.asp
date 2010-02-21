<!--#include file="include/inc.asp"-->
<%
'验证聊天室是否关闭
If RQ.Chat_Settings(0) = "0" Then
	Call RQ.showTips("聊天室目前处于关闭状态。", "", "HALTED")
End If

'验证用户是否登陆
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

Dim Action, RoomID

Action = Request.QueryString("action")
RoomID = SafeRequest(3, "roomid", 0, IntCode(Request.Cookies(CacheName &"chatroom")), 0)

If RoomID = 0 Or RoomID > IntCode(RQ.Chat_Settings(1)) Then
	RoomID = 1
End If

Response.Cookies(CacheName &"chatroom") = RoomID

Select Case Action
	Case "useitem"
		Call UseItem()
	Case "setanouncemsg"
		Call SetAnounceMsg()
	Case "deletemsg"
		Call DeleteMsg()
	Case "postmsg"
		Call PostMsg()
	Case "msglist"
		Call MsgList()
	Case "postpanel"
		Call PostPanel()
	Case Else
		Call Main()
End Select

'========================================================
'使用道具
'========================================================
Sub UseItem()
	Dim Identifier, ItemInfo
	Identifier = SafeRequest(3, "identifier", 1, "", 0)

	ItemInfo = RQ.Query("SELECT itemid, name FROM "& TablePre &"items WHERE identifier = '"& Identifier &"' AND available = 1")
	If Not IsArray(ItemInfo) Then
		Call WarnBack("道具无效。")
	End If

	If Not RQ.CheckItem(ItemInfo(0, 0), 1, TRUE) Then
		Call WarnBack("目前您没有"& ItemInfo(1, 0) &"。")
	End If

	Select Case Identifier
		Case "clearallanonymity"
			Call ClearAllAnonymity()
		Case "clearchatroom"
			Call ClearChatRoom()
		Case "dice"
			Call Dice()
	End Select
End Sub

'========================================================
'删除某人的发言(道具)
'========================================================
Sub ClearAllAnonymity()
	Dim UserName, AffectRowCount, strMessage

	UserName = SafeRequest(3, "u", 1, "", 0)

	If Len(UserName) > 0 Then
		AffectRowCount = RQ.Execute("DELETE FROM "& TablePre &"chatmessages WHERE roomid = "& RoomID &" AND usershow = N'"& UserName &"'")

		If AffectRowCount > 0 Then
			strMessage = UserName &"的发言被"& RQ.UserName &"电得无影无踪。"
			RQ.Execute("INSERT INTO "& TablePre &"chatmessages (roomid, usershow, message) VALUES ("& RoomID &", N'<b>系统提示</b>', N'"& strMessage &"')")
		End If
	End If

	Call MsgList()
End Sub

'========================================================
'聊天室清屏(道具)
'========================================================
Sub ClearChatRoom()
	Dim strMessage, ArrayTips, RndNumber

	RQ.Execute("DELETE FROM "& TablePre &"chatannounces WHERE roomid = "& RoomID)
	RQ.Execute("DELETE FROM "& TablePre &"chatmessages WHERE roomid = "& RoomID)

	Randomize
	ArrayTips = Split(RQ.Chat_Settings(8) & vbCrLf, vbCrLf)
	strMessage = Replace(ArrayTips(Int((UBound(ArrayTips) + 1) * Rnd)), "{username}", RQ.UserName)

	If Len(strMessage) > 0 Then
		RQ.Execute("INSERT INTO "& TablePre &"chatmessages (roomid, usershow, message) VALUES ("& RoomID &", N'<b>系统提示</b>', N'"& strMessage &"')")
	End If

	Call MsgList()
End Sub

'========================================================
'掷筛子(道具)
'========================================================
Sub Dice()
	Dim a, b, c, d, e, f
	Dim GetCredits, UserInfo, strMessage

	'防止发言过于频繁
	Call CheckFloodCtrl()

	Randomize
	a = Int(6 * Rnd + 1)
	b = Int(6 * Rnd + 1)
	c = Int(6 * Rnd + 1)
	d = Int(6 * Rnd + 1)
	e = Int(6 * Rnd + 1)
	f = Int(6 * Rnd + 1)

	'这个算法有点烂耶@_@
	If IntCode(a & b & c & d & e & f) / a = 111111 Then 
		GetCredits = IntCode(RQ.Item_Settings(7))
	ElseIf a + 1 = b And b + 1 = c And c + 1 = d And d + 1 = e And e + 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(7))
	ElseIf a - 1 = b And b - 1 = c And c - 1 = d And d - 1 = e And e - 1 = f Then 
		GetCredits = IntCode(RQ.Item_Settings(7))
	ElseIf IntCode(a & b & c & d & e) / a = 11111 Or IntCode(b & c & d & e & f) / b = 11111 Then
		GetCredits = IntCode(RQ.Item_Settings(8))
	ElseIf a + 1 = b And b + 1 = c And c + 1 = d And d + 1 = e Then
		GetCredits = IntCode(RQ.Item_Settings(8))
	ElseIf b + 1 = c And c + 1 = d And d + 1 = e And e + 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(8))
	ElseIf a - 1 = b And b - 1 = c And c - 1 = d And d - 1 = e Then
		GetCredits = IntCode(RQ.Item_Settings(8))
	ElseIf b - 1 = c And c - 1 = d And d - 1 = e And e - 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(8))
	ElseIf IntCode(a & b & c & d) / a = 1111 Or IntCode(b & c & d & e) / b = 1111 Or IntCode(c & d & e & f) / c = 1111 Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf a + 1 = b And b + 1 = c And c + 1 = d Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf b + 1 = c And c + 1 = d And d + 1 = e Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf c + 1 = d And d + 1 = e And e + 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf a - 1 = b And b - 1 = c And c - 1 = d Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf b - 1 = c And c - 1 = d And d - 1 = e Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf c - 1 = d And d - 1 = e And e - 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(9))
	ElseIf IntCode(a & b & c) / a = 111 Or IntCode(b & c & d) / b = 111 Or IntCode(c & d & e) / c = 111 Or IntCode(d & e & f) / d = 111 Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf a + 1 = b And b + 1 = c Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf b + 1 = c And c + 1 = d Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf c + 1 = d And d + 1 = e Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf d + 1 = e And e + 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf a - 1 = b And b - 1 = c Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf b - 1 = c And c - 1 = d Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf c - 1 = d And d - 1 = e Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf d - 1 = e And e - 1 = f Then
		GetCredits = IntCode(RQ.Item_Settings(10))
	ElseIf a = b Or b = c Or c = d Or d = e Or e = f Then
		GetCredits = IntCode(RQ.Item_Settings(11))
	End If

	strMessage = RQ.UserName &"掷出骰子,数字为:"& a &","& b &","& c &","& d &","& e &","& f

	'如果中奖则更新用户金钱数量
	If GetCredits > 0 Then
		RQ.Execute("UPDATE "& TablePre &"members SET credits = credits + "& GetCredits &" WHERE uid = "& RQ.UserID)
		strMessage = strMessage &",获得"& GetCredits & RQ.Other_Settings(0)
	End If

	RQ.Execute("INSERT INTO "& TablePre &"chatmessages (uid, roomid, usershow, message) VALUES ("& RQ.UserID &", "& RoomID &", N'<b>系统提示</b>', N'"& strMessage &"')")

	Call MsgList()
End Sub

'========================================================
'设置聊天室公告
'========================================================
Sub SetAnounceMsg()
	Dim Message, n

	Message = SafeRequest(3, "message", 1, "", 0)
	If Len(CheckContent(Message)) > 0 Then
		Message = IIF(Len(Message) > 100, Left(Message, 100), Message)

		If RQ.UserCredits >= IntCode(RQ.Chat_Settings(7)) Then
			RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& RQ.Chat_Settings(7) &" WHERE uid = "& RQ.UserID)

			n = RQ.Execute("UPDATE "& TablePre &"chatannounces SET uid = "& RQ.UserID &", usershow = N'"& RQ.UserName &"', message = N'"& Message &"' WHERE roomid = "& RoomID)
			If n = 0 Then
				RQ.Execute("INSERT INTO "& TablePre &"chatannounces (roomid, uid, usershow, message) VALUES ("& RoomID &", "& RQ.UserID &", N'"& RQ.UserName &"', N'"& Message &"')")
			End If

			RQ.Execute("INSERT INTO "& TablePre &"chatmessages (roomid, usershow, message) VALUES ("& RoomID &", N'<b>系统提示</b>', N'"& RQ.UserName &"将本房间公告设置为："& Message &"')")
		End If
	End If

	Call MsgList()
End Sub

'========================================================
'删除发言
'========================================================
Sub DeleteMsg()
	Dim MessageID, MessageInfo

	MessageID = SafeRequest(3, "msgid", 0, 0, 0)

	If RQ.UserCredits > IntCode(RQ.Chat_Settings(5)) And RQ.UserCredits > IntCode(RQ.Chat_Settings(6)) Then
		RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& RQ.Chat_Settings(6) &" WHERE uid = "& RQ.UserID)

		MessageInfo = RQ.Query("SELECT 1 FROM "& TablePre &"chatmessages WHERE msgid = "& MessageID)
		If IsArray(MessageInfo) Then
			RQ.Execute("UPDATE "& TablePre &"chatmessages SET message = N'"& RQ.UserName &"删除了一条发言', usershow = N'<b>系统提示</b>' WHERE msgid = "& MessageID)
		End If
	End If

	Call MsgList()
End Sub

'========================================================
'防止发言过于频繁
'========================================================
Sub CheckFloodCtrl()
	Dim MessageInfo
	MessageInfo = RQ.Query("SELECT TOP 1 posttime FROM "& TablePre &"chatmessages WHERE roomid = "& RoomID &" AND uid = "& RQ.UserID &" ORDER BY posttime DESC")
	If IsArray(MessageInfo) Then
		If DateDiff("s", MessageInfo(0, 0), Now()) <= IntCode(RQ.Chat_Settings(2)) Then
			Call RQ.showTips("发言（掷出骰子）不要太频繁，时间间隔为"& RQ.Chat_Settings(2) &"秒钟。", "", "")
		End If
	End If
End Sub

'========================================================
'聊天室发言
'========================================================
Sub PostMsg()
	'验证用户组是否允许发言
	If RQ.AllowChat = 0 Then
		Call RQ.showTips("您目前的身份是"& RQ.UserGroupName &"，无法在聊天室发言。", "", "NOPERM")
	End If

	'防止发言过于频繁
	Call CheckFloodCtrl()

	Dim Message
	If RQ.UserCredits >= IntCode(RQ.Chat_Settings(4)) And RQ.AllowHTML = 1 Then
		Message = SafeRequest(2, "message", 1, "", 1)
	Else
		Message = SafeRequest(2, "message", 1, "", 0)
	End If

	'词语过滤
	Message = WordsFilter(Message)

	If Len(CheckContent(Message)) > 0 Then
		Message = IIF(Len(Message) > 255, Left(Message, 255), Message)
		RQ.Execute("INSERT INTO "& TablePre &"chatmessages (roomid, uid, usershow, message) VALUES ("& RoomID &", "& RQ.UserID &", N'"& RQ.UserName &"', N'"& Message &"')")
	End If

	Call MsgList()
End Sub

'========================================================
'读取聊天室发言内容
'========================================================
Sub MsgList()
	Dim AnnounceInfo, MessageListArray

	AnnounceInfo = RQ.Query("SELECT usershow, message FROM "& TablePre &"chatannounces WHERE roomid = "& RoomID)
	MessageListArray = RQ.Query("SELECT TOP 25 msgid, uid, usershow, message, posttime FROM "& TablePre &"chatmessages WHERE roomid = "& RoomID &" ORDER BY posttime DESC")

	Call closeDataBase()
	RQ.Header()
%>
<body class="blankbg">
<% If IsArray(AnnounceInfo) Then %>
<span class="pink underline"><strong>本房间公告</strong>(<%= AnnounceInfo(0, 0) %>设置)</span>:<%= AnnounceInfo(1, 0) %>
<hr color="black" />
<% End If %>
<%
If IsArray(MessageListArray) Then 
	For i = 0 To UBound(MessageListArray, 2)
		If RQ.IsModerator And RQ.AllowPunishUser = 1 And MessageListArray(1, i) > 0 Then
			Response.Write "<a href=""managemember.asp?action=detail&uid="& MessageListArray(1, i) &"""><span class=""pink"">"& MessageListArray(2, i) &"</span></a>"
		Else
			Response.Write "<span class=""pink"">"& MessageListArray(2, i) &"</span>"
		End If

		If RQ.UserCredits > IntCode(RQ.Chat_Settings(5)) Then
			Response.Write "<a href=""javascript:deletemsg("& MessageListArray(0, i) &");"" class=""chatlink"" style=""color:#000;"">("& FormatDateTime(MessageListArray(4, i), 3) &")</a>"
		Else
			Response.Write "("& FormatDateTime(MessageListArray(4, i), 3) &")"
		End If

		Response.Write ": "& MessageListArray(3, i) &"<br />"& vbCrLf
	Next
	Erase MessageListArray
End If
%>
<form method="get" action="?">
  <input type="hidden" name="action" value="msglist" />
  <p><br />
    <span class="red">位置:<%= IIF(RoomID = 1, "公众", RoomID) %></span> &gt;&gt;&gt; <a href="?action=msglist&roomid=<%= RoomID %>" class="chatlink">[刷新]</a>[<a href="javascript:cleanroom();" class="chatlink">超级拖把</a>][<a href="javascript:promptdel();" class="chatlink">地图炮</a>][<a href="javascript:setanounce();" class="chatlink">发布房间公告(<%= RQ.Chat_Settings(7) %><%= RQ.Other_Settings(0) %>)</a>]
    <span class="red">[<a href="?action=useitem&identifier=dice" title="掷出6个骰子,用法自便." class="chatlink"><strong>贵宾券</strong></a>]</span>
	<br />
    <% If IntCode(RQ.Chat_Settings(1)) > 1 Then %><a href="?action=msglist&roomid=1" class="chatlink">公众</a> 自建:<input type="text" name="roomid" size="10" maxlength="20" value="<%= RoomID %>"><input type="submit" value="创建/进入" class="button" />(范围:1-<%= RQ.Chat_Settings(1) %>)<% End If %>
  </p>
</form>
<% If RQ.IsModerator And RQ.AllowPunishUser = 1 Then %>
<p>[<a href="managemember.asp?action=members&gid=9">黑名单管理</a>]
<% End If %>
<script type="text/javascript">setTimeout("window.location.replace('?action=msglist');", <%= IntCode(RQ.Chat_Settings(3)) * 1000 %>);</script>
<script type="text/javascript">
function cleanroom(){
	if (confirm("确认要使用拖把?")){
		window.self.location="?action=useitem&identifier=clearchatroom";
	}
}

function deletemsg(msgid){
	if (confirm("删除发言将消耗<%= RQ.Chat_Settings(6) %><%= RQ.Other_Settings(0) %>，确认删除本发言？")){
		window.self.location="?action=deletemsg&msgid="+ msgid;
	}
}

function promptdel(){
	var username = prompt("请输入要删除发言的发言人名称。","");
	if (username !== null){
		window.self.location = "?action=useitem&identifier=clearallanonymity&u="+ username;
	}
}

function setanounce(){
	var anouncemsg = prompt("请输入要设置的房间公告，100字内，消费<%= RQ.Chat_Settings(7) %><%= RQ.Other_Settings(0) %>。","");
	if (anouncemsg !== null){
		window.self.location="?action=setanouncemsg&message="+ anouncemsg;
	}
}
</script>
<%
	RQ.Footer()
End Sub

'========================================================
'显示发言界面
'========================================================
Sub PostPanel()
	RQ.Header()
%>
<body class="blankbg">
<form action="?action=postmsg" name="sendmsg" id="sendmsg" method="post" target="<%= CacheName %>msglist" onsubmit="$('message').value = $('tmpmessage').value;$('tmpmessage').value = $('autoclear').checked ? '' : $('tmpmessage').value">
  Say:
  <input type="text" name="tmpmessage" id="tmpmessage" size="30" maxlength="255"<% If RQ.AllowChat = 0 Then %> disabled<% End If %> />
  <input type="hidden" name="message" id="message" />
  <input type="submit" value="OK" class="button" /> 
  <input type="reset" value="XXX" style="background-color: #f00; color: #fff; " class="button" />
  <input type="button" value="刷新" onclick="parent.<%= CacheName %>msglist.location.href='?action=msglist';$('tmpmessage').focus();" class="button" />
  <input type="checkbox" name="clean" value="on" id="autoclear" /><label for="autoclear">自动清除</label></p>
</form>
</body>
</html>
<%
End Sub

'========================================================
'主框架
'========================================================
Sub Main()
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<title></title>
</head>

<frameset frameBorder="0" frameSpacing="0" rows="*,40">
  <frame name="<%= CacheName %>msglist" src="?action=msglist">
  <frame name="<%= CacheName %>postpanel" src="?action=postpanel" scrolling="no">
  <noframes>
    <body>
      <p>请使用支持框架的浏览器。</p>
    </body>
  </noframes>
</frameset>
</html>
<%
End Sub
%>