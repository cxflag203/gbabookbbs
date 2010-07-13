<%
If Not INGBABOOK Then
	Response.Write "ACCESS DENIED"
	Response.End()
End If

'========================================================
'投票帖子显示投票内容
'========================================================
Function getPollContent()
	Dim PollInfo, OptionListArray, s
	Dim PollVotes, blnDisablePoll, blnPolled, strTips, RemainTime, lngPercenter, rndNumber

	PollInfo = RQ.Query("SELECT multiple, visible, maxchoices, totalpoll, expirytime FROM "& TablePre &"polls WHERE tid = "& RQ.TopicID)

	If IsArray(PollInfo) Then
		'查询总投票数
		PollVotes = Conn.Execute("SELECT SUM(votes) FROM "& TablePre &"polloptions WHERE tid = "& RQ.TopicID)(0)

		'查询投票选项
		OptionListArray = RQ.Query("SELECT optionid, optionid, votes, title, voteuids FROM "& TablePre &"polloptions WHERE tid = "& RQ.TopicID &" ORDER BY displayorder ASC")
	
		s = s &"<p><form method=""post"" name=""poll"" action=""topicmisc.asp?action=submitpoll&fid="& RQ.ForumID &"&tid="& RQ.TopicID &""" onsubmit=""$('btnpoll').value='正在提交,请稍后...';$('btnpoll').disabled=true;""><strong>"& IIF(PollInfo(0, 0) = 1, "多选", "单选") &"投票</strong>："& IIF(PollInfo(0, 0) = 1, "(最多可选"& PollInfo(2, 0) &"项)，", "") &"已有"& PollInfo(3, 0) &"人参与。"

		'投票是否已经结束
		If PollInfo(4, 0) > 0 Then
			If PollInfo(4, 0) - DatetoNum(Now()) <= 0 Then
				s = s &"<br /><strong>投票已经结束。</strong>"
				blnDisablePoll = True
			Else
				RemainTime = showRemainTime(PollInfo(4, 0) - DatetoNum(Now()))
				s = s &"<br />还有"& IIF(RemainTime(0) > 0, RemainTime(0) &"天", "") & IIF(RemainTime(1) > 0, RemainTime(1) &"小时", "") & RemainTime(2) &"分钟结束。"
			End If
		End If

		s = s &"<p><table border=""0"" cellpadding=""0"" cellspacing=""0"" class=""votepanel"">"

		If IsArray(OptionListArray) Then
			If RQ.AllowPoll = 1 Then
				For i = 0 To UBound(OptionListArray, 2)
					'验证是否已经投过票
					If InStr(","& OptionListArray(4, i) &",", ","& IIF(RQ.UserID = 0, RQ.UserIP, RQ.UserID) &",") > 0 Then
						blnDisablePoll = True
						blnPolled = True
						strTips = "您已经投过票了。"
						Exit For
					End If
				Next
			Else
				blnDisablePoll = True
				strTips = IIF(RQ.UserID = 0, "游客不能参与投票，请<a href=""login.asp"" class=""bluelink"">登陆</a>。", "您目前的身份("& RQ.UserGroupName &")还不能参与投票。")
			End If

			Randomize
			For i = 0 To UBound(OptionListArray, 2)
				s = s &"<tr><td colspan=""2"">"& IIF(Not blnDisablePoll, "<input type="""& IIF(PollInfo(0, 0) = 1, "checkbox", "radio") &""" id=""option_"& OptionListArray(0, i) &""" name=""optionid"" value="""& OptionListArray(0, i) &""" />", "") &"&nbsp;<label for=""option_"& OptionListArray(0, i) &""">"& i + 1 &"."& OptionListArray(3, i) &"</label></td></tr>"
				
				'是否允许查看投票的状态
				If PollInfo(1, 0) = 1 Or blnPolled Then
					'计算百分比
					If PollVotes = 0 Then
						lngPercenter = 0
					Else
						lngPercenter = OptionListArray(2, i) / PollVotes
					End If
					
					'随机生成0-9之间的数字，对应背景css
					rndNumber = Int(10 * Rnd)

					s = s &"<tr><td style=""padding-left: 20px;""><div class=""optionbg""><div class=""optionrbg optionr"& rndNumber &""" style=""width: "& (lngPercenter * 300) + 2 &"px""></div></div></td><td class=""voteratio"">"& FormatNumber(lngPercenter, 4, -1) * 100 &"% ("& OptionListArray(2, i) &")</td></tr>"
				Else
					s = s &"<tr><td colspan=""2""><hr size=""1""></td></tr>"
				End If
			Next

			s = s &"<tr><td colspan=""2"" style=""padding-left: 20px;"">"
			If blnDisablePoll Then
				s = s & strTips
			Else
				s = s &"<input type=""submit"" id=""btnpoll"" value=""提交投票"" class=""button"" />"
			End If
			s = s &"</td></tr>"
		End If

		s = s &"</table></form>"
	Else
		RQ.Execute("UPDATE "& TablePre &"topics SET special = 0 WHERE tid = "& RQ.TopicID)
	End If

	getPollContent = s
	s = Empty
End Function

'========================================================
'投票距离过期的时间
'========================================================
Function showRemainTime(lngSecond)
	Dim Minutes, Hours, Days
	Minutes = Int((lngSecond Mod 3600) / 60)
	Hours = Int((lngSecond Mod 86400) / 3600)
	Days = Int(lngSecond / 86400)
	showRemainTime = Array(Days, Hours, Minutes)
End Function
%>