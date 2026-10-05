import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_sheets_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_logo.dart';
import '../../shared/widgets/tappable.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  bool _isLogin = true;
  UserRole _selectedRole = UserRole.patient;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Female';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _showForgotPasswordSheet() {
    final emailC = TextEditingController(text: _emailController.text);
    final newPassC = TextEditingController();
    final confirmC = TextEditingController();
    bool busy = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your registered email and a new password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Registered Email',
                  hintText: 'Enter your email',
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(CupertinoIcons.mail, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'New Password',
                  hintText: 'Enter new password',
                  controller: newPassC,
                  obscureText: true,
                  prefixIcon: const Icon(CupertinoIcons.lock, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm New Password',
                  hintText: 'Re-enter new password',
                  controller: confirmC,
                  obscureText: true,
                  prefixIcon: const Icon(CupertinoIcons.lock_shield, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 20),
                GlowButton(
                  label: busy ? 'Updating...' : 'Update Password',
                  width: double.infinity,
                  style: GlowButtonStyle.primary,
                  onPressed: busy
                      ? null
                      : () async {
                          if (emailC.text.trim().isEmpty || newPassC.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
                            return;
                          }
                          if (newPassC.text != confirmC.text) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                            return;
                          }
                          setSheetState(() => busy = true);
                          final res = await GoogleSheetsAuthService().forgotPassword(
                            email: emailC.text.trim(),
                            role: _selectedRole == UserRole.doctor ? 'doctor' : 'patient',
                            newPassword: newPassC.text.trim(),
                          );
                          setSheetState(() => busy = false);
                          if (!context.mounted) return;
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['ok'] == true ? 'Password updated! Please sign in.' : (res['message']?.toString() ?? 'Failed'))),
                          );
                        },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final notifier = ref.read(authProvider.notifier);

    final Map<String, dynamic> res = _isLogin
        ? await notifier.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _selectedRole,
          )
        : await notifier.register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
            phone: _phoneController.text.trim(),
            age: _ageController.text.trim(),
            gender: _selectedGender,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['ok'] == true) {
      if (_selectedRole == UserRole.doctor) {
        context.go('/doctor/dashboard');
      } else {
        context.go('/patient/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: GlowLogo(
                  size: 72,
                  variant: GlowLogoVariant.onGradient,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _isLogin ? 'Welcome Back to GlowAI' : 'Create Your Account',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _isLogin
                      ? 'Sign in to access your skin reports & consultations'
                      : 'Join GlowAI for smart skin analysis and dermatological care',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Segmented Role Selector Control
              const Text(
                'Account Role',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.patient;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.patient
                                ? AppColors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedRole == UserRole.patient
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Patient',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedRole == UserRole.patient
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.doctor;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.doctor
                                ? AppColors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedRole == UserRole.doctor
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Doctor',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedRole == UserRole.doctor
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!_isLogin) ...[
                AppTextField(
                  label: 'Full Name',
                  hintText: 'Enter your name',
                  controller: _nameController,
                  prefixIcon: const Icon(CupertinoIcons.person, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone Number',
                  hintText: 'Enter your 10 digit phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  digitsOnly: true,
                  prefixIcon: const Icon(CupertinoIcons.phone, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Age',
                  hintText: 'Enter your age',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  digitsOnly: true,
                  prefixIcon: const Icon(CupertinoIcons.calendar, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: ['Male', 'Female', 'Other'].map((g) {
                      final selected = _selectedGender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: selected
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              g,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              AppTextField(
                label: 'Email / Phone',
                hintText: 'Enter email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(CupertinoIcons.mail, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Password',
                hintText: 'Enter password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(CupertinoIcons.lock, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 10),

              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: Tappable(
                    onTap: _showForgotPasswordSheet,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              GlowButton(
                label: _isLoading
                    ? 'Please wait...'
                    : (_isLogin ? 'Sign In' : 'Register Now'),
                width: double.infinity,
                style: GlowButtonStyle.primary,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Tappable(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Sign Up' : 'Sign In',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
