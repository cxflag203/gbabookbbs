<!--#include file="include/inc.asp"-->
<%
If RQ.AllowViewUserInfo = 0 Then
	Call RQ.showTips("您目前的身份("& RQ.UserGroupName &")，不能查看用户资料。", "", "NOPERM")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "profilepanel"
		Call ProfilePanel()
	Case "saveprofile"
		Call SaveProfile()
	Case "searchpanel", "search"
		Call Search()
	Case Else
		Call Main()
End Select

'========================================================
'保存/更新个人资料
'========================================================
Sub SaveProfile()
	If RQ.UserID = 0 Then
		Call RQ.showTips("请先登陆。", "", "HALTED")
	End If

	Dim Province, Area, Gender, BirthYear, BirthMonth, Birthday, Constellation, Photo, Album, If_Photo
	Dim Profile(69), strProfile
	Dim UserInfo

	Gender = SafeRequest(2, "profile_1", 0, 0, 0)
	BirthYear = SafeRequest(2, "profile_3", 0, 0, 0)
	BirthMonth = SafeRequest(2, "profile_4", 0, 0, 0)
	Birthday = SafeRequest(2, "profile_5", 0, 0, 0)
	Province = SafeRequest(2, "profile_14", 1, "", 0)
	Area = SafeRequest(2, "profile_15", 1, "", 0)
	Photo = SafeRequest(2, "profile_68", 1, "", 0)
	Album = SafeRequest(2, "profile_69", 1, "", 0)

	If Gender > 1 Or Len(CheckContent(Province)) = 0 Or Len(CheckContent(Area)) = 0 Then
		Call RQ.showTips("性别、省份、地区是必选项。", "", "")
	End If

	If BirthYear > 0 Or BirthMonth > 0 Or Birthday > 0 Then
		If Not IsDate(BirthYear &"-"& BirthMonth &"-"& Birthday) Then
			Call RQ.showTips("既然填写了出生日期，那么请把它填写正确。", "", "")
		End If

		Constellation = GetConstellationFromBirthday(BirthMonth, Birthday)
	Else
		Constellation = 0
	End If

	Province = IIF(Len(Province) > 10, Left(Province, 10), Province)
	Area = IIF(Len(Area) > 10, Left(Area, 10), Area)
	If_Photo = IIF(Photo <> "http://" Or Album <> "http://", 1, 0)

	For i = 0 To 69
		Profile(i) = SafeRequest(2, "profile_"& i, 1, "", 0)
	Next

	strProfile = Join(Profile, "{|gbabook}")

	UserInfo = RQ.Query("SELECT 1 FROM "& TablePre &"memberprofiles WHERE uid = "& RQ.UserID)
	If IsArray(UserInfo) Then
		RQ.Execute("UPDATE "& TablePre &"memberprofiles SET profile = N'"& strProfile &"', province = N'"& Province &"', area = N'"& Area &"', gender = "& Gender &", birthyear = "& BirthYear &", birthmonth = "& BirthMonth &", birthday = "& Birthday &", constellation = "& Constellation &", ifphoto = "& If_Photo &" WHERE uid = "& RQ.UserID)
	Else
		RQ.Execute("INSERT INTO "& TablePre &"memberprofiles (uid, profile, province, area, gender, birthyear, birthmonth, birthday, constellation, ifphoto) VALUES ("& RQ.UserID &", N'"& strProfile &"', N'"& Province &"', N'"& Area &"', "& Gender &", "& BirthYear &", "& BirthMonth &", "& Birthday &", "& Constellation &", "& If_Photo &")")
	End If

	Call closeDatabase()
	Call RQ.showTips("您的个人资料已经成功更新。", "?action=profilepanel", "")
End Sub

'========================================================
'根据出生日期判断星座
'========================================================
Function GetConstellationFromBirthday(BirthMonth, Birthday)
	Dim ConstellationBound, BirthNum

	ConstellationBound = Array(121, 219, 321, 421, 521, 622, 723, 823, 923, 1024, 1123, 1222, 1321)
	Birthday = IIF(Len(Birthday) = 1, "0"& Birthday, Birthday)
	BirthNum = IIF(BirthMonth = 1 And Birthday < 21, IntCode(13 & Birthday), IntCode(BirthMonth & Birthday))

	For i = 0 To UBound(ConstellationBound) - 1
		If BirthNum >= ConstellationBound(i) And BirthNum < ConstellationBound(i + 1) Then
			GetConstellationFromBirthday = i + 1
			Exit For
		End If
	Next
End Function

'========================================================
'填写/编辑个人资料界面
'========================================================
Sub ProfilePanel()
	If RQ.UserID = 0 Then
		Call RQ.showTips("请先登陆。", "", "HALTED")
	End If

	Dim UserInfo, Profile(100), TEMP

	UserInfo = RQ.Query("SELECT profile FROM "& TablePre &"memberprofiles WHERE uid = "& RQ.UserID)
	Call closeDataBase()

	If IsArray(UserInfo) Then
		TEMP = Split(UserInfo(0, 0), "{|gbabook}")
		For i = 0 To UBound(TEMP)
			Profile(i) = TEMP(i)
		Next
	End If

	RQ.PageTitle = "个人资料"
	RQ.Header()
