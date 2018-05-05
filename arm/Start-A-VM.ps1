workflow Start-A-VM
{
    CmdletBinding()]
        param(
            $RGName,
            $VMName
        )

        Write-Output ("Launching script Start-A-VM, using the following parameters:")
        Write-Output ("RG Name : $RGName")
        Write-Output ("VM Name : $VMName")
        Write-Output ("-------------------------------------------------------------")
     
		$connectionName = "AzureRunAsConnection"
		try
		{
    		# Get the connection "AzureRunAsConnection"
    		$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
		
    		"Logging in to Azure..."
    		Add-AzureRmAccount `
                -ServicePrincipal `
                -TenantId $servicePrincipalConnection.TenantId `
                -ApplicationId $servicePrincipalConnection.ApplicationId `
                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
		}
		catch {
    		if (!$servicePrincipalConnection)
    		{
        		$ErrorMessage = "Connection $connectionName not found."
        		throw $ErrorMessage
    		} 
            else
            {
        		Write-Error -Message $_.Exception
        		throw $_.Exception
    		}
		}

        $VMStatus = Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName -Status|select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty displaystatus
        Write-Output("Status of machine $($VM.Name) is: $VMStatus")
        If (($VMStatus -ne "Running")  
            {
                Write-Output("Starting VM " + $VM.Name)
                Start-AzureRmVm -ResourceGroupName $VM.ResourceGroupName -Name $Vm.Name
            }
          Else
            {
                Write-Output ($VM.Name + " already is running")
            }
        }

}