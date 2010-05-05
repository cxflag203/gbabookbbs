<!--#include file="include/inc.asp"-->
<%
If RQ.ForumID = 0 Then
	Call RQ.showTips("版面不存在或者已经被删除", "", "")
End If

Dim Action, ObjDictionary, typeid, Page

Action = Request.QueryString("action")
typeid = SafeRequest(3, "typeid", 0, 0, 0)
Page = SafeRequest(3, "page", 0, 1, 0)

'链接的默认目标
RQ.PageBaseTarget = CacheName &"right"

Select Case Action
	Case "auditinglist"
		Call AuditingList()
	Case "auditing"
		Call Auditing()
	Case Else
		Call Main()
End Select

'========================================================
'帖子列表
'========================================================
Sub Main()
	RQ.Header()
%>
<body ondblclick="MM_timelinePlay('Timeline1')" class="forumdisplay">
<script type="text/javascript" src="js/tlistevent.js"></script>
<script type="text/javascript" src="js/beckon.js"></script>
<!-- 召唤面板 begin -->
<div id="floater" style="position:absolute; width:350px; height:0px; z-index:1; left:10px; top:405px">
  <div id="Layer1" style="background:#ffc; border:#ffd05c 1px solid; position:absolute; width:350px; height:167px; z-index:2; left:-750px; top:-165px; visibility:visible;" class="curmove">
    <table width="100%" border="0" cellspacing="0" cellpadding="0" align="center" height="100%">
      <tr>
        <td height="18"><table width="100%" border="0" cellspacing="1" cellpadding="0" height="100%">
            <tr>
              <td align="center"><table border="0" cellpadding="0" cellspacing="0">
                  <tr>
                    <td nowrap valign="top"><strong style="color:#f00;"><%= RQ.UserName %>您好!</strong><br />
                      <%= RQ.Other_Settings(0) %>:<%= RQ.UserCredits %>
					  <p>
                      <span style="color:#ff0080;">◆</span> <a href="post.asp?fid=<%= RQ.ForumID %>&typeid=<%= typeid %>" style="color:#0080ff;">发&nbsp; 帖</a><br />
                      <span style="color:#ff8000;">◆</span> <a href="membercp.asp">相关功能</a><br />
                      <% If RQ.Item_Settings(0) = "1" Then %><span style="color:#408080;">◆</span> <a href="item.asp">道具使用</a><br /><% End If %>
                      <% If RQ.Chat_Settings(0) = "1" Then %><span style="color:#ff80ff;">◆</span> <a href="chatroom.asp">留言板</a><% End If %>
                    </td>
                    <td width="10"></td>
                    <td bgcolor="#000000" valign="top" width="1"></td>
                    <td width="10"></td>
                    <td valign="top"><form action="search.asp" method="get" target="<%= CacheName %>search" onsubmit="javascript:parent.<%= CacheName %>leftsearch.rows='*,355';">
                        <input type="hidden" name="action" value="search" />
                        <p><strong>站内搜索</strong>
                        <p>
                          <input name="keyword" size="10" onblur="if(this.value=='')this.value='输入关键字';" onfocus="if(this.value=='输入关键字')this.value='';" value="输入关键字" />
                          <br />
                          <select name="searchtype">
                            <option value="帖子标题">帖子标题</option>
                            <option value="发言人">发言人</option>
                          </select>
                          <input type="submit" value="查找" class="button" />
                          &nbsp;&nbsp;
                        <p><a href="login.asp?action=clearcookies" style="color:#f00;" target="_top">退出本站</a><br />
                      </form></td>
                    <td bgcolor="#000000" valign="top" width="1"></td>
                    <td valign="top"><br />
                      <br />
                      &nbsp; <a href="htmls/calendarCN.htm" target="_blank">日历</a><br />
                      <br />
                      &nbsp;
                      <input type="button" value="召还" onClick="MM_timelinePlay('Timeline1')" class="curback button" />
                    </td>
                  </tr>
                </table></td>
            </tr>
          </table></td>
      </tr>
    </table>
  </div>
