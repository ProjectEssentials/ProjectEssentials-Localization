[string] $updated = "02-12-2020"
[string] $version = "1.0.0"
[string] $mcVersion = "1.15.2"
[string] $downloadDir = "temp"
[string] $outDir = "out"
[string] $urlBase = "https://github.com/ProjectEssentials"
[array] $modules = ("core", "cooldown", "permissions", "essentials", "chat", "spawn", "home", "warps", "backup")
[array] $localizations = ("en_us", "ru_ru", "de_de")

Write-Output "Project Essentials resource-pack builder $version updated $updated."
Write-Output "Building resource pack is starting ..."

if ($modules.Count -eq 0) {
    Write-Warning "Modules whose resources should be bundled in resource-pack are not specified, by default all modules will be used."
    $modules = ("core", "cooldown", "permissions", "essentials", "chat", "spawn", "home", "warps", "backup")
}

function PurgeTempFiles {
    if (Test-Path -Path $downloadDir -PathType Container) {
        Remove-Item "$downloadDir\*" -Recurse -Force
    }
}

function DownloadLocalization {
    param (
        [string] $module
    )

    Write-Output "Starting proccessing resources for $module of version $mcVersion"

    $moduleVersion
    if ($mcVersion -eq "1.14.4") {
        if ($module -eq "permissions") {
            $moduleVersion = "1.14.X"
        }
        else {
            $moduleVersion = "1.14.4"
        }
    }
    else {
        $moduleVersion = "1.15.2"
    }

    $link
    if ($module -eq "essentials") {
        $link = "$urlBase/ProjectEssentials/raw/MC-$mcVersion/src/main/resources/assets/projectessentials/lang"
    }
    else {
        $link = "$urlBase/ProjectEssentials-$module/raw/MC-$moduleVersion/src/main/resources/assets/projectessentials$module/lang"
    }

    [array] $downloaded -join ', '

    ForEach ($localization in $localizations) {
        try {
            if ($module -eq "essentials") {
                [system.io.directory]::CreateDirectory("$downloadDir\assets\projectessentials\lang")
            }
            else {
                [system.io.directory]::CreateDirectory("$downloadDir\assets\projectessentials$module\lang")
            }
            
            if ($module -eq "essentials") {
                (New-Object System.Net.WebClient).DownloadFile("$link/$localization.json", "$downloadDir\assets\projectessentials\lang\$localization.json")
            }
            else {
                (New-Object System.Net.WebClient).DownloadFile("$link/$localization.json", "$downloadDir\assets\projectessentials$module\lang\$localization.json")
            }

            $downloaded += $localization
        }
        catch {
            Write-Warning "$localization not found in $module, will be skiped."
        }
        finally {
            Write-Output "Downloaded: $downloaded localizations for module $module"
            $downloaded = ("")
        }
    }
}


function Pack {
    param (
        [string] $module
    )

    Write-Output "Packing resource-pack for $module ..."

    [system.io.directory]::CreateDirectory($outDir)

    $source
    if ($module -eq "essentials") {
        $source = "$downloadDir\assets\projectessentials"
    }
    else {
        $source = "$downloadDir\assets\projectessentials$module"
    }

    $destination = "$outDir\ProjectEssentials-Localization-$mcVersion-$module.zip"

    If (Test-path $destination) { Remove-item $destination }

    Compress-Archive -Path $source -DestinationPath "$destination"
    Compress-Archive -Path "pack\$mcVersion\pack.mcmeta" -Update -DestinationPath "$destination"
}

function PackAll {
    Write-Output "Packing generic resource-pack ..."

    $source = "$downloadDir\assets"
    $destination = "$outDir\ProjectEssentials-Localization-$mcVersion-all.zip"

    If (Test-path $destination) { Remove-item $destination }

    Compress-Archive -Path $source -DestinationPath "$destination"
    Compress-Archive -Path "pack\$mcVersion\pack.mcmeta" -Update -DestinationPath "$destination"
}


PurgeTempFiles
ForEach ($module in $modules) {
    DownloadLocalization($module)
    Pack($module)
}

PackAll

Write-Output "Resource-packs generated! Done!"

Pause