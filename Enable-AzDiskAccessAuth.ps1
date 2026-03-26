###############################################################################
# This script pulls a list of all disks for each subscription 
# and updates the disk accessauthmode to azureactivedirectory.
#
# created_by: andrew hughes
# last_modified: 03-26-2026
# dependencies: azure powershell module (az.compute, az.accounts)
###############################################################################

#!! requires az module: install-module -name az -scope currentuser !!#

start-transcript -path "c:\windows\temp\set_disk_authmode.log"
import-module az.compute, az.accounts
connect-azaccount

$subscription_list = get-azsubscription

foreach ($subscription in $subscription_list) {
    write-output "processing subscription: $($subscription.name)"
    set-azcontext -subscriptionid $subscription.id

    $disks = get-azdisk

    foreach ($disk in $disks) {
        new-azdiskupdateconfig -dataaccessauthmode "azureactivedirectory" `
        | update-azdisk -resourcegroupname "$($disk.resourcegroupname)" -diskname "$($disk.name)"
    }
}

stop-transcript
