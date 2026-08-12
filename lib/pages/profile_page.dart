import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'history_page.dart'; // ✅ อย่าลืมตรวจสอบว่าไฟล์ history_page.dart อยู่โฟลเดอร์เดียวกัน

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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

/// ============ หน้าโปรไฟล์หลัก ============
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/Log_Reg', (_) => false);
      });
      return const SizedBox();
    }

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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String sessionCount = '0';
          String totalHours = '0';
          String displayName = user!.displayName ?? 'No Name';
          String avatarAsset = 'assets/avatar_male.jpg';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final stats = data['stats'] as Map<String, dynamic>?;

            if (stats != null) {
              sessionCount = (stats['sessions'] ?? 0).toString();
              double mins = (stats['total_minutes'] ?? 0).toDouble();
              totalHours = (mins / 60).toStringAsFixed(1);
            }

            if (data.containsKey('username')) {
              displayName = data['username'];
            }
            if (data['avatar_type'] == 'female') {
              avatarAsset = 'assets/avatar_female.jpg';
            }
          }

          final joinDate = user!.metadata.creationTime != null
              ? DateFormat('MMM yyyy').format(user!.metadata.creationTime!)
              : 'Unknown';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(avatarAsset),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: _titleColor)),
                              const SizedBox(height: 4),
                              Text(user!.email ?? '',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _titleColor.withOpacity(0.7))),
                              const SizedBox(height: 2),
                              Text('Joined $joinDate',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _titleColor.withOpacity(0.7))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: _titleColor),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileEditPage()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: _titleColor.withOpacity(0.1)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatBox(value: sessionCount, label: 'Sessions'),
                        const SizedBox(width: 24),
                        _StatBox(value: '$totalHours hr', label: 'Total Time'),
                        const Spacer(),
                        const Icon(Icons.bar_chart_rounded,
                            size: 28, color: _titleColor),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Tile(
                icon: Icons.history_rounded,
                label: 'Activity History',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                ),
              ),
              _Tile(
                icon: Icons.person_rounded,
                label: 'Edit Profile',
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
                icon: Icons.shield_outlined,
                label: 'Privacy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPage()),
                ),
              ),
              const SizedBox(height: 8),
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
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/Log_Reg', (route) => false);
                    }
                  },
                  child: const Text('Log Out',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white)),
                ),
              ),
            ],
          );
        },
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
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _titleColor)),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: _titleColor.withOpacity(0.7))),
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
              color: _titleColor.withOpacity(0.1),
            ),
            child: Icon(icon, color: _titleColor),
          ),
          title: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _titleColor)),
          trailing: const Icon(Icons.chevron_right, color: _titleColor),
          onTap: onTap,
        ),
      );
}

/// ============ หน้าแก้ไขโปรไฟล์ (Avatar + Info) ============
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  DateTime? _dob;
  User? get user => FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String _selectedAvatar = 'male';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      _name.text = user!.displayName ?? '';
      _email.text = user!.email ?? '';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('dob')) {
          final timestamp = data['dob'] as Timestamp?;
          if (timestamp != null) setState(() => _dob = timestamp.toDate());
        }
        if (data.containsKey('avatar_type')) {
          setState(() => _selectedAvatar = data['avatar_type']);
        }
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 5),
      initialDate: _dob ?? DateTime(2000, 1, 1),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      if (user?.displayName != _name.text) {
        await user?.updateDisplayName(_name.text);
      }
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': _name.text,
        'dob': _dob,
        'avatar_type': _selectedAvatar,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: _card, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Choose your avatar",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AvatarOption(
                            assetPath: 'assets/avatar_male.jpg',
                            label: 'Male',
                            isSelected: _selectedAvatar == 'male',
                            onTap: () =>
                                setState(() => _selectedAvatar = 'male'),
                          ),
                          const SizedBox(width: 24),
                          _AvatarOption(
                            assetPath: 'assets/avatar_female.jpg',
                            label: 'Female',
                            isSelected: _selectedAvatar == 'female',
                            onTap: () =>
                                setState(() => _selectedAvatar = 'female'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              decoration: _filledInput('Full name'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _email,
                              enabled: false,
                              decoration: _filledInput('Email (Locked)'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickDob,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: _filledInput(
                                    'Birthday',
                                    suffix: const Icon(
                                        Icons.calendar_today_rounded),
                                  ),
                                  controller: TextEditingController(
                                    text: _dob == null
                                        ? ''
                                        : DateFormat('yyyy-MM-dd')
                                            .format(_dob!),
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
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Colors.white)),
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

class _AvatarOption extends StatelessWidget {
  final String assetPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _AvatarOption(
      {required this.assetPath,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.transparent,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(assetPath),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepOrange : Colors.black54,
              )),
        ],
      ),
    );
  }
}

/// ============ หน้าเปลี่ยนรหัสผ่าน (มี Re-authen + Strict Validation) ============
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController(); // ช่องใส่รหัสเก่า
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _isLoading = false;

  // 1. เพิ่มฟังก์ชันตรวจสอบความปลอดภัยรหัสผ่าน (เหมือนหน้า Register)
  String? _validateStrict(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 8) return 'At least 8 characters'; // กฎ 1
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a number'; // กฎ 2
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain uppercase'; // กฎ 3
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      // สร้าง Credential จากรหัสเก่าที่ User กรอก
      final cred = EmailAuthProvider.credential(
          email: user!.email!, password: _current.text);

      // 1. Re-authenticate (ยืนยันว่าเป็นเจ้าของบัญชีจริง)
      await user.reauthenticateWithCredential(cred);

      // 2. ถ้าผ่าน ถึงยอมให้เปลี่ยนรหัสใหม่
      await user.updatePassword(_new.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = e.message ?? 'Error';
        if (e.code == 'wrong-password') msg = 'Incorrect current password.';
        if (e.code == 'weak-password') msg = 'Password is too weak.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                        // รหัสปัจจุบัน
                        _pwdField(_current, 'Current password'),

                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),

                        // รหัสใหม่
                        _pwdField(_new, 'New password',
                            validator: _validateStrict),

                        const SizedBox(height: 12),

                        // ยืนยันรหัสใหม่
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white)),
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

  // แก้ไข _pwdField ให้รับ Validator แบบกำหนดเองได้
  Widget _pwdField(TextEditingController c, String label,
          {String? Function(String?)? validator}) =>
      TextFormField(
        controller: c,
        obscureText: !_show,
        decoration: _filledInput(label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _show = !_show),
          ),
        ),
        // ถ้าส่ง validator มาให้ใช้ ถ้าไม่ส่งให้ใช้ตัว Default (เช็คแค่ความยาว)
        validator:
            validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      );
}

/// ============ หน้า Privacy ============
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
                  '• เราเก็บข้อมูลบัญชีผู้ใช้ (ชื่อ อีเมล) เพื่อให้บริการ\n'
                  '• ข้อมูลรูป/วิดีโอใช้เพื่อการวิเคราะห์ท่าทางเท่านั้น\n'
                  '• ผู้ใช้สามารถขอลบบัญชี/ข้อมูลได้ตลอดเวลา\n'
                  '• เป็นโปรเจคจบสาขาวิทยาการคอมพิวเตอร์',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
