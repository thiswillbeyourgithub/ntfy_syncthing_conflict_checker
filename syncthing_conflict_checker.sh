#!/bin/zsh

# Initialize default values
verbose=false
topic="print"

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [options]
Options:
    -v, --verbose     Show verbose output
    -t, --topic      Specify notification topic (default: print)
    -h, --help       Show this help message
EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            verbose=true
            shift
            ;;
        -t|--topic)
            if [[ -z "$2" ]]; then
                echo "Error: topic argument is required" >&2
                show_usage
            fi
            topic="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            # For backward compatibility, treat single argument as topic
            if [[ $# -eq 1 && "$topic" == "print" ]]; then
                topic="$1"
                shift
            else
                echo "Error: Unknown option $1" >&2
                show_usage
            fi
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
