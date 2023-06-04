using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Adds commands that are run automatically at logon, or during the installation.

.DESCRIPTION
    Adds commands that are run automatically at logon, or during the installation.
    Commands can be set to run at first login, or on every login.
    Multiple commands can be specified at once, but if more specific settings need to be specified (different descriptions) then you can run this command multiple times to add each command.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass where the commands should run.
    Valid values are:
    windowsPE
    specialize (default)
    auditUser

.PARAMETER FirstLogonCommand
    Specifies that the command should only run the first time a user logs in.

.PARAMETER LogonCommand
    Specifies that the command is persistent, and should run every time a user logs in.

.PARAMETER Async
    Specifies that the command is run asynchronously so the logon process can finish quicker.

.PARAMETER RequiresUserInput
    Specifies that the command requires user input.

.PARAMETER RebootBehavior
    Controls how rebooting should be handled.
    Valid values are:
    Never - Never reboot the system.
    Always - Always reboot the system after this command.
    OnRequest - Reboot if the command returns with specific exit codes (1, 2)

.PARAMETER Command
    Specifies the command line to run.

.PARAMETER Description
    Specifies a description for the command.

.PARAMETER RunAsCredential
    Specifies alternative credentials that the command should run as.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Add-UnattendCommand
{
    [CmdletBinding(DefaultParameterSetName = 'Default', PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('windowsPE', 'specialize', 'auditUser')]
        [string]
        $Pass = 'specialize',

        [Parameter(Mandatory, ParameterSetName = 'FirstLogon')]
        [switch]
        $FirstLogonCommand,

        [Parameter(Mandatory, ParameterSetName = 'LogonPersistent')]
        [switch]
        $LogonCommand,

        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $Async,

        [Parameter(ParameterSetName = 'FirstLogon')]
        [Parameter(ParameterSetName = 'LogonPersistent')]
        [switch]
        $RequiresUserInput,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('Never', 'Always', 'OnRequest')]
        [string]
        $RebootBehavior,

        [Parameter(Mandatory)]
        [string[]]
        $Command,

        [Parameter()]
        [string]
        $Description,

        [Parameter(ParameterSetName = "Default")]
        [pscredential]
        $RunAsCredential
    )
    process
    {
        if ($FirstLogonCommand)
        {
            $Component         = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', 'oobeSystem')
            $ParentElementName = 'FirstLogonCommands'
            $ElementName       = 'SynchronousCommand'
            $CmdElementName    = 'CommandLine'
        }
        elseif ($LogonCommand)
        {
            $Component         = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', 'oobeSystem')
            $ParentElementName = 'LogonCommands'
            $ElementName       = 'AsynchronousCommand'
            $CmdElementName    = 'CommandLine'
        }
        else
        {
            $CmdElementName = 'Path'
            if ($Pass -eq "windowsPE")
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Setup', 'WindowsPE')
            }
            else
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Deployment', $Pass)
            }

            if ($Async)
            {
                $ParentElementName = 'RunAsynchronous'
                $ElementName = 'RunAsynchronousCommand'
            }
            else
            {
                $ParentElementName = 'RunSynchronous'
                $ElementName = 'RunSynchronousCommand'
            }
        }

        $ParentElement = $UnattendBuilder.GetOrCreateChildElement($ParentElementName, $Component)
        $CommandCounter = $ParentElement.ChildNodes.Count + 1

        foreach ($Cmd in $Command)
        {
            $CommandElement = $ParentElement.AppendChild($UnattendBuilder.CreateElement($ElementName, @{action = 'add'}))
            $UnattendBuilder.CreateAndAppendElement($CmdElementName, $Cmd, $CommandElement)
            $UnattendBuilder.CreateAndAppendElement('Order', ($CommandCounter++), $CommandElement)

            switch ($PSBoundParameters.Keys)
            {
                'RequiresUserInput'
                {
                    $UnattendBuilder.CreateAndAppendElement('RequiresUserInput', $RequiresUserInput, $CommandElement)
                    continue
                }
                'RebootBehavior'
                {
                    if ($Async)
                    {
                        Write-Warning "$_ cannot be set for async commands. Skipping this property."
                    }
                    elseif ($Pass -eq "windowsPE")
                    {
                        Write-Warning "$_ cannot be set for WinPE commands. Skipping this property."
                    }
                    else
                    {
                        $UnattendBuilder.CreateAndAppendElement('WillReboot', $RebootBehavior, $CommandElement)
                    }
                    continue
                }
                'Description'
                {
                    $UnattendBuilder.CreateAndAppendElement('Description', $Description, $CommandElement)
                    continue
                }
                'RunAsCredential'
                {
                    $UnattendBuilder.AddCredentialToElement($RunAsCredential, $CommandElement)
                    continue
                }
            }
        }

        $UnattendBuilder
    }
}