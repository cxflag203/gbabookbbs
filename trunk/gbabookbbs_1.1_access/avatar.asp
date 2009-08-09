<!--#include file="include/inc.asp"-->
<!--#include file="include/upload.class.asp"-->
<%
Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "saveorgavatar"
		Call SaveOrgAvatar()
	Case "saveavatar"
		Call SaveAvatar()
	Case Else
		Call Main()
End Select

'========================================================
'上传头像	，保存到临时目录
'========================================================
Sub SaveOrgAvatar()
	'验证是否能够上传
	If RQ.UserID = 0 Then
		Exit Sub
	End If

	Dim Upload, Files, File, SavePath
	Set Upload = new AnUpLoad

	'设置单个文件最大上传限制，单位：字节
	Upload.SingleSize = 512000

	'设置最大上传限制，单位：字节
	Upload.MaxSize = 512000

	'设置允许上传的扩展名，多个扩展名用|隔开
	Upload.Exe = "jpg,jpeg,png,gif"

	'读取文件流
	Upload.GetData()

	'如果读取出现错误则显示错误信息
	If Upload.ErrorID > 0 Then
		Exit Sub
	End If

	'验证是否有文件上传
	If Upload.Files(-1).Count = 0 Then
		Exit Sub
	End If

	'循环文件表单，保存文件
	For Each Files In Upload.Files(-1)
		Set File = Upload.files(Files)
		SavePath = "./avatars/temp/"& Date() &"/"& Rand(30) &"."& File.Ext
		If File.SaveToFile(SavePath) Then
			Response.Write SavePath
		End If
		Set File = Nothing
	Next
	Set Upload = Nothing

	'删除一天前的临时文件夹
	On Error Resume Next
	Dim Fso, tmpFolder, Folder
	Set Fso = CreateObject("Scripting.FileSystemObject")
	Set tmpFolder = Fso.GetFolder(Server.MapPath("./avatars/temp/"))
	For Each Folder In tmpFolder.SubFolders
		If IsDate(Folder.Name) Then
			If DateDiff("d", CDate(Folder.Name), Date()) > 0 Then
				Fso.DeleteFolder Server.MapPath("./avatars/temp/"& Folder.Name)
			End If
		End If
	Next
	Set tmpFolder = Nothing
	Set Fso = Nothing
End Sub

'========================================================
'保存头像
'========================================================
Sub SaveAvatar()
	If RQ.UserID = 0 Then
		Exit Sub
	End If

	Dim TempFile
	TempFile = SafeRequest(3, "tempfile", 1, "", 0)
	Call DeleteFile(TempFile)

	If Request.TotalBytes = 0 Then
		Exit Sub
	End If

	Dim SavePath, Stream

	SavePath = "./avatars/"& Left(RQ.UserID, 1) &"/"
	Call RebuildFolder(SavePath)

	Set Stream = CreateObject("ADODB.Stream")
	Stream.Mode = 3
	Stream.Type = 1
	Stream.Open
	Stream.Write(Request.BinaryRead(Request.TotalBytes))
	Stream.SaveToFile Server.MapPath(SavePath & RQ.UserID &".jpg"), 2
	Stream.Close
	Set Stream = Nothing

	RQ.Execute("UPDATE "& TablePre &"memberfields SET avatar = '"& Left(RQ.UserID, 1) &"/"& RQ.UserID &".jpg' WHERE uid = "& RQ.UserID)
	Call closeDatabase()
End Sub

'========================================================
'上传头像界面
'========================================================
Sub Main()
	Dim UserInfo, PathInfo
	UserInfo = RQ.Query("SELECT avatar FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)
	Call closeDatabase()

	PathInfo = LCase(Request.ServerVariables("PATH_INFO"))
	PathInfo = Left(PathInfo, InstrRev(PathInfo, "/"))

	RQ.Header()
%>
<body>
您当前使用的头像：
<br />
<br />
<div id="myavatar" style="border: 1px #ccc solid; width: 48px; height: 48px;"><img src="<%= IIF(Len(UserInfo(0, 0)) > 0, "avatars/"& UserInfo(0, 0), "images/common/noavatar.jpg") %>" /></div>
<br />
<br />
上传新头像(图片大小请控制在500KB以内)：
<br />
<br />
<embed src="js/uploadavatar.swf?path=<%= PathInfo %>" quality="high" width="453" height="403" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash"></embed>
<script language="javascript">
function show(_txt){
	var uid = '<%= RQ.UserID %>';
	$('myavatar').innerHTML = '<img src="avatars/'+ uid.substr(0, 1) +'/'+ uid +'.jpg?'+ Math.random() +'" />';
}
</script>
<%
	RQ.Footer()
End Sub
%>