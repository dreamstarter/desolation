<cfapplication name="GB" sessionmanagement="Yes" sessiontimeout="#createtimespan(0,1,0,0)#" applicationtimeout="#createtimespan(2,0,0,0)#">

<!--- Exception error page --->
<cferror type="EXCEPTION" template="exceptionerr.cfm">

<cfif not isDefined("application.setup")>
	<cftry>
		<cfobject component="gbsetup" name="gbsetup">
		<cfset application.setup = gbsetup>
		<cfcatch type="any">
			<cfthrow message="Could not initialize Guest book setup CFC!">
		</cfcatch>
	</cftry>
</cfif>

<cfif not isDefined("application.pro")>
	<cftry>
		<cfobject component="gbpro" name="processing">
		<cfset application.pro = processing>
		<cfcatch type="any">
			<cfthrow message="Could not initialize Guest book processing CFC!">
		</cfcatch>
	</cftry>
</cfif>