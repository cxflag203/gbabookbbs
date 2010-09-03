<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登录。", "", "NOPERM")
End If

Dim Action
Action = SafeRequest(3, "action", 1, "", 0)

Select Case Action
	Case "buy"
		Call Buy()
	Case "updatenum"
		Call UpdateNum()
	Case "setnum"
		Call SetNum()
	Case Else
		Call Main()
End Select

'========================================================
'购买推荐码
'========================================================
Sub Buy()
	If RQ.Login_Settings(0) <> "2" Then
		Call RQ.showTips("目前站点还未启用推荐码注册。", "")
	End If

	'验证用户组是否允许购买
	If RQ.AllowInvate = 0 Then
		Call RQ.showTips("抱歉，您还不能购买推荐码。", "", "")
	End If

	If RQ.UserCredits < RQ.InvatePrice Then
		Call RQ.showTips("推荐码的价格是"& RQ.InvatePrice & RQ.Other_Settings(0) &"/个，而您的"& RQ.Other_Settings(0) &"不够。", "", "")
	End If

	Dim ValidNum, UserInvationNum, InvateInfo

	ValidNum = Conn.Execute("SELECT invatenum FROM "& TablePre &"settings")(0)
	If ValidNum = 0 Then
		Call RQ.showTips("目前没有可售的推荐码。", "", "")
	End If

	'验证限购数量
	UserInvationNum = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"invate WHERE uid = "& RQ.UserID &" AND status = 0")(0)
	If UserInvationNum >= RQ.InvateMaxNum Then
		Call RQ.showTips("目前您只能购买"& RQ.InvateMaxNum &"个推荐码。", "", "")
	End If

	RQ.Execute("INSERT INTO "& TablePre &"invate (uid, username, invatecode, expirytime) VALUES ("& RQ.UserID &", N'"& RQ.UserName &"', '"& Rand(16) &"', DateAdd(d, "& RQ.InvateExpiryDay &", GETDATE()))")

	RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& RQ.InvatePrice &" WHERE uid = "& RQ.UserID)

	RQ.Execute("UPDATE "& TablePre &"settings SET invatenum = invatenum - 1")

	Call closeDatabase()
	Call RQ.showTips("推荐码购买成功。", "?", "")
End Sub

'========================================================
'管理员设置推荐码的可购买数量
'========================================================
Sub UpdateNum()
	If Not InArray(Array(1,2), RQ.AdminGroupID) Then
		Call RQ.showTips("您无权进行操作。", "", "")
	End If

	Dim NewNum
	NewNum = SafeRequest(2, "newnum", 0, 0, 0)
	RQ.Execute("UPDATE "& TablePre &"settings SET invatenum = "& NewNum)

	Call closeDatabase()
	Call RQ.showTips("推荐码数量设置完毕。", "?action=setnum", "")
End Sub

'========================================================
'设置推荐码数量页面
'========================================================
Sub SetNum()
	If Not InArray(Array(1,2), RQ.AdminGroupID) Then
		Call RQ.showTips("您无权进行操作。", "", "")
	End If

	'系统剩余的推荐码数量
	Dim ValiableNum
	ValiableNum = Conn.Execute("SELECT invatenum FROM "& TablePre &"settings")(0)
	dbQueryNum = dbQueryNum + 1

	Call closeDatabase()
	RQ.Header()
%>
<body>
<form name="setnum" method="post" action="?action=updatenum">
  <div style="border: 1px #d6bc65 solid; background: #f2eace; padding: 10px; color:#0080ff; width: 400px;">
    <h1>设置推荐码数量</h1>
	<br />
    目前可用推荐码数量：<%= ValiableNum %>个
    <br />
    <input type="text" name="newnum" size="10" />
    <input type="submit" id="btnsubmit" value="更新数量" class="button" />
	<input type="button" id="btnback" value="返回" onclick="javascript:location.href='membercp.asp';" class="button" />
  </div>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'推荐码购买页面
'========================================================
Sub Main()
	Dim ValiableNum, InvatedListArray, InvationListArray
	Dim UserName, SearchInfo, UserInvationNum

	UserName = Trim(SafeRequest(3, "username", 1, "", 0))

	'删除已过期未使用的推荐码
	RQ.Execute("DELETE FROM "& TablePre &"invate WHERE expirytime < GetDate() AND status = 0")

	'系统剩余的推荐码数量
	ValiableNum = Conn.Execute("SELECT invatenum FROM "& TablePre &"settings")(0)
	dbQueryNum = dbQueryNum + 1

	'查询推荐人
	If Len(UserName) > 0 Then
		SearchInfo = RQ.Query("SELECT username FROM "& TablePre &"invate WHERE reguid = (SELECT uid FROM "& TablePre &"members WHERE username = N'"& UserName &"')")
	End If

	'我推荐的用户
	InvatedListArray = RQ.Query("SELECT i.buytime, i.regtime, m.username FROM "& TablePre &"invate i INNER JOIN "& TablePre &"members m ON i.reguid = m.uid WHERE i.uid = "& RQ.UserID &" AND i.status = 1")

	'我的推荐码
	InvationListArray = RQ.Query("SELECT invatecode, expirytime FROM "& TablePre &"invate WHERE uid = "& RQ.UserID &" AND status = 0")

	Call closeDatabase()
	RQ.Header()
%>
<body>
<form action="?" method="get">
  查询某用户的推荐人:<input type="text" name="username" size="10" value="<%= UserName %>" /><input type="submit" value="查!" class="button" />
</form>
<p>
<%
	If Len(UserName) > 0 Then
		If IsArray(SearchInfo) Then
			Response.Write "推荐人："& SearchInfo(0, 0)
		Else
			Response.Write "未找到该用户推荐人信息。"
		End If
		Response.Write "<p>"
	End If

	If RQ.AllowInvate = 1 And RQ.Login_Settings(0) = "2" Then
		Response.Write "目前可售推荐码<span class=""red"">"& ValiableNum &"</span>个。"

		If ValiableNum > 0 Then
			If UserInvationNum >= RQ.InvateMaxNum Then
				Response.Write "您最多只能购买"& RQ.InvateMaxNum &"个推荐码。"
			Else
				Response.Write "如需购买请<a href=""?action=buy"" class=""bluelink"">点击这里</a>，系统会自动扣除相应的"& RQ.Other_Settings(0) &"。"
			End If
		Else
			Response.Write "目前已全部售完！"
		End If
	End If

	Response.Write "<p>"

	If IsArray(InvationListArray) Then
		UserInvationNum = UBound(InvationListArray, 2) + 1

		Response.Write "<hr color=""black"" />"
		For i = 0 To UBound(InvationListArray, 2)
			Response.Write "现有推荐码："& InvationListArray(0, i) &" (有效期至："& InvationListArray(1, i) &")<br />"
		Next
		Response.Write "<hr color=""black"" />"
	Else
		UserInvationNum = 0
	End If

	If IsArray(InvatedListArray) Then
		For i = 0 To UBound(InvatedListArray, 2)
			Response.Write "购买时间："& InvatedListArray(0, i) &" 使用时间："& NumtoDate(InvatedListArray(1, i)) &" 注册用户："& InvatedListArray(2, i) &"<br />"
		Next
	End If

	RQ.Footer()
End Sub
%>