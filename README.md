# DailyFaith

DailyFaith is a Flutter app that turns your lock screen and home screen into a daily dose of Scripture. It pairs a random Bible verse with a beautiful background image, then generates a wallpaper you can set manually or have updated automatically on a schedule.

## Features

- **Daily verse wallpapers** — Random verse from the Bible (labs.bible.org) over a high-quality background image (Unsplash), with readable text and optional dark overlay.
- **Verse by topic** — Filter verses by keyword: All (66 books), Love, Strength, Hope, Peace, Faith, Comfort, Wisdom, Grace, or Joy. Choose in Wallpaper Settings.
- **Manual or automatic updates** — Set the current verse + image as your wallpaper with one tap, or schedule a daily refresh at a time you choose (e.g. each morning).
- **Apply where you want** — Use Wallpaper Settings to apply updates to lock screen only, home screen only, or both.
- **Customize the look** — Adjust font size, alignment, color, and font family. Your choices are saved and used for both manual and scheduled wallpapers.
- **Unsplash attribution** — Backgrounds use Unsplash’s API and hotlinked URLs; photographer credit is shown at the bottom of each wallpaper.

## Requirements

- Flutter SDK (see `pubspec.yaml` for version)
- Android (tested); iOS and other platforms may need configuration
- Network access for verses and images
- Permissions: wallpaper, storage/media (for setting wallpaper), notifications and exact alarm (for scheduled updates)

## Getting Started

1. Clone the repo and open the project.
2. Run `flutter pub get`.
3. Run the app: `flutter run`, or build a release APK: `flutter build apk --release`.

## Project structure

- `lib/features/` — Main UI: verse screen, editor controls, wallpaper settings.
- `lib/core/services/` — Bible API, Unsplash, image generation, wallpaper, WorkManager (scheduling), settings.
- `lib/core/utils/` — Bible metadata (66 books), topic → passage mapping.
- `lib/background/` — WorkManager callback for scheduled wallpaper updates.

## License

Private project; not published to pub.dev.
