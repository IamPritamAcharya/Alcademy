import 'package:port/shared/widgets/editorial_list_row.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/features/notes/models/subject.dart';

class SubjectDetailsPage extends StatelessWidget {
  final Subject subject;

  const SubjectDetailsPage({super.key, required this.subject});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _resourceKind(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return 'Video';
    }
    if (host.contains('drive.google.com') ||
        url.toLowerCase().endsWith('.pdf')) {
      return 'Document';
    }
    return 'Link';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: Text(
          'Resources',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        centerTitle: false,
        backgroundColor: AppStyle.background,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        itemCount: subject.items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return CollectionIntro(
              title: subject.name,
              eyebrow: 'THE RESOURCE INDEX',
              detail: '${subject.items.length} resources for this subject',
            );
          }
          final item = subject.items[index - 1];
          return EditorialListRow(
            number: index,
            title: item.name,
            category: _resourceKind(item.url),
            accent: AppStyle.blue,
            subtitle: Uri.tryParse(item.url)?.host,
            onTap: () => _launchURL(item.url),
          );
        },
      ),
    );
  }
}
