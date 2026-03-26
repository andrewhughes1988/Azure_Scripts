###############################################################################
# This script ingests a list of vms from a csv file, deallocates the vm
# enables encryption-at-host for each vm, then starts the vm.
#
# created_by: andrew hughes
# last_updated: 03-26-2026
# dependencies: azure powershell module (az.compute, az.accounts)
###############################################################################

start-transcript -path "c:\windows\temp\vm_encryption_at_host.log"
import-module az.compute, az.accounts

#!! input csv format: subscription_id, resource_group, vm_name !!#
$input_file = "c:\users\andrew\downloads\vms.csv"

connect-azaccount

if(test-path -path $input_file) {
    write-host "loading vm list from: $input_file"
} else {
    write-host "input file not found: $input_file"
    exit 1
}

try {
    $vm_list = import-csv -path $input_file
} catch {
    write-host "error loading csv file: $input_file"
    exit 1
}

$jobs = @()

foreach ($vm in $vm_list) {

    $job = start-job -scriptblock {
        param($vm, $subscription)

        set-azcontext -subscriptionid $subscription

        write-host "processing vm: $($vm.vm_name)"
        
        write-host "deallocating vm: $($vm.vm_name)"
        $stopresult = stop-azvm -resourcegroupname $vm.resource_group -name $vm.vm_name -force
        
        write-host "enabling encryption-at-host on vm: $($vm.vm_name)"
        $updateresult = get-azvm -resourcegroupname $vm.resource_group -name $vm.vm_name `
        | update-azvm -encryptionathost $true
        
        write-host "restarting vm: $($vm.vm_name)"
        $startresult = start-azvm -resourcegroupname $vm.resource_group -name $vm.vm_name
        write-host "completed vm: $($vm.vm_name)"

        [pscustomobject]@{
            vmname = $vm.vm_name
            stopresult = $stopresult
            updateresult = $updateresult
            startresult = $startresult
        }
    } -argumentlist $vm, $subscription

    $jobs += $job
}

wait-job -job $jobs

foreach ($job in $jobs) {
    $result = receive-job -job $job
    write-host "vm: $($result.vmname)"
    write-host "stop vmstatus: $($result.stopresult.status)"
    write-host "update successful: $($result.updateresult.issuccessstatuscode)"
    write-host "start vm status: $($result.startresult.status)"
    write-host "`n"
}

stop-transcript
