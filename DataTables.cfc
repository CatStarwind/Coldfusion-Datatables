<cfcomponent displayname="DataTables" hint="Handle DataTables Processing" output="no">
	<cffunction name="jqdtCall" access="public" returnformat="json" returntype="struct" output="no">
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
		<cfargument name="where" required="yes" hint="WHERE clause filter">
		<cfargument name="ext" required="no" hint="Extra column data to be returned inside aData.ext">

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
								
				<cfif NOT StructKeyExists(arguments, k)>
					<cfset arguments[k] = ArrayNew(1)>
				</cfif>
				<cfset arguments[k][v] = arguments[arg]>
				<cfset StructDelete(arguments, arg)>		
			</cfif>
		</cfloop>
		<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
			<cfset arguments.mDataProp[i] = arguments.ci[i]>
		</cfloop>

		<!--- Get --->
		<cfquery name="qryMain" datasource="#application.datasource#">
			DECLARE @gSrch varchar(max) = <cfqueryparam value="%#arguments.sSearchG#%" cfsqltype="cf_sql_varchar">
			
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
					</cfif>) AS R<cfif !ArrayFind(ci, arguments.PK)>, #arguments.PK#</cfif>
					, [#ArrayToList(ListToArray(ArrayToList(ci)), '],[')#]
				FROM #arguments.view#
				<cfif arguments.sSearchG NEQ "" OR StructCount(arguments.where)>
				WHERE
					<cfif arguments.sSearchG NEQ "">
					(
						<cfset x = 0>
						<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
						<cfif arguments.bSearchable[i]>
							<cfif x++>OR</cfif> [#arguments.mDataProp[i]#] LIKE @gSrch
						</cfif>					
						</cfloop>
					)
					</cfif>
					<cfset i = 0>
					<cfloop collection="#arguments.where#" item="k">
						<cfif arguments.sSearchG NEQ "" OR i++>AND</cfif>
							<cfif arguments.where[k]["val"] NEQ 0>
							#k# #arguments.where[k].op# <cfqueryparam value="#arguments.where[k].val#">
							<cfelse>
							#k# IS NULL
							</cfif>
					</cfloop>
				</cfif>
			) Q
			WHERE R > <cfqueryparam value="#arguments.iDisplayStart#" cfsqltype="cf_sql_integer">
			ORDER BY R
		</cfquery>

		<cfquery name="qryTotal" datasource="#application.datasource#">
			DECLARE @gSrch varchar(max) = <cfqueryparam value="%#arguments.sSearchG#%" cfsqltype="cf_sql_varchar">
			
			SELECT COUNT(#arguments.PK#) AS TotalFiltered, (SELECT COUNT(#arguments.PK#) AS Total FROM #arguments.view#) AS Total
			FROM #arguments.view#
			<cfif arguments.sSearchG NEQ "" OR StructCount(arguments.where)>
			WHERE
				<cfif arguments.sSearchG NEQ "">
				(
					<cfset x = 0>
					<cfloop from="1" to="#ArrayLen(arguments.mDataProp)#" index="i">
					<cfif arguments.bSearchable[i]>
						<cfif x++>OR</cfif> [#arguments.mDataProp[i]#] LIKE @gSrch
					</cfif>					
					</cfloop>
				)
				</cfif>
				<cfset i = 0>
				<cfloop collection="#arguments.where#" item="k">
					<cfif arguments.sSearchG NEQ "" OR i++>AND</cfif>
						<cfif arguments.where[k]["val"] NEQ 0>
						#k# #arguments.where[k].op# <cfqueryparam value="#arguments.where[k].val#">
						<cfelse>
						#k# IS NULL
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
				<cfset row[i-1] = (arguments.mDataProp[i] NEQ '' ? qryMain[arguments.mDataProp[i]][CurrentRow] : '')>
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

	<cffunction name="jqdtParseFilter" access="public" returntype="struct">
		<cfargument name="initArgs" required="yes" type="struct">
		<cfargument name="procArgs" required="yes" type="struct">
		<cfset arguments.procArgs.where = StructNew()>
		
		<cfloop collection="#arguments.initArgs#" item="k">
			<cfif ListLen(k, '_') GT 1 AND ListGetAt(k, 1, '_') EQ "filter">
				<cfif arguments.initArgs[k] NEQ ''>
					<cfset arguments.procArgs.where[ListGetAt(k, 2, '_')]["val"] = arguments.initArgs[k]>
					<cfset arguments.procArgs.where[ListGetAt(k, 2, '_')]["op"] = (ListLen(k, '_') EQ 3 AND ListGetAt(k, 3, '_') EQ "ex" ? "!=" : "=")>
				</cfif>
				<cfset StructDelete(arguments.procArgs, k)>
			</cfif>
		</cfloop>

		<cfreturn arguments.procArgs>
	</cffunction>
</cfcomponent>
