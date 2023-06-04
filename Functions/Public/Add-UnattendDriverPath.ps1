using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures the paths Windows should use to look for drivers to install during setup.

.DESCRIPTION
    Configures the paths Windows should use to look for drivers to install during setup.
    Any driver files found will be added to the driverstore.
    You can run this command multiple times if you need to specify multiple UNC paths with different credentials.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    The pass that this command should apply to.
    Supported values:
    windowsPE
    offlineServicing (default)
    auditSystem

.PARAMETER Path
    The folder that contains the drivers to install.
    This folder will be checked recursively for drivers that can be installed.
    It can either be local, or a UNC path.

.PARAMETER Credential
    The credential used to access the specified folder, useful if the specified folder is a UNC path.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendDriverPath
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('windowsPE', 'offlineServicing', 'auditSystem')]
        [string[]]
        $Pass = 'offlineServicing',

        [Parameter()]
        [string[]]
        $Path,

        [Parameter()]
        [pscredential]
        $Credential
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = if ($PassName -eq 'windowsPE')
            {
                $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-PnpCustomizationsWinPE', $PassName)
            }
            else
            {
                $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-PnpCustomizationsNonWinPE', $PassName)
            }

            $DriverPaths = $UnattendBuilder.GetOrCreateChildElement("DriverPaths", $Component)
            $Counter = $DriverPaths.ChildNodes.Count + 1
            foreach ($Item in $Path)
            {
                $PathElement = $DriverPaths.AppendChild($UnattendBuilder.CreateElement("PathAndCredentials", @{action = "add";keyValue = ($Counter++)}))
                $UnattendBuilder.CreateAndAppendElement("Path", $PathElement)
                if ($Credential)
                {
                    $UnattendBuilder.AddCredentialToElement($Credential, $PathElement)
                }
            }
        }

        $UnattendBuilder
    }
}