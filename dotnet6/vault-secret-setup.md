# Auth management

## Key Vault Access

Note: words preceding arrows are defining resource menus in the azure web portal

### 1 - Generate secret and grab identifier
Key vault resource > Settings.Secrets, generate

You may have different versions of secrets (eg dev/prod)
Note Secret Identifier for later use (a url with the key version ID appended to the end)

### 2 - Enable identity management ("client" resource)
Function App rsrc > Identity
- Toggle status = on
- Enable system assigned managed identity
- Connect to vault without API key
- warning: func will be registered with Azure AD. func can be granted permissions to access resources protected by Azure AD. Do you want to enable the system assigned managed identity for ‘osar-dev-cs-func’?

### 3 - Enable Access Policy ("host" resource)
(Only available on key vault?)
Key Vault rsrc > Access Policies
- + Add Access Policy
- Search principal for our function name. It has a uuid. I cannot figure out for the life of me what that ID that shows up is, because its not the principal ID or the function object ID. After adding it shows an "Object ID" which shows up as princpial ID. Can view with this:
```
az functionapp list | jq '.[] | select(.repositorySiteName=="osar-dev-cs-func")'.identity.principalId
```
- note: could be inaccurate since I was in the middle of adding the policy

### 4 - Add secret to key vault

### 5 - Add key vault reference to function config

Func App resrc > Configuration > Application Settings [selected by default]
- @Microsoft.KeyVault(SecretUri="<url>")

** Note: Vault item name is separate from the value that the application accesses.


Vault access gets set up in the web portal under function settings. It is analagous to local.settings.json, as we don't push those settings. Contents would be accessed in the same way.
This format of reference will not work on a local instance.


## Fressh install
** fresh ss install **

Key: all but blobs_extensions works for auth on ricks debug function, which uses function permissions.

RickFunc > Authentication, can view ID Provider there
https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/186aaf49-fa38-429a-b171-4f087299e9ed

Application (client) ID section corresponds to the menu where it says to select a principal. This is in Key Vault > Access Policy > Add Access Policy.

Note: you CANNOT enter a partial ID or it will not find it.

View on the CLI as:
```
az ad sp list --filter "displayname eq 'RickHTTPTrigger1'" | jq .[0].appId
```
It is also in the URL.


## Az Function Access from Logic App

### 1 - Enable Identity Management on Logic App
Logic App > Identity
- Toggle switch on and save to generate principal ID

### 2 - Use Managed Identity on HTTP Request in workflow
- Create a new step (HTTP)
- Get the URI of the function (tba)
- Add parameter > Authentication
- Select Authentication type = Managed Identity

Alternative: Use AZ Resource manager step

### 3 - Add authorization

 uhhh I enabled CORS idk if that needs to get turned back off...


## Local Az Vault Access from .NET Project
