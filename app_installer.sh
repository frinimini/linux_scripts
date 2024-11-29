#!/bin/bash

# Log file to keep track of installations
LOG_FILE="installer.log"

# Helper function for logging with timestamps
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DESKTOP_DEB_PATH="$SCRIPT_DIR/docker-installers/docker-desktop-amd64.deb"

# Function to ensure wget is installed via apt
ensure_wget_installed_apt() {
    if ! command -v wget &> /dev/null; then
        log "wget is not installed. Installing wget via apt..."
        sudo apt update | tee -a "$LOG_FILE"
        sudo apt install -y wget | tee -a "$LOG_FILE"

        if [ $? -ne 0 ]; then
            log "Failed to install wget via apt."
        else
            log "wget has been installed successfully via apt."
        fi
    else
        log "wget is already installed."
    fi
}

# Function to ensure wget is installed via Homebrew
ensure_wget_installed_brew() {
    if ! command -v wget &> /dev/null; then
        log "wget is not installed. Installing wget via Homebrew..."
        brew install wget | tee -a "$LOG_FILE"

        if [ $? -ne 0 ]; then
            log "Failed to install wget via Homebrew."
        else
            log "wget has been installed successfully via Homebrew."
        fi
    else
        log "wget is already installed."
    fi
}

# Function to install Tilix
install_tilix() {
    if command -v tilix &> /dev/null; then
        log "Tilix is already installed."
    else
        log "Updating package lists..."
        sudo apt update | tee -a "$LOG_FILE"

        log "Installing Tilix..."
        sudo apt install -y tilix | tee -a "$LOG_FILE"

        if [ $? -eq 0 ]; then
            log "Tilix has been installed successfully!"
        else
            log "Failed to install Tilix. Please check the log for details."
        fi
    fi
}

# Function to install Git
install_git() {
    if command -v git &> /dev/null; then
        log "Git is already installed."
    else
        read -p "Do you want to install Git? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Updating package lists..."
            sudo apt update | tee -a "$LOG_FILE"

            log "Installing Git..."
            sudo apt install -y git | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Git has been installed successfully!"
            else
                log "Failed to install Git. Please check the log for details."
            fi
        else
            log "Git installation canceled."
        fi
    fi
}

# Function to install Homebrew and its dependencies
install_homebrew() {
    if command -v brew &> /dev/null; then
        log "Homebrew is already installed."
    else
        log "Installing Homebrew..."
        # Install Homebrew using the official installation script
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" | tee -a "$LOG_FILE"

        # Determine Homebrew prefix dynamically
        BREW_PREFIX=$(brew --prefix 2>/dev/null)

        if [ -d "$BREW_PREFIX" ]; then
            log "Configuring Homebrew environment..."
            # Append Homebrew environment setup to .bashrc if not already present
            grep -qxF "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" "$HOME/.bashrc" || echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$HOME/.bashrc"

            # Evaluate the Homebrew environment for the current session
            eval "$(${BREW_PREFIX}/bin/brew shellenv)"

            log "Homebrew has been installed and configured successfully!"

            log "Installing build-essential via apt..."
            sudo apt-get install -y build-essential | tee -a "$LOG_FILE"

            log "Installing GCC via Homebrew..."
            brew install gcc | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Dependencies have been installed successfully!"
            else
                log "Failed to install dependencies. Please check the log for details."
            fi
        else
            log "Homebrew installation failed. Please check the installation logs."
        fi
    fi
}

# Function to install Visual Studio Code (Stable)
install_vscode() {
    if command -v code &> /dev/null; then
        log "Visual Studio Code (stable version) is already installed."
    else
        read -p "Do you want to install Visual Studio Code (stable version)? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing Visual Studio Code (stable version) via Snap..."
            sudo snap install code --classic | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Visual Studio Code (stable version) has been installed successfully!"
            else
                log "Failed to install Visual Studio Code (stable version). Please check the log for details."
            fi
        else
            log "Visual Studio Code (stable version) installation canceled."
        fi
    fi
}

# Function to install Visual Studio Code Insiders
install_vscodeinsiders() {
    if command -v code-insiders &> /dev/null; then
        log "Visual Studio Code Insiders is already installed."
    else
        read -p "Do you want to install Visual Studio Code Insiders? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing Visual Studio Code Insiders via Snap..."
            sudo snap install code-insiders --classic | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Visual Studio Code Insiders has been installed successfully!"
            else
                log "Failed to install Visual Studio Code Insiders. Please check the log for details."
            fi
        else
            log "Visual Studio Code Insiders installation canceled."
        fi
    fi
}

