<%
'========================================================
'类名: AnUpLoad(艾恩无组件上传类)
'作者: Anlige
'版本: 艾恩无组件上传类V9.2.09
'开发日期: 2008-4-12
'修改日期: 2009-4-10
'作者主页: http://www.ii-home.cn
'Email: zhanghuiguoanlige@126.com
'QQ: 417833272
'========================================================
Dim StreamG, SpecialFileExt

SpecialFileExt = "ad,adprotot,asa,asax,ascx,asxh,asmx,asp,aspx,axd,browser,cd,cdx,cer,compiled,config,cs,csproj,dd,execlude,idc,java,jsl,ldb,ldd,lddprototype,ldf,licx,master,mdb,mdf,msgx,mde,php,php3,refresh,rem,resources,resx,sd,sdm,sdmdocument,shtm,shtml,sitemap,skin,soap,stm,svc,vb,vbproj,vjsproj,vsdisco,webinfo"

Class AnUpLoad
	Public Form
	Private Fils
	Private vCharSet, vMaxSize, vSingleSize, vErr, vVersion, vTotalSize, vAllowedExt

	'========================================================
	'设置和读取属性开始
	'========================================================
	Public Property Let MaxSize(ByVal Value)
		vMaxSize = Value
	End Property

	Public Property Let SingleSize(ByVal Value)
		vSingleSize = Value
	End Property

	Public Property Let AllowedExt(ByVal Value)
		vAllowedExt = LCase(Value)
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

	'========================================================
	'设置和读取属性结束，初始化类
	'========================================================
	Private Sub Class_Initialize()
		Set StreamG = Server.CreateObject("ADODB.Stream")
		Set Form = Server.CreateObject("Scripting.Dictionary")
		Set Fils = Server.CreateObject("Scripting.Dictionary")
		vVersion = "艾恩无组件上传类V9.4.10"
		vMaxSize = -1
		vSingleSize = -1
		vErr = -1
		vAllowedExt = ""
		vTotalSize = 0
		vCharSet = Response.Charset
	End Sub

	'========================================================
	'类结束，销毁对象
	'========================================================
	Private Sub Class_Terminate()
		Set Form = Nothing
		Set Fils = Nothing
		Set StreamG = Nothing
	End Sub

	'========================================================
	'处理客户端提交来的所有数据
	'========================================================
	Public Sub GetData()
		Dim Value, Str, bcrlf, fpos, sSplit, slen, istart
		Dim TotalBytes, BytesRead, ChunkReadSize, PartSize, DataPart, tempdata, formend, formhead, startpos, endpos
		Dim FormName, FileName, FileMime, FileExt, valueend, localname

		If CheckEntryType Then
			vTotalSize = 0
			StreamG.Type = 1
			StreamG.Mode = 3
			StreamG.Open
			TotalBytes = Request.TotalBytes
			vTotalSize = TotalBytes
			BytesRead = 0
			ChunkReadSize = 102400
			'循环分块读取
			Do While BytesRead < TotalBytes
				'分块读取
				PartSize = ChunkReadSize
				If PartSize + BytesRead > TotalBytes Then
					PartSize = TotalBytes - BytesRead
				End If
				DataPart = Request.BinaryRead(PartSize)
				StreamG.Write DataPart
				BytesRead = BytesRead + PartSize
			Loop
			StreamG.Position = 0
			tempdata = StreamG.Read
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
				FormName = LCase(Mid(Str, startpos, endpos - startpos))
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
						FileExt = GetFileExt(FileName)

						'判断扩展名
						If vAllowedExt <> "" Then
							If Not InArray(Split(vAllowedExt, ","), FileExt) Then
								vErr = 3
								Exit Sub
							End If
						End If

						If Len(FileExt) = 0 Or InStr(","& SpecialFileExt &",", ","& FileExt &",") > 0 Then
							FileExt = "attach"
						End If

						'判断上传单个文件大小
						If vSingleSize > 0 And (valueend - formend - 6) > vSingleSize Then
							vErr = 5
							Exit Sub
						End If

						'判断上传数据总大小
						If vMaxSize > 0 And vTotalSize > vMaxSize Then
							vErr = 1
							Exit Sub
						End If

						If Fils.Exists(FormName) Then
							vErr = 4
							Exit Sub
						Else
							Dim fileCls
							Set fileCls = New File
							fileCls.Size = (valueend - formend - 6)
							fileCls.Position = (formend + 3)
							fileCls.LocalName = FileName
							fileCls.Ext = FileExt
							fileCls.Mime = FileMime
							fileCls.IfImage = IIF(InArray(Array("jpg", "jpeg", "png", "gif", "bmp"), FileExt), 1, 0)
							Fils.Add FormName, fileCls
							Form.Add FormName, LocalName
							Set fileCls = Nothing
						End If
					End If
				Else
					Value = MidB(tempdata, formend + 4, valueend - formend - 6)
					If Form.Exists(FormName) Then
						Form(FormName) = Form(FormName) & "," & Bytes2Str(Value)
					Else
						Form.Add FormName, Bytes2Str(Value)
					End If
				End If
				istart = valueend + 2 + slen
			Loop Until (istart + 2) >= LenB(tempdata)
			vErr = 0
		Else
			vErr = 2
		End If
	End Sub

	'========================================================
	'二进制数据转换为字符
	'========================================================
	Private Function Bytes2Str(ByVal byt)
		If LenB(byt) = 0 Then
			Bytes2Str = ""
			Exit Function
		End If

		Dim Stream, bstr
		Set Stream = Server.CreateObject("ADODB.Stream")
		Stream.Type = 2
		Stream.Mode = 3
		Stream.Open
		Stream.WriteText byt
		Stream.Position = 0
		Stream.CharSet = vCharSet
		Stream.Position = 2
		bstr = Stream.ReadText()
		Stream.Close
		Set Stream = Nothing
		Bytes2Str = bstr
	End Function

	'========================================================
	'获取错误描述
	'========================================================
	Private Function GetErr(ByVal Num)
		Select Case Num
			Case 0
				GetErr = "数据处理完毕!"
			Case 1
				GetErr = "上传数据超过限制!可设置MaxSize属性来改变限制!"
			Case 2
				GetErr = "未设置上传表单enctype属性为multipart/form-data或者未设置method属性为Post,上传无效!"
			Case 3
				GetErr = "含有非法扩展名文件!只能上传扩展名为" & vAllowedExt & "的文件"
			Case 4
				GetErr = "对不起,程序不允许使用相同name属性的文件域!"
			Case 5
				GetErr = "单个文件大小超出上传限制!"
		End Select
	End Function

	'========================================================
	'检测上传类型是否为multipart/form-data
	'========================================================
	Private Function CheckEntryType()
		Dim ContentType, ctArray, bArray, RequestMethod
		RequestMethod = Trim(LCase(Request.ServerVariables("REQUEST_METHOD")))
		If RequestMethod = "" Or RequestMethod <> "post" Then
			CheckEntryType = False
			Exit Function
		End If
		ContentType = LCase(Request.ServerVariables("HTTP_CONTENT_TYPE"))
		ctArray = Split(ContentType, ";")
		If UBound(ctarray) >= 0 Then
			If Trim(ctArray(0)) = "multipart/form-data" Then
				CheckEntryType = True
			Else
				CheckEntryType = False
			End If
		Else
			CheckEntryType = False
		End If
	End Function

	'========================================================
	'获取上传表单值,参数可选,如果为-1则返回一个包含所有表单项的一个dictionary对象
	'========================================================
	Public Function Forms(ByVal FormName)
		If Trim(FormName) = "-1" Then
			Set Forms = Form
		Else
			If Form.Exists(LCase(FormName)) Then
				Forms = Form(LCase(FormName))
			Else
				Forms = ""
			End If
		End If
	End Function

	'========================================================
	'获取上传的文件类,参数可选,如果为-1则返回一个包含所有上传文件类的一个dictionary对象
	'========================================================
	Public Function Files(ByVal FormName)
		If Trim(FormName) = "-1" Then
			Set Files = Fils
		Else
			If Fils.Exists(LCase(FormName)) Then
				Set Files = Fils(LCase(FormName))
			Else
				Set Files = Nothing
			End If
		End If
	End Function
