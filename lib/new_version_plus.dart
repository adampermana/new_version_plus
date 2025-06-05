library new_version_plus;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Information about the app's current version, and the most recent version
/// available in the Apple App Store or Google Play Store.
class VersionStatus {
  /// The current version of the app.
  final String localVersion;

  /// The most recent version of the app in the store.
  final String storeVersion;

  /// The most recent version of the app in the store.
  final String? originalStoreVersion;

  /// A link to the app store page where the app can be updated.
  final String appStoreLink;

  /// The release notes for the store version of the app.
  final String? releaseNotes;

  /// The last update date of the store version (optional).
  final DateTime? lastUpdateDate;

  /// Returns `true` if the store version of the application is greater than the local version.
  bool get canUpdate {
    final local = localVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();

    // Each consecutive field in the version notation is less significant than the previous one,
    // therefore only one comparison needs to yield `true` for it to be determined that the store
    // version is greater than the local version.
    for (var i = 0; i < store.length; i++) {
      // The store version field is newer than the local version.
      if (store[i] > local[i]) {
        return true;
      }

      // The local version field is newer than the store version.
      if (local[i] > store[i]) {
        return false;
      }
    }

    // The local and store versions are the same.
    return false;
  }

  //Public Contructor
  VersionStatus(
      {required this.localVersion,
      required this.storeVersion,
      required this.appStoreLink,
      this.releaseNotes,
      this.originalStoreVersion,
      this.lastUpdateDate});

  VersionStatus._(
      {required this.localVersion,
      required this.storeVersion,
      required this.appStoreLink,
      this.releaseNotes,
      this.originalStoreVersion,
      this.lastUpdateDate});
}

class NewVersionPlus {
  /// An optional value that can override the default packageName when
  /// attempting to reach the Apple App Store. This is useful if your app has
  /// a different package name in the App Store.
  final String? iOSId;

  /// An optional value that can override the default packageName when
  /// attempting to reach the Google Play Store. This is useful if your app has
  /// a different package name in the Play Store.
  final String? androidId;

  /// Only affects iOS App Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  final String? iOSAppStoreCountry;

  /// Only affects Android Play Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  /// see https://www.ibm.com/docs/en/radfws/9.6.1?topic=overview-locales-code-pages-supported
  final String? androidPlayStoreCountry;

  /// An optional value that will force the plugin to always return [forceAppVersion]
  /// as the value of [storeVersion]. This can be useful to test the plugin's behavior
  /// before publishng a new version.
  final String? forceAppVersion;

  //Html original body request
  final bool androidHtmlReleaseNotes;

  /// The last update date of the store version (only available for iOS)
  final DateTime? lastUpdateDate;

  NewVersionPlus({
    this.androidId,
    this.iOSId,
    this.iOSAppStoreCountry,
    this.forceAppVersion,
    this.androidPlayStoreCountry,
    this.androidHtmlReleaseNotes = false,
    this.lastUpdateDate,
  });

  /// This checks the version status, then displays a platform-specific alert
  /// with buttons to dismiss the update alert, or go to the app store.
  showAlertIfNecessary(
      {required BuildContext context,
      LaunchModeVersion launchModeVersion = LaunchModeVersion.normal}) async {
    final VersionStatus? versionStatus = await getVersionStatus();

    if (versionStatus != null && versionStatus.canUpdate) {
      // ignore: use_build_context_synchronously
      showUpdateDialog(
          context: context,
          versionStatus: versionStatus,
          launchModeVersion: launchModeVersion);
    }
  }

