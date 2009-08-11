<!--#include file="include/inc.asp"-->
<%
If RQ.UserID = 0 Then
	Call RQ.showTips("请先登陆。", "", "NOPERM")
End If

Dim Action
Action = Request.QueryString("action")

Select Case Action
	Case "creditstransfer"
		Call CreditsTransfer()
	Case Else
		Call Main()
End Select

'========================================================
'提交转让操作
'========================================================
Sub CreditsTransfer()
	Dim ReceiveMethod, UserName, TransMethod, Credits, Reason
	Dim MemberListArray, PostListArray
	Dim Members, CreditsTransNum, CreditsTotalNum, UserIDs, UserNames, TEMP, n

	ReceiveMethod = SafeRequest(2, "receivmethod", 1, "", 0)
	UserName = SafeRequest(2, "username", 1, "", 0)
	TransMethod = SafeRequest(2, "transmethod", 1, "", 0)
	Credits = SafeRequest(2, "credits", 0, 0, 0)
	Reason = SafeRequest(2, "reason", 1, "", 0)

	If Not InArray(Array("inputtid", "inputusername"), ReceiveMethod) Then
		Call RQ.showTips("请选择接收用户的方式。", "", "")
	End If

	If ReceiveMethod = "inputtid" And RQ.TopicID = 0 Then
		Call RQ.showTips("请填写好帖子编号（tid）。", "", "")
	ElseIf ReceiveMethod = "inputusername" And Len(CheckContent(UserName)) = 0 Then
		Call RQ.showTips("请填写好接收用户。", "", "")
	End If

	If Not InArray(Array("foraverage", "foreachuser"), TransMethod) Then
		Call RQ.showTips("请选择转让的方式。", "", "")
	End If

	If Credits = 0 Then
		Call RQ.showTips("请填写好要转让的"& RQ.Other_Settings(0) &"数量。", "", "")
	End If

	If Len(CheckContent(Reason)) = 0 Then
		Call RQ.showTips("请填写好转让原因。", "", "")
	End If
	Reason = IIF(Len(Reason) > 255, Left(Reason, 255), Reason)

	'读取回复帖子的用户
	If ReceiveMethod = "inputusername" Then
		TEMP = Split(UserName, ",")
		For i = 0 To UBound(TEMP)
			If Len(TEMP(i)) > 0 And Len(TEMP(i)) <= 20 Then
				UserNames = UserNames &"N'"& TEMP(i) &"',"
			End If
		Next

		If Right(UserNames, 1) = "," Then
			UserNames = Left(UserNames, Len(UserNames) - 1)
		End If

		MemberListArray = RQ.Query("SELECT uid FROM "& TablePre &"members WHERE username IN("& UserNames &")")
		If Not IsArray(MemberListArray) Then
			Call RQ.showTips("您填写的接收用户无效。", "", "")
		End If
	Else
		'输入帖子编号
		MemberListArray = RQ.Query("SELECT DISTINCT(uid) FROM "& TablePre &"posts WHERE tid = "& RQ.TopicID &" AND iffirst = 0 AND uid > 0")
		If Not IsArray(MemberListArray) Then
			Call RQ.showTips("帖子不存在或者还没有人回复，无法转让"& RQ.Other_Settings(0), "", "")
		End If
	End If

	'计算总人数
	Members = UBound(MemberListArray, 2) + 1

	'输入金币总数，平均转让
	If TransMethod = "foraverage" Then
		'根据平均每人所得数量验证金币总量是否足够
		CreditsTransNum = Credits / Members
		If CreditsTransNum < 1 Then
			Call RQ.showTips("有"& Members &"人接收"& RQ.Other_Settings(0) &"，而您发放的总数不够。", "", "")
		End If

		'计算平均获得每个用户获得的金币数量
		CreditsTransNum = CLng(CreditsTransNum)

		'计算转让人转出金币总数
		CreditsTotalNum = Credits
	Else
		'每人获得金钱数量
		CreditsTransNum = Credits

		'计算转让人转出金币总数
		CreditsTotalNum = Members * Credits
	End If

	'验证转让人的金币数量是否足够
	If RQ.UserCredits < CreditsTotalNum Then
		Call RQ.showTips("您要转让的"& RQ.Other_Settings(0) &"总数量为"& CreditsTotalNum &"，而您的"& RQ.Other_Settings(0) &"不够。", "", "")
	End If

	'减去转让人的金币
	RQ.Execute("UPDATE "& TablePre &"members SET credits = credits - "& CreditsTotalNum &" WHERE uid = "& RQ.UserID)

	'用循环获得帖子回复用户的id集合
	For i = 0 To (Members - 1)
		UserIDs = UserIDs & MemberListArray(0, i)
		If i <> (Members - 1) Then
			UserIDs = UserIDs &","
		End If
	Next

	'更新能接收金币转让的用户金币数量
	n = RQ.Execute("UPDATE "& TablePre &"members SET credits = credits + "& CreditsTransNum &" WHERE uid IN("& UserIDs &") AND credits >= "& IntCode(RQ.User_Settings(7)))

	'如果有接收成功的用户，则写入异动报告
	If n > 0 Then
		RQ.Execute("INSERT INTO "& TablePre &"logs (uid, username, userip, targetuid, targetusername, operation, reason) SELECT "& RQ.UserID &", N'"& RQ.UserName &"', '"& RQ.UserIP &"', uid, username, N'"& RQ.Other_Settings(0) &"批转，发放总量为："& CreditsTotalNum &"，平均每人获得"& CreditsTransNum & RQ.Other_Settings(0) &"。', N'"& Reason &"' FROM "& TablePre &"members WHERE uid IN("& UserIDs &") AND credits >= "& IntCode(RQ.User_Settings(7)))
	End If

	'写入无法接收金币的用户异动报告
	RQ.Execute("INSERT INTO "& TablePre &"logs (uid, username, userip, targetuid, targetusername, operation, reason) SELECT "& RQ.UserID &", N'"& RQ.UserName &"', '"& RQ.UserIP &"', uid, username, N'"& RQ.Other_Settings(0) &"批转，发放总量为："& CreditsTotalNum &"，平均每人获得"& CreditsTransNum & RQ.Other_Settings(0) &"。<span class=""pink"">但是由于接收人的"& RQ.Other_Settings(0) &"未达到"& RQ.User_Settings(7) &"，没有接收到。</span>', N'"& Reason &"' FROM "& TablePre &"members WHERE uid IN("& UserIDs &") AND credits < "& IntCode(RQ.User_Settings(7)))

	Call closeDatabase()
	Call RQ.showTips(RQ.Other_Settings(0) &"转让完毕，转让记录已经计入您的异动报告。", "../membercp.asp", "")
