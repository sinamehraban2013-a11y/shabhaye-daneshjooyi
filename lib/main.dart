import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

// ==========================================
// تنظیمات و شناسه‌های گوگل‌درایو و اسکریپت‌ها
// ==========================================
const String scriptApiUrl = 'https://script.google.com/macros/s/AKfycbwBLyDbJu78M_nxaZtfcfFtd6DSMp6yl3Lu2lPOPwimuDynqGN8cTvZr4JpN3eJhxGA/exec'; 
// !!! آدرس وب‌اپ گوگل‌شیت خود را در متغیر زیر قرار دهید:
const String reportScriptUrl = 'https://script.google.com/macros/s/AKfycbxCPa7OPOr2Koa9umXaSkd8xoMTvhpPlCNJKDvptSIOTNpRuy01r9N3s-AVuujd75L8/exec';

const String sotFolderId = '16aRam3dFDXiFl0bgQN-3a5iZP6Q4HPE9';     // پوشه سخنرانی‌ها و صوت‌ها
const String motoonFolderId = '1R7LxofkSaSz5EGsgSv1TSbBAbJR_wE82';  // پوشه متون و کتب
const String otherProductsFolderId = '1GLHWFZK0fy74rCz2t-5h4T0UYiZnaZ94';
const String announcementFileId = '1aDcz3OOlf8oGcYmqt7gt3pJXuJjQmasGN_YqpCrorjg'; 

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

// ۷ جمله انگیزشی و ترغیب‌کننده برای روزهای هفته
const List<String> dailyMotivationMessages = [
  'امروز روزی شما در نرم‌افزار «شب‌های دانشجویی» آماده است؛ حتماً یک سر بزنید! ✨',
  'یک جرعه فکر عمیق برای آرامش امروز شما؛ سخنرانی جدید را از دست ندهید. 🎧',
  'چند دقیقه تأمل، یک دنیا آگاهی؛ کتابخانه تخصصی شب‌های دانشجویی منتظر شماست. 📚',
  'امروز با یک نکته ناب معرفتی همراه ما باشید؛ روزیِ امروزتان را دریافت کنید. 🌟',
  'فرصتی کوتاه برای اندیشیدن؛ مقالات و مباحث صوتی این هفته را شنیده‌اید؟ 💡',
  'همراه با جمع اندیشه‌ورزان؛ محتوای جدید کانال فکر عمیق در اپلیکیشن بارگذاری شد. 🌿',
  'روزی معنوی و فکری امروز شما آماده است؛ همین حالا نرم‌افزار را باز کنید. 📖',
];

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupDailyNotifications() async {
  try {
    // ۱. مقداردهی اولیه منطقه زمانی محلی
    tz.initializeTimeZones();

    // تنظیم زمان محلی مطابق با افست ساعت خودِ دستگاه کاربر
    final nowLocal = DateTime.now();
    final localLocation = tz.getLocation(tz.local.name);
    tz.setLocalLocation(localLocation);

    // ۲. تنظیمات اجرای نوتیفیکیشن و باز شدن برنامه با کلیک
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // با لمس نوتیفیکیشن، اپلیکیشن در صفحه اصلی فراخوانی و باز می‌شود
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // ۳. اخذ کلیه مجوزهای لازم در اندروید ۱۳ و مجوز آلارم دقیق در اندروید ۱۲+
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      // درخواست دسترسی دقیق برای دور زدن مدیریت انرژی و تاخیر باتری
      await androidPlugin.requestExactAlarmsPermission();
    }

    // ۴. پاکسازی زمان‌بندی‌های پیشین جهت جلوگیری از تداخل شناسه‌ها
    for (int i = 0; i < 7; i++) {
      await flutterLocalNotificationsPlugin.cancel(100 + i);
    }

    // ۵. زمان‌بندی دقیق ۷ روز آینده (راس ساعت ۱۷ بر مبنای ساعت دستگاه)
    DateTime anchor = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      17,
      0,
    );

    // اگر ساعت ۱۷ امروز گذشته، چرخه از فردا ساعت ۱۷ شروع می‌شود
    if (nowLocal.isAfter(anchor)) {
      anchor = anchor.add(const Duration(days: 1));
    }

    // تنظیم جزئیات اعلان با بالاترین اولویت سیستمی
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder_channel_v2',
        'یادآورهای روزانه شب‌های دانشجویی',
        channelDescription: 'پیام‌های انگیزشی و یادآوری رأس ساعت ۱۷',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'شب‌های دانشجویی',
        playSound: true,
        enableVibration: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
    );

    // برنامه‌ریزی ۷ روز متوالی؛ با پایان روز هفتم مجدداً تکرار هفتگی ادامه می‌یابد
    for (int i = 0; i < 7; i++) {
      final scheduledDay = anchor.add(Duration(days: i));

      // تبدیل زمان محلی دقیق دستگاه به TZDateTime
      final tzScheduledDate = tz.TZDateTime.from(scheduledDay, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        100 + i,
        'شب‌های دانشجویی 🌙',
        dailyMotivationMessages[i],
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // عبور از بهینه‌سازی باتری
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // تکرار هفتگی بی‌نهایت
      );
    }
    debugPrint('All 7 daily notifications scheduled successfully at 17:00.');
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShabHayeDaneshjouyiApp());
  // اجرای ایمن و غیرمسدودکننده در پس‌زمینه بعد از لود کامل UI
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setupDailyNotifications();
  });
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
              'تلاقی اندیشه، معرفت و پویایی',
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
    // ۱۵ کاراکتر فاصله بین هر جمله
    _allText = deepThoughtsQuotes.join('               ') + '  *****  ';
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
        border: Border(
          bottom: BorderSide(color: Color(0x33FF6B4A), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Center(
                  child: Text(
                    _allText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
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
}

// Audio playback is shared by the full-screen player and the home mini-player.
class GlobalAudioService {
  static final GlobalAudioService instance = GlobalAudioService._internal();
  factory GlobalAudioService() => instance;
  GlobalAudioService._internal() { _initListeners(); }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  final ValueNotifier<String?> currentFilePath = ValueNotifier<String?>(null);
  final ValueNotifier<String?> currentTitle = ValueNotifier<String?>(null);
  final ValueNotifier<PlayerState> playerState = ValueNotifier<PlayerState>(PlayerState.stopped);
  final ValueNotifier<Duration> position = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<double> speed = ValueNotifier<double>(1.0);
  bool _listenersInitialized = false;

  void _initListeners() {
    if (_listenersInitialized) return;
    _listenersInitialized = true;
    _player.onPlayerStateChanged.listen((s) => playerState.value = s);
    _player.onPositionChanged.listen((p) => position.value = p);
    _player.onDurationChanged.listen((d) => duration.value = d);
  }

  Future<void> play(String path, String title) async {
    _initListeners();
    if (currentFilePath.value == path && playerState.value == PlayerState.playing) return;
    currentFilePath.value = path;
    currentTitle.value = title;
    await _player.stop();
    await _player.setPlaybackRate(speed.value);
    await _player.play(DeviceFileSource(path));
  }

  Future<void> togglePlayPause() async {
    if (playerState.value == PlayerState.playing) {
      await _player.pause();
    } else if (playerState.value == PlayerState.paused) {
      await _player.resume();
    } else if (currentFilePath.value != null) {
      await _player.play(DeviceFileSource(currentFilePath.value!));
    }
  }

  Future<void> seek(Duration value) => _player.seek(value);
  Future<void> setSpeed(double value) async {
    speed.value = value;
    await _player.setPlaybackRate(value);
  }

  Future<void> stop() async {
    await _player.stop();
    currentFilePath.value = null;
    currentTitle.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }
}

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = GlobalAudioService.instance;
    return ValueListenableBuilder<String?>(
      valueListenable: audio.currentFilePath,
      builder: (context, path, _) {
        if (path == null || path.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B3B4B), Color(0xFF132A36)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66FF6B4A)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AudioPlayerScreen(filePath: path, title: audio.currentTitle.value ?? 'در حال پخش'),
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Icon(Icons.music_note_rounded, color: Color(0xFFFF6B4A), size: 25),
                    const SizedBox(width: 8),
                    Expanded(child: ValueListenableBuilder<String?>(
                      valueListenable: audio.currentTitle,
                      builder: (context, title, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title ?? 'در حال پخش', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ValueListenableBuilder<Duration>(valueListenable: audio.position, builder: (context, pos, _) {
                          final d = audio.duration.value;
                          String fmt(Duration x) => '${x.inMinutes.remainder(60).toString().padLeft(2, '0')}:${x.inSeconds.remainder(60).toString().padLeft(2, '0')}';
                          return Text('${fmt(pos)} / ${fmt(d)}', style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 11));
                        }),
                      ]),
                    )),
                    ValueListenableBuilder<PlayerState>(valueListenable: audio.playerState, builder: (context, state, _) =>
                      IconButton(icon: Icon(state == PlayerState.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: const Color(0xFFFF6B4A), size: 32), onPressed: audio.togglePlayPause)),
                    IconButton(icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(.65), size: 20), onPressed: audio.stop),
                  ]),
                  ValueListenableBuilder<Duration>(valueListenable: audio.position, builder: (context, pos, _) {
                    final ms = audio.duration.value.inMilliseconds;
                    final progress = ms > 0 ? (pos.inMilliseconds / ms).clamp(0.0, 1.0).toDouble() : 0.0;
                    return ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(
                      value: progress, minHeight: 3, backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B4A))));
                  }),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _normalizeFaSearch(String text) => text
    .replaceAll('ي', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll('ة', 'ه')
    .replaceAll('\u200C', '')
    .replaceAll(' ', '')
    .toLowerCase()
    .trim();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  double _blessingPosX = 20.0;
  double _blessingPosY = 500.0;

  List<DriveItem> _texts = [];
  List<DriveItem> _lectures = [];
  List<DriveItem> _otherProducts = [];
  List<String> _readItemIds = [];
  Set<String> _cachedFileNames = {};
  bool _hasNewAnnouncement = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // روشن نگه‌داشتن صفحه
    _loadReadItems();
    _updateCachedFilesList(); // <--- این خط اضافه شود
    _fetchAllData();
    _checkNewAnnouncement();
  }
  Future<void> _updateCachedFilesList() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      if (mounted) {
        setState(() {
          _cachedFileNames = files;
        });
      }
    } catch (e) {
      debugPrint('Error updating cached files: $e');
    }
  }

  Future<void> _manageCacheLimit() async {
    try {
      final dir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = dir.listSync()
        ..retainWhere((file) => file is File && (file.path.endsWith('.pdf') || file.path.endsWith('.mp3') || file.path.endsWith('.m4a') || file.path.endsWith('.wav')));
      
      if (files.length > 10) { // سقف ۱۰ فایل
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        final int deleteCount = files.length - 10;
        for (int i = 0; i < deleteCount; i++) {
          await files[i].delete();
        }
      }
      await _updateCachedFilesList();
    } catch (e) {
      debugPrint('Cache management error: $e');
    }
  }  

  @override
  void dispose() {
    WakelockPlus.disable(); // آزادسازی در خروج کامل
    super.dispose();
  }
  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _fetchFolder(sotFolderId),      // نتایج صوتی (سخنرانی‌ها)
        _fetchFolder(motoonFolderId),   // نتایج متنی (PDF)
        _fetchFolder(otherProductsFolderId),
      ]);

      if (!mounted) return;

      setState(() {
        _lectures = results[0];       // سخنرانی‌ها / صوت
        _texts = results[1];          // متون
        _otherProducts = results[2];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطا در دریافت اطلاعات: $e';
      });
    }
  }
  Future<List<DriveItem>> _fetchFolder(String folderId) async {
    final url = '$scriptApiUrl?folderId=$folderId';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DriveItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching folder: $e');
    }
    return [];
  }
  
