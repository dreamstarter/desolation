<!--- Add new guest book entry, for use by everyone --->
<cftry>
	<!--- if the result is true, the client IP address was banned by the administrator --->
	<cfset checkIP = application.setup.checkForBanIP(cgi.REMOTE_ADDR)>
	<cfif checkIP>
		<div style="text-align:center;">
		<h2>You IP address was banned by the guest book owner!</h2>
		<h4>Please contact him or her to resolve this issue</h4>
		</div>
		<cfabort>
	</cfif>
	<cfcatch type="Any">
		<cftrace inline="false" text="Could not perform IP validity check, unknown error - could it be that cgi variable didn't exist?">
	</cfcatch>
</cftry>
<cfset fs = application.setup.FieldSize()>
<cfset testPic = application.pro.getTestImg()><!--- Test picture support: get random picture --->

<cfif isDefined("form.name")>
	<cfset fd = form>
	<cfset res = application.pro.validateMessage(form,application.setup.FieldSize())>
	<cfif res.success>
		<cfset res2 = application.pro.addMessage(form)>
	<cfelse>
		<cfset res2 = false>
	</cfif>
	<cfif res2>
		<!--- <cfset userData = "Your guest book entry has been added <br><a href=""index.cfm""><img src=""images\gb_main_p.png"" alt=""Go back to the main page"" style=""border: 0; width: 200px; height: 35px;""></a>"> --->
		<cflocation url="index.cfm" addtoken="No">
	<cfelse>
		<cfset userData = "There was a problem adding your guest book entry, please see error messages.">
	</cfif>
<cfelse>
	<cfset fd = application.pro.emptyAddForm()>
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Guest Book - Add entry</title>
	<meta name="description" content="Guest Book" />
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<link rel="stylesheet" type="text/css" media="all" href="gb.css" />
</head>

<body>

<table width="700" cellspacing="3" cellpadding="2" align="center">
	<thead>
		<tr><td class="hed" colspan="2"><img src="images\header_add.png" alt="Add new guest book entry" style="border:0; width:700px; height:80px;"/></td></tr>
		<tr><td colspan="2">&nbsp;</td></tr>
		<cfif isDefined("userData")><!--- message shown after submit button is clicked --->
			<tr><td colspan="2" class="success"><cfoutput>#userData#</cfoutput></td></tr>
			<tr><td colspan="2" class="success">&nbsp;</td></tr>
		</cfif>
	</thead>
	<tfoot><tr><td colspan="2">&nbsp;</td></tr></tfoot>
	<tbody>
	<form action="add.cfm" method="post" name="addform" id="addform">
	<cfoutput>
	<tr>
		<td class="gbtext">Your name</td>
		<td><input type="text" value="#fd.name#" name="name" maxlength="#fs.userNameSize#" size="30"/> *</td>
	</tr>
	<cfif isDefined("res") and len(res.name)><tr><td colspan="2" class="error">#res.name#</td></tr></cfif>
	<tr>
		<td class="gbtext">Your e-mail</td>
		<td><input type="text" value="#fd.email#" name="email" maxlength="#fs.userEmailSize#" size="30"/></td>
	</tr>
	<cfif isDefined("res") and len(res.email)><tr><td colspan="2" class="error">#res.email#</td></tr></cfif>
	<tr>
		<td class="gbtext">Your web site address</td>
		<td><input type="text" value="#fd.website#" name="website" maxlength="#fs.userWebsiteSize#" size="30"/></td>
	</tr>
	<cfif isDefined("res") and len(res.website)><tr><td colspan="2" class="error">#res.website#</td></tr></cfif>
	<!--- Extra test image: --->
	<tr>
		<td class="gbtext">Please type text shown on this image<br/><img src="images/test/#testPic.file#" alt="Defense against automatic agents" width="120" height="40" border="0"/></td>
		<td><input type="text" value="" name="testPicUser" maxlength="30" size="30"/> *</td><!--- Always start blank --->
	</tr>
	<cfif isDefined("res") and len(res.testPicUser)><tr><td colspan="2" class="error">#res.testPicUser#</td></tr></cfif>
	<!--- Need to do all that in order for the Answer to be both secure and transferable through the FORM scope --->
	<cfwddx action="cfml2wddx" input="#encrypt(testPic.text,application.pro.encryptionString)#" output = "userWddxAns">
	<input type="hidden" value="#URLEncodedFormat(userWddxAns)#" name="testPicAnswer">
	<!--- End test image --->
	<tr>
		<td class="gbtext">Entry created on</td>
		<td>#dateformat(now())#<input type="hidden" value="#now()#" name="date"/></td>
	</tr>
	<cfif isDefined("res") and len(res.date)><tr><td colspan="2" class="error">#res.date#</td></tr></cfif>
	<tr><td colspan="2" class="gbtext">Your guest book entry *</td></tr>
	<tr><td colspan="2" align="center"><textarea cols="80" rows="15" name="message" id="message">#fd.message#</textarea></td></tr>
	<cfif isDefined("res") and len(res.message)><tr><td colspan="2" class="error">#res.message#</td></tr></cfif>
	<input type="hidden" value="#cgi.REMOTE_HOST#" name="ip"/>
	<cfif isDefined("res") and len(res.ip)><tr><td colspan="2" class="error">#res.ip#</td></tr></cfif>
	<tr><td colspan="2">* entries marked with a star are required for form processing</td></tr>
	<tr>
		<td><input type="image" name="subBut" src="images\send_e.png" alt="Submit new guest book entry" style="border:0; height:35px; width:180px;"/></td>
		<td><a name="go_back" id="go_back" href="index.cfm" title="Go back to index page"><img src="images\cancel.png" alt="Cancel operation" style="border:0; height:35px; width:120px;"/></a></td>
	</tr>
	</cfoutput>
	</form>
	</tbody>
</table>

</body>
</html>
