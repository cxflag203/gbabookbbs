<!--#include file="include/inc.asp"-->
<!--#include file="include/md5.inc.asp"-->
<%
'游客不能使用道具
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

'验证道具功能是否打开
If RQ.Item_Settings(0) = "0" Then
	Call RQ.showTips("道具功能已经关闭。", "", "NOPERM")
End If

'验证用户组是否允许使用道具
If RQ.AllowUseItem = 0 Then
	Call RQ.showTips("您目前的身份是"& RQ.UserGroupName &"，不能使用道具。", "", "")
End If

Dim Action, ItemID, ItemName

Action = Request.QueryString("action")
ItemID = SafeRequest(2, "itemid", 0, 0, 0)

Select Case Action
	Case "transfer"
		Call Transfer()
	Case "forsale"
		Call ForSale()
	Case "buyitem"
		Call BuyItem()
	Case "updatemymarket"
		Call UpdateMyMarket()
	Case "myitem"
		Call MyItem()
	Case Else
		Call Main()
End Select

'========================================================
'转让道具
'========================================================
Sub Transfer()
	Dim ItemInfo, UserInfo, MemberItemInfo
	Dim UserName, Num, Password
	Dim PmMsg

	ItemInfo = RQ.Query("SELECT name FROM "& TablePre &"items WHERE itemid = "& ItemID)
	If Not IsArray(ItemInfo) Then
		Call RQ.showTips("道具无效。", "", "")
	End If

	ItemName = ItemInfo(0, 0)

	UserName = SafeRequest(2, "username", 1, "", 0)
	Num = SafeRequest(2, "num", 0, 0, 0)
	Password = SafeRequest(2, "password", 1, "", 0)

	'用户名验证
	If Len(UserName) = 0 Then
		Call RQ.showTips("请填写好接收道具的用户名。", "", "")
	End If

	'数量验证
	If Num = 0 Or Num > 9999 Then
		Call RQ.showTips("请填写好转让的道具数量，数量范围在1-9999个之间。", "", "")
	End If

	'密码验证
	Password = MD5(Password)
	If Password <> RQ.UserPassword Then
		Call RQ.showTips("您输入的密码不正确。", "", "")
	End If

	'读取接收用户的信息
	UserInfo = RQ.Query("SELECT uid, username FROM "& TablePre &"members WHERE username = '"& UserName &"'")
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("接收用户无效。", "", "")
	End If

	'减去当前用户的道具
	If Not RQ.CheckItem(ItemID, Num, TRUE) Then
		Call RQ.showTips("您的道具数量不足。", "", "")
	End If

	'保存
	MemberItemInfo = RQ.Query("SELECT id FROM "& TablePre &"memberitems WHERE uid = "& UserInfo(0, 0) &" AND itemid = "& ItemID)
	If IsArray(MemberItemInfo) Then
		RQ.Execute("UPDATE "& TablePre &"memberitems SET num = num + "& Num &" WHERE id = "& MemberItemInfo(0, 0))
	Else
		RQ.Execute("INSERT INTO "& TablePre &"memberitems (uid, itemid, num) VALUES ("& UserInfo(0, 0) &", "& ItemID &", "& Num &")")
	End If

	'记录log
	RQ.Execute("INSERT INTO "& TablePre &"itemmarketlogs (uid, username, userip, targetuid, targetusername, itemid, num) VALUES ("& RQ.UserID &", '"& RQ.UserName &"', '"& RQ.UserIP &"', "& UserInfo(0, 0) &", '"& UserInfo(1, 0) &"', "& ItemID &", "& Num &")")

	'发送pm通知
	PmMsg = "<strong>系统通知：</strong><p>"& RQ.UserName &"于"& Now() &"向您转让了"& Num &"个“"& ItemName &"”道具。<p><em>如果回复此消息，"& RQ.UserName &"将会收到。</em>"
	RQ.Execute("INSERT INTO "& TablePre &"pm (msgfrom, msgfromid, msgtoid, message) VALUES ('"& RQ.UserName &"', "& RQ.UserID &", "& UserInfo(0, 0) &", '"& PmMsg &"')")

	Call closeDatabase()
	Call RQ.showTips("成功转让了"& Num &"个"& ItemName &"给"& UserInfo(1, 0) &"。", "", "HALTED")
