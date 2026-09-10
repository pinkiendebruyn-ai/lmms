# FFTW 3.3.10 - Windows Build

A pre-built distribution of FFTW (Fastest Fourier Transform in the West) version 3.3.10 for Windows, compiled with MSVC and optimized for modern x86-64 processors.

## Overview

FFTW is a C library for computing the discrete Fourier transform (DFT) in one or more dimensions, of arbitrary input size, and of both real and complex data. It is widely used in scientific computing, signal processing, and image processing applications.

This build provides optimized DLL libraries for both single and double precision floating-point operations on Windows platforms.

## Build Information

### System Environment
- **Operating System**: Windows 10 (OS Build 19045.6691)
- **Compiler**: Microsoft Visual C++ (MSVC) 17 2022
- **Build System**: CMake with Ninja 1.13.2
- **Architecture**: x64 (64-bit)
- **Build Type**: Release

### Optimization Flags
All libraries are compiled with the following SIMD optimizations:
- **SSE2**: Streaming SIMD Extensions 2
- **AVX**: Advanced Vector Extensions
- **AVX2**: Advanced Vector Extensions 2

These optimizations provide significant performance improvements on modern Intel and AMD processors.

## Library Variants

This build includes **two precision variants**, both compiled as shared libraries (DLLs):

### 1. Double Precision (Default)
- **Library**: `fftw3.dll`
- **Import Library**: `fftw3.lib`
- **Precision**: 64-bit floating-point (double)
- **Use Case**: General-purpose FFT operations requiring high precision

### 2. Single Precision (Float)
- **Library**: `fftw3f.dll`
- **Import Library**: `fftw3f.lib`
- **Precision**: 32-bit floating-point (float)
- **Use Case**: Performance-critical applications where single precision is sufficient

### Threading Support

**Note**: Threaded variants (with `ENABLE_THREADS=ON`) failed during the build process. Only non-threaded versions are available in this distribution. For multi-threaded FFT operations, consider using alternative approaches such as:
- Parallelizing at the application level
- Using multiple FFT instances across threads
- Rebuilding FFTW with threading support using a different configuration

## Directory Structure

```
C:\fftw-install\
├── bin\
│   ├── fftw3.dll          # Double precision DLL
│   └── fftw3f.dll         # Single precision DLL
├── lib\
│   ├── fftw3.lib          # Double precision import library
│   └── fftw3f.lib         # Single precision import library
└── include\
    ├── fftw3.h              # Main header file
    └── [other headers]      # Additional FFTW headers
```

## Installation

### Option 1: System-wide Installation
1. Copy the contents of `bin\` to a directory in your system PATH (e.g., `C:\Windows\System32` or `C:\Program Files\FFTW\bin`)
2. Copy the contents of `lib\` to your development library directory
3. Copy the contents of `include\` to your development include directory

### Option 2: Project-specific Installation
1. Copy the entire `fftw-install` directory to your project
2. Update your project's include and library paths to point to the FFTW directories

## Usage

### C/C++ Integration

#### 1. Include the Header
```c
#include <fftw3.h>
```

#### 2. Link the Libraries

**For Double Precision:**
- Add `fftw3.lib` to your linker input
- Ensure `fftw3.dll` is in your application's runtime path

**For Single Precision:**
- Add `fftw3f.lib` to your linker input
- Ensure `fftw3f.dll` is in your application's runtime path

#### 3. Visual Studio Configuration

**Include Directories:**
```
C:\fftw-install\include
```

**Library Directories:**
```
C:\fftw-install\lib
```

**Linker Input (Additional Dependencies):**
- For double precision: `fftw3.lib`
- For single precision: `fftw3f.lib`

**Environment Variable (Optional):**
Add to PATH:
```
C:\fftw-install\bin
```

### Example Code

#### Double Precision FFT
```c
#include <fftw3.h>
#include <stdio.h>

int main() {
    int N = 1024;
    fftw_complex *in, *out;
    fftw_plan p;

    // Allocate memory
    in = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
    out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);

    // Create plan
    p = fftw_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);

    // Initialize input (example: impulse)
    for (int i = 0; i < N; i++) {
        in[i][0] = (i == 0) ? 1.0 : 0.0;  // Real part
        in[i][1] = 0.0;                    // Imaginary part
    }

    // Execute FFT
    fftw_execute(p);

    // Process output...
    printf("FFT complete!\n");

    // Cleanup
    fftw_destroy_plan(p);
    fftw_free(in);
    fftw_free(out);

    return 0;
}
```

#### Single Precision FFT
```c
#include <fftw3.h>
#include <stdio.h>

int main() {
    int N = 1024;
    fftwf_complex *in, *out;
    fftwf_plan p;

    // Allocate memory
    in = (fftwf_complex*) fftwf_malloc(sizeof(fftwf_complex) * N);
    out = (fftwf_complex*) fftwf_malloc(sizeof(fftwf_complex) * N);

    // Create plan
    p = fftwf_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);

    // Initialize input (example: impulse)
    for (int i = 0; i < N; i++) {
        in[i][0] = (i == 0) ? 1.0f : 0.0f;  // Real part
        in[i][1] = 0.0f;                     // Imaginary part
    }

    // Execute FFT
    fftwf_execute(p);

    // Process output...
    printf("FFT complete!\n");

    // Cleanup
    fftwf_destroy_plan(p);
    fftwf_free(in);
    fftwf_free(out);

    return 0;
}
```

## Build Script

The libraries were built using the following batch script with CMake and Ninja:

<details>
<summary>Click to view build script</summary>

```batch
@echo off
REM ===========================
REM FFTW3 build batch - Windows MSVC + Ninja
REM ===========================

