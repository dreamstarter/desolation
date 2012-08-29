<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Password reset form</title>
</head>

<body>

<!--- instructions: Please uncomment CF code bellow and run the file once. Your password will be
reset to "admin" (without quotes). It is important to COMMENT the code out again so that
unauthorized users will not be able to reset your password! --->

<!--- <cfset passwordHash = "21232F297A57A5A743894A0E4A801FC3">
<cfset setupFileName = "config.xml"><!--- guest book configuration data file --->
<cfset dataDirectory = "data">

<cfset setupFileLocation = ExpandPath(".\") & dataDirectory & "\" & setupFileName>
<cftry>
	<cffile action="READ" file="#setupFileLocation#" variable="rawWddx">
	<cfwddx action="WDDX2CFML" input="#rawWddx#" output="setupData">
	<cfcatch type="Any">
		<cfthrow message="Unable to read setup file either due to file not beeing there or WDDX problem">
	</cfcatch>
</cftry>

<cfset setupData.gbconfig.password = passwordHash>

<cftry>
	<cfwddx action="CFML2WDDX" input="#setupData#" output="rawWddx" usetimezoneinfo="Yes">
	<cffile action="WRITE" file="#setupFileLocation#" output="#rawWddx#" addnewline="Yes">
	<cfcatch type="Any">
		<cfthrow message="Unable to write setup file either due to file not beeing there or WDDX problem">
	</cfcatch>
</cftry>

<h3>Password was reset, you can now log into the administrative area, your password is admin</h3>

<p>Please don't forget to comment out all ColdFusion code inside pwreset.cfm file. Also, it would be
wise to change your administrative password ASAP.</p> --->

</body>
</html>
