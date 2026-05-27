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
  bool _locationSelected = false;

  String? _gender;
  String? _relationshipStatus;

  DateTime? _birthDate;
  TimeOfDay? _birthTime;

  final Set<String> _interests = {};

  bool _loading = false;
  bool _submitted = false;

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
          
          // Mark location as selected if it has coordinates
          if (profile.birthLocation != null &&
              profile.birthLocation!.isNotEmpty &&
              profile.birthLocationLatitude != null &&
              profile.birthLocationLongitude != null) {
            _locationSelected = true;
          }

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Validates all required fields
  bool _validateFields() {
    final name = _nameController.text.trim();

    // Check name
    if (name.isEmpty) {
      return false;
    }

    // Check birth date
    if (_birthDate == null) {
      return false;
    }

    // Check location (must be selected from autocomplete)
    if (!_locationSelected ||
        _birthLocationDescription == null ||
        _birthLocationDescription!.isEmpty ||
        _selectedLatitude == null ||
        _selectedLongitude == null) {
      return false;
    }

    return true;
  }

  /// Returns the current validation error message
  String? _getValidationError() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return 'Please enter your name';
    }

    if (_birthDate == null) {
      return 'Please select your birth date';
    }

    if (!_locationSelected ||
        _birthLocationDescription == null ||
        _birthLocationDescription!.isEmpty) {
      return 'Please select your birth location from the suggestions';
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      return 'Birth location coordinates could not be determined';
    }

    return null;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Validate all fields
    if (!_validateFields()) {
      final error = _getValidationError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Please complete all required fields'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final name = _nameController.text.trim();

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
            birthLocation: _birthLocationDescription!,
            birthLocationCity: _selectedCity ?? "",
            birthLocationCountry: _selectedCountry ?? "",
            birthLocationLatitude: _selectedLatitude!,
            birthLocationLongitude: _selectedLongitude!,
            relationshipStatus: _relationshipStatus ?? "",
            interests: _interests.toList(),
          );

      if (mounted) {
        // Show success feedback before navigation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            duration: Duration(milliseconds: 1500),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validationError = _submitted ? _getValidationError() : null;

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Your Birth Chart'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NAME FIELD
              TextField(
                controller: _nameController,
                enabled: !_loading,
                onChanged: (_) {
                  if (_submitted) {
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Name *',
                  errorText:
                      _submitted && _nameController.text.trim().isEmpty
                          ? 'Name is required'
                          : null,
                  prefixIcon: _nameController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // GENDER DROPDOWN
              DropdownButtonFormField<String>(
                initialValue: _gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: AppConstants.genders
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ),
                    )
                    .toList(),
                onChanged: _loading ? null : (v) => setState(() => _gender = v),
              ),

              const SizedBox(height: 20),

              // BIRTH DATE PICKER
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _submitted && _birthDate == null
                          ? Colors.redAccent
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _birthDate == null
                        ? 'Birth date *'
                        : DateFormat.yMMMd().format(_birthDate!),
                    style: TextStyle(
                      color: _birthDate == null
                          ? Colors.grey
                          : Colors.white,
                      fontWeight: _birthDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _birthDate != null
                      ? const Icon(Icons.check_circle,
                          color: Colors.green)
                      : const Icon(Icons.calendar_today),
                  enabled: !_loading,
                  onTap: _loading
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _birthDate ?? DateTime(1995),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );

                          if (date != null) {
                            setState(() => _birthDate = date);
                          }
                        },
                ),
              ),

              if (_submitted && _birthDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16),
                  child: Text(
                    'Birth date is required',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // BIRTH TIME PICKER (optional)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _birthTime == null
                        ? 'Birth time (optional)'
                        : _birthTime!.format(context),
                    style: TextStyle(
                      color:
                          _birthTime == null ? Colors.grey : Colors.white,
                      fontWeight: _birthTime != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _birthTime != null
                      ? const Icon(Icons.check_circle,
                          color: Colors.green)
                      : const Icon(Icons.access_time),
                  enabled: !_loading,
                  onTap: _loading
                      ? null
                      : () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                                _birthTime ??
                                const TimeOfDay(hour: 12, minute: 0),
                          );

                          if (time != null) {
                            setState(() => _birthTime = time);
                          }
                        },
                ),
              ),

              const SizedBox(height: 20),

              // LOCATION FIELD WITH AUTOCOMPLETE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        _locationSelected = true;
                      });
                    },
                  ),
                  if (_submitted &&
                      (!_locationSelected ||
                          _birthLocationDescription == null ||
                          _birthLocationDescription!.isEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Text(
                        'Please select location from suggestions',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_locationSelected &&
                      _birthLocationDescription != null &&
                      _birthLocationDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Location confirmed',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // RELATIONSHIP STATUS
              DropdownButtonFormField<String>(
                initialValue: _relationshipStatus,
                isExpanded: true,
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
                onChanged:
                    _loading ? null : (v) => setState(() => _relationshipStatus = v),
              ),

              const SizedBox(height: 20),

              // INTERESTS SECTION
              const Text(
                'Interests',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.interests.map((interest) {
                  final selected = _interests.contains(interest);

                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: _loading
                        ? null
                        : (v) {
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

              // VALIDATION ERROR MESSAGE (if submitted)
              if (_submitted && validationError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          validationError,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_submitted && validationError != null)
                const SizedBox(height: 16),

              // SUBMIT BUTTON
              GradientButton(
                label: 'Save & Continue',
                isLoading: _loading,
                onPressed: _loading ? null : _save,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}