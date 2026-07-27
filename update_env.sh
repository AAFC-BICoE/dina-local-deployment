#!/usr/bin/env bash

set -e

# Check for input file argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_env_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE=".env"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' does not exist."
    exit 1
fi

# Check if output file exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Output file '$OUTPUT_FILE' already exists. Skipping secret generation."
    exit 0
fi

# Function to generate a random 16-character string
generate_random_value() {
    openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16
}

# Process the env file
{
    while IFS= read -r line || [ -n "$line" ]; do

        # Match valid env var format: VAR= or VAR="value"
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            var_name="${BASH_REMATCH[1]}"
            var_value="${BASH_REMATCH[2]}"
            # Clean up whitespace from value
            var_value="${var_value#"${var_value%%[![:space:]]*}"}"

            # Replace empty or quote-only values with random string
            if [ -z "$var_value" ] || [[ "$var_value" =~ ^\"[[:space:]]*$ ]] || [[ "$var_value" =~ ^\'[[:space:]]*$ ]]; then
                var_value="$(generate_random_value)"
            fi

            echo "${var_name}=${var_value}"
        else
            # Preserve lines that do not match expected format (for comments or other non-env lines)
            echo "$line"
        fi
    done < "$INPUT_FILE"
} > "$OUTPUT_FILE"
