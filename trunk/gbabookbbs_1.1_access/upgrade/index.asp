<% @LANGUAGE="VBSCRIPT" CODEPAGE = 65001 EnableSessionState = False %>
<%
Option Explicit

Response.Buffer = True
Response.Charset = "utf-8"

Dim strContent
strContent = LoadFile("../include/common.inc.asp")
strContent = Preg_Replace(strContent, "CODEPAGE = 936", "CODEPAGE = 65001")
strContent = Preg_Replace(strContent, "gb2312", "utf-8")
Call MakeFile(strContent, "../include/common.inc.asp")
Response.Redirect "upgrade_to_12_access.asp"

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

'========================================================
'正则表达式过滤字符
'========================================================
Public Function Preg_Replace(str, Pattern, ReplaceWith)
	If Len(str) = 0 Then
		Exit Function
	End If

	Dim regEx, strTEMP, n

	Set regEx = New RegExp
	regEx.IgnoreCase = True
	regEx.Global = True
	strTEMP = str

	If IsArray(Pattern) Then
		For n = 0 To UBound(Pattern)
			If Len(Pattern(n)) > 0 Then
				regEx.Pattern = Pattern(n)
				strTEMP = regEx.Replace(strTEMP, ReplaceWith(n))
			End If
		Next
	Else
		regEx.Pattern = Pattern
		strTEMP = regEx.Replace(strTEMP, ReplaceWith)
	End If

	Set regEx = Nothing
	Preg_Replace = strTEMP
	strTEMP  = Empty
End Function
%>