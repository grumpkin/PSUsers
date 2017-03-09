Write-Verbose "Importing Functions"

# Import everything in sub folders folder
foreach($Folder in @('Private', 'Public', 'Classes', 'Data'))
{
    $Root = Join-Path -Path $PSScriptRoot -ChildPath $Folder
    if(Test-Path -Path $Root)
    {
        Write-Verbose "Processing Folder $Root"
        $Files = Get-ChildItem -Path $Root -Filter *.ps1

        # dot source each file
        $Files | Where-Object{ $_.Name -notlike '*.Tests.ps1'} | 
            ForEach-Object{Write-Verbose $_.Name; . $_.FullName}
    }
}

Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1").BaseName