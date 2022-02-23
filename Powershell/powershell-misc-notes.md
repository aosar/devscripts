# PowerShell Misc Notes

## Functions

Example to demonstrate multiple concepts without words:

```
function WriteLog {
  param (
    [Parameter(Mandatory=$False)]
      [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
      [String] $Level = "INFO",
    [Parameter(Mandatory=$True)] [string] $Message,
    [Parameter(Mandatory=$False)] [string] $Logfile
  )
  # Commands here
}
```

## Modules

### Custom Modules
In PS v5 you can just export from a powershell file (ps1) and import it in your script (ps1). Add this to the end of the file:
```
Export-ModuleMember -Function WriteLog
```
And import like this:
```
Import-Module -Name .\Logger.ps1 -Function WriteLog
```
In PS v7 you have to make it a module file (`psm1`) and that module has to be in your path. If you have a project-specific module, you can temporarily add it to your path, import it, and set the path back to the way it was. This was my workaround for that, placed at the beginning of the file utilizing the module:
```
$TempModulePath = $env:PSModulePath
$env:PSModulePath = "${env:PSModulePath};$(pwd)"
# Import logger
Import-Module -Name .\Logger.psm1 -Function WriteLog
# Restore original path
$env:PSModulePath = $TempModulePath
```
Of course you'll want to import all your modules in between the path modifications. As a note, `$TempModulePath` does not mutate when the env variable is modified, so this works fine. It may not work if the import errors out; I havent tested thoroughly.

### Issues with external modules
- Hanging on install:
  - If you're using PS <= v7.2.1, it hangs instead of throwing an actual error. If you run in PS v5 you will probably see an error.
  - This may be a permissions issue. If appropriate, open a new terminal as admin, or elevate priveleges in current terminal. If sharing a computer you may want to change your install path to one that you own to avoid unnecessary privelege escalation.

- Strange errors
  - Ensure there aren't any conflicts with another module imported for the session. If running commands in a terminal, you can try opening a new session and importing the module fresh.

## Multiline Things

### Command: <code>`</code>
Running a multiline command you must put a backtick at the end of line.

### String: `@" ... "@`
Using a multiline string you must use `@"` (opening) and `"@` (closing). Closing characters CANNOT have whitespace preceeding it.

### Pipes
Piping a multiline command must have the pipe character on the same line as the end of the preceeding command if you do not use a backtick. You do not need a backtick if you make a newline for the command accepting input.

Here is a command example showing all of the above concepts:

```
Invoke-DbaQuery `
  -Query @"
    SELECT
      sja.start_execution_date,
      sja.stop_execution_date
    FROM msdb.dbo.sysjobactivity sja
"@ `
  -SQLInstance "${DB_SERVER}" |
  Export-Csv `
    -Path 'JobActivity.csv' `
    -Encoding UTF8 `
    -NoTypeInformation
```

Note you do not need an EOL backtick during multiline strings.



## Hashes
You cannot indirectly set a hash key-val, as such:
(this just reassigns temp key)
```
$temp_key = $someObject[$keyName]
$temp_key = $temp_DbConnStr
```
Only assign it directly:
```
$someObject[$keyName] = $temp_DbConnStr
```
(the above is probably obvious but worth pointing out?)