#!/bin/bash

# GitHub repository URL
repo_url="https://api.github.com/repos/dhruv-2015/JIOTVServer/releases"
jtv_server_zip_url="https://github.com/dhruv-2015/JIOTVServer/releases/download/V2.9.3/JTVServer.zip"
start_sh_url="https://raw.githubusercontent.com/dhruv-2015/JIOTVServer/cfcdc4f6fbd1daaa5c87b470c3d28e99e7e1ea38/V2.0.3/start.sh"

# Function to get latest release number from GitHub repository
get_latest_release_number() {
    release_number=$(curl -s "$repo_url" | grep -oP '"tag_name": "\K([^"]+)' | head -n 1 | cut -c 2-)
    echo "$release_number"
}

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to get device IP address
get_device_ip() {
    # Use ifconfig to fetch the IP address (assuming wlan0 interface)
    ip_address=$(ifconfig 2> /dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '192\.168\.[0-9]+\.[0-9]+')
    echo "$ip_address"
}

# Function to install dependencies and setup JTVServer
install() {
    apt update && apt upgrade -y
    echo "Y" | pkg install nodejs-lts wget 
    wget "$jtv_server_zip_url" -N && unzip JTVServer.zip && rm JTVServer.zip
    curl -o start.sh "$start_sh_url"
    echo "${GREEN}Installation completed.${NC}"
}

# Function to update JTVServer
update() {
    rm JTVServer -rf
    wget "$jtv_server_zip_url" -N && unzip JTVServer.zip && rm JTVServer.zip
    curl -o start.sh "$start_sh_url"
    echo "${YELLOW}Update completed.${NC}"
}

# Function to uninstall JTVServer
uninstall() {
    rm JTVServer -rf
    echo "${RED}Uninstallation completed.${NC}"
}

# Function to get user choice
get_choice() {
    local prompt="$1"
    local valid_options="$2"
    local user_choice

    read -p "$prompt" user_choice

    # Validate user input
    if [[ ! "$user_choice" =~ ^[$valid_options]$ ]]; then
        echo "${RED}Invalid choice. Please enter a valid option.${NC}"
        get_choice "$prompt" "$valid_options"
    fi

    echo "$user_choice"
}

create_shortcut() {
    shortcuts_dir="/data/data/com.termux/files/home/.shortcuts"
    icons_dir="$shortcuts_dir/icons"

    mkdir -p "$shortcuts_dir" "$icons_dir"
    chmod -R 700 "$shortcuts_dir" && chmod -R a-x,u=rwX,go-rwx "$icons_dir"

    echo "${CYAN}Select shortcut option:${NC}"
    echo "1 - ${GREEN}Launch Shortcut${NC}"
    echo "2 - ${CYAN}Setup Shortcut${NC}"

    choice=$(get_choice "Enter your choice (1 or 2): " "1-2")

    script_name="launch_shortcut.sh"
    script_content="termux-wake-lock\necho \"server is running on port 3500 in background\"\necho \"open http://localhost:3500/ to setup\"\ncd ~\nsh start.sh"

    case $choice in
        1) create_script "$shortcuts_dir/$script_name" "$script_content"
           download_icon "$icons_dir/$script_name.png" "https://raw.githubusercontent.com/mahipat99/jtvserver2/main/$script_name.png"
           echo "${GREEN}Launch Shortcut created.${NC}"
           ;;

        2) create_script "$shortcuts_dir/setup_shortcut.sh" "cd ~\nsh setup.sh"
           download_icon "$icons_dir/setup_shortcut.sh.png" "https://raw.githubusercontent.com/mahipat99/jtvserver2/main/setup_shortcut.sh.png"
           echo "${CYAN}Setup Shortcut created.${NC}"
           ;;

        *) echo "${RED}Invalid choice. Exiting.${NC}" ;;
    esac
}

# Function to create autoboot
create_autoboot() {
    echo "${CYAN}Setting up autoboot...${NC}"
    mkdir -p ~/.termux/boot  # Create directory if not exists
    echo "termux-wake-lock" > .termux/boot/auto-start.sh
    echo "echo \"server is running on port 3500 in background\"" >> .termux/boot/auto-start.sh
    echo "echo \"open http://localhost:3500/ to setup\"" >> .termux/boot/auto-start.sh
    echo "cd ~" >> .termux/boot/auto-start.sh
    echo "bash start.sh" >> .termux/boot/auto-start.sh
    echo "${GREEN}Autoboot setup completed.${NC}"
}

# Function to launch JTVServer
launch() {
    bash start.sh
}

# Function to open the login page
login() {
    ip_address=$(get_device_ip)
    if [ -n "$ip_address" ]; then
        url="http://${ip_address}:3500/login"
        termux-open $url
    else
        echo "Unable to determine the IP address."
    fi
}

# Function to update this script
update_script() {
    # Delete the existing script and suppress warning
    rm setup.sh 2>/dev/null
    curl -o setup.sh https://raw.githubusercontent.com/mahipat99/jtvserver2/main/setup.sh
    chmod +x setup.sh  # Make sure the script is executable
    echo "${YELLOW}Script updated.${NC}"
}

# Main script
clear
echo "${CYAN}"
cat << "EOF"
     ██╗██╗ ██████╗ ████████╗██╗   ██╗
     ██║██║██╔═══██╗╚══██╔══╝██║   ██║
     ██║██║██║   ██║   ██║   ██║   ██║
██   ██║██║██║   ██║   ██║   ╚██╗ ██╔╝
╚█████╔╝██║╚██████╔╝   ██║    ╚████╔╝ 
 ╚════╝ ╚═╝ ╚═════╝    ╚═╝     ╚═══╝  
EOF
echo  "${MAGENTA}By Mahipat${NC}"
echo  "${CYAN}Current Version - 2.9.3${NC} | ${YELLOW}Latest Release - $(get_latest_release_number)${NC}"
echo  "${GREEN}Mobile local IP - $(get_device_ip)${NC}"
echo  "${YELLOW}Select an option:${NC}"
echo  "1 - ${GREEN}Install${NC}"
echo  "2 - ${YELLOW}Update${NC}"
echo  "3 - ${RED}Uninstall${NC}"
echo  "4 - ${CYAN}Create a shortcut${NC}"
echo  "5 - ${CYAN}Create autoboot${NC}"
echo  "6 - ${GREEN}Launch${NC}"
echo  "7 - ${CYAN}Login${NC}"
echo  "8 - ${YELLOW}Update this script${NC}"

read -p "Enter your choice (1-8): " choice

case $choice in
    1) install ;;
    2) update ;;
    3) uninstall ;;
    4) create_shortcut ;;
    5) create_autoboot ;;
    6) launch ;;
    7) login ;;
    8) update_script ;;
    *) echo "${RED}Invalid choice. Exiting.${NC}" ;;
esac

