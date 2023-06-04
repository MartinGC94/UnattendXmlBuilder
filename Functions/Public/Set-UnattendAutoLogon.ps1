using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures the autologon user details, and whether or not autologon is enabled.

.DESCRIPTION
    Configures the autologon user details, and whether or not autologon is enabled.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command should apply to.
    Valid values are:
    specialize
    auditSystem
    oobeSystem (default)

.PARAMETER UserDomain
    Specifies the domain that the autologon user is a member of.

.PARAMETER UserName
    Specifies the username of the autologon user.

.PARAMETER Password
    Specifies the password of the autologon user.

.PARAMETER PasswordAsPlainText
    Specifies that the password should be stored as plaintext in the unattend file.

.PARAMETER SkipPasswordEncoding
    Specifies that this command should not encode the password, useful if you want to add a password that has already been encoded.

.PARAMETER DisableAutoLogon
    Disables autologon.

.PARAMETER LogonCount
    Specifies how many times the user should log in automatically.
    This is useful when running multiple setup scripts that require reboots.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendAutoLogon
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet("specialize", 'auditSystem', 'oobeSystem')]
        [string[]]
        $Pass = "oobeSystem",

        [Parameter()]
        [string]
        $UserDomain,

        [Parameter(Mandatory)]
        [string]
        $UserName,

        [Parameter()]
        [string]
        $Password,

        [Parameter()]
        [switch]
        $PasswordAsPlainText,

        [Parameter()]
        [switch]
        $SkipPasswordEncoding,

        [Parameter()]
        [switch]
        $DisableAutoLogon,

        [Parameter()]
        [uint32]
        $LogonCount
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $PassName)
            $AutoLogon = $UnattendBuilder.GetOrCreateChildElement('AutoLogon', $Component)
            switch ($PSBoundParameters.Keys)
            {
                'UserDomain'
                {
                    $UnattendBuilder.SetElementValue("Domain", $UserDomain, $AutoLogon)
                    continue
                }
                'UserName'
                {
                    $UnattendBuilder.SetElementValue("Username", $UserName, $AutoLogon)
                    continue
                }
                'Password'
                {
                    $PasswordElement = $UnattendBuilder.GetOrCreateChildElement('Password', $AutoLogon)
                    $PW = if ($PasswordAsPlainText -or $SkipPasswordEncoding)
                    {
                        $Password
                    }
                    else
                    {
                        EncodeUnattendPassword -Password $Password -Kind UserAccount
                    }
                    $UnattendBuilder.SetElementValue('Value', $PW, $PasswordElement)
                    $UnattendBuilder.SetElementValue('PlainText', $PasswordAsPlainText, $PasswordElement)
                }
                'LogonCount'
                {
                    $UnattendBuilder.SetElementValue("LogonCount", $LogonCount, $AutoLogon)
                    continue
                }
            }

            $UnattendBuilder.SetElementValue("Enabled", !$DisableAutoLogon, $AutoLogon)
        }

        $UnattendBuilder
    }
}