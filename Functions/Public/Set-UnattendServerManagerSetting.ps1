using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures server manager settings.

.DESCRIPTION
    Configures server manager settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command should apply to.
    Supported values:
    generalize
    specialize (default)

.PARAMETER DontOpenServerManagerAtLogon
    Stops server manager from opening by default when a user logs on.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendServerManagerSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('generalize', 'specialize')]
        [string[]]
        $Pass = 'specialize',

        [Parameter(Mandatory)]
        [switch]
        $DontOpenServerManagerAtLogon
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-ServerManager-SvrMgrNc', $PassName)
            $UnattendBuilder.SetElementValue('DoNotOpenServerManagerAtLogon', $DontOpenServerManagerAtLogon, $Component)
        }

        $UnattendBuilder
    }
}