<#
.SYNOPSIS
    VM_Without_Tag.ps1 - PowerShell Script to get all VMs which don't have vSphere Tag.
.DESCRIPTION
    Get the list of VMs without tag. Usefull if you use tag for backup purpose
    Send by mail
.OUTPUTS
    <none>
.NOTES
    Author        Julien Mousqueton, @JMousqueton
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
# E-Mail settings
$From = ""
$To = ""
$Subject = "VMs without Tags"
$SMTPServer = ""
$SMTPPort = "25"
# VMware settings
$vCenterServer = ""
$vCenterUser = ""
$vCenterPassword = ''
# Design
$style = '<BODY style="font-family: Arial; font-size: 10pt;"> <TABLE style="border: 1px solid red; border-collapse: collapse;"> <TH style="border: 1px solid; background-color:#4CAF50; color: white; padding: 5px;"> <TD style="border: 1px solid; padding: 5px;">'
# Enter your tag category you want to check here
$TagCategory ="Backup Tags"
#----------------------------------------------------------[Declarations]----------------------------------------------------------
# Script Version
## NOT USED ## $ScriptVersion = "1.0"
#-----------------------------------------------------------[Functions]------------------------------------------------------------
$Now = "Get-Date -format dd_MM_yyyy_hh_mm_ss"
#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Load the PowerCLI SnapIn
Add-PSSnapin VMware.VimAutomation.Core -ea "SilentlyContinue"
# Set Configuration for Certificate
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to  vCenter Server
Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPassword | Out-Null

# Generate full subject
$Subject = $Subject + " " + $Now

# Get VMs without Tag in the given category
$Report = Get-VM | Where-Object { (Get-TagAssignment -Entity $_ -Category $TagCategory) -eq $null} | Select-Object VM,
 @{Name="Cluster";Expression={$_.VM.VMHost.Parent.Name}}
 | ConvertTo-Html -Head $style | Out-String

Send-MailMessage -From $From -To $To -Subject $Subject -Body $Report -BodyAsHtml -Body $SnapshotReport -Priority High -DeliveryNotificationOption None -SmtpServer $SMTPServer -Port $SMTPPort

# Disconnecting from the vCenter Server
Disconnect-VIServer * -Confirm:$false
