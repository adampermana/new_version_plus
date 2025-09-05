import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:new_version_plus/src/models/version_status.dart';
import 'package:new_version_plus/src/utils/string_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class IosStoreService {
  final String? iOSId;
  final String? iOSAppStoreCountry;
  final String? forceAppVersion;

  IosStoreService({
    this.iOSId,
    this.iOSAppStoreCountry,
    this.forceAppVersion,
  });

  /// iOS info is fetched by using the iTunes lookup API, which returns a
  /// JSON document.
  Future<VersionStatus?> getStoreVersion(PackageInfo packageInfo) async {
    final id = iOSId ?? packageInfo.packageName;
    Map<String, dynamic> parameters = {};

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
    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    final jsonObj = json.decode(response.body);
    final List results = jsonObj['results'];
    if (results.isEmpty) {
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

    return VersionStatus.fromStore(
      localVersion: StringUtils.getCleanVersion(packageInfo.version),
      storeVersion: StringUtils.getCleanVersion(
          forceAppVersion ?? jsonObj['results'][0]['version']),
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
      ageRating: ageRating,
      contentRating: contentRating,
    );
  }
}
