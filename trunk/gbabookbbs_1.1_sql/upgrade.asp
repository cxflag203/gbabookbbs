<!--#include file="include/inc.asp"-->
<%
Dim SettingsInfo, Settings
Dim Base_Settings(4), Time_Settings(3), Login_Settings(6), User_Settings(7), Topic_Settings(17), Other_Settings(5), Chat_Settings(8)

SettingsInfo = RQ.Query("SELECT site_settings FROM "& TablePre &"settings")
If Not IsArray(SettingsInfo) Then
	Call showTips("错误的站点设置。", "", "")
End If

Settings = Split(SettingsInfo(0, 0), "_____SETTINGS_____")
For i = 0 To 4
	Base_Settings(i) = Settings(i)
Next

For i = 0 To 3
	Time_Settings(i) = Settings(i + 5)
Next

For i = 0 To 6
	Login_Settings(i) = Settings(i + 9)
Next

For i = 0 To 7
	User_Settings(i) = Settings(i + 17)
Next

For i = 0 To 4
	Topic_Settings(i) = Settings(i + 25)
Next
Topic_Settings(5) = "1"
For i = 6 To 17
	Topic_Settings(i) = Settings(i + 24)
Next

For i = 0 To 5
	Other_Settings(i) = Settings(i + 42)
Next

For i = 0 To 8
	Chat_Settings(i) = Settings(i + 48)
Next

RQ.Execute("UPDATE "& TablePre &"settings SET base_settings = '"& Join(base_settings, "{settings}") &"', time_settings = '"& Join(time_settings, "{settings}") &"', login_settings = '"& Join(login_settings, "{settings}") &"', user_settings = '"& Join(user_settings, "{settings}") &"', topic_settings = '"& Join(topic_settings, "{settings}") &"', other_settings = '"& Join(other_settings, "{settings}") &"', chat_settings = '"& Join(chat_settings, "{settings}") &"'")

Call closeDatabase()
%>