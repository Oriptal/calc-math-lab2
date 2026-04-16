# calc-math-lab2

Desktop application for ITMO computational mathematics lab 2 with a Qt Quick interface and numerical solvers implemented in C++.

## Overview

The project combines algorithmic coursework and UI work: numerical methods are implemented in C++, while the user interface is built with QML to present equations, systems, settings, and results in a desktop app format.

## Studied Topics

- nonlinear equation solving
- solving systems of equations
- separation of calculation logic and UI
- desktop interface development with QML

## Stack

- C++
- Qt Quick / QML
- CMake
- Typst for the report sources in `doc/`

## Structure

- `calc/` - numerical methods and solver logic
- `components/` - reusable QML interface elements
- `assets/` - equations and system illustrations
- `doc/` - report source and generated PDF

## Run

```bash
cmake -S . -B build
cmake --build build
./build/appHelloWorldQuickProject
```

## Release Build

The application uses Qt QML modules, including `QtCharts`, so a release should be packaged as a
full deploy directory instead of distributing only the executable.

```bash
./package.sh
```

By default, the script creates a release build in `build-release/` and a distributable package in
`dist/`.

Manual equivalent:

```bash
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release
cmake --install build-release --prefix "$(pwd)/dist"
```
