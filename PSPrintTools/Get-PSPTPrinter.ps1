function Get-PSPTPrinter {
	<#
	.SYNOPSIS
	A recreation of the Get-Printer Cmdlet without the MSFT class
	.EXAMPLE
	Get-PSPTPrinter -ComputerName ExampleComputer,LocalHost
	.PARAMETER ComputerName
	The computer name or array of computers to query, defaults to localhost
	.PARAMETER PrinterName
	The name or array of names of printers to filter against, defaults to unfiltered
	.OUTPUTS
	Microsoft.Management.Infrastructure.CimInstance#ROOT/StandardCimv2/MSFT_Printer without RenderingMode, JobCount, DisableBranchOfficeLogging, or BranchOfficeOfflineLogSizeMB
	.LINK
    https://himsel.io
    .LINK
	https://github.com/BenHimsel/PSPrintTools
	.NOTES
    Where applicable, set free under the unlicense: http://unlicense.org/ 
	Author: Ben Himsel
    .LINK
    https://github.com/BenHimsel/PSPrintTools
    .LINK
    https://himsel.io
    .NOTES
    Where applicable, set free under the terms of the Unlicense. http://unlicense.org/
    Author: Ben Himsel
	#>

	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
	param (
		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		Position = 0)]
		[string[]]$ComputerName,

		[Parameter(Mandatory=$False,
		ValueFromPipelineByPropertyName=$True,
		Position = 1)]
		[string[]]$PrinterName
	)

	begin {
		write-verbose "Initializing Helpers"
		#Converter used to change ACL into SDDL
		$sddlconverter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper
		#Create an array for Select-Object to Change Win32_Printer output to be similar to MSFT_Printer
		$selectarray = @(
			"Name"
			@{
				Name="ComputerName"
				Expression={$_.SystemName}
			}
			"ShareName"
			"PortName"
			"DriverName"
			"Location"
			"Comment"
			@{
				Name="SeparatorPageFile"
				Expression={$_.SeparatorFile}
			}
			"PrintProcessor"
			@{
				Name="Datatype"
				Expression={$_.PrintJobDataType}
			}
			"Shared"
			"Published"
			@{
				Name="PermissionSDDL"
				Expression={$sddlconverter.Win32SDToSDDL($_.getsecuritydescriptor().Descriptor).SDDL}
			}
			"KeepPrintedJobs"
			"Priority"
			@{
				Name="DefaultJobPriority"
				Expression={$_.DefaultPriority}
			}
			"StartTime"
			"UntilTime"
			@{	Name="PrinterStatus"
				Expression={
					switch ($_.PrinterStatus) {
						1 {"Other"}
						2 {"Unknown"}
						3 {"Idle"}
						4 {"Printing"}
						5 {"Warming up"}
						6 {"Stopped Printing"}
						7 {"Offline"}
						default {"Unknown"}
					}
				}
			}

		)
	}

	process {
		write-verbose "Checking ComputerName"
		if ($ComputerName) {
			write-verbose "Starting Computer Processing loop"
			foreach ($computer in $ComputerName) {
				Write-Verbose "Processing $computer"
				if ($pscmdlet.ShouldProcess($computer)) {
					#add filter if there's a printername
					if ($PrinterName) {
						write-verbose "Starting Printer Processing loop"
						foreach ($Printer in $PrinterName) {
							$CIMPrinter = Get-CimInstance -ComputerName $computer -ClassName Win32_Printer -Filter "Name like '$Printer'" | Select-Object $selectarray
						}
					} else {
						write-verbose "No PrinterName, skip Processing loop"
						$CIMPrinter = Get-CimInstance -ComputerName $computer -ClassName Win32_Printer | Select-Object $selectarray
					}
					if ($CIMPrinter.local -eq "True") {
						$Type = "Local"
					} elseif ($CIMPrinter.Network -eq "True") {
						$Type = "Connection"
					} else {
						$Type = "Unknown"
					}
					$CIMPrinter
				} 
			}
		} else {
			#add filter if there's a printername
			write-verbose "No ComputerName, skip Processing loop"
			if ($PrinterName) {
				write-verbose "Starting Printer Processing loop"
				foreach ($Printer in $PrinterName) {
					$CIMPrinter = Get-CimInstance -ClassName Win32_Printer -Filter "Name like '$Printer'" | Select-Object $selectarray
				}
			} else {
				write-verbose "No PrinterName, skip Processing loop"
				$CIMPrinter = Get-CimInstance -ClassName Win32_Printer | Select-Object $selectarray
			}
			if ($CIMPrinter.local -eq "True") {
				$Type = "Local"
			} elseif ($CIMPrinter.Network -eq "True") {
				$Type = "Connection"
			} else {
				$Type = "Unknown"
			}
			$CIMPrinter
		}
	}
	end {
			write-verbose "Ending Something1"
	}
}