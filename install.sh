#!/bin/bash
# install.sh - Cloud Trader Pro Single-Line Installer for Linux/Ubuntu

echo "========================================================="
echo "       INSTALLING CLOUD TRADER PRO BACKEND               "
echo "========================================================="
echo ""

# Define target installation directory (Allow custom path via first argument, prompt for subfolder name under /opt/ if empty)
DEFAULT_SUBDIR="cloudtraderpro"
if [ -n "$1" ]; then
    if [[ "$1" =~ ^/ ]]; then
        INSTALL_DIR="$1"
    else
        INSTALL_DIR="/opt/$1"
    fi
else
    read -p "Enter installation folder name under /opt/ [$DEFAULT_SUBDIR]: " custom_subdir < /dev/tty
    SUBDIR="${custom_subdir:-$DEFAULT_SUBDIR}"
    # Strip any leading slashes if entered by user
    SUBDIR="${SUBDIR#/}"
    INSTALL_DIR="/opt/$SUBDIR"
fi

echo "[*] Installing to: $INSTALL_DIR"
GITHUB_RAW_URL="https://raw.githubusercontent.com/bibhutibbb/cloud-trader-pro-build/main"

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

# Download image assets (only favicon is needed for Installation.html)
download_file "img/shoonya_scalper.ico" "img/shoonya_scalper.ico"

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

# Grant ownership of the installation directory to the active user (correctly resolving sudo context)
REAL_USER=${SUDO_USER:-$USER}
sudo chown -R "$REAL_USER":"$REAL_USER" "$INSTALL_DIR"

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
    echo "   4. Detailed Installation & Setup Guide:"
    echo "      Open $INSTALL_DIR/Installation.html in your browser."
    echo ""
    echo "   5. Platform User Manual & Workflows:"
    echo "      Access via your web browser: http://localhost:8002/manual.html"
    echo "========================================================="
fi
