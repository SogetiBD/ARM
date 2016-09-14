workflow StartVMs {
	
	inlineScript {
		$ConnectionAssetName = "AzureAutoCert"

        $FirstBatch = "isbdwscm01","isbdwsmtrx01","isbdwsrds01","isbdwsfs01","M42GW01"
        $SecondBatch = "isbdwsrds02","isbdwsappv01","isbdwsapp01","isbdwsweb01","isbdwsweb02"
		
		# Get the connection
		$connection = Get-AutomationConnection -Name $connectionAssetName        
		
		# Authenticate to Azure with certificate
		Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
		$Conn = Get-AutomationConnection -Name $ConnectionAssetName
		if ($Conn -eq $null)
		{
    		throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
		}
		
		$CertificateAssetName = $Conn.CertificateAssetName
		Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
		$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
		if ($AzureCert -eq $null)
		{
    		throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
		}
		
		Write-Verbose "Authenticating to Azure with certificate." -Verbose
		Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert 
		Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID
		
		# Get all VMs in the subscription and write out VM name and status
		$VMs = Get-AzureVm  | Select Name, Status, ServiceName

        Write-Output("--> Starting First set of machines")
		ForEach ($VM in $VMs)
		{
    		If ($firstBatch -contains $VM.Name) {
    
                    Write-Output ("Classic VM " + $VM.Name + " has status " +  $VM.Status)
    		        If ($VM.Status.StartsWith("Stopped"))
                    { 
                        $Message="Starting VM " + $VM.Name
                        Write-Output ($Message)
    		            Start-AzureVM -ServiceName $VM.ServiceName -Name $VM.Name
                    }
            }
            
		}

        #Wait 2.5 minutes to start first servers
        Start-Sleep -s 150

        Write-Output("--> Starting Second set of machines")
		ForEach ($VM in $VMs)
		{
    		If ($SecondBatch -contains $VM.Name) {
    
                    Write-Output ("Classic VM " + $VM.Name + " has status " +  $VM.Status)
    		        If ($VM.Status.StartsWith("Stopped"))
                    { 
                        $Message="Starting VM " + $VM.Name
                        Write-Output ($Message)
    		            Start-AzureVM -ServiceName $VM.ServiceName -Name $VM.Name
                    }
            }
            
		}

        
		
	}
}