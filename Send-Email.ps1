#
#.SYNOPSIS
#Sends SMTP email via the Hub Transport server
#
#.EXAMPLE
#.Send-Email.ps1 -To "administrator@exchangeserverpro.net" -Subject "Test email" -Body "This is a test"
#
 
param(
[string]$to,
[string]$subject,
[string]$body
)
$SmtpUser = "rammsappworkorder@outlook.com"
$smtpPassword = "mulesoft2017"
$SMTPServer = "smtp-mail.outlook.com"
$SMTPPort = "587"
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force) 
$smtpFrom = "bill.gates@mulesoft.com"
$smtpTo = $to
$bcc = "warrenbuffet@gmail.com"
$messageSubject = $subject
