using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures language and localization settings.

.DESCRIPTION
    Configures language and localization settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command should apply to.
    Valid values are:
    windowsPE
    specialize (Default)
    oobeSystem

.PARAMETER InputLocale
    Specifies the keyboard layout that should be used, for example: da-DK

.PARAMETER SystemLocale
    Specifies the language to use for non-unicode programs. Can be specified like this: da-DK

.PARAMETER UiLanguage
    Specifies the language of the shell. Can be specified like this: da-DK

.PARAMETER SetupUiLanguage
    Specifies the language to use in the WinPE setup UI.

.PARAMETER UiLanguageFallback
    The fallback language of the shell, for components that have not been localized in the primary language.
    Can be specified like this: en-US

.PARAMETER UserLocale
    Specifies the format used for dates, currency and other localized content.
    Can be specified like this: da-DK

.PARAMETER LayeredDriver
    The keyboard driver used in WinPE for asian languages.
    Valid values are 1-6.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendLanguageSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('windowsPE', 'specialize', 'oobeSystem')]
        [string[]]
        $Pass = 'specialize',

        [Parameter()]
        [cultureinfo[]]
        $InputLocale,

        [Parameter()]
        [cultureinfo]
        $SystemLocale,

        [Parameter()]
        [cultureinfo]
        $UiLanguage,

        [Parameter()]
        [cultureinfo]
        $SetupUiLanguage,

        [Parameter()]
        [cultureinfo]
        $UiLanguageFallback,

        [Parameter()]
        [cultureinfo]
        $UserLocale,

        [Parameter()]
        [ValidateRange(1, 6)]
        [int]
        $LayeredDriver
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $ComponentName = if ($PassName -eq "windowsPE")
            {
                'Microsoft-Windows-International-Core-WinPE'
            }
            else
            {
                'Microsoft-Windows-International-Core'
            }

            $Component = $UnattendBuilder.GetOrCreateComponent($ComponentName, $PassName)
            switch ($PSBoundParameters.Keys)
            {
                'InputLocale'
                {
                    $UnattendBuilder.SetElementValue('InputLocale', $InputLocale.Name -join ';', $Component)
                    continue
                }
                'SystemLocale'
                {
                    $UnattendBuilder.SetElementValue('SystemLocale', $SystemLocale.Name, $Component)
                    continue
                }
                'UiLanguage'
                {
                    $UnattendBuilder.SetElementValue('UILanguage', $UiLanguage.Name, $Component)
                    continue
                }
                'UiLanguageFallback'
                {
                    $UnattendBuilder.SetElementValue('UILanguageFallback', $UiLanguageFallback.Name, $Component)
                    continue
                }
                'UserLocale'
                {
                    $UnattendBuilder.SetElementValue('UserLocale', $UserLocale.Name, $Component)
                    continue
                }
                'SetupUiLanguage'
                {
                    if ($PassName -eq "windowsPE")
                    {
                        $SetupUIElement = $UnattendBuilder.GetOrCreateChildElement('SetupUILanguage', $Component)
                        $UnattendBuilder.SetElementValue('UILanguage', $SetupUiLanguage, $SetupUIElement)
                    }
                    else
                    {
                        Write-Warning -Message "$_ can only be set on windowsPE pass. Ignoring it for pass: $PassName"
                    }
                    continue
                }
                'LayeredDriver'
                {
                    if ($PassName -eq "windowsPE")
                    {
                        $UnattendBuilder.SetElementValue('LayeredDriver', $LayeredDriver, $ComponentName)
                    }
                    else
                    {
                        Write-Warning -Message "$_ can only be set on windowsPE pass. Ignoring it for pass: $PassName"
                    }
                    continue
                }
            }
        }

        $UnattendBuilder
    }
}