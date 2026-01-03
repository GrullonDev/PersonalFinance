#!/bin/bash

# Clean the project
flutter clean
rm -f pubspec.lock
rm -rf .dart_tool/
rm -rf .packages
rm -rf .flutter-plugins

# Get dependencies
flutter pub get

# Run build runner
dart run build_runner build --delete-conflicting-outputs
