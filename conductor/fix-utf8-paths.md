# Fix Path Handling and Error Reporting for File Export

## Objective
Ensure that files exported to directories with non-ASCII characters (like Chinese paths) on Windows are successfully processed and saved. Additionally, improve error reporting so the user is aware when a file fails to process.

## Key Files & Context
- `native/image_processor.cpp`: Uses standard `fopen` via `stb_image` and a custom `write_to_file` function. On Windows, these functions expect ANSI paths by default, causing them to fail when Dart passes UTF-8 paths containing non-ASCII characters (e.g., Chinese directory names).
- `lib/providers/processing_provider.dart`: Currently ignores the integer result code returned by the native `imageProcessor.process` method, leading to silent failures where the UI shows "Done" but no files are exported.

## Implementation Steps

### 1. Enable UTF-8 Support in Native Code
In `native/image_processor.cpp`, define the `stb_image` UTF-8 macros specifically for Windows before the includes:
```cpp
#ifdef _WIN32
#define STBI_WINDOWS_UTF8
#define STBIW_WINDOWS_UTF8
#endif

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
// ...
```

### 2. Update `write_to_file` for Windows UTF-8
In `native/image_processor.cpp`, modify the `write_to_file` helper function to handle UTF-8 paths on Windows by converting them to wide strings and using `_wfopen`:
```cpp
static int write_to_file(const char* path, const uint8_t* data, size_t size) {
#ifdef _WIN32
    int len = MultiByteToWideChar(CP_UTF8, 0, path, -1, NULL, 0);
    if (len == 0) return 0;
    std::vector<wchar_t> wpath(len);
    MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath.data(), len);
    FILE* f = _wfopen(wpath.data(), L"wb");
#else
    FILE* f = fopen(path, "wb");
#endif
    if (!f) return 0;
    size_t written = fwrite(data, 1, size, f);
    fclose(f);
    return written == size;
}
```

### 3. Improve Error Handling in Dart
In `lib/providers/processing_provider.dart`, within the `_handleResponse` method, add a check for `response.result`. If it's negative, log an error or update a fail count so that failures don't silently register as successes.

## Verification & Testing
- Select an output directory that contains Chinese characters (e.g., `D:\图片输出`).
- Drag and drop a list of files into the app.
- Process the files and verify they are correctly created in the selected output directory.
- Intentionally cause an error (e.g., read-only output directory) to ensure the failure is caught.