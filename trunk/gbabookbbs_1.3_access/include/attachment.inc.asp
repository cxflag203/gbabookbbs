<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

'========================================================
'读取附件并把数据集合放到数组中
'========================================================
Sub ReadAttachments()
	Dim AttachListArray
	'读取附件
	AttachListArray = RQ.Query("SELECT aid, pid, filename, filesize, savepath, downloads, ifimage, description, posttime FROM "& TablePre &"attachments WHERE tid = "& RQ.TopicID)

	'建立字典对象
	Set Dic = Server.CreateObject("Scripting.Dictionary")

	'设置正则表达式对象
	Set regExpSearch = New Regexp
	regExpSearch.IgnoreCase = True
	regExpSearch.Global = True
	regExpSearch.Pattern = "\[attach\](\d+)\[\/attach\]"

	If IsArray(AttachListArray) Then
		For i = 0 To UBound(AttachListArray, 2)
			'根据aid来分组把附件加入字典
			Call Dic.Add("a"& AttachListArray(0, i), ShowAttachInPost(AttachListArray(0, i), AttachListArray(2, i), AttachListArray(3, i), AttachListArray(4, i), AttachListArray(5, i), AttachListArray(6, i), AttachListArray(7, i), AttachListArray(8, i), True))

			'根据pid来分组把附件加入字典
			If Dic.Exists(AttachListArray(1, i)) Then
				Dic.Item(AttachListArray(1, i)) = Dic.Item(AttachListArray(1, i)) & ShowAttachInPost(AttachListArray(0, i), AttachListArray(2, i), AttachListArray(3, i), AttachListArray(4, i), AttachListArray(5, i), AttachListArray(6, i), AttachListArray(7, i), AttachListArray(8, i), False)
			Else
				Call Dic.Add(AttachListArray(1, i), ShowAttachInPost(AttachListArray(0, i), AttachListArray(2, i), AttachListArray(3, i), AttachListArray(4, i), AttachListArray(5, i), AttachListArray(6, i), AttachListArray(7, i), AttachListArray(8, i), False))
			End If
		Next
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET ifattachment = 0 WHERE tid = "& RQ.TopicID)
		RQ.Execute("UPDATE "& TablePre &"posts SET ifattachment = 0 WHERE tid = "& RQ.TopicID &" AND ifattachment = 1")
	End If
End Sub

