<#
.Synopsis
This script is provided as an EXAMPLE to show how to CREATE a VM using existing OS and Data Disks. You can customize it according to your specific requirements.

.Description
The script will Create a VM based on Variables provided and using an existing OS and Data Disk,
that need to be ready BEFORE running this Script. 
You can modify the script to satisfy your specific requirement but please be aware of the items specified
in the Terms of Use section.

.Terms of Use
Copyright © 2016 Microsoft Corporation.  All rights reserved.

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND/OR FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

## Lines from 28 to 103 ====> Copy Disks

###################################################################################################################################################
 ###################################################################################################################################################
  ########################################## COPY DISKS FROM ASM TO ARM STORAGE ACCOUNT #############################################################
   ###################################################################################################################################################
    ###################################################################################################################################################

###################################################################################################################################################
# To login in Azure ARM and Select Specific Subscription where DESTINATION Storage Account exists
#Login-AzureRmAccount 
Select-AzureRmSubscription -SubscriptionName "Tecnologia - Produção"


##################################################################################################################################################
# To login in Azure ASM and Select Specific Subscription where SOURCE Storage Account exists
#Add-AzureAccount 
Select-AzureSubscription -SubscriptionName "Tecnologia - Produção"


###################################################################################################################################################
# Define correct values for variables that will be used for collect Disk Info
"-----------------------------------------"
"Definindo Variaveis..."
"  "
## Copy Disks variables
$CloudService = "azpaemrsr001"
$VMName = "azpaemrsr001"
$SourceSAName = "portalvhdszkx5wgr6jgk5p"
$SourceSAURI = "https://"+$SourceSAName+".blob.core.windows.net/vhdc214689551044e0fab0adbc2f40de9c2"
$SourceSAKey = (Get-AzureStorageKey -StorageAccountName $SourceSAName).Secondary
$SAName = "satvgprodmig"
$DestSAURI = "https://"+$SAName+".blob.core.windows.net/vhds"
$RGStorage = "RG-Storage"
$DestSAKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGStorage -StorageAccountName $SAName).Value[1]

## VM Creation Variables
$location = "East US 2"
$RGVM = "RG-SharePointComercial"
$RGNetwork = "RG-Network"
$SALogName = "satvgproddiag"
$vnetName = "Vnet-Producao"
$subnetName = "FrontEnd"
$AvailSetName = "azpaemrsr001-AVS"

## Define VMSize according to ASM VM Size comparation
$vmASMSize = (Get-AzureVM -ServiceName $CloudService -Name $VMName).InstanceSize
switch ($vmASMSize) {
  Standard_D2 { 
    $vmSize = "Standard_D2_v3"
    break     
  }
  Standard_A1_v2 {
    $vmSize = "Standard_D1_v2"
    break
  }
  Standard_D1 { 
    $vmSize = "Standard_D1_v2"
    break     
  }
  A5 { 
    $vmSize = "Standard_D3_v2"
    break     
  }
  Medium { 
    $vmSize = "Standard_D1_v2"
    break     
  }
  Basic_A4 { 
    $vmSize = "Standard_D3_v2"
    break     
  }
  ExtraLarge { 
    $vmSize = "Standard_D3_v2"
    break     
  }
  Large { 
    $vmSize = "Standard_D2_v3"
    break     
  }
  Small { 
    $vmSize = "Standard_D1_v2"
    break     
  }
  Basic_A3 { 
    $vmSize = "Standard_D2_v3"
    break     
  }
  default {
    $vmSize = "Standard_D1_v2"
    break
  }
}

$NICName = $vmName+"-NIC1"
#$PIPName = $vmName+"-PIP"
#$StaticIP = "172.16.0.204"


###################################################################################################################################################
# Get Viratual Machine Properties
"-----------------------------------------"
"Coletando Informacoes da VM"
" "
$vm = Get-AzureVM -ServiceName $CloudService -Name $VMName

###################################################################################################################################################
# Get OS Disk Information
"-----------------------------------------"
"Coletando Informacoes do Disco de S.O."
" "
$osDisk = Get-AzureOSDisk -VM $vm
$osBlobName = $osDisk.MediaLink.Segments[2]



###################################################################################################################################################
# Copy VM OS Disk from an Storage Account to Another
# AzCopy MUST be installed on directory specified. If is not, change the command line above, pointing it to correct AzCopy directory
"-----------------------------------------"
"Copiando Disco de Sistema Operacional ..."
" "
$OSDiskLogFile = $VMName+"-OS_Copy.Log"
C:\AzCopy\AzCopy.exe /V:$OSDiskLogFile /Source:$SourceSAURI /Dest:$DestSAURI /SourceKey:$SourceSAKey /DestKey:$DestSAKey /Pattern:$osBlobName /SyncCopy /NC:30 /Y

#Renaming disk do vmname-OSDisk.vhd
"-----------------------------------------"
"Renomeando o Disco de SO ..."
" "
$Context = New-AzureStorageContext -StorageAccountName $SAName -StorageAccountKey $DestSAKey
$newDiskName=$VMName+"-OSDisk.vhd"
Start-AzureStorageBlobCopy -SrcContainer "vhds" -DestContainer "vhds" -SrcBlob $osBlobName -DestBlob $newDiskName -Context $Context -DestContext $Context
Remove-AzureStorageBlob -Container "vhds" -Context $Context -Blob $osBlobName
$osBlobName=$newDiskName


