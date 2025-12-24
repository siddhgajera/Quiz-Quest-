import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/activity_service.dart';

class AdminEditProfileScreen extends StatefulWidget {
  const AdminEditProfileScreen({super.key});

  @override
  State<AdminEditProfileScreen> createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _originalData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Debug method to verify current admin data
  Future<void> _debugCurrentAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('=== ADMIN DEBUG: Current User Data ===');
        print('Firebase Auth UID: ${user.uid}');
        print('Firebase Auth displayName: "${user.displayName}"');
        print('Firebase Auth email: "${user.email}"');
        
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          print('Firestore name: "${data['name']}"');
          print('Firestore email: "${data['email']}"');
          print('Firestore phone: "${data['phone']}"');
          print('Firestore bio: "${data['bio']}"');
          print('Firestore role: "${data['role']}"');
          print('Firestore isAdmin: "${data['isAdmin']}"');
        } else {
          print('Firestore document does not exist');
        }
        print('=== END ADMIN DEBUG ===');
      }
    } catch (e) {
      print('Admin debug error: $e');
    }
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Admin Edit Profile: Loading data for user ${user.uid}');
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _originalData = Map<String, dynamic>.from(data);
          
          print('Admin Edit Profile: Loaded data - name="${data['name']}", email="${data['email']}"');
          
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _isLoading = false;
          });
        } else {
          print('Admin Edit Profile: Document does not exist for user ${user.uid}');
          setState(() {
            _error = 'Admin profile not found';
            _isLoading = false;
          });
        }
      } else {
        print('Admin Edit Profile: No current user found');
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Admin Edit Profile: Error loading data - $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Debug current state before saving
    print('=== ADMIN SAVE PROFILE DEBUG ===');
    print('Attempting to save: name="${_nameController.text.trim()}", email="${_emailController.text.trim()}", phone="${_phoneController.text.trim()}", bio="${_bioController.text.trim()}"');
    await _debugCurrentAdminData();

    // Check if any changes were made
    final hasChanges = _nameController.text != (_originalData?['name'] ?? '') ||
                      _emailController.text != (_originalData?['email'] ?? '') ||
                      _phoneController.text != (_originalData?['phone'] ?? '') ||
                      _bioController.text != (_originalData?['bio'] ?? '');

    if (!hasChanges) {
      print('Admin Profile: No changes detected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle email change separately (requires re-authentication for security)
      final emailChanged = _emailController.text.trim() != (_originalData?['email'] ?? '');
      
      if (!emailChanged) {
        // If email hasn't changed, include it in the regular update
        updateData['email'] = _emailController.text.trim();
      }

      // Update Firestore document
      print('Admin Profile: Updating Firestore with data: $updateData');
      await _firestore.collection('users').doc(user.uid).update(updateData);
      print('Admin Profile: Firestore update completed successfully');

      // Verify the update was successful
      final verificationDoc = await _firestore.collection('users').doc(user.uid).get();
      if (verificationDoc.exists) {
        final verificationData = verificationDoc.data() as Map<String, dynamic>;
        final savedName = verificationData['name'];
        print('Admin Profile: Verification - Firestore now contains name="$savedName"');
        
        if (savedName != _nameController.text.trim()) {
          throw Exception('Admin profile update verification failed: expected "${_nameController.text.trim()}", got "$savedName"');
        }
      } else {
        throw Exception('Admin user document not found during verification');
      }

      // Update Firebase Auth display name
      if (_nameController.text.trim() != user.displayName) {
        print('Admin Profile: Updating Firebase Auth displayName from "${user.displayName}" to "${_nameController.text.trim()}"');
        await user.updateDisplayName(_nameController.text.trim());
        print('Admin Profile: Firebase Auth displayName updated successfully');
        
        // Reload the user to get updated displayName
        await user.reload();
        final updatedUser = _auth.currentUser;
        print('Admin Profile: Verification - Firebase Auth displayName is now "${updatedUser?.displayName}"');
      }

      // Handle email change if needed
      if (emailChanged) {
        print('Admin Profile: Handling email change to "${_emailController.text.trim()}"');
        await _handleEmailChange(_emailController.text.trim());
      }

      // Log activity
      print('Admin Profile: Logging profile update activity');
      await _activityService.logProfileUpdate(user.uid);
      print('Admin Profile: Activity logged successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate changes were made
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleEmailChange(String newEmail) async {
    // For email changes, we'll show a dialog explaining the process
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email Change'),
          content: const Text(
            'Email changes require additional verification. '
            'Please check your new email for a verification link after saving. '
            'Your email will be updated once verified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update email in Firebase Auth (requires verification)
        await user.updateEmail(newEmail);
        
        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
          'emailVerified': false, // Reset verification status
        });
      }
    } catch (e) {
      // Handle email update errors
      print('Email update error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.blue[700],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Unable to load profile'),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAdminData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Edit Admin Profile'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 50,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Edit Admin Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Update your administrative information',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Form
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person, color: Colors.blue[600]),
                            suffixIcon: _isSaving 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                            enabled: !_isSaving,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email, color: Colors.blue[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                            enabled: !_isSaving,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(Icons.phone, color: Colors.blue[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                            enabled: !_isSaving,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 10) {
                                return 'Phone number must be at least 10 digits';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Bio Field
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Bio (Optional)',
                            hintText: 'Tell us about yourself...',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.info, color: Colors.blue[600]),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                            enabled: !_isSaving,
                          ),
                          validator: (value) {
                            if (value != null && value.length > 200) {
                              return 'Bio must be less than 200 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Changes to your email will require verification. You\'ll receive a verification link at your new email address.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
