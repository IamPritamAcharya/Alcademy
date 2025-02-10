import 'package:flutter/material.dart';
import 'package:port/config.dart';
import 'package:port/pages/widgets/first_tab_page.dart';

class FirstTabWidget extends StatelessWidget {
  const FirstTabWidget({Key? key}) : super(key: key);

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
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color:
                Colors.white.withOpacity(0.05), // Translucent white background
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), // Subtle shadow
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  Color(0xFF9C27B0), // Vibrant Amethyst Purple
                  Color(0xFFFF5722), // Vibrant Tangerine
                  Color(0xFFFFD700), // Vibrant Gold
                  Color(0xFF4CAF50), // Vibrant Emerald Green
                  Color(0xFF00BCD4), // Vibrant Cyan
                  Color.fromRGBO(216, 72, 241, 1), // Vibrant Amethyst Purple
                  Color(0xFFFF5722), // Vibrant Tangerine
                  Color(0xFF607D8B), // Vibrant Slate Blue
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white
                        .withOpacity(0.8), // Icon matches glassmorphic design
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name_1st_tab,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
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
