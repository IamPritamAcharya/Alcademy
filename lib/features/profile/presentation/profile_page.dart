import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/features/profile/data/profile_repository.dart';
import 'package:port/features/profile/presentation/profile_card.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? userName;
  String? branch;
  late Future<void> _refreshFuture;

  @override
  void initState() {
    super.initState();
    _refreshFuture = loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final name = await ProfileRepository.getUserName();
      final userBranch = await ProfileRepository.getUserBranch();
      if (!mounted) return;

      debugPrint('Fetched Name: $name');
      debugPrint('Fetched Branch: $userBranch');

      if (mounted) {
        setState(() {
          userName = name ?? "User Name";
          branch = userBranch ?? "Branch Name";
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> updateUserName() async {
    final TextEditingController nameController = TextEditingController();
    nameController.text = userName ?? "";

    showDialog(
      context: context,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: AppStyle.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppStyle.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppStyle.text.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Update Name",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ProductSans',
                    color: AppStyle.text,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(
                    color: AppStyle.text,
                    fontFamily: 'ProductSans',
                  ),
                  cursorColor: AppStyle.accent,
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    hintStyle: TextStyle(
                      color: AppStyle.text.withValues(alpha: 0.5),
                      fontFamily: 'ProductSans',
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppStyle.text.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppStyle.accent,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppStyle.rule.withValues(alpha: .65),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppStyle.danger,
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isNotEmpty) {
                          await ProfileRepository.saveUserName(newName);
                          if (!mounted || !context.mounted) return;
                          if (mounted) {
                            setState(() {
                              userName = newName;
                            });
                          }
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.accent.withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.black87,
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refreshPage() async {
    setState(() {
      _refreshFuture = loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Profile",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppStyle.text,
            fontFamily: 'ProductSans',
            letterSpacing: -.5,
          ),
        ),
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: FutureBuilder<void>(
        future: _refreshFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading profile data",
                style: TextStyle(color: AppStyle.text),
              ),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              ProfileCard(
                userName: userName ?? "User Name",
                branch: branch ?? "Branch Name",
                onEditName: updateUserName,
              ),
            ],
          );
        },
      ),
    );
  }
}
