<cfcomponent name="gbsetup" displayname="Guest book setup CFC" hint="This compontent is responsible for all setup configuration maniplation.">
	<cfset this.adminLoginPassword = ""><!--- there is no function to get the password of login user + we are hashing the password in the XML file = only way to have the actual password for edit form --->
	<cfset setupFileName = "config.xml"><!--- guest book configuration data file --->
	<cfset dataDirectory = "data">
	<cfset setupData = structNew()><!--- this will store setup data --->
	<cfset initialization = readSetupFile()>
	<cfif not initialization>
		<cfthrow message="Unable to read setup configuration file. Please re-install guest book application or just copy over guest book setup file found in directory #dataDirectory# under guest book root, file name #setupFileName#.">
	</cfif>
	
	<!--- *V. 1.00* --->
	
	<!--- The purpose of this CFC is to deal with XML guest book web application setup. This
	includes interaction with the guest book setup form and security functions related to login. --->
	<!--- setup data components: --->
	<!--- 
	setupData = structNew() - setup file is a single structure
	setupData.gbconfig = structNew() - there is a structure within structure that stores configuration data
	setupData.gbData = arrayNew(1)> - there is a single dimensional array within the main structure that stores data
	dataStruct = structNew()> - data array stores structures
	dataStruct.fileName = [string that makes a file name] - the structures store a data file names
	setupData.gbconfig.password = [password string length between 5 and 50 char] - administrative area password
	setupData.gbconfig.userEmailSize = [a positive integer] - user email field size
	setupData.gbconfig.userNameSize = [a positive integer] - user name field size
	setupData.gbconfig.userWebsiteSize = [a positive integer] - user web site field size
	setupData.gbconfig.userMessageSize = [a positive integer] - user message (guest book entry) size
	setupData.gbconfig.sendEmailOnEntry = [a string that can be empty] - email string, when non-empty email is sent to this address on guest book entry
	setupData.gbconfig.messagesPerPage = [a positive integer] - number of messages that is displayed per guest book entry
	setupData.gbconfig.messagesPerFile = [a positive integer] - number of user guest book entries that data file can store at a maximum
	setupData.gbconfig.ordering = [1 or 0] - which guest book entries are show first, 1 means older 1st, 0 means newest first
	setupData.gbconfig.banIPs = [a string list that can be empty] IP addresses on this list will not be allowed to post messages to this guest book
	setupData.gbconfig.banWords = [a string list that can be empty] when user attempts to post a message which contains a banned word, their message will produce an error
	 --->

<!--- Given an IP of the client it check whatever that IP is not banned, returns true if IP is banned, false otherwise --->
<cffunction name="checkForBanIP" access="public" returntype="boolean" output="false" displayname="Given an IP of the client it check whatever that IP is not banned" hint="">
	<cfargument name="cip" required="true" type="string" displayname="client ip address" hint="">
	<cfif not len(setupData.gbconfig.banIPs)>
		<cfreturn false>
	<cfelse>
		<cfloop index="m" list="#setupData.gbconfig.banIPs#" delimiters=",">
			<cfif m eq arguments.cip>
				<cfreturn true>
			</cfif>
		</cfloop>
		<cfreturn false>
	</cfif>
</cffunction>

<!--- This function returns true if input is a positive integer, false otherwise --->
<cffunction name="isPosInteger" access="private" returntype="boolean" output="false" displayname="Returns true if input is a positive integer, false otherwise" hint="">
	<cfargument name="test" required="true" type="any" displayname="parameter to test" hint="">
	<cfif isNumeric(arguments.test) and arguments.test gt 0 and ceiling(arguments.test) eq arguments.test>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<!--- This function checks whatever email address passed to it is in valid format (it does 
not check whatever there is an actial MX record for such server and such user). --->
<cffunction name="emailValidation" access="private" returntype="string" output="false" displayname="Email address validation" hint="This function checks whatever email address passed to it is in valid format (it does not check whatever there is an actial MX record for such server and such user).">
	<cfargument name="testemail" required="true" type="string" displayname="email string that will be tested for validity" hint="">
	<cfset var ret = "">
	<cfif len(arguments.testemail)>
		<cfif not REFindNoCase(".+@.+\.[\d\w]{2,3}",arguments.testemail)>
			<cfset ret = "Please enter a valid email address">
		</cfif>
	</cfif>
	<cfreturn ret>
</cffunction>

