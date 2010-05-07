<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

'验证是否有编辑用户的权限
If RQ.AllowPunishUser = 0 Or Not InArray(Array(1, 2), RQ.AdminGroupID) Then
	Call AdminshowTips("您无权访问该页。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "banuser"
		Call BanUser()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'提交操作
'========================================================
Sub BanUser()
	Dim UserName, BanType, ExpiryTime, DeleteTopic, DeletePost, DeletePM, Reason
	Dim UserInfo, GroupInfo, ForumListArray, AttachListArray, Topics

	UserName = SafeRequest(2, "username", 1, "", 0)
	BanType = SafeRequest(2, "bantype", 1, "", 0)
	ExpiryTime = SafeRequest(2, "expirytime", 0, 0, 0)
	DeleteTopic = SafeRequest(2, "deletetopic", 0, 0, 0)
	DeletePost = SafeRequest(2, "deletepost", 0, 0, 0)
	DeletePM = SafeRequest(2, "deletepm", 0, 0, 0)
	Reason = SafeRequest(2, "reason", 1, "", 0)

	If Len(UserName) = 0 Then
		Call AdminshowTips("请填写好用户名。", "")
	End If

	'读取用户当前信息
	UserInfo = RQ.Query("SELECT m.uid, m.admingroupid, m.username, g.name, g.types FROM "& TablePre &"members m INNER JOIN "& TablePre &"usergroups g ON m.usergroupid = g.gid WHERE m.username = N'"& UserName &"'")

	If Not IsArray(UserInfo) Then
		Call AdminshowTips("“"& UserName &"”不存在，请返回重新填写。", "")
	End If

	'管理组的用户不能直接进行处罚
	If UserInfo(1, 0) > 0 Then
		Call AdminshowTips("该用户属于管理组，不允许在该处直接处罚。", "")
	End If

	'格式化有效期
	If ExpiryTime > 0 Then
		ExpiryTime = IIF(ExpiryTime > 180, 180, ExpiryTime)
		ExpiryTime = DatetoNum(DateAdd("d", ExpiryTime, Now()))
	End If

	Select Case BanType
		'禁止发言
		Case "post"
			RQ.Execute("UPDATE "& TablePre &"members SET admingroupid = 0, usergroupid = 10, groupexpiry = "& ExpiryTime &" WHERE uid = "& UserInfo(0, 0))

			If ExpiryTime > 0 Then
				RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserInfo(0, 0))
				RQ.Execute("INSERT INTO "& TablePre &"groupexpiry (uid, usergroupid, admingroupid) VALUES ("& UserInfo(0, 0) &", 4, 0)")
			End If

			'写入异动报告
			If Len(Reason) > 0 Then
				GroupInfo = RQ.Query("SELECT name FROM "& TablePre &"usergroups WHERE gid = 10")
				Call RQ.SetLog(UserInfo(0, 0), UserName, "<span style=""color: #FF0080;"">列入"& GroupInfo(0, 0) &"</span>", Reason)
			End If

		'禁止访问
		Case "visit"
			RQ.Execute("UPDATE "& TablePre &"members SET admingroupid = 0, usergroupid = 11, groupexpiry = "& ExpiryTime &" WHERE uid = "& UserInfo(0, 0))

			If ExpiryTime > 0 Then
				RQ.Execute("DELETE FROM "& TablePre &"groupexpiry WHERE uid = "& UserInfo(0, 0))
				RQ.Execute("INSERT INTO "& TablePre &"groupexpiry (uid, usergroupid, admingroupid) VALUES ("& UserInfo(0, 0) &", 4, 0)")
			End If

			'写入异动报告
			If Len(Reason) > 0 Then
				GroupInfo = RQ.Query("SELECT name FROM "& TablePre &"usergroups WHERE gid = 11")
				Call RQ.SetLog(UserInfo(0, 0), UserName, "<span style=""color: #FF0080;"">列入"& GroupInfo(0, 0) &"。</span>", Reason)
			End If

		'恢复正常
		Case Else
			RQ.Execute("UPDATE "& TablePre &"members SET admingroupid = 0, usergroupid = 4, groupexpiry = 0 WHERE uid = "& UserInfo(0, 0))

			If Len(Reason) > 0 And UserInfo(4, 0) = "restricted" Then
				Call RQ.SetLog(UserInfo(0, 0), UserName, "<span style=""color: #FF0080;"">解除"& UserInfo(3, 0) &"。</span>", Reason)
			End If
	End Select

	'删除帖子
	If DeleteTopic = 1 Then
		ForumListArray = RQ.Query("SELECT fid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &" GROUP BY fid")

		If IsArray(ForumListArray) Then
			'删除帖子关联的回复
			RQ.Execute("DELETE FROM "& TablePre &"posts WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &")")

			'删除该用户的收藏
			RQ.Execute("DELETE FROM "& TablePre &"favorites WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &")")

			'删除联盟帖子
			RQ.Execute("DELETE FROM "& TablePre &"leaguetopics WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &")")

			'删除定时置顶帖的记录
			RQ.Execute("DELETE FROM "& TablePre &"topictask WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &")")

			'删除帖子
			RQ.Execute("DELETE FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0))

			'更新版面帖子数量
			For i = 0 To UBound(ForumListArray, 2)
				Topics = Conn.Execute("SELECT COUNT(tid) FROM "& TablePre &"topics WHERE fid = "& ForumListArray(0, i))(0)
				RQ.Execute("UPDATE "& TablePre &"forums SET topics = "& Topics &" WHERE fid = "& ForumListArray(0, i))

				Call RQ.Update_TopicNum(ForumListArray(0, i), Topics)
			Next

			'删除附件
			AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &")")
			If IsArray(AttachListArray) Then
				For i = 0 To UBound(AttachListArray, 2)
					Call DeleteFile("../attachments/"& AttachListArray(0, i))
				Next
				RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE tid IN(SELECT tid FROM "& TablePre &"topics WHERE uid = "& UserInfo(0, 0) &")")
			End If
		End If
	End If

	'删除回复
	If DeletePost = 1 Then
		'更新帖子的回复数量
		RQ.Execute("UPDATE t SET posts = posts - p.num FROM "& TablePre &"topics AS t INNER JOIN (SELECT tid, COUNT(1) AS num FROM "& TablePre &"posts WHERE uid = "& UserInfo(0, 0) &" AND iffirst = 0 GROUP BY tid) AS p ON t.tid = p.tid")

		'删除回复
		RQ.Execute("DELETE FROM "& TablePre &"posts WHERE uid = "& UserInfo(0, 0) &" AND iffirst = 0")

		'删除附件
		AttachListArray = RQ.Query("SELECT savepath FROM "& TablePre &"attachments WHERE pid IN(SELECT pid FROM "& TablePre &"posts WHERE uid = "& UserInfo(0, 0) &" AND iffirst = 0)")
		If IsArray(AttachListArray) Then
			For i = 0 To UBound(AttachListArray, 2)
				Call DeleteFile("../attachments/"& AttachListArray(0, i))
			Next
			RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE pid IN(SELECT pid FROM "& TablePre &"posts WHERE uid = "& UserInfo(0, 0) &" AND iffirst = 0)")
		End If
	End If

	'删除传呼
	If DeletePM = 1 Then
		RQ.Execute("DELETE FROM "& TablePre &"pm WHERE msgfromid = "& UserInfo(0, 0))
		RQ.Execute("DELETE FROM "& TablePre &"pms WHERE uid = "& UserInfo(0, 0))
	End If

	Call closeDatabase()
	Call AdminshowTips("用户设置已经更新", "?")
End Sub

'========================================================
'禁止用户操作界面
'========================================================
Sub Main()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp?action=right" target="_parent">系统设置</a>&nbsp;&raquo;&nbsp;禁止用户</td>
  </tr>
</table>
<br />
<form method="post" name="banuser" action="?action=banuser" onsubmit="$('submit1').value='正在提交,请稍后...';$('submit1').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>禁止用户</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>用户名:</strong></td>
      <td width="70%"><input type="text" name="username" size="25" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>禁止类型:</strong></td>
      <td width="70%">
	    <input type="radio" name="bantype" id="b_normal" class="radio" value=""><label for="b_normal"> 正常状态</label><br />
		<input type="radio" name="bantype" id="b_post" class="radio" value="post"><label for="b_post"> 禁止发言</label><br />
		<input type="radio" name="bantype" id="b_visit" class="radio" value="visit"><label for="b_visit"> 禁止访问</label>
	  </td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>禁止的有效期:</strong><br />有效期之后用户将恢复为普通用户</td>
      <td width="70%"><select name="expirytime">
	    <option value="0">永久</option>
		<option value="1">一天</option>
		<option value="3">三天</option>
		<option value="5">五天</option>
		<option value="7">一周</option>
		<option value="14">两周</option>
		<option value="30">一个月</option>
		<option value="90">三个月</option>
		<option value="180">半年</option>
	  </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>同时删除该用户发表的:</strong></td>
      <td width="70%"><input type="checkbox" name="deletetopic" id="deletetopic" class="radio" value="1"><label for="deletetopic">帖子</label>&nbsp;
	  <input type="checkbox" name="deletepost" id="deletepost" class="radio" value="1"><label for="deletepost">回复</label>&nbsp;
	  <input type="checkbox" name="deletepm" id="deletepm" class="radio" value="1"><label for="deletepm">传呼</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>操作原因:</strong></td>
      <td width="70%"><textarea name="reason" rows="5" cols="40"></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1">&nbsp;</td>
      <td width="70%"><input type="submit" id="submit1" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub
%>