using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures interface specific settings.

.DESCRIPTION
    Configures interface specific settings.
    Run this command multiple times with different interface identifiers to configure multiple interfaces.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass to use.
    Valid values are:
    windowsPE
    specialize (default)

.PARAMETER InterfaceIdentifier
    Specifies the interface that settings should apply to.
    Can either be the friendly name like: "Ethernet" or the Mac address, like: "AA-AA-AA-AA-AA-AA"

.PARAMETER IpAddress
    The ip address to assign to the interface.
    Can be specified with or without the cidr notation.
    If the cidr notation is left out, Windows will use the class based system to guess the right subnet mask.

.PARAMETER DefaultGateway
    Specifies the default gateway the interface should use.

.PARAMETER Routes
    Specifies the custom routes to add to the interface.
    Use a hashtable with the following keys:
    Metric - a number that sets the priority for the route, the lower the number, the higher the priority.
    NextHopAddress - What the route should point to.
    Prefix - Specifies which destination IP addresses this route should apply to.
    For more information, see: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-tcpip-interfaces-interface-routes-route

.PARAMETER Ipv4InterfaceSettings
    Specifies ipv4 settings for the interface.
    Use a hashtable with the following keys:
    DhcpEnabled - a bool that controls whether or not DHCP is enabled on this interface.
    Metric - a number that sets the priority for the interface, the lower the number, the higher the priority.
    RouterDiscoveryEnabled - Specifies whether the router discovery protocol, which informs hosts of the existence of routers, is enabled.
    For more information, see: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-tcpip-interfaces-interface-ipv4settings

.PARAMETER Ipv6InterfaceSettings
    Specifies ipv6 settings for the interface.
    Use a hashtable with the following keys:
    DhcpEnabled - a bool that controls whether or not DHCP is enabled on this interface.
    Metric - a number that sets the priority for the interface, the lower the number, the higher the priority.
    RouterDiscoveryEnabled - Specifies whether the router discovery protocol, which informs hosts of the existence of routers, is enabled.
    For more information, see: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-tcpip-interfaces-interface-ipv6settings

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendInterfaceIpConfig
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
        [string[]]
        $IpAddress,

        [Parameter()]
        [ipaddress]
        $DefaultGateway,

        [Parameter()]
        [hashtable[]]
        $Routes,

        [Parameter()]
        [hashtable]
        $Ipv4InterfaceSettings,

        [Parameter()]
        [hashtable]
        $Ipv6InterfaceSettings
    )
    begin
    {
        if ($DefaultGateway)
        {
            $Routes += @{
                NextHopAddress = $DefaultGateway.ToString()
                Metric = 0
                Prefix = "0.0.0.0/0"
            }
        }
    }

    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TCPIP', $PassName)
            $InterfacesElement = $UnattendBuilder.GetOrCreateChildElement("Interfaces", $Component)
            $Interface = $InterfacesElement.AppendChild($UnattendBuilder.CreateElement("Interface", @{action = 'add'}))

            if ($Ipv4InterfaceSettings)
            {
                $SettingsElement = $Interface.AppendChild($UnattendBuilder.CreateElement('Ipv4Settings'))
                $UnattendBuilder.AddHashtableValuesToElement($Ipv4InterfaceSettings, $SettingsElement)
            }
            if ($Ipv6InterfaceSettings)
            {
                $SettingsElement = $Interface.AppendChild($UnattendBuilder.CreateElement('Ipv6Settings'))
                $UnattendBuilder.AddHashtableValuesToElement($Ipv6InterfaceSettings, $SettingsElement)
            }

            $UnattendBuilder.CreateAndAppendElement('Identifier', $InterfaceIdentifier, $Interface)

            if ($IpAddress)
            {
                $IpElement = $Interface.AppendChild($UnattendBuilder.CreateElement('UnicastIpAddresses'))
                $UnattendBuilder.AddSimpleListToElement($IpAddress, 'IpAddress', $IpElement)
            }

            if ($Routes)
            {
                $RoutesElement = $Interface.AppendChild($UnattendBuilder.CreateElement('Routes'))
                for ($i = 0; $i -lt $Routes.Count; $i++)
                {
                    $RouteItem = $RoutesElement.AppendChild($UnattendBuilder.CreateElement('Route', @{action = 'add'}))
                    $Table = $Routes[$i].Clone()
                    $Table.Add('Identifier', $i)
                    $UnattendBuilder.AddHashtableValuesToElement($Table, $RouteItem)
                }
            }
        }

        $UnattendBuilder
    }
}