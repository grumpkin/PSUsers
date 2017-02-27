function Disable-HorizonAccount {
    [CmdletBinding(SupportsShouldProcess = $true,
				    ConfirmImpact = 'High')]
    Param (
        # A direct ADUser object, contains all necessary properties
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ParameterSetName = 'AD')]
        [ValidateNotNull()]
        [Microsoft.ActiveDirectory.Management.ADUser]
        $ADUser,

	    # A string passed in, we need to get the ADUser object
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   ParameterSetName='String')]
        [ValidateNotNullOrEmpty()]
        [Alias('Identity')]
        [String]
        $SamAccountName,
		
	    [Parameter()]
	    [ValidatePattern('^[A-Z0-9._%+-]+@horizonnorth.ca$')]
	    [String]$ForwardingAddress,
		
	    [Parameter()]
	    [int]$DaysToForward,
		
	    # Specifies that the user is an on-premise account
        [Parameter()]
        [Switch]
        $OnPremise
    )

    BEGIN {
        if ($OnPremise) {
            $OrganizationalUnit = 'OU=Disabled Users, DC=hnl, DC=local'
        }
        if ($PsCmdlet.ParameterSetName -eq 'String') {
            $ADUser = Get-HorizonUser $SamAccountName
        }
    }

    PROCESS {
        $ADUser | Select-Object Name, Title, Office, EmailAddress, DistinguishedName | Format-List

        #TODO: figure out what to put for the first parameter. it shows when the user uses the WhatIf parameter
        if ($PSCmdlet.ShouldProcess('', 'Disable the user listed above', 'Disable Selected User')) {
            Disable-Account -ADUser $ADUser @PSBoundParameters
            Save-Information -ADUser $ADUser @PSBoundParameters
            Disable-Skype -SamAccountName $ADUser.UserPrincipalName -Delete @PSBoundParameters
            Disable-Exchange -Identity $ADUser.SamAccountName @PSBoundParameters
            Write-Host "User $($ADUser.Name) has been disabled"
        }

    }
}