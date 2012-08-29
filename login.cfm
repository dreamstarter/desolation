<!--- logout code --->
<cfif isDefined("url.logout")>
	<cflogout>
	<h2>You have been log out from admin area</h2>
	<a href="index.cfm" title="Guest book main page">Guest book main page</a>
	<cflocation url="index.cfm" addtoken="No"><!--- above shouldn't show up --->
</cfif>

<!--- login code --->
<cfif isDefined("form.loginpassword")>
	<cfif application.setup.checkLogin(form.loginpassword)>
		<cflogin idletimeout="1800"><!--- idle time for login is set at 30minutes --->
			<cfloginuser name="admin" password="#form.loginpassword#" roles="admin">
		</cflogin>
		<cfset application.setup.adminLoginPassword = form.loginpassword><!--- there can only be one password in this app --->
		<cflocation url="index.cfm" addtoken="No">
	<cfelse>
		<cfset errMsg = "Invalid password, please enter a correct password">
	</cfif>
<cfelse>
	<cfset errMsg = "">
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Guest Book login page</title>
	<meta name="description" content="Guest Book login page" />
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<link rel="stylesheet" type="text/css" media="all" href="gb.css" />
</head>

<body>

<table cellspacing="3" cellpadding="2">
	<thead>
		<tr><td colspan="3" class="hed"><img src="images\header_login.png" alt="Guest book administrative area login" style="border:0; height:80px; width:700px;"/></td></tr>
		<tr><td colspan="3" class="hed">&nbsp;</td></tr>
	</thead>
	<tbody>
	<form action="login.cfm" method="post" name="loginForm" id="loginForm">
	<tr>
		<td>Login password</td>
		<td><input type="password" name="loginpassword" value="" maxlength="50" size="25"/></td>
		<td>
			<input type="image" name="subBut" src="images\login.png" alt="Administrative area login" style="border:0; height:35px; width:120px;"/>
		</td>
	</tr>
	<cfif len(errMsg)>
	<tr><td colspan="3" class="error"><cfoutput>#errMsg#</cfoutput></td></tr>
	</cfif>
	</form>
	</tbody>
</table>

</body>
</html>
