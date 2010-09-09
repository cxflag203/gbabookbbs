CREATE TABLE [dbo].[{tablepre}wordsfilter](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[theword] [nvarchar](255) NOT NULL,
	[replacewith] [nvarchar](255) NOT NULL,
	[username] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_{tablepre}wordsfilter] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}usergroups](
	[gid] [smallint] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[types] [varchar](20) NOT NULL,
	[initialize] [tinyint] NOT NULL,
	[allowvisit] [tinyint] NOT NULL,
	[disableperiodctrl] [tinyint] NOT NULL,
	[allowpost] [tinyint] NOT NULL,
	[allowdirectpost] [tinyint] NOT NULL,
	[allowreply] [tinyint] NOT NULL,
	[anonymitysuc] [tinyint] NOT NULL,
	[allowpostpoll] [tinyint] NOT NULL,
	[allowpoll] [tinyint] NOT NULL,
	[allowsearch] [tinyint] NOT NULL,
	[allowgetattach] [tinyint] NOT NULL,
	[allowpostattach] [tinyint] NOT NULL,
	[maxattachsize] [int] NOT NULL,
	[attachextensions] [varchar](255) NOT NULL,
	[allowviewuserinfo] [tinyint] NOT NULL,
	[allowuseitem] [tinyint] NOT NULL,
	[allowhtml] [tinyint] NOT NULL,
	[allowchat] [tinyint] NOT NULL,
	[specialinterface] [ntext] NOT NULL,
	[allowinvate] [tinyint] NOT NULL,
	[invateprice] [int] NOT NULL,
	[invatemaxnum] [int] NOT NULL,
	[invateexpiryday] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}usergroups] PRIMARY KEY CLUSTERED 
(
	[gid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}topictypes](
	[typeid] [int] IDENTITY(1,1) NOT NULL,
	[fid] [smallint] NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NOT NULL,
	[displayorder] [smallint] NOT NULL,
 CONSTRAINT [PK_{tablepre}topictypes] PRIMARY KEY CLUSTERED 
(
	[typeid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}topictypes] ON [dbo].[{tablepre}topictypes] 
(
	[fid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}topictask](
	[tid] [int] NOT NULL,
	[expirytime] [datetime] NOT NULL,
	[theaction] [varchar](30) NOT NULL,
	[itemid] [smallint] NOT NULL,
 CONSTRAINT [PK_{tablepre}topictask] PRIMARY KEY NONCLUSTERED 
(
	[tid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE CLUSTERED INDEX [IX_{tablepre}topictask] ON [dbo].[{tablepre}topictask] 
(
	[expirytime] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}topics](
	[tid] [int] IDENTITY(1,1) NOT NULL,
	[fid] [smallint] NOT NULL,
	[typeid] [smallint] NOT NULL,
	[displayorder] [smallint] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[usershow] [nvarchar](100) NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[posttime] [datetime] NOT NULL,
	[lastupdate] [datetime] NOT NULL,
	[clicks] [int] NOT NULL,
	[posts] [int] NOT NULL,
	[types] [tinyint] NOT NULL,
	[special] [tinyint] NOT NULL,
	[price] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[ifelite] [tinyint] NOT NULL,
	[iflocked] [tinyint] NOT NULL,
	[ifanonymity] [tinyint] NOT NULL,
	[iftask] [tinyint] NOT NULL,
	[disablemodify] [tinyint] NOT NULL,
	[ifattachment] [tinyint] NOT NULL,
 CONSTRAINT [PK_{tablepre}topics] PRIMARY KEY CLUSTERED 
(
	[tid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}topics] ON [dbo].[{tablepre}topics] 
(
	[fid] ASC,
	[displayorder] ASC,
	[lastupdate] DESC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}topics_1] ON [dbo].[{tablepre}topics] 
(
	[fid] ASC,
	[typeid] ASC,
	[displayorder] ASC,
	[lastupdate] DESC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}topics_2] ON [dbo].[{tablepre}topics] 
(
	[types] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}topics_3] ON [dbo].[{tablepre}topics] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}sticktopics](
	[tid] [int] NOT NULL,
	[fid] [smallint] NOT NULL
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}sticktopic] ON [dbo].[{tablepre}sticktopics] 
(
	[tid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}sticktopic_1] ON [dbo].[{tablepre}sticktopics] 
(
	[fid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}settings](
	[base_settings] [ntext] NOT NULL,
	[time_settings] [ntext] NOT NULL,
	[login_settings] [ntext] NOT NULL,
	[user_settings] [ntext] NOT NULL,
	[topic_settings] [ntext] NOT NULL,
	[other_settings] [ntext] NOT NULL,
	[chat_settings] [ntext] NOT NULL,
	[wap_settings] [ntext] NOT NULL,
	[item_settings] [ntext] NOT NULL,
	[wordsfilter] [ntext] NOT NULL,
	[banip] [text] NOT NULL,
	[banner] [ntext] NOT NULL,
	[todayposts] [int] NOT NULL,
	[invatenum] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}searchindex](
	[searchid] [int] IDENTITY(1,1) NOT NULL,
	[keyword] [nvarchar](50) NOT NULL,
	[searchstring] [nvarchar](255) NOT NULL,
	[searchcount] [int] NOT NULL,
	[recordcount] [int] NOT NULL,
	[tid] [text] NOT NULL,
	[expirytime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}searchindex] PRIMARY KEY CLUSTERED 
(
	[searchid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}searchindex] ON [dbo].[{tablepre}searchindex] 
(
	[searchstring] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}posts](
	[pid] [int] IDENTITY(1,1) NOT NULL,
	[fid] [smallint] NOT NULL,
	[tid] [int] NOT NULL,
	[iffirst] [tinyint] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[usershow] [nvarchar](100) NOT NULL,
	[message] [ntext] NOT NULL,
	[posttime] [datetime] NOT NULL,
	[userip] [char](15) NOT NULL,
	[ifanonymity] [tinyint] NOT NULL,
	[ratemark] [int] NOT NULL,
	[ifattachment] [tinyint] NOT NULL,
 CONSTRAINT [PK_{tablepre}posts] PRIMARY KEY CLUSTERED 
(
	[pid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}posts_1] ON [dbo].[{tablepre}posts] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}posts_2] ON [dbo].[{tablepre}posts] 
(
	[tid] ASC,
	[posttime] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}polls](
	[tid] [int] NOT NULL,
	[multiple] [tinyint] NOT NULL,
	[visible] [tinyint] NOT NULL,
	[maxchoices] [tinyint] NOT NULL,
	[totalpoll] [int] NOT NULL,
	[expirytime] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}polls] PRIMARY KEY CLUSTERED 
(
	[tid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}polloptions](
	[optionid] [int] IDENTITY(1,1) NOT NULL,
	[tid] [int] NOT NULL,
	[votes] [int] NOT NULL,
	[displayorder] [tinyint] NOT NULL,
	[title] [nvarchar](100) NOT NULL,
	[voteuids] [text] NOT NULL,
 CONSTRAINT [PK_{tablepre}polloptions] PRIMARY KEY CLUSTERED 
(
	[optionid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}polloptions] ON [dbo].[{tablepre}polloptions] 
(
	[tid] ASC,
	[displayorder] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}pms](
	[pmid] [int] NOT NULL,
	[uid] [int] NOT NULL,
	[message] [ntext] NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}pms] PRIMARY KEY CLUSTERED
(
	[pmid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}pms] ON [dbo].[{tablepre}pms] 
(
	[uid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}pm](
	[pmid] [int] IDENTITY(1,1) NOT NULL,
	[msgfrom] [nvarchar](20) NOT NULL,
	[msgfromid] [int] NOT NULL,
	[msgtoid] [int] NOT NULL,
	[message] [ntext] NOT NULL,
	[remessage] [ntext] NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}pm] PRIMARY KEY CLUSTERED 
(
	[pmid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}pm] ON [dbo].[{tablepre}pm] 
(
	[msgtoid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}online](
	[sid] [char](10) COLLATE Chinese_PRC_BIN NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[userip] [char](15) NOT NULL,
	[usergroupid] [smallint] NOT NULL,
	[lastupdate] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}online] PRIMARY KEY CLUSTERED 
