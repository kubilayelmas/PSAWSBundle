#Requires -Module AWSPowershell
#Requires -Version 5.0

# Fill the following values with your credential information gathered from AWS Dashboard
$awsAccessKey = "XXXXXXXXXXXXXX"
$awsSecretKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$awsRegion = "us-east-2"
$awsProfileName = 'YourProfileName'

If (! (Get-AWSCredential -ProfileName $awsProfileName) ) {
    Set-AWSCredential -AccessKey $awsAccessKey -SecretKey $awsSecretKey -StoreAs $awsProfileName
}
Initialize-AWSDefaultConfiguration -ProfileName $awsProfileName -Region $awsRegion
