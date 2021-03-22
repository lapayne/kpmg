#####################################################
# This script assumes you have already used         #
# Set-AWSCredential to store an access key and      #
#####################################################

# secret to be used

#show all availible metadata types
Get-EC2InstanceMetadata -ListCategory

$vmid = read-host "Please enter the Instance of the VM"
#prompt for the metadata required
$metadata = read-host "Please enter the metadata required from the list above"

#get the data and print to the screen
(Get-EC2Instance -InstanceID $vmid ).Instances | Get-EC2InstanceMetadata -Category $metadata