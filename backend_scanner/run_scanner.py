import time

import requests

SCAN_ENDPOINT = 'http://localhost:8000/scan'
INTERVAL_SECONDS = 900


if __name__ == '__main__':
    while True:
        try:
            response = requests.post(SCAN_ENDPOINT, timeout=30)
            print(response.status_code, response.text)
        except Exception as exc:
            print(f'scan failed: {exc}')
        time.sleep(INTERVAL_SECONDS)
