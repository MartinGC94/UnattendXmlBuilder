using namespace System
using namespace System.Text

function EncodeUnattendPassword
{
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory)]
        [string]
        $Password,

        [Parameter()]
        [ValidateSet('OfflineLocalAdmin', 'LocalAdmin', 'UserAccount')]
        [string]
        $Kind
    )
    End
    {
        $MagicString = switch ($Kind)
        {
            'OfflineLocalAdmin' {'OfflineAdministratorPassword';break}
            'LocalAdmin' {'AdministratorPassword';break}
            'UserAccount' {'Password';break}
            Default{''}
        }
        [Convert]::ToBase64String([Encoding]::Unicode.GetBytes($Password + $MagicString))
    }
}