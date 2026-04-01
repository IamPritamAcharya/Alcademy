import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:port/notification/notification_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'notification_model.dart';

class NotificationHistoryPage extends StatefulWidget {
  @override
  _NotificationHistoryPageState createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage>
    with WidgetsBindingObserver {
  List<NotificationModel> notifications = [];
  List<NotificationModel> displayedNotifications = [];
  Set<String> readNotifications = {};
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isRefreshing = false;
  bool hasInitialized = false;
  int currentPage = 0;
  static const int pageSize = 10;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        displayedNotifications.length < notifications.length) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList('read_notifications') ?? [];
      setState(() {
        readNotifications = readList.toSet();
      });
      print('Loaded ${readNotifications.length} read notifications');
    } catch (e) {
      print('Error loading read status: $e');
    }
  }

  Future<void> _saveReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'read_notifications', readNotifications.toList());
      print('Saved read status for ${readNotifications.length} notifications');
    } catch (e) {
      print('Error saving read status: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (!readNotifications.contains(notificationId)) {
      setState(() {
        readNotifications.add(notificationId);
      });
      await _saveReadStatus();
    }
  }

  Future<void> _initializeNotifications() async {
    if (!hasInitialized) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      print('Initializing notifications...');

      await _loadReadStatus();

      await NotificationService().syncNotifications();

      await _loadNotifications();

      if (displayedNotifications.isEmpty) {
        _loadMoreNotifications();
      }

      hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForSelectedNotification();
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && hasInitialized) {
      print('App resumed in NotificationHistoryPage - silent sync');
      _silentSync();
    }
  }

  Future<void> _silentSync() async {
    try {
      await NotificationService().syncNotifications();
      final loadedNotifications =
          await NotificationService().getAllNotifications();

      if (mounted && loadedNotifications.length != notifications.length) {
        setState(() {
          notifications = loadedNotifications;

          displayedNotifications.clear();
          currentPage = 0;
        });
        _loadMoreNotifications();
      }
    } catch (e) {
      print('Error during silent sync: $e');
    }
  }

  void _checkForSelectedNotification() {
    final selectedId = NotificationService.getSelectedNotificationId();
    if (selectedId != null && selectedId.isNotEmpty) {
      print("Found selected notification ID: $selectedId");

      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _showNotificationDetail(selectedId);
        }
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      print("Loading notifications...");
      final loadedNotifications =
          await NotificationService().getAllNotifications();

      if (mounted) {
        setState(() {
          notifications = loadedNotifications;
          if (!hasInitialized) {
            isLoading = false;
          }
        });
        print(" Loaded ${notifications.length} notifications");

        for (int i = 0; i < notifications.length && i < 3; i++) {
          final n = notifications[i];
          print(
              "  ${i + 1}. ${n.title} - ${n.body.substring(0, n.body.length.clamp(0, 50))}...");
        }
      }
    } catch (e) {
      print("Error loading notifications: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Failed to load notifications: ${e.toString()}');
      }
    }
  }

  void _loadMoreNotifications() {
    if (isLoadingMore || displayedNotifications.length >= notifications.length)
      return;

    setState(() {
      isLoadingMore = true;
    });

    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        final startIndex = currentPage * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, notifications.length);

        setState(() {
          displayedNotifications
              .addAll(notifications.sublist(startIndex, endIndex));
          currentPage++;
          isLoadingMore = false;
        });

        print(
            'Loaded page $currentPage: ${displayedNotifications.length}/${notifications.length}');
      }
    });
  }

  void _showNotificationDetail(String notificationId) async {
    if (notifications.isEmpty) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && notifications.isNotEmpty) {
          _showNotificationDetail(notificationId);
        } else if (mounted) {
          _showErrorSnackBar('Notification not found');
        }
      });
      return;
    }

    final NotificationModel? notification = notifications.isNotEmpty
        ? notifications.firstWhere(
            (n) => n.id == notificationId,
            orElse: () => NotificationModel(
              id: 'default',
              title: 'No Notification Found',
              body: '',
              timestamp: DateTime.now(),
            ),
          )
        : null;

    if (notification != null && notification.id != 'default') {
      print("Showing notification detail for: ${notification.title}");

      await _markAsRead(notificationId);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NotificationDetailPage(notification: notification),
          ),
        );
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('Notification not found');
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final shouldDelete = await _showDeleteConfirmation();
      if (!shouldDelete) return;

      await NotificationService().deleteNotification(notificationId);

      setState(() {
        notifications.removeWhere((n) => n.id == notificationId);
        displayedNotifications.removeWhere((n) => n.id == notificationId);
        readNotifications.remove(notificationId);
      });

      await _saveReadStatus();

      _showSuccessSnackBar('Notification deleted');

      print('Deleted notification: $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
      _showErrorSnackBar('Failed to delete notification');
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                title: Text(
                  'Delete Notification',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete this notification? This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                actionsPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.redAccent.withOpacity(0.15),
                    ),
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _refreshNotifications() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
    });

    try {
      print(" Manual refresh triggered");

      await NotificationService().debugBackgroundQueue();

      await NotificationService().forceRefreshNotifications();

      await NotificationService().debugBackgroundQueue();

      setState(() {
        currentPage = 0;
        displayedNotifications.clear();
      });

      await _loadNotifications();
      _loadMoreNotifications();

      if (mounted) {
        _showSuccessSnackBar('Notifications refreshed');
      }
    } catch (e) {
      print("Error during refresh: $e");
      if (mounted) {
        _showErrorSnackBar('Failed to refresh: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: isLoading && !hasInitialized
            ? _buildLoadingState()
            : notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    backgroundColor: Color(0xFF2A2A2A),
                    color: Colors.blue,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
                      itemCount: displayedNotifications.length +
                          (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayedNotifications.length) {
                          return _buildLoadingMoreIndicator();
                        }
                        final notification = displayedNotifications[index];
                        final isRead =
                            readNotifications.contains(notification.id);
                        return _buildNotificationCard(notification, isRead);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A).withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 50,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Notifications will appear here when you receive them',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: isRefreshing ? null : _refreshNotifications,
              icon: isRefreshing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : Icon(Icons.refresh_rounded),
              label: Text(isRefreshing ? 'Refreshing...' : 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
                foregroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isRead) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? Colors.white.withOpacity(0.08)
              : Colors.blue.withOpacity(0.4),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => _showNotificationDetail(notification.id),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.01),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.blue.shade600.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                          height: 1.3,
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _deleteNotification(notification.id),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