(
	[sid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}online] ON [dbo].[{tablepre}online] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}moderators](
	[fid] [smallint] NOT NULL,
	[uid] [int] NOT NULL
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}moderators] ON [dbo].[{tablepre}moderators] 
(
	[fid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}members](
	[uid] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[thepassword] [char](32) NOT NULL,
	[secques] [varchar](32) NOT NULL,
	[admingroupid] [tinyint] NOT NULL,
	[usergroupid] [smallint] NOT NULL,
	[credits] [int] NOT NULL,
	[regtime] [datetime] NOT NULL,
	[regip] [char](15) NOT NULL,
	[lastlogintime] [datetime] NOT NULL,
	[lastloginip] [char](15) NOT NULL,
	[logintime] [datetime] NOT NULL,
	[loginip] [char](15) NOT NULL,
	[logincount] [int] NOT NULL,
	[newtopictime] [int] NOT NULL,
	[postfloodctrl] [int] NOT NULL,
	[topics] [int] NOT NULL,
	[posts] [int] NOT NULL,
	[accessmasks] [tinyint] NOT NULL,
	[groupexpiry] [int] NOT NULL,
	[newpm] [tinyint] NOT NULL,
	[leaguegid] [tinyint] NOT NULL,
	[viewtopicstyle] [tinyint] NOT NULL,
 CONSTRAINT [PK_{tablepre}members] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE UNIQUE NONCLUSTERED INDEX [IX_{tablepre}members] ON [dbo].[{tablepre}members] 
(
	[username] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}members_1] ON [dbo].[{tablepre}members] 
(
	[usergroupid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}memberprofiles](
	[uid] [int] NOT NULL,
	[profile] [ntext] NOT NULL,
	[province] [nvarchar](10) NOT NULL,
	[area] [nvarchar](10) NOT NULL,
	[gender] [tinyint] NOT NULL,
	[birthyear] [smallint] NOT NULL,
	[birthmonth] [tinyint] NOT NULL,
	[birthday] [tinyint] NOT NULL,
	[constellation] [tinyint] NOT NULL,
	[ifphoto] [tinyint] NOT NULL,
 CONSTRAINT [PK_{tablepre}memberprofiles] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}memberitems](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[uid] [int] NOT NULL,
	[itemid] [smallint] NOT NULL,
	[num] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}memberitems] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}memberitems] ON [dbo].[{tablepre}memberitems] 
(
	[uid] ASC,
	[itemid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}memberfields](
	[uid] [int] NOT NULL,
	[designation] [nvarchar](100) NOT NULL,
	[signature] [ntext] NOT NULL,
	[ignorepm] [ntext] NOT NULL,
	[avatar] [varchar](100) NOT NULL,
 CONSTRAINT [PK_{tablepre}memberfields] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}logs](
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[userip] [char](15) NOT NULL,
	[targetuid] [int] NOT NULL,
	[targetusername] [nvarchar](20) NOT NULL,
	[operation] [nvarchar](255) NOT NULL,
	[reason] [nvarchar](255) NOT NULL,
	[posttime] [datetime] NOT NULL
) ON [PRIMARY]
{next}
CREATE CLUSTERED INDEX [IX_{tablepre}logs_2] ON [dbo].[{tablepre}logs] 
(
	[posttime] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}logs] ON [dbo].[{tablepre}logs] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}logs_1] ON [dbo].[{tablepre}logs] 
(
	[targetuid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leaguetopics](
	[leagueid] [int] NOT NULL,
	[tid] [int] NOT NULL
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}leaguetopics] ON [dbo].[{tablepre}leaguetopics] 
(
	[leagueid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leagues](
	[leagueid] [int] IDENTITY(1,1) NOT NULL,
	[ifadulting] [tinyint] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[description] [ntext] NOT NULL,
	[createtime] [datetime] NOT NULL,
	[members] [int] NOT NULL,
	[news] [int] NOT NULL,
	[topics] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}leagues] PRIMARY KEY CLUSTERED 
(
	[leagueid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leaguenews](
	[articleid] [int] IDENTITY(1,1) NOT NULL,
	[leagueid] [smallint] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[message] [ntext] NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}leaguenews] PRIMARY KEY CLUSTERED 
(
	[articleid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}leaguenews] ON [dbo].[{tablepre}leaguenews] 
(
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [leagueid] ON [dbo].[{tablepre}leaguenews] 
(
	[leagueid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leaguemembers](
	[joinid] [int] IDENTITY(1,1) NOT NULL,
	[uid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[groupid] [smallint] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[designation] [nvarchar](100) NOT NULL,
	[jointime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}leaguemembers] PRIMARY KEY CLUSTERED 
(
	[joinid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}leaguemember] ON [dbo].[{tablepre}leaguemembers] 
(
	[uid] ASC,
	[groupid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}leaguemembers] ON [dbo].[{tablepre}leaguemembers] 
(
	[leagueid] ASC,
	[groupid] ASC,
	[joinid] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leaguelogs](
	[leagueid] [smallint] NOT NULL,
	[typeid] [tinyint] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[operation] [nvarchar](200) NOT NULL,
	[posttime] [datetime] NOT NULL
) ON [PRIMARY]
{next}
CREATE CLUSTERED INDEX [IX_{tablepre}leaguelogs] ON [dbo].[{tablepre}leaguelogs] 
(
	[posttime] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}leaguelogs_2] ON [dbo].[{tablepre}leaguelogs] 
(
	[leagueid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leaguefavorites](
	[uid] [int] NOT NULL,
	[leagueid] [int] NOT NULL
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}leaguefavorites] ON [dbo].[{tablepre}leaguefavorites] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}leagueelite](
	[eliteid] [int] IDENTITY(1,1) NOT NULL,
	[tid] [int] NOT NULL,
	[leagueid] [smallint] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[message] [ntext] NOT NULL,
	[lastupdate] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}leagueelite] PRIMARY KEY CLUSTERED 
(
	[eliteid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [leagueid_lastupdate] ON [dbo].[{tablepre}leagueelite] 
(
	[leagueid] ASC,
	[lastupdate] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}itemuselogs](
	[itemid] [int] NOT NULL,
	[tid] [int] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[userip] [char](15) NOT NULL,
	[targetuid] [int] NOT NULL,
	[targetusername] [nvarchar](20) NOT NULL,
	[operation] [nvarchar](255) NOT NULL,
	[posttime] [datetime] NOT NULL
) ON [PRIMARY]
{next}
CREATE CLUSTERED INDEX [IX_{tablepre}itemuselogs] ON [dbo].[{tablepre}itemuselogs] 
(
	[posttime] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemuselogs_1] ON [dbo].[{tablepre}itemuselogs] 
(
	[itemid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemuselogs_2] ON [dbo].[{tablepre}itemuselogs] 
(
	[tid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}items](
	[itemid] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[types] [varchar](10) NOT NULL,
	[identifier] [varchar](30) NOT NULL,
	[available] [tinyint] NOT NULL,
	[iflog] [tinyint] NOT NULL,
	[description] [nvarchar](255) NOT NULL,
	[displayorder] [smallint] NOT NULL,
 CONSTRAINT [PK_{tablepre}items] PRIMARY KEY CLUSTERED 
(
	[itemid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE UNIQUE NONCLUSTERED INDEX [IX_{tablepre}items] ON [dbo].[{tablepre}items] 
(
	[identifier] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}itemmessages](
	[messageid] [int] IDENTITY(1,1) NOT NULL,
	[itemid] [smallint] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[message] [nvarchar](255) NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}itemmessages] PRIMARY KEY CLUSTERED 
(
	[messageid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemmessages] ON [dbo].[{tablepre}itemmessages] 
(
	[itemid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}itemmarketlogs](
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[userip] [nchar](15) NOT NULL,
	[targetuid] [int] NOT NULL,
	[targetusername] [nvarchar](20) NOT NULL,
	[itemid] [smallint] NOT NULL,
	[num] [int] NOT NULL,
	[price] [int] NOT NULL,
	[posttime] [datetime] NOT NULL
) ON [PRIMARY]
{next}
CREATE CLUSTERED INDEX [IX_{tablepre}itemmarketlogs_2] ON [dbo].[{tablepre}itemmarketlogs] 
(
	[posttime] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemmarketlogs] ON [dbo].[{tablepre}itemmarketlogs] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemmarketlogs_1] ON [dbo].[{tablepre}itemmarketlogs] 
(
	[targetuid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}itemmarket](
	[marketid] [int] IDENTITY(1,1) NOT NULL,
	[itemid] [smallint] NOT NULL,
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[price] [int] NOT NULL,
	[num] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}itemmarket] PRIMARY KEY CLUSTERED 
(
	[marketid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemmarket] ON [dbo].[{tablepre}itemmarket] 
(
	[itemid] ASC,
	[price] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}itemmarket_1] ON [dbo].[{tablepre}itemmarket] 
(
	[uid] ASC,
	[itemid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}invate](
	[uid] [int] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[status] [tinyint] NOT NULL,
	[invatecode] [char](16) COLLATE Chinese_PRC_BIN NOT NULL,
	[buytime] [datetime] NOT NULL,
	[expirytime] [datetime] NOT NULL,
	[reguid] [int] NOT NULL,
	[regtime] [int] NOT NULL
) ON [PRIMARY]
{next}
CREATE CLUSTERED INDEX [IX_{tablepre}invate] ON [dbo].[{tablepre}invate] 
(
	[expirytime] ASC
) ON [PRIMARY]
{next}
CREATE UNIQUE NONCLUSTERED INDEX [IX_{tablepre}invated] ON [dbo].[{tablepre}invate] 
(
	[invatecode] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}invated_1] ON [dbo].[{tablepre}invate] 
(
	[uid] ASC,
	[status] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}groupexpiry](
	[uid] [int] NOT NULL,
	[usergroupid] [smallint] NOT NULL,
	[admingroupid] [smallint] NOT NULL,
 CONSTRAINT [PK_{tablepre}groupexpiry] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}forums](
	[fid] [smallint] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[parentid] [smallint] NOT NULL,
	[childs] [int] NOT NULL,
	[rootfid] [smallint] NOT NULL,
	[displayorder] [smallint] NOT NULL,
	[topics] [int] NOT NULL,
	[posts] [int] NOT NULL,
	[todayposts] [int] NOT NULL,
	[allowpost] [tinyint] NOT NULL,
	[adultingpost] [tinyint] NOT NULL,
	[showtopictype] [tinyint] NOT NULL,
	[choosetopictype] [tinyint] NOT NULL,
	[allowpolltopic] [tinyint] NOT NULL,
	[autoclose] [smallint] NOT NULL,
	[recyclebin] [tinyint] NOT NULL,
	[visitndcredits] [int] NOT NULL,
	[postndcredits] [int] NOT NULL,
	[replyndcredits] [int] NOT NULL,
	[anonyndmitycredits] [int] NOT NULL,
	[htmlndcredits] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}forums] PRIMARY KEY CLUSTERED 
