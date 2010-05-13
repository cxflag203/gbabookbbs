<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "clearfavor"
		Call ClearFavor()
	Case "viewtopicstyle"
		Call ViewTopicStyle()
	Case "designation"
		Call Designation()
	Case "designationstuff"
		Call DesignationStuff()
	Case "showlog"
		Call ShowLog()
	Case "showitemlog"
		Call ShowItemLog()
	Case "setbanner"
		Call SetBanner()
	Case Else
		Call Main()
End Select

'========================================================
'清空收藏夹
'========================================================
Sub ClearFavor()
	If SafeRequest(2, "do", 1, "", 0) = "confirm" Then
		RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE uid = "& RQ.UserID)
	End If
	Call closeDataBase()
	Call RQ.showTips("收藏夹已经被清空。", "?", "")
End Sub

'========================================================
'设置回帖样式
'========================================================
Sub ViewTopicStyle()
	Dim Style, StyleNumber

	Style = SafeRequest(3, "style", 1, "", 0)
	If Style = "avatar" Then
		StyleNumber = 2
	Else
		StyleNumber = 1
	End If

	If StyleNumber <> RQ.UserViewTopicStyle Then
		RQ.Execute("UPDATE "& TablePre &"members SET viewtopicstyle = "& StyleNumber &" WHERE uid = "& RQ.UserID)
	End If

	Call closeDatabase()
	Call RQ.showTips("回帖样式设置完毕。", "", "HALTED")
End Sub

'========================================================
'使用联盟称号
'========================================================
Sub DesignationStuff()
	Dim UserInfo

	'使用某称号
	If Len(Request.Form("usedesignation")) > 0 Then
		Dim JoinID, DesignationInfo, Designation

		JoinID = SafeRequest(2, "joinid", 0, 0, 0)
		DesignationInfo = RQ.Query("SELECT lm.designation, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.joinid = "& JoinID &" AND lm.uid = "& RQ.UserID &" AND groupid > 0")
		If Not IsArray(DesignationInfo) Then
			Call RQ.showTips("您选择的称号无效，请返回重新选择。", "", "")
		End If

		Designation = "<span title="& DesignationInfo(1, 0) &">"& DesignationInfo(0, 0) &"</span>"
		RQ.Execute("UPDATE "& TablePre &"memberfields SET designation = N'"& Designation &"' WHERE uid = "& RQ.UserID)

	'不使用任何称号
	ElseIf Len(Request.Form("cleardesignation")) > 0 Then
		RQ.Execute("UPDATE "& TablePre &"memberfields SET designation = N'' WHERE uid = "& RQ.UserID)
	End If

	Call closeDatabase()
	Call RQ.showTips("称号设置成功。", "?action=designation", "")
End Sub

