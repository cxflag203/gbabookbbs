<!--#include file="include/inc.asp"-->
<%
RQ.Header()
Call Main()
RQ.Footer()

'========================================================
'显示在线人数
'========================================================
Sub Main()
	Dim TotalOnline, GuestOnline

	If Not IsObject(Conn) Then
		Call connectDatabase()
	End If

	'统计总人数
	TotalOnline = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"online")(0)

	'统计游客人数
	GuestOnline = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"online WHERE uid = 0")(0)
	dbQueryNum = dbQueryNum + 2

	Response.Write "<span style=""color: #0080ff;"">目前("& Time() &")有"& TotalOnline &"人在线,其中注册用户"& TotalOnline - GuestOnline &"人,游客"& GuestOnline &"人 [<a href=""?action=showdetail"" style=""color: #0080FF"">列出名单</a>]</span>"

	If Request.QueryString("action") = "showdetail" Then 
		Call showDetail()
	Else
		Call closeDataBase()
	End If
End Sub

'========================================================
'显示详细的在线记录
'========================================================
Sub showDetail()
	Dim OnlineListArray, n

	OnlineListArray = RQ.Query("SELECT uid, username FROM "& TablePre &"online WHERE uid > 0")
	Call closeDataBase()

	If IsArray(OnlineListArray) Then
		Response.Write "<table border=""0"" bgcolor=""#FFFFFF"" width=""100%"" class=""tdpadding4"">"

		For i = 0 To UBound(OnlineListArray, 2)
			n = n + 1
			n = IIF(n = 5, 1, n)

			Response.Write IIF(n = 1, "<tr>", "") &"<td width=""25%"" bgcolor=""#CCFF99""><a href=""profile.asp?u="& Server.URLEncode(OnlineListArray(1, i)) &""" onclick=""return shows3(this.href);""><span style=""font-family:Wingdings; font-size:18px;"">J</span></a> <a href=""pm.asp?action=send&u="& Server.URLEncode(OnlineListArray(1, i)) &""" onclick=""return shows(this.href);"">"& OnlineListArray(1, i) &"</a></td>"& IIF(n = 4, "</tr>", "")
		Next

		Select Case n
			Case 1 : Response.Write "<td width=""25%""></td><td width=""25%""></td><td width=""25%""></td></tr>"
			Case 2 : Response.Write "<td width=""25%""></td><td width=""25%""></td></tr>"
			Case 3 : Response.Write "<td width=""25%""></td></tr>"
		End Select

		Response.Write "</table>"
	End If
End Sub

%>