</div>
<!-- 召唤面板 end -->
[<a href="?fid=<%= RQ.ForumID %>&typeid=<%= typeid %>" target="_self" style="background: #ff0;" class="underline">刷新</a> <span class="more" onmouseover="this.getElementsByTagName('span')[0].style.display='block';" onmouseout="this.getElementsByTagName('span')[0].style.display='none';">发表<span><a href="post.asp?fid=<%= RQ.ForumID %>&typeid=<%= typeid %>">发表</a><a href="post.asp?fid=<%= RQ.ForumID %>&typeid=<%= typeid %>">新帖</a><% If RQ.F_AllowPollTopic = 1 And RQ.AllowPostPoll = 1 Then %><a href="post.asp?fid=<%= RQ.ForumID %>&typeid=<%= typeid %>&special=1">投票</a><% End If %></span></span>]
<%
Call ShowTopicType()'显示帖子分类
%>
<% If RQ.Base_Settings(3) = "1" Then %><div class="warning"><strong>提示：目前站点处于关闭状态，除了站长，其他用户均无法访问。</strong></div><% End If %>
<p><span style="float:right"><a href="javascript:void(0);" onClick="showsound($('btnmusic'));"><img src="images/common/music.gif" id="btnmusic" alt="打开音乐栏"></a></span></p>
<%
	If Not IsObject(Conn) Then
		Call ConnectDatabase()
	End If

	'显示需要审核的帖子数量
	If RQ.IsModerator And RQ.AllowAuditingTopic = 1 Then
		Call AuditingTopicNum()
	End If

	'第一页则读取置顶贴
	If Page = 1 Then
		Call Show_StickTopics()
	End If

	'读取普通贴
	Call Show_Topics()

	'清除字典对象
	If IsObject(ObjDictionary) Then
		Set ObjDictionary = Nothing
	End If

	RQ.Footer()
End Sub