End Sub

'========================================================
'寄卖道具
'========================================================
Sub ForSale()
	Dim ItemInfo, MemberItemInfo, MarketInfo
	Dim Num, Price, rePrice, Password

	ItemInfo = RQ.Query("SELECT name FROM "& TablePre &"items WHERE itemid = "& ItemID)
	If Not IsArray(ItemInfo) Then
		Call RQ.showTips("道具无效。", "", "")
	End If

	ItemName = ItemInfo(0, 0)

	Num = SafeRequest(2, "num", 0, 0, 0)
	Price = SafeRequest(2, "price", 0, 0, 0)
	rePrice = SafeRequest(2, "reprice", 0, 0, 0)
	Password = SafeRequest(2, "password", 1, "", 0)

	'数量验证
	If Num = 0 Then
		Call RQ.showTips("请填写好要寄卖的道具数量。", "", "")
	End If

	'输入价格验证
	If Price = 0 Then
		Call RQ.showTips("请填写好寄卖的价格。", "", "")
	End If

	If Price <> rePrice Then
		Call RQ.showTips("两次输入的寄卖价格应该相同。", "", "")
	End If

	'密码验证
	Password = MD5(Password)
	If Password <> RQ.UserPassword Then
		Call RQ.showTips("您输入的密码不正确。", "", "")
	End If

	'减去当前用户的道具
	If Not RQ.CheckItem(ItemID, Num, TRUE) Then
		Call RQ.showTips("您的道具数量不足。", "", "")
	End If

	'保存
	MarketInfo = RQ.Query("SELECT marketid FROM "& TablePre &"itemmarket WHERE uid = "& RQ.UserID &" AND itemid = "& ItemID)
	If IsArray(MarketInfo) Then
		RQ.Execute("UPDATE "& TablePre &"itemmarket SET price = "& Price &", num = num + "& Num &" WHERE marketid = "& MarketInfo(0, 0))
	Else
		RQ.Execute("INSERT INTO "& TablePre &"itemmarket (itemid, uid, username, price, num) VALUES ("& ItemID &", "& RQ.UserID &", '"& RQ.UserName &"', "& Price &", "& Num &")")
	End If

	Call closeDatabase()
	Call RQ.showTips("道具“"& ItemName &"”已经成功寄卖。", "?itemid="& ItemID, "")
End Sub

