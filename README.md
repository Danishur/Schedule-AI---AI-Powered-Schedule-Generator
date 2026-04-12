# Schedule AI — Flutter App

An AI-powered schedule generator app built with Flutter and Anthropic's Claude API.

## Features

- **AI Schedule Generation** — Claude optimizes your task order based on priority, deadlines, and working hours
- **Task Management** — Add, edit, delete, and reorder tasks with swipe gestures
- **Priority System** — High / Medium / Low priority with color-coded UI
- **Working Hours Config** — Set your start/end time and break preferences
- **Schedule History** — Browse previously generated schedules
- **Local Storage** — All data persisted on-device via SharedPreferences
- **Offline Fallback** — If API is unavailable, local algorithm generates a schedule

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart           # Colors, typography, component styles
├── models/
│   ├── task.dart                # Task data model
│   └── schedule_block.dart      # Schedule block & generated schedule models
├── services/
│   ├── ai_schedule_service.dart # Anthropic API integration
│   └── schedule_provider.dart  # State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart         # Root screen with bottom navigation
│   ├── tasks_screen.dart        # Task list & management
│   ├── add_task_screen.dart     # Add/edit task form
│   ├── schedule_screen.dart     # AI-generated schedule view
│   ├── history_screen.dart      # Schedule history
│   └── settings_screen.dart    # API key, working hours, preferences
└── widgets/
    ├── task_card.dart           # Reusable task card with swipe-to-delete
    └── schedule_block_card.dart # Schedule time block card
```

## Setup Instructions

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- An Anthropic API key ([get one here](https://console.anthropic.com))

### Installation

1. **Clone / download the project**
   ```bash
   cd schedule_ai_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure your API key**
   
   Open the app → go to **Settings** tab → paste your Anthropic API key.
   
   Or set it in `.env`:
   ```
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```

4. **Run the app**
   ```bash
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   
   # All devices
   flutter devices
   flutter run -d <device-id>
   ```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

## How to Use

1. **Add Tasks** — Go to the Tasks tab and tap the FAB or the + button
2. **Configure Working Hours** — Set your start/end times in Settings
3. **Generate Schedule** — Tap the ✨ button in the center of the bottom navigation
4. **View Schedule** — Switch to the Schedule tab to see your AI-optimized day
5. **Track Progress** — Tap schedule blocks to mark them as completed

## AI Integration

The app calls `POST https://api.anthropic.com/v1/messages` with:
- Model: `claude-opus-4-5`
- A structured prompt containing task details, priorities, and working hours
- Response parsed as JSON with schedule blocks, stats, and an insight

If the API call fails, the app falls back to a local priority-based scheduling algorithm.

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | API calls |
| `shared_preferences` | Local storage |
| `google_fonts` | Plus Jakarta Sans font |
| `flutter_animate` | Animations |
| `intl` | Date formatting |
| `uuid` | Unique task IDs |
| `flutter_slidable` | Swipe gestures |
| `shimmer` | Loading states |

## Customization

- **Colors**: Edit `lib/theme/app_theme.dart`
- **AI Model**: Change `_model` in `lib/services/ai_schedule_service.dart`
- **Prompt**: Customize the scheduling prompt in `ai_schedule_service.dart`
- **Break Logic**: Adjust break insertion rules in `_generateFallbackSchedule()`
