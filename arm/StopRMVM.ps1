workflow StopRMVM {
	inlineScript {

        $VMsExcluded=("isbdwsdc02","isbdws2dc01","kaadds01")	
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
    		} else{
        		Write-Error -Message $_.Exception
        		throw $_.Exception
    		}
		}

        $VMs=Get-AzureRmVm
        ForEach ($VM in $VMs)
        {
            $VMStatus = Get-AzureRmVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status|select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty displaystatus
            Write-Output("Status of machine " + $VM.Name + " is: " + $VMStatus)
            If ($VMStatus -eq "VM running" -And $VMsExcluded -NotContains $VM.Name)  
              {
                Write-Output("Stopping VM " + $VM.Name)
                Stop-AzureRmVm -ResourceGroupName $VM.ResourceGroupName -Name $Vm.Name -Force
              }
            Else
              {
                  Write-Output ($VM.Name + " is excluded for shutdown")
              }
        }

	}
}