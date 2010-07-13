<!--#include file="wap.fun.asp"-->
<!--#include file="../include/gbl.fun.asp"-->
<!--#include file="../include/main.class.asp"-->
<%
Response.ContentType = "text/vnd.wap.wml"

Dim RQ, ItemCount, s
ReDim Arr(50)

Set RQ = New Cls_Forum
ItemCount = 0

'检查用户是否登录
Call RQ.CheckUserLogin()

'获取站点以及版面设置
Call RQ.Get_ForumSettings()

If RQ.Wap_Settings(0) = "0" Then
	WapHeader()
	Call WapMessage("目前WAP功能已经关闭。", "")
End If
%>