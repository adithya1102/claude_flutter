# Gusto Meets — Flutter App

## Project Overview
Airbnb-style marketplace for renting residential terraces by the hour. Android only.

## Tech Stack
- Flutter / Dart (Android only, minSdk 24)
- State: flutter_riverpod + hooks_riverpod (NO BLoC, NO GetX)
- Navigation: go_router
- Backend: Supabase (phone OTP + Google OAuth)
- Payments: razorpay_flutter
- Push: firebase_messaging
- Maps: google_maps_flutter

## Architecture
Clean Architecture: presentation / domain / data

```
lib/
├── core/         constants, env, errors, router, theme, utils
├── domain/       entities, enums, repository interfaces
├── data/         datasources (Supabase), repository implementations
└── presentation/ screens + providers, organized by feature
```

## Supabase Tables
users, terraces, terrace_permissions, bookings, reviews,
wallet_transactions, damage_reports, admin_users,
admin_audit_log, platform_config, host_payouts, promo_codes

## Color Palette
- Primary (Gusto Green): #10B981
- Secondary (Purple): #7C3AED
- Background: #F8F8FC
- Surface: #FFFFFF
- Text Primary: #111827
- Text Secondary: #6B7280

## Route Paths
- /                         → SplashScreen
- /auth                     → AuthScreen
- /auth/otp                 → OtpScreen (?phone=)
- /auth/setup               → ProfileSetupScreen
- /kyc                      → KycScreen
- /explore                  → ExploreScreen
- /explore/:id              → TerraceDetailScreen
- /explore/:id/book         → BookingSummaryScreen
- /bookings                 → BookingHistoryScreen
- /bookings/active/:bookingId → ActiveBookingScreen
- /wallet                   → WalletScreen
- /host                     → HostDashboardScreen

## Business Rules
- platformFeePercent: 15%
- overstayMultiplier: 2.0×
- bookingBufferMinutes: 30 (between bookings)
- paymentTimeoutMinutes: 15
- tMinus15AlertMinutes: 15
- maxExtensions: 3
- defaultCity: Chennai

## Key Enums (DB values)
BookingStatus: PENDING_PAYMENT | CONFIRMED | ACTIVE | EXTENDED | COMPLETED | OVERSTAYED | DISPUTED | CANCELLED
BookingPurpose: CHILLOUT | DINE_OUT | MOVIE_NIGHT | PARTY | BOARD_GAMES | STUDY_GROUP
UserRole: GUEST | HOST | ADMIN
VerificationStatus: UNVERIFIED | PENDING_INSPECTION | VERIFIED | SUSPENDED | REJECTED
AccessType: PRIVATE_STAIRCASE | SHARED_WALKTHROUGH

## Generated Files (run after code changes)
```
dart run build_runner build --delete-conflicting-outputs
```

## Setup Commands (after Flutter installed)
```
flutter create gusto_meets --org com.gustomeets --platforms android
# Then overlay the files from this repo
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --debug
```
