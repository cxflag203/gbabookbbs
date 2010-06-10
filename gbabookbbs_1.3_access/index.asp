<!--#include file="include/inc.asp"-->
<%
Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "body"
		Call Body()
	Case "top"
		Call Top()
	Case "version"
		Call Version()
	Case Else
		Call Main()
End Select

'========================================================
'更新用户登陆信息
'========================================================
Sub Main()
	If RQ.UserID > 0  Then
		Dim strSQL

		If DateDiff("n", RQ.UserLoginTime, Now()) >= IntCode(RQ.User_Settings(0)) Then
			'判断当前用户金钱是否超出限额
			If RQ.UserCredits + IntCode(RQ.User_Settings(1)) > 2147483647 Then
				RQ.UserCredits = 0
				Call RQ.SetLog(RQ.UserID, RQ.UserName, "id被爆", "系统自动增加"& RQ.Other_Settings(0) &"时"& RQ.Other_Settings(0) &"数量超出最高限额")
			Else
				RQ.UserCredits = RQ.UserCredits + IntCode(RQ.User_Settings(1))
			End If
			strSQL = ", credits = "& RQ.UserCredits &", logincount = logincount + 1"
		End If

		If RQ.UserLoginIP <> RQ.UserIP Then
			strSQL = strSQL &", lastlogintime = logintime, lastloginip = loginip, loginip = '"& RQ.UserIP &"'"
		End If
		
		RQ.Execute("UPDATE "& TablePre &"members SET logintime = #"& Now() &"#"& strSQL &" WHERE uid = "& RQ.UserID)
		Call closeDatabase()
	End If
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<meta name="keywords" content="<%= RQ.Base_Settings(1) %>" />
<meta name="description" content="<%= RQ.Base_Settings(2) %>" />
<title><%= RQ.Base_Settings(0) %> - Powered by GBABook</title>
<link rel="stylesheet" href="images/common/common.css" />
<script type="text/javascript" src="js/common.js"></script>
</head>
<frameset border="0" frameborder="0" rows="50,*">
  <frame src="?action=top&fid=<%= RQ.ForumID %>" name="<%= CacheName %>top" id="<%= CacheName %>top" scrolling="no" noresize>
  <frame src="?action=body&fid=<%= RQ.ForumID %>" name="<%= CacheName %>body" id="<%= CacheName %>body">
</frameset>
<noframes>
  <body>
    <p><a href="forumdisplay.asp?fid=<%= RQ.Other_Settings(3) %>">列表页面</a></p>
    <p><a href="index.asp?action=top">菜单栏</a></p>
 </body>
</noframes>
</html>
<% 
End Sub

'========================================================
'BODY FRAME
'========================================================
Sub Body()
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<meta name="keywords" content="<%= RQ.Base_Settings(1) %>" />
<meta name="description" content="<%= RQ.Base_Settings(2) %>" />
<title><%= RQ.Base_Settings(0) %> - Powered by GBABook</title>
<link rel="stylesheet" href="images/common/common.css" />
<script type="text/javascript" src="js/common.js"></script>
<script language="JavaScript">
if (top==self){
	document.location = "./";
}
</script>
</head>
<frameset name="<%= CacheName %>bodys" id="<%= CacheName %>bodys" cols="50%,*">
  <frameset name="<%= CacheName %>leftsearch" id="<%= CacheName %>leftsearch" rows="*,50">
    <% If RQ.ForumID = 0 Then %>
    <frame src="forumdisplay.asp?fid=<%= RQ.Other_Settings(3) %>" name="<%= CacheName %>left" id="<%= CacheName %>left">
    <% Else %>
    <frame src="forumdisplay.asp?fid=<%= RQ.ForumID %>" name="<%= CacheName %>left" id="<%= CacheName %>left">
    <% End If %>
    <frame src="membermisc.asp" name="<%= CacheName %>search" id="<%= CacheName %>search" scrolling="auto" >
  </frameset>
  <frameset name="<%= CacheName %>rightmessage" id="<%= CacheName %>rightmessage" rows="*,0" frameborder="no" border="0" framespacing="0">
    <frame src="leaguelist.asp" name="<%= CacheName %>right" id="<%= CacheName %>right" frameborder="no" border="0" framespacing="0">
    <frame name="<%= CacheName %>frame_sound" id="<%= CacheName %>frame_sound" src="about:blank">
  </frameset>