%>
<body>
<script type="text/javascript" src="js/getcity.js"></script>
<script type="text/javascript">
function validinput(){
	if ($('gender').value == ""){
		alert("请选择性别");
		$('gender').focus();
		return false;
    }
    if ($('province').value == "" || $('area').value == ""){
		alert("请选择省份和地区");
		$('province').focus();
		return false;
    }
	$('btnsubmit').value = '正在提交,请稍后...';
	$('btnsubmit').disabled = true;
	return true;
}
</script>
<form method="post" id="saveprofile" action="?action=saveprofile" onsubmit="return validinput();">
  <table class="tblborder" style="margin: 0 auto;" align="center" width="98%">
    <tr class="header">
      <td height="25" colspan="2"><strong>登记个人资料</strong></td>
    </tr>
    <tr>
      <td width="25%">用户名</td>
      <td><input type="text" name="profile_0" readonly size="20" value="<%= RQ.UserName %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>性别 </td>
      <td><select id="gender" name="profile_1">
          <option value="">请选择</option>
          <option value="1"<% If Profile(1) = "1" Then Response.Write " selected" %>>男</option>
          <option value="0"<% If Profile(1) = "0" Then Response.Write " selected" %>>女</option>
        </select></td>
    </tr>
    <tr>
      <td>一句话描述自己</td>
      <td><input type="text" name="profile_2" size="20" maxlength="100" value="<%= Profile(2) %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>生日 </td>
      <td><select name="profile_3">
          <%
	For i = Year(Now()) To 1950 Step -1
		Response.Write "<option value="""& i &""""& IIF(IntCode(Profile(3)) = i, " selected", "") &">"& i &"</option>"
	Next
	%>
        </select>
        <select name="profile_4">
          <%
	For i = 1 To 12
		Response.Write "<option value="""& i &""""& IIF(IntCode(Profile(4)) = i, " selected", "") &">"& i &"</option>"
	Next
	%>
        </select>
        <select name="profile_5">
          <%
	For i = 1 To 31
		Response.Write "<option value="""& i &""""& IIF(IntCode(Profile(5)) = i, " selected", "") &">"& i &"</option>"
	Next
	%>
        </select></td>
    </tr>
    <tr>
      <td>Email</td>
      <td><input type="text" name="profile_6" size="20" value="<%= Profile(6) %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>QQ</td>
      <td><input type="text" name="profile_7" size="20" value="<%= Profile(7) %>"  class="inputgrey"/></td>
    </tr>
    <tr>
      <td>ICQ</td>
      <td><input type="text" name="profile_8" size="20" value="<%= Profile(8) %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>MSN</td>
      <td><input type="text" name="profile_9" size="20" value="<%= Profile(9) %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>身高(Cm) </td>
      <td><input type="text" name="profile_10" size="20" value="<%= Profile(10) %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>体重(Kg)</td>
      <td><input type="text" name="profile_11" size="20" value="<%= Profile(11) %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>体形</td>
      <td><select name="profile_12">
          <option value="不知道"<% If Profile(12) = "不知道" Then Response.Write " selected" %>>不知道</option>
          <option value="胖"<% If Profile(12) = "胖" Then Response.Write " selected" %>>胖</option>
          <option value="偏胖"<% If Profile(12) = "偏胖" Then Response.Write " selected" %>>偏胖</option>
          <option value="健壮"<% If Profile(12) = "健壮" Then Response.Write " selected" %>>健壮</option>
          <option value="标准"<% If Profile(12) = "标准" Then Response.Write " selected" %>>标准</option>
          <option value="苗条"<% If Profile(12) = "苗条" Then Response.Write " selected" %>>苗条</option>
          <option value="偏瘦"<% If Profile(12) = "偏瘦" Then Response.Write " selected" %>>偏瘦</option>
          <option value="瘦"<% If Profile(12) = "瘦" Then Response.Write " selected" %>>瘦</option>
        </select></td>
    </tr>
    <tr>
      <td>血型</td>
      <td><select name="profile_13">
          <option value="不知道"<% If Profile(13) = "不知道" Then Response.Write " selected" %>>不知道</option>
          <option value="A"<% If Profile(13) = "A" Then Response.Write " selected" %>>A</option>
          <option value="B"<% If Profile(13) = "B" Then Response.Write " selected" %>>B</option>
          <option value="O"<% If Profile(13) = "O" Then Response.Write " selected" %>>O</option>
          <option value="AB"<% If Profile(13) = "AB" Then Response.Write " selected" %>>AB</option>
        </select></td>
    </tr>
    <tr>
      <td>所在地</td>
      <td><select id="province" name="profile_14" onchange="setcity();">
          <option value="">请选择</option>
          <option value="北京"<% If Profile(14) = "北京" Then Response.Write " selected" %>>北京</option>
          <option value="辽宁"<% If Profile(14) = "辽宁" Then Response.Write " selected" %>>辽宁</option>
          <option value="广东"<% If Profile(14) = "广东" Then Response.Write " selected" %>>广东</option>
          <option value="浙江"<% If Profile(14) = "浙江" Then Response.Write " selected" %>>浙江</option>
          <option value="江苏"<% If Profile(14) = "江苏" Then Response.Write " selected" %>>江苏</option>
          <option value="山东"<% If Profile(14) = "山东" Then Response.Write " selected" %>>山东</option>
          <option value="四川"<% If Profile(14) = "四川" Then Response.Write " selected" %>>四川</option>
          <option value="黑龙江"<% If Profile(14) = "黑龙江" Then Response.Write " selected" %>>黑龙江</option>
          <option value="湖南"<% If Profile(14) = "湖南" Then Response.Write " selected" %>>湖南</option>
          <option value="湖北"<% If Profile(14) = "湖北" Then Response.Write " selected" %>>湖北</option>
          <option value="上海"<% If Profile(14) = "上海" Then Response.Write " selected" %>>上海</option>
          <option value="福建"<% If Profile(14) = "福建" Then Response.Write " selected" %>>福建</option>
          <option value="陕西"<% If Profile(14) = "陕西" Then Response.Write " selected" %>>陕西</option>
          <option value="河南"<% If Profile(14) = "河南" Then Response.Write " selected" %>>河南</option>
          <option value="安徽"<% If Profile(14) = "安徽" Then Response.Write " selected" %>>安徽</option>
          <option value="重庆"<% If Profile(14) = "重庆" Then Response.Write " selected" %>>重庆</option>
          <option value="河北"<% If Profile(14) = "河北" Then Response.Write " selected" %>>河北</option>
          <option value="吉林"<% If Profile(14) = "吉林" Then Response.Write " selected" %>>吉林</option>
          <option value="江西"<% If Profile(14) = "江西" Then Response.Write " selected" %>>江西</option>
          <option value="天津"<% If Profile(14) = "天津" Then Response.Write " selected" %>>天津</option>
          <option value="广西"<% If Profile(14) = "广西" Then Response.Write " selected" %>>广西</option>
          <option value="山西"<% If Profile(14) = "山西" Then Response.Write " selected" %>>山西</option>
          <option value="内蒙古"<% If Profile(14) = "内蒙古" Then Response.Write " selected" %>>内蒙古</option>
          <option value="甘肃"<% If Profile(14) = "甘肃" Then Response.Write " selected" %>>甘肃</option>
          <option value="贵州"<% If Profile(14) = "贵州" Then Response.Write " selected" %>>贵州</option>
          <option value="新疆"<% If Profile(14) = "新疆" Then Response.Write " selected" %>>新疆</option>
          <option value="云南"<% If Profile(14) = "云南" Then Response.Write " selected" %>>云南</option>
          <option value="宁夏"<% If Profile(14) = "宁夏" Then Response.Write " selected" %>>宁夏</option>
          <option value="海南"<% If Profile(14) = "海南" Then Response.Write " selected" %>>海南</option>
          <option value="青海"<% If Profile(14) = "青海" Then Response.Write " selected" %>>青海</option>
          <option value="西藏"<% If Profile(14) = "西藏" Then Response.Write " selected" %>>西藏</option>
          <option value="港澳台"<% If Profile(14) = "港澳台" Then Response.Write " selected" %>>港澳台</option>
          <option value="海外"<% If Profile(14) = "海外" Then Response.Write " selected" %>>海外</option>
          <option value="其它"<% If Profile(14) = "其它" Then Response.Write " selected" %>>其它</option>
        </select>
		<select id="area" name="profile_15">
          <option value="">请选择</option>
        </select>
		<script language="javascript">initprovcity('<%= Profile(14) %>','<%= Profile(15) %>');</script></td>
    </tr>
    <tr>
      <td>行业</td>
      <td><select name="profile_16">
          <option value="保密"<% If Profile(16) = "保密" Then Response.Write " selected" %>>保密</option>
          <option value="金融业"<% If Profile(16) = "金融业" Then Response.Write " selected" %>>金融业</option>
          <option value="服务业"<% If Profile(16) = "服务业" Then Response.Write " selected" %>>服务业</option>
          <option value="信息产业"<% If Profile(16) = "信息产业" Then Response.Write " selected" %>>信息产业</option>
          <option value="制造业"<% If Profile(16) = "制造业" Then Response.Write " selected" %>>制造业</option>
          <option value="传播业"<% If Profile(16) = "传播业" Then Response.Write " selected" %>>传播业</option>
          <option value="教育"<% If Profile(16) = "教育" Then Response.Write " selected" %>>教育</option>
          <option value="政府机构"<% If Profile(16) = "政府机构" Then Response.Write " selected" %>>政府机构</option>
          <option value="医疗保健"<% If Profile(16) = "医疗保健" Then Response.Write " selected" %>>医疗保健</option>
          <option value="房地产"<% If Profile(16) = "房地产" Then Response.Write " selected" %>>房地产</option>
          <option value="其它"<% If Profile(16) = "其它" Then Response.Write " selected" %>>其它</option>
        </select></td>
    </tr>
    <tr>
      <td>职业</td>
      <td><select name="profile_17">
          <option value="保密"<% If Profile(17) = "保密" Then Response.Write " selected" %>>保密</option>
          <option value="待业"<% If Profile(17) = "待业" Then Response.Write " selected" %>>待业</option>
          <option value="退休"<% If Profile(17) = "退休" Then Response.Write " selected" %>>退休</option>
          <option value="学生"<% If Profile(17) = "学生" Then Response.Write " selected" %>>学生</option>
          <option value="专业人士"<% If Profile(17) = "专业人士" Then Response.Write " selected" %>>专业人士</option>
          <option value="经理"<% If Profile(17) = "经理" Then Response.Write " selected" %>>经理</option>
          <option value="公务员"<% If Profile(17) = "公务员" Then Response.Write " selected" %>>公务员</option>
          <option value="职员"<% If Profile(17) = "职员" Then Response.Write " selected" %>>职员</option>
          <option value="私营主"<% If Profile(17) = "私营主" Then Response.Write " selected" %>>私营主</option>
          <option value="其它"<% If Profile(17) = "其它" Then Response.Write " selected" %>>其它</option>
        </select></td>
    </tr>
    <tr>
      <td>学历</td>
      <td><select name="profile_18">
          <option value="保密"<% If Profile(18) = "保密" Then Response.Write " selected" %>>保密</option>
          <option value="小学"<% If Profile(18) = "小学" Then Response.Write " selected" %>>小学</option>
          <option value="初中"<% If Profile(18) = "初中" Then Response.Write " selected" %>>初中</option>
          <option value="高中"<% If Profile(18) = "高中" Then Response.Write " selected" %>>高中</option>
          <option value="大学"<% If Profile(18) = "大学" Then Response.Write " selected" %>>大学</option>
          <option value="硕士"<% If Profile(18) = "硕士" Then Response.Write " selected" %>>硕士</option>
          <option value="博士"<% If Profile(18) = "博士" Then Response.Write " selected" %>>博士</option>
        </select></td>
    </tr>
    <tr>
      <td>收入</td>
      <td><select name="profile_19">
          <option value="保密"<% If Profile(19) = "保密" Then Response.Write " selected" %>>保密</option>
          <option value="500以下"<% If Profile(19) = "500以下" Then Response.Write " selected" %>>500以下</option>
          <option value="501-1000"<% If Profile(19) = "501-1000" Then Response.Write " selected" %>>501-1000</option>
          <option value="1001-2000"<% If Profile(19) = "1001-2000" Then Response.Write " selected" %>>1001-2000</option>
          <option value="2001-4000"<% If Profile(19) = "2001-4000" Then Response.Write " selected" %>>2001-4000</option>
          <option value="4001-6000"<% If Profile(19) = "4001-6000" Then Response.Write " selected" %>>4001-6000</option>
          <option value="6000以上"<% If Profile(19) = "6000以上" Then Response.Write " selected" %>>6000以上</option>
        </select></td>
    </tr>
    <tr>
      <td>婚姻状况</td>
      <td><select name="profile_20">
          <option value="保密"<% If Profile(20) = "保密" Then Response.Write " selected" %>>保密</option>
          <option value="未婚"<% If Profile(20) = "未婚" Then Response.Write " selected" %>>未婚</option>
          <option value="已婚"<% If Profile(20) = "已婚" Then Response.Write " selected" %>>已婚</option>
          <option value="离异无子女"<% If Profile(20) = "离异无子女" Then Response.Write " selected" %>>离异无子女</option>
          <option value="离异有子女"<% If Profile(20) = "离异有子女" Then Response.Write " selected" %>>离异有子女</option>
          <option value="分居"<% If Profile(20) = "分居" Then Response.Write " selected" %>>分居</option>
          <option value="丧偶"<% If Profile(20) = "丧偶" Then Response.Write " selected" %>>丧偶</option>
        </select></td>
    </tr>
    <tr>
      <td>真实姓名&nbsp; </td>
      <td><input type="text" name="profile_21" size="20" value="<%= Profile(21) %>" class="inputgrey" />
        (保密资料)</td>
    </tr>
    <tr>
      <td>联系地址&nbsp; </td>
      <td><input type="text" name="profile_22" size="20" value="<%= Profile(22) %>" class="inputgrey" />
        (保密资料)</td>
    </tr>
    <tr>
      <td>联系电话</td>
      <td><input type="text" name="profile_23" size="20" value="<%= Profile(23) %>" class="inputgrey" />
        (保密资料)</td>
    </tr>
    <tr>
      <td>喜好描述</td>
      <td style="padding: 8px 10px;">喜欢的场所
        <input type="text" name="profile_24" size="20" value="<%= Profile(24) %>" class="inputgrey" />
        <br />
        讨厌的场所
        <input type="text" name="profile_25" size="20" value="<%= Profile(25) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的活动
        <input type="text" name="profile_26" size="20" value="<%= Profile(26) %>" class="inputgrey" />
        <br />
        讨厌的活动
        <input type="text" name="profile_27" size="20" value="<%= Profile(27) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的书籍
        <input type="text" name="profile_28" size="20" value="<%= Profile(28) %>" class="inputgrey" />
        <br />
        喜欢的电影
        <input type="text" name="profile_29" size="20" value="<%= Profile(29) %>" class="inputgrey" />
        <br />
        喜欢的游戏
        <input type="text" name="profile_30" size="20" value="<%= Profile(30) %>" class="inputgrey" />
        <br />
        喜欢的音乐
        <input type="text" name="profile_31" size="20" value="<%= Profile(31) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的食物
        <input type="text" name="profile_32" size="20" value="<%= Profile(32) %>" class="inputgrey" />
        <br />
        讨厌的食物
        <input type="text" name="profile_33" size="20" value="<%= Profile(33) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的口味
        <input type="text" name="profile_34" size="20" value="<%= Profile(34) %>" class="inputgrey" />
        <br />
        讨厌的口味
        <input type="text" name="profile_35" size="20" value="<%= Profile(35) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的饮料
        <input type="text" name="profile_36" size="20" value="<%= Profile(36) %>" class="inputgrey" />
        <br />
        讨厌的饮料
        <input type="text" name="profile_37" size="20" value="<%= Profile(37) %>" class="inputgrey" />
        <br />
        <br />
        烟酒嗜好&nbsp;&nbsp;
        <input type="text" name="profile_38" size="20" value="<%= Profile(38) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的打扮
        <input type="text" name="profile_39" size="20" value="<%= Profile(39) %>" class="inputgrey" />
        <br />
        讨厌的打扮
        <input type="text" name="profile_40" size="20" value="<%= Profile(40) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的品牌
        <input type="text" name="profile_41" size="20" value="<%= Profile(41) %>" class="inputgrey" />
        <br />
        讨厌的品牌
        <input type="text" name="profile_42" size="20" value="<%= Profile(42) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的礼物
        <input type="text" name="profile_43" size="20" value="<%= Profile(43) %>" class="inputgrey" />
        <br />
        讨厌的礼物
        <input type="text" name="profile_44" size="20" value="<%= Profile(44) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的习惯
        <input type="text" name="profile_45" size="20" value="<%= Profile(45) %>" class="inputgrey" />
        <br />
        讨厌的习惯
        <input type="text" name="profile_46" size="20" value="<%= Profile(46) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的行为
        <input type="text" name="profile_47" size="20" value="<%= Profile(47) %>" class="inputgrey" />
        <br />
        讨厌的行为
        <input type="text" name="profile_48" size="20" value="<%= Profile(48) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的植物
        <input type="text" name="profile_49" size="20" value="<%= Profile(49) %>" class="inputgrey" />
        <br />
        最喜欢的花
        <input type="text" name="profile_50" size="20" value="<%= Profile(50) %>" class="inputgrey" />
        <br />
        喜欢的动物
        <input type="text" name="profile_51" size="20" value="<%= Profile(51) %>" class="inputgrey" />
        <br />
        喜欢的季节
        <input type="text" name="profile_52" size="20" value="<%= Profile(52) %>" class="inputgrey" />
        <br />
        喜欢的天气
        <input type="text" name="profile_53" size="20" value="<%= Profile(53) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的颜色
        <input type="text" name="profile_54" size="20" value="<%= Profile(54) %>" class="inputgrey" />
        <br />
        讨厌的颜色
        <input type="text" name="profile_55" size="20" value="<%= Profile(55) %>" class="inputgrey" />
        <br />
        <br />
        喜欢的气味
        <input type="text" name="profile_56" size="20" value="<%= Profile(56) %>" class="inputgrey" />
        <br />
        讨厌的气味
        <input type="text" name="profile_57" size="20" value="<%= Profile(57) %>" class="inputgrey" />
        <br />
        <br />
        喜欢做的事
        <input type="text" name="profile_58" size="20" value="<%= Profile(58) %>" class="inputgrey" />
        <br />
        讨厌做的事
        <input type="text" name="profile_59" size="20" value="<%= Profile(59) %>" class="inputgrey" />
        <br />
        <br />
        最渴望的事
        <input type="text" name="profile_60" size="20" value="<%= Profile(60) %>" class="inputgrey" />
        <br />
        最忌讳的事
        <input type="text" name="profile_61" size="20" value="<%= Profile(61) %>" class="inputgrey" />
        <br />
        最害怕的事
        <input type="text" name="profile_62" size="20" value="<%= Profile(62) %>" class="inputgrey" />
        <br />
        害怕的东西
        <input type="text" name="profile_63" size="20" value="<%= Profile(63) %>" class="inputgrey" />
        <br />
        <br />
        其他<br />
        <textarea rows="5" name="profile_64" cols="40" class="textareagrey"><%= Profile(64) %></textarea></td>
    </tr>
	<tr>
      <td>自我介绍</td>
      <td style="padding: 8px 10px;"><textarea rows="5" name="profile_65" cols="40" class="textareagrey"><%= Profile(65) %></textarea></td>
    </tr>
    <tr>
      <td>性格描述</td>
      <td style="padding: 8px 10px;"><textarea rows="5" name="profile_66" cols="40" class="textareagrey"><%= Profile(66) %></textarea></td>
    </tr>
    <tr>
      <td>特长描述</td>
      <td style="padding: 8px 10px;"><textarea rows="5" name="profile_67" cols="40" class="textareagrey"><%= Profile(67) %></textarea></td>
    </tr>
    <tr>
      <td>照片地址</td>
      <td><input type="text" name="profile_68" size="40" value="<%= IIF(Len(Profile(68)) > 0, Profile(68), "http://") %>" class="inputgrey" /></td>
    </tr>
    <tr>
      <td>相册地址</td>
      <td><input type="text" name="profile_69" size="40" value="<%= IIF(Len(Profile(69)) > 0, Profile(69), "http://") %>" class="inputgrey" /></td>
    </tr>
  </table>
  <p align="center">
    <input type="submit" id="btnsubmit" value="提交设置" class="button" />
  </p>
</form>
<%
	RQ.Footer()
End Sub

'========================================================
'搜索
'========================================================
Sub Search()
	Dim Province, Area, Gender, BirthYear, BirthMonth, Birthday, Constellation, UserName, If_Photo
	Dim strSQL, SqlWhere, MemberListArray
	Dim RecordCount, PageCount, Page

	Province = SafeRequest(3, "province", 1, "", 0)
	Area = SafeRequest(3, "area", 1, "", 0)
	Gender = SafeRequest(3, "gender", 1, "", 0)
	BirthYear = SafeRequest(3, "birthyear", 0, 0, 0)
	BirthMonth = SafeRequest(3, "birthmonth", 0, 0, 0)
	Birthday = SafeRequest(3, "birthday", 0, 0, 0)
	Constellation = SafeRequest(3, "constellation", 0, 0, 0)
	UserName = Replace(Replace(Replace(SafeRequest(3, "username", 1, "", 0), "%", "[%]"), "[", "[[]"), "_", "[_]")
	If_Photo = SafeRequest(3, "ifphoto", 0, 0, 0)

	If Action = "search" Then
		If Len(Request.QueryString("btnsearch")) > 0 Then
			If If_Photo = 0 Then
				If Len(Province) > 0 Then
					SqlWhere = SqlWhere &" AND mp.province = N'"& Province &"'"
				End If

				If Len(Area) > 0 Then
					SqlWhere = SqlWhere &" AND mp.area = N'"& Area &"'"
				End If

				Select Case Gender
					Case "male"
						SqlWhere = SqlWhere &" AND mp.gender = 1"
					Case "female"
						SqlWhere = SqlWhere &" AND mp.gender = 0"
				End Select

				If BirthYear > 0 Then
					SqlWhere = SqlWhere &" AND mp.birthyear = "& BirthYear
				End If

				If BirthMonth > 0 Then
					SqlWhere = SqlWhere &" AND mp.birthmonth = "& BirthMonth
				End If

				If Birthday > 0 Then
					SqlWhere = SqlWhere &" AND mp.birthday = "& Birthday
				End If

				If Constellation > 0 And Constellation < 13 Then
					SqlWhere = SqlWhere &" AND mp.constellation = "& Constellation
				Else
					Constellation = 0
				End If

				If Len(UserName) > 0 Then
					SqlWhere = SqlWhere &" AND m.username LIKE N'%"& UserName &"%'"
				End If
			Else
				SqlWhere = SqlWhere &" AND mp.ifphoto = 1"
			End If

		ElseIf Len(Request.QueryString("btntoday")) > 0 Then
			SqlWhere = SqlWhere &" AND birthmonth = "& Month(Now()) &" AND birthday = "& Day(Now())
		End If

		RecordCount = Conn.Execute("SELECT COUNT(mp.uid) FROM "& TablePre &"memberprofiles mp INNER JOIN "& TablePre &"members m ON mp.uid = m.uid WHERE 1 = 1"& SqlWhere)(0)
		dbQueryNum = dbQueryNum + 1

		If RecordCount > 0 Then
			PageCount = ABS(Int(-(RecordCount / 50)))
			Page = SafeRequest(3, "page", 0, 1, 0)
			Page = IIF(Page > PageCount, PageCount, Page)

			strSQL = "SELECT TOP 50 mp.province, mp.area, mp.birthyear, mp.birthmonth, mp.birthday, m.username FROM "& TablePre &"memberprofiles mp INNER JOIN "& TablePre &"members m ON mp.uid = m.uid WHERE 1 = 1"& SqlWhere

			If Page > 1 Then
				strSQL = strSQL &" AND mp.uid < (SELECT MIN(uid) FROM (SELECT TOP "& 50 * (Page - 1) &" mp.uid FROM "& TablePre &"memberprofiles mp INNER JOIN "& TablePre &"members m ON mp.uid = m.uid WHERE 1 = 1"& SqlWhere &" ORDER BY uid DESC) AS tblTemp)"
			End If

			strSQL = strSQL &" ORDER BY m.uid DESC"

			MemberListArray = RQ.Query(strSQL)
		End If
	End If

	Call closeDataBase()

	RQ.PageTitle = "搜索个人资料"
	RQ.Header()
%>
<body class="blankbg">
<script type="text/javascript" src="js/getcity.js"></script>
<form method="get" id="fmsearch" action="?">
  <input type="hidden" name="action" value="search">
  <table border="0" cellspacing="1" style="border-collapse: collapse" bordercolor="#111111" align="center">
    <tr height="19" bgcolor="#C0C0C0">
      <td>地区</td>
      <td><select id="province" name="province" onchange="setcity();">
          <option value="">随便</option>
          <option value="北京">北京</option>
          <option value="辽宁">辽宁</option>
          <option value="广东">广东</option>
          <option value="浙江">浙江</option>
          <option value="江苏">江苏</option>
          <option value="山东">山东</option>
          <option value="四川">四川</option>
          <option value="黑龙江">黑龙江</option>
          <option value="湖南">湖南</option>
          <option value="湖北">湖北</option>
          <option value="上海">上海</option>
          <option value="福建">福建</option>
          <option value="陕西">陕西</option>
          <option value="河南">河南</option>
          <option value="安徽">安徽</option>
          <option value="重庆">重庆</option>
          <option value="河北">河北</option>
          <option value="吉林">吉林</option>
          <option value="江西">江西</option>
          <option value="天津">天津</option>
          <option value="广西">广西</option>
          <option value="山西">山西</option>
          <option value="内蒙古">内蒙古</option>
          <option value="甘肃">甘肃</option>
          <option value="贵州">贵州</option>
          <option value="新疆">新疆</option>
          <option value="云南">云南</option>
          <option value="宁夏">宁夏</option>
          <option value="海南">海南</option>
          <option value="青海">青海</option>
          <option value="西藏">西藏</option>
          <option value="港澳台">港澳台</option>
          <option value="海外">海外</option>
          <option value="其它">其它</option>
        </select><select id="area" name="area">
          <option value="">请选择</option>
        </select>
		<script language="javascript">initprovcity('<%= Province %>','<%= Area %>');</script>
      </td>
    </tr>
    <tr height="19" bgcolor="#C0C0C0">
      <td>性别</td>
      <td><select name="gender">
          <option value="">随便</option>
          <option value="male"<% If Gender = "male" Then Response.Write " selected" End If %>>男</option>
          <option value="female"<% If Gender = "female" Then Response.Write " selected" End If %>>女</option>
        </select></td>
    </tr>
    <tr height="19" bgcolor="#C0C0C0">
      <td>生日</td>
      <td><select name="birthyear">
	  <option value="0">--</option>
          <%
	For i = Year(Now()) To 1950 Step -1
		Response.Write "<option value="""& i &""""& IIF(BirthYear = i, " selected", "") &">"& i &"</option>"
	Next
	%>
        </select>
        <select name="birthmonth">
		<option value="0">--</option>
          <%
	For i = 1 To 12
		Response.Write "<option value="""& i &""""& IIF(BirthMonth = i, " selected", "") &">"& i &"</option>"
	Next
	%>
        </select>
        <select name="birthday">
		<option value="0">--</option>
          <%
	For i = 1 To 31
		Response.Write "<option value="""& i &""""& IIF(Birthday = i, " selected", "") &">"& i &"</option>"
	Next
	%>
        </select></td>
    </tr>
    <tr height="19" bgcolor="#C0C0C0">
      <td>星座</td>
      <td><select name="constellation">
          <option value="0">随便</option>
          <option value="1"<% If Constellation = 1 Then Response.Write " selected" End If %>>水瓶座(1/21~2/18)</option>
          <option value="2"<% If Constellation = 2 Then Response.Write " selected" End If %>>双鱼座(2/19~3/20)</option>
          <option value="3"<% If Constellation = 3 Then Response.Write " selected" End If %>>牡羊座(3/21~4/20)</option>
          <option value="4"<% If Constellation = 4 Then Response.Write " selected" End If %>>金牛座(4/21~5/20)</option>
          <option value="5"<% If Constellation = 5 Then Response.Write " selected" End If %>>双子座(5/21~6/21)</option>
          <option value="6"<% If Constellation = 6 Then Response.Write " selected" End If %>>巨蟹座(6/22~7/22)</option>
          <option value="7"<% If Constellation = 7 Then Response.Write " selected" End If %>>狮子座(7/23~8/22)</option>
          <option value="8"<% If Constellation = 8 Then Response.Write " selected" End If %>>处女座(8/23~9/22)</option>
          <option value="9"<% If Constellation = 9 Then Response.Write " selected" End If %>>天秤座(9/23~10/23)</option>
          <option value="10"<% If Constellation = 10 Then Response.Write " selected" End If %>>天蝎座(10/24~11/22)</option>
          <option value="11"<% If Constellation = 11 Then Response.Write " selected" End If %>>射手座(11/23~12/21)</option>
          <option value="12"<% If Constellation = 12 Then Response.Write " selected" End If %>>山羊座(12/22~1/20)</option>
      </select></td>
    </tr>
    <tr height="16" bgcolor="#C0C0C0">
      <td>用户名</td>
      <td><input type="text" name="username" size="20" value="<%= UserName %>" /></td>
    </tr>
    <tr height="16" bgcolor="#C0C0C0">
      <td>　</td>
      <td><input type="checkbox" id="ifphoto" name="ifphoto" value="1"<%= IIF(Action = "search" And If_Photo = 1, " checked", "") %> /><label for="ifphoto">只列出有照片的</label></td>
    </tr>
    <tr height="16" bgcolor="#C0C0C0">
      <td>&nbsp;</td>
      <td><input type="submit" value="搜索" name="btnsearch" class="button" />
        <input type="submit" value="今日寿星" name="btntoday" class="button" /></td>
    </tr>
  </table>
</form>
<% If Action = "search" Then %>
<p align="center"><strong>搜索条件</strong>
<br />
省份=<%= IIF(Len(Province) > 0, "<span class=""red"">"& Province &"</span>", "随便") %>,地区=<%= IIF(Len(Area) > 0, "<span class=""red"">"& Area &"</span>", "随便") %>,性别=<% If Gender = "female" Then %><span class="red">女</span><% ElseIf Gender = "male" Then %><span class="red">男</span><% Else %>随便<% End If %>,生日=<span style="color: #0000FF"><%= IIF(BirthYear > 0, BirthYear, "") %>-<%= IIF(BirthMonth > 0, BirthMonth, "") %>-<%= IIF(Birthday > 0, Birthday, "") %></span>,星座=<%= IIF(Constellation > 0, "<span class=""red"">"& ShowConstellationName(Constellation) &"</span>", "随便") %>,用户名=<%= IIF(Len(UserName) > 0, "<span class=""red"">"& UserName &"</span>", "随便") %>
<hr color="black" />
<%
		If IsArray(MemberListArray) Then
			Response.Write "找到"& RecordCount &"个<p><table border=""0"" cellpadding=""2"" cellspacing=""2"" width=""100%"">"

			For i = 0 To UBound(MemberListArray, 2)
				Response.Write IIF(i Mod 2 = 0, "<tr>", "") &"<td width=""33%""><a href=""?u="& MemberListArray(5, i) &""" title="""& MemberListArray(0, i) & MemberListArray(1, i) &""" onclick=""return shows3(this.href);"">"& MemberListArray(5, i) &"</a> ("& MemberListArray(2, i) &"-"& MemberListArray(3, i) &"-"& MemberListArray(4, i) &")</td>"& IIF(i Mod 2 <> 0, "</tr>", "")
			Next

			Erase MemberListArray

			If i Mod 2 <> 0 Then
				Response.Write "<td width=""33%"">&nbsp;</td></tr>"
			End If

			Response.Write "</table>"

			If PageCount > 1 Then
				Call ShowPageInfo(Page, PageCount, RecordCount, "&action=search&province="& Province &"&area="& Area &"&gender="& Gender &"&birthyear="& BirthYear &"&birthmonth="& BirthMonth &"&birthday="& Birthday &"&constellation="& Constellation &"&username="& UserName &"&ifphoto="& If_Photo)
			End If
		Else
			Response.Write "<p align=""center"">未找到相关记录,请重新输入搜索条件......</p>"
		End If
	End If

	RQ.Footer()
