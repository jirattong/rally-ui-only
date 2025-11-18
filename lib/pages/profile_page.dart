import 'package:flutter/material.dart';

/// ============ สีและสไตล์ร่วม ============
const _bg = Color(0xFFF9EFE6);
const _card = Color(0xFFFBE0CC);
const _accent = Colors.deepOrange;
const _titleColor = Color(0xFF3A5150);

InputDecoration _filledInput(String label, {Widget? suffix}) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

/// ============ หน้าโปรไฟล์หลัก ============
/// ใช้เรียกด้วย route: /Profile
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // ส่วนหัวโปรไฟล์ + สถิติ
          Container(
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar ใช้ Icon ไว้ก่อน (ไม่พึ่ง assets)
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.black12,
                      child:
                          Icon(Icons.person, size: 36, color: Colors.black54),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Iped Noi',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('@yutpauv', style: TextStyle(fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Joined Aug 2025',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black87),
                      onPressed: null, // (optional) แก้จากการ์ดบนสุด
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.black.withOpacity(.15)),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _StatBox(value: '12', label: 'Session'),
                    SizedBox(width: 24),
                    _StatBox(value: '7 hr', label: 'Total'),
                    Spacer(),
                    Icon(Icons.bar_chart_rounded, size: 28),
                    SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // เมนู 4 รายการ
          _Tile(
            icon: Icons.person_rounded,
            label: 'Profile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditPage()),
            ),
          ),
          _Tile(
            icon: Icons.lock_reset_rounded,
            label: 'Change Password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
          _Tile(
            icon: Icons.settings_applications_rounded,
            label: 'App Setting',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingPage()),
            ),
          ),
          _Tile(
            icon: Icons.shield_outlined,
            label: 'Privacy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPage()),
            ),
          ),
          const SizedBox(height: 8),

          // ปุ่มออกจากระบบ → /Log_Reg
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4483C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: เคลียร์ token/session ที่นี่
                Navigator.pushNamedAndRemoveUntil(
                    context, '/Log_Reg', (route) => false);
              },
              child: const Text('Log Out',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black12.withOpacity(.15),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          title: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

/// ============ หน้าแก้ไขโปรไฟล์ ============
/// (ชื่อ, อีเมล, วันเกิด, เปลี่ยนรูป — เป็น stub)
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Iped Noi');
  final _email = TextEditingController(text: 'ipednoi@example.com');
  DateTime? _dob;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 5),
      initialDate: DateTime(2000, 1, 1),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _pickAvatar() {
    // TODO: เปิดกล้อง/แกลเลอรีจริง
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Pick avatar')),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: ส่งข้อมูลไป backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved (stub)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.black12,
                      child:
                          Icon(Icons.person, size: 44, color: Colors.black54),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(.75),
                      ),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickAvatar,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: _filledInput('Full name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: _filledInput('Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Invalid email'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickDob,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _filledInput(
                              'Birthday',
                              suffix: const Icon(Icons.calendar_today_rounded),
                            ),
                            controller: TextEditingController(
                              text: _dob == null
                                  ? ''
                                  : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _save,
                          child: const Text('Save',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============ หน้าเปลี่ยนรหัสผ่าน ============
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: เปลี่ยนรหัสจริง
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Password changed (stub)')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _pwdField(_current, 'Current password'),
                  const SizedBox(height: 12),
                  _pwdField(_new, 'New password'),
                  const SizedBox(height: 12),
                  _pwdField(_confirm, 'Confirm new password'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _submit,
                      child: const Text('Update Password',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: forgot password flow
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Forgot password (stub)')),
                        );
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pwdField(TextEditingController c, String label) => TextFormField(
        controller: c,
        obscureText: !_show,
        decoration: _filledInput(label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _show = !_show),
          ),
        ),
        validator: (v) =>
            (v == null || v.length < 6) ? 'At least 6 characters' : null,
      );
}

/// ============ หน้า App Setting (stub พร้อมสวิตช์ตัวอย่าง) ============
class AppSettingPage extends StatefulWidget {
  const AppSettingPage({super.key});
  @override
  State<AppSettingPage> createState() => _AppSettingPageState();
}

class _AppSettingPageState extends State<AppSettingPage> {
  bool darkMode = false;
  bool notif = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('App Setting',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  value: darkMode,
                  onChanged: (v) {
                    setState(() => darkMode = v);
                    // TODO: apply theme จริง
                  },
                  title: const Text('Dark Mode'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: notif,
                  onChanged: (v) {
                    setState(() => notif = v);
                    // TODO: เปิด/ปิด notification จริง
                  },
                  title: const Text('Notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Language'),
                  subtitle: const Text('Follow system'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language picker (stub)')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============ หน้า Privacy/Terms ============
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Terms',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text(
                  '• เราเก็บข้อมูลบัญชีผู้ใช้ (ชื่อ อีเมล) เพื่อให้บริการและรักษาความปลอดภัย\n'
                  '• ข้อมูลรูป/วิดีโอที่อัปโหลดใช้เพื่อการวิเคราะห์ท่าทางภายในแอปเท่านั้น\n'
                  '• ผู้ใช้สามารถลบบัญชี/ข้อมูลได้ โดยข้อมูลบางส่วนอาจถูกเก็บตามกฎหมาย\n'
                  '• เราใช้คุกกี้และตัววัดผลการใช้งานเพื่อปรับปรุงประสบการณ์ของผู้ใช้\n'
                  '• การใช้งานถือว่ายอมรับข้อกำหนดและนโยบายความเป็นส่วนตัว',
                ),
                SizedBox(height: 16),
                Text('Contact',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('support@rally.ai (ตัวอย่าง)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: mark accepted / save settings
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Accepted (stub)')));
                Navigator.pop(context);
              },
              child: const Text('I Agree',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
