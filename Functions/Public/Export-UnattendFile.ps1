using module ..\..\Classes\UnattendBuilder.psm1
using namespace System
using namespace System.Management.Automation
<#
.SYNOPSIS
    Creates an unattend file from the provided UnattendBuilder object.

.DESCRIPTION
    Creates an unattend file from the provided UnattendBuilder object.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that contains all the file contents.
    Create one with the command: New-UnattendBuilder

.PARAMETER FilePath
    The full path to the file that should be created.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder
#>
function Export-UnattendFile
{
    [CmdletBinding(PositionalBinding = $false)]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(Mandatory, Position = 0)]
        [string]
        $FilePath
    )
    process
    {
        $ParentPath = Split-Path -LiteralPath $FilePath -ErrorAction Stop
        $ResolvedPath = Resolve-Path -LiteralPath $ParentPath -ErrorAction Stop
        if ($ResolvedPath.Provider.Name -ne 'FileSystem')
        {
            $PSCmdlet.ThrowTerminatingError(
                [ErrorRecord]::new(
                    [ArgumentException]::new("The provided path is invalid. Please provide a filesystem path.", "FilePath"),
                    "NotAFilesystemPath",
                    [ErrorCategory]::InvalidArgument,
                    $FilePath
                )
            )
        }

        $FileName = Split-Path -Path $FilePath -Leaf -ErrorAction Stop
        $OutputPath = Join-Path -Path $ResolvedPath.ProviderPath -ChildPath $FileName
        $UnattendBuilder.ToXml().Save($OutputPath)
    }
}