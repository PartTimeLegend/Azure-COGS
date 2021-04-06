$resources = Get-AzResource
$startDays = "Monday, Tuesday, Wednesday, Thursday, Friday"
$stopDays = "Monday, Tuesday, Wednesday, Thursday, Friday"
$startTime = "08:45"
$stopTime = "18:30"
$prefix = "${prefix}"
$dryRun = true
foreach($resource in $resources)
{
  $tags = (Get-AzTag -ResourceId $resource.Id)
  $tagsproperties = $tags.Properties
  if (!(ContainsTag $resource.id, "${prefix}StartDays"))
  {
    AddNewTags $resource.id, "${prefix}StartDays", $startDays  
  }
  if (!(ContainsTag $resource.id, "${prefix}StopDays"))
  {
    AddNewTags $resource.id, "${prefix}StopDays", $stopDays
  }
  if (!(ContainsTag $resource.id, "${prefix}StartTime"))
  {
    AddNewTags $resource.id, "${prefix}StartTime", $startTime
  }
  if (!(ContainsTag $resource.id, "${prefix}StopDays"))
  {
    AddNewTags $resource.id, "${prefix}StopTime", $stopTime
  }
}0
function ContainsTag
{
  param(
    [Parameter(Mandatory=$true)][string]$resourceId,
    [Parameter(Mandatory=$true)][string]$tag,
  )
  $tags = (Get-AzTag -ResourceId $resourceId)
  $tagsproperties = $tags.Properties
  if (!($tagsproperties.TagsProperty.ContainsKey($tag)))
  {
    Write-Host $resource.Name "has no tag called $tag"
    return true
  }
  return false
}
function AddNewTags
{
  param(
      [Parameter(Mandatory=$true)][string]$resourceId,
      [Parameter(Mandatory=$true)][string]$key,
      [Parameter(Mandatory=$trye)][string]$value
  )
  Write-Output "Attempting to tag resource $resourceId with new tag of $tag"
  if !($dryRun)
  {
    New-AzTag -ResourceId $resourceId -Tag @{$key=$value}
  }
}