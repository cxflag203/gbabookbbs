<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/sinc.asp"-->
<!--#include file="wap.fun.asp"-->
<%
WapHeader()

If RQ.ForumID = 0 Then
	Call WapMessage("错误的版面，请返回。", "")
End If

Dim RecordCount, PageCount, Page, strNewTopic
Dim strSQL, StickListArray, TopicListArray

Page = SafeRequest(3, "page", 0, 1, 0)

'第一页读取置顶帖
If Page = 1 Then
	StickListArray = RQ.Query("SELECT tid, fid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"sticktopics WHERE fid = "& RQ.ForumID &") AND fid = "& RQ.ForumID &" ORDER BY lastupdate DESC")
End If

If Not IsObject(Conn) Then
	Call connectDatabase()
End If

'读取普通帖子数量
RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = 0")(0)
If RecordCount > 0 Then
	PageCount = ABS(Int(-(RecordCount / 10)))
	
	Page = IIF(Page > PageCount, PageCount, Page)
	strSQL = "SELECT TOP 10 tid, title, clicks, posts, ifelite FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = 0"
	If Page > 1 Then
		strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& 10 * (Page - 1) &" lastupdate FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = 0 ORDER BY lastupdate DESC) AS tblTemp)"
	End If
	strSQL = strSQL &" ORDER BY lastupdate DESC"

	TopicListArray = RQ.Query(strSQL)
End If

'是否允许发帖
If RQ.AllowPost = 1 Then
	If (Len(RQ.Forum_PostTopicPerm) = 0 And RQ.UserID > 0) Or (Len(RQ.Forum_PostTopicPerm) > 0 And InStr(","& RQ.Forum_PostTopicPerm &",", ","& RQ.UserGroupID &",") > 0) Then
		strNewTopic = "<a href=""post.asp?fid="& RQ.ForumID &""">发帖</a><br />"
	End If
End If

Call Append(RQ.Forum_Name &"<br />"& strNewTopic &"<br />帖子列表 <a href=""forumdisplay.asp?fid="& RQ.ForumID &""">刷新</a><br />")

'列出置顶帖
If IsArray(StickListArray) Then
	For i = 0 To UBound(StickListArray, 2)
		StickListArray(2, i) = WapCode(StickListArray(2, i))
		Call Append("<a href=""viewtopic.asp?fid="& StickListArray(1, i) &"&amp;tid="& StickListArray(0, i) &""">"& IIF(Len(StickListArray(2, i)) > 15, Left(StickListArray(2, i), 15) &"...", StickListArray(2, i)) &" ("& StickListArray(4, i) &"/"& StickListArray(3, i) &")</a>[顶]"& IIF(StickListArray(5, i) = 1, "[精]", "") &"<br />")
	Next
	Call RQ.ClearStickTopic()
End If

Call closeDatabase()

'列出普通帖子
If IsArray(TopicListArray) Then
	For i = 0 To UBound(TopicListArray, 2)
		TopicListArray(1, i) = WapCode(TopicListArray(1, i))
		Call Append("<a href=""viewtopic.asp?fid="& RQ.ForumID &"&amp;tid="& TopicListArray(0, i) &""">"& IIF(Len(TopicListArray(1, i)) > 15, Left(TopicListArray(1, i), 15) &"...", TopicListArray(1, i)) &" ("& TopicListArray(3, i) &"/"& TopicListArray(2, i) &")</a>"& IIF(TopicListArray(4, i) = 1, "[精]", "") &"<br />")
	Next
End If

'显示分页
If PageCount > 1 Then
	Call ShowWapPage(Page, PageCount, RecordCount, "&amp;fid="& RQ.ForumID)
End If

Call Append("<br /><br />"& strNewTopic)

If RQ.AllowSearch Then
	Call Append("<input type=""text"" name=""keyword"" value="""" format=""M*m"" size=""8"" emptyok=""true"" /><anchor title=""submit"">论坛搜索<go method=""get"" href=""search.asp""><postfield name=""keyword"" value=""$(keyword)"" /><postfield name=""action"" value=""search"" /></go></anchor>")
End If

WapFooter()
%>