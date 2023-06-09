﻿using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures settings related to joining a domain or workgroup.

.DESCRIPTION
    Configures settings related to joining a domain or workgroup.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER OfflinePass
    Specifies that this should happen during the offline pass, otherwise it will happen during the specialization phase.

.PARAMETER UnsecureJoin
    Specifies whether to add the computer to the domain without requiring a unique password.
    UnsecureJoin is performed, by using a null session with a pre-existing account.
    This means there is no authentication to the domain controller when configuring the machine account; it is done anonymously.
    The account must have a well-known password or a specified value for MachinePassword.
    The well-known password is the first 14 characters of the computer name in lower case.

.PARAMETER AccountData
    Specifies the base64 string containing join details that has been generated by djoin.exe

.PARAMETER JoinCredential
    Specifies the credentials to use to join the domain.

.PARAMETER DomainName
    Specifies the name of the domain to join.

.PARAMETER WorkgroupName
    Specifies the workgroup name of the workgroup to join.

.PARAMETER DebugJoin
    Specifies a trigger to run the debugging routine if setup encounters an error code.
    This setting enables you to debug Windows Setup failures.

.PARAMETER DebugJoinError
    Specifies a particular error code that causes DebugJoin to trigger if encountered during Windows Setup.

.PARAMETER TargetOU
    Specifies the target OU to place the computer object in after the domain join.

.PARAMETER MachinePassword
    MachinePassword is used with UnsecureJoin, which is performed by using a null session with a pre-existing account.
    This means there is no authentication to the domain controller when configuring the computer account.
    It is done anonymously.
    The account must have a well-known password or a specified MachinePassword.
    The well-known password is the first 14 characters of the computer name in lowercase.

.PARAMETER TimeoutInMinutes
    Specifies how long Windows will wait until it gives up joining the domain.
    Valid values are between 5 and 60 minutes.
    Default is 15 minutes.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendDomainJoinInfo
{
    [CmdletBinding(DefaultParameterSetName = 'Workgroup', PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(Mandatory, ParameterSetName = 'DomainJoinOfflinePass')]
        [switch]
        $OfflinePass,

        [Parameter(Mandatory, ParameterSetName = 'UnsecureDomainJoin')]
        [switch]
        $UnsecureJoin,

        [Parameter(Mandatory, ParameterSetName = 'DomainJoinOfflinePass')]
        [Parameter(Mandatory, ParameterSetName = 'DomainJoinPreprovisioned')]
        [string]
        $AccountData,

        [Parameter(Mandatory, ParameterSetName = 'DomainJoin')]
        [pscredential]
        $JoinCredential,

        [Parameter(Mandatory, ParameterSetName = 'DomainJoinPreprovisioned')]
        [Parameter(Mandatory, ParameterSetName = 'DomainJoin')]
        [Parameter(Mandatory, ParameterSetName = 'UnsecureDomainJoin')]
        [string]
        $DomainName,

        [Parameter(ParameterSetName = 'Workgroup')]
        [string]
        $WorkgroupName,

        [Parameter(ParameterSetName = 'DomainJoinPreprovisioned')]
        [Parameter(ParameterSetName = 'DomainJoin')]
        [Parameter(ParameterSetName = 'UnsecureDomainJoin')]
        [switch]
        $DebugJoin,

        [Parameter(ParameterSetName = 'DomainJoinPreprovisioned')]
        [Parameter(ParameterSetName = 'DomainJoin')]
        [Parameter(ParameterSetName = 'UnsecureDomainJoin')]
        [string]
        $DebugJoinError,

        [Parameter(ParameterSetName = 'DomainJoinPreprovisioned')]
        [Parameter(ParameterSetName = 'DomainJoin')]
        [Parameter(ParameterSetName = 'UnsecureDomainJoin')]
        [string]
        $TargetOU,

        [Parameter(Mandatory, ParameterSetName = 'UnsecureDomainJoin')]
        [string]
        $MachinePassword,

        [Parameter(ParameterSetName = 'DomainJoinPreprovisioned')]
        [Parameter(ParameterSetName = 'DomainJoin')]
        [Parameter(ParameterSetName = 'UnsecureDomainJoin')]
        [ValidateRange(5, 60)]
        [int]
        $TimeoutInMinutes
    )
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'DomainJoinOfflinePass')
        {
            $PassName = 'offlineServicing'
            $ChildElementName = 'OfflineIdentification'
        }
        else
        {
            $PassName = 'specialize'
            $ChildElementName = 'Identification'
        }

        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-UnattendedJoin', $PassName)
        $IdentificationElement = $UnattendBuilder.GetOrCreateChildElement($ChildElementName, $Component)

        switch ($PSBoundParameters.Keys)
        {
            'UnsecureJoin'
            {
                $UnattendBuilder.SetElementValue('UnsecureJoin', $UnsecureJoin, $IdentificationElement)
                continue
            }
            'AccountData'
            {
                $ProvisioningElement = $UnattendBuilder.GetOrCreateChildElement('Provisioning', $IdentificationElement)
                $UnattendBuilder.SetElementValue('AccountData', $AccountData, $ProvisioningElement)
                continue
            }
            'JoinCredential'
            {
                $UnattendBuilder.SetCredentialOnElement($JoinCredential, $IdentificationElement)
                continue
            }
            'DomainName'
            {
                $UnattendBuilder.SetElementValue('JoinDomain', $DomainName, $IdentificationElement)
                continue
            }
            'WorkgroupName'
            {
                $UnattendBuilder.SetElementValue('JoinWorkgroup', $WorkgroupName, $IdentificationElement)
                continue
            }
            'DebugJoin'
            {
                $UnattendBuilder.SetElementValue('DebugJoin', $DebugJoin, $IdentificationElement)
                continue
            }
            'DebugJoinError'
            {
                $UnattendBuilder.SetElementValue('DebugJoinOnlyOnThisError', $DebugJoinError, $IdentificationElement)
                continue
            }
            'TargetOU'
            {
                $UnattendBuilder.SetElementValue('MachineObjectOU', $TargetOU, $IdentificationElement)
                continue
            }
            'MachinePassword'
            {
                $UnattendBuilder.SetElementValue('MachinePassword', $MachinePassword, $IdentificationElement)
                continue
            }
            'TimeoutInMinutes'
            {
                $UnattendBuilder.SetElementValue('TimeoutPeriodInMinutes', $TimeoutInMinutes, $IdentificationElement)
                continue
            }
        }

        $UnattendBuilder
    }
}