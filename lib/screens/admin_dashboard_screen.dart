import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'main_layout.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _createdAtMillis(QueryDocumentSnapshot<Object?> document) {
    final value = (document.data() as Map<String, dynamic>)['createdAt'];
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  List<QueryDocumentSnapshot<Object?>> _sortByCreatedAt(
    Iterable<QueryDocumentSnapshot<Object?>> documents,
  ) {
    final sorted = documents.toList();
    sorted.sort((a, b) => _createdAtMillis(b).compareTo(_createdAtMillis(a)));
    return sorted;
  }

  Widget _buildDataLoadError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل البيانات من Firebase',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تأكد من اتصال الإنترنت وأن حسابك لديه صلاحية الإدارة، ثم أعد فتح الصفحة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: AppColors.textGrey),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openMap(String locationUrl) async {
    try {
      String cleanUrl = locationUrl.trim();
      if (!cleanUrl.startsWith('http') && !cleanUrl.startsWith('geo:')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final Uri uri = Uri.parse(cleanUrl);

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched) {
        final regExp = RegExp(r'([-+]?\d*\.?\d+)[,\s]+([-+]?\d*\.?\d+)');
        final match = regExp.firstMatch(cleanUrl);
        if (match != null) {
          final lat = match.group(1);
          final lng = match.group(2);
          final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
          try {
            launched = await launchUrl(
              geoUri,
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        }
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح تطبيق الخرائط أو المتصفح'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء فتح الخريطة: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBlue,
          ),
          tooltip: 'الرجوع للتطبيق',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            }
          },
        ),
        title: Text(
          'لوحة تحكم الإدارة',
          style: GoogleFonts.cairo(
            color: AppColors.primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primaryBlue,
            ),
            tooltip: 'تصفح التطبيق كعميل',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'تأكيد تسجيل الخروج',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'هل تريد تسجيل الخروج من حساب الإدارة؟',
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'خروج',
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
          ),
        ],
        iconTheme: const IconThemeData(color: AppColors.textDark),
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          controller: _tabController,
          labelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'طلبات الخردة', icon: Icon(Icons.recycling_rounded)),
            Tab(text: 'طلبات الصيانة', icon: Icon(Icons.build_circle_outlined)),
            Tab(text: 'طلبات التأسيس', icon: Icon(Icons.plumbing_rounded)),
            Tab(text: 'إدارة المتجر', icon: Icon(Icons.storefront_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList('scrap_orders', 'الخردة'),
          _buildOrdersList('maintenance_orders', 'الصيانة'),
          _buildOrdersList('pipe_installation_orders', 'التأسيس'),
          _buildStoreManager(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1 & 2: ORDERS LIST (SCRAP & MAINTENANCE)
  // ==========================================
  Widget _buildOrdersList(String collectionName, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }
        if (snapshot.hasError) {
          return _buildDataLoadError(snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'الخردة'
                      ? Icons.recycling_rounded
                      : Icons.build_circle_outlined,
                  size: 70,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'مفيش طلبات $type حالياً',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          );
        }

        // Do not order in the Firestore query: older records may not have a
        // createdAt field and would otherwise be silently omitted.
        final orders = _sortByCreatedAt(snapshot.data!.docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final orderData = doc.data() as Map<String, dynamic>;
            return _buildOrderCard(doc.id, doc.reference, orderData, type);
          },
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'جديد':
        return AppColors.softGreen;
      case 'قيد المعاينة':
        return AppColors.warningOrange;
      case 'تم التنفيذ':
      case 'تم الإنجاز':
        return AppColors.primaryBlue;
      case 'ملغي':
        return Colors.redAccent;
      default:
        return AppColors.textGrey;
    }
  }

  Widget _buildOrderCard(
    String orderId,
    DocumentReference docRef,
    Map<String, dynamic> data,
    String type,
  ) {
    String? base64Image = data['imageBase64'];
    String? locationUrl = data['locationUrl'];
    String currentStatus = data['status'] ?? 'جديد';
    String? userEmail = data['userEmail'];
    String clientName =
        (data['clientName'] != null && data['clientName'].toString().isNotEmpty)
        ? data['clientName'].toString()
        : (userEmail ?? 'عميل كباس');
    String? clientPhone = data['clientPhone']?.toString();

    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    String dateStr = '';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr =
          '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge and Order Type / Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Dropdown / Action
                InkWell(
                  onTap: () => _showChangeStatusDialog(docRef, currentStatus),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        currentStatus,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(
                          currentStatus,
                        ).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentStatus,
                          style: GoogleFonts.cairo(
                            color: _getStatusColor(currentStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: _getStatusColor(currentStatus),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type == 'الخردة'
                        ? (data['scrapType'] ?? 'غير محدد')
                        : (data['serviceType'] ?? 'طلب صيانة'),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),

            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'تاريخ الطلب: $dateStr',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],

            // Customer Contact Info Box (Call & WhatsApp)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryBlue,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (clientPhone != null && clientPhone.isNotEmpty)
                          Text(
                            clientPhone,
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        else if (userEmail != null && userEmail != clientName)
                          Text(
                            userEmail,
                            style: GoogleFonts.cairo(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (clientPhone != null && clientPhone.isNotEmpty) ...[
                    // Call Button
                    IconButton(
                      icon: const CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.softGreen,
                        child: Icon(Icons.phone, color: Colors.white, size: 18),
                      ),
                      onPressed: () async {
                        try {
                          final uri = Uri.parse('tel:$clientPhone');
                          bool launched = false;
                          try {
                            launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                          if (!launched) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                          }
                        } catch (_) {}
                      },
                      tooltip: 'اتصال هاتفي بالعميل',
                    ),
                    // WhatsApp Button
                    IconButton(
                      icon: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFF25D366),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          String phone = clientPhone.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (phone.startsWith('0')) {
                            phone = '2$phone';
                          }
                          final uri = Uri.parse(
                            'https://wa.me/$phone?text=${Uri.encodeComponent('مرحباً $clientName، نتواصل معك بخصوص طلبك على تطبيق كَبّاس...')}',
                          );
                          bool launched = false;
                          try {
                            launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                          if (!launched) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                          }
                        } catch (_) {}
                      },
                      tooltip: 'محادثة واتساب فورية',
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 20),

            if (type == 'التأسيس') ...[
              Text(
                'عنوان المعاينة: ${data['address'] ?? "غير محدد"}',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'عدد التكييفات: ${data['unitCount'] ?? "غير محدد"}',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
            // Order details
            if (type != 'الخردة' &&
                data['description'] != null &&
                data['description'].toString().isNotEmpty) ...[
              Text(
                type == 'التأسيس' ? 'تفاصيل التأسيس:' : 'وصف العطل:',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data['description']}',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
            ],

            if (type == 'الخردة' &&
                data['estimatedWeight'] != null &&
                data['estimatedWeight'].toString().isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.scale_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الوزن التقديري: ${data['estimatedWeight']} كجم',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Customer Location button
            if (locationUrl != null && locationUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _openMap(locationUrl),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.softGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          color: AppColors.softGreen,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'عرض موقع العميل على الخريطة',
                          style: GoogleFonts.cairo(
                            color: AppColors.softGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Order Image
            if (base64Image != null && base64Image.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showFullImageDialog(base64Image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.memory(
                        base64Decode(base64Image),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'اضغط للتكبير',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'مفيش صورة مرفقة',
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons (Status & Delete)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showChangeStatusDialog(docRef, currentStatus),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(
                      'تغيير الحالة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _confirmDeleteOrder(docRef, type),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'حذف الطلب',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeStatusDialog(DocumentReference docRef, String currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final statuses = ['جديد', 'قيد المعاينة', 'تم التنفيذ', 'ملغي'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تحديث حالة الطلب',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...statuses.map((status) {
                  final isSelected = status == currentStatus;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: _getStatusColor(status),
                    ),
                    title: Text(
                      status,
                      style: GoogleFonts.cairo(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textDark,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primaryBlue)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await docRef.update({'status': status});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تغيير الحالة إلى "$status" بنجاح',
                            ),
                            backgroundColor: AppColors.softGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteOrder(DocumentReference docRef, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تأكيد حذف الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف طلب $type هذا نهائياً؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await docRef.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الطلب بنجاح 🗑️'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImageDialog(String base64Image) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: STORE & PRODUCTS MANAGEMENT
  // ==========================================
  Widget _buildStoreManager() {
    return Column(
      children: [
        // Action Bar for Adding Products
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddProductModal,
                  icon: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'إضافة منتج جديد للمتجر',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Products List from Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildDataLoadError(snapshot.error);
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 70,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد منتجات في المتجر حتى الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على الزر بالأعلى لإضافة أول منتج!',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Keep legacy products visible even if they predate createdAt.
              final products = _sortByCreatedAt(snapshot.data!.docs);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final doc = products[index];
                  final product = doc.data() as Map<String, dynamic>;
                  return _buildStoreProductItem(doc.id, doc.reference, product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreProductItem(
    String productId,
    DocumentReference docRef,
    Map<String, dynamic> product,
  ) {
    String? imageBase64 = product['imageBase64'];
    String name = product['name'] ?? 'بدون اسم';
    dynamic price = product['price'] ?? '0';
    String? category = product['category'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: imageBase64 != null && imageBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(imageBase64),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(
                        Icons.ac_unit_rounded,
                        size: 36,
                        color: Color(0xFFF5A623),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null && category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$price ج.م',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Actions (Edit Price & Delete)
            Column(
              children: [
                IconButton(
                  onPressed: () =>
                      _showEditPriceDialog(docRef, price.toString()),
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  tooltip: 'تعديل السعر',
                ),
                IconButton(
                  onPressed: () => _confirmDeleteProduct(docRef, name),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'حذف المنتج',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPriceDialog(DocumentReference docRef, String currentPrice) {
    final controller = TextEditingController(text: currentPrice);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تعديل سعر المنتج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'السعر الجديد (ج.م)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = controller.text.trim();
              if (newPrice.isNotEmpty) {
                Navigator.pop(ctx);
                await docRef.update({'price': newPrice});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث السعر بنجاح ✅'),
                      backgroundColor: AppColors.softGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              'حفظ',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(DocumentReference docRef, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تأكيد حذف المنتج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد بالتأكيد إزالة "$productName" من المتجر؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await docRef.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إزالة المنتج من المتجر 🗑️'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ADD PRODUCT MODAL SHEET
  // ==========================================
  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalContext) {
        return const _AddProductSheetContent();
      },
    );
  }
}

class _AddProductSheetContent extends StatefulWidget {
  const _AddProductSheetContent();

  @override
  State<_AddProductSheetContent> createState() =>
      _AddProductSheetContentState();
}

class _AddProductSheetContentState extends State<_AddProductSheetContent> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'قطع غيار';
  XFile? _pickedImage;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      debugPrint('Error picking product image: $e');
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();

    if (name.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم المنتج والسعر!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? base64Image;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final docRef = FirebaseFirestore.instance.collection('products').doc();
      final productData = {
        'name': name,
        'price': price,
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'imageBase64': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(productData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المنتج للمتجر بنجاح! 🎉'),
            backgroundColor: AppColors.softGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ المنتج: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'إضافة منتج جديد للمتجر',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            // Image Picker Section
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: Text(
                            'اختيار من المعرض',
                            style: GoogleFonts.cairo(),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: Text(
                            'التقاط صورة بالكاميرا',
                            style: GoogleFonts.cairo(),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pickedImage != null
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: _pickedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _pickedImage = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لإضافة صورة المنتج',
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '(معرض الصور أو الكاميرا)',
                            style: GoogleFonts.cairo(
                              color: AppColors.textGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم المنتج *',
                hintText: 'مثال: كباس تكييف شارب 1.5 حصان مستعمل',
                labelStyle: GoogleFonts.cairo(),
                hintStyle: GoogleFonts.cairo(fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Price & Category
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'السعر (ج.م) *',
                      hintText: 'مثال: 3500',
                      labelStyle: GoogleFonts.cairo(),
                      hintStyle: GoogleFonts.cairo(fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items:
                            [
                                  'قطع غيار',
                                  'أجهزة مستعملة',
                                  'نحاس ومواسير',
                                  'أخرى',
                                ]
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.cairo(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'مواصفات أو وصف إضافي (اختياري)',
                labelStyle: GoogleFonts.cairo(),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'نشر المنتج في المتجر 🚀',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
