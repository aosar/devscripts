# Auth management

Note: words preceding arrows are defining resource menus in the azure web portal

### 1 - Generate secret and grab identifier
Key vault resource > Settings.Secrets, generate

You may have different versions of secrets (eg dev/prod)
Note Secret Identifier for later use (a url with the key version ID appended to the end)

### 2 - Enable identity management
Function App rsrc > Identity
- Toggle status = on
- Enable system assigned managed identity
- Connect to vault without API key
- warning: func will be registered with Azure AD. func can be granted permissions to access resources protected by Azure AD. Do you want to enable the system assigned managed identity for ‘osar-dev-cs-func’?

### 3 - Manage policy
Key Vault rsrc > Access Policies
- + Add Access Policy
- Search principal for our function name. It has a uuid. I cannot figure out for the life of me what that ID that shows up is, because its not the principal ID or the function object ID. After adding it shows an "Object ID" which shows up as princpial ID. Can view with this:
```
az functionapp list | jq '.[] | select(.repositorySiteName=="osar-dev-cs-func")'.identity.principalId
```
- note: could be inaccurate since I was in the middle of adding the policy

### 4 - Add secret to key vault

Func App resrc > Configuration > Application Settings [selected by default]
- @Microsoft.KeyVault(SecretUri="<url>")

** Note: Vault item name is separate from the value that the application accesses.


Vault access gets set up in the web portal under function settings. It is analagous to local.settings.json, as we don't push those settings. Contents would be accessed in the same way.