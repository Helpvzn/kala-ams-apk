# Kala A.M.S — Complete Setup & Deployment Guide
## Attendance Management System | Flutter + Google Apps Script

---

## 📁 Project Structure

```
Kala A.M.S/
├── backend/
│   └── Code.gs              ← Google Apps Script backend
├── lib/
│   ├── config/app_config.dart   ← API URL config (update this!)
│   ├── models/
│   │   ├── employee.dart
│   │   └── attendance.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── session_service.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── employee/
│   │   │   ├── employee_dashboard.dart
│   │   │   ├── camera_screen.dart
│   │   │   └── history_screen.dart
│   │   └── admin/
│   │       ├── admin_dashboard.dart
│   │       ├── employee_management.dart
│   │       ├── add_edit_employee.dart
│   │       └── attendance_report.dart
│   └── main.dart
├── android/app/src/main/AndroidManifest.xml
├── ios/Runner/Info.plist
└── pubspec.yaml
```

---

## 🚀 STEP 1 — Install Flutter on Windows

1. Go to: **https://flutter.dev/docs/get-started/install/windows**
2. Click **"Download Flutter SDK"** (stable version, ~600MB zip)
3. Extract the zip to: `C:\flutter` (avoid paths with spaces)
4. Add Flutter to PATH:
   - Open **System Properties** → **Environment Variables**
   - In "User variables" → select **Path** → click **Edit**
   - Click **New** → type `C:\flutter\bin` → click OK
5. Open a **new PowerShell** and run:
   ```
   flutter doctor
   ```
6. If it says "Flutter is ready!" — ✅ Done!
7. Install Android Studio: **https://developer.android.com/studio**
   - During install: check "Android SDK", "Android Virtual Device"
8. Run `flutter doctor --android-licenses` and press `y` to accept all licenses

---

## 🗄️ STEP 2 — Create Google Sheet (Database)

1. Go to **https://sheets.google.com** and create a **New Spreadsheet**
2. Name it: `Kala AMS Database`
3. Create 3 sheets (tabs at the bottom):

### Sheet 1: `Employee_Master`
Add these headers in Row 1:
```
EmpID | Name | Mobile | Department | Designation | Password | Status | CreatedAt
```
Add a test employee in Row 2:
```
EMP001 | Rahul Sharma | 9876543210 | Sales | Executive | pass123 | active | (today's date)
```

### Sheet 2: `Attendance`
Add these headers in Row 1:
```
AttendanceID | EmpID | Name | Date | CheckInTime | CheckOutTime | WorkingHours | CheckInPhotoURL | CheckOutPhotoURL | Status | UpdatedAt
```

### Sheet 3: `Admin`
Add these headers in Row 1:
```
Username | Password | Role | Status
```
Add admin in Row 2:
```
admin | Admin@123 | superadmin | active
```

4. **Copy the Google Sheet ID** from the URL:
   - URL looks like: `https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID_HERE/edit`
   - Copy the part between `/d/` and `/edit`

---

## ⚙️ STEP 3 — Set Up Google Apps Script

1. In your Google Sheet, click **Extensions** → **Apps Script**
2. Delete all existing code in the editor
3. Open the file: `backend/Code.gs` (from this project)
4. **Copy all the code** and paste it into the Apps Script editor
5. **Update line 9** — paste your Google Sheet ID:
   ```javascript
   const SHEET_ID = 'YOUR_ACTUAL_SHEET_ID_HERE';
   ```
6. Click **Save** (💾 icon)
7. Run the setup function:
   - In the function dropdown, select `setupSheets`
   - Click **▶ Run**
   - Grant permissions when asked (this creates sheet structure automatically)

---

## 🌐 STEP 4 — Deploy as Web App API

1. In Apps Script editor, click **Deploy** → **New Deployment**
2. Click the ⚙️ gear icon next to "Type" → select **Web App**
3. Settings:
   - **Description**: `Kala AMS API v1`
   - **Execute as**: `Me`
   - **Who has access**: `Anyone`
4. Click **Deploy**
5. **Copy the Web App URL** (looks like):
   ```
   https://script.google.com/macros/s/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/exec
   ```
   ⚠️ Save this URL — you'll need it next!

---

## 🔗 STEP 5 — Connect Flutter App to Backend

1. Open the file: `lib/config/app_config.dart`
2. Paste your Web App URL:
   ```dart
   static const String apiUrl = 'https://script.google.com/macros/s/YOUR_ACTUAL_URL/exec';
   ```
3. Save the file.

---

## 📱 STEP 6 — Run the Flutter App on Android

### Option A: Physical Android Phone (Recommended)
1. On your phone: **Settings** → **About Phone** → tap **Build Number** 7 times
2. Go back → **Developer Options** → enable **USB Debugging**
3. Connect phone to PC via USB
4. In PowerShell, go to project folder:
   ```
   cd "C:\Users\ADMIN\Desktop\Kala A.M.S"
   ```
5. Run:
   ```
   flutter pub get
   flutter run
   ```
6. The app will install and open on your phone! ✅

### Option B: Android Emulator
1. Open **Android Studio** → open **Device Manager**
2. Create a virtual device (Pixel 6, API 33+)
3. Start the emulator
4. Run `flutter run` from the project folder

---

## 🍎 STEP 7 (Optional) — Run on iOS

> ⚠️ iOS requires a Mac computer with Xcode installed.
> If you don't have a Mac, skip this step and use Android.

1. On Mac, install Xcode from App Store
2. Open Terminal: `cd /path/to/KalaAMS && flutter pub get`
3. Run: `open ios/Runner.xcworkspace` in Xcode
4. Set your Apple ID in Signing & Capabilities
5. Connect iPhone and run the app

---

## 🔑 Default Login Credentials

| Type | Username / ID | Password |
|------|--------------|----------|
| Admin | admin | Admin@123 |
| Employee | EMP001 | pass123 |

> **Change these immediately after first login!**

---

## 🔄 STEP 8 — Update Apps Script (If Needed)

If you modify `Code.gs`:
1. Go back to Apps Script
2. Click **Deploy** → **Manage Deployments**
3. Click the ✏️ edit icon on your existing deployment
4. Change version to **New version**
5. Click **Deploy**

---

## 🐛 Troubleshooting

| Problem | Fix |
|---------|-----|
| "Connection failed" in app | Make sure Web App URL is correctly pasted in app_config.dart |
| Camera not opening | Check camera permissions in phone settings |
| Login fails | Verify employee ID & password match what's in the Google Sheet |
| "Unauthorized" error | Make sure SECRET_KEY in Code.gs matches the one in app_config.dart (both: `KALA_AMS_2026`) |
| Check-in not recording | Verify Google Sheet ID is correct in Code.gs |

---

## 📧 Support
This is a free, self-hosted system. All your data stays in your own Google account.
