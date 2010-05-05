<%
'========================================================
'管理界面头部内容
'========================================================
Public Sub AdminHeader()
	Response.Write "<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd""><html xmlns=""http://www.w3.org/1999/xhtml""><meta http-equiv=""Content-Type"" content=""text/html;charset="& Response.Charset &"""><title>后台管理页面</title><link rel=""stylesheet"" href=""../images/manage/admincp.css"" /><script language=""javascript"" src=""../images/manage/admin.js"" /></script></head><body leftmargin=""0"" topmargin=""0"" marginheight=""0"" marginwidth=""0"" onkeydown=""if(event.keyCode==27) return false;"">"
End Sub

'========================================================
'管理界面尾部内容
'========================================================
Public Sub AdminFooter()
	Response.Write "<div class=""footer""><hr size=""0"" noshade color=""#999999"" width=""80%"">Processed in:"& FormatNumber(Timer() - StartTime, 6, -1) &"s, queries:"& dbQueryNum &"</div></body></html>"
End Sub

'========================================================
'管理界面提示信息内容
'========================================================
Public Sub AdminshowTips(str, url)
	Response.Write "<table width=""100%"" border=""0"" cellpadding=""2"" cellspacing=""6""><tr><td><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p><table width=""500"" border=""0"" cellpadding=""0"" cellspacing=""0"" align=""center"" class=""tableborder""><tr class=""header""><td>提示</td></tr><tr><td class=""altbg2""><div align=""center""><br /><br /><br />"& str &"<br /><br /><br />"
	If Len(url) > 0 Then
		Response.Write "<a href="""& url &""">如果您的浏览器没有跳转,请点击这里.</a><script type=""text/javascript"">setTimeout(""window.location.replace('"& url &"');"", 500);</script>"
	Else
		Call closeDatabase()
		Response.Write "[<a href=""javascript:history.go(-1);"">点击这里返回上一页</a>]"
	End If
	Response.Write "<p>&nbsp;</p><p>&nbsp;</p></div></td></tr></table><p>&nbsp;</p><p>&nbsp;</p></td></tr></table>"
	AdminFooter()
	Response.End()
End Sub
%>