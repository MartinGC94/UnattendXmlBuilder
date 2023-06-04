using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures sysprep behavior for devices and device drivers.

.DESCRIPTION
    Configures sysprep behavior for devices and device drivers.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER DontCleanNonPresentDevices
    Specifies whether Plug and Play information persists on the destination computer during the following specialize configuration pass.

.PARAMETER PersistAllDeviceInstalls
    Specifies whether all Plug and Play information persists on the destination computer during the generalize configuration pass.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendSysPrepSetting
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
        $DontCleanNonPresentDevices,

        [Parameter()]
        [switch]
        $PersistAllDeviceInstalls
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-PnpSysprep', 'generalize')
        switch ($PSBoundParameters.Keys)
        {
            'DontCleanNonPresentDevices'
            {
                $UnattendBuilder.SetElementValue('DoNotCleanUpNonPresentDevices', $DontCleanNonPresentDevices, $Component)
                continue
            }
            'PersistAllDeviceInstalls'
            {
                $UnattendBuilder.SetElementValue('PersistAllDeviceInstalls', $PersistAllDeviceInstalls, $Component)
                continue
            }
        }

        $UnattendBuilder
    }
}