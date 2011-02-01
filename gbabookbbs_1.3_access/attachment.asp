<!--#include file="include/inc.asp"-->
<!--#include file="include/upload.class.asp"-->
<%
Server.ScriptTimeout = 900
Dim Action
Action = Request("action")
Select Case Action
	Case "upload"
		Call UploadAttach()
	Case "ajaxdelete"
		Call AjaxDelete()
	Case "get"
		Call GetAttach()
End Select

'========================================================
'Ajax删除附件(上传附件时点击删除按钮)
'========================================================
Sub AjaxDelete()
	Dim AttachID, AttachInfo

	AttachID = SafeRequest(2, "aid", 0, 0, 0)
	If AttachID = 0 Then
		Exit Sub
	End If

	AttachInfo = RQ.Query("SELECT savepath, ifthumb FROM "& TablePre &"attachments WHERE aid = "& AttachID &" AND pid = 0 AND uid = "& RQ.UserID)
	If IsArray(AttachInfo) Then
		'删除附件
		Call DeleteFile(RQ.Attach_Settings(0) &"/"& AttachInfo(0, 0))

		'如果有缩略图也要删除
		If AttachInfo(1, 0) = 1 Then
			Call DeleteFile(RQ.Attach_Settings(0) &"/"& AttachInfo(0, 0) &".thumb."& GetFileExt(AttachInfo(0, 0)))
		End If

		RQ.Execute("DELETE FROM "& TablePre &"attachments WHERE aid = "& AttachID)
	End If
	Call closeDatabase()
End Sub

'========================================================
'上传附件
'========================================================
Sub UploadAttach()
	'验证是否能够上传
	If Not RQ.AllowPostAttach Then
		Call UploadError("您当前的身份还不能上传附件。")
	End If

	Dim Upload, Files, File
	Dim SavePath, AttachID

	Set Upload = new AnUpLoad

	'设置单个文件最大上传限制，单位：字节
	Upload.SingleSize = IIF(RQ.MaxAttachSize = 0, 100 * 1024 * 1024, RQ.MaxAttachSize * 1024)

	'设置最大上传限制，单位：字节
	Upload.MaxSize = 0

	'设置允许上传的扩展名，多个扩展名用,隔开
	Upload.AllowedExt = RQ.AttachExtensions

	'读取文件流
	Upload.GetData()

	'如果读取出现错误则显示错误信息
	If Upload.ErrorID > 0 Then
		Call UploadError(Upload.Description)
	End If

	'验证是否有文件上传
	If Upload.Files(-1).Count = 0 Then
		Call UploadError("没有文件上传。")
	End If

	'循环文件表单，保存文件
	For Each Files In Upload.Files(-1)
		Set File = Upload.files(Files)

		SavePath = Year(Now()) & Month(Now()) &"/"& Date() &"_"& Rand(30) &"."& File.Ext

		If File.SaveToFile(RQ.Attach_Settings(0) &"/"& SavePath) Then
			RQ.Execute("INSERT INTO "& TablePre &"attachments (uid, filename, filetype, filesize, savepath, ifimage, ifthumb) VALUES ("& RQ.UserID &", '"& File.LocalName &"', '"& File.Mime &"', "& File.Size &", '"& SavePath &"', "& File.IfImage &", "& File.IfThumb &")")

			AttachID = Conn.Execute("SELECT MAX(aid) FROM "& TablePre &"attachments")(0)
			Response.Write AttachID
		Else
			Call UploadError("保存文件时出错。")
		End If
		Set File = Nothing
	Next

	Call closeDatabase()
	Set Upload = Nothing
End Sub

'========================================================
'上传输出错误
'========================================================
Sub UploadError(msg)
	Response.Status = "500"
	Response.Write msg
	Response.End()
End Sub

