# Minimalist .NET + Azure reference guide (informal)

For some reason .NET developers around the internet love to use libraries and write 20 lines of code for things that should take 1-3 lines, so I've written this guide for my own reference. I've mostly documented things helpful for debugging that people rarely or never mention in forums. Full disclosure I am going from writing vanilla JS to .NET; take that as you will.

## js to .net notes

| js | .net |
| - | - |
| `x.csproj` | `package.json` |
| `npm i` | `dotnet restore` |


`csproj` is similar to `package.json`, but more integrated with the code itself.

### Debugging
View props in an object:
```
foreach(object obj in initializedObject.AsEnumerable()) {
    Console.WriteLine($"{obj.ToString()}");
}
```
Similar to js:
```
console.log(Object.keys(obj));

// or, logically speaking, looks like what this would print:
obj.forEach(item => {console.log(`$[item]`)})
```
Keep in mind you shouldnt have to do this if you use an actual debugger.

## Error handling
So .net doesnt include stack traces by default, for whatever inane reason. So you have to try catch at the topmost part of your project if you want to log anything useful. However, that's not always possible if something else is executing your code, such as Azure.

This may or may not be specific to the azure CLI and it's wrappers (such as `func`), but you can force the errors to show a stack trace if you set environment variable. People on the internet would not tell you how to do it, just say to "set it". The one example I found simply prefixed it before execution, which did not work for me. For PowerShell, all I had to do was this:
```
$env:CLI_DEBUG=1
```
Then you get that beautiful sweet stack trace. It's a bit verbose but much better than a vague error with no other information (eg a standalone line that says `Value cannot be null. (Parameter 'provider')` with 0 context).

This also helps a lot (`host.json`):
```
 "logLevel": {
    "default": "debug"
  },
```
This gives more log details about the resource states, which I find very helpful.


During logger initialization I think its good to try catch the logger init so you can get a stack trace in the console (for debug purposes). This is the way I format my errors so far:

```
try {
  ...
} catch (Exception e) {
    // Manually log error to console. Make it red since the log function doesnt do that for some reason.
    Console.ForegroundColor = ConsoleColor.Red;
    Console.Error.WriteLine($"[DEBUG] [ClassName.FuncName] Error: {e.Message}");
    Console.Error.WriteLine(e.StackTrace);
    Console.ResetColor();
    // Propogate
    throw e;
  }
```




# Structure

## Dependency injection

Normal injection with extra steps. To be added.

## Azure tingz

### Misc Facts
- You cannot use nested values in `local.settings.json`. It throws a repetitive warning (`I`)


#### Example `I`:
The repetitive errors are with regards to calls occurring from ` Newtonsoft.Json.Serialization.JsonSerializerInternalReader`.

Begins with this:
```
FirstFunction -> C:\Projects\FirstFunction\FirstFunction\bin\output\FirstFunction.dll
C:\Users\aosar\.nuget\packages\microsoft.net.sdk.functions\4.1.0\build\Microsoft.NET.Sdk.Functions.Build.targets(32,5): warning : Newtonsoft.Json.JsonReaderException: After parsing a value an unexpected character was encountered: ". Path 'Values.test_secret', line 11, position 2. [C:\Projects\FirstFunction\FirstFunction\FirstFunction.csproj]
```

Then repeats output like these three:
```
C:\Users\aosar\.nuget\packages\microsoft.net.sdk.functions\4.1.0\build\Microsoft.NET.Sdk.Functions.Build.targets(32,5): warning :    at Newtonsoft.Json.JsonTextReader.ParsePostValue(Boolean ignoreComments) [C:\Projects\FirstFunction\FirstFunction\FirstFunction.csproj]
C:\Users\aosar\.nuget\packages\microsoft.net.sdk.functions\4.1.0\build\Microsoft.NET.Sdk.Functions.Build.targets(32,5): warning :    at Newtonsoft.Json.JsonTextReader.Read() [C:\Projects\FirstFunction\FirstFunction\FirstFunction.csproj]
C:\Users\aosar\.nuget\packages\microsoft.net.sdk.functions\4.1.0\build\Microsoft.NET.Sdk.Functions.Build.targets(32,5): warning :    at Newtonsoft.Json.Serialization.JsonSerializerInternalReader.PopulateDictionary(IDictionary dictionary, JsonReader reader, JsonDictionaryContract contract, JsonProperty containerProperty, String id) [C:\Projects\FirstFunction\FirstFunction\FirstFunction.csproj]
```



```
[assembly: FunctionsStartup(typeof(Whatever.TestNamespace.Startup))]
namespace Whatever.TestNamespace
{
    public class Startup : FunctionsStartup
    {
      public override void Configure(IFunctionsHostBuilder builder)
      {
        ...
```

not sure if Startup is a keyword or not. Class implements `FunctionsStartup` interface, which needs an impl of `Configure` function that takes in a builder. F12 into that to see the argument options.
This seems to execute 

### Azure IFunctionsHostBuilder `builder`
`builder.Services`: need a lib to extend this functionality

### Debugging notes

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