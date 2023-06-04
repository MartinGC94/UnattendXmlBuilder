using module ..\..\Classes\UnattendBuilder.psm1
<#
.SYNOPSIS
    Adds information about the user and organization for Windows to the unattend file.

.DESCRIPTION
    Adds information about the user and organization for Windows to the unattend file.

.PARAMETER UnattendBuilder
    The UnattendBuilder object that this should be added to.
    Create one with the command: New-UnattendBuilder

.PARAMETER Pass
    Specifies the pass this command applies to.
    By default, this is applied to the windowsPE and specialize phases.
    Valid values are:
    windowsPE
    offlineServicing
    generalize
    specialize
    auditUser
    oobeSystem

.PARAMETER Owner
    Sets the name of the end user of the computer.

.PARAMETER Organization
    Sets the organization that the computer belongs to.

.INPUTS
    [UnattendBuilder]
    Create one with the command: New-UnattendBuilder

.OUTPUTS
    [UnattendBuilder]
#>
function Set-UnattendOwnerInfo
{
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([UnattendBuilder])]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter()]
        [ValidateSet("windowsPE", "offlineServicing", "generalize", "specialize", "auditUser", "oobeSystem")]
        [string[]]
        $Pass = ("windowsPE", "specialize"),

        [Parameter()]
        [string]
        $Owner,

        [Parameter()]
        [string]
        $Organization
    )
    process
    {
        foreach ($PassName in $Pass)
        {
            if ($PassName -eq "windowsPE")
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Setup', $PassName)
                $UserData = $UnattendBuilder.GetOrCreateChildElement('UserData', $Component)
                switch ($PSBoundParameters.Keys)
                {
                    'Owner'
                    {
                        $UnattendBuilder.SetElementValue('FullName', $Owner, $UserData)
                        continue
                    }
                    'Organization'
                    {
                        $UnattendBuilder.SetElementValue('Organization', $Organization, $UserData)
                        continue
                    }
                }
            }
            else
            {
                $Component = $UnattendBuilder.GetOrCreateComponent('Microsoft-Windows-Shell-Setup', $PassName)
                switch ($PSBoundParameters.Keys)
                {
                    'Owner'
                    {
                        $UnattendBuilder.SetElementValue('RegisteredOwner', $Owner, $Component)
                        continue
                    }
                    'Organization'
                    {
                        $UnattendBuilder.SetElementValue('RegisteredOrganization', $Organization, $Component)
                        continue
                    }
                }
            }
        }

        $UnattendBuilder
    }
}