using module ..\..\Classes\UnattendBuilder.psm1

<#
.SYNOPSIS
    Adds image source/destination details to the unattend file.

.DESCRIPTION
    This command adds image source and destination details to the unattend file.
    This can be used to automate the selection of an OS installation image, as well as one or more data images.
    When selecting a source image, you can use the image index, name or description.
    If you specify multiple sources, the XML file will be invalid.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER SourceImagePath
    The path to the the install/data image file, including the extension (.Wim or .Esd)

.PARAMETER SourceImageIndex
    The index of the image to be applied, indexes start at 1.
    This should not be used together with "SourceImageName" nor "SourceImageDescription".
    The index for a particular image. Can be viewed with the command: Get-WindowsImage

.PARAMETER SourceImageName
    The name of the image to be applied.
    This should not be used together with "SourceImageIndex" nor "SourceImageDescription".
    The name for a particular image.

.PARAMETER SourceImageDescription
    The description of the image to be applied.
    This should not be used together with "SourceImageIndex" nor "SourceImageName".
    The description for a particular image can be viewed with the command: Get-WindowsImage

.PARAMETER SourceImageGroup
    The image group on the WDS server that contains the image to be installed.

.PARAMETER DestinationDiskID
    The disk number where the image should be applied, typically 0.

.PARAMETER DestinationPartitionID
    The ID of the partition where the image should be applied.

.PARAMETER Credential
    The credential used to access the image source location (if on a fileshare) or the credential used to log on to the WDS server.

.PARAMETER WDS
    Specifies that the image source is WDS (Windows Deployment Services).

.PARAMETER DataImage
    Specifies that the image source is a data image.
    Multiple data images can be applied on top of the OS install image to add additional files.
    To apply multiple data images, run this command multiple times.

.PARAMETER Compact
    Specifies that the OS image should be compacted when installed to the disk.
    Compacting the OS will make it take up less space, but performance can be slightly decreased.

