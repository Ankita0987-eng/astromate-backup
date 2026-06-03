import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../providers/data_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  String _selectedGender = 'Female';
  String _selectedRelationshipGoal = 'Serious relationship';
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: userProfile.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }
          return _buildForm(context, isDark, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isDark, UserProfile profile) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.purple.shade200,
                  child: Text(
                    profile.displayName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo upload coming soon')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Name
          _buildTextField(
            label: 'Name',
            controller: _nameController..text = profile.displayName,
            context: context,
          ),
          const SizedBox(height: 16),
          // Bio
          _buildTextField(
            label: 'Bio',
            controller: _bioController..text = profile.bio ?? '',
            maxLines: 3,
            context: context,
          ),
          const SizedBox(height: 16),
          // Gender
          _buildDropdown(
            label: 'Gender',
            value: _selectedGender,
            options: ['Male', 'Female', 'Other'],
            onChanged: (value) {
              setState(() => _selectedGender = value!);
            },
            context: context,
          ),
          const SizedBox(height: 16),
          // Relationship Goal
          _buildDropdown(
            label: 'Looking For',
            value: _selectedRelationshipGoal,
            options: [
              'Serious relationship',
              'Casual dating',
              'Friendship',
              'Not sure'
            ],
            onChanged: (value) {
              setState(() => _selectedRelationshipGoal = value!);
            },
            context: context,
          ),
          const SizedBox(height: 16),
          // Location
          _buildTextField(
            label: 'Location',
            controller: _locationController..text = profile.location ?? '',
            context: context,
          ),
          const SizedBox(height: 24),
          // Interests
          Text(
            'Interests',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInterestsList(context),
          const SizedBox(height: 32),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
    required BuildContext context,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: options.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInterestsList(BuildContext context) {
    final availableInterests = [
      'Travel', 'Music', 'Art', 'Sports', 'Reading',
      'Cooking', 'Movies', 'Hiking', 'Yoga', 'Photography'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableInterests.map((interest) {
        final isSelected = _interests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _interests.add(interest);
              } else {
                _interests.remove(interest);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
    );
    Navigator.pop(context);
  }
}
