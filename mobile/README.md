# Restaurant Loyalty Mobile

Flutter client for the FastAPI restaurant loyalty backend.

## Run

Install Flutter SDK first, then from this folder:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Useful API base URLs:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator or desktop: `http://localhost:8000`
- Physical phone: `http://YOUR_COMPUTER_LAN_IP:8000`

## Screens

- Login
- Register
- Home

JWT is saved with `flutter_secure_storage`.
