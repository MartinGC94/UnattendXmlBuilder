using module .\UnattendPass.psm1
using namespace System
using namespace System.IO
using namespace System.Collections
using namespace System.Xml

class UnattendBuilder
{
#region Properties
    hidden [xml] $UnattendXml
    hidden [XmlNamespaceManager] $NamespaceManager
    hidden [XmlElement[]] $Passes = [XmlElement[]]::new(7)
    hidden [string] $Namespace = 'builder'
#endregion

#region Constructors
    UnattendBuilder()
    {
        $Xml  = [xml]::new()
        $null = $Xml.AppendChild($Xml.CreateXmlDeclaration("1.0", 'utf-8', $null))
        $null = $Xml.AppendChild($Xml.CreateElement('unattend', "urn:schemas-microsoft-com:unattend"))
        $null = $Xml.ChildNodes[1].SetAttribute('xmlns', 'http://www.w3.org/2000/xmlns/', 'urn:schemas-microsoft-com:unattend')

        $this.UnattendXml = $Xml
        $this.SetNamespaceManager()
    }

    UnattendBuilder([xml] $LoadedXml)
    {
        $this.UnattendXml = $LoadedXml
        $this.SetNamespaceManager()
        $this.UpdatePasses()
    }

    UnattendBuilder([string] $XmlFilePath)
    {
        $Xml = [xml]::new()
        $Xml.Load($XmlFilePath)
        $this.UnattendXml = $Xml
        $this.SetNamespaceManager()
        $this.UpdatePasses()
    }
#endregion

#region Internal methods
    hidden [XmlElement] AddPass([UnattendPass] $Pass)
    {
        $NewPass = $this.UnattendXml.CreateElement("settings", 'urn:schemas-microsoft-com:unattend')
        $NewPass.SetAttribute("pass", $Pass)
        $this.Passes[$Pass.value__] = $NewPass
        return $NewPass
    }

    hidden [void] SetNamespaceManager()
    {
        $Manager = [XmlNamespaceManager]::new($this.UnattendXml.NameTable)
        $Manager.AddNamespace($this.Namespace, 'urn:schemas-microsoft-com:unattend')
        $this.NamespaceManager = $Manager
    }

    hidden [void] UpdatePasses()
    {
        foreach ($Pass in [Enum]::GetValues([UnattendPass]))
        {
            $FoundItem = $this.UnattendXml.SelectSingleNode("./$($this.Namespace):unattend/$($this.Namespace):settings[@pass = '$Pass']", $this.NamespaceManager)
            if ($null -ne $FoundItem)
            {
                $this.Passes[$Pass.value__] = $FoundItem
            }
        }
    }

    hidden [XmlElement] CreateComponent([string] $ComponentName)
    {
        return $this.CreateElement(
            "component",
            [ordered]@{
                name                  = $ComponentName
                processorArchitecture = 'amd64'
                publicKeyToken        = '31bf3856ad364e35'
                language              = 'neutral'
                versionScope          = 'nonSxS'
                'xmlns:wcm'           = 'http://schemas.microsoft.com/WMIConfig/2002/State'
                'xmlns:xsi'           = 'http://www.w3.org/2001/XMLSchema-instance'
            },
            $true
        )
    }
#endregion

#region Public methods
    [void] AddSimpleListToElement([string[]] $List, [string] $ItemName, [XmlElement] $Element)
    {
        for ($i = 0; $i -lt $List.Count; $i++)
        {
            $this.CreateAndAppendElement(
                $ItemName,
                $List[$i],
                [ordered]@{
                    action   = 'add'
                    keyValue = "$i"
                },
                $Element
            )
        }
    }

    [void] AddHashtableValuesToElement([hashtable] $Table, [XmlElement] $Element)
    {
        foreach ($Key in $Table.Keys)
        {
            $Value = $Table[$Key]

            if ($Value -is [bool])
            {
                $null = $Element.AppendChild($this.CreateElement($Key, $Value))
            }
            else
            {
                $null = $Element.AppendChild($this.CreateElement($Key, $Value))
            }
        }
    }

    [void] AddCredentialToElement([pscredential] $Credential, [XmlElement] $Element)
    {
        $CredentialsElement = $Element.AppendChild($this.CreateElement('Credentials'))
        $NetCreds = $Credential.GetNetworkCredential()
        if (![string]::IsNullOrEmpty($NetCreds.Domain))
        {
            $this.CreateAndAppendElement('Domain', $NetCreds.Domain, $CredentialsElement)
        }
        $this.CreateAndAppendElement('Username', $NetCreds.UserName, $CredentialsElement)
        $this.CreateAndAppendElement('Password', $NetCreds.Password, $CredentialsElement)
    }

    [void] SetCredentialOnElement([pscredential] $Credential, [XmlElement] $Element)
    {
        $CredentialsElement = $Element.SelectSingleNode("./$($this.Namespace):Credentials", $this.NamespaceManager)
        if ($null -eq $CredentialsElement)
        {
            $CredentialsElement = $Element.AppendChild($this.CreateElement('Credentials'))
        }
        else
        {
            $CredentialsElement = $Element.ReplaceChild($this.CreateElement('Credentials'), $CredentialsElement)
        }

        $NetCreds = $Credential.GetNetworkCredential()
        if (![string]::IsNullOrEmpty($NetCreds.Domain))
        {
            $this.CreateAndAppendElement('Domain', $NetCreds.Domain, $CredentialsElement)
        }
        $this.CreateAndAppendElement('Username', $NetCreds.UserName, $CredentialsElement)
        $this.CreateAndAppendElement('Password', $NetCreds.Password, $CredentialsElement)
    }

