import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/activity_service.dart';
import 'auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _firebaseAuth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();
  
  bool _saving = false;
  String _saveButtonText = 'Save Changes';
  Map<String, dynamic>? _originalData;

  @override
  void initState() {
    super.initState();
    _originalData = Map<String, dynamic>.from(widget.user);
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _bioController = TextEditingController(text: widget.user['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Test method to verify current user data
  Future<void> _debugCurrentUserData() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        print('=== DEBUG: Current User Data ===');
        print('Firebase Auth UID: ${currentUser.uid}');
        print('Firebase Auth displayName: "${currentUser.displayName}"');
        print('Firebase Auth email: "${currentUser.email}"');
        
        final doc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          print('Firestore name: "${data['name']}"');
          print('Firestore email: "${data['email']}"');
          print('Firestore phone: "${data['phone']}"');
          print('Firestore bio: "${data['bio']}"');
        } else {
          print('Firestore document does not exist');
        }
        print('=== END DEBUG ===');
      }
    } catch (e) {
      print('Debug error: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final bio = _bioController.text.trim();
    
    // Debug current state before saving
    print('=== SAVE PROFILE DEBUG ===');
    print('Attempting to save: name="$name", phone="$phone", bio="$bio"');
    await _debugCurrentUserData();
    
    // Check if any changes were made
    final hasChanges = name != (_originalData?['name'] ?? '') ||
                      phone != (_originalData?['phone'] ?? '') ||
                      bio != (_originalData?['bio'] ?? '');

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _saveButtonText = 'Saving...';
    });

    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'name': name,
        'phone': phone,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      print('Updating Firestore with data: $updateData');
      await _firestore.collection('users').doc(currentUser.uid).update(updateData);
      print('Firestore update completed successfully');

      // Verify the update was successful by reading back the data
      final verificationDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (verificationDoc.exists) {
        final verificationData = verificationDoc.data() as Map<String, dynamic>;
        final savedName = verificationData['name'];
        print('Verification: Firestore now contains name="$savedName"');
        
        if (savedName != name) {
          throw Exception('Firestore update verification failed: expected "$name", got "$savedName"');
        }
      } else {
        throw Exception('User document not found during verification');
      }

      // Update Firebase Auth display name if changed
      if (name != currentUser.displayName) {
        print('Updating Firebase Auth displayName from "${currentUser.displayName}" to "$name"');
        await currentUser.updateDisplayName(name);
        print('Firebase Auth displayName updated successfully');
        
        // Reload the user to get updated displayName
        await currentUser.reload();
        final updatedUser = _firebaseAuth.currentUser;
        print('Verification: Firebase Auth displayName is now "${updatedUser?.displayName}"');
      }

      // Log activity
      print('Logging profile update activity');
      await _activityService.logProfileUpdate(currentUser.uid);
      print('Activity logged successfully');

      if (!mounted) return;

      // Update local user data
      widget.user['name'] = name;
      widget.user['phone'] = phone;
      widget.user['bio'] = bio;
      
      setState(() {
        _saveButtonText = 'Saved!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Wait a moment to show success state, then navigate back
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate successful update
      }

    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _saveButtonText = 'Save Changes';
      });

      String errorMessage = 'Failed to update profile';
      String errorDetails = e.toString();
      
      if (errorDetails.contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your account permissions.';
      } else if (errorDetails.contains('network') || errorDetails.contains('NetworkException')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (errorDetails.contains('No user signed in')) {
        errorMessage = 'Please sign in again and try updating your profile.';
      } else {
        errorMessage = 'Update failed. Please try again.';
      }
      
      print('Profile update error: $errorDetails');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveProfile,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          if (_saveButtonText == 'Saving...') {
            _saveButtonText = 'Save Changes';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white70),
            onPressed: _saving ? null : _saveProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal[400],
                      child: Text(
                        (widget.user['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Form Fields
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, color: Colors.teal[600]),
                        suffixIcon: _saving 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
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
                    
                    const SizedBox(height: 20),
                    
                    // Email Field (Read-only)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email, color: Colors.teal[600]),
                        suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                      ),
                      readOnly: true,
                    ),
                    
                    const SizedBox(height: 8),
                    Text(
                      'Email cannot be changed from this screen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_saving,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        hintText: 'Enter your phone number',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone, color: Colors.teal[600]),
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
                    
                    const SizedBox(height: 20),
                    
                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      enabled: !_saving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio (Optional)',
                        hintText: 'Tell us about yourself...',
                        border: const OutlineInputBorder(),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.info, color: Colors.teal[600]),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return 'Bio must be less than 200 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saving ? Colors.grey : Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_saving) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _saveButtonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Cancel Button
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _saving ? Colors.grey : Colors.teal[700],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
