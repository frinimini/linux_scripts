#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
INSTALL_DIR="ComfyUI-Manager-Setup"
SCRIPT_URL="https://github.com/ltdrdata/ComfyUI-Manager/raw/main/scripts/install-comfyui-venv-linux.sh"
COMFYUI_PORT="8188"
ALIAS_NAME="comfyui"
ALIAS_COMMAND="source $PWD/ComfyUI/venv/bin/activate && python $PWD/ComfyUI/main.py"

# Update system and install prerequisites
echo "Updating system and installing prerequisites..."
sudo apt update
sudo apt install -y python3 python3-venv git wget

# Create installation directory
echo "Creating installation directory..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Download the installation script
echo "Downloading installation script..."
wget -q $SCRIPT_URL -O install-comfyui-venv-linux.sh
chmod +x install-comfyui-venv-linux.sh

# Run the installation script
echo "Running installation script..."
./install-comfyui-venv-linux.sh

# Navigate to the ComfyUI directory
cd ComfyUI

# Check and create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Add alias to shell configuration
echo "Adding alias for ComfyUI..."
if ! grep -q "alias $ALIAS_NAME=" ~/.bashrc; then
    echo "alias $ALIAS_NAME='$ALIAS_COMMAND'" >> ~/.bashrc
    echo "Alias added. Please run 'source ~/.bashrc' to activate the alias."
else
    echo "Alias already exists in ~/.bashrc."
fi

# Run ComfyUI
echo "Starting ComfyUI..."
python main.py &

# Wait for ComfyUI to start
sleep 5

# Provide access information
echo "ComfyUI is running. Access it in your browser at: http://127.0.0.1:$COMFYUI_PORT"
