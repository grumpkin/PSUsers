New-Variable -Name UserObj -Value $null -Scope Script

function Get-HorizonUser ($Identity) {
    $Parameters = @{
        Properties = @('Description', 'Office', 'OfficePhone', 'EmailAddress', 'StreetAddress', `
            'City', 'State', 'Country', 'PostalCode', 'UserAccountControl', `
            'ScriptPath', 'HomeDrive', 'HomeDirectory', 'MobilePhone', 'Info',`
            'Title', 'Department', 'Company', 'Manager', 'MemberOf', 'LastLogonDate', `
            'MailNickname', 'ProxyAddresses', 'SamAccountType', 'TargetAddress', 'WhenCreated')
        Identity = $Identity
    }

    try {
        $Script:UserObj = Get-ADUser @Parameters -ErrorAction Stop

        Write-Verbose "Found user $($Script:UserObj.Name)"

        Write-Output $Script:UserObj
    }
    catch {
        throw "Could not find an Active Directory account for $Identity"
    }
}