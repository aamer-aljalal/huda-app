package com.tarteel.app.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * ============================================================================
 * اسم الملف: AlarmReceiver.kt
 * المسؤولية: استقبال إشارة التنبيه من نظام أندرويد وتشغيل الخدمة الخلفية فوراً.
 * سبب الإنشاء: تلبية لمتطلبات نظام أندرويد الذي يفرض استقبال إشارات التوقيت عبر BroadcastReceiver.
 * متى يستخدم: عند حلول وقت المنبه/الصلاة المجدول بالثانية.
 * من يستدعيه: نظام تشغيل أندرويد (OS) عبر الـ AlarmManager.
 * الملفات التي يتواصل معها: AlarmBridge.kt (غير مباشر)، AlarmForegroundService.kt (مباشر)
 * ============================================================================
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
    }

    /**
     * الدالة الرئيسية التي يتم استدعاؤها تلقائياً من نظام أندرويد عند رنين المنبه.
     */
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "تم استقبال إشارة رنين المنبه بنجاح")

        // 1. استخراج معرف المنبه الفريد من النية القادمة
        val alarmId = intent.getStringExtra("alarm_id")
        if (alarmId == null) {
            Log.e(TAG, "فشل تشغيل المنبه: معرف المنبه (alarm_id) فارغ")
            return
        }

        Log.d(TAG, "بدء تشغيل منبه بمعرف: $alarmId")

        // 2. إعداد النية لتشغيل الخدمة الخلفية المستمرة وتمرير معرف المنبه لها
        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtra("alarm_id", alarmId)
        }

        // 3. تشغيل الخدمة الخلفية بشكل آمن يعتمد على إصدار الأندرويد
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // في أندرويد 8 فما فوق، يجب تشغيل الخدمات الخلفية كخدمات مرئية (Foreground)
                context.startForegroundService(serviceIntent)
            } else {
                // في الإصدارات القديمة، يتم التشغيل كخدمة عادية
                context.startService(serviceIntent)
            }
            Log.d(TAG, "تم إرسال أمر تشغيل الخدمة الخلفية للمنبه بنجاح")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تشغيل الخدمة الخلفية للمنبه: ${e.message}")
        }
    }
}
