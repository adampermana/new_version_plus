import 'package:flutter/foundation.dart';

class HtmlUtils {
  /// Universal release notes formatter that handles both HTML and non-HTML formats
  static String? formatReleaseNotes(
      String? rawReleaseNotes, bool isHtmlFormat) {
    if (rawReleaseNotes == null || rawReleaseNotes.isEmpty) {
      return rawReleaseNotes;
    }

    try {
      String formatted = rawReleaseNotes;

      // Step 1: Always parse Unicode characters first
      formatted = _parseUnicodeToString(formatted) ?? formatted;

      // Step 2: Handle HTML entities (both formats need this)
      final htmlEntities = {
        '\\u0026quot;': '"',
        '\\u0026apos;': "'",
        '\\u0026lt;': '<',
        '\\u0026gt;': '>',
        '\\u0026amp;': '&',
        '\\u0026#39;': "'",
        '\\u0026nbsp;': ' ',
        '&quot;': '"',
        '&apos;': "'",
        '&lt;': '<',
        '&gt;': '>',
        '&amp;': '&',
        '&#39;': "'",
        '&nbsp;': ' ',
      };

      htmlEntities.forEach((entity, replacement) {
        formatted = formatted.replaceAll(entity, replacement);
      });

      if (isHtmlFormat) {
        // HTML format processing - convert HTML tags to readable format
        formatted = _processHtmlTags(formatted);
      } else {
        // Non-HTML format processing - clean up encoded tags
        formatted = _processNonHtmlFormat(formatted);
      }

      // Step 3: Common post-processing for both formats
      formatted = _applyCommonFormatting(formatted);

      return formatted.isEmpty ? rawReleaseNotes : formatted;
    } catch (e) {
      debugPrint('Error formatting release notes: $e');
      // Return original with minimal cleanup as fallback
      return rawReleaseNotes;
    }
  }

