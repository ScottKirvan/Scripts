<#
.SYNOPSIS
    Unit tests for validate-csv.ps1

.DESCRIPTION
    Tests CSV validation script with various valid and invalid inputs.
    Run with: Invoke-Pester validate-csv.Tests.ps1
    Compatible with Pester v3+ and v5+
#>

$script:ValidateCsvScript = "$PSScriptRoot\..\validate-csv.ps1"
$script:TestDataPath = "$PSScriptRoot\testdata"

Describe "validate-csv.ps1" {
    Context "Valid CSV files" {
        It "Should validate simple CSV" {
            $result = & $script:ValidateCsvScript -Path "$script:TestDataPath\valid-simple.csv" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate CSV with quotes and special characters" {
            $result = & $script:ValidateCsvScript -Path "$script:TestDataPath\csv-with-quotes.csv" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate generated CSV from json2csv" {
            $result = & $script:ValidateCsvScript -Path "$script:TestDataPath\test-fixed.csv" -Quiet
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context "Invalid CSV files" {
        It "Should fail on empty CSV file" {
            $result = & $script:ValidateCsvScript -Path "$script:TestDataPath\empty.csv" -Quiet 2>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on non-existent file" {
            $result = & $script:ValidateCsvScript -Path "$script:TestDataPath\does-not-exist.csv" -Quiet 2>&1
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context "Inconsistent column detection" {
        It "Should warn about inconsistent column counts" {
            $output = & $script:ValidateCsvScript -Path "$script:TestDataPath\csv-inconsistent.csv" 2>&1 | Out-String
            $output | Should -Match "WARNING.*Inconsistent"
        }
    }

    Context "Delimiter support" {
        It "Should accept custom delimiter parameter" {
            # Create a TSV test file
            $tsvPath = "$script:TestDataPath\temp-test.tsv"
            "col1`tcol2`tcol3`nval1`tval2`tval3" | Out-File -FilePath $tsvPath -Encoding UTF8

            $result = & $script:ValidateCsvScript -Path $tsvPath -Delimiter "`t" -Quiet
            $LASTEXITCODE | Should -Be 0

            Remove-Item $tsvPath -ErrorAction SilentlyContinue
        }
    }

    Context "Output modes" {
        It "Should produce output in normal mode" {
            $output = & $script:ValidateCsvScript -Path "$script:TestDataPath\valid-simple.csv" 2>&1 | Out-String
            $output | Should -Match "SUCCESS"
        }

        It "Should suppress output in quiet mode" {
            $output = & $script:ValidateCsvScript -Path "$script:TestDataPath\valid-simple.csv" -Quiet 2>&1 | Out-String
            $output | Should -BeNullOrEmpty
        }
    }

    Context "Statistics reporting" {
        It "Should report row and column counts" {
            $output = & $script:ValidateCsvScript -Path "$script:TestDataPath\valid-simple.csv" 2>&1 | Out-String
            $output | Should -Match "Rows:"
            $output | Should -Match "Columns:"
        }

        It "Should report headers" {
            $output = & $script:ValidateCsvScript -Path "$script:TestDataPath\valid-simple.csv" 2>&1 | Out-String
            $output | Should -Match "Headers:"
        }

        It "Should report delimiter type" {
            $output = & $script:ValidateCsvScript -Path "$script:TestDataPath\valid-simple.csv" 2>&1 | Out-String
            $output | Should -Match "Delimiter: comma"
        }
    }
}
