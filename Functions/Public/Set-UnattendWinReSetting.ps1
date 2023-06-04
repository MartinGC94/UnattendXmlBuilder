using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures Windows RE settings.

.DESCRIPTION
    Configures Windows Recovery Environment settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER UninstallWindowsRE
    Uninstalls the recovery environment during OOBE.
    This can be used to save disk space (Typically, about 500MB) on systems where recovery options aren't needed.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendWinReSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(Mandatory)]
        [switch]
        $UninstallWindowsRE
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-WinRE-RecoveryAgent', 'oobeSystem')
        $UnattendBuilder.SetElementValue('UninstallWindowsRE', $UninstallWindowsRE, $Component)
        $UnattendBuilder
    }
}