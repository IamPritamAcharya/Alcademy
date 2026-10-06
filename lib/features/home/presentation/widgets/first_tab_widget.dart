import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/home/presentation/widgets/first_tab_page.dart';

class FirstTabWidget extends StatelessWidget {
  const FirstTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const IconData icon = Icons.info_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 6, bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FirstTabPage()),
          );
        },
        borderRadius: AppStyle.radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppStyle.radius,
            color: AppStyle.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppStyle.rule.withValues(alpha: .65)),
          ),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: AppStyle.highlights,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(borderRadius: AppStyle.radius),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: AppStyle.text.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nameFirstTab,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: AppStyle.text,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      wordSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
