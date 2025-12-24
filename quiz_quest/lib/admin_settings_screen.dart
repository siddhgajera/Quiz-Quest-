import 'package:flutter/material.dart';
import 'services/config_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackup = true;
  bool _maintenanceMode = false;
  int _questionsPerQuiz = 5;
  int _timePerQuestion = 30;

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();
  }

  Future<void> _loadInitialConfig() async {
    try {
      final value = await ConfigService().getQuestionsPerQuiz(fallback: _questionsPerQuiz);
      if (!mounted) return;
      setState(() {
        _questionsPerQuiz = value;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: Colors.blue[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('App Settings'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable push notifications'),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_notificationsEnabled
                            ? 'Notifications Enabled'
                            : 'Notifications Disabled'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Auto Backup'),
                  subtitle: const Text('Automatically backup data daily'),
                  value: _autoBackup,
                  onChanged: (val) {
                    setState(() {
                      _autoBackup = val;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Maintenance Mode'),
                  subtitle: const Text('Block user access for maintenance'),
                  value: _maintenanceMode,
                  onChanged: (val) {
                    setState(() {
                      _maintenanceMode = val;
                    });
                    _showMaintenanceModeDialog(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Quiz Settings'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Questions per Quiz'),
                  subtitle: Text('Current: $_questionsPerQuiz questions'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showNumberPickerDialog(
                      'Questions per Quiz',
                      _questionsPerQuiz,
                      1,
                      20,
                          (value) async {
                        setState(() {
                          _questionsPerQuiz = value;
                        });
                        // Persist to remote config
                        try {
                          await ConfigService().setQuestionsPerQuiz(value);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Questions per quiz set to $value'), duration: const Duration(seconds: 1)),
                          );
                        } catch (_) {}
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Time per Question'),
                  subtitle: Text('Current: $_timePerQuestion seconds'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showNumberPickerDialog(
                      'Time per Question (seconds)',
                      _timePerQuestion,
                      10,
                      120,
                          (value) {
                        setState(() {
                          _timePerQuestion = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup, color: Colors.blue),
                  title: const Text('Backup Database'),
                  subtitle: const Text('Create a backup of all data'),
                  onTap: () {
                    _showBackupDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: const Text('Restore Database'),
                  subtitle: const Text('Restore from backup file'),
                  onTap: () {
                    _showRestoreDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.clear_all, color: Colors.blue),
                  title: const Text('Clear All Data'),
                  subtitle: const Text(
                      'WARNING: This will delete everything'),
                  onTap: () {
                    _showClearDataDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('System Information'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Database Size'),
                  subtitle: const Text('2.4 MB'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Total Users'),
                  subtitle: const Text('1,250 users'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.quiz),
                  title: const Text('Total Questions'),
                  subtitle: const Text('240 questions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Admin Actions'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.send, color: Colors.blue),
                  title: const Text('Send Notification'),
                  subtitle: const Text('Send push notification to all users'),
                  onTap: () {
                    _showSendNotificationDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics, color: Colors.green),
                  title: const Text('Generate Report'),
                  subtitle: const Text('Create usage and statistics report'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Report generation feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  void _showMaintenanceModeDialog(bool enabled) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(enabled ? 'Enable Maintenance Mode' : 'Disable Maintenance Mode'),
          content: Text(enabled
              ? 'This will prevent users from accessing the app. Continue?'
              : 'Users will be able to access the app again. Continue?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _maintenanceMode = !enabled;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(enabled ? 'Maintenance mode enabled' : 'Maintenance mode disabled'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showNumberPickerDialog(
      String title, int currentValue, int min, int max, Function(int) onChanged) {
    int selectedValue = currentValue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select value: $selectedValue'),
                  Slider(
                    value: selectedValue.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedValue = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    onChanged(selectedValue);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup Database'),
          content: const Text('This will create a backup of all app data. Continue?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Backup'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup completed successfully!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore Database'),
          content: const Text(
              'This will restore data from backup file. Current data will be overwritten. Continue?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Restore'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database restored successfully!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
              'WARNING: This will permanently delete all users, questions, and scores. This action cannot be undone!'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('DELETE ALL', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showSendNotificationDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification sent to all users!')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
