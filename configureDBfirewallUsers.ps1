param
(
    [Parameter(Mandatory=$true)]
    [string] $sqluser
)

$sqlInstanceName = 'MSSQLSERVER'

#STEP1: Enable TCP protocol
Write-Output "Enabling TCP protocol"
Import-Module "sqlps"
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = new-object ($smo + 'Wmi.ManagedComputer').

# List the object properties, including the instance names.
$Wmi

# Enable the TCP protocol on the default instance.
$uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ServerInstance[@Name='$sqlInstanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
$Tcp.IsEnabled = $true
$Tcp.Alter()
$Tcp


#STEP2: Start SQL Server Browser service
Write-output "Enabling SQL browser service"
Set-Service sqlbrowser -StartupType Automatic
net start sqlbrowser


#STEP3: ADD firewall rules for SQL service
Wrie-Output "Enabling firewall rules"
netsh advfirewall firewall add rule name = SQLPort dir = in protocol = tcp action = allow localport = 1433 remoteip = any profile = domain  
netsh advfirewall firewall add rule name = SQLPortPrivate dir = in protocol = tcp action = allow localport = 1433 remoteip = any profile = private  
netsh advfirewall firewall add rule name = SQLPortPublic dir = in protocol = tcp action = allow localport = 1433 remoteip = any profile = public  

#STEP4: Restart SQL service
Write-Output "Restarting SQL service"
net stop $sqlInstanceName /yes
net start $sqlInstanceName /yes


#STEP5: Add user to SQL roles
Write-Output "Adding user to SQL roles"
$sqltoolPath=":\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\binn"
cmd /c $sqltoolPath\sqlcmd.exe -S localhost -Q "sp_addsrvrolemember '$env:ComputerName\$sqluser', 'sysadmin'"
cmd /c $sqltoolPath\sqlcmd.exe -S localhost -Q "sp_addsrvrolemember '$env:ComputerName\$sqluser', 'dbcreator'"
cmd /c $sqltoolPath\sqlcmd.exe -S localhost -Q "sp_addsrvrolemember 'NT AUTHORITY\SYSTEM', 'sysadmin'"
cmd /c $sqltoolPath\sqlcmd.exe -S localhost -Q "sp_addsrvrolemember 'NT AUTHORITY\SYSTEM', 'dbcreator'"