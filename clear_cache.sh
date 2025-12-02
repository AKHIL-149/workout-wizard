#!/bin/bash
# Clear Python cache to ensure changes take effect

echo "Clearing Python cache..."

# Remove __pycache__ directories
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
echo "[OK] Removed __pycache__ directories"

# Remove .pyc files
find . -type f -name "*.pyc" -delete 2>/dev/null
echo "[OK] Removed .pyc files"

# Remove .pyo files
find . -type f -name "*.pyo" -delete 2>/dev/null
echo "[OK] Removed .pyo files"

echo ""
echo "Cache cleared successfully!"
echo ""
echo "Now restart the backend:"
echo "  python run_backend.py"