End Sub

'========================================================
'显示星座
'========================================================
Function ShowConstellationName(ConstellationID)
	If ConstellationID = 0 Then
		Exit Function
	End If

	Dim ConstellationUbound
	ConstellationUbound = Array("水瓶座", "双鱼座", "牡羊座", "金牛座", "双子座", "巨蟹座", "狮子座", "处女座", "天秤座", "天蝎座", "射手座", "山羊座")
	ShowConstellationName = ConstellationUbound(ConstellationID - 1)
End Function

'========================================================
'查看用户资料
'========================================================
Sub Main()
	Dim UserName, UserID, UserInfo, UserProfile, SqlWhere
	Dim Profile, PostID

	UserName = SafeRequest(3, "u", 1, "", 1)
	UserID = SafeRequest(3, "uid", 0, 0, 0)
	PostID = SafeRequest(3, "pid", 0, 0, 0)

	If UserID = 0 Then
		If Len(UserName) = 0 Then
			Call RQ.showTips("请填写好用户名。", "", "")
		End If
		SqlWhere = "username = N'"& UserName &"'"
	Else
		SqlWhere = "uid = "& UserID
	End If

	UserInfo = RQ.Query("SELECT uid, username FROM "& TablePre &"members WHERE "& SqlWhere)
	If Not IsArray(UserInfo) Then
		Call RQ.showTips("用户不存在或者已经被删除。", "", "")
	End If

	UserProfile = RQ.Query("SELECT profile, constellation FROM "& TablePre &"memberprofiles WHERE uid = "& UserInfo(0, 0))
	Call closeDataBase()

	If IsArray(UserProfile) Then
		Profile = Split(UserProfile(0, 0), "{|gbabook}")
	End If

	RQ.PageTitle = "个人资料"
	RQ.Header()