String _getLocalFileName(
  DriveItem item, {
  bool isPdf = false,
  bool isApk = false,
}) {
  String fileName = item.name
      .replaceAll(
        RegExp(r'\.bin$', caseSensitive: false),
        '',
      )
      .trim();

  // جلوگیری از ایجاد مسیرهای نامعتبر در اندروید
  fileName = fileName
      .replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      )
      .trim();

  if (fileName.isEmpty) {
    fileName = item.id;
  }

  final lowerName = fileName.toLowerCase();

  if (isPdf && !lowerName.endsWith('.pdf')) {
    fileName = '$fileName.pdf';
  } else if (isApk && !lowerName.endsWith('.apk')) {
    fileName = '$fileName.apk';
  } else if (!isPdf &&
      !isApk &&
      !lowerName.endsWith('.mp3') &&
      !lowerName.endsWith('.m4a') &&
      !lowerName.endsWith('.wav') &&
      !lowerName.endsWith('.aac') &&
      !lowerName.endsWith('.ogg') &&
      !lowerName.endsWith('.flac')) {
    // برای شناسایی مطمئن‌تر فایل صوتی توسط پلیر
    fileName = '$fileName.mp3';
  }

  return fileName;
}

  Future<void> _downloadAndOpen(
    DriveItem item, {
    bool isApk = false,
    bool isPdf = false,
  }) async {
    bool downloadDialogIsOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          backgroundColor: Color(0xFF27293D),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFF6B4A),
              ),
              SizedBox(height: 16),
              Text(
                'در حال دریافت فایل...\nلطفاً شکیبا باشید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();

      final fileName = _getLocalFileName(
        item,
        isPdf: isPdf,
        isApk: isApk,
      );

      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      bool hasPrefix(List<int> bytes, List<int> prefix) {
        if (bytes.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
          if (bytes[i] != prefix[i]) return false;
        }
        return true;
      }

      bool looksLikeHtml(List<int> bytes) {
        if (bytes.isEmpty) return false;
        final text = utf8.decode(bytes, allowMalformed: true).trimLeft().toLowerCase();
        return text.startsWith('<!doctype html') ||
            text.startsWith('<html') ||
            text.contains('<title>google drive') ||
            text.contains('google drive');
      }

      Future<List<int>> readFileSample() {
        return file.openRead(0, 512).fold<List<int>>(
          <int>[],
          (buffer, chunk) {
            buffer.addAll(chunk);
            return buffer;
          },
        );
      }

      bool shouldDownload = !await file.exists();

      if (!shouldDownload) {
        final fileLength = await file.length();
        if (fileLength == 0) {
          shouldDownload = true;
        } else {
          final cachedSample = await readFileSample();
          if (looksLikeHtml(cachedSample)) {
            shouldDownload = true;
          } else if (isPdf && !hasPrefix(cachedSample, <int>[37, 80, 68, 70])) {
            shouldDownload = true;
          } else if (isApk && !hasPrefix(cachedSample, <int>[80, 75])) {
            shouldDownload = true;
          }
        }
      }

      if (shouldDownload) {
        final downloadUri = Uri.parse(
          'https://docs.google.com/uc?export=download&id=${item.id}&confirm=t',
        );

        final response = await http.get(downloadUri).timeout(
          const Duration(seconds: 90),
        );

        if (response.statusCode != 200) {
          throw Exception('خطا در دریافت فایل (${response.statusCode})');
        }

        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw Exception('فایل دریافتی خالی است');
        }

        final contentType = response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('text/html') || looksLikeHtml(bytes)) {
          throw Exception('گوگل‌درایو به‌جای فایل، صفحهٔ HTML ارسال کرده است');
        }

        if (isPdf && !hasPrefix(bytes, <int>[37, 80, 68, 70])) {
          throw Exception('فایل دریافتی PDF معتبر نیست');
        }

        if (isApk && !hasPrefix(bytes, <int>[80, 75])) {
          throw Exception('فایل دریافتی معتبر نیست');
        }

        await file.writeAsBytes(bytes, flush: true);
        await _manageCacheLimit();
      }

      // حفظ سیستم ثبت فایل خوانده‌شده
      await _markAsRead(item.id);

      // به‌روزرسانی آیکون آماده‌بودن فایل برای استفادهٔ آفلاین
      await _updateCachedFilesList();

      if (!mounted) return;

      if (downloadDialogIsOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        downloadDialogIsOpen = false;
      }

      if (isApk) {
        final lower = fileName.toLowerCase();
        String? mimeType;
        if (lower.endsWith('.apk')) {
          mimeType = 'application/vnd.android.package-archive';
        } else if (lower.endsWith('.zip')) {
          mimeType = 'application/zip';
        }
        await OpenFilex.open(filePath, type: mimeType);
      } else if (isPdf) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              title: item.name,
              filePath: filePath,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              title: item.name,
              filePath: filePath,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (downloadDialogIsOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        downloadDialogIsOpen = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بارگیری یا پخش: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  // مورد ۱: قابلیت «روزیِ من» (انتخاب تصادفی یک صوت یا متن)
  void _openDailyBlessing() {
    // انتخاب فقط از بین فایل‌های صوتی (سخنرانی‌ها)
    List<DriveItem> pool = [..._lectures];

    if (pool.isEmpty) {
      _showSnackBar('محتوای صوتی هنوز بارگذاری نشده است یا در دسترس نیست.');
      return;
    }

    final randomItem = pool[Random().nextInt(pool.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headphones,
                color: Color(0xFFD4AF37),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'روزیِ صوتی امروز شما',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'یک قطعه صوتی به عنوان رزق معنوی و فکری امروز شما انتخاب شد:',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.audiotrack,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      randomItem.name,
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
            child: const Text(
              'بعداً',
              style: TextStyle(
                fontFamily: 'Vazir',
                color: Colors.white54,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text(
              'دریافت و پخش',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx); // بستن پنجره روزی من
              _downloadAndOpen(randomItem); // نمایش دیالوگ دانلود و سپس باز شدن و پخش در پلیر
            },
          ),
        ],
      ),
    );
  }
            
  // متد خواندن مستقیم متن اطلاعیه از فایل درایو
  Future<String?> _fetchAnnouncementText() async {
    try {
      // لینک کامل و مستقیم دریافت خروجی متنی فایل ورد
      const fullDirectUrl =
          'https://docs.google.com/document/d/1aDcz3OOlf8oGcYmqt7gt3pJXuJjQmasGN_YqpCrorjg/export?format=txt';

      final response = await http
          .get(Uri.parse(fullDirectUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        // اطمینان از اینکه خروجی متن است نه صفحه خطای وب
        if (!body.startsWith('<!DOCTYPE') &&
            !body.startsWith('<html') &&
            body.isNotEmpty) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('Error fetching direct announcement: $e');
    }
    return null;
  }

  // بررسی خودکار تغییر متن برای نمایش نقطه قرمز
  Future<void> _checkNewAnnouncement() async {
    try {
      final text = await _fetchAnnouncementText();
      if (!mounted || text == null || text.trim().isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString('last_seen_announcement') ?? '';
      
      if (mounted) {
        setState(() {
          _hasNewAnnouncement = (text.trim() != lastSeen.trim());
        });
      }
    } catch (_) {}
  }

  // باز کردن اطلاعیه و خاموش کردن نقطه قرمز
  Future<void> _showNotificationNotice() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final announcement = await _fetchAnnouncementText();
    if (mounted) Navigator.pop(context);

    if (announcement != null && announcement.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_announcement', announcement.trim());
      if (mounted) {
        setState(() {
          _hasNewAnnouncement = false;
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFFFF6B4A)),
            SizedBox(width: 8),
            Text('اطلاعیه‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            announcement ?? 'در حال حاضر پیام یا اطلاعیه جدیدی ثبت نشده است.',
            style: const TextStyle(fontSize: 14, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متوجه شدم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // مورد ۸: راهنمای ۴ بندی دقیق درخواستی (متصل به علامت سوال)
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF27293D),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFFFF6B4A), size: 26),
              SizedBox(width: 8),
              Text(
                'راهنمای استفاده از برنامه',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  number: '۱',
                  text:
                      'برای استفاده از این برنامه کافی است آیکون بخش‌های مختلف در نوار پایین را لمس کنید. فهرست عناوین برای شما باز خواهد شد و هر کدام را مایل بودید انتخاب نموده و منتظر دانلود آن بمانید؛ سخنرانی‌ها به‌صورت خودکار پخش شده، متون در کتابخوان داخلی باز می‌شود و فایل‌های دانلود به صورت خودکار آماده نصب خواهند بود.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  number: '۲',
                  text:
                      'روزیِ روزانه‌ی شما به‌صورت تصادفی با لمس آیکون "روزیِ من" تقدیم خواهد شد و هر زمان مایل به ارزیابی خود بودید از آزمون تست شخصیت بهره ببرید.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  number: '۳',
                  text:
                      'با لمس سه‌نقطه در بالای صفحه می‌توانید با ما در ارتباط باشید و در شبکه‌های اجتماعی ما را دنبال کنید، همچنین با لمس آیکون شیپور، از آخرین اخبار و جدیدترین محصولات ما مطلع شوید.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  number: '۴',
                  text:
                      'فایل‌هایی را که می‌بینید و می‌شنوید با تیک سبز کم‌رنگ مشخص می‌شود و برای استفاده بدون اینترنت، ده فایل آخری که دانلود نموده‌اید در حافظه موجود بوده و با تیک سبز پررنگ مشخص می‌باشند.',
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text(
                  'بستن',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // متد کمکی جهت چیدمان منظم هر بند راهنما با تراز کامل و شماره فارسی
  Widget _buildHelpItem({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B4A).withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFF6B4A).withOpacity(0.4)),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFF6B4A),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }

            
void _showFeedbackDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ارتباط با ما', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('نظرات، پیشنهادات و مطالب خود را برای ما نوشته و ارسال کنید:'),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'متن پیام شما...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B4A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final message = textController.text.trim();
                if (message.isEmpty) return;

                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'm_khozani@yahoo.com',
                  queryParameters: {
                    'subject': 'نظر کاربر برنامه شبهای دانشجویی',
                    'body': message,
                  },
                );

                Navigator.pop(ctx);
                await _launchURL(emailUri.toString());
              },
              child: const Text('ارسال'),
            ),
          ],
        ),
      ),
    );
  }

  // تابع ساخت کارت‌های زیبای منو با طراحی اختصاصی
  Widget _buildMenuSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF6B4226),
    Color iconBgColor = const Color(0xFFF5EBE1),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEADBCE), width: 1),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBgColor,
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF4A2810),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF8D6E63),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: Color(0xFFBCAAA4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نمایش منوی کشویی پایین
  void _showMoreMenuSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7ED), // پس‌زمینه کرم گرم و چشم‌نواز
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // دستگیره بالای منو
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4226).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.info_outline_rounded,
                    title: 'درباره‌ی ما',
                    subtitle: 'با ما بیشتر آشنا شوید',
                    iconColor: const Color(0xFF6B4226),
                    iconBgColor: const Color(0xFFF3E7DC),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAboutDialog();
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.send_rounded,
                    title: 'کانال هزاران فکر عمیق دکتر شیروی',
                    subtitle: 'کلیک کنید، سپس روی دکمه‌ی پیوستن بزنید',
                    iconColor: const Color(0xFFFF8A00),
                    iconBgColor: const Color(0xFFFFF0DC),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEitaaChannel(
                        'eitaa://shiravi_ir',
                        'https://eitaa.com/shiravi_ir',
                      );
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.question_answer_rounded,
                    title: 'گروه پاسخ به پرسش‌های سخت دکتر شیروی',
                    subtitle: 'کلیک کنید، سپس عضو گروه شوید',
                    iconColor: const Color(0xFFFF6B4A),
                    iconBgColor: const Color(0xFFE0F2F1),
                    onTap: () {
                      Navigator.pop(ctx);
                      _launchURL('https://ble.ir/join/NGMyZGI5OT');
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.menu_book_rounded,
                    title: 'کانال به‌روزترین مقالات فرهنگی و آموزشی',
                    subtitle: 'کلیک کنید، سپس روی دکمه‌ی پیوستن بزنید',
                    iconColor: const Color(0xFFFF6B4A),
                    iconBgColor: const Color(0xFF27293D),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEitaaChannel(
                        'eitaa://maghaleh_shiravi',
                        'https://eitaa.com/maghaleh_shiravi',
                      );
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.auto_stories_rounded,
                    title: 'کانال جدیدترین کتب تالیفیِ گروه محفل اُنس',
                    subtitle: 'کلیک کنید، سپس روی دکمه‌ی پیوستن بزنید',
                    iconColor: const Color(0xFF8E24AA),
                    iconBgColor: const Color(0xFFF3E5F5),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEitaaChannel(
                        'eitaa://ketab_shiravi',
                        'https://eitaa.com/ketab_shiravi',
                      );
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.language_rounded,
                    title: 'سایت رسمی استاد دکتر شیروی',
                    subtitle: 'به دنیایی از هزاران شگفتی وارد شوید',
                    iconColor: const Color(0xFF0288D1),
                    iconBgColor: const Color(0xFFE1F5FE),
                    onTap: () {
                      Navigator.pop(ctx);
                      _launchURL('https://shiravi.org');
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'ارتباط با ما',
                    subtitle: 'ارسال پیشنهادات و نظرات شما از طریق ایمیل',
                    iconColor: const Color(0xFFE65100),
                    iconBgColor: const Color(0xFFFFE0B2),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showFeedbackDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
// تابع تایید و بستن برنامه
Future<void> _handleExit(BuildContext context) async {
  final bool? shouldExit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF27293D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'تأیید خروج',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'آیا مایل به بستن برنامه هستید؟',
        style: TextStyle(color: Colors.white70),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('خیر', style: TextStyle(color: Colors.white70)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B4A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('بله', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (shouldExit == true) {
    // خروج قطعی و کامل از اپلیکیشن
    SystemNavigator.pop();
  }
}

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // اجازه بستن مستقیم به سیستم‌عامل داده نمی‌شود
    onPopInvoked: (bool didPop) {
      if (didPop) return;
      _handleExit(context); // هنگام زدن کلید Back، دیالوگ باز می‌شود
    },
    child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // ۱. انتقال دکمه‌های ذره‌بین و شیپور به سمت راست عنوان
        leadingWidth: _isSearching ? 56 : 96,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'بستن جستجو' : 'جستجو',
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
            if (!_isSearching)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.campaign_outlined),
                    tooltip: 'اطلاعیه‌ها',
                    onPressed: _showNotificationNotice,
                  ),
                  if (_hasNewAnnouncement)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),

        // ۲. عنوان صفحه (در مرکز قرار می‌گیرد)
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'جستجو در عناوین...',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              )
            : const Text(
                'شب‌های دانشجویی',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

        // ۳. باقی‌مانده دکمه‌ها در سمت چپ (راهنما و منوی سه نقطه)
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'راهنما',
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'بیشتر',
            onPressed: _showMoreMenuSheet, // <-- به متد منوی کامل متصل شد
          ),
        ],
      ),
        body: Stack(
          children: [
            // محتوای اصلی صفحه
            Column(
              children: [
                const QuoteMarquee(), // نوار پیمایش افقی جملات
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

            // دکمه شناور و قابل جابه‌جایی «روزیِ من»
            Positioned(
              left: _blessingPosX,
              top: _blessingPosY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final screenSize = MediaQuery.of(context).size;
                  setState(() {
                    _blessingPosX += details.delta.dx;
                    _blessingPosY += details.delta.dy;

                    // جلوگیری از بیرون رفتن دکمه از صفحه
                    _blessingPosX = _blessingPosX.clamp(10.0, screenSize.width - 140.0);
                    _blessingPosY = _blessingPosY.clamp(10.0, screenSize.height - 180.0);
                  });
                },
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFFFF6B4A),
                  shadowColor: const Color(0xFFFF6B4A).withOpacity(0.4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _openDailyBlessing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'روزیِ من',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [const GlobalMiniPlayer(), BottomNavigationBar(
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
        )]),
      ),
    );
  }

