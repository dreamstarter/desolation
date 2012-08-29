<!--- Delete existing guest book entry, for use by administrators only. Needs presence of two URL variables fileNameToDelete and idToDelete --->
<cfif not isUserInRole("admin")>
	<cflocation url="index.cfm" addtoken="No">
</cfif>

<cfif isDefined("url.delete") and isDefined("url.fileNameToDelete") and isDefined("url.idToDelete")>
	<cfset fd = application.pro.getMessageByIDAndFileName(idToDelete,fileNameToDelete)>
	<cfif url.delete>
		<cfset res = application.pro.deleteMessage(idToDelete,fileNameToDelete)>
	<cfelse>
		<cfset res = false>
	</cfif>
	<cfif res>
		<cfset userData = "Your guest book entry has been deleted <br><a href=""index.cfm""><img src=""images\gb_main_p.png"" alt=""Go back to the main page"" style=""border: 0; width: 200px; height: 35px;""></a>">
	<cfelse>
		<cfset userData = "There was a problem deleting your guest book entry or you canceled <br><a href=""index.cfm""><img src=""images\gb_main_p.png"" alt=""Go back to the main page"" style=""border: 0; width: 200px; height: 35px;""></a>">
	</cfif>
<cfelse>
	<cfif not isDefined("fileNameToDelete") or not isDefined("idToDelete")>
		<cflocation url="index.cfm" addtoken="No">
	<cfelse>
		<cfset fd = application.pro.getMessageByIDAndFileName(idToDelete,fileNameToDelete)>
	</cfif>
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Guest Book - Delete entry</title>
	<meta name="description" content="Guest Book" />
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<link rel="stylesheet" type="text/css" media="all" href="gb.css" />
</head>

<body>

<table width="700" cellspacing="3" cellpadding="2" align="center">
	<thead>
		<tr><td class="hed" colspan="2"><img src="images\header_del.png" alt="Delete guest book entry" style="border:0; height:80px; width:700px;"/></td></tr>
		<tr><td colspan="2">&nbsp;</td></tr>
		<cfif isDefined("userData")><!--- message shown after submit button is clicked --->
			<tr><td colspan="2" class="success"><cfoutput>#userData#</cfoutput></td></tr>
			<tr><td colspan="2" class="success">&nbsp;</td></tr>
		</cfif>
	</thead>
	<tfoot><tr><td colspan="2">&nbsp;</td></tr></tfoot>
	<tbody>
	<cfoutput>
	<tr>
		<td class="gbtext">User name</td>
		<td>#fd.name#</td>
	</tr>
	<tr>
		<td class="gbtext">User e-mail</td>
		<td>#fd.email#</td>
	</tr>
	<tr>
		<td class="gbtext">User web site address</td>
		<td>#fd.website#</td>
	</tr>
	<tr>
		<td class="gbtext">Entry created on</td>
		<td>#dateformat(fd.date,"yyyy-mm-dd")#</td>
	</tr>
	<tr>
		<td class="gbtext">Entry ip</td>
		<td>#fd.ip#</td>
	</tr>
	<tr>
		<td class="gbtext">Entry id</td>
		<td>#fd.id#</td>
	</tr>
	<tr><td colspan="2" class="gbtext">User guestbook entry</td></tr>
	<tr><td colspan="2" align="center"><textarea cols="80" rows="15" name="message" id="message">#fd.message#</textarea></td></tr>
	<tr>
		<td><a href="delete.cfm?delete=true&idToDelete=#URLEncodedFormat(idToDelete)#&fileNameToDelete=#URLEncodedFormat(fileNameToDelete)#"><img src="images\delete_e.png" alt="Click here to delete this entry" style="border:0; height:35px; width:180px;"/></a></td>
		<td><a href="delete.cfm?delete=false&idToDelete=#URLEncodedFormat(idToDelete)#&fileNameToDelete=#URLEncodedFormat(fileNameToDelete)#"><img src="images\cancel_del.png" alt="Click here to cancel" style="border:0; height:35px; width:240px;"/></a></td>
	</tr>
	</cfoutput>
	</tbody>
</table>

</body>
</html>
