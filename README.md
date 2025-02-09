# My Custom Hue Control Script

This script allows you to control your Philips Hue lights by interacting with the Hue Bridge. It can turn on a selected light and cycle through colors.

## Prerequisites

- Bash shell
- `curl` command
- `jq` command

## Usage

1. Clone the repository and navigate to the directory:
    ```bash
    git clone <repository-url>
    cd my-custom-hue
    ```

2. Make the script executable:
    ```bash
    chmod +x control_hue.sh
    ```

3. Run the script:
    ```bash
    ./control_hue.sh
    ```

4. Follow the prompts:
    - The script will try to retrieve the Hue Bridge IP address automatically. If it fails, you will be asked to enter it manually.
    - If a username is not found in the configuration, you will be prompted to generate a new user. Press the link button on your Hue Bridge and then press any key to continue.
    - The script will list all available lights. Enter the ID of the light you want to control.
    - The selected light will turn on and start cycling through colors. Press any key to stop the color cycling.

## Configuration

The script saves the Hue Bridge IP address and username in the `~/.hue/config` file for future use.

## Notes

- Ensure that your Hue Bridge and the device running the script are on the same network.
- The script skips SSL verification for the Hue API calls.
