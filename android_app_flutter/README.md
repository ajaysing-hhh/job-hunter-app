# Flutter Android App (`android_app_flutter`)

This Flutter app displays resume-matched job alerts and handles push notifications.

## Features
- Fetches matched jobs from backend endpoint (`/matches`)
- Displays job title, company, location, and match score
- Registers Firebase Cloud Messaging (FCM) token with backend (`/register-device`)
- Shows notifications when backend sends new matching job alerts

## Setup
1. Install Flutter SDK.
2. Run `flutter pub get`.
3. Configure Firebase for Android and add `google-services.json` in `android/app/`.
4. Update backend URL in `lib/main.dart` if needed.
5. Run the app: `flutter run`.
