import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/src/launch_mode_version.dart';
import 'package:new_version_plus/src/models/version_status.dart';
import 'package:new_version_plus/src/services/android_store_service.dart';
import 'package:new_version_plus/src/services/ios_store_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  /// Support Locale
  final String? iOSAppStoreCountry;

  /// Only affects Android Play Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  /// see https://www.ibm.com/docs/en/radfws/9.6.1?topic=overview-locales-code-pages-supported
  /// Support Locale
  final String? androidPlayStoreCountry;

  /// An optional value that will force the plugin to always return [forceAppVersion]
  /// as the value of [storeVersion]. This can be useful to test the plugin's behavior
  /// before publishng a new version.
  final String? forceAppVersion;

  ///Html original body request
  final bool androidHtmlReleaseNotes;

  NewVersionPlus({
    this.androidId,
    this.iOSId,
    this.iOSAppStoreCountry,
    this.forceAppVersion,
    this.androidPlayStoreCountry,
    this.androidHtmlReleaseNotes = false,
  });

  /// This checks the version status and returns the information. This is useful
  /// if you want to display a custom alert, or use the information in a different
  /// way.
  Future<VersionStatus?> getVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isIOS) {
      return IosStoreService(
        iOSId: iOSId,
        iOSAppStoreCountry: iOSAppStoreCountry,
        forceAppVersion: forceAppVersion,
      ).getStoreVersion(packageInfo);
    } else if (Platform.isAndroid) {
      return AndroidStoreService(
        androidId: androidId,
        androidPlayStoreCountry: androidPlayStoreCountry,
        forceAppVersion: forceAppVersion,
        androidHtmlReleaseNotes: androidHtmlReleaseNotes,
      ).getStoreVersion(packageInfo);
    } else {
      debugPrint(
          'The target platform "${Platform.operatingSystem}" is not yet supported by this package.');
      return null;
    }
  }

  /// This checks the version status, then displays a platform-specific alert
  /// with buttons to dismiss the update alert, or go to the app store.
  Future<void> showAlertIfNecessary({
    required BuildContext context,
    LaunchModeVersion launchModeVersion = LaunchModeVersion.normal,
  }) async {
    final VersionStatus? versionStatus = await getVersionStatus();
    if (!context.mounted) return;
    if (versionStatus != null && versionStatus.canUpdate) {
      showUpdateDialog(
        context: context,
        versionStatus: versionStatus,
        launchModeVersion: launchModeVersion,
      );
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
                launchMode: launchMode,
              ),
              child: updateButtonTextWidget,
            )
          : CupertinoDialogAction(
              onPressed: () => _updateActionFunc(
                allowDismissal: allowDismissal,
                context: context,
                appStoreLink: versionStatus.appStoreLink,
                launchMode: launchMode,
              ),
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
                onPressed: dismissAction,
                child: dismissButtonTextWidget,
              )
            : CupertinoDialogAction(
                onPressed: dismissAction,
                child: dismissButtonTextWidget,
              ),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: allowDismissal,
      builder: (BuildContext context) {
        if (Platform.isAndroid) {
          return PopScope(
            canPop: allowDismissal,
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

  /// Update action fun
  /// show modal
  void _updateActionFunc({
    required String appStoreLink,
    required bool allowDismissal,
    required BuildContext context,
    LaunchMode launchMode = LaunchMode.platformDefault,
  }) {
    launchAppStore(appStoreLink, launchMode: launchMode);
    if (allowDismissal) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Launches the Apple App Store or Google Play Store page for the app.
  Future<void> launchAppStore(
    String appStoreLink, {
    LaunchMode launchMode = LaunchMode.platformDefault,
  }) async {
    if (await canLaunchUrl(Uri.parse(appStoreLink))) {
      await launchUrl(Uri.parse(appStoreLink), mode: launchMode);
    } else {
      throw 'Could not launch appStoreLink';
    }
  }
}
