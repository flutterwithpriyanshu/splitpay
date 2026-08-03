# SplitPay 💸

SplitPay is a modern Flutter expense-splitting app designed to help people track shared bills, manage friend balances, and settle payments without confusion. The app is centered around a clean dashboard experience and real-time data syncing through Firebase.

## 🌟 Project Summary

This project is a mobile-first money management application for:

- Splitting restaurant, travel, rent, and daily expenses
- Tracking who owes whom
- Linking friends using phone numbers and Firebase user lookup
- Monitoring personal wallet activity and monthly spending
- Keeping shared bill balances organized across multiple transactions

The application is built with Flutter and powered by Firebase Authentication and Cloud Firestore for storage and real-time updates.

## ✨ Core Features

- 🔐 User authentication with Firebase Email/Password login and sign-up
- 👥 Friend management with contact-based friend creation
- 📱 Phone-number lookup to connect with registered SplitPay users
- 🧾 Bill creation with title, amount, note, date, payer, and participants
- ⚖️ Flexible split options: equal split or custom split amounts
- 💰 Real-time balance calculations for what you owe and what you receive
- 🧩 Shared linked-bill support between connected users
- 📊 Wallet screen with expenditure history and monthly graph
- 🏠 Home dashboard with overview cards for balances and recent activity
- 🌗 Light and dark theme support with a polished Material design interface
- 🔄 Partial settlement tracking for unpaid balances
- 🧾 Transaction summaries and wallet balance tracking

## 🛠️ Tech Stack

- Flutter SDK
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Google Fonts
- fl_chart
- flutter_contacts
- url_launcher
- flex_color_scheme
- flutter_animate
- cupertino_icons

## 🧠 Architecture Overview

The app follows a simple service-oriented Flutter structure:

- Screens handle the UI flow for home, wallet, auth, add bill, and app shell
- Services interact with Firebase Firestore for friends, bills, and transactions
- Models define the shape of Friend, Bill, and related transaction data
- Theme files centralize styling and color configuration
- Firebase options are generated and stored in the Flutter app configuration

## 📁 Project Structure

```text
splitpay/
├── android/                # Android project configuration
├── ios/                    # iOS project configuration
├── lib/
│   ├── firebase/
│   │   └── firebase_options.dart
│   ├── model/
│   │   ├── bill.dart
│   │   ├── friend.dart
│   │   └── transaction.dart
│   ├── screens/
│   │   ├── add_bill_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── home_screen.dart
│   │   ├── main_shell.dart
│   │   ├── wallet_screen.dart
│   │   └── ...
│   ├── services/
│   │   ├── bill_service.dart
│   │   ├── friend_service.dart
│   │   └── transaction_service.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── theme.dart
│   ├── widgets/
│   ├── main.dart
│   └── ...
├── assets/                 # App icons and intro assets
├── test/                   # Unit/widget tests
├── pubspec.yaml            # Flutter package dependencies
├── firebase.json           # Firebase hosting configuration metadata
├── analysis_options.yaml
├── .gitignore
├── README.md
└── ...
```

## 🧩 Key Functional Flow

1. User signs up or logs in.
2. Firebase creates the authenticated account and stores profile details.
3. User adds friends by name and phone number.
4. Registered SplitPay users can be linked automatically via phone lookup.
5. User creates a bill with selected participants and payment details.
6. The app computes balances using equal or custom share logic.
7. Home dashboard summarizes who owes and who gets paid.
8. Wallet screen tracks all outbound and inbound transaction activity.
9. Partial settlement and shared-bill states are updated in Firestore.

## 🔥 Firebase Usage

This app uses Firebase for:

- Email/password authentication
- User profile storage
- Friend relationship storage
- Bill records and split logic
- Wallet and transaction tracking
- Real-time updates across screens

The generated configuration is already present in the project under:

- `lib/firebase/firebase_options.dart`
- Android `google-services.json`

## 🚀 Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed (`^3.12.2` in this project)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- An emulator or physical device
- Firebase project connected to the app

## ⚙️ Installation and Setup

Clone the repo:

```bash
git clone https://github.com/dhruvpalofficial/splitpay.git
cd splitpay
```

Install project dependencies:

```bash
flutter pub get
```

If you want to regenerate Firebase config:

```bash
flutterfire configure
```

Then run the app:

```bash
flutter run
```

## ▶️ Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
flutter build ios
```

## 🧪 Current Testing Status

The repository includes a widget test under `test/widget_test.dart` and can be used to validate the app structure and basic rendering. The project is configured for standard Flutter testing and linting.

## 📊 App Behavior Highlights

From the codebase, the app is designed around these user experiences:

- Home dashboard summarizing total balance
- Quick add bill flow with date selection and participant selection
- Contact permission support for friend entry
- Wallet analytics using monthly spending chart
- Theme-driven UI with a consistent financial app design
- Stream-based data refresh for live changes

## 🧩 Notable Code Areas

Some important implementation files include:

- `lib/main.dart` — app bootstrap and theme setup
- `lib/screens/home_screen.dart` — balance overview and activity feed
- `lib/screens/add_bill_screen.dart` — bill creation and split logic
- `lib/screens/wallet_screen.dart` — wallet summary and charting
- `lib/services/bill_service.dart` — bill CRUD and settlement logic
- `lib/services/friend_service.dart` — friend creation and linked-user lookup
- `lib/model/bill.dart` — bill split calculations and partial payment handling
- `lib/model/friend.dart` — friend profile model

## 📌 Notes

- The app is built around Indian Rupee formatting (`₹`) in the UI.
- Contact permission is used when adding a friend via device contacts.
- Friend linking only works for phone numbers already registered in the SplitPay system.
- The project appears to be in an active development stage with a polished UI and core financial logic already in place.

## 🚀 Future Ideas

Possible next improvements include:

- 🧾 better recurring bill support
- 📬 push notifications for balances and settlements
- 📈 advanced analytics and reporting
- 👤 profile editing and avatar updates
- 🤝 group expense rooms and shared dashboards
- 📦 export of transaction history

## 👨‍💻 Project Context

This repository is a Flutter-based personal finance and expense sharing app intended for managing day-to-day money with friends and family. It combines a modern dashboard UI, Firebase backend, and group finance logic into a single app experience.

## ✅ Summary

SplitPay is a practical expense-sharing application with a strong foundation in Flutter + Firebase. It covers the full essentials of a bill-splitting product: user auth, friend linking, split planning, settlements, wallet analytics, and a clean user interface.

If you are looking for a scalable, modern money-sharing app built with Flutter, this project is a strong starting point and a good base for extension.
