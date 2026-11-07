import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartIrrigationApp());
}

class SmartIrrigationApp extends StatefulWidget {
  const SmartIrrigationApp({super.key});

  @override
  State<SmartIrrigationApp> createState() => _SmartIrrigationAppState();
}

class _SmartIrrigationAppState extends State<SmartIrrigationApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Irrigation System',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F6F3),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF16A34A),
          secondary: Color(0xFF2563EB),
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0A1512),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF34D399),
          secondary: Color(0xFF60A5FA),
          surface: Color(0xFF0F1D18),
        ),
      ),
      home: SplashScreen(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  Timer? _messageTimer;
  Timer? _navTimer;
  int _messageIndex = 0;

  static const List<String> _messages = [
    'Initializing sensors…',
    'Connecting to modules…',
    'Calibrating pumps…',
    'Almost ready…',
  ];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    );
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_textFade);

    _entranceController.forward();

    _messageTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });

    _navTimer = Timer(const Duration(milliseconds: 3000), _goToDashboard);
  }

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => MainDashboardScreen(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _messageTimer?.cancel();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColors = isDark
        ? [const Color(0xFF0A1512), const Color(0xFF0F2E22)]
        : [const Color(0xFF0D8A46), const Color(0xFF16A34A)];
    final logoSurface = isDark ? const Color(0xFF0F1D18) : Colors.white;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Animated logo mark
              SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating dotted spinner ring
                    FadeTransition(
                      opacity: _logoFade,
                      child: _SpinnerRing(
                        animation: _pulseController,
                        size: 168,
                        color: Colors.white,
                      ),
                    ),
                    // Soft pulsing glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = (sin(_pulseController.value * 2 * pi) + 1) / 2;
                        return Container(
                          width: 118 + pulse * 10,
                          height: 118 + pulse * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.10 + pulse * 0.08),
                          ),
                        );
                      },
                    ),
                    // Core logo circle
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: logoSurface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 46,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                              ),
                              Positioned(
                                right: 14,
                                bottom: 14,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB),
                                    border: Border.all(color: logoSurface, width: 2.5),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // App name + tagline
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: const [
                      Text(
                        'Smart Irrigation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Automated care for every drop',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // Cycling status message
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        _messages[_messageIndex],
                        key: ValueKey<int>(_messageIndex),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => LinearProgressIndicator(
                            value: null,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinnerRing extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;

  const _SpinnerRing({
    required this.animation,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: animation.value * 2 * pi,
          child: CustomPaint(
            size: Size(size, size),
            painter: _RingDotsPainter(color: color),
          ),
        );
      },
    );
  }
}

class _RingDotsPainter extends CustomPainter {
  final Color color;
  static const int _dotCount = 10;

  _RingDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    for (int i = 0; i < _dotCount; i++) {
      final angle = (i / _dotCount) * 2 * pi;
      final dx = radius + radius * 0.86 * cos(angle);
      final dy = radius + radius * 0.86 * sin(angle);
      final fraction = i / _dotCount;
      final dotRadius = 1.5 + fraction * 2.8;
      canvas.drawCircle(
        Offset(dx, dy),
        dotRadius,
        Paint()..color = color.withOpacity(0.12 + fraction * 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingDotsPainter oldDelegate) => oldDelegate.color != color;
}

class MainDashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainDashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // State Variables (Offline Dummy Data)
  double soilMoisture = 45.0;
  double temperature = 28.5;
  double humidity = 65.0;
  bool rainStatus = false;
  double waterFlow = 12.5;
  double rainTankLevel = 58.0;
  double mainTankLevel = 74.0;
  bool dryRunError = false;

  bool mainPump = false;
  bool rainPump = false;
  bool manualMode = false;
  double soilThreshold = 30.0;
  bool isConnected = false;
  bool _fieldControlExpanded = true;
  String selectedCropName = 'Tomato';

  // ML prediction
  String irrigationNeed = 'Unknown';
  DatabaseReference get _predictionRef => FirebaseDatabase.instance.ref('prediction');
  StreamSubscription<DatabaseEvent>? _predictionSub;

  // ========================= WEATHER FEATURE VARIABLES =========================
  final TextEditingController cityController = TextEditingController();
  // 🆕 3-day forecast list
  List<String> forecastList = ['Clear', 'Clear', 'Clear'];

  static const List<Map<String, dynamic>> _cropPresets = [
    {'name': 'Tomato', 'emoji': '🍅', 'threshold': 30.0},
    {'name': 'Chili', 'emoji': '🌶️', 'threshold': 25.0},
    {'name': 'Orchid', 'emoji': '🌸', 'threshold': 60.0},
    {'name': 'Lettuce', 'emoji': '🥬', 'threshold': 40.0},
    {'name': 'Carrot', 'emoji': '🥕', 'threshold': 35.0},
    {'name': 'Sunflower', 'emoji': '🌻', 'threshold': 50.0},
    {'name': 'Cactus', 'emoji': '🌵', 'threshold': 20.0},
    {'name': 'Custom...', 'emoji': '✏️', 'threshold': null},
  ];

  Map<String, dynamic> get _selectedCrop =>
      _cropPresets.firstWhere((c) => c['name'] == selectedCropName, orElse: () => _cropPresets.first);

  Timer? _clockTimer;
  final Random _rng = Random();
  DateTime _now = DateTime.now();

  // Watering schedule state
  TimeOfDay morningTime = const TimeOfDay(hour: 7, minute: 0);
  int morningDuration = 5;
  bool morningEnabled = false;

  TimeOfDay eveningTime = const TimeOfDay(hour: 17, minute: 0);
  int eveningDuration = 5;
  bool eveningEnabled = false;

  static const List<int> _durationOptions = [1, 3, 5, 10, 15, 20, 30];

  // Delta indicators
  double soilMoistureDelta = 0;
  double temperatureDelta = 0;
  double humidityDelta = 0;
  double waterFlowDelta = 0;

  // Water consumption
  double totalLitersToday = 12.0;
  double rainPumpLiters = 0.1;
  int rainPumpRuntimeSec = 70;
  double mainPumpLiters = 0.0;
  int mainPumpRuntimeSec = 0;
  final String activeCrop = 'Tomato';
  final double activeCropPercent = 30;
  final List<_SensorPoint> sensorHistory = [];
  final List<_PumpLogEntry> pumpLog = [];

  // Notifications
  final List<_AppNotification> _notifications = [];
  int _unreadCount = 0;

  // Hysteresis flags
  bool _mainTankLowNotified = false;
  bool _mainTankFullNotified = false;
  bool _rainTankLowNotified = false;
  bool _rainTankFullNotified = false;
  bool _rainActiveNotified = false;

  static const double _mainTankLowThreshold = 20.0;
  static const double _mainTankLowResetThreshold = 30.0;
  static const double _tankFullThreshold = 90.0;
  static const double _tankFullResetThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _seedPumpLog();
    _seedSensorHistory();
    _connectFirebase();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _seedPumpLog() {
    final base = DateTime.now();
    pumpLog.addAll([
      _PumpLogEntry(pump: 'Rain pump', durationSec: 50, liters: 2.9, time: base.subtract(const Duration(minutes: 0))),
      _PumpLogEntry(pump: 'Rain pump', durationSec: 45, liters: 2.6, time: base.subtract(const Duration(minutes: 1))),
      _PumpLogEntry(pump: 'Rain pump', durationSec: 40, liters: 2.3, time: base.subtract(const Duration(minutes: 1, seconds: 30))),
      _PumpLogEntry(pump: 'Rain pump', durationSec: 35, liters: 2.0, time: base.subtract(const Duration(minutes: 2))),
      _PumpLogEntry(pump: 'Rain pump', durationSec: 30, liters: 1.8, time: base.subtract(const Duration(minutes: 2, seconds: 30))),
    ]);
  }

  void _seedSensorHistory() {
    for (int i = 0; i < 14; i++) {
      sensorHistory.add(_SensorPoint(
        time: DateTime.now().subtract(Duration(seconds: (13 - i) * 20)),
        temp: _fluctuate(temperature, 3, 20, 38),
        humidity: _fluctuate(humidity, 6, 30, 90),
        soil: _fluctuate(soilMoisture, 6, 10, 90),
      ));
    }
  }

  // Firebase references
  DatabaseReference get _sensorRef => FirebaseDatabase.instance.ref('sensorData');
  DatabaseReference get _controlsRef => FirebaseDatabase.instance.ref('controls');

  StreamSubscription<DatabaseEvent>? _sensorSub;
  StreamSubscription<DatabaseEvent>? _controlsSub;
  StreamSubscription<DatabaseEvent>? _connectionSub;
  Timer? _bookkeepingTimer;

  DateTime? _rainPumpStartTime;
  DateTime? _mainPumpStartTime;

  double _asDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return fallback;
  }