.PARAMETER InstallToAvailablePartition
    When set, the installer will find the first available partition with enough space for the OS, and install it there.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendImage
{
    [CmdletBinding(DefaultParameterSetName = "Standard", PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [string]
        $SourceImagePath,

        [Parameter(ParameterSetName = "Standard")]
        [Parameter(ParameterSetName = "DataImage")]
        [uint32]
        $SourceImageIndex,

        [Parameter()]
        [string]
        $SourceImageName,

        [Parameter(ParameterSetName = "Standard")]
        [Parameter(ParameterSetName = "DataImage")]
        [string]
        $SourceImageDescription,

        [Parameter(ParameterSetName = "WDS")]
        [string]
        $SourceImageGroup,

        [Parameter()]
        [uint32]
        $DestinationDiskID,

        [Parameter()]
        [uint32]
        $DestinationPartitionID,

        [Parameter()]
        [pscredential]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = "WDS")]
        [switch]
        $WDS,

        [Parameter(Mandatory, ParameterSetName = "DataImage")]
        [switch]
        $DataImage,

        [Parameter(ParameterSetName = "Standard")]
        [switch]
        $Compact,

        [Parameter(ParameterSetName = "Standard")]
        [switch]
        $InstallToAvailablePartition
    )
    process
    {
        $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Setup', 'windowsPE')

        if ($WDS)
        {
            $SubComponent = $UnattendBuilder.GetOrCreateChildElement('WindowsDeploymentServices', $Component)
            if ($SourceImagePath -or $SourceImageGroup -or $SourceImageName -or $DestinationDiskID -or $DestinationPartitionID)
            {
                $ImageSelection = $SubComponent.AppendChild($UnattendBuilder.CreateElement('ImageSelection'))
                switch ($PSBoundParameters.Keys)
                {
                    'SourceImagePath'
                    {
                        $InstallImage = $UnattendBuilder.GetOrCreateChildElement('InstallImage', $ImageSelection)
                        $UnattendBuilder.CreateAndAppendElement('Filename', $SourceImagePath, $InstallImage)
                        continue
                    }
                    'SourceImageGroup'
                    {
                        $InstallImage = $UnattendBuilder.GetOrCreateChildElement('InstallImage', $ImageSelection)
                        $UnattendBuilder.CreateAndAppendElement('ImageGroup', $SourceImageGroup, $InstallImage)
                        continue
                    }
                    'SourceImageName'
                    {
                        $InstallImage = $UnattendBuilder.GetOrCreateChildElement('InstallImage', $ImageSelection)
                        $UnattendBuilder.CreateAndAppendElement('ImageName', $SourceImageName, $InstallImage)
                        continue
                    }
                    'DestinationDiskID'
                    {
                        $InstallTo = $UnattendBuilder.GetOrCreateChildElement('InstallTo', $ImageSelection)
                        $UnattendBuilder.CreateAndAppendElement('DiskID', $DestinationDiskID, $InstallImage)
                        continue
                    }
                    'DestinationPartitionID'
                    {
                        $InstallTo = $UnattendBuilder.GetOrCreateChildElement('InstallTo', $ImageSelection)
                        $UnattendBuilder.CreateAndAppendElement('PartitionID', $DestinationPartitionID, $InstallImage)
                        continue
                    }
                }
            }
            if ($Credential)
            {
                $Login = $SubComponent.AppendChild($UnattendBuilder.CreateElement('Login'))
                $UnattendBuilder.AddCredentialToElement($Credential, $Login)
            }
        }
        else
        {
            $SubComponent = $UnattendBuilder.GetOrCreateChildElement('ImageInstall', $Component)
            if ($DataImage)
            {
                $ImageElement = $SubComponent.AppendChild($UnattendBuilder.CreateElement("DataImage", @{action = 'add'}))
                $UnattendBuilder.CreateAndAppendElement("Order", $SubComponent.ChildNodes.Count, $ImageElement)
            }
            else
            {
                $ImageElement = $UnattendBuilder.GetOrCreateChildElement('OSImage', $SubComponent)
                if ($PSBoundParameters.ContainsKey('Compact'))
                {
                    $UnattendBuilder.CreateAndAppendElement('Compact', $Compact, $ImageElement)
                }
                if ($PSBoundParameters.ContainsKey('InstallToAvailablePartition'))
                {
                    $UnattendBuilder.CreateAndAppendElement('InstallToAvailablePartition', $InstallToAvailablePartition, $ImageElement)
                }
            }

            if ($SourceImagePath -or $SourceImageIndex -or $SourceImageName -or $SourceImageDescription -or $Credential)
            {
                $InstallFrom = $ImageElement.AppendChild($UnattendBuilder.CreateElement('InstallFrom'))
                switch ($PSBoundParameters.Keys)
                {
                    'SourceImagePath'
                    {
                        $UnattendBuilder.CreateAndAppendElement('Path', $SourceImagePath, $InstallFrom)
                        continue
                    }
                    'SourceImageIndex'
                    {
                        $MetaData = $InstallFrom.AppendChild($UnattendBuilder.CreateElement('MetaData', @{action = 'add'}))
                        $UnattendBuilder.CreateAndAppendElement('Key', '/IMAGE/INDEX', $MetaData)
                        $UnattendBuilder.CreateAndAppendElement('Value', $SourceImageIndex, $MetaData)
                        continue
                    }
                    'SourceImageName'
                    {
                        $MetaData = $InstallFrom.AppendChild($UnattendBuilder.CreateElement('MetaData', @{action = 'add'}))
                        $UnattendBuilder.CreateAndAppendElement('Key', '/IMAGE/NAME', $MetaData)
                        $UnattendBuilder.CreateAndAppendElement('Value', $SourceImageName, $MetaData)
                        continue
                    }
                    'SourceImageDescription'
                    {
                        $MetaData = $InstallFrom.AppendChild($UnattendBuilder.CreateElement('MetaData', @{action = 'add'}))
                        $UnattendBuilder.CreateAndAppendElement('Key', '/IMAGE/DESCRIPTION', $MetaData)
                        $UnattendBuilder.CreateAndAppendElement('Value', $SourceImageDescription, $MetaData)
                        continue
                    }
                    'Credential'
                    {
                        $UnattendBuilder.AddCredentialToElement($Credential, $InstallFrom)
                    }
                }
            }
            if ($DestinationDiskID)
            {
                $InstallTo = $UnattendBuilder.GetOrCreateChildElement('InstallTo', $ImageElement)
                $UnattendBuilder.CreateAndAppendElement('DiskID', $DestinationDiskID, $InstallTo)
            }
            if ($DestinationPartitionID)
            {
                $InstallTo = $UnattendBuilder.GetOrCreateChildElement('InstallTo', $ImageElement)
                $UnattendBuilder.CreateAndAppendElement('PartitionID', $DestinationPartitionID, $InstallTo)
            }
        }

        $UnattendBuilder
    }
}