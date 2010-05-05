<!--#include file="include/inc.asp"-->
<%
Dim OnlineInfo, PmInfo

If RQ.UserID = 0 And Len(RQ.UserName) = 0 Then
	RQ.UserName = "游客"
End If

If Not IsObject(Conn) Then
	Call connectDatabase()
End If

OnlineInfo = RQ.Query("SELECT 1 FROM "& TablePre &"online WHERE sid = '"& RQ.UserSessionID &"' AND uid = "& RQ.UserID)
If IsArray(OnlineInfo) Then
	'更新当前用户
	RQ.Execute("UPDATE "& TablePre &"online SET uid = "& RQ.UserID &", username = '"& RQ.UserName &"', userip = '"& RQ.UserIP &"', usergroupid = "& RQ.UserGroupID &", lastupdate = #"& Now() &"# WHERE sid = '"& RQ.UserSessionID &"'")
Else
	'删除不在线的用户
	RQ.Execute("DELETE FROM "& TablePre &"online WHERE sid = '"& RQ.UserSessionID &"' OR lastupdate < #"& DATEADD("n", -IntCode(RQ.User_Settings(3)), Now()) &"# OR (uid > 0 AND uid = "& RQ.UserID &") OR (uid = 0 AND userip = '"& RQ.UserIP &"' AND lastupdate < #"& DATEADD("n", -60, Now()) &"#)")

	'记录当前用户
	RQ.Execute("INSERT INTO "& TablePre &"online (sid, uid, username, userip, usergroupid) VALUES ('"& RQ.UserSessionID &"', "& RQ.UserID &", '"& RQ.UserName &"', '"& RQ.UserIP &"', "& RQ.UserGroupID &")")
End If

PmInfo = RQ.Query("SELECT 1 FROM "& TablePre &"pm WHERE msgtoid = "& RQ.UserID &" AND posttime <= #"& Now() &"#")

Call closeDatabase()

If IsArray(PmInfo) Then
%>
<% If RQ.Other_Settings(5) = "1" Then %>
<script type="text/javascript">
  parent.document.getElementById('newmsg').style.display = '';
  parent.document.getElementById('newmsg').innerHTML = '<a href="pm.asp" target="_blank" title="您有新短信，点击查看" onclick="$(\'newmsg\').style.display = \'none\'" style="background:none;"><img src="images/common/newmsg.gif" /></a>';
</script>
<% Else %>
<script type="text/javascript">
  window.open("pm.asp" ,"showpm","scrollbars=yes,top=100,left=100,width=355,height=215");
</script>
<bgsound src="images/common/1up.wav" loop="0" />
<% End If %>
<%
End If
%>
<meta http-equiv="refresh" content="<%= IntCode(RQ.User_Settings(2)) * 60 %>" />