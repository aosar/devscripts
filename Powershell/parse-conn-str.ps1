$FILE_PATH=$Args[0]

if (-not $FILE_PATH) {
  echo "Missing parameter FILE_PATH `n"
  exit 1
}

[xml]$xmlContent = Get-Content -Path $FILE_PATH

# Possible TODO: keep these scoped
$dbConnLookup = @{}
$dbConnList = New-Object System.Collections.Generic.List[System.Object]


# Currently using piped for loops for the convenience of oneliners,
# move to real loops if these scripts get more complicated

# For use with atypically structured conn strings
# Only for viewing
function PrintAllConnStr {
  echo "`n"
  $xmlContent.Executable.ConnectionManagers.ConnectionManager |
    ForEach-Object {
      echo "=============================="
      echo $_.ObjectData.ConnectionManager.ConnectionString
    }
  echo "`n"
}

# Returns JSON-style array of objects.
function GetConnStrAsObjList {
  $xmlContent.Executable.ConnectionManagers.ConnectionManager |
    ForEach-Object {
      $temp_DbConnStr = New-Object System.Data.Common.DbConnectionStringBuilder
      $temp_DbConnStr.set_ConnectionString(
        $_.ObjectData.ConnectionManager.ConnectionString
      )
	    $dbConnList.Add($temp_DbConnStr)
    }
  return $dbConnList | ConvertTo-Json
}

# Store connection strings in a hash table using DTSID as lookup key
function GetConnStrAsHash {
  $xmlContent.Executable.ConnectionManagers.ConnectionManager |
    ForEach-Object {
      $temp_DbConnStr = New-Object System.Data.Common.DbConnectionStringBuilder
      try {
        $temp_DbConnStr.set_ConnectionString(
          $_.ObjectData.ConnectionManager.ConnectionString
        )
      } catch {
        echo "Connection string could not be converted into a database connection string. Printing raw string:"
        echo "$_.ObjectData.ConnectionManager.ConnectionString"
        return;
      }
      # var in case change for something else
      $lookupId = $_.DTSID

      # Validate object doesnt already exist in hash table
      if (!!$dbConnLookup[$lookupId]) {
        ## This shouldn't happen unless something has gotten corrupted
        echo "Warning: Connection ID already exists. Possible data corruption, proceed with caution."
        # skip this iteration
        return
      }

      # Add to lookup table
	    $dbConnLookup[$lookupId] = $temp_DbConnStr
    }
  return $dbConnLookup
}

# === Table parser ===

# pseudo code
# Executable.ObjectData.pipeline.components | forEach component
# properties | foreach Property
# if name === "OpenRowset"
  # return embedded element

# Defaults to get enabled sql queries
function GetSqlQueries {
  $Namespace = @{
    DTS = "www.microsoft.com/SqlServer/Dts"
    SQLTask = "www.microsoft.com/sqlserver/dts/tasks/sqltask"
  }
   $areDisabled = 'False' # Default to false
  
  $SqlQueryXPath = '//SQLTask:SqlTaskData'

  # TODO: more efficient templating
  if (!$getAll) {
    if ($areDisabled -eq 'True') {
      $SqlQueryXPath = "//DTS:Executable[@DTS:Disabled=`"${areDisabled}`"]/DTS:ObjectData/SQLTask:SqlTaskData"
    } else { # implicit areDisabled="False", modify if changing default from False
      # consider missing prop not disabled
      $SqlQueryXPath = "(//DTS:Executable[@DTS:Disabled=`"${areDisabled}`"]|//DTS:Executable[not(@DTS:Disabled)])/DTS:ObjectData/SQLTask:SqlTaskData"
    }
  }
  return $(
    Select-Xml -Path $FILE_PATH -Namespace $Namespace -XPath $SqlQueryXPath
  ).Node
}
function GetSqlQueriesByConnId {
  param (
    [string]$connectionId
  )
  $queries = New-Object System.Collections.Generic.List[System.Object]

  GetSqlQueries |
    ForEach-Object {
      if ($_.Connection -eq $connectionId) {
        $queries.Add($_.SqlStatementSource);
      }
    }
  return $queries
}

# (temp comment-uncomment section)
# ==== Function Calls ====
#PrintAllConnStr
# GetConnStrAsObjList
# GetConnStrAsHash | ConvertTo-Json
# $(GetConnStrAsHash).keys | ForEach-Object {
#   $_.SqlQueries = GetSqlQueriesByConnId($_)
# }
# GetSqlQueriesByConnId '{B4D95B53-7D7E-40C0-BDE4-735C16D4AEDE}'
$(GetSqlQueries)

## Parsing examples
#$(GetConnStrAsHash)["{DEA-DBEEF-456}"]