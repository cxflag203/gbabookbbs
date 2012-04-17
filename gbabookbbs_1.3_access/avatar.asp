<!--#include file="include/inc.asp"-->
<!--#include file="include/upload.class.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("游客无法使用头像功能。", "", "")
End If

Dim Action, PathInfo, SITEURL

Action = Request.QueryString("action")
If Len(Action) = 0 Then
	Action = Request.QueryString("a")
End If
 
PathInfo = Request.ServerVariables("PATH_INFO")
PathInfo = Mid(PathInfo, 1, InstrRev(PathInfo, "/"))
SITEURL = "http://"& Request.ServerVariables("SERVER_NAME") & PathInfo

Select Case Action
	Case "deleteavatar"
		Call DeleteAvatar()
	Case "saveorgavatar", "uploadavatar"
		Call SaveOrgAvatar()
	Case "saveavatar", "rectavatar"
		Call SaveAvatar()
	Case Else
		Call Main()
End Select

'========================================================
'删除头像
'========================================================
Sub DeleteAvatar()
	If Request.Form("do") = "delete" Then
		RQ.Execute("UPDATE "& TablePre &"memberfields SET avatar = '' WHERE uid = "& RQ.UserID)
		Call DeleteFile("./avatars/"& Left(RQ.UserID, 1) &"/"& RQ.UserID &".jpg")
	End If

	Call closeDatabase()
	Call RQ.showTips("头像已经成功删除。", "?", "")
End Sub

'========================================================
'上传头像	，保存到临时目录
'========================================================
Sub SaveOrgAvatar()
	Dim Upload, Files, File, SavePath
	Set Upload = new AnUpLoad

	'设置单个文件最大上传限制，单位：字节
	Upload.SingleSize = 1024000

	'设置最大上传限制，单位：字节
	Upload.MaxSize = 1024000

	'设置允许上传的扩展名，多个扩展名用|隔开
	Upload.AllowedExt = "jpg,jpeg,png,gif"

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
		SavePath = "avatars/temp/"& Date() &"/"& Rand(30) &"."& File.Ext
		If File.SaveToFile(SavePath) Then
			Response.Write SITEURL & SavePath
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
'解码flash图片数据
'========================================================
%>
<script language="jscript" runat="server">
function FlashDecode(s) {
	var r, l, i, k1, k2;
	r = '';
	l = s.length;
	for(i=0; i<l; i=i+2) {
		k1 = s.charAt(i).charCodeAt() - 48;
		k1 -= k1 > 9 ? 7 : 0;
		k2 = s.charAt(i+1).charCodeAt() - 48;
		k2 -= k2 > 9 ? 7 : 0;
		r = r + (k1 << 4 | k2) +',';
	}
	return r;
}
</script>
<%
'========================================================
'保存头像
'========================================================
Sub SaveAvatar()
	Dim Avatar_Small, strImage, SavePath
	Dim AryAvatar

	Avatar_Small = SafeRequest(2, "avatar3", 1, "", 0)
	If Len(Avatar_Small) = 0 Then
		Response.Write "<?xml version=""1.0"" ?><root><face success=""0""/></root>"
		Response.End()
	End If
	
	Avatar_Small = FlashDecode(Avatar_Small)
	AryAvatar = Split(Avatar_Small, ",")
	For i = 0 To UBound(AryAvatar) - 1
		strImage = strImage & ChrB(AryAvatar(i))
	Next

	SavePath = "./avatars/"& Left(RQ.UserID, 1) &"/"

	Call CheckFolder(SavePath)
	Call ByteToImage(strImage, SavePath & RQ.UserID &".jpg")

	RQ.Execute("UPDATE "& TablePre &"memberfields SET avatar = '"& Left(RQ.UserID, 1) &"/"& RQ.UserID &".jpg' WHERE uid = "& RQ.UserID)
	Call closeDatabase()

	Response.Write "<?xml version=""1.0"" ?><root><face success=""1""/></root>"

'	Dim TempFile
'	TempFile = SafeRequest(3, "tempfile", 1, "", 0)
'	Call DeleteFile(TempFile)
'
'	If Request.TotalBytes = 0 Then
'		Exit Sub
'	End If
'
'	Dim SavePath, Stream
'
'	SavePath = "./avatars/"& Left(RQ.UserID, 1) &"/"
'	Call CheckFolder(SavePath)
'
'	Set Stream = CreateObject("ADODB.Stream")
'	Stream.Mode = 3
'	Stream.Type = 1
'	Stream.Open
'	Stream.Write(Request.BinaryRead(Request.TotalBytes))
'	Stream.SaveToFile Server.MapPath(SavePath & RQ.UserID &".jpg"), 2
'	Stream.Close
'	Set Stream = Nothing
'
'	RQ.Execute("UPDATE "& TablePre &"memberfields SET avatar = '"& Left(RQ.UserID, 1) &"/"& RQ.UserID &".jpg' WHERE uid = "& RQ.UserID)
'	Call closeDatabase()
End Sub

'========================================================
'保存头像
'========================================================
Sub ByteToImage(strContent, FileName)
	Dim Stream, Stream2
	Set Stream = Server.CreateObject("ADODB.Stream")
	Set Stream2 = Server.CreateObject("ADODB.Stream")
	Stream.Type = 2
	Stream.Open
	Stream.Position = Stream.Size
	Stream.WriteText = strContent
	Stream2.Type = 1
	Stream2.Open
	Stream.Position = 2
	Stream.CopyTo Stream2, Stream.Size
	Stream.Close
	Stream2.SaveToFile Server.MapPath(FileName), 2
	Stream2.close
	Set Stream = Nothing
	Set Stream2 = Nothing
	strContent = Empty
End Sub

'========================================================
'上传头像界面
'========================================================
Sub Main()
	Dim UserInfo
	UserInfo = RQ.Query("SELECT avatar FROM "& TablePre &"memberfields WHERE uid = "& RQ.UserID)
	Call closeDatabase()

	RQ.Header()
%>
<body>
您当前使用的头像：
<br />
<br />
<div style="border: 1px #ccc solid; width: 48px; height: 48px;"><img id="myavatar" src="<%= IIF(Len(UserInfo(0, 0)) > 0, "avatars/"& UserInfo(0, 0), "images/common/noavatar.jpg") %>" /></div>
<% If Len(UserInfo(0, 0)) > 0 Then %>
<br />
[<a href="###" onclick="postvalue('?action=deleteavatar', 'do', 'delete')" class="underline">删除头像</a>]
<% End If %>
<p>
上传新头像(图片大小请控制在500KB以内)：
<br />
<br />
<embed src="js/camera.swf?nt=1&input=<%= Server.URLEncode(RQ.UserCode) %>&ucapi=<%= Server.URLEncode(SITEURL & "avatar.asp") %>" quality="high" width="450" height="253" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash"></embed>
<script language="javascript">
function updateavatar(sender, args) {
	var uid = '<%= RQ.UserID %>';
	$('myavatar').src = 'avatars/'+ uid.substr(0, 1) +'/'+ uid +'.jpg?'+ Math.random();
}
</script>
<%
	RQ.Footer()
End Sub
%>