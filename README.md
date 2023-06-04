# UnattendXmlBuilder
This PowerShell module lets you build or modify Windows Unattend files (AKA Answer files) that can be used to automate Windows installations.  
For more general information about answer files, see: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs

# Getting started
First, install the module from the PowerShell gallery: `Install-Module UnattendXmlBuilder`  
Then check the available commands in the module: `Get-Command -Module UnattendXmlBuilder`  
The basic idea on how this module works is that you create a builder object with `New-UnattendBuilder` and pass that object through other commands via the pipeline to configure different settings.  
The `Add` commands are expected to be used multiple times, and therefore don't make any changes to existing instances, while the `Set` commands are only expected to be used once and will change existing settings.  
When all the desired settings have been configured you use `Export-UnattendFile` to save the file.  
Here's a basic example that adds a user, sets the computername and saves the file to the desktop:
```
New-UnattendBuilder |
  Add-UnattendUser -Name DemoUser -Password 'Pa$$w0rd' |
  Set-UnattendComputerName -ComputerName "MyComputer" |
  Export-UnattendFile -FilePath "$HOME\Desktop\Autounattend.xml"
```
`New-UnattendBuilder` includes parameters to configure most commonly used settings, here's an example of a fully automated Windows 10 installation:
```
$BuilderParams = @{
    UiLanguage        = 'da-DK'
    SystemLocale      = 'da-DK'
    InputLocale       = 'da-DK'
    ProductKey        = 'VK7JG-NPHTM-C97JM-9MPGT-3V66T'
    DiskTemplate      = 'UEFI'
    SkipOOBE          = $true
    LocalUserToAdd    = 'AdminUser'
    LocalUserPassword = 'Pa$$w0rd'
}
New-UnattendBuilder @BuilderParams | Export-UnattendFile -FilePath "$HOME\Desktop\Autounattend.xml"
```
You can also import existing unattend files, which can then be modified by the same commands you would normally use to build one:
```
New-UnattendBuilder -SourceFile C:\Template.xml |
  Set-UnattendProductKey -ProductKey XGVPP-NMH47-7TTHJ-W3FW7-8HV2C |
  Export-UnattendFile -FilePath "$HOME\Desktop\unattend.xml"
```

# Adding additional commands
Unattend files allow you to configure a lot of different settings and this module only covers a subset of all the possible settings, so what should you do if a setting is missing?
You have 3 options:
1. Create an unattend file with the missing settings and use that as a template for `New-UnattendBuilder`
2. Open an issue in this repository and wait for me (or someone else) to fix it.
3. Create your own functions to modify the missing settings and (ideally) create a PR so other people can enjoy those changes as well.

If you want to create your own functions you need to add `using module UnattendXmlBuilder` at the top of the file containing the functions.
Then you can add an `UnattendBuilder` parameter to your function like this:
```
param
(
    [Parameter(Mandatory, ValueFromPipeline)]
    [UnattendBuilder]
    $UnattendBuilder
)
```
This will allow you to use all the helper methods from `$UnattendBuilder`. Finally, make sure your function outputs the `$UnattendBuilder` (and nothing else).  
If you don't plan on contributing back to this project then I would suggest using a different prefix than `Unattend` for the noun, that way future releases won't conflict with your local implementation.