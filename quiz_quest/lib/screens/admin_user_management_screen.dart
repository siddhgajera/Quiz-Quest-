import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/admin_user_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  bool _checkingAccess = true;
  bool _isAdmin = false;
  String _error = '';
  String _statusFilter = 'all'; // all | active | inactive

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final provider = context.read<AdminUserProvider>();
      final ok = await provider.currentUserIsAdmin();
      if (!mounted) return;
      setState(() {
        _isAdmin = ok;
        _checkingAccess = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _checkingAccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminUserProvider>();
    final currentUser = provider.currentUser;

    if (_checkingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Users'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: Colors.blue[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error.isNotEmpty
                      ? _error
                      : 'You are not authorized to view this page. Admin role required.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[700],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              'Admin User Management',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: provider.streamAllUsers(limit: 1000),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This usually means you need proper admin permissions or Firestore security rules need to be configured.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          // Apply status filter
          final docs = allDocs.where((d) {
            final data = d.data();
            final isActive = (data['isActive'] ?? false) as bool;
            if (_statusFilter == 'active') return isActive;
            if (_statusFilter == 'inactive') return !isActive;
            return true;
          }).toList();
          docs.sort((a, b) {
            final an = (a.data()['name'] ?? '') as String;
            final bn = (b.data()['name'] ?? '') as String;
            return an.toLowerCase().compareTo(bn.toLowerCase());
          });

          final isWide = MediaQuery.of(context).size.width >= 800;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    _statusFilter == 'active'
                        ? 'No active users found'
                        : _statusFilter == 'inactive'
                        ? 'No inactive users found'
                        : 'No users found',
                  ),
                ],
              ),
            );
          }

          final activeCount = allDocs.where((d) => (d.data()['isActive'] ?? false) as bool).length;
          final totalCount = allDocs.length;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusFilterBar(activeCount: activeCount, totalCount: totalCount),
                const SizedBox(height: 8),
                _adminActionsBar(context, provider, activeCount, totalCount),
                const SizedBox(height: 8),
                Expanded(
                  child: isWide
                      ? _buildTable(context, provider, currentUser, docs)
                      : _buildList(context, provider, currentUser, docs),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusFilterBar({required int activeCount, required int totalCount}) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Active: $activeCount / $totalCount',
            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
          ),
        ),
        ChoiceChip(
          label: const Text('All'),
          selected: _statusFilter == 'all',
          selectedColor: Colors.blue.shade100,
          checkmarkColor: Colors.blue.shade800,
          onSelected: (val) => setState(() => _statusFilter = 'all'),
        ),
        ChoiceChip(
          label: const Text('Active'),
          selected: _statusFilter == 'active',
          selectedColor: Colors.blue.shade100,
          checkmarkColor: Colors.blue.shade800,
          onSelected: (val) => setState(() => _statusFilter = 'active'),
        ),
        ChoiceChip(
          label: const Text('Inactive'),
          selected: _statusFilter == 'inactive',
          selectedColor: Colors.blue.shade100,
          checkmarkColor: Colors.blue.shade800,
          onSelected: (val) => setState(() => _statusFilter = 'inactive'),
        ),
      ],
    );
  }

  Widget _adminActionsBar(BuildContext context, AdminUserProvider provider, int activeCount, int totalCount) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Admin Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fix user status issues: If users appear active but should be inactive, use these tools.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _bulkUpdateInactiveUsers(context, provider),
                  icon: const Icon(Icons.update, size: 16),
                  label: const Text('Auto-Fix Inactive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _setAllUsersInactive(context, provider),
                  icon: const Icon(Icons.pause_circle, size: 16),
                  label: const Text('Set All Inactive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showBulkUpdateInfo(context),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Help'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, AdminUserProvider provider, User? currentUser,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final theme = Theme.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Promote/Demote')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Last Login')),
            DataColumn(label: Text('Actions')),
          ],
          rows: docs.map((d) {
            final data = d.data();
            final uid = d.id;
            final name = (data['name'] ?? 'User') as String;
            final email = (data['email'] ?? '') as String;
            String role = 'user';
            if (data['role'] != null && data['role'].toString().isNotEmpty) {
              role = data['role'].toString().toLowerCase();
            } else if (data['isAdmin'] == true) {
              role = 'admin';
            }
            if (email.toLowerCase() == 'siddh@gmail.com') {
              role = 'admin';
            }
            final isActive = (data['isActive'] ?? false) as bool;
            final lastLogin = (data['lastLoginAt']);
            final isSelf = currentUser?.uid == uid;

            return DataRow(cells: [
              DataCell(Text(name)),
              DataCell(Text(email)),
              DataCell(_roleChip(role, theme)),
              DataCell(_roleToggleButton(context, provider, uid, role, isSelf)),
              DataCell(_statusSwitch(uid, isActive, isSelf, provider)),
              DataCell(Text(_formatTimestamp(lastLogin))),
              DataCell(_actionButtons(context, provider, uid, role, isSelf)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AdminUserProvider provider, User? currentUser,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final d = docs[index];
        final data = d.data();
        final uid = d.id;
        final name = (data['name'] ?? 'User') as String;
        final email = (data['email'] ?? '') as String;
        String role = 'user';
        if (data['role'] != null && data['role'].toString().isNotEmpty) {
          role = data['role'].toString().toLowerCase();
        } else if (data['isAdmin'] == true) {
          role = 'admin';
        }
        if (email.toLowerCase() == 'siddh@gmail.com') {
          role = 'admin';
        }
        final isActive = (data['isActive'] ?? false) as bool;
        final lastLogin = (data['lastLoginAt']);
        final isSelf = currentUser?.uid == uid;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: role == 'admin' ? Colors.blue.shade100 : Colors.grey.shade200,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: role == 'admin' ? Colors.blue.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _roleChip(role, theme),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildMobileDetailRow('Status', isActive ? 'Active' : 'Inactive',
                          isActive ? Colors.green : Colors.orange),
                      const SizedBox(height: 8),
                      _buildMobileDetailRow('Last Login', _formatTimestamp(lastLogin), Colors.grey.shade600),
                      const SizedBox(height: 8),
                      _buildMobileDetailRow('User ID', uid, Colors.grey.shade600),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _mobileRoleToggleButton(context, provider, uid, role, isSelf),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _mobileStatusToggleButton(context, provider, uid, isActive, isSelf),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showUserDetailsDialog(context, data, uid),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(Colors.blue.shade700),
                          side: MaterialStateProperty.all(
                            BorderSide(color: Colors.blue.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSelf ? null : () => _showDeleteConfirmation(context, provider, uid, name),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(
                            isSelf ? Colors.grey : Colors.blue.shade700,
                          ),
                          side: MaterialStateProperty.all(
                            BorderSide(color: isSelf ? Colors.grey.shade300 : Colors.blue.shade300),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FIXED: This widget is now flexible to prevent overflows with long text.
  Widget _buildMobileDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16), // Added spacing for clarity
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Mobile-optimized role toggle button
  Widget _mobileRoleToggleButton(BuildContext context, AdminUserProvider provider, String uid, String role, bool isSelf) {
    final isAdmin = role == 'admin';
    return ElevatedButton.icon(
      onPressed: isSelf
          ? null
          : () async {
        final confirm = await _confirm(
          context,
          title: isAdmin ? 'Demote Admin' : 'Promote to Admin',
          message: isAdmin
              ? 'Are you sure you want to demote this admin to a user?'
              : 'Are you sure you want to promote this user to admin?',
          confirmText: isAdmin ? 'Demote' : 'Promote',
        );
        if (confirm != true) return;
        try {
          await provider.toggleRole(uid: uid, currentRole: role);
          _snack(context, 'Role updated successfully', Colors.green.shade700);
        } catch (e) {
          _snack(context, e.toString(), Colors.blue.shade700);
        }
      },
      icon: Icon(
        isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
        size: 16,
      ),
      label: Text(isAdmin ? 'Demote' : 'Promote'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAdmin ? Colors.orange.shade600 : Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // Mobile-optimized status toggle button
  Widget _mobileStatusToggleButton(BuildContext context, AdminUserProvider provider, String uid, bool isActive, bool isSelf) {
    return ElevatedButton.icon(
      onPressed: isSelf
          ? null
          : () async {
        try {
          await provider.toggleActive(uid: uid, isActive: !isActive);
          _snack(context, isActive ? 'User deactivated' : 'User activated', Colors.green.shade700);
        } catch (e) {
          _snack(context, e.toString(), Colors.blue.shade700);
        }
      },
      icon: Icon(
        isActive ? Icons.pause : Icons.play_arrow,
        size: 16,
      ),
      label: Text(isActive ? 'Deactivate' : 'Activate'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.orange.shade600 : Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // Show user details dialog with real-time data
  void _showUserDetailsDialog(BuildContext context, Map<String, dynamic> data, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['name'] ?? 'User'} Details'),
        content: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final userData = snapshot.data?.data() as Map<String, dynamic>? ?? data;
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogDetailRow('Name', userData['name'] ?? 'N/A'),
                  _buildDialogDetailRow('Email', userData['email'] ?? 'N/A'),
                  _buildDialogDetailRow('User ID', uid),
                  _buildDialogDetailRow('Role', userData['role'] ?? (userData['isAdmin'] == true ? 'admin' : 'user')),
                  _buildDialogDetailRow('Status', (userData['isActive'] ?? false) ? 'Active' : 'Inactive'),
                  const Divider(),
                  _buildDialogDetailRow('Quizzes Completed', (userData['quizzesCompleted'] ?? 0).toString()),
                  _buildDialogDetailRow('Total Score', (userData['totalScore'] ?? 0).toString()),
                  _buildDialogDetailRow('Average Score', (userData['averageScore'] ?? 0).toString()),
                  _buildDialogDetailRow('Highest Score', (userData['highestScore'] ?? 0).toString()),
                  const Divider(),
                  _buildDialogDetailRow('Member Since', _formatTimestamp(userData['createdAt'])),
                  _buildDialogDetailRow('Last Active', _formatTimestamp(userData['lastActive'])),
                  _buildDialogDetailRow('Last Login', _formatTimestamp(userData['lastLoginAt'])),
                  _buildDialogDetailRow('Email Verified', (userData['isEmailVerified'] ?? false) ? 'Yes' : 'No'),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Show delete confirmation
  void _showDeleteConfirmation(BuildContext context, AdminUserProvider provider, String uid, String name) async {
    final confirm = await _confirm(
      context,
      title: 'Delete User',
      message: 'This will permanently delete $name from Auth and Firestore. This action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
    );
    if (confirm != true) return;
    try {
      await provider.removeUserCompletely(uid: uid);
      _snack(context, 'User deleted successfully', Colors.green.shade700);
    } catch (e) {
      _snack(context, 'Delete failed: $e', Colors.blue.shade700);
    }
  }

  Widget _roleChip(String role, ThemeData theme) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.blue.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAdmin ? Icons.security : Icons.person_outline, size: 16, color: isAdmin ? Colors.blue.shade700 : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(isAdmin ? 'Admin' : 'User', style: TextStyle(color: isAdmin ? Colors.blue.shade700 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _statusSwitch(String uid, bool isActive, bool isSelf, AdminUserProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.power_settings_new, size: 16),
        Switch(
          value: isActive,
          onChanged: isSelf
              ? null
              : (val) async {
            try {
              await provider.toggleActive(uid: uid, isActive: val);
              _snack(context, val ? 'User activated' : 'User deactivated', Colors.green.shade700);
            } catch (e) {
              _snack(context, e.toString(), Colors.blue.shade700);
            }
          },
        ),
      ],
    );
  }

  Widget _roleToggleButton(BuildContext context, AdminUserProvider provider, String uid, String role, bool isSelf) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: isSelf
            ? null
            : () async {
          final confirm = await _confirm(
            context,
            title: isAdmin ? 'Demote Admin' : 'Promote to Admin',
            message: isAdmin
                ? 'Are you sure you want to demote this admin to a user?'
                : 'Are you sure you want to promote this user to admin?',
            confirmText: isAdmin ? 'Demote' : 'Promote',
          );
          if (confirm != true) return;
          try {
            await provider.toggleRole(uid: uid, currentRole: role);
            _snack(context, 'Role updated successfully', Colors.green.shade700);
          } catch (e) {
            _snack(context, e.toString(), Colors.blue.shade700);
          }
        },
        icon: Icon(
          isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
          size: 16,
        ),
        label: Text(
          isAdmin ? 'Demote' : 'Promote',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAdmin ? Colors.orange.shade600 : Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(80, 32),
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context, AdminUserProvider provider, String uid, String role, bool isSelf) {
    return Wrap(
      spacing: 8,
      children: [
        Tooltip(
          message: role == 'admin' ? 'Demote to User' : 'Promote to Admin',
          child: IconButton(
            icon: Icon(role == 'admin' ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.blue[700]),
            onPressed: isSelf
                ? null
                : () async {
              final confirm = await _confirm(
                context,
                title: role == 'admin' ? 'Demote Admin' : 'Promote to Admin',
                message: role == 'admin'
                    ? 'Are you sure you want to demote this admin to a user?'
                    : 'Are you sure you want to promote this user to admin?',
                confirmText: role == 'admin' ? 'Demote' : 'Promote',
              );
              if (confirm != true) return;
              try {
                await provider.toggleRole(uid: uid, currentRole: role);
                _snack(context, 'Role updated', Colors.green.shade700);
              } catch (e) {
                _snack(context, e.toString(), Colors.blue.shade700);
              }
            },
          ),
        ),
        Tooltip(
          message: 'Remove user',
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.blue),
            onPressed: isSelf
                ? null
                : () async {
              final confirm = await _confirm(
                context,
                title: 'Delete User',
                message: 'This will permanently delete the user from Auth and Firestore. This action cannot be undone.',
                confirmText: 'Delete',
                isDanger: true,
              );
              if (confirm != true) return;
              try {
                await provider.removeUserCompletely(uid: uid);
                _snack(context, 'User deleted', Colors.green.shade700);
              } catch (e) {
                _snack(context, 'Delete failed: $e', Colors.blue.shade700);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _confirm(BuildContext context, {required String title, required String message, required String confirmText, bool isDanger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDanger ? Colors.blue.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return DateFormat.yMMMd().add_jm().format(dt);
    }
    if (ts is DateTime) {
      return DateFormat.yMMMd().add_jm().format(ts);
    }
    return '-';
  }

  // Bulk update inactive users based on last activity
  Future<void> _bulkUpdateInactiveUsers(BuildContext context, AdminUserProvider provider) async {
    final confirm = await _confirm(
      context,
      title: 'Auto-Fix Inactive Users',
      message: 'This will set users to inactive if they haven\'t been active in the last 24 hours. Your account will remain active. Continue?',
      confirmText: 'Fix Status',
    );
    if (confirm != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Updating user status...'),
            ],
          ),
        ),
      );

      final result = await provider.bulkUpdateInactiveUsers(inactiveHours: 24);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true) {
        _snack(context, result['message'], Colors.green.shade700);
      } else {
        _snack(context, result['message'], Colors.blue.shade700);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _snack(context, 'Error: $e', Colors.blue.shade700);
    }
  }

  // Set all users except current admin to inactive
  Future<void> _setAllUsersInactive(BuildContext context, AdminUserProvider provider) async {
    final confirm = await _confirm(
      context,
      title: 'Set All Users Inactive',
      message: 'This will set ALL users (except you) to inactive status. This is useful for testing or resetting user status. Continue?',
      confirmText: 'Set Inactive',
      isDanger: true,
    );
    if (confirm != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Setting users inactive...'),
            ],
          ),
        ),
      );

      final result = await provider.setAllUsersInactive();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true) {
        _snack(context, result['message'], Colors.green.shade700);
      } else {
        _snack(context, result['message'], Colors.blue.shade700);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _snack(context, 'Error: $e', Colors.blue.shade700);
    }
  }

  // Show help information about bulk update features
  void _showBulkUpdateInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Update Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'User Status Issue:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Users are automatically set to "active" when they log in and should be set to "inactive" when they log out or close the app. However, if users don\'t properly log out, they may remain active.',
              ),
              SizedBox(height: 16),
              Text(
                'Auto-Fix Inactive:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Sets users to inactive if they haven\'t been active in 24+ hours\n'
                '• Uses lastLoginAt and lastActive timestamps\n'
                '• Your admin account remains active\n'
                '• Safe to run multiple times',
              ),
              SizedBox(height: 16),
              Text(
                'Set All Inactive:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Sets ALL users (except you) to inactive\n'
                '• Useful for testing or complete reset\n'
                '• Users will be set to active when they next log in',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}