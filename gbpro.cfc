<cfcomponent name="gbpro" displayname="Guest book processing component" hint="This component is responsible for manipulation of the XML data that contains user's comments.">
	<cfset dataDirectory = "data">
	<cfset this.encryptionString = "456fsdfsd7ddsa"><!--- automation defense encryption string --->
	<cfset Randomize(round(getTickCount()/10000))><!--- Make sure images are random --->
	<cfset testPicArray = setupTestPictures()><!--- Random image array --->
	<!--- CFC initialization, get all gust book entries and cache them all --->
	<cfset guestBookData = queryNew("filename,num,name,email,website,date,ip,message,id")><!--- cache variable --->
	<cfset totalMsgNumber = 0><!--- the total number of messages contained within a guest book --->
	<cfset entriesPerFile = arrayNew(1)><!--- store the file name and number of entries in it --->
	<cfset resV = intiCacheData()>
	<cfif not resV>
		<cfthrow message="Failed to read all guest book XML data files. It is possible that one of the files doesn't exist or is corrupted. You can check by hand or just restore from backup.">
	</cfif>
	
	<!--- *V. 1.02* July 18th 2005 Added test picture support --->
	
	<!--- NOTES: --->
	<!--- The purpose of this CFC is to deal with normal day to day activities that users perform
	when interacting with the guest book application. This includes displaying the gust book
	entries, adding new entries, editing existing entries and deleting no longer desired entries. --->
	<!--- Above initialization variables are not scoped with 'this' keyword since they are private to this CFC --->
	<!--- Each function has a comment on top of it describing in detail its function. This comment is very similar
	or identical to the hint/displayname property of the function. However, the lines are broken
	up and it is much easier to follow them then long 'hint' properties of functions. I have
	still included the help text inside function paramenters since it makes use of automated 
	CFC browsing tools a possibility. --->

	<!--- XML data file schema explanation --->
	<!--- The root element is called gbdata, it has a property recordNumber which is the number of 
	records stored in this particular data file. Inside gbdata element there are gbentry elements (no
	maximum or minimum number of these) each gbentry element has properties ip, id and date. The date
	holds date value which, if not edited by the system administrator is the time when record was
	created. The IP is the IP address of the PC that made the entry (if not modified by guest book administrator),
	the ID is system generated message ID. The gbentry element has the following child elements: name, email,
	website and message. Their purpose is self explanatory. --->

<cffunction name="setupTestPictures" access="private" returntype="array" output="false" displayname="Setup Test Picture array" hint="">
	<cfset var testFileExt = ".gif"><!--- All test pictures are GIFs --->
	<cfset var testText = "akw971|btq129|ffq129|gto565|hgw634|qsd834|txc237|upd912|ytq391|zqy260|wen473|fog511|rup412|rus247|ccc666|can345|ftt960|dog129|cat390|joe725">
	<cfset var ret = arrayNew(1)>
	<cfset var temp = structNew()>
	
	<cfloop index="m" list="#testText#" delimiters="|">
		<cfset temp = structNew()>
		<cfset temp.text = m>
		<cfset temp.file = m & testFileExt>
		<cfset arrayAppend(ret,temp)>
	</cfloop>
	
	<cftrace inline="false" text="Test picture array created with #arrayLen(ret)# elements.">
	<cfreturn ret>
</cffunction>

<cffunction name="getTestImg" access="public" returntype="struct" output="false" displayname="Get test image" hint="Get anty automation image - protect yourself from people that just dump their stuff onto you.">
	<cfset var randImg = RandRange(1, arrayLen(testPicArray))><!--- Arrays start at 1 --->
	<cfreturn testPicArray[randImg]>
</cffunction>

<!--- This function returns true if input is a positive integer, false otherwise --->
<cffunction name="isPosInteger" access="public" returntype="boolean" output="false" displayname="Returns true if input is a positive integer, false otherwise" hint="">
	<cfargument name="test" required="true" type="any" displayname="parameter to test" hint="anything">
	<cfif isNumeric(arguments.test) and arguments.test gt 0 and ceiling(arguments.test) eq arguments.test>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<!--- This function returns true if input is a natural number, false otherwise --->
<cffunction name="isNaturalNumber" access="public" returntype="boolean" output="false" displayname="Returns true if input is a natural number, false otherwise" hint="">
	<cfargument name="test" required="true" type="any" displayname="parameter to test" hint="anything">
	<cfif isNumeric(arguments.test) and arguments.test gte 0 and ceiling(arguments.test) eq arguments.test>
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
	<cfset var te = escapeHtmlTags(arguments.testemail)>
	<cfif len(te)>
		<cfif not REFindNoCase(".+@.+\.[\d\w]{2,3}",te)>
			<cfset ret = "Please enter a valid email address">
		</cfif>
	</cfif>
	<cfreturn ret>
</cffunction>

<!--- This function checks whatever input sent to it is a valid URL (more then 4 characters)
and returns true if it is, false otherwise. --->
<cffunction name="isValidURL" access="private" returntype="boolean" output="false" displayname="Is the input a valid url address?" hint="This function checks whatever input sent to it is a valid URL (more then 4 characters) and returns true if it is, false otherwise.">
	<cfargument name="testURL" required="true" type="string" displayname="url string to be tested" hint="">
	<cfif len(escapeHtmlTags(arguments.testURL)) lt 4>
		<cfreturn false>
	<cfelse>
		<cfreturn true>
	</cfif>
</cffunction>

<!--- Check for banned words in the message, if any found, return the first one found --->
<cffunction name="bannedWordsCheck" access="private" returntype="string" output="false" displayname="Check for banned words in the message, if any found, return the first one found" hint="">
	<cfargument name="msgText" required="true" type="string" displayname="message text" hint="">
	<cfargument name="configData" required="true" type="struct" displayname="configuration data" hint="">
	<cfset var ret = "">
	<cfset var reexp = "">
	<cfset var searchRes = "">
	<cfif not len(arguments.configData.banWords)>
		<cfreturn ""><!--- no banned words --->
	</cfif>
	<!--- build regular expression --->
	<cfloop index="m" list="#arguments.configData.banWords#" delimiters=",">
		<cfset reexp = reexp & m & "|">
	</cfloop>
	<cftry>
		<cfset reexp = left(reexp,len(reexp)-1)><!--- remove last pipe --->
		<cfset reexp = "\b(" & reexp & ")\b">
		<cfset searchRes = REFindNoCase(reexp,arguments.msgText,1,true)><!--- avoid double evaluation --->
		<cfif searchRes.len[1] neq 0>
			<cfset ret = mid(arguments.msgText,searchRes.pos[1],searchRes.len[1]) & " at position " & searchRes.pos[1]>
		</cfif>
		<cfcatch type="Any">
			<cftrace inline="false" text="There was a problem checking banned words! Make sure you are passing a list of words with comma as a delimeter">
		</cfcatch>
	</cftry>
	<cfreturn ret>
</cffunction>

<!--- Long words detection" hint="This function will detect words that are longer than 60 characters and return true if it finds any, false otherwise. --->
<cffunction name="superLongWordsDet" access="private" returntype="boolean" output="false" displayname="Long words detection" hint="This function will detect words that are longer than 60 characters and return true if it finds any, false otherwise.">
	<cfargument name="msgText" required="true" type="string" displayname="message text" hint="">
	<cfloop index="m" list="#arguments.msgText#" delimiters="#chr(32)##chr(13)##chr(10)#">
		<cfif len(m) gt 50>
			<cfreturn true>
		</cfif>
	</cfloop>
	<cfreturn false>
</cffunction>

<!--- This function replaces of occurances of the return with <br> tags. --->
<cffunction name="createPageBreaks" access="private" returntype="string" output="false" displayname="Create page breaks in text" hint="This function replaces of occurances of the return with <br> tags.">
	<cfargument name="msgText" required="true" type="string" displayname="message text" hint="">
	<cfset var pb = Chr(13) & Chr(10)>
	<cfset var ret = "">
	<cfset ret = Replace(arguments.msgText, pb, "<br/>", "ALL")>
	<!--- <cfset ret = rereplace(arguments.msgText, "\f|\n|\r", "<br/>", "ALL")> --->
	<cfreturn ret>
</cffunction>

<!--- This function removes BR tags and place page breaks into their place. --->
<cffunction name="removeBR" access="private" returntype="string" output="false" displayname="Remove BR tags and place page breaks into their place" hint="This function removes BR tags and place page breaks into their place.">
	<cfargument name="msgText" required="true" type="string" displayname="message text" hint="">
	<cfset var pb = Chr(13) & Chr(10)>
	<cfset var ret = "">
	<cfset ret = Replace(arguments.msgText, "<br/>",pb,"ALL")>
	<cfreturn ret>
