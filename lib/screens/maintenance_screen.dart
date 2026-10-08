import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // ضفنا الخرائط
import '../theme/app_colors.dart';
import '../services/pipe_installation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, this.isPipeInstallation = false});

  final bool isPipeInstallation;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final addressController = TextEditingController();
  final unitCountController = TextEditingController();
  XFile? selectedImage;
  String? locationUrl;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;
  bool isLocating = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        nameController.text = user.displayName!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        phoneController.text = user.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    unitCountController.dispose();
    nameController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );
    if (image != null && mounted) setState(() => selectedImage = image);
  }

  // دالة تحديد الموقع عبر الـ GPS
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تفعيل خدمة الـ GPS على هاتفك أولاً'),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن تحديد الموقع')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'إذن الموقع مرفوض بشكل دائم، يرجى تفعيله من إعدادات الهاتف.',
            ),
            action: SnackBarAction(
              label: 'الإعدادات',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => isLocating = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحديد موقعك بدقة... 📍'),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (mounted) {
        setState(() {
          locationUrl =
              'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد الموقع بنجاح! 📍'),
            backgroundColor: AppColors.softGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر جلب الموقع: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLocating = false);
      }
    }
  }

  Future<void> _submitMaintenanceOrder() async {
    final clientName = nameController.text.trim();
    final clientPhone = phoneController.text.trim();

    if (clientName.isEmpty || clientName.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اكتب اسمك بالكامل للتواصل!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (clientPhone.isEmpty ||
        clientPhone.length < 8 ||
        clientPhone.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل رقم هاتف صحيح للتواصل معك!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final unitCount = parseUnitCount(unitCountController.text);
    if (widget.isPipeInstallation &&
        (addressController.text.trim().isEmpty ||
            addressController.text.trim().length > 500 ||
            unitCount == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب عنوان المعاينة وعدد التكييفات من 1 إلى 100'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!widget.isPipeInstallation &&
        selectedImage == null &&
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اكتب وصف للعطل أو ارفع صورة!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? base64Image;
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        if (bytes.length > 650000) {
          throw StateError('الصورة كبيرة جداً. اختر صورة أصغر.');
        }
        base64Image = base64Encode(bytes);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('يرجى تسجيل الدخول أولاً');

      final docRef = FirebaseFirestore.instance
          .collection(
            widget.isPipeInstallation
                ? pipeInstallationCollection
                : 'maintenance_orders',
          )
          .doc();
      final orderData = {
        'clientName': clientName,
        'clientPhone': clientPhone,
        'serviceType': widget.isPipeInstallation
            ? pipeInstallationService
            : 'صيانة عامة',
        if (widget.isPipeInstallation) 'address': addressController.text.trim(),
        if (widget.isPipeInstallation) 'unitCount': unitCount,
        'description': descriptionController.text.trim(),
        'imageBase64': base64Image,
        'locationUrl': locationUrl,
        'userId': user.uid,
        'userEmail': user.email,
        'status': 'جديد',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(orderData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isPipeInstallation
                  ? 'تم إرسال طلب التأسيس بنجاح! ✅'
                  : 'تم إرسال طلب الصيانة بنجاح! ✅',
            ),
            backgroundColor: AppColors.softGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الإرسال: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPipeInstallation ? pipeInstallationService : 'طلب صيانة',
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. بياناتك للتواصل (مهم جداً للفني):'),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'الاسم بالكامل *',
                hintText: 'مثال: محمد أحمد',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryBlue,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الموبايل أو الواتساب *',
                hintText: 'مثال: 01012345678',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.primaryBlue,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 25),

            if (widget.isPipeInstallation) ...[
              _buildSectionTitle('بيانات تأسيس المواسير'),
              const SizedBox(height: 10),
              const Text(
                'اترك بيانات المكان لنتواصل معك ونحدد المعاينة والتكلفة.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'عنوان المعاينة بالتفصيل *',
                  hintText: 'المنطقة، الشارع، رقم العقار والدور',
                  prefixIcon: Icon(Icons.home_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCountController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                decoration: const InputDecoration(
                  labelText: 'عدد التكييفات المطلوب تأسيسها *',
                  hintText: 'مثال: 3',
                  prefixIcon: Icon(Icons.ac_unit_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle(
              widget.isPipeInstallation
                  ? 'تفاصيل التأسيس (اختياري):'
                  : '2. أوصف المشكلة اللي في الجهاز:',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.isPipeInstallation
                    ? 'مساحة المكان، مرحلة التشطيب، أطوال المواسير التقريبية وأي ملاحظات...'
                    : 'مثال: التكييف بينقط مياه ومش بيسقع...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle(
              widget.isPipeInstallation
                  ? 'الموقع الجغرافي (اختياري):'
                  : '3. الموقع الجغرافي للفني:',
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: isLocating ? null : _getCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: locationUrl == null
                        ? Colors.grey.shade300
                        : AppColors.softGreen,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: locationUrl == null
                          ? AppColors.textGrey
                          : AppColors.softGreen,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        locationUrl == null
                            ? 'اضغط لتحديد موقعك الحالي 📍'
                            : 'تم التقاط الموقع بنجاح',
                        style: TextStyle(
                          color: locationUrl == null
                              ? AppColors.textGrey
                              : AppColors.softGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            _buildSectionTitle(
              widget.isPipeInstallation
                  ? 'صورة المكان أو المخطط (اختياري):'
                  : '4. صور العطل (اختياري):',
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: selectedImage == null
                      ? AppColors.primaryBlue.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selectedImage == null
                        ? AppColors.primaryBlue.withValues(alpha: 0.5)
                        : Colors.blue,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedImage == null
                          ? Icons.add_a_photo_rounded
                          : Icons.check_circle_rounded,
                      color: selectedImage == null
                          ? AppColors.primaryBlue
                          : Colors.blue,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedImage == null
                          ? 'اضغط هنا لاختيار صورة'
                          : 'تم اختيار الصورة بنجاح!',
                      style: TextStyle(
                        color: selectedImage == null
                            ? AppColors.primaryBlue
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitMaintenanceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isPipeInstallation
                            ? 'إرسال طلب التأسيس'
                            : 'إرسال طلب الصيانة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    ),
  );
}
