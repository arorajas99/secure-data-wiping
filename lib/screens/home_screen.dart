import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/wipe_service.dart';
import 'file_explorer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDisclaimerDialog();
    });
  }

  Future<void> _showDisclaimerDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Important Disclaimer'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: PERMANENT DATA DELETION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This application uses military-grade data wiping algorithms that will:\n\n'
                '• Permanently delete selected files and folders\n'
                '• Make data recovery IMPOSSIBLE\n'
                '• Overwrite data multiple times\n'
                '• Cannot be undone or reversed\n\n'
                'The developers are NOT responsible for any data loss. '
                'Please ensure you have backed up any important data before proceeding.\n\n'
                'By clicking "I Understand", you acknowledge:\n'
                '• You understand the risks\n'
                '• You accept full responsibility\n'
                '• You have necessary backups',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit app
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPermissions() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final hasPermission = await storageService.requestStoragePermissions();
    
    if (!hasPermission) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to scan and wipe files. '
          'Please grant the necessary permissions in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final wipeService = Provider.of<WipeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureWipe Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'SecureWipe Pro v1.0\n\n'
                    'Military-grade secure data wiping application.\n\n'
                    'WARNING: All wiping operations are permanent and cannot be reversed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Devices Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Storage Devices',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            await storageService.scanForStorageDevices();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (storageService.storageDevices.isEmpty)
                      const Center(
                        child: Text('No storage devices found'),
                      )
                    else
                      ...storageService.storageDevices.map(
                        (device) => ListTile(
                          leading: Icon(
                            device.type == StorageType.internal
                                ? Icons.phone_android
                                : device.type == StorageType.external
                                    ? Icons.sd_card
                                    : Icons.usb,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(device.name),
                          subtitle: Text(device.path),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FileExplorerScreen(
                                  initialPath: device.path,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Wipe Method Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Wipe Method',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...WipeMethod.values.map(
                      (method) => RadioListTile<WipeMethod>(
                        title: Text(
                          wipeService.getMethodDescription(method).split(' - ')[0],
                        ),
                        subtitle: Text(
                          wipeService.getMethodDescription(method).split(' - ')[1],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: method,
                        groupValue: wipeService.selectedMethod,
                        onChanged: (value) {
                          if (value != null) {
                            wipeService.setWipeMethod(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileExplorerScreen(
                                initialPath: '/storage/emulated/0',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse Files'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: wipeService.wipeResults.isEmpty
                            ? null
                            : () {
                                // Show certificates screen
                                Navigator.pushNamed(context, '/certificates');
                              },
                        icon: const Icon(Icons.description),
                        label: Text(
                          'View Certificates (${wipeService.wipeResults.length})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics
            if (wipeService.wipeResults.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Total Operations:',
                        wipeService.wipeResults.length.toString(),
                      ),
                      _buildStatRow(
                        'Successful:',
                        wipeService.wipeResults
                            .where((r) => r.success)
                            .length
                            .toString(),
                      ),
                      _buildStatRow(
                        'Failed:',
                        wipeService.wipeResults
                            .where((r) => !r.success)
                            .length
                            .toString(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
