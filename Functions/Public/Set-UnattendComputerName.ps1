using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Sets the computer computer name to be set during installation.

.DESCRIPTION
    Sets the computer computer name to be set during installation.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    The pass that this command should apply to.
    Supported values are:
    offlineServicing
    specialize (default)

.PARAMETER ComputerName
    The computer name to set during installation.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendComputerName
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet("offlineServicing", "specialize")]
        [string[]]
        $Pass = "specialize",

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $PassName)
            $UnattendBuilder.SetElementValue('ComputerName', $ComputerName, $Component)
        }

        $UnattendBuilder
    }
}