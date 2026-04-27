# MVP Implementation Plan

## Phase 1: Foundation & Native Core Setup
1. **FFI Architecture**: Define the C-style interface for the native image processing core.
2. **Implement Native Functions**: Set up the native build system (CMake/C++) for image manipulation.
3. **Bridge Verification**: Ensure Flutter can call the native functions via Dart FFI successfully.

## Phase 2: UI Framework & Theming
1. **Window Management**: Integrate `bitsdojo_window` to hide default OS title bar and make the window frameless.
2. **Theming**: Define the "Sleek Dark Minimalist" theme (colors, typography).
3. **Layout Structure**: Build the Custom Title Bar, Sidebar, Main Content Area, and Properties Panel.

## Phase 3: Core Features Integration
1. **Drag & Drop**: Integrate `desktop_drop` in the Main Content Area.
2. **State Management**: Implement Riverpod providers to hold image lists and processing configurations.
3. **Processing Logic**: Wire the UI "Start" button to dispatch batch jobs to the native core via FFI, updating the UI progress state.

## Phase 4: Polish & Advanced Features
1. **Real-time Preview**: Implement a split-view widget to compare original vs. processed image.
2. **Presets**: Allow saving the current configuration to local storage (using `shared_preferences` or `hive`) and loading them via the UI.
3. **Refinement**: Add subtle animations, hover effects, and ensure error handling (e.g., unsupported files).
