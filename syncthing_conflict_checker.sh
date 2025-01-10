#!/bin/zsh

# Store topic before parsing args
if [ -z "$1" ]; then
    echo "Error: No ntfy topic provided"
    exit 1
fi
topic=$1
shift

# Parse arguments
verbose=false
while getopts ":v" opt; do
  case $opt in
    v)
      verbose=true
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
    ntfy pub "$topic" "Error: syncthingctl could not be found, please install it first"
    exit 1
fi

# Get all synced paths
sync_paths=$(syncthingctl | awk '{print $NF}' | grep '^/')

if [ -z "$sync_paths" ]; then
    ntfy pub "$topic" "Error: No synced paths found"
    exit 1
fi

# Initialize conflicts variable
conflicts=""

# Search for conflicts in each path
echo "$sync_paths" | while IFS= read -r sync_path; do
    if [ ! -d "$sync_path" ]; then
        ntfy pub "$topic" "Warning: Path $sync_path does not exist or is not a directory"
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
    ntfy pub "$topic" "Sync conflicts found in:\n$sync_paths\n\nConflicts:\n$conflicts"
elif [ "$verbose" = true ]; then
    ntfy pub "$topic" "No sync conflicts found in:\n$sync_paths"
fi
