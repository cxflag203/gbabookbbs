<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action, TypesArray
Action = Request.QueryString("action")
TypesArray = Array("member", "topic", "anonymity", "other")

Select Case Action
	Case "itemop"
		Call ItemOperation()
	Case "update"
		Call Update()
	Case "edit"
		Call Edit()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'道具列表相关更改
'========================================================
Sub ItemOperation()
	Dim d_ItemID
	Dim ItemID, Name, Available, Iflog, DisplayOrder
	Dim ItemInfo, New_Name, New_Types, New_Identifier, New_Available, New_Iflog, New_DisplayOrder

	d_ItemID = NumberGroupFilter(Replace(SafeRequest(2, "d_itemid", 1, "", 0), " ", ""))
	If Len(d_ItemID) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"itemmarket WHERE itemid IN("& d_ItemID &")")
		RQ.Execute("DELETE FROM "& TablePre &"itemmarketlogs WHERE itemid IN("& d_ItemID &")")
		RQ.Execute("DELETE FROM "& TablePre &"itemuselogs WHERE itemid IN("& d_ItemID &")")
		RQ.Execute("DELETE FROM "& TablePre &"itemmessages WHERE itemid IN("& d_ItemID &")")
		RQ.Execute("DELETE FROM "& TablePre &"memberitems WHERE itemid IN("& d_ItemID &")")
		RQ.Execute("DELETE FROM "& TablePre &"items WHERE itemid IN("& d_ItemID &")")
	End If

	If Request.Form("itemid").Count > 0 Then
		For i = 1 To Request.Form("itemid").Count
			ItemID = IntCode(Request.Form("itemid")(i))
			Name = strFilter(Request.Form("name")(i))
			Available = IntCode(Request.Form("available_"& ItemID))
			Iflog = IntCode(Request.Form("iflog_"& ItemID))
			DisplayOrder = IntCode(Request.Form("displayorder")(i))
			Available = IIF(Available > 1, 0, Available)
			Iflog = IIF(Iflog > 1, 0, Iflog)

			If ItemID > 0 And Len(Name) > 0 Then
				RQ.Execute("UPDATE "& TablePre &"items SET name = '"& Name &"', available = "& Available &", iflog = "& IfLog &", displayorder = "& DisplayOrder &" WHERE itemid = "& ItemID)
			End If
		Next
	End If

	New_Name = SafeRequest(2, "new_name", 1, "", 0)
	New_Types = SafeRequest(2, "new_types", 1, "", 0)
	New_Identifier = SafeRequest(2, "new_identifier", 1, "", 0)
	New_Available = SafeRequest(2, "new_available", 0, 0, 0)
	New_Iflog = SafeRequest(2, "new_iflog", 0, 0, 0)
	New_DisplayOrder = SafeRequest(2, "new_displayorder", 0, 0, 0)

	If Len(CheckContent(New_Name)) > 0 And InArray(Array("member", "topic", "anonymity", "other"), New_Types) And Len(CheckContent(New_Identifier)) > 0 And InArray(Array(0, 1), New_Available) And InArray(Array(0, 1), New_Iflog) Then
		ItemInfo = RQ.Query("SELECT 1 FROM "& TablePre &"items WHERE identifier = '"& New_Identifier &"'")
		If Not IsArray(ItemInfo) Then
			RQ.Execute("INSERT INTO "& TablePre &"items (name, types, identifier, available, iflog, displayorder) VALUES ('"& New_Name &"', '"& New_Types &"', '"& New_Identifier &"', "& New_Available &", "& New_Iflog &", "& New_DisplayOrder &")")
		End If
	End If

	Call closeDatabase()
	Call AdminshowTips("道具设置更新成功。", "?")
End Sub

