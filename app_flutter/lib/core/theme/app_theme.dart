import 'package:flutter/material.dart';

import 'eva_palette.dart';

/// Monta o [ThemeData] do Material a partir de uma [EvaPalette].
///
/// Equivale ao que o custom.css faz na versao web: os tokens de cor da
/// paleta alimentam botoes, campos, cards e tipografia de uma vez so.
class AppTheme {
  const AppTheme._();

  /// Fonte dos titulos -- equivale ao font-family Orbitron do CSS.
  static const titleFont = 'Orbitron';

  /// Fonte dos numeros e textos corridos -- Share Tech Mono no CSS.
  static const monoFont = 'ShareTechMono';

  static ThemeData build(EvaPalette p) {
    final baseFont = p.monoFont ? monoFont : null;

    final scheme = ColorScheme(
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primary: p.purple,
      onPrimary: Colors.white,
      primaryContainer: p.purple.withValues(alpha: 0.18),
      onPrimaryContainer: p.purpleLight,
      secondary: p.purpleLight,
      onSecondary: p.isDark ? Colors.black : Colors.white,
      tertiary: p.green,
      onTertiary: Colors.black,
      error: p.red,
      onError: Colors.white,
      surface: p.bgCard,
      onSurface: p.text,
      surfaceContainerHighest: p.bgCardHover,
      onSurfaceVariant: p.textMuted,
      outline: p.border,
      outlineVariant: p.borderBright,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: baseFont,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(p),

      appBarTheme: AppBarTheme(
        backgroundColor: p.bgCard,
        foregroundColor: p.textBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: titleFont,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: p.purple,
        ),
        iconTheme: IconThemeData(color: p.purpleLight, size: 20),
        shape: Border(bottom: BorderSide(color: p.border)),
      ),

      cardTheme: CardThemeData(
        color: p.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border),
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textMuted, size: 20),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: titleFont,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textMuted,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: titleFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.purpleLight,
          textStyle: const TextStyle(
            fontFamily: titleFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.isDark ? p.bg : p.bgCardHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        hintStyle: TextStyle(color: p.textMuted, fontSize: 13),
        labelStyle: TextStyle(color: p.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(color: p.purpleLight, fontSize: 13),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        errorStyle: TextStyle(color: p.red, fontSize: 11),
        border: _inputBorder(p.border),
        enabledBorder: _inputBorder(p.border),
        focusedBorder: _inputBorder(p.purple, width: 1.6),
        errorBorder: _inputBorder(p.red),
        focusedErrorBorder: _inputBorder(p.red, width: 1.6),
        disabledBorder: _inputBorder(p.border.withValues(alpha: 0.5)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border),
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border),
          borderRadius: BorderRadius.circular(8),
        ),
        titleTextStyle: TextStyle(
          fontFamily: titleFont,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: p.textBright,
        ),
        contentTextStyle:
            TextStyle(fontFamily: baseFont, fontSize: 13, color: p.text),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.bgCardHover,
        contentTextStyle: TextStyle(
          fontFamily: baseFont,
          color: p.textBright,
          fontSize: 13,
        ),
        actionTextColor: p.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border),
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bgCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.purple.withValues(alpha: 0.18),
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: titleFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: p.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 21,
            color: states.contains(WidgetState.selected)
                ? p.purpleLight
                : p.textMuted,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.bgCard,
        indicatorColor: p.purple.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: p.purpleLight, size: 22),
        unselectedIconTheme: IconThemeData(color: p.textMuted, size: 22),
        selectedLabelTextStyle: TextStyle(
          fontFamily: titleFont,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.purpleLight,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: titleFont,
          fontSize: 10,
          color: p.textMuted,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.purple,
        linearTrackColor: p.border,
        circularTrackColor: p.border,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.green : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.green.withValues(alpha: 0.3)
              : p.border,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.bg,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(fontFamily: baseFont, fontSize: 11, color: p.text),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textMuted,
        textColor: p.text,
        titleTextStyle:
            TextStyle(fontFamily: baseFont, fontSize: 13.5, color: p.text),
        subtitleTextStyle:
            TextStyle(fontFamily: baseFont, fontSize: 11.5, color: p.textMuted),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.bgCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.purple,
        headerForegroundColor: Colors.white,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme(EvaPalette p) {
    final body = p.monoFont ? monoFont : null;
    return TextTheme(
      // Titulos usam Orbitron, como .page-title e os h1..h6 do tema EVA.
      headlineMedium: TextStyle(
          fontFamily: titleFont,
          color: p.textBright,
          fontWeight: FontWeight.w700,
          fontSize: 20),
      headlineSmall: TextStyle(
          fontFamily: titleFont,
          color: p.textBright,
          fontWeight: FontWeight.w700,
          fontSize: 17),
      titleLarge: TextStyle(
          fontFamily: titleFont,
          color: p.textBright,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3),
      titleMedium: TextStyle(
          fontFamily: titleFont,
          color: p.textBright,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.3),
      titleSmall: TextStyle(
          fontFamily: titleFont,
          color: p.text,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: 0.3),
      // Corpo usa Share Tech Mono no tema EVA.
      bodyLarge: TextStyle(fontFamily: body, color: p.text, fontSize: 14.5),
      bodyMedium: TextStyle(fontFamily: body, color: p.text, fontSize: 13),
      bodySmall:
          TextStyle(fontFamily: body, color: p.textMuted, fontSize: 11.5),
      labelLarge: TextStyle(
          fontFamily: titleFont,
          color: p.text,
          fontSize: 12,
          fontWeight: FontWeight.w600),
      labelMedium: TextStyle(
          fontFamily: titleFont,
          color: p.textMuted,
          fontSize: 10.5,
          letterSpacing: 0.4),
      labelSmall: TextStyle(
          fontFamily: titleFont,
          color: p.textMuted,
          fontSize: 9.5,
          letterSpacing: 0.4),
    );
  }
}
