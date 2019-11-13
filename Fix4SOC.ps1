# Fix4SOC
# V1.0.0
# 5/23/2017
# Ward Lange
#
# Will search through all deployments for SOC packages performed by Console Lite.  
# If re-run behavior is rerun on failure, it will set the deployment to always rerun
# This will allow the same machine to rerun the package on subsequent advertisements

param([String]$SiteServer)

write-host $SiteServer

#Get Provider Site Code from Site Server
$Provider=Get-WmiObject -ComputerName $SiteServer -Namespace ROOT\SMS -Query "Select SiteCode from SMS_ProviderLocation"
$SiteCode=$Provider.SiteCode
write-host $SiteCode

#Get the CategoryID for the SOC security scope
$SOCCategory= Get-WmiObject -ComputerName $SiteServer -Namespace "ROOT\SMS\SITE_$($SiteCode)" -Query "Select CategoryID from SMS_SecuredCategory where CategoryName='SOC' "
$CategoryID=$SOCCategory.CategoryID


#Find ConsoleLite Deployments for packages matching the CategoryID for SOC security scope
$Deployments=Get-WmiObject -ComputerName $SiteServer -Namespace "ROOT\SMS\SITE_$($SiteCode)" -Query "Select * from SMS_Advertisement where comment like '%Console_Lite%' and packageID in (Select objectkey from SMS_SecuredCategoryMembership where ObjectTypeID=2 and CategoryID='$($CategoryID)')"

#Cycle through each advertisement and examine RemoteClienFlags
Foreach ($Ad in $Deployments)  
{ Write-host $Ad.PackageID $Ad.AdvertisementID $Ad.AdvertisementName $Ad.AdvertFlags $ad.OfferType $ad.path

$RemoteClientFlags=$Ad.RemoteClientFlags

If (($RemoteClientFlags -band 2048) -ne 2048)
{
  if (($RemoteClientFlags -band 4096) -eq 4096) {$RemoteClientFlags=$RemoteClientFlags-4096}
  if (($RemoteClientFlags -band 8192) -eq 8192) {$RemoteClientFlags=$RemoteClientFlags-8192}
  if (($RemoteClientFlags -band 16384) -eq 16834) {$RemoteClientFlags=$RemoteClientFlags-16384}
  $RemoteClientFlags+=2048
  $Comment=$Ad.Comment + " *SOC*"
  Set-WmiInstance -path $ad.path -Arguments @{RemoteClientFLags=$RemoteClientFlags;Comment=$Comment}
}
 }


#RemoteClientFlags  BitWise settings
#2048 - AlwaysReRun
#4096 - Never Rerun
#8192 - Rerun on Failure
#16464 - Rerun on Success