// تابع کمکی برای نرمال‌سازی متن جهت جستجوی دقیق فارسی
String _normalizeText(String input) {
  return input
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('\u200c', '') // حذف نیم‌فاصله
      .replaceAll(' ', '')
      .toLowerCase();
}

List<DriveItem> _filterItems(List<DriveItem> sourceList) {
  if (_searchQuery.trim().isEmpty) {
    return sourceList;
  }
  final query = _normalizeText(_searchQuery);
  return sourceList.where((item) {
    final title = _normalizeText(item.name);
    return title.contains(query);
  }).toList();
}

Widget _buildTabBody() {
  switch (_selectedIndex) {
    case 0:
      return _buildItemList(_filterItems(_texts));
    case 1:
      return _buildItemList(_filterItems(_lectures));
    case 2:
      return const MbtiQuizScreen();
    case 3:
      return _buildItemList(_filterItems(_texts));
    default:
      return const SizedBox.shrink();
  }
}
  Widget _buildItemList(List<DriveItem> items, {bool isProductTab = false}) {
    if (items.isEmpty && !_isLoading) {
      return RefreshIndicator(
        onRefresh: _fetchAllData,
        color: const Color(0xFFFF6B4A),
        backgroundColor: const Color(0xFF27293D),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'موردی برای نمایش یافت نشد.\nبرای بروزرسانی صفحه را به پایین بکشید.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: const Color(0xFFFF6B4A),
      backgroundColor: const Color(0xFF27293D),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
        final item = items[index];
        final bool isRead = _readItemIds.contains(item.id);

        final bool isOfflineReady = _cachedFileNames.contains(
          _getLocalFileName(
            item,
            isPdf: _selectedIndex == 0,
            isApk: isProductTab,
          ),
        );
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF27293D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFF6B4A).withOpacity(0.15),
                child: Icon(
                  isProductTab
                      ? Icons.apps_rounded
                      : (_selectedIndex == 0 ? Icons.picture_as_pdf_rounded : Icons.audiotrack_rounded),
                  color: const Color(0xFFFF6B4A),
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOfflineReady) ...[
                  const Tooltip(
                    message: 'آماده پخش آفلاین',
                    child: Icon(
                      Icons.offline_pin_rounded,
                      color: Color(0xFF00E676),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (isRead) ...[
                  const Tooltip(
                    message: 'مطالعه شده',
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFFF6B4A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
              ],
            ),
              onTap: () => _downloadAndOpen(
                item,
                isApk: isProductTab,
                isPdf: _selectedIndex == 0,
              ),
            ),
          );
        },
      ),
    );
  }
  
