<!--#include file="gbl.fun.asp"-->
<!--#include file="main.class.asp"-->
<%
'初始化类
Dim RQ
Set RQ = New Cls_Forum

'检查用户是否登录
Call RQ.CheckUserLogin()

'获取站点以及版面设置
Call RQ.Get_ForumSettings()

%>