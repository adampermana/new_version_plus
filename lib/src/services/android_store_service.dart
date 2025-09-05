import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:new_version_plus/src/models/version_status.dart';
import 'package:new_version_plus/src/utils/date_utils.dart';
import 'package:new_version_plus/src/utils/html_utils.dart';
import 'package:new_version_plus/src/utils/string_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AndroidStoreService {
  final String? androidId;
  final String? androidPlayStoreCountry;
  final String? forceAppVersion;
  final bool androidHtmlReleaseNotes;

  AndroidStoreService({
    this.androidId,
    this.androidPlayStoreCountry,
    this.forceAppVersion,
    this.androidHtmlReleaseNotes = false,
  });

  Future<VersionStatus?> getStoreVersion(PackageInfo packageInfo) async {
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
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    final regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
    final storeVersion = regexp.firstMatch(response.body)?.group(1);

    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
    String? releaseNotes = regexpRelease.firstMatch(response.body)?.group(3);

    String? appIconUrl = _extractAppIconUrl(response.body);
    final appInfo = _extractAppInfo(response.body);
    final ratings = _extractRatings(response.body);
    final ageRatings = _extractAgeRatings(response.body);
    final lastUpdateDate =
        _extractLastUpdateDate(response.body, androidPlayStoreCountry);

    return VersionStatus.fromStore(
      localVersion: StringUtils.getCleanVersion(packageInfo.version),
      storeVersion:
          StringUtils.getCleanVersion(forceAppVersion ?? storeVersion ?? ""),
      originalStoreVersion: forceAppVersion ?? storeVersion ?? "",
      appStoreLink: uri.toString(),
      releaseNotes:
          HtmlUtils.formatReleaseNotes(releaseNotes, androidHtmlReleaseNotes),
      lastUpdateDate: lastUpdateDate,
      appName: appInfo['appName'],
      developerName: appInfo['developerName'],
      appIconUrl: appIconUrl,
      ratingApp: ratings['rating'],
      ratingCount: ratings['ratingCount'],
      downloadCount: ratings['downloadCount'],
      ageRating: ageRatings['ageRating'],
      contentRating: ageRatings['contentRating'],
    );
  }

  String? _extractAppIconUrl(String body) {
    try {
      // Method 1: Structured data
      final structuredIconRegex =
          RegExp(r'"image"\s*:\s*"([^"]*)"', caseSensitive: false);
      final structuredMatch = structuredIconRegex.firstMatch(body);
      if (structuredMatch != null) return structuredMatch.group(1);

      // Method 2: Meta tags
      final metaIconRegex = RegExp(
          r'<meta\s+property="og:image"\s+content="([^"]+)"',
          caseSensitive: false);
      final metaMatch = metaIconRegex.firstMatch(body);
      if (metaMatch != null) return metaMatch.group(1);

      // Method 3: Play Store patterns
      final playStoreIconPatterns = [
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s512[^"]*)"'),
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s256[^"]*)"'),
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s128[^"]*)"'),
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*)"'),
        RegExp(r'<img[^>]*class="[^"]*icon[^"]*"[^>]*src="([^"]*)"'),
        RegExp(r'<img[^>]*src="([^"]*)"[^>]*class="[^"]*icon[^"]*"'),
      ];

      for (final pattern in playStoreIconPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          var url = match.group(1);
          if (url != null && url.contains('play-lh.googleusercontent.com')) {
            url = url.replaceAll(RegExp(r'=s\d+'), '=s512');
            if (!url.contains('=s')) url += '=s512';
          }
          return url;
        }
      }

      // Method 4: JSON-LD
      final jsonLdPattern = RegExp(
          r'"@type"\s*:\s*"MobileApplication"[^}]*"image"\s*:\s*"([^"]*)"',
          caseSensitive: false,
          dotAll: true);
      final jsonLdMatch = jsonLdPattern.firstMatch(body);
      if (jsonLdMatch != null) {
        var url = jsonLdMatch.group(1);
        if (url != null && !url.startsWith('http')) {
          if (url.startsWith('//')) {
            url = 'https:$url';
          } else if (url.startsWith('/')) {
            url = 'https://play.google.com$url';
          }
        }
        return url;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Map<String, String?> _extractAppInfo(String body) {
    String? appName;
    String? developerName;

    try {
      // Extract app name
      final titleRegex = RegExp(
          r'<title[^>]*>([^<]+)\s*-\s*Apps on Google Play</title>',
          caseSensitive: false);
      final titleMatch = titleRegex.firstMatch(body);
      if (titleMatch != null) {
        appName = titleMatch.group(1)?.trim();
      }

      if (appName == null || appName.isEmpty) {
        final jsonLdRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
        final jsonLdMatch = jsonLdRegex.firstMatch(body);
        if (jsonLdMatch != null) {
          appName = jsonLdMatch.group(1)?.trim();
        }
      }

      if (appName == null || appName.isEmpty) {
        final metaRegex = RegExp(
            r'<meta\s+property="og:title"\s+content="([^"]+)"',
            caseSensitive: false);
        final metaMatch = metaRegex.firstMatch(body);
        if (metaMatch != null) {
          appName = metaMatch.group(1)?.trim();
        }
      }

      // Extract developer name
      final developerRegex =
          RegExp(r'"author"\s*:\s*{\s*"name"\s*:\s*"([^"]+)"');
      final developerMatch = developerRegex.firstMatch(body);
      if (developerMatch != null) {
        developerName = developerMatch.group(1)?.trim();
      }

      if (developerName == null || developerName.isEmpty) {
        final altDeveloperRegex = RegExp(r'"publisher"\s*:\s*"([^"]+)"');
        final altDeveloperMatch = altDeveloperRegex.firstMatch(body);
        if (altDeveloperMatch != null) {
          developerName = altDeveloperMatch.group(1)?.trim();
        }
      }

      // Clean up names
      if (appName != null) {
        appName = appName
            .replaceAll(
                RegExp(r'\s*-\s*Apps on Google Play$', caseSensitive: false),
                '')
            .replaceAll(
                RegExp(r'\s*-\s*Google Play$', caseSensitive: false), '')
            .trim();
        appName = HtmlUtils.decodeHtmlEntities(appName);
      }

      if (developerName != null) {
        developerName = HtmlUtils.decodeHtmlEntities(developerName);
      }
    } catch (e) {
      // Ignore errors
    }

    return {
      'appName': appName,
      'developerName': developerName,
    };
  }

  Map<String, dynamic> _extractRatings(String body) {
    double? rating;
    int? ratingCount;
    String? downloadCount;

    try {
      // Extract rating
      final ratingPatterns = [
        RegExp(r'"ratingValue"\s*:\s*"?([0-9.]+)"?'),
        RegExp(r'"aggregateRating"[^}]*"ratingValue"\s*:\s*"?([0-9.]+)"?'),
        RegExp(r'star.*?([0-9.]+)', caseSensitive: false),
      ];

      for (final pattern in ratingPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          rating = double.tryParse(match.group(1)!);
          if (rating != null) break;
        }
      }

      // Extract rating count
      final ratingCountPatterns = [
        RegExp(r'"ratingCount"\s*:\s*"?([0-9,]+)"?'),
        RegExp(r'"reviewCount"\s*:\s*"?([0-9,]+)"?'),
        RegExp(r'([0-9,]+)\s*reviews?', caseSensitive: false),
        RegExp(r'([0-9,]+)\s*ratings?', caseSensitive: false),
      ];

      for (final pattern in ratingCountPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          final countStr = match.group(1)!.replaceAll(',', '');
          ratingCount = int.tryParse(countStr);
          if (ratingCount != null) break;
        }
      }

      // Extract download count
      final downloadPatterns = [
        RegExp(r'([0-9,]+\+?)\s*downloads?', caseSensitive: false),
        RegExp(r'([0-9,]+\+?)\s*installs?', caseSensitive: false),
        RegExp(r'"interactionCount"\s*:\s*"([0-9,]+\+?)"'),
      ];

      for (final pattern in downloadPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          downloadCount = match.group(1)!;
          break;
        }
      }

      // Alternative extraction
      if (rating == null || ratingCount == null) {
        final jsRatingPattern = RegExp(r'\[\s*([0-9.]+)\s*,\s*([0-9,]+)\s*\]');
        final jsMatches = jsRatingPattern.allMatches(body);

        for (final match in jsMatches) {
          final potentialRating = double.tryParse(match.group(1)!);
          final potentialCount =
              int.tryParse(match.group(2)!.replaceAll(',', ''));

          if (potentialRating != null &&
              potentialRating >= 1.0 &&
              potentialRating <= 5.0) {
            rating ??= potentialRating;
            ratingCount ??= potentialCount;
            break;
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return {
      'rating': rating,
      'ratingCount': ratingCount,
      'downloadCount': downloadCount,
    };
  }

  Map<String, String?> _extractAgeRatings(String body) {
    String? ageRating;
    String? contentRating;

    try {
      // Method 1: Content rating
      final contentRatingPatterns = [
        RegExp(r'"contentRating"\s*:\s*"([^"]+)"', caseSensitive: false),
        RegExp(r'"ratingValue"\s*:\s*"([^"]+)"', caseSensitive: false),
        RegExp(r'Rated for (\d+\+)', caseSensitive: false),
        RegExp(r'Ages (\d+\+)', caseSensitive: false),
      ];

      for (final pattern in contentRatingPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          contentRating = match.group(1)?.trim();
          break;
        }
      }

      // Method 2: ESRB/PEGI ratings
      final esrbPatterns = [
        RegExp(
            r'\b(Everyone|Everyone 10\+|Teen|Mature 17\+|Adults Only 18\+)\b',
            caseSensitive: false),
        RegExp(r'\b(E|E10\+|T|M|AO)\b'),
        RegExp(r'ESRB:\s*([^<\n]+)', caseSensitive: false),
      ];

      for (final pattern in esrbPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          ageRating = match.group(1)?.trim();
          break;
        }
      }

      // Method 3: Meta tags
      if (ageRating == null || ageRating.isEmpty) {
        final metaRatingPatterns = [
          RegExp(r'<meta[^>]*name=".*rating.*"[^>]*content="([^"]+)"',
              caseSensitive: false),
          RegExp(r'<meta[^>]*property=".*rating.*"[^>]*content="([^"]+)"',
              caseSensitive: false),
        ];

        for (final pattern in metaRatingPatterns) {
          final match = pattern.firstMatch(body);
          if (match != null) {
            final rating = match.group(1)?.trim();
            if (rating != null && rating.isNotEmpty) {
              ageRating = rating;
              break;
            }
          }
        }
      }

      // Method 4: Age indicators
      if (ageRating == null || ageRating.isEmpty) {
        final ageIndicatorPatterns = [
          RegExp(r'(\d+)\+', caseSensitive: false),
          RegExp(r'Ages (\d+) and up', caseSensitive: false),
          RegExp(r'Suitable for ages (\d+)\+', caseSensitive: false),
        ];

        for (final pattern in ageIndicatorPatterns) {
          final matches = pattern.allMatches(body);
          for (final match in matches) {
            final age = match.group(1);
            if (age != null) {
              final ageNum = int.tryParse(age);
              if (ageNum != null && ageNum >= 0 && ageNum <= 18) {
                ageRating = '$age+';
                break;
              }
            }
          }
          if (ageRating != null) break;
        }
      }

      // Method 5: JavaScript data
      if (ageRating == null || ageRating.isEmpty) {
        final jsRatingPattern = RegExp(r'"contentRating":\s*"([^"]+)"');
        final jsMatch = jsRatingPattern.firstMatch(body);
        if (jsMatch != null) {
          ageRating = jsMatch.group(1)?.trim();
        }
      }

      // Set default content rating if not found
      if (contentRating == null || contentRating.isEmpty) {
        contentRating = ageRating;
      }

      // Clean up ratings
      if (ageRating != null) {
        ageRating = ageRating
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (ageRating.isEmpty) ageRating = null;
      }

      if (contentRating != null) {
        contentRating = contentRating
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (contentRating.isEmpty) contentRating = null;
      }
    } catch (e) {
      // Ignore errors
    }

    return {
      'ageRating': ageRating,
      'contentRating': contentRating,
    };
  }

  DateTime? _extractLastUpdateDate(String body, String? playStoreCountry) {
    DateTime? lastUpdateDate;
    try {
      final currentCountry = playStoreCountry ?? 'en_US';
      final countryCode = currentCountry.split('_')[0];

      // Method 1: Structured data
      final structuredDataRegex = RegExp(r'"datePublished":"([^"]+)"');
      final structuredMatch = structuredDataRegex.firstMatch(body);

      if (structuredMatch != null) {
        try {
          lastUpdateDate = DateTime.parse(structuredMatch.group(1)!);
        } catch (e) {
          // Ignore error
        }
      }

      // Method 2: JavaScript data
      if (lastUpdateDate == null) {
        final jsDataPatterns = [
          RegExp(r'\["Updated",.*?"([^"]+)"\]'),
          RegExp(r'\["Diperbarui",.*?"([^"]+)"\]'), // Indonesian
          RegExp(r'"dateModified":"([^"]+)"'),
          RegExp(r'"lastModified":"([^"]+)"'),
        ];

        for (final pattern in jsDataPatterns) {
          final jsMatch = pattern.firstMatch(body);
          if (jsMatch != null) {
            try {
              final dateStr = jsMatch.group(1)!;
              lastUpdateDate =
                  DateUtil.parseMultiLanguageDate(dateStr, countryCode);
              break;
            } catch (e) {
              continue;
            }
          }
        }
      }

      // Method 3: HTML patterns
      if (lastUpdateDate == null) {
        final updatePatterns = [
          RegExp(r'Updated on ([^<]+)', caseSensitive: false),
          RegExp(r'Last updated ([^<]+)', caseSensitive: false),
          RegExp(r'Diperbarui pada ([^<]+)', caseSensitive: false),
          RegExp(r'Terakhir diperbarui ([^<]+)', caseSensitive: false),
          RegExp(r'"lastModified":"([^"]+)"'),
          RegExp(r'"dateModified":"([^"]+)"'),
        ];

        for (final pattern in updatePatterns) {
          final match = pattern.firstMatch(body);
          if (match != null) {
            try {
              final dateStr = match.group(1)!.trim();
              final cleanDateStr = dateStr
                  .replaceAll(RegExp(r'<[^>]*>'), '')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
              lastUpdateDate =
                  DateUtil.parseMultiLanguageDate(cleanDateStr, countryCode);
              break;
            } catch (e) {
              continue;
            }
          }
        }
      }

      // Method 4: Fallback patterns
      if (lastUpdateDate == null) {
        final englishPattern = RegExp(
            r'(\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b)');
        final indonesianPattern = RegExp(
            r'(\b(?:\d{1,2}\s+(?:Jan|Feb|Mar|Apr|Mei|Jun|Jul|Ags|Sep|Okt|Nov|Des|Januari|Februari|Maret|April|Juni|Juli|Agustus|September|Oktober|November|Desember)[a-z]*\s+\d{4})\b)',
            caseSensitive: false);

        final patterns = countryCode.toLowerCase() == 'id'
            ? [indonesianPattern, englishPattern]
            : [englishPattern, indonesianPattern];

        for (final pattern in patterns) {
          final fallbackMatch = pattern.firstMatch(body);
          if (fallbackMatch != null) {
            try {
              final dateStr = fallbackMatch.group(1)!;
              lastUpdateDate =
                  DateUtil.parseMultiLanguageDate(dateStr, countryCode);
              break;
            } catch (e) {
              continue;
            }
          }
        }
      }

      // Method 5: Extreme fallback
      if (lastUpdateDate == null) {
        final datePattern = RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4})');
        final dateMatch = datePattern.firstMatch(body);

        if (dateMatch != null) {
          try {
            final dateStr = dateMatch.group(1)!;
            if (countryCode.toLowerCase() == 'id') {
              lastUpdateDate = DateFormat('dd/MM/yyyy').parse(dateStr);
            } else {
              lastUpdateDate = DateFormat('MM/dd/yyyy').parse(dateStr);
            }
          } catch (e) {
            // Ignore error
          }
        }
      }
    } catch (e) {
      // Ignore error
    }

    return lastUpdateDate;
  }
}
