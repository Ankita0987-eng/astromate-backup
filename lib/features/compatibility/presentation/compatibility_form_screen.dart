import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/zodiac_utils.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/google_places_autocomplete.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/services/ads_service.dart';
import '../../../providers/app_providers.dart';

class CompatibilityFormScreen extends ConsumerStatefulWidget {
  const CompatibilityFormScreen({super.key});

  @override
  ConsumerState<CompatibilityFormScreen> createState() =>
      _CompatibilityFormScreenState();
}

class _CompatibilityFormScreenState
    extends ConsumerState<CompatibilityFormScreen> {
  final _nameController = TextEditingController();
  String? _birthLocationDescription;
  String? _selectedCity;
  String? _selectedCountry;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _gender;
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _loading = false;

  Future<void> _generate() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (user == null || profile == null) return;

    if (_nameController.text.trim().isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and birth date are required')),
      );
      return;
    }

    final canCheck =
        await ref.read(userRepositoryProvider).canRunCompatibilityCheck(profile);
    if (!canCheck) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily limit reached. Go Premium or watch an ad.'),
          ),
        );
      }
      final rewarded = await AdsService.instance.showRewarded(
        onReward: () {},
      );
      if (!rewarded && !profile.isPremium) {
        if (mounted) context.push('/premium');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      DateTime? birthTime;
      if (_birthTime != null) {
        birthTime = DateTime(
          _birthDate!.year,
          _birthDate!.month,
          _birthDate!.day,
          _birthTime!.hour,
          _birthTime!.minute,
        );
      }

      final personA = PersonInput(
        name: profile.displayName,
        gender: profile.gender,
        birthDate: profile.birthDate!,
        birthTime: profile.birthTime,
        birthLocation: profile.birthLocation,
        birthLocationCity: profile.birthLocationCity,
        birthLocationCountry: profile.birthLocationCountry,
        birthLocationLatitude: profile.birthLocationLatitude,
        birthLocationLongitude: profile.birthLocationLongitude,
        zodiacSign: profile.zodiacSign ?? ZodiacUtils.signFromDate(profile.birthDate!),
      );

      final personB = PersonInput(
        name: _nameController.text.trim(),
        gender: _gender,
        birthDate: _birthDate!,
        birthTime: birthTime,
        birthLocation: _birthLocationDescription,
        birthLocationCity: _selectedCity,
        birthLocationCountry: _selectedCountry,
        birthLocationLatitude: _selectedLatitude,
        birthLocationLongitude: _selectedLongitude,
        zodiacSign: ZodiacUtils.signFromDate(_birthDate!),
      );

      final reportId = const Uuid().v4();
      final report = await ref.read(astrologyServiceProvider).generateCompatibility(
            userId: user.uid,
            reportId: reportId,
            personA: personA,
            personB: personB,
            isPremium: profile.isPremium,
          );

      await ref.read(compatibilityRepositoryProvider).saveReport(user.uid, report);
      if (!profile.isPremium) {
        await ref.read(userRepositoryProvider).incrementCompatibilityUsage(user.uid);
      }

      await AdsService.instance.maybeShowInterstitial();

      if (mounted) {
        context.push('/compatibility/result', extra: report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Compatibility Check'),
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Enter their birth details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Their name'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: AppConstants.genders
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_birthDate == null
                        ? 'Birth date'
                        : DateFormat.yMMMd().format(_birthDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1998),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _birthDate = date);
                    },
                  ),
                  ListTile(
                    title: Text(_birthTime == null
                        ? 'Birth time (optional)'
                        : _birthTime!.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 12, minute: 0),
                      );
                      if (time != null) setState(() => _birthTime = time);
                    },
                  ),
                  GooglePlacesAutocomplete(
                    initialValue: _birthLocationDescription,
                    labelText: 'Birth location (optional)',
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
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Generate Compatibility',
                    icon: Icons.auto_awesome,
                    isLoading: _loading,
                    onPressed: _generate,
                  ),
                ],
              ),
            ),
          ),
          if (_loading) const LoadingOverlay(message: 'Reading the stars...'),
        ],
      ),
    );
  }
}