REM --- Paths ---
set FFTW_SRC=C:\fftw-src\fftw.3.10
set BUILD_DIR=C:\fftw-build
set INSTALL_DIR=C:\fftw-install

REM --- Create folders ---
mkdir %BUILD_DIR%
mkdir %INSTALL_DIR%
mkdir %INSTALL_DIR%\bin
mkdir %INSTALL_DIR%\lib
mkdir %INSTALL_DIR%\include

REM --- Setup MSVC environment ---
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

REM ===========================
REM 1️⃣ Build DOUBLE precision (non-threaded)
REM ===========================
echo.
echo Building DOUBLE precision (non-threaded)...
mkdir %BUILD_DIR%\double
cd %BUILD_DIR%\double

cmake %FFTW_SRC% ^
  -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_C_COMPILER=cl ^
  -DBUILD_SHARED_LIBS=ON ^
  -DENABLE_THREADS=OFF ^
  -DENABLE_FLOAT=OFF ^
  -DENABLE_SSE2=ON ^
  -DENABLE_AVX=ON ^
  -DENABLE_AVX2=ON ^
  -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR%

ninja
ninja install

REM ===========================
REM 2️⃣ Build SINGLE precision (non-threaded)
REM ===========================
echo.
echo Building SINGLE precision (non-threaded)...
mkdir %BUILD_DIR%\float
cd %BUILD_DIR%\float

cmake %FFTW_SRC% ^
  -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_C_COMPILER=cl ^
  -DBUILD_SHARED_LIBS=ON ^
  -DENABLE_THREADS=OFF ^
  -DENABLE_FLOAT=ON ^
  -DENABLE_SSE2=ON ^
  -DENABLE_AVX=ON ^
  -DENABLE_AVX2=ON ^
  -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR%

ninja
ninja install

echo.
echo =====================================
echo FFTW3 build complete!
echo Output directory:
echo Include: %INSTALL_DIR%\include
echo Libraries: %INSTALL_DIR%\lib
echo DLLs: %INSTALL_DIR%\bin
echo =====================================
pause
```
</details>

## Known Issues

### Compatibility
- Requires Visual C++ Redistributable 2022 (x64) to be installed on target systems
- Optimized for x86-64 processors with AVX2 support (Intel Haswell/AMD Excavator or newer)
- May run with reduced performance on older processors that don't support AVX/AVX2

## Performance Considerations

1. **Plan Creation**: Use `FFTW_MEASURE` or `FFTW_PATIENT` flags for better performance in production code (instead of `FFTW_ESTIMATE`)
2. **Memory Alignment**: Use `fftw_malloc()` and `fftw_free()` for optimal SIMD performance
3. **Plan Reuse**: Create plans once and reuse them for multiple FFT operations
4. **Precision Choice**: Use single precision (`fftw3f`) when appropriate for 2x memory savings and potential performance gains

## Redistribution

When distributing applications using this FFTW build:

1. Include the required DLL(s) with your application:
   - `fftw3.dll` for double precision
   - `fftw3f.dll` for single precision

2. Ensure the Visual C++ 2022 Redistributable is available on target systems

3. Comply with FFTW's GNU General Public License (GPL) or obtain a commercial license

## License

FFTW is licensed under the **GNU General Public License (GPL) version 2 or later**.

### Important License Notes:
- If you distribute software using FFTW, your software must also be GPL-compatible
- For proprietary/commercial applications, you may need to purchase a commercial license from MIT
- See the [FFTW License Page](http://www.fftw.org/doc/License-and-Copyright.html) for details

## Resources

- **Official FFTW Website**: http://www.fftw.org/
- **FFTW Documentation**: http://www.fftw.org/fftw3_doc/
- **FFTW Download Page**: http://www.fftw.org/download.html
- **GitHub Repository**: https://github.com/Arifmaulanaazis

## Version History

### Version 3.3.10 (Windows Build)
- **Date**: December 2025
- **Compiler**: MSVC 17 2022
- **Build System**: CMake + Ninja 1.13.2
- **Optimizations**: SSE2, AVX, AVX2
- **Variants**: Double and Single precision (non-threaded)

## Credits

- **FFTW Authors**: Matteo Frigo and Steven G. Johnson
- **Build Maintainer**: [Arifmaulanaazis](https://github.com/Arifmaulanaazis)
- **FFTW Official Site**: Massachusetts Institute of Technology (MIT)

## Support

For issues related to:
- **FFTW library itself**: Visit the [official FFTW site](http://www.fftw.org/)
- **This Windows build**: Open an issue on the [GitHub repository](https://github.com/Arifmaulanaazis)

---

**Built with**: CMake, Ninja, and MSVC on Windows 10
**Last Updated**: December 2025