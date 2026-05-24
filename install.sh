#!/bin/bash
# install.sh - Cloud Trader Pro Single-Line Installer for Linux/Ubuntu

echo "========================================================="
echo "       INSTALLING CLOUD TRADER PRO BACKEND               "
echo "========================================================="
echo ""

# Define target installation directory
INSTALL_DIR="/opt/cloudtraderpro"
GITHUB_RAW_URL="https://raw.githubusercontent.com/bibhutibbb/cloud-trader-pro-build/main"

echo "[*] Creating target directory at $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR/configs"
sudo mkdir -p "$INSTALL_DIR/logs"
sudo mkdir -p "$INSTALL_DIR/symbolmaster"
sudo mkdir -p "$INSTALL_DIR/datafetcher/historicaldatas"
sudo mkdir -p "$INSTALL_DIR/backtester/backtest_histories"
sudo mkdir -p "$INSTALL_DIR/img"

# Function to download files safely
download_file() {
    local src_file="$1"
    local dest_file="$2"
    echo "[*] Fetching $src_file..."
    sudo curl -sSL "$GITHUB_RAW_URL/$src_file" -o "$INSTALL_DIR/$dest_file"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to download $src_file"
        exit 1
    fi
}

# Download base orchestration files
download_file "docker-compose.yml" "docker-compose.yml"
download_file "cloudflare_tunnel_command.txt" "cloudflare_tunnel_command.txt"
download_file "setup.sh" "setup.sh"
download_file "Installation.html" "Installation.html"

# Download image assets
download_file "img/shoonya_scalper.ico" "img/shoonya_scalper.ico"
download_file "img/shoonya_scalper.png" "img/shoonya_scalper.png"

# Download config template samples
download_file "configs/app_settings.json.sample" "configs/app_settings.json.sample"
download_file "configs/cf_secrets.json.sample" "configs/cf_secrets.json.sample"
download_file "configs/credentials.json.sample" "configs/credentials.json.sample"
download_file "configs/upstox_credentials.json.sample" "configs/upstox_credentials.json.sample"

# Set permissions on setup.sh
sudo chmod +x "$INSTALL_DIR/setup.sh"

# Initialize settings file if not exists
if [ ! -f "$INSTALL_DIR/configs/app_settings.json" ]; then
    sudo cp "$INSTALL_DIR/configs/app_settings.json.sample" "$INSTALL_DIR/configs/app_settings.json"
    echo "[!] Configuration template configs/app_settings.json created."
    echo "    Make sure to edit this file later to add your license key and passwords."
fi

echo ""
echo "[*] Configuration files downloaded successfully."
read -p "Would you like to run the Cloudflare Tunnel setup helper now? (y/n): " run_setup

if [[ "$run_setup" =~ ^[Yy]$ ]]; then
    cd "$INSTALL_DIR"
    sudo ./setup.sh
else
    echo ""
    echo "========================================================="
    echo "       CLOUD TRADER PRO BACKEND - SETUP CHECKLIST        "
    echo "========================================================="
    echo "   1. Configure settings:"
    echo "      Open and edit: $INSTALL_DIR/configs/app_settings.json"
    echo "      Add your API keys, passwords, and license."
    echo ""
    echo "   2. Optional - Remote HTTPS Access (Cloudflare Tunnel):"
    echo "      Paste your Docker run command into:"
    echo "      $INSTALL_DIR/cloudflare_tunnel_command.txt"
    echo "      Then run: cd $INSTALL_DIR && sudo ./setup.sh"
    echo ""
    echo "   3. Start the Server:"
    echo "      Run: cd $INSTALL_DIR && sudo docker compose up -d"
    echo ""
    echo "   4. Detailed manual and walkthroughs:"
    echo "      Open $INSTALL_DIR/Installation.html in your browser."
    echo "========================================================="
fi
