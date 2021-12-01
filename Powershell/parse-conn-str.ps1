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
function GetConnStrAsHashByDTSID {
  $xmlContent.Executable.ConnectionManagers.ConnectionManager |
    ForEach-Object {
      $temp_DbConnStr = New-Object System.Data.Common.DbConnectionStringBuilder
      $temp_DbConnStr.set_ConnectionString(
        $_.ObjectData.ConnectionManager.ConnectionString
      )
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

# (temp comment-uncomment section)
# ==== Function Calls ====
#PrintAllConnStr
#GetConnStrAsObjList
GetConnStrAsHashByDTSID

## Parsing examples
#$(GetConnStrAsHashByDTSID)["{DEA-DBEEF-456}"]