#!/bin/zsh

# Initialize default values
verbose=false
topic="print"
nodate=false
abspath=false

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [options]
Options:
    -v, --verbose    Show verbose output
    -t, --topic      Specify notification topic (default: print)
    -D, --no-date    Dont include dates in the output
    -a, --absolute   Use absolute paths instead of relative
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
            # Check if ntfy is installed
            if ! command -v ntfy &> /dev/null; then
                echo "ntfy could not be found, please install it first"
                exit 1
            fi
            topic="$2"
            shift 2
            ;;
        -D|--no-date)
            nodate=true
            shift
            ;;
        -a|--absolute)
            abspath=true
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            show_usage
            ;;
    esac
done

function notify() {
    if [[ "$topic" == "print" ]]
    then
        echo "$1"
    else
        # clean newlines for ntfy
        cleaned=$(echo "$1" | sed 's/\n/\r\r/g')
        NTFY_TITLE="Syncthing Conflicts" ntfy pub --quiet "$topic" "$cleaned"
    fi
}

# Check if syncthingctl is installed
if ! command -v syncthingctl &> /dev/null; then
    notify "Error: syncthingctl could not be found, please install it first"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    notify "Error: jq could not be found, please install it first"
    exit 1
fi

# Get all synced paths and sort them alphabetically
sync_paths=$(syncthingctl cat | jq -r '.folders[]["path"]' | sort)

if [ -z "$sync_paths" ]; then
    notify "Error: No synced paths found"
    exit 1
fi

# Initialize variables
conflicts=""
conflict_paths=""

# Search for conflicts in each path
echo "$sync_paths" | while IFS= read -r sync_path; do
    if [ ! -d "$sync_path" ]; then
        notify "Warning: Path $sync_path does not exist or is not a directory"
        continue
    fi
    if [[ "$verbose" == true ]]; then
        echo "checking $sync_path"
    fi

    if [[ "$abspath" == "true" ]]
    then
        pathcmd='$1'
    else
        pathcmd='$(realpath --relative-to="'$sync_path'" "$1")'
    fi
    
    # Find conflicts and append to variable with relative paths and if needed creation dates
    # Exclude conflicts in .stversions directories as they are just versioning files
    if [[ "$nodate" == "false" ]]
    then
        new_conflicts=$(find "$sync_path" -type f -name "*\.sync-conflict-*-*-*" -not -path "*/.stversions/*" -exec sh -c 'printf "%s (%s)\n" "'$pathcmd'" "$(stat -c "%y" "$1" | cut -d"." -f1)"' _ {} \; | sort)
    else
        new_conflicts=$(find "$sync_path" -type f -name "*\.sync-conflict-*-*-*" -not -path "*/.stversions/*" -exec sh -c 'printf "%s\n" "'$pathcmd'"' _ {} \; | sort)
    fi

    if [ -n "$new_conflicts" ]; then
        conflicts+="$new_conflicts\n"
        # Add path to conflict_paths if not already present
        if [[ ! "$conflict_paths" =~ "$sync_path" ]]; then
            conflict_paths+="$sync_path\n"
        fi
    fi
done

# Send results
if [ -n "$conflicts" ]; then
    notify "Sync conflicts found in:\n$conflict_paths\n\nConflicts:\n$conflicts"
elif [ "$verbose" = true ]; then
    notify "No sync conflicts found in:\n$sync_paths"
fi
