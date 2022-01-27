param (
    [switch]$IsDev
  )

# prevent scoping issue in for loop
$MainCallArgs=$Args
$DEV_PREFIX = '\\'
$PREFIX = '\\'

if ($IsDev) {
  $PREFIX = $DEV_PREFIX
}

@(
  '\Subpath\Filename.dtsx'
) |
ForEach-Object {
  echo "======== Data for ${_} ========"
    # TODO better path joining & arg passthrough
  .\parse-conn-str.ps1 "${PREFIX}${_}" $MainCallArgs[0] $MainCallArgs[1]
}