workflow Start-A-VM
{
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

        $VMStatus = inlineScript {
             Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName -Status|select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty displaystatus
        }
        Write-Output("Status of machine $VMName is: " + $VMStatus)
        If ($VMStatus -ne "VM running")  
            {
                Write-Output("Starting VM " + $VMName)
                Start-AzureRmVm -ResourceGroupName $RGName -Name $VmName
            }
          Else
            {
                Write-Output ($VMName + " already is running")
            }

}