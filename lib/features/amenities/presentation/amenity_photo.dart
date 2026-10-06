import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

String amenityImageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'drive.google.com') return url;
  var id = uri.queryParameters['id'];
  final segments = uri.pathSegments;
  final marker = segments.indexOf('d');
  if (id == null && marker >= 0 && marker + 1 < segments.length) {
    id = segments[marker + 1];
  }
  if (id == null || id.isEmpty) return url;
  return Uri.https('drive.google.com', '/uc', {
    'export': 'view',
    'id': id,
  }).toString();
}

class AmenityPhoto extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  const AmenityPhoto({super.key, this.url, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppStyle.surface,
      child: Center(
        child: Icon(
          Icons.location_on_outlined,
          size: 42,
          color: AppStyle.muted,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      amenityImageUrl(url!),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (_, child, frame, loaded) =>
          loaded || frame != null ? child : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