%>
<body style="background: #97baf4;">
<style>
html { scrollbar-base-color: #97BAF4; scrollbar-face-color: #D4D0C8; scrollbar-shadow-color: #97BAF4; scrollbar-highlight-color: #97BAF4; scrollbar-3dlight-color: #97BAF4; scrollbar-darkshadow-color: #97BAF4; scrollbar-track-color: #97BAF4; scrollbar-arrow-color: #97BAF4 }
</style>
<div style="text-align: center;">
  <form id="search" method="get" action="?">
    用户名:
    <input type="text" name="u" size="5" />
    <input type="submit" value="提交" class="button" />
    <a href="?action=searchpanel">组合查询</a> <a href="?action=profilepanel" style="background-color: #0F0">登记资料</a> [<a href="search.asp?action=search&keyword=<%= Server.UrlEncode(UserInfo(1, 0)) %>&searchtype=author" class="underline"><strong><%= UserInfo(1, 0) %></strong>所发帖</a>]<% If PostID > 0 Then %>[<a href="###" onclick="postvalue('item.asp?action=useitem&pid=<%= PostID %>', 'itemid', '12')">匿名</a>]<% End If %>
  </form>
  <p>
  <% If IsArray(Profile) Then %>
  <table border="0" class="profiletd">
    <tr>
      <td>用户名</td>
      <td><input type="text" size="20" value="<%= UserInfo(1, 0) %>">
        [<a href="pm.asp?action=send&u=<%= UserName %>" onclick="return shows(this.href);" class="underline">发送传呼</a>]</td>
    </tr>
    <tr>
      <td>自我描述</td>
      <td><input type="text" size="40" value="<%= Profile(2) %>" /></td>
    </tr>
    <tr>
      <td>性别 </td>
      <td><input type="text" size="20" value="<%= IIF(Profile(1) = "1", "男", "女") %>" /></td>
    </tr>
    <tr>
      <td>生日 </td>
      <td><input type="text" size="20" value="<%= Profile(3)%>-<%= Profile(4) %>-<%= Profile(5) %>" /></td>
    </tr>
    <tr>
      <td>星座</td>
      <td><input type="text" size="20" value="<%= ShowConstellationName(UserProfile(1, 0)) %>" /></td>
    </tr>
    <tr>
      <td>Email</td>
      <td><input type="text" size="40" value="<%= Profile(6) %>" /></td>
    </tr>
    <tr>
      <td>QQ</td>
      <td><input type="text"size="20" value="<%= Profile(7) %>" /></td>
    </tr>
    <tr>
      <td>ICQ</td>
      <td><input type="text" size="20" value="<%= Profile(8) %>" /></td>
    </tr>
    <tr>
      <td>MSN</td>
      <td><input type="text" size="40" value="<%= Profile(9) %>" /></td>
    </tr>
    <tr>
      <td>身高</td>
      <td><input type="text" size="20" value="<%= Profile(10) %>" /></td>
    </tr>
    <tr>
      <td>体重</td>
      <td><input type="text" size="20" value="<%= Profile(11) %>" /></td>
    </tr>
    <tr>
      <td>体形</td>
      <td><input type="text" size="20" value="<%= Profile(12) %>" /></td>
    </tr>
    <tr>
      <td>血型</td>
      <td><input type="text" size="20" value="<%= Profile(13) %>" /></td>
    </tr>
    <tr>
      <td>所在地</td>
      <td><input type="text" size="40" value="<%= Profile(14) %><%= Profile(15) %>" /></td>
    </tr>
    <tr>
      <td>行业</td>
      <td><input type="text" size="20" value="<%= Profile(16) %>" /></td>
    </tr>
    <tr>
      <td>职业</td>
      <td><input type="text" size="20" value="<%= Profile(17) %>" /></td>
    </tr>
    <tr>
      <td>学历</td>
      <td><input type="text" size="20" value="<%= Profile(18) %>" /></td>
    </tr>
    <tr>
      <td>收入</td>
      <td><input type="text" size="20" value="<%= Profile(19) %>" /></td>
    </tr>
    <tr>
      <td> 婚姻状况</td>
      <td><input type="text" size="20" value="<%= Profile(20) %>" /></td>
    </tr>
    <tr>
      <td>喜好描述</td>
      <td><textarea rows="8" cols="40">
喜欢的场所:<%= Profile(24) %>
讨厌的场所:<%= Profile(25) %>
喜欢的活动:<%= Profile(26) %>
讨厌的活动:<%= Profile(27) %>

喜欢的书籍:<%= Profile(28) %>
喜欢的电影:<%= Profile(29) %>
喜欢的游戏:<%= Profile(30) %>
喜欢的音乐:<%= Profile(31) %>
喜欢的食物:<%= Profile(32) %>
讨厌的食物:<%= Profile(33) %>
喜欢的口味:<%= Profile(34) %>
讨厌的口味:<%= Profile(35) %>
喜欢的饮料:<%= Profile(36) %>
讨厌的饮料:<%= Profile(37) %>
烟酒嗜好:<%= Profile(38) %>

喜欢的打扮:<%= Profile(39) %>
讨厌的打扮:<%= Profile(40) %>
喜欢的品牌:<%= Profile(41) %>
讨厌的品牌:<%= Profile(42) %>
喜欢的礼物:<%= Profile(43) %>
讨厌的礼物:<%= Profile(44) %>

喜欢的习惯:<%= Profile(45) %>
讨厌的习惯:<%= Profile(46) %>
喜欢的行为:<%= Profile(47) %>
讨厌的行为:<%= Profile(48) %>
喜欢的植物:<%= Profile(49) %>
最喜欢的花:<%= Profile(50) %>

喜欢的动物:<%= Profile(51) %>
喜欢的季节:<%= Profile(52) %>
喜欢的天气:<%= Profile(53) %>
喜欢的颜色:<%= Profile(54) %>
讨厌的颜色:<%= Profile(55) %>
喜欢的气味:<%= Profile(56) %>
讨厌的气味:<%= Profile(57) %>

喜欢做的事:<%= Profile(58) %>
讨厌做的事:<%= Profile(59) %>
最渴望的事:<%= Profile(60) %>
最忌讳的事:<%= Profile(61) %>
最害怕的事:<%= Profile(62) %>
害怕的东西:<%= Profile(63) %>

其他:<%= Profile(64) %>
</textarea></td>
    </tr>
    <td>自我介绍</td>
      <td><textarea rows="8" cols="40"><%= Profile(65) %></textarea></td>
    </tr>
    <tr>
      <td>性格描述</td>
      <td><textarea rows="8" cols="40"><%= Profile(66) %></textarea></td>
    </tr>
    <tr>
      <td>特长描述</td>
      <td><textarea rows="8" cols="40"><%= Profile(67) %></textarea></td>
    </tr>
    <% If Len(Profile(68)) > 0 And Profile(69) <> "http://" Then %>
    <tr>
      <td>相关照片</td>
      <td><a href="<%= Profile(68) %>" target="_blank" class="underline" />点击查看照片</a></td>
    </tr>
    <% End If %>
    <% If Len(Profile(69)) > 0 And Profile(69) <> "http://" Then %>
    <tr>
      <td>相册地址</td>
      <td><a href="<%= Profile(69) %>" target="_blank" class="underline" />点击进入相册</a></td>
    </tr>
    <% End If %>
  </table>
  <% Else %>
  该用户尚未登记资料
  <% End If %>
</div>
<%
	RQ.Footer()
End Sub
%>
