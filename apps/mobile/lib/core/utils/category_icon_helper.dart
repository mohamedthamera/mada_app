import 'package:flutter/material.dart';

class CategoryIconHelper {
  static const String _iconFolder = 'assets/icons';
  static const String _defaultIcon = 'assets/icons/default.png';

  static const Map<String, String> _arabicToEnglishMap = {
    'تسويق': 'marketing.png',
    'تصميم': 'design.png',
    'برمجة': 'programming.png',
    'لغات': 'languages.png',
    'أعمال': 'business.png',
    'ذكاء اصطناعي': 'ai.png',
  };

  static const Map<String, String> _emojiFallback = {
    'marketing.png': '📈',
    'design.png': '🎨',
    'programming.png': '💻',
    'languages.png': '🌍',
    'business.png': '💼',
    'ai.png': '🤖',
  };

  static String _normalize(String? input) {
    if (input == null || input.trim().isEmpty) {
      return '';
    }
    return input.trim().toLowerCase();
  }

  static String getIconPath(String? categoryName) {
    if (categoryName == null || categoryName.trim().isEmpty) {
      return _defaultIcon;
    }

    final normalized = _normalize(categoryName);
    final englishKey = _arabicToEnglishMap[categoryName];

    if (englishKey != null) {
      return '$_iconFolder/$englishKey';
    }

    final foundKey = _arabicToEnglishMap.entries
        .firstWhere(
          (entry) => _normalize(entry.key) == normalized,
          orElse: () => const MapEntry('', ''),
        )
        .key;

    if (foundKey.isNotEmpty) {
      return '$_iconFolder/${_arabicToEnglishMap[foundKey]}';
    }

    return _defaultIcon;
  }

  static String getIconPathForEnglish(String englishKey) {
    if (englishKey.trim().isEmpty) {
      return _defaultIcon;
    }
    return '$_iconFolder/$englishKey';
  }

  static Widget getCategoryIcon(
    String? categoryName, {
    double width = 32,
    double height = 32,
    Color? color,
  }) {
    final iconPath = getIconPath(categoryName);

    return Image.asset(
      iconPath,
      width: width,
      height: height,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackIcon(categoryName, width, height);
      },
    );
  }

  static Widget getCategoryIconByEnglish(
    String englishKey, {
    double width = 32,
    double height = 32,
    Color? color,
  }) {
    final iconPath = getIconPathForEnglish(englishKey);

    return Image.asset(
      iconPath,
      width: width,
      height: height,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildEmojiFallback(englishKey, width, height);
      },
    );
  }

  static Widget _buildFallbackIcon(
    String? categoryName,
    double width,
    double height,
  ) {
    return Image.asset(
      _defaultIcon,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        final emoji = _getEmojiForCategory(categoryName);
        return _buildEmojiWidget(emoji, width, height);
      },
    );
  }

  static Widget _buildEmojiFallback(
    String englishKey,
    double width,
    double height,
  ) {
    String key = englishKey.toLowerCase();
    if (!key.endsWith('.png')) {
      key = '$englishKey.png';
    }
    final emoji = _emojiFallback[key] ?? '📁';
    return _buildEmojiWidget(emoji, width, height);
  }

  static Widget _buildEmojiWidget(String emoji, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: width * 0.6)),
      ),
    );
  }

  static String _getEmojiForCategory(String? categoryName) {
    if (categoryName == null || categoryName.trim().isEmpty) {
      return '📁';
    }

    final englishKey = _arabicToEnglishMap[categoryName];
    if (englishKey != null) {
      return _emojiFallback[englishKey] ?? '📁';
    }

    for (final entry in _arabicToEnglishMap.entries) {
      if (_normalize(entry.key) == _normalize(categoryName)) {
        return _emojiFallback[entry.value] ?? '📁';
      }
    }

    return '📁';
  }
}
