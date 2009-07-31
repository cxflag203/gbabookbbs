<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

'验证是否有禁止IP的权限
If RQ.AllowBanIP = 0 Then
	Call AdminshowTips("您无权访问该页。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "post"
		Call Post()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'提交IP操作
'========================================================
Sub Post()
	Dim d_BanIP
	Dim IP(4), ExistsNum, CurrentUserIP
	Dim BanListArray, n, strBanIP, sqladdon

	d_BanIP = NumberGroupFilter(Replace(SafeRequest(2, "d_banip", 1, "", 0), " ", ""))
	If Len(d_BanIP) > 0 Then
		sqladdon = IIF(RQ.AdminGroupID <> 1, " AND username = '"& RQ.UserName &"'", "")
		RQ.Execute("DELETE FROM "& TablePre &"banip WHERE id IN("& d_BanIP &")"& sqladdon)
	End If

	For i = 1 To 4
		If Len(Request.Form("ip"& i)) > 0 Then
			If Not IsNumeric(Request.Form("ip"& i)) Then
				IP(i) = -1
			Else
				IP(i) = CLng(Request.Form("ip"& i))
			End If
		End If
	Next

	If Len(IP(1)) > 0 And Len(IP(2)) > 0 And Len(IP(3)) > 0 And Len(IP(4)) > 0 Then
		CurrentUserIP = Split(RQ.UserIP, ".")
		For i = 1 To 4
			If IP(i) < 0 Or IP(i) >= 255 Then
				IP(i) = -1
				ExistsNum = ExistsNum + 1
			ElseIf IP(i) = CLng(CurrentUserIP(i - 1)) Then
				ExistsNum = ExistsNum + 1
			End If
		Next

		If ExistsNum = 4 Then
			Call AdminshowTips("您要禁止的是自己的IP，请重新填写。", "")
		End If
	
		ExistsNum = 0

		BanListArray = RQ.Query("SELECT ip1, ip2, ip3, ip4 FROM "& TablePre &"banip")
		If IsArray(BanListArray) Then
			For i = 0 To UBound(BanListArray, 2)
				For n = 1 To 4
					If BanListArray(n - 1, i) = -1 Then
						ExistsNum = ExistsNum + 1
					ElseIf BanListArray(n - 1, i) = IP(n) Then
						ExistsNum = ExistsNum + 1
					End If
				Next

				If ExistsNum = 4 Then
					Exit For
				Else
					ExistsNum = 0
				End If
			Next
		End If

		If ExistsNum <> 4 Then
			RQ.Execute("INSERT INTO "& TablePre &"banip (ip1, ip2, ip3, ip4, username) VALUES ("& IP(1) &", "& IP(2) &", "& IP(3) &", "& IP(4) &", '"& RQ.UserName &"')")
		End If
	End If

	BanListArray = RQ.Query("SELECT ip1, ip2, ip3, ip4 FROM "& TablePre &"banip")
	If IsArray(BanListArray) Then
		For i = 0 To UBound(BanListArray, 2)
			strBanIP = strBanIP & BanListArray(0, i) &"."& BanListArray(1, i) &"."& BanListArray(2, i) &"."& BanListArray(3, i)
			If i <> UBound(BanListArray, 2) Then strBanIP = strBanIP &"|"
		Next
		strBanIP = Replace(strBanIP, "-1", "(\d+)")
	End If

	RQ.Execute("UPDATE "& TablePre &"settings SET banip = '"& strBanIP &"'")

	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call AdminshowTips("操作成功。", "?")
End Sub

'========================================================
'禁止IP设置列表
'========================================================
Sub Main()
	Dim BanListArray
	BanListArray = RQ.Query("SELECT id, ip1, ip2, ip3, ip4, username, posttime FROM "& TablePre &"banip ORDER BY id ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp?action=right" target="_parent">系统设置</a>&nbsp;&raquo;&nbsp;禁止IP</td>
  </tr>
</table>
<% If RQ.AdminGroupID = 1 Then %>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>您可以填写“*”来禁止某个IP段</td>
  </tr>
</table>
<% End If %>
<br />
<form method="post" name="banuser" action="?action=post" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'd_banip');" />删?</td>
      <td>IP地址</td>
      <td width="20%">操作者</td>
	  <td width="40%">设置时间</td>
    </tr>
	<% If IsArray(BanListArray) Then %>
	<% For i = 0 To UBound(BanListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="d_banip" class="radio" value="<%= BanListArray(0, i) %>"<% If RQ.AdminGroupID <> 1 And BanListArray(5, i) <> RQ.UserName Then Response.Write " disabled" End If %> /></td>
      <td class="altbg2"><%= IIF(BanListArray(1, i) = -1, "*", BanListArray(1, i)) %>.<%= IIF(BanListArray(2, i) = -1, "*", BanListArray(2, i)) %>.<%= IIF(BanListArray(3, i) = -1, "*", BanListArray(3, i)) %>.<%= IIF(BanListArray(4, i) = -1, "*", BanListArray(4, i)) %></td>
      <td class="altbg1"><%= BanListArray(5, i) %></td>
	  <td class="altbg2"><%= BanListArray(6, i) %></td>
    </tr>
	<% Next %>
	<% End If %>
	<tr>
      <td class="altbg1">添加：</td>
      <td class="altbg2"><input type="text" name="ip1" size="5" />.<input type="text" name="ip2" size="5" />.<input type="text" name="ip3" size="5" />.<input type="text" name="ip4" size="5" /></td>
      <td class="altbg1">&nbsp;</td>
	  <td class="altbg2">&nbsp;</td>
    </tr>
  </table>
  <p align="center"><input type="submit" name="submit1" id="btnsubmit" class="button" value="提交设置" />
</form>
<%
End Sub
%>