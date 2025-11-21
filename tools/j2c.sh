#!/usr/bin/env bash
#
# j2c.sh - JSON to CSV converter for bash
# Converts JSON files to CSV format with support for nested objects and arrays
#

set -euo pipefail

# Default values
INPUT_PATH=""
OUTPUT_PATH=""
ARRAY_HANDLING="stringify"
MAX_DEPTH=3
DELIMITER=","

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") -i <input> [-o <output>] [-a <strategy>] [-d <depth>] [-s <separator>]

Options:
    -i, --input PATH        Input JSON file (required, or use stdin with -)
    -o, --output PATH       Output CSV file (optional, uses stdout if not specified)
    -a, --array STRATEGY    Array handling: stringify|concatenate|separate (default: stringify)
    -d, --depth NUMBER      Maximum nesting depth to flatten (default: 3)
    -s, --separator CHAR    CSV delimiter character (default: ,)
    -h, --help              Show this help message

Examples:
    $(basename "$0") -i data.json
    $(basename "$0") -i data.json -o output.csv
    $(basename "$0") -i data.json -a concatenate
    cat data.json | $(basename "$0") -i - > output.csv
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_PATH="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -a|--array)
            ARRAY_HANDLING="$2"
            shift 2
            ;;
        -d|--depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        -s|--separator)
            DELIMITER="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

# Check required arguments
if [[ -z "$INPUT_PATH" ]]; then
    echo "Error: Input path is required" >&2
    show_help >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    cat >&2 << 'EOF'
Error: jq is required but not installed

This script requires the 'jq' command-line JSON processor.

Installation instructions:
  • Ubuntu/Debian:  sudo apt-get install jq
  • macOS:          brew install jq
  • Fedora/RHEL:    sudo dnf install jq
  • Windows:        choco install jq
  • Or download from: https://jqlang.github.io/jq/download/

EOF
    exit 127  # Command not found
fi

# Read input
if [[ "$INPUT_PATH" == "-" ]]; then
    echo "Reading JSON from stdin..." >&2
    JSON_DATA=$(cat)
else
    if [[ ! -f "$INPUT_PATH" ]]; then
        echo "Error: Input file not found: $INPUT_PATH" >&2
        exit 1
    fi
    echo "Reading JSON from: $INPUT_PATH" >&2
    JSON_DATA=$(cat "$INPUT_PATH")
fi

# Check for empty input
if [[ -z "$JSON_DATA" || "$JSON_DATA" == "null" ]]; then
    echo "Error: Empty or null JSON input" >&2
    exit 1
fi

# Check for empty keys
if echo "$JSON_DATA" | grep -q '""[[:space:]]*:'; then
    echo "Error: Invalid JSON - Found empty string as property name" >&2
    exit 1
fi

# Flatten JSON to CSV
echo "Converting JSON to CSV..." >&2

# Build jq filter based on array handling
case "$ARRAY_HANDLING" in
    stringify)
        ARRAY_FILTER='tostring'
        ;;
    concatenate)
        ARRAY_FILTER='join("; ")'
        ;;
    separate)
        # This is complex and would require multiple passes
        echo "Warning: 'separate' mode not fully implemented in bash version, using stringify" >&2
        ARRAY_FILTER='tostring'
        ;;
    *)
        echo "Error: Invalid array handling strategy: $ARRAY_HANDLING" >&2
        exit 1
        ;;
esac

# Function to flatten nested objects with dot notation
flatten_json() {
    local depth="$1"
    jq -r --arg depth "$depth" --arg array_filter "$ARRAY_FILTER" '
    def flatten_obj(prefix; max_depth; current_depth):
        if current_depth >= (max_depth | tonumber) then
            if type == "object" then
                tostring
            elif type == "array" then
                ('"$ARRAY_FILTER"')
            else
                .
            end
        else
            if type == "object" then
                to_entries |
                map(
                    if .value | type == "object" then
                        .value | flatten_obj((prefix + (if prefix == "" then "" else "." end) + .key); max_depth; current_depth + 1)
                    elif .value | type == "array" then
                        {key: (prefix + (if prefix == "" then "" else "." end) + .key), value: (.value | '"$ARRAY_FILTER"')}
                    else
                        {key: (prefix + (if prefix == "" then "" else "." end) + .key), value: .value}
                    end
                ) |
                if type == "array" then . else [.] end |
                flatten |
                from_entries
            elif type == "array" then
                ('"$ARRAY_FILTER"')
            else
                .
            end
        end;

    if type == "array" then
        map(flatten_obj(""; $depth; 0))
    else
        [flatten_obj(""; $depth; 0)]
    end |
    (.[0] | keys_unsorted) as $keys |
    $keys,
    (.[] | [.[$keys[]]] | map(. // "")) |
    @csv
    ' <<< "$JSON_DATA"
}

# Convert JSON to CSV
CSV_OUTPUT=$(flatten_json "$MAX_DEPTH")

# Handle delimiter if not comma
if [[ "$DELIMITER" != "," ]]; then
    CSV_OUTPUT=$(echo "$CSV_OUTPUT" | sed "s/,/$DELIMITER/g")
fi

# Output to file or stdout
if [[ -n "$OUTPUT_PATH" ]]; then
    echo "Writing CSV to: $OUTPUT_PATH" >&2
    echo "$CSV_OUTPUT" > "$OUTPUT_PATH"
    echo "SUCCESS: Conversion complete!" >&2
    echo "  Rows: $(echo "$CSV_OUTPUT" | wc -l)" >&2
else
    echo "Writing CSV to stdout..." >&2
    echo "$CSV_OUTPUT"
    echo "SUCCESS: Conversion complete!" >&2
fi
