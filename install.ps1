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
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\datafetcher\historicaldatas" | Out-Null
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\backtester\backtest_histories" | Out-Null
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\img" | Out-Null

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

# Download image assets (only favicon is needed for Installation.html)
Download-File "img/cloud-trader-pro.ico" "img/cloud-trader-pro.ico"

# Download config template samples
Download-File "configs/app_settings.json.sample" "configs/app_settings.json.sample"
Download-File "configs/credentials.json.sample" "configs/credentials.json.sample"
Download-File "configs/upstox_credentials.json.sample" "configs/upstox_credentials.json.sample"

# Initialize settings file if not exists
$settingsFile = "$INSTALL_DIR\configs\app_settings.json"
$sampleFile = "$INSTALL_DIR\configs\app_settings.json.sample"
if (-not (Test-Path $settingsFile)) {
    # Generate secure random secrets
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $dashPassword = -join (1..12 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $hexChars = 'abcdef0123456789'
    $jwtSecret = -join (1..64 | ForEach-Object { $hexChars[(Get-Random -Maximum $hexChars.Length)] })

    Copy-Item $sampleFile $settingsFile
    
    # Replace placeholders in configs/app_settings.json
    $content = Get-Content $settingsFile -Raw
    $content = $content -replace "your_secure_web_password", $dashPassword
    $content = $content -replace "long_random_string_for_web_tokens", $jwtSecret
    Set-Content $settingsFile $content -NoNewline
    
    Write-Host "[!] Configuration configs/app_settings.json initialized with secure credentials:" -ForegroundColor Yellow
    Write-Host "    -----------------------------------------------------" -ForegroundColor Yellow
    Write-Host "    Dashboard Password : $dashPassword" -ForegroundColor Green
    Write-Host "    JWT Secret Key     : (Dynamically generated & configured)" -ForegroundColor Green
    Write-Host "    -----------------------------------------------------" -ForegroundColor Yellow
    Write-Host "    *(You can modify these credentials anytime in configs/app_settings.json)*" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "[*] Existing configs/app_settings.json found. Keeping original settings." -ForegroundColor Green
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
    Write-Host "       CLOUD TRADER PRO BACKEND - SETUP CHECKLIST        " -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
    Write-Host "   1. Configure settings:" -ForegroundColor Green
    Write-Host "      Open and edit: $INSTALL_DIR\configs\app_settings.json" -ForegroundColor Green
    Write-Host "      Add your license key." -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "   2. Optional - Setup Remote Access (Cloudflare Tunnel):" -ForegroundColor Green
    Write-Host "      Paste your Docker run command into cloudflare_tunnel_command.txt" -ForegroundColor Green
    Write-Host "      Then run: cd $INSTALL_DIR; .\setup.ps1" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "   3. Start the Server:" -ForegroundColor Green
    Write-Host "      Run: cd $INSTALL_DIR; docker compose up -d" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "   4. Connect to Frontend Dashboard:" -ForegroundColor Green
    Write-Host "      - Open your browser and go to: https://terminal.cloudtraderpro.in" -ForegroundColor Green
    Write-Host "      - Select Server Type (Localhost or Cloud Server)." -ForegroundColor Green
    Write-Host "      - Enter your Backend URL (http://localhost:8002 or your Cloudflare Tunnel HTTPS URL)." -ForegroundColor Green
    Write-Host "      - Enter your Dashboard Password and log in." -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "   5. Detailed Installation & Setup Guide:" -ForegroundColor Green
    Write-Host "      Open $INSTALL_DIR\Installation.html in your browser." -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
}
