$Host.UI.RawUI.WindowTitle = 'Computer Evaluation - CIT'
Clear-Host
$OSINFO = Get-WmiObject -Class Win32_OperatingSystem
$OSNAME = ($OSINFO).Caption
If ($OSNAME -Match "10" -Or "11") {
    IF ($OSNAME -Match "Pro" -Or "Enterprise" -Or "Iot") {
        $OSSTATUS = "OK"
    } Else {
        $OSSTATUS = "Out of compliance"
    }
} Else {
    $OSSTATUS = "Disposal"
}
$OSARCHITECTURE = $osInfo.OSArchitecture
If ($OSARCHITECTURE -Match "64 bits") {
    $ARCHSTATUS = "OK"
} Else {
    $ARCHSTATUS = "Disposal"
}
$CPU = Get-WmiObject Win32_Processor
$CPUNAME = $CPU.Name
If ($cpuName -match "AMD" -and $cpuName -match "Ryzen") {
    $CPUStatus = "OK"
} ElseIf ($cpuName -match "Intel") {
    if ($cpuName -match "Core" -and ($cpuName -match "i[3-9]-[8-9][0-9]{2,3}" -or $cpuName -match "i[3-9]-[1-9][0-9]{3,4}")) {
        $CPUStatus = "OK"
    } ElseIf ($cpuName -match "Xeon") {
        $CPUStatus = "OK"
    } Else {
        $CPUStatus = "Disposal"
    }
} Else {
    $CPUStatus = "Disposal"
}
$RAM = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum /1GB
If ($RAM -lt 8) {
    $RAMSTATUS = "Disposal"
} Else {
    $RAMSTATUS = "OK"
}
$USERSFOLDERS = Get-ChildItem "$Env:HOMEDRIVE\Users\"
$N_USERS = $USERSFOLDERS.Count
If ($N_USERS -ge 6) {
    $N_USERS_STATUS = "Recommended cleanup"
} Else {
    $N_USERS_STATUS = "OK"
}
$NETWORKINFO = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress }
$DOMAIN = $NETWORKINFO.DNSDomain
If ([string]::IsNullOrEmpty($DOMAIN)) {
    $NETWORKSTATUS = "Disconnected"
} Else {
    $NETWORKSTATUS = "OK"
}
$DISK = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$Env:HOMEDRIVE'"
$PERCENTFREE = ($DISK.FreeSpace / $DISK.Size) * 100
$DISKSIZE = $DISK.Size / 1GB
If ($PERCENTFREE -le 30) {
    $DISKSTATUS = "Recommended cleanup"
} Else {
    $DISKSTATUS = "OK"
}
If ($DISKSIZE -lt 210) {
    $DISK_SIZE_STATUS = "Recommended upgrade"
} Else {
    $DISK_SIZE_STATUS = "OK"
}
$GPU = Get-WmiObject Win32_VideoController
$GPUNAME = $GPU.VideoProcessor
If ($GPUNAME -Like "*Intel*") {
    $GPUStatus = "OK"
} ElseIf ($GPUNAME -like "*ATI*") {
    $GPUStatus = "Recommended upgrade"
} Elseif ($GPUNAME -Like "*NVIDIA*" -Or $GPUNAME -like "*AMD*") {
    $GPUStatus = "OK"
} Else {
    $GPUStatus = "Unknown"
}
$AVPRODUCTS = Get-WmiObject -Namespace "ROOT\SecurityCenter2" -Query "SELECT * FROM AntivirusProduct"
$HASKASPERSKY = $AVPRODUCTS | Where-Object { $_.displayName -like "*Kaspersky*" }
$AVNAME = $HASKASPERSKY.DisplayName
If ($HASKASPERSKY) {
    $AVSTATUS = "OK"
} Else {
    $AVSTATUS = "Out of compliance"
}
$UPTIME = (Get-Date) - ($OSINFO.ConvertToDateTime($OSINFO.LastBootupTime))
$UPTIMEDISPLAY = "{0} days, {1} hours, {2} minutes" -f $UPTIME.Days, $UPTIME.Hours, $UPTIME.Minutes
If ($UPTIME.Days -Ge 1) {
    $UPTIME_STATUS = "Reboot Recommended"
} Else {
    $UPTIME_STATUS = "OK"
}
$PROCESSOROBJECT = [PSCustomObject]@{
    Category = "Processor"
    Specification = $CPUNAME
    Situation = $CPUSTATUS
}
$RAMOBJECT = [PSCustomObject]@{
    Category = "RAM"
    Specification = "$RAM Gb"
    Situation = $RAMSTATUS
}
$NUSERSOBJECT = [PSCustomObject]@{
    Category = "Users"
    Specification = $N_USERS
    Situation = $N_USERS_STATUS
}
$NETWORKOBJECT = [PSCustomObject]@{
    Category = "Network"
    Specification = $DOMAIN
    Situation = $NETWORKSTATUS
}
$DISKSPACEOBJECT = [PSCustomObject]@{
    Category = "Free disk space"
    Specification = "$PERCENTFREE%"
    Situation = $DISKSTATUS
}
$ARCHITECTUREOBJECT = [PSCustomObject]@{
    Category = "OS Architecture"
    Specification = $OSARCHITECTURE
    Situation = $ARCHSTATUS
}
$DISK_SIZE_OBJECT = [PSCustomObject]@{
    Category = "Disk Size"
    Specification = $DISKSIZE
    Situation = $DISK_SIZE_STATUS
}
$OSOBJECT = [PSCustomObject]@{
    Category = "Operating System"
    Specification = $OSNAME
    Situation = $OSSTATUS
}
$GPUOBJECT = [PSCustomObject]@{
    Category = "GPU"
    Specification = $GPUNAME
    Situation = $GPUStatus
}
$AVOBJECT = [PSCustomObject]@{
    Category = "Kaspersky"
    Specification = $AVNAME
    Situation = $AVSTATUS
}
$UPTIME_OBJECT = [PSCustomObject]@{
    Category = "Uptime"
    Specification = $UPTIMEDISPLAY
    Situation = $UPTIME_STATUS
}
$OSOBJECT, $ARCHITECTUREOBJECT, $PROCESSOROBJECT, $GPUOBJECT, $RAMOBJECT, $NUSERSOBJECT, $NETWORKOBJECT, $DISK_SIZE_OBJECT, $DISKSPACEOBJECT, $AVOBJECT, $UPTIME_OBJECT | Format-Table