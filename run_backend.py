"""
Convenience script to run the backend with better error visibility.
"""

import sys
import logging
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent))

# Set up logging to console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

if __name__ == "__main__":
    import uvicorn
    
    print("\n" + "="*70)
    print("  FITNESS RECOMMENDATION SYSTEM - BACKEND SERVER")
    print("="*70)
    print("\nStarting server...")
    print("- API: http://localhost:8000")
    print("- Docs: http://localhost:8000/docs")
    print("- Health: http://localhost:8000/health")
    print("\nPress CTRL+C to stop\n")
    print("="*70 + "\n")
    
    try:
        uvicorn.run(
            "src.api.app:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
    except Exception as e:
        print(f"\n\nERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

