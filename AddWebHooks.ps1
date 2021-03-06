<#
.SYNOPSIS
Adds Webhooks to the Vow of the Disciple (VotD) Stream Deck Profile

.PARAMETER $StreamProfilePathandName
Path to the Stream Deck Profile.  May be in .zip or .streamDeckProfile format

.PARAMETER WebHookUrl
The WebHook URL you would like to add to teh Stream Deck Profile.

.PARAMETER AddToStreamDeck
Set to true by default.  Used to add the profile to the Stream Deck Profiles Directory automatically.  
Setting to False will create a zip file containing the new Stream Deck Profile.

.PARAMETER OverWriteProfile
Set to false by default.  Set this to True to overwrite an existing profile.  

.DESCRIPTION
This script will allows a user to add their own webhook URL to the Vow of the Disciple Stream Deck Profile.

.EXAMPLE
AddWebHooks.ps1 -StreamProfilePathandName "C:\Users\cayde\Downloads\VotD v_4CLEAN.zip" -WebHookURL https://bungie.net

Adds the webhook https://bungie.net to the VotD v_4 Stream Deck Profile and adds it to the Stream Deck Profile Directory.

.EXAMPLE
AddWebHooks.ps1 -StreamProfilePathandName "C:\Users\cayde\Downloads\VotD v_4CLEAN.zip" -WebHookURL https://bungie.net -AddToStreamDeck:$false

Adds the webhook https://bungie.net to the VotD v_4 Stream Deck Profile and creates a zip file with containing the edited profile.

.EXAMPLE
AddWebHooks.ps1 -StreamProfilePathandName "C:\Users\cayde\Downloads\VotD v_4CLEAN.zip" -WebHookURL https://bungie.net -OverwriteProfile:$true

Adds the webhook https://bungie.net to the VotD v_4 Stream Deck Profile and overwrites an existing VotD profile with the same Identifier in the Stream Deck Profile Directory.
#>

param
(
    [Parameter(Mandatory=$true)]
    [String]$StreamProfilePathandName = "",
	[Parameter(Mandatory=$true)]
	[String]$WebHookURL	= "",
	[Parameter(Mandatory=$false)]
	[Bool]$AddToStreamDeck = $true,
	[Parameter(Mandatory=$false)]
	[Bool]$OverwriteProfile = $false
)


if ($(Test-Path -Path $StreamProfilePathandName) -eq $false)
{
	Write-Host "Invalid path $StreamProfilePathandName entered, please enter a valid path and try again." -ForegroundColor Red
}
else 
{
	if (!$StreamProfilePathandName.EndsWith(".zip"))
	{
		$ZipName = $StreamProfilePathandName + ".zip"
		Rename-Item -Path $StreamProfilePathandName -NewName $ZipName
		$sdProfile = Get-ChildItem $ZipName
	}
	else
	{
		$sdProfile = Get-ChildItem $StreamProfilePathandName
		$ZipName = $StreamProfilePathandName
	}
	
	$sdProfileObj = [Management.Automation.PSObject]@{
		Original = $StreamProfilePathandName
		Zip = $ZipName
		WorkingFolder = $sdProfile.DirectoryName + "\" + $sdProfile.BaseName
		Base = $sdProfile.BaseName
		Extension = $sdProfile.Extension
		New = $($sdProfile.DirectoryName + "\" + $sdProfile.BaseName + "EDITED" + $sdProfile.Extension)
	}

	Expand-Archive -Path $sdProfileObj.Zip -DestinationPath $sdProfileObj.WorkingFolder	
	
	$jsonFiles = Get-ChildItem -Path $sdProfileObj.WorkingFolder -Filter "*.json" -Recurse
	
	For ($i = 0; $i -lt $jsonFiles.count; $i++)
	{
		$Content = Get-Content -Path $jsonFiles[$i].VersionInfo.FileName
		
		If ($Content.Contains("discordwebhook"))
		{
			$Content = $Content.Replace('discordwebhook":"', 'discordwebhook":"' + $WebHookURL)
			Set-Content -Path $jsonFiles[$i].VersionInfo.FileName -value $Content
		}
	}
	
	if ($AddToStreamDeck)
	{
		$ProfileName = Get-ChildItem $sdProfileObj.WorkingFolder
		if($OverwriteProfile)
		{
			Read-Host "Close Stream Deck, then press enter to continue"
			Copy-Item -Path $ProfileName.FullName -Destination  $($env:APPDATA + "\Elgato\StreamDeck\ProfilesV2") -Recurse -Force
			Read-Host "Re-open Stream Deck and verify your Profile updates."
		}
		else
		{
			Copy-Item -Path $ProfileName.FullName -Destination  $($env:APPDATA + "\Elgato\StreamDeck\ProfilesV2") -Recurse
			Read-Host "Fully close the Stream Deck application and re-open to see your new profile in the drop-downn menu."
		}
	}
	else
	{
		Compress-Archive -Path $($sdProfileObj.WorkingFolder + "\*.*") -DestinationPath $sdProfileObj.New
	}
	
	Remove-Item $sdProfileObj.WorkingFolder -Recurse
	Rename-Item $sdProfileObj.Zip -NewName $sdProfileObj.Original
}

