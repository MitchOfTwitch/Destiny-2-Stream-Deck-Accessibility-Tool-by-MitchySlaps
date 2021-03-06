param
(
    [Parameter(Mandatory=$true)]
    $StreamProfilePathandName = "",
	[Parameter(Mandatory=$true)]
	$WebHookURL	= ""
)


if ($(Test-Path -Path $StreamProfilePathandName) -eq $false)
{
	Write-Host "Invalid path $StreamProfilePathandName entered, please enter a valid path and try again." -ForegroundColor Red
}
else 
{
	$OriginalName = Get-ChildItem $StreamProfilePathandName
	$ZipName = $OriginalName.FullName + ".zip"
	$WorkingFolder = $OriginalName.FullName.Split(".")[0]
	$NewName = $OriginalName.FullName.Split(".")[0]  + "CLEAN.zip"
	
	Rename-Item -Path $OriginalName -NewName $ZipName
	
	Expand-Archive -Path $ZipName -DestinationPath $WorkingFolder
	
	Rename-Item $ZipName -NewName $OriginalName.Name
	
	$jsonFiles = Get-ChildItem -Path $WorkingFolder -Filter "*.json" -Recurse
	
	For ($i = 0; $i -lt $jsonFiles.count; $i++)
	{
		$Content = Get-Content -Path $jsonFiles[$i].VersionInfo.FileName
		
		If ($Content.Contains("discordwebhook"))
		{
			$Content = $Content.Replace($WebHookURL, "")

			Set-Content -Path $jsonFiles[$i].VersionInfo.FileName -value $Content
		}
	}	
	Compress-Archive -Path $($WorkingFolder + "\*.*") -DestinationPath $NewName
	#Rename-Item -Path $NewName -NewName $($NewName.Split(".")[0] + ".streamDeckProfile")
	Remove-Item $WorkingFolder -Recurse		
}

