<!--#include file="include/admininc.asp"-->
<%
AdminHeader()

'站长和高级管理员才能访问
If RQ.AdminGroupID <> 1 And RQ.AdminGroupID <> 2 Then
	Call AdminshowTips("您无权进行访问。", "")
End If

Dim Action
Action = Request.QueryString("action")
Select Case Action
	Case "post"
		Call Post()
	Case Else
		Call Main()
End Select
AdminFooter()

'========================================================
'保存
'========================================================
Sub Post()
	Dim deleteid, id, theWord, replaceWith
	Dim new_theWord, new_replaceWith
	Dim WordsListArray, strWordsFilter
	ReDim aryTheWord(0), aryReplace(0), aryBanned(0), aryMod(0)
	Dim ar, ab, am

	'删除
	deleteid = NumberGroupFilter(Replace(SafeRequest(2, "deleteid", 1, "", 0), " ", ""))
	If Len(deleteid) > 0 Then
		RQ.Execute("DELETE FROM "& TablePre &"wordsfilter WHERE id IN("& deleteid &")"& IIF(RQ.AdminGroupID <> 1, " AND username = N'"& RQ.UserName &"'", ""))
	End If

	'更新
	If Request.Form("id").Count > 0 Then
		For i = 1 To Request.Form("id").Count
			id = IntCode(Request.Form("id")(i))
			theWord = Replace(strFilter(Request.Form("theword")(i)), """", """""")
			replaceWith = Replace(strFilter(Request.Form("replacewith")(i)), """", """""")

			If id > 0 And Len(theWord) > 0 And Len(replaceWith) > 0 Then
				RQ.Execute("UPDATE "& TablePre &"wordsfilter SET theword = N'"& theWord &"', replacewith = N'"& replaceWith &"' WHERE id = "& id)
			End If
		Next
	End If

	'添加
	new_theWord = Replace(Replace(SafeRequest(2, "new_theword", 1, "", 0), Chr(9), ""), """", """""")
	new_replaceWith = Replace(Replace(SafeRequest(2, "new_replacewith", 1, "", 0), Chr(9), ""), """", """""")

	If Len(CheckContent(new_theWord)) > 0 And Len(CheckContent(new_replaceWith)) > 0 Then
		RQ.Execute("INSERT INTO "& TablePre &"wordsfilter (theword, replacewith, username) VALUES (N'"& new_theWord &"', N'"& new_replaceWith &"', N'"& RQ.UserName &"')")
	End If

	WordsListArray = RQ.Query("SELECT theword, replacewith FROM "& TablePre &"wordsfilter")
	If IsArray(WordsListArray) Then
		ar = 0
		ab = 0
		am = 0
		For i = 0 To UBound(WordsListArray, 2)
			Select Case WordsListArray(1, i)
				Case "{BANNED}"
					ReDim Preserve aryBanned(ab)
					aryBanned(ab) = PregSpecialChr(WordsListArray(0, i))
					ab = ab + 1
				Case "{ADT}"
					ReDim Preserve aryMod(am)
					aryMod(am) = PregSpecialChr(WordsListArray(0, i))
					am = am + 1
				Case Else
					ReDim Preserve aryTheWord(ar)
					ReDim Preserve aryReplace(ar)
					aryTheWord(ar) = PregSpecialChr(WordsListArray(0, i))
					aryReplace(ar) = PregSpecialChr(WordsListArray(1, i))
					ar = ar + 1
			End Select
		Next

		strWordsFilter = "Array(Array("""& Join(aryTheWord, """, """) &"""), Array("""& Join(aryReplace, """, """) &"""), """& Join(aryMod, "|") &""", """& Join(aryBanned, "|") &""")"
	End If

	RQ.Execute("UPDATE "& TablePre &"settings SET wordsfilter = N'"& strWordsFilter &"'")

	Call RQ.Reload_Site_Settings()
	Call closeDatabase()
	Call AdminshowTips("操作完毕。", "?")
End Sub

'========================================================
'过滤正则表达式的关键字
'========================================================
Function PregSpecialChr(str)
	Dim aryChar, n
	aryChar = Array(".", "\\", "+", "*", "?", "[", "^", "]", "$", "(", ")", "{", "}", "=", "!", "<", ">", "|", ":", "/")
	For n = 0 To UBound(aryChar)
		str = Replace(str, aryChar(n), "\"& aryChar(n))
	Next
	str = Preg_Replace(str, "\\\{(\d+)\\\}", ".{0,$1}")
	PregSpecialChr = str
	str = Empty
End Function

'========================================================
'列表
'========================================================
Sub Main()
	Dim WordsListArray
	WordsListArray = RQ.Query("SELECT id, theword, replacewith, username FROM "& TablePre &"wordsfilter ORDER BY id ASC")
	Call closeDatabase()
%>
<br />
<table width="98%" cellpadding="0" cellspacing="0" align="center" class="guide">
  <tr>
    <td><a href="index.asp?action=right" target="_parent">系统设置</a>&nbsp;&raquo;&nbsp;词语过滤</td>
  </tr>
</table>
<br />
<table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
  <tr class="header">
    <td>提示</td>
  </tr>
  <tr class="altbg2">
    <td>替换前的内容可以使用限定符 {x} 以限定相邻两字符间可忽略的文字，x 是忽略字符的个数。如 "a{1}s{2}s"(不含引号) 可以过滤 "ass" 也可过滤 "axsxs" 和 "axsxxs" 等等。
	<br />如需禁止发布包含某个词语的文字，而不是替换过滤，请将其对应的替换内容设置为{BANNED}即可；如需当用户发布包含某个词语的文字时，自动标记为需要人工审核，而不直接显示或替换过滤，请将其对应的替换内容设置为{ADT}即可。</td>
  </tr>
</table>
<br />
<form method="post" name="banuser" action="?action=post" onsubmit="$('btnsubmit').value='正在提交,请稍后...';$('btnsubmit').disabled=true;">
  <table width="98%" border="0" cellpadding="0" cellspacing="0" align="center" class="tableborder">
    <tr class="header">
      <td width="10%"><input type="checkbox" class="radio" onclick="checkall(this.form, 'deleteid');" />删?</td>
      <td>需要过滤的词语</td>
      <td width="30%">替换为</td>
      <td width="20%">操作者</td>
    </tr>
	<% If IsArray(WordsListArray) Then %>
	<% For i = 0 To UBound(WordsListArray, 2) %>
    <tr>
      <td class="altbg1"><input type="checkbox" name="deleteid" class="radio" value="<%= WordsListArray(0, i) %>"<% If RQ.AdminGroupID <> 1 And WordsListArray(2, i) <> RQ.UserName Then Response.Write " disabled" End If %> />
	    <input type="hidden" name="id" value="<%= WordsListArray(0, i) %>" /></td>
      <td class="altbg2"><input type="text" name="theword" value="<%= WordsListArray(1, i) %>" size="30" /></td>
      <td class="altbg1"><input type="text" name="replacewith" value="<%= WordsListArray(2, i) %>" size="30" /></td>
	  <td class="altbg2"><%= WordsListArray(3, i) %></td>
    </tr>
	<% Next %>
	<% End If %>
	<tr>
      <td class="altbg1">添加：</td>
      <td class="altbg2"><input type="text" name="new_theword" size="30" /></td>
      <td class="altbg1"><input type="text" name="new_replacewith" size="30" /></td>
	  <td class="altbg2">&nbsp;</td>
    </tr>
  </table>
  <p align="center"><input type="submit" name="submit1" id="btnsubmit" class="button" value="提交设置" />
</form>
<%
End Sub
%>