import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/google_places_autocomplete.dart';
import '../../../providers/app_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();

  String? _birthLocationDescription;
  String? _selectedCity;
  String? _selectedCountry;
  double? _selectedLatitude;
  double? _selectedLongitude;

  String? _gender;
  String? _relationshipStatus;

  DateTime? _birthDate;
  TimeOfDay? _birthTime;

  final Set<String> _interests = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).valueOrNull;

      if (profile != null) {
        setState(() {
          _nameController.text = profile.displayName;

          _birthLocationDescription = profile.birthLocation;
          _selectedCity = profile.birthLocationCity;
          _selectedCountry = profile.birthLocationCountry;
          _selectedLatitude = profile.birthLocationLatitude;
          _selectedLongitude = profile.birthLocationLongitude;

          _gender = profile.gender;
          _relationshipStatus = profile.relationshipStatus;

          _birthDate = profile.birthDate;

          if (profile.birthTime != null) {
            _birthTime = TimeOfDay.fromDateTime(profile.birthTime!);
          }

          _interests.addAll(profile.interests);
        });
      }
    });
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final name = _nameController.text.trim();
    final location = _birthLocationDescription?.trim();

    // ✅ REQUIRED FIELDS CHECK
    if (name.isEmpty ||
        _birthDate == null ||
        location == null ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill Name, Birth Date and Birth Location'),
        ),
      );
      return;
    }

    // ✅ LOCATION VALIDATION (IMPORTANT FIX)
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select location from suggestions'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      DateTime? birthDateTime;

      if (_birthTime != null) {
        birthDateTime = DateTime(
          _birthDate!.year,
          _birthDate!.month,
          _birthDate!.day,
          _birthTime!.hour,
          _birthTime!.minute,
        );
      }

      await ref.read(userRepositoryProvider).saveProfileSetup(
            uid: user.uid,
            displayName: name,
            gender: _gender ?? "",
            birthDate: _birthDate!,
            birthTime: birthDateTime,
            birthLocation: location,
            birthLocationCity: _selectedCity ?? "",
            birthLocationCountry: _selectedCountry ?? "",
            birthLocationLatitude: _selectedLatitude,
            birthLocationLongitude: _selectedLongitude,
            relationshipStatus: _relationshipStatus ?? "",
            interests: _interests.toList(),
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Your Birth Chart')),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NAME
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                ),
              ),

              const SizedBox(height: 16),

              // GENDER
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: AppConstants.genders
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),

              const SizedBox(height: 16),

              // BIRTH DATE
              ListTile(
                title: Text(
                  _birthDate == null
                      ? 'Birth date *'
                      : DateFormat.yMMMd().format(_birthDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1995),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );

                  if (date != null) {
                    setState(() => _birthDate = date);
                  }
                },
              ),

              // BIRTH TIME
              ListTile(
                title: Text(
                  _birthTime == null
                      ? 'Birth time (optional)'
                      : _birthTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );

                  if (time != null) {
                    setState(() => _birthTime = time);
                  }
                },
              ),

              // LOCATION
              GooglePlacesAutocomplete(
                initialValue: _birthLocationDescription,
                labelText: 'Birth location *',
                hintText: 'City, Country',
                onLocationSelected: (displayName, details) {
                  setState(() {
                    _birthLocationDescription = displayName;
                    _selectedCity = details.city;
                    _selectedCountry = details.country;
                    _selectedLatitude = details.latitude;
                    _selectedLongitude = details.longitude;
                  });
                },
              ),

              const SizedBox(height: 16),

              // RELATIONSHIP STATUS
              DropdownButtonFormField<String>(
                value: _relationshipStatus,
                decoration: const InputDecoration(
                  labelText: 'Relationship status',
                ),
                items: AppConstants.relationshipStatuses
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _relationshipStatus = v),
              ),

              const SizedBox(height: 16),

              // INTERESTS
              const Text(
                'Interests',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              Wrap(
                spacing: 8,
                children: AppConstants.interests.map((interest) {
                  final selected = _interests.contains(interest);

                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _interests.add(interest);
                        } else {
                          _interests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // BUTTON
              GradientButton(
                label: 'Save & Continue',
                isLoading: _loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}