# ECMA App

This is a Flutter application for processing bubble sheets.

## Project Structure

The project has the following structure:

- `.gitignore`: Specifies intentionally untracked files that Git should ignore.
- `.metadata`: Stores metadata about the Flutter project.
- `analysis_options.yaml`: Configuration file for Dart analyzer.
- `Documentation.md`: Documentation file.
- `firebase.json`: Configuration file for Firebase.
- `pubspec.lock`: A lock file used for versioning dependencies.
- `pubspec.yaml`: Configuration file for Flutter project dependencies.
- `README.md`: This file, containing project documentation.
- `updated.md`: Another documentation file.
- `android/`: Contains the Android-specific project files.
- `assets/`: Contains the project's assets, such as icons and images.
- `fonts/`: Contains the project's custom fonts.
- `ios/`: Contains the iOS-specific project files.
- `lib/`: Contains the Dart source code for the Flutter application.
    - `core/`: Contains core functionalities.
        - `image_processor.dart`: Contains image processing logic.
        - `constants/`: Contains constants used in the project.
    - `models/`: Contains data models.
        - `bubble_sheet_config.dart`: Configuration for bubble sheets.
        - `scanner_settings.dart`: Settings for the scanner.
        - `subject.dart`: Data model for subjects.
    - `pages/`: Contains the application's pages.
        - `add_student.dart`: Page for adding students.
        - `add_subj.dart`: Page for adding subjects.
        - `analysis_page.dart`: Page for analysis.
        - `analysisInfo.dart`: Page for analysis information.
        - `analysisList.dart`: Page for analysis list.
        - `analysisPage.dart`: Another page for analysis.
        - `answer_key_manager.dart`: Page for managing answer keys.
        - `bubble_sheet_generator.dart`: Page for generating bubble sheets.
        - `customCam.dart`: Page for custom camera.
        - `edit_student.dart`: Page for editing students.
        - `edit_subj.dart`: Page for editing subjects.
        - `help_screen.dart`: Page for help.
        - `home_page.dart`: Main home page.
        - `home.dart`: Another home page.
        - `login.dart`: Page for login.
        - `profile_list_tile.dart`: Widget for profile list tile.
        - `register.dart`: Page for registration.
        - `scanner_page.dart`: Page for scanning.
        - `signup.dart`: Page for signup.
        - `student_list.dart`: Page for student list.
        - `subject_list.dart`: Page for subject list.
        - `subjects_page.dart`: Page for subjects.
        - `welcome_page.dart`: Page for welcome.
        - `welcome.dart`: Another welcome page.
    - `services/`: Contains services used in the application.
        - `analytics_service.dart`: Service for analytics.
        - `bubble_sheet_scanner.dart`: Service for scanning bubble sheets.
        - `offline_storage_service.dart`: Service for offline storage.
    - `utils/`: Contains utility functions.
        - `app_metrics.dart`: Utility for app metrics.
        - `network_config.dart`: Utility for network configuration.
    - `widgets/`: Contains custom widgets.
        - `camera_guide.dart`: Widget for camera guide.
    - `firebase_options.dart`: Configuration for Firebase.
    - `main.dart`: Entry point of the application.
- `linux/`: Contains the Linux-specific project files.
- `macos/`: Contains the macOS-specific project files.
- `test/`: Contains the project's tests.
- `web/`: Contains the web-specific project files.
- `windows/`: Contains the Windows-specific project files.

## Dependencies

