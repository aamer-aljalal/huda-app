package com.tarteel.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.tarteel.app.alarm.AlarmBridge

/**
 * ============================================================================
 * اسم الملف: MainActivity.kt
 * المسؤولية: الفئة الأساسية لتشغيل التطبيق وتهيئة محرك فلاتر وربطه بجسر الأندرويد.
 * سبب التعديل: تفعيل قناة الاتصال (AlarmBridge) لتمكين الجدولة وتمرير البيانات.
 * متى يستخدم: عند بداية إقلاع التطبيق بالكامل.
 * من يستدعيه: نظام تشغيل أندرويد (OS).
 * الملفات التي يتواصل معها: AlarmBridge.kt (لتسجيل القناة وتفعيلها).
 * ============================================================================
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // تسجيل وتفعيل جسر المنبهات الموحد للبدء بالاستماع للأوامر من فلاتر
        AlarmBridge.registerWith(flutterEngine.dartExecutor.binaryMessenger, this)
    }
}
