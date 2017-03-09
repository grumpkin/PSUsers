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
        if ($PsCmdlet.ParameterSetName -eq 'String') {
            $ADUser = Get-HorizonUser $SamAccountName
        }

        $CommonParams = @{
            Verbose = if ($PSBoundParameters['Verbose']) {$PSBoundParameters['Verbose']} else {$false}
            Confirm = if ($PSBoundParameters['Confirm']) {$PSBoundParameters['Confirm']} else {$false}
            Debug = if ($PSBoundParameters['Debug']) {$PSBoundParameters['Debug']} else {$false}
            WhatIf = if ($PSBoundParameters['WhatIf']) {$PSBoundParameters['WhatIf']} else {$false}
        }
    }

    PROCESS {
        $ADUser | Select-Object Name, Title, Office, EmailAddress, DistinguishedName | Format-List

        #TODO: figure out what to put for the first parameter. it shows when the user uses the WhatIf parameter
        if ($PSCmdlet.ShouldProcess('', 'Disable the user listed above', 'Disable Selected User')) {
            Disable-Account -ADUser $ADUser -OnPremise:$OnPremise @CommonParams
            Save-Information -ADUser $ADUser @CommonParams
            Disable-Skype -SamAccountName $ADUser.UserPrincipalName -Delete @CommonParams
            Disable-Exchange @PSBoundParameters
            Write-Host "User $($ADUser.Name) has been disabled"
        }

    }
}