# SCP-Helper

## Purpose
**SCP-Helper** is a streamlined shell script designed to simplify secure file transfers using the `scp` command. It provides an interactive interface to manage file downloads from and uploads to remote servers, ensuring a user-friendly experience.

## Usage
To use **SCP-Helper**, follow these steps:

1. **Prepare the Configuration File**:

Create a JSON configuration file named `config.json` in the same directory as `scp_helper.sh`. The file should contain the following structure:

   ```json
    {
        "servers": [
            {
                "server_id": 1,
                "server_address": "192.168.1.1",
                "server_port": 22,
                "server_username": "user1",
                "server_keyfile": "/path/to/keyfile1",
                "local_dir": "/path/to/local_dir1",
                "remote_dir": "/path/to/remote_dir1"
            },
            {
                "server_id": 2,
                "server_address": "192.168.1.2",
                "server_port": 22,
                "server_username": "user2",
                "server_keyfile": "/path/to/keyfile2",
                "local_dir": "/path/to/local_dir2",
                "remote_dir": "/path/to/remote_dir2"
            }
        ]
    }
    ```

Replace the placeholders with your actual server details and paths.

2. Run the Script: Execute the script from the terminal:

    ```bash
    sh scp_helper.sh
    ```

The script will guide you through the process of downloading files from a remote host or uploading files from your local host to a remote host.

## Features
- Server Selection: Choose from multiple pre-configured servers.
- File Transfer Options: Download files from or upload files to the specified server.
- Overwrite Protection: Manage existing files on the remote server with options to overwrite or save with a new filename.
- Flexible Paths: Specify local and remote directory paths easily.

## Requirements
- A Unix-like operating system (Linux, macOS)
- scp command available on your system
- jq for parsing JSON configuration files
