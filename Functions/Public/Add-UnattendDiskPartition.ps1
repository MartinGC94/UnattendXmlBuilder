using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Adds disk partitioning related settings to the unattend file.

.DESCRIPTION
    Adds disk partitioning related settings to the unattend file.
    You can either use one of the predefined templates that handle all the partitioning, or run this command multiple times to add all the custom partitions you need.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Template
    Specifies the template to use.
    BIOS will create 3 partitions (System (100MB), Recovery (620MB), Windows (Rest of disk))
    UEFI will create 4 partitions (System (100MB), MSR (16MB), Recovery (620MB), Windows (Rest of disk))

.PARAMETER DontWipeDisk
    Specifies that the disk should not be wiped.

.PARAMETER DiskNumber
    Specifies which disk to target.

.PARAMETER SizeMB
    Specifies how big the partition should be.

.PARAMETER UseRemainingSpace
    Specifies that it should use the remaining space on the disk for this partition.

.PARAMETER PartitionType
    Specifies what kind of partition should be created.

.PARAMETER Active
    Specifies that the partition should be marked "Active" (this is needed for the System partition on BIOS layouts)

.PARAMETER Filesystem
    Specifies the filesystem for this partition.

.PARAMETER VolumeLabel
    Specifies a custom label for this partition.

.PARAMETER DriveLetter
    Assigns a driveletter to this partition.

