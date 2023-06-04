using module ..\..\Classes\UnattendBuilder.psm1
using module ..\..\Classes\RdpSecurityLayer.psm1
<#
.SYNOPSIS
    Configures RDP settings.

.DESCRIPTION
    Configures RDP settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this should apply to.
    Valid values are:
    offlineServicing
    generalize
    specialize (default)

.PARAMETER EnableRDP
    Enables RDP connections to this computer.

.PARAMETER AllowArbitraryRemoteApps
    Allows remote users to launch remote apps that haven't been explicitly whitelisted on this computer.

.PARAMETER DisableNLA
    Disables Network Level Authentication when connecting to this computer.

.PARAMETER SecurityLayer
    Sets the security layer used when connecting to this computer.
    Valid values are:
    RDP - The RDP protocol is used.
    Negotiate - Client and server negotiates the most secure protocol supported by both.
    TLS - Forces the protocol to use TLS.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendRdpSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('offlineServicing', 'generalize', 'specialize')]
        [string[]]
        $Pass = 'specialize',

        [Parameter()]
        [switch]
        $EnableRDP,

        [Parameter()]
        [switch]
        $AllowArbitraryRemoteApps,

        [Parameter()]
        [switch]
        $DisableNLA,

        [Parameter()]
        [RdpSecurityLayer]
        $SecurityLayer
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            switch ($PSBoundParameters.Keys)
            {
                'EnableRDP'
                {
                    $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TerminalServices-LocalSessionManager', $PassName)
                    $UnattendBuilder.SetElementValue('fDenyTSConnections', !$EnableRDP, $Component)
                    continue
                }
                'AllowArbitraryRemoteApps'
                {
                    $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TerminalServices-Publishing-WMIProvider', $PassName)
                    $UnattendBuilder.SetElementValue('fDisabledAllowList', $AllowArbitraryRemoteApps, $Component)
                    continue
                }
                'DisableNLA'
                {
                    if ($PassName -ne "offlineServicing")
                    {
                        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TerminalServices-RDP-WinStationExtensions', $PassName)
                        $UnattendBuilder.SetElementValue('UserAuthentication', (!$DisableNLA).ToInt32($null), $Component)
                    }
                    else
                    {
                        Write-Warning -Message "$_ cannot be set in offlineServicing pass. Ignoring it for this pass."
                    }

                    continue
                }
                'SecurityLayer'
                {
                    if ($PassName -ne "offlineServicing")
                    {
                        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TerminalServices-RDP-WinStationExtensions', $PassName)
                        $UnattendBuilder.SetElementValue('SecurityLayer', $SecurityLayer.value__, $Component)
                    }
                    else
                    {
                        Write-Warning -Message "$_ cannot be set in offlineServicing pass. Ignoring it for this pass."
                    }

                    continue
                }
            }
        }

        $UnattendBuilder
    }
}