# Billdora - Professional Invoicing App

A Flutter-based invoicing and business management app built with Clerk authentication and Supabase backend.

## Tech Stack

- **Frontend:** Flutter 3.x (iOS, Android, Web)
- **Authentication:** Clerk
- **Backend:** Supabase (PostgreSQL)
- **Payments:** Stripe
- **State Management:** Provider + Riverpod

## Getting Started

### Prerequisites

1. Flutter SDK (3.0+)
2. Xcode (for iOS)
3. Android Studio (for Android)
4. CocoaPods (for iOS dependencies)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/BarisRahimi123/Billdora.git
cd Billdora/billdora_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. For iOS, install CocoaPods dependencies:
```bash
cd ios && pod install && cd ..
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/          # Environment configuration
├── models/          # Data models
├── providers/       # State management
├── router/          # Navigation (go_router)
├── screens/         # UI screens
│   ├── auth/        # Login, Signup, Forgot Password
│   ├── dashboard/   # Main dashboard
│   ├── invoices/    # Invoice CRUD
│   ├── clients/     # Client management
│   ├── projects/    # Project tracking
│   ├── expenses/    # Expense tracking
│   ├── receipts/    # Receipt scanning
│   ├── reports/     # Analytics & reports
│   ├── settings/    # App settings
│   └── shell/       # Bottom navigation shell
├── services/        # API services
│   ├── auth_service.dart      # Clerk authentication
│   └── supabase_service.dart  # Supabase database
└── widgets/         # Reusable widgets
```

## Features

- [x] User authentication (Clerk)
- [x] Dashboard with stats
- [x] Invoice creation & management
- [x] Client management
- [x] Project tracking
- [x] Expense tracking
- [x] Receipt scanning
- [x] Reports & analytics
- [x] Settings & preferences
- [ ] Push notifications
- [ ] Offline support
- [ ] PDF export
- [ ] Stripe payments

## Environment Configuration

Update `lib/config/env.dart` with your credentials:

```dart
class Env {
  static const String clerkPublishableKey = 'your_clerk_key';
  static const String supabaseUrl = 'your_supabase_url';
  static const String supabaseAnonKey = 'your_supabase_key';
}
```

## Building for Production

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
```

### Web
```bash
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

Proprietary - All rights reserved
