# MVP Specification

## 1. UI/UX Architecture
- **Custom Title Bar**: Replaces default OS chrome. Contains window controls and app title.
- **Sidebar**: Navigation (Tasks, Presets, Settings).
- **Main View**:
  - Empty state: Dropzone for drag & drop.
  - Active state: Grid/List of imported images with status (pending, processing, done).
- **Properties Panel (Right)**:
  - Resize controls (Width/Height, Percentage).
  - Format selection (JPG, PNG, WEBP).
  - Quality slider.
  - Export location selection.

## 2. Native Core Interface (via Dart FFI)
- `process_image(const char* input_path, const char* output_path, int width, int height, int quality)`
- Future: Structs/callbacks to handle batch job state and progress reporting back to Flutter.

## 3. Flutter State
- `JobState`: List of `ImageTask` (path, original_size, new_size, status).
- `SettingsState`: Current resize/compress parameters.
