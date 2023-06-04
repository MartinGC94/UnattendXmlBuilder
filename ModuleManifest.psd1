@{
    RootModule             = "UnattendXmlBuilder.psm1"
    ModuleVersion          = {0}
    CompatiblePSEditions   = @("Core", "Desktop")
    GUID                   = 'e99124c9-56eb-4032-b40c-1508a7c3c62c'
    Author                 = 'MartinGC94'
    CompanyName            = 'Unknown'
    Copyright              = '(c) 2023 MartinGC94. All rights reserved.'
    Description            = 'Module for building Windows unattend XML documents.'
    PowerShellVersion      = '5.1'
    FormatsToProcess       = @()
    FunctionsToExport      = @({1})
    CmdletsToExport        = @()
    VariablesToExport      = @()
    AliasesToExport        = @()
    DscResourcesToExport   = @()
    FileList               = @({2})
    PrivateData            = @{
        PSData = @{
             Tags         = @("Unattend", "Autounattend", "XML", "Windows", "Installation")
             ProjectUri   = 'https://github.com/MartinGC94/UnattendXmlBuilder'
             ReleaseNotes = @'
{3}
'@
        }
    }
}