# Recreate the VM

$rgname = "SP-UNVM-vm1"

$loc = "Australia East"

$vmsize = "Standard_DS2_v2"

$vmname = "SP-UNVM-vm1"

$nicname = "SP-UNVM-vm1-nic1"

$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;

$nic = Get-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgname;

$nicId = $nic.Id;

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nicId;

$osDiskName = "SP-UNVM-vm1-os"

$osDiskVhdUri = "YourDiskOSUri"

$vm = Set-AzureRmVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption attach -Windows

New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $vm -Verbose