$CultureCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $TrimmedWord = $wordToComplete.Trim(("'",'"'))
    foreach ($Culture in [cultureinfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures))
    {
        if ($Culture.Name -ne "" -and $Culture.Name -like "$TrimmedWord*")
        {
            $CompletionText = $Culture.Name
            $ListItemText   = $Culture.Name
            $ResultType     = [System.Management.Automation.CompletionResultType]::ParameterValue
            $ToolTip        = $Culture.DisplayName
            [System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
        }
    }
}
Register-ArgumentCompleter -CommandName New-UnattendBuilder,Set-UnattendLanguageSetting -ParameterName UiLanguage      -ScriptBlock $CultureCompleter
Register-ArgumentCompleter -CommandName New-UnattendBuilder,Set-UnattendLanguageSetting -ParameterName SystemLocale    -ScriptBlock $CultureCompleter
Register-ArgumentCompleter -CommandName New-UnattendBuilder,Set-UnattendLanguageSetting -ParameterName InputLocale     -ScriptBlock $CultureCompleter
Register-ArgumentCompleter -CommandName Set-UnattendLanguageSetting                     -ParameterName SetupUiLanguage -ScriptBlock $CultureCompleter
Register-ArgumentCompleter -CommandName Set-UnattendLanguageSetting                     -ParameterName UserLocale -ScriptBlock $CultureCompleter

Register-ArgumentCompleter -CommandName New-UnattendBuilder,Set-UnattendProductKey -ParameterName ProductKey -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $TrimmedWord = $wordToComplete.Trim(("'",'"'))
    $WindowsKeyTable = [ordered]@{
        Win10Home            = 'YTMG3-N6DKC-DKB77-7M9GH-8HVX7'
        Win10Pro             = 'VK7JG-NPHTM-C97JM-9MPGT-3V66T'
        Win10Edu             = 'YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY'
        Win10Enterprise      = 'XGVPP-NMH47-7TTHJ-W3FW7-8HV2C'
        Server2016Standard   = 'WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY'
        Server2016Datacenter = 'CB7KF-BWN84-R7R2Y-793K2-8XDDG'
        Server2019Standard   = 'N69G4-B89J2-4G8F4-WWYCC-J464C'
        Server2019Datacenter = 'WMDGN-G9PQG-XVVXX-R3X43-63DFG'
        Server2022Standard   = 'VDYBN-27WPP-V4HQT-9VMD4-VMK7H'
        Server2022Datacenter = 'WX4NM-KYWYW-QJJR4-XV3QB-6VM33'
    }
    foreach ($Key in $WindowsKeyTable.Keys)
    {
        if ($Key -like "$TrimmedWord*")
        {
            $CompletionText = $WindowsKeyTable[$Key]
            $ListItemText   = $Key
            $ResultType     = [System.Management.Automation.CompletionResultType]::ParameterValue
            $ToolTip        = $Key
            [System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
        }
    }
}

$FwGroupCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $TrimmedWord = $wordToComplete.Trim(("'",'"'))
    $AllGroups = @'
DisplayGroup;Group
COM+ Network Access;@%systemroot%\system32\firewallapi.dll,-3400
COM+ Remote Administration;@%systemroot%\system32\firewallapi.dll,-3405
Core Networking;@FirewallAPI.dll,-25000
Core Networking Diagnostics;@FirewallAPI.dll,-27000
DHCP Server;@FirewallAPI.dll,-50209
DHCP Server Management;@FirewallAPI.dll,-50213
DIAL protocol server;@FirewallAPI.dll,-37101
Distributed Transaction Coordinator;@FirewallAPI.dll,-33502
DNS Service;@firewallapi.dll,-53012
File and Printer Sharing;@FirewallAPI.dll,-28502
File and Printer Sharing over QUIC;@FirewallAPI.dll,-28652
File and Printer Sharing over SMBDirect;@FirewallAPI.dll,-28602
File Server Remote Management;@fssmres.dll,-100
Hyper-V;@%systemroot%\system32\vmms.exe,-210
Hyper-V Management Clients;@FirewallAPI.dll,-60201
Hyper-V Replica HTTP;@%systemroot%\system32\vmms.exe,-251
Hyper-V Replica HTTPS;@%systemroot%\system32\vmms.exe,-253
iSCSI Service;@FirewallAPI.dll,-29002
Key Management Service;@FirewallAPI.dll,-28002
mDNS;@%SystemRoot%\system32\firewallapi.dll,-37302
Microsoft Media Foundation Network Source;@FirewallAPI.dll,-54001
Netlogon Service;@firewallapi.dll,-37681
Network Discovery;@FirewallAPI.dll,-32752
Performance Logs and Alerts;@FirewallAPI.dll,-34752
Remote Desktop;@FirewallAPI.dll,-28752
Remote Desktop (WebSocket);@FirewallAPI.dll,-28782
Remote Event Log Management;@FirewallAPI.dll,-29252
Remote Event Monitor;@FirewallAPI.dll,-36801
Remote Scheduled Tasks Management;@FirewallAPI.dll,-33252
Remote Service Management;@FirewallAPI.dll,-29502
Remote Shutdown;@firewallapi.dll,-36751
Remote Volume Management;@FirewallAPI.dll,-34501
Routing and Remote Access;@FirewallAPI.dll,-33752
Secure Socket Tunneling Protocol;@sstpsvc.dll,-35001
SNMP Trap;@firewallapi.dll,-50323
Windows Defender Firewall Remote Management;@FirewallAPI.dll,-30002
Windows Deployment Services;@firewallapi.dll,-38201
Windows Device Management;@FirewallAPI.dll,-37502
Windows Management Instrumentation (WMI);@FirewallAPI.dll,-34251
Windows Remote Management;@FirewallAPI.dll,-30267
Windows Remote Management (Compatibility);@FirewallAPI.dll,-30252
'@ | ConvertFrom-Csv -Delimiter ';'
    foreach ($Group in $AllGroups)
    {
        if ($Group.DisplayGroup -like "$TrimmedWord*")
        {
            $CompletionText = "'$($Group.Group)'"
            $ListItemText   = $Group.DisplayGroup
            $ResultType     = [System.Management.Automation.CompletionResultType]::ParameterValue
            $ToolTip        = $Group.DisplayGroup
            [System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
        }
    }
}
Register-ArgumentCompleter -CommandName Set-UnattendFirewallSetting -ParameterName EnabledFirewallGroups -ScriptBlock $FwGroupCompleter
Register-ArgumentCompleter -CommandName Set-UnattendFirewallSetting -ParameterName DisabledFirewallGroups -ScriptBlock $FwGroupCompleter