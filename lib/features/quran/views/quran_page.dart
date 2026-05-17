import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../../models/ayah_model.dart';
import '../widgets/ayah_widget.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ayah = AyahModel(
      number: 1,
      text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
    );

    return Scaffold(
      appBar: AppBar(title: Text("القرآن")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: AyahWidget(
          ayah: ayah,
          onTap: () {
            print("تم الضغط على الآية");
          },
        ),
      ),
    );
  }
}
