using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures various settings used during Windows setup in WinPE.

.DESCRIPTION
    Configures various settings used during Windows setup in WinPE.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER DisableFirewall
    Specifies whether Windows Firewall is enabled for Windows Preinstallation Environment (Windows PE).
    This setting does not apply to the Windows Firewall settings of the Windows installation.

.PARAMETER EnableNetwork
    Specifies whether network connection is enabled.
    This setting applies only to Windows Preinstallation Environment (Windows PE).
    In the standard Windows setup WinPE image, networking is disabled by default.
    For custom WinPE images, networking is enabled by default.

.PARAMETER LogDirectory
    Specifies where log files for WinPE will be saved.

.PARAMETER ShutdownAfterWinPE
    Specifies that WinPE should shutdown rather than reboot after finishing.

.PARAMETER UseConfigurationSet
    Specifies whether to use a configuration set for Windows Setup.
    A configuration set is a folder that contains additional device drivers, applications, or other binaries that you want to add to Windows during installation.
    You can create a configuration set in Windows System Image Manager.

.PARAMETER DisableDiskEncryptionProvisioning
    Specifies whether Windows activates encryption on blank drives that are capable of hardware-based encryption during installation.

.PARAMETER PagefilePath
    Specifies the path to use for the page file used in WinPE.

.PARAMETER PagefileSizeMB
    Specifies the max size of the page file used in WinPE.

.PARAMETER AcceptEula
    Specifies that you accept the Windows EULA of the image you are installing.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendWindowsSetupSetting
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
        $DisableFirewall,

        [Parameter()]
        [switch]
        $EnableNetwork,

        [Parameter()]
        [string]
        $LogDirectory,

        [Parameter()]
        [switch]
        $ShutdownAfterWinPE,

        [Parameter()]
        [switch]
        $UseConfigurationSet,

        [Parameter()]
        [switch]
        $DisableDiskEncryptionProvisioning,

        [Parameter()]
        [string]
        $PagefilePath,

        [Parameter()]
        [string]
        $PagefileSizeMB,

        [Parameter()]
        [switch]
        $AcceptEula
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Setup', 'windowsPE')
        switch ($PSBoundParameters.Keys)
        {
            'DisableFirewall'
            {
                $UnattendBuilder.SetElementValue('EnableFirewall', !$DisableFirewall, $Component)
                continue
            }
            'EnableNetwork'
            {
                $UnattendBuilder.SetElementValue('EnableNetwork', $EnableNetwork, $Component)
                continue
            }
            'LogDirectory'
            {
                $UnattendBuilder.SetElementValue('LogPath', $LogDirectory, $Component)
                continue
            }
            'ShutdownAfterWinPE'
            {
                $Text = if ($ShutdownAfterWinPE)
                {
                    "Shutdown"
                }
                else
                {
                    "Restart"
                }
                $UnattendBuilder.SetElementValue('Restart', $Text, $Component)
                continue
            }
            'UseConfigurationSet'
            {
                $UnattendBuilder.SetElementValue('UseConfigurationSet', $UseConfigurationSet, $Component)
                continue
            }
            'DisableDiskEncryptionProvisioning'
            {
                $DiskConfig = $UnattendBuilder.GetOrCreateChildElement('DiskConfiguration', $Component)
                $UnattendBuilder.SetElementValue('DisableEncryptedDiskProvisioning', $DisableDiskEncryptionProvisioning, $DiskConfig)
                continue
            }
            'PagefilePath'
            {
                $PageFile = $UnattendBuilder.GetOrCreateChildElement('PageFile', $Component)
                $UnattendBuilder.SetElementValue('Path', $PagefilePath, $PageFile)
                continue
            }
            'PagefileSizeMB'
            {
                $PageFile = $UnattendBuilder.GetOrCreateChildElement('PageFile', $Component)
                $UnattendBuilder.SetElementValue('Size', $PagefileSizeMB, $PageFile)
                continue
            }
            'AcceptEula'
            {
                $UserData = $UnattendBuilder.GetOrCreateChildElement('UserData', $Component)
                $UnattendBuilder.SetElementValue('AcceptEula', $AcceptEula, $UserData)
                continue
            }
        }
        $UnattendBuilder
    }
}