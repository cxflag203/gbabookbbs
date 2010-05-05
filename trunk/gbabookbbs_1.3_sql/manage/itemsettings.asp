<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "savesettings"
		Call SaveSettings()
	Case Else
		Call Main()
End Select
AdminFooter()

Sub SaveSettings()
	Dim Item_Settings(11), Settings

	Item_Settings(0) = SafeRequest(2, "item_settings_0", 0, 0, 0)
	Item_Settings(1) = SafeRequest(2, "item_settings_1", 0, 60, 0)
	Item_Settings(2) = SafeRequest(2, "item_settings_2", 0, 24, 0)
	Item_Settings(3) = SafeRequest(2, "item_settings_3", 0, 72, 0)
	Item_Settings(4) = SafeRequest(2, "item_settings_4", 0, 2, 0)

	Item_Settings(5) = SafeRequest(2, "item_settings_5", 0, 100, 0)
	If Item_Settings(5) > 100 Then
		Item_Settings(5) = 4
	End If

	Item_Settings(6) = SafeRequest(2, "item_settings_6", 0, 4, 0)
	If Item_Settings(6) > 100 Then
		Item_Settings(6) = 100
	End If

	Item_Settings(7) = SafeRequest(2, "item_settings_7", 0, 4700, 0)
	Item_Settings(8) = SafeRequest(2, "item_settings_8", 0, 470, 0)
	Item_Settings(9) = SafeRequest(2, "item_settings_9", 0, 170, 0)
	Item_Settings(10) = SafeRequest(2, "item_settings_10", 0, 17, 0)
	Item_Settings(11) = SafeRequest(2, "item_settings_11", 0, 7, 0)

	Settings = Join(Item_Settings, "{settings}")

	RQ.Execute("UPDATE "& TablePre &"settings SET item_settings = N'"& Settings &"'")

	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call AdminshowTips("道具设置已经更新.", "?")
End Sub

Sub Main()
	Dim ItemListArray, ItemDic
	Dim SettingsInfo, Item_Settings

	ItemListArray = RQ.Query("SELECT itemid, name, identifier FROM "& TablePre &"items")

	SettingsInfo = RQ.Query("SELECT item_settings FROM "& TablePre &"settings")

	Call closeDatabase()

	Item_Settings = Split(SettingsInfo(0, 0), "{settings}")

	Set ItemDic = Server.CreateObject("Scripting.Dictionary")

	For i = 0 To UBound(ItemListArray, 2)
		ItemDic.Item(ItemListArray(2, i)) = ItemListArray(1, i)
	Next
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;道具设置</td>
  </tr>
</table>
<br />
<form method="post" name="form1" action="?action=savesettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>道具功能开关</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否打开道具功能:</strong></td>
      <td width="70%"><input type="checkbox" name="item_settings_0" id="item_settings_0" value="1" class="radio" onclick="if($('item_settings_0').checked){$('item_settings').style.display='';}else{$('item_settings').style.display='none';}"<% If Item_Settings(0) = "1" Then Response.Write " checked" End If %> /><label for="item_settings_0">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>清除道具转让记录:</strong></td>
      <td width="70%">自动清除&nbsp;<input type="text" name="item_settings_1" size="5" value="<%= Item_Settings(1) %>" />&nbsp;天后的道具转让记录,默认60天</td>
    </tr>
  </table>
  <br />
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0" id="item_settings">
    <tr class="header">
      <td height="25" colspan="2"><strong>道具设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("sticktopicplus") %>:</strong></td>
      <td width="70%">置顶帖子&nbsp;<input type="text" name="item_settings_2" size="5" value="<%= Item_Settings(2) %>" />&nbsp;小时</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("sticktopic") %>:</strong></td>
      <td width="70%">置顶帖子&nbsp;<input type="text" name="item_settings_3" size="5" value="<%= Item_Settings(3) %>" />&nbsp;小时</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("sinktopic") %>:</strong></td>
      <td width="70%">把帖子送回&nbsp;<input type="text" name="item_settings_4" size="5" value="<%= Item_Settings(4) %>" />&nbsp;天前</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("sinksticktopic") %>:</strong></td>
      <td width="70%">破坏<%= ItemDic.Item("sticktopicplus") %>&nbsp;<input type="text" name="item_settings_5" size="5" value="<%= Item_Settings(5) %>" />&nbsp;%的效果</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("sinksticktopic") %>:</strong></td>
      <td width="70%">破坏<%= ItemDic.Item("sticktopic") %>&nbsp;<input type="text" name="item_settings_6" size="5" value="<%= Item_Settings(6) %>" />&nbsp;%的效果</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("dice") %>:</strong></td>
      <td width="70%">6个骰子相同或连号获得&nbsp;<input type="text" name="item_settings_7" size="5" value="<%= Item_Settings(7) %>" />&nbsp;<%= RQ.Other_Settings(0) %></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("dice") %>:</strong></td>
      <td width="70%">5个骰子相同或连号获得&nbsp;<input type="text" name="item_settings_8" size="5" value="<%= Item_Settings(8) %>" />&nbsp;<%= RQ.Other_Settings(0) %></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("dice") %>:</strong></td>
      <td width="70%">4个骰子相同或连号获得&nbsp;<input type="text" name="item_settings_9" size="5" value="<%= Item_Settings(9) %>" />&nbsp;<%= RQ.Other_Settings(0) %></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("dice") %>:</strong></td>
      <td width="70%">3个骰子相同或连号获得&nbsp;<input type="text" name="item_settings_10" size="5" value="<%= Item_Settings(10) %>" />&nbsp;<%= RQ.Other_Settings(0) %></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong><%= ItemDic.Item("dice") %>:</strong></td>
      <td width="70%">2个骰子相同获得&nbsp;<input type="text" name="item_settings_11" size="5" value="<%= Item_Settings(11) %>" />&nbsp;<%= RQ.Other_Settings(0) %></td>
    </tr>
  </table>
  <script type="text/javascript">if($('item_settings_0').checked){$('item_settings').style.display='';}else{$('item_settings').style.display='none';}</script>
  <p align="center"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></p>
</form>
<%
	Set ItemDic = Nothing
End Sub
%>