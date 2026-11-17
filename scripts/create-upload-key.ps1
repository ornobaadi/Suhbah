# Creates the Play upload keystore for Suhbah and prints its fingerprints.
# Run from the project root:  powershell -ExecutionPolicy Bypass -File scripts\create-upload-key.ps1
# keytool asks for the passwords itself; they are never stored by this script.
$dir = Join-Path $env:USERPROFILE "keys"
New-Item -ItemType Directory -Force $dir | Out-Null
$jks = Join-Path $dir "suhbah-upload.jks"
if (Test-Path $jks) { Write-Host "Keystore already exists at $jks"; exit 1 }
keytool -genkeypair -v -keystore $jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload `
  -dname "CN=Suhbah"
Write-Host ""
Write-Host "Created $jks. Fingerprints (add both in Firebase > Project settings > Android app):"
keytool -list -v -keystore $jks -alias upload | Select-String "SHA1:|SHA256:"
Write-Host ""
Write-Host "Next: copy android\key.properties.example to android\key.properties and fill in the passwords and this path:"
Write-Host ($jks -replace '\','/')
