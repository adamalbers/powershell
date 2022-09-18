# Accepts an object as input.
# Returns true if count = 1 and false if count = anything else.


# ----- DO NOT MODIFY BELOW THIS LINE ----- #
function Test-Unique {
     Param( [Parameter(Mandatory = $true)] $object )

     $count = ($object | Measure-Object).Count
     
     if ($count -eq 1) {
        return $true
     }

   return $false 
}