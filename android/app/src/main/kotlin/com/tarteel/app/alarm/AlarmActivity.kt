package com.tarteel.app.alarm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * ============================================================================
 * اسم الملف: AlarmActivity.kt
 * المسؤولية: الشاشة الأصلية التي تظهر فوق شاشة قفل الهاتف لعرض تفاصيل الصلاة وأزرار التحكم.
 * سبب الإنشاء: المكون الأساسي لعرض واجهة المنبه التفاعلية بملء الشاشة عند قفل الهاتف.
 * متى يستخدم: يتم فتحه تلقائياً بواسطة نظام التشغيل عند رنين المنبه/الأذان.
 * من يستدعيه: نظام التشغيل أندرويد عبر نية الشاشة الكاملة (FullScreenIntent).
 * الملفات التي يتواصل معها: AlarmForegroundService.kt (لإرسال الأوامر)، AlarmBridge.kt (لقراءة البيانات).
 * ============================================================================
 */
class AlarmActivity : Activity() {

    private var alarmId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. إعداد شاشة الهاتف لإيقاظها وتخطي قفل الهاتف الأمني
        setupLockScreenFlags()

        // 2. استخراج معرف المنبه القادم مع النية
        alarmId = intent.getStringExtra("alarm_id")

        // 3. جلب بيانات التنبيه من الذاكرة المشتركة SharedPreferences
        var alarmTitle = "حان الآن موعد الصلاة"
        var alarmSubtitle = "الله أكبر"
        
        if (alarmId != null) {
            val sharedPrefs = getSharedPreferences("native_alarm_prefs", Context.MODE_PRIVATE)
            val jsonStr = sharedPrefs.getString("alarm_$alarmId", null)
            if (jsonStr != null) {
                try {
                    val alarmData = AlarmData.fromJson(jsonStr)
                    alarmTitle = alarmData.title
                    alarmSubtitle = alarmData.subtitle
                } catch (e: Exception) {
                    // في حال الفشل نبقي على القيم الافتراضية
                }
            }
        }

        // 4. بناء الواجهة الرسومية برمجياً بنسق داكن وراقي (دون الحاجة لملفات XML)
        val rootLayout = buildRootLayout()
        
        // أ. إضافة أيقونة المنبه/المسجد الافتراضية
        val iconView = buildIconView()
        rootLayout.addView(iconView)

        // ب. إضافة عنوان الصلاة (مثال: حان الآن موعد صلاة الظهر)
        val titleView = buildTextView(alarmTitle, 24f, "#FFFFFF", true)
        rootLayout.addView(titleView)

        // ج. إضافة اسم المؤذن أو التفاصيل (مثال: بصوت الشيخ إسلام صبحي)
        val subtitleView = buildTextView(alarmSubtitle, 16f, "#90A4AE", false)
        // إعطاء مساحة فارغة صغيرة أسفل الوصف
        val subtitleParams = subtitleView.layoutParams as LinearLayout.LayoutParams
        subtitleParams.setMargins(0, dpToPx(8), 0, dpToPx(48))
        subtitleView.layoutParams = subtitleParams
        rootLayout.addView(subtitleView)

        // د. إضافة زر إيقاف الأذان باللون الأحمر الداكن
        val stopButton = buildButton("إيقاف الأذان", "#EF5350") {
            sendActionToService(AlarmForegroundService.ACTION_STOP)
            finish() // إغلاق الشاشة الحالية
        }
        rootLayout.addView(stopButton)

        // هـ. إضافة زر كتم الصوت باللون الأزرق الرمادي الداكن
        val muteButton = buildButton("كتم الصوت", "#37474F") {
            sendActionToService(AlarmForegroundService.ACTION_MUTE)
            // نكتم الصوت ولكن نبقي الشاشة مفتوحة لكي يستطيع المستخدم الإيقاف لاحقاً
        }
        val muteParams = muteButton.layoutParams as LinearLayout.LayoutParams
        muteParams.setMargins(0, dpToPx(16), 0, 0)
        muteButton.layoutParams = muteParams
        rootLayout.addView(muteButton)

        setContentView(rootLayout)
    }

    /**
     * إعدادات النوافذ لإيقاظ شاشة الهاتف وتخطي شاشة القفل.
     */
    private fun setupLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            // إبقاء الشاشة مضيئة طوال فترة رنين المنبه
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    /**
     * بناء وتنسيق الحاوية الرئيسية للواجهة.
     */
    private fun buildRootLayout(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B0F19")) // ثيم داكن ملكي فاخر
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(24))
        }
    }

    /**
     * بناء أيقونة المنبه الجمالية في وسط الشاشة.
     */
    private fun buildIconView(): ImageView {
        return ImageView(this).apply {
            setImageResource(android.R.drawable.ic_lock_idle_alarm)
            layoutParams = LinearLayout.LayoutParams(dpToPx(96), dpToPx(96)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                setMargins(0, 0, 0, dpToPx(32))
            }
            // صبغ الأيقونة باللون الأبيض ليتناسب مع الخلفية الداكنة
            setColorFilter(Color.WHITE)
        }
    }

    /**
     * بناء حقول النصوص بشكل موحد.
     */
    private fun buildTextView(text: String, sizeSp: Float, colorHex: String, isBold: Boolean): TextView {
        return TextView(this).apply {
            this.text = text
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
            setTextColor(Color.parseColor(colorHex))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            if (isBold) {
                setTypeface(typeface, android.graphics.Typeface.BOLD)
            }
        }
    }

    /**
     * بناء الأزرار وتصميم زواياها الدائرية برمجياً باستخدام TextView لتفادي مشاكل ثيمات Material.
     */
    private fun buildButton(text: String, colorHex: String, onClick: () -> Unit): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
            
            // تصميم خلفية دائرية راقية للزر برمجياً (Rounded Button Background)
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(24).toFloat() // زوايا دائرية ناعمة
                setColor(Color.parseColor(colorHex))
            }
            background = shape
            
            // إعطاء الزر عرضاً ثابتاً ومناسباً
            layoutParams = LinearLayout.LayoutParams(
                dpToPx(240),
                dpToPx(48)
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }

            isClickable = true
            isFocusable = true
            setOnClickListener { onClick() }
        }
    }

    /**
     * إرسال الأمر للخدمة الخلفية للتحكم بالرنين (إيقاف أو كتم).
     */
    private fun sendActionToService(action: String) {
        val serviceIntent = Intent(this, AlarmForegroundService::class.java).apply {
            this.action = action
            putExtra("alarm_id", alarmId)
        }
        startService(serviceIntent)
    }

    /**
     * دالة تحويل المقاسات من DP إلى البكسل لتناسب شاشات الهواتف المختلفة.
     */
    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    /**
     * منع إغلاق الشاشة بالضغط على زر الرجوع الافتراضي للهاتف لضمان بقاء المنبه نشطاً.
     */
    override fun onBackPressed() {
        // لا نفعل شيئاً؛ يجب على المستخدم تفاعل الأزرار الظاهرة فقط
    }
}
