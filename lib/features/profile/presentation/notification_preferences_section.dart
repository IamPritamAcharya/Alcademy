import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:port/features/notifications/data/notification_preferences.dart';
import 'package:port/features/notifications/data/notification_service.dart';
import 'package:port/shared/theme/app_style.dart';

class NotificationPreferencesSection extends StatefulWidget {
  final NotificationPreferencesRepository repository;
  final Future<bool> Function(bool enabled)? syncSubscriptions;
  final Future<bool> Function()? readPermission;

  const NotificationPreferencesSection({
    super.key,
    this.repository = const NotificationPreferencesRepository(),
    this.syncSubscriptions,
    this.readPermission,
  });

  @override
  State<NotificationPreferencesSection> createState() =>
      _NotificationPreferencesSectionState();
}

class _NotificationPreferencesSectionState
    extends State<NotificationPreferencesSection>
    with WidgetsBindingObserver {
  NotificationPreferences? _preferences;
  bool _busy = false;
  bool? _permission;
  String? _message;
  int _revision = 0;

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await widget.repository.read();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _message = null;
      });
      await _readPermission();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Couldn’t load preferences. Please retry.');
      }
    }
  }

  Future<void> _readPermission() async {
    try {
      final bool? permission = widget.readPermission != null
          ? await widget.readPermission!()
          : _supportsPush
          ? await NotificationService().notificationPermissionGranted()
          : null;
      if (mounted) setState(() => _permission = permission);
    } catch (_) {
      // The switches remain usable when Firebase or the platform is unavailable.
    }
  }

  Future<void> _change(NotificationCategory category, bool enabled) async {
    if (_busy) return;
    final revision = ++_revision;
    setState(() {
      _busy = true;
      _message = null;
    });
    var saved = false;
    try {
      await widget.repository.setEnabled(category, enabled);
      saved = true;
      final preferences = await widget.repository.read();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _busy = false;
      });
      bool synced;
      if (widget.syncSubscriptions != null) {
        synced = await widget.syncSubscriptions!(enabled);
      } else if (_supportsPush) {
        final service = NotificationService();
        if (enabled) await service.notificationPermissionGranted(request: true);
        synced = await service.syncNoticeSubscriptions(force: true);
      } else {
        synced = false;
      }
      await _readPermission();
      if (mounted && revision == _revision && !synced) {
        setState(
          () => _message =
              'Saved on this device. Topic changes will retry when you reopen the app with a connection.',
        );
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(
          () => _message = saved
              ? 'Saved on this device. Subscription updates will retry when you reopen the app.'
              : 'Couldn’t save this change. Please try again.',
        );
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _readPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppStyle.rule),
        const SizedBox(height: 24),
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the updates you want to receive.',
          style: TextStyle(color: AppStyle.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        if (_preferences != null) ...[
          _toggle(
            'Notices',
            'New notices published by the college.',
            Icons.campaign_outlined,
            _preferences!.notices,
            NotificationCategory.notices,
          ),
          const Divider(color: AppStyle.rule, height: 1),
          _toggle(
            'General',
            'App announcements and other updates.',
            Icons.notifications_none_rounded,
            _preferences!.general,
            NotificationCategory.general,
          ),
          if (_permission == false) ...[
            const SizedBox(height: 8),
            const Text(
              'Notifications are blocked in your phone settings. Allow them there to receive your selected updates.',
              style: TextStyle(color: AppStyle.gold, fontSize: 12, height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Saved on this device. If you’re offline, subscription changes apply after reconnecting and reopening the app.',
            style: TextStyle(color: AppStyle.muted, fontSize: 12, height: 1.5),
          ),
        ] else if (_message == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            style: const TextStyle(
              color: AppStyle.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (_preferences == null)
            TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ],
    ),
  );

  Widget _toggle(
    String title,
    String subtitle,
    IconData icon,
    bool enabled,
    NotificationCategory category,
  ) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    secondary: Icon(icon, color: AppStyle.muted, size: 23),
    title: Text(
      title,
      style: const TextStyle(
        color: AppStyle.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: AppStyle.muted, fontSize: 12, height: 1.5),
    ),
    value: enabled,
    activeTrackColor: AppStyle.blue,
    onChanged: _busy ? null : (value) => _change(category, value),
  );
}
