<#
.SYNOPSIS
  Tag all resources that do not currently have a set of start and stop tags with them.
.DESCRIPTION
  Tag all resources that do not currently have a set of start and stop tags with them.
.PARAMETER $startDays days of the week to start resources.
.PARAMETER $stopDays days of the week to stop resources.
.PARAMETER $startTime time of day to start resources.
.PARAMETER $stopTime time of day to stop resources.
.PARAMETER $dryRun if true no tags will be added to Azure.
.PARAMETER $prefix a prefix for the tags such as COGS_ can be used for multiple sets of similar tags.
.NOTES
  Version:        1.0
  Author:         Antony Bailey
  Creation Date:  2021/04/06
  Purpose/Change: Initial script development
  
.EXAMPLE
  ./TagUntagged.ps1 -startDays "Monday Tuesday Wednesday Thursday Friday" -stopDays "Monday Tuesday Wednesday Thursday Friday" -startTime "08:45" -stopTime "18:30" -dryRun 1 -prefix "COGS_"
#>
[CmdletBinding()]
param(  
  [Parameter(Mandatory=$true)][string]$startDays,
  [Parameter(Mandatory=$true)][string]$stopDays,
  [Parameter(Mandatory=$true)][string]$startTime,
  [Parameter(Mandatory=$true)][string]$stopTime,
  [Parameter(Mandatory=$true)][bool]$dryRun,
  [Parameter(Mandatory=$false)][string]$prefix
)
function ContainsTag
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$resourceId,
    [Parameter(Mandatory=$true)][string]$tag
  )
  $tags = (Get-AzTag -ResourceId $resourceId)
  $tagsproperties = $tags.Properties
  if (!($tagsproperties.TagsProperty.ContainsKey($tag)))
  {
    Write-Host $resource.Name "has no tag called $tag"
    return $false
  }
  return $true
}
function AddNewTags
{
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)][string]$resourceId,
      [Parameter(Mandatory=$true)][string]$key,
      [Parameter(Mandatory=$true)][string]$value
  )
  $newTag = @{$key=$value}
  Write-Output "Attempting to tag resource $resourceId with new tag of $key $value"
  if (!($dryRun))
  {
    New-AzTag -ResourceId $resourceId -Tag $newTag
  }
}
$resources = Get-AzResource
foreach($resource in $resources)
{
  if ((ContainsTag $resource.ResourceId "${prefix}StartDays") -eq $false)
  { 
    AddNewTags $resource.ResourceId "${prefix}StartDays" $startDays
  }
  if ((ContainsTag $resource.ResourceId "${prefix}StopDays") -eq $false)
  {
    AddNewTags $resource.ResourceId "${prefix}StopDays" $stopDays
  }
  if ((ContainsTag $resource.ResourceId "${prefix}StartTime") -eq $false)
  {
    AddNewTags $resource.ResourceId "${prefix}StartTime" $startTime
  }
  if ((ContainsTag $resource.ResourceId "${prefix}StopDays") -eq $false)
  {
    AddNewTags $resource.ResourceId "${prefix}StopTime" $stopTime
  }
}