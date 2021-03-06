$FILE_PATH=$Args[0]

$CALL=$Args[1]
$PASSTHRU=$Args[2]

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
      #echo "=============================="
      # todo rename var. call is just arg for data output
      if ($CALL -eq "name") {
        echo $_.ObjectName
      } else {
        echo $_.ObjectData.ConnectionManager.ConnectionString
      }
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
      $connStrDataOriginal = $_.ObjectData.ConnectionManager.ConnectionString
      $lookupId = $_.DTSID
      try {
        # Note: this function mutates "this" ($_). If unsuccessful it sets it to an error (yay Powershell)
        $temp_DbConnStr.set_ConnectionString(
          $connStrDataOriginal
        )
      } catch {
        ## silence warning
        ## echo "[Warning] Connection string could not be converted into a database connection object. Using raw string."

        $temp_DbConnStr = $connStrDataOriginal
      }

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

function GetSqlQueries {
  param (
    [switch]$AreDisabled,
    [switch]$GetAll
  )
  $Namespace = @{
    DTS = "www.microsoft.com/SqlServer/Dts"
    SQLTask = "www.microsoft.com/sqlserver/dts/tasks/sqltask"
  }
  
  $SqlQueryXPath = '//SQLTask:SqlTaskData'

  # TODO: more efficient templating
  if (!$GetAll) {
    if ($AreDisabled) {
      $SqlQueryXPath = "//DTS:Executable[@DTS:Disabled=`"True`"]/DTS:ObjectData/SQLTask:SqlTaskData"
    } else { # implicit areDisabled="False", modify if changing default from False
      # consider missing prop not disabled
      $SqlQueryXPath = "(//DTS:Executable[@DTS:Disabled=`"False`"]|//DTS:Executable[not(@DTS:Disabled)])/DTS:ObjectData/SQLTask:SqlTaskData"
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

function PrintAllVar {
  echo "`n"
  $xmlContent.Executable.Variables.Variable |
    ForEach-Object {
    #echo $_
      #echo "=============================="
      # todo rename var
      if ($PASSTHRU -eq "name") {
        echo $_.ObjectName
      } else {
        if ($_.EvaluateAsExpression) {
          echo $_.Expression
        } else {
          echo $_.VariableValue.InnerText
        }
      }
    }
  echo "`n"
}

# (temp comment-uncomment section)
# ==== Function Calls ====
#PrintAllConnStr
# GetConnStrAsObjList
# echo " === Connection String Lookup =="
if ($CALL -eq "conn") {
  GetConnStrAsHash | ConvertTo-Json
}
#GetConnStrAsHash 
#| ForEach-Object {
#  echo $_.Name
#  $_.Value | ConvertTo-JSON
#}


if ($CALL -eq "sql") {
  if(-not $PASSTHRU) {
    echo "[debug] no arg"
    GetSqlQueries
  } else {
    GetSqlQueriesByConnId $PASSTHRU | ConvertTo-Json
  }
}

## Parsing examples
#$(GetConnStrAsHash)["{DEA-DBEEF-456}"]

<#
# "View"
$ConnHash = GetConnStrAsHash
$ConnView = @{}
$ConnHash.keys | ForEach-Object {
   #echo GetSqlQueriesByConnId("`"${_}`"")
   echo $(GetSqlQueriesByConnId("${_}"))
  
  #$ConnView[$ConnHash["${_}"]] = GetSqlQueriesByConnId($_)
  #$ConnHash["${_}"]['SqlQueries'] = GetSqlQueriesByConnId($_)
}
#$ConnView
#>




if ($CALL -eq "var") {
  PrintAllVar
} else {
  echo "[debug] print all conn"
  PrintAllConnStr
}

<#
  Example usage:
  .\parse-conn-str.ps1 $FILEPATH.dtsx sql
  .\parse-conn-str.ps1 $FILEPATH.dtsx sql "{$UUID}"
  $(.\parse-conn-str.ps1 $FILEPATH.dtsx sql).SqlStatementSource
  .\parse-conn-str.ps1 $FILEPATH.dtsx conn
  .\parse-conn-str.ps1 $FILEPATH.dtsx var
  .\parse-conn-str.ps1 $FILEPATH.dtsx var name
#>