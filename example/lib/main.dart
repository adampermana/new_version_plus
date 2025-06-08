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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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
  String _currentVersion = 'Loading...',
      _storeVersion = 'Loading...',
      _lastUpdateDate = 'Loading...',
      _releaseNotes = 'Loading...',
      _appName = 'Loading...',
      _developerName = 'Loading...',
      _downloadCount = 'Loading...',
      _ageRating = 'Loading...',
      _contentRating = 'Loading...';
  String? _appIconUrl;
  double? _appRating;
  int? _ratingCount;
  bool _canUpdate = false;
  bool _isLoading = false;
  bool _showAdvancedInfo = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    setState(() => _isLoading = true);

    try {
      final newVersion = NewVersionPlus(
        androidId: 'com.hamilton.app', // Replace with your package ID
        iOSId: 'com.your.ios.id', // Replace with your iOS app ID
        androidHtmlReleaseNotes: true,
        androidPlayStoreCountry: 'id',
      );

      final status = await newVersion.getVersionStatus();

      if (status == null) {
        _showError('Failed to fetch version info');
        return;
      }

      setState(() {
        _currentVersion = status.localVersion;
        _storeVersion = status.storeVersion;
        _canUpdate = status.canUpdate;
        _lastUpdateDate = status.lastUpdateDate != null
            ? DateFormat('dd MMMM yyyy').format(status.lastUpdateDate!)
            : 'Not available';
        _releaseNotes = status.releaseNotes ?? 'No release notes available';
        _appName = status.appName ?? 'Unknown app name';
        _developerName = status.developerName ?? 'Unknown developer';
        _appIconUrl = status.appIconUrl;
        _downloadCount = status.downloadCount ?? 'Not available';
        _appRating = status.ratingApp;
        _ratingCount = status.ratingCount;
        _ageRating = status.ageRating ?? 'Not rated';
        _contentRating = status.contentRating ?? 'Not rated';
        _isLoading = false;
      });

      if (status.canUpdate && mounted) {
        _showUpdateDialog(newVersion, status);
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _currentVersion = 'Error';
        _storeVersion = message;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showUpdateDialog(NewVersionPlus newVersion, VersionStatus status) {
    newVersion.showUpdateDialog(
      context: context,
      versionStatus: status,
      dialogTitle: 'Update Available',
      dialogText: 'A new version ${status.storeVersion} is available!',
      updateButtonText: 'Update Now',
      dismissButtonText: 'Later',
      dismissAction: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Version Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkVersion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_appIconUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _appIconUrl!,
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.android,
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            _appName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'by $_developerName',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildVersionRow(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Update Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Update Information',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Chip(
                                label: Text(
                                  _canUpdate
                                      ? 'Update Available'
                                      : 'Up to Date',
                                  style: TextStyle(
                                    color: _canUpdate
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                backgroundColor: _canUpdate
                                    ? Colors.orange
                                    : Colors.green.shade100,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoTile(
                            'Current Version',
                            _currentVersion,
                            Icons.verified_user_outlined,
                          ),
                          _buildInfoTile(
                            'Store Version',
                            _storeVersion,
                            Icons.store,
                          ),
                          _buildInfoTile(
                            'Last Updated',
                            _lastUpdateDate,
                            Icons.calendar_today,
                          ),
                          _buildInfoTile(
                            'Downloads',
                            _downloadCount,
                            Icons.download,
                          ),
                          _buildRatingInfo(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Release Notes Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Release Notes',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: Icon(
                                  _showAdvancedInfo
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onPressed: () => setState(() =>
                                    _showAdvancedInfo = !_showAdvancedInfo),
                              ),
                            ],
                          ),
                          if (_showAdvancedInfo) ...[
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildInfoTile(
                              'Age Rating',
                              _ageRating,
                              Icons.stars_sharp,
                            ),
                            _buildInfoTile(
                              'Content Rating',
                              _contentRating,
                              Icons.warning,
                            ),
                          ],
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            _releaseNotes,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_canUpdate)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.system_update),
                        label: const Text('Show Update Dialog'),
                        onPressed: () async {
                          final newVersion = NewVersionPlus(
                            androidId: 'com.hamilton.app',
                            iOSId: 'com.your.ios.id',
                          );
                          final status = await newVersion.getVersionStatus();
                          if (status != null && mounted) {
                            _showUpdateDialog(newVersion, status);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _checkVersion,
        tooltip: 'Check for updates',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildVersionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              'Current',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _currentVersion,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue,
                  ),
            ),
          ],
        ),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Column(
          children: [
            Text(
              'Latest',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _storeVersion,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _canUpdate ? Colors.orange : Colors.green,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.star, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (_appRating != null && _ratingCount != null)
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: index < _appRating!.floor()
                                ? Colors.amber
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_appRating!.toStringAsFixed(1)} (${NumberFormat.compact().format(_ratingCount)})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                else
                  Text(
                    'Not available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
