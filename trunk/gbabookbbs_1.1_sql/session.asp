<!--#include file="include/inc.asp"-->
<%
Dim Cmd, NewPm

If RQ.UserID = 0 And Len(RQ.UserName) = 0 Then
	RQ.UserName = "游客"
End If

If Not IsObject(Conn) Then
	Call connectDatabase()
End If

Set Cmd = Server.CreateObject("ADODB.Command")
With Cmd
	.ActiveConnection = Conn
	.CommandType = 4
	.Prepared = True
	.CommandText = TablePre &"sp_online_newpm"
	.Parameters.Item("@sid") = RQ.UserSessionID
	.Parameters.Item("@uid") = RQ.UserID
	.Parameters.Item("@username") = RQ.UserName
	.Parameters.Item("@userip") = RQ.UserIP
	.Parameters.Item("@usergroupid") = RQ.UserGroupID
	.Parameters.Item("@onlinehold") = IntCode(RQ.User_Settings(3))
	.Execute
	NewPm = .Parameters.Item(0)
End With
Set Cmd = Nothing

Call closeDatabase()

If NewPm > 0 Then
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