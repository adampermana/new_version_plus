class StringUtils {
  /// This function attempts to clean local version strings so they match the MAJOR.MINOR.PATCH
  /// versioning pattern, so they can be properly compared with the store version.
  static String getCleanVersion(String version) =>
      RegExp(r'\d+(\.\d+)?(\.\d+)?').stringMatch(version) ?? '0.0.0';
}
