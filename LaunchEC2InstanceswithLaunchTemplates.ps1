#Requires -Module AWSPowershell
#Requires -Version 5.0

<#
This script will automatically launch 2 EC2 instances in your AWS account. The instances are launched using LaunchTemplates that are
defined already and the script is using the launch template names.

The script will also gather the 1st instances private IPv4 address and use that value to create a tag for the 2nd ec2 instance.

Finally, an output of the executed operations will be displayed on the screen to give the executor an overview of operations.

Please make sure that your AWS credentials are set on the workstation that you'll be using this script.
You can use the Get-AWSCredentials cmdlet to find out what is your profile name.
This profile defines the user credentials to be able to complete the following operations of creating and launching the instances.
If the profile is not setup yet, you can use the Set-AWSCredential and Initialize-AWSDefaultConfiguration cmdlets to configure your account.
You can also follow the instructions from this article to set it up;
https://docs.aws.amazon.com/powershell/latest/userguide/specifying-your-aws-credentials.html

**** DO NOT FORGET TO MODIFY $awsProfileName VARIABLE WITH YOUR PROFILE NAME IN THIS SCRIPT ***
#>

$awsProfileName = "myprofilename"

try {
    if (! (Get-AWSCredentials -ProfileName $awsProfileName) ) {
        Write-Output "Your profile name is invalid or doesn't exist! Please make sure you set your AWSCredentials before using this script!"
        Break
    }
    else {
        Write-Output "$awsProfileName AWS profile name seems to be present. This script will continue using this AWSProfile."
        
        # Just give some time to user to see which profile is being used
        Start-Sleep -Seconds 3
    }
}
catch { Write-Output "An error has occured while trying to find your AWSProfile, please make sure your profile exists and configured properly." }

# Prepare LaunchTemplate to be used. Launch templates are very useful to keep consistency when launching new instances.
# With pre-defined instances types, VPC, tags and other properties, it's very useful to keep resources with in a standard.

# LaunchTemplate for your first instance
$LaunchTemplate1 = New-Object -TypeName Amazon.EC2.Model.LaunchTemplateSpecification
$LaunchTemplate1.LaunchTemplateName = "MyLaunchTemplateName1"
$LaunchTemplate1.Version = 4

# Launch a new instance based on launchtemplate1 defined earlier, set a subnet ID in your vpc and grab instance info.
$Instance1Info = (New-EC2Instance -LaunchTemplate $LaunchTemplate1 -SubnetID subnet-xxxxxxid -ProfileName $awsProfileName).instances

# Get the launched EC2 Instance IP Address to be used later
$Instance1IP = $Instance1Info.PrivateIpAddress

# LaunchTemplate for a second EC2 Instance
$LaunchTemplate2 = New-Object -TypeName Amazon.EC2.Model.LaunchTemplateSpecification
$LaunchTemplate2.LaunchTemplateName = "MyLaunchTemplateName2"
$LaunchTemplate2.Version = 5

# Prepare the tag recuperated from the first instance to be used with the 2nd Instance. This part creates a tag called "FirstInstanceIP" and sets the value
# gathered earlier from the first instance IP address as a tag in this second instance.
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "FirstInstanceIP"
$tag.Value = $Instance1IP

# Launch a new instance based on launchtemplate2 defined earlier, set a subnet ID in your vpc and grab instance info.
$Instance2Info = (New-EC2Instance -LaunchTemplate $LaunchTemplate2 -SubnetID subnet-xxxxxxid -ProfileName $awsProfileName).instances

# Set the Instance ID of the second instance in a variable to later use it with the tag.
$Instance2ID = $Instance2Info.instanceID
New-EC2Tag -Resource $Instance2ID -Tag $tag -ProfileName $awsProfileName

# Output the summary of the operations

$instance2Table = @()

$instance2Table += [PSCustomObject] @{
    Instance2IP                 = $Instance2Info.PrivateIpAddress
    Instance2ID                 = $Instance2Info.instanceID
    Instance2State              = ($Instance2Info | Select-Object State -ExpandProperty State).Name
    Instance2Type               = $Instance2Info.InstanceType
    Instance2Platform           = $Instance2Info.Platform
    Instance2SubnetID           = $Instance2Info.SubnetID
    Instance2VpcID              = $Instance2Info.VpcID
    Instance2ImageID            = $Instance2Info.ImageID
}

$instance1Table = @()

$instance1Table += [PSCustomObject] @{
    Instance1IP                = $Instance1Info.PrivateIpAddress
    Instance1InstanceID        = $Instance1Info.instanceID
    Instance1InstanceState     = ($Instance1Info | Select-Object State -ExpandProperty State).Name
    Instance1InstanceType      = $Instance1Info.InstanceType
    Instance1Platform          = $Instance1Info.Platform
    Instance1SubnetID          = $Instance1Info.SubnetID
    Instance1VpcID             = $Instance1Info.VpcID
    Instance1ImageID           = $Instance1Info.ImageID
}

Write-Output "See the summary of all operations below. If you do not see any output, please logon to your AWS Dashboard to see if your instances are started!"
$instance2Table
$instance1Table
