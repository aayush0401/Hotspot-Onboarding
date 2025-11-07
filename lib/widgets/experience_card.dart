import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExperienceCard extends StatelessWidget {
  final int id;
  final String title;
  final String tagline;
  final String imageUrl;
  final bool selected;
  final VoidCallback? onTap;

  const ExperienceCard({super.key, required this.id, required this.title, required this.tagline, required this.imageUrl, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    
    // Debug: print image URL to console
    if (kDebugMode) {
      print('ExperienceCard[$title]: imageUrl = "$imageUrl"');
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [BoxShadow(color: accent.withOpacity(0.28), blurRadius: 14, spreadRadius: 1)]
              : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
          border: selected ? Border.all(color: accent, width: 2) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: selected
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                    : const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                child: _buildImage(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.black.withOpacity(0.58), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(tagline, style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(backgroundColor: Color(0xFF2196F3), child: Icon(Icons.check, color: Colors.white, size: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      // TEMPORARY WORKAROUND: Use gradient placeholders for web due to CORS issues
      // TODO: Fix CORS headers on CloudFront CDN for production
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e + (id * 100000) % 0xFFFFFF),
              Color(0xFF0d47a1 + (id * 150000) % 0xFFFFFF),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            _getIconForExperience(title),
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      );
    } else {
      // On mobile (iOS/Android), CachedNetworkImage works perfectly - no CORS issues
      return CachedNetworkImage(
        imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/400x300/1a237e/FFFFFF?text=${Uri.encodeComponent(title)}',
        fit: BoxFit.cover,
        placeholder: (c, u) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a237e + (id * 100000) % 0xFFFFFF).withOpacity(0.3),
                Color(0xFF0d47a1 + (id * 150000) % 0xFFFFFF).withOpacity(0.3),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
          ),
        ),
        errorWidget: (c, u, e) {
          if (kDebugMode) {
            print('❌ CachedNetworkImage error for "$imageUrl": $e');
          }
          // Fallback to gradient + icon on error
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a237e + (id * 100000) % 0xFFFFFF),
                  Color(0xFF0d47a1 + (id * 150000) % 0xFFFFFF),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                _getIconForExperience(title),
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          );
        },
      );
    }
  }

  IconData _getIconForExperience(String experienceName) {
    final name = experienceName.toLowerCase();
    if (name.contains('party') || name.contains('house party')) return Icons.celebration;
    if (name.contains('picnic') || name.contains('outdoor')) return Icons.park;
    if (name.contains('brunch') || name.contains('lunch') || name.contains('dinner') || name.contains('dining')) return Icons.restaurant;
    if (name.contains('music') || name.contains('dance')) return Icons.music_note;
    if (name.contains('travel') || name.contains('getaway')) return Icons.flight;
    if (name.contains('liquor') || name.contains('tasting')) return Icons.wine_bar;
    if (name.contains('art') || name.contains('craft')) return Icons.palette;
    if (name.contains('food') || name.contains('cook')) return Icons.fastfood;
    if (name.contains('comedy')) return Icons.theater_comedy;
    if (name.contains('games')) return Icons.sports_esports;
    if (name.contains('lit') || name.contains('meet')) return Icons.menu_book;
    return Icons.star;
  }
}
