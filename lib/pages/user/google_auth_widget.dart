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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '722495505334-m9rbec4ncl2rb26skkp1cviq2d8duh4e.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();

    _initializeAuthStateListener();
    _checkSession();
    _loadCooldownTimes();
  }

  Future<void> _loadCooldownTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginString = prefs.getString('lastLoginTime') ?? '';
      final lastLogoutString = prefs.getString('lastLogoutTime') ?? '';

      setState(() {
        _lastLoginTime = DateTime.tryParse(lastLoginString);
        _lastLogoutTime = DateTime.tryParse(lastLogoutString);
      });
    } catch (e) {}
  }

  Future<void> _saveCooldownTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastLoginTime != null) {
        final loginTimeString = _lastLoginTime!.toIso8601String();
        await prefs.setString('lastLoginTime', loginTimeString);
      }
      if (_lastLogoutTime != null) {
        final logoutTimeString = _lastLogoutTime!.toIso8601String();
        await prefs.setString('lastLogoutTime', logoutTimeString);
      }
    } catch (e) {}
  }

  void _checkSession() {
    try {
      final session = supabase.auth.currentSession;

      if (session != null) {
        setState(() {
          _userId = session.user.id;
          _email = session.user.email;
          _fullName =
              session.user.userMetadata?['full_name'] as String? ?? 'No Name';
        });

        print(
            ' DEBUG: Set state - userId: $_userId, email: $_email, fullName: $_fullName');
      } else {}
    } catch (e) {}
  }

  void _initializeAuthStateListener() {
    try {
      supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final user = session?.user;

        if (user != null) {
          setState(() {
            _userId = user.id;
            _email = user.email;
            _fullName = user.userMetadata?['full_name'] as String? ?? 'No Name';
          });

          print(
              ' DEBUG: Updated state after auth change - userId: $_userId, email: $_email, fullName: $_fullName');
        } else {
          setState(() {
            _userId = null;
            _email = null;
            _fullName = null;
          });
        }
      });
    } catch (e) {}
  }

  Future<void> _signInWithGoogle() async {
    if (_lastLoginTime != null) {
      final timeDifference =
          DateTime.now().difference(_lastLoginTime!).inMinutes;

      if (timeDifference < 30) {
        print(
            ' DEBUG: Sign-in blocked due to cooldown (${30 - timeDifference} minutes remaining)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can only log in once every 30 minutes')),
        );
        return;
      }
    } else {}

    setState(() {
      _isLoading = true;
    });

    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken != null) {}
      if (idToken != null) {}

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth tokens. AccessToken: $accessToken, IdToken: $idToken';
      }

      final authResponse = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (authResponse.user != null) {}

      final currentSession = supabase.auth.currentSession;

      setState(() {
        _userId = currentSession?.user.id;
        _email = currentSession?.user.email;
        _fullName =
            currentSession?.user.userMetadata?['full_name'] ?? 'No Name';
        _lastLoginTime = DateTime.now();
      });

      await _saveCooldownTimes();
    } catch (error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    if (_lastLogoutTime != null) {
      final timeDifference =
          DateTime.now().difference(_lastLogoutTime!).inMinutes;

      if (timeDifference < 30) {
        print(
            ' DEBUG: Sign-out blocked due to cooldown (${30 - timeDifference} minutes remaining)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can only log out once every 30 minutes')),
        );
        return;
      }
    } else {}

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      setState(() {
        _userId = null;
        _email = null;
        _fullName = null;
        _lastLogoutTime = DateTime.now();
      });

      await _saveCooldownTimes();
    } catch (error, stackTrace) {
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
              width: double.infinity,
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
                      onPressed: _isLoading ? null : _signOut,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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
              width: double.infinity,
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
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'lib/file assets/googleicon.png',
                                height: 24,
                                width: 24,
                              ),
                              const SizedBox(width: 16),
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