# Function to install Docker Engine and Docker Desktop
install_docker() {
    # Ensure wget is installed via apt
    ensure_wget_installed_apt

    # Check if Docker Engine is installed
    if command -v docker &> /dev/null; then
        log "Docker Engine is already installed."
    else
        log "Installing Docker Engine..."

        # Add Docker's official GPG key
        log "Adding Docker's official GPG key..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg | tee -a "$LOG_FILE"

        # Set up the stable repository
        log "Setting up the Docker repository..."
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Update package index again after adding Docker repo
        log "Updating package index..."
        sudo apt update | tee -a "$LOG_FILE"

        # Install Docker Engine, CLI, and containerd
        log "Installing Docker Engine, CLI, and containerd..."
        sudo apt install -y docker-ce docker-ce-cli containerd.io | tee -a "$LOG_FILE"

        if [ $? -eq 0 ]; then
            log "Docker Engine has been installed successfully!"
        else
            log "Failed to install Docker Engine. Please check the log for details."
            return
        fi

        # Add current user to the docker group
        log "Adding current user to the docker group..."
        sudo usermod -aG docker $USER | tee -a "$LOG_FILE"

        # Enable Docker to start on boot
        log "Enabling Docker to start on boot..."
        sudo systemctl enable docker | tee -a "$LOG_FILE"

        # Start Docker service
        log "Starting Docker service..."
        sudo systemctl start docker | tee -a "$LOG_FILE"

        # Check Docker service status
        log "Checking Docker service status..."
        sudo systemctl status docker | tee -a "$LOG_FILE"

        log "Docker Engine installation completed successfully."
    fi

    # Check if Docker Desktop is installed
    if dpkg -l | grep -q docker-desktop; then
        log "Docker Desktop is already installed."
    else
        log "Installing Docker Desktop..."

        # Create directory for Docker installers if it doesn't exist
        if [ ! -d "$SCRIPT_DIR/docker_installers" ]; then
            log "Creating directory $SCRIPT_DIR/docker_installers for storing Docker installers..."
            mkdir -p "$SCRIPT_DIR/docker_installers" | tee -a "$LOG_FILE"
        fi

        # Define Docker Desktop .deb download path
        DOCKER_DESKTOP_DEB_PATH="$SCRIPT_DIR/docker_installers/docker-desktop-amd64.deb"

        # Download the Docker Desktop .deb file if not already downloaded
        if [ ! -f "$DOCKER_DESKTOP_DEB_PATH" ]; then
            log "Downloading Docker Desktop from https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb..."
            wget -O "$DOCKER_DESKTOP_DEB_PATH" "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb" | tee -a "$LOG_FILE"

            if [ $? -ne 0 ]; then
                log "Failed to download Docker Desktop. Please check your internet connection or the download URL."
                return
            fi
        else
            log "Docker Desktop .deb file already exists at $DOCKER_DESKTOP_DEB_PATH."
        fi

        # Install Docker Desktop
        log "Installing Docker Desktop..."
        sudo apt install -y "$DOCKER_DESKTOP_DEB_PATH" | tee -a "$LOG_FILE"

        if [ $? -eq 0 ]; then
            log "Docker Desktop has been installed successfully!"
        else
            log "Failed to install Docker Desktop. Please check the log for details."
            return
        fi

        # Enable Docker Desktop to start on boot
        log "Enabling Docker Desktop to start on boot..."
        sudo systemctl enable --now docker-desktop | tee -a "$LOG_FILE"

        # Check Docker Desktop service status
        log "Checking Docker Desktop service status..."
        sudo systemctl status docker-desktop | tee -a "$LOG_FILE"

        log "Docker Desktop installation completed successfully."
    fi

    echo "Docker Engine and Docker Desktop installation completed." | tee -a "$LOG_FILE"
    echo "Please log out and log back in to apply group changes." | tee -a "$LOG_FILE"
}

# Function to update Docker Desktop
update_docker_desktop() {
    # Define Docker Desktop .deb download path
    DOCKER_DESKTOP_DEB_PATH="$SCRIPT_DIR/docker_installers/docker-desktop-amd64.deb"

    # Check if Docker Desktop is installed
    if ! dpkg -l | grep -q docker-desktop; then
        log "Docker Desktop is not installed. Please install it first using the installer."
        return
    fi

    # Check if the .deb file exists
    if [ ! -f "$DOCKER_DESKTOP_DEB_PATH" ]; then
        log "Docker Desktop .deb file not found at $DOCKER_DESKTOP_DEB_PATH."
        log "Please install Docker Desktop first or download the .deb file manually."
        return
    fi

    # Update Docker Desktop using the .deb file
    log "Updating Docker Desktop using the existing .deb file..."
    sudo apt install -y "$DOCKER_DESKTOP_DEB_PATH" | tee -a "$LOG_FILE"

    if [ $? -eq 0 ]; then
        log "Docker Desktop has been updated successfully!"
    else
        log "Failed to update Docker Desktop. Please check the log for details."
        return
    fi

    # Ensure Docker Desktop is enabled to start on boot
    log "Ensuring Docker Desktop is enabled to start on boot..."
    sudo systemctl enable --now docker-desktop | tee -a "$LOG_FILE"

    # Check Docker Desktop service status
    log "Checking Docker Desktop service status..."
    sudo systemctl status docker-desktop | tee -a "$LOG_FILE"

    echo "Docker Desktop update completed." | tee -a "$LOG_FILE"
}

