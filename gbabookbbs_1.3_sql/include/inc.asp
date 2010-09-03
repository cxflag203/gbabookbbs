<!--#include file="common.inc.asp"-->
<!--#include file="gbl.fun.asp"-->
<!--#include file="main.class.asp"-->
<%
'my pretty demo
Dim Mpd
Set Mpd = New Cls_Forum

'检查用户是否登录
Call Mpd.CheckUserLogin()

'获取站点以及版面设置
Call Mpd.Get_ForumSettings()
%>