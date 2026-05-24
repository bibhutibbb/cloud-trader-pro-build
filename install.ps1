# install.ps1 - Cloud Trader Pro Single-Line Installer for Windows
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "       INSTALLING CLOUD TRADER PRO BACKEND (WINDOWS)      " -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""

$INSTALL_DIR = "C:\CloudTraderPro"
$GITHUB_RAW_URL = "https://raw.githubusercontent.com/bibhutibbb/cloud-trader-pro-build/main"

Write-Host "[*] Creating target directory at $INSTALL_DIR..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\configs" | Out-Null
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\logs" | Out-Null
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\symbolmaster" | Out-Null

function Download-File {
    param (
        [string]$srcFile,
        [string]$destFile
    )
    Write-Host "[*] Fetching $srcFile..." -ForegroundColor Yellow
    $url = "$GITHUB_RAW_URL/$srcFile"
    $output = "$INSTALL_DIR\$destFile"
    
    try {
        Invoke-RestMethod -Uri $url -OutFile $output
    } catch {
        Write-Host "[ERROR] Failed to download $srcFile" -ForegroundColor Red
        Exit
    }
}

# Download base orchestration files
Download-File "docker-compose.yml" "docker-compose.yml"
Download-File "cloudflare_tunnel_command.txt" "cloudflare_tunnel_command.txt"
Download-File "setup.ps1" "setup.ps1"
Download-File "setup.bat" "setup.bat"
Download-File "Installation.html" "Installation.html"

# Download config template samples
Download-File "configs/app_settings.json.sample" "configs/app_settings.json.sample"
Download-File "configs/cf_secrets.json.sample" "configs/cf_secrets.json.sample"
Download-File "configs/credentials.json.sample" "configs/credentials.json.sample"
Download-File "configs/upstox_credentials.json.sample" "configs/upstox_credentials.json.sample"

# Initialize settings file if not exists
$settingsFile = "$INSTALL_DIR\configs\app_settings.json"
$sampleFile = "$INSTALL_DIR\configs\app_settings.json.sample"
if (-not (Test-Path $settingsFile)) {
    Copy-Item $sampleFile $settingsFile
    Write-Host "[!] Configuration template configs/app_settings.json created." -ForegroundColor Yellow
    Write-Host "    Make sure to edit this file later to add your license key and passwords." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[*] Configuration files downloaded successfully." -ForegroundColor Green
$response = Read-Host "Would you like to run the Cloudflare Tunnel setup helper now? (y/n)"

if ($response -match "^[Yy]$") {
    Set-Location $INSTALL_DIR
    & .\setup.ps1
} else {
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Green
    Write-Host "[OK] Files downloaded. To start the application manually:" -ForegroundColor Green
    Write-Host "   1. Go to: $INSTALL_DIR" -ForegroundColor Green
    Write-Host "   2. Configure configs\app_settings.json" -ForegroundColor Green
    Write-Host "   3. Run: docker compose up -d" -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
}
