import 'package:babyshopapp/services/auth.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const Color bgColor   = Color(0xFFeef9fa);
  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);
  static const Color darkGrey  = Color(0xFF575757);

  final AuthService _auth = AuthService();
  final ProductService _ps = ProductService();

  Map<String, dynamic>? _userData;
  bool _loading = true;

  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _auth.getUserData(user.uid);
      setState(() {
        _userData = data;
        _loading = false;
        _nameCtrl.text = data?['name'] ?? '';
        _phoneCtrl.text = data?['phone'] ?? '';
        _addressCtrl.text = data?['address'] ?? '';
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  String _avatarInitial(User? user) {
    final name = (_userData?['name'] ?? '').toString().trim();
    final email = (user?.email ?? '').trim();
    final seed = name.isNotEmpty ? name : (email.isNotEmpty ? email : 'U');
    return seed[0].toUpperCase();
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Profile', style: TextStyle(fontFamily: 'DynaPuff', fontSize: 20)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: _dec('Name', Icons.person_outline)),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _dec('Phone', Icons.phone_outlined)),
          const SizedBox(height: 12),
          TextField(controller: _addressCtrl, decoration: _dec('Address', Icons.home_outlined)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: torquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                await _auth.updateUserData(user.uid, {
                  'name': _nameCtrl.text.trim(),
                  'phone': _phoneCtrl.text.trim(),
                  'address': _addressCtrl.text.trim(),
                });
                await _loadUser();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff')),
            ),
          ),
        ]),
      ),
    );
  }

  void _showFeedbackDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Support', style: TextStyle(fontFamily: 'DynaPuff')),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe your issue or feedback...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: torquoise),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              await _ps.submitFeedback(userId: user.uid, userEmail: user.email ?? '', message: ctrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback sent! We\'ll get back to you.'), backgroundColor: Color(0xFF2e9fb4)));
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontFamily: 'DynaPuff')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6ecdd4)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: rose.withOpacity(0.2),
            child: Text(
              _avatarInitial(user),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: rose),
            ),
          ),
          const SizedBox(height: 12),
          Text(_userData?['name'] ?? 'Your Name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Info cards
          _InfoCard(icon: Icons.person_outline, label: 'Name', value: _userData?['name'] ?? 'Not set'),
          _InfoCard(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? 'Not set'),
          _InfoCard(icon: Icons.phone_outlined, label: 'Phone', value: _userData?['phone']?.isNotEmpty == true ? _userData!['phone'] : 'Not set'),
          _InfoCard(icon: Icons.home_outlined, label: 'Address', value: _userData?['address']?.isNotEmpty == true ? _userData!['address'] : 'Not set'),

          const SizedBox(height: 24),

          // Edit button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, color: torquoise),
              label: const Text('Edit Profile', style: TextStyle(color: torquoise, fontFamily: 'DynaPuff')),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: torquoise), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _showEditSheet,
            ),
          ),
          const SizedBox(height: 12),

          // Contact support
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.support_agent_outlined, color: teal),
              label: const Text('Contact Support', style: TextStyle(color: teal, fontFamily: 'DynaPuff')),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: teal), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _showFeedbackDialog,
            ),
          ),
          const SizedBox(height: 12),

          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff')),
              style: ElevatedButton.styleFrom(backgroundColor: rose, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;

                if (FirebaseAuth.instance.currentUser != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to log out. Please try again.')),
                  );
                  return;
                }

                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint, prefixIcon: Icon(icon, color: teal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: torquoise, width: 1.5)),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF6ecdd4), size: 22),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}
