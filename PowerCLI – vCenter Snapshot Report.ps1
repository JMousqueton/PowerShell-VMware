<#
	.NOTES
	===========================================================================
	 Created on:   	28/05/2020
	 Created by:   	Julien Mousqueton
	 Organization:  Computacenter
	 Filename:     	PowerCLI - vCenter Snapshot Report.ps1
	===========================================================================
#>

#Variables
$vCenter = ""
$vCenterUser = ""
$vCenterPass = ""
$SMTPServer = ""
$From = ""
$To = ""


#HTML formatting
$style = '<BODY style="font-family: Arial; font-size: 10pt;"> <TABLE style="border: 1px solid red; border-collapse: collapse;"> <TH style="border: 1px solid; background-color:#4CAF50; color: white; padding: 5px;"> <TD style="border: 1px solid; padding: 5px;">'
$date = Get-Date -Format "dddd dd/MM/yyyy HH:mm"

#Connect to vCenter"
Write-Output "Connecting to $vCenter"
Connect-VIServer -Server $vCenter -User $vCenterUser -Password $vCenterPass -Force | Out-Null
Write-Output " Connected to $vCenter"

#Get list of VMs with snapshots
Write-Output "Generating VM snapshot report"
$SnapshotReport = Get-vm | Get-Snapshot | Select-Object VM,
    @{Name="SnapShot Name";Expression={ $_.Name}},
    @{Name="Created By";Expression={
        Get-VIEvent -Start $_.Created.AddMinutes(-1) -Finish $_.Created.AddMinutes(1) |
        Where-Object{$_ -is [VMware.Vim.TaskEvent] -and $_.Info.DescriptionId -eq 'VirtualMachine.createSnapshot'} |
        Select-Object -Last 1 -ExpandProperty UserName
    }},
    PowerState,
    @{Name="SnapShot Description";Expression={ $_.Description}},
    @{Name="Size GB";Expression={ [math]::Round($_.SizeGB,2) }},
    @{Name="Age";Expression={ [math]::round( ((Get-Date) - $_.Created).TotalDays, 0) }},
    @{Name="Cluster";Expression={$_.VM.VMHost.Parent.Name}}
| Sort-Object -Descending Age | ConvertTo-Html -Head $style | Out-String
Write-Output " Completed"


#Sending email report
Write-Output "Sending VM snapshot report"
Send-MailMessage -smtpserver $SMTPServer -From $From -To $To -Subject "Snapshot Email Report for $Date" -BodyAsHtml -Body $SnapshotReport

Write-Output " Completed"

#Disconnecting vCenter
Disconnect-VIServer -Server $vCenter -Force -Confirm:$false
Write-Output "Disconnecting to $vCenter"