.PARAMETER PartitionTypeID
    Specifies a custom partition ID to be set. This is rarely needed.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendDiskPartition
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(Mandatory, ParameterSetName = "Predefined")]
        [ValidateSet("BIOS", "UEFI")]
        [string]
        $Template,

        [Parameter()]
        [switch]
        $DontWipeDisk,

        [Parameter(Mandatory)]
        [uint32]
        $DiskNumber,

        [Parameter(Mandatory, ParameterSetName = "CustomSize")]
        [uint32]
        $SizeMB,

        [Parameter(Mandatory, ParameterSetName = "CustomExtend")]
        [switch]
        $UseRemainingSpace,

        [Parameter(ParameterSetName = "CustomSize")]
        [Parameter(ParameterSetName = "CustomExtend")]
        [ValidateSet('Primary', 'EFI', 'MSR', 'Recovery')]
        [string]
        $PartitionType = 'Primary',

        [Parameter(ParameterSetName = "CustomSize")]
        [Parameter(ParameterSetName = "CustomExtend")]
        [switch]
        $Active,

        [Parameter(ParameterSetName = "CustomSize")]
        [Parameter(ParameterSetName = "CustomExtend")]
        [ValidateSet('FAT32', 'NTFS')]
        [string]
        $Filesystem,

        [Parameter(ParameterSetName = "CustomSize")]
        [Parameter(ParameterSetName = "CustomExtend")]
        [string]
        $VolumeLabel,

        [Parameter(ParameterSetName = "CustomSize")]
        [Parameter(ParameterSetName = "CustomExtend")]
        [char]
        $DriveLetter,

        [Parameter(ParameterSetName = "CustomSize")]
        [Parameter(ParameterSetName = "CustomExtend")]
        [string]
        $PartitionTypeID
    )
    process
    {
        if ($Template)
        {
            $Disk = @{DiskNumber = $DiskNumber}
            $SystemCommonParams = @{
                DontWipeDisk = $DontWipeDisk
                SizeMB       = 100
                VolumeLabel  = "System"
            }
            $RecoveryParams = @{
                SizeMB        = 620
                PartitionType = "Recovery"
                Filesystem    = "NTFS"
                VolumeLabel   = "Recovery"
            }
            $WindowsParams = @{
                UseRemainingSpace = $true
                FileSystem        = "NTFS"
                PartitionType     = "Primary"
                VolumeLabel       = "Windows"
                DriveLetter       = "C"
            }
            if ($Template -eq 'BIOS')
            {
                $UnattendBuilder |
                    Add-UnattendDiskPartition @Disk @SystemCommonParams -PartitionType Primary -Active -Filesystem NTFS |
                    Add-UnattendDiskPartition @Disk @RecoveryParams |
                    Add-UnattendDiskPartition @Disk @WindowsParams
            }
            else
            {
                $UnattendBuilder |
                    Add-UnattendDiskPartition @Disk @SystemCommonParams -PartitionType EFI -Filesystem FAT32 |
                    Add-UnattendDiskPartition @Disk -SizeMB 16 -PartitionType MSR |
                    Add-UnattendDiskPartition @Disk @RecoveryParams |
                    Add-UnattendDiskPartition @Disk @WindowsParams
            }
        }
        else
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Setup', 'windowsPE')
            $DiskConfig = $UnattendBuilder.GetOrCreateChildElement('DiskConfiguration', $Component)
            $DiskElement = $UnattendBuilder.GetChildElementFromXpath("./Disk/DiskID/text()[. = '$DiskNumber']/../..", $DiskConfig)
            $AddAction = @{action = 'add'}

            if ($null -eq $DiskElement)
            {
                $DiskElement = $DiskConfig.AppendChild($UnattendBuilder.CreateElement("Disk", $AddAction))
                $UnattendBuilder.CreateAndAppendElement("DiskID", $DiskNumber, $DiskElement)
            }

            if ($PSBoundParameters.ContainsKey('DontWipeDisk'))
            {
                $UnattendBuilder.SetElementValue('WillWipeDisk', !$DontWipeDisk, $DiskElement)
            }

            $CreatePartitionsElement = $UnattendBuilder.GetOrCreateChildElement('CreatePartitions', $DiskElement)
            $ModifyPartitionsElement = $UnattendBuilder.GetOrCreateChildElement('ModifyPartitions', $DiskElement)
            $Order = $CreatePartitionsElement.ChildNodes.Count + 1

            $Partition = $CreatePartitionsElement.AppendChild($UnattendBuilder.CreateElement("CreatePartition", $AddAction))
            $UnattendBuilder.CreateAndAppendElement("Order", $Order, $Partition)
            if ($SizeMB)
            {
                $UnattendBuilder.CreateAndAppendElement("Size", $SizeMB, $Partition)
            }
            else
            {
                $UnattendBuilder.CreateAndAppendElement('Extend', $UseRemainingSpace, $Partition)
            }

            if ($PartitionType -eq "Recovery")
            {
                $RealPartitionType = "Primary"
                $RealCustomPartitionID = 'DE94BBA4-06D1-4D40-A16A-BFD50179D6AC'
            }
            else
            {
                $RealPartitionType = $PartitionType
                $RealCustomPartitionID = $PartitionTypeID
            }
            $UnattendBuilder.CreateAndAppendElement('Type', $RealPartitionType, $Partition)

            $ModifyPartition = $ModifyPartitionsElement.AppendChild($UnattendBuilder.CreateElement("ModifyPartition", $AddAction))
            $UnattendBuilder.CreateAndAppendElement("Order", $Order, $ModifyPartition)
            $UnattendBuilder.CreateAndAppendElement("PartitionID", $Order, $ModifyPartition)

            if ($VolumeLabel)
            {
                $UnattendBuilder.CreateAndAppendElement("Label", $VolumeLabel, $ModifyPartition)
            }
            if ($Filesystem)
            {
                $UnattendBuilder.CreateAndAppendElement("Format", $Filesystem, $ModifyPartition)
            }
            if ($RealCustomPartitionID)
            {
                $UnattendBuilder.CreateAndAppendElement("TypeID", $RealCustomPartitionID, $ModifyPartition)
            }
            if ($PSBoundParameters.ContainsKey('Active'))
            {
                $UnattendBuilder.CreateAndAppendElement("Active", $Active, $ModifyPartition)
            }

            $UnattendBuilder
        }
    }
}