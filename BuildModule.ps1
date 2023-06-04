#Requires -Version 5.1
using namespace System
using namespace System.Text
using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param
(
    [Parameter(Mandatory)]
    [Alias("ModuleVersion")]
    [version]$Version,

    [Parameter()]
    [string]
    $Destination = "$PSScriptRoot\Releases"
)
$ModuleName="UnattendXmlBuilder"

#region Create destination folder and make sure it is empty
$DestinationDirectory = Join-Path -Path $Destination -ChildPath "$ModuleName\$Version"
$null = New-Item -Path $DestinationDirectory -ItemType Directory -Force

$ItemsToRemove = Get-ChildItem -LiteralPath $DestinationDirectory -Force
if ($ItemsToRemove)
{
    if ($PSCmdlet.ShouldProcess($DestinationDirectory, "Deleting $($ItemsToRemove.Count) item(s)"))
    {
        Remove-Item -LiteralPath $ItemsToRemove.FullName -Recurse -Force
    }
    else
    {
        exit
    }
}
#endregion

#region Compile and add all content to destination folder
$UniqueUsingStatements = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$PublicFunctionNames = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$Psm1Builder = [StringBuilder]::new()
$FilePaths = @(
    "$PSScriptRoot\Classes"
    "$PSScriptRoot\Functions"
)

foreach ($File in Get-ChildItem -LiteralPath $FilePaths -Filter *.ps*1 -File -Recurse)
{
    $ScriptTokens = $null
    $BaseAst = [Parser]::ParseFile($File.FullName, [ref]$ScriptTokens, [ref]$null)
    foreach ($UsingStatement in $BaseAst.UsingStatements)
    {
        if ($UsingStatement.UsingStatementKind -eq [UsingStatementKind]::Namespace -and $null -eq $UsingStatement.Alias)
        {
            $null = $UniqueUsingStatements.Add("using namespace $($UsingStatement.Name.Value)")
        }
    }

    switch -Wildcard ($File.DirectoryName)
    {
        "$PSScriptRoot\Functions\*"
        {
            if ($BaseAst.EndBlock.Extent.StartOffset -gt 0)
            {
                $TokenBeforeAst = $ScriptTokens | Where-Object -FilterScript {$_.Extent.EndOffset -lt $BaseAst.EndBlock.Extent.StartOffset -and $_.Kind -ne [TokenKind]::NewLine} | Select-Object -Last 1
                if ($TokenBeforeAst.Kind -eq [TokenKind]::Comment)
                {
                    $null = $Psm1Builder.AppendLine($TokenBeforeAst.Text)
                }
            }

            $null = $Psm1Builder.AppendLine($BaseAst.EndBlock.Extent.Text)
            if ($_ -like "*\Public")
            {
                $null = $PublicFunctionNames.Add($File.BaseName)
            }
            break
        }
        Default
        {
            $null = $Psm1Builder.AppendLine($BaseAst.EndBlock.Extent.Text)
        }
    }
}

$null = $Psm1Builder.AppendLine((Get-Content -Path "$PSScriptRoot\ArgumentCompleters.ps1" -Raw))
$NewModuleFile = New-Item -Path "$DestinationDirectory\$ModuleName.psm1" -ItemType File -Force
$UniqueUsingStatements | Sort-Object | Add-Content -LiteralPath $NewModuleFile.FullName
Add-Content -Value $Psm1Builder.ToString() -LiteralPath $NewModuleFile.FullName
Copy-Item -LiteralPath "$PSScriptRoot\ModuleManifest.psd1" -Destination "$DestinationDirectory\$ModuleName.psd1"
#endregion

#region update module manifest
$FileList = (Get-ChildItem -LiteralPath $DestinationDirectory -File -Recurse | ForEach-Object -Process {
    "'$($_.FullName.Replace("$DestinationDirectory\", ''))'"
}) -join ','
$PublicFunctionNames = ($PublicFunctionNames | ForEach-Object -Process {
    "'$_'"
}) -join ','
$ReleaseNotes = Get-Content -LiteralPath "$PSScriptRoot\Release notes.txt" -Raw

((Get-Content -LiteralPath "$PSScriptRoot\ModuleManifest.psd1" -Raw) -replace '{(?=[^\d])','{{' -replace '(?<!\d)}','}}') -f @(
    "'$Version'"
    $PublicFunctionNames
    $FileList
    $ReleaseNotes
) | Set-Content -LiteralPath "$DestinationDirectory\$ModuleName.psd1" -Force
#endregion