End Sub

'========================================================
'显示转让界面
'========================================================
Sub Main()
	RQ.Header()
%>
<div class="warning">
  1. <%= RQ.Other_Settings(0) %>低于<%= RQ.User_Settings(7) %>的用户将无法接收<br />
  2. 如果要对某帖子的所有回帖用户发放<%= RQ.Other_Settings(0) %>，请直接填写帖子编号（tid）<br />
  3. 如果要自己填写接收<%= RQ.Other_Settings(0) %>的用户，请注意填写的用户名中不要包括称号，多个用户用<strong>英文逗号</strong>隔开，例如：张三,李四<br />
</div>
<br />
<form method="post" action="?action=creditstransfer" onsubmit="if(!confirm('是否确定所有信息都填写无误？'))return false;$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" class="tblborder">
    <tr class="header">
      <td height="25" colspan="2"><strong><%= RQ.Other_Settings(0) %>转让</strong></td>
    </tr>
    <tr height="25">
      <td width="30%">接收用户方式：</td>
      <td><input type="radio" id="receivmethod_1" name="receivmethod" value="inputtid" onclick="showpanel();" /><label for="receivmethod_1">填写帖子ID对回复人进行批转</label>
	    <br /><input type="radio" id="receivmethod_2" name="receivmethod" value="inputusername" onclick="showpanel();" /><label for="receivmethod_2">直接填写接收用户</label></td>
    </tr>
	<tr height="25" id="p_inputtid" style="display: none;">
      <td>帖子编号（tid）：</td>
      <td><input type="text" name="tid" size="20" class="inputgrey" /></td>
    </tr>
	<tr height="25" id="p_inputusername" style="display: none;">
      <td>接收人：</td>
      <td style="padding: 8px 10px;"><textarea name="username" rows="5" cols="40" class="textareagrey" style="width: 90%"></textarea></td>
    </tr>
	<tr height="25">
      <td>转让方式：</td>
      <td><input type="radio" id="transmethod_1" name="transmethod" value="foraverage" /><label for="transmethod_1">输入<%= RQ.Other_Settings(0) %>转让的总数量，平均分配给每个人</label>
	    <br /><input type="radio" id="transmethod_2" name="transmethod" value="foreachuser" /><label for="transmethod_2">输入每人获得的<%= RQ.Other_Settings(0) %>数量</label></td>
    </tr>
	<tr height="25" id="p_inputtid">
      <td><%= RQ.Other_Settings(0) %>数量：</td>
      <td><input type="text" name="credits" size="20" class="inputgrey" /> <%= RQ.Other_Settings(0) %></td>
    </tr>
	<tr height="25">
      <td>转让原因：</td>
      <td><input type="text" name="reason" size="30" maxlength="255" class="inputgrey" /></td>
    </tr>
	<tr height="25">
      <td>&nbsp;</td>
      <td><input type="submit" id="btnsubmit" value="确定转让" class="button" /></td>
    </tr>
  </table>
</form>
<script type="text/javascript">
function showpanel(){
	$('p_inputtid').style.display = $('receivmethod_1').checked ? '' : 'none';
	$('p_inputusername').style.display = $('receivmethod_2').checked ? '' : 'none';
}
</script>
<%
	RQ.Footer()
End Sub
%>