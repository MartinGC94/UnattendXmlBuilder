using module ..\..\Classes\UnattendBuilder.psm1
using namespace System.Xml

function AddFirewallGroupsToElement
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [UnattendBuilder]
        $UnattendBuilder,

        [Parameter(Mandatory)]
        [XmlElement]
        $Parent,

        [Parameter(Mandatory)]
        [string[]]
        $GroupNames,

        [Parameter(Mandatory)]
        [string]
        $FirewallProfile,

        [Parameter(Mandatory)]
        [bool]
        $Active
    )
    process
    {
        foreach ($GroupName in $GroupNames)
        {
            $Attributes = [ordered]@{
                action   = 'add'
                keyValue = $GroupName
            }
            $FwGroupElement = $Parent.AppendChild($UnattendBuilder.CreateElement("FirewallGroup", $Attributes))
            $UnattendBuilder.CreateAndAppendElement("Group", $GroupName, $FwGroupElement)
            $UnattendBuilder.CreateAndAppendElement("Active", $Active, $FwGroupElement)
            $UnattendBuilder.CreateAndAppendElement("Profile", $FirewallProfile, $FwGroupElement)
        }
    }
}