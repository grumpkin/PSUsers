function Save-Information {
    [CmdletBinding(ConfirmImpact='Medium')]

    [OutputType([String])]
    Param (
        # A direct ADUser object, contains all necessary properties
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Microsoft.ActiveDirectory.Management.ADUser]
        $ADUser
    )

    PROCESS {
        $ADUser | Export-Clixml -Path "\\HNL-FS01\LogsDisable$\$($Identity.SamAccountName).xml" -Depth 4

        $CurrentNotes = $Identity.Info

        $NewNotes = "Office Phone #: $($ADUser.OfficePhone)`r`n"
        $NewNotes += "Mobile Phone #: $($ADUser.MobilePhone)`r`n"
        $NewNotes += "Skype Phone #: $($ADUser.'msRTCSIP-Line')`r`n"

        $NewNotes += "˅--Groups removed by disable user script`r`n"
        foreach ($Group in $Identity.MemberOf)
		{
			$Group = Get-ADGroup $Group
			$NewNotes += "$($Group.Name)`r`n"
			Remove-ADGroupMember -Identity $Group -Members $Identity -Confirm:$false
		}
		$NewNotes += "˄--Groups removed by disable user script`r`n"
		$NewNotes += $CurrentNotes

        Set-ADUser -Identity $ADUser.SamAccountName -Replace @{info=$NewNotes}

        Write-Output "User information successfully saved to \\HNL-FS01\LogsDisable$\$($Identity.SamAccountName).xml"
    }
}