import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// تنظیمات و شناسه‌های گوگل‌درایو و اسکریپت‌ها
// ==========================================
const String scriptApiUrl = 'https://script.google.com/macros/s/AKfycbxCPa7OPOr2Koa9umXaSkd8xoMTvhpPlCNJKDvptSIOTNpRuy01r9N3s-AVuujd75L8/exec'; 
// !!! آدرس وب‌اپ گوگل‌شیت خود را در متغیر زیر قرار دهید:
const String reportScriptUrl = 'https://script.google.com/macros/s/YOUR_REPORT_SCRIPT_URL_HERE/exec';

const String ketabFolderId = '1J3N_YOUR_KETAB_FOLDER_ID';
const String maghalehFolderId = '1K4M_YOUR_MAGHALEH_FOLDER_ID';
const String otherProductsFolderId = '1GLHWFZK0fy74rCz2t-5h4T0UYiZnaZ94';

// لیست جملات کتاب «هزاران فکر عمیق» جهت نمایش در نوار پیمایش افقی (Marquee)
const List<String> deepThoughtsQuotes = [
" امام، منتظرِ قیام ما و ما منتظر ظهور او هستیم! کی و کجا تحقق‌ پیدا خواهد کرد؟",
" مسجد همه‌ی منزلت خود را از سجده‌ی انسان دارد.",   
"کمال انسان مثل آب در کوزه‌ی گلی است، جلوی نشت آن را نمی‌توان گرفت.",
"کاروان ابدیت انسان هنوز در ازل است، پس کاروانت را انتخاب کن!",
"مردم را دوست داشتن کمترین شباهت به خداست.",
"خداوند جایی بهتر از کاروان کربلا برای تجلی ندارد.",
"نگاه ساده به طبیعت نشانه‌ی غفلت است.",
"فقط خدا را نگاه کن تا فقط تو را نگاه کند.",
"هر چه انسان از خدا دورتر شود خدا به او نزدیک تر خواهد بود!",
"کاروانت را انتخاب کن و در مسیر عشق قدم بگذار.",
" عظمت انسان، عظمت خداست.",
" علی(ع) در بلندای عالم است و سرگشتگان به‌سوی ضلالت را به سوی خدا و محبت خود دعوت می‌کند.",
" فاطمه‌ی زهرا سلام‌الله‌علیها بهترین دست‌خط زیبای خداوند در ترسیم چهره‌ی زن است."
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShabHayeDaneshjouyiApp());
}

// مدل آیتم‌های فایل گوگل درایو
class DriveItem {
  final String id;
  final String name;

  DriveItem({required this.id, required this.name});

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    return DriveItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'بدون نام',
    );
  }
}

class ShabHayeDaneshjouyiApp extends StatelessWidget {
  const ShabHayeDaneshjouyiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شب‌های دانشجویی',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        primaryColor: const Color(0xFFFF6B4A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B4A),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF27293D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF27293D),
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// صفحه اسپلش و بررسی Onboarding
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final bool isRegistered = prefs.getBool('is_registered') ?? false;

    if (!mounted) return;

    if (isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 85, color: Color(0xFFFF6B4A)),
            SizedBox(height: 20),
            Text(
              'شب‌های دانشجویی',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'اندیشه، دانایی و رشد فردی',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(height: 35),
            CircularProgressIndicator(color: Color(0xFFFF6B4A)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// صفحه Onboarding (دریافت نام، سن و ارسال به شیت)
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String name = _nameController.text.trim();
    String age = _ageController.text.trim();

    String deviceModel = 'ناشناخته';
    String osVersion = 'ناشناخته';
    String deviceId = 'ناشناخته';

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        deviceId = androidInfo.id;
      }
    } catch (_) {}

    // ذخیره در حافظه محلی
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_age', age);
    await prefs.setBool('is_registered', true);

