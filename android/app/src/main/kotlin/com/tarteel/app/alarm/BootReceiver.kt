package com.tarteel.app.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

/**
 * ============================================================================
 * اسم الملف: BootReceiver.kt
 * المسؤولية: إعادة جدولة المنبهات تلقائياً عند تشغيل الهاتف أو تعديل الساعة.
 * سبب الإنشاء: حل مشكلة حذف المنبهات التلقائي من نظام أندرويد عند إعادة تشغيل الهاتف.
 * متى يستخدم: عند إقلاع الجهاز أو تغيير توقيت ساعة الهاتف أو المنطقة الزمنية.
 * من يستدعيه: نظام تشغيل أندرويد (OS).
 * الملفات التي يتواصل معها: AlarmBridge.kt (غير مباشر لقراءة وإعادة جدولة البيانات).
 * ============================================================================
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "تم استقبال إشارة النظام: $action - بدء إعادة الجدولة التلقائية")

        // 1. جلب مدير المنبهات والذاكرة المشتركة
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val sharedPrefs = context.getSharedPreferences("native_alarm_prefs", Context.MODE_PRIVATE)

        // 2. قراءة جميع المفاتيح المخزنة في الذاكرة
        val allEntries = sharedPrefs.all
        val currentTime = System.currentTimeMillis()

        for ((key, value) in allEntries) {
            // التحقق من أن المفتاح يخص منبه مجدول
            if (key.startsWith("alarm_") && value is String) {
                try {
                    // فك ترميز JSON إلى كائن المنبه
                    val alarmData = AlarmData.fromJson(value)

                    // 3. التحقق من صلاحية وقت المنبه
                    if (alarmData.scheduledTime > currentTime) {
                        // أ. إذا كان المنبه في المستقبل، نعيد جدولته فوراً
                        reschedule(context, alarmManager, alarmData)
                        Log.d(TAG, "تمت إعادة جدولة منبه صلاة: ${alarmData.title} بنجاح")
                    } else {
                        // ب. إذا كان وقت المنبه قد فات (في الماضي)، نقوم بحذفه لتنظيف الذاكرة
                        sharedPrefs.edit().remove(key).apply()
                        Log.d(TAG, "تم تنظيف وحذف المنبه المنتهي: ${alarmData.title} من الذاكرة")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "خطأ أثناء معالجة المنبه $key: ${e.message}")
                }
            }
        }
    }

    /**
     * دالة الجدولة المباشرة في الـ AlarmManager المأخوذة من منطق الـ AlarmBridge.
     */
    private fun reschedule(context: Context, alarmManager: AlarmManager, alarmData: AlarmData) {
        // التحقق من صلاحيات المنبه الدقيق لأندرويد 12+ لتفادي توقف التطبيق
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.e(TAG, "فشلت إعادة الجدولة: صلاحية المنبه الدقيق غير مفعّلة في النظام")
                return
            }
        }

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("alarm_id", alarmData.id)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmData.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                alarmData.scheduledTime,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                alarmData.scheduledTime,
                pendingIntent
            )
        }
    }
}