'========================================================
'编辑道具设置(保存)
'========================================================
Sub Update()
	Dim ItemID, ItemInfo, Name, Types, Identifier, Available, Iflog, Description
	ItemID = SafeRequest(2, "itemid", 0, 0, 0)
	Name = SafeRequest(2, "name", 1, "", 0)
	Types = SafeRequest(2, "types", 1, "", 0)
	Identifier = CheckContent(SafeRequest(2, "identifier", 1, "", 0))
	Available = SafeRequest(2, "available", 0, 0, 0)
	Iflog = SafeRequest(2, "iflog", 0, 0, 0)
	Description = SafeRequest(2, "description", 1, "", 1)

	If Len(CheckContent(Name)) = 0 Then
		Call AdminshowTips("请填写好道具名称。", "")
	End If

	If Not InArray(TypesArray, Types) Then
		Call AdminshowTips("请选择道具类型。", "")
	End If

	If Len(Identifier) = 0 Then
		Call AdminshowTips("请填写好道具标识。", "")
	End If

	Available = IIF(Available > 1, 0, Available)
	Iflog = IIF(Iflog > 1, 0, Iflog)
	Description = IIF(Len(Description) > 255, Left(Description, 255), Description)
	Description = Replace(Description, vbCrLf, "<br />")

	ItemInfo = RQ.Query("SELECT 1 FROM "& TablePre &"items WHERE itemid = "& ItemID)
	If Not IsArray(ItemInfo) Then
		Call AdminshowTips("道具不存在或者已经被删除。", "")
	End If

	ItemInfo = RQ.Query("SELECT 1 FROM "& TablePre &"items WHERE itemid <> "& ItemID &" AND identifier = '"& Identifier &"'")
	If IsArray(ItemInfo) Then
		Call AdminshowTips("道具标识("& Identifier &")已经有其他道具使用了，请更换一个。", "")
	End If

	RQ.Execute("UPDATE "& TablePre &"items SET name = '"& Name &"', types = '"& Types &"', identifier = '"& Identifier &"', available = "& Available &", iflog = "& Iflog &", description = '"& Description &"' WHERE itemid = "& ItemID)

	Call closeDatabase()
	Call AdminshowTips("道具设置更新成功。", "?")
End Sub

'========================================================
'编辑道具设置
'========================================================
Sub Edit()
	Dim ItemID, ItemInfo

	ItemID = SafeRequest(3, "itemid", 0, 0, 0)
	ItemInfo = RQ.Query("SELECT name, types, identifier, available, iflog, description FROM "& TablePre &"items WHERE itemid = "& ItemID)

	Call closeDatabase()

	If Not IsArray(ItemInfo) Then
		Call AdminshowTips("道具不存在或者已经被删除。", "")
	End If
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;道具设置</td>
  </tr>
</table>
<br />
<form method="post" name="form1" action="?action=update" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="itemid" value="<%= ItemID %>" />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>道具设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>道具名称:</strong></td>
      <td width="70%"><input type="text" name="name" value="<%= ItemInfo(0, 0) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>道具类型:</strong><br />这里请勿随意改动，以免使用无效。</td>
      <td width="70%"><select name="types">
	    <option value="">--</option>
	    <option value="member"<% If ItemInfo(1, 0) = "member" Then Response.Write " selected" End If %>>用户相关</option>
	    <option value="topic"<% If ItemInfo(1, 0) = "topic" Then Response.Write " selected" End If %>>帖子相关</option>
		<option value="anonymity"<% If ItemInfo(1, 0) = "anonymity" Then Response.Write " selected" End If %>>匿名相关</option>
		<option value="other"<% If ItemInfo(1, 0) = "other" Then Response.Write " selected" End If %>>其他</option>
	  </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>道具标识:</strong><br />这里请勿随意改动，道具标识关联了该道具的执行脚本<br />(/include/items/<span id="showitemindifier"></span>.asp)</td>
      <td width="70%"><input type="text" name="identifier" id="identifier" value="<%= ItemInfo(2, 0) %>" onkeyup="javascript:showtext();" />
	    <script type="text/javascript">function showtext(){$('showitemindifier').innerHTML = $('identifier').value} showtext();</script></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否可用:</strong></td>
      <td width="70%"><input type="checkbox" name="available" id="available" value="1" class="radio"<% If ItemInfo(3, 0) = 1 Then Response.Write " checked" End If %> /><label for="available">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否记录使用日志:</strong></td>
      <td width="70%"><input type="checkbox" name="iflog" id="iflog" value="1" class="radio"<% If ItemInfo(4, 0) = 1 Then Response.Write " checked" End If %> /><label for="iflog">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>道具说明:</strong></td>
      <td width="70%"><textarea name="description" rows="5" cols="40"><%= Preg_Replace(ItemInfo(5, 0), "<br(.*?)>", vbCrLf) %></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"></td>
      <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'道具列表
