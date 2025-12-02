# Clear Python cache to ensure changes take effect

Write-Host "Clearing Python cache..." -ForegroundColor Yellow

# Remove __pycache__ directories
Get-ChildItem -Path . -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force
Write-Host "[OK] Removed __pycache__ directories" -ForegroundColor Green

# Remove .pyc files
Get-ChildItem -Path . -Recurse -File -Filter "*.pyc" | Remove-Item -Force
Write-Host "[OK] Removed .pyc files" -ForegroundColor Green

# Remove .pyo files
Get-ChildItem -Path . -Recurse -File -Filter "*.pyo" | Remove-Item -Force
Write-Host "[OK] Removed .pyo files" -ForegroundColor Green

Write-Host "`nCache cleared successfully!" -ForegroundColor Green
Write-Host "`nNow restart the backend:" -ForegroundColor Cyan
Write-Host "  python run_backend.py" -ForegroundColor White