'========================================================
'读取该版置顶贴
'========================================================
Sub Show_StickTopics()
	Dim sqlwhere, TopicListArray

	If typeid > 0 Then
		sqlwhere = "AND typeid = "& typeid
	End If

	TopicListArray = RQ.Query("SELECT tid, fid, typeid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE tid IN(SELECT tid FROM "& TablePre &"sticktopics WHERE fid = "& RQ.ForumID &") AND displayorder >= 0 "& sqlwhere &" ORDER BY lastupdate DESC")

	If IsArray(TopicListArray) Then

		For i = 0 To UBound(TopicListArray, 2)

			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""">◆</a> "
			Else
				Response.Write "◆ "
			End If

			If IsObject(ObjDictionary) And TopicListArray(2, i) > 0 And TopicListArray(1, i) = RQ.ForumID Then
				Response.Write "【<a href=""?fid="& RQ.ForumID &"&typeid="& TopicListArray(2, i) &""" target=""_self"">"& ObjDictionary.Item(TopicListArray(2, i)) &"</a>】"
			End If

			Response.Write "<a href=""viewtopic.asp?fid="& TopicListArray(1, i) &"&tid="& TopicListArray(0, i) &""" title='【"& TopicListArray(7, i) &" "& TopicListArray(3, i) &"】'>"& TopicListArray(4, i) &" ("& TopicListArray(6, i) &"/"& TopicListArray(5, i) &")</a><br />"
		Next

		Erase TopicListArray

		'清除过期的置顶帖
		Call RQ.ClearStickTopic()

		Response.Write "<p>"
	End If
End Sub

'========================================================
'读取普通帖子列表
'========================================================
Sub Show_Topics()
	Dim RecordCount, PageCount, strSQL, SqlWhere
	Dim TopicListArray, CountArray

	If typeid > 0 Then
		RecordCount = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND typeid = "& typeid &" AND displayorder = 0")(0)
		dbQueryNum = dbQueryNum + 1
		SqlWhere = "AND typeid = "& typeid
	Else
		RecordCount = RQ.Forum_Topics
	End If

	'如果版面设置了只读取n页内的帖子则检查帖子总数量够不够
	If IntCode(RQ.Topic_Settings(3)) > 0 Then
		If RecordCount > IntCode(RQ.Topic_Settings(2)) * IntCode(RQ.Topic_Settings(3)) Then
			RecordCount = IntCode(RQ.Topic_Settings(2)) * IntCode(RQ.Topic_Settings(3))
		End If
	End If

	'如果没有帖子则退出
	If RecordCount = 0 Then
		Exit Sub
	End If

	PageCount = ABS(Int(-(RecordCount / IntCode(RQ.Topic_Settings(2)))))
	Page = IIF(Page > PageCount, PageCount, Page)

	strSQL = "SELECT TOP "& RQ.Topic_Settings(2) &" tid, typeid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = 0 "& SqlWhere
	If Page > 1 Then
		strSQL = strSQL &" AND lastupdate < (SELECT MIN(lastupdate) FROM (SELECT TOP "& IntCode(RQ.Topic_Settings(2)) * (Page - 1) &" lastupdate FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = 0 "& SqlWhere &" ORDER BY lastupdate DESC) AS tblTemp)"
	End If
	strSQL = strSQL &" ORDER BY lastupdate DESC"

	TopicListArray = RQ.Query(strSQL)

	Call closeDataBase()

	If IsArray(TopicListArray) Then
		'计算数组下标
		CountArray = UBound(TopicListArray, 2)

		For i = 0 To CountArray
			If RQ.IsModerator And RQ.AllowManageTopic = 1 Then
				Response.Write "<a href=""managetopic.asp?fid="& RQ.ForumID &"&tid="& TopicListArray(0, i) &""">◆</a> "
			Else
				Response.Write "◆ "
			End If

			'如果版面有帖子分类则显示
			If IsObject(ObjDictionary) And TopicListArray(1, i) > 0 Then
				Response.Write "【<a href=""?fid="& RQ.ForumID &"&typeid="& TopicListArray(1, i) &""" target=""_self"">"& ObjDictionary.Item(TopicListArray(1, i)) &"</a>】"
			End If

			Response.Write "<a href=""viewtopic.asp?fid="& RQ.ForumID &"&tid="& TopicListArray(0, i) &""" title='【"& TopicListArray(6, i) &" "& TopicListArray(2, i) &"】'>"& TopicListArray(3, i) &" ("& TopicListArray(5, i) &"/"& TopicListArray(4, i) &")</a><br />"
		Next

		Erase TopicListArray

		'如果总页数超过一页则显示分页列表
		If PageCount > 1 Then
			Call ShowPageInfo(Page, PageCount, RecordCount, "&fid="& RQ.ForumID &"&typeid="& typeid)
		End If
	End If
End Sub

'========================================================
'列出帖子分类并放入字典对象
'========================================================
Sub ShowTopicType()
	If Len(RQ.Forum_TopicType) = 0 Then
		typeid = 0
		Exit Sub
	End If

	Dim TypeListArray, Checktype

	TypeListArray = eval(RQ.Forum_TopicType)
	Checktype = False

	'如果本版显示帖子分类则建立字典对象
	If RQ.F_ShowTopicType = 1 Then
		Set ObjDictionary = Server.CreateObject("Scripting.Dictionary")
	End If

	Response.Write "[<a href=""?fid="& RQ.ForumID &""" class=""bluelink"" target=""_self"">"& IIF(typeid = 0, "<strong>全部</strong>", "全部") &"</a>]["

	For i = 0 To UBound(TypeListArray)
		Response.Write "<a href=""?fid="& RQ.ForumID &"&typeid="& TypeListArray(i)(1) &""" target=""_self"" class=""bluelink"">"

		If typeid = TypeListArray(i)(1) Then 
			Response.Write "<strong>"& TypeListArray(i)(0) &"</strong>"
			Checktype = True
		Else
			Response.Write TypeListArray(i)(0)
		End If

		Response.Write "</a>"

		If i <> UBound(TypeListArray) Then
			Response.Write " "
		End If

		'把帖子分类编号和名称加入字典对象
		If RQ.F_ShowTopicType = 1 Then
			Call ObjDictionary.Add(TypeListArray(i)(1), TypeListArray(i)(0))
		End If
	Next

	'验证typeid是否正确
	If Not Checktype Then
		typeid = 0
	End If

	Response.Write "]"
