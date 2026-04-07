# 💰 MyFinance Tracker — Flutter Personal Finance App

A **100% offline**, production-ready Android personal finance tracker built with Flutter.
No login • No cloud • No ads • All data stays on your device.

---

## 📱 Features

| Category | Features |
|---|---|
| Transactions | Add/Edit/Delete income & expenses, Receipt photos, Recurring transactions |
| Categories | 21 defaults + create custom (color + emoji) |
| Dashboard | Balance hero card, monthly progress, mini pie chart, recent list |
| Budget | Overall monthly + per-category budgets with color alerts |
| Reports | Bar chart, pie chart, daily line graph, 6-month comparison |
| Calendar | Color-coded transaction view per day |
| Search | Live full-text search across all transactions |
| Savings Goals | Target + contributions + estimated ETA |
| Debt Tracker | I Owe / Owed to Me + settle + due date reminders |
| AI Tips | 50/30/20 analysis, financial health score (0–100), rule-based tips |
| Security | Biometric / PIN app lock |
| Data | JSON backup export/restore, SQLite local storage |
| Settings | Currency, Theme (Light/Dark/AMOLED), week start, month start day |
| Onboarding | 3-screen flow (skip-able) |

---

## 🏗️ Tech Stack

| Layer | Package |
|---|---|
| Framework | Flutter 3.x (Dart 3.x) |
| Database | `sqflite` + `path` |
| State Management | `provider` |
| Charts | `fl_chart` |
| Calendar | `table_calendar` |
| Notifications | `flutter_local_notifications` |
| Biometrics | `local_auth` |
| PDF Export | `pdf` + `printing` |
| Settings | `shared_preferences` |
| Camera/Gallery | `image_picker` |
| File I/O | `path_provider`, `file_picker` |
| UI | Material Design 3 |

---

## 🗄️ SQLite Database Schema

```sql
-- Transactions
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  amount REAL NOT NULL,
  type TEXT NOT NULL,              -- 'income' | 'expense'
  category_id TEXT NOT NULL,
  date TEXT NOT NULL,              -- 'yyyy-MM-dd'
  note TEXT,
  payment_mode TEXT DEFAULT 'Cash', -- Cash|UPI|Card|Bank Transfer|Other
  is_recurring INTEGER DEFAULT 0,
  recurrence_type TEXT,            -- Daily|Weekly|Monthly
  receipt_image TEXT,              -- local file path
  created_at TEXT NOT NULL
);

-- Categories
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,              -- 'income' | 'expense'
  color INTEGER NOT NULL,          -- ARGB int
  emoji TEXT NOT NULL,
  is_default INTEGER DEFAULT 0,
  is_deleted INTEGER DEFAULT 0
);

-- Budgets
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  category_id TEXT,                -- NULL = overall monthly budget
  amount REAL NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL
);

-- Savings Goals
CREATE TABLE savings_goals (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  target_amount REAL NOT NULL,
  saved_amount REAL DEFAULT 0,
  deadline TEXT,
  created_at TEXT NOT NULL,
  is_completed INTEGER DEFAULT 0
);

-- Debts
CREATE TABLE debts (
  id TEXT PRIMARY KEY,
  person_name TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,              -- 'owe' | 'owed'
  note TEXT,
  due_date TEXT,
  is_settled INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);
```

---

## 🚀 Build Instructions (Step by Step)

### Prerequisites

```bash
# 1. Install Flutter SDK (if not already installed)
# Download from https://flutter.dev/docs/get-started/install

# 2. Verify Flutter is installed
flutter doctor

# 3. Accept Android licenses
flutter doctor --android-licenses

# 4. Ensure you have Android SDK installed (via Android Studio or sdkmanager)
#    Minimum SDK: 21 (Android 5.0)
#    Target SDK:  34 (Android 14)
```

---

### Step 1 — Clone / Extract the Project

```bash
# If you received a ZIP:
unzip myfinance_tracker.zip
cd myfinance_tracker

# Or if using git:
git clone <repo-url>
cd myfinance_tracker
```

---

### Step 2 — Install Dependencies

```bash
flutter pub get
```

---

### Step 3 — Verify the Project Structure

```
myfinance_tracker/
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── res/
│   │           ├── values/styles.xml
│   │           └── xml/file_paths.xml
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── assets/images/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── database/database_helper.dart
│   │   └── theme/app_theme.dart
│   ├── models/
│   │   ├── transaction_model.dart
│   │   └── models.dart
│   ├── providers/
│   │   ├── settings_provider.dart
│   │   ├── transaction_provider.dart
│   │   ├── category_provider.dart
│   │   └── budget_savings_debt_providers.dart
│   ├── screens/
│   │   ├── onboarding/onboarding_screen.dart
│   │   ├── main/main_screen.dart
│   │   ├── dashboard/dashboard_screen.dart
│   │   ├── transactions/
│   │   │   ├── transactions_screen.dart
│   │   │   └── add_transaction_screen.dart
│   │   ├── reports/reports_screen.dart
│   │   ├── budget/budget_screen.dart
│   │   ├── more/more_screen.dart
│   │   ├── savings/savings_screen.dart
│   │   ├── debts/debts_screen.dart
│   │   ├── ai_tips/ai_tips_screen.dart
│   │   ├── calendar/calendar_view_screen.dart
│   │   ├── search/search_screen.dart
│   │   ├── categories/categories_screen.dart
│   │   └── settings/settings_screen.dart
│   └── widgets/
│       ├── transaction_card.dart
│       └── summary_widgets.dart
└── pubspec.yaml
```

