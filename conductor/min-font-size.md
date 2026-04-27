# Implement Project-Wide Minimum Font Size Constraint

## Objective
Enforce a global UI restriction where the absolute minimum font size in the application is 12px.

## Key Files & Context
- `lib/theme.dart`: Contains the central `TextTheme` where `labelSmall` is currently set to `10px`.
- `lib/widgets/**/*.dart`: Several widgets (like `properties_panel.dart`, `history_list_view.dart`, `file_list_view.dart`, `dropzone_area.dart`) contain hardcoded `fontSize: 10` or `fontSize: 11` for small text, badges, and labels.

## Implementation Steps
1. **Update Theme**: Modify `lib/theme.dart` to set `labelSmall`'s `fontSize` to `12`.
2. **Update Hardcoded Sizes**: Search through the `lib/widgets` directory and replace all instances of `fontSize: 10` and `fontSize: 11` with `fontSize: 12`.
3. **Verify Layout**: Ensure that changing these small labels to 12px does not cause significant text overflow issues (e.g., using `TextOverflow.ellipsis` where necessary).

## Verification & Testing
- Run the application and inspect the UI elements that previously used very small text (like the history item secondary text, properties panel hints, watermark opacity percentage, etc.).
- Ensure they are readable and rendered at the new minimum size of 12px without breaking the layout.