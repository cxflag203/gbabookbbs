<!--#include file="include/inc.asp"-->
<%
If RQ.CheckTimeSetting(RQ.Time_Settings(3)) And RQ.DisablePeriodCtrl = 0 Then
	Call RQ.showTips("在以下的时间段里才能进行搜索：<br />"& Replace(RQ.Time_Settings(3), "_", "<br />"), "", "NOPERM")
End If

If RQ.AllowSearch = 0 Then
	Call RQ.showTips("您目前的身份是"& RQ.UserGroupName &"，还不能搜索哟。", "", "NOPERM")
End If

Dim Action, SearchID, blnUpdateCache
Action = Request.QueryString("action")
Select Case Action
	Case "search"
		Call Search()
	Case Else
		Call Main()
End Select
RQ.Footer()

'========================================================
'按照条件进行搜索，并缓存搜索结果
'========================================================
Sub Search()
	Dim Keyword, SearchType, SearchString, SqlWhere
	Dim TopicID, RecordCount, strUserID, AccessableForumID
	Dim SearchInfo, TopicListArray

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Keyword = IIF(Keyword = "输入关键字", "", Keyword)

	If Len(Keyword) = 0 Then
		Call RQ.showTips("请输入要搜索的内容。", "", "")
	End If

	Keyword = IIF(Len(Keyword) > 50, Left(Keyword, 50), Keyword)
	SearchType = SafeRequest(3, "searchtype", 1, "", 0)

	'读取有访问权限的版面编号
	AccessableForumID = RQ.Get_Accessable_ForumID()

	SearchString = SearchType &"|"& Keyword &"|"& AccessableForumID &"|"

	SearchInfo = RQ.Query("SELECT searchid, expirytime FROM "& TablePre &"searchindex WHERE searchstring = N'"& SearchString &"'")

	If IsArray(SearchInfo) Then
		SearchID = SearchInfo(0, 0)
		If DateDiff("n", Now(), SearchInfo(1, 0)) < 0 Then
			blnUpdateCache = True
		Else
			blnUpdateCache = False
			RQ.Execute("UPDATE "& TablePre &"searchindex SET searchcount = searchcount + 1 WHERE searchid = "& SearchID)
		End If
	Else
		blnUpdateCache = True
		SearchID = 0
	End If

	If SearchType = "author" And blnUpdateCache Then
		strUserID = Get_UserID(Keyword, SearchString)
	End If

	If blnUpdateCache Then
		If SearchType = "author" Then
			SqlWhere = "uid IN("& strUserID &")"
		Else
			SqlWhere = "title LIKE N'%"& Keyword &"%'"
		End If

		TopicListArray = RQ.Query("SELECT TOP "& RQ.Other_Settings(2) &" tid FROM "& TablePre &"topics WHERE fid IN("& AccessableForumID &") AND "& SqlWhere &" AND displayorder >= 0 ORDER BY tid DESC")

		If IsArray(TopicListArray) Then
			For i = 0 To UBound(TopicListArray, 2)
				TopicID = TopicID & TopicListArray(0, i)
				If i <> UBound(TopicListArray, 2) Then
					TopicID = TopicID &","
				End If
			Next

			RecordCount = UBound(TopicListArray, 2) + 1
		Else
			RecordCount = 0
			TopicID = "0"
		End If

		If SearchID > 0 Then
			RQ.Execute("UPDATE "& TablePre &"searchindex SET searchcount = searchcount + 1, recordcount = "& RecordCount &", tid = '"& TopicID &"', expirytime = DATEADD(s, 3600, GETDATE()) WHERE searchid = "& SearchID)
		Else
			RQ.Execute("INSERT INTO "& TablePre &"searchindex (keyword, searchstring, recordcount, tid, expirytime) VALUES (N'"& Keyword &"', N'"& SearchString &"', "& RecordCount &", '"& TopicID &"', DATEADD(s, 3600, GETDATE()))")

			SearchID = Conn.Execute("SELECT SCOPE_IDENTITY()")(0)
			dbQueryNum = dbQueryNum + 1
		End If
	End If

	Call closeDataBase()
	Call RQ.showTips("搜索完成，请点击这里查看搜索结果。", "?searchid="& SearchID, "")
End Sub

