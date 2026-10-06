import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/markdown_viewer.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/core/config/app_config.dart';

class FirstTabPage extends StatelessWidget {
  const FirstTabPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppConfig>(
    valueListenable: AppConfiguration.current,
    builder: (context, config, child) => _buildPage(context),
  );

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: Text(
          nameFirstTab,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppStyle.text,
            letterSpacing: -.5,
          ),
        ),
        backgroundColor: AppStyle.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              SharedMarkdownViewer(
                enableDefaultLinks: false,
                markdownData: markdownContentFirstTab,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href));
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
