<!--#include file="include/inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "leaguefavorite"
		Call LeagueFavorite()
	Case Else
		Call Main()
End Select

'========================================================
'收藏联盟
'========================================================
Sub LeagueFavorite()
	If RQ.UserID = 0 Then
		Call RQ.showTips("登陆后才能收藏联盟。", "", "NOPERM")
	End If

	Dim LeagueID, strLeagueID, strTips

	If Request.Form("leagueid").Count > 0 Then
		For i = 1 To Request.Form("leagueid").Count
			If i > IntCode(RQ.User_Settings(5)) Then
				Exit For
			End If
			LeagueID = IntCode(Request.Form("leagueid")(i))
			strLeagueID = IIF(LeagueID > 0, strLeagueID & LeagueID &",", "")
		Next

		'除去末尾的连接符号
		If Right(strLeagueID, 1) = "," Then
			strLeagueID = Left(strLeagueID, Len(strLeagueID) - 1)
		End If
	End If

	RQ.Execute("DELETE FROM "& TablePre &"leaguefavorites WHERE uid = "& RQ.UserID)

	If Len(strLeagueID) > 0 Then
		RQ.Execute("INSERT INTO "& TablePre &"leaguefavorites SELECT "& RQ.UserID &", leagueid FROM "& TablePre &"leagues WHERE leagueid IN("& strLeagueID &")")
		strTips = "成功收藏了 "& i - 1 &" 个联盟。"
	Else
		strTips = "您已经取消了联盟收藏。"
	End If

	Call closeDatabase()
	Call RQ.showTips(strTips, "?", "")
End Sub

'========================================================
'联盟列表
'========================================================
Sub Main()
	Dim LeagueListArray, NewsListArray, n, j

	j = 0
	LeagueListArray = RQ.Query("SELECT l.leagueid, l.name, ISNULL(lf.leagueid, 0) FROM "& TablePre &"leagues l LEFT JOIN (SELECT leagueid FROM "& TablePre &"leaguefavorites WHERE uid = "& RQ.UserID &") lf ON l.leagueid = lf.leagueid ORDER BY l.leagueid ASC")

	NewsListArray = RQ.Query("SELECT TOP 5 ln.articleid, ln.leagueid, l.name, ln.username, ln.title, ln.message, ln.posttime FROM "& TablePre &"leaguenews ln INNER JOIN "& TablePre &"leagues l ON ln.leagueid = l.leagueid ORDER BY ln.articleid DESC")

	Call closeDataBase()
	RQ.Header()
%>
<% If IsArray(LeagueListArray) Then %>

选取或取消联盟名称前的复选框选择即可进行相应的预定或取消预定的操作<br />
[<a target="_self" href="javascript:history.go(-1)" class="bluelink">返回</a>]
[<a href="leaguecp.asp?action=postnews" class="bluelink">发消息</a> <a href="leaguecp.asp?action=editdesignation" class="bluelink">修改称号</a>]
[<a href="htmls/league.html" target="_blank" class="bluelink">联盟说明</a>]
<p>
<form name="leaguefavorite" method="post" action="?action=leaguefavorite" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table border="0" cellpadding="0" cellspacing="0" width="100%" class="tdpadding4">
    <%
For i = 0 To UBound(LeagueListArray, 2)
	n = n + 1
	n = IIF(n = 4, 1, n)
	Response.Write IIF(n = 1, "<tr>", "") &"<td width=""25%"" nowrap><input type=""checkbox"" name=""leagueid"" value="""& LeagueListArray(0, i) &""""

	If LeagueListArray(0, i) = LeagueListArray(2, i) Then 
		Response.Write " checked"
		j = j + 1
	End If

	Response.Write " /> <a href=""leaguenews.asp?lid="& LeagueListArray(0, i) &""" class=""underline"">"& LeagueListArray(1, i) &"</a></td>"& IIF(n = 3, "</tr>", "")
Next

Erase LeagueListArray

Select Case n
	Case 1
		Response.Write "<td width=""25%"">&nbsp;</td><td width=""25%"">&nbsp;</td></tr>"
	Case 2
		Response.Write "<td width=""25%"">&nbsp;</td></tr>"
End Select
%>
  </table>
  <p>
    <input type="submit" id="btnsubmit" value="确定" class="button" />
    目前已预定联盟<%= j %>个,拖出左边底部的页面点"联盟"可以看到所预定联盟的帖子.</p>
</form>
<% End If %>
<% If IsArray(NewsListArray) Then %>
<p><strong>联盟消息</strong>
<% For i = 0 To UBound(NewsListArray, 2) %>
<%= NewsListArray(6, i) %>&nbsp;<%= NewsListArray(4, i) %> [<%= NewsListArray(3, i) %>] <a href="leaguenews.asp?lid=<%= NewsListArray(1, i) %>" class="bluelink"><strong><%= NewsListArray(2, i) %></strong></a>
<hr color="black" />
<%= NewsListArray(5, i) %>
<p>
<% Next %>
<% Erase NewsListArray %>
<% End If %>
<%
	RQ.Footer()
End Sub
%>