End Class

'========================================================
'文件类,存储文件的详细信息
'========================================================
Class File
	Private vSize, vPosition, vName, vLocalName
	Public Ext, Mime, IfImage, IfThumb

	'========================================================
	'设置属性
	'========================================================
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

	'========================================================
	'根据参数保存文件到服务器
	'========================================================
	Public Function SaveToFile(ByVal Path)
		If InStr(","& SpecialFileExt &",", ","& GetFileExt(Path) &",") > 0 Then
			Response.Status = 500
			Response.End()
		End If

		On Error Resume Next

		Dim Stream
		Set Stream = Server.CreateObject("ADODB.Stream")
		Stream.Type = 1
		Stream.Mode = 3
		Stream.Open
		StreamG.Position = vPosition
		StreamG.CopyTo Stream, vSize
		Stream.SaveToFile Server.MapPath(Path), 2
		If Err Then
			'如果目录不存在则重建目录
			If Err.Number = 3004 Then
				Call CheckFolder(GetFileFolder(Path))
				Err.Clear
			End If

			Stream.SaveToFile Server.MapPath(Path), 2
			
			If Err Then
				SaveToFile = False
			Else
				SaveToFile = True
			End If

			Err.Clear
		Else
			SaveToFile = True
		End If

		Stream.Close
		Set Stream = Nothing

		'生成缩略图
		IfThumb = 0
		If SaveToFile And IfImage = 1 And RQ.Attach_Settings(3) = "1" Then
			Call Thumb(Path)
		End If
	End Function

	'========================================================
	'缩略图处理
	'========================================================
	Private Sub Thumb(Path)
		On Error Resume Next

		Dim Img
		Set Img = New Image
		Img.PicBin = GetBytes()
		Img.ThumbSavePath = Path &".thumb."& Ext
		Img.ThumbWidth = CLng(RQ.Attach_Settings(4))
		Img.ThumbHeight = CLng(RQ.Attach_Settings(5))
		Img.ReizeOption = CLng(RQ.Attach_Settings(6))
		Img.JpegQuality = CLng(RQ.Attach_Settings(7))
		Img.ResizeImage()
		IfThumb = IIF(Img.blnCancelProcess, 0, 1)
		Set Img = Nothing

		Err.Clear
	End Sub

	'========================================================
	'获取文件的二进制形式
	'========================================================
	Public Function GetBytes()
		StreamG.Position = vPosition
		GetBytes = StreamG.Read(vSize)
	End Function

	'========================================================
	'根据文件完整保持路径获取目录路径
	'========================================================
	Public Function GetFileFolder(Path)
		Dim tAry
		tAry = Split(Path, "/")
		GetFileFolder = Replace(Path, tAry(UBound(tAry)), "")
	End Function
