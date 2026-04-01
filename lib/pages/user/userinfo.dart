import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/onboarding/utils/user_data.dart';
import 'package:port/pages/user/NavigationTile.dart';
import 'package:port/pages/user/access.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_auth_widget.dart';
import 'profile_card.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? userName;
  String? branch;
  late Future<void> _refreshFuture;
  bool canUpload = false;

  @override
  void initState() {
    super.initState();
    checkUserAccess();
    _refreshFuture = loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final name = await UserData.getUserName();
      final userBranch = await UserData.getUserBranch();

      print('Fetched Name: $name');
      print('Fetched Branch: $userBranch');

      setState(() {
        userName = name ?? "User Name";
        branch = userBranch ?? "Branch Name";
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> updateUserName() async {
    final TextEditingController nameController = TextEditingController();
    nameController.text = userName ?? "";

    showDialog(
      context: context,
      builder: (context) => Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ProductSans',
                    ),
                    cursorColor: Colors.greenAccent,
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'ProductSans',
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.greenAccent,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
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
                            color: Colors.redAccent,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          if (newName.isNotEmpty) {
                            await UserData.saveUserName(newName);
                            setState(() {
                              userName = newName;
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.withOpacity(0.8),
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
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PROFILE",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'ProductSans',
              letterSpacing: 2),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
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
                style: TextStyle(color: Colors.white),
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
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: SignInWidget(),
              ),
              Expanded(
                child: ListView(
                  children: [
                    NavigationTile(
                      icon: LineIcons.key,
                      title: "API Key",
                      onTap: () {
                        context.push('/api');
                      },
                    ),
                    if (canUpload)
                      NavigationTile(
                        icon: LineIcons.upload,
                        title: "Upload",
                        onTap: () {
                          context.push('/upload');
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> checkUserAccess() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    List<UserAccess> allowedUsers = await fetchAllowedUsers();
    setState(() {
      canUpload = allowedUsers.any((u) => u.userId == user.id);
    });
  }
}