    [XmlElement] GetOrCreatePass([UnattendPass] $Pass)
    {
        $ReturnPass = $this.Passes[$Pass.value__]
        if ($null -eq $ReturnPass)
        {
            $ReturnPass = $this.AddPass($Pass)
        }

        return $ReturnPass
    }

    [XmlElement] GetOrCreateComponent([string] $ComponentName, [UnattendPass] $Pass)
    {
        $PassElement = $this.GetOrCreatePass($Pass)
        $ComponentElement = $PassElement.SelectSingleNode("./$($this.Namespace):component[@name='$ComponentName']", $this.NamespaceManager)
        if ($null -eq $ComponentElement)
        {
            $ComponentElement = $PassElement.AppendChild($this.CreateComponent($ComponentName))
        }

        return $ComponentElement
    }

    [XmlElement] GetOrCreateChildElement([string] $ElementName, [XmlElement] $Parent)
    {
        $ChildElement = $Parent.SelectSingleNode("./$($this.Namespace):$ElementName", $this.NamespaceManager)
        if ($null -eq $ChildElement)
        {
            $ChildElement = $Parent.AppendChild($this.CreateElement($ElementName))
        }

        return $ChildElement
    }

    [XmlElement] GetChildElementFromXpath ([string]$Path, [XmlElement] $Parent)
    {
        # The regex adds the proper namespace to each path segment that needs one.
        # Relative path segments, and special xpath function calls don't get it.
        $RealPath = $Path -replace '\/(?=\w+(?:\/|$))', "/$($this.Namespace):"
        return $Parent.SelectSingleNode($RealPath, $this.NamespaceManager)
    }

    [XmlElement] CreateElement([string] $Name)
    {
        return $this.UnattendXml.CreateElement($Name, 'urn:schemas-microsoft-com:unattend')
    }

    [XmlElement] CreateElement([string] $Name, [IDictionary] $AttributesToAdd)
    {
        return $this.CreateElement($Name, $AttributesToAdd, $false)
    }

    [XmlElement] CreateElement([string] $Name, [IDictionary] $AttributesToAdd, [bool] $NoNamespaceUri)
    {
        $Element = $this.CreateElement($Name)
        foreach ($Key in $AttributesToAdd.Keys)
        {
            if ($NoNamespaceUri)
            {
                $null = $Element.SetAttribute($Key, $AttributesToAdd[$Key])
            }
            else
            {
                $null = $Element.SetAttribute($Key, 'http://schemas.microsoft.com/WMIConfig/2002/State', $AttributesToAdd[$Key])
            }
        }
        return $Element
    }

    [XmlElement] CreateElement([string] $Name, [string] $Value)
    {
        $Element = $this.CreateElement($Name)
        $ElementValue = $this.UnattendXml.CreateTextNode($Value)
        $null = $Element.AppendChild($ElementValue)
        return $Element
    }

    [XmlElement] CreateElement([string] $Name, [string] $Value, [IDictionary] $AttributesToAdd)
    {
        $Element = $this.CreateElement($Name, $AttributesToAdd)
        $ElementValue = $this.UnattendXml.CreateTextNode($Value)
        $null = $Element.AppendChild($ElementValue)
        return $Element
    }

    [XmlElement] CreateElement([string] $Name, [bool] $Value)
    {
        return $this.CreateElement($Name, $Value.ToString().ToLower())
    }

    [void] CreateAndAppendElement([string] $Name, [IDictionary] $AttributesToAdd, [XmlElement] $Parent)
    {
        $null = $Parent.AppendChild($this.CreateElement($Name, $AttributesToAdd))
    }

    [void] CreateAndAppendElement([string] $Name, [string] $Value, [XmlElement] $Parent)
    {
        $null = $Parent.AppendChild($this.CreateElement($Name, $Value))
    }

    [void] CreateAndAppendElement([string] $Name, [string] $Value, [IDictionary] $AttributesToAdd, [XmlElement] $Parent)
    {
        $null = $Parent.AppendChild($this.CreateElement($Name, $Value, $AttributesToAdd))
    }

    [void] CreateAndAppendElement([string] $Name, [bool] $Value, [XmlElement] $Parent)
    {
        $null = $Parent.AppendChild($this.CreateElement($Name, $Value))
    }

    [void] SetElementValue([string] $Name, [string] $Value, [XmlElement] $Parent)
    {
        $Element = $this.GetOrCreateChildElement($Name, $Parent)
        if ($Element.HasChildNodes)
        {
            $null = $Element.ReplaceChild($this.UnattendXml.CreateTextNode($Value), $Element.FirstChild)
        }
        else
        {
            $null = $Element.AppendChild($this.UnattendXml.CreateTextNode($Value))
        }
    }

    [void] SetElementValue([string] $Name, [bool] $Value, [XmlElement] $Parent)
    {
        $this.SetElementValue($Name, $Value.ToString().ToLower(), $Parent)
    }

    [xml] ToXml()
    {
        foreach ($Pass in $this.Passes)
        {
            if ($null -ne $Pass)
            {
                $ExistingNode = $this.UnattendXml.SelectSingleNode("/$($this.Namespace):unattend/$($this.Namespace):settings[@pass=$($Pass.pass)]", $this.NamespaceManager)
                if ($null -eq $ExistingNode)
                {
                    $null = $this.UnattendXml.ChildNodes[1].AppendChild($Pass)
                }
            }
        }

        return $this.UnattendXml
    }

    [string] ToString()
    {
        $Xml = $this.ToXml()
        $Writer = [StringWriter]::new()
        $Xml.Save($Writer)
        $Text = $Writer.ToString()
        $Writer.Dispose()
        return $Text
    }
#endregion
}