End Class

'========================================================
'图像处理类
'========================================================
Class Image
	Public PicURL, PicBin, ThumbWidth, ThumbHeight, ImgOrgWidth, ImgOrgHeight
	Public ReizeOption, BackGround, JpegQuality, ThumbSavePath, blnCancelProcess
	Private CropThumbWidth, CropThumbHeight, blnFillCanvas
	Private ary, Jpeg

	'========================================================
	'类初始化
	'========================================================
	Private Sub Class_Initialize()
		On Error Resume Next
		Set Jpeg = Server.Createobject("Persits.Jpeg")

		'缩图设置，0：直接缩图；1：切图；2：缩图并遵循指定的比率，不够的地方用空白填充
		ReizeOption = 0
		JpegQuality = 95
		BackGround = &HFFFFFF
	End Sub

	'========================================================
	'类结束
	'========================================================
	Private Sub Class_Terminate()
		Set Jpeg = Nothing
	End Sub

	'========================================================
	'缩图
	'========================================================
	Public Sub ResizeImage()
		'读取图片信息
		Call GetImageInfo()

		'根据设置计算缩图宽高以及裁切位置
		ary = SizeValue()

		'如果原图宽高小于指定大小则放弃处理
		If blnCancelProcess Then
			Exit Sub
		End If

		If ReizeOption < 0 Or ReizeOption > 2 Then
			ReizeOption = 0
		End If

		'输出图片质量
		Jpeg.Quality = JpegQuality

		'输出图片锐化
		'Jpeg.Sharpen 1, 101

		If ReizeOption = 0 Or ReizeOption = 2 Then
			Jpeg.Width = ary(2)
			Jpeg.Height = ary(3)

			If ReizeOption = 2 Then
				Call FillCanvas()
			Else
				Jpeg.Save Server.MapPath(ThumbSavePath)
			End If
		Else
			If CropThumbWidth > 0 And CropThumbHeight > 0 Then
				Jpeg.Width = CropThumbWidth
				Jpeg.Height = CropThumbHeight
			End If

			Jpeg.Crop ary(0), ary(1), ary(2), ary(3)

			If blnFillCanvas Then
				Call FillCanvas()
			Else
				Jpeg.Save Server.MapPath(ThumbSavePath)
			End If
		End If
	End Sub

	'========================================================
	'生成缩略图大小的画布并让图片填充进去
	'========================================================
	Private Sub FillCanvas()
		Dim JpegCopy
		Set JpegCopy = Server.CreateObject("Persits.Jpeg")
		JpegCopy.Quality = JpegQuality
		JpegCopy.New ThumbWidth, ThumbHeight, BackGround
		JpegCopy.Canvas.DrawImage (ThumbWidth - ary(2)) / 2, (ThumbHeight - ary(3)) / 2, Jpeg
		JpegCopy.Save Server.MapPath(ThumbSavePath)
		Set JpegCopy = Nothing
	End Sub

	'========================================================
	'读取图片信息
	'========================================================
	Public Sub GetImageInfo()
		If Len(PicURL) > 0 Then
			Jpeg.Open Server.MapPath(PicURL)
		Else
			Jpeg.OpenBinary(PicBin)
			PicBin = Null
		End If
		ImgOrgWidth = CLng(Jpeg.OriginalWidth)
		ImgOrgHeight = CLng(Jpeg.OriginalHeight)
	End Sub

	'========================================================
	'缩图计算
	'========================================================
	Private Function SizeValue()
		Dim x, y, w, h
		Dim x_Ratio, y_Ratio
		x = 0
		y = 0
		w = 0
		h = 0
		If ReizeOption = 1 Then
			If ImgOrgWidth <= ThumbWidth Or ImgOrgHeight <= ThumbHeight Then
				If ImgOrgWidth <= ThumbWidth And ImgOrgHeight <= ThumbHeight Then
					'宽高都小于指定大小则不处理
					blnCancelProcess = True
					'w = ImgOrgWidth
					'h = ImgOrgHeight
					'宽高都不够那么就用空白填充画布
					'blnFillCanvas = True
				Else
					If ImgOrgWidth <= ThumbWidth Then
						y = ABS(Int(-(ImgOrgHeight - ThumbHeight) / 2))
						w = ImgOrgWidth
						h = y + ThumbHeight
					Else
						x = ABS(Int(-(ImgOrgWidth - ThumbWidth) / 2))
						w = x + ThumbWidth
						h = ImgOrgHeight
					End If
				End If
			Else
				x_Ratio = ThumbWidth / ImgOrgWidth
				y_Ratio = ThumbHeight / ImgOrgHeight

				If x_Ratio < y_Ratio Then
					CropThumbWidth = ImgOrgWidth * y_Ratio
					CropThumbHeight = ImgOrgHeight * y_Ratio
					x = ABS(Int(-(CropThumbWidth - ThumbWidth) / 2))
					w = x + ThumbWidth
					h = ThumbHeight
				Else
					CropThumbWidth = ImgOrgWidth * x_Ratio
					CropThumbHeight = ImgOrgHeight * x_Ratio
					y = ABS(Int(-(CropThumbHeight - ThumbHeight) / 2))
					w = ThumbWidth
					h = y + ThumbHeight
				End If
			End If
		Else
			If ImgOrgWidth > ThumbWidth Or ImgOrgHeight > ThumbHeight Then
				x_Ratio = ThumbWidth / ImgOrgWidth
				y_Ratio = ThumbHeight / ImgOrgHeight
				If x_Ratio * ImgOrgHeight < ThumbHeight Then
					h = ABS(Int(-x_Ratio * ImgOrgHeight))
					w = ThumbWidth
				Else
					w = ABS(Int(-y_Ratio * ImgOrgWidth))
					h = ThumbHeight
				End If
			Else
				'宽高都小与指定大小则不处理
				blnCancelProcess = True
				'w = ImgOrgWidth
				'h = ImgOrgHeight
			End If
		End If

		SizeValue = Array(x, y, w, h)
	End Function
End Class
%>
