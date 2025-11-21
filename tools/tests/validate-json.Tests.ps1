<#
.SYNOPSIS
    Unit tests for validate-json.ps1

.DESCRIPTION
    Tests JSON validation script with various valid and invalid inputs.
    Run with: Invoke-Pester validate-json.Tests.ps1
    Compatible with Pester v3+ and v5+
#>

$script:ValidateJsonScript = "$PSScriptRoot\..\validate-json.ps1"
$script:TestDataPath = "$PSScriptRoot\testdata"

Describe "validate-json.ps1" {
    Context "Valid JSON files" {
        It "Should validate simple flat JSON" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\simple-flat.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate array of objects" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\array-of-objects.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate nested objects" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\nested-objects.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate JSON with arrays" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\with-arrays.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate JSON with varying schema" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\varying-schema.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate JSON with null values" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\with-nulls.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate deeply nested JSON" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\deep-nesting.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate JSON with empty arrays" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\empty-array.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }

        It "Should validate JSON with special characters" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\special-characters.json" -Quiet
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context "Invalid JSON files" {
        It "Should fail on malformed JSON" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\malformed.json" -Quiet 2>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on empty JSON file" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\empty.json" -Quiet 2>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on non-existent file" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\does-not-exist.json" -Quiet 2>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Should fail on JSON with empty keys (PowerShell limitation)" {
            $result = & $script:ValidateJsonScript -Path "$script:TestDataPath\invalid-empty-key.json" -Quiet 2>&1
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context "Empty key detection" {
        It "Should warn about empty keys when -CheckEmptyKeys is used" {
            $output = & $script:ValidateJsonScript -Path "$script:TestDataPath\invalid-empty-key.json" -CheckEmptyKeys 2>&1 | Out-String
            $output | Should -Match "WARNING.*empty string"
        }
    }

    Context "Output modes" {
        It "Should produce output in normal mode" {
            $output = & $script:ValidateJsonScript -Path "$script:TestDataPath\simple-flat.json" 2>&1 | Out-String
            $output | Should -Match "SUCCESS"
        }

        It "Should suppress output in quiet mode" {
            $output = & $script:ValidateJsonScript -Path "$script:TestDataPath\simple-flat.json" -Quiet 2>&1 | Out-String
            $output | Should -BeNullOrEmpty
        }
    }

    Context "Statistics reporting" {
        It "Should report object type and properties" {
            $output = & $script:ValidateJsonScript -Path "$script:TestDataPath\simple-flat.json" 2>&1 | Out-String
            $output | Should -Match "Type:"
            $output | Should -Match "Properties:"
        }

        It "Should report array type and item count" {
            $output = & $script:ValidateJsonScript -Path "$script:TestDataPath\array-of-objects.json" 2>&1 | Out-String
            $output | Should -Match "Type: Array"
            $output | Should -Match "Items:"
        }
    }
}
