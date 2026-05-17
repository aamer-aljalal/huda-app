import 'package:flutter_screenutil/flutter_screenutil.dart';
// صفحة عرض السورة (مطابقة للصورة مع تفاعلات كاملة)
import 'package:flutter/material.dart';

class Ayah {
  final int number;
  final String text;
  final String? tafsir; // تفسير الآية (يمكن تمريره من المصدر)
  Ayah({required this.number, required this.text, this.tafsir});
}

class SurahDetailPage extends StatefulWidget {
  final int surahId;
  final String surahName;
  final List<Ayah> verses; // يجب تمرير الآيات من المصدر مع تفاسيرها
  const SurahDetailPage({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.verses,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool isPlaying = false;
  Set<int> favoriteAyahs = {}; // تخزين أرقام الآيات المفضلة محلياً

  // دالة لإظهار النافذة العائمة عند الضغط على آية
  void _showAyahOptions(Ayah ayah) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        final isFav = favoriteAyahs.contains(ayah.number);
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'الآية ${ayah.number}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6B58),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  ayah.text,
                  style: TextStyle(fontSize: 18.sp, height: 1.5.h),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'التفسير:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                ayah.tafsir ?? 'لا يوجد تفسير متاح حالياً.',
                style: TextStyle(fontSize: 14.sp, height: 1.4.h),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomSheetButton(
                    icon: Icons.save_alt,
                    label: 'حفظ الآية',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حفظ الآية ${ayah.number}')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildBottomSheetButton(
                    icon: isFav ? Icons.favorite : Icons.favorite_border,
                    label: isFav ? 'أزل من المفضلة' : 'أضف للمفضلة',
                    onTap: () {
                      setState(() {
                        if (isFav) {
                          favoriteAyahs.remove(ayah.number);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تمت إزالة الآية ${ayah.number} من المفضلة',
                              ),
                            ),
                          );
                        } else {
                          favoriteAyahs.add(ayah.number);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تمت إضافة الآية ${ayah.number} إلى المفضلة',
                              ),
                            ),
                          );
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B58).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1A6B58), size: 28.sp),
          ),
          SizedBox(height: 6.h),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2A32),
            fontSize: 22.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A6B58)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: const Color(0xFF1A6B58),
              size: 30.sp,
            ),
            onPressed: () {
              setState(() => isPlaying = !isPlaying);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isPlaying ? 'تشغيل التلاوة' : 'إيقاف التلاوة'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // قائمة الآيات القابلة للنقر
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: widget.verses.length,
              itemBuilder: (context, index) {
                final ayah = widget.verses[index];
                return GestureDetector(
                  onTap: () => _showAyahOptions(ayah),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        // رقم الآية داخل دائرة صغيرة
                        Container(
                          width: 36.w,
                          height: 36.h,
                          margin: EdgeInsets.only(left: 12, top: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A6B58), Color(0xFF239F82)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${ayah.number}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                        // نص الآية
                        Expanded(
                          child: Text(
                            ayah.text,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 18.sp,
                              height: 1.5.h,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // الأزرار السفلية
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.play_circle_outline, 'استماع', () {
                      setState(() => isPlaying = !isPlaying);
                    }),
                    _buildActionButton(Icons.description_outlined, 'تفسير', () {
                      // يمكن فتح صفحة تفسير السورة كاملة
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('فتح التفسير الكامل للسورة'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }),
                    _buildActionButton(Icons.bookmark_outline, 'حفظ موضوع', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'حفظ الموضوع (سيتم إضافته إلى المحفوظات)',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }),
                    _buildActionButton(
                      Icons.save_alt_outlined,
                      'حفظ الآية',
                      () {
                        // حفظ الآية الحالية (مثال: أول آية)
                        if (widget.verses.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم حفظ الآية ${widget.verses.first.number}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // الانتقال إلى سورة البقرة (يمكن توجيه المستخدم)
                      Navigator.pop(context);
                      // يمكن إضافة صفحة سورة البقرة
                    },
                    icon: Icon(Icons.navigate_before),
                    label: Text(
                      'الذهاب إلى سورة البقرة',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B58),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B58).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1A6B58), size: 28.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E2A32),
            ),
          ),
        ],
      ),
    );
  }
}

// مثال لاستخدام الصفحة مع بيانات مطابقة للصورة (سورة الفاتحة)
// SurahDetailPage(
//   surahId: 1,
//   surahName: 'الفاتحة',
//   verses: [
//     Ayah(number: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', tafsir: 'التسمية: بدء باسم الله ذي الرحمة العامة والخاصة'),
//     Ayah(number: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', tafsir: 'الثناء على الله بصفات الكمال، مالك العالمين'),
//     Ayah(number: 3, text: 'الرَّحْمَٰنِ الرَّحِيمِ', tafsir: 'الرحمن ذو الرحمة الواسعة، الرحيم بالمؤمنين'),
//     Ayah(number: 4, text: 'مَالِكِ يَوْمِ الدِّينِ', tafsir: 'المالك ليوم الجزاء والحساب'),
//     Ayah(number: 5, text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', tafsir: 'نخصك بالعبادة والطلب'),
//     Ayah(number: 6, text: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', tafsir: 'وفقنا إلى طريق الحق'),
//     Ayah(number: 7, text: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', tafsir: 'طريق الأنبياء والصديقين، لا طريق المغضوب عليهم ولا الضالين'),
//   ],
// )
