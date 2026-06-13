# Grammar Assistant — Flutter Frontend

The desktop UI for Grammar Assistant, built with **Flutter** and **Material 3 Design**.

## Tech Stack

- **Flutter** 3.x (Windows Desktop)
- **Material 3** with custom dark/light theming
- **Google Fonts** (Inter)
- **flutter_animate** for smooth micro-animations
- **window_manager** for custom title bar and window controls

## Running in Development

```bash
# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows
```

> **Note:** The Python backend must be running on `http://127.0.0.1:11434` before launching the app. See the [root README](../README.md) for full setup instructions.

## Building for Release

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/grammar_assistant.exe`

## Project Structure

```
lib/
├── main.dart               # App entry point
├── app.dart                # MaterialApp + routing
├── models/
│   └── action_result.dart  # API response model
├── screens/
│   ├── home_screen.dart    # Main editor screen
│   └── settings_screen.dart# Theme & app settings
├── services/
│   ├── backend_launcher.dart  # Starts Python backend
│   └── backend_service.dart   # HTTP client for API
├── theme/
│   └── app_colors.dart     # Color palette (dark/light)
└── widgets/
    ├── action_button_row.dart # AI action buttons
    ├── input_editor.dart      # Text input area
    └── output_editor.dart     # Result display area
```

## Features

- 🎨 Premium dark and light themes
- ✨ Smooth animations and hover effects
- 📋 One-click copy to clipboard
- ⚡ Real-time backend health indicator
- 🪟 Custom window title bar
- 📱 Responsive layout
