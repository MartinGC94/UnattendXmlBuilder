using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures time settings.

.DESCRIPTION
    Configures time settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command should apply to.
    Supported values:
    specialize (default)
    auditSystem
    oobeSystem

.PARAMETER TimeZone
    The ID of the timezone to set during installation.
    The available timzones can be listed with the following PS command: [System.TimeZoneInfo]::GetSystemTimeZones()

.PARAMETER DisableAutoDaylight
    Specifies that daylight savings should not be applied automatically by Windows.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendTimeSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet("specialize", "auditSystem", "oobeSystem")]
        [string[]]
        $Pass = "specialize",

        [Parameter()]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $TrimmedWord = $wordToComplete.Trim(("'",'"'))

            foreach ($Timezone in [System.TimeZoneInfo]::GetSystemTimeZones())
            {
                if ($Timezone.Id -like "$TrimmedWord*")
                {
                    $CompletionText = "'$($Timezone.Id)'"
                    $ListItemText   = $Timezone.Id
                    $ResultType     = [System.Management.Automation.CompletionResultType]::ParameterValue
                    $ToolTip        = $Timezone.DisplayName
                    [System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
                }
            }
        })]
        [string]
        $TimeZone,

        [Parameter()]
        [switch]
        $DisableAutoDaylight
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $PassName)
            switch ($PSBoundParameters.Keys)
            {
                'TimeZone'
                {
                    $UnattendBuilder.SetElementValue('TimeZone', $TimeZone, $Component)
                    continue
                }
                'DisableAutoDaylight'
                {
                    $UnattendBuilder.SetElementValue('DisableAutoDaylightTimeSet', $DisableAutoDaylight, $Component)
                    continue
                }
            }
        }

        $UnattendBuilder
    }
}