'========================================================
'把附件内容放到帖子内容中
'========================================================
Function ShowAttachments(PostID, PostMessage)
	Dim AttachInPost, strAttachList, n

	'验证查看附件的权限
	If RQ.AllowGetAttach Then
		'读取所有属于该回复的附件
		strAttachList = Dic.Item(PostID)

		'读取插入到内容中的附件
		AttachInPost = SearchAttachInPost(PostMessage)

		If Len(AttachInPost) > 0 Then
			AttachInPost = Left(AttachInPost, Len(AttachInPost) - 1)
			AttachInPost = Split(AttachInPost, ",")
			For n = 0 To UBound(AttachInPost)
				PostMessage = Replace(PostMessage, "[attach]"& AttachInPost(n) &"[/attach]", Dic("a"& AttachInPost(n)))
				strAttachList = Preg_Replace(strAttachList, "<dl class=""t_attachlist"" id="""& AttachInPost(n) &""">(.*?)</dl>", "")
			Next
		End If
		ShowAttachments = PostMessage & IIF(Len(strAttachList) > 0, "<div class=""showattachlist"">"& strAttachList &"</div>", "")
		strAttachList = Empty
	Else
		PostMessage = regExpSearch.Replace(PostMessage, "")
		ShowAttachments = PostMessage &"<div class=""viewdenied"" style=""width: 300px;"">您当前的身份（"& RQ.UserGroupName &"）还不能查看附件。</div>"
	End If
End Function

'========================================================
'根据附件在帖子里的状态来显示附件
'========================================================
Function ShowAttachInPost(AttachID, FileName, FileSize, SavePath, Downloads, IfImage, Description, PostTime, InPost)
	Dim FileExt
	If InStr(FileName, ".") > 0 Then
		FileExt = LCase(Right(FileName, Len(FileName) - InstrRev(FileName, ".")))
	End If

	If IfImage = 0 Then
		If InPost Then
			If FileExt = "mp3" Then
				ShowAttachInPost = "<embed wmode=""transparent"" menu=""false"" type=""application/x-shockwave-flash"" quality=""high"" height=""24"" width=""290"" src=""js/player.swf?bg=0xCDDFF3&leftbg=0x357DCE&lefticon=0xF2F2F2&rightbg=0xF06A51&rightbghover=0xAF2910&righticon=0xF2F2F2&righticonhover=0xFFFFFF&text=0x357DCE&slider=0x357DCE&track=0xFFFFFF&border=0xFFFFFF&loader=0xAF2910&soundFile="& Server.URLEncode("attachments/"& SavePath) &"""></embed>"
			Else
				ShowAttachInPost = "<img src=""images/attachicons/"& ShowFileType(FileExt) &""" align=""absmiddle"" />&nbsp;<a href=""attachment.asp?action=get&aid="& AttachID &""" class=""underline"" target=""_blank"">"& FileName &"</a>"
			End If
		Else
			ShowAttachInPost = "<dl class=""t_attachlist"" id="""& AttachID &"""><dt><img src=""images/attachicons/"& ShowFileType(FileExt) &""" />&nbsp;<a href=""attachment.asp?action=get&aid="& AttachID &""" class=""underline"" target=""_blank"">"& FileName &"</a><em>("& ShowFileSize(FileSize) &")</em></dt><dd><p>"& PostTime &"，下载次数: "& Downloads &"</p>"& IIF(Len(Description) > 0, "<p>"& Description &"</p>", "") &"</dd></dl>"
		End If
	Else
		If InPost Then
			ShowAttachInPost = "<a href=""attachments/"& SavePath &""" target=""_blank""><img src=""attachments/"& SavePath &""" alt="""& Description &""" onload=""if(this.width>document.body.clientWidth-100)this.width=document.body.clientWidth-100"" /></a>"
		Else
			ShowAttachInPost = "<dl class=""t_attachlist"" id="""& AttachID &"""><dt></dt><dd><p><a href=""attachments/"& SavePath &""" target=""_blank""><img src=""attachments/"& SavePath &"""  alt="""& Description &""" onload=""if(this.width>document.body.clientWidth-110)this.width=document.body.clientWidth-110"" /></a></p></dd></dl>"
		End If
	End If
End Function

'========================================================
'搜索帖子内容中插入的附件
'========================================================
Function SearchAttachInPost(str)
	Dim Matches, Match, TEMP
	Set Matches = regExpSearch.Execute(str)
	For Each Match In Matches
		TEMP = TEMP & Match.SubMatches(0) &","
	Next
	Set Matches = Nothing
	SearchAttachInPost = TEMP
	TEMP = Empty
End Function

'========================================================
'显示附件大小
'========================================================
Function ShowFileSize(FileSize)
	If FileSize >= 1048576 Then
		ShowFileSize = Round(FileSize / 1048576 * 100) / 100 &" MB"
	ElseIf FileSize >= 1024 Then
		ShowFileSize = Round(FileSize / 1024 * 100) / 100 &" KB"
	Else
		ShowFileSize = FileSize &" Bytes"
	End If
End Function

'========================================================
'根据附件名显示文件图标
'========================================================
Function ShowFileType(FileExt)
	Select Case FileExt
		Case "wav", "mid", "mp3", "wma", "asf", "asx", "mpg", "mpeg", "avi", "wmv"
			ShowFileType = "av.gif"
		Case "rmvb", "ra", "rm"
			ShowFileType = "real.gif"
		Case "jpg", "jpeg", "png", "gif", "bmp"
			ShowFileType = "img.gif"
		Case "swf", "fla", "swi"
			ShowFileType = "flash.gif"
		Case "pdf"
			ShowFileType = "pdf.gif"
		Case "txt"
			ShowFileType = "txt.gif"
		Case "doc", "xls", "ppt", "docx", "xlsx", "pptx"
			ShowFileType = "msoffice.gif"
		Case "rar"
			ShowFileType = "rar.gif"
		Case "zip", "arj", "arc", "cab", "lzh", "lha", "tar", "gz"
			ShowFileType = "zip.gif"
		Case Else
			ShowFileType = "common.gif"
	End Select
End Function
%>