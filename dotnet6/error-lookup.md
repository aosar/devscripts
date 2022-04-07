# .NET-Azure Error Lookup

**Error:**
```
[2022-03-22 15:21:04.076] [Error] -Host.Startup: A host error has occurred during startup operation '319dbd9a-fb20-461c-a096-2bc504f79b85'.
System.InvalidOperationException: Secret initialization from Blob storage failed due to missing both an Azure Storage connection string and a SAS connection uri. For Blob Storage, please provide at least one of these. If you intend to use files for secrets, add an App Setting key 'AzureWebJobsSecretStorageType' with value 'Files'.
```

**Solutions:**
Add line to config `.Values`:
```
"AzureWebJobsSecretStorageType": "Files"
```

Alternative solution, if it seems to be ignoring this option:
Change dependency version:
`Microsoft.Azure.WebJobs.Extensions.Storage`
- v5 causes issues, perhaps because `Files` isnt a config option anymore
- Downgrade to v4 and there arent really issues


**Error:**
```
Value cannot be null. (Parameter 'provider')
   at Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions.GetRequiredService[T](IServiceProvider provider)
   at Azure.Functions.Cli.Actions.HostActions.StartHostAction.RunAsync() in D:\a\1\s\src\Azure.Functions.Cli\Actions\HostActions\StartHostAction.cs:line 367
   at Azure.Functions.Cli.ConsoleApp.RunAsync[T](String[] args, IContainer container) in D:\a\1\s\src\Azure.Functions.Cli\ConsoleApp.cs:line 64
```
(This usually just occurs as a standalone message `Value cannot be null. (Parameter 'provider')`. The stack trace can be viewed by enabling the env variable `CLI_DEBUG`)

This is an interesting one. Note the following statements may not be completely accurate. It is speculation based on my own trial and error and reading output logs, as Microsoft documentation and various forums didn't cover the particular issue I was having. 

This can happen if you propogate errors in one of the startup hooks, and I think this happens because the storage host hasn't been initalized yet and it's not sure what to do with the logging. This is partially evidenced by the following logs (note the null host):
```
[DEBUG] [Startup.Configure] Error: Serilog config file ./appsettings.json does not exist.
   at Company.Function.Startup.Configure(IFunctionsHostBuilder builder) in C:\Projects\test-azure-cs\Startup.cs:line 26
[2022-03-30T20:09:11.735Z] A host error has occurred during startup operation 'c1934275-4a4b-4c83-9490-a6cbcca1b161'.
[2022-03-30T20:09:11.735Z] test-azure-cs: Serilog config file ./appsettings.json does not exist.
[2022-03-30T20:09:11.736Z] Active host changing from '(null)' to '(null)'.
[2022-03-30T20:09:11.737Z] Will start a new host after delay.
[2022-03-30T20:09:11.739Z] Delay is '00:00:01'.
Value cannot be null. (Parameter 'provider')
[2022-03-30T20:09:11.748Z] Cancellation for operation 'c1934275-4a4b-4c83-9490-a6cbcca1b161' requested during delay. A new host will not be started.
[2022-03-30T20:09:11.749Z] Startup operation 'c1934275-4a4b-4c83-9490-a6cbcca1b161' completed.
[2022-03-30T20:09:11.752Z] Initialization cancellation requested by runtime.
```
Extra details:
- the first line is a custom log with the same setup as described earlier in this document
- `host.json` contains the setting `logLevel.default=debug`
- `$env:CLI_DEBUG=0` (PowerShell env)

The log line `Active host changing from '(<id>)' to '(<id>)'` contains an ID in the first position when errors are thrown outside the context of the startup hook. The provider error does not occur if you swallow the error in a try catch block (you can still log the error, just dont throw it).


**Error:**
```
Microsoft.Azure.WebJobs.Host.Indexers.FunctionIndexingException: Error indexing method 'getName'
 ---> System.InvalidOperationException: Storage account connection string 'AzureWebJobsAzureWebJobsStorage' does not exist. Make sure that it is a defined App Setting.
```

**Solution:**
This can happen if your `local.settings.json` has nested json objects within Values. It doesnt do **any** validation, and it can't read any of the values because it gets confused..

**Error:**
```
[2022-04-05 10:10:18.553] [Error] -Host.Startup: Error indexing method 'getName'
Microsoft.Azure.WebJobs.Host.Indexers.FunctionIndexingException: Error indexing method 'getName'
 ---> System.InvalidOperationException: Storage account connection string for 'AzureWebJobsAzureWebJobsStorage' is invalid
```
This happened when I set `Files` which was deprecated in the newer versions of storage.

Solution:
TBA