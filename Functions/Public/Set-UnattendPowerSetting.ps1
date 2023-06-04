using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures power settings.

.DESCRIPTION
    Configures power settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass the command should apply to.
    Supported values are:
    generalize
    specialize (default)

.PARAMETER PowerPlan
    The GUID of the powerplan that should be set

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendPowerSetting
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
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $TrimmedWord = $wordToComplete.Trim(("'",'"'))
            $PowerplanTable = @{
                PowerSaver          = 'a1841308-3541-4fab-bc81-f71556f20b4a'
                Balanced            = '381b4222-f694-41f0-9685-ff5bb260df2e'
                HighPerformance     = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                UltimatePerformance = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
            }
            foreach ($Key in $PowerplanTable.Keys)
            {
                if ($Key -like "$TrimmedWord*")
                {
                    $CompletionText = $PowerplanTable[$Key]
                    $ListItemText   = $Key
                    $ResultType     = [System.Management.Automation.CompletionResultType]::ParameterValue
                    $ToolTip        = $Key
                    [System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
                }
            }
        })]
        [guid]
        $PowerPlan
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-powercpl', $PassName)
            $UnattendBuilder.SetElementValue('PreferredPlan', $PowerPlan.Guid, $Component)
        }

        $UnattendBuilder
    }
}