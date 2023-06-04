using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Configures global DNS settings.

.DESCRIPTION
    Configures global DNS settings.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command should apply to.
    Valid values are:
    windowsPE
    specialize (Default)

.PARAMETER DnsDomain
   Specifies the primary DNS domain to be used for name resolution.
   This will be used for DNS client registrations and DNS client resolution if no suffixes have been configured.

.PARAMETER DisableDomainNameDevolution
     Specifies that the name resolver does not use domain-name devolution.

.PARAMETER DnsSuffixSearchOrder
    Specifies the DNS suffixes to use when attempting to resolve hostnames without a domain.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendDnsSetting
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet('windowsPE', 'specialize')]
        [string[]]
        $Pass = 'specialize',

        [Parameter()]
        [string]
        $DnsDomain,

        [Parameter()]
        [switch]
        $DisableDomainNameDevolution,

        [Parameter()]
        [string[]]
        $DnsSuffixSearchOrder
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-DNS-Client', $PassName)
            switch ($PSBoundParameters.Keys)
            {
                'DnsDomain'
                {
                    $UnattendBuilder.SetElementValue('DNSDomain', $DnsDomain, $Component)
                    continue
                }
                'DisableDomainNameDevolution'
                {
                    $UnattendBuilder.SetElementValue('UseDomainNameDevolution', !$DisableDomainNameDevolution, $Component)
                    continue
                }
                'DnsSuffixSearchOrder'
                {
                    $SuffixElement = $UnattendBuilder.GetOrCreateChildElement('DNSSuffixSearchOrder', $Component)
                    if ($SuffixElement.HasChildNodes)
                    {
                        $SuffixElement.RemoveAll()
                    }
                    $UnattendBuilder.AddSimpleListToElement($DnsSuffixSearchOrder, 'DomainName', $SuffixElement)
                    continue
                }
            }
        }

        $UnattendBuilder
    }
}