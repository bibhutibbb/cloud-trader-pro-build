#!/bin/bash

# Cloud Trader Pro - Linux Docker Setup Helper
echo "========================================================="
echo "        CLOUD TRADER PRO - DOCKER SETUP HELPER           "
echo "========================================================="
echo ""

# Get script folder and change context to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR" || exit 1

cmd=""
command_file="cloudflare_tunnel_command.txt"

if [ -f "$command_file" ]; then
    # Read file line by line, trim, strip backslashes, skip comments
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed=$(echo "$line" | xargs)
        # Skip empty or comments
        if [ -z "$trimmed" ] || [[ "$trimmed" =~ ^# ]]; then
            continue
        fi
        # Remove trailing backslash if present
        trimmed="${trimmed%\\}"
        trimmed=$(echo "$trimmed" | xargs)
        if [ -z "$cmd" ]; then
            cmd="$trimmed"
        else
            cmd="$cmd $trimmed"
        fi
    done < "$command_file"
fi

if [ -z "$cmd" ]; then
    echo "No Cloudflare command found in $command_file."
    echo "Please paste the full Docker Run command copied from the"
    echo "Cloudflare Tunnel dashboard, and press Enter:"
    echo ""
    read -r cmd
else
    echo "Found Cloudflare command configuration in $command_file."
fi

# Extract the token using regex
if [[ $cmd =~ --token[[:space:]\=]+\"?\'?([^[:space:]\"\'\\]+) ]]; then
    token="${BASH_REMATCH[1]}"
else
    # If they pasted only the token or regex failed, trim and use
    token=$(echo "$cmd" | xargs)
fi

if [ -z "$token" ]; then
    echo "[ERROR] Could not extract token. Please make sure you copied the correct command."
    exit 1
fi

# Write token to the .env file
echo "TUNNEL_TOKEN=$token" > .env
echo "[OK] Token successfully saved to .env file."

# Create docker-compose.override.yml dynamically to add the cloudflare tunnel sidecar service
cat << 'EOF' > docker-compose.override.yml
services:
  cloudflare-tunnel:
    image: cloudflare/cloudflared:latest
    restart: always
    command: tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}
EOF

echo "[OK] Created docker-compose.override.yml with Cloudflare Tunnel sidecar."

# Authenticate with GitHub Container Registry (GHCR) if private
if [ -f .env ]; then
    [ -z "$GHCR_USER" ] && GHCR_USER=$(grep "^GHCR_USER=" .env | cut -d '=' -f2)
    [ -z "$GHCR_TOKEN" ] && GHCR_TOKEN=$(grep "^GHCR_TOKEN=" .env | cut -d '=' -f2)
fi

if [ -z "$GHCR_USER" ] || [ -z "$GHCR_TOKEN" ]; then
    echo ""
    echo "========================================================="
    echo "  GitHub Container Registry (GHCR) Authentication        "
    echo "  (Required to pull private Cloud Trader Pro container)  "
    echo "========================================================="
    if [ -z "$GHCR_USER" ]; then
        read -p "Enter GitHub Username: " GHCR_USER
        echo "GHCR_USER=$GHCR_USER" >> .env
    fi
    if [ -z "$GHCR_TOKEN" ]; then
        read -r -p "Enter GitHub Token (ghp_...): " GHCR_TOKEN
        echo "GHCR_TOKEN=$GHCR_TOKEN" >> .env
    fi
fi

if [ -n "$GHCR_USER" ] && [ -n "$GHCR_TOKEN" ]; then
    echo "[*] Authenticating with GitHub Container Registry (GHCR)..."
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "[OK] GHCR authentication confirmed."
    fi
fi

echo "[*] Starting containers via Docker Compose..."
echo ""

docker compose up -d

echo ""
echo "========================================================="
echo "[SUCCESS] Cloud Trader Pro and Cloudflare Tunnel launched!"
echo "You can access your secure dashboard at your configured domain."
echo "========================================================="