---

### Step 4 — Add Gradle Wrapper (if missing)

If you don't have the `gradle/wrapper/` directory (happens when creating fresh):

```bash
cd android
gradle wrapper --gradle-version=8.0
cd ..
```

Or copy the wrapper from another Flutter project. The standard Flutter wrapper files are:
- `android/gradle/wrapper/gradle-wrapper.jar`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/gradlew`
- `android/gradlew.bat`

**Quick fix — create wrapper properties manually:**

```bash
mkdir -p android/gradle/wrapper
cat > android/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
EOF
```

---

### Step 5 — Build the Release APK

```bash
# Option A: Standard APK (works on all devices)
flutter build apk --release

# Option B: Split APKs by ABI (smaller per-device download)
flutter build apk --release --split-per-abi

# Option C: Fat APK (all ABIs in one file — largest but most compatible)
flutter build apk --release --no-shrink
```

---

### Step 6 — Find Your APK

```bash
# Standard APK location:
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Split APKs location:
ls -lh build/app/outputs/flutter-apk/
# → app-armeabi-v7a-release.apk   (32-bit ARM — older phones)
# → app-arm64-v8a-release.apk     (64-bit ARM — most modern phones ✅)
# → app-x86_64-release.apk        (64-bit x86 — emulators)
```

**Recommended for physical Android phones:** `app-arm64-v8a-release.apk`

---

### Step 7 — Install on Device

```bash
# Via ADB (USB debugging enabled):
adb install build/app/outputs/flutter-apk/app-release.apk

# Or copy the APK to your phone and open it with a file manager.
# Enable "Install from Unknown Sources" in Settings > Security.
```

---

## 🔧 Troubleshooting

### `sdk.dir` not set
```bash
# Create android/local.properties:
echo "sdk.dir=$ANDROID_SDK_ROOT" >> android/local.properties
echo "flutter.sdk=$(which flutter | xargs dirname | xargs dirname)" >> android/local.properties
```

### Gradle build fails with Java version
```bash
# Ensure you use JDK 17:
java -version   # Should show 17.x
# Install with: sudo apt install openjdk-17-jdk  (Linux)
#               brew install openjdk@17            (macOS)
```

### `flutter doctor` shows issues
```bash
flutter doctor -v   # Verbose output
flutter clean       # Clean build cache
flutter pub get     # Re-fetch packages
```

### Multidex error on old Android
Already handled — `multiDexEnabled true` is set in `build.gradle`.

### local_auth not working in emulator
Biometrics require a physical device with fingerprint sensor, or
an emulator with fingerprint configured in Extended Controls → Fingerprint.

---

## 🧹 Clean Build (if something goes wrong)

```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter build apk --release
```

---

## 📦 Release Signing (for Play Store)

```bash
# 1. Generate a keystore:
keytool -genkey -v -keystore ~/myfinance_keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias myfinance

# 2. Create android/key.properties:
cat > android/key.properties << 'EOF'
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=myfinance
storeFile=/home/YOUR_USER/myfinance_keystore.jks
EOF

# 3. Update android/app/build.gradle — add before android {}:
#    def keyProperties = new Properties()
#    def keyPropertiesFile = rootProject.file('key.properties')
#    keyProperties.load(new FileInputStream(keyPropertiesFile))
#    ... (add signingConfigs block)

# 4. Build signed APK:
flutter build apk --release
```

---

## 🏃 Run in Debug Mode (for development)

```bash
# Connect a device or start an emulator first
flutter devices          # List available devices
flutter run              # Run in debug mode
flutter run --profile    # Run in profile mode (performance testing)
```

---

## ⚙️ Customization

| What | Where |
|---|---|
| App name | `android/app/src/main/AndroidManifest.xml` → `android:label` |
| Package ID | `android/app/build.gradle` → `applicationId` |
| Default currency | `lib/core/constants/app_constants.dart` |
| Color theme | `lib/core/constants/app_constants.dart` → `primarySeed` |
| Default categories | `lib/core/constants/app_constants.dart` |
| App icon | Replace `android/app/src/main/res/mipmap-*/ic_launcher.png` |

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

*Built with ❤️ using Flutter | Material Design 3 | SQLite | 100% Offline*