  /// Enhanced function for convert text - handles multiple Unicode formats
  static String? _parseUnicodeToString(String? release) {
    try {
      if (release == null || release.isEmpty) return release;

      String result = release;

      // Handle Unicode code points (\uXXXX)
      result = result.replaceAllMapped(
        RegExp(r'\\u([0-9A-Fa-f]{4})'),
        (match) {
          final codePoint = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(codePoint);
        },
      );

      // Handle percent-encoded characters (%XX)
      result = result.replaceAllMapped(
        RegExp(r'%([0-9A-Fa-f]{2})'),
        (match) {
          final asciiValue = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(asciiValue);
        },
      );

      // Handle HTML character references (&#XXX;)
      result = result.replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (match) {
          final charCode = int.parse(match.group(1)!);
          return String.fromCharCode(charCode);
        },
      );

      // Handle hexadecimal HTML character references (&#xXXX;)
      result = result.replaceAllMapped(
        RegExp(r'&#x([0-9A-Fa-f]+);'),
        (match) {
          final charCode = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(charCode);
        },
      );

      return result;
    } catch (e) {
      debugPrint('Error parsing Unicode in release notes: $e');
      return release;
    }
  }

  /// Process HTML tags for androidHtmlReleaseNotes = true
  static String _processHtmlTags(String formatted) {
    // Convert HTML tags to readable format
    // Line breaks and paragraphs
    formatted =
        formatted.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003cbr\\u003e', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003cbr\s*\/\\u003e', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'<p\s*/?>', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003cp\\u003e', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003c\/p\\u003e', caseSensitive: false), '\n');

    // Lists
    formatted =
        formatted.replaceAll(RegExp(r'<li\s*/?>', caseSensitive: false), '• ');
    formatted =
        formatted.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003cli\\u003e', caseSensitive: false), '• ');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003c\/li\\u003e', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'<ul\s*/?>', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'</ul>', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003cul\\u003e', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003c\/ul\\u003e', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'<ol\s*/?>', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'</ol>', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003col\\u003e', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003c\/ol\\u003e', caseSensitive: false), '\n');

    // Headers
    formatted = formatted.replaceAll(
        RegExp(r'<h[1-6]\s*/?>', caseSensitive: false), '\n');
    formatted =
        formatted.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003ch[1-6]\\u003e', caseSensitive: false), '\n');
    formatted = formatted.replaceAll(
        RegExp(r'\\u003c\/h[1-6]\\u003e', caseSensitive: false), '\n');

    // Bold, italic, and other formatting tags (remove but keep content)
    final formattingTags = [
      RegExp(r'</?b\s*/?>', caseSensitive: false),
      RegExp(r'</?i\s*/?>', caseSensitive: false),
      RegExp(r'</?strong\s*/?>', caseSensitive: false),
      RegExp(r'</?em\s*/?>', caseSensitive: false),
      RegExp(r'</?u\s*/?>', caseSensitive: false),
      RegExp(r'\\u003cb\\u003e', caseSensitive: false),
      RegExp(r'\\u003c\/b\\u003e', caseSensitive: false),
      RegExp(r'\\u003ci\\u003e', caseSensitive: false),
      RegExp(r'\\u003c\/i\\u003e', caseSensitive: false),
      RegExp(r'\\u003cstrong\\u003e', caseSensitive: false),
      RegExp(r'\\u003c\/strong\\u003e', caseSensitive: false),
      RegExp(r'\\u003cem\\u003e', caseSensitive: false),
      RegExp(r'\\u003c\/em\\u003e', caseSensitive: false),
    ];

    for (final tag in formattingTags) {
      formatted = formatted.replaceAll(tag, '');
    }

    // Remove any remaining HTML-like tags
    formatted = formatted.replaceAll(RegExp(r'<[^>]*>'), '');
    formatted = formatted.replaceAll(RegExp(r'\\u003c[^\\]*\\u003e'), '');

    return formatted;
  }

  /// Process non-HTML format for androidHtmlReleaseNotes = false
  static String _processNonHtmlFormat(String formatted) {
    // Remove encoded HTML tags but preserve structure
    final tagPatterns = [
      RegExp(r"\\u003c[A-Za-z]{1,10}\\u003e",
          multiLine: true, caseSensitive: true),
      RegExp(r"\\u003c\/[A-Za-z]{1,10}\\u003e",
          multiLine: true, caseSensitive: true),
      RegExp(r"\\u003c[A-Za-z\s\/]{1,20}\\u003e",
          multiLine: true, caseSensitive: true),
    ];

    for (final pattern in tagPatterns) {
      formatted = formatted.replaceAll(pattern, '');
    }

    // Handle line breaks that might be encoded differently
    formatted = formatted.replaceAll(RegExp(r'\\n'), '\n');
    formatted = formatted.replaceAll(RegExp(r'\\r'), '');
    formatted = formatted.replaceAll(RegExp(r'\\t'), '  ');

    // Look for bullet point patterns in the text itself
    formatted =
        formatted.replaceAll(RegExp(r'^\s*[-*•▪▫]\s*', multiLine: true), '• ');
    formatted =
        formatted.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '• ');

    return formatted;
  }

  /// Apply common formatting rules for both HTML and non-HTML formats
  static String _applyCommonFormatting(String formatted) {
    // Handle escaped characters
    formatted = formatted.replaceAll(r'\"', '"');
    formatted = formatted.replaceAll(r"\'", "'");
    formatted = formatted.replaceAll(r'\\', '');

    // Standardize bullet points
    formatted =
        formatted.replaceAll(RegExp(r'^\s*[-*•▪▫]\s*', multiLine: true), '• ');
    formatted =
        formatted.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '• ');

    // Clean up whitespace
    // Remove excessive newlines but preserve structure
    formatted = formatted.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    formatted = formatted.replaceAll(RegExp(r'^\s+', multiLine: true), '');
    formatted = formatted.replaceAll(RegExp(r'\s+$', multiLine: true), '');

    // Ensure proper spacing after bullet points
    formatted = formatted.replaceAll(RegExp(r'•\s*'), '• ');

    // Handle version formatting
    formatted = formatted.replaceAllMapped(
        RegExp(r'^(Version\s+[\d.]+[:\s]*)',
            multiLine: true, caseSensitive: false),
        (match) => '\n${match.group(1)}\n');

    // Capitalize first letter after bullet points
    formatted = formatted.replaceAllMapped(RegExp(r'•\s+([a-z])'),
        (match) => '• ${match.group(1)!.toUpperCase()}');

    // Final cleanup
    formatted = formatted.trim();

    // Remove empty bullet points
    formatted = formatted.replaceAll(RegExp(r'\n•\s*\n'), '\n');
    formatted = formatted.replaceAll(RegExp(r'^•\s*$', multiLine: true), '');

    // Ensure we don't start with newlines
    formatted = formatted.replaceAll(RegExp(r'^\n+'), '');

    // Make sure there's proper spacing between sections
    // formatted = formatted.replaceAll(RegExp('([a-zA-Z.])\n([A-Z\u2022])'), '$1\n\n$2');

    return formatted;
  }

  // Helper method untuk decode HTML entities
  static String decodeHtmlEntities(String text) {
    final htmlEntities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&#x27;': "'",
      '&#x2F;': '/',
      '&#x60;': '`',
      '&#x3D;': '=',
    };

    String result = text;
    htmlEntities.forEach((entity, replacement) {
      result = result.replaceAll(entity, replacement);
    });

    // Handle numeric character references
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        final charCode = int.parse(match.group(1)!);
        return String.fromCharCode(charCode);
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9A-Fa-f]+);'),
      (match) {
        final charCode = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(charCode);
      },
    );

    return result;
  }
}
