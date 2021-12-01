# Alternative to `cat $FILE | grep $REGEX`
function SearchFileWithRegex {
  param (
    [string]$FILE,
    [string]$REGEX
  )
  $(Select-String -Path $FILE -Pattern $REGEX).Matches.ForEach({ $_.Value })
}

# (temp comment-uncomment section)
# ==== Function Calls ====
SearchFileWithRegex $Args[0] $Args[1]

# Example usage
# Use single quotes!!
#.\misc-funcs.ps1 ..\..\some-xml-file.xml '(?<=name="OpenRowset">)(\[\w*\]\.\[\w*\])(?=<\/property>)'