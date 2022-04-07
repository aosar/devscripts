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