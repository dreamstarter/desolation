<!--- Administrative redirect if not already logged in as guest book administrator --->
<cfprocessingdirective suppresswhitespace="Yes"><!--- less white space --->
<cfif isDefined("url.admin") and not isUserInRole("admin")>
	<cflocation url="login.cfm" addtoken="No">
</cfif>

<!--- Which messages to display, and getting them --->
<cfif not isDefined("startMsg")>
	<cfset startMsg = -1>
	<cfset msg = application.pro.getMessages(startMsg)>
<cfelse>
	<cfset msg = application.pro.getMessages(startMsg)>
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd">

<html>
<head>
	<title>Guest Book</title>
	<meta name="description" content="Guest Book" />
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<link rel="stylesheet" type="text/css" media="all" href="gb.css" />
	<style type="text/css">
		
	</style>
</head>

<body>

<div align="center">
<div style="width: 700px; margin-left:auto; margin-right:auto;">

<table width="100%" cellspacing="0" cellpadding="0" align="center">
	<thead>
		<tr><td colspan="2" class="hed"><img src="images\header.png" alt="Guest Book header" style="border:0; width:700px; height:80px;"/></td></tr>
		<cfif isUserInRole("admin")><!--- do we shown administrative page button? --->
		<tr>
			<td style="text-align: left;"><a href="set.cfm"><img src="images\edit_gb_s.png" alt="Edit guest book settings" style="border: 0; width:240px; height:35px;"/></a></td>
			<td style="text-align: right;"><a href="login.cfm?logout=yes"><img src="images\logout.png" alt="Log out" style="border: 0; width:120px; height:35px;"/></a></td>
		</tr>
		</cfif>
		<tr><td colspan="2" style="text-align: center;"><a href="add.cfm"><img src="images\new_gb_e.png" alt="Would you like to add an entry to the guest book?" style="border:0; width:200px; height:35px;"/></a></td></tr>
		<tr>
			<cfif application.pro.isPreviousPage(startMsg)><!--- do we shown previous page button? --->
				<td style="text-align: left;"><a href="index.cfm?startMsg=<cfoutput>#application.pro.getPreviousPage(startMsg)#</cfoutput>"><img src="images\p_page.png" alt="Previous page" style="border:0; width:120px; height:35px;"/></a></td>
			<cfelse>
				<td>&nbsp;</td>
			</cfif>
			<cfif application.pro.isNextPage(startMsg)><!--- do we shown next page button? --->
				<td style="text-align: right;"><a href="index.cfm?startMsg=<cfoutput>#application.pro.getNextPage(startMsg)#</cfoutput>"><img src="images\n_page.png" alt="Next page" style="border:0; width:120px; height:35px;"/></a></td>
			<cfelse>
				<td>&nbsp;</td>
			</cfif>
		</tr>
	</thead>
	
	<tfoot>
		<tr>
			<cfif application.pro.isPreviousPage(startMsg)><!--- do we shown previous page button? --->
				<td style="text-align: left;"><a href="index.cfm?startMsg=<cfoutput>#application.pro.getPreviousPage(startMsg)#</cfoutput>"><img src="images\p_page.png" alt="Previous page" style="border: 0; width:120px; height:35px;"/></a></td>
			<cfelse>
				<td>&nbsp;</td>
			</cfif>
			<cfif application.pro.isNextPage(startMsg)><!--- do we shown next page button? --->
				<td style="text-align: right;"><a href="index.cfm?startMsg=<cfoutput>#application.pro.getNextPage(startMsg)#</cfoutput>"><img src="images\n_page.png" alt="Next page" style="border: 0; width:120px; height:35px;"/></a></td>
			<cfelse>
				<td>&nbsp;</td>
			</cfif>
		</tr>
		<tr><td colspan="2" style="text-align: center;"><a href="add.cfm"><img src="images\new_gb_e.png" alt="Would you like to add an entry to the guest book?" style="border: 0; width:200px; height:35px;"/></a></td></tr>
	</tfoot>
	
	<tbody>
	<tr style="background-color: #c9e4fc"><td colspan="2"><img src="images\divider.png" alt="just a line divider" style="border:0; width:700px; height:15px;"/></td></tr>
	<cfif msg.recordcount eq 0><!--- no messages to display? --->
		<tr><td colspan="2" class="hed">No messages were entered into this Guest Book</td></tr>
		<tr><td colspan="2" class="hed">Enter your message and be the first one!</td></tr>
	</cfif>
	<cfoutput query="msg"><!--- here we spit out actual messages, in separate tables so they don't affect each other --->
		<cfif msg.currentrow/2 eq round(msg.currentrow/2)><!--- alternatig colors table --->
			<cfset Bcolor = "##b0d5fd">
		<cfelse>
			<cfset Bcolor = "##c9e4fc">
		</cfif>
		<tr>
			<td colspan="2">
			<table width="100%" cellspacing="0" cellpadding="1">
			<tr style="background-color: #Bcolor#">
				<td class="gbtext" nowrap>Guest name&nbsp;&nbsp;</td>
				<td>#msg.name#</td>
				<td>&nbsp;</td>
				<td class="gbtext" nowrap>E-mail&nbsp;&nbsp;</td>
				<td><cfif len(trim(msg.email)) gt 0><a href="mailto: #msg.email#">#msg.email#</a></cfif></td>
			</tr>
			<tr style="background-color: #Bcolor#">
				<td class="gbtext" nowrap>Web site&nbsp;&nbsp;</td>
				<td><a href="#msg.website#" target="_blank">#msg.website#</a></td>
				<td>&nbsp;</td>
				<td class="gbtext" nowrap>Date&nbsp;&nbsp;</td>
				<td>#dateformat(msg.date,"yyyy-mm-dd")#</td>
			</tr>
			<tr style="background-color: #Bcolor#"><td colspan="5" class="gbtext">#msg.name# guest book entry:</td></tr>
			<tr style="background-color: #Bcolor#"><td colspan="5" align="left">#msg.message#</td></tr>
			<cfif isUserInRole("admin")><!--- extra for administrators logged in --->
				<tr style="background-color: #Bcolor#">
					<td class="gbtext" nowrap>IP address&nbsp;&nbsp;</td>
					<td>#msg.ip#</td>
					<td>&nbsp;</td>
					<td class="gbtext" nowrap>ID&nbsp;&nbsp;</td>
					<td>#msg.id#</td>
				</tr>
				<tr style="background-color: #Bcolor#">
					<td colspan="3"><a href="delete.cfm?fileNameToDelete=#URLEncodedFormat(msg.filename)#&idToDelete=#URLEncodedFormat(msg.id)#"><img src="images\delete.png" alt="Click to Delete" style="border:0; width:120px; height:35px;"/></a></td>
					<td colspan="2"><a href="edit.cfm?fileNameToEdit=#URLEncodedFormat(msg.filename)#&idToEdit=#URLEncodedFormat(msg.id)#"><img src="images\edit.png" alt="Click to Edit" style="border:0; width:120px; height:35px;"/></a></td>
				</tr>
			</cfif>
			<tr style="background-color: #Bcolor#"><td colspan="5"><img src="images\divider.png" alt="just a line divider" style="border:0; width:700px; height:15px;"/></td></tr>
			</table>
			</td>
		</tr>
	</cfoutput>
	</tbody>
</table>

</div>
</div>

</body>
</html>
</cfprocessingdirective>