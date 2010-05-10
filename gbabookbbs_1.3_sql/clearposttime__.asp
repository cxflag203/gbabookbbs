<!--#include file="include/inc.asp"-->
<%
Dim RecordCount, PageCount, Page, strSQL
Dim PostListArray, Message

If Not IsObject(Conn) Then
	Call connectDatabase()
End If

RecordCount = Conn.Execute("SELECT COUNT(*) FROM "& TablePre &"posts WHERE iffirst = 1")(0)
If RecordCount > 0 Then
	PageCount = ABS(Int(-(RecordCount / 200)))
	Page = SafeRequest(3, "page", 0, 1, 0)
	If Page > PageCount Then
		Call RQ.showTips("全部操作已完成。", "", "")
	End If

	strSQL = "SELECT TOP 200 pid, message FROM "& TablePre &"posts WHERE iffirst = 1"
	If Page > 1 Then
		strSQL = strSQL &" AND pid > (SELECT MAX(pid) FROM (SELECT TOP "& 200 * (Page - 1) &" pid FROM "& TablePre &"posts WHERE iffirst = 1 ORDER BY pid ASC) AS tblTemp)"
	End If
	strSQL = strSQL &" ORDER BY pid ASC"

	PostListArray = RQ.Query(strSQL)
	If IsArray(PostListArray) Then
		For i = 0 To UBound(PostListArray, 2)
			Message = Preg_Replace(PostListArray(1, i), "<br(.*?)><em>\(发帖时间:(.*?)\)<\/em>(|\s)<br(.*?)>", "")
			RQ.Execute("UPDATE "& TablePre &"posts SET message = '"& Message &"' WHERE pid = "& PostListArray(0, i))
		Next
	End If
End If

Call closeDatabase()
Call showMessage("进行下一页操作("& Page &"/"& PageCount &")", "?page="& Page + 1, "")

Public Sub showMessage(Message, URL)
	RQ.Header()
	Response.Write "<body><table class=""tipsborder"" cellSpacing=""0"" cellPadding=""0"" align=""center""><tr><td class=""transborder"" width=""8"">&nbsp;</td><td class=""transborder"">&nbsp;</td><td class=""transborder"" width=""8"">&nbsp;</td></tr><tr><td class=""transborder"" width=""8"">&nbsp;</td><td class=""tipstd""><div class=""mainarea""><div class=""tipstd_bottom""></div><div class=""tips_header""><h1>提示信息</h1></div><div class=""tips_content"">"& IIF(Len(URL) > 0, Message, "<span class=""pink"">"& Message &"</span>") &"<p>"

	If Len(URL) > 0 Then
		Response.Write "<a href="""& URL &""" target=""_self"">如果您的浏览器没有跳转，请点击这里。</a><script type=""text/javascript"">setTimeout(""self.location.replace('"& URL &"');"", 1000);</script>"
	Else
		Call closeDatabase()
		Response.Write "<a href=""javascript:history.go(-1);"" target=""_self"">点击这里返回上一页</a>"
	End If

	Response.Write "</p></div></div></td><td class=""transborder"" width=""8"">&nbsp;</td></tr><tr><td class=""transborder"" width=""8"">&nbsp;</td><td class=""transborder"">&nbsp;</td><td class=""transborder"" width=""8"">&nbsp;</td></tr></table>"
	RQ.Footer()
	Response.End()
End Sub
%>