</cffunction>

<!--- Make URL valid by making sure 'http://' is at the fornt of the string. --->
<cffunction name="makeValidURL" access="private" returntype="string" output="false" displayname="Make URL valid by making sure 'http://' is at the fornt of the string" hint="">
	<cfargument name="urlString" required="true" type="string" displayname="url string" hint="Assumed to be otherwise valid">
	<cfset var us = escapeHtmlTags(arguments.urlString)>
	<cfif us eq "http://" or us eq "https://">
		<cfreturn "">
	</cfif>
	<cfif len(us) gte 7>
		<cfif left(us,7) eq "http://">
			<cfreturn us>
		<cfelse>
			<cfreturn "http://" & us>
		</cfif>
	<cfelseif len(us) gte 8>
		<cfif left(us,8) eq "https://">
			<cfreturn us>
		<cfelse>
			<cfreturn "http://" & us>
		</cfif>
	<cfelse>
		<cfif len(us)>
			<cfreturn "http://" & us>
		<cfelse>
			<cfreturn us>
		</cfif>
	</cfif>
</cffunction>

<!--- Does the same thing as date format function in CF but more securly (Includes check for invalid date passed) --->
<cffunction name="myDateFormat" access="private" returntype="date" output="false" displayname="Does the same thing as date format function in CF but more securly" hint="Includes check for invalid date passed">
	<cfargument name="testdate" required="true" type="any" displayname="Candidate date" hint="">
	<cfif isDate(arguments.testdate)>
		<cfreturn dateformat(arguments.testdate, "yyyy-mm-dd")>
	<cfelse>
		<cfreturn dateformat(now(), "yyyy-mm-dd")>
	</cfif>
</cffunction>

<!--- Convert query to a structure (Only 1st row of a query is converted to a struct) --->
<cffunction name="queryToStruct" access="public" returntype="struct" output="false" displayname="Convert query to a structure" hint="Only 1st row of a query is converted to a struct">
	<cfargument name="queryToConv" required="true" type="query" displayname="Query which we are going to convert to a struct" hint="">
	<cfset var ret = structNew()>
	<cfloop index="m" list="#arguments.queryToConv.columnList#" delimiters=",">
		<cfset structInsert(ret,m,evaluate("queryToConv.#m#"),true)>
	</cfloop>
	<cfreturn ret>
</cffunction>

<!--- Creates structure from input list --->
<cffunction name="listToStruct" access="public" returntype="struct" output="false" displayname="Creates structure from input list" hint="">
	<cfargument name="mylist" required="true" type="string" displayname="String list" hint="">
	<cfargument name="del" required="false" default="," type="string" displayname="List delimeter" hint="Not required, comma is the default setting">
	<cfset var ret = structNew()>
	<cfloop index="m" list="#arguments.mylist#" delimiters="#arguments.del#">
		<cfset structInsert(ret,m,"",true)>
	</cfloop>
	<cfreturn ret>
</cffunction>

<!--- This function strips from the input all tags, where tag is anything starting with < and ending with a >. --->
<cffunction name="escapeHtmlTags" access="private" returntype="string" output="false" displayname="Return text with no HTML style tags" hint="This function strips from the input all tags, where tag is anything starting with < and ending with a >.">
	<cfargument name="htmlText" required="true" type="string" displayname="html text to be converted to plain text" hint="">
	<cfset var ret = REReplaceNoCase(arguments.htmlText,"<[^>]*>","","ALL")><!--- replace html and any other tags with blanks --->
	<cfreturn ret>
</cffunction>

<!--- Returns the total number of guest book messages --->
<cffunction name="totalGuestBookMessages" access="public" returntype="numeric" output="false" roles="admin" displayname="Returns the total number of guest book messages" hint="">
	<cfreturn totalMsgNumber>
</cffunction>

<!--- *** data file caching and searching *** --->

<!--- This function validates XML structure passed to it for comformation with gust book data file schema
This function will return false on any error that occurs while validating the XML file. --->
<cffunction name="validateXMLdataFile" access="private" returntype="boolean" output="false" displayname="This function validates XML structure passed to it for comformation with gust book data file schema" hint="This function will return false on any error that occurs while validating the XML file.">
	<cfargument name="pXML" required="true" type="any" displayname="Parsed XML string extracted from data file" hint="">
	<cfif IsXmlDoc(arguments.pXML)>
		<cfif arguments.pXML.xmlroot.XmlName neq "gbdata">
			<cftrace inline="false" text="The root of the XML data file is not 'gbdata'.">
			<cfreturn false>
		</cfif>
		<cftry>
			<cfif not isNumeric(arguments.pXML.xmlroot.xmlAttributes.recordNumber)>
				<cftrace inline="false" text="The root of the XML data file doesn't contain valid value for attribute recordNumber (i.e. positive integer)">
				<cfreturn false>
			</cfif>
			<cfcatch type="Expression">
				<cftrace inline="false" text="The root of the XML data file doesn't contain attribute recordNumber (which should be a positive integer)">
				<cfreturn false>
			</cfcatch>
		</cftry>
		<cfloop index="m" from="1" to="#arrayLen(arguments.pXML.xmlroot.xmlchildren)#" step="1">
			<cftry>
				<!--- There tests are wrapped in a cftry tag since some of them may not exist and cause an error when value of their is tested --->
				<cfif arguments.pXML.xmlroot.xmlchildren[m].XmlName neq "gbentry">
					<cftrace inline="false" text="The guest book entry element has an invalid name!">
					<cfreturn false>
				</cfif>
				<cfif not len(arguments.pXML.xmlroot.xmlchildren[m].xmlAttributes.ip) or not isDate(arguments.pXML.xmlroot.xmlchildren[m].xmlAttributes.date) or not len(arguments.pXML.xmlroot.xmlchildren[m].xmlAttributes.id)>
					<cftrace inline="false" text="One of the xmlAttributes of guest book entry (such as ip, date or id) is empty.">
					<cfreturn false>
				</cfif>
				<cfset test1 = arguments.pXML.xmlroot.xmlchildren[m].email.XmlText>
				<cfset test2 = arguments.pXML.xmlroot.xmlchildren[m].name.XmlText>
				<cfset test3 = arguments.pXML.xmlroot.xmlchildren[m].website.XmlText>
				<cfset test4 = arguments.pXML.xmlroot.xmlchildren[m].message.XmlText>
				<cfif not len(arguments.pXML.xmlroot.xmlchildren[m].name.XmlText)>
					<cftrace inline="false" text="There was no name of guest book user found in the XML file, this is a required element!">
					<cfreturn false>
				</cfif>
				<cfcatch type="Expression">
					<cftrace inline="false" text="One or more of the values faund in guest book entry section of data file is invalid">
					<cfreturn false>
				</cfcatch>
			</cftry>
		</cfloop>
	<cfelse>
		<cftrace inline="false" text="The value passed does not appear to be a valid XML document">
		<cfreturn false>
	</cfif>
	<cfreturn true>
</cffunction>

