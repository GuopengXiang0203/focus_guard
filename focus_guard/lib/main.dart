import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const FocusGuardApp());
}

class FocusGuardApp extends StatelessWidget {
  const FocusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '专注守护',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isFocusMode = false;
  Timer? _timer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt('startHour') ?? 9;
    final startMinute = prefs.getInt('startMinute') ?? 0;
    final endHour = prefs.getInt('endHour') ?? 17;
    final endMinute = prefs.getInt('endMinute') ?? 0;
    
    setState(() {
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startHour', _startTime.hour);
    await prefs.setInt('startMinute', _startTime.minute);
    await prefs.setInt('endHour', _endTime.hour);
    await prefs.setInt('endMinute', _endTime.minute);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    bool inFocusPeriod = false;
    int remaining = 0;

    if (startMinutes <= endMinutes) {
      // 同一天：比如 9:00 - 17:00
      inFocusPeriod = currentMinutes >= startMinutes && currentMinutes < endMinutes;
      if (currentMinutes < startMinutes) {
        remaining = startMinutes - currentMinutes;
      } else if (currentMinutes >= endMinutes) {
        remaining = (24 * 60 - currentMinutes) + startMinutes;
      } else {
        remaining = endMinutes - currentMinutes;
      }
    } else {
      // 跨天：比如 22:00 - 6:00
      inFocusPeriod = currentMinutes >= startMinutes || currentMinutes < endMinutes;
      if (currentMinutes >= startMinutes) {
        remaining = (24 * 60 - currentMinutes) + endMinutes;
      } else if (currentMinutes < endMinutes) {
        remaining = endMinutes - currentMinutes;
      } else {
        remaining = startMinutes - currentMinutes;
      }
    }

    final hours = remaining ~/ 60;
    final minutes = remaining % 60;
    final seconds = 60 - now.second;

    String statusText;
    if (inFocusPeriod) {
      final remainSecs = (endMinutes - currentMinutes);
      if (remainSecs > 0) {
        statusText = '专注时间剩余 ${remainSecs ~/ 60}小时${remainSecs % 60}分钟';
      } else {
        statusText = '专注时间结束';
      }
    } else {
      if (currentMinutes < startMinutes) {
        statusText = '距专注开始还有 $hours 小时 $minutes 分钟';
      } else {
        statusText = '距专注开始还有 $hours 小时 $minutes 分钟';
      }
    }

    if (mounted) {
      setState(() {
        _remainingTime = statusText;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
      _saveSettings();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
      _saveSettings();
    }
  }

  Future<void> _startGuidedAccess() async {
    // 引导用户开启引导式访问
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 16),
            const Text(
              '开启引导式访问',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '步骤：\n1. 打开「设置」→「辅助功能」\n2. 点击「引导式访问」\n3. 开启「引导式访问」\n4. 设置密码',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openGuidedAccessSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '前往设置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGuidedAccessSettings() async {
    // 尝试打开辅助功能设置
    final url = Uri.parse('App-prefs:ACCESSIBILITY');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // 如果打不开，尝试打开通用设置
      final generalUrl = Uri.parse('App-prefs:');
      if (await canLaunchUrl(generalUrl)) {
        await launchUrl(generalUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 标题
              const Text(
                '专注守护',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '设定时间，自动进入专注模式',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 时间设置卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 开始时间
                    _buildTimeRow(
                      icon: Icons.wb_sunny_outlined,
                      label: '开始时间',
                      time: _startTime,
                      onTap: _selectStartTime,
                    ),
                    const Divider(height: 24),
                    // 结束时间
                    _buildTimeRow(
                      icon: Icons.nightlight_outlined,
                      label: '结束时间',
                      time: _endTime,
                      onTap: _selectEndTime,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 状态显示
              if (_remainingTime.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _remainingTime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // 大按钮
              GestureDetector(
                onTap: _startGuidedAccess,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '开始专注',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '点击开启 iOS 引导式访问',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 退出提示
              Text(
                '三击电源键可退出引导式访问',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final formatter = DateFormat('HH:mm');
    final displayTime = formatter.format(
      DateTime(2024, 1, 1, time.hour, time.minute),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            Text(
              displayTime,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