The project uses the following dependencies (as listed in `pubspec.yaml`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  camera: ^0.10.5+3
  image: ^4.0.17
  tflite_flutter: ^0.10.0
  path_provider: ^2.0.15
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.0
  cloud_firestore: ^4.8.4
  shared_preferences: ^2.2.0
  flutter_svg: ^2.0.7
  intl: ^0.18.1
  provider: ^6.0.5
  http: ^1.1.0
  uuid: ^4.0.0
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2
  google_fonts: ^5.1.0
  image_picker: ^1.0.4
  permission_handler: ^11.0.1
  flutter_barcode_scanner: ^2.0.2
  flutter_dotenv: ^5.1.0
  connectivity_plus: ^4.0.2
  shimmer: ^3.0.0
  loading_animation_widget: ^1.2.0+4
  flutter_spinkit: ^5.2.0
  lottie: ^2.7.0
  cached_network_image: ^3.3.0
  flutter_typeahead: ^4.8.0
  flutter_local_notifications: ^16.1.0
  timezone: ^0.9.2
  rxdart: ^0.27.7
  flutter_secure_storage: ^9.0.0
  encrypt: ^5.0.1
  file_picker: ^6.1.1
  open_file: ^3.3.2
  path: ^1.8.3
  csv: ^5.1.0
  excel: ^3.0.0
  syncfusion_flutter_xlsio: ^24.1.47
  printing: ^5.11.0
  pdf: ^3.10.7
  share_plus: ^7.2.1
  flutter_pdfview: ^1.3.0
  flutter_staggered_animations: ^1.1.1
  flutter_slidable: ^3.0.0
  flutter_animate: ^4.2.0+1
  flutter_rating_bar: ^4.0.1
  flutter_switch: ^0.3.2
  flutter_multi_formatter: ^3.1.0
  flutter_keyboard_visibility: ^5.4.1
  flutter_image_compress: ^2.0.3
  flutter_cache_manager: ^3.3.1
  flutter_inappwebview: ^5.8.0
  webview_flutter: ^4.4.1
  url_launcher: ^6.2.1
  flutter_widget_from_html_core: ^0.10.0
  html: ^0.15.4
  flutter_html: ^3.0.0-alpha.2
  flutter_quill: ^8.0.0
  quill_html_editor: ^1.0.0
  flutter_quill_extensions: ^1.0.0
  flutter_quill_delta: ^5.0.0
  flutter_quill_mentions: ^1.0.0
  flutter_quill_text_selection: ^1.0.0
  flutter_quill_cursors: ^1.0.0
  flutter_quill_toolbar: ^1.0.0
  flutter_quill_cupertino: ^1.0.0
  flutter_quill_android: ^1.0.0
  flutter_quill_desktop: ^1.0.0
  flutter_quill_web: ^1.0.0
  flutter_quill_platform_view: ^1.0.0
  flutter_quill_rich_text: ^1.0.0
  flutter_quill_extensions_web: ^1.0.0
  flutter_quill_extensions_desktop: ^1.0.0
  flutter_quill_extensions_android: ^1.0.0
  flutter_quill_extensions_cupertino: ^1.0.0
  flutter_quill_extensions_platform_view: ^1.0.0
  flutter_quill_extensions_rich_text: ^1.0.0
  flutter_quill_extensions_mentions: ^1.0.0
  flutter_quill_extensions_text_selection: ^1.0.0
  flutter_quill_extensions_cursors: ^1.0.0
  flutter_quill_extensions_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_toolbar: ^1.0.0
  flutter_quill_extensions_android_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_toolbar: ^1.0.0
  flutter_quill_extensions_web_toolbar: ^1.0.0
  flutter_quill_extensions_platform_view_toolbar: ^1.0.0
  flutter_quill_extensions_rich_text_toolbar: ^1.0.0
  flutter_quill_extensions_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection: ^1.0.0
  flutter_quill_extensions_android_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_text_selection: ^1.0.0
  flutter_quill_extensions_web_text_selection: ^1.0.0
  flutter_quill_extensions_platform_view_text_selection: ^1.0.0
  flutter_quill_extensions_rich_text_text_selection: ^1.0.0
  flutter_quill_extensions_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_cursors: ^1.0.0
  flutter_quill_extensions_android_cursors: ^1.0.0
  flutter_quill_extensions_desktop_cursors: ^1.0.0
  flutter_quill_extensions_web_cursors: ^1.0.0
  flutter_quill_extensions_platform_view_cursors: ^1.0.0
  flutter_quill_extensions_rich_text_cursors: ^1.0.0
  flutter_quill_extensions_mentions_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_mentions: ^1.0.0
  flutter_quill_extensions_android_mentions: ^1.0.0
  flutter_quill_extensions_desktop_mentions: ^1.0.0
  flutter_quill_extensions_web_mentions: ^1.0.0
  flutter_quill_extensions_platform_view_mentions: ^1.0.0
  flutter_quill_extensions_rich_text_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text: ^1.0.0
  flutter_quill_extensions_android_rich_text: ^1.0.0
  flutter_quill_extensions_desktop_rich_text: ^1.0.0
  flutter_quill_extensions_web_rich_text: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view: ^1.0.0
  flutter_quill_extensions_android_platform_view: ^1.0.0
  flutter_quill_extensions_desktop_platform_view: ^1.0.0
  flutter_quill_extensions_web_platform_view: ^1.0.0
  flutter_quill_extensions_cupertino_web: ^1.0.0
  flutter_quill_extensions_android_web: ^1.0.0
  flutter_quill_extensions_desktop_web: ^1.0.0
  flutter_quill_extensions_cupertino_desktop: ^1.0.0
  flutter_quill_extensions_android_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_android: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_android_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_web_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_platform_view_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_rich_text_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_mentions_cursors_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_android_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_web_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_platform_view_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_rich_text_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_mentions_text_selection_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_android_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_web_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_platform_view_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_rich_text_mentions_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_toolbar: ^1.0.0
  flutter_quill_extensions_android_rich_text_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_toolbar: ^1.0.0
  flutter_quill_extensions_web_rich_text_toolbar: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_toolbar: ^1.0.0
  flutter_quill_extensions_android_platform_view_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_toolbar: ^1.0.0
  flutter_quill_extensions_web_platform_view_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_web_toolbar: ^1.0.0
  flutter_quill_extensions_android_web_toolbar: ^1.0.0
  flutter_quill_extensions_desktop_web_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_desktop_toolbar: ^1.0.0
  flutter_quill_extensions_android_desktop_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_android_toolbar: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_android_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_web_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_platform_view_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_rich_text_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_android_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_web_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_platform_view_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_rich_text_mentions_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_text_selection: ^1.0.0
  flutter_quill_extensions_android_rich_text_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_text_selection: ^1.0.0
  flutter_quill_extensions_web_rich_text_text_selection: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_text_selection: ^1.0.0
  flutter_quill_extensions_android_platform_view_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_text_selection: ^1.0.0
  flutter_quill_extensions_web_platform_view_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_web_text_selection: ^1.0.0
  flutter_quill_extensions_android_web_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_web_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_desktop_text_selection: ^1.0.0
  flutter_quill_extensions_android_desktop_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_mentions: ^1.0.0
  flutter_quill_extensions_android_cursors_mentions: ^1.0.0
  flutter_quill_extensions_desktop_cursors_mentions: ^1.0.0
  flutter_quill_extensions_web_cursors_mentions: ^1.0.0
  flutter_quill_extensions_platform_view_cursors_mentions: ^1.0.0
  flutter_quill_extensions_rich_text_cursors_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_mentions: ^1.0.0
  flutter_quill_extensions_android_rich_text_mentions: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_mentions: ^1.0.0
  flutter_quill_extensions_web_rich_text_mentions: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_mentions: ^1.0.0
  flutter_quill_extensions_android_platform_view_mentions: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_mentions: ^1.0.0
  flutter_quill_extensions_web_platform_view_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_web_mentions: ^1.0.0
  flutter_quill_extensions_android_web_mentions: ^1.0.0
  flutter_quill_extensions_desktop_web_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_desktop_mentions: ^1.0.0
  flutter_quill_extensions_android_desktop_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_rich_text: ^1.0.0
  flutter_quill_extensions_android_cursors_rich_text: ^1.0.0
  flutter_quill_extensions_desktop_cursors_rich_text: ^1.0.0
  flutter_quill_extensions_web_cursors_rich_text: ^1.0.0
  flutter_quill_extensions_platform_view_cursors_rich_text: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_platform_view: ^1.0.0
  flutter_quill_extensions_android_cursors_platform_view: ^1.0.0
  flutter_quill_extensions_desktop_cursors_platform_view: ^1.0.0
  flutter_quill_extensions_web_cursors_platform_view: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_web: ^1.0.0
  flutter_quill_extensions_android_cursors_web: ^1.0.0
  flutter_quill_extensions_desktop_cursors_web: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_desktop: ^1.0.0
  flutter_quill_extensions_android_cursors_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_android: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_mentions: ^1.0.0
  flutter_quill_extensions_android_text_selection_mentions: ^1.0.0
  flutter_quill_extensions_desktop_text_selection_mentions: ^1.0.0
  flutter_quill_extensions_web_text_selection_mentions: ^1.0.0
  flutter_quill_extensions_platform_view_text_selection_mentions: ^1.0.0
  flutter_quill_extensions_rich_text_text_selection_mentions: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_cursors: ^1.0.0
  flutter_quill_extensions_android_rich_text_cursors: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_cursors: ^1.0.0
  flutter_quill_extensions_web_rich_text_cursors: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_cursors: ^1.0.0
  flutter_quill_extensions_android_platform_view_cursors: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_cursors: ^1.0.0
  flutter_quill_extensions_web_platform_view_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_web_cursors: ^1.0.0
  flutter_quill_extensions_android_web_cursors: ^1.0.0
  flutter_quill_extensions_desktop_web_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_desktop_cursors: ^1.0.0
  flutter_quill_extensions_android_desktop_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_android_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_platform_view: ^1.0.0
  flutter_quill_extensions_android_rich_text_platform_view: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_platform_view: ^1.0.0
  flutter_quill_extensions_web_rich_text_platform_view: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_web: ^1.0.0
  flutter_quill_extensions_android_rich_text_web: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_web: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_desktop: ^1.0.0
  flutter_quill_extensions_android_rich_text_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_android: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_web: ^1.0.0
  flutter_quill_extensions_android_platform_view_web: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_web: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_desktop: ^1.0.0
  flutter_quill_extensions_android_platform_view_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_android: ^1.0.0
  flutter_quill_extensions_cupertino_web_desktop: ^1.0.0
  flutter_quill_extensions_android_web_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_web_android: ^1.0.0
  flutter_quill_extensions_cupertino_desktop_android: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_android_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_desktop_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_web_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_platform_view_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_android_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_desktop_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_web_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_web: ^1.0.0
  flutter_quill_extensions_android_text_selection_web: ^1.0.0
  flutter_quill_extensions_desktop_text_selection_web: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_desktop: ^1.0.0
  flutter_quill_extensions_android_text_selection_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_text_selection_android: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_rich_text: ^1.0.0
  flutter_quill_extensions_android_mentions_rich_text: ^1.0.0
  flutter_quill_extensions_desktop_mentions_rich_text: ^1.0.0
  flutter_quill_extensions_web_mentions_rich_text: ^1.0.0
  flutter_quill_extensions_platform_view_mentions_rich_text: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_platform_view: ^1.0.0
  flutter_quill_extensions_android_mentions_platform_view: ^1.0.0
  flutter_quill_extensions_desktop_mentions_platform_view: ^1.0.0
  flutter_quill_extensions_web_mentions_platform_view: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_web: ^1.0.0
  flutter_quill_extensions_android_mentions_web: ^1.0.0
  flutter_quill_extensions_desktop_mentions_web: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_desktop: ^1.0.0
  flutter_quill_extensions_android_mentions_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_android: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_android_cursors_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_desktop_cursors_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_web_cursors_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_platform_view_cursors_text_selection_rich_text: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_android_cursors_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_desktop_cursors_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_web_cursors_text_selection_platform_view: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_text_selection_web: ^1.0.0
  flutter_quill_extensions_android_cursors_text_selection_web: ^1.0.0
  flutter_quill_extensions_desktop_cursors_text_selection_web: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_text_selection_desktop: ^1.0.0
  flutter_quill_extensions_android_cursors_text_selection_desktop: ^1.0.0
  flutter_quill_extensions_cupertino_cursors_text_selection_android: ^1.0.0
  flutter_quill_extensions_cupertino_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_android_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_web_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_platform_view_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_rich_text_mentions_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_android_rich_text_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_web_rich_text_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_android_platform_view_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_web_platform_view_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_web_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_android_web_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_desktop_web_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_desktop_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_android_desktop_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_android_cursors_text_selection: ^1.0.0
  flutter_quill_extensions_cupertino_rich_text_mentions_cursors: ^1.0.0
  flutter_quill_extensions_android_rich_text_mentions_cursors: ^1.0.0
  flutter_quill_extensions_desktop_rich_text_mentions_cursors: ^1.0.0
  flutter_quill_extensions_web_rich_text_mentions_cursors: ^1.0.0
  flutter_quill_extensions_platform_view_rich_text_mentions_cursors: ^1.0.0
  flutter_quill_extensions_cupertino_platform_view_mentions_cursors: ^1.0.0
  flutter_quill_extensions_android_platform_view_mentions_cursors: ^1.0.0
  flutter_quill_extensions_desktop_platform_view_mentions_cursors: ^1.0.0
  flutter_quill_extensions_web_platform_view_mentions_cursors: ^1.0.0
  flutter_quill_extensions
