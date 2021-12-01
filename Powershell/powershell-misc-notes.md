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