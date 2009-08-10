<% @LANGUAGE="VBSCRIPT" CODEPAGE = 65001 EnableSessionState = False %>
<%
Option Explicit

Response.Buffer = True
Response.Charset = "utf-8"

Dim strContent
strContent = LoadFile("../include/common.inc.asp")
strContent = Replace(strContent, "CODEPAGE = 936", "CODEPAGE = 65001")
strContent = Replace(strContent, "gb2312", "utf-8")
Call MakeFile(strContent, "../include/common.inc.asp")
Response.Redirect "upgrade_to_12_sql.asp"

'========================================================
'读取文件内容
'========================================================
Public Function LoadFile(sFileName)
	Dim Stream
	Set Stream = Server.CreateObject("ADODB.Stream")
	With Stream
		.Mode = 3
		.Type = 2
		.Open
		.Charset = "gb2312"
		.LoadFromFile(Server.MapPath(sFileName))
		LoadFile = .ReadText
		.Close
	End With
	Set Stream = Nothing
End Function

'========================================================
'生成文件
'========================================================
Public Sub MakeFile(strContent, FileName)
	Dim Stream
	Set Stream = Server.CreateObject("ADODB.Stream") 
	With Stream 
		.Type = 2 
		.Open 
		.Charset = Response.CharSet
		.Position = Stream.Size 
		.WriteText = strContent
		.SaveToFile Server.MapPath(FileName), 2 
		.Close 
	End With
	Set Stream = Nothing
	strContent = Empty
End Sub
%>