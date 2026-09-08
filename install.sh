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

# Download config template samples
download_file "configs/app_settings.json.sample" "configs/app_settings.json.sample"
download_file "configs/credentials.json.sample" "configs/credentials.json.sample"
download_file "configs/upstox_credentials.json.sample" "configs/upstox_credentials.json.sample"

# Set permissions on setup.sh
sudo chmod +x "$INSTALL_DIR/setup.sh"

# Initialize settings file if not exists
if [ ! -f "$INSTALL_DIR/configs/app_settings.json" ]; then
    # Generate secure random secrets
    JWT_SECRET=$(tr -dc 'a-f0-9' < /dev/urandom | head -c 64)
    DASH_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)

    sudo cp "$INSTALL_DIR/configs/app_settings.json.sample" "$INSTALL_DIR/configs/app_settings.json"
    
    # Replace placeholders in configs/app_settings.json
    sudo sed -i "s/your_secure_web_password/$DASH_PASSWORD/g" "$INSTALL_DIR/configs/app_settings.json"
    sudo sed -i "s/long_random_string_for_web_tokens/$JWT_SECRET/g" "$INSTALL_DIR/configs/app_settings.json"

    echo "[!] Configuration configs/app_settings.json initialized with secure credentials:"
    echo "    -----------------------------------------------------"
    echo "    Dashboard Password : $DASH_PASSWORD"
    echo "    JWT Secret Key     : (Dynamically generated & configured)"
    echo "    -----------------------------------------------------"
    echo "    *(You can modify these credentials anytime in configs/app_settings.json)*"
    echo ""
else
    echo "[*] Existing configs/app_settings.json found. Keeping original settings."
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
    echo "   1. Start the Server:"
    echo "      Run: cd $INSTALL_DIR && sudo docker compose up -d"
    echo ""
    echo "   2. Optional - Remote HTTPS Access (Cloudflare Tunnel):"
    echo "      Paste your Docker run command into:"
    echo "      $INSTALL_DIR/cloudflare_tunnel_command.txt"
    echo "      Then run: cd $INSTALL_DIR && sudo ./setup.sh"
    echo ""
    echo "   3. Route Your Domain (Cloudflare Tunnel):"
    echo "      In the Cloudflare Tunnel dashboard, go to the Public Hostname tab,"
    echo "      click Add a public hostname, and configure the fields:"
    echo "      - Subdomain: trader (or any subdomain of your choice, e.g. trader.yourdomain.com)."
    echo "      - Domain: Select your registered domain."
    echo "      - Type: HTTP"
    echo "      - URL: backend-api:8002 (routing requests internally inside the Docker network to the backend API container)."
    echo "      💡 Running cloudflared directly on your host system? Set the URL to localhost:8002 instead."
    echo ""
    echo "   4. Connect to Frontend Dashboard & Configure:"
    echo "      - Open your browser and go to: https://terminal.cloudtraderpro.in"
    echo "      - Select Server Type (Localhost or Cloud Server)."
    echo "      - Enter your Backend URL (http://localhost:8002 or your Cloudflare URL)."
    echo "      - Enter your auto-generated Dashboard Password and log in."
    echo "      - Once logged in, enter your License Key and Broker API credentials"
    echo "        directly inside the Settings page."
    echo ""
    echo "   5. Detailed Installation & Setup Guide:"
    echo "      Read: $INSTALL_DIR/README.md"
    echo "========================================================="
fi
