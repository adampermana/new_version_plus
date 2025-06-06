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

  /// The name of the app as it appears in the store.
  final String? appName;

  /// The developer/publisher name of the app.
  final String? developerName;

  // The Image Apps
  final String? appIconUrl;

  /// App rating (1.0 - 5.0)
  final double? ratingApp;

  /// Number of ratings/reviews
  final int? ratingCount;

  /// Total download count (Android only, iOS doesn't provide this)
  final String? downloadCount;

  /// Age rating for the app (e.g., "4+", "12+", "17+" for iOS or "Everyone", "Teen", "Mature 17+" for Android)
  final String? ageRating;

  /// Content rating details (Android specific - e.g., "Rated for 3+", "Everyone 10+")
  final String? contentRating;

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
  VersionStatus({
    required this.localVersion,
    required this.storeVersion,
    required this.appStoreLink,
    this.releaseNotes,
    this.originalStoreVersion,
    this.lastUpdateDate,
    this.appName,
    this.developerName,
    this.appIconUrl,
    this.ratingApp,
    this.ratingCount,
    this.downloadCount,
    this.ageRating,
    this.contentRating,
  });

  VersionStatus._({
    required this.localVersion,
    required this.storeVersion,
    required this.appStoreLink,
    this.releaseNotes,
    this.originalStoreVersion,
    this.lastUpdateDate,
    this.appName,
    this.developerName,
    this.appIconUrl,
    this.ratingApp,
    this.ratingCount,
    this.downloadCount,
    this.ageRating,
    this.contentRating,
  });
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

  // /// The last update date of the store version (only available for iOS)
  // final DateTime? lastUpdateDate;

  NewVersionPlus({
    this.androidId,
    this.iOSId,
    this.iOSAppStoreCountry,
    this.forceAppVersion,
    this.androidPlayStoreCountry,
    this.androidHtmlReleaseNotes = false,
    // this.lastUpdateDate,
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

    // Extract age rating from iOS App Store
    String? ageRating;
    String? contentRating;

    try {
      // Method 1: Extract from contentAdvisoryRating
      final contentAdvisoryRating =
          jsonObj['results'][0]['contentAdvisoryRating'];
      if (contentAdvisoryRating != null) {
        ageRating = contentAdvisoryRating.toString();
        debugPrint('iOS Age Rating (Advisory): $ageRating');
      }

      // Method 2: Extract from trackContentRating
      if (ageRating == null || ageRating.isEmpty) {
        final trackContentRating = jsonObj['results'][0]['trackContentRating'];
        if (trackContentRating != null) {
          ageRating = trackContentRating.toString();
          debugPrint('iOS Age Rating (Track): $ageRating');
        }
      }

      // Method 3: Extract from advisories array
      if (ageRating == null || ageRating.isEmpty) {
        final advisories = jsonObj['results'][0]['advisories'];
        if (advisories != null && advisories is List && advisories.isNotEmpty) {
          ageRating = advisories.join(', ');
          debugPrint('iOS Age Rating (Advisories): $ageRating');
        }
      }

      // Method 4: Extract age rating from description or other fields
      if (ageRating == null || ageRating.isEmpty) {
        // Sometimes age rating is embedded in other fields
        final description = jsonObj['results'][0]['description'];
        if (description != null) {
          final agePattern = RegExp(r'(\d+\+|\bEveryone\b|\bTeen\b|\bMature\b)',
              caseSensitive: false);
          final ageMatch = agePattern.firstMatch(description.toString());
          if (ageMatch != null) {
            ageRating = ageMatch.group(1);
            debugPrint('iOS Age Rating (Description): $ageRating');
          }
        }
      }

      // Set content rating same as age rating for iOS
      contentRating = ageRating;

      debugPrint('Final iOS Age Rating: $ageRating');
      debugPrint('Final iOS Content Rating: $contentRating');
    } catch (e) {
      debugPrint('Failed to extract age rating from iOS: $e');
    }

    double? ratingApp;
    int? ratingCount;

    try {
      // Get average user rating (0-5 scale)
      final averageUserRating = jsonObj['results'][0]['averageUserRating'];
      if (averageUserRating != null) {
        ratingApp = double.tryParse(averageUserRating.toString());
      }

      // Get rating count for current version
      final userRatingCountForCurrentVersion =
          jsonObj['results'][0]['userRatingCountForCurrentVersion'];
      if (userRatingCountForCurrentVersion != null) {
        ratingCount = int.tryParse(userRatingCountForCurrentVersion.toString());
      }

      // If current version rating count is null or 0, try to get overall rating count
      if (ratingCount == null || ratingCount == 0) {
        final userRatingCount = jsonObj['results'][0]['userRatingCount'];
        if (userRatingCount != null) {
          ratingCount = int.tryParse(userRatingCount.toString());
        }
      }

      debugPrint('iOS App Rating: $ratingApp');
      debugPrint('iOS Rating Count: $ratingCount');
    } catch (e) {
      debugPrint('Failed to extract rating information from iOS: $e');
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

    // Get app icon URL (try multiple sizes)
    String? appIconUrl;
    try {
      appIconUrl = jsonObj['results'][0]['artworkUrl512'] as String?;
      appIconUrl ??= jsonObj['results'][0]['artworkUrl100'] as String?;
      appIconUrl ??= jsonObj['results'][0]['artworkUrl60'] as String?;
      debugPrint('iOS App Icon URL: $appIconUrl');
    } catch (e) {
      debugPrint('Failed to get iOS app icon URL: $e');
    }

    // Extract app name and developer name from iOS App Store
    String? appName;
    String? developerName;

    try {
      appName = jsonObj['results'][0]['trackName'] as String?;
      developerName = jsonObj['results'][0]['artistName'] as String?;

      debugPrint('iOS App Name: $appName');
      debugPrint('iOS Developer Name: $developerName');
    } catch (e) {
      debugPrint('Failed to extract app name or developer name from iOS: $e');
    }
    return VersionStatus._(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion:
          _getCleanVersion(forceAppVersion ?? jsonObj['results'][0]['version']),
      originalStoreVersion: forceAppVersion ?? jsonObj['results'][0]['version'],
      appStoreLink: jsonObj['results'][0]['trackViewUrl'],
      releaseNotes: jsonObj['results'][0]['releaseNotes'],
      lastUpdateDate: lastUpdateDate,
      appName: appName,
      developerName: developerName,
      appIconUrl: appIconUrl,
      ratingApp: ratingApp,
      ratingCount: ratingCount,
      downloadCount: null,
      ageRating: ageRating, // Add this
      contentRating: contentRating, // Add this
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

    String? appIconUrl;

    try {
      // Method 1: Look for app icon in structured data (most reliable)
      final structuredIconRegex =
          RegExp(r'"image"\s*:\s*"([^"]*)"', caseSensitive: false);
      final structuredMatch = structuredIconRegex.firstMatch(response.body);
      if (structuredMatch != null) {
        appIconUrl = structuredMatch.group(1);
        debugPrint('Found icon from structured data: $appIconUrl');
      }

      // Method 2: Look for app icon in meta tags
      if (appIconUrl == null || appIconUrl.isEmpty) {
        final metaIconRegex = RegExp(
            r'<meta\s+property="og:image"\s+content="([^"]+)"',
            caseSensitive: false);
        final metaMatch = metaIconRegex.firstMatch(response.body);
        if (metaMatch != null) {
          appIconUrl = metaMatch.group(1);
          debugPrint('Found icon from meta tag: $appIconUrl');
        }
      }

      // Method 3: Look for specific Play Store icon patterns
      if (appIconUrl == null || appIconUrl.isEmpty) {
        final playStoreIconPatterns = [
          // Pattern for high resolution icons
          RegExp(
              r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s512[^"]*)"'),
          RegExp(
              r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s256[^"]*)"'),
          RegExp(
              r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s128[^"]*)"'),
          // Pattern for any Play Store hosted images
          RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*)"'),
          // Fallback pattern for app icons
          RegExp(r'<img[^>]*class="[^"]*icon[^"]*"[^>]*src="([^"]*)"'),
          RegExp(r'<img[^>]*src="([^"]*)"[^>]*class="[^"]*icon[^"]*"'),
        ];

        for (final pattern in playStoreIconPatterns) {
          final match = pattern.firstMatch(response.body);
          if (match != null) {
            appIconUrl = match.group(1);
            debugPrint('Found icon from pattern: $appIconUrl');
            break;
          }
        }
      }

      // Method 4: Look for JSON-LD structured data
      if (appIconUrl == null || appIconUrl.isEmpty) {
        final jsonLdPattern = RegExp(
            r'"@type"\s*:\s*"MobileApplication"[^}]*"image"\s*:\s*"([^"]*)"',
            caseSensitive: false,
            dotAll: true);
        final jsonLdMatch = jsonLdPattern.firstMatch(response.body);
        if (jsonLdMatch != null) {
          appIconUrl = jsonLdMatch.group(1);
          debugPrint('Found icon from JSON-LD: $appIconUrl');
        }
      }

      // Clean up the URL if found
      if (appIconUrl != null && appIconUrl.isNotEmpty) {
        // Handle relative URLs
        if (!appIconUrl.startsWith('http')) {
          if (appIconUrl.startsWith('//')) {
            appIconUrl = 'https:$appIconUrl';
          } else if (appIconUrl.startsWith('/')) {
            appIconUrl = 'https://play.google.com$appIconUrl';
          }
        }

        // For Play Store images, try to get higher resolution
        if (appIconUrl.contains('play-lh.googleusercontent.com')) {
          // Replace size parameter with higher resolution if available
          appIconUrl = appIconUrl.replaceAll(RegExp(r'=s\d+'), '=s512');
          // If no size parameter, add one
          if (!appIconUrl.contains('=s')) {
            appIconUrl += '=s512';
          }
        }

        debugPrint('Final Android App Icon URL: $appIconUrl');
      }
    } catch (e) {
      debugPrint('Failed to get Android app icon URL: $e');
    }

    // Extract app name from Google Play Store
    String? appName;
    String? developerName;

    try {
      // Method 1: Extract from page title
      final titleRegex = RegExp(
          r'<title[^>]*>([^<]+)\s*-\s*Apps on Google Play</title>',
          caseSensitive: false);
      final titleMatch = titleRegex.firstMatch(response.body);
      if (titleMatch != null) {
        appName = titleMatch.group(1)?.trim();
        debugPrint('Found app name from title: $appName');
      }

      // Method 2: Extract from structured data (JSON-LD)
      if (appName == null || appName.isEmpty) {
        final jsonLdRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
        final jsonLdMatch = jsonLdRegex.firstMatch(response.body);
        if (jsonLdMatch != null) {
          appName = jsonLdMatch.group(1)?.trim();
          debugPrint('Found app name from JSON-LD: $appName');
        }
      }

      // Method 3: Extract from meta property
      if (appName == null || appName.isEmpty) {
        final metaRegex = RegExp(
            r'<meta\s+property="og:title"\s+content="([^"]+)"',
            caseSensitive: false);
        final metaMatch = metaRegex.firstMatch(response.body);
        if (metaMatch != null) {
          appName = metaMatch.group(1)?.trim();
          debugPrint('Found app name from meta tag: $appName');
        }
      }

      // Method 4: Extract from JavaScript data
      if (appName == null || appName.isEmpty) {
        final jsDataRegex = RegExp(r'\["ds:5"[^\]]*\]\s*,\s*\[\s*"([^"]+)"');
        final jsDataMatch = jsDataRegex.firstMatch(response.body);
        if (jsDataMatch != null) {
          appName = jsDataMatch.group(1)?.trim();
          debugPrint('Found app name from JS data: $appName');
        }
      }

      // Method 5: Alternative pattern for app name in structured data
      if (appName == null || appName.isEmpty) {
        final altRegex = RegExp(r'"applicationName"\s*:\s*"([^"]+)"');
        final altMatch = altRegex.firstMatch(response.body);
        if (altMatch != null) {
          appName = altMatch.group(1)?.trim();
          debugPrint('Found app name from application name: $appName');
        }
      }

      // Extract developer name
      // Method 1: From structured data
      final developerRegex =
          RegExp(r'"author"\s*:\s*{\s*"name"\s*:\s*"([^"]+)"');
      final developerMatch = developerRegex.firstMatch(response.body);
      if (developerMatch != null) {
        developerName = developerMatch.group(1)?.trim();
        debugPrint('Found developer name: $developerName');
      }

      // Method 2: Alternative pattern for developer
      if (developerName == null || developerName.isEmpty) {
        final altDeveloperRegex = RegExp(r'"publisher"\s*:\s*"([^"]+)"');
        final altDeveloperMatch = altDeveloperRegex.firstMatch(response.body);
        if (altDeveloperMatch != null) {
          developerName = altDeveloperMatch.group(1)?.trim();
          debugPrint('Found developer name (alt): $developerName');
        }
      }

      // Clean up app name if found
      if (appName != null) {
        // Remove common suffixes and clean up
        appName = appName
            .replaceAll(
                RegExp(r'\s*-\s*Apps on Google Play$', caseSensitive: false),
                '')
            .replaceAll(
                RegExp(r'\s*-\s*Google Play$', caseSensitive: false), '')
            .trim();

        // Decode HTML entities
        appName = _decodeHtmlEntities(appName);
      }

      if (developerName != null) {
        developerName = _decodeHtmlEntities(developerName);
      }

      debugPrint('Final Android App Name: $appName');
      debugPrint('Final Android Developer Name: $developerName');
    } catch (e) {
      debugPrint(
          'Failed to extract app name or developer name from Android: $e');
    }

    // Extract age rating from Google Play Store
    String? ageRating;
    String? contentRating;

    try {
      // Method 1: Look for content rating in structured data
      final contentRatingPatterns = [
        RegExp(r'"contentRating"\s*:\s*"([^"]+)"', caseSensitive: false),
        RegExp(r'"ratingValue"\s*:\s*"([^"]+)"', caseSensitive: false),
        RegExp(r'Rated for (\d+\+)', caseSensitive: false),
        RegExp(r'Ages (\d+\+)', caseSensitive: false),
      ];

      for (final pattern in contentRatingPatterns) {
        final match = pattern.firstMatch(response.body);
        if (match != null) {
          contentRating = match.group(1)?.trim();
          debugPrint('Found content rating: $contentRating');
          break;
        }
      }

      // Method 2: Look for ESRB/PEGI ratings
      final esrbPatterns = [
        RegExp(
            r'\b(Everyone|Everyone 10\+|Teen|Mature 17\+|Adults Only 18\+)\b',
            caseSensitive: false),
        RegExp(r'\b(E|E10\+|T|M|AO)\b'),
        RegExp(r'ESRB:\s*([^<\n]+)', caseSensitive: false),
      ];

      for (final pattern in esrbPatterns) {
        final match = pattern.firstMatch(response.body);
        if (match != null) {
          ageRating = match.group(1)?.trim();
          debugPrint('Found ESRB rating: $ageRating');
          break;
        }
      }

      // Method 3: Look for age rating in meta tags
      if (ageRating == null || ageRating.isEmpty) {
        final metaRatingPatterns = [
          RegExp(r'<meta[^>]*name=".*rating.*"[^>]*content="([^"]+)"',
              caseSensitive: false),
          RegExp(r'<meta[^>]*property=".*rating.*"[^>]*content="([^"]+)"',
              caseSensitive: false),
        ];

        for (final pattern in metaRatingPatterns) {
          final match = pattern.firstMatch(response.body);
          if (match != null) {
            final rating = match.group(1)?.trim();
            if (rating != null && rating.isNotEmpty) {
              ageRating = rating;
              debugPrint('Found meta rating: $ageRating');
              break;
            }
          }
        }
      }

      // Method 4: Look for common age indicators in the page
      if (ageRating == null || ageRating.isEmpty) {
        final ageIndicatorPatterns = [
          RegExp(r'(\d+)\+', caseSensitive: false),
          RegExp(r'Ages (\d+) and up', caseSensitive: false),
          RegExp(r'Suitable for ages (\d+)\+', caseSensitive: false),
        ];

        for (final pattern in ageIndicatorPatterns) {
          final matches = pattern.allMatches(response.body);
          for (final match in matches) {
            final age = match.group(1);
            if (age != null) {
              final ageNum = int.tryParse(age);
              if (ageNum != null && ageNum >= 0 && ageNum <= 18) {
                ageRating = '$age+';
                debugPrint('Found age indicator: $ageRating');
                break;
              }
            }
          }
          if (ageRating != null) break;
        }
      }

      // Method 5: Look for rating in JavaScript data
      if (ageRating == null || ageRating.isEmpty) {
        final jsRatingPattern = RegExp(r'"contentRating":\s*"([^"]+)"');
        final jsMatch = jsRatingPattern.firstMatch(response.body);
        if (jsMatch != null) {
          ageRating = jsMatch.group(1)?.trim();
          debugPrint('Found JS rating: $ageRating');
        }
      }

      // Set default content rating if not found
      if (contentRating == null || contentRating.isEmpty) {
        contentRating = ageRating;
      }

      // Clean up ratings
      if (ageRating != null) {
        ageRating = ageRating
            .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
            .trim();

        if (ageRating.isEmpty) ageRating = null;
      }

      if (contentRating != null) {
        contentRating = contentRating
            .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
            .trim();

        if (contentRating.isEmpty) contentRating = null;
      }

      debugPrint('Final Android Age Rating: $ageRating');
      debugPrint('Final Android Content Rating: $contentRating');
    } catch (e) {
      debugPrint('Failed to extract age rating from Android: $e');
    }

    // Extract rating and rating count from Google Play Store
    double? rating;
    int? ratingCount;
    String? downloadCount;

    try {
      // Method 1: Extract rating from structured data
      final ratingPatterns = [
        RegExp(r'"ratingValue"\s*:\s*"?([0-9.]+)"?'),
        RegExp(r'"aggregateRating"[^}]*"ratingValue"\s*:\s*"?([0-9.]+)"?'),
        RegExp(r'star.*?([0-9.]+)', caseSensitive: false),
      ];

      for (final pattern in ratingPatterns) {
        final match = pattern.firstMatch(response.body);
        if (match != null) {
          rating = double.tryParse(match.group(1)!);
          if (rating != null) {
            debugPrint('Found rating from pattern: $rating');
            break;
          }
        }
      }

      // Method 2: Extract rating count
      final ratingCountPatterns = [
        RegExp(r'"ratingCount"\s*:\s*"?([0-9,]+)"?'),
        RegExp(r'"reviewCount"\s*:\s*"?([0-9,]+)"?'),
        RegExp(r'([0-9,]+)\s*reviews?', caseSensitive: false),
        RegExp(r'([0-9,]+)\s*ratings?', caseSensitive: false),
      ];

      for (final pattern in ratingCountPatterns) {
        final match = pattern.firstMatch(response.body);
        if (match != null) {
          final countStr = match.group(1)!.replaceAll(',', '');
          ratingCount = int.tryParse(countStr);
          if (ratingCount != null) {
            debugPrint('Found rating count from pattern: $ratingCount');
            break;
          }
        }
      }

      // Method 3: Extract download count
      final downloadPatterns = [
        RegExp(r'([0-9,]+\+?)\s*downloads?', caseSensitive: false),
        RegExp(r'([0-9,]+\+?)\s*installs?', caseSensitive: false),
        RegExp(r'"interactionCount"\s*:\s*"([0-9,]+\+?)"'),
      ];

      for (final pattern in downloadPatterns) {
        final match = pattern.firstMatch(response.body);
        if (match != null) {
          downloadCount = match.group(1)!;
          debugPrint('Found download count: $downloadCount');
          break;
        }
      }

      // Method 4: Alternative extraction from page content
      if (rating == null || ratingCount == null) {
        // Look for rating in JavaScript data structures
        final jsRatingPattern = RegExp(r'\[\s*([0-9.]+)\s*,\s*([0-9,]+)\s*\]');
        final jsMatches = jsRatingPattern.allMatches(response.body);

        for (final match in jsMatches) {
          final potentialRating = double.tryParse(match.group(1)!);
          final potentialCount =
              int.tryParse(match.group(2)!.replaceAll(',', ''));

          if (potentialRating != null &&
              potentialRating >= 1.0 &&
              potentialRating <= 5.0) {
            rating ??= potentialRating;
            ratingCount ??= potentialCount;
            debugPrint('Found rating from JS: $rating, count: $ratingCount');
            break;
          }
        }
      }

      debugPrint('Final Android App Rating: $rating');
      debugPrint('Final Android Rating Count: $ratingCount');
      debugPrint('Final Android Download Count: $downloadCount');
    } catch (e) {
      debugPrint('Failed to extract rating information from Android: $e');
    }

    // Method untuk mendukung parsing tanggal Android dengan bahasa Indonesia
// Ganti seluruh bagian "Extract last update date for Android" di method _getAndroidStoreVersion
// mulai dari baris "DateTime? lastUpdateDate;" sampai "debugPrint('Final lastUpdateDate: $lastUpdateDate');"
// dengan kode di bawah ini:

// Extract last update date for Android - improved method with Indonesian support
    DateTime? lastUpdateDate;
    try {
      final currentCountry = androidPlayStoreCountry ?? 'en_US';
      final countryCode =
          currentCountry.split('_')[0]; // Ambil kode negara saja

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
        // Pattern yang lebih fleksibel untuk berbagai bahasa
        final jsDataPatterns = [
          RegExp(r'\["Updated",.*?"([^"]+)"\]'),
          RegExp(r'\["Diperbarui",.*?"([^"]+)"\]'), // Indonesian
          RegExp(r'"dateModified":"([^"]+)"'),
          RegExp(r'"lastModified":"([^"]+)"'),
        ];

        for (final pattern in jsDataPatterns) {
          final jsMatch = pattern.firstMatch(response.body);
          if (jsMatch != null) {
            try {
              final dateStr = jsMatch.group(1)!;
              debugPrint('Found JS date string: $dateStr');

              lastUpdateDate = _parseMultiLanguageDate(dateStr, countryCode);
              if (lastUpdateDate != null) {
                debugPrint('Successfully parsed JS date: $lastUpdateDate');
                break;
              }
            } catch (e) {
              debugPrint('Failed to parse JS date: $e');
              continue;
            }
          }
        }
      }

      // Method 3: Look for alternative date patterns in the HTML
      if (lastUpdateDate == null) {
        // Pattern untuk berbagai bahasa
        final updatePatterns = [
          // English patterns
          RegExp(r'Updated on ([^<]+)', caseSensitive: false),
          RegExp(r'Last updated ([^<]+)', caseSensitive: false),
          // Indonesian patterns
          RegExp(r'Diperbarui pada ([^<]+)', caseSensitive: false),
          RegExp(r'Terakhir diperbarui ([^<]+)', caseSensitive: false),
          // Generic patterns
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

              lastUpdateDate =
                  _parseMultiLanguageDate(cleanDateStr, countryCode);
              if (lastUpdateDate != null) {
                debugPrint(
                    'Successfully parsed alternative date: $lastUpdateDate');
                break;
              }
            } catch (e) {
              debugPrint('Failed to parse alternative date pattern: $e');
              continue;
            }
          }
        }
      }

      // Method 4: Look for any date-like pattern as fallback
      if (lastUpdateDate == null) {
        // Pattern untuk bulan bahasa Inggris
        final englishPattern = RegExp(
            r'(\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b)');

        // Pattern untuk bulan bahasa Indonesia
        final indonesianPattern = RegExp(
            r'(\b(?:\d{1,2}\s+(?:Jan|Feb|Mar|Apr|Mei|Jun|Jul|Ags|Sep|Okt|Nov|Des|Januari|Februari|Maret|April|Juni|Juli|Agustus|September|Oktober|November|Desember)[a-z]*\s+\d{4})\b)',
            caseSensitive: false);

        final patterns = countryCode.toLowerCase() == 'id'
            ? [indonesianPattern, englishPattern]
            : [englishPattern, indonesianPattern];

        for (final pattern in patterns) {
          final fallbackMatch = pattern.firstMatch(response.body);
          if (fallbackMatch != null) {
            try {
              final dateStr = fallbackMatch.group(1)!;
              debugPrint('Found fallback date: $dateStr');

              lastUpdateDate = _parseMultiLanguageDate(dateStr, countryCode);
              if (lastUpdateDate != null) {
                debugPrint(
                    'Successfully parsed fallback date: $lastUpdateDate');
                break;
              }
            } catch (e) {
              debugPrint('Failed to parse fallback date: $e');
              continue;
            }
          }
        }
      }

      // Method 5: Extreme fallback - cari pattern tanggal apapun
      if (lastUpdateDate == null) {
        // Cari pattern dd/mm/yyyy atau mm/dd/yyyy
        final datePattern = RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4})');
        final dateMatch = datePattern.firstMatch(response.body);

        if (dateMatch != null) {
          try {
            final dateStr = dateMatch.group(1)!;
            debugPrint('Found extreme fallback date: $dateStr');

            // Coba format dd/mm/yyyy untuk Indonesia
            if (countryCode.toLowerCase() == 'id') {
              lastUpdateDate = DateFormat('dd/MM/yyyy').parse(dateStr);
            } else {
              lastUpdateDate = DateFormat('MM/dd/yyyy').parse(dateStr);
            }

            debugPrint(
                'Successfully parsed extreme fallback date: $lastUpdateDate');
          } catch (e) {
            debugPrint('Failed to parse extreme fallback date: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to extract Android update date: $e');
    }

// Debug log the final result
    // debugPrint(
    //     'Final lastUpdateDate for country $countryCode: $lastUpdateDate');
    return VersionStatus._(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(forceAppVersion ?? storeVersion ?? ""),
      originalStoreVersion: forceAppVersion ?? storeVersion ?? "",
      appStoreLink: uri.toString(),
      releaseNotes: _formatReleaseNotes(releaseNotes, androidHtmlReleaseNotes),
      lastUpdateDate: lastUpdateDate,
      appName: appName,
      developerName: developerName,
      appIconUrl: appIconUrl,
      ratingApp: rating,
      ratingCount: ratingCount,
      downloadCount: downloadCount,
      ageRating: ageRating, // Add this
      contentRating: contentRating, // Add this
    );
  }

  // Helper method untuk decode HTML entities
  String _decodeHtmlEntities(String text) {
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
  Map<String, String> _getIndonesianMonthMapping() {
    return {
      // Bulan penuh
      'januari': 'January',
      'februari': 'February',
      'maret': 'March',
      'april': 'April',
      'mei': 'May',
      'juni': 'June',
      'juli': 'July',
      'agustus': 'August',
      'september': 'September',
      'oktober': 'October',
      'november': 'November',
      'desember': 'December',
      // Bulan singkat
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'jun': 'Jun',
      'jul': 'Jul',
      'ags': 'Aug',
      'sep': 'Sep',
      'okt': 'Oct',
      'nov': 'Nov',
      'des': 'Dec',
    };
  }

// Method untuk convert tanggal Indonesia ke format yang bisa di-parse
  String _convertIndonesianDateToEnglish(String dateStr) {
    String result = dateStr.toLowerCase().trim();
    final monthMapping = _getIndonesianMonthMapping();

    // Replace Indonesian month names with English ones
    monthMapping.forEach((indonesian, english) {
      result = result.replaceAll(indonesian, english);
    });

    return result;
  }

// Method untuk parsing tanggal dengan support multi-bahasa
  DateTime? _parseMultiLanguageDate(String dateStr, String countryCode) {
    try {
      String cleanDateStr = dateStr.trim();

      // Jika country code adalah Indonesia, convert dulu ke format Inggris
      if (countryCode.toLowerCase() == 'id') {
        cleanDateStr = _convertIndonesianDateToEnglish(cleanDateStr);
      }

      // Daftar format tanggal yang mungkin
      final formats = [
        'MMM d, yyyy', // Mar 15, 2024
        'MMMM d, yyyy', // March 15, 2024
        'd MMM yyyy', // 15 Mar 2024
        'd MMMM yyyy', // 15 March 2024
        'yyyy-MM-dd', // 2024-03-15
        'MM/dd/yyyy', // 03/15/2024
        'dd/MM/yyyy', // 15/03/2024
        'dd-MM-yyyy', // 15-03-2024
        'yyyy/MM/dd', // 2024/03/15
      ];

      // Coba parse dengan berbagai format
      for (final format in formats) {
        try {
          return DateFormat(format, 'en_US').parse(cleanDateStr);
        } catch (e) {
          continue;
        }
      }

      // Jika masih gagal, coba dengan format Indonesia langsung
      if (countryCode.toLowerCase() == 'id') {
        final indonesianFormats = [
          'dd MMMM yyyy', // 15 Maret 2024
          'd MMMM yyyy', // 15 Maret 2024
          'dd MMM yyyy', // 15 Mar 2024
          'd MMM yyyy', // 15 Mar 2024
        ];

        for (final format in indonesianFormats) {
          try {
            return DateFormat(format, 'id_ID').parse(dateStr);
          } catch (e) {
            continue;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
      return null;
    }
  }
}

enum LaunchModeVersion { normal, external }
