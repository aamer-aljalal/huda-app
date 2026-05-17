import 'package:flutter/material.dart';

void main() {
  runApp(const AzkarApp());
}

class AzkarApp extends StatelessWidget {
  const AzkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الأذكار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      home: const AzkarScreen(),
    );
  }
}

/// UI ONLY — No logic, no state management, no data persistence.
/// All values are static and for visual demonstration only.
class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Static dummy data for each tab (UI only)
  final List<ZekrItem> _morningZekr = [
    ZekrItem(
      text:
          'أصبحنا وأصبح الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له',
      count: 3,
      current: 1,
    ),
    ZekrItem(
      text: 'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور',
      count: 1,
      current: 0,
    ),
    ZekrItem(
      text: 'سبحان الله وبحمده عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته',
      count: 3,
      current: 2,
    ),
  ];

  final List<ZekrItem> _eveningZekr = [
    ZekrItem(
      text:
          'أمسينا وأمسى الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له',
      count: 3,
      current: 3,
    ),
    ZekrItem(
      text: 'اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير',
      count: 1,
      current: 0,
    ),
  ];

  final List<ZekrItem> _sleepZekr = [
    ZekrItem(text: 'باسمك اللهم أموت وأحيا', count: 3, current: 2),
    ZekrItem(text: 'اللهم قني عذابك يوم تبعث عبادك', count: 3, current: 0),
  ];

  final List<ZekrItem> _afterPrayerZekr = [
    ZekrItem(text: 'سبحان الله (٣٣ مرة)', count: 33, current: 12),
    ZekrItem(text: 'الحمد لله (٣٣ مرة)', count: 33, current: 20),
    ZekrItem(text: 'الله أكبر (٣٤ مرة)', count: 34, current: 34),
  ];

  final List<ZekrItem> _customZekr = [
    ZekrItem(text: 'لا إله إلا الله وحده لا شريك له', count: 10, current: 5),
    ZekrItem(text: 'أستغفر الله العظيم', count: 100, current: 45),
  ];

  @override
  Widget build(BuildContext context) {
    // Static progress values (UI only)
    int totalZekr =
        _morningZekr.length +
        _eveningZekr.length +
        _sleepZekr.length +
        _afterPrayerZekr.length +
        _customZekr.length;
    int completedZekr = 5; // Dummy completed count

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: const Text(
          'الأذكار',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {}, // UI only – no navigation
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // UI only – no search logic
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Section (Optional)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📊 التقدم',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '$completedZekr / $totalZekr',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completedZekr / totalZekr,
                    minHeight: 8,
                    backgroundColor: Colors.green.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '🌅 صباح'),
              Tab(text: '🌙 مساء'),
              Tab(text: '🛏 نوم'),
              Tab(text: '🤲 بعد الصلاة'),
              Tab(text: '⭐ مخصص'),
            ],
            labelColor: Colors.green.shade800,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green.shade700,
            dividerColor: Colors.transparent,
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildZekrList(_morningZekr),
                _buildZekrList(_eveningZekr),
                _buildZekrList(_sleepZekr),
                _buildZekrList(_afterPrayerZekr),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZekrList(List<ZekrItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // Visual only: if current == 0, we can simulate a "completed" style
        bool isCompleted = item.current == 0;
        return GestureDetector(
          onTap: () {
            // Visual ripple only – no actual counting logic
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isCompleted
                  ? Border.all(color: Colors.green.shade300, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {}, // UI only
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Zekr Text
                      Text(
                        item.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E5C2E),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                      // Row with counter, favorite, audio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Audio and Favorite Icons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite_border,
                                  size: 22,
                                ),
                                color: Colors.red.shade300,
                                onPressed: () {}, // UI only
                                splashRadius: 24,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.volume_up, size: 22),
                                color: Colors.blue.shade400,
                                onPressed: () {}, // UI only
                                splashRadius: 24,
                              ),
                            ],
                          ),
                          // Counter display [current / count]
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '[ ${item.current} / ${item.count} ]',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.green.shade800
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return Column(
      children: [
        // Add button (visual only)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {}, // UI only
              icon: const Icon(Icons.add),
              label: const Text('إضافة ذكر جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _buildZekrList(_customZekr)),
      ],
    );
  }
}

/// Simple data class for UI representation only
class ZekrItem {
  final String text;
  final int count;
  final int current; // UI only – static value

  ZekrItem({required this.text, required this.count, required this.current});
}
