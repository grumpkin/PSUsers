function Disable-Exchange {
	[CmdletBinding(SupportsShouldProcess = $true,
				   DefaultParameterSetName = 'Block',
				   ConfirmImpact = 'High')]
	Param (
		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ParameterSetName = 'Block')]
		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ParameterSetName = 'Forward')]
		[ValidatePattern('[A-Z0-9._%+-]{3,20}')]
		[Alias('SamAccountName')]
		[String]$Identity,
			
		[Parameter(Mandatory = $true,
				   ParameterSetName = 'Forward')]
		#[ValidatePattern('^[A-Z0-9._%+-]+@horizonnorth.ca$')]
        #[ValidateScript({if($_ -match '^[A-Z0-9._%+-]+@horizonnorth.ca$') {$true}})]
		[String]$ForwardingAddress,
			
		[Parameter(ParameterSetName = 'Forward')]
		[int]$DaysToForward = 30,
			
		[Parameter(ParameterSetName = 'Block')]
		[bool]$BlockEmail = $true,
			
		[Parameter(ParameterSetName = 'Block')]
		[string]$BlockDistributionGroup = 'Disabled Users',
			
		[Parameter()]
		[Switch]$OnPremise
	)
		
	BEGIN 
	{
		if ($OnPremise)
		{
			Write-Verbose -Message 'USERS: Creating and importing Exchane On-Premise session'
			$ExSession = New-PSSession -ConnectionUri http://hnlcgy-vmexch01/powershell -ConfigurationName Microsoft.Exchange
			Import-PSSession -Session $ExSession -DisableNameChecking -AllowClobber *> $null
		}
		else
		{
			Write-Verbose -Message 'USERS: Creating and importing Exchange Online session'
			$ExSession = Get-ExchangeOnlineSession -Verbose:$Verbose
			Import-PSSession -Session $ExSession -DisableNameChecking -AllowClobber  *> $null
		}
	}
	PROCESS
	{
		$Mailbox = Get-Mailbox -Identity $Identity -ErrorAction SilentlyContinue
		$Voicemail = Get-UMMailbox -Identity $Identity -ErrorAction SilentlyContinue
			
		if (-not $Mailbox)
		{
			Write-Warning -Message "Unable to find on-premise or online mailbox for $Identity.  No changes have been made."
			return
		}
			
		if ($PSCmdlet.ShouldProcess($Identity, 'Delete Mailbox'))
		{
			if ($Voicemail)
			{
				Disable-UMMailbox -Identity $Identity -KeepProperties $false -Confirm:$false > $null
			}
			if ($Mailbox -and $OnPremise)
			{
				Set-Mailbox -Identity $Identity -HiddenFromAddressListsEnabled $true
				#New-MoveRequest -Identity $SamAccountName -TargetDatabase 'DisabledUsers' > $null
					
				# Block all currently listed ActiveSync devices
				$Devices = Get-ActiveSyncDeviceStatistics –Mailbox $Identity | Select DeviceID
				if ($Devices) {	Set-CASMailbox -Identity $Identity -ActiveSyncBlockedDeviceIDs @{ Add = $Devices.DeviceID } }
					
				# Disable all services with access to mailbox (EAS,EWS,OWA,MAPI)
				Set-CASMailbox -Identity $Identity -ActiveSyncEnabled $false -OWAEnabled $false -EwsEnabled $false `
								-ECPEnabled $false -PopEnabled $false -ImapEnabled $false -MAPIEnabled $false
			}
			elseif ($Mailbox)
			{
				Set-Mailbox -Identity $Identity -Type Shared
				Set-ADUser -Identity $Identity -Replace @{msExchHideFromAddressLists=$true}
				Remove-OnlineLicenseService -Identity $Identity -Services EXCHANGE_S_ENTERPRISE -Confirm:$false -Verbose:$Verbose
					
				# Block all currently listed ActiveSync devices
				$Devices = Get-MobileDeviceStatistics –Mailbox $Identity | Select DeviceID
                if ($Devices) {	Set-CASMailbox -Identity $Identity -ActiveSyncBlockedDeviceIDs @{ Add = $Devices.DeviceID } }
					
				# Disable all services with access to mailbox (EAS,EWS,OWA,MAPI)
				Set-CASMailbox -Identity $Identity -ActiveSyncEnabled $false -OWAEnabled $false -EwsEnabled $false `
								-PopEnabled $false -ImapEnabled $false -EwsAllowMacOutlook $false -MAPIEnabled $false `
								-OWAforDevicesEnabled $false -EwsAllowOutlook $false -UniversalOutlookEnabled $false
			}
				
			if ($ForwardingAddress)
			{
				Set-Mailbox -Identity $Identity -ForwardingAddress $ForwardingAddress -DeliverToMailboxAndForward $false
				$File = Get-ForwardingDataFile -Path '\\HNL-FS01\LogsDisable$\Forwarding' -Name 'ForwardedMailboxes' -Create -Verbose:$Verbose
				Add-ForwardingData -File $File -Identity $Identity -ForwardedTo $ForwardingAddress -DaysToForward $DaysToForward -Verbose:$Verbose
			}
			elseif ($BlockEmail)
			{
				Add-ADGroupMember -Identity $BlockDistributionGroup -Members $Identity
			}
		}
	}
	END
	{
		Write-Verbose -Message 'USERS: Removing Exchange session'
		Remove-PSSession -Session $ExSession
	}
}