using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Sets the product key to use during installation.

.DESCRIPTION
    Sets the product key to use during installation.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    The pass this command should apply to.
    By default, this command will add the key to all supported install phases.
    Supported values:
    windowsPE
    specialize

.PARAMETER ProductKey
    The product key to install.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendProductKey
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet("windowsPE", "specialize")]
        [string[]]
        $Pass = ("windowsPE", "specialize"),

        [Parameter(Mandatory, Position = 0)]
        [string]
        $ProductKey
    )
    process
    {
        switch ($Pass)
        {
            'windowsPE'
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Setup', $_)
                $UserData = $UnattendBuilder.GetOrCreateChildElement("UserData", $Component)
                $KeyElement = $UnattendBuilder.GetOrCreateChildElement('ProductKey', $UserData)
                $UnattendBuilder.SetElementValue('Key', $ProductKey, $KeyElement)
                continue
            }
            'specialize'
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $_)
                $UnattendBuilder.SetElementValue('ProductKey', $ProductKey, $Component)
                continue
            }
        }

        $UnattendBuilder
    }
}