# Function to install Python using Homebrew
install_python() {
    if command -v python3 &> /dev/null; then
        log "Python is already installed."
    else
        if ! command -v brew &> /dev/null; then
            log "Homebrew is not installed. Please install Homebrew first."
            return
        fi

        read -p "Do you want to install Python via Homebrew? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing Python via Homebrew..."
            brew install python | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Python has been installed successfully!"
            else
                log "Failed to install Python. Please check the log for details."
            fi
        else
            log "Python installation canceled."
        fi
    fi
}

# Function to install Node.js using Homebrew
install_node() {
    if command -v node &> /dev/null; then
        log "Node.js is already installed."
    else
        if ! command -v brew &> /dev/null; then
            log "Homebrew is not installed. Please install Homebrew first."
            return
        fi

        read -p "Do you want to install Node.js via Homebrew? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing Node.js via Homebrew..."
            brew install node | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Node.js has been installed successfully!"
            else
                log "Failed to install Node.js. Please check the log for details."
            fi
        else
            log "Node.js installation canceled."
        fi
    fi
}

# Function to install Java using Homebrew
install_java() {
    if command -v java &> /dev/null; then
        log "Java is already installed."
    else
        if ! command -v brew &> /dev/null; then
            log "Homebrew is not installed. Please install Homebrew first."
            return
        fi

        read -p "Do you want to install Java via Homebrew? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing Java via Homebrew..."
            brew install java | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Java has been installed successfully!"
            else
                log "Failed to install Java. Please check the log for details."
            fi
        else
            log "Java installation canceled."
        fi
    fi
}

# Function to install wget via Homebrew
install_wget_brew() {
    if command -v wget &> /dev/null; then
        log "wget is already installed."
    else
        if ! command -v brew &> /dev/null; then
            log "Homebrew is not installed. Please install Homebrew first."
            return
        fi

        read -p "Do you want to install wget via Homebrew? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing wget via Homebrew..."
            brew install wget | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "wget has been installed successfully via Homebrew!"
            else
                log "Failed to install wget via Homebrew. Please check the log for details."
            fi
        else
            log "wget installation via Homebrew canceled."
        fi
    fi
}

# Function to install Expo CLI using npm
install_expo_cli() {
    if command -v expo &> /dev/null; then
        log "Expo CLI is already installed."
    else
        if ! command -v node &> /dev/null; then
            log "Node.js is not installed. Please install Node.js first."
            return
        fi

        if ! command -v npm &> /dev/null; then
            log "npm is not installed. Please ensure Node.js is properly installed."
            return
        fi

        read -p "Do you want to install Expo CLI globally using npm? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Installing Expo CLI globally using npm..."
            npm install -g expo-cli | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                log "Expo CLI has been installed successfully!"
            else
                log "Failed to install Expo CLI. Please check the log for details."
            fi
        else
            log "Expo CLI installation canceled."
        fi
    fi
}

# Function to display the main menu
show_menu() {
    echo "===================================="
    echo "      Application Installer"
    echo "===================================="
    echo "Please choose an option:"
    echo "1) Install Tilix"
    echo "2) Install Git"
    echo "3) Install Homebrew"
    echo "4) Install Visual Studio Code (Stable)"
    echo "5) Install Visual Studio Code Insiders"
    echo "6) Install Docker Engine and Desktop"
    echo "7) Update Docker Desktop"
    echo "8) Install Python"
    echo "9) Install Node.js"
    echo "10) Install Java"
    echo "11) Install wget via Homebrew"
    echo "12) Install Expo CLI"
    echo "13) Back"
    echo "14) Quit"
    echo "===================================="
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [1-14]: " choice

    case $choice in
        1)
            install_tilix
            ;;
        2)
            install_git
            ;;
        3)
            install_homebrew
            ;;
        4)
            install_vscode
            ;;
        5)
            install_vscodeinsiders
            ;;
        6)
            install_docker
            ;;
        7)
            update_docker_desktop
            ;;
        8)
            install_python
            ;;
        9)
            install_node
            ;;
        10)
            install_java
            ;;
        11)
            install_wget_brew
            ;;
        12)
            install_expo_cli
            ;;
        13)
            # Since this is the main menu, 'Back' can be used to refresh the menu or can be left for future sub-menus
            log "You are already at the main menu."
            ;;
        14)
            log "Exiting the installer. Goodbye!"
            exit 0
            ;;
        *)
            log "Invalid option. Please try again."
            ;;
    esac

    echo # Adds an empty line for better readability
done
