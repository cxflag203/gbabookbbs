<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/sinc.asp"-->
<!--#include file="wap.fun.asp"-->
<%
WapHeader()

If RQ.CheckTimeSetting(RQ.Time_Settings(3)) And RQ.DisablePeriodCtrl = 0 Then
	Call WapMessage("在以下的时间段里才能进行搜索：<br />"& Replace(RQ.Time_Settings(3), "_", "<br />"), "")
End If

If RQ.AllowSearch = 0 Then
	Call WapMessage("您目前的身份是"& RQ.UserGroupName &"，还不能搜索哟。", "")
End If

Dim Action, SearchID, blnUpdateCache
Action = Request.QueryString("action")
Select Case Action
	Case "search"
		Call Search()
	Case Else
		Call Main()
End Select
WapFooter()

'========================================================
'按照条件进行搜索，并缓存搜索结果
'========================================================
Sub Search()
	Dim Keyword, SearchType, lngSearchType, SqlWhere
	Dim SearchInfo, strUserID
	Dim TopicListArray, TopicID, RecordCount

	Keyword = Replace(Replace(Replace(SafeRequest(3, "keyword", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	Keyword = IIF(Keyword = "输入关键字", "", Keyword)
	SearchType = SafeRequest(3, "searchtype", 1, "", 0)

	If Len(Keyword) = 0 Then
		Call WapMessage("请输入要搜索的内容。", "")
	End If

	Keyword = IIF(Len(Keyword) > 50, Left(Keyword, 50), Keyword)
	lngSearchType = IIF(SearchType = "author", 1, 0)

	SearchInfo = RQ.Query("SELECT searchid, expirytime FROM "& TablePre &"searchindex WHERE keyword = N'"& Keyword &"' AND searchtype = "& lngSearchType)

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

	If lngSearchType = 1 And blnUpdateCache Then
		strUserID = Get_UserID(Keyword)
	End If

	If blnUpdateCache Then
		If SearchType = "author" Then
			SqlWhere = "uid IN("& strUserID &")"
		Else
			SqlWhere = "title LIKE N'%"& Keyword &"%'"
		End If

		TopicListArray = RQ.Query("SELECT TOP "& RQ.Other_Settings(2) &" tid FROM "& TablePre &"topics WHERE "& SqlWhere &" AND displayorder >= 0 ORDER BY lastupdate DESC")

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
			RQ.Execute("UPDATE "& TablePre &"searchindex SET searchcount = searchcount + 1, recordcount = "& RecordCount &", tid = '"& TopicID &"', expirytime = DATEADD(n, 5, GETDATE()) WHERE searchid = "& SearchID)
		Else
			RQ.Execute("INSERT INTO "& TablePre &"searchindex (keyword, searchtype, recordcount, tid, expirytime) VALUES (N'"& Keyword &"', "& lngSearchType &", "& RecordCount &", '"& TopicID &"', DATEADD(n, 5, GETDATE()))")

			SearchID = Conn.Execute("SELECT SCOPE_IDENTITY()")(0)
			dbQueryNum = dbQueryNum + 1
		End If		
	End If

	Call closeDataBase()
	Response.Redirect "search.asp?searchid="& SearchID
End Sub

'========================================================
'根据用户名模糊查询，获取用户编号
'========================================================
Function Get_UserID(Keyword)
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
		RQ.Execute("INSERT INTO "& TablePre &"searchindex (keyword, searchtype, recordcount, tid, expirytime) VALUES (N'"& Keyword &"', 1, 0, '0', DATEADD(n, 5, GETDATE()))")
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
	SearchInfo = RQ.Query("SELECT keyword, searchtype, recordcount, tid FROM "& TablePre &"searchindex WHERE searchid = "& SearchID)
	If Not IsArray(SearchInfo) Then
		Call WapMessage("搜索编号不正确，请返回重新搜索。", "")
	End If


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

	Call closeDataBase()

	If Not IsArray(TopicListArray) Then
		Call WapMessage("没找到符合条件的帖子。", "")
	End If

	Keyword = SearchInfo(0, 0)
	SearchType = SearchInfo(1, 0)

	For i = 0 To UBound(TopicListArray, 2)
		Call Append("<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&amp;tid="& TopicListArray(0, i) &""">"& IIF(Len(TopicListArray(2, i)) > 15, Left(TopicListArray(2, i), 15) &"...", TopicListArray(2, i)) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a><br />")
	Next

	Erase TopicListArray
	
	If PageCount > 1 Then
		Call ShowPageInfo(Page, PageCount, RecordCount, "&amp;searchid="& SearchID)
	End If
End Sub
%>