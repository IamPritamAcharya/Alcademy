import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/features/notifications/models/notification_model.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Notification Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppStyle.text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppStyle.background, AppStyle.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppStyle.blue, AppStyle.blue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    color: AppStyle.onAccent,
                    size: 40,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Text(
                  notification.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: AppStyle.text,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppStyle.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppStyle.rule.withValues(alpha: .65),
                    ),
                  ),
                  child: Text(
                    _formatDateTime(notification.timestamp),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppStyle.muted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Container(
                height: 1,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppStyle.muted.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Message',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppStyle.blue,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 16),
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppStyle.muted,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