</frameset>
<noframes>
  <body>
    <p><a href="forumdisplay.asp?fid=<%= RQ.Other_Settings(3) %>">列表页面</a></p>
    <p><a href="index.asp?action=top">菜单栏</a></p>
  </body>
</noframes>
<% 
End Sub

'========================================================
'BBS顶端内容
'========================================================
Sub Top()
	Dim ForumListArray
	ForumListArray = RQ.Query("SELECT f.fid, f.name, f.visitndcredits, ff.viewperm FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid ORDER BY f.displayorder ASC")
	Call closeDatabase()
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= Response.Charset %>" />
<title></title>
<link rel="stylesheet" href="images/common/common.css" />
<script type="text/javascript" src="js/common.js"></script>
</head>

<body style="padding: 0px; background: none;">
<div class="mainbg">
  <div class="leftstuff">
    <div class="topmsg"><iframe name="<%= CacheName %>online" src="session.asp" width="0" height="0" scrolling="no" frameborder="0"></iframe><span id="newmsg"></span></div>
    <div class="banner"><%= RQ.Gbl_Banner %></div>
	<div class="memberzone">
	  <% If RQ.UserID > 0 Then %>
      <span>您好，<%= RQ.UserName %> [<a href="<%= RQ.Login_Settings(1) %>?action=clearcookies" class="mcplink" target="_top">退出</a>]</span>
	  <span><a href="membercp.asp" class="mcplink" target="<%= CacheName %>right">相关功能</a></span>
	  <span><a href="item.asp" target="<%= CacheName %>right" class="mcplink">道具</a></span>
	  <% Else %>
      <span><a href="<%= RQ.Login_Settings(1) %>" class="mcplink" target="<%= CacheName %>right">注册/登陆</a></span>
	  <% End If %>
      <span><a href="leaguelist.asp" class="mcplink" target="<%= CacheName %>right">联盟</a></span>
	  <% If RQ.Wap_Settings(0) = "1" Then %><span><a href="wap/" class="mcplink" target="_blank">WAP</a></span><% End If %>
      <span><a href="htmls/help.html" class="mcplink" target="<%= CacheName %>right">帮助</a></span>
      <% If RQ.AdminGroupID = 1 Or RQ.AdminGroupID = 2 Or (RQ.AllowPunishUser = 1 And InArray(Array(1, 2), RQ.AdminGroupID)) Or RQ.AllowBanIP = 1 Or RQ.AllowViewLog = 1 Then %><span><a href="manage/" class="mcplink" target="_top">系统设置</a></span><% End If %>
    </div>
  </div>
  <div class="tabbg">
    <div class="linkbg">
      <div class="forums" id="forums">
	    <% If IsArray(ForumListArray) Then %>
		<% For i = 0 To UBound(ForumListArray, 2) %>
		<% If (ForumListArray(2, i) = 0 Or RQ.UserCredits >= ForumListArray(2, i)) And (Len(ForumListArray(3, i)) = 0 Or InStr(","& ForumListArray(3, i) &",", ","& RQ.UserGroupID &",") > 0) Then %>
        <a href="forumdisplay.asp?fid=<%= ForumListArray(0, i) %>" target="<%= CacheName %>left" id="f_<%= ForumListArray(0, i) %>" class="tabunselected" onclick="switchtab(this.id);"><%= ForumListArray(1, i) %></a>
		<% End If %>
		<% Next %>
		<% End If %>
      </div>
    </div>
  </div>
</div>
<script type="text/javascript">
function switchtab(theid){
	var obj = $('forums');
	for (i = 0; i < obj.getElementsByTagName('a').length; i++){
		var e = obj.getElementsByTagName('a')[i].id;
		if (e == theid){
			$(theid).className = 'tabselected';
		}else {
			$(e).className = 'tabunselected';
		}
	}
}
switchtab('f_<%= IIF(RQ.ForumID = 0, RQ.Other_Settings(3), RQ.ForumID) %>');
</script>
</body>
</html>
<%
End Sub

Sub Version()
	Response.Write "GBABOOK BBS V1.3 for Access Released at 2010-06-01"
End Sub
%>