<!--- This function gets all data file names, reads them and stores them in the CFC. This greatly increases 
speed of the CFC. Each time something is added another function is used to update, no need to read 1000's of messages when just one is added! --->
<cffunction name="intiCacheData" access="private" returntype="boolean" output="false" displayname="CFC initialization (data caching)" hint="This function gets all data file names, reads them and stores them in the CFC. This greatly increases speed of the CFC. Each time something is added another function is used to update, no need to read 1000's of messages when just one is added!">
	<cfset var da = application.setup.getMessageDataArray()><!--- get data array --->
	<cfset var counter = 1>
	<!--- we repeat the initialization of the global variables here in case this function gets called twice --->
	<cfset guestBookData = queryNew("filename,num,name,email,website,date,ip,message,id")><!--- cache variable --->
	<cfset totalMsgNumber = 0><!--- the total number of messages contained within a guest book --->
	<cfset entriesPerFile = arrayNew(1)><!--- store the file name and number of entries in it --->
	<!--- loop through every data file, and get the XML parsed from that data file --->
	<cftrace inline="false" text="The number of XML data files that need processing: #arrayLen(da)#">
	<cfloop index="m" from="1" to="#arrayLen(da)#" step="1">
		<cfset dataFileName = da[m].fileName>
		<cfset dataFileLocation = ExpandPath(".\") & dataDirectory & "\" & dataFileName>
		<cftry>
			<cffile action="READ" file="#dataFileLocation#" variable="rawXML">
			<cfset parsedXML = xmlParse(rawXML)>
			<cfcatch type="Any">
				<cftrace inline="false" text="Failed to read data from guest book data file. Either file read operation failed or XML parsing failed.">
				<cfreturn false>
			</cfcatch>
		</cftry>
		<!--- check for validity of XML within data file --->
		<cfif not validateXMLdataFile(parsedXML)>
			<cftrace inline="false" text="The gust book data file, #dataFileName#, failed validity test, it is not the right XML format!">
			<cfreturn false>
		</cfif>
		<!--- enter values into an array that stores number of entries used per file --->
		<cfset insertA = structNew()>
		<cfset insertA.filename = dataFileName>
		<cfset insertA.entries = parsedXML.xmlroot.xmlAttributes.recordNumber>
		<cfset arrayAppend(entriesPerFile,insertA)>
		<cfset totalMsgNumber = totalMsgNumber + parsedXML.xmlroot.xmlAttributes.recordNumber><!--- total guest book messages counter --->
		<!--- loop through the data in this particular file and add it to the main query --->
		<cfloop index="k" from="1" to="#arrayLen(parsedXML.xmlroot.xmlchildren)#" step="1">
			<cfset QueryAddRow(guestBookData)>
			<cfset QuerySetCell(guestBookData, "num", counter)>
			<cfset QuerySetCell(guestBookData, "filename", dataFileName)>
			<cfset QuerySetCell(guestBookData, "name", parsedXML.xmlroot.xmlchildren[k].name.XmlText)>
			<cfset QuerySetCell(guestBookData, "email", parsedXML.xmlroot.xmlchildren[k].email.XmlText)>
			<cfset QuerySetCell(guestBookData, "website", parsedXML.xmlroot.xmlchildren[k].website.XmlText)>
			<cfset QuerySetCell(guestBookData, "date", parsedXML.xmlroot.xmlchildren[k].xmlAttributes.date)>
			<cfset QuerySetCell(guestBookData, "ip", parsedXML.xmlroot.xmlchildren[k].xmlAttributes.ip)>
			<cfset QuerySetCell(guestBookData, "message", parsedXML.xmlroot.xmlchildren[k].message.XmlText)>
			<cfset QuerySetCell(guestBookData, "id", parsedXML.xmlroot.xmlchildren[k].xmlAttributes.id)>
			<cfset counter = counter + 1>
		</cfloop>
	</cfloop>
	<cfreturn true>
</cffunction>

<!--- Used by getMessages function only, returns a query with messages for the first page of the guest book --->
<cffunction name="getMessagesFirstPage" access="private" returntype="query" output="false" displayname="Used by getMessages function only" hint="Returns a query with messages for the first page of the guest book">
	<cfargument name="config" required="true" type="struct" displayname="configuration structure from setup module" hint="No need to call it twice">
	<!--- Please note that we start from zero in few cases since the filter is set from x to lt y so 1 to lt 1 wouldn't work --->
	<cfif arguments.config.ordering eq 1><!--- older messages are shown on the first guest book page --->
		<cfif arguments.config.messagesPerPage gte totalMsgNumber>
			<cftrace inline="false" text="[1]This is 1st guest book page, older msg shown 1st, displaying msg from 1 to #totalMsgNumber+1#">
			<cfreturn getMessageQuery(0, totalMsgNumber+1, false)>
		<cfelse>
			<cftrace inline="false" text="[2]This is 1st guest book page, older msg shown 1st, displaying msg from 1 to #arguments.config.messagesPerPage+1#">
			<cfreturn getMessageQuery(1, arguments.config.messagesPerPage+1, false)>
		</cfif>
	<cfelse><!--- newer messages first --->
		<cfif arguments.config.messagesPerPage gte totalMsgNumber><!--- for boundary adj. --->
			<cftrace inline="false" text="[3]This is 1st guest book page, newer msg shown 1st, displaying msg from 1 to #totalMsgNumber+1#">
			<cfreturn getMessageQuery(0, totalMsgNumber+1, true)>
		<cfelse>
			<cftrace inline="false" text="[4]This is 1st guest book page, newer msg shown 1st, displaying msg from #totalMsgNumber-arguments.config.messagesPerPage+1# to #totalMsgNumber+1#">
			<cfreturn getMessageQuery(totalMsgNumber-arguments.config.messagesPerPage+1, totalMsgNumber+1,true)>
		</cfif>
	</cfif>
</cffunction>

<!--- Used by main page to return a query that contains the right number of messages --->
<!--- This function together with getPreviousPage, getNextPage, isPreviousPage and isNextPage 
control which messages are displayed on the guest book page. These functions gave me the most
trouble and I am still not sure whatever they work correctly. The biggest challenge was making the
newest first ordering work, as it was sort of counter intuitive to count backwords. If you find any
problems, please e-mail me (preferably fix things first :) ) --->
<cffunction name="getMessages" access="public" returntype="query" output="false" displayname="Used by main page to return a query that contains the right number of messages" hint="">
	<cfargument name="currentStartMsg" required="true" type="any" displayname="define 0 as nothing - no value, this is for nat having to use ifs in the calling page for variable existance checking" hint="">
	<cfset var conf = application.setup.FieldSize()><!--- get configuration data --->
	<!--- check for a valid input (this input can be taken from URL variable) --->
	<cfif not isNumeric(arguments.currentStartMsg) or arguments.currentStartMsg lt -1>
		<cftrace inline="false" text="The current starting guest book entry is invlaid, it is not numeric or it is negative [lt -1], #arguments.currentStartMsg#, ignoring value">
		<cfreturn getMessagesFirstPage(conf)>
	</cfif>
	<!--- get guest book entries for the display page --->
	<cfif arguments.currentStartMsg eq -1><!--- 1st GB page --->
		<cfreturn getMessagesFirstPage(conf)>
	<cfelse><!--- not first page --->
		<!--- We always display forward of the reference point, only difference is in the page message ordering --->
		<cfif conf.ordering eq 1><!--- older messages 1st--->
			<cfif (arguments.currentStartMsg + conf.messagesPerPage) gt totalMsgNumber><!--- last page till total messages --->
				<cftrace inline="false" text="[5]This is not 1st guest book page, older msg shown 1st, displaying msg from #arguments.currentStartMsg# to #totalMsgNumber+1#">
				<cfreturn getMessageQuery(arguments.currentStartMsg, totalMsgNumber+1, false)>
			<cfelse><!--- page somewhere in the middle or 1st --->
				<cftrace inline="false" text="[6]This is not 1st guest book page, older msg shown 1st, displaying msg from #arguments.currentStartMsg# to #arguments.currentStartMsg + conf.messagesPerPage#">
				<cfreturn getMessageQuery(arguments.currentStartMsg, arguments.currentStartMsg + conf.messagesPerPage, false)>
			</cfif>
		<cfelse><!--- newer messages first --->
			<cfif arguments.currentStartMsg eq 0><!--- last page till total messages --->
				<!--- fix a bug => what if we have a perfect fit i.e. totalMsgNumber - fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage = 0? --->
				<cfif totalMsgNumber - fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage gt 0>
					<cftrace inline="false" text="[7]This is not 1st guest book page, newer msg shown 1st, displaying msg from #arguments.currentStartMsg# to #totalMsgNumber+1-fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage#">
					<cfreturn getMessageQuery(arguments.currentStartMsg+1, totalMsgNumber+1-fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage, true)>
				<cfelse>
					<cftrace inline="false" text="[7.5]This is not 1st guest book page, newer msg shown 1st, displaying msg from #arguments.currentStartMsg# to #conf.messagesPerPage+1#">
					<cfreturn getMessageQuery(arguments.currentStartMsg+1, conf.messagesPerPage+1, true)>
				</cfif>
			<cfelse><!--- page somewhere in the middle or 1st --->
				<cftrace inline="false" text="[8]This is not 1st guest book page, newer msg shown 1st, displaying msg from #arguments.currentStartMsg+1# to #arguments.currentStartMsg + conf.messagesPerPage+1#">
				<cfreturn getMessageQuery(arguments.currentStartMsg+1, arguments.currentStartMsg + conf.messagesPerPage+1, true)>
			</cfif>
		</cfif>
	</cfif>
</cffunction>

