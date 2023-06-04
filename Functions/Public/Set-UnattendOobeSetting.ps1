using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures settings related to the OOBE.

.DESCRIPTION
    Configures settings related to the Out Of Box Experience.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER HideEula
    Skips the EULA page (With the implication that you accept the EULA)

.PARAMETER HideLocalAccount
    Skips the page to set the password for the Administrator account on server editions.

.PARAMETER HideOem
    Skips any OEM specific page.

.PARAMETER HideOnlineAccount
    Skips the online account sign in/creation screen.

.PARAMETER HideNetworkSetup
    Skips the network setup page.

.PARAMETER UseExpressSettings
    Skips the pages related to express settings.
    When this switch is set, express settings will be turned on, and the page will be skipped.
    When this switch is explicitly turned off (by specifying the parameter like this: -UseExpressSettings:$false)
    Express settings will be turned off, and the page will be skipped.
    If this is not set then the page will be shown during OOBE.

.PARAMETER SkipMachineOOBE
    Is supposedly deprecated but skips the OOBE.

.PARAMETER SkipUserOOBE
    Is supposedly deprecated but skips the OOBE.

.PARAMETER NetworkLocation
    Sets the network location.
    Valid values are:
    Home
    Work
    Other

.PARAMETER SkipAdminProfileRemoval
    Skip removing the default administrator account profile.

.PARAMETER SkipLanguageChange
    Skips notifying windows about language changes during the OOBE.

.PARAMETER SkipWinReInitialization
    Skips setting up Win RE during the OOBE.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendOobeSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [switch]
        $HideEula,

        [Parameter()]
        [switch]
        $HideLocalAccount,

        [Parameter()]
        [switch]
        $HideOem,

        [Parameter()]
        [switch]
        $HideOnlineAccount,

        [Parameter()]
        [switch]
        $HideNetworkSetup,

        [Parameter()]
        [switch]
        $UseExpressSettings,

        [Parameter()]
        [switch]
        $SkipMachineOOBE,

        [Parameter()]
        [switch]
        $SkipUserOOBE,

        [Parameter()]
        [ValidateSet('Home', 'Work', 'Other')]
        [string]
        $NetworkLocation,

        [Parameter()]
        [switch]
        $SkipAdminProfileRemoval,

        [Parameter()]
        [switch]
        $SkipLanguageChange,

        [Parameter()]
        [switch]
        $SkipWinReInitialization
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', 'oobeSystem')
        $OOBE = $UnattendBuilder.GetOrCreateChildElement('OOBE', $Component)
        switch ($PSBoundParameters.Keys)
        {
            'HideEula'
            {
                $UnattendBuilder.SetElementValue('HideEULAPage', $HideEula, $OOBE)
                continue
            }
            'HideLocalAccount'
            {
                $UnattendBuilder.SetElementValue('HideLocalAccountScreen', $HideLocalAccount, $OOBE)
                continue
            }
            'HideOem'
            {
                $UnattendBuilder.SetElementValue('HideOEMRegistrationScreen', $HideOem, $OOBE)
                continue
            }
            'HideOnlineAccount'
            {
                $UnattendBuilder.SetElementValue('HideOnlineAccountScreens', $HideOnlineAccount, $OOBE)
                continue
            }
            'HideNetworkSetup'
            {
                $UnattendBuilder.SetElementValue('HideWirelessSetupInOOBE', $HideNetworkSetup, $OOBE)
                continue
            }
            'UseExpressSettings'
            {
                $Value = if ($UseExpressSettings)
                {
                    1
                }
                else
                {
                    3
                }
                $UnattendBuilder.SetElementValue('ProtectYourPC', $Value, $OOBE)
                continue
            }
            'SkipMachineOOBE'
            {
                $UnattendBuilder.SetElementValue('SkipMachineOOBE', $SkipMachineOOBE, $OOBE)
                continue
            }
            'SkipUserOOBE'
            {
                $UnattendBuilder.SetElementValue('SkipUserOOBE', $SkipUserOOBE, $OOBE)
                continue
            }
            'NetworkLocation'
            {
                $UnattendBuilder.SetElementValue('NetworkLocation', $NetworkLocation, $OOBE)
                continue
            }
            'SkipAdminProfileRemoval'
            {
                $VmOptimizations = $UnattendBuilder.GetOrCreateChildElement('VMModeOptimizations', $OOBE)
                $UnattendBuilder.SetElementValue('SkipAdministratorProfileRemoval', $SkipAdminProfileRemoval, $VmOptimizations)
                continue
            }
            'SkipLanguageChange'
            {
                $VmOptimizations = $UnattendBuilder.GetOrCreateChildElement('VMModeOptimizations', $OOBE)
                $UnattendBuilder.SetElementValue('SkipNotifyUILanguageChange', $SkipLanguageChange, $VmOptimizations)
                continue
            }
            'SkipWinReInitialization'
            {
                $VmOptimizations = $UnattendBuilder.GetOrCreateChildElement('VMModeOptimizations', $OOBE)
                $UnattendBuilder.SetElementValue('SkipWinREInitialization', $SkipWinReInitialization, $VmOptimizations)
                continue
            }
        }

        $UnattendBuilder
    }
}