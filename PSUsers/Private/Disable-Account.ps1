function Disable-Account {
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact='Medium')]

    [OutputType([String])]
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
        
        # The OU to move the user to when they are disabled
        [Parameter()]
        [Alias('OU')]
        [String]
        $OrganizationalUnit = 'OU=Disabled EXO Users,DC=hnl,DC=local',

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
        if ($PsCmdlet.ShouldProcess($ADUser.Name, 'Disable User Account')) {
            $DisabledTime = [DateTime]::Now.ToString()
            $DisabledUser = 'Disable user script run by ' + $ENV:USERNAME

            Set-ADUser -Identity $ADUser -Enabled $false `
            -Replace @{extensionAttribute1=$DisabledTime;`
                       extensionAttribute2=$DisabledUser}
            Move-ADObject -Identity $ADUser -TargetPath $OrganizationalUnit
            Write-Verbose "Account $($ADUser.Name) disabled and moved to $OrganizationalUnit"
        }
    }
    
    END {
        Write-Output "User $($ADUser.Name) successfully disabled"
    }
}