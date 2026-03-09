from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import requests
from bs4 import BeautifulSoup
from fastapi import FastAPI
from pydantic import BaseModel

from resume_matching_system.matcher import ResumeMatcher

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
except Exception:  # firebase is optional for local development
    firebase_admin = None
    credentials = None
    messaging = None

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / 'data'
DATA_DIR.mkdir(exist_ok=True)
MATCHES_FILE = DATA_DIR / 'matches.json'
DEVICES_FILE = DATA_DIR / 'devices.json'
RESUME_FILE = BASE_DIR / 'resume.txt'

LINKEDIN_JOBS_URL = os.getenv('LINKEDIN_JOBS_URL', 'https://www.linkedin.com/jobs/search?keywords=software%20engineer')
MATCH_THRESHOLD = float(os.getenv('MATCH_THRESHOLD', '0.30'))

app = FastAPI(title='LinkedIn Job Scanner API')


class DeviceRegistration(BaseModel):
    token: str


def _load_resume() -> str:
    if RESUME_FILE.exists():
        return RESUME_FILE.read_text(encoding='utf-8')
    return 'Python, Flutter, Android, backend development, machine learning, APIs'


def _load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding='utf-8'))


def _save_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, indent=2), encoding='utf-8')


def scrape_linkedin_jobs() -> list[dict]:
    """
    Scrapes publicly accessible job snippets.
    If scraping fails (auth/rate limits), returns seed data for development.
    """
    try:
        response = requests.get(LINKEDIN_JOBS_URL, timeout=12)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        cards = soup.select('.base-search-card')

        jobs = []
        for idx, card in enumerate(cards):
            title = card.select_one('.base-search-card__title')
            company = card.select_one('.base-search-card__subtitle')
            location = card.select_one('.job-search-card__location')
            link = card.select_one('a.base-card__full-link')
            desc = f"{title.get_text(' ', strip=True) if title else ''} at {company.get_text(' ', strip=True) if company else ''}"

            jobs.append(
                {
                    'id': f'linkedin-{idx}',
                    'title': title.get_text(' ', strip=True) if title else 'Unknown role',
                    'company': company.get_text(' ', strip=True) if company else 'Unknown company',
                    'location': location.get_text(' ', strip=True) if location else 'Unknown location',
                    'description': desc,
                    'url': link['href'] if link and link.has_attr('href') else LINKEDIN_JOBS_URL,
                }
            )

        if jobs:
            return jobs
    except Exception:
        pass

    return [
        {
            'id': 'fallback-1',
            'title': 'Flutter Android Developer',
            'company': 'SampleTech',
            'location': 'Remote',
            'description': 'Build Flutter apps, integrate APIs, and optimize Android performance.',
            'url': LINKEDIN_JOBS_URL,
        },
        {
            'id': 'fallback-2',
            'title': 'Backend Python Engineer',
            'company': 'DataWorks',
            'location': 'New York, NY',
            'description': 'Develop FastAPI services, data pipelines, and ML-based ranking systems.',
            'url': LINKEDIN_JOBS_URL,
        },
    ]


def generate_matches() -> list[dict]:
    resume_text = _load_resume()
    matcher = ResumeMatcher(resume_text)
    jobs = scrape_linkedin_jobs()
    ranked = matcher.rank_jobs(jobs)
    filtered = [job for job in ranked if job['match_score'] >= MATCH_THRESHOLD]
    _save_json(MATCHES_FILE, filtered)
    return filtered


def _initialize_firebase() -> bool:
    if firebase_admin is None:
        return False

    if firebase_admin._apps:
        return True

    service_account_file = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    if not service_account_file or not Path(service_account_file).exists():
        return False

    cred = credentials.Certificate(service_account_file)
    firebase_admin.initialize_app(cred)
    return True


def notify_devices(new_matches: list[dict]) -> None:
    if not new_matches or not _initialize_firebase():
        return

    devices = _load_json(DEVICES_FILE, [])
    if not devices:
        return

    top = new_matches[0]
    payload = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='New LinkedIn job match',
            body=f"{top['title']} • {top['company']} ({int(top['match_score'] * 100)}%)",
        ),
        tokens=devices,
        data={
            'job_id': top['id'],
            'job_url': top['url'],
        },
    )
    messaging.send_each_for_multicast(payload)


@app.get('/matches')
def get_matches() -> list[dict]:
    if not MATCHES_FILE.exists():
        return generate_matches()
    return _load_json(MATCHES_FILE, [])


@app.post('/scan')
def scan_jobs() -> dict:
    previous = {m['id'] for m in _load_json(MATCHES_FILE, [])}
    current = generate_matches()
    new_matches = [job for job in current if job['id'] not in previous]
    notify_devices(new_matches)
    return {'total_matches': len(current), 'new_matches': len(new_matches)}


@app.post('/register-device')
def register_device(registration: DeviceRegistration) -> dict:
    devices = _load_json(DEVICES_FILE, [])
    if registration.token not in devices:
        devices.append(registration.token)
        _save_json(DEVICES_FILE, devices)
    return {'registered_devices': len(devices)}