'========================================================
'根据用户名模糊查询，获取用户编号
'========================================================
Function Get_UserID(Keyword, SearchString)
	Dim MemberListArray, str

	MemberListArray = RQ.Query("SELECT uid FROM "& TablePre &"members WHERE username = N'"& Keyword &"'")

	If IsArray(MemberListArray) Then
		For i = 0 To UBound(MemberListArray, 2)
			str = str & MemberListArray(0, i)
			If i <> UBound(MemberListArray, 2) Then
				str = str &","
			End If
		Next
		Erase MemberListArray
	Else
		RQ.Execute("INSERT INTO "& TablePre &"searchindex (keyword, searchstring, recordcount, tid, expirytime) VALUES (N'"& Keyword &"', N'"& SearchString &"', 0, '0', DATEADD(s, 3600, GETDATE()))")
		str = "0"

		SearchID = Conn.Execute("SELECT SCOPE_IDENTITY()")(0)
		dbQueryNum = dbQueryNum + 1

		blnUpdateCache = False
	End If

	Get_UserID = str
	str = Empty
End Function

'========================================================
'在分隔符组合而成的帖子id中取出当前页的帖子id
'========================================================
Function Get_TopicIDPosition(strArray, RecordCount, Page, PageSize)
	Dim str

	strArray = Split(strArray, ",")

	If Page = 1 Then
		For i = 0 To (PageSize - 1)
			If i > RecordCount - 1 Then
				Exit For
			End If
			str = str & strArray(i) &","
		Next
	Else
		For i = ((Page - 1) * PageSize) To ((Page - 1) * PageSize) - 1 + PageSize
			If i > RecordCount - 1 Then
				Exit For
			End If
			str = str & strArray(i) &","
		Next
	End If

	If Right(str, 1) = "," Then
		str = Left(str, Len(str) - 1)
	End If

	Get_TopicIDPosition = str
	str = Empty
End Function

'========================================================
'显示搜索结果
'========================================================
Sub Main()
	Dim SearchInfo, RecordCount, PageCount, Page
	Dim Keyword, SearchType, TopicPosition
	Dim TopicListArray

	SearchID = SafeRequest(3, "searchid", 0, 0, 0)
	SearchInfo = RQ.Query("SELECT keyword, searchstring, recordcount, tid FROM "& TablePre &"searchindex WHERE searchid = "& SearchID)

	If IsArray(SearchInfo) Then
		RecordCount = SearchInfo(2, 0)
		If RecordCount > 0 Then
			Page = SafeRequest(3, "page", 0, 1, 0)
			PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(2)))))
			Page = IIF(Page > PageCount, PageCount, Page)

			If RecordCount = 1 Then
				TopicPosition = SearchInfo(3, 0)
			Else
				TopicPosition = Get_TopicIDPosition(SearchInfo(3, 0), RecordCount, Page, IntCode(RQ.Topic_Settings(2)))
			End If

			TopicListArray = RQ.Query("SELECT tid, fid, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE tid IN("& TopicPosition &") ORDER BY lastupdate DESC")
		End If

		Keyword = SearchInfo(0, 0)
		SearchType = Split(SearchInfo(1, 0), "|")(0)
	End If

	Call closeDataBase()

	RQ.PageBaseTarget = CacheName &"right"
	RQ.Header()
%>
<body>
<form action="?" method="get" target="_self">
  <input type="hidden" name="action" value="search" />
  <strong>站内搜索:</strong>
  <input name="keyword" size="10" value="<%= Keyword %>" />
  <select name="searchtype">
    <option value="title">帖子标题</option>
    <option value="author"<%= IIF(SearchType = "author", " selected", "") %>>发帖人</option>
  </select>
  <input type="submit" value="查找" class="button" />
  [<a href="membermisc.asp" target="_self">返回</a>]
</form>
<p><strong>查找内容:</strong><%= Keyword %>&nbsp;&nbsp;&nbsp;<strong>查找范围:</strong><%= IIF(SearchType = "title", "帖子标题", "发帖人") %>
<hr color="black" />
<p>
  <%
	If IsArray(TopicListArray) Then
		For i = 0 To UBound(TopicListArray, 2)
			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""">◆</a>"
			Else
				Response.Write "◆"
			End If

			Response.Write " <a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""" title="""& TopicListArray(5, i) &""">"& TopicListArray(2, i) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a><br />"
		Next

		Erase TopicListArray
		
		If PageCount > 1 Then
			Call ShowPageInfo(Page, PageCount, RecordCount, "&searchid="& SearchID)
		End If
	End If
End Sub
%>