'========================================================
'购买道具
'========================================================
Sub BuyItem()
	Dim MarketID, MarketInfo, UserInfo, UserItemInfo
	Dim BuyNum, PayCredits

	MarketID = SafeRequest(2, "marketid", 0, 0, 0)
	BuyNum = SafeRequest(2, "buynum", 0, 0, 0)

	'验证购买数量
	If BuyNum = 0 Then
		Call RQ.showTips("请输入正确的购买数量。", "", "")
	End If

	MarketInfo = RQ.Query("SELECT it.itemid, it.uid, it.price, it.num FROM "& TablePre &"itemmarket it INNER JOIN "& TablePre &"items i ON it.itemid = i.itemid WHERE it.marketid = "& MarketID)
	If Not IsArray(MarketInfo) Then
		Call RQ.showTips("道具购买无效，可能已经被别人买走了。", "", "")
	End If

	'验证道具数量
	If BuyNum > MarketInfo(3, 0) Then
		Call RQ.showTips("卖家的道具数量不足。", "", "")
	End If

	PayCredits = MarketInfo(2, 0) * BuyNum

	'金钱是否足够
	If PayCredits > RQ.UserCredits Then
		Call RQ.showTips("您的"& RQ.Other_Settings(0) &"数量不足。", "", "")
	End If

	'更新道具市场
	If BuyNum = MarketInfo(3, 0) Then
		RQ.Execute("DELETE FROM "& TablePre &"itemmarket WHERE marketid = "& MarketID)
	Else
		RQ.Execute("UPDATE "& TablePre &"itemmarket SET num = num - "& BuyNum &" WHERE marketid = "& MarketID)
	End If

	'减去当前用户的金钱
	RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& PayCredits &" WHERE uid = "& RQ.UserID)

	'查询卖家信息,更新金钱
	UserInfo = RQ.Query("SELECT username, credits FROM "& TablePre &"members WHERE uid = "& MarketInfo(1, 0))

	If IsArray(UserInfo) Then
		If UserInfo(1, 0) >= IntCode(RQ.User_Settings(7)) Then
			RQ.Execute("UPDATE "& TablePre &"members SET credits = credits + "& PayCredits - CLng((PayCredits * 0.05)) &" WHERE uid = "& MarketInfo(1, 0))
		End If

		'记录log
		RQ.Execute("INSERT INTO "& TablePre &"itemmarketlogs (uid, username, userip, targetuid, targetusername, itemid, num, price) VALUES ("& RQ.UserID &", '"& RQ.UserName &"', '"& RQ.UserIP &"', "& MarketInfo(1, 0) &", '"& UserInfo(0, 0) &"', "& MarketInfo(0, 0) &", "& BuyNum &", "& MarketInfo(2, 0) * BuyNum &")")
	End If

	'更新当前用户的道具
	UserItemInfo = RQ.Query("SELECT id FROM "& TablePre &"memberitems WHERE uid = "& RQ.UserID &" AND itemid = "& MarketInfo(0, 0))

	If IsArray(UserItemInfo) Then
		RQ.Execute("UPDATE "& TablePre &"memberitems SET num = num + "& BuyNum &" WHERE id = "& UserItemInfo(0, 0))
	Else
		RQ.Execute("INSERT INTO "& TablePre &"memberitems (uid, itemid, num) VALUES ("& RQ.UserID &", "& MarketInfo(0, 0) &", "& BuyNum &")")
	End If

	Call closeDatabase()
	Call RQ.showTips("购买成功。","?itemid="& MarketInfo(0, 0), "")
End Sub

'========================================================
'对寄卖道具的操作(更新价格/取回)
'========================================================
Sub UpdateMyMarket()
	Dim g_MarketID, MarketID, Price
	Dim MarketInfo, MarketListArray, MemberItemInfo

	'取回道具
	If Len(Request.Form("btngetback")) > 0 Then
		g_MarketID = NumberGroupFilter(Replace(SafeRequest(2, "g_marketid", 1, "", 0), " ", ""))
		If Len(g_MarketID) > 0 Then
			MarketListArray = RQ.Query("SELECT marketid, itemid, num FROM "& TablePre &"itemmarket WHERE marketid IN("& g_MarketID &") AND uid = "& RQ.UserID)

			If IsArray(MarketListArray) Then
				For i = 0 To UBound(MarketListArray, 2)
					MemberItemInfo = RQ.Query("SELECT id FROM "& TablePre &"memberitems WHERE uid = "& RQ.UserID &" AND itemid = "& MarketListArray(1, i))

					If IsArray(MemberItemInfo) Then
						RQ.Execute("UPDATE "& TablePre &"memberitems SET num = num + "& MarketListArray(2, i) &" WHERE id = "& MemberItemInfo(0, 0))
					Else
						RQ.Execute("INSERT INTO "& TablePre &"memberitems (uid, itemid, num) VALUES ("& RQ.UserID &", "& MarketListArray(1, i) &", "& MarketListArray(2, i) &")")
					End If
				Next
				'取回后删除道具市场的记录
				RQ.Execute("DELETE FROM "& TablePre &"itemmarket WHERE marketid IN("& g_MarketID &")")
			End If
		End If

	'更新价格
	ElseIf Len(Request.Form("btnupdate")) > 0 Then
		If Request.Form("marketid").Count > 0 Then
			For i = 1 To Request.Form("marketid").Count
				MarketID = IntCode(Request.Form("marketid")(i))
				Price = IntCode(Request.Form("price")(i))
				If MarketID > 0 And Price > 0 Then
					RQ.Execute("UPDATE "& TablePre &"itemmarket SET price = "& Price &" WHERE marketid = "& MarketID &" AND uid = "& RQ.UserID)
				End If
			Next
		End If
	End If

	Call closeDatabase()
	Call RQ.showTips("道具市场更新完毕。", "?action=myitem", "")
