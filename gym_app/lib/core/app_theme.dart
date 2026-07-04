import 'package:flutter/material.dart';

class AppTheme {
  // Màu chủ đạo: xanh lá đậm (năng lượng, gym) + cam nhấn (call-to-action)
  static const Color primary = Color(0xFF1B5E3A);
  static const Color primaryLight = Color(0xFF2E8B57);
  static const Color accent = Color(0xFFFF6B35);
  static const Color background = Color(0xFFF6F7F5);
  static const Color surface = Colors.white;
  static const Color danger = Color(0xFFD64545);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withOpacity(0.08),
        labelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}

/// Badge trạng thái nhỏ dùng ở nhiều màn hình (active/inactive/expired...).
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.$1.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.$2,
        style: TextStyle(color: config.$1, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  (Color, String) _configFor(String status) {
    switch (status) {
      case 'active':
        return (AppTheme.primaryLight, 'Đang hoạt động');
      case 'inactive':
        return (Colors.grey, 'Ngừng hoạt động');
      case 'expired':
        return (AppTheme.danger, 'Đã hết hạn');
      case 'cancelled':
        return (Colors.grey, 'Đã huỷ');
      default:
        return (Colors.grey, status);
    }
  }
}
