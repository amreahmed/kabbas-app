import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/account_deletion.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Reauthenticate before touching any data, including Google accounts.
      if (user.providerData.any(
        (provider) => provider.providerId == 'password',
      )) {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email!,
            password: _password.text,
          ),
        );
      } else {
        final google = GoogleSignIn();
        await google.signOut();
        final account = await google.signIn();
        if (account == null) return;
        final authentication = await account.authentication;
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(
            accessToken: authentication.accessToken,
            idToken: authentication.idToken,
          ),
        );
      }
      await deleteCurrentAccount(user);
      await GoogleSignIn().signOut();
      if (!mounted) return;
      context.read<CartProvider>().clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف حسابك وبياناتك من كبّاس.')),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = switch (error.code) {
            'wrong-password' || 'invalid-credential' =>
              'كلمة المرور غير صحيحة. لم يكتمل حذف الحساب.',
            'user-mismatch' => 'اختر حساب جوجل المرتبط بحساب كبّاس الحالي.',
            _ =>
              'تعذر تأكيد أو حذف الحساب. أعد المحاولة أو اتصل على 01007658105.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'لم يكتمل الحذف. ربما حُذف جزء من البيانات؛ يمكنك إعادة المحاولة بأمان أو التواصل على 01007658105.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usesPassword =
        FirebaseAuth.instance.currentUser?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('حذف الحساب والبيانات')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            const Text(
              'سيؤدي الحذف إلى إزالة حساب تسجيل الدخول وملفك الشخصي وطلبات الصيانة والخردة وتأسيس المواسير، بما فيها الأسماء وأرقام الهواتف والصور والمواقع المرتبطة بها. لا يمكن التراجع عن الحذف.',
            ),
            const SizedBox(height: 12),
            const Text(
              'رسائل واتساب تظل خارج التطبيق. لطلب حذف المحادثات أو المساعدة اتصل على 01007658105. يتطلب الحذف اتصالاً بالإنترنت وتأكيد هويتك.',
            ),
            if (usesPassword)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                  ),
                ),
              ),
            CheckboxListTile(
              value: _confirmed,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _confirmed = value ?? false),
              title: const Text('أفهم أن حسابي وبياناتي سيتم حذفها نهائياً'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: _confirmed && !_busy ? _delete : null,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('تأكيد الهوية وحذف الحساب'),
            ),
          ],
        ),
      ),
    );
  }
}