End Sub

'========================================================
'查看寄卖的道具
'========================================================
Sub MyItem()
	Dim MarketListArray
	MarketListArray = RQ.Query("SELECT it.marketid, it.price, it.num, i.name FROM "& TablePre &"itemmarket it INNER JOIN "& TablePre &"items i ON it.itemid = i.itemid WHERE it.uid = "& RQ.UserID &" ORDER BY i.displayorder ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body class="blankbg">
<h1>我寄卖的道具</h1>
<p>
<form name="market" method="post" action="?action=updatemymarket">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td width="10%">取回?</td>
      <td width="25%">道具名称</td>
      <td width="20%">寄卖数量</td>
      <td>寄卖价格</td>
    </tr>
    <% If IsArray(MarketListArray) Then %>
    <% For i = 0 To UBound(MarketListArray, 2) %>
    <tr>
      <td><input type="checkbox" name="g_marketid" value="<%= MarketListArray(0, i) %>" /></td>
      <td><%= MarketListArray(3, i) %></td>
      <td><%= MarketListArray(2, i) %></td>
      <td><input type="hidden" name="marketid" value="<%= MarketListArray(0, i) %>" />
	    <input type="text" name="price" size="10" value="<%= MarketListArray(1, i) %>" class="marketinput" /></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="4"><em>还没有寄卖的道具</em></td>
	</tr>
    <% End If %>
  </table>
  <% If IsArray(MarketListArray) Then %>
  <p>
    <input type="submit" name="btnupdate" value="更新价格" class="button" />
    <input type="submit" name="btngetback" value="取回选中的道具" class="button" />
  </p>
  <% End If %>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'显示道具市场
'========================================================
Sub Main()
	Dim ItemID, ItemInfo
	Dim ItemListArray, MarketListArray

	ItemID = SafeRequest(3, "itemid", 0, 17, 0)
	ItemInfo = RQ.Query("SELECT name, description FROM "& TablePre &"items WHERE itemid = "& ItemID)

	If Not IsArray(ItemInfo) Then
		Call RQ.showTips("道具无效。", "", "")
	End If

	ItemListArray = RQ.Query("SELECT itemid, name FROM "& TablePre &"items ORDER BY displayorder ASC")
	MarketListArray = RQ.Query("SELECT marketid, username, price, num FROM "& TablePre &"itemmarket WHERE itemid = "& ItemID &" ORDER BY price ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body class="blankbg">
请选择道具种类:<select name="itemid" onchange="location.href='?itemid='+ this.options[this.options.selectedIndex].value;">
  <% If IsArray(ItemListArray) Then %>
  <% For i = 0 To UBound(ItemListArray, 2) %>
  <option value="<%= ItemListArray(0, i) %>"<%= IIF(ItemID = ItemListArray(0, i), " selected", "") %>><%= ItemListArray(1, i) %></option>
  <% Next %>
  <% End If %>
</select>
<p class="iteminfo"><h1><%= ItemInfo(0, 0) %></h1>
<em style="color:#999;font-style: normal;"><%= ItemInfo(1, 0) %></em>
<p>
<table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
  <tr class="header">
    <td>卖家</td>
    <td width="22%">价格</td>
    <td width="20%">数量</td>
    <td width="25%">购买数量</td>
  </tr>
  <% If IsArray(MarketListArray) Then %>
  <% For i = 0 To UBound(MarketListArray, 2) %>
  <tr>
    <td><%= MarketListArray(1, i) %></td>
    <td><%= MarketListArray(2, i) %></td>
    <td><%= MarketListArray(3, i) %></td>
    <td><form name="buy_<%= MarketListArray(0, i) %>" method="post" action="?action=buyitem">
	  <input type="hidden" name="marketid" value="<%= MarketListArray(0, i) %>" />
	  <input type="text" name="buynum" size="5" class="marketinput" />
	  <input type="submit" value="购买" class="button" /></form></td>
  </tr>
  <% Next %>
  <% Else %>
  <tr>
    <td colspan="4">还没有卖家出售</td>
  </tr>
  <% End If %>
</table>
<%
	RQ.Footer()
End Sub
%>