<!--- Check if the string passed to it is a list of valid IP addresses" hint="Strings that are empty return true, strings that are not empty are iterated, if all IPs are OK, true is returned, otherwise false. --->
<cffunction name="isIPList" access="private" returntype="boolean" output="false" displayname="">
	<cfargument name="iplist" required="true" type="string" displayname="Candidate IP list" hint="">
	<cfif len(arguments.iplist)>
		<cfloop index="m" list="#arguments.iplist#" delimiters=",">
			<cfif REFind("\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b",m) eq 0>
				<cfreturn false>
			</cfif>
		</cfloop>
		<cfreturn true>
	<cfelse>
		<cfreturn true><!--- empty strings are OK --->
	</cfif>
</cffunction>

<!--- Returns true if the list of words passed to it is valid - By valid we mean that it is a comma separated list of words without special characters --->
<cffunction name="isValidBanWordList" access="private" returntype="boolean" output="false" displayname="Returns true if the list of words passed to it is valid" hint="By valid we mean that it is a comma separated list of words without special characters">
	<cfargument name="banW" required="true" type="string" displayname="banned words candidate string list" hint="">
	<cfset var banW2 = Replace(arguments.banW,chr(10),"","ALL")>
	<cfset banW2 = Replace(banW2,chr(13),"","ALL")>
	<cfset banW2 = Replace(banW2," ","","ALL")>
	<cfloop index="m" list="#banW2#" delimiters=",">
		<cfloop index="q" from="1" to="#len(m)#" step="1">
			<cfif asc(ucase(mid(m,q,1))) lt 65 or asc(ucase(mid(m,q,1))) gt 90>
				<cftrace inline="false" text="w=#m#">
				<cfreturn false>
			</cfif>
		</cfloop>
	</cfloop>
	<cfreturn true>
</cffunction>

<!--- This function checks data passed to it for comformation to the structure format. If it is found to be valid, true is returned, otherwise false is returned. --->
<cffunction name="checkSetupFile" access="private" returntype="boolean" output="false" displayname="Check data found in the setup file for validity" hint="This function checks data passed to it for comformation to the structure format. If it is found to be valid, true is returned, otherwise false is returned.">
	<cfargument name="configFileData" required="true" type="any" displayname="Candidate data read from setup file" hint="">
	<cfif not isStruct(arguments.configFileData)>
		<cftrace inline="false" text="Data extracted from guest book configuration file does not contain the main structure!">
		<cfreturn false>
	<cfelse>
		<cfif not isDefined("arguments.configFileData.gbdata") or not isDefined("arguments.configFileData.gbconfig") or not isArray(arguments.configFileData.gbdata) or not isStruct(arguments.configFileData.gbconfig)>
			<cftrace inline="false" text="Data extracted from guest book configuration file does not contain the sub structure for configuration or array for data">
			<cfreturn false>
		</cfif>
	</cfif>
	<cfreturn true>
</cffunction>

