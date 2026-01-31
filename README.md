<div align="center">
  <img src="assets/app_icon.png" width="128" height="128" alt="LeTing">
  <h1>乐听 LeTing</h1>
  <p>Apple Music 风格的本地音乐播放器，Flutter 构建</p>
  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
    <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter" alt="Flutter">
    <img src="https://img.shields.io/badge/platform-Android%20|%20iOS%20|%20macOS-lightgrey" alt="Platform">
  </p>
</div>

## Features

- Local music scanning with ID3 metadata & cover art extraction
- Full playback controls: play, pause, seek, volume, queue management
- Play modes: sequential, shuffle, repeat one, repeat all
- LRC lyrics display (synced with playback)
- Favorites & play history
- Playlist creation and management
- Artist & album browsing (aggregated from library)
- Custom artist avatars
- Full-text search with history
- Background playback with notification controls (audio_service)
- Equalizer (Android)
- Dark / Light / System theme
- i18n: Chinese & English
- Localized app name per system language

## Screenshots

<!-- Add screenshots here -->

## Build

```bash
# Clone
git clone https://github.com/sealovesky/leting.git
cd leting

# Install dependencies
flutter pub get

# Generate l10n
flutter gen-l10n

# Run (debug)
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Requirements

- Flutter SDK >= 3.10
- Android: compileSdk 34, minSdk 21
- iOS: Deployment Target 13.0
- macOS: for macOS build only

### Android Permissions

- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` — local music scanning
- `FOREGROUND_SERVICE` / `WAKE_LOCK` — background playback

## Architecture

```
lib/
├── main.dart              # Entry point, MultiProvider injection
├── theme/                 # Colors & theme config
├── models/                # Song, Artist, Album, Playlist, PlayMode
├── services/              # Pure Dart logic layer
│   ├── audio_player_service   # just_audio + audio_service
│   ├── local_music_service    # File scanning + metadata extraction
│   ├── storage_service        # SQLite CRUD
│   └── preference_service     # SharedPreferences KV store
├── providers/             # State management (ChangeNotifier)
│   ├── player_provider        # Playback state, queue, progress
│   ├── library_provider       # Songs, artists, albums, favorites
│   ├── playlist_provider      # Playlist CRUD
│   ├── search_provider        # Search + history
│   └── settings_provider      # Theme, language, audio quality
├── screens/               # Pages
└── widgets/               # Reusable components
```

Services layer has no Flutter dependency. Providers call services and drive UI via `notifyListeners()`.

## Tech Stack

| Package | Purpose |
|---------|---------|
| provider | State management |
| just_audio | Audio playback engine |
| audio_service | Background playback + notification controls |
| audio_metadata_reader | ID3 tag & cover art extraction (pure Dart) |
| permission_handler | Android/iOS storage permissions |
| sqflite | SQLite local database |
| shared_preferences | KV persistence |

## License

[MIT](LICENSE)
