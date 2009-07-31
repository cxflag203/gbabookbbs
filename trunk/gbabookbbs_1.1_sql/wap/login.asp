<!--#include file="../include/common.inc.asp"-->
<% ScriptName = "wap" %>
<!--#include file="../include/sinc.asp"-->
<!--#include file="wap.fun.asp"-->
<%
Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case Else
		Call Main()
End Select

Sub Main()
	WapHeader()

	WapFooter()
End Sub
%>