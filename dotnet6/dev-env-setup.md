# Project setup

## 1 - Clone repo
## 2 - Install extensions
1. Azure Functions
  - This will install dependencies Azure Account and Azure Resources
2. NuGet Package Manager - jmrog
3. C# - more optional
4. Azure tools

## 3 - Install C# package dependencies through NuGet
- ctrl + shift + p
- View packages in `.csproj` file under Project.ItemGroup. Search names
- Search "nuget", select Add Package. Manually type the names in and select the relevant versions.

## UI-based Setup:
### 4a - Set up function as local server
- Install azure functions core tools if not installed
- Go to debugger > Attach .NET Functions
- If error "You must have Azure Functions Core Tools installed":
  - https://github.com/Azure/azure-functions-core-tools/releases
  - Download x64 msi file and isntall (alternatively download zip and add to env variables)
  - Restart vscode (reload is not enough)
- Output should list functions and their ports and paths listening. May be `7071`.

### 5a - Query API endpoints with PostMan

## CLI-based Setup
This may be preferred since response time is faster (in the magnitude of seconds and milliseconds, but enough to stifle a good train of thought) and more accurate. At times the VSCode debugger can be finnicky, such as not displaying output until focusing on the output window and pressing enter.

This also displays basic logging output (eg Console.WriteLine) and displays datetime next to output in more logger style.

### 4b - Set up function as local server
- Azure functions core tools uses `func` command
- Same debug steps as above
- Install coreclr
- Navigate to folder with csharp file(s)
- Run command:
```
C:\Program` Files\dotnet\dotnet.exe build /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary
func host start
```
  - id recommend adding a function to invoke both of these

### 5b - Query API endpoints with curl
- note: this will be a pain if you require use of headers or HTTPS

## Connect to a remote db
Rudimentary setup:
Use firewall to whitelist IPs

Here is an example of `local.setings.json` connecting to a test db:
```
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "CONNECTION_STRING": "Server=tcp:someresrcname.database.windows.net,1433;Initial Catalog=db1;Persist Security Info=False;User ID={user};Password={password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;",
    "dbPassword": "foobarpw123",
    "dbUser": "admin"
  }
}
```

## Storage setup
Azure made some vague names for their configs, so spelling that out here.

[missing installation notes]

- TODO: finish sections
### Option 1 - Use filesystem storage (local) - `Files`
- `"AzureWebJobsSecretStorageType": "Files"`
- This arg value doesnt work for some dependency versions. Seems like they are trying really hard to deprecate it.

### Option 2 - Use emulated storage resource (local) - `Blob`
```
"AzureWebJobsSecretStorageType": "Blob"
"AzureWebJobsStorage": "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=<keypath>==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;", 
```

 - default values for local instance