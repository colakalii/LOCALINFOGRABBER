
$info = [ordered]@{
    'PC Name' = ""  
    'Model' = ""
    'Serial Number' = "" 
    'MAC Address' = ""     
    'IP Addresses' = ""  
    'CPU Model' = ""      
    'RAM Capacity (GB)' = "" 
    'GPU Model' = ""
}


$info['PC Name'] = (Get-WmiObject Win32_ComputerSystem).Name

$info['Model'] = (Get-WmiObject Win32_ComputerSystem).Model

$info['Serial Number'] = (Get-WmiObject Win32_BIOS).SerialNumber

$info['MAC Address'] = ((Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE").MACAddress | Select-Object -First 1)

$ipAddresses = (Get-NetIPAddress | Where-Object { 
    $_.AddressFamily -eq 'IPv4' -and 
    $_.IPAddress -notlike '169.254.*.*' -and  # Exclude APIPA (Automatic Private IP Addressing) addresses
    $_.InterfaceAlias -notlike 'Loopback*'     # Exclude Loopback interface
}).IPAddress
$info['IP Addresses'] = $ipAddresses -join '; '  # Join IP addresses with semicolon

$info['CPU Model'] = (Get-WmiObject Win32_Processor).Name

$ramInBytes = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
$info['RAM Capacity (GB)'] = [math]::Round($ramInBytes / 1GB, 2) 

$gpu = Get-WmiObject Win32_VideoController | Select-Object -First 1
if ($gpu) {
    $info['GPU Model'] = $gpu.Name
} else {
    $info['GPU Model'] = "Not Found"
}

$filename = Read-Host "Please enter the output filename (without extension): "
$filename += ".txt"  # Add .txt extension


$info.GetEnumerator() | ForEach-Object {
    "$($_.Key):$($_.Value)"
} | Out-File $filename -Encoding utf8


$smbShare = "\\yourlocalhostadress\yourpath"
$username = "username"
$password = ConvertTo-SecureString "password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $password)

try {
    New-PSDrive -Name "SMBShare" -PSProvider FileSystem -Root $smbShare -Credential $credential -ErrorAction Stop
    
    
    Copy-Item -Path $filename -Destination "SMBShare:\" -ErrorAction Stop
    
    Write-Host "Information has been saved to $filename and copied to the SMB share."
}
catch {
    Write-Host "An error occurred: $_"
}
finally {
    
    Remove-PSDrive -Name "SMBShare" -ErrorAction SilentlyContinue
}
