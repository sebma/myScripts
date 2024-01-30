# https://learn.microsoft.com/en-us/azure/virtual-desktop/language-packs
# https://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_CLIENTLANGPACKDVD_OEM_MULTI.iso

$isoMountDIR = "L:"
$LanguagePacksDIR = "$isoMountDIR/x64/langpacks"
$LocalExperiencePackRootDIR = "$isoMountDIR/LocalExperiencePack"

Add-AppxPackage -Path "$LocalExperiencePackRootDIR/en-gb/LanguageExperiencePack.en-GB.Neutral.appx"
Add-AppxPackage -Path "$LocalExperiencePackRootDIR/en-us/LanguageExperiencePack.en-US.Neutral.appx"
Add-AppxPackage -Path "$LocalExperiencePackRootDIR/es-es/LanguageExperiencePack.es-ES.Neutral.appx"
Add-AppxPackage -Path "$LocalExperiencePackRootDIR/fr-fr/LanguageExperiencePack.fr-FR.Neutral.appx"
Add-AppxPackage -Path "$LocalExperiencePackRootDIR/it-it/LanguageExperiencePack.it-IT.Neutral.appx"
Add-AppxPackage -Path "$LocalExperiencePackRootDIR/ro-ro/LanguageExperiencePack.ro-RO.Neutral.appx"

Add-WindowsPackage -Online -PackagePath "$LanguagePacksDIR/Microsoft-Windows-Client-Language-Pack_x64_ro-ro.cab"
Add-WindowsPackage -Online -PackagePath "$LanguagePacksDIR/Microsoft-Windows-Client-Language-Pack_x64_it-it.cab"
Add-WindowsPackage -Online -PackagePath "$LanguagePacksDIR/Microsoft-Windows-Client-Language-Pack_x64_fr-fr.cab"
Add-WindowsPackage -Online -PackagePath "$LanguagePacksDIR/Microsoft-Windows-Client-Language-Pack_x64_es-es.cab"
Add-WindowsPackage -Online -PackagePath "$LanguagePacksDIR/Microsoft-Windows-Client-Language-Pack_x64_en-GB.cab"
Add-WindowsPackage -Online -PackagePath "$LanguagePacksDIR/Microsoft-Windows-Client-Language-Pack_x64_en-US.cab"
