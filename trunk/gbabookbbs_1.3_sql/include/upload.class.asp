<%
'=========================================================
'类名: AnUpLoad(艾恩无组件上传类)
'作者: Anlige
'版本: 艾恩无组件上传类V9.2.09
'开发日期: 2008-4-12
'修改日期: 2009-4-10
'作者主页: http://www.ii-home.cn
'Email: zhanghuiguoanlige@126.com
'QQ: 417833272
'=========================================================
Dim StreamT, SpecialFileExt
SpecialFileExt = "ad,adprotot,asa,asax,ascx,asxh,asmx,asp,aspx,axd,browser,cd,cdx,cer,compiled,config,cs,csproj,dd,execlude,idc,java,jsl,ldb,ldd,lddprototype,ldf,licx,master,mdb,mdf,msgx,mde,php,php3,refresh,rem,resources,resx,sd,sdm,sdmdocument,shtm,shtml,sitemap,skin,soap,stm,svc,vb,vbproj,vjsproj,vsdisco,webinfo"

Class AnUpLoad
	Public Form
	Private Fils
	Private vCharSet, vMaxSize, vSingleSize, vErr, vVersion, vTotalSize, vExe

	'==============================
	'设置和读取属性开始
	'==============================
	Public Property Let MaxSize(ByVal Value)
		vMaxSize = Value
	End Property

	Public Property Let SingleSize(ByVal Value)
		vSingleSize = Value
	End Property

	Public Property Let Exe(ByVal Value)
		vExe = LCase(Value)
	End Property

	Public Property Let CharSet(ByVal Value)
		vCharSet = Value
	End Property

	Public Property Get ErrorID()
		ErrorID = vErr
	End Property

	Public Property Get Description()
		Description = GetErr(vErr)
	End Property

	Public Property Get Version()
		Version = vVersion
	End Property

	Public Property Get TotalSize()
		TotalSize = vTotalSize
	End Property

	'==============================
	'设置和读取属性结束，初始化类
	'==============================
	Private Sub Class_Initialize()
		Set StreamT = server.CreateObject("ADODB.STREAM")
		Set Form = server.CreateObject("Scripting.Dictionary")
		Set Fils = server.CreateObject("Scripting.Dictionary")
		vVersion = "艾恩无组件上传类V9.4.10"
		vMaxSize = -1
		vSingleSize = -1
		vErr = -1
		vExe = ""
		vTotalSize = 0
		vCharSet = "utf-8"
	End Sub

	Private Sub Class_Terminate()
		Set Form = Nothing
		Set Fils = Nothing
		Set StreamT = Nothing
	End Sub

	'==============================
	'函数名:GetData
	'作用:处理客户端提交来的所有数据
	'==============================
	Public Sub GetData()
		Dim Value, Str, bcrlf, fpos, sSplit, slen, istart
		Dim TotalBytes, BytesRead, ChunkReadSize, PartSize, DataPart, tempdata, formend, formhead, startpos, endpos, formname, FileName, FileMime, fileExe, valueend, localname
		If checkEntryType = True Then
			vTotalSize = 0
			StreamT.Type = 1
			StreamT.Mode = 3
			StreamT.Open
			TotalBytes = Request.TotalBytes
			vTotalSize = TotalBytes
			BytesRead = 0
			ChunkReadSize = 102400
			'循环分块读取
			Do While BytesRead < TotalBytes
				'分块读取
				PartSize = ChunkReadSize
				If PartSize + BytesRead > TotalBytes Then PartSize = TotalBytes - BytesRead
				DataPart = Request.BinaryRead(PartSize)
				StreamT.Write DataPart
				BytesRead = BytesRead + PartSize
			Loop
			StreamT.Position = 0
			tempdata = StreamT.Read
			bcrlf = ChrB(13) & ChrB(10)
			fpos = InStrB(1, tempdata, bcrlf)
			sSplit = MidB(tempdata, 1, fpos - 1)
			slen = LenB(sSplit)
			istart = slen + 2
			Do
				formend = InStrB(istart, tempdata, bcrlf & bcrlf)
				formhead = MidB(tempdata, istart, formend - istart)
				Str = Bytes2Str(formhead)
				startpos = InStr(Str, "name=""") + 6
				endpos = InStr(startpos, Str, """")
				formname = LCase(Mid(Str, startpos, endpos - startpos))
				valueend = InStrB(formend + 3, tempdata, sSplit)
				If InStr(Str, "filename=""") > 0 Then
					startpos = InStr(Str, "filename=""") + 10
					endpos = InStr(startpos, Str, """")
					FileName = strFilter(Mid(Str, startpos, endpos - startpos))
					FileMime = strFilter(Mid(Str, InStr(Str, "Content-Type: ") + 14))
					If Len(FileName) > 0 Then
						LocalName = FileName
						FileName = Replace(FileName, "/", "\")
						FileName = Mid(FileName, InStrRev(FileName, "\") + 1)
						fileExe = LCase(Split(FileName, ".")(UBound(Split(FileName, "."))))
						If vExe <> "" Then '判断扩展名
							If checkExe(vExe, fileExe) = True Then
								vErr = 3
								Exit Sub
							End If
						End If
						'vTotalSize = vTotalSize + valueend - formend - 6
						If vSingleSize > 0 And (valueend - formend - 6) > vSingleSize Then '判断上传单个文件大小
							vErr = 5
							Exit Sub
						End If
						If vMaxSize > 0 And vTotalSize > vMaxSize Then '判断上传数据总大小
							vErr = 1
							Exit Sub
						End If
						If Fils.Exists(formname) Then
							vErr = 4
							Exit Sub
						Else
							Dim fileCls
							Set fileCls = New fileAction
							fileCls.Size = (valueend - formend - 6)
							fileCls.Position = (formend + 3)
							fileCls.LocalName = FileName
							fileCls.Ext = FileExe
							fileCls.Mime = FileMime
							Fils.Add formname, fileCls
							Form.Add formname, LocalName
							Set fileCls = Nothing
						End If
					End If
				Else
					Value = MidB(tempdata, formend + 4, valueend - formend - 6)
					If Form.Exists(formname) Then
						Form(formname) = Form(formname) & "," & Bytes2Str(Value)
					Else
						Form.Add formname, Bytes2Str(Value)
					End If
				End If
				istart = valueend + 2 + slen
			Loop Until (istart + 2) >= LenB(tempdata)
			vErr = 0
		Else
			vErr = 2
		End If
	End Sub

	'==============================
	'把数字转换为文件大小显示方式
	'==============================
	Public Function GetSize(ByVal Size)
		If Size < 1024 Then
			GetSize = FormatNumber(Size, 2) & "B"
		ElseIf Size >= 1024 And Size < 1048576 Then
			GetSize = FormatNumber(Size / 1024, 2) & "KB"
		ElseIf Size >= 1048576 Then
			GetSize = FormatNumber((Size / 1024) / 1024, 2) & "MB"
		End If
	End Function

	'==============================
	'二进制数据转换为字符
	'==============================
	Private Function Bytes2Str(ByVal byt)
		If LenB(byt) = 0 Then
			Bytes2Str = ""
			Exit Function
		End If
		Dim mystream, bstr
		Set mystream = server.CreateObject("ADODB.Stream")
		mystream.Type = 2
		mystream.Mode = 3
		mystream.Open
		mystream.WriteText byt
		mystream.Position = 0
		mystream.CharSet = vCharSet
		mystream.Position = 2
		bstr = mystream.ReadText()
		mystream.Close
		Set mystream = Nothing
		Bytes2Str = bstr
	End Function

	'==============================
	'获取错误描述
	'==============================
	Private Function GetErr(ByVal Num)
		Select Case Num
			Case 0
				GetErr = "数据处理完毕!"
			Case 1
				GetErr = "上传数据超过" & GetSize(vMaxSize) & "限制!可设置MaxSize属性来改变限制!"
			Case 2
				GetErr = "未设置上传表单enctype属性为multipart/form-data或者未设置method属性为Post,上传无效!"
			Case 3
				GetErr = "含有非法扩展名文件!只能上传扩展名为" & vExe & "的文件"
			Case 4
				GetErr = "对不起,程序不允许使用相同name属性的文件域!"
			Case 5
				GetErr = "单个文件大小超出" & GetSize(vSingleSize) & "的上传限制!"
		End Select
	End Function

	'==============================
	'检测上传类型是否为multipart/form-data
	'==============================
	Private Function checkEntryType()
		Dim ContentType, ctArray, bArray, RequestMethod
		RequestMethod = Trim(LCase(Request.ServerVariables("REQUEST_METHOD")))
		If RequestMethod = "" Or RequestMethod<>"post" Then
			checkEntryType = False
			Exit Function
		End If
		ContentType = LCase(Request.ServerVariables("HTTP_CONTENT_TYPE"))
		ctArray = Split(ContentType, ";")
		If UBound(ctarray)>= 0 Then
			If Trim(ctArray(0)) = "multipart/form-data" Then
				checkEntryType = True
			Else
				checkEntryType = False
			End If
		Else
			checkEntryType = False
		End If
	End Function

	'==============================
	'获取上传表单值,参数可选,如果为-1则返回一个包含所有表单项的一个dictionary对象
	'==============================
	Public Function Forms(ByVal formname)
		If Trim(formname) = "-1" Then
			Set Forms = Form
		Else
			If Form.Exists(LCase(formname)) Then
				Forms = Form(LCase(formname))
			Else
				Forms = ""
			End If
		End If
	End Function

	'==============================
	'获取上传的文件类,参数可选,如果为-1则返回一个包含所有上传文件类的一个dictionary对象
	'==============================
	Public Function Files(ByVal formname)
		If Trim(formname) = "-1" Then
			Set Files = Fils
		Else
			If Fils.Exists(LCase(formname)) Then
				Set Files = Fils(LCase(formname))
			Else
				Set Files = Nothing
			End If
		End If
	End Function
End Class

'==============================
'文件类,存储文件的详细信息
'==============================

Class fileAction
	Private vSize, vPosition, vName, vLocalName
	Public Ext, Mime
	'==============================
	'设置属性
	'==============================
	Public Property Let LocalName(ByVal Value)
		vLocalName = Value
		vName = Value
	End Property

	Public Property Get LocalName()
		LocalName = vLocalName
	End Property

	Public Property Get FileName()
		FileName = vName
	End Property

	Public Property Let Position(ByVal Value)
		vPosition = Value
	End Property

	Public Property Let Size(ByVal Value)
		vSize = Value
	End Property

	Public Property Get Size()
		Size = vSize
	End Property

	'==============================
	'函数名:SaveToFile
	'作用:根据参数保存文件到服务器
	'参数:参数1--文件保存的路径
	'==============================
	Public Function SaveToFile(ByVal Path)
		If InStr(","& SpecialFileExt &",", ","& LCase(Split(Path, ".")(UBound(Split(Path, ".")))) &",") > 0 Then
			Response.Status = 500
			Response.End()
		End If

		On Error Resume Next

		Dim mystream
		Set mystream = server.CreateObject("ADODB.Stream")
		mystream.Type = 1
		mystream.Mode = 3
		mystream.Open
		StreamT.Position = vPosition
		StreamT.CopyTo mystream, vSize
		mystream.SaveToFile Server.MapPath(Path), 2
		If Err Then
			'如果目录不存在则重建目录
			If Err.Number = 3004 Then
				Call RebuildFolder(Path)
				Err.Clear
			End If
			mystream.SaveToFile Server.MapPath(Path), 2
			If Err Then
				SaveToFile = False
			Else
				SaveToFile = True
			End If
		Else
			SaveToFile = True
		End If
		mystream.Close
		Set mystream = Nothing
	End Function

	'==============================
	'函数名:GetBytes
	'作用:获取文件的二进制形式
	'参数:无
	'==============================
	Public Function GetBytes()
		StreamT.Position = vPosition
		GetBytes = StreamT.Read(vSize)
	End Function
End Class

'==============================
'判断扩展名
'==============================
Public Function checkExe(vExe, ex)
	Dim notIn
	notIn = True
	If InStr(1, vExe, ",") > 0 Then
		Dim tempExe
		tempExe = Split(vExe, ",")
		If InArray(tempExe, ex) Then
			notIn = False
		End If
	Else
		If LCase(vExe) = ex Then
			notIn = False
		End If
	End If
	checkExe = notIn
End Function

'========================================================
'根据路径检查目录，如果不存在则新建目录
'========================================================
Public Sub RebuildFolder(FullPath)
	If FullPath = "/" Then
		Exit Sub
	End If

	Dim Fso, Folder, Content, n
	Set Fso = CreateObject("Scripting.FileSystemObject")

	Folder = FullPath
	If Right(FullPath, 1) <> "/" Then 
		Folder = Left(FullPath, InstrRev(FullPath, "/") - 1)
	End If

	Folder = Split(Folder, "/")
	Content = IIF(Left(FullPath, 1) = "/", "/", "")

	For n = 0 To UBound(Folder)
		If Len(Folder(n)) > 0 Then
			Content = Content & Folder(n) &"/"
			If Not Fso.FolderExists(Server.MapPath(Content)) Then
				Fso.CreateFolder(Server.MapPath(Content))
			End If
		End If
	Next
	Set Fso = Nothing
End Sub
%>
