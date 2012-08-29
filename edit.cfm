<!--- Edit existing guest book entry, for use by by administrators only. Needs presence of two URL variables (or form) fileNameToEdit and idToEdit --->
<cfif not isUserInRole("admin")>
	<cflocation url="index.cfm" addtoken="No">
</cfif>

<cfset fs = application.setup.FieldSize()>

<cfif isDefined("form.name")>
	<cfset fd = form>
	<cfset res = application.pro.validateMessage(form,application.setup.FieldSize())>
	<cfif res.success>
		<cfset res2 = application.pro.editMessage(form,idToEdit,fileNameToEdit)>
	<cfelse>
		<cfset res2 = false>
	</cfif>
	<cfif res2>
		<cfset userData = "Your guest book entry has been edited <br><a href=""index.cfm""><img src=""images\gb_main_p.png"" alt=""Go back to the main page"" style=""border: 0; width: 200px; height: 35px;""></a>">
	<cfelse>
		<cfset userData = "There was a problem editing your guest book entry, please see error messages.">
	</cfif>
<cfelse>
	<cfif not isDefined("fileNameToEdit") or not isDefined("idToEdit")>
		<cflocation url="index.cfm" addtoken="No">
	<cfelse>
		<cfset fd = application.pro.getMessageByIDAndFileName(idToEdit,fileNameToEdit)>
	</cfif>
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Guest Book - Edit entry</title>
	<meta name="description" content="Guest Book" />
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<link rel="stylesheet" type="text/css" media="all" href="gb.css" />
</head>

<body>

<table width="700" cellspacing="3" cellpadding="2" align="center">
	<thead>
		<tr><td class="hed" colspan="2"><img src="images\header_edit.png" alt="Edit guest book entry" style="border:0; height:80px; width:700px;"/></td></tr>
		<tr><td colspan="2">&nbsp;</td></tr>
		<cfif isDefined("userData")><!--- message shown after submit button is clicked --->
			<tr><td colspan="2" class="success"><cfoutput>#userData#</cfoutput></td></tr>
			<tr><td colspan="2" class="success">&nbsp;</td></tr>
		</cfif>
	</thead>
	<tfoot><tr><td colspan="2">&nbsp;</td></tr></tfoot>
	<tbody>
	<form action="edit.cfm" method="post" name="editform" id="editform">
	<cfoutput>
	<tr>
		<td class="gbtext">User name</td>
		<td><input type="text" value="#fd.name#" name="name" maxlength="#fs.userNameSize#" size="30"/> *</td>
	</tr>
	<cfif isDefined("res") and len(res.name)><tr><td colspan="2" class="error">#res.name#</td></tr></cfif>
	<tr>
		<td class="gbtext">User e-mail</td>
		<td><input type="text" value="#fd.email#" name="email" maxlength="#fs.userEmailSize#" size="30"/></td>
	</tr>
	<cfif isDefined("res") and len(res.email)><tr><td colspan="2" class="error">#res.email#</td></tr></cfif>
	<tr>
		<td class="gbtext">User web site address</td>
		<td><input type="text" value="#fd.website#" name="website" maxlength="#fs.userWebsiteSize#" size="30"/></td>
	</tr>
	<cfif isDefined("res") and len(res.website)><tr><td colspan="2" class="error">#res.website#</td></tr></cfif>
	<tr>
		<td class="gbtext">User entry created on</td>
		<td><input type="text" value="<cfif isDate(fd.date)>#dateformat(fd.date, 'yyyy-mm-dd')#<cfelse>#fd.date#</cfif>" name="date" maxlength="20" size="30"/></td>
	</tr>
	<cfif isDefined("res") and len(res.date)><tr><td colspan="2" class="error">#res.date#</td></tr></cfif>
	<tr>
		<td class="gbtext">User IP address</td>
		<td><input type="text" value="#fd.ip#" name="ip" maxlength="20" size="30"/></td>
	</tr>
	<cfif isDefined("res") and len(res.ip)><tr><td colspan="2" class="error">#res.ip#</td></tr></cfif>
	<tr><td colspan="2" class="gbtext">User guest book entry *</td></tr>
	<tr><td colspan="2" align="center"><textarea cols="80" rows="15" name="message" id="message">#fd.message#</textarea></td></tr>
	<cfif isDefined("res") and len(res.message)><tr><td colspan="2" class="error">#res.message#</td></tr></cfif>
	<input type="hidden" value="#idToEdit#" name="idToEdit"/>
	<input type="hidden" value="#fileNameToEdit#" name="fileNameToEdit"/>
	<tr><td colspan="2">* entries marked with a star are required for form processing</td></tr>
	<tr>
		<td><input type="image" name="subBut" src="images\update_e.png" alt="Update guest book entry" style="border:0; height:35px; width:180px;"/></td>
		<td><a name="go_back" id="go_back" href="index.cfm" title="Go back to index page"><img src="images\cancel.png" alt="Cancel operation" style="border:0; height:35px; width:120px;"/></a></td>
	</tr>
	</cfoutput>
	</form>
	</tbody>
</table>

</body>
</html>
