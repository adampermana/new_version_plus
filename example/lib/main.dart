// import 'package:example/cache_images.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _currentVersion = '-',
      _storeVersion = '-',
      _lastUpdateDate = '-',
      _releaseNotes = '-',
      _nameApk = '-',
      _nameDevelop = '-';

  String? _imageApp;

  bool _canUpdate = false, _isLoading = true;

  @override
  void initState() {
    super.initState();
    checkNewVersion();
  }

  Future<void> checkNewVersion() async {
    try {
      final newVersion = NewVersionPlus(
        androidId: 'com.solu.mobsen', // Ganti dengan package ID milikmu
        iOSId:
            'com.your.ios.id', // Optional, kalau kamu juga publish ke App Store
        androidHtmlReleaseNotes:
            true, // Optional, untuk menampilkan catatan rilis HTML
        androidPlayStoreCountry: 'id',
        // locale: AppLocale.id,
      );

      final status = await newVersion.getVersionStatus();

      if (status == null) {
        setState(() {
          _isLoading = false;
          _currentVersion = 'Error';
          _storeVersion = 'Gagal mengambil versi terbaru';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _currentVersion = status.localVersion;
        _storeVersion = status.storeVersion;
        _canUpdate = status.canUpdate;
        _lastUpdateDate = status.lastUpdateDate != null
            ? DateFormat('dd MMMM yyyy').format(status.lastUpdateDate!)
            : 'Tidak tersedia';
        _releaseNotes = status.releaseNotes ?? 'Tidak ada catatan rilis';
        _nameApk = status.appName ?? 'Tidak ada Name APk';
        _nameDevelop = status.developerName ?? 'Tidak ada Name DEv';
        _nameDevelop = status.appIconUrl ?? '';
        _imageApp = status.appIconUrl ?? ''; // Ini yang diperbaiki
        debugPrint('===== Nama $_nameDevelop, _nameApk');
        debugPrint('===== Image $_imageApp, imageAPp');
      });

      // Show dialog automatically if update is available
      if (status.canUpdate && mounted) {
        _showUpdateDialog(newVersion, status);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentVersion = 'Error';
        _storeVersion = 'Terjadi kesalahan: $e';
      });
    }
  }

  void _showUpdateDialog(NewVersionPlus newVersion, VersionStatus status) {
    newVersion.showUpdateDialog(
      context: context,
      versionStatus: status,
      dialogTitle: 'Update Tersedia',
      dialogText: 'Versi terbaru ${status.storeVersion} sudah tersedia.',
      updateButtonText: 'Update Sekarang',
      dismissButtonText: 'Nanti',
      // showReleaseNotes: true,
      dismissAction: () {
        Navigator.of(context).pop();
      },
    );
  }

  void _checkManually() {
    setState(() {
      _isLoading = true;
    });
    checkNewVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Versi Aplikasi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengecek versi aplikasi...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Versi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Versi Saat Ini:', _currentVersion),
                          const SizedBox(height: 8),
                          _buildInfoRow('Versi di Store:', _storeVersion),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Status Update:',
                            _canUpdate ? 'Tersedia Update' : 'Versi Terkini',
                            valueColor:
                                _canUpdate ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                              'Tanggal Update Terakhir:', _lastUpdateDate),
                          _buildInfoRow('Name APK:', _nameApk),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const SizedBox(
                                width: 140,
                                child: Text(
                                  'Image',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              _imageApp != null
                                  ? Image.network(
                                      _imageApp!,
                                      width: 50,
                                      height: 50,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.error),
                                    )
                                  : const Text('Tidak ada gambar'),
                            ],
                          )
                          // _buildInfoRow('Name Develop:', _nameDevelop),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Rilis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _releaseNotes,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkManually,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Cek Ulang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_canUpdate) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newVersion = NewVersionPlus(
                            androidId: 'com.g4sindonesia.gracia',
                            iOSId: 'com.your.ios.id',
                          );
                          final status = await newVersion.getVersionStatus();
                          if (status != null && mounted) {
                            _showUpdateDialog(newVersion, status);
                          }
                        },
                        icon: const Icon(Icons.system_update),
                        label: const Text('Tampilkan Dialog Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
