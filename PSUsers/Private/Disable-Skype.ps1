function Disable-Skype {
    [CmdletBinding(ConfirmImpact='Medium')]

    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Identity')]
        [String]
        $SamAccountName,

        [Parameter()]
        [Switch]
        $Delete
    )

    PROCESS {
		$SkypeAccount = Get-CsUser -Identity $Identity 2> $null
			
		if ($SkypeAccount -and $Delete)	{
			if ($PSCmdlet.ShouldProcess($Identity,'Delete Skype account')) {
				Disable-CsUser -Identity $Identity -Confirm:$false
			}
		}
		elseif ($SkypeAccount) {
			Revoke-CsClientCertificate -Identity $Identity
			Start-Sleep -Seconds 5
			Set-CsUser -Identity $Identity -Enabled $false -LineURI $null -EnterpriseVoiceEnabled $false
		}
		else {
			Write-Warning -Message "$Identity does not have a Skype account. No changes have been made."
		}
    }
}