Future<void> _openEitaaChannel(String appUrl, String webUrl) async {
  try {
    final appUri = Uri.parse(appUrl);
    final webUri = Uri.parse(webUrl);

    // ابتدا تلاش برای باز کردن مستقیم در اپلیکیشن ایتا
    final launchedApp = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    if (!launchedApp) {
      // در صورت عدم نصب یا خطا، باز شدن در مرورگر
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    try {
      final webUri = Uri.parse(webUrl);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان باز کردن پیوند وجود ندارد')),
        );
      }
    }
  }
}

  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);

    try {
      // تلاش مستقیم برای باز کردن پیوند (وب، بله، ایمیل و ...)
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان باز کردن این پیوند وجود ندارد.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان باز کردن این پیوند وجود ندارد.')),
        );
      }
    }
  }

  // نمایش اسنک‌بار
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // علامت‌گذاری خوانده‌شده‌ها
  Future<void> _markAsRead(String id) async {
    if (!_readItemIds.contains(id)) {
      setState(() {
        _readItemIds.add(id);
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('read_items', _readItemIds.toList());
      } catch (_) {}
    }
  }
  Future<void> _loadReadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('read_items') ?? [];
      if (mounted) {
        setState(() {
          _readItemIds = savedList; // <-- اصلاح شد (بدون .toSet)
        });
      }
    } catch (_) {}
  }
  
  // دیالوگ درباره ما
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              'درباره برنامه',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: const Text(
            'این نرم‌افزار حاصل ایده‌پردازی و کوشش جوانان هنرمندی است که در پاسخ به ندای رهبر شهید انقلاب و در راستای ایجاد تمدن ایرانی-اسلامی، با تلاشی مخلصانه و خلاقانه، جهاد تبیین را شروع کرده‌اند. امیدواریم با هدایت اهل فن و حمایت شما، بتوانیم محصولاتی جذاب، فرهنگی و مفید برای شما فراهم کنیم. معرفی و کمک در انتشار این برنامه و محتواهای تولیدی، علاوه بر اجر معنوی و نشاط روحی، انشاءالله شما را در شمار جان‌فدایان مولایمان قرار خواهد داد. به دعای خیر شما و حمایت‌هایتان محتاجیم.\n'
            'با ما در شبکه‌های اجتماعی در ارتباط باشید.\n'
            'اللهم عجل لولیک الفرج',
            textAlign: TextAlign.justify,
            style: TextStyle(fontFamily: 'Vazirmatn', height: 1.8, fontSize: 13.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 16, top: 4),
          actions: [
            SizedBox(
              width: 120,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4226),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                ),
                child: const Text(
                  'بستن',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
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
  final GlobalAudioService _audio = GlobalAudioService.instance;
  bool _dragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    if (_audio.currentFilePath.value != widget.filePath) _audio.play(widget.filePath, widget.title);
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60)), s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${two(d.inHours)}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFF0F2633),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('پخش صوت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2633), Color(0xFF163E52), Color(0xFF0D1E28)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Column(children: [
          const Spacer(),
          Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFFFF8A65), Color(0xFFFF6B4A), Color(0xFFBF360C)], stops: [0.2, 0.7, 1]),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6B4A).withOpacity(.35), blurRadius: 30, spreadRadius: 6)]),
            child: Center(child: Container(width: 190, height: 190, decoration: const BoxDecoration(color: Color(0xFF0F2633), shape: BoxShape.circle),
              child: const Icon(Icons.audiotrack_rounded, size: 80, color: Color(0xFFFF6B4A))))),
          const Spacer(),
          Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(.1))),
            child: Column(children: [Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
              const SizedBox(height: 6), Text('جلسات شب‌های دانشجویی', style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12))])),
          const SizedBox(height: 24),
          ValueListenableBuilder<Duration>(valueListenable: _audio.position, builder: (context, pos, _) => ValueListenableBuilder<Duration>(valueListenable: _audio.duration, builder: (context, dur, _) {
            final max = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
            final value = (_dragging ? _dragValue : pos.inSeconds.toDouble()).clamp(0.0, max).toDouble();
            return Column(children: [SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xFFFF6B4A), inactiveTrackColor: Colors.white.withOpacity(.15), thumbColor: const Color(0xFFFF6B4A), overlayColor: const Color(0x33FF6B4A), trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
              child: Slider(value: value, min: 0, max: max, onChanged: (v) => setState(() { _dragging = true; _dragValue = v; }), onChangeEnd: (v) { _audio.seek(Duration(seconds: v.toInt())); setState(() => _dragging = false); })),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_format(Duration(seconds: value.toInt())), style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12)), Text(_format(dur), style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12))]))]);
          })),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ValueListenableBuilder<double>(valueListenable: _audio.speed, builder: (context, speed, _) => TextButton(style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(.08), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () { const speeds = [1.0, 1.25, 1.5, 1.75, 2.0]; final i = speeds.indexOf(speed); _audio.setSpeed(speeds[(i + 1) % speeds.length]); }, child: Text('${speed}x', style: const TextStyle(color: Color(0xFFFF6B4A), fontWeight: FontWeight.bold)))),
            IconButton(iconSize: 32, icon: const Icon(Icons.replay_10_rounded, color: Colors.white), onPressed: () { final t = _audio.position.value - const Duration(seconds: 10); _audio.seek(t < Duration.zero ? Duration.zero : t); }),
            ValueListenableBuilder<PlayerState>(valueListenable: _audio.playerState, builder: (context, state, _) => IconButton(iconSize: 64, padding: EdgeInsets.zero, icon: Icon(state == PlayerState.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFFF6B4A)), onPressed: _audio.togglePlayPause)),
            IconButton(iconSize: 32, icon: const Icon(Icons.forward_10_rounded, color: Colors.white), onPressed: () { final t = _audio.position.value + const Duration(seconds: 10); final d = _audio.duration.value; _audio.seek(d > Duration.zero && t > d ? d : t); }),
            IconButton(iconSize: 28, icon: Icon(Icons.stop_circle_outlined, color: Colors.white.withOpacity(.6)), onPressed: () { _audio.stop(); Navigator.pop(context); }),
          ]),
          const Spacer(),
        ]))),
      ),
    ),
  );
}


