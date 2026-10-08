import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';

class ScrapSellScreen extends StatefulWidget {
  const ScrapSellScreen({super.key});

  @override
  State<ScrapSellScreen> createState() => _ScrapSellScreenState();
}

class _ScrapSellScreenState extends State<ScrapSellScreen> {
  String? selectedScrapType;
  XFile? selectedImage;
  String? locationUrl;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
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
    nameController.dispose();
    phoneController.dispose();
    weightController.dispose();
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
    if (image != null && mounted) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    LocationPermission permission = await Geolocator.checkPermission();
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

  Future<void> _submitOrder() async {
    final clientName = nameController.text.trim();
    final clientPhone = phoneController.text.trim();

    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اكتب اسمك بالكامل للتواصل!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (clientPhone.isEmpty || clientPhone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل رقم هاتف صحيح للتواصل معك!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (selectedScrapType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختر نوع الخردة!'),
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
          .collection('scrap_orders')
          .doc();
      final orderData = {
        'clientName': clientName,
        'clientPhone': clientPhone,
        'scrapType': selectedScrapType,
        'estimatedWeight': weightController.text.trim(),
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
          const SnackBar(
            content: Text('تم إرسال طلبك بنجاح! سنتواصل معك قريباً ✅'),
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
        title: const Text(
          'تثمين وبيع خردة',
          style: TextStyle(
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
            _buildSectionTitle('1. بياناتك للتواصل (مهم جداً للتثمين):'),
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
            _buildSectionTitle('2. إيه نوع الخردة اللي عندك؟'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('اختر نوع الخردة'),
                  value: selectedScrapType,
                  items:
                      [
                        'تكييف قديم كامل',
                        'ثلاجة قديمة',
                        'مواتير وكباسات',
                        'نحاس وألومنيوم',
                        'أخرى',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) =>
                      setState(() => selectedScrapType = newValue),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('3. صور الخردة (مهم جداً للتثمين):'),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: selectedImage == null
                      ? AppColors.softGreen.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selectedImage == null
                        ? AppColors.softGreen.withValues(alpha: 0.5)
                        : Colors.green,
                    style: BorderStyle.solid,
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
                          ? AppColors.softGreen
                          : Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedImage == null
                          ? 'اضغط هنا لاختيار صورة'
                          : 'تم اختيار الصورة بنجاح!',
                      style: TextStyle(
                        color: selectedImage == null
                            ? AppColors.softGreen
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('4. الوزن التقديري (اختياري):'),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'مثال: 50 كيلو',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('5. موقع استلام الخردة (اختياري):'),
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
                    isLocating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.softGreen,
                            ),
                          )
                        : Icon(
                            Icons.location_on_rounded,
                            color: locationUrl == null
                                ? AppColors.textGrey
                                : AppColors.softGreen,
                          ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        isLocating
                            ? 'جاري تحديد موقعك بدقة...'
                            : locationUrl == null
                            ? 'اضغط لتحديد موقعك الحالي 📍'
                            : 'تم تحديد الموقع بنجاح ✅',
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
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'اطلب معاينة وتثمين',
                        style: TextStyle(
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
