import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Version Plus Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _versionStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    checkNewVersion();
  }

  Future<void> checkNewVersion() async {
    final newVersion = NewVersionPlus(
      androidId: 'com.mobile.legends', // Ganti dengan package ID milikmu
      iOSId:
          'com.your.ios.id', // Optional, kalau kamu juga publish ke App Store
    );

    final status = await newVersion.getVersionStatus();
    if (status == null) {
      setState(() => _versionStatus = 'Gagal mengambil versi terbaru');
      return;
    }

    setState(() {
      _versionStatus = '''
Current Version: ${status.localVersion}
Store Version: ${status.storeVersion}
Can Update: ${status.canUpdate}
RELEASE UPDATE: ${status.lastUpdateDate}

Release Notes: ${status.releaseNotes ?? 'Tidak ada'}
''';
    });

    if (status.canUpdate) {
      debugPrint('==== ${status.lastUpdateDate} data lastUpdate Info Aplikasi');

      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: 'Update Tersedia',
        dialogText:
            'Versi terbaru ${status.storeVersion} sudah tersedia.\n\n${status.releaseNotes ?? ''}',
        updateButtonText: 'Update Sekarang',
        dismissButtonText: 'Nanti',
        dismissAction: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Versi Aplikasi'),
      ),
      body: Center(
        child: Text(_versionStatus),
      ),
    );
  }
}
