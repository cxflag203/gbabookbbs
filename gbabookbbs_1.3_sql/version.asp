<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

'请不要修改这里的任何地方，以免以后更新程序的判断出错
Const GBABOOKBBS_VERSION = "1.3"
Const GBABOOKBBS_TYPE = "SQL Server"
Const GBABOOKBBS_RELEASE = "20100601"
%>