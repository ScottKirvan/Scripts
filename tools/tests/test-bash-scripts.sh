#!/usr/bin/env bash
#
# test-bash-scripts.sh - Unit tests for bash versions of the tools
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
TESTDATA_DIR="$SCRIPT_DIR/testdata"

J2C_SCRIPT="$TOOLS_DIR/j2c.sh"
VALIDATE_JSON_SCRIPT="$TOOLS_DIR/validate-json.sh"
VALIDATE_CSV_SCRIPT="$TOOLS_DIR/validate-csv.sh"

# Temp output directory
TEMP_OUTPUT="$TESTDATA_DIR/temp-bash-output"

# Setup
setup() {
    mkdir -p "$TEMP_OUTPUT"
}

# Cleanup
cleanup() {
    rm -rf "$TEMP_OUTPUT"
}

# Test result tracking
test_start() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  [TEST] $1 ... "
}

test_pass() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}FAIL${NC}"
    if [[ -n "${1:-}" ]]; then
        echo "    Error: $1"
    fi
}

# Check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        cat << 'EOF'
Error: jq is required but not installed

This test suite requires the 'jq' command-line JSON processor.

Installation instructions:
  • Ubuntu/Debian:  sudo apt-get install jq
  • macOS:          brew install jq
  • Fedora/RHEL:    sudo dnf install jq
  • Windows:        choco install jq
  • Or download from: https://jqlang.github.io/jq/download/

EOF
        exit 127
    fi
}

# Test validate-json.sh
test_validate_json() {
    echo -e "\n${CYAN}Testing validate-json.sh${NC}"

    # Test: Valid simple JSON
    test_start "Valid simple JSON"
    if bash "$VALIDATE_JSON_SCRIPT" -p "$TESTDATA_DIR/simple-flat.json" -q; then
        test_pass
    else
        test_fail "Should pass for valid JSON"
    fi

    # Test: Valid array JSON
    test_start "Valid array JSON"
    if bash "$VALIDATE_JSON_SCRIPT" -p "$TESTDATA_DIR/array-of-objects.json" -q; then
        test_pass
    else
        test_fail "Should pass for valid array JSON"
    fi

    # Test: Valid nested JSON
    test_start "Valid nested JSON"
    if bash "$VALIDATE_JSON_SCRIPT" -p "$TESTDATA_DIR/nested-objects.json" -q; then
        test_pass
    else
        test_fail "Should pass for valid nested JSON"
    fi

    # Test: Invalid JSON (malformed)
    test_start "Invalid malformed JSON"
    if bash "$VALIDATE_JSON_SCRIPT" -p "$TESTDATA_DIR/malformed.json" -q 2>/dev/null; then
        test_fail "Should fail for malformed JSON"
    else
        test_pass
    fi

    # Test: Empty JSON file
    test_start "Empty JSON file"
    if bash "$VALIDATE_JSON_SCRIPT" -p "$TESTDATA_DIR/empty.json" -q 2>/dev/null; then
        test_fail "Should fail for empty file"
    else
        test_pass
    fi

    # Test: Empty key detection
    test_start "Empty key detection"
    OUTPUT=$(bash "$VALIDATE_JSON_SCRIPT" -p "$TESTDATA_DIR/invalid-empty-key.json" -e 2>&1 || true)
    if echo "$OUTPUT" | grep -q "WARNING.*empty"; then
        test_pass
    else
        test_fail "Should warn about empty keys"
    fi

    # Test: stdin input
    test_start "Stdin input"
    if cat "$TESTDATA_DIR/simple-flat.json" | bash "$VALIDATE_JSON_SCRIPT" -p - -q; then
        test_pass
    else
        test_fail "Should work with stdin"
    fi
}

# Test validate-csv.sh
test_validate_csv() {
    echo -e "\n${CYAN}Testing validate-csv.sh${NC}"

    # Test: Valid simple CSV
    test_start "Valid simple CSV"
    if bash "$VALIDATE_CSV_SCRIPT" -p "$TESTDATA_DIR/valid-simple.csv" -q; then
        test_pass
    else
        test_fail "Should pass for valid CSV"
    fi

    # Test: Valid CSV with quotes
    test_start "Valid CSV with quotes"
    if bash "$VALIDATE_CSV_SCRIPT" -p "$TESTDATA_DIR/csv-with-quotes.csv" -q; then
        test_pass
    else
        test_fail "Should pass for CSV with quotes"
    fi

    # Test: Empty CSV file
    test_start "Empty CSV file"
    if bash "$VALIDATE_CSV_SCRIPT" -p "$TESTDATA_DIR/empty.csv" -q 2>/dev/null; then
        test_fail "Should fail for empty file"
    else
        test_pass
    fi

    # Test: Inconsistent columns warning
    test_start "Inconsistent columns warning"
    OUTPUT=$(bash "$VALIDATE_CSV_SCRIPT" -p "$TESTDATA_DIR/csv-inconsistent.csv" 2>&1)
    if echo "$OUTPUT" | grep -q "WARNING.*inconsistent"; then
        test_pass
    else
        test_fail "Should warn about inconsistent columns"
    fi

    # Test: stdin input
    test_start "Stdin input"
    if cat "$TESTDATA_DIR/valid-simple.csv" | bash "$VALIDATE_CSV_SCRIPT" -p - -q; then
        test_pass
    else
        test_fail "Should work with stdin"
    fi
}