<!--- Get message containing query, the query returned is in the following format: filename,num,name,email,website,date,ip,message,id --->
<cffunction name="getMessageQuery" access="private" returntype="query" output="true" displayname="Get message containing query" hint="The query returned is in the following format: filename,num,name,email,website,date,ip,message,id">
	<cfargument name="fromNo" required="true" type="numeric" displayname="From this message number" hint="">
	<cfargument name="toNo" required="true" type="numeric" displayname="To this message number" hint="">
	<cfargument name="revOrder" required="true" type="boolean" displayname="in reverse order?" hint="If true the result is sorted in reverse order, false means regular order">
	<cfif not isNaturalNumber(arguments.fromNo) or not isPosInteger(arguments.toNo)>
		<cftrace inline="false" text="There was an internal error in the function that gathers guest book entries - arguments passed are not positive integers. Please investingate, function name getMessageQuery.">
		<cfreturn queryNew("filename,name,email,website,date,ip,message,id")>
	</cfif>
	<cfif arguments.fromNo gt arguments.toNo>
		<cftrace inline="false" text="An error has occured while retreiving data from memory, the from message number is greater then the to message number">
		<cfreturn queryNew("filename,name,email,website,date,ip,message,id")>
	<cfelseif not isQuery(guestBookData)>
		<cftrace inline="false" text="An error has occured while retreiving data from memory, cached data is not in the format of a query">
		<cfreturn queryNew("filename,name,email,website,date,ip,message,id")>
	<cfelse>
		<cftry>
			<!--- <cftrace inline="false" text="Getting message query from #arguments.fromNo# to #arguments.toNo# order #arguments.revOrder#"> --->
			<!--- The from number is included in the result but not the to number --->
			<cfquery name="mq" dbtype="query"><!--- cfqueryparam was causing strange behaviour to occur, like missing order by --->
				SELECT filename,name,email,website,[date],ip,message,id
				FROM guestBookData
				WHERE num >= #arguments.fromNo#
				AND num < #arguments.toNo#
				ORDER BY num <cfif arguments.revOrder>DESC</cfif>
			</cfquery>
			<cfcatch type="Database">
				<cftrace inline="false" text="[1] There was a problem accessing the guest book cached data. Please refresh the application scope and try again.">
				<cfthrow message="There was a problem accessing the guest book cached data. Please refresh the application scope and try again.">
			</cfcatch>
			<cfcatch type="any">
				<!--- I got a strange error, java.lang.ClassCastException when I was inserting the very
				2st GB message. Something got corrupted. I could not fix it or understand why it is doing what it
				was. So, I re-initialize the whole thing if java.lang.ClassCastException happens and I have just
				one message in the guest book. --->
				<cftry>
					<cfif totalMsgNumber eq 1>
						<cfset guestBookData = queryNew("filename,num,name,email,website,date,ip,message,id")>
						<cfset resV = intiCacheData()>
						<cfif not resV>
							<cfthrow message="Failed to read all guest book XML data files. It is possible that one of the files doesn't exist or is corrupted. You can check by hand or just restore from backup.">
						</cfif>
						<cfquery name="mq" dbtype="query"><!--- cfqueryparam was causing strange behaviour to occur, like missing order by --->
							SELECT filename,name,email,website,[date],ip,message,id
							FROM guestBookData
							WHERE num >= #arguments.fromNo#
							AND num < #arguments.toNo#
							ORDER BY num <cfif arguments.revOrder>DESC</cfif>
						</cfquery>
					<cfelse>
						<cfquery name="mq" dbtype="query">
							SELECT filename,name,email,website,[date],ip,message,id
							FROM guestBookData
							ORDER BY num <cfif arguments.revOrder>DESC</cfif>
						</cfquery>
					</cfif>
					<cfcatch type="Database">
						<cftrace inline="false" text="[2] There was a problem accessing the guest book cached data. Please refresh the application scope and try again.">
						<cfthrow message="There was a problem accessing the guest book cached data. Please refresh the application scope and try again.">
					</cfcatch>
				</cftry>
			</cfcatch>
		</cftry>
		<cfreturn mq>
	</cfif>
</cffunction>

<!--- Get a single message using ID and data file name, used by edit and delete operations --->
<cffunction name="getMessageByIDAndFileName" access="public" returntype="struct" output="false" roles="admin" displayname="Get a single message using ID and data file name" hint="Used by edit and delete operations">
	<cfargument name="recordID" required="true" type="string" displayname="record id to be editd" hint="">
	<cfargument name="fn" required="true" type="string" displayname="file name where record resides" hint="">
	<cftry>
		<cfquery name="getByID" dbtype="query"><!--- cfqueryparam was causing strange behaviour to occur, like missing order by --->
			SELECT filename,name,email,website,[date],ip,message,id
			FROM guestBookData
			WHERE filename = '#arguments.fn#'
			AND id = '#arguments.recordID#'
		</cfquery>
		<cfcatch type="Database">
			<cftrace inline="false" text="Unable to get guest book entry with id #arguments.recordID# and in data file #arguments.fn# due to cache query database error.">
			<cfreturn listToStruct("filename,name,email,website,date,ip,message,id")>
		</cfcatch>
	</cftry>
	<!--- exchange the <br> with page breaks: --->
	<cfset querysetCell(getByID, "message", removeBR(getByID.message),1)>
	<cfif getByID.recordcount eq 1>
		<cfreturn queryToStruct(getByID)>
	<cfelse>
		<cftrace inline="false" text="Unable to get gust book entry with id #arguments.recordID# and in data file #arguments.fn# due to record not being found in the internal cache query.">
		<cfreturn listToStruct("filename,name,email,website,date,ip,message,id")>
	</cfif>
</cffunction>

<!--- *** message management *** --->

<!--- This function returns structure that makes empty message add form --->
<cffunction name="emptyAddForm" access="public" returntype="struct" output="false" displayname="This function returns structure that makes empty message add form" hint="">
	<cfargument name="dataStr" required="false" type="struct" displayname="optional data containing struct" hint="The form gets pre-populated with this data, if its provided">
	<cfset var ret = structNew()>
	<cfset ret.name = "">
	<cfset ret.email = "">
	<cfset ret.website = "">
	<cfset ret.message = "">
	<cfset ret.testPicUser = "">
	<cfif isDefined("arguments.dataStr")>
		<cfset res = validateMessage(arguments.dataStr,application.setup.FieldSize())>
		<cfif res.success>
			<cfset ret.name = arguments.dataStr.name>
			<cfset ret.email = arguments.dataStr.email>
			<cfset ret.website = arguments.dataStr.website>
			<cfset ret.message = arguments.dataStr.message>
		</cfif>
	</cfif>
	<cfreturn ret>
</cffunction>

