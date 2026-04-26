# ============================================================
# scripts/clean.ps1  -  Wipe build/sim artifacts.
#   powershell -ExecutionPolicy Bypass -File scripts/clean.ps1
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "[clean] Removing ModelSim work library..."
Remove-Item -Recurse -Force "work"          | Out-Null
Remove-Item -Force          "transcript"    | Out-Null
Remove-Item -Force          "vsim.wlf"      | Out-Null
Remove-Item -Force          "modelsim.ini"  | Out-Null
Remove-Item -Force          "waveform.vcd"  | Out-Null

Write-Host "[clean] Removing reports..."
if (Test-Path "reports") {
    Get-ChildItem "reports" -Exclude ".gitkeep" -Recurse |
        Remove-Item -Recurse -Force
}

Write-Host "[clean] Removing __pycache__ ..."
Get-ChildItem -Recurse -Filter "__pycache__" -Directory |
    Remove-Item -Recurse -Force

Write-Host "[clean] Done."