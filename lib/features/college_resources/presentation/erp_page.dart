import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/features/college_resources/data/erp_session_manager.dart';
import 'package:port/features/college_resources/presentation/erp_auto_login.dart';
import 'package:port/features/profile/presentation/profile_page.dart';

class AcademicWebViewPage extends StatefulWidget {
  const AcademicWebViewPage({super.key});

  @override
  State<AcademicWebViewPage> createState() => _AcademicWebViewPageState();
}

class _AcademicWebViewPageState extends State<AcademicWebViewPage> {
  late final WebViewController _webViewController;
  bool isLoading = true;
  bool isDesktopView = false;
  final _credentialsRepository = const ErpCredentialsRepository();
  ErpCredentials? _credentials;
  bool _attemptedAutoLogin = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        isDesktopView
            ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            try {
              await _injectViewportMetaTag();
              await _autoLogin(url);
            } catch (_) {
              // Keep the website available for manual login if scripting fails.
            }
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => isLoading = false);
            }
          },
        ),
      );
    await ErpSessionManager.prepare();
    await _readCredentials();
    if (mounted) await _loadInitialPage();
  }

  Future<void> _readCredentials() async {
    try {
      _credentials = await _credentialsRepository.read();
    } catch (_) {
      _credentials = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t read saved ERP credentials. You can still sign in manually.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _autoLogin(String url) async {
    final credentials = _credentials;
    if (_attemptedAutoLogin ||
        credentials == null ||
        !ErpAutoLogin.isLoginPage(url)) {
      return;
    }
    _attemptedAutoLogin = true;
    await _webViewController.runJavaScript(ErpAutoLogin.script(credentials));
  }

  Future<void> _openCredentials() async {
    final previous = _credentials;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserProfilePage(
          focusErpCredentials: true,
          erpCredentials: _credentialsRepository,
        ),
      ),
    );
    if (!mounted) return;
    await _readCredentials();
    if (!mounted) return;
    final current = _credentials;
    if (current != null &&
        (current.username != previous?.username ||
            current.password != previous?.password)) {
      await ErpSessionManager.prepare();
      if (mounted) await _relogin();
    }
  }

  Future<void> _loadInitialPage() async {
    try {
      await _webViewController.loadRequest(
        Uri.parse(
          'https://igit.icrp.in/academic/Student-cp/Students_profile.aspx',
        ),
      );
    } catch (e) {
      await _webViewController.loadRequest(
        Uri.parse('https://igit.icrp.in/academic/'),
      );
    }
  }

  Future<void> _relogin() async {
    _attemptedAutoLogin = false;
    setState(() {
      isLoading = true;
    });
    await _webViewController.loadRequest(ErpAutoLogin.loginUri);
  }

  Future<void> _toggleDesktopView() async {
    setState(() {
      isDesktopView = !isDesktopView;
    });

    // user agent
    await _webViewController.setUserAgent(
      isDesktopView
          ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
          : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
    );

    // viewport changes
    await _injectViewportMetaTag();
  }

  Future<void> _injectViewportMetaTag() async {
    if (isDesktopView) {
      await _webViewController.runJavaScript("""
        (function() {
          let existingMeta = document.querySelector('meta[name="viewport"]');
          if (existingMeta) {
            existingMeta.remove();
          }
          
          let meta = document.createElement('meta');
          meta.name = "viewport";
          meta.content = "width=1200, initial-scale=0.6, maximum-scale=2.0, user-scalable=yes";
          document.head.appendChild(meta);
          
          if (document.body) {
            document.body.style.minWidth = '1200px';
            document.body.style.zoom = '0.8';
          }
        })();
      """);
    } else {
      await _webViewController.runJavaScript("""
        (function() {
          let existingMeta = document.querySelector('meta[name="viewport"]');
          if (existingMeta) {
            existingMeta.remove();
          }
          
          let meta = document.createElement('meta');
          meta.name = "viewport";
          meta.content = "width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes";
          document.head.appendChild(meta);
          
          if (document.body) {
            document.body.style.minWidth = '';
            document.body.style.zoom = '';
          }
        })();
      """);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (await _webViewController.canGoBack()) {
          await _webViewController.goBack();
        } else {
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppStyle.background,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppStyle.text),
            onPressed: () async {
              if (await _webViewController.canGoBack()) {
                await _webViewController.goBack();
              } else {
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'ERP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppStyle.text,
              fontSize: 16,
              fontFamily: 'ProductSans',
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: AppStyle.text.withValues(alpha: 0.6),
              height: 1,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: _openCredentials,
              icon: const Icon(Icons.key_rounded, size: 18),
              label: const Text('Credentials'),
              style: TextButton.styleFrom(foregroundColor: AppStyle.text),
            ),
            IconButton(
              icon: Icon(
                isDesktopView
                    ? Icons.desktop_windows_rounded
                    : Icons.smartphone_rounded,
                color: AppStyle.text,
              ),
              tooltip: isDesktopView ? 'Switch to Mobile' : 'Switch to Desktop',
              onPressed: _toggleDesktopView,
            ),
            IconButton(
              onPressed: _relogin,
              tooltip: 'Retry ERP login',
              icon: const Icon(Icons.login_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (isLoading)
              Container(
                color: AppStyle.background.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppStyle.text,
                        backgroundColor: AppStyle.background,
                      ),
                      SizedBox(height: 16),
                      Text(
                        isDesktopView
                            ? 'Loading Desktop View...'
                            : 'Loading Mobile View...',
                        style: TextStyle(
                          color: AppStyle.text,
                          fontSize: 16,
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