  /// This checks the version status and returns the information. This is useful
  /// if you want to display a custom alert, or use the information in a different
  /// way.
  Future<VersionStatus?> getVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isIOS) {
      return _getiOSStoreVersion(packageInfo);
    } else if (Platform.isAndroid) {
      return _getAndroidStoreVersion(packageInfo);
    } else {
      debugPrint(
          'The target platform "${Platform.operatingSystem}" is not yet supported by this package.');
      return null;
    }
  }

  /// This function attempts to clean local version strings so they match the MAJOR.MINOR.PATCH
  /// versioning pattern, so they can be properly compared with the store version.
  String _getCleanVersion(String version) =>
      RegExp(r'\d+(\.\d+)?(\.\d+)?').stringMatch(version) ?? '0.0.0';
  // RegExp(r'\d+\.\d+(\.\d+)?').stringMatch(version) ?? '0.0.0';
  //RegExp(r'\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?').stringMatch(version) ?? '0.0.0'; \d+(\.\d+)?(\.\d+)?

  /// iOS info is fetched by using the iTunes lookup API, which returns a
  /// JSON document.
  Future<VersionStatus?> _getiOSStoreVersion(PackageInfo packageInfo) async {
    final id = iOSId ?? packageInfo.packageName;
    // final parameters = {"bundleId": id};

    Map<String, dynamic> parameters = {};

    /// programmermager:fix/issue-35-ios-failed-host-lookup
    if (id.contains('.')) {
      parameters['bundleId'] = id;
    } else {
      parameters['id'] = id;
    }

    parameters['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

    if (iOSAppStoreCountry != null) {
      parameters.addAll({"country": iOSAppStoreCountry!});
    }
    var uri = Uri.https("itunes.apple.com", "/lookup", parameters);
    // final response = await http.get(uri);
    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      debugPrint('Failed to query iOS App Store\n$e');
      return null;
    }

    if (response.statusCode != 200) {
      debugPrint('Failed to query iOS App Store');
      return null;
    }
    final jsonObj = json.decode(response.body);
    final List results = jsonObj['results'];
    if (results.isEmpty) {
      debugPrint('Can\'t find an app in the App Store with the id: $id');
      return null;
    }

    // Parse last update date from currentVersionReleaseDate
    DateTime? lastUpdateDate;
    try {
      final releaseDateString =
          jsonObj['results'][0]['currentVersionReleaseDate'];
      if (releaseDateString != null) {
        lastUpdateDate = DateTime.parse(releaseDateString);
      }
    } catch (e) {
      debugPrint('Failed to parse release date: $e');
    }
    return VersionStatus._(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion:
          _getCleanVersion(forceAppVersion ?? jsonObj['results'][0]['version']),
      originalStoreVersion: forceAppVersion ?? jsonObj['results'][0]['version'],
      appStoreLink: jsonObj['results'][0]['trackViewUrl'],
      releaseNotes: jsonObj['results'][0]['releaseNotes'],
      lastUpdateDate: lastUpdateDate,
    );
  }

  /// Android info is fetched by parsing the html of the app store page.
  /// Android info is fetched by parsing the html of the app store page.
  /// Android info is fetched by parsing the html of the app store page.
  Future<VersionStatus?> _getAndroidStoreVersion(
      PackageInfo packageInfo) async {
    final id = androidId ?? packageInfo.packageName;
    final uri = Uri.https("play.google.com", "/store/apps/details", {
      "id": id.toString(),
      "hl": androidPlayStoreCountry ?? "en_US",
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
    });

    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      debugPrint('Failed to query Google Play Store\n$e');
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception("Invalid response code: ${response.statusCode}");
    }

    // Extract version - supports 1.2.3 (most apps) and 1.2.prod.3 (e.g. Google Cloud)
    final regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
    final storeVersion = regexp.firstMatch(response.body)?.group(1);

    // Extract release notes with improved patterns
    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
    final expRemoveSc = RegExp(r"\\u003c[A-Za-z]{1,10}\\u003e",
        multiLine: true, caseSensitive: true);
    final expRemoveQuote =
        RegExp(r"\\u0026quot;", multiLine: true, caseSensitive: true);

    String? releaseNotes = regexpRelease.firstMatch(response.body)?.group(3);

    // Extract last update date for Android - improved method
    DateTime? lastUpdateDate;
    try {
      // Method 1: Look for structured data containing date
      final structuredDataRegex = RegExp(r'"datePublished":"([^"]+)"');
      final structuredMatch = structuredDataRegex.firstMatch(response.body);

      if (structuredMatch != null) {
        try {
          lastUpdateDate = DateTime.parse(structuredMatch.group(1)!);
          debugPrint('Found structured date: ${structuredMatch.group(1)}');
        } catch (e) {
          debugPrint('Failed to parse structured date: $e');
        }
      }

      // Method 2: Look for JavaScript data containing update date
      if (lastUpdateDate == null) {
        final jsDataRegex = RegExp(r'\["Updated",.*?"([^"]+)"\]');
        final jsMatch = jsDataRegex.firstMatch(response.body);

        if (jsMatch != null) {
          try {
            final dateStr = jsMatch.group(1)!;
            debugPrint('Found JS date string: $dateStr');

            // Try different date formats
            final formats = [
              'MMM d, yyyy',
              'MMMM d, yyyy',
              'd MMM yyyy',
              'd MMMM yyyy',
              'yyyy-MM-dd',
            ];

            for (final format in formats) {
              try {
                lastUpdateDate = DateFormat(format, 'en_US').parse(dateStr);
                debugPrint(
                    'Successfully parsed date with format $format: $lastUpdateDate');
                break;
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            debugPrint('Failed to parse JS date: $e');
          }
        }
      }

      // Method 3: Look for alternative date patterns in the HTML
      if (lastUpdateDate == null) {
        // Pattern for "Updated on" or similar
        final updatePatterns = [
          RegExp(r'Updated on ([^<]+)'),
          RegExp(r'Last updated ([^<]+)'),
          RegExp(r'"lastModified":"([^"]+)"'),
          RegExp(r'"dateModified":"([^"]+)"'),
        ];

        for (final pattern in updatePatterns) {
          final match = pattern.firstMatch(response.body);
          if (match != null) {
            try {
              final dateStr = match.group(1)!.trim();
              debugPrint('Found date pattern: $dateStr');

              // Clean up the date string
              final cleanDateStr = dateStr
                  .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
                  .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
                  .trim();

              // Try to parse the cleaned date
              final formats = [
                'MMM d, yyyy',
                'MMMM d, yyyy',
                'd MMM yyyy',
                'd MMMM yyyy',
                'yyyy-MM-dd',
                'MM/dd/yyyy',
                'dd/MM/yyyy',
              ];

              for (final format in formats) {
                try {
                  lastUpdateDate =
                      DateFormat(format, 'en_US').parse(cleanDateStr);
                  debugPrint(
                      'Successfully parsed alternative date: $lastUpdateDate');
                  break;
                } catch (e) {
                  continue;
                }
              }

              if (lastUpdateDate != null) break;
            } catch (e) {
              debugPrint('Failed to parse alternative date pattern: $e');
              continue;
            }
          }
        }
      }

      // Method 4: Look for any date-like pattern as fallback
      if (lastUpdateDate == null) {
        final fallbackPattern = RegExp(
            r'(\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b)');
        final fallbackMatch = fallbackPattern.firstMatch(response.body);

        if (fallbackMatch != null) {
          try {
            final dateStr = fallbackMatch.group(1)!;
            debugPrint('Found fallback date: $dateStr');

            final formats = ['MMM d, yyyy', 'MMMM d, yyyy'];
            for (final format in formats) {
              try {
                lastUpdateDate = DateFormat(format, 'en_US').parse(dateStr);
                debugPrint(
                    'Successfully parsed fallback date: $lastUpdateDate');
                break;
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            debugPrint('Failed to parse fallback date: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to extract Android update date: $e');
    }

    // Debug log the final result
    debugPrint('Final lastUpdateDate: $lastUpdateDate');

    return VersionStatus._(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(forceAppVersion ?? storeVersion ?? ""),
      originalStoreVersion: forceAppVersion ?? storeVersion ?? "",
      appStoreLink: uri.toString(),
      releaseNotes: _formatReleaseNotes(releaseNotes, androidHtmlReleaseNotes),
      lastUpdateDate: lastUpdateDate,
    );
  }

  /// Universal release notes formatter that handles both HTML and non-HTML formats
  String? _formatReleaseNotes(String? rawReleaseNotes, bool isHtmlFormat) {
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

  /// Process HTML tags for androidHtmlReleaseNotes = true
  String _processHtmlTags(String formatted) {
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
  String _processNonHtmlFormat(String formatted) {
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
  String _applyCommonFormatting(String formatted) {
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

  /// Enhanced function for convert text - handles multiple Unicode formats
  String? _parseUnicodeToString(String? release) {
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

  /// Update action fun
  /// show modal
  void _updateActionFunc(
      {required String appStoreLink,
      required bool allowDismissal,
      required BuildContext context,
      LaunchMode launchMode = LaunchMode.platformDefault}) {
    launchAppStore(appStoreLink, launchMode: launchMode);
    if (allowDismissal) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Shows the user a platform-specific alert about the app update. The user
  /// can dismiss the alert or proceed to the app store.
  ///
  /// To change the appearance and behavior of the update dialog, you can
  /// optionally provide [dialogTitle], [dialogText], [updateButtonText],
  /// [dismissButtonText], and [dismissAction] parameters.
  void showUpdateDialog({
    required BuildContext context,
    required VersionStatus versionStatus,
    String dialogTitle = 'Update Available',
    String? dialogText,
    String updateButtonText = 'Update',
    bool allowDismissal = true,
    String dismissButtonText = 'Maybe Later',
    VoidCallback? dismissAction,
    LaunchModeVersion launchModeVersion = LaunchModeVersion.normal,
  }) async {
    final dialogTitleWidget = Text(dialogTitle);
    final dialogTextWidget = Text(dialogText ??
        'You can now update this app from ${versionStatus.localVersion} to ${versionStatus.storeVersion}');

    final launchMode = launchModeVersion == LaunchModeVersion.external
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    final updateButtonTextWidget = Text(updateButtonText);

    List<Widget> actions = [
      Platform.isAndroid
          ? TextButton(
              onPressed: () => _updateActionFunc(
                  allowDismissal: allowDismissal,
                  context: context,
                  appStoreLink: versionStatus.appStoreLink,
                  launchMode: launchMode),
              child: updateButtonTextWidget,
            )
          : CupertinoDialogAction(
              onPressed: () => _updateActionFunc(
                  allowDismissal: allowDismissal,
                  context: context,
                  appStoreLink: versionStatus.appStoreLink,
                  launchMode: launchMode),
              child: updateButtonTextWidget,
            ),
    ];

    if (allowDismissal) {
      final dismissButtonTextWidget = Text(dismissButtonText);
      dismissAction = dismissAction ??
          () => Navigator.of(context, rootNavigator: true).pop();
      actions.add(
        Platform.isAndroid
            ? TextButton(
                onPressed: dismissAction, child: dismissButtonTextWidget)
            : CupertinoDialogAction(
                onPressed: dismissAction, child: dismissButtonTextWidget),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: allowDismissal,
      builder: (BuildContext context) {
        if (Platform.isAndroid) {
          return WillPopScope(
            onWillPop: () async => allowDismissal,
            child: AlertDialog(
              title: dialogTitleWidget,
              content: dialogTextWidget,
              actions: actions,
            ),
          );
        } else {
          return CupertinoAlertDialog(
            title: dialogTitleWidget,
            content: dialogTextWidget,
            actions: actions,
          );
        }
      },
    );
  }

  /// Launches the Apple App Store or Google Play Store page for the app.
  Future<void> launchAppStore(String appStoreLink,
      {LaunchMode launchMode = LaunchMode.platformDefault}) async {
    if (await canLaunchUrl(Uri.parse(appStoreLink))) {
      await launchUrl(Uri.parse(appStoreLink), mode: launchMode);
    } else {
      throw 'Could not launch appStoreLink';
    }
  }

  /// Function for convert text
  /// _parseUnicodeToString
  // String? _parseUnicodeToStrings(String? release) {
  //   try {
  //     if (release == null || release.isEmpty) return release;

  //     final re = RegExp(
  //       r'(%(?<asciiValue>[0-9A-Fa-f]{2}))'
  //       r'|(\\u(?<codePoint>[0-9A-Fa-f]{4}))'
  //       r'|.',
  //     );

  //     var matches = re.allMatches(release);
  //     var codePoints = <int>[];
  //     for (var match in matches) {
  //       var codePoint =
  //           match.namedGroup('asciiValue') ?? match.namedGroup('codePoint');
  //       if (codePoint != null) {
  //         codePoints.add(int.parse(codePoint, radix: 16));
  //       } else {
  //         codePoints += match.group(0)!.runes.toList();
  //       }
  //     }
  //     var decoded = String.fromCharCodes(codePoints);
  //     return decoded;
  //   } catch (e) {
  //     return release;
  //   }
  // }
}

enum LaunchModeVersion { normal, external }
