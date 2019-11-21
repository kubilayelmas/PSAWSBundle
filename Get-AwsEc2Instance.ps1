#Requires -Modules AwsPowerShell
function Get-AwsEc2Instance {
    <#
.SYNOPSIS
    Gather AWS EC2 Instance detailed information based on a given tag.
    This function assumes that your instance is already have a tag called "hostname" with a value.
.DESCRIPTION
    Based on a given value for the hostname tag in your EC2 instance. This function will create
    a small table with useful information about your instance. It helps to visualize your instance
    details at a glance.
.EXAMPLE
    Get-AwsEc2Instance -HostnameTag myhost01 -KeyPairPath C:\mykeypairs\aws-keypair.pem
.NOTES
    - Make sure that the "hostname" tag is created and has a value in your instance.
    - For now, this only works when your instance is created with a keypair file.
    - Make sure you have the AWSPowerShell module is installed in your system and you have a functional IAM user setup.
    - https://aws.amazon.com/powershell/
#>
    [CmdletBinding(DefaultParameterSetName = 'HostnameTag',
        SupportsShouldProcess = $false,
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # The tag value of your hostname tag field in Amazon.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'HostnameTag')]
        [ValidateNotNullOrEmpty()]
        [Alias("h")] 
        [string[]]$HostnameTag,

        # Path to your keypair file. This was created during your initial instance setup for security.
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateScript( { Test-Path $_ })]
        [Alias("k")]
        [string]$KeyPairPath
    )

    begin {
        $saveErrActPref = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        #create the main table that will be converted to custom object later. This is the master table that contains all info.
        $mainTable = @()
    }

    process {
        foreach ($tag in $hostnameTag) {

            try {
                $instanceTag = Get-EC2Tag -Filter @{Name = "resource-type"; Value = "instance" }, @{Name = "tag:hostname"; Value = $tag }
                $instance = (Get-Ec2Instance -InstanceId $instanceTag.ResourceId).Instances
                $instanceState = ((Get-Ec2Instance -InstanceId $instanceTag.ResourceId).Instances | Select-Object State -ExpandProperty State).Name
                $instancePass = Get-EC2PasswordData -InstanceID  $instanceTag.ResourceId -PemFile $KeyPairPath
            }

            catch {
                $errMessage = $_.Exception.Message
                Write-Warning "An error has occured gathering instance info: $errMessage"
            }

            finally {
                foreach ($i in $instance) {
                    # Filling in the earlier created table with items.
                    $mainTable += [PSCustomObject] @{
                        HostnameTag   = $instanceTag.Value
                        InstanceID    = $i.InstanceID
                        InstanceState = $InstanceState
                        InstanceType  = $i.InstanceType
                        Platform      = $i.Platform
                        HostPassword  = $instancePass
                        PrivateIP     = $i.PrivateIpAddress
                        PublicIP      = $i.PublicIpAddress
                        SubnetID      = $i.SubnetID
                        VpcID         = $i.VpcID
                        ImageID       = $i.ImageID
                    }
                }
            }
        }
        $mainTable
    }

    end {
        $ErrorActionPreference = $saveErrActPref
    }
}