    // ارسال مشخصات به Google Sheets
    try {
      if (reportScriptUrl.startsWith('https://script.google.com')) {
        await http.post(
          Uri.parse(reportScriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'age': age,
            'deviceModel': deviceModel,
            'osVersion': osVersion,
            'deviceId': deviceId,
          }),
        ).timeout(const Duration(seconds: 7));
      }
    } catch (_) {
      // در صورت نبود اینترنت در مرحله اول، خطا مانع ورود کاربر نمی‌شود
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 75, color: Color(0xFFFF6B4A)),
                  const SizedBox(height: 16),
                  const Text(
                    'به جمع شب‌های دانشجویی خوش آمدید!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'جهت شخصی‌سازی محتوا و همراهی بهتر، لطفاً مشخصات خود را وارد کنید:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'نام و نام خانوادگی',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: const Color(0xFF27293D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً نام خود را وارد کنید' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'سن',
                      prefixIcon: const Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: const Color(0xFF27293D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً سن خود را وارد کنید' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B4A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _submitInfo,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ورود به برنامه', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ویجت نوار پیمایش متنی افقی (Marquee)
// ==========================================
class QuoteMarquee extends StatefulWidget {
  const QuoteMarquee({super.key});

  @override
  State<QuoteMarquee> createState() => _QuoteMarqueeState();
}

class _QuoteMarqueeState extends State<QuoteMarquee> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  late final String _allText;

  @override
  void initState() {
    super.initState();
    _allText = deepThoughtsQuotes.join('  ✦  ') + '  ✦  ';
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!_scrollController.hasClients) return;
      double maxScroll = _scrollController.position.maxScrollExtent;
      double current = _scrollController.offset;
      if (current >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          current + 1.5,
          duration: const Duration(milliseconds: 40),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF27293D),
        border: Border(bottom: BorderSide(color: Color(0x33FF6B4A), width: QuoteMarquee> createState() => _QuoteMarqueeState();
}

class _QuoteMarqueeState extends State<QuoteMarquee> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  late final String _allText;

  @override
  void initState() {
    super.initState();
    _allText = deepThoughtsQuotes.join('  ✦  ') + '  ✦  ';
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!_scrollController.hasClients) return;
      double maxScroll = _scrollController.position.maxScrollExtent;
      double current = _scrollController.offset;
      if (current >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          current + 1.5,
          duration: const Duration(milliseconds: 40),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF27293D),
        border: Border(bottom: BorderSide(color: Color(0x33FF6B4A), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFFF6B4A).withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.auto_stories, size: 16, color: Color(0xFFFF6B4A)),
                SizedBox(width: 4),
                Text('هزاران فکر عمیق:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScroll    setState(() {
      _readItemIds.add(id);
    });
    await prefs.setStringList('read_items_ids', _readItemIds.toList());
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _fetchFolder(ketabFolderId),
        _fetchFolder(maghalehFolderId),
        _fetchFolder(otherProductsFolderId),
      ]);

      setState(() {
        _texts = results[0];
        _lectures = results[1];
        _otherProducts = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطای اتصال به اینترنت. لطفاً مجدداً بررسی نمایید.';
        _isLoading = false;
      });
    }
  }

  Future<List<DriveItem>> _fetchFolder(String folderId) async {
    final url = '$scriptApiUrl?folderId=$folderId';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DriveItem.fromJson(json)).toList();
    }
    return [];
  }

  // دانلود و باز کردن فایل
  Future<void> _downloadAndOpen(DriveItem item, {bool isApk = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF27293D),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFF6B4A)),
                SizedBox(height: 16),
                Text('در حال دریافت و آماده‌سازی فایل...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final downloadUrl = 'https://drive.google.com/uc?export=download&id=${item.id}';
      final response = await http.get(Uri.parse(downloadUrl)).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        
        // ثبت به عنوان خوانده شده
        await _markAsRead(item.id);

        if (!mounted) return;ترنت. لطفاً مجدداً بررسی نمایید.';
        _isLoading = false;
      });
    }
  }

  Future<List<DriveItem>> _fetchFolder(String folderId) async {
    final url = '$scriptApiUrl?folderId=$folderId';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DriveItem.fromJson(json)).toList();
    }
    return [];
  }

  // دانلود و باز کردن فایل
  Future<void> _downloadAndOpen(DriveItem item, {bool isApk = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF27293D),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFF6B4A)),
                SizedBox(height: 16),
                Text('در حال دریافت و آماده‌سازی فایل...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final downloadUrl = 'https://drive.google.com/uc?export=download&id=${item.id}';
      final response = await http.get(Uri.parse(downloadUrl)).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        
        // ثبت به عنوان خوانده شده
        await _markAsRead(item.id);

        if (!mounted) return;
        Navigator.pop(context); // بستن لودینگ

        if (isApk) {
          // مدیریت فایل‌های با پسوند .bin یا تغییر نام به .apk
          String cleanName = item.name.endsWith('.bin') ? item.name.showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // مورد ۱: قابلیت «روزیِ من» (انتخاب تصادفی یک صوت یا متن)
  void _openDailyBlessing() {
    List<DriveItem> pool = [..._texts, ..._lectures];
    if (pool.isEmpty) {
      _showSnackBar('محتوا هنوز بارگذاری نشده است.');
      return;
    }

    final randomItem = pool[Random().nextInt(pool.length)];
    final bool isAudio = randomItem.name.toLowerCase().endsWith('.mp3');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF27293D),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFFF6B4A)),
            SizedBox(width: 8),
            Text('روزیِ امروز شما', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'امروز این تحفه‌ی فکری و معنوی برای شما انتخاب شده است:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF6B4A).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(isAudio ? Icons.headphones : Icons.menu_book, color: const Color(0xFFFF6B4A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      randomItem.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بعداً', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
            onPressed: () {
      return;
    }

    final randomItem = pool[Random().nextInt(pool.length)];
    final bool isAudio = randomItem.name.toLowerCase().endsWith('.mp3');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF27293D),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFFF6B4A)),
            SizedBox(width: 8),
            Text('روزیِ امروز شما', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'امروز این تحفه‌ی فکری و معنوی برای شما انتخاب شده است:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF6B4A).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(isAudio ? Icons.headphones : Icons.menu_book, color: const Color(0xFFFF6B4A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      randomItem.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بعداً', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndOpen(randomItem);
            },
            child: const Text('مشاهده و مطالعه', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // مورد ۴: نشان اعلان (شیپور)
  void _showNotificationNotice() {
    showDialog(
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• زبانه متون و سخنرانی:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              Text('می‌توانید کتب و صوت‌های سخنرانی‌ها را با کلیک دریافت کنید. فایل‌های مطالعه‌شده با تیک سبز متمایز می‌شوند.', style: TextStyle(fontSize: 12.5)),
              SizedBox(height: 10),
              Text('• دکمه "روزیِ من":', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              Text('در هر ورود یا مطالعه روزانه، یک محتوا به صورت تصادفی به عنوان هدیه روز برای شما به نمایش در می‌آید.', style: TextStyle(fontSize: 12.5)),
              SizedBox(height: 10),
              Text('• تست MBTI:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              Text('با پاسخ به ۳۲ سوال، سنخ شخصیتی خود را شناسایی نمایید.', style: TextStyle(fontSize: 12.5)),
              SizedBox(height: 10),
              Text('• بخش محصولات:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              Text('سایر برنامه‌ها نظیر بازی جورچین و نرم‌افزارهای آموزشی از این بخش قابل بارگیری و نصب است.', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن', style: TextStyle(color: Color(0xFFFF6B4A))),
          ),
        ],
      ),
    );
  }

  // مورد ۶: منوی سه نقطه به صورت Bottom Sheet
  void _showCustomBottomSheetMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF27293D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min10),
              Text('• تست MBTI:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              Text('با پاسخ به ۳۲ سوال، سنخ شخصیتی خود را شناسایی نمایید.', style: TextStyle(fontSize: 12.5)),
              SizedBox(height: 10),
              Text('• بخش محصولات:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
              Text('سایر برنامه‌ها نظیر بازی جورچین و نرم‌افزارهای آموزشی از این بخش قابل بارگیری و نصب است.', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن', style: TextStyle(color: Color(0xFFFF6B4A))),
          ),
        ],
      ),
    );
  }

  // مورد ۶: منوی سه نقطه به صورت Bottom Sheet
  void _showCustomBottomSheetMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF27293D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFFF6B4A)),
              title: const Text('درباره ما'),
              onTap: () {
                Navigator.pop(ctx);
                _showAboutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF38BDF8)),
              title: const Text('وبسایت رسمی (shiravi.org)'),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('http://shiravi.org');
              },
            ),
            ListTile(
              leading: const Icon(Icons.send, color: Colors.greenAccent),
              title: const Text('کانال ایتا'),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://eitaa. [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // مورد ۷: تایید خروج با کلیک روی Back گوشی
  Future<bool> _onWillPop() async {
    final bool? exitApp = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF27293D),
        title: const Text('تأیید خروج'),
        content: const Text('آیا مایل به بستن برنامه هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('خیر', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('بله', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return exitApp ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'جستجو در عناوین...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                )
              : const Text('شب‌های دانشجویی'),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.campaign_outlined), // نشان اعلان (شیپور)
              tooltip: 'اعلانات',
              onPressed: _showNotificationNotice,
            ),
            IconButton(
              icon: const Icon(Icons.help_outline), // راهنما
              tooltip: 'راهنما',
              onPressed: _showHelpDialog,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'بیشتر',
              onPressed: _showCustomBottomSheetMenu,
            ),
          ],
        ),
        body: Column(
          children: [
            const QuoteMarquee(), // مورد ۹: نوار پیمایش افقی جملات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)))
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
                                onPressed: _fetchAllData,
                                child: const Text('تلاش مجدد', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _buildTabBody(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF6B4A),
          onPressed: _openDailyBlessing,
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text('روزیِ من', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: const Color(0xFF27293D),
          selectedItemColor: const Color(0xFFFF6B4A),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'متون'),
            BottomNavigationBarItem(icon: Icon(Icons.headphones), label: 'سخنرانی‌ها'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'تست شخصیت'),
            BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'سایر محصولات'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildItemList(_texts, false);
      case 1:
        return _buildItemList(_lectures, false);
      case 2:
        return const MbtiQuizScreen();
      case 3:
        return _buildItemList(_otherProducts, true);
      default:
        return const SizedBox();
    }
  }

  Widget _buildItemList(List<DriveItem> items, bool isProductTab) {
    final filtered = items.where((it) => it.name.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('محتوایی یافت نشد.', style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      color: const Color(0xFFFF6B4A),
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          final bool isRead = _readItemIds.contains(item.id);
          final bool isAudio = item.name.toLowerCase().endsWith('.mp3');

          Widget leadingIcon;
          if (isProductTab) {
            leadingIcon = const Icon(Icons.android, color: Colors.greenAccent);
          } else if (isRead) {
            leadingIcon = const Icon(Icons.check_circle, color: Colors.green);
          } else {
            leadingIcon = Icon(isAudio ? Icons.audiotrack : Icons.picture_as_pdf, color: const Color(0xFFFF6B4A));
          }

          return Card(
            color: const Color(0xFF27293D),
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: isRead ? const BorderSide(color: Colors.green, width: 0.5) : BorderSide.none,
            ),
            child: ListTile(
              leading: leadingIcon,
              title: Text(
                item.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  color: isRead ? Colors.white70 : Colors.white,
                ),
              ),
              subtitle: isProductTab
                  ? const Text('جهت بارگیری و نصب لمس کنید', style: TextStyle(fontSize: 11, color: Colors.white54))
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
              onTap: () => _downloadAndOpen(item, isApk: isProductTab),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// صفحه پخش صوت (Audio Player)
// ==========================================
class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const AudioPlayerScreen({super.key, required this.filePath, required this.title});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.play(DeviceFileSource(widget.filePath));
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${twoDigits(d.inHours)}:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پخش سخنرانی')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFFFF6B4A), Color(0xFF27293D)]),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF6B4A).withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.headphones, size: 75, color: Colors.white),
            ),
            const SizedBox(height: 30),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
              value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
              activeColor: const Color(0xFFFF6B4A),
              onChanged: (val) => _player.seek(Duration(seconds: val.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.replay_10),
                  onPressed: () => _player.seek(_position - const Duration(seconds: 10)),
                ),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 64,
                  color: const Color(0xFFFF6B4A),
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  onPressed: () => _isPlaying ? _player.pause() : _player.resume(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.forward_10),
                  onPressed: () => _player.seek(_position + const Duration(seconds: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// صفحه نمایش PDF
// ==========================================
class PdfViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({super.key, required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 15))),
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}

// ==========================================
// بخش تست MBTI (کامل ۳۲ سواله و آفلاین)
// ==========================================
class MbtiQuestion {
  final String title;
  final String optionA;
  final String optionB;
  final String typeA;
  final String typeB;

  MbtiQuestion({
    required this.title,
    required this.optionA,
    required this.optionB,
    required this.typeA,
    required this.typeB,
  });
}

class MbtiQuizScreen extends StatefulWidget {
  const MbtiQuizScreen({super.key});

  @override
  State<MbtiQuizScreen> createState() => _MbtiQuizScreenState();
}

class _MbtiQuizScreenState extends State<MbtiQuizScreen> {
  final Map<int, String> _answers = {};
  String? _finalResult;

  final List<MbtiQuestion> _questions = [
    // بخش E vs I
    MbtiQuestion(title: "در جمع‌های شلوغ معمولاً:", optionA: "انرژی بیشتری می‌گیرم و سرزنده می‌شوم.", optionB: "انرژی‌ام تحلیل می‌رود و نیاز به خلوت دارم.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "برای حل مسائل فکری ترجیح می‌دهید:", optionA: "با دیگران همفکری و گفتگو کنم.", optionB: "ابتدا در تنهایی خودم به آن فکر کنم.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "در یک محیط تازه:", optionA: "سریعاً با دیگران ارتباط برقرار می‌کنم.", optionB: "کمی صبر می‌کنم تا بقیه جلو بیایند.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "بعد از یک هفته کاری سنگین:", optionA: "رفتن به دورهمی خستگی‌ام را در می‌آورد.", optionB: "ماندن در خانه و مطالعه/استراحت آرامم می‌کند.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "معمولاً:", optionA: "ابتدا حرف می‌زنم و سپس عمیقاً فکر می‌کنم.", optionB: "ابتدا در ذهن می‌سنجم و بعد سخن می‌گویم.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "دایره ارتباطات شما:", optionA: "گسترده و شامل افراد گوناگون است.", optionB: "محدود به چند دوست بسیار نزدیک و عمیق است.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "در اوقات فراغت:", optionA: "فعالیت گروهی را ترجیح می‌دهم.", optionB: "فعالیت فردی و تمرکز درونی را می‌پسندم.", typeA: "E", typeB: "I"),
    MbtiQuestion(title: "دیگران معمولاً شما را فردی:", optionA: "پرانرژی و برون‌ریز می‌دانند.", optionB: "آرام، تودار و متفکر توصیف می‌کنند.", typeA: "E", typeB: "I"),

    // بخش S vs N
    MbtiQuestion(title: "در مواجهه با اطلاعات جدید:", optionA: "به جزئیات، آمار و واقعیات ملموس توجه دارم.", optionB: "به کلیت، ارتباطات پنهان و الگوهای کلان می‌نگرم.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "بیشتر به چه چیزی علاقه دارید؟", optionA: "مسائل کاربردی که همین الان قابل اجرا باشند.", optionB: "ایده‌ها و نظریه‌های آینده‌نگرانه.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "رویکرد شما به تجارب پیشین:", optionA: "به روش‌های آزموده‌شده پایبندم.", optionB: "همواره به دنبال راه‌های جدید و نوآوری هستم.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "هنگام توصیف یک رویداد:", optionA: "به ترتیب و با ذکر جزئیات دقیق بیان می‌کنم.", optionB: "برداشت و حس کلی واقعه را تعریف می‌کنم.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "شما بیشتر فردی:", optionA: "واقع‌بین و اهل عمل هستید.", optionB: "الهام‌پذیر و صاحب تخیل هستید.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "در پروژه‌ها معمولاً:", optionA: "به شیوه‌های گام‌به‌گام و ملموس اعتماد دارم.", optionB: "به بینش ناگهانی و خلاقیت ناخودآگاه اتکا دارم.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "علاقه به خواندن کدام متون دارید؟", optionA: "کتب راهنما، تاریخی و مستند.", optionB: "کتب فلسفی، نمادین و استعاری.", typeA: "S", typeB: "N"),
    MbtiQuestion(title: "در زندگی روزمره:", optionA: "به آنچه در واقعیت وجود دارد تمرکز دارم.", optionB: "به آنچه می‌تواند در آینده خلق شود می‌اندیشم.", typeA: "S", typeB: "N"),

    // بخش T vs F
    MbtiQuestion(title: "هنگام تصمیم‌گیری مهم:", optionA: "منطق، اصول بی‌طرفانه و سود/زیان را مبنا قرار می‌دهم.", optionB: "ارزش‌های انسانی و احساسات افراد درگیر را ملاک می‌دانم.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "در برخورد با اختلاف میان دوستان:", optionA: "حق و حقیقت منطقی را شفاف می‌گویم حتی اگر تلخ باشد.", optionB: "سعی در حفظ هماهنگی، همدلی و آرامش دل‌ها دارم.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "انتقاد از دیگران:", optionA: "صریح و بر پایه دلایل منطقی است.", optionB: "با احتیاط و مراعات شدید احساس طرف مقابل همراه است.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "کدام صفت بیشتر برازنده شماست؟", optionA: "منطقی و منصف.", optionB: "مهربان و صمیمی.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "در قضاوت‌ها:", optionA: "عدالت یکسان برای همه بر اساس ضوابط.", optionB: "درک شرایط ویژه فرد و بخشش عاطفی.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "هنگام مواجهه با مشکل دوستتان:", optionA: "سریعاً راه‌حل‌های عملی و تحلیلی پیشنهاد می‌دهم.", optionB: "گوش شنوا می‌شوم و با او همدردی احساسی می‌کنم.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "بیشتر به چه تحسینی نیاز دارید؟", optionA: "تحسین شایستگی فکری و کارآمدی.", optionB: "تحسین درک عاطفی و مهربانی.", typeA: "T", typeB: "F"),
    MbtiQuestion(title: "معیار شما برای سنجش موفقیت:", optionA: "دستیابی به اهداف استاندارد و منطقی.", optionB: "میزان رضایت، پیوند انسانی و آرامش.", typeA: "T", typeB: "F"),

    // بخش J vs P
    MbtiQuestion(title: "در امور روزانه:", optionA: "برنامه‌ریزی دقیق، جدول زمانی و ددلاین‌ها را دوست دارم.", optionB: "انعطاف‌پذیری و جریان خودانگیخته را ترجیح می‌دهم.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "قبل از سفر:", optionA: "همه چیز را رزرو کرده و برنامه مشخص می‌نویسم.", optionB: "بدون نقشه قبلی می‌روم تا در لحظه تصمیم بگیرم.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "انجام کارها و تکالیف:", optionA: "خیلی زودتر از موعد تحویل تمام می‌کنم.", optionB: "در لحظات آخر و زیر فشار نهایی بهترین نتیجه را می‌گیرم.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "نظم اتاق و میز کار شما:", optionA: "همیشه مرتب، سازمان‌یافته و در جای مشخص است.", optionB: "نظم خلاقانه در بی‌نظمی ظاهری وجود دارد.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "پرونده‌ها و تصمیمات:", optionA: "سریعاً تصمیم نهایی را می‌گیرم و پرونده را می‌بندم.", optionB: "ترجیح می‌دهم گزینه‌ها باز بمانند تا اطلاعات جدید برسد.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "سبک زندگی شما:", optionA: "ساختاریافته و همراه با چارچوب‌های تثبیت‌شده.", optionB: "تطبیق‌پذیر، غیرمنتظره و بازی‌گوشانه با رویدادها.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "تغییر ناگهانی در برنامه‌ها:", optionA: "مرا کلافه و مضطرب می‌کند.", optionB: "به عنوان فرصتی جدید و هیجان‌انگیز از آن استقبال می‌کنم.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "رضایت درونی شما از چیست؟", optionA: "تیک زدن و پایان دادن کامل به وظایف.", optionB: "شروع کاوش‌های نو و جریان تجربه اندوزی.", typeA: "J", typeB: "P"),
  ];

  final Map<String, Map<String, String>> _personalityDetails = {
    'INTJ': {'title': 'معمار / استراتژیست', 'desc': 'متفکرانی مبتکر با انگیزه‌ای درونی برای اجرای ایده‌ها و رسیدن به هدف‌ها. تحلیل‌گر، مستقل و کمال‌گرا.'},
    'INTP': {'title': 'اندیشمند / منطق‌دان', 'desc': 'جستجوگر تبیین‌های منطقی برای هر پدیده؛ تئوریکMbtiQuestion(title: "پرونده‌ها و تصمیمات:", optionA: "سریعاً تصمیم نهایی را می‌گیرم و پرونده را می‌بندم.", optionB: "ترجیح می‌دهم گزینه‌ها باز بمانند تا اطلاعات جدید برسد.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "سبک زندگی شما:", optionA: "ساختاریافته و همراه با چارچوب‌های تثبیت‌شده.", optionB: "تطبیق‌پذیر، غیرمنتظره و بازی‌گوشانه با رویدادها.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "تغییر ناگهانی در برنامه‌ها:", optionA: "مرا کلافه و مضطرب می‌کند.", optionB: "به عنوان فرصتی جدید و هیجان‌انگیز از آن استقبال می‌کنم.", typeA: "J", typeB: "P"),
    MbtiQuestion(title: "رضایت درونی شما از چیست؟", optionA: "تیک زدن و پایان دادن کامل به وظایف.", optionB: "شروع کاوش‌های نو و جریان تجربه اندوزی.", typeA: "J", typeB: "P"),
  ];

  final Map<String, Map<String, String>> _personalityDetails = {
    'INTJ': {'title': 'معمار / استراتژیست', 'desc': 'متفکرانی مبتکر با انگیزه‌ای درونی برای اجرای ایده‌ها و رسیدن به هدف‌ها. تحلیل‌گر، مستقل و کمال‌گرا.'},
    'INTP': {'title': 'اندیشمند / منطق‌دان', 'desc': 'جستجوگر تبیین‌های منطقی برای هر پدیده؛ تئوریک، کنجکاو، دقیق و علاقه‌مند به مفاهیم محض.'},
    'ENTJ': {'title': 'فرمانده / پیشرو', 'desc': 'رهبرانی قاطع، رک و سامان‌دهنده که سیستم‌ها و نیروها را برای تحقق مقاصد به خوبی سازماندهی می‌کنند.'},
    'ENTP': {'title': 'مبتکر / مجادله‌گر', 'desc': 'سریع، زیرک، مشتاق مناظره، عاشق طرح احتملموس باور دارند.'},
    'ESFJ': {'title': 'سفیر / مراقب', 'desc': 'خوش‌مشرب، خونگرم، وظیفه‌شناس و هماهنگ‌کننده جوامع انسانی با حساسیت نسبت به نیاز دیگران.'},
    'ISTP': {'title': 'چیره‌دست / مکانیک', 'desc': 'ناظرانی تیزبین، خونسرد، مسلط بر ابزارها و اهل عمل که مسائل پیچیده فنی را در سکوت حل می‌کنند.'},
    'ISFP': {'title': 'هنرمند / ماجراجو', 'desc': 'آرام، حساس، لذت‌برنده از لحظه حال، دارای درک زیباشناختی بسیار بالا و وفادار به باورها.'},
    'ESTP': {'title': 'کارآفرین / پویا', 'desc': 'اهل ریسک، سریع در واکنش، عمل‌گرا، عاشق هیجان و مواجهه عملی با امور ملموس زندگی.'},
    'ESFP': {'title': 'بازیگر / سرگرم‌کننده', 'desc': 'برون‌گرا، خودانگیخته، شاد و سرزنده که لذت حضور را به همگان هدیه می‌دهند.'},
  };

  void _calculateResult() {
    int e = 0, i = 0, s = 0, n = 0, t = 0, f = 0, j = 0, p = 0;

    _answers.forEach((index, ans) {
      if (ans == 'E') e++;
      if (ans == 'I') i++;
      if (ans == 'S') s++;
      if (ans == 'N') n++;
      if (ans == 'T') t++;
      if (ans == 'F') f++;
      if (ans == 'J') j++;
      if (ans == 'P') p++;
    });

    String type = '';
    type += (e >= i) ? 'E' : 'I';
    type += (s >= n) ? 'S' : 'N';
    type += (t >= f) ? 'T' : 'F';
    type += (j >= p) ? 'J' : 'P';

    setState(() {
      _finalResult = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finalResult != null) {
      final info = _personalityDetails[_finalResult] ?? {'title': 'نامشخص', 'desc': ''};
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF27293D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF6B4A), width: 2),
                ),
                child: Column(
                  children: [
                    const Text('نتیجه سنخ‌شناسی شخصیتی شما', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(
                      _finalResult!,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A)),
                    ),
                    Text(
                      info['title']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      info['desc']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, height: 1.6, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('پاسخ‌گویی مجدد', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() {
                    _answers.clear();
                    _finalResult = null;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: _answers.length / _questions.length,
          backgroundColor: const Color(0xFF27293D),
          color: const Color(0xFFFF6B4A),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('آزمون خودارزیابی سنخ شخصیتی (MBTI)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              Text('${_answers.length} از ${_questions.length}', style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B4A))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _questions.length,
            itemBuilder: (ctx, idx) {
              final q = _questions[idx];
              final selected = _answers[idx];

              return Card(
                color: const Color(0xFF27293D),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${idx + 1}. ${q.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        value: q.typeA,
                        groupValue: selected,
                        activeColor: const Color(0xFFFF6B4A),
                        title: Text(q.optionA, style: const TextStyle(fontSize: 12)),
                        onChanged: (val) => setState(() => _answers[idx] = val!),
                      ),
                      RadioListTile<String>(
                        value: q.typeB,
                        groupValue: selected,
                        activeColor: const Color(0xFFFF6B4A),
                        title: Text(q.optionB, style: const TextStyle(fontSize: 12)),
                        onChanged: (val) => setState(() => _answers[idx] = val!),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B4A),
                disabledBackgroundColor: Colors.white24,
              ),
              onPressed: _answers.length == _questions.length ? _calculateResult : null,
              child: const Text('مشاهده تحلیل شخصیت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
