# JSON/CSV Tools Test Suite

Comprehensive test suite for the JSON/CSV conversion and validation tools.

## Test Structure

```
tests/
├── README.md                    # This file
├── Run-AllTests.ps1            # Test runner script
├── validate-json.Tests.ps1     # Tests for validate-json.ps1
├── validate-csv.Tests.ps1      # Tests for validate-csv.ps1
├── j2c.Tests.ps1              # Tests for j2c.ps1 (json to csv)
└── testdata/                   # Test data files
    ├── simple-flat.json        # Simple flat JSON object
    ├── array-of-objects.json   # Array of objects
    ├── nested-objects.json     # Nested object structures
    ├── with-arrays.json        # JSON with array properties
    ├── varying-schema.json     # Objects with different properties
    ├── with-nulls.json         # JSON with null values
    ├── deep-nesting.json       # Deeply nested objects (5+ levels)
    ├── empty-array.json        # JSON with empty arrays
    ├── special-characters.json # Special characters, quotes, unicode
    ├── invalid-empty-key.json  # JSON with empty property name
    ├── malformed.json          # Invalid JSON syntax
    ├── empty.json              # Empty file
    ├── valid-simple.csv        # Simple valid CSV
    ├── csv-with-quotes.csv     # CSV with quoted fields
    ├── csv-inconsistent.csv    # CSV with inconsistent columns
    ├── empty.csv               # Empty CSV file
    ├── test.json               # Original test file with empty key
    ├── test-fixed.json         # Fixed version with named key
    └── test-fixed.csv          # Generated CSV output
```

## Prerequisites

Install Pester (PowerShell testing framework):

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

## Running Tests

### Run All Tests
```powershell
.\Run-AllTests.ps1
```

### Run with Detailed Output
```powershell
.\Run-AllTests.ps1 -Detailed
```

### Run Specific Test Suite
```powershell
Invoke-Pester validate-json.Tests.ps1
Invoke-Pester validate-csv.Tests.ps1
Invoke-Pester j2c.Tests.ps1
```

### Run Specific Test
```powershell
Invoke-Pester validate-json.Tests.ps1 -TestName "Should validate simple flat JSON"
```

## Test Coverage

### validate-json.ps1
- ✅ Valid JSON files (9 scenarios)
- ✅ Invalid JSON files (4 scenarios)
- ✅ Empty key detection
- ✅ Output modes (normal, quiet)
- ✅ Statistics reporting

### validate-csv.ps1
- ✅ Valid CSV files (3 scenarios)
- ✅ Invalid CSV files (2 scenarios)
- ✅ Inconsistent column detection
- ✅ Custom delimiter support
- ✅ Output modes (normal, quiet)
- ✅ Statistics reporting

### j2c.ps1
- ✅ Basic conversion (3 scenarios)
- ✅ Nested object flattening (2 scenarios)
- ✅ Array handling strategies (2 scenarios)
- ✅ Schema discovery with varying schemas
- ✅ Null and empty value handling (2 scenarios)
- ✅ Special character escaping
- ✅ Custom delimiter support
- ✅ Error handling (4 scenarios)

**Total: 35+ test cases**

## Test Data Descriptions

| File | Purpose |
|------|---------|
| `simple-flat.json` | Basic JSON object with primitive types |
| `array-of-objects.json` | Multiple objects with consistent schema |
| `nested-objects.json` | Multi-level nested object structure |
| `with-arrays.json` | JSON with array properties |
| `varying-schema.json` | Objects with different properties (schema discovery) |
| `with-nulls.json` | Null value handling |
| `deep-nesting.json` | 5+ levels deep nesting (MaxDepth testing) |
| `empty-array.json` | Empty array handling |
| `special-characters.json` | Quotes, commas, newlines, unicode |
| `invalid-empty-key.json` | Empty property name (PowerShell limitation) |
| `malformed.json` | Syntax error in JSON |
| `valid-simple.csv` | Basic valid CSV |
| `csv-with-quotes.csv` | Quoted fields, embedded quotes |
| `csv-inconsistent.csv` | Rows with different column counts |

## Continuous Integration

Test results are written to `TestResults.xml` in NUnit format, compatible with most CI/CD systems.

```yaml
# Example GitHub Actions
- name: Run Tests
  run: pwsh -File tools/tests/Run-AllTests.ps1
```

## Adding New Tests

1. Add test data to `testdata/` directory
2. Add test cases to appropriate `.Tests.ps1` file
3. Follow the existing pattern:
   ```powershell
   It "Should do something specific" {
       $result = & $script:ScriptPath -Parameter "value"
       $LASTEXITCODE | Should -Be 0
       # Additional assertions
   }
   ```

## Troubleshooting

### "Pester module not found"
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

### Tests fail with "script not found"
Ensure you're running from the `tests/` directory or using the full path.

### Permission errors
Run PowerShell as administrator or adjust execution policy:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
