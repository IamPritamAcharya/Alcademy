import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AcademicWebViewPage extends StatefulWidget {
  @override
  _AcademicWebViewPageState createState() => _AcademicWebViewPageState();
}

class _AcademicWebViewPageState extends State<AcademicWebViewPage> {
  late final WebViewController _webViewController;
  bool isLoading = true;
  bool isDesktopView = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(isDesktopView
          ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
          : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) {
            _injectViewportMetaTag();
            setState(() {
              isLoading = false;
            });
          },
        ),
      );
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    try {
      await _webViewController.loadRequest(Uri.parse(
          'https://igit.icrp.in/academic/Student-cp/Students_profile.aspx'));
    } catch (e) {
      await _webViewController
          .loadRequest(Uri.parse('https://igit.icrp.in/academic/'));
    }
  }

  Future<void> _relogin() async {
    setState(() {
      isLoading = true;
    });
    await _webViewController
        .loadRequest(Uri.parse('https://igit.icrp.in/academic/'));
  }

  Future<void> _toggleDesktopView() async {
    setState(() {
      isDesktopView = !isDesktopView;
    });

    // user agent
    await _webViewController.setUserAgent(isDesktopView
        ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36');

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
        onPopInvoked: (didPop) async {
          if (didPop) return;

          if (await _webViewController.canGoBack()) {
            await _webViewController.goBack();
          } else {
        
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1D1E),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                if (await _webViewController.canGoBack()) {
                  await _webViewController.goBack();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              isDesktopView ? 'Desktop View' : 'Mobile View',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'ProductSans',
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Colors.white.withOpacity(0.6),
                height: 1,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDesktopView
                      ? Icons.desktop_windows_rounded
                      : Icons.smartphone_rounded,
                  color: Colors.white,
                ),
                tooltip:
                    isDesktopView ? 'Switch to Mobile' : 'Switch to Desktop',
                onPressed: _toggleDesktopView,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: _relogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2F30),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (isLoading)
                Container(
                  color: const Color(0xFF1A1D1E).withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          backgroundColor: const Color(0xFF1A1D1E),
                        ),
                        SizedBox(height: 16),
                        Text(
                          isDesktopView
                              ? 'Loading Desktop View...'
                              : 'Loading Mobile View...',
                          style: TextStyle(
                            color: Colors.white,
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
        ));
  }
}
