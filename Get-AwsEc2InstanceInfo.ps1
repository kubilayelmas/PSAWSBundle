#Requires -Modules AwsPowerShell
function Get-AwsEc2InstanceInfo {
    <#
.SYNOPSIS
    Gather AWS EC2 Instance details with your instance ID information.
.DESCRIPTION
    Based on a given value for the InstanceID in your EC2 instance. This function will create
    a small table with useful information about your instance. It helps to visualize your instance
    details at a glance.
.EXAMPLE
    Get-AwsEc2InstanceInfo -InstanceID i-037f05b848ab94c52 -KeyPairPath C:\mykeypairs\aws-keypair.pem -ProfileName "myprofilename"
.NOTES
    - Make sure you have the AWSPowerShell module is installed in your system and you have a functional IAM user setup.
    - https://aws.amazon.com/powershell/
#>
    [CmdletBinding(DefaultParameterSetName = 'InstanceID',
        SupportsShouldProcess = $false,
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # The instance ID of your EC2 instance.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'InstanceID')]
        [ValidateNotNullOrEmpty()]
        [Alias("i")] 
        [string[]]$InstanceID,

        # Path to your keypair file. This was created during your initial instance setup for security.
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateScript( { Test-Path $_ })]
        [Alias("k")]
        [string]$KeyPairPath,

        # Profilename of your AWS account. This must be setup before using this cmdlet with Set-AWSCredentials cmdlet.
        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias("p")] 
        [string]$ProfileName
    )

    begin {
        $saveErrActPref = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        #create the main table that will be converted to custom object later. This is the master table that contains all info.
        $mainTable = @()
    }

    process {
        foreach ($id in $InstanceID) {

            try {
                $instance = (Get-Ec2Instance -InstanceId $id -ProfileName $ProfileName).Instances
                $instanceState = ($instance | Select-Object State -ExpandProperty State).Name
                $instancePass = Get-EC2PasswordData -InstanceID $id -PemFile $KeyPairPath -ProfileName $ProfileName
                $hostnameTag = (Get-EC2Tag -Filter @{Name = "resource-type"; Value = "instance"}, @{Name="key";Value="Name"} -Region us-east-1 -ProfileName tgdp | Where-Object {$_.ResourceID -eq $id}).Value
            }

            catch {
                $errMessage = $_.Exception.Message
                Write-Warning "An error has occured gathering instance info: $errMessage"
            }

            finally {
                foreach ($i in $instance) {
                    # Filling in the earlier created table with items.
                    $mainTable += [PSCustomObject] @{
                        HostnameTag   = $hostnameTag
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