# Cloud Trader Pro - Windows Docker Setup Helper
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "        CLOUD TRADER PRO - DOCKER SETUP HELPER           " -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""

$cmd = ""
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ScriptDir) { $ScriptDir = "." }
$commandFile = Join-Path $ScriptDir "cloudflare_tunnel_command.txt"

if (Test-Path $commandFile) {
    # Read the whole file content
    $content = Get-Content -Path $commandFile -Raw
    if (-not [string]::IsNullOrEmpty($content)) {
        # Split into lines to remove comments
        $lines = $content -split '\r?\n'
        $validLines = @()
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if (-not [string]::IsNullOrEmpty($trimmed) -and -not $trimmed.StartsWith("#")) {
                # Remove trailing backslashes if it was copy-pasted multi-line
                $trimmed = $trimmed -replace '\\$', ''
                $validLines += $trimmed.Trim()
            }
        }
        # Join the lines with spaces to make it a single-line command
        $cmd = $validLines -join " "
    }
}

if ([string]::IsNullOrEmpty($cmd)) {
    Write-Host "No Cloudflare command found in $commandFile."
    Write-Host "Please paste the full Docker Run command copied from the"
    Write-Host "Cloudflare Tunnel dashboard, and press Enter:"
    Write-Host ""
    $cmd = Read-Host
} else {
    Write-Host "Found Cloudflare command configuration in $commandFile."
}

# Extract the token using regex
if ($cmd -match '--token[\s=]+["'']?([^\s"''>]+)') {
    $token = $Matches[1]
} else {
    # If they pasted only the token, use it directly
    $token = $cmd.Trim()
}

if ([string]::IsNullOrEmpty($token)) {
    Write-Host "[ERROR] Could not extract token. Please make sure you copied the correct command." -ForegroundColor Red
    Exit
}

# Write token to the .env file in ASCII encoding to prevent formatting issues
$envFile = Join-Path $ScriptDir ".env"
"TUNNEL_TOKEN=$token" | Out-File -FilePath $envFile -Encoding ascii
Write-Host "[OK] Token successfully saved to .env file." -ForegroundColor Cyan

# Create docker-compose.override.yml dynamically to add the cloudflare tunnel sidecar service
$overrideContent = @'
services:
  cloudflare-tunnel:
    image: cloudflare/cloudflared:latest
    container_name: cloudflare-tunnel
    restart: always
    command: tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}
'@

$overrideFile = Join-Path $ScriptDir "docker-compose.override.yml"
$overrideContent | Out-File -FilePath $overrideFile -Encoding ascii
Write-Host "[OK] Created docker-compose.override.yml with Cloudflare Tunnel sidecar." -ForegroundColor Cyan

Write-Host "[*] Starting containers via Docker Compose..." -ForegroundColor Yellow
Write-Host ""

Set-Location $ScriptDir
docker compose up -d

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Cloud Trader Pro and Cloudflare Tunnel launched!" -ForegroundColor Green
Write-Host "You can access your secure dashboard at your configured domain." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
