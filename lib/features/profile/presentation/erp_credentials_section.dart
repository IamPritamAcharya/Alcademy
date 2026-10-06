import 'package:flutter/material.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/shared/theme/app_style.dart';

class ErpCredentialsSection extends StatefulWidget {
  final ErpCredentialsRepository repository;
  const ErpCredentialsSection({super.key, required this.repository});

  @override
  State<ErpCredentialsSection> createState() => _ErpCredentialsSectionState();
}

class _ErpCredentialsSectionState extends State<ErpCredentialsSection> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  ErpCredentials? _saved;
  bool _loading = true;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await widget.repository.read();
      if (!mounted) return;
      _saved = saved;
      _username.text = saved?.username ?? '';
      _error = null;
    } catch (_) {
      if (!mounted) return;
      _error = 'Couldn’t read secure storage. Please try again.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final credentials = ErpCredentials(
        username: _username.text.trim(),
        password: _password.text.isEmpty ? _saved!.password : _password.text,
      );
      await widget.repository.save(credentials);
      if (!mounted) return;
      setState(() {
        _saved = credentials;
        _password.clear();
        _obscure = true;
        _error = null;
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ERP credentials saved securely on this device.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t save securely. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forget() async {
    setState(() => _busy = true);
    try {
      await widget.repository.delete();
      if (!mounted) return;
      setState(() {
        _saved = null;
        _username.clear();
        _password.clear();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saved ERP credentials removed. Automatic login is off.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn’t remove credentials. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppStyle.rule),
          const SizedBox(height: 24),
          const Text('ERP / AUTOMATIC LOGIN', style: AppStyle.eyebrow),
          const SizedBox(height: 12),
          const Text(
            'Your ERP account',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Used only for automatic login to the college ERP. Your username and password are stored securely in encrypted storage on this device. They are sent only to the ERP when signing in.',
            style: TextStyle(color: AppStyle.muted, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_saved != null) ...[
              const Text(
                'Automatic login is enabled',
                style: TextStyle(color: AppStyle.success, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _username,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'ERP username'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your ERP username'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_busy) _save();
              },
              decoration: InputDecoration(
                labelText: 'ERP password',
                helperText: _saved != null
                    ? 'Leave empty to keep your saved password.'
                    : null,
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: _busy
                      ? null
                      : () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) && _saved == null
                  ? 'Enter your ERP password'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppStyle.danger)),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: Icon(
                    _busy
                        ? Icons.hourglass_top_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('Save credentials'),
                ),
                if (_saved != null)
                  TextButton(
                    onPressed: _busy ? null : _forget,
                    child: const Text('Forget credentials'),
                  ),
                if (_error != null)
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Retry storage'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Removing saved credentials stops automatic login. It does not sign out an existing ERP session.',
              style: TextStyle(
                color: AppStyle.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
