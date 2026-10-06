import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/amenities/presentation/amenity_photo.dart';
import 'package:port/features/amenities/presentation/details_page.dart';

class AmenitiesList extends StatelessWidget {
  final List<dynamic> items;
  final int startIndex;
  const AmenitiesList({required this.items, this.startIndex = 0, super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < items.length; i++)
        AmenityEntry(
          item: items[i] as Map<String, dynamic>,
          index: startIndex + i,
          featured: i == 0 && startIndex == 0,
        ),
    ],
  );
}

class AmenityEntry extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool featured;
  final String heroPrefix;
  const AmenityEntry({
    super.key,
    required this.item,
    required this.index,
    this.featured = false,
    this.heroPrefix = 'amenity',
  });
  @override
  Widget build(BuildContext context) {
    final images = (item['images'] as List<dynamic>? ?? []).cast<String>();
    final name = item['name'] as String? ?? 'Unnamed amenity';
    final tag = item['tag'] as String? ?? 'Campus';
    final heroTag = '$heroPrefix:$name:$index';
    final accent = AppStyle.highlights[index % AppStyle.highlights.length];
    void open() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsPage(item: item, heroTag: heroTag),
      ),
    );
    if (featured) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppStyle.surface,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.85,
                  child: Hero(
                    tag: heroTag,
                    child: AmenityPhoto(url: images.firstOrNull),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                letterSpacing: -.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.north_east_rounded,
                              color: AppStyle.muted,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppStyle.rule)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 88,
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AmenityPhoto(url: images.firstOrNull),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(index + 1).toString().padLeft(2, '0')} / ${tag.toUpperCase()}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Icon(
                  Icons.north_east_rounded,
                  size: 17,
                  color: AppStyle.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
