Coldfusion-DataTables
=======================

Coldfusion CFC to handle server side processing of jQuery DataTables. Root files are DataTables v1.10.x and v1.9.x processing combined. The folders are dedicated files to each version, though might be outdated.

##DataTables v1.10.x (DT_1.10)##
#####DataTables.cfc####
#####DTCalls.cfc####
#####Functions.cfc####

##DataTables v1.9.x (DT_1.9)##
#####DataTables.cfc#####
* jqdtCall - The main function that handles the parsing and building of the JSON response for DataTables.
* jqdtParseFilter - The helper method to handle situations where you would want to filter out data manually (e.g. A dropdown selection)
 * It keys off input/select names that start with "filter\_". It is inclusive by default ("=") but can be set to exclusive ("!=") by appending \_ex to the input/select name (e.g. filter\_fooID\_ex).
  
#####dtAjax.cfc#####
* Contains an example function jqdtExample. This is what you would have DataTables call via sAjaxSource (e.g. 'dtAjax.cfc?method=jqdtExample').
 * CI is the Column Index. This should match your DataTables headers.
 * View is the SQL view that will be used to fetch the data. It doesn't have to be a view if the data is simple enough, but views are a lot easier to manage in this context.
 * PK is the PrimaryKey of the view.
  
I strongly recommend the fnSetFilteringDelay and fnReloadAjax plugins as they will help termendously if your dataset is particularly large.
    
    
Example DataTables Initialization
=======================
	$('#tblFoo').dataTable({
		,bServerSide: true
		,sAjaxSource: "dtAjax.cfc?method=jqdtExample"
	});
