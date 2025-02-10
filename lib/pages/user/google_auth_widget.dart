import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabase = Supabase.instance.client;

class SignInWidget extends StatefulWidget {
  const SignInWidget({Key? key}) : super(key: key);

  @override
  State<SignInWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  String? _userId;
  String? _email;
  String? _fullName;
  bool _isLoading = false;
  DateTime? _lastLoginTime;
  DateTime? _lastLogoutTime;

  @override
  void initState() {
    super.initState();
    _initializeAuthStateListener();
    _checkSession();
    _loadCooldownTimes();
  }

  // Load stored cooldown times from SharedPreferences
  Future<void> _loadCooldownTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastLoginTime =
          DateTime.tryParse(prefs.getString('lastLoginTime') ?? '');
      _lastLogoutTime =
          DateTime.tryParse(prefs.getString('lastLogoutTime') ?? '');
    });
  }

  // Save cooldown times to SharedPreferences
  Future<void> _saveCooldownTimes() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastLoginTime != null) {
      prefs.setString('lastLoginTime', _lastLoginTime!.toIso8601String());
    }
    if (_lastLogoutTime != null) {
      prefs.setString('lastLogoutTime', _lastLogoutTime!.toIso8601String());
    }
  }

  // Check if the user is already signed in
  void _checkSession() {
    final session =
        supabase.auth.currentSession; // Correct method to get the session
    if (session != null && session.user != null) {
      setState(() {
        _userId = session.user?.id;
        _email = session.user?.email;
        _fullName =
            session.user?.userMetadata?['full_name'] as String? ?? 'No Name';
      });
    }
  }

  // Initialize the listener for auth state changes
  void _initializeAuthStateListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;

      if (user != null) {
        setState(() {
          _userId = user.id;
          _email = user.email;
          _fullName = user.userMetadata?['full_name'] as String? ?? 'No Name';
        });
      } else {
        setState(() {
          _userId = null;
          _email = null;
          _fullName = null;
        });
      }
    });
  }

  // Handle Google sign-in
  Future<void> _signInWithGoogle() async {
    // Cooldown check (30 minutes)
    if (_lastLoginTime != null &&
        DateTime.now().difference(_lastLoginTime!).inMinutes < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only log in once every 30 minutes')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const webClientId =
        '722495505334-pqlj40pv7mgipconaq36mf3dtecl0b4m.apps.googleusercontent.com';

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled sign-in
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth tokens.';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      setState(() {
        _userId = supabase.auth.currentSession?.user?.id;
        _email = supabase.auth.currentSession?.user?.email;
        _fullName =
            supabase.auth.currentSession?.user?.userMetadata?['full_name'] ??
                'No Name';
        _lastLoginTime = DateTime.now();
      });

      // Save the login time in SharedPreferences
      await _saveCooldownTimes();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle sign-out
  Future<void> _signOut() async {
    // Cooldown check (30 minutes)
    if (_lastLogoutTime != null &&
        DateTime.now().difference(_lastLogoutTime!).inMinutes < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only log out once every 30 minutes')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.auth.signOut();
      setState(() {
        _userId = null;
        _email = null;
        _fullName = null;
        _lastLogoutTime = DateTime.now();
      });

      // Save the logout time in SharedPreferences
      await _saveCooldownTimes();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-out failed: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_userId != null)
            Container(
              width: double.infinity, // Makes the box cover full width
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1D1E).withOpacity(0.6),
                    Colors.grey.shade800.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Account: $_fullName',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_email',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _signOut,
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity, // Makes the box cover full width
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1D1E).withOpacity(0.6),
                    Colors.grey.shade800.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Not signed in',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signInWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/file assets/googleicon.png', // Ensure the logo image is in the assets folder
                          height: 24, // Adjust the size of the logo
                          width: 24,
                        ),
                        const SizedBox(
                            width: 16), // Spacing between the logo and text
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
