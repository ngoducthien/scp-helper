#!/bin/bash

# print a line of repeated characters by using the printf command
print_line() {
    local char="$1"
    local repeat="$2"
    printf "%${repeat}s\n" | tr ' ' "$char"
}

# Adjust this value to set the length of the line
repeat=80

# Read the JSON file and extract server information using jq
servers=$(jq -c '.servers[]' config.json)

# Display the list of servers with an exit option
echo "Available servers:"
echo "[0] Exit"
for server in $servers; do
    server_id=$(echo $server | jq '.server_id')
    server_address=$(echo $server | jq -r '.server_address')
    echo "[$server_id] $server_address"
done

# Prompt user to select a server or exit
read -p "Enter the server_id of the server you want to select (or 0 to exit): " selected_id

if [ "$selected_id" -eq 0 ]; then
    echo "Exiting..."
    exit 0
fi

# Find the selected server and display its full information
for server in $servers; do
    server_id=$(echo $server | jq '.server_id')
    if [ "$server_id" -eq "$selected_id" ]; then
        server_address=$(echo $server | jq -r '.server_address')
        server_port=$(echo $server | jq -r '.server_port')
        server_username=$(echo $server | jq -r '.server_username')
        server_keyfile=$(echo $server | jq -r '.server_keyfile')
        remote_dir=$(echo $server | jq -r '.remote_dir')
        local_dir=$(echo $server | jq -r '.local_dir')

        print_line "-" $repeat
        echo "  Server ID:  | $server_id"
        print_line "-" $repeat
        echo "  Address:    | $server_address"
        print_line "-" $repeat
        echo "  Port:       | ${server_port:-default (22)}"
        print_line "-" $repeat
        echo "  Username:   | $server_username"
        print_line "-" $repeat
        echo "  Keyfile:    | $server_keyfile"
        print_line "-" $repeat
        echo "  Remote dir: | $remote_dir"
        print_line "-" $repeat
        echo "  Local dir:  | $local_dir"
        print_line "-" $repeat

        
        # Prompt user to choose between Download, Upload, or Exit
        echo
        echo "Choose an action:"
        echo "[1] Download"
        echo "[2] Upload"
        echo "[0] Exit"
        read -p "Enter 1 for Download, 2 for Upload, or 0 to Exit: " action

        if [ "$action" -eq 1 ]; then
            # Prompt user for local destination folder
            echo
            print_line "-" $repeat
            echo "Choose the local destination folder:"
            echo "[1] Default folder ($local_dir)"
            echo "[2] Current folder ($(pwd))"
            echo "[3] Manually enter a folder path"
            read -p "Select 1, 2, or 3: " destination_option

            if [ "$destination_option" -eq 1 ]; then
                download_dir="$local_dir"
            elif [ "$destination_option" -eq 2 ]; then
                download_dir="$(pwd)"
            elif [ "$destination_option" -eq 3 ]; then
                echo
                print_line "-" $repeat
                read -p "Enter the local destination folder path: " download_dir
                # Verify that the specified folder exists
                if [ ! -d "$download_dir" ]; then
                    echo
                    echo "The specified folder does not exist. Exiting..."
                    exit 1
                fi
            else
                echo
                print_line "-" $repeat
                echo "Invalid option. Exiting..."
                exit 1
            fi

            # Download options
            echo
            print_line "-" $repeat
            echo "Download options:"
            echo "[1] List files in the default folder ($remote_dir)"
            echo "[2] Manually enter the file path"
            read -p "Choose 1 to list files or 2 to enter file path manually: " download_option
            
            if [ "$download_option" -eq 1 ]; then
                echo
                print_line "-" $repeat
                echo "Listing files in $remote_dir..."
                
                # Retrieve the file list
                if [ -n "$server_port" ]; then
                    file_list=$(ssh -i "$server_keyfile" -p "$server_port" "$server_username@$server_address" "ls -1 $remote_dir")
                else
                    file_list=$(ssh -i "$server_keyfile" "$server_username@$server_address" "ls -1 $remote_dir")
                fi

                # Display files with numbers and store in an array
                IFS=$'\n' read -rd '' -a files <<< "$file_list"
                for i in "${!files[@]}"; do
                    echo "[$i] ${files[i]}"
                done

                # Prompt user to select a file by number
                echo
                print_line "-" $repeat
                read -p "Enter the number of the file to download: " file_number
                if [[ "$file_number" =~ ^[0-9]+$ ]] && [ "$file_number" -ge 0 ] && [ "$file_number" -lt "${#files[@]}" ]; then
                    selected_filename="${files[$file_number]}"
                    remote_file_path="$remote_dir/$selected_filename"
                else
                    echo
                    echo "Invalid file number. Exiting..."
                    exit 1
                fi

            elif [ "$download_option" -eq 2 ]; then
                echo
                print_line "-" $repeat
                read -p "Enter the full path of the file to download: " remote_file_path
                selected_filename=$(basename "$remote_file_path")
            else
                echo
                print_line "-" $repeat
                echo "Invalid option. Exiting..."
                exit 1
            fi

            # Check if file exists locally
            local_file_path="$download_dir/$selected_filename"
            if [ -e "$local_file_path" ]; then
                echo
                print_line "-" $repeat
                echo "Warning: The file '$selected_filename' already exists in the destination folder."
                echo "Choose an option:"
                echo "[1] Save as new filename (new_TIMESTAMP_$selected_filename)"
                echo "[2] Overwrite the existing file"
                read -p "Enter 1 to save as new or 2 to overwrite: " file_choice

                if [ "$file_choice" -eq 1 ]; then
                    timestamp=$(date +%Y%m%d%H%M%S)
                    local_file_path="$download_dir/new_${timestamp}_$selected_filename"
                elif [ "$file_choice" -eq 2 ]; then
                    # Keep the same path for overwrite
                    :
                else
                    echo
                    print_line "-" $repeat
                    echo "Invalid choice. Exiting..."
                    exit 1
                fi
            fi

            echo
            print_line "-" $repeat
            echo "Starting download of $remote_file_path to $local_file_path..."
            # Download the file using scp (with or without port)
            if [ -n "$server_port" ]; then
                scp -i "$server_keyfile" -P "$server_port" "$server_username@$server_address:$remote_file_path" "$local_file_path"
            else
                scp -i "$server_keyfile" "$server_username@$server_address:$remote_file_path" "$local_file_path"
            fi

            echo
            print_line "-" $repeat
            echo "Download completed."


        elif [ "$action" -eq 2 ]; then
            # Upload section

            # Prompt user for remote destination folder
            echo
            print_line "-" $repeat
            echo "Choose the remote destination folder:"
            echo "[1] Default remote folder ($remote_dir)"
            echo "[2] Manually enter a remote folder path"
            read -p "Select 1 or 2: " remote_option

            if [ "$remote_option" -eq 1 ]; then
                upload_dir="$remote_dir"
            elif [ "$remote_option" -eq 2 ]; then
                echo
                print_line "-" $repeat
                read -p "Enter the remote destination folder path: " upload_dir
            else
                echo
                print_line "-" $repeat
                echo "Invalid option. Exiting..."
                exit 1
            fi

            # Upload file selection
            echo
            print_line "-" $repeat
            echo "Choose the file to upload:"
            echo "[1] List files in local directory ($local_dir)"
            echo "[2] Manually enter the file path"
            read -p "Select 1 or 2: " upload_file_option

            if [ "$upload_file_option" -eq 1 ]; then
                # List files in local_dir and allow the user to select
                echo
                print_line "-" $repeat
                echo "Files in $local_dir:"
                files=("$local_dir"/*)
                for i in "${!files[@]}"; do
                    echo "[$i] ${files[$i]}"
                done

                echo
                print_line "-" $repeat
                read -p "Enter the number of the file to upload: " file_number
                if [[ "$file_number" =~ ^[0-9]+$ ]] && [ "$file_number" -ge 0 ] && [ "$file_number" -lt "${#files[@]}" ]; then
                    local_file="${files[$file_number]}"
                else
                    echo
                    print_line "-" $repeat
                    echo "Invalid file number. Exiting..."
                    exit 1
                fi

            elif [ "$upload_file_option" -eq 2 ]; then
                echo
                print_line "-" $repeat
                read -p "Enter the full path of the file to upload: " local_file
                if [ ! -f "$local_file" ]; then
                    echo
                    echo "The specified file does not exist. Exiting..."
                    exit 1
                fi
            else
                echo
                print_line "-" $repeat
                echo "Invalid option. Exiting..."
                exit 1
            fi

            # Get the filename and check if it exists on the remote destination
            filename=$(basename "$local_file")
            if [ -n "$server_port" ]; then
                remote_file_check=$(ssh -i "$server_keyfile" -p "$server_port" "$server_username@$server_address" "[ -e '$upload_dir/$filename' ] && echo 'exists'")
            else
                remote_file_check=$(ssh -i "$server_keyfile" "$server_username@$server_address" "[ -e '$upload_dir/$filename' ] && echo 'exists'")
            fi

            # Handle if file exists on remote server
            if [ "$remote_file_check" == "exists" ]; then
                echo
                print_line "-" $repeat
                echo "Warning: The file '$filename' already exists in the destination folder on the server."
                echo "Choose an option:"
                echo "[1] Save as new filename (new_TIMESTAMP_$filename)"
                echo "[2] Overwrite the existing file"
                read -p "Enter 1 to save as new or 2 to overwrite: " file_choice

                if [ "$file_choice" -eq 1 ]; then
                    timestamp=$(date +%Y%m%d%H%M%S)
                    remote_file_path="$upload_dir/new_${timestamp}_$filename"
                elif [ "$file_choice" -eq 2 ]; then
                    remote_file_path="$upload_dir/$filename"
                else
                    echo
                    print_line "-" $repeat
                    echo "Invalid choice. Exiting..."
                    exit 1
                fi
            else
                remote_file_path="$upload_dir/$filename"
            fi

            # Start the upload process
            echo
            print_line "-" $repeat
            echo "Uploading $local_file to $remote_file_path on $server_address..."
            if [ -n "$server_port" ]; then
                scp -i "$server_keyfile" -P "$server_port" "$local_file" "$server_username@$server_address:$remote_file_path"
            else
                scp -i "$server_keyfile" "$local_file" "$server_username@$server_address:$remote_file_path"
            fi
            echo
            print_line "-" $repeat
            echo "Upload completed."

        elif [ "$action" -eq 0 ]; then
            echo
            print_line "-" $repeat
            echo "Exiting..."
            exit 0
        else
            echo
            print_line "-" $repeat
            echo "Invalid action selected. Exiting..."
            exit 1
        fi
        break
    fi
done

