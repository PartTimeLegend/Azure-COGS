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
  [Parameter(Mandatory=$false)][string]$prefix,
)
$startDaysTagKey = "${prefix}StartDays"
$stopDaysTagKey = "${prefix}StopDays"
$resources = Get-AzResource
$currentDay = (Get-Date -Format dddd)
function Get-AzVMStatus
{
  param(  
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$vmName,
  )
  return (Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Status).Statuses[1].DisplayStatus
}
foreach ($resource in $resources)
{
  $startDaysValue = $resource.Tags[$startDaysTagKey]
  $stopDaysValue = $resource.Tags[$stopDaysTagKey]
  # Check for commented out. # will not be shutdown or started. These are manual ONLY.
  if ($startDaysValue -like '#' or $stopDaysValue -like '#') 
  {  
    Write-Output "INFO: The resource $resource.ResouceId is exempt from start / stop functionality." 
    Write-Output "INFO: The Start Days were ${startDaysValue} and the Stop Days were ${stopDaysValue} a # indicates skip."
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
      # Start these resources
      switch ($resource.ResourceType)
      {
        "Microsoft.Compute/virtualMachines" 
        {
          if (Get-AzVMStatus $resource.ResourceGroupName $resource.Name -ne "VM running")
          {
            Start-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
          }
        }        
      }
    }
    elseif ($currentUtcTimeofDay -lt $startTimeOfDay -and $currentUtcTimeofDay -ge $stopTimeOfDay)
    {
      # Stop these resources
      switch ($resource.ResourceType)
      {
        "Microsoft.Compute/virtualMachines" 
        {
          if (Get-AzVMStatus $resource.ResourceGroupName $resource.Name -eq "VM running")
          {
            Stop-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
          }
        }        
      }
    }
    else
    {
      Write-Output "ERROR: Some made up date happened."
      Write-Output "ERROR: Resource is ${resource.ResourceId}."
      Write-Output "ERROR: Current UTC Time of Day ${currentUtcTimeofDay}, Start Time Of Day ${startTimeOfDay}, Stop Time Of Day ${stopTimeOfDay}."
      Write-Output "ERROR: You might want to find this."
    }
  }
}