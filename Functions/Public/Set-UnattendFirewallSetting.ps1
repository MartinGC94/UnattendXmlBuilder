using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures firewall settings.

.DESCRIPTION
    Configures firewall settings, these firewall settings apply to the installed OS, not WinPE.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER DisableStatefulFTP
    Disables the FTP inspection engine.
    On server editions this is turned on by default, and setting this switch will disable it.
    On client editions this is turned off by default, but can be enabled by setting this switch to false: -DisableStatefulFTP:$false

.PARAMETER DisableStatefulPPTP
    Disables the point to point tunneling inspection.
    On server editions this is turned on by default, and setting this switch will disable it.
    On client editions this is turned off by default, but can be enabled by setting this switch to false: -DisableStatefulPPTP:$false

.PARAMETER FirewallProfile
    Specifies the firewall profile the profile specific settings should apply to.

.PARAMETER DisableFirewall
    Disables the specified firewall profile.

.PARAMETER DisableNotifications
    Disables notifications about programs being blocked.

.PARAMETER LogDroppedPackets
    Enables logging of dropped packets.

.PARAMETER LogSuccessfulConnections
    Enables logging of allowed connections, by default only dropped connections are logged.

.PARAMETER LogFilePath
    Specifies the filepath of the logfile for this profile.

.PARAMETER LogFileSizeKB
    Specifies how big the logfile can be.

.PARAMETER EnabledFirewallGroups
    Specifies the firewall groups to enable.
    Firewall group names can be found with this command: Get-NetFirewallRule | select Name,DisplayName,Group

.PARAMETER DisabledFirewallGroups
    Specifies the firewall groups to disable.
    Firewall group names can be found with this command: Get-NetFirewallRule | select Name,DisplayName,Group

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendFirewallSetting
{
    [CmdletBinding(DefaultParameterSetName = 'GlobalSettings', PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(ParameterSetName = "GlobalSettings")]
        [Parameter(ParameterSetName = "ProfileSpecific")]
        [switch]
        $DisableStatefulFTP,

        [Parameter(ParameterSetName = "GlobalSettings")]
        [Parameter(ParameterSetName = "ProfileSpecific")]
        [switch]
        $DisableStatefulPPTP,

        [Parameter(Mandatory, ParameterSetName = "ProfileSpecific")]
        [ValidateSet("Domain", 'Private', 'Public', 'All')]
        [string]
        $FirewallProfile,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [switch]
        $DisableFirewall,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [switch]
        $DisableNotifications,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [switch]
        $LogDroppedPackets,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [switch]
        $LogSuccessfulConnections,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [string]
        $LogFilePath,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [int]
        $LogFileSizeKB,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [string[]]
        $EnabledFirewallGroups,

        [Parameter(ParameterSetName = "ProfileSpecific")]
        [string[]]
        $DisabledFirewallGroups
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Networking-MPSSVC-Svc', 'specialize')
        if ($EnabledFirewallGroups -or $DisabledFirewallGroups)
        {
            $GroupsElement = $UnattendBuilder.GetOrCreateChildElement('FirewallGroups', $Component)
            $FwCommonParams = @{
                UnattendBuilder = $UnattendBuilder
                Parent          = $GroupsElement
                FirewallProfile = $FirewallProfile.ToLower()
            }
            if ($EnabledFirewallGroups)
            {
                AddFirewallGroupsToElement @FwCommonParams -GroupNames $EnabledFirewallGroups -Active $true
            }
            if ($DisabledFirewallGroups)
            {
                AddFirewallGroupsToElement @FwCommonParams -GroupNames $DisabledFirewallGroups -Active $false
            }
        }

        if ($PSBoundParameters.ContainsKey('DisableStatefulFTP'))
        {
            $UnattendBuilder.SetElementValue('DisableStatefulFTP', $DisableStatefulFTP, $Component)
        }
        if ($PSBoundParameters.ContainsKey('DisableStatefulPPTP'))
        {
            $UnattendBuilder.SetElementValue('DisableStatefulPPTP', $DisableStatefulPPTP, $Component)
        }

        $FwProfiles = if ($FirewallProfile -eq "All")
        {
            "Domain", 'Private', 'Public'
        }
        else
        {
            $FirewallProfile
        }

        foreach ($Item in $FwProfiles)
        {
            switch ($PSBoundParameters.Keys)
            {
                'DisableFirewall'
                {
                    $UnattendBuilder.SetElementValue("${Item}Profile_EnableFirewall", !$DisableFirewall, $Component)
                    continue
                }
                'DisableNotifications'
                {
                    $UnattendBuilder.SetElementValue("${Item}Profile_DisableNotifications", $DisableNotifications, $Component)
                    continue
                }
                'LogDroppedPackets'
                {
                    $UnattendBuilder.SetElementValue("${Item}Profile_LogDroppedPackets", $LogDroppedPackets, $Component)
                    continue
                }
                'LogSuccessfulConnections'
                {
                    $UnattendBuilder.SetElementValue("${Item}Profile_LogSuccessfulConnections", $LogSuccessfulConnections, $Component)
                    continue
                }
                'LogFilePath'
                {
                    $UnattendBuilder.SetElementValue("${Item}Profile_LogFile", $LogFilePath, $Component)
                    continue
                }
                'LogFileSizeKB'
                {
                    $UnattendBuilder.SetElementValue("${Item}Profile_LogFileSize", $LogFileSizeKB, $Component)
                    continue
                }
            }
        }

        $UnattendBuilder
    }
}