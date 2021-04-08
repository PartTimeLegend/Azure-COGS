<#
.SYNOPSIS
  Starts and stops resources based on a day of the week and a time setting.
.DESCRIPTION
  Starts and stops resources based on a day of the week and a time setting.
.PARAMETER $dryRun if true no resources will be altered.
.PARAMETER $prefix a prefix for the tags such as COGS_ can be used for multiple sets of similar tags.
.NOTES
  Version:        1.0
  Author:         Antony Bailey
  Creation Date:  2021/04/07
  Purpose/Change: Initial script development
  
.EXAMPLE
  ./Runner.ps1 -dryRun 1 -prefix "COGS_"
#>
param(  
  [Parameter(Mandatory=$true)][bool]$dryRun=$true,
  [Parameter(Mandatory=$false)][string]$prefix
)
$startDaysTagKey = "${prefix}StartDays"
$stopDaysTagKey = "${prefix}StopDays"
$apimDaySku = "Basic"
$apimNightSku = "Developer"
$resources = Get-AzResource
$currentDay = (Get-Date -Format dddd)
function Get-AzVMStatus
{
  param(  
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$vmName
  )
  return (Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Status).Statuses[1].DisplayStatus
}
function StartResource
{
  param(  
    [Parameter(Mandatory=$true)]$resource
  )
  Write-FormattedOutput "INFO: Starting or scaling up resouce ${resource.ResourceId}" -ForegroundColor "Green"
  switch ($resource.ResourceType)
  {
    "Microsoft.Compute/virtualMachines" 
    {
      if (Get-AzVMStatus $resource.ResourceGroupName $resource.Name -ne "VM running")
      {
        Start-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
      }
    }   
    "Microsoft.ApiManagement/service"
    {
      # Scale up not create
      $apim = Get-AzApiManagement -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
      $apim.Sku = $apimDaySku
      Set-AzApiManagement -InputObject $apim
    }     
  }
}
function StopResource
{
  param(  
    [Parameter(Mandatory=$true)]$resource
  )
  Write-FormattedOutput "INFO: Stopping, deleting, or scaling down resouce ${resource.ResourceId}" -ForegroundColor "Green"
  switch ($resource.ResourceType)
  {
    "Microsoft.Compute/virtualMachines" 
    {
      if (Get-AzVMStatus $resource.ResourceGroupName $resource.Name -eq "VM running")
      {
        Stop-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
      }
    }
    "Microsoft.Web/sites"
    {
      Remove-AzWebApp -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.Storage/storageContainers"
    {
      Remove-AzStorageContainer -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.Storage/storageAccounts"
    {
      Remove-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.SignalRService/SignalR"
    {
      Remove-AzSignalR -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.Sql/servers/databases"
    {
      Remove-AzSqlDatabase -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.ServerName -DatabaseName $resouce.DatabaseName
    }
    "Microsoft.Sql/servers"
    {
      Remove-AzSqlServer  -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.Insights/components"
    {
      Remove-AzApplicationInsights -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.Web/serverFarms"
    {
      Remove-AzAppServicePlan -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.DocumentDb/databaseAccounts"
    {
      Remove-AzCosmosDBAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.Search/searchServices"
    {
      Remove-AzSearchService -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.ServiceBus/namespaces"
    {
      Remove-AzServiceBusNamespace -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
    "Microsoft.ApiManagement/service"
    {
      # Scale down not delete.
      $apim = Get-AzApiManagement -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
      $apim.Sku = $apimNightSku
      Set-AzApiManagement -InputObject $apim
    }
  }
}
function Write-FormattedOutput
{
    [CmdletBinding()]
    Param(
         [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][Object] $Object,
         [Parameter(Mandatory=$False)][ConsoleColor] $BackgroundColor,
         [Parameter(Mandatory=$False)][ConsoleColor] $ForegroundColor
    )    

    # save the current color
    $bc = $host.UI.RawUI.BackgroundColor
    $fc = $host.UI.RawUI.ForegroundColor

    # set the new color
    if($BackgroundColor -ne $null)
    { 
       $host.UI.RawUI.BackgroundColor = $BackgroundColor
    }

    if($ForegroundColor -ne $null)
    {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    Write-FormattedOutput $Object
  
    # restore the original color
    $host.UI.RawUI.BackgroundColor = $bc
    $host.UI.RawUI.ForegroundColor = $fc
}
foreach ($resource in $resources)
{
  $startDaysValue = $resource.Tags[$startDaysTagKey]
  $stopDaysValue = $resource.Tags[$stopDaysTagKey]
  # Check for commented out. # will not be shutdown or started. These are manual ONLY.
  if ($startDaysValue -like '#' -or $stopDaysValue -like '#') 
  {  
    Write-FormattedOutput "INFO: The resource $resource.ResouceId is exempt from start / stop functionality." -$ForegroundColor "Green"
    Write-FormattedOutput "INFO: The Start Days were ${startDaysValue} and the Stop Days were ${stopDaysValue} a # indicates skip." -$ForegroundColor "Green"
    return 0
  }
  # Is today a day we do this for this resource?
  elseif ($startDaysValue -like $currentDay)
  {
    # We do this a lot, but the time might tick onwards during a run and some resources start.
    $currentUtcTimeofDay = (Get-Date).ToUniversalTime().TimeOfDay
    $startTimeValue = $resource.Tags["${prefix}StartTime"]
    $stopTimeValue = $resource.Tags["${prefix}StartTime"]
    $startTimeOfDay = [DateTime]::ParseExact($startTimeValue,"HH:mm",$null).TimeOfDay
    $stopTimeOfDay = [DateTime]::ParseExact($stopTimeValue,"HH:mm",$null).TimeOfDay
    if ($currentUtcTimeofDay -ge $startTimeOfDay -and $currentUtcTimeofDay -lt $stopTimeOfDay)
    {
      # Start this resource
      StartResource $resource
    }
    elseif ($currentUtcTimeofDay -lt $startTimeOfDay -and $currentUtcTimeofDay -ge $stopTimeOfDay)
    {
      # Stop this resource
      StopResource $resouce
    }
    else
    {
      Write-FormattedOutput "ERROR: Some made up date happened." -$BackgroundColor "Red"
      Write-FormattedOutput "ERROR: Resource is ${resource.ResourceId}." -$BackgroundColor "Red"
      Write-FormattedOutput "ERROR: Current UTC Time of Day ${currentUtcTimeofDay}, Start Time Of Day ${startTimeOfDay}, Stop Time Of Day ${stopTimeOfDay}." -$ForegroundColor "Red"
      Write-FormattedOutput "ERROR: You might want to find this." -$BackgroundColor "Red"
    }
  }
}