End Sub

'========================================================
'读取未通过审核的帖子
'========================================================
Sub AuditingTopicNum()
	Dim n

	n = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = -1")(0)
	dbQueryNum = dbQueryNum + 1

	If n > 0 Then 
		Response.Write "<a href=""?fid="& RQ.ForumID &"&action=auditinglist"" style=""color:#f00;"" class=""underline"" target=""_self"">该版有"& n &"个新帖子待审核</a><p>"
	End If
End Sub

'========================================================
'显示未通过审核的帖子列表
'========================================================
Sub AuditingList()
	If Not RQ.IsModerator Or RQ.AllowAuditingTopic = 0 Then
		Call RQ.showTips("只有管理员才能审核帖子。", "", "NOPERM")
	End If

	Dim TopicListArray
	TopicListArray = RQ.Query("SELECT tid, usershow, title, clicks, posts, lastupdate FROM "& TablePre &"topics WHERE fid = "& RQ.ForumID &" AND displayorder = -1 ORDER BY lastupdate DESC")

	Call closeDatabase()
	RQ.Header()
%>
<body onclick="document_onclick();" class="forumdisplay">
<script type="text/javascript" src="js/tlistevent.js"></script>
[<a href="?fid=<%= RQ.ForumID %>&action=auditinglist" target="_self" style="background-color: #ff0;" class="underline">刷新</a>][<a href="?fid=<%= RQ.ForumID %>" class="bluelink" target="_self">返回列表</a>]
<p>
  <%
	If IsArray(TopicListArray) Then
		Response.Write "<form action=""?action=auditing"" method=""post"" target=""_self""><input type=""hidden"" name=""fid"" value="""& RQ.ForumID &""" />"

		For i = 0 To UBound(TopicListArray, 2)
			Response.Write "<input type=""checkbox"" name=""a_tid"" value="""& TopicListArray(0, i) &"""> <a href=""viewtopic.asp?fid="& RQ.ForumID &"&tid="& TopicListArray(0, i) &""" title='【"& TopicListArray(5, i) &" "& TopicListArray(1, i) &"】'>"& TopicListArray(2, i) &" ("& TopicListArray(4, i) &"/"& TopicListArray(3, i) &")</a><br />"
		Next

		Erase TopicListArray

		Response.Write "<br /><input type=""submit"" name=""pass"" value=""审核通过(先选中)"" class=""button"" /> <input type=""submit"" name=""delete"" value=""删除"" class=""button"" /></form>"
	End If

	RQ.Footer()
End Sub

'========================================================
'帖子审核
'========================================================
Sub Auditing()
	If Not RQ.IsModerator Or RQ.AllowAuditingTopic = 0 Then
		Call RQ.showTips("只有管理员才能审核帖子。", "", "")
	End If

	Dim AuditingTopicID, n, strTips
	AuditingTopicID = NumberGroupFilter(Replace(SafeRequest(2, "a_tid", 1, "", 0), " ", ""))

	If Len(AuditingTopicID) = 0 Then
		Call RQ.showTips("请先选中要审核的帖子。", "", "")
	End If

	'审核通过
	If Len(Request.Form("pass")) > 0 Then
		n = RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 0 WHERE tid IN("& AuditingTopicID &") AND fid = "& RQ.ForumID)

		If n > 0 Then
			RQ.Execute("UPDATE "& TablePre &"forums SET topics = topics + "& n &" WHERE fid = "& RQ.ForumID)
			Call RQ.Update_TopicNum(RQ.ForumID, RQ.Forum_Topics + n)
		End If
		strTips = n &"条帖子被审核通过。"
	'审核未通过
	ElseIf Len(Request.Form("delete")) > 0 Then
		n = RQ.Execute("DELETE FROM "& TablePre &"topics WHERE tid IN("& AuditingTopicID &") AND fid = "& RQ.ForumID)
		strTips = n &"条帖子被删除（审核未通过）。"
	End If

	Call closeDataBase()
	Call RQ.showTips(strTips, "?fid="& RQ.ForumID, "")
End Sub
%>
