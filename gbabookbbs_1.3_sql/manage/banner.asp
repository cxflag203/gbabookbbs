<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

'验证是否有编辑用户的权限
If RQ.AdminGroupID <> 1 Then
	Call AdminshowTips("您无权访问该页。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "banuser"
		Call BanUser()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'提交操作
'========================================================
Sub BanUser()


	Call closeDatabase()
	Call AdminshowTips("用户设置已经更新", "?")
End Sub

'========================================================
'禁止用户操作界面
'========================================================
Sub Main()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp?action=right" target="_parent">系统设置</a>&nbsp;&raquo;&nbsp;禁止用户</td>
  </tr>
</table>
<br />
<form method="post" name="banuser" action="?action=banuser" onsubmit="$('submit1').value='正在提交,请稍后...';$('submit1').disabled=true;">
  <table width="98%" class="tableborder" cellSpacing="0" cellPadding="0" align="center" border="0">
    <tr class="header">
      <td height="25" colspan="2"><strong>禁止用户</strong></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>用户名:</strong></td>
      <td width="70%"><input type="text" name="username" size="25" /></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>禁止类型:</strong></td>
      <td width="70%">
	    <input type="radio" name="bantype" id="b_normal" class="radio" value=""><label for="b_normal"> 正常状态</label><br />
		<input type="radio" name="bantype" id="b_post" class="radio" value="post"><label for="b_post"> 禁止发言</label><br />
		<input type="radio" name="bantype" id="b_visit" class="radio" value="visit"><label for="b_visit"> 禁止访问</label>
	  </td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>禁止的有效期:</strong><br />有效期之后用户将恢复为普通用户</td>
      <td width="70%"><select name="expirytime">
	    <option value="0">永久</option>
		<option value="1">一天</option>
		<option value="3">三天</option>
		<option value="5">五天</option>
		<option value="7">一周</option>
		<option value="14">两周</option>
		<option value="30">一个月</option>
		<option value="90">三个月</option>
		<option value="180">半年</option>
	  </select></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>同时删除该用户发表的:</strong></td>
      <td width="70%"><input type="checkbox" name="deletetopic" id="deletetopic" class="radio" value="1"><label for="deletetopic">帖子</label>&nbsp;
	  <input type="checkbox" name="deletepost" id="deletepost" class="radio" value="1"><label for="deletepost">回复</label>&nbsp;
	  <input type="checkbox" name="deletepm" id="deletepm" class="radio" value="1"><label for="deletepm">传呼</label></td>
    </tr>
    <tr height="25">
      <td class="altbg1"><strong>操作原因:</strong></td>
      <td width="70%"><textarea name="reason" rows="5" cols="40"></textarea></td>
    </tr>
    <tr height="25">
      <td class="altbg1">&nbsp;</td>
      <td width="70%"><input type="submit" id="submit1" value="提交设置" class="button" /></td>
    </tr>
  </table>
</form>
<%
End Sub
%>