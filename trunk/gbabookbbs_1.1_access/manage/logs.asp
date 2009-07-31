<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AllowViewLog = 0 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "reginvate"
		Call RegInvate()
	Case "itemuse"
		Call ItemUse()
	Case "itemmarket"
		Call ItemMarket()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'推荐码注册
'========================================================
Sub RegInvate()
	If RQ.AdminGroupID <> 1 And RQ.AdminGroupID <> 2 Then
		Call AdminshowTips("您无权进行访问。", "")
	End If

	Dim Keyword, Status
	Dim Page, PageCount, RecordCount, strSQL, sqlwhere, sqlpage
	Dim LogListArray

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Status = SafeRequest(3, "status", 1, "", 0)

	If Len(Keyword) > 0 Then
		sqlwhere = " AND uid IN (SELECT uid FROM "& TablePre &"members WHERE username LIKE '%"& Keyword &"%')"
		sqlpage = " AND inv.uid IN (SELECT uid FROM "& TablePre &"members WHERE username LIKE '%"& Keyword &"%')"
	End If

	Select Case Status
		Case "new"
			sqlwhere = " AND status = 0"
			sqlpage = " AND inv.status = 0"
		Case "used"
			sqlwhere = " AND status = 1"
			sqlpage = " AND inv.status = 1"
	End Select

	RQ.Execute("DELETE FROM "& TablePre &"invate WHERE expirytime < #"& Now() &"# AND status = 0")

	RecordCount = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"invate WHERE 1 = 1"& sqlwhere)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)

		If Page > PageCount Then
			Page = PageCount
		End If

		strSQL = "SELECT TOP 30 inv.uid, inv.username, inv.status, inv.invatecode, inv.buytime, inv.expirytime, inv.reguid, inv.regtime, m.username FROM "& TablePre &"invate inv LEFT JOIN "& TablePre &"members m ON inv.reguid = m.uid WHERE 1 = 1"& sqlpage
		If Page > 1 Then
			strSQL = strSQL &" AND buytime < (SELECT MIN(buytime) FROM (SELECT TOP "& 30 * (Page - 1) &" buytime FROM "& TablePre &"invate WHERE 1 = 1 "& sqlwhere &" ORDER BY buytime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY inv.buytime DESC"

		LogListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;推荐码注册记录</td>
  </tr>
</table>
<br />
<form name="fmsearch" id="fmsearch" action="?" method="get">
  <input type="hidden" name="action" value="reginvate" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>搜索</td>
    </tr>
    <tr class="altbg2">
      <td>按用户名搜索:
        <input type="text" name="keyword" size="30" value="<%= Keyword %>" />
		<select name="status" onchange="$('fmsearch').submit();">
          <option value="">是否使用</option>
		  <option value="new"<% If Status = "new" Then Response.Write " selected" End If %>>未使用</option>
		  <option value="used"<% If Status = "used" Then Response.Write " selected" End If %>>已使用</option>
		</select>
        <input type="submit" value="搜索" class="s_button" /></td>
    </tr>
  </table>
</form>
<br />
<form name="fmlog" method="post" action="?action=deletelog">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">推荐码注册记录</td>
    </tr>
    <tr class="category">
      <td>购买人</td>
      <td>购买时间</td>
      <td>到期时间</td>
	  <td>推荐码</td>
      <td>推荐码状态</td>
      <td>注册用户</td>
      <td>注册时间</td>
    </tr>
    <% If IsArray(LogListArray) Then %>
    <% For i = 0 To UBound(LogListArray, 2) %>
    <tr>
      <td class="altbg1"><a href="members.asp?action=detail&uid=<%= LogListArray(0, i) %>"><%= LogListArray(1, i) %></a></td>
      <td class="altbg2"><%= LogListArray(4, i) %></td>
      <td class="altbg1"><%= LogListArray(5, i) %></td>
	  <td class="altbg2"><%= LogListArray(3, i) %></td>
	  <td class="altbg1"><% If LogListArray(2, i) = 0 Then %>未使用<% Else %>已使用<% End If %></td>
      <td class="altbg2"><% If LogListArray(6, i) > 0 Then %><a href="members.asp?action=detail&uid=<%= LogListArray(6, i) %>"><%= LogListArray(8, i) %></a><% End If %></td>
      <td class="altbg1"><% If LogListArray(7, i) > 0 Then Response.Write NumtoDate(LogListArray(7, i)) End If %></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="7"><em>暂无</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center"><% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=itemuse&keyword="& Keyword &"&itemid="& ItemID) %></div>
  <% End If %>
