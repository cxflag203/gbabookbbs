<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

'站长和高级管理员才能访问
If RQ.AdminGroupID <> 1 And RQ.AdminGroupID <> 2 Then
	Call AdminshowTips("您无权进行访问。", "")
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
'提交操作
'========================================================
Sub Post()
	Dim OperationTopicID, Operation
	Dim NumListArray, AttachListArray, Topics, strSQL

	OperationTopicID = NumberGroupFilter(Replace(SafeRequest(2, "optid", 1, "", 0), " ", ""))
	Operation = SafeRequest(2, "operation", 1, "", 0)

	If Len(OperationTopicID) = 0 Then
		Call AdminshowTips("请选中要操作的帖子。", "")
	End If

	If Not InArray(Array("restore", "delete"), Operation) Then
		Call AdminshowTips("请选择对帖子的操作方式。", "")
	End If

	NumListArray = RQ.Query("SELECT fid, COUNT(tid) FROM "& TablePre &"topics WHERE tid IN("& OperationTopicID &") AND displayorder = -2 GROUP BY fid")
	If IsArray(NumListArray) Then
		If Operation = "delete" Then
			RQ.Execute("DELETE FROM "& TablePre &"topics WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"posts WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"sticktopics WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"polls WHERE tid IN("& OperationTopicID &")")
			RQ.Execute("DELETE FROM "& TablePre &"polloptions WHERE tid IN("& OperationTopicID &")")
		Else
			RQ.Execute("UPDATE "& TablePre &"topics SET displayorder = 0 WHERE tid IN("& OperationTopicID &")")
		End If

		'删除附件
		AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE tid IN("& OperationTopicID &")")
		If IsArray(AttachListArray) Then
			For i = 0 To UBound(AttachListArray, 2)
				Call DeleteFile("../attachments/"& AttachListArray(0, i))
			Next
			RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE tid IN("& OperationTopicID &")")
		End If

		'更新版面帖子数量统计
		For i = 0 To UBound(NumListArray, 2)
			Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& NumListArray(0, i) &" AND displayorder >= 0")(0)
			RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &" WHERE fid = "& NumListArray(0, i))

			Call RQ.Update_TopicNum(NumListArray(0, i), Topics)
		Next
	End If
	Call closeDatabase()
	Call AdminshowTips("操作完毕。", "?")
End Sub

'========================================================
'回收站帖子列表
'========================================================
Sub Main()
	Dim TopicListArray
	TopicListArray = RQ.Query("SELECT tid, fid, username, title, clicks, posts FROM "& TablePre &"topics WHERE displayorder = -2")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp?action=right" target="_parent">系统设置</a>&nbsp;&raquo;&nbsp;帖子回收站</td>
  </tr>
</table>
<br />
<form name="topicop" method="post" action="?action=post" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <input type="hidden" name="uid" value="1" />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td colspan="9">帖子回收站</td>
    </tr>
    <tr class="category">
      <td width="8%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'optid');" />选</td>
      <td>标题</td>
      <td width="15%">作者</td>
      <td width="14%">回复</td>
      <td width="15%">浏览</td>
    </tr>
	<% If IsArray(TopicListArray) Then %>
	<% For i = 0 To UBound(TopicListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="optid" value="<%= TopicListArray(0, i) %>" class="radio" /></td>
      <td class="altbg2"><a href="../viewtopic.asp?fid=<%= TopicListArray(1, i) %>&tid=<%= TopicListArray(0, i) %>" target="_blank"><%= TopicListArray(3, i) %></a></td>
	  <td class="altbg1"><%= TopicListArray(2, i) %></td>
      <td class="altbg2"><%= TopicListArray(5, i) %></td>
      <td class="altbg1"><%= TopicListArray(4, i) %></td>
    </tr>
    <% Next %>
	<% Else %>
	<tr>
      <td colspan="5"><em>暂无帖子</em></td>
	</tr>
	<% End If %>
  </table>
  <% If IsArray(TopicListArray) Then %>
  <br />
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td>操作</td>
    </tr>
    <tr class="altbg2">
      <td><select name="operation">
	    <option value="">--</option>
	    <option value="restore">恢复选中的帖子</option>
        <option value="delete">删除选中的帖子</option>
      </select>
      <input type="submit" id="btnsubmit" value="提交操作" class="s_button" /></td>
    </tr>
  </table>
  <% End If %>
</form>
<%
End Sub
%>