workflow StartRMVMs
{
    Write-Output ("Launching script")
     #saved: "isbdws2rds03","isbdws2file01","isbdwsrds04",   
        $FirstBatch=("ssw-rds01","ssw-file01","ssw-portal")	
        $SecondBatch=("ssw-rds03","isbdwsmtrx03")
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
        ForEach -Parallel ($VM in $VMs)
        {
            $VMStatus = InlineScript {
                $GetStatus=Get-AzureRmVM -ResourceGroupName $Using:VM.ResourceGroupName -Name $Using:VM.Name -Status|select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty displaystatus
                $GetStatus
            }
            Write-Output("Status of machine $($VM.Name) is: $VMStatus")
            If (($VMStatus -ne "VM running") -And ($FirstBatch -Contains $VM.Name))  
              {
                Write-Output("Starting VM " + $VM.Name)
                Start-AzureRmVm -ResourceGroupName $VM.ResourceGroupName -Name $Vm.Name
              }
            Else
              {
                  Write-Output ($VM.Name + " is excluded for startup")
              }
        }

        ForEach -Parallel ($VM in $VMs)
        {
            $VMStatus = InlineScript {
                $GetStatus=Get-AzureRmVM -ResourceGroupName $Using:VM.ResourceGroupName -Name $Using:VM.Name -Status|select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty displaystatus
                $GetStatus
            }
            Write-Output("Status of machine $($VM.Name) is: $VMStatus")
            If (($VMStatus -ne "VM running") -And ($SecondBatch -Contains $VM.Name))  
              {
                Write-Output("Starting VM " + $VM.Name)
                Start-AzureRmVm -ResourceGroupName $VM.ResourceGroupName -Name $Vm.Name
              }
            Else
              {
                  Write-Output ($VM.Name + " is excluded for startup")
              }
        }

}