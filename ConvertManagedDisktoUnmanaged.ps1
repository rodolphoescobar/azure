# Get Access to the Managed Disk using the SAS Key

Login-AzureRmAccount

Select-AzureRmSubscription "Tecnologia - QA"

Get-AzureRmDisk -Name "Star-Dev-002" -ResourceGroupName "QUALIDADE"

Grant-AzureRmDiskAccess -DiskName "Star-Dev-002" -ResourceGroupName "QUALIDADE" -DurationInSecond 3600 -Access Read

# Get the destination details

$storageAccountName = "satvgqamig"

$storageContainerName = "vhds"

$destinationVHDFileName = "StarDev2-OSDisk.vhd"

$storageAccountKey = "7W9yFeAUHXETJR6ZTmhZFd/h9oM0v0vw2QLnypJvVE1qf54ShHIdLFDaQEb15eVTy55ojiEBcE3Hsynyv8dRwg=="

$destinationContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

$sas = "https://md-dn0s33b4lgvp.blob.core.windows.net/2vcfnfjwqlbj/abcd?sv=2017-04-17&sr=b&si=0138ccc5-6582-4577-9775-b9e38c1fcd31&sig=UrTy%2BijDfwxc7bcSHSazKbJWYm%2BKo2Fmx%2F9jI0M3NYc%3D"

# copy the vhd

Start-AzureStorageBlobCopy -AbsoluteUri $sas -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName


# Check the copy status

$status = Get-AzureStorageBlobCopyState -Blob $destinationVHDFileName -Container $storageContainerName -Context $destinationContext

$percentage = $status.BytesCopied/$status.TotalBytes*100

$percentage = "{0:N2}" -f $percentage

Write-Host -ForegroundColor Yellow "$percentage completed!"