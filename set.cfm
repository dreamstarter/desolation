<!--- Administrative area settings page --->
<cfif not isUserInRole("admin")>
	<cflocation url="index.cfm" addtoken="No">
</cfif>

<cfif isDefined("form.password")>
	<cfset sd = application.setup.convertFormToSetupData(form)>
	<cfset res = application.setup.checkUserSetupData(form)>
	<cfif res.success>
		<cfset application.setup.writeAllUserSetupData(form)>
		<cfset userDataSave = "Your user data has been saved successfuly!">
	<cfelse>
		<cfset userDataSave = "Please correct indicated errors and try again.">
	</cfif>
<cfelse>
	<cfset sd = duplicate(application.setup.getAllSetupData())><!--- this must be a CF bug - you can modify this structure inside CFC --->
	<cfset sd.gbconfig.password = application.setup.adminLoginPassword><!--- don't want to display hashed version --->
	<cfset sd.gbconfig.password2 = ""><!--- this is only for repeat entry --->
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Guest Book</title>
	<meta name="description" content="Guest Book" />
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<link rel="stylesheet" type="text/css" media="all" href="gb.css" />
	<style type="text/css">
		tr {
			position: relative;
			width: 100%;
			padding: 8px;
			text-align: left;
		}
		.odd {background-color: #b0d5fd;}
		.even {background-color: #c9e4fc;}
		table {
			margin: 0 20px 0 20px;
		}
		a {font-size: 120%; padding: 20px;}
		body {z-index: 1;}
	</style>
</head>

<body>

<table cellspacing="1" cellpadding="0">
	<form action="set.cfm" method="post" name="setF" id="setF">
	<thead>
		<tr><td colspan="2" class="hed"><img src="images\header_set.png" alt="Guest book settings edit page" style="border:0; height:80px; width:700px;"/></td></tr>
		<tr><td colspan="2">&nbsp;</td></tr>
		<cfif isDefined("userDataSave")><!--- message shown after submit button is clicked --->
			<tr><td colspan="2" class="success"><cfoutput>#userDataSave#</cfoutput></td></tr>
			<tr><td colspan="2" class="success">&nbsp;</td></tr>
		</cfif>
	</thead>
	<tfoot><tr><td colspan="2">&nbsp;</td></tr></tfoot>
	<tbody>
	<cfoutput>
	<tr class="odd">
		<td>Enter administrator's password (min 5, max 50 characters)</td>
		<td><input type="text" name="password" value="#sd.gbconfig.password#" size="25" maxlength="50"/></td>
	</tr>
	<cfif isDefined("res") and len(res.password)><tr><td colspan="2" class="error">#res.password#</td></tr></cfif>
	<tr class="even">
		<td>Re-enter administrator's password</td>
		<td><input type="text" name="password2" value="#sd.gbconfig.password2#" size="25" maxlength="50"/></td>
	</tr>
	<cfif isDefined("res") and len(res.password2)><tr><td colspan="2" class="error">#res.password2#</td></tr></cfif>
	<tr class="odd">
		<td>Enter user e-mail maximum length (positive integer)</td>
		<td><input type="text" name="userEmailSize" value="#sd.gbconfig.userEmailSize#" size="10" maxlength="10"/></td>
	</tr>
	<cfif isDefined("res") and len(res.userEmailSize)><tr><td colspan="2" class="error">#res.userEmailSize#</td></tr></cfif>
	<tr class="even">
		<td>Enter maximum user name length (positive integer)</td>
		<td><input type="text" name="userNameSize" value="#sd.gbconfig.userNameSize#" size="10" maxlength="10"/></td>
	</tr>
	<cfif isDefined("res") and len(res.userNameSize)><tr><td colspan="2" class="error">#res.userNameSize#</td></tr></cfif>
	<tr class="odd">
		<td>Enter maximum user web site length (positive integer)</td>
		<td><input type="text" name="userWebsiteSize" value="#sd.gbconfig.userWebsiteSize#" size="10" maxlength="10"/></td>
	</tr>
	<cfif isDefined("res") and len(res.userWebsiteSize)><tr><td colspan="2" class="error">#res.userWebsiteSize#</td></tr></cfif>
	<tr class="even">
		<td>Enter maximum user message length - guest book entry (positive integer)</td>
		<td><input type="text" name="userMessageSize" value="#sd.gbconfig.userMessageSize#" size="10" maxlength="10"/></td>
	</tr>
	<cfif isDefined("res") and len(res.userMessageSize)><tr><td colspan="2" class="error">#res.userMessageSize#</td></tr></cfif>
	<tr class="odd">
		<td>Enter number of guest book entries to be shown per page (positive integer)</td>
		<td><input type="text" name="messagesPerPage" value="#sd.gbconfig.messagesPerPage#" size="10" maxlength="10"/></td>
	</tr>
	<cfif isDefined("res") and len(res.messagesPerPage)><tr><td colspan="2" class="error">#res.messagesPerPage#</td></tr></cfif>
	<tr class="even">
		<td>Enter the maximum number of user guest book messages to be stored per data file (positive integer)</td>
		<td><input type="text" name="messagesPerFile" value="#sd.gbconfig.messagesPerFile#" size="10" maxlength="10"/></td>
	</tr>
	<cfif isDefined("res") and len(res.messagesPerFile)><tr><td colspan="2" class="error">#res.messagesPerFile#</td></tr></cfif>
	<tr class="odd">
		<td>Do you want to receive e-mail notification when entry is added to guest book? Enter valid e-mail if yes (recommended)</td>
		<td><input type="text" name="sendEmailOnEntry" value="#sd.gbconfig.sendEmailOnEntry#" size="25" maxlength="100"/></td>
	</tr>
	<cfif isDefined("res") and len(res.sendEmailOnEntry)><tr><td colspan="2" class="error">#res.sendEmailOnEntry#</td></tr></cfif>
	<tr class="even">
		<td>Please select the ordering of guest book messages that display on the first page</td>
		<td nowrap>
			<!--- Opera doesn't play along with the checked property! --->
			Newest first <input type="radio" name="ordering" value="0" <cfif not sd.gbconfig.ordering>checked</cfif>/> 
			Oldest first <input type="radio" name="ordering" value="1" <cfif sd.gbconfig.ordering>checked</cfif>/>
		</td>
	</tr>
	<cfif isDefined("res") and len(res.ordering)><tr><td colspan="2" class="error">#res.ordering#</td></tr></cfif>
	<tr class="odd">
		<td>Please list IP addresses, which you want to ban, separated by a comma</td>
		<td>
			<!--- <input type="text" name="banIPs" value="#sd.gbconfig.banIPs#" size="25" maxlength="1000"/> --->
			<textarea cols="25" rows="1" name="banIPs" id="n">#sd.gbconfig.banIPs#</textarea>
		</td>
	</tr>
	<cfif isDefined("res") and len(res.banIPs)><tr><td colspan="2" class="error">#res.banIPs#</td></tr></cfif>
	<tr class="even">
		<td>Please list words you want to ban, separated by a comma</td>
		<td>
			<!--- <input type="text" name="banWords" value="#sd.gbconfig.banWords#" size="25" maxlength="1000"/> --->
			<textarea cols="25" rows="1" name="banWords" id="n">#sd.gbconfig.banWords#</textarea>
		</td>
	</tr>
	<cfif isDefined("res") and len(res.banWords)><tr><td colspan="2" class="error">#res.banWords#</td></tr></cfif>
	</cfoutput>
	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
		<td><input type="image" name="subBut" src="images\updgbset.png" alt="Update user configuration" style="border: 0; z-index: 10; height:35px; width:240px;"/></td>
		<td><a name="go_back" id="go_back" href="index.cfm" title="Go back to index page"><img src="images\cancel.png" alt="Cancel operation" style="border:0; height:35px; width:120px;"/></a></td>
	</tr>
	</form>
	</tbody>
</table>

<table cellspacing="1" cellpadding="1" width="90%">
	<tbody>
	<tr>
		<td><a href="index.cfm" title="Guest book main page"><img src="images\gb_main_p.png" alt="Guest book main page" style="border: 0; z-index: 10; height:35px; width:200px;"/></a></td>
		<td><a href="login.cfm?logout=yes" title="Log out"><img src="images\logout.png" alt="Log out" style="border: 0; z-index: 10; height:35px; width:120px;"/></a></td>
		<td><a href="docs/index.htm" title="View documentation"><img src="images\docs.png" alt="View documentation" style="border: 0; z-index: 10; height:35px; width:160px;"/></a></td>
	</tr>
	</tbody>
</table>

<table cellspacing="1" cellpadding="0" width="90%">
	<thead>
		<tr><td>&nbsp;</td></tr>
		<tr><td class="hed">Information about files that store guest book data</td></tr>
		<tr><td>&nbsp;</td></tr>
		<tr>
			<td>Total messages in the guest book: <cfoutput>#application.pro.totalGuestBookMessages()#</cfoutput></td>
		</tr>
		<tr><td>Data files that make up the guest book:</td></tr>
	</thead>
	<tfoot>
		<tr><td>&nbsp;</td></tr>
		<tr><td style="text-align: center;">XML Guest Book Version 1.0 Date: 23.July.2004</td></tr>
	</tfoot>
	<tbody>
		<cfloop index="m" from="1" to="#arrayLen(sd.gbdata)#" step="1">
			<cfoutput><tr><td nowrap>#sd.gbdata[m].fileName#</td></tr></cfoutput>
		</cfloop>
	</tbody>
</table>

</body>
</html>