// ==========================================
// صفحه نمایش PDF
// ==========================================
class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  
  int _currentPage = 1;
  int _pageCount = 0;
  bool _isHorizontal = true; // حالت پیش‌فرض: ورق زدن افقی مثل کتاب

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _showJumpToPageDialog() {
    final pageInputController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'رفتن به صفحه',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: pageInputController,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'شماره صفحه (۱ تا $_pageCount)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(pageInputController.text);
                if (page != null && page >= 1 && page <= _pageCount) {
                  _pdfViewerController.jumpToPage(page);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('شماره صفحه نامعتبر است')),
                  );
                }
              },
              child: const Text('برو'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'جستجوی کلمه در متن...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: (query) async {
                  if (query.trim().isNotEmpty) {
                    _searchResult = await _pdfViewerController.searchText(query);
                    setState(() {});
                  }
                },
              )
            : Text(
                widget.title,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (_isSearchOpen) ...[
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'قبلی',
              onPressed: () => _searchResult.previousInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              tooltip: 'بعدی',
              onPressed: () => _searchResult.nextInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearchOpen = false;
                  _searchResult.clear();
                  _searchController.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'جستجو در متن',
              onPressed: () {
                setState(() {
                  _isSearchOpen = true;
                });
              },
            ),
            IconButton(
              icon: Icon(_isHorizontal ? Icons.swap_vert : Icons.swap_horiz),
              tooltip: _isHorizontal ? 'تغییر به اسکرول عمودی' : 'تغییر به ورق‌زدن افقی',
              onPressed: () {
                setState(() {
                  _isHorizontal = !_isHorizontal;
                });
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // نمایشگر اصلی PDF
          SfPdfViewer.file(
            File(widget.filePath),
            controller: _pdfViewerController,
            enableTextSelection: true, // امکان های‌لایت و کپی متن
            pageLayoutMode: _isHorizontal
                ? PdfPageLayoutMode.single
                : PdfPageLayoutMode.continuous,
            scrollDirection: _isHorizontal
                ? PdfScrollDirection.horizontal
                : PdfScrollDirection.vertical,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _pageCount = details.document.pages.count;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
          ),

          // نوار ابزار شیشه‌ای و مدرن در پایین صفحه
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زوم اوت
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white),
                      tooltip: 'کوچک‌نمایی',
                      onPressed: () {
                        _pdfViewerController.zoomLevel =
                            (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                      },
                    ),

                    // شماره صفحه و دکمه پرش به صفحه
                    InkWell(
                      onTap: _pageCount > 0 ? _showJumpToPageDialog : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$_currentPage / $_pageCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // زوم این
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white),
                      tooltip: 'بزرگ‌نمایی',
                      onPressed: () {
                        _pdfViewerController.zoomLevel =
                            (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// صفحه و منطق تست شخصیت‌شناسی MBTI (کامل و مدرن)
// ==========================================

class MbtiQuestion {
  final String title;
  final String optA;
  final String optB;
  final String typeA;
  final String typeB;

  const MbtiQuestion({
    required this.title,
    required this.optA,
    required this.optB,
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
  bool _showResult = false;
  String _calculatedType = '';

  // بانک کامل ۳۲ سوال آزمون
  static const List<MbtiQuestion> questions = [
    // بعد ۱: E یا I
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۱', optA: 'بعد از یک مهمانی شلوغ، احساس سرزندگی می‌کنم', optB: 'بعد از یک مهمانی شلوغ، احساس خستگی می‌کنم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۲', optA: 'ترجیح می‌دهم در گروه فکر کنم و حرف بزنم', optB: 'ترجیح می‌دهم اول تنها فکر کنم، بعد بگویم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۳', optA: 'دوستان زیادی دارم و راحت آشنا می‌شوم', optB: 'دوستان کمی دارم اما روابطم عمیق است', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۴', optA: 'سکوت در جمع برایم ناراحت‌کننده است', optB: 'سکوت در جمع برایم طبیعی و راحت است', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۵', optA: 'وقتی تنها هستم، دنبال کاری برای انجام دادن می‌گردم', optB: 'وقتی تنها هستم، از آن لذت می‌برم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۶', optA: 'در جمع انرژی می‌گیرم', optB: 'در خلوت انرژی می‌گیرم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۷', optA: 'ترجیح می‌دهم با تلفن صحبت کنم', optB: 'ترجیح می‌دهم پیام بدهم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش ۱: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۸', optA: 'اغلب قبل از فکر کردن حرف می‌زنم', optB: 'اغلب قبل از حرف زدن فکر می‌کنم', typeA: 'E', typeB: 'I'),

    // بعد ۲: S یا N
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۹', optA: 'به جزئیات و واقعیت‌های ملموس توجه می‌کنم', optB: 'به الگوها و معناهای پنهان توجه می‌کنم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۰', optA: 'ترجیح می‌دهم دستورالعمل گام‌به‌گام داشته باشم', optB: 'ترجیح می‌دهم کلیت کار را بفهمم و خودم جزئیات را پر کنم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۱', optA: 'به تجربه‌ی عملی بیشتر از نظریه اعتماد دارم', optB: 'ایده‌های جدید و نظریه‌ها برایم جذاب‌اند', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۲', optA: '«واقع‌بین» بودن برایم مهم است', optB: '«خلاق» بودن برایم مهم است', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۳', optA: 'از روش‌های آزموده‌شده استفاده می‌کنم', optB: 'دنبال راه‌های جدید می‌گردم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۴', optA: 'حال حاضر برایم مهم‌تر از آینده است', optB: 'آینده و امکانات برایم جذاب‌تر از حال است', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۵', optA: 'وقتی چیزی می‌خوانم، به کلمات دقیق توجه می‌کنم', optB: 'وقتی چیزی می‌خوانم، دنبال معنای کلی می‌گردم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش ۲: حسی (S) یا شهودی (N) - سوال ۱۶', optA: 'از کارهای دقیق و تکراری خسته نمی‌شوم', optB: 'کارهای تکراری زود خسته‌ام می‌کنند', typeA: 'S', typeB: 'N'),

    // بعد ۳: T یا F
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۱۷', optA: 'در تصمیم‌گیری، منطق و داده برایم اولویت دارد', optB: 'در تصمیم‌گیری، احساسات و ارزش‌ها برایم اولویت دارد', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۱۸', optA: 'انتقاد صادقانه را به تعریف مؤدبانه ترجیح می‌دهم', optB: 'انتقاد، حتی اگر درست باشد، اگر بی‌ملاحظه باشد آزارم می‌دهد', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۱۹', optA: 'در تعارض، دنبال راه‌حل منطقی می‌گردم', optB: 'در تعارض، اول می‌خواهم احساسم شنیده شود', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۲۰', optA: '«عادلانه» بودن برایم مهم‌تر از «مهربانانه» بودن است', optB: '«مهربانانه» بودن برایم مهم‌تر از «عادلانه» بودن است', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۲۱', optA: 'می‌توانم تصمیم سختی بگیرم بدون اینکه احساساتم مانع شود', optB: 'تصمیم‌های سخت که به کسی آسیب می‌زند برایم دشوار است', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۲۲', optA: 'وقتی کسی مشکل دارد، اول راه‌حل پیشنهاد می‌دهم', optB: 'وقتی کسی مشکل دارد، اول گوش می‌دهم و همدلی می‌کنم', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۲۳', optA: 'صداقت را بر مدارا ترجیح می‌دهم', optB: 'مدارا را بر صداقت بی‌پرده ترجیح می‌دهم', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش ۳: تفکری (T) یا احساسی (F) - سوال ۲۴', optA: 'اشتباهات دیگران را تحلیل می‌کنم', optB: 'اشتباهات دیگران را می‌بخشم و نادیده می‌گیرم', typeA: 'T', typeB: 'F'),

    // بعد ۴: J یا P
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۲۵', optA: 'برنامه‌ریزی دقیق دارم و طبق آن پیش می‌روم', optB: 'دوست دارم منعطف باشم و بر اساس شرایط تصمیم بگیرم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۲۶', optA: 'کارها را زودتر از موعد تمام می‌کنم', optB: 'کارها را نزدیک مهلت نهایی انجام می‌دهم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۲۷', optA: 'تغییر برنامه در لحظه آخر آزارم می‌دهد', optB: 'تغییر برنامه در لحظه آخر هیجان‌انگیز است', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۲۸', optA: 'دوست دارم تصمیم‌ها گرفته شوند و کار تمام شود', optB: 'دوست دارم گزینه‌ها باز بمانند', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۲۹', optA: 'فهرست کارها و برنامه روزانه دارم', optB: 'فهرست کارها برایم محدودکننده است', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۳۰', optA: 'محیط نامرتب حواسم را پرت می‌کند', optB: 'می‌توانم در محیط نامرتب هم کار کنم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۳۱', optA: 'ترجیح می‌دهم همه چیز مشخص و قطعی باشد', optB: 'با ابهام و عدم قطعیت راحتم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش ۴: قضاوتی (J) یا ادراکی (P) - سوال ۳۲', optA: 'وقتی کاری نیمه‌تمام است، ذهنم درگیر است', optB: 'می‌توانم چند کار نیمه‌تمام داشته باشم بدون استرس', typeA: 'J', typeB: 'P'),
  ];

  // شرح و نام‌گذاری دقیق تمامی ۱۶ تیپ شخصیتی
  static const Map<String, Map<String, String>> personalityDetails = {
    'INFJ': {
      'title': 'حامی و مشاور معنوی (The Advocate)',
      'desc': 'شما فردی با بصیرت عمیق، آرمان‌گرا و دلسوز هستید. معنای عمیق‌تری در رویدادها و پیوندهای انسانی می‌جویید و مشتاق هدایت جامعه به سوی کمال و اخلاق‌مداری می‌باشید.'
    },
    'INTJ': {
      'title': 'معمار و استراتژیست (The Architect)',
      'desc': 'فکری نظام‌مند، نوآور و دوراندیش دارید. ساختارها و الگوها را عمیقاً تحلیل کرده و همواره در پی طراحی مسیرهای بهینه و تحقق طرح‌های بلندمدت با پشتکار فراوان هستید.'
    },
    'INFP': {
      'title': 'میانجی و سالک آرمان‌گرا (The Mediator)',
      'desc': 'شخصیتی لطیف، متفکر و پایبند به ارزش‌های اصیل انسانی دارید. همواره در جستجوی زیبایی‌های باطنی و حقیقت بوده و با همدلی و آرامش با جهان پیرامون تعامل می‌کنید.'
    },
    'INTP': {
      'title': 'متفکر و پژوهشگر حقیقت (The Logician)',
      'desc': 'عاشق کاوش در نظریه‌ها، کشف قوانین حاکم بر هستی و حل معماهای پیچیده‌اید. صداقت فکری و رسیدن به درکی جامع از پدیده‌ها بزرگ‌ترین انگیزه درونی شماست.'
    },
    'ENFJ': {
      'title': 'راهنما و مربی الهام‌بخش (The Protagonist)',
      'desc': 'رهبری پرجاذبه، دلسوز و آرمان‌خواه هستید. توانایی شگرفی در برانگیختن استعدادهای دیگران و هدایت جمعی به سوی اهداف متعالی و وحدت‌بخش دارید.'
    },
    'ENTJ': {
      'title': 'فرمانده و مدیر راهبردی (The Commander)',
      'desc': 'شخصیتی قاطع، مقتدر و سازمان‌دهنده دارید. با دیدگاهی روشن و تکیه بر ساختارهای مستحکم، چالش‌ها را به فرصت تبدیل کرده و گروه‌ها را به سمت پیروزی رهبری می‌نمایید.'
    },
    'ENFP': {
      'title': 'پیک الهام و مشتاق اندیشه (The Campaigner)',
      'desc': 'پر از شور و شوق، خلاقیت و دیدگاه‌های نوآورانه هستید. روابط پرمعنا با انسان‌ها برقرار می‌کنید و زندگی را عرصه‌ای سرشار از امکان‌ها و امیدهای نو می‌بینید.'
    },
    'ENTP': {
      'title': 'مناظره‌گر و نوآور پویا (The Debater)',
      'desc': 'فکری پویا، چابک و سرشار از شوخ‌طبعی و نبوغ دارید. با به چالش کشیدن باورهای سنتی و ارائه ایده‌های بدیع، مسیرهای ناشناخته و جذاب را پیش پای دیگران می‌گشایید.'
    },
    'ISFJ': {
      'title': 'مدافع و خادم فداکار (The Protector)',
      'desc': 'بسیار صبور، باوفا، خدمت‌گزار و مبادی آداب هستید. با تعهدی بی‌ادعا از سنت‌ها و حریم امن خانواده و اطرافیان محافظت کرده و پایبند به تکالیف خویشید.'
    },
    'ISTJ': {
      'title': 'بازرس و امین وظیفه‌شناس (The Inspector)',
      'desc': 'شخصیتی منظم، واقع‌بین، مسئولیت‌پذیر و استوار دارید. برای انضباط، اصول و وظایف اهمیت بنیادین قائلید و با دقت تمام امور را به سرانجام می‌رسانید.'
    },
    'ESFJ': {
      'title': 'سفیر مهر و حامی جامعه (The Caregiver)',
      'desc': 'کانون گرمی، محبت و هماهنگی در جمع هستید. به نیازهای ملموس دیگران عمیقاً توجه دارید و در برپایی نظم، الفت و صمیمیت اجتماعی نقشی بی‌بدیل ایفا می‌کنید.'
    },
    'ESTJ': {
      'title': 'ناظر و مدیر نظم‌آفرین (The Executive)',
      'desc': 'منظم، واقع‌گرا، صریح و سخت‌کوش هستید. در مدیریت منابع، ساماندهی وظایف اجرایی و برقراری رویه‌های شفاف و قانونی با اقتدار و کارآمدی عمل می‌کنید.'
    },
    'ISFP': {
      'title': 'هنرمند و کاوشگر زیبایی (The Adventurer)',
      'desc': 'روحی لطیف، متواضع و سرشار از درک زیبایی‌ها دارید. بی سر و صدا در پی کسب تجارب اصیل و ارزشمند در زندگی هستید و آرامش و صفای درون را بر هر تعارض و هیاهویی ترجیح می‌دهید.'
    },
    'ISTP': {
      'title': 'صنعتگر و چیره‌دست کاردان (The Virtuoso)',
      'desc': 'فردی عمل‌گرا، تحلیل‌گر، ماهر و خونسرد در بحران‌ها هستید. با ابزارها و سازوکارهای عینی به خوبی ارتباط برقرار می‌کنید و مسائل را با راه‌حل‌های عملی و منطقی رفع می‌نمایید.'
    },
    'ESFP': {
      'title': 'شادی‌آفرین و پیام‌آور سرزندگی (The Entertainer)',
      'desc': 'پر از نشاط، شادابی، ذوق زیستن و بخشش هستید. با حضور خود صفا و تحرک به مجالس می‌بخشید و از لحظه لحظه زندگی و نعمت‌های موجود در آن شکرگزارانه بهره می‌برید.'
    },
    'ESTP': {
      'title': 'کارآفرین و پیشگام باصلابت (The Entrepreneur)',
      'desc': 'شجاع، واقع‌گرا، اهل اقدام صریح و تصمیم‌گیری سریع هستید. از پذیرش چالش‌ها و مواجهه مستقیم با واقعیت‌های متغیر هراسی ندارید و با هوشمندی فرصت‌ها را شکار می‌کنید.'
    },
  };

  void _calculateResult() {
    int countE = 0, countI = 0;
    int countS = 0, countN = 0;
    int countT = 0, countF = 0;
    int countJ = 0, countP = 0;

    for (int i = 0; i < 8; i++) {
      if (_answers[i] == 'E') countE++;
      if (_answers[i] == 'I') countI++;
    }
    for (int i = 8; i < 16; i++) {
      if (_answers[i] == 'S') countS++;
      if (_answers[i] == 'N') countN++;
    }
    for (int i = 16; i < 24; i++) {
      if (_answers[i] == 'T') countT++;
      if (_answers[i] == 'F') countF++;
    }
    for (int i = 24; i < 32; i++) {
      if (_answers[i] == 'J') countJ++;
      if (_answers[i] == 'P') countP++;
    }

    final eOrI = countE >= countI ? 'E' : 'I';
    final sOrN = countS >= countN ? 'S' : 'N';
    final tOrF = countT >= countF ? 'T' : 'F';
    final jOrP = countJ >= countP ? 'J' : 'P';

    setState(() {
      _calculatedType = '$eOrI$sOrN$tOrF$jOrP';
      _showResult = true;
    });
  }

  void _resetQuiz() {
    setState(() {
      _answers.clear();
      _showResult = false;
      _calculatedType = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B4A);
    const secondaryColor = Color(0xFF00ADB5);
    const darkCardColor = Color(0xFF222831);
    const surfaceColor = Color(0xFF2C3440);

    final int answeredCount = _answers.length;
    final double progress = answeredCount / questions.length;

    if (_showResult) {
      final details = personalityDetails[_calculatedType] ?? {
        'title': 'تیپ شخصیتی $_calculatedType',
        'desc': 'شرح این تیپ شخصیتی در دسترس نیست.'
      };

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E222D), Color(0xFF12141A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.12),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          child: const Icon(Icons.psychology_rounded, color: primaryColor, size: 54),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'نتیجه تحلیل شخصیت شما',
                          style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF8E53), Color(0xFFFF6B4A)],
                          ).createShader(bounds),
                          child: Text(
                            _calculatedType,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          details['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1.5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, primaryColor.withOpacity(0.5), Colors.transparent],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          details['desc'] ?? '',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFFE0E0E0)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _resetQuiz,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'آزمون مجدد',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // بخش هدر پیشرفت پاسخ‌دهی
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: darkCardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.quiz_rounded, color: primaryColor, size: 22),
                        SizedBox(width: 8),
                        Text('آزمون شخصیت‌شناسی MBTI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ],
                    ),
                    Text(
                      '$answeredCount از ${questions.length}',
                      style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // لیست ۳۲ سوال با استایل مدرن
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 85),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final selectedAnswer = _answers[index];
                final isAnswered = selectedAnswer != null;

                return Card(
                  elevation: isAnswered ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: isAnswered ? const Color(0xFF262E3B) : surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isAnswered ? primaryColor.withOpacity(0.65) : Colors.white10,
                      width: isAnswered ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isAnswered ? primaryColor : Colors.white24,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isAnswered ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildOptionTile(
                          text: q.optA,
                          value: q.typeA,
                          groupValue: selectedAnswer,
                          onTap: () => setState(() => _answers[index] = q.typeA),
                        ),
                        const SizedBox(height: 8),
                        _buildOptionTile(
                          text: q.optB,
                          value: q.typeB,
                          groupValue: selectedAnswer,
                          onTap: () => setState(() => _answers[index] = q.typeB),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // دکمه شناور پایین برای مشاهده نتیجه
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: darkCardColor,
              boxShadow: [
                BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: answeredCount == questions.length ? primaryColor : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: answeredCount == questions.length ? 5 : 0,
                ),
                onPressed: answeredCount == questions.length ? _calculateResult : null,
                child: Text(
                  answeredCount == questions.length
                      ? 'مشاهده نتیجه تحلیل شخصیت'
                      : 'پاسخ به سوالات (${questions.length - answeredCount} سوال مانده)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String text,
    required String value,
    required String? groupValue,
    required VoidCallback onTap,
  }) {
    final bool isSelected = value == groupValue;
    const primaryColor = Color(0xFFFF6B4A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.18) : Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white12,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? primaryColor : Colors.white38, width: 2),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
