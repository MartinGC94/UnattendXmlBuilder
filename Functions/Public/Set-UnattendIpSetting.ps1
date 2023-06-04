using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures global IP settings.

.DESCRIPTION
    Configures global IP settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass to use.
    Valid values are:
    windowsPE
    specialize (default)

.PARAMETER DisableIcmpRedirects
    Specifies that the IPv4 and IPv6 path caches are not updated in response to ICMP redirect messages.
    This is a global setting that applies to all interfaces.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendIpSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('windowsPE', 'specialize')]
        [string[]]
        $Pass = 'specialize',

        [Parameter()]
        [switch]
        $DisableIcmpRedirects
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TCPIP', $PassName)

            if ($PSBoundParameters.ContainsKey('DisableIcmpRedirects'))
            {
                $UnattendBuilder.SetElementValue('IcmpRedirectsEnabled', !$DisableIcmpRedirects, $Component)
            }
        }

        $UnattendBuilder
    }
}