(
	[fid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}forumfields](
	[fid] [int] NOT NULL,
	[moderators] [ntext] NOT NULL,
	[viewperm] [text] NOT NULL,
	[posttopicperm] [text] NOT NULL,
	[postreplyperm] [text] NOT NULL,
	[postattachperm] [text] NOT NULL,
	[getattachperm] [text] NOT NULL,
	[topictype] [ntext] NOT NULL,
 CONSTRAINT [PK_{tablepre}forumfields] PRIMARY KEY CLUSTERED 
(
	[fid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}favorites](
	[uid] [int] NOT NULL,
	[tid] [int] NOT NULL
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}favorites] ON [dbo].[{tablepre}favorites] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}failedlogins](
	[userip] [char](15) NOT NULL,
	[falsecount] [tinyint] NOT NULL,
	[locktime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}failedlogins] PRIMARY KEY NONCLUSTERED 
(
	[userip] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}chatmessages](
	[msgid] [int] IDENTITY(1,1) NOT NULL,
	[roomid] [int] NOT NULL,
	[uid] [int] NOT NULL,
	[usershow] [nvarchar](20) NOT NULL,
	[message] [nvarchar](255) NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}chatmessages] PRIMARY KEY CLUSTERED 
(
	[msgid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}chatmessages] ON [dbo].[{tablepre}chatmessages] 
(
	[roomid] ASC,
	[posttime] DESC
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}chatannounces](
	[roomid] [int] NOT NULL,
	[uid] [int] NOT NULL,
	[usershow] [nvarchar](20) NOT NULL,
	[message] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_{tablepre}chatannounces] PRIMARY KEY CLUSTERED 
