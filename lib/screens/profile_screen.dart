import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'privacy_screen.dart';
import 'delete_account_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminClaim();
  }

  Future<void> _loadAdminClaim() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult(
        true,
      );
      if (mounted) setState(() => _isAdmin = token?.claims?['admin'] == true);
    } catch (_) {
      // Fail closed when the server cannot verify privileges.
    }
  }

  // دالة تشغيل الروابط والمكالمات
  Future<void> _launchExternal(String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString.trim());
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط المطلوب')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء فتح الرابط: $e')));
    }
  }

  // دالة تأكيد وتسجيل الخروج
  Future<void> _confirmLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // دالة تعديل اسم المستخدم
  Future<void> _showEditNameDialog(
    BuildContext context,
    String currentName,
    User user,
  ) async {
    final controller = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تعديل الاسم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'أدخل اسمك الجديد',
            hintStyle: GoogleFonts.cairo(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await user.updateDisplayName(newName);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({'name': newName}, SetOptions(merge: true));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث الاسم بنجاح! 🎉'),
                        backgroundColor: AppColors.softGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ أثناء التحديث: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حفظ',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // نافذة تغيير وإعادة تعيين كلمة المرور بتصميم احترافي
  void _showChangePasswordModal(BuildContext context, String currentEmail) {
    final emailController = TextEditingController(text: currentEmail);
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5A623), Color(0xFFFF8C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تغيير كلمة المرور',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابطاً آمناً وفورياً لتعيين كلمة مرور جديدة لحسابك.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFF5A623),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ستصلك رسالة بريد تتضمن رابطاً آمناً؛ اضغط عليه لإدخال كلمة المرور الجديدة وتأكيدها.',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.brown.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى كتابة البريد الإلكتروني'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          setModalState(() => isSending = true);
                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: email)
                                .timeout(const Duration(seconds: 4));
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم إرسال رابط تعيين كلمة المرور إلى $email بنجاح! 📧 تفقد بريدك الآن.',
                                ),
                                backgroundColor: AppColors.softGreen,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String msg = 'تعذر إرسال الرابط';
                            if (e.code == 'user-not-found') {
                              msg = 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
                            } else if (e.code == 'invalid-email') {
                              msg = 'صيغة البريد الإلكتروني غير صحيحة.';
                            } else if (e.message != null &&
                                e.message!.isNotEmpty) {
                              msg = e.message!;
                            }
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('حدث خطأ: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setModalState(() => isSending = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'إرسال رابط إعادة التعيين 🚀',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // دالة نبذة عن التطبيق
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const AppLogo(size: 36),
            ),
            const SizedBox(width: 12),
            Text(
              'عن تطبيق كبّاس',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'تطبيق كبّاس هو المنصة الرائدة والمتخصصة في مصر لخدمات شراء خردة التكييفات والثلاجات والتبريد بأعلى تقييم فوري وعادل، بالإضافة لتوفير خدمات تأسيس مواسير التكييفات وصيانة احترافية وقطع غيار أصلية بضمان معتمد.\n\nالإصدار: 1.0.3\nالحقوق محفوظة © كبّاس 2026',
          style: GoogleFonts.cairo(fontSize: 14, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حسناً',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة عرض سجل طلبات المستخدم
  void _showMyOrdersSheet(
    BuildContext context,
    String userId,
    String userEmail,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سجل طلباتي 📦',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textGrey,
                  indicatorColor: AppColors.primaryBlue,
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(
                      text: 'طلبات بيع الخردة',
                      icon: Icon(Icons.recycling_rounded),
                    ),
                    Tab(
                      text: 'طلبات الصيانة',
                      icon: Icon(Icons.build_circle_outlined),
                    ),
                    Tab(
                      text: 'طلبات التأسيس',
                      icon: Icon(Icons.plumbing_rounded),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUserOrdersList(
                        collection: 'scrap_orders',
                        userId: userId,
                        userEmail: userEmail,
                        scrollController: scrollController,
                        type: 'خردة',
                      ),
                      _buildUserOrdersList(
                        collection: 'maintenance_orders',
                        userId: userId,
                        userEmail: userEmail,
                        scrollController: scrollController,
                        type: 'صيانة',
                      ),
                      _buildUserOrdersList(
                        collection: 'pipe_installation_orders',
                        userId: userId,
                        userEmail: userEmail,
                        scrollController: scrollController,
                        type: 'تأسيس',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserOrdersList({
    required String collection,
    required String userId,
    required String userEmail,
    required ScrollController scrollController,
    required String type,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('تعذر تحميل الطلبات. تحقق من الاتصال وحاول مرة أخرى.'),
          );
        }
        final userOrders = snapshot.data?.docs ?? [];

        if (userOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'خردة'
                        ? Icons.recycling_rounded
                        : Icons.build_circle_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لم تقم بطلب أي خدمة $type حتى الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: userOrders.length,
          itemBuilder: (context, index) {
            final orderData = userOrders[index].data() as Map<String, dynamic>;
            final status = orderData['status'] ?? 'جديد';
            final title = type == 'خردة'
                ? (orderData['scrapType'] ?? 'بيع خردة')
                : (orderData['serviceType'] ?? 'طلب صيانة');

            Color statusColor;
            switch (status) {
              case 'جديد':
                statusColor = AppColors.softGreen;
                break;
              case 'قيد المعاينة':
                statusColor = AppColors.warningOrange;
                break;
              case 'تم التنفيذ':
              case 'تم الإنجاز':
                statusColor = AppColors.primaryBlue;
                break;
              case 'ملغي':
                statusColor = Colors.redAccent;
                break;
              default:
                statusColor = AppColors.textGrey;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (type == 'خردة' &&
                      orderData['estimatedWeight'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'الوزن التقديري: ${orderData['estimatedWeight']} كجم',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                  if (type == 'تأسيس') ...[
                    const SizedBox(height: 6),
                    Text(
                      'العنوان: ${orderData['address'] ?? "غير محدد"}',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    Text(
                      'عدد التكييفات: ${orderData['unitCount'] ?? "غير محدد"}',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                  ],
                  if (type != 'خردة' && orderData['description'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'الوصف: ${orderData['description']}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 60,
                color: AppColors.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'برجاء تسجيل الدخول أولاً',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: Text(
                  'تسجيل الدخول',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String userEmail = user.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic>? userData;
          if (snapshot.hasData && snapshot.data!.exists) {
            userData = snapshot.data!.data() as Map<String, dynamic>?;
          }

          final bool isAdmin = _isAdmin;

          String displayName = user.displayName ?? '';
          if (displayName.isEmpty &&
              userData != null &&
              userData['name'] != null) {
            displayName = userData['name'].toString();
          }
          if (displayName.isEmpty) {
            displayName = userEmail.isNotEmpty
                ? userEmail.split('@').first
                : 'مستخدم كبّاس';
          }

          return _buildProfileContent(
            context,
            user: user,
            name: displayName,
            email: userEmail,
            isAdmin: isAdmin,
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context, {
    required User user,
    required String name,
    required String email,
    required bool isAdmin,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==============================
          // 1. بطاقة المستخدم الرئيسية
          // ==============================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: isAdmin
                          ? const Color(0xFFF59E0B)
                          : AppColors.primaryBlue,
                      child: CircleAvatar(
                        radius: 43,
                        backgroundColor: isAdmin
                            ? const Color(0xFF0F172A)
                            : AppColors.lightBlue.withValues(alpha: 0.3),
                        child: Text(
                          name.isNotEmpty
                              ? name.characters.first.toUpperCase()
                              : 'ك',
                          style: GoogleFonts.cairo(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: isAdmin
                                ? const Color(0xFFF59E0B)
                                : AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showEditNameDialog(context, name, user),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? const Color(0xFFF59E0B)
                              : AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isAdmin ? Colors.white70 : AppColors.textGrey,
                      ),
                      onPressed: () => _showEditNameDialog(context, name, user),
                      tooltip: 'تعديل الاسم',
                    ),
                  ],
                ),
                Text(
                  email,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isAdmin ? Colors.white70 : AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 14),
                // شارة نوع الحساب
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdmin
                          ? const Color(0xFFF59E0B)
                          : AppColors.primaryBlue.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                        size: 18,
                        color: isAdmin
                            ? const Color(0xFFF59E0B)
                            : AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAdmin ? 'مدير النظام (Admin) 🛡️' : 'عميل كبّاس 👤',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isAdmin
                              ? const Color(0xFFF59E0B)
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==============================
          // 2. بطاقة الإدارة السريعة (تظهر فقط للمدير)
          // ==============================
          if (isAdmin) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, Color(0xFF023E8A)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330284C7),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة تحكم الإدارة الكاملة',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'متابعة طلبات الخردة والصيانة والتأسيس وإدارة المتجر',
                              style: GoogleFonts.cairo(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.launch_rounded, size: 20),
                      label: Text(
                        'فتح لوحة تحكم الإدارة الآن',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ==============================
          // 3. طلباتي وسجل المعاملات
          // ==============================
          _buildMenuSection(
            title: 'طلباتي ومعاملاتي',
            items: [
              _buildMenuItem(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'سجل طلباتي (الخردة والصيانة والتأسيس)',
                subtitle: 'متابعة حالة الطلبات السابقة ومواعيد المعاينة',
                onTap: () => _showMyOrdersSheet(context, user.uid, email),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==============================
          // 4. الدعم الفني والتواصل
          // ==============================
          _buildMenuSection(
            title: 'الدعم والمساعدة',
            items: [
              _buildMenuItem(
                icon: Icons.phone_in_talk_rounded,
                iconColor: AppColors.softGreen,
                title: 'الاتصال بالخط الساخن (24/7)',
                subtitle: '01007658105 - فريق الدعم الفني جاهز لمساعدتك',
                onTap: () => _launchExternal('tel:01007658105'),
              ),
              _buildMenuItem(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'محادثة مباشرة عبر واتساب',
                subtitle: 'استفسر فوراً عن الأسعار والخدمات',
                onTap: () => _launchExternal(
                  'https://wa.me/201007658105?text=${Uri.encodeComponent('مرحباً كبّاس، أود الاستفسار عن خدماتكم...')}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==============================
          // 5. إعدادات الحساب ومعلومات التطبيق
          // ==============================
          _buildMenuSection(
            title: 'إعدادات الحساب والمعلومات',
            items: [
              _buildMenuItem(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.primaryBlue,
                title: 'سياسة الخصوصية',
                subtitle: 'كيف نستخدم بياناتك وطرق حذفها',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.redAccent,
                title: 'حذف الحساب والبيانات',
                subtitle: 'حذف حسابك وطلباتك وصورك نهائياً',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                ),
              ),
              _buildMenuItem(
                icon: Icons.lock_reset_rounded,
                iconColor: AppColors.warningOrange,
                title: 'تغيير كلمة المرور',
                subtitle: 'إعادة تعيين وتحديث كلمة المرور لحسابك',
                onTap: () => _showChangePasswordModal(context, email),
              ),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'عن تطبيق كبّاس',
                subtitle: 'معلومات عن خدماتنا وأهدافنا وشروط الاستخدام',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==============================
          // 6. زر تسجيل الخروج
          // ==============================
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                elevation: 0,
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}
