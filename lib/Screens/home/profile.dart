import 'package:babyshopapp/Screens/home/help_faq_screen.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Customer profile: edit details, demo payment methods, support, logout, delete account.
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
  List<Map<String, dynamic>> _paymentMethods = [];

  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// Pulls name, address, and saved payment methods from Firestore `users/{uid}`.
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
        _paymentMethods = _parsePaymentMethods(data?['paymentMethods']);
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parsePaymentMethods(dynamic raw) {
    final out = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        }
      }
    }
    return out;
  }

  String _avatarInitial(User? user) {
    final name = (_userData?['name'] ?? '').toString().trim();
    final email = (user?.email ?? '').trim();
    final seed = name.isNotEmpty ? name : (email.isNotEmpty ? email : 'U');
    return seed[0].toUpperCase();
  }

  Future<void> _persistPaymentMethods() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ok = await _auth.updateUserData(user.uid, {'paymentMethods': _paymentMethods});
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update payment methods')));
    }
    await _loadUser();
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

  void _showAddPaymentMethodSheet() {
    final labelCtrl = TextEditingController();
    final last4Ctrl = TextEditingController();
    String kind = 'Card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add payment method', style: TextStyle(fontFamily: 'DynaPuff', fontSize: 20)),
              const SizedBox(height: 8),
              Text('Demo only — no real card data is stored.', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: InputDecoration(
                  labelText: 'Method type',
                  prefixIcon: Icon(Icons.payment_outlined, color: teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: torquoise, width: 1.5),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Card', child: Text('Card (last 4 digits)')),
                  DropdownMenuItem(value: 'COD', child: Text('Cash on delivery')),
                ],
                onChanged: (v) => setS(() => kind = v ?? 'Card'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: _dec(kind == 'Card' ? 'Label (e.g. Personal Visa)' : 'Nickname', Icons.label_outline),
              ),
              if (kind == 'Card') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: last4Ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: _dec('Last 4 digits', Icons.numbers_outlined),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: torquoise,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (labelCtrl.text.trim().isEmpty) return;
                    if (kind == 'Card' && last4Ctrl.text.trim().length != 4) return;
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final entry = <String, dynamic>{
                      'id': id,
                      'type': kind,
                      'label': labelCtrl.text.trim(),
                      if (kind == 'Card') 'last4': last4Ctrl.text.trim(),
                    };
                    setState(() => _paymentMethods = [..._paymentMethods, entry]);
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _persistPaymentMethods();
                  },
                  child: const Text('Save method', style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff')),
                ),
              ),
            ],
          ),
        ),
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

  /// Permanent delete — password proves identity; then Firestore profile + Auth user go away.
  void _showDeleteAccountDialog() {
    final pwdCtrl = TextEditingController();
    var busy = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Delete account', style: TextStyle(fontFamily: 'DynaPuff')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This permanently deletes your shop profile and your sign-in. You will need to register again to use the same email.',
                      style: TextStyle(height: 1.35, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pwdCtrl,
                      obscureText: true,
                      enabled: !busy,
                      decoration: _dec('Confirm password', Icons.lock_outline),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: rose),
                  onPressed: busy
                      ? null
                      : () async {
                          final pw = pwdCtrl.text;
                          if (pw.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter your password to confirm.')),
                            );
                            return;
                          }
                          setSt(() => busy = true);
                          final err = await _auth.deleteCurrentUserAccountWithPassword(pw);
                          if (ctx.mounted) setSt(() => busy = false);
                          if (!context.mounted) return;
                          if (err == null) {
                            Navigator.pop(ctx);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                          }
                        },
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Delete my account'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => pwdCtrl.dispose());
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

          Align(
            alignment: Alignment.centerLeft,
            child: Text('Payment methods (demo)', style: TextStyle(fontWeight: FontWeight.w600, color: darkGrey, fontFamily: 'DynaPuff')),
          ),
          const SizedBox(height: 10),
          if (_paymentMethods.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Text('No saved payment methods yet.', style: TextStyle(color: Colors.grey[700])),
            )
          else
            ..._paymentMethods.map((m) {
              final id = m['id']?.toString() ?? '';
              final type = m['type']?.toString() ?? '';
              final label = m['label']?.toString() ?? '';
              final last4 = m['last4']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: ListTile(
                  leading: Icon(type == 'COD' ? Icons.local_shipping_outlined : Icons.credit_card, color: torquoise),
                  title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(type == 'COD' ? 'Cash on delivery' : 'Card ending ···· $last4'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: rose.withOpacity(0.85)),
                    onPressed: () async {
                      setState(() {
                        _paymentMethods = _paymentMethods.where((e) => e['id']?.toString() != id).toList();
                      });
                      await _persistPaymentMethods();
                    },
                  ),
                ),
              );
            }),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, color: torquoise),
              label: const Text('Add payment method', style: TextStyle(color: torquoise, fontFamily: 'DynaPuff')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: torquoise),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showAddPaymentMethodSheet,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.help_outline, color: darkGrey),
              label: const Text('Help & FAQ', style: TextStyle(color: darkGrey, fontFamily: 'DynaPuff')),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: darkGrey.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFaqScreen())),
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

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showDeleteAccountDialog,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: rose.withOpacity(0.85)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Delete my account', style: TextStyle(color: rose, fontFamily: 'DynaPuff')),
            ),
          ),
          const SizedBox(height: 8),

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
