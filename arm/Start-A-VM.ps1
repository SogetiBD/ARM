workflow Start-A-VM
{
    #[CmdletBinding()]
    param (
        [object]$WebhookData
    ) 
    
    $VerbosePreference = 'continue'

    # If runbook was called from Webhook, WebhookData will not be null.
    if ($WebHookData){
        # Collect properties of WebhookData
        $WebhookName     =     $WebHookData.WebhookName
        $WebhookHeaders  =     $WebHookData.RequestHeader
        $WebhookBody     =     $WebHookData.RequestBody

        # Collect individual headers. Input converted from JSON.
        $From = $WebhookHeaders.From
        $VMData=(ConvertFrom-Json -InputObject $WebhookBody)
        Write-Verbose "WebhookBody: $VMData"
        Write-Output -InputObject ('Runbook started from webhook {0} by {1}.' -f $WebhookName, $From)
    }
    else
    {
        Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop
    }

    $RGName=$VMData.ResourceGroup
    $VMName=$VMData.VMName
    $Action=$VMData.Action
        
        Write-Output ("Launching script Start-A-VM, using the following parameters:")
        Write-Output ("RG Name : $RGName")
        Write-Output ("VM Name : $VMName")
        Write-Output ("Action : $Action")
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
            $GetStatus=Get-AzureRmVM -ResourceGroupName $Using:RGName -Name $Using:VMName -Status|select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty displaystatus
            $GetStatus
        }
        Write-Output("Status of machine $VMName is: $VMStatus")
        
        If ($Action -eq "Start") 
        {
            If ($VMStatus -ne "VM running")  
                {
                    Write-Output("Starting VM " + $VMName)
                    Start-AzureRmVm -ResourceGroupName $RGName -Name $VmName
                }
            Else
                {
                    Write-Output ($VMName + " already is running.")
                }
        }

        If ($Action -eq "Stop") 
        {
            If ($VMStatus -ne "VM deallocated")  
                {
                    Write-Output("Stopping VM " + $VMName)
                    Start-AzureRmVm -ResourceGroupName $RGName -Name $VmName
                }
            Else
                {
                    Write-Output ($VMName + " already is stopped.")
                }
        }      

}