# Ntfy Syncthing Conflict Checker

A simple Zsh script to detect and report file conflicts in Syncthing shared folders.

## Features

- Scans all Syncthing shared folders for sync conflicts
- Supports both local output and remote notifications via ntfy
- Verbose mode for detailed output
- Customizable notification topics
- Checks for required dependencies

## Requirements

- Zsh shell
- Syncthing with `syncthingctl` command available. Can be found [on this repo](https://github.com/Martchus/syncthingtray)
- (Optional) ntfy for remote notifications

## Installation

1. Clone this repository or download the script:

```bash
cd ntfy_syncthing-conflict-checker
```

2. Make the script executable:

```bash
chmod +x ntfy_syncthing_conflict_checker.sh
```

## Usage

Basic usage:
```bash
./ntfy_syncthing_conflict_checker.sh
```

Options:
```
-v, --verbose     Show verbose output
-t, --topic       Specify notification topic (default: print)
-D, --no-date     Don't include dates in the output
-h, --help        Show this help message
```

Examples:

1. Check for conflicts with verbose output:
```bash
./ntfy_syncthing_conflict_checker.sh --verbose
```

2. Send notifications to a specific ntfy topic:
```bash
./ntfy_syncthing_conflict_checker.sh --topic mytopic
```

3. Check for conflicts without showing dates:
```bash
./ntfy_syncthing_conflict_checker.sh --no-date
```

## Output

The script will output:
- A list of paths containing conflicts
- The full paths of conflicting files
- Warnings for non-existent paths (in verbose mode)
- Confirmation when no conflicts are found (in verbose mode)

## Notification Support

When using the `--topic` option, the script will send notifications via ntfy. Make sure ntfy is installed and configured.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Acknowledgements

- Syncthing project: https://syncthing.net/
- ntfy project: https://ntfy.sh/