<!--- Read XML file and if successful place data into internal structure, returns false on any error --->
<cffunction name="readSetupFile" access="private" returntype="boolean" output="false" displayname="Read XML file and if successful place data into internal structure" hint="Returns false on any error.">
	<cfset var setupFileLocation = ExpandPath(".\") & dataDirectory & "\" & setupFileName>
	<cftry>
		<cffile action="READ" file="#setupFileLocation#" variable="rawWddx">
		<cfwddx action="WDDX2CFML" input="#rawWddx#" output="setupData">
		<cfcatch type="Any">
			<cftrace inline="false" text="Unable to read setup file either due to file not beeing there or WDDX problem">
			<cfreturn false>
		</cfcatch>
	</cftry>
	<cfreturn checkSetupFile(setupData)>
</cffunction>

<!--- This function has to allow for execution without the admin role since data needs to be written when new data file is added by guest book add operation. --->
<cffunction name="writeSetupFile" access="public" returntype="boolean" output="false" displayname="Write setup data to disk" hint="This function has to allow for execution without the admin role since data needs to be written when new data file is added by guest book add operation.">
	<cfset var setupFileLocation = ExpandPath(".\") & dataDirectory & "\" & setupFileName>
	<cftry>
		<cfwddx action="CFML2WDDX" input="#setupData#" output="rawWddx" usetimezoneinfo="Yes">
		<cffile action="WRITE" file="#setupFileLocation#" output="#rawWddx#" addnewline="Yes">
		<cfcatch type="Any">
			<cftrace inline="false" text="Unable to write setup file either due to file write problem (disk?) or WDDX conversion problem">
			<cfreturn false>
		</cfcatch>
	</cftry>
	<cfreturn true>
</cffunction>

<!--- Add new data file name to the configuration file, the return value indicates success of the addition operation --->
<cffunction name="addNewDataFileName" access="package" returntype="boolean" output="false" displayname="Add new data file name to the configuration file" hint="The return value indicates success of the addition operation">
	<cfargument name="newFileName" required="true" type="string" displayname="new data file name" hint="">
	<cfset var ins = structNew()>
	<cfset ins.filename = arguments.newFileName>
	<cfset arrayAppend(setupData.gbData,ins)>
	<cfreturn writeSetupFile()>
</cffunction>

<!--- Write down data that makes up user settings accessible only for administrators of the guest book
Throws an error on data writing problem. We assume user will not hack his own guest book. --->
<cffunction name="writeAllUserSetupData" access="public" returntype="boolean" output="false" roles="admin" displayname="Write down data that makes up user settings accessible only for administrators of the guest book" hint="Throws an error on data writing problem. We assume user will not hack his own guest book.">
	<cfargument name="userStruct" required="true" type="struct" displayname="structure containing user defined configuration data" hint="This data is assumed to be valid">
	<cfset setupData.gbconfig = Duplicate(arguments.userStruct)>
	<cfset this.adminLoginPassword = setupData.gbconfig.password><!--- so we know what the password is --->
	<cfset setupData.gbconfig.password = hash(setupData.gbconfig.password)><!--- only hash here --->
	<!--- remove password2 field (don't want unencrypted password ther!) --->
	<cfset StructDelete(setupData.gbconfig,"password2")>
	<cfif not writeSetupFile()>
		<cfthrow message="There was a problem with saving your user data!">
		<cfreturn false>
	</cfif>
	<cfreturn true>
</cffunction>

<!--- Check information entered by the user for setup data
This function takes the user provided setup data and checks it for validity, for example it checks whatever password was entered or the number of messages to be displayed per page is a positive integer. --->
<cffunction name="checkUserSetupData" access="public" returntype="struct" output="false" displayname="Check information entered by the user for setup data" roles="admin" hint="This function takes the user provided setup data and checks it for validity, for example it checks whatever password was entered or the number of messages to be displayed per page is a positive integer.">
	<cfargument name="userStruct" required="true" type="any" displayname="structure containing user defined configuration data" hint="This data is to be checked for validity">
	<cfset var ret = structNew()>
	<cfset ret.success = true><!--- true if form passed all the tests, false otherwise --->
	<cfif not isStruct(arguments.userStruct)>
		<cfthrow message="This function was expecting form data - a structure, what it got was something else, check your inputs!">
	<cfelse>
		<cfif not isDefined("arguments.userStruct.password") or len(arguments.userStruct.password) lt 5 or len(arguments.userStruct.password) gt 50>
			<cfset ret.password = "Please make sure you provide a password and its length is between 5 and 50 characters.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.password = "">
		</cfif>
		<!--- note the use of 'is' keyword in the password equality test, passwords are case sensitive thus strict equality is needed --->
		<cfif not isDefined("arguments.userStruct.password2") or (isDefined("arguments.userStruct.password") and isDefined("arguments.userStruct.password2") and not (arguments.userStruct.password is arguments.userStruct.password2))>
			<cfset ret.password2 = "Re-entered password doesn't match the original, please re-enter both passwords">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.password2 = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.userEmailSize") or not isPosInteger(arguments.userStruct.userEmailSize)>
			<cfset ret.userEmailSize = "User e-mail size has to be a positive integer.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.userEmailSize = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.userNameSize") or not isPosInteger(arguments.userStruct.userNameSize)>
			<cfset ret.userNameSize = "User name size has to be a positive integer.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.userNameSize = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.userWebsiteSize") or not isPosInteger(arguments.userStruct.userWebsiteSize)>
			<cfset ret.userWebsiteSize = "User web site size has to be a positive integer.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.userWebsiteSize = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.userMessageSize") or not isPosInteger(arguments.userStruct.userMessageSize)>
			<cfset ret.userMessageSize = "User message size has to be a positive integer.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.userMessageSize = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.messagesPerPage") or not isPosInteger(arguments.userStruct.messagesPerPage)>
			<cfset ret.messagesPerPage = "The number of user messages displayed per page has to be a positive integer.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.messagesPerPage = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.messagesPerFile") or not isPosInteger(arguments.userStruct.messagesPerFile)>
			<cfset ret.messagesPerFile = "The number of user messages that is to be stored per data file has to be a positive integer.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.messagesPerFile = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.sendEmailOnEntry") or (len(arguments.userStruct.sendEmailOnEntry) and len(emailValidation(arguments.userStruct.sendEmailOnEntry)))>
			<cfset ret.sendEmailOnEntry = "Please enter a valid e-mail address if you would like to receive e-mail notifications.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.sendEmailOnEntry = "">
		</cfif>
		<cfif not isDefined("arguments.userStruct.ordering") or (arguments.userStruct.ordering neq 0 and arguments.userStruct.ordering neq 1)>
			<cfset ret.ordering = "Please select the order in which messages are to be displayed on the first index page.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.ordering = "">
		</cfif>
		<!--- banIPs is not required (can be empty), max length is 1000 --->
		<cfif not isDefined("arguments.userStruct.banIPs") or not isIPList(arguments.userStruct.banIPs) or len(arguments.userStruct.banIPs) gt 1000>
			<cfset ret.banIPs = "If you want to enter benned IPs, make sure they formatted as a comma separated list.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.banIPs = "">
		</cfif>
		<!--- banWords is not required (can be empty), max length is 1000 --->
		<cfif not isDefined("arguments.userStruct.banWords") or len(arguments.userStruct.banWords) gt 1000>
			<cfset ret.banWords = "Please make sure banned words field is present and input is less than 1000 characters.">
			<cfset ret.success = false>
		<cfelseif not isValidBanWordList(arguments.userStruct.banWords)>
			<cfset ret.banWords = "Please make sure that the banned words are a list without special characters">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.banWords = "">
		</cfif>
	</cfif>
	<cfreturn ret>
