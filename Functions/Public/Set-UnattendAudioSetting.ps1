using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures audio settings.

.DESCRIPTION
    Configures audio settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER DisableSpatialOnComboEndpoints
    Not documented.

.PARAMETER DisableCaptureMonitor
    Prevents users from playing audio by connecting devices (music players) to the "Audio in" port.

.PARAMETER DisableVolumeControlOnLockscreen
    Disables volume adjustment from the lock screen.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendAudioSetting
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
        $DisableSpatialOnComboEndpoints,

        [Parameter()]
        [switch]
        $DisableCaptureMonitor,

        [Parameter()]
        [switch]
        $DisableVolumeControlOnLockscreen
    )
    process
    {
        $Pass = 'specialize'

        switch ($PSBoundParameters.Keys)
        {
            'DisableSpatialOnComboEndpoints'
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Audio-AudioCore', $Pass)
                $UnattendBuilder.SetElementValue('DisableSpatialOnComboEndpoints', $DisableSpatialOnComboEndpoints, $Component)
                continue
            }
            'DisableCaptureMonitor'
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Audio-AudioCore', $Pass)
                $UnattendBuilder.SetElementValue('EnableCaptureMonitor', !$DisableCaptureMonitor, $Component)
                continue
            }
            'DisableVolumeControlOnLockscreen'
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Audio-VolumeControl', $Pass)
                $UnattendBuilder.SetElementValue('EnableVolumeControlWhileLocked', !$DisableVolumeControlOnLockscreen, $Component)
                continue
            }
        }

        $UnattendBuilder
    }
}