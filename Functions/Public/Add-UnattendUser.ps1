using module ..\..\Classes\UnattendBuilder.psm1
using namespace System
using namespace System.Management.Automation
<#
.SYNOPSIS
    Adds local accounts to the machine and optionally adds them to groups.

.DESCRIPTION
    Adds local accounts to the machine and optionally adds them to groups.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass where the account should be added.
    Valid values are:
    offlineServicing
    auditSystem
    oobeSystem (default)

.PARAMETER LocalAdmin
    Specifies that you are setting the local admin password.

.PARAMETER Name
    Specifies the name of the user to create.

.PARAMETER Password
    Specifies the password to set for the local account.
    If a name is not specified then this will set the local admin password.

.PARAMETER DisplayName
    Specifies a displayname for the new local account.

.PARAMETER Group
    Specifies the groups local account should be added to.

.PARAMETER Description
    Specifies a description for the new local account.

.PARAMETER PasswordAsPlainText
    Specifies that the PW should be stored as plaintext in the unattend file.

.PARAMETER SkipPasswordEncoding
    Skips encoding the PW for the unattend file. Useful if you want to add a PW that has already been encoded.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendUser
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('offlineServicing', 'auditSystem', 'oobeSystem')]
        [string]
        $Pass = 'oobeSystem',

        [Parameter(Mandatory, ParameterSetName = 'LocalAdmin')]
        [switch]
        $LocalAdmin,

        [Parameter(Mandatory, ParameterSetName = 'LocalUser')]
        [string[]]
        $Name,

        [Parameter(ParameterSetName = 'LocalUser')]
        [Parameter(Mandatory, ParameterSetName = 'LocalAdmin')]
        [AllowEmptyString()]
        [string]
        $Password,

        [Parameter(ParameterSetName = 'LocalUser')]
        [string]
        $DisplayName,

        [Parameter(ParameterSetName = 'LocalUser')]
        [string[]]
        $Group,

        [Parameter(ParameterSetName = 'LocalUser')]
        [string]
        $Description,

        [Parameter()]
        [switch]
        $PasswordAsPlainText,

        [Parameter()]
        [switch]
        $SkipPasswordEncoding
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $Pass)
        if ($LocalAdmin)
        {
            if ($Pass -eq 'offlineServicing')
            {
                $UserAccounts = $UnattendBuilder.GetOrCreateChildElement('OfflineUserAccounts', $Component)
                $AdminElement = $UnattendBuilder.GetOrCreateChildElement('OfflineAdministratorPassword', $UserAccounts)
            }
            else
            {
                $UserAccounts = $UnattendBuilder.GetOrCreateChildElement('UserAccounts', $Component)
                $AdminElement = $UnattendBuilder.GetOrCreateChildElement('AdministratorPassword', $UserAccounts)
            }

            $PW = if ($PasswordAsPlainText -or $SkipPasswordEncoding -or [string]::IsNullOrEmpty($Password))
            {
                $Password
            }
            else
            {
                if ($Pass -eq 'offlineServicing')
                {
                    EncodeUnattendPassword -Password $Password -Kind OfflineLocalAdmin
                }
                else
                {
                    EncodeUnattendPassword -Password $Password -Kind LocalAdmin
                }
            }

            $UnattendBuilder.SetElementValue('Value', $PW, $AdminElement)
            $UnattendBuilder.SetElementValue('PlainText', $PasswordAsPlainText, $AdminElement)
        }
        else
        {
            if ($Pass -eq 'offlineServicing')
            {
                $UserAccounts = $UnattendBuilder.GetOrCreateChildElement('OfflineUserAccounts', $Component)
                $LocalAccounts = $UnattendBuilder.GetOrCreateChildElement("OfflineLocalAccounts", $UserAccounts)
            }
            else
            {
                $UserAccounts = $UnattendBuilder.GetOrCreateChildElement('UserAccounts', $Component)
                $LocalAccounts = $UnattendBuilder.GetOrCreateChildElement("LocalAccounts", $UserAccounts)
            }

            foreach ($UserName in $Name)
            {
                $NewAccount = $LocalAccounts.AppendChild($UnattendBuilder.CreateElement('LocalAccount', @{action = 'add'}))
                switch ($PSBoundParameters.Keys)
                {
                    'Description'
                    {
                        $UnattendBuilder.CreateAndAppendElement('Description', $Description, $NewAccount)
                        continue
                    }
                    'DisplayName'
                    {
                        $UnattendBuilder.CreateAndAppendElement('DisplayName', $DisplayName, $NewAccount)
                        continue
                    }
                    'Group'
                    {
                        $UnattendBuilder.CreateAndAppendElement('Group', $Group -join ';', $NewAccount)
                        continue
                    }
                    'Name'
                    {
                        $UnattendBuilder.CreateAndAppendElement('Name', $UserName, $NewAccount)
                        continue
                    }
                    'Password'
                    {
                        $PasswordElement = $NewAccount.AppendChild($UnattendBuilder.CreateElement('Password'))
                        $PW = if ($PasswordAsPlainText -or $SkipPasswordEncoding -or [string]::IsNullOrEmpty($Password))
                        {
                            $Password
                        }
                        else
                        {
                            EncodeUnattendPassword -Password $Password -Kind UserAccount
                        }
                        $UnattendBuilder.CreateAndAppendElement('Value', $PW, $PasswordElement)
                        $UnattendBuilder.CreateAndAppendElement('PlainText', $PasswordAsPlainText, $PasswordElement)
                        continue
                    }
                }
            }
        }

        $UnattendBuilder
    }
}