</form>
<%
End Sub

'========================================================
'道具使用记录
'========================================================
Sub ItemUse()
	If RQ.AdminGroupID <> 1 And RQ.AdminGroupID <> 2 Then
		Call AdminshowTips("您无权进行访问。", "")
	End If

	Dim Keyword, ItemID
	Dim Page, PageCount, RecordCount, strSQL, sqlwhere, sqlpage
	Dim LogListArray, ItemListArray

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	ItemID = SafeRequest(3, "itemid", 0, 0, 0)

	If Len(Keyword) > 0 Then
		sqlwhere = " AND im.username LIKE '%"& Keyword &"%' OR im.targetusername LIKE '%"& Keyword &"%'"
		sqlpage = " AND username LIKE '%"& Keyword &"%' OR targetusername LIKE '%"& Keyword &"%'"
	End If

	If ItemID > 0 Then
		sqlwhere = sqlwhere &" AND im.itemid = "& ItemID
		sqlpage = sqlpage &" AND itemid = "& ItemID
	End If

	RecordCount = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"itemuselogs WHERE 1 = 1"& sqlpage)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)

		If Page > PageCount Then
			Page = PageCount
		End If

		strSQL = "SELECT TOP 30 im.itemid, im.tid, im.uid, im.username, im.userip, im.targetuid, im.targetusername, im.operation, im.posttime, i.name, IIF(t.title IS NULL, '', t.title) FROM ("& TablePre &"itemuselogs im INNER JOIN "& TablePre &"items i ON im.itemid = i.itemid) LEFT JOIN "& TablePre &"topics t ON im.tid = t.tid WHERE 1 = 1"& sqlwhere
		If Page > 1 Then
			strSQL = strSQL &" AND im.posttime < (SELECT MIN(posttime) FROM (SELECT TOP "& 30 * (Page - 1) &" posttime FROM "& TablePre &"itemuselogs WHERE 1 = 1"& sqlpage &" ORDER BY posttime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY im.posttime DESC"

		LogListArray = RQ.Query(strSQL)
	End If

	ItemListArray = RQ.Query("SELECT itemid, name FROM "& TablePre &"items ORDER BY displayorder ASC")

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;道具使用记录</td>
  </tr>
</table>
<br />
<form name="fmsearch" id="fmsearch" action="?" method="get">
  <input type="hidden" name="action" value="itemuse" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>搜索</td>
    </tr>
    <tr class="altbg2">
      <td>按用户名搜索:
        <input type="text" name="keyword" size="30" value="<%= Keyword %>" />
		<select name="itemid" onchange="$('fmsearch').submit();">
		  <option value="0">选择道具的详细记录</option>
		  <% If IsArray(ItemListArray) Then %>
		  <% For i = 0 To UBound(ItemListArray, 2) %>
		  <option value="<%= ItemListArray(0, i) %>"<% If ItemID = ItemListArray(0, i) Then Response.Write " selected" End If %>><%= ItemListArray(1, i) %></option>
		  <% Next %>
		  <% End If %>
		</select>
        <input type="submit" value="搜索" class="s_button" /></td>
    </tr>
  </table>