'========================================================
Sub Main()
	Dim ItemListArray, types, strSQL

	types = SafeRequest(3, "types", 1, "", 0)
	If InArray(TypesArray, types) Then
		strSQL = " AND types = '"& types &"'"
	End If

	ItemListArray = RQ.Query("SELECT itemid, name, types, identifier, available, iflog, displayorder FROM "& TablePre &"items WHERE 1 = 1"& strSQL &" ORDER BY displayorder ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;道具设置</td>
  </tr>
</table>
<br />
<form name="fmfilter" id="fmfilter" action="?" method="get">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>筛选</td>
    </tr>
    <tr class="altbg2">
      <td>按类型筛选：<select name="types" onchange="$('fmfilter').submit();">
	    <option value="">--</option>
	    <option value="member"<% If types = "member" Then Response.Write " selected" End If %>>用户相关</option>
	    <option value="topic"<% If types = "topic" Then Response.Write " selected" End If %>>帖子相关</option>
		<option value="anonymity"<% If types = "anonymity" Then Response.Write " selected" End If %>>匿名相关</option>
		<option value="other"<% If types = "other" Then Response.Write " selected" End If %>>其他</option>
	  </select></td>
    </tr>
  </table>
</form>
<br />
<form name="items" method="post" action="?action=itemop" onsubmit="$('submit1').value='正在提交,请稍后...';$('submit1').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%">删?</td>
      <td>道具名称</td>
      <td>类型</td>
      <td>标识</td>
      <td>可用</td>
	  <td>记录使用日志</td>
      <td>显示顺序</td>
      <td>操作</td>
    </tr>
    <% If IsArray(ItemListArray) Then %>
    <% For i = 0 To UBound(ItemListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_itemid" value="<%= ItemListArray(0, i) %>" class="radio" />
	    <input type="hidden" name="itemid" value="<%= ItemListArray(0, i) %>" /></td>
      <td class="altbg2"><input type="input" name="name" value="<%= ItemListArray(1, i) %>" size="20" /></td>
      <td class="altbg1"><%
Select Case ItemListArray(2, i)
	Case "member"
		Response.Write "用户相关"
	Case "topic"
		Response.Write "帖子相关"
	Case "anonymity"
		Response.Write "匿名相关"
	Case "other"
		Response.Write "其他"
End Select
      %></td>
      <td class="altbg2"><%= ItemListArray(3, i) %></td>
      <td class="altbg1"><input type="checkbox" name="available_<%= ItemListArray(0, i) %>" value="1" class="radio"<% If ItemListArray(4, i) = 1 Then Response.Write " checked" End If %> /></td>
      <td class="altbg2"><input type="checkbox" name="iflog_<%= ItemListArray(0, i) %>" value="1" class="radio"<% If ItemListArray(5, i) = 1 Then Response.Write " checked" End If %> /></td>
      <td class="altbg1" width="12%"><input type="text" name="displayorder" size="5" value="<%= ItemListArray(6, i) %>" /></td>
      <td class="altbg2"><a href="?action=edit&itemid=<%= ItemListArray(0, i) %>">编辑</a></td>
    </tr>
    <% Next %>
    <% End If %>
	<tr>
      <td class="altbg1">新增：</td>
	  <td class="altbg2"><input type="input" name="new_name" size="20" /></td>
	  <td class="altbg1"><select name="new_types">
	    <option value="">请选择</option>
		<option value="member">用户相关</option>
		<option value="topic">帖子相关</option>
		<option value="anonymity">匿名相关</option>
		<option value="other">其他</option>
	  </select></td>
	  <td class="altbg2"><input type="text" name="new_identifier" size="20" /></td>
	  <td class="altbg1"><input type="checkbox" name="new_available" value="1" class="radio" /></td>
	  <td class="altbg2"><input type="checkbox" name="new_iflog" value="1" class="radio" /></td>
	  <td class="altbg1"><input type="text" name="new_displayorder" size="5" value="<%= i + 1 %>" /></td>
	  <td class="altbg2"></td>
	</tr>
  </table>
  <p align="center"><input type="submit" id="submit1" value="提交设置" class="button" /></p>
</form>
<%
End Sub
%>