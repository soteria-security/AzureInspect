# Check if SQL databases have TDE enabled
$findings = @()
Get-AzSqlServer | ForEach-Object {
    $server = $_
    Get-AzSqlDatabase -ServerName $_.ServerName -ResourceGroupName $_.ResourceGroupName | 
    Where-Object { $_.DatabaseName -ne "master" } | ForEach-Object {
        $tde = Get-AzSqlDatabaseTransparentDataEncryption -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName -DatabaseName $_.DatabaseName
        if ($tde.State -ne "Enabled") {
            $findings += [PSCustomObject]@{
                Severity = "High"
                Resource = "$($server.ServerName)/$($_.DatabaseName)"
                Finding = "SQL database does not have TDE enabled"
            }
        }
    }
}
$findings
