<!--#include file="include/inc.asp"-->
<%
'游客不能使用道具
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

'验证道具功能是否打开
If RQ.Item_Settings(0) = "0" Then
	Call RQ.showTips("道具功能已经关闭。", "", "")
End If

'验证用户组是否允许使用道具
If RQ.AllowUseItem = 0 Then
	Call RQ.showTips("您目前的身份是"& RQ.UserGroupName &"，不能使用道具。", "", "")
End If

Dim Action, ItemID, ItemName, ItemIflog
Action = Request.QueryString("action")
ItemID = SafeRequest(2, "itemid", 0, 0, 0)

Select Case Action
	Case "acoption"
		Call ActionOption()
	Case "useitem"
		Call UseItem()
	Case "viewface"
		Call ViewFace()
	Case "forsale"
		Call ForSale()
	Case "topicitem"
		Call TopicItem()
	Case "memberitem"
		Call MemberItem()
	Case Else
		Call Main()
End Select

'========================================================
'使用道具(提交后的操作)
'========================================================
Sub UseItem()
	Dim ItemInfo

	ItemInfo = RQ.Query("SELECT name, identifier, iflog FROM "& TablePre &"items WHERE itemid = "& ItemID &" AND available = 1")
	If Not IsArray(ItemInfo) Then
		Call RQ.showTips("没有选择道具或者道具无效。", "", "")
	End If

	ItemName = ItemInfo(0, 0)
	ItemIflog = ItemInfo(2, 0)

	'查询用户是否有该道具
	If Not RQ.CheckItem(ItemID, 1, TRUE) Then
		Call RQ.showTips("您目前没有"& ItemName &"，请在<a href=""itemmarket.asp?itemid="& ItemID &""">道具市场</a>购买后再使用。", "", "")
	End If

	Call Include("./include/items/"& ItemInfo(1, 0) &".asp")
End Sub

'========================================================
'查看匿名(face)
'========================================================
Sub ViewFace()
	Dim ItemInfo, PostID, PostInfo

	ItemInfo = RQ.Query("SELECT itemid, name, iflog FROM "& TablePre &"items WHERE identifier = 'viewanonymity' AND available = 1")

	If Not IsArray(ItemInfo) Then
		Call Confirm("道具无效。")
	End If

	PostID = SafeRequest(2, "pid", 0, 0, 0)
	PostInfo = RQ.Query("SELECT tid, uid, username, ifanonymity FROM "& TablePre &"posts WHERE pid = "& PostID)
	If Not IsArray(PostInfo) Then
		Call Confirm("回复不存在或者已经被删除。")
	End If

	'检测道具数量
	If PostInfo(3, 0) > 0 Then
		If Not RQ.CheckItem(ItemInfo(0, 0), PostInfo(3, 0), TRUE) Then
			Call Confirm("您目前没有“"& ItemInfo(1, 0) &"”，请在道具市场购买。")
		End If
	End If

	If ItemInfo(2, 0) = 1 Then
		RQ.TopicID = PostInfo(0, 0)
		Call RQ.SetItemUserLog(ItemID, PostInfo(1, 0), PostInfo(2, 0), "对回复使用道具")
	End If

	Call closeDatabase()
	Call Confirm("使用了"& PostInfo(3, 0) &"个"& ItemInfo(1, 0) &"查看到发言人是："& PostInfo(2, 0))
End Sub

'========================================================
'道具使用/转让/寄卖
'========================================================
Sub ActionOption()
	Dim ItemInfo

	ItemInfo = RQ.Query("SELECT name, identifier, available FROM "& TablePre &"items WHERE itemid = "& ItemID)
	If Not IsArray(ItemInfo) Then
		Call RQ.showTips("没有选择道具或者道具无效。", "", "")
	End If

	ItemName = ItemInfo(0, 0)

	'查询用户是否有该道具
	If Not RQ.CheckItem(ItemID, 1, FALSE) Then
		Call RQ.showTips("您目前没有"& ItemName &"，请在<a href=""itemmarket.asp?itemid="& ItemID &""">道具市场</a>购买后再使用。", "", "HALTED")
	End If

	Call closeDatabase()

	'使用
	If Len(Request.Form("btnuse")) > 0 Then
		If ItemInfo(2, 0) = 0 Then
			Call RQ.showTips("该道具目前不可用。", "", "")
		End If

		RQ.Header()
		Response.Write "<body class=""blankbg""><form name=""useitem"" method=""post"" action=""?action=useitem"" onsubmit=""$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;""><input type=""hidden"" name=""itemid"" value="""& ItemID &""" />"

		Call Include("./include/items/"& ItemInfo(1, 0) &".asp")
		
		Response.Write "</form>"
		RQ.Footer()

	'转让
	ElseIf Len(Request.Form("btntransfer")) > 0 Then
		Call ItemTransPanel()

	'寄卖
	ElseIf Len(Request.Form("btnsell")) > 0 Then
		Call ItemSalePanel()
	End If
End Sub

'========================================================
'转让道具页面
'========================================================
Sub ItemTransPanel()
	RQ.Header()
%>
<body class="blankbg">
<form method="post" action="itemmarket.asp?action=transfer" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="itemid" value="<%= ItemID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="4">转让道具：<%= ItemName %></td>
    </tr>
    <tr>
      <td width="30%">接收人：</td>
      <td><input type="text" name="username" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>数量：</td>
      <td><input type="text" name="num" maxlength="4" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>登陆密码：</td>
      <td><input type="password" name="password" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td></td>
      <td><input type="submit" id="btnsubmit" value="确定" class="button" /></td>
    </tr>
  </table>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'寄卖道具页面
'========================================================
Sub ItemSalePanel()
	RQ.Header()
%>
<body class="blankbg">
<div style="border: 1px #f60 solid; background: #fff2e9; padding: 10px; color:#0080ff; width: 98%;">所寄卖道具售出后将收取当次成交额的5%作为市场管理费</div>
<br />
<form method="post" action="itemmarket.asp?action=forsale" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="itemid" value="<%= ItemID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="4">寄卖道具：<%= ItemName %></td>
    </tr>
    <tr>
      <td width="30%">寄卖数量：</td>
      <td><input type="text" name="num" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>寄卖价格：</td>
      <td><input type="text" name="price" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>确认价格：</td>
      <td><input type="text" name="reprice" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>登陆密码：</td>
      <td><input type="password" name="password" size="20" class="inputgrey" /></td>
    </tr>
    <tr>
      <td></td>
      <td><input type="submit" id="btnsubmit" value="确定" class="button" /></td>
    </tr>
  </table>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'用户道具界面
'========================================================
Sub MemberItem()
	Dim Operation, ItemListArray, MyItemListArray
	ItemListArray = RQ.Query("SELECT itemid, name, types FROM "& TablePre &"items WHERE available = 1 ORDER BY displayorder ASC")

	Operation = Request.QueryString("op")
	Select Case Operation
		Case "all"
			MyItemListArray = RQ.Query("SELECT mi.num, it.itemid, it.name, it.description FROM "& TablePre &"memberitems mi INNER JOIN "& TablePre &"items it ON mi.itemid = it.itemid WHERE mi.uid = "& RQ.UserID &" ORDER BY it.displayorder ASC")
		Case "member"
			MyItemListArray = RQ.Query("SELECT mi.num, it.itemid, it.name, it.description FROM "& TablePre &"memberitems mi INNER JOIN "& TablePre &"items it ON mi.itemid = it.itemid WHERE mi.uid = "& RQ.UserID &" AND it.types = 'member' ORDER BY it.displayorder ASC")
	End Select

	Call closeDatabase()

	RQ.PageBaseTarget = CacheName &"useitem"
	RQ.Header()
%>
<body class="blankbg">
[<a href="?action=memberitem&op=all" target="_self" class="bluelink">所有道具</a>][<a
href="?action=memberitem&op=member" target="_self" class="bluelink">在此用的道具</a>][<a href="itemmarket.asp" class="bluelink">道具市场</a>][<a href="itemmarket.asp?action=myitem" class="bluelink">查看寄卖的道具</a>]
<p>
<table border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td width="50%"><form method="post" name="acoption1" action="?action=acoption">
        <select name="itemid">
          <% If IsArray(ItemListArray) Then %>
          <% For i = 0 To UBound(ItemListArray, 2) %>
          <% If ItemListArray(2, i) = "member" Then %>
          <option value="<%= ItemListArray(0, i) %>"><%= ItemListArray(1, i) %></option>
          <% End If %>
          <% Next %>
          <% End If %>
        </select><input type="submit" name="btnuse" value="使用" class="button" />
      </form></td>
    <td><form method="post" name="acoption2" action="?action=acoption">
        <select name="itemid">
          <% If IsArray(ItemListArray) Then %>
          <% For i = 0 To UBound(ItemListArray, 2) %>
          <option value="<%= ItemListArray(0, i) %>"><%= ItemListArray(1, i) %></option>
          <% Next %>
          <% End If %>
        </select><input type="submit" name="btntransfer" value="转让" class="button" /><input type="submit" name="btnsell" value="寄卖" class="button" />
      </form></td>
  </tr>
</table>
<p>
<% If IsArray(MyItemListArray) Then %>
<form name="useitem3" method="post" action="?action=acoption">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td width="10%">选择</td>
      <td width="25%">名称</td>
      <td width="15%">数量</td>
      <td>说明</td>
    </tr>
    <% For i = 0 To UBound(MyItemListArray, 2) %>
    <tr>
      <td><input type="radio" name="itemid" value="<%= MyItemListArray(1, i) %>" /></td>
      <td><%= MyItemListArray(2, i) %></td>
      <td><%= MyItemListArray(0, i) %></td>
      <td><%= MyItemListArray(3, i) %></td>
    </tr>
    <% Next %>
  </table>
  <p>
    <input type="submit" name="btnuse" value="使用" class="button" />
    <input type="submit" name="btntransfer" value="转让" class="button" />
    <input type="submit" name="btnsell" value="寄卖" class="button" />
  </p>
</form>
<% End If %>
<%
	RQ.Footer()
End Sub

'========================================================
'列出帖子道具
'========================================================
Sub TopicItem()
	Dim Operation, TopicInfo, PostID, PostInfo, SqlTypes
	Dim ItemListArray, ItemInfo, blnShowFacePanel, AnonymityNum

	Operation = Request.QueryString("op")
	If Operation = "anonymity" Then
		'验证回复
		PostID = SafeRequest(3, "pid", 0, 0, 0)
		PostInfo = RQ.Query("SELECT ifanonymity FROM "& TablePre &"posts WHERE pid = "& PostID)
		If Not IsArray(PostInfo) Then
			Call RQ.showTips("回复不存在或者已经被删除。", "", "")
		End If

		'是否是使用道具：面子
		If PostInfo(0, 0) > 1 Then
			ItemInfo = RQ.Query("SELECT 1 FROM "& TablePre &"items WHERE identifier = 'viewanonymity' AND available = 1")
			If Not IsArray(ItemInfo) Then
				Call RQ.showTips("道具无效。", "", "HALTED")
			End If

			blnShowFacePanel = True
			AnonymityNum = PostInfo(0, 0)
		End If

		SqlTypes = "anonymity"
	Else
		'验证帖子
		TopicInfo = RQ.Query("SELECT 1 FROM "& TablePre &"topics WHERE tid = "& RQ.TopicID &" AND displayorder >= 0")
		If Not IsArray(TopicInfo) Then
			Call RQ.showTips("帖子不存在或者已经被删除或者还没有通过审核。", "", "")
		End If

		SqlTypes = "topic"
	End If

	'按照道具类型读取道具列表
	ItemListArray = RQ.Query("SELECT itemid, name, identifier, description FROM "& TablePre &"items WHERE types = '"& SqlTypes &"' AND available = 1 ORDER BY displayorder ASC")

	Call closeDatabase()
	RQ.Header()
%>
<body class="blankbg">
<% If blnShowFacePanel Then %>
有面子就是有面子……<br />
当然你可以花<%= AnonymityNum %>个照妖镜<a href="###" onclick="postvalue('?action=viewface', 'pid', '<%= PostID %>')" class="underline">看看我是谁。</a>
<% Else %>
<form method="post" action="?action=useitem">
  <input type="hidden" name="tid" value="<%= RQ.TopicID %>" />
  <input type="hidden" name="pid" value="<%= PostID %>" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td colspan="3">使用道具：<%= ItemName %></td>
    </tr>
    <% If IsArray(ItemListArray) Then %>
    <% For i = 0 To UBound(ItemListArray, 2) %>
    <tr>
      <td><input type="radio" value="<%= ItemListArray(0, i) %>" name="itemid" /></td>
      <td nowrap><%= ItemListArray(1, i) %></td>
      <td nowrap><%= ItemListArray(3, i) %>
        <% If ItemListArray(2, i) = "settopiccolor" Then '如果是醒目灯则显示颜色下拉框 %>
        <select name="color">
          <option style="color: #000000; background: #000000" value="#000000">#000000</option>
          <option style="color: #00ffff; background: #00ffff" value="#00FFFF">#00FFFF</option>
          <option style="color: #7fffd4; background: #7fffd4" value="#7FFFD4">#7FFFD4</option>
          <option style="color: #0000ff; background: #0000ff" value="#0000FF">#0000FF</option>
          <option style="color: #8a2be2; background: #8a2be2" value="#8A2BE2">#8A2BE2</option>
          <option style="color: #a52a2a; background: #a52a2a" value="#A52A2A">#A52A2A</option>
          <option style="color: #deb887; background: #deb887" value="#DEB887">#DEB887</option>
          <option style="color: #5f9ea0; background: #5f9ea0" value="#5F9EA0">#5F9EA0</option>
          <option style="color: #7fff00; background: #7fff00" value="#7FFF00">#7FFF00</option>
          <option style="color: #d2691e; background: #d2691e" value="#D2691E">#D2691E</option>
          <option style="color: #ff7f50; background: #ff7f50" value="#FF7F50">#FF7F50</option>
          <option style="color: #1e90ff; background: #1e90ff" value="#1E90FF">#1E90FF</option>
          <option style="color: #696969; background: #696969" value="#696969">#696969</option>
          <option style="color: #6495ed; background: #6495ed" value="#6495ED">#6495ED</option>
          <option style="color: #dc143c; background: #dc143c" value="#DC143C">#DC143C</option>
          <option style="color: #00ffff; background: #00ffff" value="#00FFFF">#00FFFF</option>
          <option style="color: #00008b; background: #00008b" value="#00008B">#00008B</option>
          <option style="color: #ff0000; background: #ff0000" value="#ff0000">#ff0000</option>
          <option style="color: #b8860b; background: #b8860b" value="#B8860B">#B8860B</option>
          <option style="color: #a9a9a9; background: #a9a9a9" value="#A9A9A9">#A9A9A9</option>
          <option style="color: #006400; background: #006400" value="#006400">#006400</option>
          <option style="color: #bdb76b; background: #bdb76b" value="#BDB76B">#BDB76B</option>
          <option style="color: #8b008b; background: #8b008b" value="#8B008B">#8B008B</option>
          <option style="color: #556b2f; background: #556b2f" value="#556B2F">#556B2F</option>
          <option style="color: #ff8c00; background: #ff8c00" value="#FF8C00">#FF8C00</option>
          <option style="color: #9932cc; background: #9932cc" value="#9932CC">#9932CC</option>
          <option style="color: #8b0000; background: #8b0000" value="#8B0000">#8B0000</option>
          <option style="color: #e9967a; background: #e9967a" value="#E9967A">#E9967A</option>
          <option style="color: #8fbc8f; background: #8fbc8f" value="#8FBC8F">#8FBC8F</option>
          <option style="color: #483d8b; background: #483d8b" value="#483D8B">#483D8B</option>
          <option style="color: #2f4f4f; background: #2f4f4f" value="#2F4F4F">#2F4F4F</option>
          <option style="color: #00ced1; background: #00ced1" value="#00CED1">#00CED1</option>
          <option style="color: #9400d3; background: #9400d3" value="#9400D3">#9400D3</option>
        </select>
        <% End If %>
      </td>
    </tr>
    <% Next %>
    <% End If %>
  </table>
  <p>
    <input type="submit" value="使用" class="button" />
  </p>
</form>
<%
	End If
	RQ.Footer()
End Sub

'========================================================
'用户道具界面框架
'========================================================
Sub Main()
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<title>使用道具 - <%= RQ.Base_Settings(0) %></title>
</head>
<frameset rows="50%,*">
  <frame name="<%= CacheName %>itemlist" scrolling="auto" target="main" src="?action=memberitem" />
  <frame name="<%= CacheName %>useitem" src="" scrolling="auto" />
  <noframes>
    <body><p>您使用的浏览器不支持框架，请使用支持框架的浏览器打开。</p></body>
  </noframes>
</frameset>
</html>
<% End Sub %>