import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_forms.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _allergiesController = TextEditingController();
    _conditionsController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get current user from auth service
      final currentUserId = _authService.currentUserId;
      
      if (currentUserId == null) {
        throw Exception('No user logged in');
      }
      
      // Load user profile from database
      _userProfile = await _databaseService.getUserProfile(currentUserId);
      
      if (_userProfile == null) {
        // Create a default profile for the current user
        final currentUser = _authService.currentUser;
        _userProfile = UserProfile(
          id: currentUserId,
          name: currentUser?.name ?? 'User',
          email: currentUser?.email ?? 'user@example.com',
          phoneNumber: '',
          emergencyContact: '',
          allergies: [],
          medicalConditions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.insertUserProfile(_userProfile!);
      }
      
      _updateControllers();
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateControllers() {
    if (_userProfile != null) {
      _nameController.text = _userProfile!.name;
      _emailController.text = _userProfile!.email;
      _phoneController.text = _userProfile!.phoneNumber ?? '';
      _emergencyContactController.text = _userProfile!.emergencyContact ?? '';
      _allergiesController.text = _userProfile!.allergies.join(', ');
      _conditionsController.text = _userProfile!.medicalConditions.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    if (_userProfile == null) {
      return const Center(child: Text('No profile data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userProfile!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userProfile!.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Contact Information
          _buildSectionTitle('Contact Information'),
          _buildInfoCard([
            _buildInfoRow('Phone', _userProfile!.phoneNumber ?? 'Not provided'),
            _buildInfoRow('Emergency Contact', _userProfile!.emergencyContact ?? 'Not provided'),
          ]),
          
          const SizedBox(height: 24),
          
          // Medical Information
          _buildSectionTitle('Medical Information'),
          _buildInfoCard([
            _buildInfoRow('Allergies', _userProfile!.allergies.isEmpty ? 'None' : _userProfile!.allergies.join(', ')),
            _buildInfoRow('Medical Conditions', _userProfile!.medicalConditions.isEmpty ? 'None' : _userProfile!.medicalConditions.join(', ')),
          ]),
          
          const SizedBox(height: 24),
          
          // Account Information
          _buildSectionTitle('Account Information'),
          _buildInfoCard([
            _buildInfoRow('Member Since', _formatDate(_userProfile!.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(_userProfile!.updatedAt)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _changeProfilePicture,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Personal Information
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),
            
            CustomFormField(
              label: 'Full Name',
              controller: _nameController,
              validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            
            CustomFormField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value?.isEmpty ?? true ? 'Email is required' : null,
            ),
            const SizedBox(height: 16),
            
            CustomFormField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            CustomFormField(
              label: 'Emergency Contact',
              controller: _emergencyContactController,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 32),
            
            // Medical Information
            _buildSectionHeader('Medical Information'),
            const SizedBox(height: 16),
            
            CustomFormField(
              label: 'Allergies',
              controller: _allergiesController,
              hintText: 'Separate with commas',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            CustomFormField(
              label: 'Medical Conditions',
              controller: _conditionsController,
              hintText: 'Separate with commas',
              maxLines: 2,
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    // TODO: Implement profile picture change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture change coming soon!'),
      ),
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _updateControllers(); // Reset controllers to original values
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedProfile = UserProfile(
          id: _userProfile!.id,
          name: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
          emergencyContact: _emergencyContactController.text.isEmpty ? null : _emergencyContactController.text,
          allergies: _allergiesController.text.isEmpty 
              ? [] 
              : _allergiesController.text.split(',').map((e) => e.trim()).toList(),
          medicalConditions: _conditionsController.text.isEmpty 
              ? [] 
              : _conditionsController.text.split(',').map((e) => e.trim()).toList(),
          createdAt: _userProfile!.createdAt,
          updatedAt: DateTime.now(),
        );

        await _databaseService.updateUserProfile(updatedProfile);
        _userProfile = updatedProfile;
        
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }
}
