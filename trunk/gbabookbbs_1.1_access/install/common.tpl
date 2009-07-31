<% @LANGUAGE="VBSCRIPT" CODEPAGE = 65001 EnableSessionState = False %>
<%
Option Explicit

Response.Buffer = True
Response.CharSet = "utf-8"

Dim StartTime, dbQueryNum
Dim dbSource, Conn, Rs, i, ScriptName

StartTime = Timer()
dbQueryNum = 0

Const CacheName = "{cachename}"
Const TablePre = "gb_"
Const PrivateKey = "{privatekey}"
Const INGBABOOK = True
Const SHOWVERSION = "1.1"

'数据库路径
dbSource = Server.MapPath("database/{dbsource}")

'========================================================
'连接数据库
'========================================================
Public Sub connectDatabase()
	On Error Resume Next
	Set Conn = Server.CreateObject("ADODB.Connection")
	Conn.Open("Provider=Microsoft.Jet.OLEDB.4.0;Data Source="& dbSource)
	If Err <> 0 Then
		Err.Clear
		Set Conn = Nothing
		Response.Write "数据库大姨妈了...."
		Response.End()
	End If
End Sub

'========================================================
'关闭数据库
'========================================================
Public Sub closeDatabase()
	On Error Resume Next
	Set Rs = Nothing
	Conn.Close
	Set Conn = Nothing
End Sub
%>