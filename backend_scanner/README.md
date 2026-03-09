# Backend Scanner (`backend_scanner`)

FastAPI service that scans LinkedIn jobs, scores matches against a resume, and notifies devices.

## Endpoints
- `GET /matches` – Returns latest matched jobs
- `POST /scan` – Runs scanner + matching and pushes notifications for new jobs
- `POST /register-device` – Stores FCM device tokens

## Run
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn scanner_service:app --host 0.0.0.0 --port 8000
```

## Notes
- Set `GOOGLE_APPLICATION_CREDENTIALS` for FCM push notifications.
- LinkedIn HTML changes often; scanner includes fallback job data for local development.
