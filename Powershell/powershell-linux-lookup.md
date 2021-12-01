# PowerShell - Linux cheat sheet

View PS Version

| Linux Command | PS Command | PS Example |
| - | - | - |
| `grep` | `Select-String -Pattern` | `echo "abc" | Select-String -Pattern 'b'` |

Get-Location
is pwd

`-match`
This is a weird one.
```
$(cat file.txt) -match 'str'
```
outputs a string

```
'a string' -match 'str'
```
Outputs nothing, and populates the `$Matches` variable.

From docs:
-match and -notmatch support regex capture groups. Each time they run on scalar input, and the -match result is True, or the -notmatch result is False, they overwrite the $Matches automatic variable. **$Matches is a Hashtable that always has a key named '0'**, which stores the entire match. **If the regular expression contains capture groups, the $Matches contains additional keys for each group.**


Allow console output to go into variable (or somewhere):
```
$VarName = & command
# append 2>&1 to include error
```
https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.matchinfo?view=powershellsdk-7.0.0

Enter `\n` in string:
```
echo "Output string `n"
```