(
	[roomid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}banip](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ip1] [smallint] NOT NULL,
	[ip2] [smallint] NOT NULL,
	[ip3] [smallint] NOT NULL,
	[ip4] [smallint] NOT NULL,
	[username] [nvarchar](20) NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}banip] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}admingroups](
	[gid] [smallint] NOT NULL,
	[allowmanagetopic] [tinyint] NOT NULL,
	[alloweditpoll] [tinyint] NOT NULL,
	[allowsticktopic] [tinyint] NOT NULL,
	[allowauditingtopic] [tinyint] NOT NULL,
	[allowviewip] [tinyint] NOT NULL,
	[allowbanip] [tinyint] NOT NULL,
	[allowedituser] [tinyint] NOT NULL,
	[allowpunishuser] [tinyint] NOT NULL,
	[disablepostctrl] [tinyint] NOT NULL,
	[allowdelitemmsg] [tinyint] NOT NULL,
	[disablepmctrl] [tinyint] NOT NULL,
	[allowviewlog] [tinyint] NOT NULL,
 CONSTRAINT [PK_{tablepre}admingroups] PRIMARY KEY CLUSTERED 
(
	[gid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}access](
	[uid] [int] NOT NULL,
	[allowvisit] [tinyint] NOT NULL,
	[disableperiodctrl] [tinyint] NOT NULL,
	[allowpost] [tinyint] NOT NULL,
	[allowdirectpost] [tinyint] NOT NULL,
	[allowreply] [tinyint] NOT NULL,
	[anonymitysuc] [tinyint] NOT NULL,
	[allowpostpoll] [tinyint] NOT NULL,
	[allowpoll] [tinyint] NOT NULL,
	[allowsearch] [tinyint] NOT NULL,
	[allowgetattach] [tinyint] NOT NULL,
	[allowpostattach] [tinyint] NOT NULL,
	[maxattachsize] [int] NOT NULL,
	[attachextensions] [varchar](255) NOT NULL,
	[allowviewuserinfo] [tinyint] NOT NULL,
	[allowuseitem] [tinyint] NOT NULL,
	[allowhtml] [tinyint] NOT NULL,
	[allowchat] [tinyint] NOT NULL,
	[specialinterface] [ntext] NOT NULL,
	[allowinvate] [tinyint] NOT NULL,
	[invateprice] [int] NOT NULL,
	[invatemaxnum] [int] NOT NULL,
	[invateexpiryday] [int] NOT NULL,
 CONSTRAINT [PK_{tablepre}access] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
{next}
CREATE TABLE [dbo].[{tablepre}attachments](
	[aid] [int] IDENTITY(1,1) NOT NULL,
	[tid] [int] NOT NULL,
	[pid] [int] NOT NULL,
	[uid] [int] NOT NULL,
	[filename] [nvarchar](255) NOT NULL,
	[filetype] [varchar](50) NOT NULL,
	[filesize] [int] NOT NULL,
	[savepath] [varchar](100) NOT NULL,
	[downloads] [int] NOT NULL,
	[ifimage] [tinyint] NOT NULL,
	[description] [nvarchar](100) NOT NULL,
	[posttime] [datetime] NOT NULL,
 CONSTRAINT [PK_{tablepre}attachments] PRIMARY KEY CLUSTERED 
(
	[aid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}attachments] ON [dbo].[{tablepre}attachments] 
(
	[tid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}attachments_1] ON [dbo].[{tablepre}attachments] 
(
	[uid] ASC
) ON [PRIMARY]
{next}
CREATE NONCLUSTERED INDEX [IX_{tablepre}attachments_2] ON [dbo].[{tablepre}attachments] 
(
	[pid] ASC,
	[posttime] ASC
) ON [PRIMARY]
{next}
CREATE PROCEDURE [dbo].[{tablepre}sp_postlist]
@tid int,
@viewauthorid int,
@page int, 
@posts int,
@pagesize smallint,
@pagecount int output

AS
SET NOCOUNT ON

DECLARE @recordcount int
DECLARE @sql nvarchar(2000)
DECLARE @sqladdon nvarchar(200)

SET @sqladdon = ''

IF @viewauthorid = 0
	SET @recordcount = @posts
ELSE
	BEGIN
		SELECT @recordcount = COUNT(pid) FROM {tablepre}posts WHERE tid = @tid AND uid = @viewauthorid AND ifanonymity = 0
		SET @sqladdon = N'AND uid = '+ CAST(@viewauthorid AS varchar(10)) +' AND ifanonymity = 0'
	END

IF @recordcount = 0
	SET @recordcount = 1
	
SET @pagecount = CEILING(@recordcount * 1.0 / @pagesize)
IF @page > @pagecount
	SET @page = @pagecount

IF @page = 1
	SET @sql = N'SELECT TOP '+ CAST((@pagesize + 1) AS varchar(10)) +' pid, iffirst, uid, username, usershow, message, posttime, ifanonymity, ratemark, ifattachment FROM {tablepre}posts WHERE tid = @tid '+ @sqladdon +' ORDER BY posttime ASC'
ELSE
	SET @sql = N'SELECT TOP '+ CAST(@pagesize AS varchar(10)) + ' pid, iffirst, uid, username, usershow, message, posttime, ifanonymity, ratemark, ifattachment FROM {tablepre}posts WHERE tid = @tid '+ @sqladdon +' AND posttime > (
			SELECT MAX(posttime) 
			FROM (
					SELECT TOP '+ CAST((@pagesize * (@page - 1) + 1) AS varchar(10))+' posttime
					FROM {tablepre}posts
					WHERE tid = @tid '+ @sqladdon +'
					ORDER BY posttime ASC
				) 
			AS tblTemp
		)
		ORDER BY posttime ASC'

EXEC sp_executesql @sql, N'@tid int', @tid = @tid

UPDATE {tablepre}topics SET clicks = clicks + 1 WHERE tid = @tid

RETURN @recordcount

SET NOCOUNT OFF
{next}
CREATE PROCEDURE [dbo].[{tablepre}sp_topiclist]
@fid smallint,
@page int,             
@pagesize smallint,
@typeid tinyint

AS

SET NOCOUNT ON

DECLARE @sql NVARCHAR(1000)

IF @page > 1
	BEGIN
		IF @typeid > 0
			SET @sql = N'SELECT TOP '+ CAST(@pagesize AS VARCHAR(10)) +' tid, typeid, usershow, title, clicks, posts, lastupdate 
				FROM {tablepre}topics 
				WHERE fid = @fid AND typeid = @typeid AND displayorder = 0 AND lastupdate < (
					SELECT MIN(lastupdate) 
					FROM (
						SELECT TOP '+ CAST(@pagesize * (@page - 1) AS VARCHAR(10)) +' lastupdate 
						FROM {tablepre}topics 
						WHERE fid = @fid AND typeid = @typeid AND displayorder = 0 
						ORDER BY lastupdate DESC
					) AS tblTemp
				) 
				ORDER BY lastupdate DESC'
		ELSE
			SET @sql = N'SELECT TOP '+ CAST(@pagesize AS VARCHAR(10)) +' tid, typeid, usershow, title, clicks, posts, lastupdate 
				FROM {tablepre}topics 
				WHERE fid = @fid AND displayorder = 0 AND lastupdate < (
					SELECT MIN(lastupdate) 
					FROM (
						SELECT TOP '+ CAST(@pagesize * (@page - 1) AS VARCHAR(10)) +' lastupdate 
						FROM {tablepre}topics 
						WHERE fid = @fid AND displayorder = 0 
						ORDER BY lastupdate DESC
					) AS tblTemp
				)
				ORDER BY lastupdate DESC'
	END
ELSE
	BEGIN
		IF @typeid > 0
			SET @sql = N'SELECT TOP '+ CAST(@pagesize AS VARCHAR(10)) +' tid, typeid, usershow, title, clicks, posts, lastupdate
				FROM {tablepre}topics 
				WHERE fid = @fid AND typeid = @typeid AND displayorder = 0 
				ORDER BY lastupdate DESC'
		ELSE
			SET @sql = N'SELECT TOP '+ CAST(@pagesize AS VARCHAR(10)) +' tid, typeid, usershow, title, clicks, posts, lastupdate 
				FROM {tablepre}topics 
				WHERE fid = @fid AND displayorder = 0 
				ORDER BY lastupdate DESC'
	END

EXEC sp_executesql @sql, N'@fid smallint, @typeid tinyint', @fid = @fid, @typeid = @typeid

SET NOCOUNT OFF
{next}
CREATE procedure [dbo].[{tablepre}sp_online_newpm]
@sid char(10),
@uid int,
@username nvarchar(20),
@userip char(15),
@usergroupid smallint,
@onlinehold smallint,
@thetime datetime
AS

SET NOCOUNT ON

IF EXISTS(SELECT 1 FROM {tablepre}online WHERE sid = @sid AND uid = @uid)
	UPDATE {tablepre}online SET uid = @uid, username = @username, userip = @userip, usergroupid = @usergroupid, lastupdate = GetDate() WHERE sid = @sid
ELSE
	BEGIN
		DELETE FROM {tablepre}online WHERE sid = @sid OR lastupdate < DATEADD(n, -@onlinehold, GETDATE()) OR (uid > 0 AND uid = @uid) OR (uid = 0 AND userip = @userip AND lastupdate < DATEADD(n, -60, GETDATE()))
		INSERT INTO {tablepre}online (sid, uid, username, userip, usergroupid) VALUES (@sid, @uid, @username, @userip, @usergroupid)
	END

--输出是否有新传呼
IF @uid > 0
	BEGIN
		IF EXISTS(SELECT 1 FROM {tablepre}pm WHERE msgtoid = @uid AND posttime <= @thetime)
			RETURN 1
	END

SET NOCOUNT OFF
{next}
CREATE PROCEDURE [dbo].[{tablepre}sp_newtopic]
@fid smallint,
@typeid tinyint,
@displayorder smallint,
@uid int,
@username nvarchar(20),
@usershow nvarchar(100),
@title nvarchar(255),
@types tinyint,
@special tinyint,
@price int,
@leaguejoinid int,
@iflocked tinyint,
@ifanonymity tinyint,
@ifattachment tinyint,
@message ntext,
@userip char(15),
@tid int output,
@pid int output

AS
SET NOCOUNT ON

DECLARE @league_name nvarchar(50)
DECLARE @league_userid int
DECLARE @leagueid smallint

--验证联盟
SET @leagueid = 0
IF @leaguejoinid > 0 AND @uid > 0
BEGIN
	SELECT @league_userid = lm.uid, @leagueid = lm.leagueid, @league_name = l.name FROM {tablepre}leaguemembers lm INNER JOIN {tablepre}leagues l ON lm.leagueid = l.leagueid WHERE lm.joinid = @leaguejoinid
	IF @league_userid = @uid
		SET @title = N'【' + @league_name + N'】' + @title
END

--保存帖子信息
INSERT INTO {tablepre}topics (fid, typeid, displayorder, uid, username, usershow, title, types, special, price, leagueid, iflocked, ifanonymity, ifattachment)
VALUES (@fid, @typeid, @displayorder, @uid, @username, @usershow, @title, @types, @special, @price, @leagueid, @iflocked, @ifanonymity, @ifattachment)

--取得新帖子的编号
SELECT @tid = SCOPE_IDENTITY()

--保存帖子内容
INSERT INTO {tablepre}posts (fid, tid, iffirst, uid, username, usershow, message, userip, ifanonymity, ifattachment)
VALUES (@fid, @tid, 1, @uid, @username, @usershow, @message, @userip, @ifanonymity, @ifattachment)

--取得新回复的编号
SELECT @pid = SCOPE_IDENTITY()

--如果是联盟贴则进行联盟操作
IF @leagueid > 0
	BEGIN
		INSERT INTO {tablepre}leaguetopics (leagueid, tid) VALUES (@leagueid, @tid)
		INSERT INTO {tablepre}leaguelogs (leagueid, username, operation) VALUES (@leagueid, @username, N'<b>'+ @title +'</b>('+ @userip +')')
		UPDATE {tablepre}leagues SET topics = topics + 1 WHERE leagueid = @leagueid
	END

--更新版面帖子统计
IF @displayorder = 0
	UPDATE {tablepre}forums SET topics = topics + 1 WHERE fid = @fid

--更新用户帖子统计
IF @uid > 0
	UPDATE {tablepre}members SET topics = topics + 1, newtopictime = DateDiff(s, '1970-01-01 0:00:00', GETDATE()) WHERE uid = @uid

RETURN @tid
RETURN @pid
SET NOCOUNT OFF
{next}
CREATE PROCEDURE [dbo].[{tablepre}sp_newreply]
@fid smallint,
@tid int,
@uid int,
@username nvarchar(20),
@usershow nvarchar(100),
@message ntext,
@userip char(15),
@ifanonymity tinyint,
@ratemark int,
@disable_update tinyint,
@postfloodctrl int,
@ifattachment tinyint,
@t_ifattachment tinyint

AS
SET NOCOUNT ON
DECLARE @pid int

--保存回复内容
INSERT INTO {tablepre}posts(fid, tid, uid, username, usershow, message, userip, ifanonymity, ratemark, ifattachment) 
VALUES(@fid, @tid, @uid, @username, @usershow, @message, @userip, @ifanonymity, @ratemark, @ifattachment)

--获取编号
SELECT @pid = SCOPE_IDENTITY()

--如果没有上传附件，那么帖子附件标记不改变
IF @ifattachment = 0
	SET @ifattachment = @t_ifattachment

--更新帖子回复数量; 是否更新帖子
IF @disable_update = 1
	UPDATE {tablepre}topics SET posts = posts + 1, ifattachment = @ifattachment WHERE tid = @tid
ELSE
	UPDATE {tablepre}topics SET lastupdate = GetDate(), posts = posts + 1, ifattachment = @ifattachment WHERE tid = @tid

--更新版面回帖统计
UPDATE {tablepre}forums SET posts = posts + 1 WHERE fid = @fid

--更新用户回帖统计; 是否回帖灌水
IF @uid > 0
	UPDATE {tablepre}members SET postfloodctrl = @postfloodctrl, posts = posts + 1 WHERE uid = @uid

RETURN @pid
SET NOCOUNT OFF
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowvisit]  DEFAULT ((0)) FOR [allowvisit]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_disableperiodctrl]  DEFAULT ((0)) FOR [disableperiodctrl]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowpost]  DEFAULT ((0)) FOR [allowpost]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowdirectpost]  DEFAULT ((0)) FOR [allowdirectpost]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowreply]  DEFAULT ((0)) FOR [allowreply]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_anonymitysuc]  DEFAULT ((0)) FOR [anonymitysuc]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowpostpoll]  DEFAULT ((0)) FOR [allowpostpoll]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowpoll]  DEFAULT ((0)) FOR [allowpoll]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowsearch]  DEFAULT ((0)) FOR [allowsearch]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowgetattach]  DEFAULT ((0)) FOR [allowgetattach]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowpostattach]  DEFAULT ((0)) FOR [allowpostattach]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_maxattachsize]  DEFAULT ((0)) FOR [maxattachsize]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_attachextensions]  DEFAULT ('') FOR [attachextensions]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowviewuserinfo]  DEFAULT ((0)) FOR [allowviewuserinfo]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowuseitem]  DEFAULT ((0)) FOR [allowuseitem]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowhtml]  DEFAULT ((0)) FOR [allowhtml]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowchat]  DEFAULT ((0)) FOR [allowchat]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_specialinterface]  DEFAULT ('') FOR [specialinterface]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_allowinvate]  DEFAULT ((0)) FOR [allowinvate]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_invateprice]  DEFAULT ((0)) FOR [invateprice]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_invatemaxnum]  DEFAULT ((0)) FOR [invatemaxnum]
{next}
ALTER TABLE [dbo].[{tablepre}access] ADD  CONSTRAINT [DF_{tablepre}access_invateexpiryday]  DEFAULT ((0)) FOR [invateexpiryday]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_alloweditpost]  DEFAULT (0) FOR [allowmanagetopic]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_alloweditpoll]  DEFAULT (0) FOR [alloweditpoll]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowsticktopic]  DEFAULT (0) FOR [allowsticktopic]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowauditingtopic]  DEFAULT (0) FOR [allowauditingtopic]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowviewip]  DEFAULT (0) FOR [allowviewip]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowbanip]  DEFAULT (0) FOR [allowbanip]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowedituser]  DEFAULT (0) FOR [allowedituser]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowpunishuser]  DEFAULT (0) FOR [allowpunishuser]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowdisablecontrol]  DEFAULT (0) FOR [disablepostctrl]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowdelitemmsg]  DEFAULT (0) FOR [allowdelitemmsg]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_disablepmctrl]  DEFAULT (0) FOR [disablepmctrl]
{next}
ALTER TABLE [dbo].[{tablepre}admingroups] ADD  CONSTRAINT [DF_{tablepre}admingroups_allowviewlog]  DEFAULT (0) FOR [allowviewlog]
{next}
ALTER TABLE [dbo].[{tablepre}banip] ADD  CONSTRAINT [DF_{tablepre}banip_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}chatmessages] ADD  CONSTRAINT [DF_{tablepre}chatmessages_uid]  DEFAULT (0) FOR [uid]
{next}
ALTER TABLE [dbo].[{tablepre}chatmessages] ADD  CONSTRAINT [DF_{tablepre}chatmessages_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}failedlogins] ADD  CONSTRAINT [DF_{tablepre}failedlogins_falsecount]  DEFAULT (1) FOR [falsecount]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_moderators]  DEFAULT ('') FOR [moderators]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_viewperm]  DEFAULT ('') FOR [viewperm]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_posttopicperm]  DEFAULT ('') FOR [posttopicperm]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_postreplyperm]  DEFAULT ('') FOR [postreplyperm]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_postattachperm]  DEFAULT ('') FOR [postattachperm]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_getattachperm]  DEFAULT ('') FOR [getattachperm]
{next}
ALTER TABLE [dbo].[{tablepre}forumfields] ADD  CONSTRAINT [DF_{tablepre}forumfields_topictype]  DEFAULT ('') FOR [topictype]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_name]  DEFAULT ('') FOR [name]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_parentid]  DEFAULT (0) FOR [parentid]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_childs]  DEFAULT (0) FOR [childs]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_rootfid]  DEFAULT (0) FOR [rootfid]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_displayorder]  DEFAULT (0) FOR [displayorder]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_topics]  DEFAULT (0) FOR [topics]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_posts]  DEFAULT (0) FOR [posts]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_todayposts]  DEFAULT (0) FOR [todayposts]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_allowpost]  DEFAULT (0) FOR [allowpost]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_adultingpost]  DEFAULT (0) FOR [adultingpost]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_showtopictype]  DEFAULT (0) FOR [showtopictype]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_choosetopictype]  DEFAULT (0) FOR [choosetopictype]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_allowpolltopic]  DEFAULT (0) FOR [allowpolltopic]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_autoclose]  DEFAULT (0) FOR [autoclose]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_recyclebin]  DEFAULT (0) FOR [recyclebin]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_visitndcredits]  DEFAULT (0) FOR [visitndcredits]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_postndcredits]  DEFAULT (0) FOR [postndcredits]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_replyndcredits]  DEFAULT (0) FOR [replyndcredits]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_anonymitycredits]  DEFAULT (0) FOR [anonyndmitycredits]
{next}
ALTER TABLE [dbo].[{tablepre}forums] ADD  CONSTRAINT [DF_{tablepre}forums_htmlndcredits]  DEFAULT (0) FOR [htmlndcredits]
{next}
ALTER TABLE [dbo].[{tablepre}invate] ADD  CONSTRAINT [DF_{tablepre}invate_status]  DEFAULT ((0)) FOR [status]
{next}
ALTER TABLE [dbo].[{tablepre}invate] ADD  CONSTRAINT [DF_{tablepre}invate_buytime]  DEFAULT (getdate()) FOR [buytime]
{next}
ALTER TABLE [dbo].[{tablepre}invate] ADD  CONSTRAINT [DF_{tablepre}invate_reguid]  DEFAULT ((0)) FOR [reguid]
{next}
ALTER TABLE [dbo].[{tablepre}invate] ADD  CONSTRAINT [DF_{tablepre}invate_regtime]  DEFAULT ((0)) FOR [regtime]
{next}
ALTER TABLE [dbo].[{tablepre}itemmarketlogs] ADD  CONSTRAINT [DF_{tablepre}itemmarketlogs_price]  DEFAULT (0) FOR [price]
{next}
ALTER TABLE [dbo].[{tablepre}itemmarketlogs] ADD  CONSTRAINT [DF_{tablepre}itemmarketlogs_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}itemmessages] ADD  CONSTRAINT [DF_{tablepre}itemmessages_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}items] ADD  CONSTRAINT [DF_{tablepre}items_available]  DEFAULT ((0)) FOR [available]
{next}
ALTER TABLE [dbo].[{tablepre}items] ADD  CONSTRAINT [DF_{tablepre}items_iflog]  DEFAULT ((0)) FOR [iflog]
{next}
ALTER TABLE [dbo].[{tablepre}items] ADD  CONSTRAINT [DF_{tablepre}items_description]  DEFAULT ('') FOR [description]
{next}
ALTER TABLE [dbo].[{tablepre}items] ADD  CONSTRAINT [DF_{tablepre}items_displayorder]  DEFAULT ((0)) FOR [displayorder]
{next}
ALTER TABLE [dbo].[{tablepre}itemuselogs] ADD  CONSTRAINT [DF_{tablepre}itemuselogs_operation]  DEFAULT ('') FOR [operation]
{next}
ALTER TABLE [dbo].[{tablepre}itemuselogs] ADD  CONSTRAINT [DF_{tablepre}itemuselogs_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}leaguelogs] ADD  CONSTRAINT [DF_{tablepre}leaguelogs_typeid]  DEFAULT (0) FOR [typeid]
{next}
ALTER TABLE [dbo].[{tablepre}leaguelogs] ADD  CONSTRAINT [DF_{tablepre}leaguelogs_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}leaguemembers] ADD  CONSTRAINT [DF_{tablepre}leaguemembers_jointime]  DEFAULT (getdate()) FOR [jointime]
{next}
ALTER TABLE [dbo].[{tablepre}leaguenews] ADD  CONSTRAINT [DF_{tablepre}leaguenews_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}leagues] ADD  CONSTRAINT [DF_{tablepre}leagues_ifadulting]  DEFAULT (0) FOR [ifadulting]
{next}
ALTER TABLE [dbo].[{tablepre}leagues] ADD  CONSTRAINT [DF_{tablepre}leagues_createtime]  DEFAULT (getdate()) FOR [createtime]
{next}
ALTER TABLE [dbo].[{tablepre}leagues] ADD  CONSTRAINT [DF_{tablepre}leagues_members]  DEFAULT (1) FOR [members]
{next}
ALTER TABLE [dbo].[{tablepre}leagues] ADD  CONSTRAINT [DF_{tablepre}leagues_news]  DEFAULT (0) FOR [news]
{next}
ALTER TABLE [dbo].[{tablepre}leagues] ADD  CONSTRAINT [DF_{tablepre}leagues_topics]  DEFAULT (0) FOR [topics]
{next}
ALTER TABLE [dbo].[{tablepre}logs] ADD  CONSTRAINT [DF_{tablepre}logs_operation]  DEFAULT ('') FOR [operation]
{next}
ALTER TABLE [dbo].[{tablepre}logs] ADD  CONSTRAINT [DF_{tablepre}logs_reason]  DEFAULT ('') FOR [reason]
{next}
ALTER TABLE [dbo].[{tablepre}logs] ADD  CONSTRAINT [DF_{tablepre}logs_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}memberfields] ADD  CONSTRAINT [DF_{tablepre}memberfields_designation]  DEFAULT ('') FOR [designation]
{next}
ALTER TABLE [dbo].[{tablepre}memberfields] ADD  CONSTRAINT [DF_{tablepre}memberfields_signature]  DEFAULT ('') FOR [signature]
{next}
ALTER TABLE [dbo].[{tablepre}memberfields] ADD  CONSTRAINT [DF_{tablepre}memberfields_ignorepm]  DEFAULT ('') FOR [ignorepm]
{next}
ALTER TABLE [dbo].[{tablepre}memberfields] ADD  CONSTRAINT [DF_{tablepre}memberfields_avatar]  DEFAULT ('') FOR [avatar]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_profile]  DEFAULT ('') FOR [profile]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_province]  DEFAULT ('') FOR [province]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_area]  DEFAULT ('') FOR [area]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_gender]  DEFAULT (0) FOR [gender]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_birthyear]  DEFAULT (0) FOR [birthyear]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_birthmonth]  DEFAULT (0) FOR [birthmonth]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_birthday]  DEFAULT (0) FOR [birthday]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_constellation]  DEFAULT (0) FOR [constellation]
{next}
ALTER TABLE [dbo].[{tablepre}memberprofiles] ADD  CONSTRAINT [DF_{tablepre}memberprofiles_ifphoto]  DEFAULT (0) FOR [ifphoto]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_secques]  DEFAULT ('') FOR [secques]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_admingroupid]  DEFAULT ((0)) FOR [admingroupid]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_credits]  DEFAULT ((0)) FOR [credits]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_regtime]  DEFAULT (getdate()) FOR [regtime]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_lastlogintime]  DEFAULT (getdate()) FOR [lastlogintime]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_logintime]  DEFAULT (getdate()) FOR [logintime]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_logincount]  DEFAULT ((1)) FOR [logincount]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_newtopictime]  DEFAULT ((0)) FOR [newtopictime]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_postfloodctrl]  DEFAULT ((0)) FOR [postfloodctrl]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_topics]  DEFAULT ((0)) FOR [topics]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_posts]  DEFAULT ((0)) FOR [posts]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_accessmasks]  DEFAULT ((0)) FOR [accessmasks]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_groupexpiry]  DEFAULT ((0)) FOR [groupexpiry]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_newpm]  DEFAULT ((0)) FOR [newpm]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_leaguegid]  DEFAULT ((0)) FOR [leaguegid]
{next}
ALTER TABLE [dbo].[{tablepre}members] ADD  CONSTRAINT [DF_{tablepre}members_viewtopicstyle]  DEFAULT ((0)) FOR [viewtopicstyle]
{next}
ALTER TABLE [dbo].[{tablepre}online] ADD  CONSTRAINT [DF_{tablepre}online_lastupdate]  DEFAULT (getdate()) FOR [lastupdate]
{next}
ALTER TABLE [dbo].[{tablepre}pm] ADD  CONSTRAINT [DF_{tablepre}pm_remessage]  DEFAULT ('') FOR [remessage]
{next}
ALTER TABLE [dbo].[{tablepre}pm] ADD  CONSTRAINT [DF_{tablepre}pm_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}polloptions] ADD  CONSTRAINT [DF_{tablepre}polloptions_votes]  DEFAULT ((0)) FOR [votes]
{next}
ALTER TABLE [dbo].[{tablepre}polloptions] ADD  CONSTRAINT [DF_{tablepre}polloptions_displayorder]  DEFAULT ((0)) FOR [displayorder]
{next}
ALTER TABLE [dbo].[{tablepre}polloptions] ADD  CONSTRAINT [DF_{tablepre}polloptions_voteuids]  DEFAULT ('') FOR [voteuids]
{next}
ALTER TABLE [dbo].[{tablepre}polls] ADD  CONSTRAINT [DF_{tablepre}polls_multiple]  DEFAULT ((0)) FOR [multiple]
{next}
ALTER TABLE [dbo].[{tablepre}polls] ADD  CONSTRAINT [DF_{tablepre}polls_visible]  DEFAULT ((0)) FOR [visible]
{next}
ALTER TABLE [dbo].[{tablepre}polls] ADD  CONSTRAINT [DF_{tablepre}polls_maxchoices]  DEFAULT ((0)) FOR [maxchoices]
{next}
ALTER TABLE [dbo].[{tablepre}polls] ADD  CONSTRAINT [DF_{tablepre}polls_totalpoll]  DEFAULT ((0)) FOR [totalpoll]
{next}
ALTER TABLE [dbo].[{tablepre}polls] ADD  CONSTRAINT [DF_{tablepre}polls_expirytime]  DEFAULT ((0)) FOR [expirytime]
{next}
ALTER TABLE [dbo].[{tablepre}posts] ADD  CONSTRAINT [DF_{tablepre}posts_iffirst]  DEFAULT ((0)) FOR [iffirst]
{next}
ALTER TABLE [dbo].[{tablepre}posts] ADD  CONSTRAINT [DF_{tablepre}posts_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}posts] ADD  CONSTRAINT [DF_{tablepre}posts_ifanonymity]  DEFAULT ((0)) FOR [ifanonymity]
{next}
ALTER TABLE [dbo].[{tablepre}posts] ADD  CONSTRAINT [DF_{tablepre}posts_ratemark]  DEFAULT ((0)) FOR [ratemark]
{next}
ALTER TABLE [dbo].[{tablepre}posts] ADD  CONSTRAINT [DF_{tablepre}posts_ifattachment]  DEFAULT ((0)) FOR [ifattachment]
{next}
ALTER TABLE [dbo].[{tablepre}searchindex] ADD  CONSTRAINT [DF_{tablepre}searchindex_searchcount]  DEFAULT (1) FOR [searchcount]
{next}
ALTER TABLE [dbo].[{tablepre}settings] ADD  CONSTRAINT [DF_{tablepre}settings_wordsfilter]  DEFAULT ('') FOR [wordsfilter]
{next}
ALTER TABLE [dbo].[{tablepre}settings] ADD  CONSTRAINT [DF_{tablepre}settings_banip]  DEFAULT ('') FOR [banip]
{next}
ALTER TABLE [dbo].[{tablepre}settings] ADD  CONSTRAINT [DF_{tablepre}settings_todayposts]  DEFAULT (0) FOR [todayposts]
{next}
ALTER TABLE [dbo].[{tablepre}settings] ADD  CONSTRAINT [DF_{tablepre}settings_invatenum]  DEFAULT (0) FOR [invatenum]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_fid]  DEFAULT ((0)) FOR [fid]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_typeid]  DEFAULT ((0)) FOR [typeid]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_displayorder]  DEFAULT ((0)) FOR [displayorder]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_uid]  DEFAULT ((0)) FOR [uid]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_lastupdate]  DEFAULT (getdate()) FOR [lastupdate]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_clicks]  DEFAULT ((0)) FOR [clicks]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_posts]  DEFAULT ((0)) FOR [posts]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_types]  DEFAULT ((0)) FOR [types]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_special]  DEFAULT ((0)) FOR [special]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_price]  DEFAULT ((0)) FOR [price]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_leagueid]  DEFAULT ((0)) FOR [leagueid]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_ifelite]  DEFAULT ((0)) FOR [ifelite]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_iflocked]  DEFAULT ((0)) FOR [iflocked]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_ifanonymity]  DEFAULT ((0)) FOR [ifanonymity]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_ifmod]  DEFAULT ((0)) FOR [iftask]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_disablemodify]  DEFAULT ((0)) FOR [disablemodify]
{next}
ALTER TABLE [dbo].[{tablepre}topics] ADD  CONSTRAINT [DF_{tablepre}topics_ifattachment]  DEFAULT ((0)) FOR [ifattachment]
{next}
ALTER TABLE [dbo].[{tablepre}topictask] ADD  CONSTRAINT [DF_{tablepre}topictask_theaction]  DEFAULT ('') FOR [theaction]
{next}
ALTER TABLE [dbo].[{tablepre}topictask] ADD  CONSTRAINT [DF_{tablepre}topictask_itemid]  DEFAULT (0) FOR [itemid]
{next}
ALTER TABLE [dbo].[{tablepre}topictypes] ADD  CONSTRAINT [DF_{tablepre}topictypes_description]  DEFAULT ('') FOR [description]
{next}
ALTER TABLE [dbo].[{tablepre}topictypes] ADD  CONSTRAINT [DF_{tablepre}topictypes_displayorder]  DEFAULT (0) FOR [displayorder]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_initialize]  DEFAULT ((0)) FOR [initialize]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowvisit]  DEFAULT ((0)) FOR [allowvisit]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_disableperiodctrl]  DEFAULT ((0)) FOR [disableperiodctrl]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowpost]  DEFAULT ((0)) FOR [allowpost]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowdirectpost]  DEFAULT ((0)) FOR [allowdirectpost]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowreply]  DEFAULT ((0)) FOR [allowreply]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_anonymitysuc]  DEFAULT ((0)) FOR [anonymitysuc]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowpostpoll]  DEFAULT ((0)) FOR [allowpostpoll]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowpoll]  DEFAULT ((0)) FOR [allowpoll]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowsearch]  DEFAULT ((0)) FOR [allowsearch]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowgetattach]  DEFAULT ((0)) FOR [allowgetattach]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowpostattach]  DEFAULT ((0)) FOR [allowpostattach]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_maxattachsize]  DEFAULT ((0)) FOR [maxattachsize]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_attachextensions]  DEFAULT ('') FOR [attachextensions]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowviewuserinfo]  DEFAULT ((0)) FOR [allowviewuserinfo]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowuseitem]  DEFAULT ((0)) FOR [allowuseitem]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowhtml]  DEFAULT ((0)) FOR [allowhtml]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowchat]  DEFAULT ((0)) FOR [allowchat]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_specialinterface]  DEFAULT ('') FOR [specialinterface]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_allowinvate]  DEFAULT ((0)) FOR [allowinvate]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_invateprice]  DEFAULT ((0)) FOR [invateprice]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_invatemaxnum]  DEFAULT ((0)) FOR [invatemaxnum]
{next}
ALTER TABLE [dbo].[{tablepre}usergroups] ADD  CONSTRAINT [DF_{tablepre}usergroups_invateexpiryday]  DEFAULT ((0)) FOR [invateexpiryday]
{next}
ALTER TABLE [dbo].[{tablepre}attachments] ADD  CONSTRAINT [DF_{tablepre}attachments_tid]  DEFAULT ((0)) FOR [tid]
{next}
ALTER TABLE [dbo].[{tablepre}attachments] ADD  CONSTRAINT [DF_{tablepre}attachments_pid]  DEFAULT ((0)) FOR [pid]
{next}
ALTER TABLE [dbo].[{tablepre}attachments] ADD  CONSTRAINT [DF_{tablepre}attachments_downloads]  DEFAULT ((0)) FOR [downloads]
{next}
ALTER TABLE [dbo].[{tablepre}attachments] ADD  CONSTRAINT [DF_{tablepre}attachments_ifimage]  DEFAULT ((0)) FOR [ifimage]
{next}
ALTER TABLE [dbo].[{tablepre}attachments] ADD  CONSTRAINT [DF_{tablepre}attachments_description]  DEFAULT ('') FOR [description]
{next}
ALTER TABLE [dbo].[{tablepre}attachments] ADD  CONSTRAINT [DF_{tablepre}attachments_posttime]  DEFAULT (getdate()) FOR [posttime]
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'站长', CONVERT(TEXT, N'moderator'), 1, 1, 1, 1, 1, 1, 100, 1, 1, 1, 1, 1, 0, CONVERT(TEXT, N''), 1, 1, 1, 1, N'', 1, 1, 9999, 999)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'高级管理员', CONVERT(TEXT, N'moderator'), 1, 1, 1, 1, 1, 1, 90, 1, 1, 1, 1, 1, 4000, CONVERT(TEXT, N''), 1, 1, 1, 1, N'', 1, 10, 999, 99)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'初级管理员', CONVERT(TEXT, N'moderator'), 1, 1, 1, 1, 1, 1, 80, 1, 1, 1, 1, 1, 2048, CONVERT(TEXT, N''), 1, 1, 1, 1, N'', 1, 30, 50, 60)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'普通用户', CONVERT(TEXT, N'member'), 1, 1, 0, 1, 1, 1, 60, 1, 1, 1, 1, 1, 512, N'jpg,jpeg,gif,png,rar,zip', 1, 1, 1, 1, N'', 1, 50, 10, 30)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'游客', CONVERT(TEXT, N'member'), 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, CONVERT(TEXT, N''), 0, 0, 0, 0, N'', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'黑名单', CONVERT(TEXT, N'restricted'), 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, CONVERT(TEXT, N''), 1, 1, 0, 1, N'<style>body,div,span,.bg0,.bg1,.quotetop,.quotemain{background:#000;background-color:#000;}.quotetop,.quotemain{color:#000;}</style>', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'发帖限制', CONVERT(TEXT, N'restricted'), 1, 1, 0, 1, 0, 1, 50, 0, 1, 1, 1, 0, 0, CONVERT(TEXT, N''), 1, 1, 1, 1, N'', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'禁止HTML', CONVERT(TEXT, N'restricted'), 1, 1, 0, 1, 1, 1, 50, 1, 1, 1, 1, 0, 0, CONVERT(TEXT, N''), 1, 1, 0, 1, N'', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'聊天室黑名单', CONVERT(TEXT, N'restricted'), 1, 1, 0, 1, 1, 1, 50, 1, 1, 1, 1, 0, 0, CONVERT(TEXT, N''), 1, 1, 1, 0, N'', 1, 100, 5, 5)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'禁止发言', CONVERT(TEXT, N'restricted'), 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, CONVERT(TEXT, N''), 1, 0, 0, 0, N'', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'禁止访问', CONVERT(TEXT, N'restricted'), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, CONVERT(TEXT, N''), 0, 0, 0, 0, N'', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}usergroups] ([name], [types], [initialize], [allowvisit], [disableperiodctrl], [allowpost], [allowdirectpost], [allowreply], [anonymitysuc], [allowpostpoll], [allowpoll], [allowsearch], [allowgetattach], [allowpostattach], [maxattachsize], [attachextensions], [allowviewuserinfo], [allowuseitem], [allowhtml], [allowchat], [specialinterface], [allowinvate], [invateprice], [invatemaxnum], [invateexpiryday]) VALUES (N'脑残一族', CONVERT(TEXT, N'restricted'), 1, 1, 0, 1, 1, 1, 50, 1, 1, 1, 0, 0, 0, CONVERT(TEXT, N''), 1, 1, 1, 1, N'<script type="text/javascript" src="js/marsconver.js"></script>', 0, 0, 0, 0)
{next}
INSERT [dbo].[{tablepre}settings] ([base_settings], [time_settings], [login_settings], [user_settings], [topic_settings], [other_settings], [chat_settings], [wap_settings], [item_settings], [wordsfilter], [banip], [banner], [todayposts], [invatenum]) VALUES (N'{bbsname}{settings}{settings}{settings}{settings}0{settings}站点维护中', N'{settings}{settings}{settings}', N'0{settings}login.asp{settings}{settings}1{settings}20{settings}100{settings}5', N'15{settings}3{settings}3{settings}20{settings}200{settings}5{settings}0{settings}15', N'100{settings}10000{settings}100{settings}0{settings}100{settings}2{settings}<p>{settings}标题党帖{settings}3{settings}5{settings}3{settings}1{settings}神秘黑衣大哥哥{settings}0{settings}1{settings}60{settings}{username}企图匿名，但是可耻的失败了<img src="face/846.gif" />{settings}edit', N'金币{settings}60{settings}1000{settings}1{settings}0{settings}1', N'1{settings}300{settings}5{settings}15{settings}500{settings}300{settings}20{settings}100{settings}勤劳的家庭主妇{username}把房间打扫得干干净净。', N'1{settings}0{settings}0{settings}10{settings}10{settings}800', N'1{settings}60{settings}24{settings}72{settings}2{settings}4{settings}100{settings}4700{settings}470{settings}170{settings}17{settings}7', N'', CONVERT(TEXT, N''), N'当初所坚持的心情，是不是还依然存在', 0, 99)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'MP转让器', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'credittransfer'), 0, 1, N'转让金钱到其他用户处，处理结果记录到异动报告。', 1)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'吖噗鸡', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'uptopic'), 1, 1, N'可UP任意帖子到帖子列表顶部。', 2)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'变相怪杰', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'setsig'), 1, 1, N'设置签名。', 3)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'大救生圈', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'sticktopicplus'), 1, 1, N'比救生圈置顶更长的时间。', 4)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'笛子', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'requestmusic'), 1, 1, N'点歌。', 5)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'恶魔时空机', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'sinktopic'), 1, 1, N'帖子送回几天前在列表内消失。', 6)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'精灵弓', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'sinksticktopic'), 1, 1, N'破坏救生圈效果', 7)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'九尾狐', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'setdesignation'), 1, 1, N'设置称号，用户发帖、回帖时，称号将跟在用户名后面。', 8)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'救生圈', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'sticktopic'), 1, 1, N'让帖子置顶一段时间。', 9)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'地图炮', CONVERT(TEXT, N'anonymity'), CONVERT(TEXT, N'clearallanonymity'), 1, 1, N'使本帖内目前所有匿名失效（使用面子除外）。', 10)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'玫瑰', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'statusbar'), 1, 1, N'设置状态栏信息，设置好的信息将在浏览器状态栏滚动（仅支持IE6）。', 11)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'匿名符', CONVERT(TEXT, N'other'), CONVERT(TEXT, N'anonymity'), 1, 1, N'帮没有匿名的用户匿名，使用方法为点击发言人用户名，在弹出的窗口中点击“匿名”。', 12)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'黑眼睛', CONVERT(TEXT, N'anonymity'), CONVERT(TEXT, N'clearanonymity'), 1, 1, N'使当前发言的匿名用户失效。', 13)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'疯兔', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'reversetopic'), 1, 1, N'逆转帖子标题字符顺序。', 14)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'醒目灯', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'settopiccolor'), 1, 1, N'改变帖子标题颜色。', 15)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'远望之镜', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'userdetail'), 1, 1, N'查看用户信息。', 16)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'照妖镜', CONVERT(TEXT, N'anonymity'), CONVERT(TEXT, N'viewanonymity'), 1, 1, N'查看匿名用户的真实名称。', 17)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'水晶球', CONVERT(TEXT, N'member'), CONVERT(TEXT, N'viewip'), 1, 1, N'查询用户IP同时列出同IP其他用户。', 18)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'超级拖把', CONVERT(TEXT, N'other'), CONVERT(TEXT, N'clearchatroom'), 1, 1, N'聊天室清屏。', 19)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'赌场贵宾券', CONVERT(TEXT, N'other'), CONVERT(TEXT, N'dice'), 1, 1, N'在聊天室掷出骰子，根据规则获得金钱。', 20)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'帖之沉默', CONVERT(TEXT, N'topic'), CONVERT(TEXT, N'disablereply'), 1, 1, N'使帖子不能回复，需楼主自行回复。', 21)
{next}
INSERT [dbo].[{tablepre}items] ([name], [types], [identifier], [available], [iflog], [description], [displayorder]) VALUES (N'面子', CONVERT(TEXT, N'anonymity'), CONVERT(TEXT, N'face'), 1, 1, N'有面子的匿名才是真的匿名。', 22)
{next}
INSERT [dbo].[{tablepre}forums] ([name], [parentid], [childs], [rootfid], [displayorder], [topics], [posts], [todayposts], [allowpost], [adultingpost], [showtopictype], [choosetopictype], [allowpolltopic], [autoclose], [recyclebin], [visitndcredits], [postndcredits], [replyndcredits], [anonyndmitycredits], [htmlndcredits]) VALUES (N'默认版面', 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 50, 100)
{next}
INSERT [dbo].[{tablepre}forumfields] ([fid], [moderators], [viewperm], [posttopicperm], [postreplyperm], [postattachperm], [getattachperm], [topictype]) VALUES (1, CONVERT(TEXT, N''), CONVERT(TEXT, N''), CONVERT(TEXT, N''), CONVERT(TEXT, N''), CONVERT(TEXT, N''), CONVERT(TEXT, N''), CONVERT(TEXT, N''))
{next}
INSERT [dbo].[{tablepre}admingroups] ([gid], [allowmanagetopic], [alloweditpoll], [allowsticktopic], [allowauditingtopic], [allowviewip], [allowbanip], [allowedituser], [allowpunishuser], [disablepostctrl], [allowdelitemmsg], [disablepmctrl], [allowviewlog]) VALUES (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
{next}
INSERT [dbo].[{tablepre}admingroups] ([gid], [allowmanagetopic], [alloweditpoll], [allowsticktopic], [allowauditingtopic], [allowviewip], [allowbanip], [allowedituser], [allowpunishuser], [disablepostctrl], [allowdelitemmsg], [disablepmctrl], [allowviewlog]) VALUES (2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
{next}
INSERT [dbo].[{tablepre}admingroups] ([gid], [allowmanagetopic], [alloweditpoll], [allowsticktopic], [allowauditingtopic], [allowviewip], [allowbanip], [allowedituser], [allowpunishuser], [disablepostctrl], [allowdelitemmsg], [disablepmctrl], [allowviewlog]) VALUES (3, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0)