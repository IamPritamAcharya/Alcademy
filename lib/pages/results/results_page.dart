import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultWebView extends StatefulWidget {
  const ResultWebView({Key? key}) : super(key: key);

  @override
  _ResultWebViewState createState() => _ResultWebViewState();
}

class _ResultWebViewState extends State<ResultWebView> {
  WebViewController? _controller;
  String? pdfUrl;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure widget is mounted
    Future.microtask(() {
      if (mounted) {
        _initializeWebView();
      }
    });
  }

  void _initializeWebView() {
    try {
      if (!mounted) return;

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = true;
                });
              }
            },
            onPageFinished: (String url) async {
              try {
                if (_controller != null && mounted) {
                  await _injectCustomScripts();
                  setState(() => isLoading = false);
                }
              } catch (e) {
                _handleError("Script injection error: $e");
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.endsWith(".pdf")) {
                if (mounted) {
                  setState(() {
                    pdfUrl = request.url;
                  });
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              _handleError("Web resource error: ${error.description}");
            },
          ),
        )
        // Set mobile user agent
        ..setUserAgent(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1");

      // Clear cache and load page with sufficient delay
      _controller?.clearCache().then((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && _controller != null) {
              _loadActualPage();
            }
          });
        }
      });
    } catch (e) {
      _handleError("WebView initialization error: $e");
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        hasError = true;
        errorMessage = message;
        isLoading = false;
      });
    }
    debugPrint("WebView error: $message");
  }

  void _loadActualPage() {
    try {
      if (_controller != null && mounted) {
        setState(() {
          isLoading = true;
        });

        _controller!.loadRequest(
            Uri.parse("https://igitsarang.ac.in/downloads/results"));
      }
    } catch (e) {
      _handleError("Failed to load page: $e");
    }
  }

  Future<void> _injectCustomScripts() async {
    if (_controller == null || !mounted) return;

    try {
      // Break the script into smaller chunks to avoid execution issues
      await _controller?.runJavaScript('''
        try {
          // Base styling
          document.body.style.margin = "0";
          document.body.style.padding = "0";
          document.body.style.backgroundColor = "#121212";
          document.body.style.color = "#E0E0E0";
          document.body.style.fontFamily = "Arial, sans-serif";
          document.body.style.lineHeight = "1.6";
          document.body.style.width = "100%";
          
          // Add meta viewport tag
          let viewport = document.querySelector('meta[name="viewport"]');
          if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = "viewport";
            document.head.appendChild(viewport);
          }
          viewport.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
        } catch (error) {
          console.error("Base style error:", error);
        }
      ''');

      // Add the main style sheet
      await _controller?.runJavaScript('''
        try {
          let style = document.createElement('style');
          style.textContent = `
            * {
              max-width: 100vw !important;
              box-sizing: border-box !important;
            }
            
            body {
              display: flex !important;
              flex-direction: column !important;
              align-items: center !important;
              justify-content: center !important;
              min-height: 100vh !important;
              width: 100% !important;
              padding: 0 !important;
              margin: 0 !important;
              text-align: center !important;
            }

            a {
              color: #BB86FC !important;
              text-decoration: none;
            }
            a:hover {
              color: #D0AFFF !important;
              text-decoration: underline;
            }

            .container, .content, div, section, article, aside, header, footer, nav, main {
              width: 100% !important;
              max-width: 100% !important;
              text-align: center !important;
              margin: 0 auto !important;
            }

            h1, h2, h3, h4, h5, h6, p, span, li, a {
              text-align: center !important;
            }

            img {
              max-width: 100% !important;
              height: auto !important;
              margin: 0 auto !important;
            }

            table {
              width: 100% !important;
              max-width: 100% !important;
              background-color: #1E1E1E !important;
              color: #E0E0E0 !important;
              border-collapse: collapse;
              font-size: 14px !important;
              margin: 10px auto !important;
              table-layout: fixed !important;
            }
            th, td {
              padding: 8px !important;
              border: 1px solid #333 !important;
              text-align: center !important;
              font-size: 12px !important;
              word-break: break-word;
            }
            th {
              background-color: #292929 !important;
              color: #FFFFFF !important;
            }
            td {
              background-color: #1E1E1E !important;
            }
            tr:hover {
              background-color: #2A2A2A !important;
            }
            
            button, input[type="submit"] {
              background-color: #BB86FC !important;
              color: #121212 !important;
              border: none !important;
              padding: 8px 16px !important;
              font-size: 14px !important;
              border-radius: 6px;
              cursor: pointer;
              margin: 10px auto !important;
            }
            
            input, select, textarea {
              background-color: #333 !important;
              color: #E0E0E0 !important;
              border: 1px solid #555 !important;
              padding: 8px !important;
              border-radius: 5px !important;
              margin: 5px auto !important;
              text-align: center !important;
            }

            form {
              display: flex !important;
              flex-direction: column !important;
              gap: 10px !important;
              align-items: center !important;
              max-width: 500px !important;
              margin: 0 auto !important;
            }

            /* Remove unwanted elements */
            .top-header, .bottom-header, .manu, .clearfix, .sec5, footer, 
            .inright-cont-hding.faculties-hd, .inright-subcont.bdfont, .lftmnu-hd {
              display: none !important;
            }
          `;
          document.head.appendChild(style);
        } catch (error) {
          console.error("Style injection error:", error);
        }
      ''');

      // Apply mobile table fixes
      await _controller?.runJavaScript('''
        try {
          // Add mobile-specific styles
          let mobileStyle = document.createElement('style');
          mobileStyle.textContent = `
            @media screen and (max-width: 600px) {
              table, thead, tbody, th, td, tr {
                display: block !important;
                width: 100% !important;
                text-align: center !important;
              }
              tr {
                margin-bottom: 15px !important;
                border: 1px solid #555 !important;
              }
              td {
                border: none !important;
                border-bottom: 1px solid #333 !important;
                position: relative !important;
                padding: 8px 5px !important;
                min-height: 30px !important;
              }
            }
          `;
          document.head.appendChild(mobileStyle);
          
          // Fix tables
          const tables = document.querySelectorAll('table');
          tables.forEach(table => {
            table.style.margin = "0 auto";
            table.style.textAlign = "center";
          });
        } catch (error) {
          console.error("Mobile style error:", error);
        }
      ''');

      // Final touches and make page visible
      await _controller?.runJavaScript('''
        try {
          // Ensure HTML and body take full viewport
          document.documentElement.style.height = "100%";
          document.documentElement.style.width = "100%";
          document.documentElement.style.margin = "0";
          document.documentElement.style.padding = "0";
          
          // Show page after styling is complete
          document.body.style.visibility = "visible";
        } catch (error) {
          console.error("Final style error:", error);
        }
      ''');
    } catch (e) {
      _handleError("JavaScript execution error: $e");
    }
  }

  void _resetWebView() {
    if (!mounted) return;

    setState(() {
      pdfUrl = null;
      isLoading = true;
      hasError = false;
      errorMessage = "";
      _controller = null;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _initializeWebView();
      }
    });
  }

  Future<void> _downloadPdf() async {
    if (pdfUrl == null) return;

    try {
      final Uri url = Uri.parse(pdfUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch download URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        centerTitle: true,
        title: Text(
          pdfUrl == null ? "IGIT Results" : "Viewing PDF",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'ProductSans',
            letterSpacing: 2,
          ),
        ),
        leading: pdfUrl != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => pdfUrl = null),
              )
            : null,
        actions: [
          if (pdfUrl != null)
            IconButton(
              icon: const Icon(LineIcons.download),
              onPressed: _downloadPdf,
              tooltip: 'Download PDF',
            ),
          IconButton(
            icon: const Icon(LineIcons.syncIcon),
            onPressed: _resetWebView,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Something went wrong",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _resetWebView,
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              )
            else if (pdfUrl == null && _controller != null)
              WebViewWidget(controller: _controller!),
            if (pdfUrl != null && !isLoading)
              Stack(
                children: [
                  SfPdfViewer.network(
                    pdfUrl!,
                    onDocumentLoadFailed:
                        (PdfDocumentLoadFailedDetails details) {
                      _handleError("Failed to load PDF: ${details.error}");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to load PDF: ${details.error}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: _downloadPdf,
                      backgroundColor: const Color(0xFFBB86FC),
                      child:
                          const Icon(Icons.download, color: Color(0xFF121212)),
                      tooltip: 'Download PDF',
                    ),
                  ),
                ],
              ),
            if (isLoading)
              Container(
                color: const Color(0xFF1A1D1E),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "Loading results...",
                        style: TextStyle(fontSize: 16, color: Colors.white),
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

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }
}
