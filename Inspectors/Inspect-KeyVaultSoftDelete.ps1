# Check if Key Vaults have soft delete enabled
$findings = @()
Get-AzKeyVault | ForEach-Object {
    $vault = Get-AzKeyVault -VaultName $_.VaultName
    if (-not $vault.EnableSoftDelete) {
        $findings += [PSCustomObject]@{
            Severity = "Medium"
            Resource = $_.VaultName
            Finding = "Key Vault does not have soft delete enabled"
        }
    }
}
$findings
