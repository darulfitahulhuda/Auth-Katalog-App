import 'package:flutter/material.dart';

/// Parses the persisted [ThemeMode] from [String]. Anything unrecognized
/// (missing key / stale value) falls back to system, never crashes.
ThemeMode themeModeFromString(String? raw) => switch (raw) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};