import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_sheets_auth_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glow_button.dart';

class EditDoctorProfileScreen extends ConsumerStatefulWidget {
  const EditDoctorProfileScreen({super.key});

  @override
  ConsumerState<EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends ConsumerState<EditDoctorProfileScreen> {
  final _name = TextEditingController();
  final _specialty = TextEditingController();
  final _experience = TextEditingController();
  final _languages = TextEditingController();
  final _fee = TextEditingController();
  final _bio = TextEditingController();
  final _clinic = TextEditingController();
  final _phone = TextEditingController();
  final _modes = TextEditingController();
  bool _saving = false;
  bool _available = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authProvider);
    try {
      final res = await GoogleSheetsAuthService().listDoctors();
      if (res['ok'] == true && res['doctors'] is List) {
        for (final d in res['doctors'] as List) {
          final m = d as Map;
          if (m['id']?.toString() == user.id) {
            _name.text = m['name']?.toString() ?? user.name;
            _specialty.text = m['specialty']?.toString() ?? '';
            _experience.text = m['experience']?.toString() ?? '';
            _languages.text = m['languages']?.toString() ?? '';
            _fee.text = m['fee']?.toString() ?? '';
            _bio.text = m['bio']?.toString() ?? '';
            _clinic.text = m['clinicAddress']?.toString() ?? '';
            _phone.text = m['phone']?.toString() ?? '';
            _modes.text = m['modes']?.toString() ?? '';
            _available = m['isAvailable'] == null ? true : (m['isAvailable'] is bool ? m['isAvailable'] as bool : m['isAvailable'].toString().toLowerCase() == 'true');
            break;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final c in [_name, _specialty, _experience, _languages, _fee, _bio, _clinic, _phone, _modes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authProvider);
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    final res = await GoogleSheetsAuthService().updateDoctorProfile(
      id: user.id,
      name: _name.text.trim(),
      specialty: _specialty.text.trim(),
      experience: _experience.text.trim(),
      languages: _languages.text.trim(),
      fee: _fee.text.trim(),
      bio: _bio.text.trim(),
      clinicAddress: _clinic.text.trim(),
      phone: _phone.text.trim(),
      modes: _modes.text.trim(),
      isAvailable: _available ? 'true' : 'false',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['ok'] == true) {
      ref.read(authProvider.notifier).updateName(_name.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Update failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppScaffold(title: 'Edit Profile', body: Center(child: CircularProgressIndicator()));
    }
    return AppScaffold(
      title: 'Edit Profile',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTextField(label: 'Name', hintText: 'Dr. Name', controller: _name),
          const SizedBox(height: 12),
          AppTextField(label: 'Specialty', hintText: 'Dermatologist', controller: _specialty),
          const SizedBox(height: 12),
          AppTextField(label: 'Experience', hintText: '10 years', controller: _experience),
          const SizedBox(height: 12),
          AppTextField(label: 'Languages (comma separated)', hintText: 'English, Hindi', controller: _languages),
          const SizedBox(height: 12),
          AppTextField(label: 'Consultation Fee (₹)', hintText: '499', controller: _fee, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(label: 'Bio', hintText: 'About you', controller: _bio, maxLines: 3),
          const SizedBox(height: 12),
          AppTextField(label: 'Clinic Address', hintText: 'Clinic location', controller: _clinic),
          const SizedBox(height: 12),
          AppTextField(label: 'Phone', hintText: 'Number', controller: _phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          AppTextField(label: 'Modes', hintText: 'chat, voice, video', controller: _modes),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Available / Busy'),
            value: _available,
            onChanged: (v) => setState(() => _available = v),
          ),
          const SizedBox(height: 20),
          GlowButton(
            label: _saving ? 'Saving...' : 'Save Changes',
            width: double.infinity,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