</cffunction>

<!--- This function is used so that user entries into the setup form are not forgotten. 
Nothing is worse than a user who enters data with one wrong speck in it and when he submits data is lost. Users and programmers hate to re-enter data. This function prevents stuff from happening that pisses users off. --->
<cffunction name="convertFormToSetupData" access="public" returntype="struct" output="false" displayname="Convert form variable data to look like data from user setup data" hint="This function is used so that user entries into the setup form are not forgotten. Nothing is worse than a user who enters data with one wrong speck in it and when he submits data is lost. Users and programmers hate to re-enter data. This function prevents stuff from happening that pisses users off.">
	<cfargument name="fs" required="true" type="struct" displayname="user entered data from a form" hint="Note this may not be a valid data, but that doesn't change things, this is for memory only">
	<cfset var ret = structNew()>
	<cfset ret.gbconfig = arguments.fs>
	<cfif not isDefined("arguments.fs.ordering")><!--- this is to fix a bug in Opera where it doesn't pass radio button well --->
		<cfset ret.gbconfig.ordering = 1>
	</cfif>
	<cfset ret.gbData = setupData.gbdata>
	<cfreturn ret>
</cffunction>

<!--- **** Get portions of setup data **** --->

<!--- Returns the whole setup structure (Not to be abused) --->
<cffunction name="getAllSetupData" access="public" returntype="struct" output="false" roles="admin" displayname="Returns the whole setup structure" hint="Not to be abused">
	<cfreturn setupData>
</cffunction>

<!--- Check whatever password passed to it is valid, returns true if passwords match, false otherwise. --->
<cffunction name="checkLogin" access="public" returntype="boolean" output="false" displayname="Check whatever password passed to it is valid" hint="Returns true if passwords match, false otherwise.">
	<cfargument name="pass" required="true" type="string" displayname="candidate login string" hint="Maximum of 50 characters">
	<cfif len(arguments.pass) lte 50><!--- maximum password size is fixed at 50 --->
		<cfif setupData.gbconfig.password eq hash(arguments.pass)><!--- check if hashes agree --->
			<cfreturn true>
		<cfelse>
			<cftrace inline="false" text="The password used to log in, hashes to #hash(arguments.pass)# while system stored hash is: #setupData.gbconfig.password#">
			<cfreturn false>
		</cfif>
	<cfelse>
		<cftrace inline="false" text="Password length exceed the hard coded length of 50 characters!">
		<cfreturn false>
	</cfif>
</cffunction>

<!--- Get the data array for use in gust book display caching function --->
<cffunction name="getMessageDataArray" access="package" returntype="array" output="false" displayname="Get the data array for use in gust book display caching function" hint="">
	<cfreturn setupData.gbdata>
</cffunction>

<!--- This function returns filed sizes of elements, it is used to dynamically generate 
the right form field lenghts while adding guest book data --->
<cffunction name="FieldSize" access="public" returntype="struct" output="false" displayname="This function returns filed sizes of elements" hint="Used to dynamically generate the right form field lenghts while adding guest book data">
	<cfreturn setupData.gbconfig>
</cffunction>

<!--- This function returns the number of messages in the guest book --->
<cffunction name="messagesPerPage" access="public" returntype="numeric" output="false" displayname="This function returns the number of messages in the guest book" hint="">
	<cfreturn setupData.gbconfig.messagesPerPage>
</cffunction>

</cfcomponent>