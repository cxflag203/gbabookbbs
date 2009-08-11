<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "basesettings"
		Call BaseSettings()
	Case "savebasesettings"
		Call SaveBaseSettings()
	Case "timesettings"
		Call TimeSettings()
	Case "savetimesettings"
		Call SaveTimeSettings()
	Case "loginsettings"
		Call LoginSettings()
	Case "saveloginsettings"
		Call SaveLoginSettings()
	Case "usersettings"
		Call UserSettings()
	Case "saveusersettings"
		Call SaveUserSettings()
	Case "topicsettings"
		Call TopicSettings()
	Case "savetopicsettings"
		Call SaveTopicSettings()
	Case "othersettings"
		Call OtherSettings()
	Case "saveothersettings"
		Call SaveOtherSettings()
	Case "chatsettings"
		Call ChatSettings()
	Case "savechatsettings"
		Call SaveChatSettings()
	Case "wapsettings"
		Call WapSettings()
	Case "savewapsettings"
		Call SaveWapSettings()
End Select
AdminFooter()

'========================================================
'基本设置
'========================================================
Sub BaseSettings()
	Dim SettingsInfo, Base_Settings

	SettingsInfo = RQ.Query("SELECT base_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Base_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;基本设置</td>
  </tr>
</table>
<br />
<form method="post" name="basesettings" action="?action=savebasesettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellspacing="0" cellpadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>基本设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>站点名称:</strong></td>
      <td width="70%"><input type="text" name="basesettings_0" size="40" value="<%= Base_Settings(0) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>站点关键字:</strong><br />便于搜索引擎检索，多个关键字用英文逗号隔开<br />注意：请不要设置过多的关键字</td>
      <td width="70%"><input type="text" name="basesettings_1" size="40" value="<%= Base_Settings(1) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>站点描述:</strong><br />便于搜索引擎检索<br />注意：字数最好控制在200字内</td>
      <td width="70%"><input type="text" name="basesettings_2" size="40" value="<%= Base_Settings(2) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>关闭论坛:</strong><br />论坛关闭后，只有站长才能进入。</td>
      <td width="70%"><input type="checkbox" class="radio" name="basesettings_3" id="basesettings_3" value="1"<% If Base_Settings(3) = "1" Then Response.Write " checked" End If %> /><label for="basesettings_3">是的</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>关闭后的提示文字:</strong><br />支持HTML语言</td>
      <td width="70%"><textarea name="basesettings_4" rows="4" cols="40" /><%= Base_Settings(4) %></textarea></td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'保存基本设置
'========================================================
Sub SaveBaseSettings()
	Dim Base_Settings(4)
	Base_Settings(0) = SafeRequest(2, "basesettings_0", 1, "", 0)
	Base_Settings(1) = SafeRequest(2, "basesettings_1", 1, "", 0)
	Base_Settings(2) = SafeRequest(2, "basesettings_2", 1, "", 0)
	Base_Settings(3) = SafeRequest(2, "basesettings_3", 0, 0, 0)
	Base_Settings(4) = SafeRequest(2, "basesettings_4", 1, "", 1)

	RQ.Execute("UPDATE "& TablePre &"settings SET base_settings = '"& Join(Base_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call AdminshowTips("基本设置保存成功。", "?action=basesettings")
End Sub

'========================================================
'时间段设置
'========================================================
Sub TimeSettings()
	Dim SettingsInfo, Time_Settings

	SettingsInfo = RQ.Query("SELECT time_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Time_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;时间段设置</td>
  </tr>
</table>
<br />
<form method="post" name="timesettings" action="?action=savetimesettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>时间段设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>禁止访问的时间段:</strong><br />一行一个时间段,多个时间段用回车隔开。<br />例如：21:00-6:00表示从当天晚上9点到次日早上6点</td>
      <td><textarea name="timesettings_0" rows="3" cols="40"><%= Replace(Time_Settings(0), "_", vbCrLf) %></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>论坛只读的时间段:</strong><br />同上</td>
      <td><textarea name="timesettings_1" rows="3" cols="40"><%= Replace(Time_Settings(1), "_", vbCrLf) %></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发帖审核的时间段:</strong><br />同上</td>
      <td><textarea name="timesettings_2" rows="3" cols="40"><%= Replace(Time_Settings(2), "_", vbCrLf) %></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>允许搜索的时间段:</strong><br />同上</td>
      <td><textarea name="timesettings_3" rows="3" cols="40"><%= Replace(Time_Settings(3), "_", vbCrLf) %></textarea></td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'验证时间格式(时间段的设置)
'========================================================
Function CheckTimeFormat(str)
	Dim Temp, ArrayTime, strs

	Temp = Replace(Replace(str, vbCrLf, "_"), " ", "")

	If Len(Temp) = 0 Then 
		Exit Function
	End If

	Temp = Split(Temp, "_")

	For i = 0 To UBound(Temp)
		If InStr(Temp(i), "-") > 0 Then
			ArrayTime = Split(Temp(i), "-")
			If IsDate(ArrayTime(0)) And IsDate(ArrayTime(1)) Then
				strs = strs & Temp(i) &"_"
			End If
		End If
	Next

	If Right(strs, 1) = "_" Then
		strs = Left(strs, Len(strs) - 1)
	End If

	CheckTimeFormat = strs
	strs = Empty
End Function

'========================================================
'保存时间段设置
'========================================================
Sub SaveTimeSettings()
	Dim Time_Settings(3)
	Time_Settings(0) = CheckTimeFormat(SafeRequest(2, "timesettings_0", 1, "", 0))
	Time_Settings(1) = CheckTimeFormat(SafeRequest(2, "timesettings_1", 1, "", 0))
	Time_Settings(2) = CheckTimeFormat(SafeRequest(2, "timesettings_2", 1, "", 0))
	Time_Settings(3) = CheckTimeFormat(SafeRequest(2, "timesettings_3", 1, "", 0))

	RQ.Execute("UPDATE "& TablePre &"settings SET time_settings = '"& Join(Time_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()
	
	Call closeDatabase()
	Call AdminshowTips("时间段设置保存成功。", "?action=timesettings")
End Sub

'========================================================
'注册和登录设置
'========================================================
Sub LoginSettings()
	Dim SettingsInfo, Login_Settings

	SettingsInfo = RQ.Query("SELECT login_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Login_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;注册和登录设置</td>
  </tr>
</table>
<br />
<form method="post" name="loginsettings" action="?action=saveloginsettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>注册和登录设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否停止注册</strong><br />如果停止注册则自动转入推荐码模式</td>
      <td><select name="loginsettings_0" id="loginsettings_0">
        <option value="0"<% If Login_Settings(0) = "0" Then Response.Write " selected" End If %>>开放注册</option>
        <option value="1"<% If Login_Settings(0) = "1" Then Response.Write " selected" End If %>>关闭注册</option>
        <option value="2"<% If Login_Settings(0) = "2" Then Response.Write " selected" End If %>>使用推荐码注册</option>
      </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>注册/登陆的文件名</strong><br />如果修改了文件名，请登陆FTP将对应的文件名也改掉</td>
      <td><input type="text" name="loginsettings_1" value="<%= Login_Settings(1) %>" size="30" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>用户名保留关键字</strong><br />在用户名中无法使用这些关键字。<br />每个关键字一行，可使用通配符 "*" 例如 "*管理员*"(不含引号)</td>
      <td><textarea name="loginsettings_2" rows="5" cols="40"><%= Login_Settings(2) %></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>注册用户名长度</strong><br />最小1 - 最大20</td>
      <td><input type="text" name="loginsettings_3" value="<%= Login_Settings(3) %>" size="5" />
        -
        <input type="text" name="loginsettings_4" value="<%= Login_Settings(4) %>" size="5" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>新用户的初始金币</strong></td>
      <td><input type="text" name="loginsettings_5" value="<%= Login_Settings(5) %>" size="5" />
        金币</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>登陆失败</strong><br />次数为0则不限制</td>
      <td>登陆失败
        <input type="text" name="loginsettings_6" size="5" value="<%= Login_Settings(6) %>" />
        次后30分钟内禁止登陆</td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'保存登陆设置
'========================================================
Sub SaveLoginSettings()
	Dim Login_Settings(6)

	Login_Settings(0) = SafeRequest(2, "loginsettings_0", 0, 0, 0)
	Login_Settings(1) = SafeRequest(2, "loginsettings_1", 1, "", 0)
	If Len(Login_Settings(1)) = 0 Then
		Call AdminshowTips("请填写好注册/登陆的文件名。", "")
	End If

	Login_Settings(2) = SafeRequest(2, "loginsettings_2", 1, "", 0)
	If Len(Login_Settings(2)) > 0 Then
		Login_Settings(2) = Trim(Preg_Replace(Login_Settings(2), "\s*(\r\n|\n\r|\n|\r)\s*", vbCrLf))
		If Right(Login_Settings(2), 2) = vbCrLf Then
			Login_Settings(2) = Left(Login_Settings(2), Len(Login_Settings(2)) - 2)
		End If
	End If

	Login_Settings(3) = SafeRequest(2, "loginsettings_3", 0, 1, 0)
	Login_Settings(4) = SafeRequest(2, "loginsettings_4", 0, 20, 0)
	If Login_Settings(4) > 20 Then
		Login_Settings(4) = 20
	End If

	If Login_Settings(3) > Login_Settings(4) Then
		Login_Settings(3) = 1
		Login_Settings(4) = 20
	End If

	Login_Settings(5) = SafeRequest(2, "loginsettings_5", 0, 0, 0)
	Login_Settings(6) = SafeRequest(2, "loginsettings_6", 0, 0, 0)

	RQ.Execute("UPDATE "& TablePre &"settings SET login_settings = '"& Join(Login_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call AdminshowTips("登陆设置保存成功。", "?action=loginsettings")
End Sub

'========================================================
'用户功能设置
'========================================================
Sub UserSettings()
	Dim SettingsInfo, User_Settings

	SettingsInfo = RQ.Query("SELECT user_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	User_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;用户功能设置</td>
  </tr>
</table>
<br />
<form method="post" name="usersettings" action="?action=saveusersettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>用户功能相关</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>刷新获得金币</strong></td>
      <td>注册用户每隔
        <input type="text" name="usersettings_0" value="<%= User_Settings(0) %>" size="5" />
        分钟刷新浏览器可获得
        <input type="text" name="usersettings_1" value="<%= User_Settings(1) %>" size="5" />
        金币</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>传呼/在线</strong></td>
      <td>每隔
        <input type="text" name="usersettings_2" value="<%= User_Settings(2) %>" size="5" />
        分钟检查传呼和检查在线</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>刷新在线用户</strong></td>
      <td>自动删除
        <input type="text" name="usersettings_3" size="5" value="<%= User_Settings(3) %>" />
        分钟后不活动的用户</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>收藏夹</strong></td>
      <td>会员最多收藏
        <input type="text" name="usersettings_4" size="5" value="<%= User_Settings(4) %>" />
        个帖子,管理员不受限制</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>联盟订阅</strong></td>
      <td>最多订阅
        <input type="text" name="usersettings_5" size="5" value="<%= User_Settings(5) %>" />
        个联盟的帖子</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>传呼限制</strong></td>
      <td><input type="text" name="usersettings_6" size="5" value="<%= User_Settings(6) %>" />
        金币以上才能发送传呼,但可以接收.管理员不受限制</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>接收金币限制</strong></td>
      <td><input type="text" name="usersettings_7" size="5" value="<%= User_Settings(7) %>" />
        金币以上才能接收别人的转让金币</td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'保存用户设置
'========================================================
Sub SaveUserSettings()
	Dim User_Settings(7)
	User_Settings(0) = SafeRequest(2, "usersettings_0", 0, 1, 0)
	User_Settings(1) = SafeRequest(2, "usersettings_1", 0, 1, 0)
	User_Settings(2) = SafeRequest(2, "usersettings_2", 0, 1, 0)
	User_Settings(3) = SafeRequest(2, "usersettings_3", 0, 1, 0)
	User_Settings(4) = SafeRequest(2, "usersettings_4", 0, 1, 0)
	User_Settings(5) = SafeRequest(2, "usersettings_5", 0, 1, 0)
	User_Settings(6) = SafeRequest(2, "usersettings_6", 0, 0, 0)
	User_Settings(7) = SafeRequest(2, "usersettings_7", 0, 0, 0)

	RQ.Execute("UPDATE "& TablePre &"settings SET user_settings = '"& Join(User_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()

	Call closeDatabase()
	Call AdminshowTips("用户设置保存成功。", "?action=usersettings")
End Sub

'========================================================
'帖子和回复设置
'========================================================
Sub TopicSettings()
	Dim SettingsInfo, Topic_Settings

	SettingsInfo = RQ.Query("SELECT topic_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Topic_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;帖子和回复设置</td>
  </tr>
</table>
<br />
<form method="post" name="topicsettings" action="?action=savetopicsettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>帖子和回复相关</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发表帖子时标题的最大长度:</strong></td>
      <td><input type="text" name="topicsettings_0" size="5" value="<%= Topic_Settings(0) %>" />&nbsp;个字，超过就自动截断。</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发表帖子/回复内容的最大长度:</strong><br />管理员/版主不受此限制</td>
      <td><input type="text" name="topicsettings_1" size="5" value="<%= Topic_Settings(1) %>" />&nbsp;个字</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>帖子列表每页帖子数量:</strong></td>
      <td><input type="text" name="topicsettings_2" size="5" value="<%= Topic_Settings(2) %>" /> 条</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>帖子列表最多显示页数:</strong><br />设置为0则不限制</td>
      <td><input type="text" name="topicsettings_3" size="5" value="<%= Topic_Settings(3) %>" /> 页</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>帖子回复每页回复数量:</strong></td>
      <td><input type="text" name="topicsettings_4" size="5" value="<%= Topic_Settings(4) %>" /> 条</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>帖子回复页面的样式:</strong></td>
      <td><input type="radio" name="topicsettings_5" id="topicsettings_5_1" value="1" class="radio"<% If Topic_Settings(5) = "1" Then Response.Write " checked" End If %> onclick="show_stylepanel();" /><label for="topicsettings_5_1">简洁样式</label><br />
	    <input type="radio" name="topicsettings_5" id="topicsettings_5_2" value="2" class="radio"<% If Topic_Settings(5) = "2" Then Response.Write " checked" End If %> onclick="show_stylepanel();" /><label for="topicsettings_5_2">带头像的样式</label></td>
    </tr>
    <tr height="25" id="topicsettings_6_disp" style="display: none;">
      <td class="altbg1"><strong>帖子回复的楼层分隔符:</strong><br />允许使用HTML</td>
      <td><input type="text" name="topicsettings_6" size="35" value="<%= strFilter(Topic_Settings(6)) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>帖子鉴定:</strong></td>
      <td>默认被鉴定为:
        <input type="text" name="topicsettings_7" size="35" value="<%= Topic_Settings(7) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>发帖防灌水控制:</strong><br />时间设置为0则为不限制。</td>
      <td>多次发帖必须间隔 <input type="text" name="topicsettings_8" value="<%= Topic_Settings(8) %>" size="5" /> 分钟</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>回帖防灌水控制:</strong><br />时间设置为0则为不限制</td>
      <td>回帖内容少于 <input type="text" name="topicsettings_9" size="5" value="<%= Topic_Settings(9) %>" /> 个字则限制回复
	    <input type="text" name="topicsettings_10" size="5" value="<%= Topic_Settings(10) %>" /> 分钟</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>匿名成功扣除金币:</strong><br />匿名失败或者设置为0则不扣除</td>
      <td>匿名扣除 <input type="text" name="topicsettings_11" value="<%= Topic_Settings(11) %>" size="5" /> 金币</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>匿名前缀:</strong></td>
      <td><input type="text" name="topicsettings_12" value="<%= Topic_Settings(12) %>" />&nbsp;, 后面的数字
        <input type="radio" class="radio" id="topicsettings_13_1" name="topicsettings_13" value="0"<% If Topic_Settings(13) = "0" Then Response.Write " checked" End If %> /><label for="topicsettings_13_1">随机</label>
        <input type="radio" class="radio" id="topicsettings_13_2" name="topicsettings_13" value="1"<% If Topic_Settings(13) = "1" Then Response.Write " checked" End If %> /><label for="topicsettings_13_2">根据IP生成</label>
      </td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>匿名失败功能:</strong></td>
      <td><input type="checkbox" class="radio" name="topicsettings_14" id="topicsettings_14" value="1"<% If Topic_Settings(14) = "1" Then Response.Write " checked" End If %> onclick="show_anonymitypanel();" /><label for="topicsettings_14">打开</label></td>
    </tr>
    <tr height="25" id="topicsettings_15_disp" style="display: none;">
      <td class="altbg1"><strong>匿名成功机率:</strong><br />请填写1-100之间的数字</td>
      <td><input type="text" name="topicsettings_15" value="<%= Topic_Settings(15) %>" size="5" />&nbsp;%</td>
    </tr>
    <tr height="25" id="topicsettings_16_disp" style="display: none;">
      <td class="altbg1"><strong>匿名失败提示文字:</strong><br />注意用户名的格式，长度不能超过70个字，否则会被截断。<br />支持HTML</td>
      <td><input type="text" name="topicsettings_16" size="50" value="<%= strFilter(Topic_Settings(16)) %>" maxlength="70" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>默认使用编辑器:</strong></td>
      <td><input type="checkbox" name="topicsettings_17" id="topicsettings_17_1" value="topic" class="radio"<% If InStr(Topic_Settings(17), "topic") > 0 Then Response.Write " checked" End If %> /><label for="topicsettings_17_1">发帖</label>
	    <input type="checkbox" name="topicsettings_17" id="topicsettings_17_2" value="reply" class="radio"<% If InStr(Topic_Settings(17), "reply") > 0 Then Response.Write " checked" End If %> /><label for="topicsettings_17_2">回帖</label>
		<input type="checkbox" name="topicsettings_17" id="topicsettings_17_3" value="edit" class="radio"<% If InStr(Topic_Settings(17), "edit") > 0 Then Response.Write " checked" End If %> /><label for="topicsettings_17_3">编辑帖子/回复</label>
      </td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<script type="text/javascript">
function show_stylepanel(){
	$('topicsettings_6_disp').style.display = $('topicsettings_5_1').checked ? '' : 'none';
}
function show_anonymitypanel(){
	$('topicsettings_15_disp').style.display = $('topicsettings_16_disp').style.display = $('topicsettings_14').checked ? '' : 'none';
}
show_stylepanel();
show_anonymitypanel();
</script>
<%
End Sub

'========================================================
'保存帖子和回复设置
'========================================================
Sub SaveTopicSettings()
	Dim Topic_Settings(17)

	Topic_Settings(0) = SafeRequest(2, "topicsettings_0", 0, 100, 0)
	If Topic_Settings(0) > 100 Then
		Topic_Settings(0) = 100
	End If

	Topic_Settings(1) = SafeRequest(2, "topicsettings_1", 0, 10000, 0)
	Topic_Settings(2) = SafeRequest(2, "topicsettings_2", 0, 100, 0)
	Topic_Settings(3) = SafeRequest(2, "topicsettings_3", 0, 0, 0)
	Topic_Settings(4) = SafeRequest(2, "topicsettings_4", 0, 100, 0)
	Topic_Settings(5) = SafeRequest(2, "topicsettings_5", 0, 0, 0)
	If Not InArray(Array(1, 2), Topic_Settings(5)) Then
		Topic_Settings(5) = 1
	End If

	Topic_Settings(6) = SafeRequest(2, "topicsettings_6", 1, "", 1)
	Topic_Settings(7) = SafeRequest(2, "topicsettings_7", 1, "", 0)
	Topic_Settings(8) = SafeRequest(2, "topicsettings_8", 0, 0, 0)
	Topic_Settings(9) = SafeRequest(2, "topicsettings_9", 0, 1, 0)
	Topic_Settings(10) = SafeRequest(2, "topicsettings_10", 0, 0, 0)
	Topic_Settings(11) = SafeRequest(2, "topicsettings_11", 0, 0, 0)
	Topic_Settings(12) = SafeRequest(2, "topicsettings_12", 1, "", 0)
	Topic_Settings(13) = SafeRequest(2, "topicsettings_13", 0, 0, 0)
	Topic_Settings(14) = SafeRequest(2, "topicsettings_14", 0, 0, 0)
	Topic_Settings(15) = SafeRequest(2, "topicsettings_15", 0, 0, 0)
	If Topic_Settings(15) > 100 Then
		Topic_Settings(15) = 100
	End If

	Topic_Settings(16) = Left(SafeRequest(2, "topicsettings_16", 1, "", 1), 70)
	Topic_Settings(17) = Replace(SafeRequest(2, "topicsettings_17", 1, "", 0), " ", "")

	RQ.Execute("UPDATE "& TablePre &"settings SET topic_settings = '"& Join(Topic_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()
	
	Call closeDatabase()
	Call AdminshowTips("帖子和回复设置保存成功。", "?action=topicsettings")
End Sub

'========================================================
'搜索和其他设置
'========================================================
Sub OtherSettings()
	Dim SettingsInfo, Other_Settings
	Dim ForumListArray

	SettingsInfo = RQ.Query("SELECT other_settings FROM "& TablePre &"settings")
	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Other_Settings = Split(SettingsInfo(0, 0), "{settings}")

	ForumListArray = RQ.Query("SELECT fid, name FROM "& TablePre &"forums ORDER BY displayorder ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;搜索和其他设置</td>
  </tr>
</table>
<br />
<form method="post" name="othersettings" action="?action=saveothersettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>搜索和其他设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>论坛货币名称</strong></td>
      <td><input type="text" name="othersettings_0" size="10" value="<%= Other_Settings(0) %>" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>清除过期的异动报告</strong></td>
      <td>自动清除&nbsp;<input type="text" name="othersettings_1" size="5" value="<%= Other_Settings(1) %>" />&nbsp;天后的异动报告,默认60天</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>搜索结果</strong></td>
      <td>最大搜索结果&nbsp;<input type="text" name="othersettings_2" size="5" value="<%= Other_Settings(2) %>" />&nbsp;个,请在500-1500之间填写</td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>默认进入版面</strong></td>
      <td><select name="othersettings_3">
	    <option value="0">--</option>
<%
If IsArray(ForumListArray) Then
	For i = 0 To UBound(ForumListArray, 2)
		Response.Write "<option value="""& ForumListArray(0, i) &""""
		If IntCode(Other_Settings(3)) = ForumListArray(0, i) Then Response.Write " selected"
		Response.Write ">"& ForumListArray(1, i) &"</option>"
	Next
End If
%>
      </select></td>
    </tr>
    <!--<tr height="25">
      <td class="altbg1"><strong>右侧默认页面</strong></td>
      <td><input type="radio" name="othersettings_4" id="othersettings_4_0" value="0"<% If Other_Settings(4) = "0" Then Response.Write " checked" End If %> class="radio" /><label for="othersettings_4_0">联盟列表</label>
	    <input type="radio" name="othersettings_4" id="othersettings_4_1" value="1"<% If Other_Settings(4) = "1" Then Response.Write " checked" End If %> class="radio" /><label for="othersettings_4_1">四格帖子列表</label></td>
    </tr>-->
    <tr height="25">
      <td class="altbg1"><strong>新传呼通知的显示方式</strong></td>
      <td><input type="radio" name="othersettings_5" id="othersettings_5_0" value="0"<% If Other_Settings(5) = "0" Then Response.Write " checked" End If %> class="radio" /><label for="othersettings_5_0">弹出新窗口</label>
	    <input type="radio" name="othersettings_5" id="othersettings_5_1" value="1"<% If Other_Settings(5) = "1" Then Response.Write " checked" End If %> class="radio" /><label for="othersettings_5_1">在顶部框架闪烁显示</label></td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub

'========================================================
'保存搜索和其他设置
'========================================================
Sub SaveOtherSettings()
	Dim Other_Settings(5)

	Other_Settings(0) = SafeRequest(2, "othersettings_0", 1, "", 0)
	If Len(Other_Settings(0)) = 0 Then
		Call AdminShowTips("请填写好论坛货币名称。", "")
	End If

	Other_Settings(1) = SafeRequest(2, "othersettings_1", 0, 60, 0)
	Other_Settings(2) = SafeRequest(2, "othersettings_2", 0, 500, 0)
	If Other_Settings(2) < 500 Or Other_Settings(2) > 1500 Then
		Other_Settings(2) = 500
	End If

	Other_Settings(3) = SafeRequest(2, "othersettings_3", 0, 0, 0)
	If Other_Settings(3) = 0 Then
		Call AdminShowTips("请选择默认进入版面。", "")
	End If

	Other_Settings(4) = SafeRequest(2, "othersettings_4", 0, 0, 0)
	Other_Settings(5) = SafeRequest(2, "othersettings_5", 0, 0, 0)

	RQ.Execute("UPDATE "& TablePre &"settings SET other_settings = '"& Join(Other_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()
	
	Call closeDatabase()
	Call AdminshowTips("搜索和其他设置保存成功。", "?action=othersettings")
End Sub

'========================================================
'聊天室设置
'========================================================
Sub ChatSettings()
	Dim SettingsInfo, Chat_Settings

	SettingsInfo = RQ.Query("SELECT chat_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Chat_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;聊天室设置</td>
  </tr>
</table>
<br />
<form method="post" name="chatsettings" action="?action=savechatsettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>聊天室设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否打开聊天室</strong></td>
      <td width="70%"><input type="checkbox" name="chatsettings_0" id="chatsettings_0" value="1" class="radio"<% If Chat_Settings(0) = "1" Then Response.Write " checked" End If %> onclick="showpanel();" /><label for="chatsettings_0">打开</label></td>
    </tr>
    <tr id="p_chatsettings_1" style="display: none;">
      <td class="altbg1"><strong>聊天房间最大数量</strong></td>
      <td><input type="text" name="chatsettings_1" size="5" value="<%= Chat_Settings(1) %>" /> 个，默认300</td>
    </tr>
    <tr id="p_chatsettings_2">
      <td class="altbg1"><strong>发言频率</strong></td>
      <td>两次发言间隔 <input type="text" name="chatsettings_2" size="5" value="<%= Chat_Settings(2) %>" /> 秒，默认5</td>
    </tr>
    <tr id="p_chatsettings_3">
      <td class="altbg1"><strong>刷新聊天记录</strong></td>
      <td>每隔 <input type="text" name="chatsettings_3" size="5" value="<%= Chat_Settings(3) %>" /> 秒刷新一次页面，默认15</td>
    </tr>
    <tr id="p_chatsettings_4">
      <td class="altbg1"><strong>发言使用HTML</strong></td>
      <td><input type="text" name="chatsettings_4" size="5" value="<%= Chat_Settings(4) %>" /> 金币以上才能使用HTML,默认500</td>
    </tr>
	<tr id="p_chatsettings_5">
      <td class="altbg1"><strong>删除发言</strong></td>
      <td><input type="text" name="chatsettings_5" size="5" value="<%= Chat_Settings(5) %>" /> 金币以上才能删除发言,默认300</td>
    </tr>
	<tr id="p_chatsettings_6">
      <td class="altbg1"><strong>删除发言</strong></td>
      <td>扣除 <input type="text" name="chatsettings_6" size="5" value="<%= Chat_Settings(6) %>" /> 金币</td>
    </tr>
	<tr id="p_chatsettings_7">
      <td class="altbg1"><strong>发布聊天室公告</strong></td>
      <td>扣除 <input type="text" name="chatsettings_7" size="5" value="<%= Chat_Settings(7) %>" /> 金币</td>
    </tr>
	<tr id="p_chatsettings_8">
      <td class="altbg1"><strong>清空聊天室发言后的提示</strong><br />可设置多个,用回车隔开,注意用户名的格式.</td>
      <td><textarea name="chatsettings_8" rows="5" cols="50"><%= Chat_Settings(8) %></textarea></td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<script type="text/javascript">
function showpanel(){
	$('p_chatsettings_1').style.display = $('p_chatsettings_2').style.display = $('p_chatsettings_3').style.display = $('p_chatsettings_4').style.display = $('p_chatsettings_5').style.display = $('p_chatsettings_6').style.display = $('p_chatsettings_7').style.display = $('p_chatsettings_8').style.display = $('chatsettings_0').checked ? '' : 'none';
}
showpanel();
</script>
<%
End Sub

'========================================================
'保存聊天室设置
'========================================================
Sub SaveChatSettings()
	Dim Chat_Settings(8)

	Chat_Settings(0) = SafeRequest(2, "chatsettings_0", 0, 0, 0)
	Chat_Settings(1) = SafeRequest(2, "chatsettings_1", 0, 300, 0)
	Chat_Settings(2) = SafeRequest(2, "chatsettings_2", 0, 5, 0)
	Chat_Settings(3) = SafeRequest(2, "chatsettings_3", 0, 15, 0)
	Chat_Settings(4) = SafeRequest(2, "chatsettings_4", 0, 500, 0)
	Chat_Settings(5) = SafeRequest(2, "chatsettings_5", 0, 300, 0)
	Chat_Settings(6) = SafeRequest(2, "chatsettings_6", 0, 1, 0)
	Chat_Settings(7) = SafeRequest(2, "chatsettings_7", 0, 1, 0)
	Chat_Settings(8) = SafeRequest(2, "chatsettings_8", 1, "", 1)

	RQ.Execute("UPDATE "& TablePre &"settings SET chat_settings = '"& Join(Chat_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()
	
	Call closeDatabase()
	Call AdminshowTips("聊天室设置保存成功。", "?action=chatsettings")
End Sub

'========================================================
'wap设置
'========================================================
Sub WapSettings()
	Dim SettingsInfo, Wap_Settings

	SettingsInfo = RQ.Query("SELECT wap_settings FROM "& TablePre &"settings")
	Call closeDatabase()

	If Not IsArray(SettingsInfo) Then
		Call RQ.showTips("错误的站点设置。", "")
	End If

	Wap_Settings = Split(SettingsInfo(0, 0), "{settings}")
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp" target="_parent">系统中心</a>&nbsp;&raquo;&nbsp;WAP设置</td>
  </tr>
</table>
<br />
<form method="post" name="chatsettings" action="?action=savewapsettings" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td colspan="2" height="25"><strong>WAP设置</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>是否打开WAP功能：</strong></td>
      <td width="70%"><input type="checkbox" name="wapsettings_0" id="wapsettings_0" value="1" class="radio"<% If Wap_Settings(0) = "1" Then Response.Write " checked" End If %> onclick="showpanel();" /><label for="wapsettings_0">打开</label></td>
    </tr>
    <tr id="p_wapsettings_1" style="display: none;">
      <td class="altbg1"><strong>是否可以在WAP注册新用户：</strong></td>
      <td><input type="checkbox" name="wapsettings_1" id="wapsettings_1" value="1" class="radio"<% If Wap_Settings(1) = "1" Then Response.Write " checked" End If %> /><label for="wapsettings_1">是的</label></td>
    </tr>
    <tr id="p_wapsettings_2">
      <td class="altbg1"><strong>WAP字符集：</strong><br />UTF-8编码尺寸较小，但遇有乱码等情况可能导致页面无法浏览；UNICODE编码尺寸大很多，但对乱码等有良好的容错性。默认为UNICODE编码</td>
      <td><input type="radio" name="wapsettings_2" id="wapsettings_2_0" value="1" class="radio"<% If Wap_Settings(2) = "1" Then Response.Write " checked" End If %> /><label for="wapsettings_2_0">UTF-8</label>
	    <br /><input type="radio" name="wapsettings_2" id="wapsettings_2_1" value="0" class="radio"<% If Wap_Settings(2) = "0" Then Response.Write " checked" End If %> /><label for="wapsettings_2_1">UNICODE</label></td>
    </tr>
    <tr id="p_wapsettings_3">
      <td class="altbg1"><strong>WAP页面每页显示帖子数量：</strong></td>
      <td><input type="text" name="wapsettings_3" size="5" value="<%= Wap_Settings(3) %>" /> 条</td>
    </tr>
    <tr id="p_wapsettings_4">
      <td class="altbg1"><strong>WAP页面每页显示回复数量：</strong></td>
      <td><input type="text" name="wapsettings_4" size="5" value="<%= Wap_Settings(4) %>" /> 条</td>
    </tr>
	<tr id="p_wapsettings_5">
      <td class="altbg1"><strong>WAP帖子内容每页显示字符数量：</strong><br />用于控制WAP看帖页面长度，并根据该长度对帖子内容进行拆分。建议设置为300~3000以内的整数，以便获得更多的兼容性和浏览易用性。</td>
      <td><input type="text" name="wapsettings_5" size="5" value="<%= Wap_Settings(5) %>" /> 字</td>
    </tr>
    <tr height="25">
	  <td class="altbg1">&nbsp;</td>
	  <td width="70%"><input type="submit" id="btnsubmit" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<script type="text/javascript">
function showpanel(){
	$('p_wapsettings_1').style.display = $('p_wapsettings_2').style.display = $('p_wapsettings_3').style.display = $('p_wapsettings_4').style.display = $('p_wapsettings_5').style.display = $('wapsettings_0').checked ? '' : 'none';
}
showpanel();
</script>
<%
End Sub

'========================================================
'保存WAP设置
'========================================================
Sub SaveWapSettings()
	Dim Wap_Settings(5)

	Wap_Settings(0) = SafeRequest(2, "wapsettings_0", 0, 0, 0)
	Wap_Settings(1) = SafeRequest(2, "wapsettings_1", 0, 0, 0)
	Wap_Settings(2) = SafeRequest(2, "wapsettings_2", 0, 0, 0)
	Wap_Settings(3) = SafeRequest(2, "wapsettings_3", 0, 10, 0)
	Wap_Settings(4) = SafeRequest(2, "wapsettings_4", 0, 10, 0)
	Wap_Settings(5) = SafeRequest(2, "wapsettings_5", 0, 300, 0)

	RQ.Execute("UPDATE "& TablePre &"settings SET wap_settings = '"& Join(Wap_Settings, "{settings}") &"'")
	Call RQ.Reload_Site_Settings()
	
	Call closeDatabase()
	Call AdminshowTips("WAP设置保存成功。", "?action=wapsettings")
End Sub
%>