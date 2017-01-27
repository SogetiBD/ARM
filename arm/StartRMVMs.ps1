workflow StartRMVMs
{
    Write-Output ("Launching script")
        
        $VMsIncluded=("XA-Controller","XA-VDA")	
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
            Write-Output("Status of machine $($VM.Name) is: $VMStatus")
            If (($VMStatus -ne "Running") -And ($VMsIncluded -Contains $VM.Name))  
              {
                Write-Output("Starting VM " + $VM.Name)
                Start-AzureRmVm -ResourceGroupName $VM.ResourceGroupName -Name $Vm.Name -Force
              }
            Else
              {
                  Write-Output ($VM.Name + " is excluded for startup")
              }
        }

}