import 'package:flutter/material.dart';

class NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const NavigationTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: ListTile(
              leading: Icon(icon, color: Colors.white),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontFamily: 'ProductSans',
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
              tileColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
