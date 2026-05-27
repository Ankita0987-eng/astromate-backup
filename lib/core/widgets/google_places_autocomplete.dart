import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/google_places_provider.dart';
import '../../data/services/google_places_service.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class GooglePlacesAutocomplete extends ConsumerStatefulWidget {
  const GooglePlacesAutocomplete({
    super.key,
    required this.onLocationSelected,
    this.initialValue,
    this.labelText = 'Birth location',
    this.hintText = 'City, Country',
    this.validator,
  });

  final void Function(String displayName, PlaceDetails details) onLocationSelected;
  final String? initialValue;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;

  @override
  ConsumerState<GooglePlacesAutocomplete> createState() => _GooglePlacesAutocompleteState();
}

class _GooglePlacesAutocompleteState extends ConsumerState<GooglePlacesAutocomplete> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  bool _isFetchingDetails = false;
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _hasSelection = true;
    }
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasSelection) {
      // If the user modifies text after selecting, reset selection state
      // so new autocomplete calls can happen.
      _hasSelection = false;
    }
    
    if (_focusNode.hasFocus && !_hasSelection) {
      ref.read(placesAutocompleteProvider.notifier).search(_controller.text);
      _showOverlay();
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty && !_hasSelection) {
        ref.read(placesAutocompleteProvider.notifier).search(_controller.text);
        _showOverlay();
      }
    } else {
      // Delay hiding overlay to allow tap events on list tiles to fire first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _hideOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 6.0),
            child: Material(
              color: Colors.transparent,
              child: _SuggestionsOverlay(
                onSelected: _onSuggestionSelected,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _hideOverlay();
    _focusNode.unfocus();
    setState(() {
      _isFetchingDetails = true;
      _controller.text = suggestion.description;
      _hasSelection = true;
    });

    try {
      final details = await ref.read(googlePlacesServiceProvider).getPlaceDetails(suggestion.placeId);
      
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
        widget.onLocationSelected(suggestion.description, details);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch location details: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine suffix icon based on loading and content states
    Widget? suffix;
    if (_isFetchingDetails) {
      suffix = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_controller.text.isNotEmpty) {
      suffix = IconButton(
        icon: const Icon(Icons.clear, size: 20, color: AppColors.moonSilver),
        onPressed: () {
          _controller.clear();
          ref.read(placesAutocompleteProvider.notifier).clear();
          setState(() {
            _hasSelection = false;
          });
        },
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !_isFetchingDetails,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: suffix != null 
                ? UnconstrainedBox(child: suffix)
                : null,
          ),
        ),
      ),
    );
  }
}

class _SuggestionsOverlay extends ConsumerWidget {
  const _SuggestionsOverlay({required this.onSelected});

  final void Function(PlaceSuggestion) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autocompleteState = ref.watch(placesAutocompleteProvider);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: autocompleteState.when(
          data: (suggestions) {
            if (suggestions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'No regions found',
                  style: TextStyle(color: AppColors.moonSilver),
                ),
              );
            }
            return Scrollbar(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: Text(
                      suggestion.mainText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: suggestion.secondaryText != null
                        ? Text(
                            suggestion.secondaryText!,
                            style: const TextStyle(color: AppColors.moonSilver, fontSize: 12),
                          )
                        : null,
                    onTap: () => onSelected(suggestion),
                  );
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Error: ${err.toString().replaceAll('Exception:', '').trim()}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
