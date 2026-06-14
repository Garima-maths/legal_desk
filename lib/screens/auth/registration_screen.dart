import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Clean advocate sign-up form. Creates a Firebase email/password account and
/// saves the profile to `users/{uid}`.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _chamber = TextEditingController();
  final _barNumber = TextEditingController();
  final _organization = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _mobile,
      _chamber,
      _barNumber,
      _organization,
      _city,
      _pincode,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.registerAdvocate(
        name: _name.text.trim(),
        email: _email.text.trim(),
        mobile: _mobile.text.trim(),
        chamberNumber: _chamber.text.trim(),
        barNumber: _barNumber.text.trim(),
        organization: _organization.text.trim(),
        city: _city.text.trim(),
        pincode: _pincode.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Sign Up')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Create your account',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Register as an advocate to get started.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            _field(_name, 'Full name',
                validator: (v) => _required(v, 'Full name')),
            _field(
              _email,
              'Email ID',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final r = _required(v, 'Email');
                if (r != null) return r;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(v!.trim());
                return ok ? null : 'Enter a valid email address';
              },
            ),
            _field(
              _mobile,
              'Mobile number',
              keyboardType: TextInputType.phone,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                final r = _required(v, 'Mobile number');
                if (r != null) return r;
                return v!.trim().length == 10
                    ? null
                    : 'Enter a valid 10-digit number';
              },
            ),
            _field(_barNumber, 'Bar enrollment number',
                validator: (v) => _required(v, 'Bar enrollment number')),
            _field(_chamber, 'Chamber number (optional)'),
            _field(_organization, 'Organization (optional)'),
            _field(_city, 'City (optional)'),
            _field(
              _pincode,
              'Pin code (optional)',
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                // Optional, but if provided must be a valid 6-digit pin code.
                if (v == null || v.trim().isEmpty) return null;
                return v.trim().length == 6
                    ? null
                    : 'Enter a valid 6-digit pin code';
              },
            ),
            _field(
              _password,
              'Password',
              obscure: _obscure,
              suffix: IconButton(
                icon:
                    Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Use at least 6 characters'
                  : null,
            ),
            _field(
              _confirm,
              'Confirm password',
              obscure: _obscure,
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? keyboardType,
    bool obscure = false,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        obscureText: obscure,
        inputFormatters: formatters,
        validator: validator,
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
      ),
    );
  }
}
