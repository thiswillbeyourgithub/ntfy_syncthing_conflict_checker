#!/bin/zsh

# Parse arguments
verbose=true
while getopts ":v" opt; do
  case $opt in
    v)
      verbose=false
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Check if ntfy is installed
if ! command -v ntfy &> /dev/null; then
    echo "ntfy could not be found, please install it first"
    exit 1
fi

# Check if syncthingctl is installed
if ! command -v syncthingctl &> /dev/null; then
    ntfy pub "$1" "Error: syncthingctl could not be found, please install it first"
    exit 1
fi

# Get all synced paths
sync_paths=$(syncthingctl | awk '{print $NF}' | grep '^/')

if [ -z "$sync_paths" ]; then
    ntfy pub "$1" "Error: No synced paths found"
    exit 1
fi

# Initialize conflicts variable
conflicts=""

# Search for conflicts in each path
echo "$sync_paths" | while IFS= read -r sync_path; do
    if [ ! -d "$sync_path" ]; then
        ntfy pub "$1" "Warning: Path $sync_path does not exist or is not a directory"
        continue
    fi
    
    # Find conflicts and append to variable
    new_conflicts=$(find "$sync_path" -type f -name "*sync.conflict*")
    if [ -n "$new_conflicts" ]; then
        conflicts+="$new_conflicts\n"
    fi
done

# Send results
if [ -n "$conflicts" ]; then
    ntfy pub "$1" "Sync conflicts found in:\n$sync_paths\n\nConflicts:\n$conflicts"
elif [ "$verbose" = true ]; then
    ntfy pub "$1" "No sync conflicts found in:\n$sync_paths"
fi
