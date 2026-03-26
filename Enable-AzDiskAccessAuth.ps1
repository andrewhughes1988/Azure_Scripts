###############################################################################
# This script ingests a list of disks from a csv file and updates 
# the data access auth mode to "azureactivedirectory" for each disk.
#
# Created by: Andrew Hughes
# Last updated: 03-26-2026
###############################################################################

### requires az module: install-module -name az -scope currentuser ###

start-transcript -path "c:\windows\temp\disk_disk_set_auth.log"
import-module az.compute

### UPDATE THE INPUT FILE PATH BELOW TO POINT TO YOUR CSV FILE ###
### input csv format: subscription_id, resource_group, disk_name ###
$input_file = "c:\users\andrew\downloads\disks.csv"

connect-azaccount

if(test-path -path $input_file) {
    write-host "loading disk list from: $input_file"
} else {
    write-host "input file not found: $input_file"
    exit 1
}

try {
    $disks = import-csv -path $input_file
} catch {
    write-host "error loading csv file: $input_file"
    exit 1
}

$subscription = $disks[0].subscription_id

foreach ($disk in $disks) {

    if($disk.subscription_id -ne $subscription) {
        $subscription = $disk.subscription_id
        set-azcontext -subscriptionid $subscription
    }

new-azdiskupdateconfig -dataaccessauthmode "azureactivedirectory" | `
    update-azdisk -resourcegroupname "$($disk.resource_group)" -diskname "$($disk.disk_name)"
}

stop-transcript
