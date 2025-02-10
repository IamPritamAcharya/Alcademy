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
      ..setNavigationDelegate(
        NavigationDelegate(
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
    await _webViewController
        .loadRequest(Uri.parse('https://igit.icrp.in/academic/'));
  }

  Future<void> _toggleDesktopView() async {
    setState(() {
      isDesktopView = !isDesktopView;
    });

    // Inject the viewport adjustment script dynamically
    _injectViewportMetaTag();
  }

  Future<void> _injectViewportMetaTag() async {
    if (isDesktopView) {
      // Set desktop width viewport
      await _webViewController.runJavaScript("""
        (function() {
          let meta = document.querySelector('meta[name="viewport"]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = "viewport";
            document.head.appendChild(meta);
          }
          meta.content = "width=1200";
        })();
      """);
    } else {
      // Reset to default responsive viewport
      await _webViewController.runJavaScript("""
        (function() {
          let meta = document.querySelector('meta[name="viewport"]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = "viewport";
            document.head.appendChild(meta);
          }
          meta.content = "width=device-width, initial-scale=1.0";
        })();
      """);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
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
            onPressed: _toggleDesktopView,
          ),
          Padding(
            padding:
                const EdgeInsets.only(right: 0.0), // Add spacing from the right
            child: ElevatedButton(
              onPressed: _relogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                    0xFF2C2F30), // Slightly lighter than the app bar
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20), // Rounded top-left corner
                    bottomLeft:
                        Radius.circular(20), // Rounded bottom-left corner
                  ),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontFamily: 'ProductSans', // Use Product Sans font
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
            Center(
                child: CircularProgressIndicator(
              color: Colors.white,
              backgroundColor: const Color(0xFF1A1D1E),
            )),
        ],
      ),
    );
  }
}
