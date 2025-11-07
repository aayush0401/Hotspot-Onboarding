import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience.dart';
import '../providers/experience_provider.dart';
import '../providers/state_providers.dart';
import 'onboarding_question.dart';
import '../widgets/experience_card.dart';

class ExperienceSelectionScreen extends ConsumerStatefulWidget {
  const ExperienceSelectionScreen({super.key});

  @override
  ConsumerState<ExperienceSelectionScreen> createState() => _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState extends ConsumerState<ExperienceSelectionScreen> {
  // ApiService provided via Riverpod (apiServiceProvider)
  bool _loading = true;
  String _error = '';
  List<Experience> _items = [];
  final Set<int> _animatingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });
      final api = ref.read(apiServiceProvider);
      final list = await api.fetchExperiences();
      _items = list;
      ref.read(experiencesProvider.notifier).setExperiences(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  final selected = ref.watch(selectedExperiencesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Text('Error: $_error'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top title matching Figma
                        const SizedBox(height: 6),
                        Text('Select Experience Type', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final e = _items[index];
                              final isSelected = selected.contains(e.id);
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: isSelected ? 0.95 : 1.0, end: isSelected ? 1.0 : 1.0),
                                duration: const Duration(milliseconds: 220),
                                builder: (context, val, child) {
                                  return Transform.scale(
                                    scale: val,
                                    child: ExperienceCard(id: e.id, title: e.name, tagline: e.tagline, imageUrl: e.imageUrl, selected: isSelected, onTap: () => _onCardTap(e, isSelected, index)),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Multi-line text field
                        TextField(
                          maxLines: 4,
                          maxLength: 250,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Tell us about your hosting experience...',
                          ),
                          onChanged: (v) => ref.read(experiencesTextProvider.notifier).state = v,
                        ),
                        const SizedBox(height: 16),
                        // Next button full width, rounded radius 16
                        SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selected.length >= 3 ? const Color(0xFF2196F3) : Colors.grey[800],
                                foregroundColor: selected.length >= 3 ? Colors.white : Colors.grey[600],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: selected.length >= 3 ? () {
                                final sel = ref.read(selectedExperiencesProvider);
                                final txt = ref.read(experiencesTextProvider);
                                debugPrint('✅ Selected experience ids: $sel');
                                debugPrint('✅ Experience text: $txt');
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingQuestionScreen()));
                              } : null,
                              child: Text(
                                selected.length >= 3 
                                  ? 'Next' 
                                  : 'Select at least ${3 - selected.length} more',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
        ),
      ),
    );
  }

  Future<void> _onCardTap(Experience e, bool isSelected, int index) async {
    // If selecting (not previously selected), animate and move to first index.
    if (!isSelected) {
      setState(() {
        _animatingIds.add(e.id);
      });
      // Small delay to show scale animation
      await Future.delayed(const Duration(milliseconds: 180));
      // toggle selection
      ref.read(selectedExperiencesProvider.notifier).toggle(e.id);
      // move item to first index
      final currentIndex = _items.indexWhere((it) => it.id == e.id);
      if (currentIndex != -1) {
        setState(() {
          final item = _items.removeAt(currentIndex);
          _items.insert(0, item);
          _animatingIds.remove(e.id);
        });
      } else {
        setState(() => _animatingIds.remove(e.id));
      }
    } else {
      // If already selected, just toggle off
      ref.read(selectedExperiencesProvider.notifier).toggle(e.id);
    }
  }
}

// Using shared ExperienceCard widget from widgets/experience_card.dart
