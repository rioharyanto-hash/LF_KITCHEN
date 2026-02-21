---
description: Build and deploy the application to Firebase Hosting
---

This workflow will build the Flutter web application and deploy it to Firebase Hosting.

### Prerequisites
1. Firebase CLI installed (`npm install -g firebase-tools`)
2. Logged into Firebase (`firebase login`)
3. Access to the project `lfkitchen-app-5070f`

### Steps

1. Clean the project and get dependencies
```bash
flutter clean
flutter pub get
```

2. Build the Flutter Web application in release mode
// turbo
```bash
flutter build web --release
```

3. Deploy to Firebase Hosting
// turbo
```bash
firebase deploy --only hosting
```