'========================================================
'列出称号
'========================================================
Sub Designation()
	Dim DesignListArray, UserInfo

	DesignListArray = RQ.Query("SELECT lm.joinid, lm.designation, l.name FROM "& TablePre &"leaguemembers lm INNER JOIN "& TablePre &"leagues l ON lm.leagueid = l.leagueid WHERE lm.uid = "& RQ.UserID &" AND groupid > 0 ORDER BY l.leagueid ASC")

	UserInfo = RQ.Query("SELECT designation FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)

	Call closeDataBase()
	RQ.Header()
%>
<body>
<% If IsArray(DesignListArray) Then %>
请选择下列其中一个称号。
<% If Len(UserInfo(0, 0)) > 0 Then %>目前使用称号：【<%= UserInfo(0, 0) %>】<% End If %>
<p>
<form action="?action=designationstuff" method="post">
  <% For i = 0 To UBound(DesignListArray, 2) %>
  <input type="radio" name="joinid" value="<%= DesignListArray(0, i) %>" />
  【<%= DesignListArray(1, i) %>】(<%= DesignListArray(2, i) %>)<br />
  <% Next %>
  <p>
    <input type="submit" name="usedesignation" value="使用称号" class="button" />
    <input type="submit" name="cleardesignation" value="不使用称号" class="button" />
</form>
<% Else %>
您还没有加入任何联盟。
<% End If %>
<p>[<a href="?">返回</a>]
  <%
	RQ.Footer()
End Sub

'========================================================
'状态、金钱异动报告
'========================================================
Sub ShowLog()
	Dim Keyword
	Dim strSQL, SqlTop, LogListArray

	RQ.Execute("DELETE FROM "& TablePre &"logs WHERE posttime < DateAdd(d, "& -IntCode(RQ.Other_Settings(1)) &", GETDATE())")

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")

	If Len(Keyword) = 0 Then
		strSQL = "SELECT username, userip, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE uid = "& RQ.UserID &" UNION SELECT username, userip, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE targetuid = "& RQ.UserID &" ORDER BY posttime DESC"

		Keyword = RQ.UserName
	Else
		SqlTop = IIF(RQ.IsModerator, "", " TOP 50")
		strSQL = "SELECT"& SqlTop &" username, userip, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE (username LIKE N'%"& Keyword &"%' OR targetusername LIKE N'%"& Keyword &"%') ORDER BY posttime DESC"
	End If

	LogListArray = RQ.Query(strSQL)

	Call closeDataBase()
	RQ.Header()
%>
<body>
<form method="get" action="?">
  <input type="hidden" name="action" value="showlog">
  搜索与
  <input type="text" name="keyword" size="10" value="<%= Keyword %>" />
  有关的记录
  <input type="submit" value="搜索" class="button" />
  <a href="?action=showitemlog">道具转让记录</a>
  <p>
  <hr color="black" />
</form>
<%
	If IsArray(LogListArray) Then
		For i = 0 To UBound(LogListArray, 2)
			Response.Write LogListArray(5, i) &" 被修改人:"& LogListArray(2, i) &" 修改人:"& LogListArray(0, i) &" 异动内容:"& LogListArray(3, i) &"<br />异动原因:"& LogListArray(4, i) &"<hr color=""black"" />"
		Next
	End If

	RQ.Footer()
End Sub

'========================================================
'道具异动报告
'========================================================
Sub ShowItemLog()
	Dim Keyword
	Dim strSQL, SqlTop, LogListArray

	RQ.Execute("DELETE FROM "& TablePre &"itemmarketlogs WHERE posttime < DateAdd(d, "& -IntCode(RQ.Item_Settings(1)) &", GetDate())")

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")

	If Len(Keyword) = 0 Then
		strSQL = "SELECT ml.username, ml.userip, ml.targetusername, ml.num, ml.price, ml.posttime, i.name FROM "& TablePre &"itemmarketlogs ml INNER JOIN "& TablePre &"items i ON ml.itemid = i.itemid WHERE ml.uid = "& RQ.UserID &" UNION SELECT ml.username, ml.userip, ml.targetusername, ml.num, ml.price, ml.posttime, i.name FROM "& TablePre &"itemmarketlogs ml INNER JOIN "& TablePre &"items i ON ml.itemid = i.itemid WHERE ml.targetuid = "& RQ.UserID &" ORDER BY ml.posttime DESC"

		Keyword = RQ.UserName
	Else
		SqlTop = IIF(RQ.IsModerator, "", " TOP 50")
		strSQL = "SELECT"& SqlTop &" ml.username, ml.userip, ml.targetusername, ml.num, ml.price, ml.posttime, i.name FROM "& TablePre &"itemmarketlogs ml INNER JOIN "& TablePre &"items i ON ml.itemid = i.itemid WHERE (ml.username LIKE N'%"& Keyword &"%' OR ml.targetusername LIKE N'%"& Keyword &"%') ORDER BY ml.posttime DESC"
	End If

	LogListArray = RQ.Query(strSQL)

	Call closeDataBase()
	RQ.Header()
%>
<body>
<form method="get" action="?">
  <input type="hidden" name="action" value="showitemlog">
  搜索与
  <input type="text" name="keyword" size="10" value="<%= Keyword %>" />
  有关的记录
  <input type="submit" value="搜索" class="button" />
  <a href="?action=showlog">异动报告</a>
  <p>
  <hr color="black" />
</form>
<%
	If IsArray(LogListArray) Then
		For i = 0 To UBound(LogListArray, 2)
			Response.Write LogListArray(5, i) &" "& LogListArray(6, i) &"("
			If LogListArray(4, i) > 0 Then
				Response.Write "寄卖"& LogListArray(4, i) & RQ.Other_Settings(0) &" "
			End If
			Response.Write Trim(LogListArray(1, i)) &")X"& LogListArray(3, i) &" 转让人:"& LogListArray(0, i) &" 接收人:"& LogListArray(2, i) &"<hr color=""black"" />"
		Next
	End If

	RQ.Footer()
End Sub

'========================================================
'更新标语设置
'========================================================
Sub SetBanner()
	If Not InArray(Array(1,2), RQ.AdminGroupID) Then
		Call RQ.showTips("您无权进行操作。", "", "")
	End If

	Dim Banner
	Banner = SafeRequest(2, "banner", 1, "", 1)
	'词语过滤
	Banner = WordsFilter(Banner)

	RQ.Execute("UPDATE "& TablePre &"settings SET banner = N'"& Banner &"'")

	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call RQ.showTips("标语设置完毕。", "?", "")
End Sub

'========================================================
'相关功能界面
'========================================================
Sub Main()
	RQ.Header()
%>
<body>
<strong>站点功能</strong>
<p>
<table border="0" width="100%" cellpadding="3" cellspacing="3" class="tdpadding2">
  <tr>
    <td bgcolor="#CCFFCC" style="width:150px;"><a href="htmls/help.html" target="_blank">用户必读</a></td>
    <td bgcolor="#F2EACE">bbs的基本帮助和一些规则。为了更好的使用社区，希望大家都能仔细阅读。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="leaguelist.asp">联盟区</a></td>
    <td bgcolor="#F2EACE">通过联盟集中同类型的帖子，欢迎志同道合者加盟或创建自己的联盟。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="membermisc.asp?action=favorites" target="<%= CacheName %>search" onClick="javascript:parent.<%= CacheName %>leftsearch.rows='*,355';">收藏区</a></td>
    <td bgcolor="#F2EACE">查看收藏的帖子。也可以从左侧底部拉出新的页面查看。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="profile.asp?action=profilepanel" onClick="return shows3(this.href);">登记个人资料</a></td>
    <td bgcolor="#F2EACE">如果你想让更多的玩友认识你，填写资料吧。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a target="_self" href="pwdsafe.asp">修改密码/密码保护</a></td>
    <td bgcolor="#F2EACE">非常重要，请一定申请密码保护以免密码遗忘造成损失。<br />
      注意问题的答案不要过于简单让他人很容易猜出。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="avatar.asp">上传头像</a></td>
    <td bgcolor="#F2EACE">上传头像，在帖子回复中显示。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC">设置回帖样式</td>
    <td bgcolor="#F2EACE">[<a href="?action=viewtopicstyle&style=simple" class="underline">简单样式</a>]
	  [<a href="?action=viewtopicstyle&style=avatar" class="underline">头像样式</a>]</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="membercp.asp?action=showlog">异动报告</a></td>
    <td bgcolor="#F2EACE">如发现状态有异常或者<%= RQ.Other_Settings(0) %>、道具有变化，请在这里查询以获知原因。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="batchcreditstransfer.asp"><%= RQ.Other_Settings(0) %>转让</a></td>
    <td bgcolor="#F2EACE">把<%= RQ.Other_Settings(0) %>转让给其他用户。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="item.asp">道具使用</a></td>
    <td bgcolor="#F2EACE">使用道具，寄卖道具，转让道具，进入道具市场的入口。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="htmls/calendarCN.htm" target="_blank">日历</a></td>
    <td bgcolor="#F2EACE">功能颇强的日历，很好用，有需要就来查。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="###" onclick="javascript:if(!confirm('是否确定要清空收藏夹？'))return false;postvalue('?action=clearfavor', 'do', 'confirm');">清空收藏夹</a></td>
    <td bgcolor="#F2EACE">没有特别需要的话还是不要清空。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="membercp.asp?action=designation">使用联盟称号</a></td>
    <td bgcolor="#F2EACE">选择发贴时ID后跟所选联盟称号。</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="chatroom.asp">聊天室</a></td>
    <td bgcolor="#F2EACE">聊天室，可以自己创建聊天房间。</td>
  </tr>
  <% If RQ.Login_Settings(0) = "2" Then %>
  <tr>
    <td bgcolor="#CCFFCC"><a href="invate.asp">购买推荐码</a><% If InArray(Array(1, 2), RQ.AdminGroupID) Then %>[<a href="invate.asp?action=setnum" class="bluelink">设置数量</a>]<% End If %></td>
    <td bgcolor="#F2EACE">购买注册新用户时需使用的推荐码，推荐码请务必在购买天内使用，过时作废。</td>
  </tr>
  <% End If %>
  <tr>
    <td bgcolor="#CCFFCC">传呼相关</td>
    <td bgcolor="#F2EACE">[<a href="pm.asp" class="underline" title="由于浏览器问题，有时候传呼窗口是一片空白，这种情况下可以到这里查看。">看不到传呼</a>]
      [<a href="pm.asp?action=showfavor" class="underline" title="保存下来的传呼记录请在这里查看。">传呼记录</a>]
	  [<a href="pm.asp?action=ignorepm" class="underline" title="设置传呼黑名单">传呼黑名单设置</a>]</td>
  </tr>
  <tr>
    <td bgcolor="#CCFFCC"><a href="online.asp">在线列表</a></td>
    <td bgcolor="#F2EACE">显示当前在线人数，可以直接给在线列表中的用户发送传呼。</td>
  </tr>
  <% If RQ.AllowEditUser = "1" Or RQ.AllowPunishUser = "1" Then %>
  <tr>
    <td bgcolor="#CCFFCC"><a href="managemember.asp">用户管理</a></td>
    <td bgcolor="#F2EACE">用户列表、查看、处罚相关操作。</td>
  </tr>
  <% End If %>
</table>
<br />
<% If InArray(Array(1,2), RQ.AdminGroupID) Then %>
<form name="setbanner" method="post" action="?action=setbanner">
  <div style="border: 1px #75ea00 solid; background: #dfffbf; padding: 10px; color:#0080ff; width: 400px;">
    <h1>标语设置</h1>
    <input type="text" name="banner" size="45" value="<%= RQ.Gbl_Banner %>" />
    <input type="submit" value="提交设置" class="button" />
  </div>
</form>
<p>
<% End If %>
<form method="post" id="sendpm" action="pm.asp?action=sendpost&r=mcp" onkeydown="fastpost('btnsend', event);" onsubmit="$('btnsend').value='正在提交,请稍后...';$('btnsend').disabled=true;">
  <div style="border: 1px #d6bc65 solid; background: #f2eace; padding: 10px; color:#0080ff; width: 400px;">
    <h1>玩友传呼</h1>
    接收人：<% If RQ.DisablePmCtrl = 1 Then %>(如果要进行群发，将多个接收人用逗号隔开即可。)<% End If %>
	<br />
    <input type="text" name="username" size="35" />
	<br />
	发送信息：
	<br />
	<textarea rows="5" name="message" cols="40"></textarea>
	<br />
	发送时间(定时发给自己可作备忘提醒用)：
	<br />
	<input type="text" name="posttime" size="23" value="<%= Now() %>" />
	<p>
	<input type="submit" name="btnsend" id="btnsend" value="发送" class="button" />
  </div>
</form>
<%
	RQ.Footer()
End Sub
%>