<!--- Validate user guest book entry form or edit form (Very simple validation, nothing fancy here) --->
<cffunction name="validateMessage" access="public" returntype="struct" output="false" displayname="Validate user guest book entry form or edit form" hint="Very simple validation, nothing fancy here">
	<cfargument name="fs" required="true" type="struct" displayname="user form structure" hint="">
	<cfargument name="fieledSizes" required="true" type="struct" displayname="form maximum field sizes" hint="">
	<cfset var bannedWords = "">
	<cfset var ret = structNew()>
	<cfset var userTestPicAnswer = "">
	<cfset ret.success = true><!--- true if form is valid, false otherwise --->
	<cfif not isDefined("arguments.fs.name") or not len(arguments.fs.name) or len(arguments.fs.name) gt arguments.fieledSizes.userNameSize>
		<cfset ret.name = "Please enter your name.">
		<cfset ret.success = false>
	<cfelse>
		<cfset ret.name = "">
	</cfif>
	<cfif not isDefined("arguments.fs.email") or len(arguments.fs.email) gt arguments.fieledSizes.userEmailSize>
		<cfset ret.email = "Email field not found or lenght is invalid, please correct.">
		<cfset ret.success = false>
	<cfelseif isDefined("arguments.fs.email") and len(emailValidation(arguments.fs.email))>
		<cfset ret.email = "The e-mail address you provided is not valid">
		<cfset ret.success = false>
	<cfelse>
		<cfset ret.email = "">
	</cfif>
	<cfif not isDefined("arguments.fs.website") or len(arguments.fs.website) gt arguments.fieledSizes.userWebsiteSize>
		<cfset ret.website = "Web site field not found or lenght is invalid, please correct.">
		<cfset ret.success = false>
	<cfelseif isDefined("arguments.fs.website") and len(arguments.fs.website) and not isValidURL(arguments.fs.website)>
		<cfset ret.website = "The web site address you provided is invalid, please correct.">
		<cfset ret.success = false>
	<cfelse>
		<cfset ret.website = "">
	</cfif>
	<cfif not isDefined("arguments.fs.date") or not isDate(arguments.fs.date)>
		<cfset ret.date = "Date field not found or date is not a valid date, please correct.">
		<cfset ret.success = false>
	<cfelse>
		<cfset ret.date = "">
	</cfif>
	<!--- We use this extra if to take avoid using costly bannedWordsCheck function twice --->
	<cfif isDefined("arguments.fs.message") and len(arguments.fs.message) lte arguments.fieledSizes.userMessageSize and len(arguments.fs.message)>
		<cfset bannedWords = bannedWordsCheck(arguments.fs.message,arguments.fieledSizes)>
	</cfif>
	<cfif not isDefined("arguments.fs.message") or len(arguments.fs.message) gt arguments.fieledSizes.userMessageSize>
		<cfset ret.message = "Your message has a size limit of #arguments.fieledSizes.userMessageSize# please shorten your guest book entry">
		<cfset ret.success = false>
	<cfelseif not len(arguments.fs.message)>
		<cfset ret.message = "Please enter your message for the guest book owner.">
		<cfset ret.success = false>
	<cfelseif len(bannedWords)>
		<cfset ret.message = "Banned word found: ""#bannedWords#""">
		<cfset ret.success = false>
	<cfelseif superLongWordsDet(arguments.fs.message)>
		<cfset ret.message = "A word in your guest book entry exceeds 50 character limit.">
		<cfset ret.success = false>
	<cfelse>
		<cfset ret.message = "">
	</cfif>
	<cfif isDefined("arguments.fs.ip")>
		<cfif len(arguments.fs.ip) gt 15>
			<cfset ret.ip = "An IP address has a maximum of 15 characters.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.ip = "">
		</cfif>
	</cfif>
	<!--- Case for test image - need to check only if it is add form (i.e. answer is present) --->
	<cfif not isDefined("arguments.fs.testPicUser") and isDefined("arguments.fs.testPicAnswer")>
		<cfset ret.testPicUser = "Incorrect text provided, please try again.">
		<cfset ret.success = false>
	<cfelseif isDefined("arguments.fs.testPicUser") and isDefined("arguments.fs.testPicAnswer")>
		<cfwddx action="wddx2cfml" input="#URLDecode(arguments.fs.testPicAnswer)#" output="userTestPicAnswer">
		<cfif ucase(arguments.fs.testPicUser) neq ucase(decrypt(userTestPicAnswer,this.encryptionString))>
			<cfset ret.testPicUser = "Incorrect text provided, please try again.">
			<cfset ret.success = false>
		<cfelse>
			<cfset ret.testPicUser = "">
		</cfif>
	<cfelse>
		<cfset ret.testPicUser = "">
	</cfif>
	<cftrace inline="false" text="Results of message validation: ""#ret.success#"" if true then OK, false means errors occured">
	<cfreturn ret>
</cffunction>

<!--- This function checks whatever guest book owner wants to be notified of new messages, sends an e-mail if yes.
The e-mail that is sent to the owner contains the information that is entered and shown in the guest book. --->
<cffunction name="newMessageNotification" access="private" returntype="void" output="false" displayname="This function checks whatever guest book owner wants to be notified of new messages, sends an e-mail if yes" hint="The e-mail that is sent to the owner contains the information that is entered and shown in the guest book">
	<cfargument name="fs" required="true" type="struct" displayname="data containing structure" hint="Data is assumed to be valid">
	<cfset var temp = application.setup.FieldSize()>
	<cfset var ownerEmail = temp.sendEmailOnEntry>
	<cfset var notEmail = "<h2>New guest book entry</h2>">
	<cfif len(ownerEmail) and not len(emailValidation(ownerEmail))>
		<cfset notEmail = notEmail & "<b>From:</b> " & arguments.fs.name & "<br>">
		<cfset notEmail = notEmail & "<b>Email:</b> " & arguments.fs.email & "<br>">
		<cfset notEmail = notEmail & "<b>Web site:</b> " & arguments.fs.website & "<br>">
		<cfset notEmail = notEmail & "<b>Date:</b> " & dateformat(arguments.fs.date,"yyyy-mm-dd") & "<br>">
		<cfset notEmail = notEmail & "<b>Message:</b> " & "<br><br>">
		<cfset notEmail = notEmail & arguments.fs.message & "<br>">
		<cftry>
			<cfmail to="#ownerEmail#" from="#ownerEmail#" subject="New guest book entry" type="HTML">#notEmail#</cfmail>
			<cfcatch type="Any">
				<cftrace inline="false" text="Unknown error prevented the guest book from notifying the guest book owner about new guest book entry.">
			</cfcatch>
		</cftry>
	</cfif>
</cffunction>

