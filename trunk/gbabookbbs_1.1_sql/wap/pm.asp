<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/sinc.asp"-->
<!--#include file="wap.fun.asp"-->
<%
WapHeader()

If RQ.UserID = 0 Then
	Call WapMessage("登陆后才能使用此功能。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "newpmlist"
		Call NewPmList()
	Case Else
		Call Main()
End Select
WapFooter()

Sub NewPmList()
	Dim PmListArray

	PmListArray = RQ.Query("SELECT pmid, msgfrom, message, remessage, posttime FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID &" ORDER BY posttime DESC")
	Call closeDataBase()

	If Not IsArray(PmListArray) Then
		Call WapMessage("您还没有收到新短信。", "")
	End If

	For i = 0 To UBound(PmListArray, 2)
		Call Append("("& i + 1 &"):"& PmListArray(1, i) &"给您发送的信息 ("& PmListArray(4, i) &")<br />"& IIF(Len(PmListArray(3, i)) > 0, "re:"& PmListArray(3, i) &"<br />", "") & PmListArray(2, i))
		Call Append("<br /><input type=""text"" name=""message"" format=""M*m"" size=""10"" /><anchor title=""回复"">回复<go method=""post"" href=""pm.asp?action=reply&amp;pmid="& PmListArray(0, i) &"""><postfield name=""message"" value=""$(message)"" /></go></anchor><br /><br />")
	Next
End Sub

'========================================================
'传呼菜单列表
'========================================================
Sub Main()
	Dim NewPmNum
	NewPmNum = Conn.Execute("SELECT COUNT(pmid) FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID)(0)
	Call closeDatabase()

	Call Append("<a href=""pm.asp?action=newpmlist"">未读传呼("& NewPmNum &")</a><br /><a href=""pm.asp?action=favorpmlist"">传呼记录</a><br /><a href=""pm.asp?action=send"">发送传呼</a>")
End Sub
%>