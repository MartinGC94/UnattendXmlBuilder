using module ..\..\Classes\UnattendBuilder.psm1
using module ..\..\Classes\TpmClearBehavior.psm1
<#
.SYNOPSIS
    Configures TPM settings.

.DESCRIPTION
    Configures Trusted Platform Module settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER ClearBehavior
    Controls under which circumstances the TPM should be cleared.
    Clearing the TPM will delete all the keys stored on the TPM, such as bitlocker keys or Windows Hello PINs.
    Valid values:
    Never - Does not clear the TPM (Default behavior).
    WhenOwner - Clears the TPM if Windows has taken ownership of the TPM.
    Always - Always clears the TPM.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendTpmSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(Mandatory)]
        [TpmClearBehavior]
        $ClearBehavior
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-TPM-Tasks', 'specialize')
        $UnattendBuilder.SetElementValue('ClearTpm', $ClearBehavior.value__, $Component)
        $UnattendBuilder
    }
}