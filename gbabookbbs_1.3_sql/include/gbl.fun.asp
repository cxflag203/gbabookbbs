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
	Dim sParent

	Set Fso = Server.CreateObject("Scripting.FileSystemObject")

	If Not InStr(Folder, ":") > 0 Then
		Folder = Server.MapPath(Folder)
	End If

	sParent = Fso.GetParentFolderName(Folder)
	
	If sParent = "" Then
		Set Fso = Nothing
		Exit Sub
	End If
	
	If Not Fso.FolderExists(sParent) Then
		Call CheckFolder(sParent)
	End If

	If Not Fso.FolderExists(Folder) Then
		Fso.CreateFolder(Folder)
		Fso.CreateTextFile(Folder &"\index.html")
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

'========================================================
'COOKIE编码
'========================================================
Function CookieCode(str, Action)
	Dim Prand, sPos, Mult, Incr, Modu, chrEnc, strEnc
	Dim i

	For i = 1 To Len(PrivateKey)
		Prand = Prand & Asc(Mid(PrivateKey, i, 1))
	Next

	sPos = Int(Len(Prand) / 5)
	Mult = CLng(Mid(Prand, sPos + 1, 1) + Mid(Prand, (sPos * 2) + 1, 1) + Mid(Prand, (sPos * 3) + 1, 1) + Mid(Prand, (sPos * 4) + 1, 1) + Mid(Prand, (sPos * 5) + 1, 1))
	Incr = ABS(Int(-(Len(PrivateKey) / 2)))
	Modu = 2 ^ 31 - 1

	If Mult < 2 Then
		Exit Function
	End If

	While Len(Prand) > 10
		Prand = CDbl(Mid(Prand, 1, 10)) + CDbl(Mid(Prand, 11, Len(Prand)))
	Wend

	Prand = (Mult * Prand + Incr) - Int((Mult * Prand + Incr) / Modu) * Modu

	If Action = "DECODE" Then
		For i = 1 To Len(str) Step 2
			chrEnc = CLng(Hex2Clng("&H"& Mid(str, i, 2)) Xor Int((Prand / Modu) * 255))
			strEnc = strEnc & Chr(chrEnc)
			Prand = (Mult * Prand + Incr) - Int((Mult * Prand + Incr) / Modu) * Modu
		Next
	Else
		For i = 1 To Len(str)
			chrEnc = CLng(Asc(Mid(str, i, 1)) Xor Int((Prand / Modu) * 255))
			If chrEnc < 16 Then
				strEnc = strEnc &"0"& Hex(chrEnc)
			Else
				strEnc = strEnc & Hex(chrEnc)
			End If
			Prand = (Mult * Prand + Incr) - Int((Mult * Prand + Incr) / Modu) * Modu
		Next
	End If

	CookieCode = strEnc
End Function

'========================================================
'十六进制转十进制
'========================================================
Function Hex2Clng(strHex)
	On Error Resume Next
	Dim n
	n = CLng(strHex)

	If Err Then
		n = 0
	End If

	Hex2Clng = n
End Function
%>