  void _connectFirebase() {
    _connectionSub = FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value == true;
      if (mounted) setState(() => isConnected = connected);
    });

    // ==================== UPDATED SENSOR LISTENER ====================
    _sensorSub = _sensorRef.onValue.listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);

      final newSoil = _asDouble(map['soilMoisture'], soilMoisture);
      final newTemp = _asDouble(map['temperature'], temperature);
      final newHumidity = _asDouble(map['humidity'], humidity);
      final newFlow = _asDouble(map['flowRate'], waterFlow);
      final newTotalLiters = _asDouble(map['totalWaterLiters'], totalLitersToday);
      final newMainTank = _asDouble(map['mainTankLevel'], mainTankLevel);
      final newRainTank = _asDouble(map['rainTankLevel'], rainTankLevel);
      final newRainStatus = map['isRaining'] == true || map['isRaining'] == 1;
      final newDryRunError = map['dryRunError'] == true;

      // ESP32 Live Pump Status (only for Auto mode)
      final newMainPumpStatus = map['mainPumpStatus'] == true;
      final newRainPumpStatus = map['rainPumpStatus'] == true;

      bool mainTankJustLow = false;
      bool mainTankJustFull = false;
      bool rainTankJustLow = false;
      bool rainTankJustFull = false;
      bool rainJustStarted = false;

      setState(() {
        soilMoistureDelta = newSoil - soilMoisture;
        temperatureDelta = newTemp - temperature;
        humidityDelta = newHumidity - humidity;
        waterFlowDelta = newFlow - waterFlow;

        soilMoisture = newSoil;
        temperature = newTemp;
        humidity = newHumidity;
        waterFlow = newFlow;
        totalLitersToday = newTotalLiters;
        mainTankLevel = newMainTank;
        rainTankLevel = newRainTank;
        dryRunError = newDryRunError;

        // Auto mode: update pump status from ESP32
        if (!manualMode) {
          mainPump = newMainPumpStatus;
          rainPump = newRainPumpStatus;
        }

        if (newRainStatus && !rainStatus && !_rainActiveNotified) {
          _rainActiveNotified = true;
          rainJustStarted = true;
        } else if (!newRainStatus) {
          _rainActiveNotified = false;
        }
        rainStatus = newRainStatus;

        if (mainTankLevel < _mainTankLowThreshold && !_mainTankLowNotified) {
          _mainTankLowNotified = true;
          mainTankJustLow = true;
        } else if (mainTankLevel >= _mainTankLowResetThreshold) {
          _mainTankLowNotified = false;
        }

        if (mainTankLevel >= _tankFullThreshold && !_mainTankFullNotified) {
          _mainTankFullNotified = true;
          mainTankJustFull = true;
        } else if (mainTankLevel <= _tankFullResetThreshold) {
          _mainTankFullNotified = false;
        }

        if (rainTankLevel < _mainTankLowThreshold && !_rainTankLowNotified) {
          _rainTankLowNotified = true;
          rainTankJustLow = true;
        } else if (rainTankLevel >= _mainTankLowResetThreshold) {
          _rainTankLowNotified = false;
        }

        if (rainTankLevel >= _tankFullThreshold && !_rainTankFullNotified) {
          _rainTankFullNotified = true;
          rainTankJustFull = true;
        } else if (rainTankLevel <= _tankFullResetThreshold) {
          _rainTankFullNotified = false;
        }

        sensorHistory.add(_SensorPoint(time: DateTime.now(), temp: newTemp, humidity: newHumidity, soil: newSoil));
        if (sensorHistory.length > 16) {
          sensorHistory.removeAt(0);
        }
      });

      if (rainJustStarted) {
        _notify(
          title: 'Rain detected',
          message: 'It has started raining — rain sensor is active.',
          icon: Icons.grain_rounded,
          color: const Color(0xFF2563EB),
        );
      }
      if (mainTankJustLow) {
        _notify(
          title: 'Main tank water low',
          message: 'Main tank is at ${mainTankLevel.toStringAsFixed(0)}% — refill soon.',
          icon: Icons.storage_rounded,
          color: const Color(0xFFDC2626),
        );
      }
      if (mainTankJustFull) {
        _notify(
          title: 'Main tank full',
          message: 'Main tank is at ${mainTankLevel.toStringAsFixed(0)}% — tank is full.',
          icon: Icons.storage_rounded,
          color: const Color(0xFF16A34A),
        );
      }
      if (rainTankJustLow) {
        _notify(
          title: 'Rain tank water low',
          message: 'Rain tank is at ${rainTankLevel.toStringAsFixed(0)}% — level is low.',
          icon: Icons.cloud_rounded,
          color: const Color(0xFFDC2626),
        );
      }
      if (rainTankJustFull) {
        _notify(
          title: 'Rain tank full',
          message: 'Rain tank is at ${rainTankLevel.toStringAsFixed(0)}% — tank is full.',
          icon: Icons.cloud_rounded,
          color: const Color(0xFF16A34A),
        );
      }
    });
    // ==================== END UPDATED SENSOR LISTENER ====================

    // ==================== UPDATED 3-DAY WEATHER FORECAST LISTENER ====================
    _sensorRef.child('weatherForecast').onValue.listen((event) {
      final forecast = event.snapshot.value as String?;
      if (forecast != null && mounted) {
        // Split by comma to get up to 3 values
        final parts = forecast.split(',');
        if (parts.length >= 3) {
          setState(() {
            forecastList = parts.take(3).map((e) => e.trim()).toList();
          });
        } else {
          // If less than 3, repeat the single value or fill with 'Clear'
          setState(() {
            final single = forecast.trim();
            forecastList = List.filled(3, single);
          });
        }
      }
    });
    // ==================== END 3-DAY WEATHER FORECAST LISTENER ====================

    _controlsSub = _controlsRef.onValue.listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);

      final newMainPump = map['mainPump'] == true;
      final newRainPump = map['rainPump'] == true;
      final mainJustOn = newMainPump && !mainPump;
      final rainJustOn = newRainPump && !rainPump;
      final mainJustOff = !newMainPump && mainPump;
      final rainJustOff = !newRainPump && rainPump;

      if (mainJustOn) _mainPumpStartTime = DateTime.now();
      if (rainJustOn) _rainPumpStartTime = DateTime.now();

      setState(() {
        mainPump = newMainPump;
        rainPump = newRainPump;
        manualMode = map['manualMode'] == true;
        soilThreshold = _asDouble(map['soilThreshold'], soilThreshold);

        if (mainJustOff && _mainPumpStartTime != null) {
          final dur = DateTime.now().difference(_mainPumpStartTime!).inSeconds;
          final liters = waterFlow * (dur / 60);
          pumpLog.insert(0, _PumpLogEntry(pump: 'Main pump', durationSec: dur, liters: liters, time: DateTime.now()));
          if (pumpLog.length > 30) pumpLog.removeLast();
        }
        if (rainJustOff && _rainPumpStartTime != null) {
          final dur = DateTime.now().difference(_rainPumpStartTime!).inSeconds;
          final liters = waterFlow * (dur / 60);
          pumpLog.insert(0, _PumpLogEntry(pump: 'Rain pump', durationSec: dur, liters: liters, time: DateTime.now()));
          if (pumpLog.length > 30) pumpLog.removeLast();
        }
      });

      if (mainJustOn) {
        _notify(
          title: 'Main pump ON (Auto)',
          message: 'Main water pump has been turned on by the system.',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF2563EB),
        );
      }
      if (rainJustOn) {
        _notify(
          title: 'Rain pump ON (Auto)',
          message: 'Rain water pump has been turned on by the system.',
          icon: Icons.eco_rounded,
          color: const Color(0xFF16A34A),
        );
      }
    });

    // ==================== CITY NAME LISTENER ====================
    _controlsRef.child('cityName').onValue.listen((event) {
      final city = event.snapshot.value as String?;
      if (city != null && mounted) {
        cityController.text = city;
      }
    });
    // ==================== END CITY NAME LISTENER ====================

    _predictionSub = _predictionRef.onValue.listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);
      setState(() {
        irrigationNeed = map['irrigationNeed'] ?? 'Unknown';
      });
    });

    _bookkeepingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        if (rainPump) {
          rainPumpRuntimeSec += 3;
          rainPumpLiters += waterFlow * (3 / 60);
        }
        if (mainPump) {
          mainPumpRuntimeSec += 3;
          mainPumpLiters += waterFlow * (3 / 60);
        }
      });
    });
  }

  void _notify({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final notif = _AppNotification(
      title: title,
      message: message,
      icon: icon,
      color: color,
      time: DateTime.now(),
    );
    setState(() {
      _notifications.insert(0, notif);
      if (_notifications.length > 30) _notifications.removeLast();
      _unreadCount++;
    });
    _showToast(notif);
  }

  void _showToast(_AppNotification notif) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastBanner(
        notification: notif,
        onDismiss: () => entry.remove(),
      ),
    );
    overlayState.insert(entry);
  }

  // ============ UPDATED CONTROL METHODS (with immediate local update and manual notifications) ============
  void _setMainPump(bool val) {
    setState(() => mainPump = val);
    _controlsRef.child('mainPump').set(val);
    
    // 🔔 Manual toggle notification (ON / OFF)
    if (val) {
      _notify(
        title: 'Main pump ON',
        message: 'Main water pump has been turned on manually.',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF2563EB),
      );
    } else {
      _notify(
        title: 'Main pump OFF',
        message: 'Main water pump has been turned off manually.',
        icon: Icons.water_drop_rounded,
        color: Colors.grey,
      );
    }
  }

  void _setRainPump(bool val) {
    setState(() => rainPump = val);
    _controlsRef.child('rainPump').set(val);
    
    // 🔔 Manual toggle notification (ON / OFF)
    if (val) {
      _notify(
        title: 'Rain pump ON',
        message: 'Rain water pump has been turned on manually.',
        icon: Icons.eco_rounded,
        color: const Color(0xFF16A34A),
      );
    } else {
      _notify(
        title: 'Rain pump OFF',
        message: 'Rain water pump has been turned off manually.',
        icon: Icons.eco_rounded,
        color: Colors.grey,
      );
    }
  }

  void _setManualMode(bool val) {
    setState(() => manualMode = val);
    _controlsRef.child('manualMode').set(val);
    if (!val) {
      setState(() {
        mainPump = false;
        rainPump = false;
      });
      _controlsRef.child('mainPump').set(false);
      _controlsRef.child('rainPump').set(false);
    }
  }

  void _setSoilThreshold(double val) {
    _controlsRef.child('soilThreshold').set(val);
  }

  void _resetDryRun() {
    _controlsRef.child('resetDryRun').set(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dry-run reset signal sent to ESP32'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCropPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ..._cropPresets.map((crop) {
                  final selected = crop['name'] == selectedCropName;
                  final threshold = crop['threshold'] as double?;
                  return InkWell(
                    onTap: () {
                      setState(() => selectedCropName = crop['name'] as String);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Row(
                        children: [
                          Text(crop['emoji'] as String, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              threshold != null
                                  ? '${crop['name']} — ${threshold.toStringAsFixed(0)}%'
                                  : crop['name'] as String,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Icon(
                            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyCropThreshold(double threshold) {
    setState(() => soilThreshold = threshold);
    _setSoilThreshold(threshold);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Threshold set to ${threshold.toStringAsFixed(0)}% for $selectedCropName'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCropPresetCard(Color primaryColor, bool isDark) {
    final crop = _selectedCrop;
    final threshold = crop['threshold'] as double?;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.4);

    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Crop preset',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'PLANT TYPE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _openCropPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(crop['emoji'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      threshold != null
                          ? '${crop['name']} — ${threshold.toStringAsFixed(0)}%'
                          : crop['name'] as String,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (threshold != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_rounded, size: 15, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Threshold: ${threshold.toStringAsFixed(0)} %',
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _applyCropThreshold(threshold),
                icon: const Icon(Icons.check_circle_rounded, size: 17),
                label: const Text('Apply to ESP32'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Use the slider above to set a custom threshold.',
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openNotificationCenter() {
    setState(() => _unreadCount = 0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.notifications_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              if (_notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 22),
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: n.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(n.icon, color: n.color, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(
                                  n.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatClock(n.time),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _resetTodayWater() {
    _sensorRef.child('totalLiters').set(0);
    setState(() {
      totalLitersToday = 0;
      rainPumpLiters = 0;
      mainPumpLiters = 0;
      rainPumpRuntimeSec = 0;
      mainPumpRuntimeSec = 0;
      pumpLog.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Today\'s water usage reset'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m}m ${s}s';
  }

  String _formatClock(DateTime dt) {
    final hour24 = dt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  double _fluctuate(double current, double maxDelta, double min, double max) {
    final delta = (_rng.nextDouble() * 2 - 1) * maxDelta;
    final next = current + delta;
    return next.clamp(min, max);
  }

  String _formatTime(DateTime dt) {
    final hour24 = dt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute:$second $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _bookkeepingTimer?.cancel();
    _sensorSub?.cancel();
    _controlsSub?.cancel();
    _connectionSub?.cancel();
    _predictionSub?.cancel();
    cityController.dispose(); // 🆕 Dispose city controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF14532D), const Color(0xFF064E3B)]
                  : [const Color(0xFF66BB6A), const Color(0xFF43A047)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Field Control',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'ESP32 · Firebase · DHT22 · HC-SR04 · Plot 01',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(isConnected: isConnected),
                  const SizedBox(width: 4),
                  _NotificationBell(
                    count: _unreadCount,
                    onTap: _openNotificationCenter,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isDarkMode
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      color: Colors.white,
                    ),
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _currentIndex == 0
            ? _buildHomePage(primaryColor, secondaryColor, isDark)
            : _currentIndex == 1
                ? _buildWaterPage(primaryColor, isDark)
                : _buildControlPage(primaryColor, isDark),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: _currentIndex == 0,
                  color: primaryColor,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.water_drop_rounded,
                  label: 'Water',
                  selected: _currentIndex == 1,
                  color: primaryColor,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: _currentIndex == 2,
                  color: primaryColor,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- HOME TAB --------------------
  Widget _buildFieldControlHeader(bool isDark) {
    final activePump = mainPump ? 'Main Pump' : (rainPump ? 'Rain Pump' : 'None');
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _fieldControlExpanded = !_fieldControlExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Icon(Icons.menu_rounded, size: 20, color: subtitleColor),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => ClipRect(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
            ),
            child: !_fieldControlExpanded
                ? const SizedBox(key: ValueKey('field_control_collapsed'), width: double.infinity)
                : Column(
                  key: const ValueKey('field_control_expanded'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _pillButton(
                            icon: widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                            label: widget.isDarkMode ? 'Light' : 'Dark',
                            onTap: widget.onToggleTheme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _pillStatus(
                            dotColor: isConnected ? const Color(0xFF16A34A) : Colors.grey,
                            label: isConnected ? 'Live data' : 'Demo data',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _pillButton(
                            icon: manualMode ? Icons.pan_tool_alt_rounded : Icons.power_settings_new_rounded,
                            label: manualMode ? 'Manual' : 'Auto mode',
                            onTap: () => _setManualMode(!manualMode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            icon: Icons.wifi_rounded,
                            iconColor: isConnected ? const Color(0xFF16A34A) : Colors.grey,
                            label: 'ESP32',
                            value: isConnected ? 'Connected' : 'Simulated',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(
                            icon: Icons.settings_rounded,
                            iconColor: const Color(0xFF2563EB),
                            label: 'MODE',
                            value: manualMode ? 'Manual' : 'Auto',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            icon: Icons.water_drop_rounded,
                            iconColor: const Color(0xFF9333EA),
                            label: 'ACTIVE PUMP',
                            value: activePump,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(
                            icon: rainStatus ? Icons.grain_rounded : Icons.wb_sunny_outlined,
                            iconColor: const Color(0xFFF59E0B),
                            label: 'WEATHER',
                            value: '${temperature.toStringAsFixed(0)}°C',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            icon: Icons.psychology_rounded,
                            iconColor: const Color(0xFF9333EA),
                            label: 'ML PREDICTION',
                            value: irrigationNeed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _pillButton({required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillStatus({required Color dotColor, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== UPDATED 3-DAY FORECAST CARD ====================
  Widget _buildForecastCard() {
    final today = DateTime.now();
    final days = [
      'Today',
      'Tomorrow',
      _formatShortDate(today.add(const Duration(days: 2))),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grain_rounded, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                '3-Day Weather Forecast',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final condition = forecastList[index];
              final isRain = condition.contains('Rain');
              return Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRain
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isRain ? Icons.grain_rounded : Icons.wb_sunny_rounded,
                      color: isRain ? Colors.blue.shade700 : Colors.orange.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    condition.replaceAll('3D', '').trim(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isRain ? Colors.blue.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Helper to format date as "Mon 12"
  String _formatShortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildHomePage(Color primaryColor, Color secondaryColor, bool isDark) {
    final pumpActive = mainPump || rainPump;
    return SingleChildScrollView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dry-run emergency banner
          if (dryRunError) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🚨 EMERGENCY: Dry-Run Detected!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Pumps have been turned OFF. Please reset.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _resetDryRun,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],

          _buildFieldControlHeader(isDark),
          const SizedBox(height: 20),

          // Main Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: pumpActive
                    ? [const Color(0xFF16A34A), const Color(0xFF0D8A46)]
                    : [const Color(0xFF64748B), const Color(0xFF475569)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (pumpActive ? primaryColor : Colors.grey)
                      .withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pumpActive ? Icons.water_drop_rounded : Icons.power_settings_new_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pumpActive ? 'Water Pump is ON' : 'Water Pump is OFF',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            manualMode ? Icons.pan_tool_alt_rounded : Icons.auto_mode_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            manualMode ? 'Manual Control' : 'Automatic Logic',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Live Clock
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 10),
                Text(
                  _formatTime(_now),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(_now),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🆕 3-Day Forecast Card
          _buildForecastCard(),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Live Sensor Readings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
              ),
            ),
          ),

          // Sensors Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.68,
            children: [
              _buildGaugeCard(
                title: 'Soil Moisture',
                icon: Icons.grass_rounded,
                color: const Color(0xFF16A34A),
                value: soilMoisture.toStringAsFixed(0),
                unitLabel: '% MOIST',
                progress: soilMoisture / 100,
                subtitle: 'threshold ${soilThreshold.toStringAsFixed(0)}%',
                delta: soilMoistureDelta,
                deltaSuffix: '',
                isDark: isDark,
              ),
              _buildGaugeCard(
                title: 'Temperature',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFF97316),
                value: temperature.toStringAsFixed(1),
                unitLabel: '°C',
                progress: (temperature / 50).clamp(0, 1),
                subtitle: 'GPIO 4 · DHT22',
                delta: temperatureDelta,
                deltaSuffix: '',
                isDark: isDark,
              ),
              _buildGaugeCard(
                title: 'Humidity',
                icon: Icons.water_rounded,
                color: const Color(0xFF2563EB),
                value: humidity.toStringAsFixed(0),
                unitLabel: '% RH',
                progress: humidity / 100,
                subtitle: 'GPIO 4 · DHT22',
                delta: humidityDelta,
                deltaSuffix: '',
                isDark: isDark,
              ),
              _buildRainCard(isDark),
              // ---- WATER FLOW CARD WITH SMALL ANIMATED WAVE LINE ----
              _FlowWaveCard(
                flowValue: waterFlow,
                unitLabel: 'L/m',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.dns_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Tank Levels',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TankLevelBox(
                  title: 'Rain Tank',
                  level: rainTankLevel,
                  icon: Icons.cloud_rounded,
                  colors: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  pinInfo: 'TRIG 32 / ECHO 33',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TankLevelBox(
                  title: 'Main Tank',
                  level: mainTankLevel,
                  icon: Icons.storage_rounded,
                  colors: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
                  pinInfo: 'TRIG 18 / ECHO 19',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- WATER TAB --------------------
  Widget _buildWaterPage(Color primaryColor, bool isDark) {
    final rainPct = totalLitersToday <= 0
        ? 0.0
        : (rainPumpLiters / (rainPumpLiters + mainPumpLiters == 0 ? 1 : rainPumpLiters + mainPumpLiters));
    final mainPct = 1 - rainPct;
    final totalRuntime = rainPumpRuntimeSec + mainPumpRuntimeSec;
    final estPowerWh = (totalRuntime / 3600) * 30;
    final avgSession = pumpLog.isEmpty
        ? 0
        : (pumpLog.fold<int>(0, (sum, e) => sum + e.durationSec) / pumpLog.length).round();

    return SingleChildScrollView(
      key: const ValueKey('water'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Water consumption',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                'today',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total used card
          _sectionCard(
            isDark,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Total used',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: [
                      TextSpan(text: totalLitersToday.toStringAsFixed(1)),
                      const TextSpan(
                        text: ' L',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'V11 · totalLiters from ESP32',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _resetTodayWater,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Reset today'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                    side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildPumpUsageCard(
            title: 'Rain pump',
            icon: Icons.eco_rounded,
            color: const Color(0xFF16A34A),
            liters: rainPumpLiters,
            runtimeLabel: _formatDuration(rainPumpRuntimeSec),
            progress: rainPumpLiters == 0 && mainPumpLiters == 0 ? 1.0 : rainPct,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          _buildPumpUsageCard(
            title: 'Main pump',
            icon: Icons.crop_square_rounded,
            color: const Color(0xFFF97316),
            liters: mainPumpLiters,
            runtimeLabel: _formatDuration(mainPumpRuntimeSec),
            progress: rainPumpLiters == 0 && mainPumpLiters == 0 ? 0.0 : mainPct,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Live sensor trend',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _sectionCard(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _legendDot(const Color(0xFFF97316), 'Temp °C'),
                    const SizedBox(width: 14),
                    _legendDot(const Color(0xFF2563EB), 'Humidity %'),
                    const SizedBox(width: 14),
                    _legendDot(const Color(0xFF16A34A), 'Soil %'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: _SensorTrendChart(
                    points: sensorHistory,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text(
                'Pump runtime log',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _sectionCard(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _statBox('TOTAL RUNTIME', _formatDuration(totalRuntime))),
                    Expanded(child: _statBox('SESSIONS', '${pumpLog.length}')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _statBox('EST. POWER', '${estPowerWh.toStringAsFixed(0)} Wh')),
                    Expanded(child: _statBox('AVG SESSION', '${avgSession}s')),
                  ],
                ),
                const SizedBox(height: 8),
                if (pumpLog.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'No pump activity yet today',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      const Divider(height: 24),
                      ...pumpLog.take(8).map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 66,
                                  child: Text(
                                    _formatClock(entry.time),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.pump,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  _formatDuration(entry.durationSec),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: 46,
                                  child: Text(
                                    '${entry.liters.toStringAsFixed(1)} L',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Icon(Icons.water_drop_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                "Today's water use",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _sectionCard(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${totalLitersToday.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 14),
                _sourceBar('Rain', rainPct, const Color(0xFF16A34A)),
                const SizedBox(height: 10),
                _sourceBar('Main', mainPct, const Color(0xFFF97316)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Active crop: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      activeCrop,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      ' · ${activeCropPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _sourceBar(String label, double fraction, Color color) {
    final pct = (fraction * 100).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: fraction.clamp(0, 1)),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, val, _) => LinearProgressIndicator(
                    value: val,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 36,
              child: Text(
                '${pct.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPumpUsageCard({
    required String title,
    required IconData icon,
    required Color color,
    required double liters,
    required String runtimeLabel,
    required double progress,
    required bool isDark,
  }) {
    return _sectionCard(
      isDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              children: [
                TextSpan(text: liters.toStringAsFixed(1)),
                const TextSpan(
                  text: ' L',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Runtime: $runtimeLabel',
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: progress.clamp(0, 1)),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, val, _) => LinearProgressIndicator(
                      value: val,
                      minHeight: 6,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- CONTROL TAB --------------------
  // ==================== CITY SETTINGS CARD ====================
  Widget _buildCitySettingsCard(Color primaryColor, bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Weather Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cityController,
            decoration: InputDecoration(
              hintText: 'Enter city name (e.g. Matara)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade50,
            ),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final city = cityController.text.trim();
                    if (city.isNotEmpty) {
                      _controlsRef.child('cityName').set(city);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ City saved: $city'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 17),
                  label: const Text('Save City'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Current: ${cityController.text.isNotEmpty ? cityController.text : 'Not set (Matara)'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPage(Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('controls'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            isDark,
            child: Column(
              children: [
                _styledSwitchTile(
                  title: 'Manual Mode',
                  subtitle: 'Turn on to control pumps manually',
                  icon: Icons.pan_tool_alt_rounded,
                  value: manualMode,
                  color: primaryColor,
                  onChanged: _setManualMode,
                ),
                const Divider(height: 28),
                _styledSwitchTile(
                  title: 'Main Water Pump',
                  subtitle: manualMode ? 'Tap to toggle' : 'Enable manual mode first',
                  icon: Icons.water_drop_rounded,
                  value: mainPump,
                  color: const Color(0xFF2563EB),
                  onChanged: manualMode ? _setMainPump : null,
                ),
                const SizedBox(height: 12),
                _styledSwitchTile(
                  title: 'Rain Water Pump',
                  subtitle: manualMode ? 'Tap to toggle' : 'Enable manual mode first',
                  icon: Icons.cloudy_snowing,
                  value: rainPump,
                  color: const Color(0xFF9333EA),
                  onChanged: manualMode ? _setRainPump : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Auto Watering Threshold',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${soilThreshold.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryColor,
                    thumbColor: primaryColor,
                    overlayColor: primaryColor.withOpacity(0.2),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: soilThreshold,
                    min: 10,
                    max: 80,
                    divisions: 7,
                    label: '${soilThreshold.round()}%',
                    onChanged: (val) {
                      setState(() => soilThreshold = val);
                    },
                    onChangeEnd: _setSoilThreshold,
                  ),
                ),
                Text(
                  'Pump activates automatically when soil moisture drops below this level.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildCropPresetCard(primaryColor, isDark),

          // ==================== CITY SETTINGS CARD ====================
          const SizedBox(height: 16),
          _buildCitySettingsCard(primaryColor, isDark),

          const SizedBox(height: 24),
          _buildWateringSchedule(primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildWateringSchedule(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Watering Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveSchedule,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildScheduleSession(
            title: 'Morning session',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFF59E0B),
            time: morningTime,
            duration: morningDuration,
            enabled: morningEnabled,
            onTimeChanged: (t) => setState(() => morningTime = t),
            onDurationChanged: (d) => setState(() => morningDuration = d),
            onEnabledChanged: (v) => setState(() => morningEnabled = v),
          ),
          const SizedBox(height: 16),
          _buildScheduleSession(
            title: 'Evening session',
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF9333EA),
            time: eveningTime,
            duration: eveningDuration,
            enabled: eveningEnabled,
            onTimeChanged: (t) => setState(() => eveningTime = t),
            onDurationChanged: (d) => setState(() => eveningDuration = d),
            onEnabledChanged: (v) => setState(() => eveningEnabled = v),
          ),
        ],
      ),
    );
  }

  void _saveSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Watering schedule saved'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickTime(TimeOfDay initial, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onPicked(picked);
  }

  Widget _buildScheduleSession({
    required String title,
    required IconData icon,
    required Color iconColor,
    required TimeOfDay time,
    required int duration,
    required bool enabled,
    required ValueChanged<TimeOfDay> onTimeChanged,
    required ValueChanged<int> onDurationChanged,
    required ValueChanged<bool> onEnabledChanged,
  }) {
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.4);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? iconColor.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? iconColor.withOpacity(0.3) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (enabled ? const Color(0xFF16A34A) : Colors.grey)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  enabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: enabled ? const Color(0xFF16A34A) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Time selector
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickTime(time, onTimeChanged),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTimeOfDay(time),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Duration selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: duration,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                items: _durationOptions
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d min')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onDurationChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                  activeColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  enabled ? 'Enabled — will run at scheduled time' : 'Disabled — enable to schedule',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _styledSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color color,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (enabled ? color : Colors.grey).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: enabled ? color : Colors.grey, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: color),
      ],
    );
  }

  // ---------- GAUGE CARD ----------
  Widget _buildGaugeCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String unitLabel,
    required double progress,
    required String subtitle,
    required double delta,
    required String deltaSuffix,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: progress.clamp(0, 1)),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedVal, _) => SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: animatedVal,
                      strokeWidth: 6,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      unitLabel,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          _buildDeltaPill(delta, deltaSuffix),
        ],
      ),
    );
  }

  Widget _buildDeltaPill(double delta, String suffix) {
    final isFlat = delta.abs() < 0.05;
    final isUp = delta > 0;
    final color = isFlat
        ? Colors.grey
        : (isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626));
    final arrow = isFlat ? '—' : (isUp ? '↗' : '↘');
    final text = isFlat ? '— +0.0$suffix' : '$arrow ${delta.toStringAsFixed(1)}$suffix';

    if (isFlat) {
      return Text(
        text,
        style: TextStyle(fontSize: 11, color: color.withOpacity(0.6), fontWeight: FontWeight.w500),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // Rain card
  Widget _buildRainCard(bool isDark) {
    final color = const Color(0xFF9333EA);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rainStatus ? Icons.grain_rounded : Icons.wb_sunny_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: Center(
              child: Text(
                rainStatus ? 'Raining' : 'Dry',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RAIN SENSOR',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rainStatus ? color : const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                rainStatus ? 'active' : 'idle',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== WATER FLOW CARD WITH SMALL ANIMATED WAVE LINE ====================
class _FlowWaveCard extends StatefulWidget {
  final double flowValue;
  final String unitLabel;
  final bool isDark;

  const _FlowWaveCard({
    required this.flowValue,
    required this.unitLabel,
    required this.isDark,
  });

  @override
  State<_FlowWaveCard> createState() => _FlowWaveCardState();
}

class _FlowWaveCardState extends State<_FlowWaveCard> with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves_rounded, size: 30, color: color),
          const SizedBox(height: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.55), blurRadius: 8, spreadRadius: 1.5),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.flowValue.toStringAsFixed(1),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 3),
              Text(
                widget.unitLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ---- SMALL ANIMATED WAVE LINE ----
          SizedBox(
            height: 20,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SmallWavePainter(
                    phase: _waveController.value * 2 * pi,
                    color: color,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'WATER FLOW',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _SmallWavePainter extends CustomPainter {
  final double phase;
  final Color color;

  _SmallWavePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const amplitude = 4.0;
    final path = Path();
    path.moveTo(0, size.height / 2);

    const step = 2.0;
    for (double x = 0; x <= size.width; x += step) {
      final y = size.height / 2 +
          sin((x / size.width * 2 * pi) + phase) * amplitude;
      path.lineTo(x, y);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SmallWavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

// ==================== SUPPORTING WIDGETS ====================
class _StatusPill extends StatelessWidget {
  final bool isConnected;
  const _StatusPill({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Live' : 'Demo',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AppNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime time;

  _AppNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
  });
}

class _ToastBanner extends StatefulWidget {
  final _AppNotification notification;
  final VoidCallback onDismiss;

  const _ToastBanner({required this.notification, required this.onDismiss});

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _autoDismiss = Timer(const Duration(milliseconds: 3200), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    _autoDismiss?.cancel();
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: n.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(n.icon, color: n.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _SensorPoint {
  final DateTime time;
  final double temp;
  final double humidity;
  final double soil;

  _SensorPoint({
    required this.time,
    required this.temp,
    required this.humidity,
    required this.soil,
  });
}

class _PumpLogEntry {
  final String pump;
  final int durationSec;
  final double liters;
  final DateTime time;

  _PumpLogEntry({
    required this.pump,
    required this.durationSec,
    required this.liters,
    required this.time,
  });
}

class _SensorTrendChart extends StatefulWidget {
  final List<_SensorPoint> points;
  final bool isDark;

  const _SensorTrendChart({required this.points, required this.isDark});

  @override
  State<_SensorTrendChart> createState() => _SensorTrendChartState();
}

class _SensorTrendChartState extends State<_SensorTrendChart> {
  int? _hoverIndex;

  String _clockLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _updateHover(Offset localPos, double width) {
    if (widget.points.isEmpty) return;
    final fraction = (localPos.dx / width).clamp(0.0, 1.0);
    final index = (fraction * (widget.points.length - 1)).round();
    setState(() => _hoverIndex = index.clamp(0, widget.points.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return Center(
        child: Text(
          'Collecting sensor data…',
          style: TextStyle(
            fontSize: 12.5,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (d) => _updateHover(d.localPosition, width),
          onPanUpdate: (d) => _updateHover(d.localPosition, width),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: _TrendPainter(
                    points: widget.points,
                    isDark: widget.isDark,
                    hoverIndex: _hoverIndex,
                  ),
                ),
              ),
              if (_hoverIndex != null && _hoverIndex! < widget.points.length)
                _buildTooltip(width),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(double width) {
    final point = widget.points[_hoverIndex!];
    final fraction = _hoverIndex! / (widget.points.length - 1);
    double left = fraction * width - 68;
    left = left.clamp(0.0, max(0.0, width - 136));

    return Positioned(
      left: left,
      top: 4,
      child: Container(
        width: 136,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _clockLabel(point.time),
              style: const TextStyle(color: Colors.white54, fontSize: 10.5),
            ),
            const SizedBox(height: 4),
            _tooltipRow(const Color(0xFFF97316), 'Temp', '${point.temp.toStringAsFixed(0)}'),
            _tooltipRow(const Color(0xFF2563EB), 'Humidity', '${point.humidity.toStringAsFixed(0)}'),
            _tooltipRow(const Color(0xFF16A34A), 'Soil', '${point.soil.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _tooltipRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<_SensorPoint> points;
  final bool isDark;
  final int? hoverIndex;

  _TrendPainter({required this.points, required this.isDark, this.hoverIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final gridColor = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final labelColor = (isDark ? Colors.white : Colors.black).withOpacity(0.35);
    final chartTop = 6.0;
    final chartBottom = size.height - 18;
    final chartHeight = chartBottom - chartTop;

    for (final pct in [0.0, 0.5, 1.0]) {
      final y = chartBottom - chartHeight * pct;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()..color = gridColor..strokeWidth = 1);
      final label = '${(pct * 100).toInt()}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 9.5, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height - 2));
    }

    for (final temp in [40, 20]) {
      final frac = ((temp - 15) / 30).clamp(0.0, 1.0);
      final y = chartBottom - chartHeight * frac;
      final tp = TextPainter(
        text: TextSpan(text: '$temp', style: TextStyle(fontSize: 9.5, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height - 2));
    }

    if (points.length < 2) return;

    Offset toPoint(int i, double Function(_SensorPoint) getValue, double minV, double maxV) {
      final x = size.width * (i / (points.length - 1));
      final v = getValue(points[i]).clamp(minV, maxV);
      final frac = (v - minV) / (maxV - minV);
      final y = chartBottom - chartHeight * frac;
      return Offset(x, y);
    }

    void drawLine(double Function(_SensorPoint) getValue, double minV, double maxV, Color color) {
      final path = Path();
      for (int i = 0; i < points.length; i++) {
        final p = toPoint(i, getValue, minV, maxV);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawLine((p) => p.temp, 15, 45, const Color(0xFFF97316));
    drawLine((p) => p.humidity, 0, 100, const Color(0xFF2563EB));
    drawLine((p) => p.soil, 0, 100, const Color(0xFF16A34A));

    if (hoverIndex != null && hoverIndex! < points.length) {
      final x = size.width * (hoverIndex! / (points.length - 1));
      canvas.drawLine(
        Offset(x, chartTop),
        Offset(x, chartBottom),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.15)
          ..strokeWidth = 1,
      );
      void dot(double Function(_SensorPoint) getValue, double minV, double maxV, Color color) {
        final p = toPoint(hoverIndex!, getValue, minV, maxV);
        canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
        canvas.drawCircle(p, 3.5, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      dot((p) => p.temp, 15, 45, const Color(0xFFF97316));
      dot((p) => p.humidity, 0, 100, const Color(0xFF2563EB));
      dot((p) => p.soil, 0, 100, const Color(0xFF16A34A));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.hoverIndex != hoverIndex || oldDelegate.isDark != isDark;
  }
}

// Tank level card
class _TankLevelBox extends StatefulWidget {
  final String title;
  final double level;
  final IconData icon;
  final List<Color> colors;
  final String pinInfo;
  final bool isDark;

  const _TankLevelBox({
    required this.title,
    required this.level,
    required this.icon,
    required this.colors,
    required this.pinInfo,
    required this.isDark,
  });

  @override
  State<_TankLevelBox> createState() => _TankLevelBoxState();
}

class _TankLevelBoxState extends State<_TankLevelBox> with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.level / 100).clamp(0.0, 1.0);
    final labelColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.colors.last),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.colors.last.withOpacity(0.08),
                border: Border.all(color: widget.colors.last.withOpacity(0.15)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: pct),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedPct, __) => CustomPaint(
                          size: const Size(double.infinity, 130),
                          painter: _WavePainter(
                            fillFraction: animatedPct,
                            phase: _waveController.value * 2 * pi,
                            colors: widget.colors,
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    '${widget.level.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: pct > 0.42
                          ? Colors.white
                          : (widget.isDark ? Colors.white : Colors.black87),
                      shadows: pct > 0.08
                          ? [Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 4)]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.pinInfo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double fillFraction;
  final double phase;
  final List<Color> colors;

  _WavePainter({
    required this.fillFraction,
    required this.phase,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waveAmplitude = 5.0;
    final baseY = size.height * (1 - fillFraction);

    Path buildWavePath(double phaseShift, double amplitude) {
      final path = Path();
      path.moveTo(0, baseY);
      const step = 4.0;
      for (double x = 0; x <= size.width; x += step) {
        final y = baseY + sin((x / size.width * 2 * pi) + phase + phaseShift) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      return path;
    }

    if (fillFraction <= 0.01) return;

    final backPaint = Paint()..color = colors.first.withOpacity(0.45);
    canvas.drawPath(buildWavePath(pi / 2, waveAmplitude * 0.7), backPaint);

    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, baseY, size.width, size.height - baseY + 20));
    canvas.drawPath(buildWavePath(0, waveAmplitude), frontPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction || oldDelegate.phase != phase;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}