param (
	[Parameter(Mandatory = $true)] [String] $AzureSubscription,
    [Parameter(Mandatory = $true)] [String] $WebSite
)

if ((Test-Path "azure.err") -eq $True) {
	Write-Host "azure.err will be deleted"
	del azure.err
}

# Check if Windows Azure Powershell is avaiable
if ((Get-Module -ListAvailable Azure) -eq $null) {
    throw "Windows Azure Powershell not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools"
}

try{
	Write-Host "set subscription for PowerShell"
	Select-AzureSubscription $AzureSubscription

	Write-Host "set subscription for CLI"
	azure account set $AzureSubscription

	Write-Host "retrieve production settings for $WebSite"
	$productionWebSite = Get-AzureWebsite -Name $WebSite -slot production
	Write-Host "retrieve staging settings for $WebSite"
	$stagingWebSite = Get-AzureWebsite -Name $WebSite -slot staging

	Write-Host "set production settings for staging slot"
	Set-AzureWebsite -Name $WebSite -slot staging -AppSettings $productionWebSite.AppSettings`
		-ConnectionStrings $productionWebSite.ConnectionStrings`
		-DefaultDocuments $productionWebSite.DefaultDocuments`
		-DetailedErrorLoggingEnabled $productionWebSite.DetailedErrorLoggingEnabled`
		-HandlerMappings $productionWebSite.HandlerMappings`
		-HttpLoggingEnabled $productionWebSite.HttpLoggingEnabled`
		-RequestTracingEnabled $productionWebSite.RequestTracingEnabled

	Write-Host "swap $WebSite"
	azure site swap --quiet $WebSite
	
	Write-Host "set staging settings for $WebSite"
	Set-AzureWebsite -Name $WebSite -slot staging -AppSettings $stagingWebSite.AppSettings`
		-ConnectionStrings $stagingWebSite.ConnectionStrings`
		-DefaultDocuments $stagingWebSite.DefaultDocuments`
		-DetailedErrorLoggingEnabled $stagingWebSite.DetailedErrorLoggingEnabled`
		-HandlerMappings $stagingWebSite.HandlerMappings`
		-HttpLoggingEnabled $stagingWebSite.HttpLoggingEnabled`
		-RequestTracingEnabled $stagingWebSite.RequestTracingEnabled

	if ((Test-Path "azure.err") -eq $True) {
		Write-Host "`n`nCLI ERRORS - check azure.err for details on errors`n"
	}
	else {
		Write-Host "`n`nCLI & POWERSHELL SUCCESS - no error logged through CLI or PowerShell commands`n"	
	}
}
catch {
	Write-Host "`n`n POWERSHELL ERROR - Azure PowerShell command terminated with the following error:"
	Write-Host $_
}