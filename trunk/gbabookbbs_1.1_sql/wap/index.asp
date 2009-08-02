<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/sinc.asp"-->
<!--#include file="wap.fun.asp"-->
<%
Dim NewPmNum, ForumListArray

If RQ.UserID > 0 Then
	'检查新传呼
	NewPmNum = Conn.Execute("SELECT COUNT(pmid) FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID)(0)
End If

ForumListArray = RQ.Query("SELECT f.fid, f.name, ff.viewperm FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid ORDER BY f.displayorder ASC")
Call closeDatabase()

WapHeader()
Call Append(RQ.Base_Settings(0) &"<br />")

If NewPmNum > 0 Then
	Call Append("<a href=""pm.asp?action=newpmlist"">"& NewPmNum &"条新传呼</a><br />")
End If

Call Append("<br /><a href=""membermisc.asp?action=newtopic"">查看新帖</a><br /><a href=""membermisc.asp?action=elitetopic"">精华贴</a><br />")

If RQ.UserID > 0 Then
	Call Append("<a href=""membermisc.asp"">我的收藏</a><br /><a href=""pm.asp"">传呼</a><br />")
End If

If RQ.AllowSearch = 1 Then
	Call Append("<a href=""search.asp"">论坛搜索</a><br />")
End If

Call Append("<br />论坛版面<br />")

If IsArray(ForumListArray) Then
	For i = 0 To UBound(ForumListArray, 2)
		If Len(ForumListArray(2, i)) = 0 Or InStr(","& ForumListArray(2, i) &",", ","& RQ.UserGroupID &",") > 0 Then
			Call Append("<a href=""forumdisplay.asp?fid="& ForumListArray(0, i) &""">"& ForumListArray(1, i) &"</a><br />")
		End If
	Next
End If

If RQ.AllowSearch Then
	Call Append("<br /><br /><input type=""text"" name=""keyword"" value="""" format=""M*m"" size=""8"" emptyok=""true"" /><anchor title=""submit"">论坛搜索<go method=""get"" href=""search.asp""><postfield name=""keyword"" value=""$(keyword)"" /><postfield name=""action"" value=""search"" /></go></anchor>")
End If

WapFooter()
%>