</form>
<br />
<form name="fmlog" method="post" action="?action=deletelog">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">道具使用记录</td>
    </tr>
    <tr class="category">
      <td>道具名称</td>
      <td>使用人</td>
      <td>使用人IP</td>
      <td>被使用人</td>
      <td>相关帖</td>
      <td>操作</td>
      <td width="19%">操作时间</td>
    </tr>
    <% If IsArray(LogListArray) Then %>
    <% For i = 0 To UBound(LogListArray, 2) %>
    <tr>
      <td class="altbg1"><a href="?action=itemuse&itemid=<%= LogListArray(0, i) %>"><%= LogListArray(9, i) %></a></td>
      <td class="altbg2"><a href="members.asp?action=detail&uid=<%= LogListArray(2, i) %>"><%= LogListArray(3, i) %></a></td>
      <td class="altbg1"><%= LogListArray(4, i) %></td>
      <td class="altbg2"><a href="members.asp?action=detail&uid=<%= LogListArray(5, i) %>"><%= LogListArray(6, i) %></a></td>
      <td class="altbg1"><% If Len(LogListArray(10, i)) > 0 Then %><a href="../viewtopic.asp?tid=<%= LogListArray(1, i) %>" target="_blank"><%= dfc(LogListArray(10, i)) %></a><% End If %></td>
      <td class="altbg2"><%= LogListArray(7, i) %></td>
      <td class="altbg1"><%= LogListArray(8, i) %></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="7"><em>暂无</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center"><% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=itemuse&keyword="& Keyword &"&itemid="& ItemID) %></div>
  <% End If %>
</form>
<%
End Sub

'========================================================
'道具转让记录
'========================================================
Sub ItemMarket()
	Dim Keyword, ItemID
	Dim Page, PageCount, RecordCount, strSQL, sqlwhere, sqlpage
	Dim LogListArray, ItemListArray

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	ItemID = SafeRequest(3, "itemid", 0, 0, 0)

	If Len(Keyword) > 0 Then
		sqlwhere = " AND im.username LIKE '%"& Keyword &"%' OR im.targetusername LIKE '%"& Keyword &"%'"
		sqlpage = " AND username LIKE '%"& Keyword &"%' OR targetusername LIKE '%"& Keyword &"%'"
	End If

	If ItemID > 0 Then
		sqlwhere = sqlwhere &" AND im.itemid = "& ItemID
		sqlpage = sqlpage &" AND itemid = "& ItemID
	End If

	RecordCount = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"itemmarketlogs WHERE 1 = 1"& sqlpage)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)

		If Page > PageCount Then
			Page = PageCount
		End If

		strSQL = "SELECT TOP 30 im.uid, im.username, im.userip, im.targetuid, im.targetusername, im.itemid, im.num, im.price, im.posttime, i.name FROM "& TablePre &"itemmarketlogs im INNER JOIN "& TablePre &"items i ON im.itemid = i.itemid WHERE 1 = 1"& sqlwhere
		If Page > 1 Then
			strSQL = strSQL &" AND im.posttime < (SELECT MIN(posttime) FROM (SELECT TOP "& 30 * (Page - 1) &" posttime FROM "& TablePre &"itemmarketlogs WHERE 1 = 1"& sqlpage &" ORDER BY posttime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY im.posttime DESC"

		LogListArray = RQ.Query(strSQL)
	End If

	ItemListArray = RQ.Query("SELECT itemid, name FROM "& TablePre &"items ORDER BY displayorder ASC")

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;道具转让记录</td>
  </tr>
</table>
<br />
<form name="fmsearch" id="fmsearch" action="?" method="get">
  <input type="hidden" name="action" value="itemmarket" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>搜索</td>
    </tr>
    <tr class="altbg2">
      <td>按用户名搜索:
        <input type="text" name="keyword" size="30" value="<%= Keyword %>" />
		<select name="itemid" onchange="$('fmsearch').submit();">
		  <option value="0">选择道具的详细记录</option>
		  <% If IsArray(ItemListArray) Then %>
		  <% For i = 0 To UBound(ItemListArray, 2) %>
		  <option value="<%= ItemListArray(0, i) %>"<% If ItemID = ItemListArray(0, i) Then Response.Write " selected" End If %>><%= ItemListArray(1, i) %></option>
		  <% Next %>
		  <% End If %>
		</select>
        <input type="submit" value="搜索" class="s_button" /></td>
    </tr>
  </table>