# Test j2c.sh
test_j2c() {
    echo -e "\n${CYAN}Testing j2c.sh${NC}"

    # Test: Basic conversion to file
    test_start "Basic conversion to file"
    OUTPUT_FILE="$TEMP_OUTPUT/simple-flat.csv"
    if bash "$J2C_SCRIPT" -i "$TESTDATA_DIR/simple-flat.json" -o "$OUTPUT_FILE" 2>/dev/null; then
        if [[ -f "$OUTPUT_FILE" ]] && [[ -s "$OUTPUT_FILE" ]]; then
            test_pass
        else
            test_fail "Output file not created or empty"
        fi
    else
        test_fail "Conversion failed"
    fi

    # Test: Array of objects
    test_start "Array of objects conversion"
    OUTPUT_FILE="$TEMP_OUTPUT/array.csv"
    if bash "$J2C_SCRIPT" -i "$TESTDATA_DIR/array-of-objects.json" -o "$OUTPUT_FILE" 2>/dev/null; then
        LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
        if [[ $LINE_COUNT -eq 4 ]]; then  # 1 header + 3 data rows
            test_pass
        else
            test_fail "Expected 4 lines, got $LINE_COUNT"
        fi
    else
        test_fail "Conversion failed"
    fi

    # Test: Nested objects (dot notation)
    test_start "Nested objects with dot notation"
    OUTPUT_FILE="$TEMP_OUTPUT/nested.csv"
    if bash "$J2C_SCRIPT" -i "$TESTDATA_DIR/nested-objects.json" -o "$OUTPUT_FILE" 2>/dev/null; then
        if grep -q "user\.name" "$OUTPUT_FILE" && grep -q "user\.contact\.email" "$OUTPUT_FILE"; then
            test_pass
        else
            test_fail "Dot notation not found in output"
        fi
    else
        test_fail "Conversion failed"
    fi

    # Test: Stdout output
    test_start "Stdout output"
    OUTPUT=$(bash "$J2C_SCRIPT" -i "$TESTDATA_DIR/simple-flat.json" 2>/dev/null)
    if echo "$OUTPUT" | grep -q '"active"'; then
        test_pass
    else
        test_fail "Stdout output missing or invalid"
    fi

    # Test: Stdin input
    test_start "Stdin input"
    OUTPUT=$(cat "$TESTDATA_DIR/simple-flat.json" | bash "$J2C_SCRIPT" -i - 2>/dev/null)
    if echo "$OUTPUT" | grep -q '"active"'; then
        test_pass
    else
        test_fail "Stdin input failed"
    fi

    # Test: Empty key detection
    test_start "Empty key detection"
    if bash "$J2C_SCRIPT" -i "$TESTDATA_DIR/invalid-empty-key.json" -o "$TEMP_OUTPUT/error.csv" 2>/dev/null; then
        test_fail "Should fail for empty keys"
    else
        test_pass
    fi

    # Test: Malformed JSON
    test_start "Malformed JSON error"
    if bash "$J2C_SCRIPT" -i "$TESTDATA_DIR/malformed.json" -o "$TEMP_OUTPUT/error.csv" 2>/dev/null; then
        test_fail "Should fail for malformed JSON"
    else
        test_pass
    fi
}

# Main execution
main() {
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  Bash Scripts Test Suite${NC}"
    echo -e "${CYAN}======================================${NC}"

    check_dependencies
    setup

    test_validate_json
    test_validate_csv
    test_j2c

    cleanup

    # Summary
    echo -e "\n${CYAN}======================================${NC}"
    echo -e "${CYAN}  Test Results Summary${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo "Total Tests:  $TOTAL_TESTS"
    echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
    echo -e "${CYAN}======================================${NC}"

    # Exit with appropriate code
    if [[ $FAILED_TESTS -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main
main "$@"
