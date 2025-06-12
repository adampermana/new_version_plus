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
