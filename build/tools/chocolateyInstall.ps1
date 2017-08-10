﻿$ErrorActionPreference = 'Stop'

$packageName = 'keypirinha'
$packageVersion = '2.15.3.20170810'

$url32 = "https://github.com/Keypirinha/Keypirinha/releases/download/v$packageVersion/keypirinha-$packageVersion-x86-portable.7z"
$url64 = "https://github.com/Keypirinha/Keypirinha/releases/download/v$packageVersion/keypirinha-$packageVersion-x64-portable.7z"

$checksum32 = 'a239aca5e168e20c9115e970574fb5a4e045da92a18863dbdfd8b17ddcb858e8'
$checksum64 = 'a9286c7b696f4123b3c58a52bdabde3bf2a58c87a98865ac552dec7a5faf1bfe'
$checksumType = 'sha256'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$installDir = "$toolsDir\keypirinha"
$portableDir = "$toolsDir\keypirinha\portable"

Write-Host 'Stopping Keypirinha...'
Stop-Process -processname keypirinha* -force

# Manually remove shims erroneously created by previous versions of the
# Chocolatey package (2.15.3 and previous).
# We specify their -Path to ensure only Keypirinha's shims are removed.
Uninstall-BinFile -Name "keypirinha-x86" `
                  -Path "$installDir\bin\x86\keypirinha-x86.exe"
Uninstall-BinFile -Name "keypirinha-x64" `
                  -Path "$installDir\bin\x64\keypirinha-x64.exe"
Uninstall-BinFile -Name "Notepad2" `
                  -Path "$installDir\bin\x86\bin\notepad2\Notepad2.exe"
Uninstall-BinFile -Name "Notepad2" `
                  -Path "$installDir\bin\x64\bin\notepad2\Notepad2.exe"

# Note: a "Get-ProcessorBits 64" test would be redundant here since
# Install-ChocolateyZipPackage apparently takes care of choosing the appropriate
# URL
Install-ChocolateyZipPackage -PackageName $packageName `
                             -Url $url32 `
                             -UnzipLocation "$toolsDir" `
                             -Url64bit $url64 `
                             -Checksum $checksum32 `
                             -ChecksumType $checksumType `
                             -Checksum64 $checksum64 `
                             -Checksum64Type $checksumType

# Generate an "*.ignore" file for every executable except keypirinha.exe, so
# Chocolatey creates only one shim for Keypirinha (i.e. "keypirinha.exe" at the
# root of $installDir).
$files = Get-ChildItem $installDir -include *.exe -recurse
foreach ($file in $files) {
  if (!($file.Name.Contains('keypirinha.exe'))) {
    New-Item "$file.ignore" -type file -force | Out-Null
  }
}

# Generate a "keypirinha.exe.gui" file to ensure Chocolatey does not run
# Keypirinha in console mode.
# Note: it did not seem to be necessary during tests...
New-Item "$installDir\keypirinha.exe.gui" -type file -force | Out-Null

# Keypirinha specific: delete the "portable" directory to enable "Install Mode"
if ( $(Try { Test-Path $portableDir } Catch { $false }) ) {
  Write-Host "Deleting `'$portableDir`' so that Keypirinha runs in Install Mode"
  Remove-Item -Recurse -Force $portableDir
}
