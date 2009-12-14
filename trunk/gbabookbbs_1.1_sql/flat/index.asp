<!--#include file="../include/inc.asp"-->
<%
Call Main()

Sub Main()
	Dim f_ListArray, ForumListArray, ForumInfo(12, 0), aryModerators, aryLastPost
	Dim Dict, ForumGroupID, strMenu, TodayPosts, Topics, Posts, n, t, j
	ReDim CateListArray(1, 0)

	ForumGroupID = SafeRequest(3, "gid", 0, 0, 0)

	f_ListArray = RQ.Query("SELECT f.fid, f.name, f.parentid, f.childs, f.rootfid, f.topics, f.posts, f.todayposts, f.lastpost, f.visitndcredits, ff.description, ff.icon, ff.moderators, ff.viewperm FROM "& TablePre &"forums f INNER JOIN "& TablePre &"forumfields ff ON f.fid = ff.fid"& IIF(ForumGroupID > 0, " WHERE f.rootfid = "& ForumGroupID, "") &" ORDER BY f.displayorder ASC")

	If IsArray(f_ListArray) Then
		Set Dict = Server.CreateObject("Scripting.Dictionary")
		n = 0
		For i = 0 To UBound(f_ListArray, 2)
			If f_ListArray(2, i) > 0 Then
				'读取版面列表
				If Len(f_ListArray(13, i)) = 0 Or InStr(","& f_ListArray(13, i) &",", ","& RQ.UserGroupID &",") > 0 Then
					If f_ListArray(2, i) = f_ListArray(4, i) Then
						'二级版面
						ForumListArray = Dict.Item("cat"& f_ListArray(2, i))
						If IsArray(ForumListArray) Then						
							t = UBound(ForumListArray, 2) + 1
							ReDim Preserve ForumListArray(12, t)
							For j = 0 To 12
								ForumListArray(j, t) = f_ListArray(j, i)
							Next
							Dict.Item("cat"& f_ListArray(2, i)) = ForumListArray
						Else
							For j = 0 To 12
								ForumInfo(j, 0) = f_ListArray(j, i)
							Next
							Dict.Item("cat"& f_ListArray(2, i)) = ForumInfo
						End If
					Else
						'三级版面
						Dict.Item("forum"& f_ListArray(2, i)) = Dict.Item("forum"& f_ListArray(2, i)) &"<a href=""forumdisplay.asp?fid="& f_ListArray(0, i) &""">"& f_ListArray(1, i) &"</a>&nbsp;&nbsp;"
					End If

					'版面最后发帖
					If RQ.UserCredits >= f_ListArray(9, i) Or f_ListArray(9, i) = 0 Then
						If Len(f_ListArray(8, i)) > 0 Then
							aryLastPost = Split(f_ListArray(8, i), Chr(9))
							Dict.Item("forum_lp"& f_ListArray(0, i)) = "<a href=""redirect.asp?tid="& aryLastPost(0) &"&goto=lastpost#lastpost"">"& CutString(aryLastPost(1), 34) &"</a><cite>by "& IIF(Len(aryLastPost(3)) > 0, "<a href=""space.asp?username="& Server.URLEncode(aryLastPost(3)) &""">"& aryLastPost(3) &"</a>", "匿名") &" - "& CDate(aryLastPost(2)) &"</cite>"
						Else
							Dict.Item("forum_lp"& f_ListArray(0, i)) = "从未"
						End If
					Else
						Dict.Item("forum_lp"& f_ListArray(0, i)) = "私密论坛"
					End If
				End If
				TodayPosts = TodayPosts + f_ListArray(7, i)
				Topics = Topics + f_ListArray(5, i)
				Posts = Posts + f_ListArray(6, i)
			Else
				'读取分区列表
				ReDim Preserve CateListArray(1, n)
				CateListArray(0, n) = f_ListArray(0, i)
				CateListArray(1, n) = f_ListArray(1, i)
				n = n + 1
			End If

			'版主列表
			If Len(f_ListArray(12, i)) > 0 Then
				aryModerators = Split(f_ListArray(12, i), Chr(9))
				For j = 0 To UBound(aryModerators)
					Dict.Item("forum_m"& f_ListArray(0, i)) = Dict.Item("forum_m"& f_ListArray(0, i)) &"<a class=""notabs"" href=""space.asp?username="& Server.URLEncode(aryModerators(j)) &""">"& aryModerators(j) &"</a>"& IIF(j <> UBound(aryModerators), ", ", "")
				Next
			End If
		Next
		f_ListArray = Empty
		ForumListArray = Empty
	End If

	t = 0

	If RQ.UserID > 0 Then
		If ForumGroupID > 0 then
			strMenu = "<a href=""index.asp"">"& RQ.Base_Settings(0) &"</a>"
		Else
			strMenu = "<a href=""space.php?action=viewpro&amp;uid=1"" class=""dropmenu"" id=""creditlist"" onmouseover=""showMenu(this.id)"">"& RQ.UserName &"</a>"
		End If
		strMenu = strMenu &" - <a href=""space.php?uid=1"" target=""_blank"">个人空间</a>"
	Else
		strMenu = "<a href=""index.asp"">"& RQ.Base_Settings(0) &"</a>"
	End If

	Call closeDatabase()
	RQ.FlatHeader()
%>
<div id="foruminfo">
<div id="userinfo">
<div id="nav"><%= strMenu %></div>
<p>
<% If RQ.UserID > 0 Then %>
状态: <span id="loginstatus"><a href="member.php?action=switchstatus" title="切换到隐身模式" onclick="ajaxget(this.href, 'loginstatus');doane(event);">正常模式</a></span>,
您上次访问是在: <em>2009-12-13 10:52</em> &nbsp; <a href="search.php?srchfrom=2000&amp;searchsubmit=yes">查看新帖</a> <a href="member.php?action=markread" id="ajax_markread" onclick="ajaxmenu(event, this.id)">标记已读</a>
<% Else %>
<form id="loginform" method="post" name="login" action="logging.php?action=login&amp;loginsubmit=true">
<input type="hidden" name="cookietime" value="2592000" />
<input type="text" id="username" name="username" size="15" maxlength="40" tabindex="1" value="用户名" onclick="this.value = ''" />
<input type="password" id="password" name="password" size="10" tabindex="2" onkeypress="if((event.keyCode ? event.keyCode : event.charCode) == 13) $('loginform').submit()" />
<button name="userlogin" type="submit" value="true">登录</button>
</form>
<% End If %>
</p>
</div>
<div id="forumstats">
<p> 今日: <em><%= TodayPosts %></em>, 昨日: <em>1</em>, 最高日: <em>1</em> &nbsp; <a href="digest.php">精华区</a> <a href="rss.php?auth=btmivDoI%2B7OhNInSB4W0fHANpw" title="RSS 订阅全部版块" target="_blank"><img src="images/common/xml.gif" alt="RSS 订阅全部版块" /></a> </p>
<p>主题: <em><%= Topics %></em>, 帖子: <em><%= Posts %></em>, 会员: <em>1</em>, 欢迎新会员 <cite><a href="space.php?username=admin">admin</a></cite></p>
</div>
</div>
<div id="ad_text"></div>
<table summary="HeadBox" class="portalbox" cellpadding="0" cellspacing="1">
<tr> </tr>
</table>
<% If n > 0 Then %>
<% For i = 0 To UBound(CateListArray, 2) %>
<% ForumListArray = Dict.Item("cat"& CateListArray(0, i)) %>
<% If IsArray(ForumListArray) Then %>
<div class="mainbox forumlist">
<span class="headactions"><% If Len(Dict.Item("forum_m"& CateListArray(0, i))) > 0 Then %>分区版主: <%= Dict.Item("forum_m"& CateListArray(0, i)) %><% End If %>
<img id="category_1_img" src="images/default/collapsed_no.gif" title="收起/展开" alt="收起/展开" onclick="toggle_collapse('category_1');" /> </span>
<h3><a href="index.asp?gid=<%= CateListArray(0, i) %>"><%= CateListArray(1, i) %></a></h3>
<table id="category_1" summary="category1" cellspacing="0" cellpadding="0" style="">
<thead class="category">
<tr>
<th>版块</th>
<td class="nums">主题</td>
<td class="nums">帖数</td>
<td class="lastpost">最后发表</td>
</tr>
</thead>
<% For t = 0 To UBound(ForumListArray, 2) %>
<tbody id="forum2">
<tr>
<th><% If Len(ForumListArray(11, t)) > 0 Then %><a href="forumdisplay.asp?fid=<%= ForumListArray(0, t) %>"><img style="margin-right: 10px" src="<%= ForumListArray(11, t) %>" align="left" alt="" border="0" /></a><% End If %><h2><a href="forumdisplay.asp?fid=<%= ForumListArray(0, t) %>"><%= ForumListArray(1, t) %></a><% If ForumListArray(7, t) > 0 Then %><em> (今日: <%= ForumListArray(7, t) %>)</em><% End If %></h2>
<% If Len(ForumListArray(10, t)) > 0 Then %><p><%= ForumListArray(10, t) %></p><% End If %>
<% If Len(Dict.Item("forum"& ForumListArray(0, t))) > 0 Then %><p>子版块: <%= Dict.Item("forum"& ForumListArray(0, t)) %></p><% End If %>
<% If Len(Dict.Item("forum_m"& ForumListArray(0, t))) > 0 Then %><p>版主: <%= Dict.Item("forum_m"& ForumListArray(0, t)) %></p><% End If %></th>
<td class="nums"><%= ForumListArray(5, t) %></td>
<td class="nums"><%= ForumListArray(6, t) %></td>
<td class="lastpost"><%= Dict.Item("forum_lp"& ForumListArray(0, t)) %></td>
</tr>
</tbody>
<% Next %>
</table>
</div>
<div id="ad_intercat_<%= CateListArray(0, i) %>"></div>
<% End If %>
<% Next %>
<% End If %>
<div class="box"> <span class="headactions"><img id="forumlinks_img" src="images/default/collapsed_no.gif" alt="" onclick="toggle_collapse('forumlinks');" /></span>
<h4>友情链接</h4>
<table summary="联盟论坛" id="forumlinks" cellpadding="0" cellspacing="0" style="">
<tr>
<td>
<a href="http://www.gbabook.com" target="_blank"><img src="http://www.hdcdape.com/attachments/lianmenglogo/mazi.gif" border="0" alt="GBABOOK1" /></a>
<a href="http://www.gbabook.com" target="_blank"><img src="http://localhost/asp/gbabookbbs/develop/gbabookbbs_1.1_sql/flat/images/logo.gif" border="0" alt="GBABOOK2" /></a>
<br />
<a href="http://www.hdcdape.com" target="_blank">[HDCD]</a>
<a href="http://www.btchina.net" target="_blank">[BTCHINA]</a>
</td>
</tr>
</table>
</div>
<div class="box" id="online"> <span class="headactions"><a href="index.php?showoldetails=no#online" title="关闭"><img src="images/default/collapsed_no.gif" alt="关闭" /></a></span>
<h4> <strong><a href="member.php?action=online">在线会员</a></strong> - <em>1</em> 人在线
- <em>1</em> 会员(<em>0</em> 隐身), <em>0</em> 位游客
- 最高记录是 <em>1</em> 于 <em>2002-12-16</em>. </h4>
<dl id="onlinelist">
<dt><img src="images/common/online_admin.gif" alt="" /> 管理员 &nbsp; &nbsp; &nbsp; <img src="images/common/online_supermod.gif" alt="" /> 超级版主 &nbsp; &nbsp; &nbsp; <img src="images/common/online_moderator.gif" alt="" /> 版主 &nbsp; &nbsp; &nbsp; <img src="images/common/online_member.gif" alt="" /> 会员 &nbsp; &nbsp; &nbsp; </dt>
<dd>
<ul class="userlist">
<li title="时间: 11:17
操作: 浏览论坛首页 "> <img src="images/common/online_admin.gif" alt="" /> <a href="space.php?uid=1">admin</a> </li>
</ul>
</dd>
</dl>
</div>
<div class="legend">
<label><img src="images/default/forum_new.gif" alt="有新帖的版块" />有新帖的版块</label>
<label><img src="images/default/forum.gif" alt="无新帖的版块" />无新帖的版块</label>
</div>
<ul class="popupmenu_popup" id="creditlist_menu" style="display: none">
<li><%= RQ.Other_Settings(0) %>: <%= RQ.UserCredits %></li>
</ul>
<%
	Set Dict = Nothing
	RQ.FlatFooter()
End Sub
%>