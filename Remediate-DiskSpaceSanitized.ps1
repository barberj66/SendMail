#=============================================================================================================================
# Script Name:     Remediate_Diskspace.ps1
# Description:     Can be used to send a mail to helpdesk to log a job for diskspace issues
# Notes:           To be used as Intune Detection script
# Author:          James Barber
# Date:            20th June 2022
#=============================================================================================================================
#This section gets the information about the disk space so we can use it to form the email
$os = Get-CimInstance Win32_OperatingSystem
$systemDrive = Get-CimInstance Win32_LogicalDisk -Filter "deviceid='$($os.SystemDrive)'"
$PercentFree = ($systemDrive.FreeSpace / $systemDrive.Size) * 100
$PercentRounded = [math]::Truncate($PercentFree)
#This section gets the computer name and logged on user so we can provide this to the helpdesk when logging the case
$ComputerInfo = Get-ComputerInfo
$ComputerName = $ComputerInfo.CsName
$CurrentLoggedOnUser = (Get-WmiObject -Class win32_computersystem).UserName


#Variables required for mail and graph request
$tenantID = "YourTenantID"
$clientID = "YourClientID"
$clientsecret = "YourClientSecret"
$EmailSubject = "Low Disk Space Notification"
$MailSender = "Your Sender Address"
$MailRecipient = "Your recipient"
$MailBodyContent = "The computer $ComputerName currently only has $percentrounded % free disk space. Username for this machine is $CurrentLoggedOnUser . Please log to technician to have them assist in freeing up some space proactively."

#Obtain Auth token
 
$AuthBody = @{
    client_id     = $clientID
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}

$accesstoken = Invoke-WebRequest -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $AuthBody -Method Post
     
$accessToken = $accessToken.content | ConvertFrom-Json
     
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer " + $accessToken.access_token
    'ExpiresOn'     = $accessToken.expires_in
}

#Constructing the mail body
$body =
@"
{
    "message" : {
    "subject": "$EmailSubject",
    "body" : {
    "contentType": "html",
    "content": "$MailBodyContent"
    },
    "toRecipients": [
    {
    "emailAddress" : {
    "address" : "$MailRecipient"
    }
    }
    ]
    }
    }
"@
         
#Sending the email
Invoke-RestMethod -Headers $authHeader -URI "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail" -Body $body -Method POST -ContentType 'application/json'
