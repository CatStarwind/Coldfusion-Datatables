<cfcomponent displayname="DataTables" hint="Handle DataTables Processing" output="no" extends="Functions">
	<cffunction name="processCall" access="public" returnformat="json" returntype="struct" output="no">
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
		<cfset var jqdt = {"data"=[]}>
		<cfset var row = StructNew()>

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
				WHERE 1=1
					<cfif arguments.search.value NEQ "" OR ArrayLen(arguments.where)>
						<cfif arguments.search.value NEQ "">
						AND (
							<cfset x = 0>
							<cfloop from="1" to="#ArrayLen(arguments.ci)#" index="i">
							<cfif arguments.columns[i-1].searchable AND arguments.ci[i] NEQ ''>
								<cfif x++>OR</cfif> [#arguments.ci[i]#] LIKE @gSrch
							</cfif>					
							</cfloop>
						)
						</cfif>
						
						<cfset i = 0>
						<cfloop array="#arguments.where#" index="c">
							AND 
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
							<cfif (arguments.search.value NEQ "" OR StructCount(arguments.where)) OR x++>AND</cfif>
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
			WHERE 1=1
					<cfif arguments.search.value NEQ "" OR ArrayLen(arguments.where)>
						<cfif arguments.search.value NEQ "">
						AND (
							<cfset x = 0>
							<cfloop from="1" to="#ArrayLen(arguments.ci)#" index="i">
							<cfif arguments.columns[i-1].searchable AND arguments.ci[i] NEQ ''>
								<cfif x++>OR</cfif> [#arguments.ci[i]#] LIKE @gSrch
							</cfif>					
							</cfloop>
						)
						</cfif>

						<cfset i = 0>
						<cfloop array="#arguments.where#" index="c">
							AND 
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
							<cfif (arguments.search.value NEQ "" OR StructCount(arguments.where)) OR x++>AND</cfif>
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
				<cfset row[i-1] = (arguments.ci[i] NEQ '' ? qryMain[arguments.ci[i]][CurrentRow] : '')>
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
	
	<cffunction name="ParseFilter" access="public" returntype="struct" output="yes">
		<cfargument name="args" required="yes" type="struct">
		<cfset var k = "">
		<cfset var params = []>
		<cfset var op = "">
		<cfset var arguments.args.where = []>
		
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
						</cfswitch>
					<cfelse>
						<cfset op = "LIKE">
					</cfif>
					
					<cfset ArrayAppend(arguments.args.where, {
						"col" = params[2]
						,"val" = arguments.args[k]
						,"op" = op
					})>
					<cfset StructDelete(arguments.args, k)>
				</cfif>
				
			</cfif>
		</cfloop>
		
		<cfreturn arguments.args>
	</cffunction>
</cfcomponent>
