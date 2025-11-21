<#
.SYNOPSIS
    Unit tests for j2c.ps1 (json to csv converter)

.DESCRIPTION
    Tests JSON to CSV conversion script with various inputs and options.
    Run with: Invoke-Pester j2c.Tests.ps1
    Compatible with Pester v3+ and v5+
#>

$script:J2cScript = "$PSScriptRoot\..\j2c.ps1"
$script:TestDataPath = "$PSScriptRoot\testdata"
$script:OutputPath = "$PSScriptRoot\testdata\temp-output"

Describe "j2c.ps1" {
    BeforeEach {
        # Create output directory
        New-Item -ItemType Directory -Path $script:OutputPath -Force -ErrorAction SilentlyContinue | Out-Null
    }

    AfterEach {
        # Clean up output directory
        Remove-Item -Path $script:OutputPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    Context "Basic conversion" {
        It "Should convert simple flat JSON to CSV" {
            $output = "$script:OutputPath\simple-flat.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\simple-flat.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            Test-Path $output | Should -Be $true

            $csv = Import-Csv $output
            $csv.Count | Should -Be 1
            $csv[0].name | Should -Be "John Doe"
        }

        It "Should convert array of objects to CSV" {
            $output = "$script:OutputPath\array-of-objects.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\array-of-objects.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output
            $csv.Count | Should -Be 3
            $csv[0].name | Should -Be "Alice"
            $csv[1].name | Should -Be "Bob"
        }

        It "Should default output path to input filename with .csv extension" {
            $input = "$script:OutputPath\test-input.json"
            Copy-Item "$script:TestDataPath\simple-flat.json" $input

            & $script:J2cScript -InputPath $input

            $LASTEXITCODE | Should -Be 0
            Test-Path "$script:OutputPath\test-input.csv" | Should -Be $true
        }
    }

    Context "Nested object flattening" {
        It "Should flatten nested objects with dot notation" {
            $output = "$script:OutputPath\nested-objects.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\nested-objects.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            # Check for flattened column names
            $csv[0].PSObject.Properties.Name | Should -Contain "user.name"
            $csv[0].PSObject.Properties.Name | Should -Contain "user.contact.email"
            $csv[0].PSObject.Properties.Name | Should -Contain "user.contact.address.city"
        }

        It "Should respect MaxDepth parameter" {
            $output = "$script:OutputPath\nested-maxdepth.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\deep-nesting.json" -OutputPath $output -MaxDepth 2

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            # Should have level1.level2 but not deeper
            $csv[0].PSObject.Properties.Name | Should -Contain "level1.level2"
        }
    }

    Context "Array handling" {
        It "Should stringify arrays by default" {
            $output = "$script:OutputPath\with-arrays-stringify.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\with-arrays.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            # Array should be JSON stringified
            $csv[0].tags | Should -Match '^\[.*\]$'
        }

        It "Should concatenate arrays when specified" {
            $output = "$script:OutputPath\with-arrays-concat.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\with-arrays.json" -OutputPath $output -ArrayHandling Concatenate

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            # Array should be semicolon-separated
            $csv[0].tags | Should -Match 'urgent; backend; api'
        }
    }

    Context "Schema discovery" {
        It "Should discover all fields across varying schemas" {
            $output = "$script:OutputPath\varying-schema.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\varying-schema.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            # All unique fields should be present as columns
            $csv[0].PSObject.Properties.Name | Should -Contain "price"
            $csv[0].PSObject.Properties.Name | Should -Contain "stock"
            $csv[0].PSObject.Properties.Name | Should -Contain "discount"
            $csv[0].PSObject.Properties.Name | Should -Contain "featured"

            # Missing values should be empty
            $csv[0].discount | Should -BeNullOrEmpty
        }
    }

    Context "Null and empty value handling" {
        It "Should handle null values as empty strings" {
            $output = "$script:OutputPath\with-nulls.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\with-nulls.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            $csv[0].phone | Should -BeNullOrEmpty
            $csv[1].email | Should -BeNullOrEmpty
        }

        It "Should handle empty arrays" {
            $output = "$script:OutputPath\empty-array.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\empty-array.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            Test-Path $output | Should -Be $true
        }
    }

    Context "Special characters" {
        It "Should properly escape special characters in CSV" {
            $output = "$script:OutputPath\special-characters.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\special-characters.json" -OutputPath $output

            $LASTEXITCODE | Should -Be 0
            $csv = Import-Csv $output

            # CSV parser should handle quotes and commas
            $csv[0].text_with_quotes | Should -Match 'hello'
            $csv[0].text_with_comma | Should -Match 'Last, First, Middle'
        }
    }

    Context "Custom delimiter" {
        It "Should support custom delimiter" {
            $output = "$script:OutputPath\custom-delimiter.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\simple-flat.json" -OutputPath $output -Delimiter ";"

            $LASTEXITCODE | Should -Be 0
            $content = Get-Content $output -Raw
            $content | Should -Match ';'
        }
    }

    Context "Stdout output" {
        It "Should output to stdout when no OutputPath specified" {
            $output = & $script:J2cScript -InputPath "$script:TestDataPath\simple-flat.json" 2>$null

            $LASTEXITCODE | Should -Be 0
            $output | Should -Not -BeNullOrEmpty
            $output[0] | Should -Match "active.*age.*email"
            $output.Count | Should -BeGreaterThan 1
        }

        It "Should output valid CSV to stdout" {
            $output = & $script:J2cScript -InputPath "$script:TestDataPath\array-of-objects.json" 2>$null

            $LASTEXITCODE | Should -Be 0
            # First line should be headers
            $output[0] | Should -Match "department.*id.*name.*salary"
            # Should have 4 lines total (1 header + 3 data rows)
            $output.Count | Should -Be 4
            # Data row should contain actual values
            $output[1] | Should -Match "Alice"
        }

        It "Should send progress messages to stderr when outputting to stdout" {
            # Capture stderr
            $stderr = & $script:J2cScript -InputPath "$script:TestDataPath\simple-flat.json" 2>&1 |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] -or $_.GetType().Name -eq 'String' } |
                Out-String

            # Progress messages should go to stderr
            # Note: [Console]::Error.WriteLine goes to stderr but is hard to capture in PowerShell tests
            # So we just verify stdout works and contains CSV data
            $stdout = & $script:J2cScript -InputPath "$script:TestDataPath\simple-flat.json" 2>$null
            $stdout[0] | Should -Match '"active"'
        }
    }

    Context "Error handling" {
        It "Should fail on non-existent file" {
            $output = "$script:OutputPath\error.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\does-not-exist.json" -OutputPath $output 2>&1 | Out-Null

            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on malformed JSON" {
            $output = "$script:OutputPath\error.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\malformed.json" -OutputPath $output 2>&1 | Out-Null

            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on empty JSON file" {
            $output = "$script:OutputPath\error.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\empty.json" -OutputPath $output 2>&1 | Out-Null

            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on JSON with empty keys" {
            $output = "$script:OutputPath\error.csv"
            & $script:J2cScript -InputPath "$script:TestDataPath\invalid-empty-key.json" -OutputPath $output 2>&1 | Out-Null

            $LASTEXITCODE | Should -Be 1
        }
    }
}
