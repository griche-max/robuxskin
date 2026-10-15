import 'package:flutter/material.dart';

/// Shared visual language for the studio and its editing workspaces.
abstract final class StudioTheme {
  static const background = Color(0xFF101214);
  static const panel = Color(0xFF1B1E22);
  static const raised = Color(0xFF25292E);
  static const line = Color(0xFF353B42);
  static const accent = Color(0xFFB8F34A);
  static const text = Color(0xFFF1F3F5);
  static const muted = Color(0xFF9BA3AD);
  static final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: line),
  );

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: background,
        secondary: accent,
        onSecondary: background,
        surface: panel,
        onSurface: text,
        surfaceContainerHighest: raised,
        onSurfaceVariant: muted,
        outline: line,
        outlineVariant: line,
        primaryContainer: Color(0xFF303D20),
        onPrimaryContainer: accent,
        secondaryContainer: Color(0xFF303D20),
        onSecondaryContainer: accent,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: text, displayColor: text)
          .copyWith(
            titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            labelLarge: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
      ),
      cardTheme: CardThemeData(color: panel, elevation: 0, shape: shape),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(shape),
          side: const WidgetStatePropertyAll(BorderSide(color: line)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? raised : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : muted,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: shape,
        backgroundColor: panel,
        selectedColor: const Color(0xFF303D20),
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: line),
          minimumSize: const Size(48, 44),
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: muted, shape: shape),
      ),
      popupMenuTheme: PopupMenuThemeData(color: raised, shape: shape),
      dialogTheme: DialogThemeData(backgroundColor: panel, shape: shape),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: panel,
        modalBackgroundColor: panel,
        showDragHandle: true,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: line,
        thumbColor: accent,
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: raised,
        contentTextStyle: const TextStyle(color: text),
        shape: shape,
      ),
    );
  }
}
