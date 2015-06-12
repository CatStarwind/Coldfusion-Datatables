<cfcomponent displayname="DataTables" hint="Handle DataTables Processing" output="no" extends="Functions">
	<!--- 1.10.x --->
	<cffunction name="processCall" access="public" returnformat="json" returntype="struct" output="no" hint="DT 1.10.x">
		<cfargument name="draw" required="yes" type="numeric" hint="Draw counter. This is used by DataTables to ensure that the Ajax returns from server-side processing requests are drawn in sequence by DataTables.">
		<cfargument name="start" required="yes" type="numeric" hint="Paging first record indicator. This is the start point in the current data set (0 index based - i.e. 0 is the first record).">
		<cfargument name="length" required="yes" type="numeric" hint="Number of records that the table can display in the current draw. It is expected that the number of records returned will be equal to this number, unless the server has fewer records to return. Note that this can be -1 to indicate that all records should be returned (although that negates any benefits of server-side processing!)">
		<cfargument name="search" required="yes" type="struct" hint="Value: Global search value. To be applied to all columns which have searchable as true. Regex: true if the global filter should be treated as a regular expression for advanced searching, false otherwise. ">
		<cfargument name="order" required="yes" type="struct" hint="Column: Column to which ordering should be applied. This is an index reference to the columns array of information that is also submitted to the server. Dir: Ordering direction for this column. It will be asc or desc to indicate ascending ordering or descending ordering, respectively.">
		<cfargument name="columns" required="yes" type="struct" hint="Data: Column's data source, as defined by columns.data, Name: Column's name, as defined by columns.name, Serachable, Orderable, Search.Value, Search.Regex">
		<cfargument name="ci" required="yes" type="array" hint="Column Index">
		<cfargument name="view" required="yes" type="string" hint="SQL View">
		<cfargument name="pk" required="yes" type="string"  hint="Primary Key">
		<cfargument name="where" required="yes" type="array" hint="WHERE clause filter">
		<cfargument name="ext" required="no" type="array" hint="Extra column data to be returned inside aData.ext">
		<cfset var i = 0>
		<cfset var x = 0>
		<cfset var k = 0>
		<cfset var c = "">
		<cfset var jqdt = StructNew()>		
		<cfset var row = StructNew()>		
		<cfset jqdt["data"] = ArrayNew(1)>

		<!--- Get --->
		<cfquery name="qryMain" datasource="#application.datasource#">
			DECLARE @gSrch varchar(max) = <cfqueryparam value="%#arguments.search.value#%" cfsqltype="cf_sql_varchar">
			
			SELECT <cfif arguments.length GT 0>TOP(<cfqueryparam value="#arguments.length#" cfsqltype="cf_sql_integer">)</cfif> *
			FROM (
				SELECT ROW_NUMBER() OVER(
					<cfif StructCount(arguments.order)>
						<cfset x = 0>
						<cfloop from="0" to="#StructCount(arguments.order)-1#" index="i">
							<cfset c = arguments.order[i].column>
							<cfif arguments.columns[c].orderable>
								<cfif x++>,<cfelse>ORDER BY</cfif> #arguments.ci[c+1]# #arguments.order[i].dir#
							</cfif>
						</cfloop>
						<cfif !x>ORDER BY #arguments.PK# ASC</cfif>
					</cfif>) AS R<cfif !(arguments.ci.indexOf(arguments.PK)+1)>, #arguments.PK#</cfif>
					, [#ArrayToList(ListToArray(ArrayToList(arguments.ci)), '],[')#]
					<cfif ArrayLen(arguments.ext)>, [#ArrayToList(ListToArray(ArrayToList(arguments.ext)), '],[')#]</cfif>
					
				FROM #arguments.view#				
				<cfif arguments.search.value NEQ "" OR ArrayLen(arguments.where)>
					WHERE
						<cfset x = 0>
						<cfif arguments.search.value NEQ "">
						(
							<cfloop from="1" to="#ArrayLen(arguments.ci)#" index="i">
							<cfif arguments.columns[i-1].searchable AND arguments.ci[i] NEQ ''>
								<cfif x++>OR</cfif> [#arguments.ci[i]#] LIKE @gSrch
							</cfif>					
							</cfloop>
						)
						</cfif>
						
						<cfloop array="#arguments.where#" index="c">
							<cfif x++>AND</cfif>
								<cfif c["val"] NEQ 0>
								#c.col# #c.op# <cfqueryparam value="#c.val#">
								<cfelse>
								#c.col# IS NULL
								</cfif>
						</cfloop>
				</cfif>					
				<cfset x = 0>
				<cfloop collection="#columns#" item="k">
					<cfif columns[k].search.value NEQ ''>
						<cfif (arguments.search.value NEQ "" OR ArrayLen(arguments.where)) OR x++>AND<cfelse>WHERE</cfif>
						(#arguments.ci[k+1]# = <cfqueryparam value="#columns[k].search.value#">)
					</cfif>
				</cfloop>
			) Q
			WHERE R > <cfqueryparam value="#arguments.start#" cfsqltype="cf_sql_integer">
			ORDER BY R
		</cfquery>

		<cfquery name="qryTotal" datasource="#application.datasource#">
			DECLARE @gSrch varchar(max) = <cfqueryparam value="%#arguments.search.value#%" cfsqltype="cf_sql_varchar">
			
			SELECT COUNT(#arguments.PK#) AS TotalFiltered, (SELECT COUNT(#arguments.PK#) AS Total FROM #arguments.view#) AS Total
			FROM #arguments.view#
			<cfif arguments.search.value NEQ "" OR ArrayLen(arguments.where)>
			WHERE
				<cfset x = 0>
				<cfif arguments.search.value NEQ "">
				(
					<cfloop from="1" to="#ArrayLen(arguments.ci)#" index="i">
					<cfif arguments.columns[i-1].searchable AND arguments.ci[i] NEQ ''>
						<cfif x++>OR</cfif> [#arguments.ci[i]#] LIKE @gSrch
					</cfif>					
					</cfloop>
				)
				</cfif>
				
				<cfloop array="#arguments.where#" index="c">
					<cfif x++>AND</cfif>
						<cfif c["val"] NEQ 0>
						#c.col# #c.op# <cfqueryparam value="#c.val#">
						<cfelse>
						#c.col# IS NULL
						</cfif>
				</cfloop>
			</cfif>					
			<cfset x = 0>
			<cfloop collection="#columns#" item="k">
				<cfif columns[k].search.value NEQ ''>
					<cfif (arguments.search.value NEQ "" OR ArrayLen(arguments.where)) OR x++>AND<cfelse>WHERE</cfif>
					(#arguments.ci[k+1]# = <cfqueryparam value="#columns[k].search.value#">)
				</cfif>
			</cfloop>
		</cfquery>

		<!--- Build --->
		<cfset jqdt["draw"] = arguments.draw>
		<cfset jqdt["recordsTotal"] = qryTotal.Total>		
		<cfset jqdt["recordsFiltered"] = qryTotal.TotalFiltered>
		<cfoutput query="qryMain">
			<cfset row = StructNew()>
			<cfloop from="1" to="#ArrayLen(arguments.ci)#" index="i">
				<cfset row[i-1] = IIF(arguments.ci[i] NEQ '', "qryMain[arguments.ci[i]][CurrentRow]", "")>
			</cfloop>
			<cfset row["DT_RowId"] = arguments.PK&"_"&qryMain[arguments.PK][CurrentRow]>			

			<cfif ArrayLen(arguments.ext)>
				<cfset row["ext"] = StructNew()>
				<cfloop array="#arguments.ext#" index="k">
					<cfset row["ext"][k] = qryMain[k][CurrentRow]>
				</cfloop>
			</cfif>

			<cfset ArrayAppend(jqdt["data"],row)>
		</cfoutput>

		<cfreturn jqdt>
	</cffunction>
	
	<cffunction name="parseRequest" access="public" returntype="struct" output="no">
		<cfargument name="args" type="struct" required="yes">
		<cfset var columns = StructNew()>
		<cfset var order = StructNew()>
		<cfset var search = StructNew()>
		<cfset var k = "">		
		<cfset var params = []>
		<cfset StructDelete(arguments.args, '_')>
		
		<cfloop collection="#arguments.args#" item="k">
			<cfif REFindNoCase('^columns', k)>
				<cfset params = REFindA('\[(\w+)\]', k)>
				<cfif ArrayLen(params) EQ 3>
					<cfset columns[params[1]][params[2]][params[3]] = arguments.args[k]>
				<cfelse>
					<cfset columns[params[1]][params[2]] = arguments.args[k]>
				</cfif>
				<cfset StructDelete(arguments.args, k)>
			</cfif>	
			
			<cfif REFindNoCase('^order', k)>
				<cfset params = REFindA('\[(\w+)\]', k)>
				<cfset order[params[1]][params[2]] = arguments.args[k]>
				<cfset StructDelete(arguments.args, k)>
			</cfif>	
			
			<cfif REFindNoCase('^search', k)>
				<cfset params = REFindA('\[(\w+)\]', k)>
				<cfset search[params[1]] = arguments.args[k]>
				<cfset StructDelete(arguments.args, k)>
			</cfif>
		</cfloop>
		<cfset arguments.args["columns"] = columns>
		<cfset arguments.args["order"] = order>
		<cfset arguments.args["search"] = search>
		<cfreturn arguments.args>
	</cffunction>
	
	<cffunction name="ParseFilter" access="public" returntype="struct" output="no">
		<cfargument name="args" required="yes" type="struct">
		<cfset var k = "">
		<cfset var params = []>
		<cfset var op = "">
		<cfset var tempObj = StructNew()>
		<cfset arguments.args.where = []>
		
		<cfloop collection="#arguments.args#" item="k">
			<cfif REFindNoCase('^filter_', k)>
				<cfif arguments.args[k] NEQ ''>
					<cfset params = ListToArray(k, '_')>
					<cfif ArrayLen(params) EQ 3>
						<cfswitch expression="#params[3]#">
							<cfcase value="eq">
								<cfset op = "=">
							</cfcase>
							<cfcase value="neq">
								<cfset op = "!=">
							</cfcase>
							<cfcase value="lte">
								<cfset op = "<=">
							</cfcase>
							<cfcase value="gte">
								<cfset op = ">=">
							</cfcase>
							<cfcase value="lt">
								<cfset op = "<">
							</cfcase>
							<cfcase value="gt">
								<cfset op = ">">
							</cfcase>
							<cfcase value="bitA">
								<cfset op = "&">
							</cfcase>
						</cfswitch>
					<cfelse>
						<cfset op = "LIKE">
					</cfif>
					
					<cfset tempObj["col"] = params[2]>
					<cfset tempObj["op"] = op>					
					<cfset tempObj["val"] = arguments.args[k]>
					
					<cfset ArrayAppend(arguments.args.where, tempObj)>
					<cfset tempObj = StructNew()>
					<cfset StructDelete(arguments.args, k)>
				</cfif>				
			</cfif>
		</cfloop>
		
		<cfreturn arguments.args>
	</cffunction>
	
	<cffunction name="jqdtColumnFilter" access="public" returntype="struct" output="no">
		<cfargument name="args" required="yes" type="struct">
		<cfset var k = 0>
		<cfset var i = 0>
		<cfset var dtRange = ''>
		
		<cfif StructKeyExists(arguments.args, 'sRangeSeparator')>
			<cfloop collection="#arguments.args#" item="k">
				<cfif REFindNoCase('^sSearch_', k) AND arguments.args[k] CONTAINS arguments.args.sRangeSeparator>
					<cfset i = ListGetAt(k, 2, '_')+1>
					<cfset dtRange = ListToArray(arguments.args[k], '~', true)>
					
					<cfif ArrayLen(dtRange) AND IsDate(dtRange[1])>
						<cfset arguments.args["filter_" & arguments.args.ci[i] & "_gte"] = dtRange[1] & " 00:00:00">3
					</cfif>
					<cfif ArrayLen(dtRange) EQ 2 AND IsDate(dtRange[2])>
						<cfset arguments.args["filter_" & arguments.args.ci[i] & "_lte"] = dtRange[2] & " 23:59:59.997">
					</cfif>
					
					<cfset arguments.args[k] = "">
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn arguments.args>
	</cffunction>
	
	<!--- 1.9.x --->
	<cffunction name="jqdtCall" access="public" returnformat="json" returntype="struct" output="no" hint="DT 1.9.x">
		<cfargument name="iDisplayStart" required="yes" hint="Display start point in the current data set.">
		<cfargument name="iDisplayLength" required="yes" hint="Number of records that the table can display in the current draw. It is expected that the number of records returned will be equal to this number, unless the server has fewer records to return.">
		<cfargument name="iColumns" required="yes" hint="Number of columns being displayed (useful for getting individual column search info)">
		<cfargument name="sSearch" required="yes" hint="Global search field">
		<cfargument name="bRegex" required="yes" hint="True if the global filter should be treated as a regular expression for advanced filtering, false if not.">
		<cfargument name="iSortingCols" required="yes" hint="Number of columns to sort on">
		<cfargument name="sEcho" required="yes" hint="Information for DataTables to use for rendering.">
		<cfargument name="ci" required="yes" hint="Column Index">
		<cfargument name="view" required="yes" hint="SQL View">
		<cfargument name="pk" required="yes" hint="Primary Key">
		<cfargument name="where" required="yes" type="array" hint="WHERE clause filter">
		<cfargument name="ext" required="no" type="array" hint="Extra column data to be returned inside aData.ext" default="#ArrayNew(1)#">

		<cfset var jqdt = StructNew()>		
		<cfset var arg = "">
		<cfset var k = "">
		<cfset var v = 0>
		<cfset var qryMain = QueryNew('')>
		<cfset var qryTotal = QueryNew('')>
		<cfset var i = 0>
		<cfset var x = 0>
		<cfset var c = 0>
		<cfset var cr = 1>
		<cfset var filter = true>
		<cfset var row = StructNew()>	
		
		<cfset jqdt["sEcho"] = arguments.sEcho>
		<cfset jqdt["aaData"] = ArrayNew(1)>
		
		<!--- CleanUp --->
		<cfset arguments.sSearchG = arguments.sSearch>
		<cfset arguments.bRegexG = arguments.bRegex>		
		<cfset StructDelete(arguments, "sSearch")>
		<cfset StructDelete(arguments, "bRegex")>
		<cfloop collection="#arguments#" item="arg">
			<cfif ListLen(arg, '_') EQ 2>
				<cfset k = ListFirst(arg, '_')>
				<cfset v = ListLast(arg, '_')+1>								
				<cfif NOT StructKeyExists(arguments, k)><cfset arguments[k] = ArrayNew(1)></cfif>				
				<cfset arguments[k][v] = arguments[arg]>
				<cfset StructDelete(arguments, arg)>		
			</cfif>
		</cfloop>
		<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
			<cfset arguments.mDataProp[i] = arguments.ci[i]>
		</cfloop>

		<!--- Get --->
		<cfquery name="qryMain" datasource="#application.datasource#">
			DECLARE @gSrch varchar(max) 
			SET @gSrch = <cfqueryparam value="%#arguments.sSearchG#%" cfsqltype="cf_sql_varchar">
			
			SELECT <cfif arguments.iDisplayLength GT 0>TOP(<cfqueryparam value="#arguments.iDisplayLength#" cfsqltype="cf_sql_integer">)</cfif> *
			FROM (
				SELECT ROW_NUMBER() OVER(ORDER BY
					<cfif arguments.iSortingCols>
						<cfloop from="1" to="#arguments.iSortingCols#" index="i">
							<cfset c = arguments.iSortCol[i]+1>
							<cfif arguments.bSortable[c]>
								<cfif i GT 1>,</cfif> #arguments.mDataProp[c]# #arguments.sSortDir[i]#
							</cfif>
						</cfloop>
					</cfif>) AS R<cfif !(ci.indexOf(arguments.PK)+1) AND !(ext.indexOf(arguments.PK)+1)>, #arguments.PK#</cfif>
					, [#ArrayToList(ListToArray(ArrayToList(ci)), '],[')#]
					<cfif ArrayLen(arguments.ext)>, [#ArrayToList(ListToArray(ArrayToList(arguments.ext)), '],[')#]</cfif>
					
				FROM #arguments.view#
				<cfif arguments.sSearchG NEQ "" OR ArrayLen(arguments.where) OR ArrayLen(ListToArray(ArrayToList(arguments.sSearch)))>
				WHERE
					<cfif arguments.sSearchG NEQ "">
					(
						<cfset x = 0>
						<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
						<cfif arguments.bSearchable[i] AND arguments.mDataProp[i] NEQ ''>
							<cfif x++>OR</cfif> [#arguments.mDataProp[i]#] LIKE @gSrch
						</cfif>					
						</cfloop>
					) <cfif ArrayLen(ListToArray(ArrayToList(arguments.sSearch))) OR ArrayLen(arguments.where)>AND</cfif>
					</cfif>
					
					<cfset x = 0>
					<cfloop from="1" to="#ArrayLen(arguments.sSearch)#" index="i">						
						<cfif arguments.sSearch[i] NEQ "">							
							<cfif x++>AND</cfif>
							([#arguments.mDataProp[i]#] LIKE <cfqueryparam value="%#arguments.sSearch[i]#%">)
						</cfif>
					</cfloop>
					
					<cfset i = 0>
					<cfloop array="#arguments.where#" index="c">
						<cfif x++>AND</cfif>
							<cfif c["val"] NEQ 0 OR c.col CONTAINS ' '>
							#c.col# #c.op# <cfqueryparam value="#c.val#">
							<cfelse>
							#c.col# IS NULL
							</cfif>
					</cfloop>
				</cfif>
			) Q
			WHERE R > <cfqueryparam value="#arguments.iDisplayStart#" cfsqltype="cf_sql_integer">
			ORDER BY R
		</cfquery>

		<cfquery name="qryTotal" datasource="#application.datasource#">
			DECLARE @gSrch varchar(max)
			SET @gSrch = <cfqueryparam value="%#arguments.sSearchG#%" cfsqltype="cf_sql_varchar">
			
			SELECT COUNT(#arguments.PK#) AS TotalFiltered, (SELECT COUNT(#arguments.PK#) AS Total FROM #arguments.view#) AS Total
			FROM #arguments.view#
			<cfif arguments.sSearchG NEQ "" OR ArrayLen(arguments.where) OR ArrayLen(ListToArray(ArrayToList(arguments.sSearch)))>
			WHERE
				<cfif arguments.sSearchG NEQ "">
				(
					<cfset x = 0>
					<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
					<cfif arguments.bSearchable[i] AND arguments.mDataProp[i] NEQ ''>
						<cfif x++>OR</cfif> [#arguments.mDataProp[i]#] LIKE @gSrch
					</cfif>					
					</cfloop>
				) <cfif ArrayLen(ListToArray(ArrayToList(arguments.sSearch))) OR ArrayLen(arguments.where)>AND</cfif>
				</cfif>
				
				<cfset x = 0>
				<cfloop from="1" to="#ArrayLen(arguments.sSearch)#" index="i">
					<cfif arguments.sSearch[i] NEQ "">							
						<cfif x++>AND</cfif>
						([#arguments.mDataProp[i]#] LIKE <cfqueryparam value="%#arguments.sSearch[i]#%">)
					</cfif>
				</cfloop>
				
				<cfset i = 0>
				<cfloop array="#arguments.where#" index="c">
					<cfif x++>AND</cfif>
						<cfif c["val"] NEQ 0 OR c.col CONTAINS ' '>
						#c.col# #c.op# <cfqueryparam value="#c.val#">
						<cfelse>
						#c.col# IS NULL
						</cfif>
				</cfloop>
			</cfif>
		</cfquery>

		<!--- Build --->
		<cfset jqdt["iTotalRecords"] = qryTotal.Total>		
		<cfset jqdt["iTotalDisplayRecords"] = qryTotal.TotalFiltered>
		<cfoutput query="qryMain">
			<cfset row = StructNew()>
			<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
				<cfset row[i-1] = IIF(arguments.mDataProp[i] NEQ '' , "qryMain[arguments.mDataProp[i]][CurrentRow]", '')>
			</cfloop>
			<cfset row["DT_RowId"] = arguments.PK&"_"&qryMain[arguments.PK][CurrentRow]>

			<cfif StructKeyExists(arguments, "ext")>
				<cfset row["ext"] = StructNew()>
				<cfloop array="#arguments.ext#" index="k">
					<cfset row["ext"][k] = qryMain[k][CurrentRow]>
				</cfloop>
			</cfif>

			<cfset ArrayAppend(jqdt["aaData"],row)>
		</cfoutput>

		<cfreturn jqdt>
	</cffunction>

	<cffunction name="jqdtParseFilter" access="public" returntype="struct" output="no">
		<cfargument name="initArgs" required="yes" type="struct">
		<cfargument name="procArgs" required="yes" type="struct">
		<cfset arguments.procArgs.where = StructNew()>

		<cfloop collection="#arguments.initArgs#" item="k">
			<cfif REFindNoCase('^filter_', k)>
				<cfif arguments.initArgs[k] NEQ ''>
					<cfset params = ListToArray(k, '_')>
					<cfif ArrayLen(params) EQ 3>
						<cfswitch expression="#params[3]#">
							<cfcase value="eq">
								<cfset op = "=">
							</cfcase>
							<cfcase value="neq">
								<cfset op = "!=">
							</cfcase>
							<cfcase value="lte">
								<cfset op = "<=">
							</cfcase>
							<cfcase value="gte">
								<cfset op = ">=">
							</cfcase>
							<cfcase value="lt">
								<cfset op = "<">
							</cfcase>
							<cfcase value="gt">
								<cfset op = ">">
							</cfcase>
						</cfswitch>
					<cfelse>
						<cfset op = "LIKE">
					</cfif>
					
					<cfset arguments.procArgs.where[ListGetAt(k, 2, '_')]["col"] = params[2]>
					<cfset arguments.procArgs.where[ListGetAt(k, 2, '_')]["val"] = arguments.initArgs[k]>
					<cfset arguments.procArgs.where[ListGetAt(k, 2, '_')]["op"] = op>
					
					<cfset StructDelete(arguments.procArgs, k)>
				</cfif>
				
			</cfif>
		</cfloop>

		<cfreturn arguments.procArgs>
	</cffunction>
	
</cfcomponent>
