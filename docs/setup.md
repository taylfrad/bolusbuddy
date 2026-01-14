# Setup Guide

## Flutter App

```bash
cd bolusbuddy_app
flutter pub get
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

Notes:
- On physical devices, replace `10.0.2.2` with your machine’s IP.
- iOS requires ARKit-capable devices for depth capture.
- Android requires ARCore-supported devices for depth capture.

## Backend (Local)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

Set USDA API key (optional but recommended):

```bash
export USDA_API_KEY="YOUR_KEY"  # Windows: setx USDA_API_KEY "YOUR_KEY"
```

## Cloud Run (Always-Free)

1. Build and push:
   ```bash
   gcloud builds submit --tag gcr.io/PROJECT_ID/bolusbuddy-api
   ```
2. Deploy with free-tier settings:
   ```bash
   gcloud run services replace cloudrun.yaml --region us-central1
   ```
3. Update `BACKEND_URL` in Flutter using `--dart-define`.

Free-tier safeguards:
- `minScale: 0` (scale-to-zero)
- `maxScale: 1` (limit concurrency and cost)
- No paid services or always-on instances
