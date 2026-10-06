import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';

class AppBarDivider extends StatelessWidget implements PreferredSizeWidget {
  const AppBarDivider({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(1);

  @override
  Widget build(BuildContext context) =>
      Container(color: AppStyle.rule, height: 1);
}
