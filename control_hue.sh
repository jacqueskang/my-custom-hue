#!/bin/bash

# Exit the script on any error and display an error message
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR
set -e

CONFIG_FILE=~/.hue/config

# Create the ~/.hue/ folder if it does not exist
mkdir -p ~/.hue

# Function to save the configuration
save_config() {
  echo "bridge_ip=$HUE_BRIDGE_IP" >> $CONFIG_FILE
  echo "username=$USERNAME" > $CONFIG_FILE
}

# Check if the local file ~/.hue/config exists
if [ -f $CONFIG_FILE ]; then
  # Read Hue Bridge IP address from the configuration file
  USERNAME=$(grep 'username' $CONFIG_FILE | cut -d '=' -f2 | xargs)
  HUE_BRIDGE_IP=$(grep 'bridge_ip' $CONFIG_FILE | cut -d '=' -f2 | xargs)
fi

# If the bridge IP is not found in the config, try to retrieve it from the URL
if [ -z "$HUE_BRIDGE_IP" ]; then
  echo "Trying to retrieve the bridge IP address..."
  HUE_BRIDGE_IP=$(curl -s -k https://discovery.meethue.com/ | jq -r '.[0].internalipaddress')
fi

# If the bridge IP is retrieved, ask the user for confirmation
if [ -n "$HUE_BRIDGE_IP" ]; then
  echo "Retrieved Hue Bridge IP address: $HUE_BRIDGE_IP"
  read -p "Is this correct? (y/n): " confirm
  if [ "$confirm" != "y" ]; then
    read -p "Please enter the correct Hue Bridge IP address: " HUE_BRIDGE_IP
  fi
else
  # If the bridge IP is not retrieved, ask the user to provide it
  read -p "Please enter the Hue Bridge IP address: " HUE_BRIDGE_IP
fi

# Ask the user to confirm the username if it is retrieved from the config file
if [ -n "$USERNAME" ]; then
  echo "Configured username: $USERNAME"
  read -p "Is this correct? (y/n): " confirm
  if [ "$confirm" != "y" ]; then
    USERNAME=""
  fi
fi

# If the username is not retrieved or not confirmed, ask the user whether to generate a new user
if [ -z "$USERNAME" ]; then
  read -p "Do you want to generate a new user? (y/n): " generate_user
  if [ "$generate_user" == "y" ]; then
    echo "Please press the link button on your Hue Bridge, then press any key to continue within 10 second..."
    read -n 1 -s
    USERNAME_RESPONSE=$(curl -s -k -X POST -d '{"devicetype":"my_hue_app#jacqueskang"}' "https://$HUE_BRIDGE_IP/api")
    USERNAME=$(echo $USERNAME_RESPONSE | jq -r '.[0].success.username // empty')
    if [ -z "$USERNAME" ]; then
      ERROR_MESSAGE=$(echo $USERNAME_RESPONSE | jq -r '.[0].error.description')
      echo -e "\e[31mFailed to generate a new user! Error: $ERROR_MESSAGE\e[0m"
      exit 1
    fi
    echo "Generated username: $USERNAME"
    # Save the configuration if a new username is generated
    save_config
  else
    echo "Username is required to control the Hue lights!"
    exit 1
  fi
fi

# Save the configuration
save_config

# List lights
echo "Listing lights..."
LIGHTS_RESPONSE=$(curl -s -k "https://$HUE_BRIDGE_IP/api/$USERNAME/lights")
LIGHTS=$(echo $LIGHTS_RESPONSE | jq -r 'to_entries[] | "\(.key): \(.value.name)"')
if [ -z "$LIGHTS" ]; then
  echo "No lights found or failed to retrieve lights."
else
  echo "Lights found:"
  echo "$LIGHTS"
fi

# Ask user to select lights by ID (comma-separated)
read -p "Please enter the IDs of the lights you want to control (comma-separated): " LIGHT_IDS
IFS=',' read -r -a LIGHT_ID_ARRAY <<< "$LIGHT_IDS"

# Validate selected lights
for LIGHT_ID in "${LIGHT_ID_ARRAY[@]}"; do
  SELECTED_LIGHT=$(echo "$LIGHTS" | grep "^$LIGHT_ID: ")
  if [ -z "$SELECTED_LIGHT" ]; then
    echo "Invalid light ID selected: $LIGHT_ID"
    exit 1
  else
    echo "Selected light: $SELECTED_LIGHT"
  fi
done

# Turn on the selected lights
for LIGHT_ID in "${LIGHT_ID_ARRAY[@]}"; do
  TURN_ON_RESPONSE=$(curl -s -k -X PUT -d '{"on":true}' "https://$HUE_BRIDGE_IP/api/$USERNAME/lights/$LIGHT_ID/state")
  if echo "$TURN_ON_RESPONSE" | grep -q '"success"'; then
    echo "Light $LIGHT_ID turned on successfully."
  else
    echo "Failed to turn on light $LIGHT_ID."
  fi
done

# Ask user to select the style
echo "Select the light style:"
echo "1. Spectrum"
echo "2. Police"
read -p "Enter the number of the style you want to use: " STYLE

# Apply the selected style
case $STYLE in
  1)
    echo "Cycling through colors (Spectrum). Press any key to stop."
    while true; do
      for HUE in {0..65535..6554}; do
        for LIGHT_ID in "${LIGHT_ID_ARRAY[@]}"; do
          curl -s -k -X PUT -d "{\"hue\":$HUE, \"sat\":254}" "https://$HUE_BRIDGE_IP/api/$USERNAME/lights/$LIGHT_ID/state" > /dev/null
        done
        sleep 0.1
        if read -t 0.1 -n 1; then
          break 2
        fi
      done
    done
    ;;
  2)
    echo "Cycling through colors (Police). Press any key to stop."
    while true; do
      for COLOR in "red" "blue"; do
        case $COLOR in
          "red") HUE=0 ;;
          "blue") HUE=46920 ;;
        esac
        for LIGHT_ID in "${LIGHT_ID_ARRAY[@]}"; do
          curl -s -k -X PUT -d "{\"hue\":$HUE, \"sat\":254}" "https://$HUE_BRIDGE_IP/api/$USERNAME/lights/$LIGHT_ID/state" > /dev/null
        done
        sleep 0.5
        if read -t 0.1 -n 1; then
          break 2
        fi
      done
    done
    ;;
  *)
    echo "Invalid style selected."
    exit 1
    ;;
esac

# ...existing code...
