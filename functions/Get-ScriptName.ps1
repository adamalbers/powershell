# Used in some scripts to make sure they don't call on themselves.
# For example, the importAllFunctions.ps1 should not import itself.

function Get-ScriptName {
    return $myInvocation.ScriptName
}