import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  final Future<bool> Function(Uri)? openLink;
  const AboutPage({super.key, this.openLink});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !['https', 'http'].contains(uri.scheme)) return;
    try {
      final opened =
          await (openLink?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t open the link. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('About'),
      centerTitle: false,
      bottom: const AppBarDivider(),
    ),
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const Text('THE CAMPUS COMPANION', style: AppStyle.eyebrow),
        const SizedBox(height: 12),
        const AutoSizeText(
          'Alcademy.',
          maxLines: 1,
          minFontSize: 24,
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            letterSpacing: -2.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Notes, notices, and campus resources.\nMade by a student, for students.',
          style: TextStyle(fontSize: 15, height: 1.6, color: AppStyle.muted),
        ),
        const SizedBox(height: 28),
        const Divider(color: AppStyle.rule),
        const SizedBox(height: 24),
        const Text('01 / THE MAKER', style: AppStyle.eyebrow),
        const SizedBox(height: 20),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: Image(
                image: AssetImage('assets/images/me.jpg'),
                width: 84,
                height: 112,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pritam\nAcharya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.7,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Developer · 16th CSE\n2023–27',
                    style: TextStyle(
                      color: AppStyle.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _social(
              context,
              'Instagram',
              'assets/images/insta.png',
              'https://www.instagram.com/pritam.ach/',
            ),
            _social(
              context,
              'LinkedIn',
              'assets/images/link.png',
              'https://www.linkedin.com/in/pritamacharya/',
            ),
            _social(
              context,
              'YouTube',
              'assets/images/yt.png',
              'https://www.youtube.com/@Pritam-Ach',
            ),
          ],
        ),
        const SizedBox(height: 32),
        _withoutTapOverlay(context, _story()),
        const SizedBox(height: 28),
        const Text('02 / WITH THANKS', style: AppStyle.eyebrow),
        const SizedBox(height: 18),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: Image(
                image: AssetImage('assets/images/codex.jpeg'),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Codex Crew',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'For the notes, contributions, and support that helped make Alcademy possible.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<AppConfig>(
          valueListenable: AppConfiguration.current,
          builder: (_, config, __) => _withoutTapOverlay(
            context,
            _contributors(context, config.contributors),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Alcademy · Made by Pritam Acharya',
          style: TextStyle(fontSize: 11, height: 1.5, color: AppStyle.muted),
        ),
      ],
    ),
  );

  Widget _withoutTapOverlay(BuildContext context, Widget child) => Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    ),
    child: child,
  );

  Widget _social(
    BuildContext context,
    String label,
    String asset,
    String url,
  ) => OutlinedButton.icon(
    onPressed: () => _openUrl(context, url),
    icon: Image.asset(asset, width: 16, height: 16),
    label: Text(label, style: const TextStyle(fontSize: 12)),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppStyle.text,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );

  Widget _story() => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(vertical: 8),
    childrenPadding: const EdgeInsets.only(bottom: 24),
    shape: const Border(
      top: BorderSide(color: AppStyle.rule),
      bottom: BorderSide(color: AppStyle.rule),
    ),
    collapsedShape: const Border(
      top: BorderSide(color: AppStyle.rule),
      bottom: BorderSide(color: AppStyle.rule),
    ),
    iconColor: AppStyle.paper,
    collapsedIconColor: AppStyle.muted,
    title: const Text(
      'Behind the app',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -.5,
      ),
    ),
    subtitle: const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'A note from the developer',
        style: TextStyle(fontSize: 12, color: AppStyle.muted),
      ),
    ),
    children: [
      const Text(
        "This app has been a significant part of my journey, taking 4 months to develop, including 2 months of full-time effort.\n\nAs a second-year student, I had to learn a lot along the way, and making a production-ready app was a challenging yet rewarding experience.\n\nThe app is entirely free, and setting everything up was undoubtedly difficult. It consists of over 13,000 lines of code, so I apologize in advance if there are any issues or bugs.\n\nPlease feel free to report any issues either in the group or through my social channels, and I will address them as quickly as possible.\n\nThis app would not have been possible without the contributors who provided the notes, especially Codex Crew—I am immensely grateful for their support.\n\nI hope you enjoy using this app\n(RIP my third semesters lol!)",
        style: TextStyle(fontSize: 14, height: 1.7, color: AppStyle.muted),
      ),
    ],
  );

  Widget _contributors(
    BuildContext context,
    List<Map<String, String>> people,
  ) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(vertical: 8),
    childrenPadding: const EdgeInsets.only(bottom: 12),
    shape: const Border(
      top: BorderSide(color: AppStyle.rule),
      bottom: BorderSide(color: AppStyle.rule),
    ),
    collapsedShape: const Border(
      top: BorderSide(color: AppStyle.rule),
      bottom: BorderSide(color: AppStyle.rule),
    ),
    iconColor: AppStyle.paper,
    collapsedIconColor: AppStyle.muted,
    title: const Text(
      'Contributors',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -.5,
      ),
    ),
    children: people.isEmpty
        ? [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No contributors listed yet.',
                style: TextStyle(color: AppStyle.muted),
              ),
            ),
          ]
        : [
            for (var i = 0; i < people.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  (i + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 12, color: AppStyle.muted),
                ),
                title: Text(
                  people[i]['name'] ?? 'Contributor',
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                trailing: (people[i]['url'] ?? '').isEmpty
                    ? null
                    : const Icon(
                        Icons.north_east_rounded,
                        size: 18,
                        color: AppStyle.muted,
                      ),
                onTap: (people[i]['url'] ?? '').isEmpty
                    ? null
                    : () => _openUrl(context, people[i]['url']!),
              ),
          ],
  );
}
