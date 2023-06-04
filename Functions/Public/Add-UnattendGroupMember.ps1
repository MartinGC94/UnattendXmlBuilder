using module ..\..\Classes\UnattendBuilder.psm1
using namespace System
using namespace System.Management.Automation
<#
.SYNOPSIS
    Adds domain accounts to one or more groups.

.DESCRIPTION
    Adds domain accounts to one or more groups.
    Local accounts can be added to groups while creating them with "Add-UnattendAccount".

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass where the account should be added.
    Valid values are:
    offlineServicing
    auditSystem
    oobeSystem (default)

.PARAMETER DomainName
    Specifies the name of the domain where the domain account is located.

.PARAMETER Name
    Specifies the domain user or group name to add to a group.

.PARAMETER SID
    Specifies the SID of the domain user or group to add to a group.

.PARAMETER Group
    Specifies the groups the domain account should be added to.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendGroupMember
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(ParameterSetName = 'DomainAccount')]
        [ValidateSet('auditSystem', 'oobeSystem')]
        [string]
        $Pass = 'oobeSystem',

        [Parameter(Mandatory, ParameterSetName = 'DomainAccount')]
        [string]
        $DomainName,

        [Parameter(Mandatory, ParameterSetName = 'DomainAccount')]
        [string[]]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'OfflineDomainAccount')]
        [string[]]
        $SID,

        [Parameter(Mandatory)]
        [string[]]
        $Group
    )
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'OfflineDomainAccount')
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', 'offlineServicing')
            $UserAccountsElement = $UnattendBuilder.GetOrCreateChildElement('OfflineUserAccounts', $Component)
            $DomainAccountsElement = $UnattendBuilder.GetOrCreateChildElement('OfflineDomainAccounts', $UserAccountsElement)
            foreach ($User in $SID)
            {
                $NewAccount = $DomainAccountsElement.AppendChild($UnattendBuilder.CreateElement('OfflineDomainAccount', @{action = 'add'}))
                $UnattendBuilder.CreateAndAppendElement('SID', $User, $NewAccount)
                $UnattendBuilder.CreateAndAppendElement('Group', $Group -join ';', $NewAccount)
            }

        }
        else
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $Pass)
            $UserAccountsElement = $UnattendBuilder.GetOrCreateChildElement('UserAccounts', $Component)
            $DomainAccountsElement = $UnattendBuilder.GetOrCreateChildElement('DomainAccounts', $UserAccountsElement)
            $DomainElement = $UnattendBuilder.GetChildElementFromXpath("./DomainAccountList/Domain/text()[. = '$DomainName']/../..", $DomainAccountsElement)
            if ($null -eq $DomainElement)
            {
                $DomainElement = $DomainAccountsElement.AppendChild($UnattendBuilder.CreateElement("DomainAccountList", @{action = 'add'}))
                $UnattendBuilder.CreateAndAppendElement("Domain", $DomainName, $DomainElement)
            }
            $NewAccount = $DomainElement.AppendChild($UnattendBuilder.CreateElement('DomainAccount', @{action = 'add'}))
            $UnattendBuilder.CreateAndAppendElement('Name', $Name, $NewAccount)
            $UnattendBuilder.CreateAndAppendElement('Group', $Group -join ';', $NewAccount)
        }

        $UnattendBuilder
    }
}