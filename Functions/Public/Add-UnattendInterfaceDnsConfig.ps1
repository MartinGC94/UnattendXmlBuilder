using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures DNS settings that are interface specific.

.DESCRIPTION
    Configures DNS settings that are interface specific.
    Run this command multiple times with different interface identifiers to add settings for multiple interfaces.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command should apply to.
    Valid values are:
    windowsPE
    specialize (Default)

.PARAMETER InterfaceIdentifier
    Specifies the interface that these settings should apply to.
    Can either be the friendly name like: "Ethernet" or the Mac address, like: "AA-AA-AA-AA-AA-AA"

.PARAMETER InterfaceDomain
    Specifies the DNS domain that should be used for connections out from the specified interface.
    If a global DNS domain has been set then that takes priority, and if nothing is found then the interface domain is used.

.PARAMETER EnableDynamicUpdate
    Specifies that A and PTR resource records are registered dynamically.

.PARAMETER DisableAdapterDomainRegistration
    Specifies that A and PTR resource records are not registered for this adapter.

.PARAMETER DnsServer
    Specifies a list of IP addresses to use when searching for the DNS server on the network.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendInterfaceDnsConfig
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

        [Parameter(Mandatory)]
        [string]
        $InterfaceIdentifier,

        [Parameter()]
        [string]
        $InterfaceDomain,

        [Parameter()]
        [switch]
        $EnableDynamicUpdate,

        [Parameter()]
        [switch]
        $DisableAdapterDomainRegistration,

        [Parameter()]
        [ipaddress[]]
        $DnsServer
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-DNS-Client', $PassName)
            $InterfacesElement = $UnattendBuilder.GetOrCreateChildElement("Interfaces", $Component)
            $Interface = $InterfacesElement.AppendChild($UnattendBuilder.CreateElement('Interface', @{action = 'add'}))

            switch ($PSBoundParameters.Keys)
            {
                'EnableDynamicUpdate'
                {
                    $UnattendBuilder.CreateAndAppendElement('DisableDynamicUpdate', !$EnableDynamicUpdate, $Interface)
                    continue
                }
                'InterfaceDomain'
                {
                    $UnattendBuilder.CreateAndAppendElement('DNSDomain', $InterfaceDomain, $Interface)
                    continue
                }
                'DisableAdapterDomainRegistration'
                {
                    $UnattendBuilder.CreateAndAppendElement('EnableAdapterDomainNameRegistration', !$DisableAdapterDomainRegistration, $Interface)
                    continue
                }
                'DnsServer'
                {
                    $DnsElement = $Interface.AppendChild($UnattendBuilder.CreateElement('DNSServerSearchOrder'))
                    $UnattendBuilder.AddSimpleListToElement($DnsServer, "IpAddress", $DnsElement)
                }
            }

            $UnattendBuilder.CreateAndAppendElement('Identifier', $InterfaceIdentifier, $Interface)
        }

        $UnattendBuilder
    }
}