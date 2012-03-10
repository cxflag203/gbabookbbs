<%
'========================================================
'弹出提示文字返回上一页
'
'@param string str		提示文字
'========================================================
Public Sub WarnBack(str)
	Call closeDatabase()
	Response.Write "<script type=""text/javascript"">alert("""& Replace(Replace(Replace(str, """", "\"""), "\", "\\"), vbCrLf, "\n") &""");javascript:history.go(-1);</script>"
	Response.End()
End Sub

'========================================================
'弹出提示文字并关闭当前窗口
'
'@param string str		提示文字
'========================================================
Public Sub Confirm(str)
	Call closeDatabase()
	Response.Write "<script type=""text/javascript"">alert("""& Replace(Replace(Replace(str, """", "\"""), "\", "\\"), vbCrLf, "\n") &""");window.close();</script>"
	Response.End()
End Sub

'========================================================
'去掉字符串中的空白字符
'
'@param string str		需要过滤空白字符的字符串
'@return string
'========================================================
Function CheckContent(str)
	Dim TEMP
	TEMP = Replace(str, vbCrLf, "")
	TEMP = Replace(TEMP, Chr(9), "")
	TEMP = Replace(TEMP, Chr(10), "")
	TEMP = Replace(TEMP, Chr(13), "")
	TEMP = Replace(TEMP, " ", "")
	TEMP = Replace(TEMP, "　","")
	TEMP = Replace(TEMP, "&nbsp;", "")
	CheckContent = TEMP
	TEMP = Empty
End Function

'========================================================
'验证数字集合
'
'@param string strNumber		数字集合,例如(1,2,3,4)
'@return string
'
'用于同名表单项目多选提交，例如选中多个帖子回复，批量删除。
'========================================================
Public Function NumberGroupFilter(strNumber)
	If Len(strNumber) = 0 Then
		NumberGroupFilter = ""
		Exit Function
	End If

	Dim TEMP, Numbers, n
	TEMP = Split(strNumber, ",")
	For n = 0 To UBound(TEMP)
		Numbers = Numbers & IntCode(TEMP(n))
		If n <> UBound(TEMP) Then
			Numbers = Numbers &","
		End If
	Next
	NumberGroupFilter = Numbers
End Function

'========================================================
'格式化数字

'@param int n		数字
'@return int

'如果参数小于等于0或者大于长整数的最大值或者为非数字则返回0
'========================================================
Public Function IntCode(n)
	If IsNumeric(n) Then
		If n > 2147483647 Then
			IntCode = 2147483647
		ElseIf n < 0 Then
			IntCode = 0
		Else
			IntCode = CLng(n)
		End If
	Else
		IntCode = 0
	End If
End Function

'========================================================
'过滤字符串中的特殊字符和Html标签
'========================================================
Public Function strFilter(str)
	If Len(str) = 0 Then
		Exit Function
	End If

	Dim strTEMP
	strTEMP = Replace(str, "'", "&#39;")
	strTEMP = Replace(strTEMP, """", "&quot;")
	strTEMP = Replace(strTEMP, "<", "&lt;")
	strTEMP = Replace(strTEMP, ">", "&gt;")
	strTEMP = Replace(strTEMP, Chr(0), "")
	strFilter = strTEMP
	strTEMP = Empty
End Function

'========================================================
'过滤危险Html代码(允许Html格式)
'========================================================
Public Function HtmlFilter(str)
	If Len(str) = 0 Then
		Exit Function
	End If

	Dim regEx, strTEMP

	Set regEx = New RegExp
	regEx.IgnoreCase = True
	regEx.Global = True
	strTEMP = str

	regEx.Pattern = "<script"
	strTEMP = regEx.Replace(strTEMP, "&lt;script")

	regEx.Pattern = "</script>"
	strTEMP = regEx.Replace(strTEMP, "&lt;/script&gt;")

	regEx.Pattern = "\son([a-zA-Z]*)="
	strTEMP = regEx.Replace(strTEMP, " on$1&#61")

	regEx.Pattern = "<iframe(.*?)>(.*?)</iframe>"
	strTEMP = regEx.Replace(strTEMP, "")

	regEx.Pattern = "<object"
	strTEMP = regEx.Replace(strTEMP, "&lt;object")

	regEx.Pattern = "</object>"
	strTEMP = regEx.Replace(strTEMP, "&lt;/object&gt;")

	'regEx.Pattern = "<param"
	'strTEMP = regEx.Replace(strTEMP, "&lt;param")

	regEx.Pattern = "<img(.[^>]*)src=(.[^>]*)"& Replace(RQ.Login_Settings(1), ".", "\.") &"(.[^>]*)>"
	strTEMP = regEx.Replace(strTEMP, "贴图无效。")

	regEx.Pattern = "<a(.*?)href=(""|'|)(.*?)script(.*?)>"
	strTEMP = regEx.Replace(strTEMP, "&lt;a$1href&#61;$2$3script$4>")

	Set regEx = Nothing

	strTEMP = Replace(strTEMP, "'", "&#39;")
	strTEMP = Replace(strTEMP, "<"&"%", "&lt;%")
	strTEMP = Replace(strTEMP, "%"&">", "%&gt;")
	strTEMP = Replace(strTEMP, Chr(0), "")

	HtmlFilter = strTEMP
	strTEMP = Empty
End Function

'========================================================
'辨识网址和图片
'========================================================
Function ParseURL(str)
	Dim regEx
	Set regEx = New RegExp
	regEx.IgnoreCase = True
	regEx.Global = True

	regEx.Pattern = "([^>=""'\/]|^)((((https?|ftp):\/\/)|www\.)([\w\-]+\.)*[\w\-\u4e00-\u9fa5]+\.([\.a-zA-Z0-9]+|\u4E2D\u56FD|\u7F51\u7EDC|\u516C\u53F8)((\?|\/|:)+[\w\.\/=\?%\-&~`@':+!]*)+\.(jpg|jpeg|gif|png|bmp))"
	str = regEx.Replace(str, "$1<br /><a href=""$2"" target=""_blank""><img src=""$2"" border=""0"" /></a><br />")

	regEx.Pattern = "([^>=""'\/@]|^)((((https?|ftp):\/\/))([\w\-]+\.)*[:\.@\-\w\u4e00-\u9fa5]+\.([\.a-zA-Z0-9]+|\u4E2D\u56FD|\u7F51\u7EDC|\u516C\u53F8)((\?|\/|:)+[\w\.\/=\?%\-&~`@':+!#]*)*)"
	str = regEx.Replace(str, "$1<a href=""$2"" target=""_blank"">$2</a>")

	regEx.Pattern = "([^\w>=""'\/@]|^)((www\.)([\w\-]+\.)*[:\.@\-\w\u4e00-\u9fa5]+\.([\.a-zA-Z0-9]+|\u4E2D\u56FD|\u7F51\u7EDC|\u516C\u53F8)((\?|\/|:)+[\w\.\/=\?%\-&~`@':+!#]*)*)"
	str = regEx.Replace(str, "$1<a href=""http://$2"" target=""_blank"">$2</a>")

	Set regEx = Nothing
	ParseURL = str
	str = Empty
End Function

'========================================================
'按照指定长度截取字符串
'========================================================
Function CutString(str, length)
	Dim n, j, outLen, strLen

	str = Replace(str, "&amp;", "&")
	str = Replace(str, "&#39;", "'")
	str = Replace(str, "&quot;", """")
	str = dfc(str)

	strLen = Len(str)
	outLen = 0

	For n = 1 To strLen
		If ABS(Asc(Mid(str, n, 1))) <= 1 Then
			j = j + 2
		Else
			j = j + 1
		End If

		If j >= length And outLen = 0 Then
			outLen = n
			Exit For
		End If
	Next

	outLen = IIF(outLen = 0, strLen, outLen)
	str = Left(str, outLen)
	str = str & IIF(j > length, "...", "")

	str = Replace(str, "&", "&amp;")
	str = Replace(str, "'", "&#39;")
	str = Replace(str, """", "&quot;")
	CutString = str
End Function

'========================================================
'正则表达式验证字符串
'========================================================
Function RegExpTest(patrn, strng) 
	Dim regEx
	Set regEx = New RegExp
	regEx.Pattern = patrn
	regEx.IgnoreCase = True
	RegExpTest = regEx.Test(strng)
	Set regEx = Nothing
End Function

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

'========================================================
'词语过滤以及检测禁止词语
'========================================================
Public Function WordsFilter(str)
	If Len(RQ.WordsFilter_Settings) = 0 Then
		WordsFilter = str
		Exit Function
	End If

	Dim aryWords
	aryWords = eval(RQ.WordsFilter_Settings)

	If Len(aryWords(3)) > 0 And RegExpTest("("& aryWords(3) &")", str) Then
		Call RQ.showTips("您提交的内容里包含有敏感词语。", "", "")
	Else
		WordsFilter = Preg_Replace(str, aryWords(0), aryWords(1))
	End If
End Function

'========================================================
'是否有关键字需要审核
'========================================================
Public Function WordsAdulting(str)
	If Len(RQ.WordsFilter_Settings) = 0 Then
		Exit Function
	End If

	Dim aryWords
	aryWords = eval(RQ.WordsFilter_Settings)

	WordsAdulting = Len(aryWords(2)) > 0 And RegExpTest("("& aryWords(2) &")", str)
End Function

'========================================================
'清除Html标签
'========================================================
Public Function dfc(str)
	dfc = Preg_Replace(str, "<(.[^>]*)>", "")
End Function

'========================================================
'通用Request取值(Cookie取值使用strFilter或IntCode)
'========================================================
Public Function SafeRequest(Requester, RequestName, RequestType, DefaultValue, FilterType)
    Dim TempValue

    Select Case Requester
        Case 0
            TempValue = RequestName
        Case 1
            TempValue = Request(RequestName)
        Case 2
            TempValue = Request.Form(RequestName)
        Case 3
            TempValue = Request.QueryString(RequestName)
    End Select

    Select Case RequestType
        Case 0
            If Not IsNumeric(TempValue) Then
                TempValue = DefaultValue
            Else
				If TempValue > 2147483647 Then
					TempValue = 2147483647
				ElseIf TempValue <= 0 Then
					TempValue = DefaultValue
				Else
					TempValue = CLng(TempValue)
				End If
            End If
        Case 1
			Select Case FilterType
				Case 0
					TempValue = Replace(TempValue, "'", "&#39;")
					TempValue = Replace(TempValue, """", "&quot;")
					TempValue = Replace(TempValue, "<", "&lt;")
					TempValue = Replace(TempValue, ">", "&gt;")
					TempValue = Replace(TempValue, Chr(0), "")
				Case 1
					TempValue = HtmlFilter(TempValue)
			End Select
        Case 2
            If Not IsDate(TempValue) Then
                TempValue = CDate(DefaultValue)
            Else
                TempValue = CDate(TempValue)
            End If
    End Select

    SafeRequest = TempValue
	TempValue = Empty
End Function

'========================================================
'显示报错信息，并停止输出
'========================================================
Public Sub showErr(str)
	Call closeDataBase()
	Response.Write str
	RQ.Footer()
	Response.End()
End Sub

'========================================================
'设置缓存
'========================================================
Public Sub setCache(cacheName, cacheValue)
	Application.Lock
	Application(cacheName) = cacheValue
	Application.UnLock
End Sub

'========================================================
'随机生成长度为n的字符串
'========================================================
Public Function Rand(n)
	Dim str, length, hash, i
	str = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	length = Len(str)
	Randomize
	For i = 1 To n
		hash = hash & Mid(str, Int((length * Rnd) + 1), 1)
	Next
	Rand = hash
End Function

'========================================================
'日期格式转为UNIX时间戳
'========================================================
Public Function DatetoNum(strDateTime)
	If Not IsDate(strDateTime) Then
		DatetoNum = 0
	Else
		DatetoNum = DateDiff("s", "1970-01-01 0:00:00", strDateTime)
	End If
End Function

'========================================================
'UNIX时间戳转为日期格式
'========================================================
Public Function NumtoDate(lngSeconds)
	If IntCode(lngSeconds) = 0 Then
		NumtoDate = CDate("1970-01-01 0:00:00")
	Else
		NumtoDate = DateAdd("s", lngSeconds, "1970-01-01 0:00:00")
	End If
End Function

'========================================================
'检查数组中是否存在某个值
'========================================================
Public Function InArray(GArray, Variable)
	InArray = False

	If Len(Variable) = 0 Then
		Exit Function
	End If

	Dim n
	For n = 0 To UBound(GArray)
		If Variable = GArray(n) Then
			InArray = True
			Exit For
		End If
	Next
End Function

'========================================================
'三态
'========================================================
Function IIF(Expression, Pa, Pb)
	If Expression Then
		IIF = Pa
	Else
		IIF = Pb
	End If
End Function

'========================================================
'删除文件
'========================================================
Public Sub DeleteFile(FileName)
	If Len(FileName) = 0 Then
		Exit Sub
	End If

	On Error Resume Next
	Dim Fso
	Set Fso = CreateObject("Scripting.FileSystemObject")
	Fso.DeleteFile(Server.MapPath(FileName))
	If Err Then
		Err.Clear
		Set Fso = Nothing
	End If
	Set Fso = Nothing
End Sub

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
		.Charset = Response.CharSet
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
'根据路径检查目录，如果不存在则新建目录
'========================================================
Public Sub CheckFolder(Folder)
	Dim Fso
	Dim sParent, tFolder

	Set Fso = Server.CreateObject("Scripting.FileSystemObject")

	tFolder = Folder

	If Not InStr(tFolder, ":") > 0 Then
		tFolder = Server.MapPath(tFolder)
	End If

	sParent = Fso.GetParentFolderName(tFolder)
	
	If sParent = "" Then
		Set Fso = Nothing
		Exit Sub
	End If
	
	If Not Fso.FolderExists(sParent) Then
		Call CheckFolder(sParent)
	End If

	If Not Fso.FolderExists(tFolder) Then
		Fso.CreateFolder(tFolder)
		Fso.CreateTextFile(tFolder &"\index.html")
	End If

	Set Fso = Nothing
End Sub

'========================================================
'获取文件扩展名
'========================================================
Public Function GetFileExt(FileName)
	If Not InStr(FileName, ".") > 0 Then
		GetFileExt = ""
		Exit Function
	End If

	Dim tAry
	tAry = Split(FileName, ".")
	GetFileExt = LCase(tAry(UBound(tAry)))
End Function

'========================================================
'动态包含文件
'========================================================
Public Function Include(FileName)
	Dim strContent
	strContent = LoadFile(FileName)
	strContent = Replace(Replace(strContent, "<"&"%", ""), "%"&">", "")
	ExecuteGlobal(strContent)
End function

'========================================================
'通用分页
'========================================================
Public Sub ShowPageInfo(Page, PageCount, RecordCount, Condition)
	Dim StartPage

	If Page > PageCount - 9 And PageCount > 9 Then
		If Page - (PageCount - 9) = 1 And PageCount - 10 > 0 Then
			StartPage = PageCount - 10
		Else
			StartPage = PageCount - 9
		End If
	ElseIf (Page - 2) > 0 And PageCount > 10 Then
		StartPage = Page - 2
	Else
		StartPage = 1
	End If

	Response.Write "<div class=""pages_btns""><div class=""pages"">"

	If PageCount + 1 > Page And Page > 1 Then
		If StartPage > 1 Then
			Response.Write "<a href=""?page=1"& Condition &""" class=""iffirst"" title=""第一页"" target=""_self"">1...</a>"
		End If
		Response.Write "<a href=""?page="& Page - 1 & Condition &""" class=""prev"" title=""上一页"" target=""_self"">&lsaquo;&lsaquo;</a>"
	End If

	For i = StartPage To StartPage + 9
		If i > PageCount Then
			Exit For
		End If

		If i = Page Then
			Response.Write "<strong>"& i &"</strong>"
		Else
			Response.Write "<a href=""?page="& i & Condition &""" target=""_self"">"& i &"</a>"
		End If
	Next

	If PageCount > Page Then
		Response.Write "<a href=""?page="& Page + 1 & Condition &""" class=""next"" title=""下一页"" target=""_self"">&rsaquo;&rsaquo;</a>"
	End If

	If StartPage + 9 < PageCount Then
		Response.Write "<a href=""?page="& PageCount & Condition &""" class=""last"" title=""尾页"" target=""_self"">"& PageCount &"...</a>"
	End If

	If PageCount > 10 Then
		Response.Write "<kbd><input type=""text"" name=""gotopage"" size=""3"" onkeydown=""if(event.keyCode==13) {window.self.location='?page='+this.value+'"& Condition &"'; return false;}"" /></kbd>"
	End If

	Response.Write "</div></div>"
End Sub
%>
<script language="jscript" runat="server">
//XXTEA加密算法
var XXTEA=new function(){var delta=0x9E3779B9;function longArrayToString(data,includeLength){var length=data.length;var n=(length-1)<<2;if(includeLength){var m=data[length-1];if((m<n-3)||(m>n))return null;n=m;}for(var i=0;i<length;i++){data[i]=String.fromCharCode(data[i]&0xff,data[i]>>>8&0xff,data[i]>>>16&0xff,data[i]>>>24&0xff);}if(includeLength){return data.join('').substring(0,n);}else{return data.join('');}}function stringToLongArray(string,includeLength){var length=string.length;var result=[];for(var i=0;i<length;i+=4){result[i>>2]=string.charCodeAt(i)|string.charCodeAt(i+1)<<8|string.charCodeAt(i+2)<<16|string.charCodeAt(i+3)<<24;}if(includeLength){result[result.length]=length;}return result;}this.encrypt=function(string,key){if(string==''){return string;}var v=stringToLongArray(string,true);var k=stringToLongArray(key,false);if(k.length<4){k.length=4;}var n=v.length-1;var z=v[n],y=v[0];var mx,e,p,q=Math.floor(6+52 /(n+1)),sum=0;while(0<q--){sum=sum+delta&0xffffffff;e=sum>>>2&3;for(p=0;p<n;p++){y=v[p+1];mx=(z>>>5^y<<2)+(y>>>3^z<<4)^(sum^y)+(k[p&3^e]^z);z=v[p]=v[p]+mx&0xffffffff;}y=v[0];mx=(z>>>5^y<<2)+(y>>>3^z<<4)^(sum^y)+(k[p&3^e]^z);z=v[n]=v[n]+mx&0xffffffff;}return base64_encode(longArrayToString(v,false));};this.decrypt=function(string,key){if(string == ''){return string;}var v=stringToLongArray(base64_decode(string),false);var k=stringToLongArray(key,false);if(k.length<4){k.length=4;}var n=v.length-1;var z=v[n-1],y=v[0];var mx,e,p,q=Math.floor(6+52 /(n+1)),sum=q * delta&0xffffffff;while(sum != 0){e=sum>>>2&3;for(p=n;p > 0;p--){z=v[p-1];mx=(z>>>5^y<<2)+(y>>>3^z<<4)^(sum^y)+(k[p&3^e]^z);y=v[p]=v[p]-mx&0xffffffff;}z=v[n];mx=(z>>>5^y<<2)+(y>>>3^z<<4)^(sum^y)+(k[p&3^e]^z);y=v[0]=v[0]-mx&0xffffffff;sum=sum-delta&0xffffffff;}return longArrayToString(v,true);}}
//BASE64编码
base64_encode=function(){var base64EncodeChars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('');return function(str){var out,i,j,len,r,l,c;i=j=0;len=str.length;r=len%3;len=len-r;l=(len/3)<<2;if(r>0){l+=4}out=new Array(l);while(i<len){c=str.charCodeAt(i++)<<16|str.charCodeAt(i++)<<8|str.charCodeAt(i++);out[j++]=base64EncodeChars[c>>18]+base64EncodeChars[c>>12&0x3f]+base64EncodeChars[c>>6&0x3f]+base64EncodeChars[c&0x3f]}if(r==1){c=str.charCodeAt(i++);out[j++]=base64EncodeChars[c>>2]+base64EncodeChars[(c&0x03)<<4]+"=="}else if(r==2){c=str.charCodeAt(i++)<<8|str.charCodeAt(i++);out[j++]=base64EncodeChars[c>>10]+base64EncodeChars[c>>4&0x3f]+base64EncodeChars[(c&0x0f)<<2]+"="}return out.join('')}}();base64_decode=function(){var base64DecodeChars=[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,-1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1];return function(str){var c1,c2,c3,c4;var i,j,len,r,l,out;len=str.length;if(len%4!=0){return''}if(/[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\+\/\=]/.test(str)){return''}if(str.charAt(len-2)=='='){r=1}else if(str.charAt(len-1)=='='){r=2}else{r=0}l=len;if(r>0){l-=4}l=(l>>2)*3+r;out=new Array(l);i=j=0;while(i<len){c1=base64DecodeChars[str.charCodeAt(i++)];if(c1==-1)break;c2=base64DecodeChars[str.charCodeAt(i++)];if(c2==-1)break;out[j++]=String.fromCharCode((c1<<2)|((c2&0x30)>>4));c3=base64DecodeChars[str.charCodeAt(i++)];if(c3==-1)break;out[j++]=String.fromCharCode(((c2&0x0f)<<4)|((c3&0x3c)>>2));c4=base64DecodeChars[str.charCodeAt(i++)];if(c4==-1)break;out[j++]=String.fromCharCode(((c3&0x03)<<6)|c4)}return out.join('')}}();
//中文转码
function utf16to8(str){var out,i,j,len,c,c2;out=[];len=str.length;for(i=0,j=0;i<len;i++,j++){c=str.charCodeAt(i);if(c<=0x7f){out[j]=str.charAt(i);}else if(c<=0x7ff){out[j]=String.fromCharCode(0xc0|(c>>>6),0x80|(c&0x3f));}else if(c<0xd800||c>0xdfff){out[j]=String.fromCharCode(0xe0|(c>>>12),0x80|((c>>>6)&0x3f),0x80|(c&0x3f));}else{if(++i<len){c2=str.charCodeAt(i);if(c<=0xdbff&&0xdc00<=c2&&c2<=0xdfff){c=((c&0x03ff)<<10|(c2&0x03ff))+0x010000;if(0x010000<=c&&c<=0x10ffff){out[j]=String.fromCharCode(0xf0|((c>>>18)&0x3f),0x80|((c>>>12)&0x3f),0x80|((c>>>6)&0x3f),0x80|(c&0x3f));}else{out[j]='?';}}else{i--;out[j]='?';}}else{i--;out[j]='?';}}}return out.join('');}function utf8to16(str){var out,i,j,len,c,c2,c3,c4,s;out=[];len=str.length;i=j=0;while(i<len){c=str.charCodeAt(i++);switch(c>>4){case 0:case 1:case 2:case 3:case 4:case 5:case 6:case 7:out[j++]=str.charAt(i-1);break;case 12:case 13:c2=str.charCodeAt(i++);out[j++]=String.fromCharCode(((c&0x1f)<<6)|(c2&0x3f));break;case 14:c2=str.charCodeAt(i++);c3=str.charCodeAt(i++);out[j++]=String.fromCharCode(((c&0x0f)<<12)|((c2&0x3f)<<6)|(c3&0x3f));break;case 15:switch(c&0xf){case 0:case 1:case 2:case 3:case 4:case 5:case 6:case 7:c2=str.charCodeAt(i++);c3=str.charCodeAt(i++);c4=str.charCodeAt(i++);s=((c&0x07)<<18)|((c2&0x3f)<<12)|((c3&0x3f)<<6)|(c4&0x3f)-0x10000;if(0<=s&&s<=0xfffff){out[j]=String.fromCharCode(((s>>>10)&0x03ff)|0xd800,(s&0x03ff)|0xdc00);}else{out[j]='?';}break;case 8:case 9:case 10:case 11:i+=4;out[j]='?';break;case 12:case 13:i+=5;out[j]='?';break;}}j++;}return out.join('');}
</script>