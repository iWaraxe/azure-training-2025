$resourceGroup = (Get-AutomationVariable -Name 'ResourceGroup')
$enable_vm = (Get-AutomationVariable -Name 'enable_vm')
$enable_webapp = (Get-AutomationVariable -Name 'enable_webapp')
$subscription = (Get-AutomationVariable -Name 'SubscriptionId')
$tenantId = (Get-AutomationVariable -Name 'TenantId')
$credentials = (Get-AutomationPSCredential -Name "AzureAdCredentials")

# Connect to Azure and select the subscription to work against
$securityString = $credentials.GetNetworkCredential().Password | ConvertTo-SecureString -Force -AsPlainText
$credential = New-Object System.Management.Automation.PsCredential($credentials.UserName, $securityString)
$session = Get-Credential -Credential $credential

# login to azure account
Connect-AzAccount -Credential $session `
                  -TenantId $tenantId `
                  -ServicePrincipal `
                  -Subscription $subscription *>$null


$trafficManagers = Get-AzTrafficManagerProfile -ResourceGroup $ResourceGroup 

foreach($item in $trafficManagers) {

    $primaryEndpoint = $item.Endpoints | where {$_.Name -eq "primary_endpoint"}
    $secondaryEndpoint = $item.Endpoints | where {$_.Name -eq "secondary_endpoint"}

    if ("$enable_webapp" -eq "yes") {
        Write-Output "User requested to activate WebApp infrastructure"
 
        if ($primaryEndpoint.EndpointStatus -eq "Enabled") {
            Disable-AzTrafficManagerEndpoint -Name "primary_endpoint" -ProfileName $item.name -ResourceGroupName $item.ResourceGroupName -Type externalEndpoints -force
            Write-Output ("Disable primary TF endpoint" -f $item.name)
        }
    }

    if ("$enable_vm" -eq "yes") {
        Write-Output "User requested to activate VM infrastructure"

        if ($primaryEndpoint.EndpointStatus -eq "Disabled") {
            Write-Output ("Enable primary TF endpoint" -f $item.name)
            Enable-AzTrafficManagerEndpoint -Name "primary_endpoint" -ProfileName $item.name -ResourceGroupName $item.ResourceGroupName -Type externalEndpoints
        }
    }
}

