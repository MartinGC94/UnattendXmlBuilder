using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures UAC settings.

.DESCRIPTION
    Configures User Account Control settings (previously known as Limited User Account).

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER DisableUAC
    Disables UAC.
    Disabling UAC means that any program run by privileged accounts will run elevated without any prompt, even if "Run As Administrator" is not chosen by the user.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendUacSetting
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
        $DisableUAC
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-LUA-Settings', "offlineServicing")
        $UnattendBuilder.SetElementValue('EnableLUA', !$DisableUAC, $Component)
        $UnattendBuilder
    }
}