<!--- Find free data file and return its name, if none of existing files have any free space in them then we create a new file and return its name. --->
<cffunction name="findFreeFile" access="private" returntype="string" output="false" displayname="Find free data file and return its name" hint="If none of existing files have any free space in them then we create a new file and return its name.">
	<cfset var conf = application.setup.FieldSize()><!--- get configuration data --->
	<cfset var lastArrayElement = ArrayLen(entriesPerFile)>
	<cfloop index="t" from="1" to="#lastArrayElement#" step="1">
		<cfif entriesPerFile[t].entries lt conf.messagesPerFile>
			<cfreturn entriesPerFile[t].filename>
		</cfif>
	</cfloop>
	<!--- create XML for the new data file --->
	<cfset newXML = xmlNew()>
	<cfset newXML.xmlroot = XmlElemNew(newXML,"gbdata")>
	<cfset newXML.xmlroot.xmlAttributes.recordNumber = "0">
	<cfset XMLstring = toString(newXML)>
	<!--- need to create a new XML data file, this is the default format --->
	<cfset newFileName = "data" & lastArrayElement + 1 & ".xml">
	<cfset dataFileLocation = ExpandPath(".\") & dataDirectory & "\" & newFileName>
	<cfif fileexists(dataFileLocation)><!--- don't want to overwrite some file by accident, should never happen --->
		<cftrace inline="false" text="Error, planned new data file, #newFileName# exists! Please remove offending file.">
		<cfthrow message="Error, planned new data file, #newFileName# exists! Please remove offending file.">
	</cfif>
	<cftry>
		<cffile action="WRITE" file="#dataFileLocation#" output="#XMLstring#" addnewline="Yes">
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to write blank XML data storage file.">
			<cfthrow message="Unable to write blank XML data file, #newFileName#, into #dataFileLocation# check drive">
		</cfcatch>
	</cftry>
	<!--- add this file name to the internal cached array --->
	<cfset ins = structNew()>
	<cfset ins.filename = newFileName>
	<cfset ins.entries = 0>
	<cfset arrayAppend(entriesPerFile,ins)>
	<!--- add this file name to the configuration file --->
	<cfset application.setup.addNewDataFileName(newFileName)>
	<cftrace inline="false" text="Created a new data file, #newFileName#">
	<cfreturn newFileName>
</cffunction>

<!--- Update internal array EntriesPerFile entries for the file name specified by the number specified, returns the new number of entries. --->
<cffunction name="updateEntriesPerFileArray" access="private" returntype="numeric" output="false" displayname="Update internal array EntriesPerFile entries for the file name specified by the number specified" hint="Returns the new number of entries.">
	<cfargument name="sfilename" required="true" type="string" displayname="file name number of entries to update" hint="">
	<cfargument name="adj" required="true" type="numeric" displayname="update by this number" hint="">
	<cfloop index="m" from="1" to="#arrayLen(entriesPerFile)#" step="1">
		<cfif entriesPerFile[m].filename eq arguments.sfilename>
			<cfset entriesPerFile[m].entries = entriesPerFile[m].entries + arguments.adj>
			<cfreturn entriesPerFile[m].entries>
		</cfif>
	</cfloop>
	<cftrace inline="false" text="There was a problem while updating entries per file internal array - object was not found that was to be updated.">
	<cfreturn 0>
</cffunction>

<!--- This function edits an entry in the internal data cached query. There is no need to re-read the files, just edit data in the cached data query by 'hand' --->
<cffunction name="editInCacheQuery" access="private" returntype="void" output="false" displayname="This function edits an entry in the internal data cached query" hint="There is no need to re-read the files, just edit data in the cached data query by 'hand'">
	<cfargument name="fs" required="true" type="struct" displayname="data containing structure" hint="Data is assumed to be valid">
	<cfargument name="uuid" required="true" type="string" displayname="The ID of the entry, generated in the add function" hint="">
	<cfset var rowNo = 1>
	<!--- need to get row number, so we can edit the right row in the query --->
	<cftry>
		<cfquery name="getRowNo" dbtype="query"><!--- cfqueryparam was causing strange behaviour to occur, like missing order by --->
			SELECT num
			FROM guestBookData
			WHERE id = '#arguments.uuid#'
		</cfquery>
		<cfif getRowNo.recordCount eq 1 and isNumeric(getRowNo.num)>
			<cfset rowNo = getRowNo.num>
		<cfelse>
			<cftrace inline="false" text="Unable to get the row in the data cache query that contains the guest book entry that we wanted to edit due unability to find record with id: #arguments.uuid#. This will cause problems with display, but when cache is reloaded it will be fine again. Please check the query.">
			<cfset QueryAddRow(guestBookData)><!--- just in case it is empty query --->
		</cfif>
		<cfcatch type="Database">
			<cftrace inline="false" text="Unable to get the row in the data cache query that contains the guest book entry that we wanted to edit due to query problem. This will cause problems with display, but when cache is reloaded it will be fine again. Please check the query.">
			<cfset QueryAddRow(guestBookData)><!--- just in case it is empty query --->
		</cfcatch>
	</cftry>
	<!--- we need to escape data here as well, since we don't want it executed when it is displayed from cache (we are getting raw data) --->
	<cfset QuerySetCell(guestBookData, "name", escapeHtmlTags(arguments.fs.name), rowNo)>
	<cfset QuerySetCell(guestBookData, "email", escapeHtmlTags(arguments.fs.email), rowNo)>
	<cfset QuerySetCell(guestBookData, "website", escapeHtmlTags(makeValidURL(arguments.fs.website)), rowNo)>
	<cfset QuerySetCell(guestBookData, "date", myDateFormat(arguments.fs.date,"yyyy-mm-dd"), rowNo)>
	<cfset QuerySetCell(guestBookData, "ip", escapeHtmlTags(arguments.fs.ip), rowNo)>
	<cfset QuerySetCell(guestBookData, "message", createPageBreaks(escapeHtmlTags(arguments.fs.message)), rowNo)>
</cffunction>

<!--- This function delete entry from the internal data cached query, there is no need to re-read the files, just delete data in the cached data query by 'hand' --->
<cffunction name="deleteInCacheQuery" access="private" returntype="boolean" output="false" displayname="This function delete entry from the internal data cached query" hint="There is no need to re-read the files, just delete data in the cached data query by 'hand'">
	<cfargument name="uuid" required="true" type="string" displayname="The ID of the entry, generated in the add function" hint="">
	<cfset var nq = queryNew("name,email,website,date,ip,message,filename,id,num")>
	<cfset var counter = 0>
	<cfloop index="rowNo" from="1" to="#guestBookData.recordcount#" step="1">
		<cfif guestBookData.id[rowNo] neq arguments.uuid>
			<cfset counter = counter + 1>
			<cfset QueryAddRow(nq)>
			<cfset QuerySetCell(nq, "name", guestBookData.name[rowNo])>
			<cfset QuerySetCell(nq, "email", guestBookData.email[rowNo])>
			<cfset QuerySetCell(nq, "website", guestBookData.website[rowNo])>
			<cfset QuerySetCell(nq, "date", guestBookData.date[rowNo])>
			<cfset QuerySetCell(nq, "ip", guestBookData.ip[rowNo])>
			<cfset QuerySetCell(nq, "message", guestBookData.message[rowNo])>
			<cfset QuerySetCell(nq, "id", guestBookData.id[rowNo])>
			<cfset QuerySetCell(nq, "filename", guestBookData.filename[rowNo])>
			<cfset QuerySetCell(nq, "num", counter)><!--- re-numerate guest book data --->
		</cfif>
	</cfloop>
	<cfset guestBookData = nq>
	<!--- The code underneath doesn't work, besides we need to re-number everything for the display queries to work --->
	<!--- <cftry>
		<cfquery name="deleteFromDataQuery" dbtype="query">
			DELETE FROM guestBookData
			WHERE id = '#arguments.uuid#'
		</cfquery>
		<cfcatch type="any">
			<cftrace inline="false" text="Unable to delete guest book entry from the internal data cache query. This will cause problems with display, but when cache is reloaded it will be fine again. Please check the query.">
			<cfreturn false>
		</cfcatch>
	</cftry> --->
	<cfreturn true>
</cffunction>

<!--- This function inserts new addition into internal cached query, there is no need to re-read the files, just add data to the cached data query by 'hand' --->
<cffunction name="insertIntoCacheQuery" access="private" returntype="void" output="false" displayname="This function inserts new addition into internal cached query" hint="There is no need to re-read the files, just add data to the cached data query by 'hand'">
	<cfargument name="fs" required="true" type="struct" displayname="data containing structure" hint="Data is assumed to be valid">
	<cfargument name="fn" required="true" type="string" displayname="XML data file name where this guest book entry is stored" hint="">
	<cfargument name="uuid" required="true" type="string" displayname="The ID of the entry, generated in the add function" hint="">
	<cfset var newNum = 1>
	<!--- get the new value of num --->
	<cftry>
		<cfquery name="getNum" dbtype="query">
			SELECT max(num) as maxNum
			FROM guestBookData
		</cfquery>
		<cfif isNumeric(getNum.maxNum)>
			<cfset newNum = getNum.maxNum + 1>
		<cfelse>
			<cftrace inline="false" text="Entring first Guest Book message!">
			<cfset newNum = 1><!--- First GB entry! --->
		</cfif>
		<cfcatch type="Database">
			<cftrace inline="false" text="Unable to get the maximum element in the guest book. This will cause problems with display, but when cache is reloaded it will be fine again. Please check the query.">
			<cfset newNum = 1>
		</cfcatch>
	</cftry>
	<!--- query fields: filename,num,name,email,website,date,ip,message,id --->
	<cfset QueryAddRow(guestBookData)>
	<cfset QuerySetCell(guestBookData, "filename", arguments.fn)>
	<!--- we need to escape data here as well, since we don't want it executed when it is displayed from cache (we are getting raw data) --->
	<cfset QuerySetCell(guestBookData, "num", newNum)>
	<cfset QuerySetCell(guestBookData, "name", escapeHtmlTags(arguments.fs.name))>
	<cfset QuerySetCell(guestBookData, "email", escapeHtmlTags(arguments.fs.email))>
	<cfset QuerySetCell(guestBookData, "website", escapeHtmlTags(makeValidURL(arguments.fs.website)))>
	<cfset QuerySetCell(guestBookData, "date", myDateFormat(arguments.fs.date,"yyyy-mm-dd"))>
	<cfset QuerySetCell(guestBookData, "ip", escapeHtmlTags(arguments.fs.ip))>
	<cfset QuerySetCell(guestBookData, "message", createPageBreaks(escapeHtmlTags(arguments.fs.message)))>
	<cfset QuerySetCell(guestBookData, "id", arguments.uuid)>
</cffunction>

<!--- This function adds new guest book entry to the guest book --->
<cffunction name="addMessage" access="public" returntype="boolean" output="false" displayname="This function adds new guest book entry to the guest book" hint="">
	<cfargument name="fs" required="true" type="struct" displayname="data containing structure" hint="Data is assumed to be valid">
	<cfset var dataFile = findFreeFile()>
	<cfset var dataFileLocation = ExpandPath(".\") & dataDirectory & "\" & dataFile>
	<!--- read intended storage location data file --->
	<cftry>
		<cffile action="READ" file="#dataFileLocation#" variable="rawXML">
		<cfset parsedXML = xmlParse(rawXML)>
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to read XML data file #dataFile# or problem with XML parsing.">
			<cfthrow message="Failed to read XML data file #dataFile# or problem with XML parsing.">
		</cfcatch>
	</cftry>
	<cftry>
		<cfset lastElement = arrayLen(parsedXML.xmlroot.xmlchildren)>
		<cfcatch type="Expression">
			<cfset lastElement = 0>
		</cfcatch>
	</cftry>
	<!--- add our data to it --->
	<cfset lastElement = lastElement + 1><!--- new last element --->
	<cfset parsedXML.xmlroot.xmlAttributes.recordNumber = parsedXML.xmlroot.xmlAttributes.recordNumber + 1>
	<cfset newEleGbEntry = XmlElemNew(parsedXML,"gbentry")>
	<cfset newEleGbEntry.xmlAttributes.ip = escapeHtmlTags(arguments.fs.ip)>
	<cfset newEleGbEntry.xmlAttributes.date = myDateFormat(arguments.fs.date)>
	<cfset newEleGbEntry.xmlAttributes.id = createUUID()>
	<cfset arrayAppend(parsedXML.xmlroot.xmlchildren, newEleGbEntry)>
	<cfset newEle = XmlElemNew(parsedXML,"email")>
	<cfset newEle.xmlText = escapeHtmlTags(arguments.fs.email)>
	<cfset arrayAppend(parsedXML.xmlroot.xmlchildren[lastElement].xmlchildren, newEle)>
	<cfset newEle = XmlElemNew(parsedXML,"name")>
	<cfset newEle.xmlText = escapeHtmlTags(arguments.fs.name)>
	<cfset arrayAppend(parsedXML.xmlroot.xmlchildren[lastElement].xmlchildren, newEle)>
	<cfset newEle = XmlElemNew(parsedXML,"website")>
	<cfset newEle.xmlText = escapeHtmlTags(makeValidURL(arguments.fs.website))>
	<cfset arrayAppend(parsedXML.xmlroot.xmlchildren[lastElement].xmlchildren, newEle)>
	<cfset newEle = XmlElemNew(parsedXML,"message")>
	<cfset newEle.xmlText = createPageBreaks(escapeHtmlTags(arguments.fs.message))>
	<cfset arrayAppend(parsedXML.xmlroot.xmlchildren[lastElement].xmlchildren, newEle)>
	<cfset newXML = toString(parsedXML)>
	<!--- write new data file --->
	<cftry>
		<cffile action="WRITE" file="#dataFileLocation#" output="#newXML#" addnewline="Yes">
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to write XML data file #dataFile#.">
			<cfthrow message="Failed to write XML data file #dataFile#.">
		</cfcatch>
	</cftry>
	<!--- update message totals --->
	<cfset totalMsgNumber = totalMsgNumber + 1>
	<cfset updateEntriesPerFileArray(dataFile,1)>
	<!--- update caching query --->
	<cfset insertIntoCacheQuery(arguments.fs,dataFile,newEleGbEntry.xmlAttributes.id)>
	<!--- do we need to send an e-mail to the guest book owner? --->
	<cfset newMessageNotification(arguments.fs)>
	<cftrace inline="false" text="New guest book entry was added to the XML data storage file, #dataFileLocation#.">
	<cfreturn true>
</cffunction>

<!--- This function edits an existing guest book entry, only for administrators --->
<cffunction name="editMessage" access="public" returntype="boolean" output="false" roles="admin" displayname="This function edits an existing guest book entry, only for administrators" hint="">
	<cfargument name="fs" required="true" type="struct" displayname="data containing structure" hint="Data is assumed to be valid">
	<cfargument name="recordID" required="true" type="string" displayname="record id to be editd" hint="">
	<cfargument name="fn" required="true" type="string" displayname="file name where record resides" hint="">
	<cfset var dataFile = arguments.fn>
	<cfset var dataFileLocation = ExpandPath(".\") & dataDirectory & "\" & dataFile>
	<!--- read intended storage location data file --->
	<cftry>
		<cffile action="READ" file="#dataFileLocation#" variable="rawXML">
		<cfset parsedXML = xmlParse(rawXML)>
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to read XML data file #dataFile# or problem with XML parsing.">
			<cfthrow message="Failed to read XML data file #dataFile# or problem with XML parsing.">
		</cfcatch>
	</cftry>
	<!--- find our element in the data file --->
	<cftry>
		<cfloop index="t" from="1" to="#arrayLen(parsedXML.xmlroot.xmlchildren)#" step="1">
			<cfif parsedXML.xmlroot.xmlchildren[t].xmlAttributes.id eq arguments.recordID>
				<cfset elementToEdit = t>
			</cfif>
		</cfloop>
		<cfcatch type="Expression">
			<cftrace inline="false" text="Unable to edit this message, looked for id #arguments.recordID# in file #dataFileLocation# but didn't find it?">
			<cfreturn false>
		</cfcatch>
	</cftry>
	<cfif not isDefined("elementToEdit")>
		<cftrace inline="false" text="Unable to edit this message, looked for id #arguments.recordID# in file #dataFileLocation# but didn't find it?">
		<cfreturn false>
	</cfif>
	<!--- edit our data --->
	<cfset parsedXML.xmlroot.xmlchildren[elementToEdit].xmlAttributes.ip = escapeHtmlTags(arguments.fs.ip)>
	<cfset parsedXML.xmlroot.xmlchildren[elementToEdit].xmlAttributes.date = MyDateFormat(arguments.fs.date)>
	<cfset parsedXML.xmlroot.xmlchildren[elementToEdit].email.XmlText = escapeHtmlTags(arguments.fs.email)>
	<cfset parsedXML.xmlroot.xmlchildren[elementToEdit].name.XmlText = escapeHtmlTags(arguments.fs.name)>
	<cfset parsedXML.xmlroot.xmlchildren[elementToEdit].website.XmlText = escapeHtmlTags(makeValidURL(arguments.fs.website))>
	<cfset parsedXML.xmlroot.xmlchildren[elementToEdit].message.XmlText = createPageBreaks(escapeHtmlTags(arguments.fs.message))>
	<cfset editXML = toString(parsedXML)>
	<!--- write edited data file --->
	<cftry>
		<cffile action="WRITE" file="#dataFileLocation#" output="#editXML#" addnewline="Yes">
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to write XML data file #dataFile#.">
			<cfthrow message="Failed to read XML data file #dataFile#.">
		</cfcatch>
	</cftry>
	<!--- update caching query --->
	<cfset editInCacheQuery(arguments.fs,arguments.recordID)>
	<cftrace inline="false" text="Edit of the message with ID #arguments.recordID# in XML data file #arguments.fn# was successful.">
	<cfreturn true>
</cffunction>

<!--- This function deletes an exisiting guest book entry from the guest book, only for administrators --->
<cffunction name="deleteMessage" access="public" returntype="boolean" output="false" roles="admin" displayname="This function deletes an exisiting guest book entry from the guest book, only for administrators" hint="">
	<cfargument name="recordID" required="true" type="string" displayname="record id to be editd" hint="">
	<cfargument name="fn" required="true" type="string" displayname="file name where record resides" hint="">
	<cfset var dataFile = arguments.fn>
	<cfset var dataFileLocation = ExpandPath(".\") & dataDirectory & "\" & dataFile>
	<!--- read storage location data file --->
	<cftry>
		<cffile action="READ" file="#dataFileLocation#" variable="rawXML">
		<cfset parsedXML = xmlParse(rawXML)>
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to read XML data file #dataFile# or problem with XML parsing.">
			<cfthrow message="Failed to read XML data file #dataFile# or problem with XML parsing.">
		</cfcatch>
	</cftry>
	<!--- find our element in the data file --->
	<cftry>
		<cfloop index="t" from="1" to="#arrayLen(parsedXML.xmlroot.xmlchildren)#" step="1">
			<cfif parsedXML.xmlroot.xmlchildren[t].xmlAttributes.id eq arguments.recordID>
				<cfset elementToDel = t>
				<cfbreak>
				<!--- NOTE: Cannot DELETE HERE! -> Remember that arrayDeleteAt re-orders the indexes and we are in a loop! --->
			</cfif>
		</cfloop>
		<cfcatch type="Expression">
			<cftrace inline="false" text="Unable to delete this message, looked for id #arguments.recordID# in file #dataFileLocation# but didn't find it?">
			<cfreturn false>
		</cfcatch>
	</cftry>
	<!--- delete element from this data file --->
	<cfset parsedXML.xmlroot.xmlAttributes.recordNumber = parsedXML.xmlroot.xmlAttributes.recordNumber - 1>
	<cftry>
		<cfset ArrayDeleteAt(parsedXML.xmlroot.xmlchildren, elementToDel)>
		<cfcatch type="Expression">
			<cftrace inline="false" text="Could not delete guest book with ID: #arguments.recordID# in file #dataFile# due to array removal problem - are you trying to remove entry that doesn't exist?">
			<cfreturn false>
		</cfcatch>
	</cftry>
	<cfset newXML = toString(parsedXML)>
	<!--- write new data file --->
	<cftry>
		<cffile action="WRITE" file="#dataFileLocation#" output="#newXML#" addnewline="Yes">
		<cfcatch type="Any">
			<cftrace inline="false" text="Failed to write XML data file #dataFile#.">
			<cfthrow message="Failed to write XML data file #dataFile#.">
		</cfcatch>
	</cftry>
	<!--- update message totals --->
	<cfset totalMsgNumber = totalMsgNumber - 1>
	<cfset updateEntriesPerFileArray(dataFile,-1)>
	<!--- update caching query --->
	<cftrace inline="false" text="Delete of guest book entry in the data file #arguments.fn# with id of #arguments.recordID# was successful.">
	<cfreturn deleteInCacheQuery(arguments.recordID)>
</cffunction>

<!--- *** page control *** --->

<!--- This function displays previous page button/link if this is the current last message? --->
<cffunction name="isPreviousPage" access="public" returntype="boolean" output="false" displayname="This function displays previous page button/link if this is the current last message?" hint="">
	<cfargument name="currentStartMsg" required="true" type="string" displayname="define 0 as nothing - no value, this is for nat having to use ifs in the calling page for variable existance checking" hint="Type is 'string' to prevent hackers from seeing error messages">
	<cfset var conf = application.setup.FieldSize()><!--- get configuration data --->
	<cfset var ret = true>
	<cfset var cm = arguments.currentStartMsg>
	<cfif not isNumeric(cm) or cm lt -1>
		<cfset cm = 1><!--- in case of non-numeric input assume it is 1 --->
	</cfif>
	<cfif cm eq -1>
		<cfset ret = false>
	<cfelse>
		<cfif conf.ordering eq 1><!--- older messages 1st --->
			<cfif cm gt 1>
				<cfset ret = true>
			<cfelse>
				<cfset ret = false>
			</cfif>
		<cfelse>
			<cfif cm + conf.messagesPerPage lt totalMsgNumber>
				<cfset ret = true>
			<cfelse>
				<cfset ret = false>
			</cfif>
		</cfif>
	</cfif>
	<cftrace inline="false" text="Ordering: #conf.ordering# Is there a previous page? Answer: #ret#">
	<cfreturn ret>
</cffunction>

<!--- This function displays next page button/link if this is the current last message? --->
<cffunction name="isNextPage" access="public" returntype="boolean" output="false" displayname="This function displays next page button/link if this is the current last message?" hint="">
	<cfargument name="currentStartMsg" required="true" type="string" displayname="define 0 as nothing - no value, this is for nat having to use ifs in the calling page for variable existance checking" hint="Type is 'string' to prevent hackers from seeing error messages">
	<cfset var conf = application.setup.FieldSize()><!--- get configuration data --->
	<cfset var ret = true>
	<cfset var cm = arguments.currentStartMsg>
	<cfif not isNumeric(cm) or cm lt -1>
		<cfset cm = 1><!--- in case of non-numeric input assume it is 1 --->
	</cfif>
	<cfif cm eq -1>
		<cfif totalMsgNumber gt conf.messagesPerPage>
			<cfset ret = true>
		<cfelse>
			<cfset ret = false>
		</cfif>
	<cfelse>
		<cfif conf.ordering eq 1><!--- older messages 1st --->
			<cfif cm + conf.messagesPerPage lte totalMsgNumber>
				<cfset ret = true>
			<cfelse>
				<cfset ret = false>
			</cfif>
		<cfelse>
			<cfif cm gt 0>
				<cfset ret = true>
			<cfelse>
				<cfset ret = false>
			</cfif>
		</cfif>
	</cfif>
	<cftrace inline="false" text="Ordering: #conf.ordering# Is there a next page? Answer: #ret#">
	<cfreturn ret>
</cffunction>

<!--- This function used to start guest book number functions when error computation occurs --->
<cffunction name="pageErrorReturn" access="private" returntype="numeric" output="false" displayname="This function used to start guest book number functions when error computation occurs" hint="">
	<cfargument name="currentStartMsg" required="true" type="any" displayname="the value that caused computation problems" hint="">
	<cfargument name="errMsg" required="true" type="string" displayname="error message to return as trace" hint="">
	<cftrace inline="false" text="#arguments.errMsg#">
	<cfif not isNumeric(arguments.currentStartMsg) or arguments.currentStartMsg lt -1>
		<cfreturn 1><!--- in case of non-numeric input assume it is 1 --->
	<cfelse>
		<cfreturn arguments.currentStartMsg>
	</cfif>
</cffunction>

<!--- This function gets the number of the next page to display, returns current next page number if there is no next page, should never happen --->
<cffunction name="getNextPage" access="public" returntype="numeric" output="false" displayname="This function gets the number of the next page to display" hint="Returns current next page number if there is no next page, should never happen">
	<cfargument name="currentStartMsg" required="true" type="any" displayname="define 0 as nothing - no value, this is for nat having to use ifs in the calling page for variable existance checking" hint="The type is set to any since end users may pass anything to it">
	<cfset var conf = application.setup.FieldSize()><!--- get configuration data --->
	<cfset var ret = 0>
	<!--- handle pre-computation problems: --->
	<cfif not isNumeric(arguments.currentStartMsg) or arguments.currentStartMsg lt -1>
		<cfreturn pageErrorReturn(arguments.currentStartMsg,"The value passed as the current start guest book entry is invalid, it is #arguments.currentStartMsg#")>
	</cfif>
	<!--- compute value to return --->
	<cfif arguments.currentStartMsg eq -1>
		<cfif conf.ordering eq 1>
			<cfset referenceP = 1>
		<cfelse>
			<cfset referenceP = max(1,totalMsgNumber-conf.messagesPerPage)>
		</cfif>
	<cfelse>
		<cfset referenceP = arguments.currentStartMsg>
	</cfif>
	<cfif conf.ordering eq 1><!--- older messages 1st --->
		<cfset ret = referenceP + conf.messagesPerPage>
	<cfelse>
		<cfset ret = max(0,referenceP - conf.messagesPerPage)>
	</cfif>
	<!--- return value and handle problems with computation: --->
	<cfif isNextPage(arguments.currentStartMsg)>
		<cfif isNaturalNumber(ret)>
			<cfreturn ret>
		<cfelse>
			<cfreturn pageErrorReturn(arguments.currentStartMsg,"The system indicates that there is a next page, but when it is computed the value is non-positive integer. Returning valid default values.")>
		</cfif>
	<cfelse><!--- this should not happen --->
		<cfreturn pageErrorReturn(arguments.currentStartMsg,"The function that returns the next page first guest book record number was called through there is no next page. Returning default value.")>
	</cfif>
</cffunction>

<!--- This function gets the number of the previous page to display, returns current previous page number if there is no next page, should never happen --->
<cffunction name="getPreviousPage" access="public" returntype="numeric" output="false" displayname="This function gets the number of the previous page to display" hint="Returns current previous page number if there is no next page, should never happen">
	<cfargument name="currentStartMsg" required="true" type="any" displayname="define 0 as nothing - no value, this is for nat having to use ifs in the calling page for variable existance checking" hint="The type is set to any since end users may pass anything to it">
	<cfset var conf = application.setup.FieldSize()><!--- get configuration data --->
	<!--- handle pre-computation problems: --->
	<cfif not isNumeric(arguments.currentStartMsg) or arguments.currentStartMsg lt -1>
		<cfreturn pageErrorReturn(arguments.currentStartMsg,"The value passed as the current start guest book entry is invalid, it is #arguments.currentStartMsg#")>
	</cfif>
	<!--- compute value to return --->
	<cfif arguments.currentStartMsg eq -1>
		<cfif conf.ordering eq 1><!--- older messages 1st --->
			<cfset referenceP = 1>
		<cfelse>
			<cfset referenceP = max(0,totalMsgNumber-conf.messagesPerPage)>
		</cfif>
	<cfelse>
		<cfset referenceP = arguments.currentStartMsg>
	</cfif>
	<cfif conf.ordering eq 1><!--- older messages 1st --->
		<cfset ret = max(1,referenceP - conf.messagesPerPage)>
	<cfelse>
		<cfif referenceP neq 0>
			<cfset ret = referenceP + conf.messagesPerPage>
		<cfelse>
			<!--- fix a bug: what it is a perfect numeric fit => we would go into a loop! --->
			<cfif totalMsgNumber-1-fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage gt 0>
				<cfset ret = totalMsgNumber-fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage>
			<cfelseif totalMsgNumber-1-fix(totalMsgNumber/conf.messagesPerPage)*conf.messagesPerPage eq 0>
				<cfset ret = 1><!--- returning 0 will get us into endless loop --->
			<cfelse>
				<cfset ret = conf.messagesPerPage>
			</cfif>
		</cfif>
	</cfif>
	<!--- return value and handle problems with computation: --->
	<cfif isPreviousPage(arguments.currentStartMsg)>
		<cfif isPosInteger(ret)>
			<cfreturn ret>
		<cfelse>
			<cfreturn pageErrorReturn(arguments.currentStartMsg,"The system indicates that there is a previous page, but when it is computed the value is non-positive integer. Returning valid default values.")>
		</cfif>
	<cfelse><!--- this should not happen --->
		<cfreturn pageErrorReturn(arguments.currentStartMsg,"The function that returns the previous page first gust book record number was called through there is no previous page. Returning default value.")>
	</cfif>
</cffunction>

</cfcomponent>