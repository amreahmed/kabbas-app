import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'scrap_sell_screen.dart';
import 'store_screen.dart';
import 'maintenance_screen.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import '../widgets/app_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متغير بيحدد هل اللي فاتح ده أدمن ولا لأ
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // بنشغل الفحص أول ما الشاشة تفتح
  }

  // الدالة اللي بتفحص إيميل ودور المستخدم
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdTokenResult(true);
        if (mounted) setState(() => isAdmin = token.claims?['admin'] == true);
      } catch (_) {
        // Silently continue in offline mode
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء النور';
    return 'مساء الخير';
  }

  // دالة تسجيل الخروج
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              greeting: _greeting(),
              isAdmin:
                  isAdmin, // بنبعت معلومة الأدمن للهيدر عشان يظهر أيقونة لوحة التحكم
              onLogout: _logout, // بنبعت دالة الخروج
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionEyebrow(label: 'الخدمات المتاحة'),
                const SizedBox(height: 16),
                _ServiceTicket(
                  title: 'بيع خردة',
                  subtitle: 'تكييفات وثلاجات ومواتير قديمة',
                  tag: 'تقييم فوري',
                  icon: Icons.recycling_rounded,
                  color: AppColors.softGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScrapSellScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _ServiceTicket(
                  title: 'المتجر وقطع الغيار',
                  subtitle: 'أجهزة مستعملة وقطع غيار أصلية',
                  tag: 'تشكيلة يومية',
                  icon: Icons.storefront_rounded,
                  color: AppColors.warningOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StoreScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _ServiceTicket(
                  title: 'طلب صيانة',
                  subtitle: 'صيانة تكييفات وأجهزة تبريد',
                  tag: 'زيارة فنية',
                  icon: Icons.build_circle_rounded,
                  color: AppColors.primaryBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ServiceTicket(
                  title: 'تأسيس مواسير التكييفات',
                  subtitle: 'تجهيز مسارات ومواسير التكييف قبل التشطيب',
                  tag: 'طلب معاينة',
                  icon: Icons.plumbing_rounded,
                  color: AppColors.warningOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MaintenanceScreen(isPipeInstallation: true),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final bool isAdmin;
  final VoidCallback onLogout;

  const _Header({
    required this.greeting,
    required this.isAdmin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 44),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlue, Color(0xFF023E73)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -26,
              top: -16,
              child: Opacity(
                opacity: 0.16,
                child: CustomPaint(
                  size: const Size(150, 150),
                  painter: _GaugePainter(),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 42),
                        const SizedBox(width: 10),
                        Text(
                          'كبّاس',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // زرار لوحة تحكم الأدمن (يظهر للأدمن فقط)
                        if (isAdmin)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warningOrange.withValues(
                                  alpha: 0.9,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        // زرار تسجيل الخروج للكل
                        GestureDetector(
                          onTap: onLogout,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  greeting,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختار الخدمة اللي محتاجها النهارده',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.72, ring);
    final tick = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4;
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + radius * 0.84 * math.cos(angle),
        center.dy + radius * 0.84 * math.sin(angle),
      );
      canvas.drawLine(inner, outer, tick);
    }
    final needle = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final needleAngle = 200 * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.6 * math.cos(needleAngle),
        center.dy + radius * 0.6 * math.sin(needleAngle),
      ),
      needle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionEyebrow extends StatelessWidget {
  final String label;
  const _SectionEyebrow({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ServiceTicket extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceTicket({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: MediaQuery.textScalerOf(context).scale(150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _DashedDivider(color: color.withValues(alpha: 0.28)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        width: 1.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dashCount = (constraints.maxHeight / 7).floor();
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                dashCount,
                (_) => Container(width: 1.5, height: 4, color: color),
              ),
            );
          },
        ),
      ),
    );
  }
}
