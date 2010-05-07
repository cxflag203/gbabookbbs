<!--#include file="include/admininc.asp"-->
<!--#include file="../version.asp"-->
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=<%= Response.Charset %>">
<title><%= RQ.Base_Settings(0) %> - 后台管理页面</title>
<link rel="stylesheet" href="../images/manage/admincp.css">
<script language="javascript" src="../images/manage/admin.js"></script>
<base target="<%= CacheName %>admin_body" />
</head>
<%

If Not RQ.IsModerator Then
	Call AdminshowTips("您无权访问。", "")
End If

Dim Action, n

n = 0
Action = Request.QueryString("action")
Select Case Action
	Case "show_menu"
		Call Show_Menu()
	Case "show_top"
		Call Show_Top()
	Case Else
		Call Main()
End Select

'========================================================
'循环数组显示菜单
'========================================================
Sub ListMenu(Title, MenuListArray)
	Dim TEMP
	Response.Write "<table width=""146"" border=""0"" cellspacing=""0"" align=""center"" cellpadding=""0"" class=""leftmenulist"" style=""margin-bottom: 5px;"">"& _
	"<tr class=""leftmenutext"">"& _
	"<td height=""25"" onclick=""showsubmenu("& n &")""><img id=""menuimg_"& n &""" src=""../images/manage/menu_reduce.gif"" border=""0"" /> "& Title &"</td>"& _
	"</tr>"& _
	"<tr class=""leftmenutd"" id=""submenu"& n &""">"& _
	"<td>"& _
	"<table border=""0"" cellspacing=""0"" cellpadding=""0"" class=""leftmenuinfo"">"
	For i = 0 To UBound(MenuListArray)
		If Len(MenuListArray(i)) = 0 Then
			Exit For
		End If
		TEMP = Split(MenuListArray(i), ",")
		Response.Write "<tr>"& _
		"<td height=""20""><a href="""& TEMP(0) &""">"& TEMP(1) &"</a></td>"& _
		"</tr>"
	Next
	Response.Write "</table>"& _
	"</td>"& _
	"</tr>"& _
	"</table>"
	n = n + 1
End Sub

'========================================================
'左边菜单栏
'========================================================
Sub Show_Menu()
%>
<body leftmargin="0" topmargin="0" marginheight="0" marginwidth="0" onclick="document_onclick()"><br>
<table width="146" border="0" cellspacing="0" align="center" cellpadding="0" class="leftmenulist" style="margin-bottom: 5px;">
  <tr class="leftmenutext">
    <td height="25"><a href="../" target="_top">&#187; 返回首页</a></td>
  </tr>
</table>
<%
	Dim MenuArray(10), strMenu

	If RQ.AdminGroupID = 1 Then
		MenuArray(0) = "settings.asp?action=basesettings,基本设置"
		MenuArray(1) = "settings.asp?action=timesettings,时间段设置"
		MenuArray(2) = "settings.asp?action=loginsettings,注册/登录设置"
		MenuArray(3) = "settings.asp?action=usersettings,用户功能相关"
		MenuArray(4) = "settings.asp?action=topicsettings,帖子和回复相关"
		MenuArray(5) = "settings.asp?action=othersettings,搜索和其他设置"
		MenuArray(6) = "settings.asp?action=chatsettings,聊天室设置"
		MenuArray(7) = "settings.asp?action=wapsettings,WAP设置"
		Call ListMenu("站点设置", MenuArray)
		Erase MenuArray

		MenuArray(0) = "forums.asp,编辑版面"
		MenuArray(1) = "forums.asp?action=add_forum,添加版面"
		MenuArray(2) = "forums.asp?action=merge,合并版面"
		Call ListMenu("版面设置", MenuArray)
		Erase MenuArray

		MenuArray(0) = "members.asp,编辑用户"
		MenuArray(1) = "banuser.asp,禁止用户"
		MenuArray(2) = "banip.asp,禁止IP"
		MenuArray(3) = "usergroups.asp,用户组"
		Call ListMenu("用户管理", MenuArray)
		Erase MenuArray

		MenuArray(0) = "wordfilter.asp,词语过滤"
		MenuArray(1) = "attachment.asp,附件管理"
		MenuArray(2) = "recyclebin.asp,回收站"
		Call ListMenu("帖子管理", MenuArray)
		Erase MenuArray

		MenuArray(0) = "items.asp,道具管理"
		MenuArray(1) = "itemsettings.asp,道具设置"
		'MenuArray(2) = "items.asp,道具效果管理"
		Call ListMenu("道具管理", MenuArray)
		Erase MenuArray

		MenuArray(0) = "leagues.asp,编辑联盟"
		MenuArray(1) = "leagues.asp?action=add,添加联盟"
		Call ListMenu("联盟管理", MenuArray)
		Erase MenuArray

		MenuArray(0) = "logs.asp,异动报告"
		MenuArray(1) = "logs.asp?action=itemmarket,道具转让记录"
		MenuArray(2) = "logs.asp?action=itemuse,道具使用记录"
		MenuArray(3) = "logs.asp?action=reginvate,推荐码注册记录"
		Call ListMenu("查看日志", MenuArray)
		Erase MenuArray

		MenuArray(0) = "database.asp?action=sql,执行SQL语句"
		MenuArray(1) = "database.asp,数据库信息"
		Call ListMenu("系统工具", MenuArray)
		Erase MenuArray
	Else
		If RQ.AdminGroupID = 2 And RQ.AllowEditUser = 1 Then
			strMenu = strMenu &"members.asp,编辑用户;"
		End If

		'站长和高级管理员才能禁止用户
		If RQ.AllowPunishUser = 1 And RQ.AdminGroupID = 2 Then
			strMenu = strMenu &"banuser.asp,禁止用户;"
		End If

		If RQ.AllowBanIP = 1 Then
			strMenu = strMenu &"banip.asp,禁止IP;"
		End If

		If RQ.AdminGroupID = 2 Then
			strMenu = strMenu &"wordfilter.asp,词语过滤;"
			strMenu = strMenu &"recyclebin.asp,回收站;"
			strMenu = strMenu &"attachment.asp,附件管理;"
			strMenu = strMenu &"leagues.asp,联盟管理;"
			strMenu = strMenu &"leagues.asp?action=add,添加联盟;"
		End If

		'If RQ.AllowDelItemMsg = 1 Then
		'	strMenu = strMenu &"itemmessage.asp,道具效果管理;"
		'End If

		If RQ.AllowViewLog = 1 Then
			strMenu = strMenu &"logs.asp,异动报告;"
			strMenu = strMenu &"logs.asp?action=itemmarket,道具转让日志;"
			If RQ.AdminGroupID = 2 Then
				strMenu = strMenu &"logs.asp?action=itemuse,道具使用记录;"
				strMenu = strMenu &"logs.asp?action=reginvate,推荐码注册记录;"
			End If
		End If

		If Len(strMenu) > 0 Then
			Call ListMenu("管理面板", Split(strMenu, ";"))
		End If
	End If
	Response.Write "<br /><br /><br />"
End Sub

'========================================================
'顶部内容
'========================================================
Sub Show_Top()
	Response.Write "<body><div class=""topcontainer""><div class=""toplogo""><img src=""../images/manage/logo.gif"" /></div><div class=""topmsg""><script type=""text/javascript"" src=""http://stat.gbabook.net/notice.asp?version="& GBABOOKBBS_VERSION &"&types="& GBABOOKBBS_TYPE &"&release="& GBABOOKBBS_RELEASE &"""></script></div></div>"
End Sub

'========================================================
'定义框架
'========================================================
Sub Main()
%>
<frameset rows="30,*" cols="*" frameborder="no" border="0" framespacing="0">
  <frame name="<%= CacheName %>admin_header" scrolling="No" noresize="noresize" src="?action=show_top" />
  <frameset cols="180,*" frameborder="no" border="0" framespacing="0">
    <frame name="<%= CacheName %>admin_menu" noresize scrolling="yes" src="?action=show_menu">
    <frame name="<%= CacheName %>admin_body" noresize scrolling="yes" src="<% If RQ.AdminGroupID = 1 Or (RQ.AdminGroupID = 2 And RQ.AllowEditUser = 1) Then %>members.asp<% End If %>">
  </frameset>
</frameset>
<% 
End Sub
%>
</body>
</html>