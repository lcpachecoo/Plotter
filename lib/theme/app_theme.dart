import 'package:flutter/material.dart';

/// Tema visual centralizado do Plotter, reaproveitado por todas as telas.
///
/// Na Etapa 3 a paleta foi revisada para garantir contraste adequado (todas
/// as cores de texto/ícone listadas abaixo atingem no mínimo 4,5:1 sobre o
/// fundo claro, conforme WCAG 2.1 AA) e os componentes receberam tamanhos
/// mínimos de toque de 48 dp, aplicando a Lei de Fitts.
class AppTheme {
  AppTheme._();

  // --- Cores de marca -----------------------------------------------------
  static const Color primaryGreen = Color(0xFF2E7D32); // 5,1:1 sobre branco
  static const Color darkGreen = Color(0xFF1B5E20); // 8,0:1 sobre branco
  static const Color lightGreen = Color(0xFF66BB6A); // apenas preenchimentos
  static const Color earthBrown = Color(0xFF6D4C41); // 7,6:1 sobre branco

  // --- Superfícies --------------------------------------------------------
  static const Color background = Color(0xFFF4F6F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFC9D2C6);

  // --- Texto --------------------------------------------------------------
  static const Color textPrimary = Color(0xFF1B2019); // 15,8:1
  static const Color textSecondary = Color(0xFF4F5B52); // 7,1:1

  // --- Cores de status (usadas em texto, ícones e selos) ------------------
  static const Color doneGreen = Color(0xFF2E7D32); // 5,1:1
  static const Color pendingOrange = Color(0xFFBF5000); // 4,8:1
  static const Color scheduledBlue = Color(0xFF1565C0); // 5,7:1
  static const Color dangerRed = Color(0xFFB3261E); // 6,0:1

  /// Altura/largura mínima de qualquer alvo de toque (Lei de Fitts e
  /// recomendação de acessibilidade do Material Design).
  static const double minTouchTarget = 48;

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      onPrimary: Colors.white,
      secondary: darkGreen,
      surface: surface,
      onSurface: textPrimary,
      error: dangerRed,
    );

    // Borda extra desenhada quando o componente recebe foco de teclado,
    // garantindo indicação visual para quem navega sem toque.
    WidgetStateProperty<BorderSide?> focusSide(Color color) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: color, width: 3);
        }
        return null;
      });
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      // Densidade padrão (e não compacta) preserva alvos de toque grandes.
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: primaryGreen.withValues(alpha: 0.16),
      hoverColor: primaryGreen.withValues(alpha: 0.08),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: outline, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        // Campos altos são mais fáceis de acertar com o dedo em campo.
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 16),
        helperStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: textSecondary),
        errorStyle: const TextStyle(
          color: dangerRed,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          // Botão principal alto e largo: alvo grande = ação mais rápida.
          minimumSize: const Size(minTouchTarget, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(side: focusSide(darkGreen)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkGreen,
          minimumSize: const Size(minTouchTarget, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(side: focusSide(darkGreen)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkGreen,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        extendedTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(
        // Itens de lista com 56 dp de altura mínima continuam confortáveis
        // mesmo com a fonte do sistema ampliada.
        minTileHeight: 56,
        iconColor: primaryGreen,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        height: 72,
        elevation: 3,
        indicatorColor: lightGreen.withValues(alpha: 0.30),
        // Rótulos sempre visíveis: o ícone sozinho não identifica a ação.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? darkGreen
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? darkGreen
                : textSecondary,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: darkGreen, size: 28),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 26),
        selectedLabelTextStyle: TextStyle(
          color: darkGreen,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: TextStyle(color: textSecondary, fontSize: 14),
        minWidth: 88,
        minExtendedWidth: 220,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF26312A),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        actionTextColor: lightGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF26312A),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryGreen
              : const Color(0xFFDDE3DA),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: lightGreen.withValues(alpha: 0.30),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // Tipografia com corpo de texto a partir de 15 px, evitando textos
      // pequenos demais para leitura sob sol forte, em campo aberto.
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 15, color: textPrimary),
        bodySmall: TextStyle(fontSize: 14, color: textSecondary),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Breakpoints usados para adaptar o layout e o mecanismo de navegação a
/// diferentes tamanhos de tela.
class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 700;
  static const double desktop = 1100;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static bool isExtraWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}
