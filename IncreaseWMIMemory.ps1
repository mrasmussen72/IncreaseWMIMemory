$hostname = "localhost"
[uint32]$memoryPerHost = 1073741824 #equal to 1024 MB.  This is the number of bytes
[uint32]$memoryAllHosts = 2147483648 # equal to 2048 MB.  This is the number of bytes
$enableLogging = $true
$logFilePath = $env:temp + "\" + $env:computername + ".txt"
$success = $false
$memPerHostSet = $false
$memAllHostsSet = $false
$sb = New-object System.Text.StringBuilder

function Write-Log 
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$False)]
    [string]$Line,
    [Parameter(Mandatory=$False)]
    [string]$LogFilePathAndName
  )
	try
	{
		if($Line.Equals("") -or $LogFilePathAndName.Equals(""))
		{
			return
		}
		if(-Not (Test-Path -Path $LogFilePathAndName))
		{
			# create file?
		}
		[string] $data = (Get-Date).ToString() + " - "
		$data += $Line
		$data += "`r`n"

		#$LogFile += "$($env:COMPUTERNAME)-AfterBackupLogFile.txt"
		$data | Out-File -FilePath $LogFilePathAndName -Append
	}
	catch
	{}
}


try 
{
    $sb.Append("Begin Compliance Setting###############################################`r`n") | Out-Null
    $sb.Append("Connecting to WMI...`r`n") | Out-Null
    $memory = Get-WmiObject -Namespace "root" -ComputerName $hostname -Query "Select * from __ProviderHostQuotaConfiguration"
    $sb.Append("Connected successfully`r`n") | Out-Null
    if($null -eq $memory)
    {
        $sb.Append("object returned by query is null, exiting`r`n") | Out-Null
        Exit
        #issue
    }
    $sb.Append("Looping through the class properties..`r`n") | Out-Null
    #loop through the properties, looking for our values
    foreach($property in $memory.Properties)
    {
        if($property.Name.ToLower().equals("memoryperhost"))
        {
            $sb.Append("Found MemoryPerHost, changing value`r`n") | Out-Null
            $instance = Get-WmiObject -Namespace "root" -Class __ProviderHostQuotaConfiguration -ComputerName $hostname
            $instance | Set-WmiInstance -Arguments @{MemoryPerHost = $memoryPerHost}
            $sb.Append("Value changed`r`n") | Out-Null
            $memPerHostSet = $true
        }
        elseif($property.Name.ToLower().equals("memoryallhosts"))
        {
            $sb.Append("Found MemoryAllHosts, changing value`r`n") | Out-Null
            $instance = Get-WmiObject -Namespace "root" -Class __ProviderHostQuotaConfiguration -ComputerName $hostname
            $instance | Set-WmiInstance -Arguments @{MemoryAllHosts = $memoryAllHosts}
            $sb.Append("Value changed`r`n") | Out-Null
            $memAllHostsSet = $true
        }
    }
}
catch 
{
    $sb.Append("Error running compliance setting." + $_.Exception.Message + "`r`n") | Out-Null
    $success = $false
}

if($memPerHostSet -eq $true -and $memAllHostsSet -eq $true)
{
    $success = $true
}
else 
{
    $success = $false    
}
$sb.Append("Returing " + $success.ToString() + "`r`n") | Out-Null
if($enableLogging){ Write-Log -LogFilePathAndName $logFilePath -Line $sb.ToString() }
$success
