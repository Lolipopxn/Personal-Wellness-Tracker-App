import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPageData(
      title: 'สุขภาพดี เริ่มต้นวันนี้',
      desc:
          'แอปนี้ช่วยติดตามสุขภาพและความเป็นอยู่ของคุณ\nทั้งการนอน อารมณ์ และโภชนาการ',
      imageAsset: 'assets/images/onboard_1.png',
    ),
    _OnboardPageData(
      title: 'ดูแลตัวเองง่าย ๆ',
      desc:
          'ติดตามตัวชี้วัดสำคัญ\nอัพเดตรายวันและรับรางวัลแรงใจเล็ก ๆ',
      imageAsset: 'assets/images/onboard_2.png',
    ),
    _OnboardPageData(
      title: 'ปรับแผนให้เหมาะกับคุณ',
      desc:
          'อายุ เพศ น้ำหนัก และเป้าหมาย\n(ลดน้ำหนัก / รักษาสุขภาพ / เพิ่มพลัง ฯลฯ)',
      imageAsset: 'assets/images/onboard_3.png',
    ),
    _OnboardPageData(
      title: 'รู้จักสุขภาพคุณมากขึ้น',
      desc:
          'มอนิเตอร์สถิติประจำวัน\nตั้งเป้าหมายใหม่ และเห็นความก้าวหน้าชัดเจนขึ้น',
      imageAsset: 'assets/images/onboard_4.png',
    ),
  ];

  Future<void> _finish() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() {
    _finish();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              p.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                width: 200,
                                height: 120,
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image, size: 56),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Dots(length: _pages.length, index: _index),
                        const SizedBox(height: 16),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.desc,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black.withOpacity(.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75C86B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _index == _pages.length - 1 ? 'เริ่มใช้งาน' : 'NEXT',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _skip,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('SKIP'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String title;
  final String desc;
  final String imageAsset;
  const _OnboardPageData({
    required this.title,
    required this.desc,
    required this.imageAsset,
  });
}

class _Dots extends StatelessWidget {
  final int length;
  final int index;
  const _Dots({required this.length, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 12 : 8,
          height: active ? 12 : 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF49C250) : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
