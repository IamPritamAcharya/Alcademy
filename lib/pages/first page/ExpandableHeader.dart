import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';

class ExpandableHeader extends StatefulWidget {
  final Map<String, dynamic> theme;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final ValueNotifier<bool> isOnlineNotifier;

  const ExpandableHeader({
    Key? key,
    required this.theme,
    this.scaffoldKey,
    required this.isOnlineNotifier,
  }) : super(key: key);

  @override
  _ExpandableHeaderState createState() => _ExpandableHeaderState();
}

class _ExpandableHeaderState extends State<ExpandableHeader> {
  Widget _buildScaledHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    required double iconSize,
    required double padding,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          
          final double totalHeight = 120;
          final double minHeight = 60;
          final double currentHeight = constraints.maxHeight;
          final double collapseRatio =
              ((totalHeight - currentHeight) / (totalHeight - minHeight))
                  .clamp(0.0, 1.0);

          
          final double iconSize = 22 - (collapseRatio * 4); 
          final double iconPadding = 12 - (collapseRatio * 3); 
          final double statusFontSize = 14 - (collapseRatio * 2); 
          final double statusPadding = 8 - (collapseRatio * 2); 
          final double horizontalPadding = 20 - (collapseRatio * 4); 
          final double verticalPadding = 10 - (collapseRatio * 4); 

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.theme['primary'],
                  widget.theme['secondary'],
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScaledHeaderAction(
                      icon: LineIcons.graduationCap,
                      onTap: () => context.push('/year'),
                      iconSize: iconSize,
                      padding: iconPadding,
                    ),

                    ValueListenableBuilder<bool>(
                      valueListenable: widget.isOnlineNotifier,
                      builder: (context, isOnline, _) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 - (collapseRatio * 4),
                              vertical: statusPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8 - (collapseRatio * 1), 
                                height: 8 - (collapseRatio * 1), 
                                decoration: BoxDecoration(
                                  color:
                                      isOnline ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(
                                  width: 8 - (collapseRatio * 2)), 
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: statusFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    _buildScaledHeaderAction(
                      icon: LineIcons.bars,
                      onTap: () =>
                          widget.scaffoldKey?.currentState?.openDrawer(),
                      iconSize: iconSize,
                      padding: iconPadding,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
