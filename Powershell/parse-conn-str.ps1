$FILE_PATH=$Args[0]

if (-not $FILE_PATH) {
  echo "Missing parameter FILE_PATH `n"
  exit 1
}

[xml]$xmlContent = Get-Content -Path $FILE_PATH

# Possible TODO: keep these scoped
$dbConnLookup = @{}
$dbConnList = New-Object System.Collections.Generic.List[System.Object]
$Namespace = @{
  DTS = "www.microsoft.com/SqlServer/Dts"
}

$TestXml = Select-Xml -Path $FILE_PATH -Namespace $Namespace -XPath "/DTS:Executable/DTS:Property"
echo $TestXml.Node

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


function GetTablesByConnection {
  # $Connections = GetConnStrAsHashByDTSID;
  # $Connections |
  #   ForEach-Object {
  #     echo "===="
  #     $_
  #   } 

  # $xmlContent.Load()
  # echo $xmlContent.SelectNodes("/Executable", Nam);
  # echo $xmlContent.SelectNodes("//SQLTask:SqlTaskData");
  # echo $xmlContent.SelectNodes("//SqlTaskData[@Connection='{C7520A9D-14A9-4EB1-9764-6F60CDE13EE8}']");

  # $Tables = @{};
  # $Connections

}

# (temp comment-uncomment section)
# ==== Function Calls ====
#PrintAllConnStr
# GetConnStrAsObjList
# GetConnStrAsHashByDTSID | ConvertTo-Json
GetTablesByConnection

## Parsing examples
#$(GetConnStrAsHashByDTSID)["{DEA-DBEEF-456}"]