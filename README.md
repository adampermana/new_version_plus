# 🚀 New Version Plus Plugin

Enhanced fork of the original [`new_version`](https://github.com/CodesFirst/new_version) plugin by **Peter Herrera**, with additional features and ongoing maintenance by **Adam Permana**.

---

## 📌 Project Status

| Attribute           | Information                                   |
|---------------------|-----------------------------------------------|
| Original Author     | Peter Herrera ([@CodesFirst](https://github.com/CodesFirst)) |
| Current Maintainer  | Adam Permana ([@adampermana](https://github.com/adampermana)) |
| Original Repository | [github.com/CodesFirst/new_version](https://github.com/CodesFirst/new_version) |
| Fork Reason         | Original repository is no longer maintained  |

---

## 🌟 Enhanced Features

✅ **Extended Metadata Support**
- App icons  
- Developer information  
- Ratings and review counts  
- Download statistics  
- Age/content ratings  

✅ **Improved Localization**
- Better date parsing (international support)  
- Multilingual release note support  

✅ **Advanced Release Notes**
- HTML formatting  
- Cleaned and readable text  

✅ **Additional Platform Support**
- Custom country codes (Play Store & App Store)  
- Enhanced error handling  

---

## 📦 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  new_version_plus:
    git:
      url: https://github.com/adampermana/new_version_plus.git
      ref: main
```

---

## 🛠️ Basic Usage

### 1. Initialize the Plugin

```dart
final newVersion = NewVersionPlus(
  androidId: 'com.example.app',          // Optional
  iOSId: 'com.example.app',              // Optional
  androidPlayStoreCountry: 'id',         // Optional
  iOSAppStoreCountry: 'us',              // Optional
);
```

### 2. Check for Updates (Simple)

```dart
newVersion.showAlertIfNecessary(context: context);
```

### 3. Advanced Usage with Custom Dialog

```dart
final status = await newVersion.getVersionStatus();

if (status != null && status.canUpdate) {
  newVersion.showUpdateDialog(
    context: context,
    versionStatus: status,
    dialogTitle: 'Update Available',
    dialogText: 'New version ${status.storeVersion} is available!',
    updateButtonText: 'Update Now',
    dismissButtonText: 'Later',
  );
}
```

---

## 📊 `VersionStatus` Properties

| Property         | Type        | Description                         |
|------------------|-------------|-------------------------------------|
| `localVersion`   | `String`    | Current app version                 |
| `storeVersion`   | `String`    | Latest version on store             |
| `appStoreLink`   | `String`    | URL to the app store                |
| `releaseNotes`   | `String?`   | HTML-formatted release notes        |
| `lastUpdateDate` | `DateTime?` | Date of the latest update           |
| `appName`        | `String?`   | Name of the app                     |
| `developerName`  | `String?`   | Publisher/Developer name            |
| `appIconUrl`     | `String?`   | Icon URL from the store             |
| `ratingApp`      | `double?`   | Rating (1.0 - 5.0)                  |
| `ratingCount`    | `int?`      | Number of user ratings              |
| `downloadCount`  | `String?`   | Total downloads (Play Store only)   |
| `ageRating`      | `String?`   | Age restriction (App Store)         |
| `contentRating`  | `String?`   | Content description (Play Store)    |

---

## 🌍 Country Code Support

For region-specific stores, you can customize:

```dart
NewVersionPlus(
  androidPlayStoreCountry: 'id', // Example: Indonesia
  iOSAppStoreCountry: 'jp',     // Example: Japan
);
```

---

## 🎨 Customization Options

```dart
showUpdateDialog(
  context: context,
  versionStatus: status,
  dialogTitle: 'Custom Title',
  dialogText: 'Custom message',
  updateButtonText: 'Upgrade',
  dismissButtonText: 'Not Now',
  allowDismissal: false,
  launchModeVersion: LaunchModeVersion.external, // Open store in browser
);
```

---

## 📸 Screenshots

> _(Add screenshots here if available for illustration)_

![Screenshots](screenshots/both.png)
---

## 🤝 Contribution

Contributions are welcome! You can help by:
- Reporting bugs
- Suggesting features
- Improving documentation
- Creating pull requests

---

## 📜 License

This project is licensed under the **MIT License**, same as the original.