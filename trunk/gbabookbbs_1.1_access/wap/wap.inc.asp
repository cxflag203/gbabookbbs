<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/gbl.fun.asp"-->
<!--#include file="../include/main.class.asp"-->
<!--#include file="wap.fun.asp"-->
<%
dbSource = Server.MapPath("../database/#SNWgdHYqWbgdjanLsmvT.mdb")

'初始化类
Dim RQ
Set RQ = New Cls_Forum

'检查用户是否登录
Call RQ.CheckUserLogin()

'获取站点以及版面设置
Call RQ.Get_ForumSettings()

Response.ContentType = "text/vnd.wap.wml"

Dim ItemCount, s
ReDim Arr(50)
ItemCount = 0

If RQ.Base_Settings(3) = "1" Then
	WapHeader()
	Call WapMessage("论坛目前临时关闭。", "")
End If

If RQ.Wap_Settings(0) = "0" Then
	WapHeader()
	Call WapMessage("目前WAP功能已经关闭。", "")
End If
%>