'========================================================
'下载附件
'========================================================
Sub GetAttach()
	Dim AttachID, AttachInfo, AttachURL, NoThumb, NoUpdate
	Dim Fso, File, FileSize, Stream

	AttachID = SafeRequest(3, "aid", 0, 0, 0)
	AttachInfo = RQ.Query("SELECT a.uid, a.filename, a.filetype, a.savepath, a.ifimage, a.ifthumb, t.fid FROM "& TablePre &"attachments a INNER JOIN "& TablePre &"topics t ON a.tid = t.tid WHERE a.aid = "& AttachID &" AND t.displayorder >= 0")
	If Not IsArray(AttachInfo) Then
		Call RQ.showTips("附件信息不存在或者已经被删除。", "", "")
	End If

	'当前用户是否有浏览版面的权限
	RQ.Forum_ViewPerm = RQ.Get_Forum_Settings(AttachInfo(6, 0), 23)
	If Len(RQ.Forum_ViewPerm) > 0 And Not InStr(","& RQ.Forum_ViewPerm &",", ","& RQ.UserGroupID &",") > 0 Then
		Call RQ.showTips("抱歉，您当前的用户身份("& RQ.UserGroupName &")还不能浏览该版面。", "", "NOPERM")
	End If

	'获取版面允许下载附件的用户组列表
	RQ.Forum_GetAttachPerm = RQ.Get_Forum_Settings(AttachInfo(6, 0), 27)

	'根据版面设置判断允许当前用户是否允许下载附件
	If Len(RQ.Forum_GetAttachPerm) > 0 And Not InStr(","& RQ.Forum_GetAttachPerm &",", ","& RQ.UserGroupID &",") > 0 Then
		RQ.AllowGetAttach = False
	End If 

	If Not RQ.AllowGetAttach Then
		Call RQ.showTips("您当前的身份（"& RQ.UserGroupName &"）无法下载附件。", "", "")
	End If

	'是否更新点击量
	NoUpdate = SafeRequest(3, "noupdate", 0, 0, 0)
	If NoUpdate = 0 Then
		RQ.Execute("UPDATE "& TablePre &"attachments SET downloads = downloads + 1 WHERE aid = "& AttachID)
	End If

	Call closeDatabase()

	'点击缩略图链接后显示原图
	NoThumb = SafeRequest(3, "nothumb", 0, 0, 0)

	If AttachInfo(4, 0) = 1 And AttachInfo(5, 0) = 1 And NoThumb = 0 Then
		AttachURL = RQ.Attach_Settings(0) &"/"& AttachInfo(3, 0) &".thumb."& GetFileExt(AttachInfo(3, 0))
	Else
		AttachURL = RQ.Attach_Settings(0) &"/"& AttachInfo(3, 0)
	End If

	Set Fso = Server.CreateObject("Scripting.FileSystemObject")
	If Not Fso.FileExists(Server.MapPath(AttachURL)) Then
		Set Fso = Nothing
		Call RQ.showTips("附件文件丢失。", "", "")
	End If

	'读取文件信息
	Set File = Fso.GetFile(Server.MapPath(AttachURL))
	FileSize = File.Size
	Set File = Nothing
	Set Fso = Nothing

	If FileSize > 4096000 Then
		Response.Redirect AttachURL
	Else
		Set Stream = Server.CreateObject("ADODB.Stream")
		Stream.Open
		Stream.Type = 1
		'读取文件
		Stream.LoadFromFile Server.MapPath(AttachURL)

		'如果是IE浏览器，则使用URLEncode编码来发送文件名
		If InStr(LCase(Request.ServerVariables("HTTP_USER_AGENT")), "msie") > 0 Then
			Response.AddHeader "Content-Disposition", "attachment; filename="& Replace(LCase(Server.URLEncode(AttachInfo(1, 0))), "%2e", ".")
		Else
			Response.AddHeader "Content-Disposition", "attachment; filename="& AttachInfo(1, 0)
		End If

		Response.AddHeader "Content-Length", FileSize
		Response.ContentType = "application/octet-stream"

		If Response.IsClientConnected Then
			If FileSize >= 102400 Then
				Do While FileSize > 0
					Response.BinaryWrite Stream.Read(102400)
					FileSize = FileSize - 102400
				Loop
			Else
				Response.BinaryWrite Stream.Read
			End If
		End If

		Response.Flush
		Response.Clear()
		Stream.Close
		Set Stream = Nothing
	End If
End Sub
%>