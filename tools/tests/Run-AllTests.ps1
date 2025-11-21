<#
.SYNOPSIS
    Run all test suites for the JSON/CSV tools.

.DESCRIPTION
    Executes all Pester tests and provides a summary report.
    Requires Pester module to be installed.

.PARAMETER Detailed
    Show detailed test output instead of summary.

.EXAMPLE
    .\Run-AllTests.ps1

.EXAMPLE
    .\Run-AllTests.ps1 -Detailed
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

# Check if Pester is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "ERROR: Pester module is not installed." -ForegroundColor Red
    Write-Host "Install it with: Install-Module -Name Pester -Force -SkipPublisherCheck" -ForegroundColor Yellow
    exit 1
}

Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  JSON/CSV Tools Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Configure Pester
$config = New-PesterConfiguration
$config.Run.Path = $PSScriptRoot
$config.Run.Exit = $false
$config.Output.Verbosity = if ($Detailed) { 'Detailed' } else { 'Normal' }
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\TestResults.xml"

# Run tests
$result = Invoke-Pester -Configuration $config

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $($result.TotalCount)" -ForegroundColor White
Write-Host "Passed:       $($result.PassedCount)" -ForegroundColor Green
Write-Host "Failed:       $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped:      $($result.SkippedCount)" -ForegroundColor Yellow
Write-Host "Duration:     $($result.Duration)" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

# Exit with appropriate code
exit $result.FailedCount
