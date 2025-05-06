$DBProduct = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations").SqlActiveConfiguration

# Add EncryptionSalt value from registry HKLM\SOFTWARE\Veeam\Veeam Backup and Replication\Data
$saltbase = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\Data").EncryptionSalt


if ($DBProduct -eq "Mssql")
{
    #Get SQL configuration
    $SQLConfiguration = Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\MsSql"
    $SQLServer        = $SQLConfiguration.SqlServerName
    $SQLInstance      = $SQLConfiguration.SqlInstanceName
    $SQLDB            = $SQLConfiguration.SqlDatabaseName
    $SQLConnection    = $SQLServer + "\" + $SQLInstance
    $sqlquery="SELECT user_name,password from dbo.Credentials"

    $Connection                  = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$SQLConnection';database='$SQLDB';trusted_connection=false; integrated security='true'"
    $Connection.Open()
    $command                     = $Connection.CreateCommand()
    $command.CommandText         = $sqlquery
    $Datatable                   = New-Object "System.Data.Datatable"
    $result                      = $command.ExecuteReader()
    $Datatable.Load($result)
    $Result=$Datatable   


}

else
{
    #If postgreSQL
    
    #Get PostgreSQL configuration

    $PostgreSQLConfiguration = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\PostgreSql")
    $PostgreUser             = $PostgreSQLConfiguration.SQLUsername
    $PostgreSecPassword      = (Get-Credential -Message "Enter password for user $PostgreUser" -UserName $PostgreUser)
    $PostgrePassword         = $PostgreSecPassword.GetNetworkCredential().Password
    $PostgrePort             = $PostgreSQLConfiguration.SqlHostPort
    $PostgreDatabase         = $PostgreSQLConfiguration.SqlDatabaseName
    $PostgreQuery            = "SELECT user_name,password,description,change_time_utc FROM credentials"
    $dburl                   = "postgresql://$($PostgreUser):$PostgrePassword@localhost:$PostgrePort/$PostgreDatabase"
    $Result                  = $PostgreQuery | & "C:\Program Files\PostgreSQL\15\bin\psql" --csv $dburl | ConvertFrom-Csv

}

#Decrypt password
Foreach ($account in $result)
{
    $Name = $account.user_name
    $Password = "<N/A>"
    if ($account.password -like "AQAA*")
    {
        $context = $account.password
        Add-Type -AssemblyName 'system.security'
        $data = [Convert]::FromBase64String($context)
        $raw = [System.Security.Cryptography.ProtectedData]::Unprotect($data, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
        $Password = [System.Text.Encoding]::UTF8.Getstring($raw)

    }
    if ($account.password -like "VmVlY*")
    {    
        # Add encrypted value from the configuration database with single quotes. ('value' not '"value"')
        $context = $account.password


        # Make no changes below this line
        Add-Type -AssemblyName System.Security 
        $salt = [System.Convert]::FromBase64String($saltbase)
        $data = [System.Convert]::FromBase64String($context)
        $hex = New-Object -TypeName System.Text.StringBuilder -ArgumentList ($data.Length * 2)
        foreach ($byte in $data) {$hex.AppendFormat("{0:x2}", $byte) > $null}
        $hex.ToString()
        $hex = $hex.ToString().Substring(74,$hex.Length-74)
        $hex
        $data = New-Object -TypeName byte[] -ArgumentList ($hex.Length / 2)
        for ($i = 0; $i -lt $hex.Length; $i += 2) {$data[$i / 2] = [System.Convert]::ToByte($hex.Substring($i, 2), 16)}
        $securedPassword = [System.Convert]::ToBase64String($data)
        $data = [System.Convert]::FromBase64String($securedPassword)
        $local = [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        $raw = [System.Security.Cryptography.ProtectedData]::Unprotect($data, $salt, $local) 
        $Password = [System.Text.Encoding]::UTF8.Getstring($raw)
    }

    [PSCustomObject]@{
        Name     = $Name
        Password = $Password
    }
}
