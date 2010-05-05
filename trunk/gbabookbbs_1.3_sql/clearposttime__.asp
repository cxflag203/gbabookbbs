<!--#include file="include/inc.asp"-->
<%
Dim PostListArray, Message
PostListArray = RQ.Query("SELECT pid, message FROM "& TablePre &"posts WHERE iffirst = 1")
If IsArray(PostListArray) Then
	For i = 0 To UBound(PostListArray, 2)
		Message = Preg_Replace(PostListArray(1, i), "<br \/><em>\(发帖时间:(.*?)\)<\/em>(|\s)<br \/>", "")
		RQ.Execute("UPDATE "& TablePre &"posts SET message = '"& Message &"' WHERE pid = "& PostListArray(0, i))
	Next
End If

Call closeDatabase()
%>