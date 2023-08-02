using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Creates a new unattendbuilder object that can be used to build an unattend file.

.DESCRIPTION
    Creates a new unattendbuilder object that can be used to build an unattend file.
    This command includes convenience parameters that allow you to get started with a new unattend file that includes the basics
    but you can also start from a clean slate.
    Another option is to import an existing file/XML document as a baseline, and add additional settings to it.

.PARAMETER SourceFile
    Specifies the path to an XML file that contains an existing unattend file to import.

.PARAMETER SourceDocument
    Specifies the XmlDocument object that contains an existing unattend file that should be modified.

.PARAMETER UiLanguage
    Specifies the display language to set in WinPE and Windows.

.PARAMETER SystemLocale
    Specifies the system locale to set in WinPE and Windows.

.PARAMETER InputLocale
    Specifies the keyboard layout to set in WinPE and Windows.

.PARAMETER ProductKey
    Specifies the product key to add the unattend file.

.PARAMETER DiskTemplate
    Specifies the predefined disk template to use during the installation

.PARAMETER SkipOOBE
    Skips all the OOBE windows.

.PARAMETER LocalAdminPassword
    Sets the local admin password.

.PARAMETER LocalUserToAdd
    Adds a local user as admin.

.PARAMETER LocalUserPassword
    Sets a password for the specified user.

.OUTPUTS
    [UnattendBuilder]
#>
function New-UnattendBuilder
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string]
        $SourceFile,

        [Parameter(ValueFromPipeline)]
        [xml]
        $SourceDocument,

        [Parameter()]
        [cultureinfo]
        $UiLanguage,

        [Parameter()]
        [cultureinfo]
        $SystemLocale,

        [Parameter()]
        [cultureinfo[]]
        $InputLocale,

        [Parameter()]
        [string]
        $ProductKey,

        [Parameter()]
        [ValidateSet('BIOS', 'UEFI')]
        [string]
        $DiskTemplate,

        [Parameter()]
        [switch]
        $SkipOOBE,

        [Parameter()]
        [string]
        $LocalAdminPassword,

        [Parameter()]
        [string]
        $LocalUserToAdd,

        [Parameter()]
        [string]
        $LocalUserPassword
    )
    process
    {
        $Builder = try
        {
            if ($SourceFile)
            {
                $ResolvedPath = Resolve-Path -LiteralPath $SourceFile -ErrorAction Stop
                [UnattendBuilder]::new($ResolvedPath.ProviderPath)
            }
            elseif ($SourceDocument)
            {
                [UnattendBuilder]::new($SourceDocument)
            }
            else
            {
                [UnattendBuilder]::new()
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $LanguageParams = @{}
        switch ($PSBoundParameters.Keys)
        {
            'UiLanguage'
            {
                $LanguageParams.Add('UiLanguage', $UiLanguage)
                continue
            }
            'SystemLocale'
            {
                $LanguageParams.Add('SystemLocale', $SystemLocale)
                continue
            }
            'InputLocale'
            {
                $LanguageParams.Add('InputLocale', $InputLocale)
                continue
            }
            'ProductKey'
            {
                $null = $Builder | Set-UnattendProductKey -ProductKey $ProductKey
                continue
            }
            'DiskTemplate'
            {
                $null = $Builder | Add-UnattendDiskPartition -Template $DiskTemplate -DiskNumber 0 | Add-UnattendImage -InstallToAvailablePartition
                continue
            }
            'SkipOOBE'
            {
                $null = $Builder | Set-UnattendWindowsSetupSetting -AcceptEula | Set-UnattendOobeSetting -HideEula -HideLocalAccount -HideOem -HideOnlineAccount -HideNetworkSetup -UseExpressSettings:$false
                continue
            }
            'LocalAdminPassword'
            {
                $null = $Builder | Add-UnattendUser -LocalAdmin -Password $LocalAdminPassword
                continue
            }
            'LocalUserToAdd'
            {
                $UserParams = @{Name = $LocalUserToAdd}
                if ($LocalUserPassword)
                {
                    $UserParams.Add("Password", $LocalUserPassword)
                }
                $null = $Builder | Add-UnattendUser @UserParams -Group Administrators
                continue
            }
        }

        if ($LanguageParams.Count -gt 0)
        {
            $null = $Builder | Set-UnattendLanguageSetting -Pass windowsPE,specialize,oobeSystem @LanguageParams
        }

        $Builder
    }
}