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
$messageBody = $body
$mail = New-Object System.Net.Mail.MailMessage
$mail.from = "bill.gates@mulesoft.com"
$mail.to.Add($smtpTo)
$mail.Subject = $messageSubject
$mail.Body = $messageBody
$mail.IsBodyHtml = $true
#Send-MailMessage -SmtpServer $SMTPServer -From $smtpFrom  -To $smtpTo -Bcc $bcc -Subject $messageSubject -Body $messageBody -UseSsl false -Credential $Credentials

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.UseDefaultCredentials = $false;
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $smtpPassword);
#$smtp.Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force) 
$smtp.Send($mail);
