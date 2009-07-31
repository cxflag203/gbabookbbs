<%
Response.ContentType = "text/vnd.wap.wml"

If RQ.Base_Settings(3) = "1" Then
	Call WapMessage("论坛目前临时关闭。", "")
End If

Dim ItemCount, s
ReDim Arr(50)
itemCount = 0

'========================================================
'把字符串放到动态数组中
'========================================================
Public Sub Append(str)
	If ItemCount > UBound(Arr) Then
		ReDim Preserve Arr(UBound(Arr) + 50)
	End If

	Arr(ItemCount) = str
	ItemCount = ItemCount + 1
End Sub

'========================================================
'wap页头
'========================================================
Public Sub WapHeader()
	Call Append("<?xml version=""1.0""?><!DOCTYPE wml PUBLIC ""-//WAPFORUM//DTD WML 1.1//EN"" ""http://www.wapforum.org/DTD/wml_1.1.xml""><wml><head><meta http-equiv=""cache-control"" content=""max-age=180,private"" /></head><card id=""gbabook_wml"" title="""& RQ.Base_Settings(0) &"""><p>")
End Sub

'========================================================
'wap页脚，并输出内容
'========================================================
Public Sub WapFooter()
	Call Append("</p><p>"& Now() &"<br /><anchor title=""confirm""><prev/>返回</anchor> <a href=""index.asp"">首页</a><br />"& IIF(RQ.UserID > 0, "<a href=""login.asp?action=logout"">"& RQ.UserName &":退出</a>", "<a href=""login.asp"">登陆</a>") &"<br /><br />"& FormatNumber(Timer() - StartTime, 6, -1) &"</p></card></wml>")
	If RQ.Wap_Settings(2) = "0" Then
		Response.Write WapConvert(Join(Arr, ""))
	Else
		Response.Write Join(Arr, "")
	End If
End Sub

'========================================================
'wap显示提示信息
'========================================================
Public Sub WapMessage(strtips, url)
	Call WapHeader()
	Call Append(strtips & IIF(Len(url) > 0, "<a href="""& url &""">点击这里跳转</a>", ""))
	Call WapFooter()
	Response.End()
End Sub

'========================================================
'去掉内容中的html标签和隐藏内容标签
'========================================================
Public Function WapCode(str)
	Dim regEx
	Set regEx = New Regexp
	regEx.IgnoreCase = True
	regEx.Global = True
	regEx.Pattern = "<br(.*?)>"
	str = regEx.Replace(str, "[br]")
	regEx.Pattern = "\[hide\](.+?)\[\/hide\]"
	str = regEx.Replace(str, "[隐藏内容]")
	regEx.Pattern = "\[hide=(\d+)\](.+?)\[\/hide\]"
	str = regEx.Replace(str, "[隐藏内容]")
	regEx.Pattern = "\[attach\](\d+)\[\/attach\]"
	str = regEx.Replace(str, "")
	regEx.Pattern = "<(.[^>]*)>"
	str = regEx.Replace(str, "")
	str = Replace(str, "&", "&amp;")
	str = Replace(str, "'", "&#39;")
	str = Replace(str, """", "&quot;")
	WapCode = str
End Function

'========================================================
'wap显示分页
'========================================================
Public Sub ShowWapPage(Page, PageCount, RecordCount, Condition)
	Dim StartPage

	If Page > PageCount - 9 And PageCount > 9 Then
		If Page - (PageCount - 9) = 1 And PageCount - 10 > 0 Then
			StartPage = PageCount - 10
		Else
			StartPage = PageCount - 9
		End If
	ElseIf (Page - 2) > 0 Then
		StartPage = Page - 2
	Else
		StartPage = 1
	End If

	If PageCount + 1 > Page And Page > 1 Then
		If StartPage > 1 Then
			Call Append("<a href=""?page=1"& Condition &""">1...</a> ")
		End If
		Call Append("<a href=""?page="& Page - 1 & Condition &""">上页</a> ")
	End If

	For i = StartPage To StartPage + 9
		If i > PageCount Then
			Exit For
		End If

		If i = Page Then
			Call Append(i &" ")
		Else
			Call Append("<a href=""?page="& i & Condition &""">"& i &"</a> ")
		End If
	Next

	If PageCount > Page Then
		Call Append("<a href=""?page="& Page + 1 & Condition &""">下页</a> ")
	End If

	If StartPage + 9 < PageCount Then
		Call Append("<a href=""?page="& PageCount & Condition &""">"& PageCount &"...</a>")
	End If
End Sub

'========================================================
'字符串转为Unicode编码
'========================================================
%>
<script language="jscript" runat="server">
var WapConvert = function(str){
	var n, cur, ret = [];
	for (n = 1; n <= str.length; n++){
		cur = str.substr(n - 1, 1);
		if (cur.charCodeAt(cur) > 127){
			ret.push(escape(cur).replace("%u", "&#x")+';');
		}else{
			ret.push(cur);
		}
	}
	return ret.join('');
}
</script>