</form>
<br />
<form name="fmlog" method="post" action="?action=deletelog">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">道具转让记录</td>
    </tr>
    <tr class="category">
      <td>道具名称</td>
      <td>接收人</td>
      <td>转让人</td>
      <td>转让人IP</td>
      <td>数量</td>
      <td>总价格</td>
      <td width="19%">操作时间</td>
    </tr>
    <% If IsArray(LogListArray) Then %>
    <% For i = 0 To UBound(LogListArray, 2) %>
    <tr>
      <td class="altbg1"><a href="?action=itemmarket&itemid=<%= LogListArray(5, i) %>"><%= LogListArray(9, i) %></a></td>
      <td class="altbg2"><a href="members.asp?action=detail&uid=<%= LogListArray(3, i) %>"><%= LogListArray(4, i) %></a></td>
      <td class="altbg1"><a href="members.asp?action=detail&uid=<%= LogListArray(0, i) %>"><%= LogListArray(1, i) %></a></td>
      <td class="altbg2"><%= LogListArray(2, i) %></td>
      <td class="altbg1"><%= LogListArray(6, i) %></td>
      <td class="altbg2"><%= LogListArray(7, i) %></td>
      <td class="altbg1"><%= LogListArray(8, i) %></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="7"><em>暂无</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center"><% Call ShowPageInfo(Page, PageCount, RecordCount, "&action=itemmarket&keyword="& Keyword &"&itemid="& ItemID) %></div>
  <% End If %>
</form>
<%
End Sub

'========================================================
'用户异动报告
'========================================================
Sub Main()
	Dim Keyword
	Dim Page, PageCount, RecordCount, strSQL, sqlwhere
	Dim LogListArray

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")

	If Len(Keyword) > 0 Then
		sqlwhere = " AND username LIKE '%"& Keyword &"%' OR targetusername LIKE '%"& Keyword &"%'"
	End If

	RecordCount = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"logs WHERE 1 = 1"& sqlwhere)(0)
	dbQueryNum = dbQueryNum + 1

	If RecordCount > 0 Then
		PageCount = ABS(Int(-(RecordCount / 30)))
		Page = SafeRequest(3, "page", 0, 1, 0)

		If Page > PageCount Then
			Page = PageCount
		End If

		strSQL = "SELECT TOP 30 uid, username, userip, targetuid, targetusername, operation, reason, posttime FROM "& TablePre &"logs WHERE 1 = 1"& sqlwhere
		If Page > 1 Then
			strSQL = strSQL &" AND posttime < (SELECT MIN(posttime) FROM (SELECT TOP "& 30 * (Page - 1) &" posttime FROM "& TablePre &"logs WHERE 1 = 1"& sqlwhere &" ORDER BY posttime DESC) AS tblTemp)"
		End If
		strSQL = strSQL &" ORDER BY posttime DESC"

		LogListArray = RQ.Query(strSQL)
	End If

	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;异动报告</td>
  </tr>
</table>
<br />
<form name="fmsearch" action="?" method="get">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>搜索</td>
    </tr>
    <tr class="altbg2">
      <td>按用户名搜索:
        <input type="text" name="keyword" size="30" value="<%= Keyword %>" />
        <input type="submit" value="搜索" class="s_button" /></td>
    </tr>
  </table>
</form>
<br />
<form name="fmlog" method="post" action="?action=deletelog">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">异动报告</td>
    </tr>
    <tr class="category">
      <td>被修改人</td>
      <td>修改人</td>
      <td>修改人IP</td>
      <td>异动内容</td>
      <td>异动原因</td>
      <td width="19%">操作时间</td>
    </tr>
    <% If IsArray(LogListArray) Then %>
    <% For i = 0 To UBound(LogListArray, 2) %>
    <tr>
      <td class="altbg1"><a href="members.asp?action=detail&uid=<%= LogListArray(3, i) %>"><%= LogListArray(4, i) %></a></td>
      <td class="altbg2"><a href="members.asp?action=detail&uid=<%= LogListArray(0, i) %>"><%= LogListArray(1, i) %></a></td>
      <td class="altbg1"><%= LogListArray(2, i) %></td>
      <td class="altbg2"><%= LogListArray(5, i) %></td>
      <td class="altbg1"><%= LogListArray(6, i) %></td>
      <td class="altbg2"><%= LogListArray(7, i) %></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="7"><em>暂无</em></td>
	</tr>
    <% End If %>
  </table>
  <% If PageCount > 1 Then %>
  <div align="center"><% Call ShowPageInfo(Page, PageCount, RecordCount, "&keyword="& Keyword) %></div>
  <% End If %>
</form>
<%
End Sub
%>