import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/erp_credentials_repository.dart';
import '../data/erp_session_manager.dart';
import 'erp_auto_login.dart';
import '../data/erp_data_flow.dart';

/// A mounted, non-interactive browser uses the same native cookie store as ERP.
/// Only the requested data reaches the native UI; credentials stay in secure storage.
class ErpDataSession<T> extends StatefulWidget {
  final ValueChanged<T> onLoaded;
  final ValueChanged<ErpDataException> onError;
  final ValueChanged<String> onStatus;
  final Uri target;
  final String resource;
  final String extractionScript;
  final String? Function(Object) decode;
  final T Function(String) parse;
  final Duration timeout;
  const ErpDataSession({
    required this.target,
    required this.resource,
    required this.extractionScript,
    required this.decode,
    required this.parse,
    this.timeout = const Duration(seconds: 45),
    super.key,
    required this.onLoaded,
    required this.onError,
    required this.onStatus,
  });
  @override
  State<ErpDataSession<T>> createState() => _ErpDataSessionState<T>();
}

class _ErpDataSessionState<T> extends State<ErpDataSession<T>> {
  WebViewController? _controller;
  ErpDataFlow<T>? _flow;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await ErpSessionManager.prepare();
      if (!mounted) return;
      final controller = WebViewController();
      final flow = ErpDataFlow<T>(
        target: widget.target,
        resource: widget.resource,
        parse: widget.parse,
        readCredentials: const ErpCredentialsRepository().read,
        navigate: controller.loadRequest,
        signIn: (credentials) async {
          final value = await controller.runJavaScriptReturningResult(
            ErpAutoLogin.script(credentials),
          );
          return value == 'submitted' || value == '"submitted"';
        },
        readMarkup: () async {
          final deadline = DateTime.now().add(widget.timeout);
          while (DateTime.now().isBefore(deadline)) {
            if (!mounted || _flow?.active == false) {
              throw const FormatException('ERP loading was cancelled.');
            }
            final result = widget.decode(
              await controller.runJavaScriptReturningResult(
                widget.extractionScript,
              ),
            );
            if (result != null) return result;
            await Future<void>.delayed(const Duration(milliseconds: 400));
          }
          throw FormatException(
            'ERP took too long to return ${widget.resource}.',
          );
        },
        onLoaded: (data) {
          _timeout?.cancel();
          if (mounted) widget.onLoaded(data);
        },
        onError: (error) {
          _timeout?.cancel();
          if (mounted) widget.onError(error);
        },
        onStatus: (message) {
          if (mounted) widget.onStatus(message);
        },
      );
      _flow = flow;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.isMainFrame || ErpDataFlow.trusted(request.url)) {
              return NavigationDecision.navigate;
            }
            flow.fail(
              const ErpDataException(
                ErpDataFailure.connection,
                'ERP redirected to an unexpected website.',
              ),
            );
            return NavigationDecision.prevent;
          },
          onPageFinished: flow.pageFinished,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              flow.fail(
                const ErpDataException(
                  ErpDataFailure.connection,
                  'Couldn’t reach ERP. Check your connection and try again.',
                ),
              );
            }
          },
        ),
      );
      if (!mounted) {
        flow.cancel();
        return;
      }
      setState(() => _controller = controller);
      // Mount the platform view before navigating so both Android and iOS can
      // finish page loading and execute JavaScript while showing the native UI.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _timeout = Timer(
          widget.timeout,
          () => flow.fail(
            const ErpDataException(
              ErpDataFailure.connection,
              'ERP took too long to respond. Please try again.',
            ),
          ),
        );
        try {
          await flow.start();
        } catch (_) {
          flow.fail(
            const ErpDataException(
              ErpDataFailure.connection,
              'Couldn’t open ERP. Please try again.',
            ),
          );
        }
      });
    } catch (_) {
      if (mounted) {
        widget.onError(
          const ErpDataException(
            ErpDataFailure.connection,
            'The ERP connection couldn’t start on this device.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _controller == null
      ? const SizedBox.shrink()
      : ExcludeSemantics(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: WebViewWidget(controller: _controller!),
              ),
            ),
          ),
        );

  @override
  void dispose() {
    _timeout?.cancel();
    _flow?.cancel();
    super.dispose();
  }
}