###################################################################################################################################################
# Get Data Disk Information when VM has ONLY 01 Data Disk attached
# For VMs with Multiple Data Disks, we need to collect BlobName manually (for now)
"-----------------------------------------"
"Coletando Informações sobre o(s) Disco(s) de Dados"
" "
$DataDisks = Get-AzureDataDisk -VM $vm

if ($DataDisks -eq $null){
    "### VM Sem Disco de Dados ###"
}
Else{
    "-----------------------------------------"
    "Copiando " + $Datadisks.Count + " Disco(s) de Dados ..."
    " "
    foreach ($DataDisk in $DataDisks){
        $DataDiskBlobName = $DataDisk.MediaLink.Segments[2]
        $DataDiskLogFile = $VMName+"-DataDisks_Copy.Log"
        C:\AzCopy\AzCopy.exe /V:$DataDiskLogFile /Source:$SourceSAURI /Dest:$DestSAURI /SourceKey:$SourceSAKey /DestKey:$DestSAKey /Pattern:$DataDiskBlobName /SyncCopy /NC:30 /Y
    }
}




###################################################################################################################################################
 ###################################################################################################################################################
  ########################################## CREATE AN ARM VIRTUAL MACHINE ##########################################################################
   ###################################################################################################################################################
    ###################################################################################################################################################

# To set some common Variables that can be used in many others cmdlets


# To create a New Public IP (PIP) without associate it to anything
#"-----------------------------------------"
#"Criando o PIP ..."
#" "
#New-AzureRmPublicIpAddress -ResourceGroupName $RGVM -Name $PIPName -Location $location -AllocationMethod Dynamic

"-----------------------------------------"
"Criando a NIC ..."
" "
# To create a New Network Interface (NIC) associated to a specific Subnet and PIP, give it an Static Internal IP without associate it to a VM
#$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RGNetwork -Name $vnetName
#$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
#$pip = Get-AzureRmPublicIpAddress -ResourceGroupName $RGNetwork -Name $PIPName
#New-AzureRmNetworkInterface -ResourceGroupName $RGVM -Location $location -Name $NICName -Subnet $subnet -PublicIpAddress $pip -PrivateIpAddress $StaticIP 

# To create a New Network Interface (NIC) associated to a specific Subnet with Static IP and WITHOUT PIP
#$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RGNetwork -Name $vnetName
#$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
#New-AzureRmNetworkInterface -ResourceGroupName $RGVM -Location $location -Name $NICName -Subnet $subnet -PrivateIpAddress $StaticIP

# To create a New Network Interface (NIC) associated to a specific Subnet WITHOUT Static IP and WITHOUT PIP
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RGNetwork -Name $vnetName
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
#$pip = Get-AzureRmPublicIpAddress -ResourceGroupName $RGVM -Name $PIPName
New-AzureRmNetworkInterface -ResourceGroupName $RGVM -Location $location -Name $NICName -Subnet $subnet #-PublicIpAddress $pip


# Use JUST if the AVSET was not previously created
"-----------------------------------------"
"Criando o Availability Set ..."
" "
New-AzureRmAvailabilitySet -ResourceGroupName $RGVM -Location $location -Name $AvailSetName -PlatformFaultDomainCount 3 -PlatformUpdateDomainCount 5


###################################################################################################################################################
# To create a New Virtual Machine
# We need to create SOME/MANY variables to specify major properties, 
# Then, create a new variable that will have all VM configs, and then create a new VM using that config variable
"-----------------------------------------"
"Criando a VM ..."
" "
$nic = Get-AzureRmNetworkInterface -ResourceGroupName $RGVM -Name $NICName
$storageacc = Get-AzureRmStorageAccount -ResourceGroupName $RGStorage -Name $SAName
$avset = Get-AzureRmAvailabilitySet -ResourceGroupName $RGVM -Name $AvailSetName
$osblobPath = "vhds/"+$osBlobName
$osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + $osblobPath
$osdiskName = $osBlobName
#$osdiskName = $vmname+"-osDisk"

$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -LicenseType "Windows_Server" -AvailabilitySetId $avset.Id
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osdiskName -VhdUri $osDiskUri -Windows -CreateOption attach

## Incluindo Discos de Dados
if ($DataDisks -eq $null){
    "### VM Sem Disco de Dados ###"
}Else{
    foreach ($DtDisk in $Datadisks){
        $DataDiskblobPath = "vhds/"+$DtDisk.MediaLink.Segments[2]
        $DataDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + $DataDiskblobPath
        $DataDiskName = $DtDisk.MediaLink.Segments[2]
        $vm = Add-AzureRmVMDataDisk -VM $vm -Name $DataDiskName -VhdUri $DataDiskUri -DiskSizeInGB $DtDisk.LogicalDiskSizeInGB -Lun $dtdisk.Lun -Caching None -CreateOption Attach
    }
}
$vm = Set-AzureRMVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $RGStorage -StorageAccountName $SALogName

New-AzureRmVM -ResourceGroupName $RGVM -Location $location -VM $vm -Verbose


###################################################################################################################################################
 ###################################################################################################################################################
  ########################################## MIGRATING VM DISKS TO MANAGED DISKS ####################################################################
   ###################################################################################################################################################
    ###################################################################################################################################################

#"-----------------------------------------"
#"Convertendo os Discos em  a VM ..."
#" "
#Stop-AzureRmVM -ResourceGroupName $RGVM -Name $VMName -Force
#Update-AzureRmAvailabilitySet -AvailabilitySet $avSet -Sku Aligned 
#ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $RGVM -VMName $VMName
#Start-AzureRmVM -ResourceGroupName $RGVM -Name $VMName